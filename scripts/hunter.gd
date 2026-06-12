extends CharacterBody2D
## The Skriker — an exsurgent that hunts Halcyon's decks. It cannot be killed:
## only outrun, EMP-staggered (Synth burn or an EMP charge: 4s), or cut off
## behind a sealed bulkhead (it leaves, and finds another way). Suspense
## levers: you HEAR it before you see it (distance-attenuated heartbeat that
## quickens when it has you), and its attention is a weight — being near it
## with line of sight bleeds Moxie, feeding the derangement/whisper spiral.
##
## States: PATROL drifting between anchors -> HUNT toward a noise -> CHASE on
## line of sight -> SEARCH where it lost you -> back to PATROL. STUNNED freezes
## it. Difficulty scales speed and sight (GameState.difficulty); berserk() is
## the post-climax finale switch.

signal relocated  ## it gave up on a blocked route and went somewhere else

enum State { PATROL, HUNT, CHASE, SEARCH, STUNNED }

const DAMAGE := 25
const DAMAGE_MOXIE := 5
const DAMAGE_INTERVAL := 1.2
const DREAD_RADIUS := 260.0      ## within this + LOS, its attention drains you
const DREAD_INTERVAL := 1.5
const LOSE_SIGHT_GRACE := 3.0    ## seconds of broken LOS before it loses you
const SEARCH_TIME := 4.0
const BLOCKED_LIMIT := 5.0       ## seconds shoving a wall/bulkhead before it relocates
const BLOCKED_LIMIT_BERSERK := 1.5  ## in the finale it stops being patient
const ANCHOR_REACHED := 28.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $DamageZone
@onready var sight_ray: RayCast2D = $SightRay
@onready var heart: AudioStreamPlayer2D = $Heartbeat

var state: State = State.PATROL
var anchors: Array[Vector2] = []          ## set by the op script
var _anchor_index := 0
var _player: CharacterBody2D
var _speed := 105.0
var _sight_radius := 300.0
var _dread_moxie := 1
var _target := Vector2.ZERO               ## current movement goal
var _last_seen := Vector2.ZERO            ## player's position last time we had LOS
var _player_in_zone := false
var _damage_timer := 0.0
var _dread_timer := 0.0
var _lost_timer := 0.0
var _idle_timer := 0.0
var _blocked_timer := 0.0
var _stun_timer := 0.0
var _berserk := false

func _ready() -> void:
	add_to_group("hunter")
	_player = get_tree().get_first_node_in_group("player")
	damage_zone.body_entered.connect(_on_zone_entered)
	damage_zone.body_exited.connect(_on_zone_exited)
	if is_instance_valid(_player):
		sight_ray.add_exception(_player)
	_apply_difficulty()
	_build_frames()
	_build_heartbeat()
	sprite.play("crawl")
	if not anchors.is_empty():
		_target = anchors[0]

func _apply_difficulty() -> void:
	match GameState.difficulty:
		GameState.Difficulty.STORY:
			_speed = 70.0
			_sight_radius = 230.0
			_dread_moxie = 1
		GameState.Difficulty.RELENTLESS:
			_speed = 130.0
			_sight_radius = 370.0
			_dread_moxie = 2
		_:
			_speed = 105.0
			_sight_radius = 300.0
			_dread_moxie = 1

# ---------------------------------------------------------------------------
# Public API (the op script drives these)
# ---------------------------------------------------------------------------

## Something loud happened (elevator, the generator, the climax).
func alert_to(pos: Vector2) -> void:
	if state == State.STUNNED:
		return
	_target = pos
	if state != State.CHASE:
		state = State.HUNT

func stun(duration: float) -> void:
	state = State.STUNNED
	_stun_timer = duration
	velocity = Vector2.ZERO
	sprite.modulate = Color(0.6, 0.8, 1.0)

## The finale: containment is done and it knows where you are. Bypasses
## alert_to's stun guard — when the stun ends it wakes up already hunting.
## Capped just under the fastest morph: you can outrun it, barely, in a line.
func berserk() -> void:
	_berserk = true
	_speed = minf(_speed * 1.35, 165.0)
	_sight_radius += 120.0
	if is_instance_valid(_player):
		_target = _player.global_position
		if state != State.STUNNED:
			state = State.HUNT

## After a player death/respawn, be fair: go somewhere far away.
func relocate_far_from(pos: Vector2) -> void:
	if anchors.is_empty():
		return
	var best := anchors[0]
	for a in anchors:
		if a.distance_squared_to(pos) > best.distance_squared_to(pos):
			best = a
	global_position = best
	_target = best
	_anchor_index = anchors.find(best)
	_stun_timer = 0.0
	_blocked_timer = 0.0
	sprite.modulate = Color.WHITE
	state = State.PATROL

# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player) or _player.is_dead:
		velocity = Vector2.ZERO
		return
	match state:
		State.STUNNED:
			_stun_timer -= delta
			if _stun_timer <= 0.0:
				sprite.modulate = Color.WHITE
				if _berserk:  # it wakes up already hunting
					state = State.HUNT
					_target = _player.global_position
				else:
					state = State.SEARCH
					_idle_timer = SEARCH_TIME
			_update_heartbeat()
			return
		State.PATROL:
			_patrol(delta)
		State.HUNT:
			_move_toward(_target, delta)
			if global_position.distance_to(_target) < ANCHOR_REACHED:
				state = State.SEARCH
				_idle_timer = SEARCH_TIME
		State.CHASE:
			_target = _player.global_position
			_move_toward(_target, delta)
		State.SEARCH:
			velocity = Vector2.ZERO
			_idle_timer -= delta
			if _idle_timer <= 0.0:
				state = State.PATROL
	_update_senses(delta)
	_update_heartbeat()
	_apply_contact_damage(delta)

