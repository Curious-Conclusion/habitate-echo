extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal moxie_changed(current: int, maximum: int)
signal player_died
signal moxie_flavor(text: String)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var move_speed: float
var current_dir := "down"
var base_color: Color
var max_health: int = 100
var current_health: int = 100
var is_dead := false
var max_moxie: int = 100
var current_moxie: int = 100

var speed_mult: float = 1.0   ## transient multiplier from a Moxie burn
var invulnerable: bool = false

const MOXIE_BURN_COST := 30
const DERANGE_THRESHOLD := 35  ## below this, low-Moxie derangement sets in

func _ready() -> void:
	_apply_morph(MorphManager.get_current_morph())
	MorphManager.morph_changed.connect(_on_morph_changed)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input.length() > 1.0:
		input = input.normalized()

	velocity = input * move_speed * speed_mult * _derange_factor()
	move_and_slide()
	_update_animation(input)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("moxie_burn"):
		try_moxie_burn()

## Derangement: at low Moxie, control slows. 1.0 above threshold, ramping
## down to 0.5 at zero Moxie.
func _derange_factor() -> float:
	if current_moxie >= DERANGE_THRESHOLD:
		return 1.0
	return remap(float(current_moxie), 0.0, float(DERANGE_THRESHOLD), 0.5, 1.0)

func is_deranged() -> bool:
	return current_moxie < DERANGE_THRESHOLD

func _on_morph_changed(morph_id: StringName) -> void:
	_apply_morph(MorphManager.get_morph(morph_id))

func _apply_morph(data: MorphManager.MorphData) -> void:
	move_speed = data.speed
	max_health = data.max_health
	current_health = max_health
	base_color = data.color
	is_dead = false
	var art_dir: String = _ART_DIRS.get(data.id, "")
	if art_dir != "":
		_build_morph_frames(art_dir)
	else:
		_build_placeholder_frames()
	sprite.play("idle_" + current_dir)
	health_changed.emit(current_health, max_health)
	moxie_changed.emit(current_moxie, max_moxie)

func take_damage(amount: int) -> void:
	if is_dead or invulnerable:
		return
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	_flash_damage()
	if current_health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	player_died.emit()

func _flash_damage() -> void:
	var tw := create_tween()
	sprite.modulate = Color.RED
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func restore_health() -> void:
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)

func reduce_moxie(amount: int) -> void:
	current_moxie = maxi(current_moxie - amount, 0)
	moxie_changed.emit(current_moxie, max_moxie)

func restore_moxie(amount: int) -> void:
	current_moxie = mini(current_moxie + amount, max_moxie)
	moxie_changed.emit(current_moxie, max_moxie)

# ---------------------------------------------------------------------------
# Moxie burn — spend Moxie for an emergency effect. The result depends on the
# sleeve you currently wear (its ability shapes what the burn does).
# ---------------------------------------------------------------------------

func try_moxie_burn() -> void:
	if is_dead:
		return
	if current_moxie < MOXIE_BURN_COST:
		moxie_flavor.emit("Not enough Moxie to burn.")
		return
	reduce_moxie(MOXIE_BURN_COST)
	match MorphManager.get_current_morph().ability:
		MorphManager.Ability.WALL_CLING:
			_burn_scramble()
		MorphManager.Ability.VACUUM_SEAL:
			_burn_emp()
		MorphManager.Ability.CYBERBRAIN:
			_burn_medichine()
		_:
			moxie_flavor.emit("This sleeve has nothing to burn for.")

## Octomorph: ink-and-scramble — a burst of speed and brief invulnerability.
func _burn_scramble() -> void:
	moxie_flavor.emit("Ink and scramble — you blur out of reach.")
	speed_mult = 2.0
	invulnerable = true
	sprite.modulate = Color(0.6, 1.0, 0.85)
	await get_tree().create_timer(3.0).timeout
	speed_mult = 1.0
	invulnerable = false
	sprite.modulate = Color.WHITE

## Synth: EMP discharge — disperse every nanite swarm on the station.
func _burn_emp() -> void:
	var swarms := get_tree().get_nodes_in_group("nanite_swarm")
	for s in swarms:
		s.queue_free()
	if swarms.is_empty():
		moxie_flavor.emit("EMP discharge — nothing to disperse.")
	else:
		moxie_flavor.emit("EMP discharge — the swarm scatters into static.")

## Biomorph: medichine surge — flush damage and restore the flesh.
func _burn_medichine() -> void:
	moxie_flavor.emit("Medichine surge — your wounds knit shut.")
	restore_health()

