extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var title_label: Label = $Background/VBoxContainer/TitleLabel
@onready var flavor_label: Label = $Background/VBoxContainer/FlavorLabel
@onready var credit_label: Label = $Background/VBoxContainer/CreditLabel
@onready var prompt_label: Label = $Background/VBoxContainer/PromptLabel

var _active := false

func _ready() -> void:
	background.visible = false

func show_end(title: String, lines: Array, bg_color: Color) -> void:
	title_label.text = title
	flavor_label.text = "\n".join(lines)
	background.color = bg_color
	background.visible = true
	background.modulate.a = 0.0
	_active = true
	get_tree().paused = true
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(background, "modulate:a", 1.0, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		get_tree().paused = false
		get_tree().reload_current_scene()
