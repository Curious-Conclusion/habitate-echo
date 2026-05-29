extends CharacterBody2D

@export var chase_speed: float = 70.0
@export var damage: int = 10
@export var damage_interval: float = 0.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $DamageZone

var player: CharacterBody2D
var player_in_zone := false
var damage_timer: float = 0.0

func _ready() -> void:
	add_to_group("nanite_swarm")
	player = get_tree().get_first_node_in_group("player")
	damage_zone.body_entered.connect(_on_body_entered)
	damage_zone.body_exited.connect(_on_body_exited)
	_build_swarm_frames()
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.is_dead:
		velocity = Vector2.ZERO
		return
	var dir := global_position.direction_to(player.global_position)
	velocity = dir * chase_speed
	move_and_slide()

	if player_in_zone and not player.invulnerable:
		damage_timer -= delta
		if damage_timer <= 0.0:
			player.take_damage(damage)
			player.reduce_moxie(3)
			damage_timer = damage_interval

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = true
		damage_timer = 0.0  # immediate first hit

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = false
		damage_timer = 0.0

# ---------------------------------------------------------------------------
# Procedural placeholder — jagged red-purple blob
# ---------------------------------------------------------------------------

func _build_swarm_frames() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 4)
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", _load_swarm_tex("res://art/swarm/0.png"))
	frames.add_frame("idle", _load_swarm_tex("res://art/swarm/1.png"))
	sprite.sprite_frames = frames

func _load_swarm_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return _swarm_tex(0)  # fall back to procedural if the PNG is missing

func _swarm_tex(frame_idx: int) -> ImageTexture:
	var s := 20
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var cx := s / 2.0
	var cy := s / 2.0
	var base_r := 7.0 if frame_idx == 0 else 6.0
	var col := Color(0.7, 0.1, 0.3)
	var col2 := Color(0.5, 0.05, 0.5)

	# Jagged body
	for x in s:
		for y in s:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy))
			var jag := sin(atan2(y - cy, x - cx) * 6.0 + frame_idx * 1.5) * 2.0
			if d <= base_r + jag:
				img.set_pixel(x, y, col if (x + y + frame_idx) % 3 != 0 else col2)
			elif d <= base_r + jag + 1.0:
				img.set_pixel(x, y, col.darkened(0.4))

	# Scattered particles
	var rng := RandomNumberGenerator.new()
	rng.seed = 42 + frame_idx
	for i in 5:
		var px := rng.randi_range(1, s - 2)
		var py := rng.randi_range(1, s - 2)
		var d := Vector2(px + 0.5, py + 0.5).distance_to(Vector2(cx, cy))
		if d > base_r + 2.0 and d < s / 2.0:
			img.set_pixel(px, py, col2)

	return ImageTexture.create_from_image(img)