func _update_animation(input: Vector2) -> void:
	if input == Vector2.ZERO:
		sprite.play("idle_" + current_dir)
		return

	# Map 8-direction input to 4-direction animation
	if absf(input.x) > absf(input.y):
		current_dir = "right" if input.x > 0.0 else "left"
	else:
		current_dir = "down" if input.y > 0.0 else "up"

	sprite.play("walk_" + current_dir)

# ---------------------------------------------------------------------------
# Procedural placeholder — draws a simple octomorph blob with tentacle stubs.
# Replace with real SpriteFrames once art is ready.
# ---------------------------------------------------------------------------

## Morphs with authored PNG art (res://art/<dir>/) use it; any others fall back
## to the procedural placeholder below.
const _ART_DIRS := {
	&"octomorph": "octomorph",
	&"synth": "synth",
	&"biomorph": "biomorph",
}

func _build_morph_frames(art_dir: String) -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for dir: String in ["down", "up", "left", "right"]:
		var t0 := _load_sprite_tex("res://art/%s/%s_0.png" % [art_dir, dir])
		var t1 := _load_sprite_tex("res://art/%s/%s_1.png" % [art_dir, dir])
		var idle_name := "idle_" + dir
		frames.add_animation(idle_name)
		frames.set_animation_speed(idle_name, 2)
		frames.set_animation_loop(idle_name, true)
		frames.add_frame(idle_name, t0)
		var walk_name := "walk_" + dir
		frames.add_animation(walk_name)
		frames.set_animation_speed(walk_name, 6)
		frames.set_animation_loop(walk_name, true)
		frames.add_frame(walk_name, t0)
		frames.add_frame(walk_name, t1)
	sprite.sprite_frames = frames

func _load_sprite_tex(path: String) -> Texture2D:
	# Use the imported resource when available; otherwise read the PNG directly.
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _build_placeholder_frames() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var palette := {
		"down":  base_color,
		"up":    base_color.lightened(0.15),
		"left":  base_color.darkened(0.1),
		"right": base_color.darkened(0.05),
	}

	for dir: String in palette:
		var col: Color = palette[dir]

		# idle — single frame
		var idle_name := "idle_" + dir
		frames.add_animation(idle_name)
		frames.set_animation_speed(idle_name, 1)
		frames.set_animation_loop(idle_name, true)
		frames.add_frame(idle_name, _octomorph_tex(col, 0))

		# walk — two-frame bob
		var walk_name := "walk_" + dir
		frames.add_animation(walk_name)
		frames.set_animation_speed(walk_name, 6)
		frames.set_animation_loop(walk_name, true)
		frames.add_frame(walk_name, _octomorph_tex(col, 0))
		frames.add_frame(walk_name, _octomorph_tex(col.lightened(0.15), 1))

	sprite.sprite_frames = frames

func _octomorph_tex(color: Color, frame_idx: int) -> ImageTexture:
	var s := 24
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var cx := s / 2.0
	var cy := s / 2.0
	var r := 8.0 if frame_idx == 0 else 7.0

	# Body disc
	for x in s:
		for y in s:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy))
			if d <= r:
				img.set_pixel(x, y, color)
			elif d <= r + 1.0:
				img.set_pixel(x, y, color.darkened(0.35))

	# Tentacle stubs — four short lines beneath the body
	var tc := color.darkened(0.25)
	var legs: Array[Vector2]
	if frame_idx == 0:
		legs = [Vector2(-5, 6), Vector2(-2, 7), Vector2(2, 7), Vector2(5, 6)]
	else:
		legs = [Vector2(-4, 7), Vector2(-1, 8), Vector2(3, 8), Vector2(6, 7)]
	for off in legs:
		var px := int(cx + off.x)
		var py := int(cy + off.y)
		if px >= 0 and px < s and py >= 0 and py < s:
			img.set_pixel(px, py, tc)
		if px + 1 < s and py < s:
			img.set_pixel(px + 1, py, tc)

	# Eye dot (direction hint)
	var eye_off := Vector2.ZERO
	match current_dir:
		"down":  eye_off = Vector2(0, 2)
		"up":    eye_off = Vector2(0, -3)
		"left":  eye_off = Vector2(-3, 0)
		"right": eye_off = Vector2(3, 0)
	var ex := clampi(int(cx + eye_off.x), 0, s - 1)
	var ey := clampi(int(cy + eye_off.y), 0, s - 1)
	img.set_pixel(ex, ey, Color.WHITE)

	return ImageTexture.create_from_image(img)
