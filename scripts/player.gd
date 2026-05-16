extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal moxie_changed(current: int, maximum: int)
signal player_died

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var move_speed: float
var current_dir := "down"
var base_color: Color
var max_health: int = 100
var current_health: int = 100
var is_dead := false
var max_moxie: int = 100
var current_moxie: int = 100

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

	velocity = input * move_speed
	move_and_slide()
	_update_animation(input)

func _on_morph_changed(morph_id: StringName) -> void:
	_apply_morph(MorphManager.get_morph(morph_id))

func _apply_morph(data: MorphManager.MorphData) -> void:
	move_speed = data.speed
	max_health = data.max_health
	current_health = max_health
	base_color = data.color
	is_dead = false
	_build_placeholder_frames()
	sprite.play("idle_" + current_dir)
	health_changed.emit(current_health, max_health)
	moxie_changed.emit(current_moxie, max_moxie)

func take_damage(amount: int) -> void:
	if is_dead:
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