func _patrol(delta: float) -> void:
	if anchors.is_empty():
		velocity = Vector2.ZERO
		return
	if global_position.distance_to(anchors[_anchor_index]) < ANCHOR_REACHED:
		velocity = Vector2.ZERO
		_idle_timer -= delta
		if _idle_timer <= 0.0:
			_anchor_index = (_anchor_index + 1) % anchors.size()
			_idle_timer = randf_range(1.5, 3.0)
		return
	_move_toward(anchors[_anchor_index], delta)

func _move_toward(goal: Vector2, delta: float) -> void:
	var dir := global_position.direction_to(goal)
	velocity = dir * _speed
	var before := global_position
	move_and_slide()
	sprite.flip_h = velocity.x < 0.0
	# Shoving a wall or sealed bulkhead? It doesn't wait forever — and in the
	# finale, it barely waits at all.
	var patience := BLOCKED_LIMIT_BERSERK if _berserk else BLOCKED_LIMIT
	if global_position.distance_to(before) < _speed * delta * 0.25 \
			and global_position.distance_to(goal) > ANCHOR_REACHED * 2.0:
		_blocked_timer += delta
		if _blocked_timer >= patience:
			_blocked_timer = 0.0
			_relocate()
	else:
		_blocked_timer = 0.0

func _relocate() -> void:
	if anchors.is_empty():
		return
	# Berserk: it finds the way that comes out NEAREST the player. Otherwise it
	# wanders off — the anchor farthest from where it was stuck.
	var best := anchors[0]
	if _berserk and is_instance_valid(_player):
		for a in anchors:
			if a.distance_squared_to(_player.global_position) < best.distance_squared_to(_player.global_position):
				best = a
	else:
		for a in anchors:
			if a.distance_squared_to(global_position) > best.distance_squared_to(global_position):
				best = a
	global_position = best
	_anchor_index = anchors.find(best)
	_target = _player.global_position if _berserk else best
	state = State.HUNT if _berserk else State.PATROL
	relocated.emit()

func _has_line_of_sight() -> bool:
	sight_ray.target_position = to_local(_player.global_position)
	sight_ray.force_raycast_update()
	return not sight_ray.is_colliding()

func _update_senses(delta: float) -> void:
	var dist := global_position.distance_to(_player.global_position)
	var seen := dist < _sight_radius and _has_line_of_sight()
	if seen:
		_lost_timer = 0.0
		_last_seen = _player.global_position
		if state != State.CHASE:
			state = State.CHASE
	elif state == State.CHASE:
		_lost_timer += delta
		if _lost_timer > LOSE_SIGHT_GRACE:
			state = State.HUNT
			_target = _last_seen  # where you WERE — break LOS and stay broken
	# Its attention is a weight: near + seen = Moxie bleed.
	if seen and dist < DREAD_RADIUS and not _player.invulnerable:
		_dread_timer -= delta
		if _dread_timer <= 0.0:
			_player.reduce_moxie(_dread_moxie)
			_dread_timer = DREAD_INTERVAL
	else:
		_dread_timer = 0.0

func _apply_contact_damage(delta: float) -> void:
	if not _player_in_zone or _player.invulnerable:
		return
	_damage_timer -= delta
	if _damage_timer <= 0.0:
		_player.take_damage(DAMAGE)
		_player.reduce_moxie(DAMAGE_MOXIE)
		_damage_timer = DAMAGE_INTERVAL

func _on_zone_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_zone = true
		_damage_timer = 0.0

func _on_zone_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_zone = false

# ---------------------------------------------------------------------------
# The heartbeat: a low double thump, attenuated by distance — you hear it
# through the deck before you ever see it. It quickens when it has you.
# ---------------------------------------------------------------------------

func _update_heartbeat() -> void:
	heart.pitch_scale = 1.45 if state == State.CHASE else 1.0
	if state == State.STUNNED:
		heart.pitch_scale = 0.7

func _build_heartbeat() -> void:
	var rate := 22050
	var dur := 1.1
	var n := int(rate * dur)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var s := 0.0
		for thump_t: float in [0.0, 0.34]:  # lub... dub
			var dt := t - thump_t
			if dt >= 0.0 and dt < 0.22:
				s += sin(TAU * 52.0 * dt) * exp(-dt * 26.0) * 0.9
		var v := clampi(int(s * 32767.0), -32768, 32767)
		buf[i * 2] = v & 0xFF
		buf[i * 2 + 1] = (v >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = buf
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = n
	heart.stream = stream
	heart.max_distance = 460.0
	heart.attenuation = 1.6
	heart.play()

func _build_frames() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("crawl")
	frames.set_animation_speed("crawl", 3)
	frames.set_animation_loop("crawl", true)
	frames.add_frame("crawl", _load_tex("res://art/hunter/0.png"))
	frames.add_frame("crawl", _load_tex("res://art/hunter/1.png"))
	sprite.sprite_frames = frames

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null
