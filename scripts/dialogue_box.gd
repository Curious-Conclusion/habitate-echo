extends CanvasLayer

signal dialogue_finished
signal choice_made(choice_index: int)

@onready var panel: PanelContainer = $Panel
@onready var dialogue_label: Label = $Panel/MarginContainer/VBoxContainer/DialogueLabel
@onready var choice_box: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ChoiceBox
@onready var continue_hint: Label = $Panel/MarginContainer/VBoxContainer/ContinueHint

var _lines: Array = []
var _current_line: int = 0
var _choices: Array = []
var _is_open: bool = false
var _awaiting_choice: bool = false

func _ready() -> void:
	panel.visible = false

func show_lines(lines: Array) -> void:
	_lines = lines
	_choices = []
	_start()

func show_lines_with_choices(lines: Array, choices: Array) -> void:
	_lines = lines
	_choices = choices
	_start()

func _start() -> void:
	_current_line = 0
	_is_open = true
	_awaiting_choice = false
	panel.visible = true
	get_tree().paused = true
	_show_current()

func _show_current() -> void:
	dialogue_label.text = str(_lines[_current_line])
	var is_last := _current_line >= _lines.size() - 1
	if is_last and _choices.size() > 0:
		_show_choices()
	else:
		_clear_choices()
		continue_hint.visible = true

func _show_choices() -> void:
	_awaiting_choice = true
	continue_hint.visible = false
	for child in choice_box.get_children():
		child.queue_free()
	for i in _choices.size():
		var btn := Button.new()
		btn.text = str(_choices[i])
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choice_box.add_child(btn)
	await get_tree().process_frame
	if choice_box.get_child_count() > 0:
		choice_box.get_child(0).grab_focus()

func _clear_choices() -> void:
	_awaiting_choice = false
	for child in choice_box.get_children():
		child.queue_free()

func _advance() -> void:
	_current_line += 1
	if _current_line >= _lines.size():
		_close()
	else:
		_show_current()

func _close() -> void:
	_is_open = false
	_awaiting_choice = false
	panel.visible = false
	_clear_choices()
	get_tree().paused = false
	dialogue_finished.emit()

func _on_choice_pressed(index: int) -> void:
	_close()
	choice_made.emit(index)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if _awaiting_choice:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance()
