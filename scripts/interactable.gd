extends Area2D

signal interact_requested

@export var prompt_text: String = "[E] Interact"
@export var visual_color: Color = Color.WHITE
@export var visual_size: Vector2 = Vector2(32, 32)

@onready var prompt_label: Label = $PromptLabel
@onready var visual: ColorRect = $Visual

var player_in_range := false

func _ready() -> void:
	prompt_label.text = prompt_text
	prompt_label.visible = false
	visual.color = visual_color
	visual.size = visual_size
	visual.position = -visual_size / 2.0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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
