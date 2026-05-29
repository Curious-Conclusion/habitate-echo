extends PanelContainer

@onready var button_box: VBoxContainer = $MarginContainer/VBoxContainer/ButtonBox

var _buttons: Dictionary = {}

func _ready() -> void:
	visible = false
	_build_buttons()
	MorphManager.morph_changed.connect(_on_morph_changed)

func open() -> void:
	_refresh_buttons()
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _build_buttons() -> void:
	for id: StringName in MorphManager.get_all_ids():
		var btn := Button.new()
		btn.name = String(id)
		btn.pressed.connect(_on_morph_pressed.bind(id))
		button_box.add_child(btn)
		_buttons[id] = btn

func _refresh_buttons() -> void:
	var current := MorphManager.current_morph_id
	for id: StringName in _buttons:
		var data := MorphManager.get_morph(id)
		var btn: Button = _buttons[id]
		var label := "%s  |  SPD %d  HP %d" % [data.display_name, int(data.speed), data.max_health]
		if id == current:
			label += "  [current]"
		btn.text = label
		btn.disabled = (id == current)

func _on_morph_pressed(morph_id: StringName) -> void:
	visible = false
	# The op scene (any root) owns a TransitionLayer child; resolve it relative to
	# the current scene rather than a hard-coded /root/Main path.
	var transition := get_tree().current_scene.get_node_or_null("TransitionLayer") as CanvasLayer
	if transition:
		transition.play_resleeve(morph_id)
	else:
		MorphManager.switch_morph(morph_id)
		get_tree().paused = false

func _on_morph_changed(_id: StringName) -> void:
	_refresh_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		close()
