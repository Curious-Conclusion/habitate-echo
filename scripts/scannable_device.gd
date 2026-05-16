extends Area2D

signal scan_completed

@export var scan_duration: float = 3.0
@export var prompt_text: String = "[Hold E] Scan Device"
@export var visual_color: Color = Color(0.6, 0.1, 0.6)

@onready var prompt_label: Label = $PromptLabel
@onready var visual: ColorRect = $Visual
@onready var scan_bar: ProgressBar = $ScanProgressBar

var player_in_range := false
var is_scanning := false
var scan_progress: float = 0.0
var scan_done := false

func _ready() -> void:
	prompt_label.text = prompt_text
	prompt_label.visible = false
	visual.color = visual_color
	scan_bar.visible = false
	scan_bar.max_value = scan_duration
	scan_bar.value = 0.0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if scan_done or not player_in_range:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		is_scanning = true
		scan_bar.visible = true

func _process(delta: float) -> void:
	if not is_scanning or scan_done:
		return
	if not player_in_range or not Input.is_action_pressed("interact"):
		_reset_scan()
		return
	scan_progress += delta
	scan_bar.value = scan_progress
	var secs := ceili(scan_duration - scan_progress)
	prompt_label.text = "Scanning... %d/%d" % [ceili(scan_progress), ceili(scan_duration)]
	if scan_progress >= scan_duration:
		_complete_scan()

func _reset_scan() -> void:
	is_scanning = false
	scan_progress = 0.0
	scan_bar.value = 0.0
	scan_bar.visible = false
	if player_in_range and not scan_done:
		prompt_label.text = prompt_text

func _complete_scan() -> void:
	scan_done = true
	is_scanning = false
	scan_bar.visible = false
	prompt_label.text = "[Scanned]"
	scan_completed.emit()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false
		if is_scanning:
			_reset_scan()
