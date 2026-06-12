extends Area2D
## A sealable bulkhead door. [E] toggles it: sealed = a solid blocker the
## hunter (and you) cannot pass. It will not wait at a sealed door forever —
## it leaves to find another way (hunter.gd's blocked-relocate). Sealing
## yourself in feels safe. Feels.

signal toggled(sealed: bool)

@export var start_sealed: bool = false

@onready var prompt_label: Label = $PromptLabel
@onready var door_sprite: Sprite2D = $DoorSprite
@onready var blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D

var sealed := false
var _player_in_range := false

func _ready() -> void:
	prompt_label.visible = false
	door_sprite.texture = _load_tex("res://art/objects/bulkhead.png")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_set_sealed(start_sealed)

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_set_sealed(not sealed)
		toggled.emit(sealed)

func _set_sealed(value: bool) -> void:
	sealed = value
	blocker_shape.set_deferred("disabled", not sealed)
	door_sprite.modulate = Color(1.0, 0.55, 0.5) if sealed else Color.WHITE
	prompt_label.text = "[E] Unseal Bulkhead" if sealed else "[E] Seal Bulkhead"

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		prompt_label.visible = false

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null
