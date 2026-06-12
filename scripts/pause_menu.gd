extends CanvasLayer
## [Esc] pause overlay. Freezes the tree (the hunter, swarms, and hazards all
## pause with it). Won't open over a dialogue or other pausing panel — those
## own the pause already. Self-contained: instance into any playable scene.

@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var quit_btn: Button = $Panel/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	panel.visible = false
	resume_btn.pressed.connect(_close)
	quit_btn.pressed.connect(_quit_to_title)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if panel.visible:
		get_viewport().set_input_as_handled()
		_close()
	elif not get_tree().paused:  # a dialogue/panel already owns the pause
		get_viewport().set_input_as_handled()
		_open()

func _open() -> void:
	panel.visible = true
	get_tree().paused = true
	resume_btn.grab_focus()

func _close() -> void:
	panel.visible = false
	get_tree().paused = false

## Mid-op progress follows the save model: hub + op-start checkpoint only.
func _quit_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title.tscn")
