extends Area2D

signal interact_requested

## Optional PNG sprite. When set, it replaces the colored-square visual.
@export var sprite_path: String = ""

@onready var prompt_label: Label = $PromptLabel
@onready var visual: ColorRect = $Visual

var player_in_range := false

func _ready() -> void:
	prompt_label.visible = false
	if sprite_path != "":
		visual.visible = false
		var spr := Sprite2D.new()
		spr.texture = _load_tex(sprite_path)
		add_child(spr)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact_requested.emit()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false
