extends CanvasLayer
## In-field gear quick-use. Press [G] to open a list of carried consumables;
## pick one to spend it. Self-contained — drop this node into any op scene; it
## finds the player by group and reads the loadout from GameState. Effects are
## resolved via GearCatalog (see effect ids there).

@onready var panel: PanelContainer = $Panel
@onready var button_box: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ButtonBox

const HEAL_MOXIE := 25

var _player: CharacterBody2D

func _ready() -> void:
	panel.visible = false
	_player = get_tree().get_first_node_in_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("use_gear"):
		return
	if panel.visible:
		get_viewport().set_input_as_handled()
		_close()
	elif not get_tree().paused:  # don't pop over a dialogue / morph-select
		get_viewport().set_input_as_handled()
		_open()

func _open() -> void:
	_build_buttons()
	panel.visible = true
	get_tree().paused = true
	await get_tree().process_frame
	for child in button_box.get_children():
		if child is Button and not (child as Button).disabled:
			child.grab_focus()
			break

func _close() -> void:
	panel.visible = false
	get_tree().paused = false

func _build_buttons() -> void:
	for c in button_box.get_children():
		c.queue_free()
	if GameState.gear.is_empty():
		var lbl := Label.new()
		lbl.text = "No gear carried."
		button_box.add_child(lbl)
		return
	# Stack identical items: gear_id -> count.
	var counts: Dictionary = {}
	for id: StringName in GameState.gear:
		counts[id] = int(counts.get(id, 0)) + 1
	for id: StringName in counts:
		var btn := Button.new()
		btn.text = "%s  x%d" % [GearCatalog.display_name(id), counts[id]]
		btn.pressed.connect(_on_gear_pressed.bind(id))
		button_box.add_child(btn)

func _on_gear_pressed(gear_id: StringName) -> void:
	if not GameState.consume_gear(gear_id):
		_close()
		return
	var fx := GearCatalog.effect(gear_id)
	# Unpause before applying so effects (and any scene change) run normally.
	panel.visible = false
	get_tree().paused = false
	_apply_effect(fx)

func _apply_effect(fx: String) -> void:
	match fx:
		"heal":
			if is_instance_valid(_player):
				_player.restore_health()
				_player.restore_moxie(HEAL_MOXIE)
		"emp":
			for s in get_tree().get_nodes_in_group("nanite_swarm"):
				s.queue_free()
		"extract":
			SceneFlow.go_to_hub()
