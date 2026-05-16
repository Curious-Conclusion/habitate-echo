extends Node2D

const NaniteSwarmScene := preload("res://scenes/nanite_swarm.tscn")

@onready var resleeving_pod: Area2D = $ResleevingPod
@onready var morph_select_ui: PanelContainer = $UI/MorphSelectUI
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var sample_locker: Area2D = $SampleLocker
@onready var terminal: Area2D = $Terminal
@onready var airlock_control: Area2D = $AirlockControl
@onready var lore_terminal: Area2D = $LoreTerminal
@onready var suspicious_device: Area2D = $SuspiciousDevice
@onready var player: CharacterBody2D = $Player
@onready var hp_bar: ProgressBar = $UI/HpBar
@onready var moxie_bar: ProgressBar = $UI/MoxieBar
@onready var end_screen: CanvasLayer = $EndScreen

func _ready() -> void:
	resleeving_pod.interact_requested.connect(morph_select_ui.open)
	sample_locker.interact_requested.connect(_on_sample_locker)
	terminal.interact_requested.connect(_on_terminal)
	airlock_control.interact_requested.connect(_on_airlock)
	lore_terminal.interact_requested.connect(_on_lore_terminal)
	suspicious_device.scan_completed.connect(_on_device_scanned)
	player.player_died.connect(_on_player_died)
	MorphManager.morph_changed.connect(_on_resleeve_moxie)
	hp_bar.setup(player)
	moxie_bar.setup(player)
	MissionManager.all_objectives_completed.connect(_on_all_complete)

# -- Sample Locker (Med Bay, any morph) --

func _on_sample_locker() -> void:
	if MissionManager.is_complete(&"retrieve_stack"):
		dialogue_box.show_lines(["The locker is empty. You already have the cortical stack."])
		return
	MissionManager.complete_objective(&"retrieve_stack")
	dialogue_box.show_lines([
		"You open the sample locker.",
		"Inside, a cortical stack glints under the amber light.",
		"Cortical stack retrieved.",
	])

# -- Terminal (Server Alcove, requires CYBERBRAIN) --

func _on_terminal() -> void:
	var morph := MorphManager.get_current_morph()
	if morph.ability != MorphManager.Ability.CYBERBRAIN:
		dialogue_box.show_lines([
			"This terminal requires a cyberbrain interface.",
			"Your current morph can't access it.",
			"Try resleeving into the Biomorph at the Med Bay pod.",
		])
		return
	if not MissionManager.is_complete(&"retrieve_stack"):
		dialogue_box.show_lines([
			"The terminal is ready, but you have no cortical stack to scan.",
			"Check the sample locker in Med Bay first.",
		])
		return
	if MissionManager.is_complete(&"scan_stack"):
		dialogue_box.show_lines(["You've already scanned the cortical stack."])
		return
	MissionManager.complete_objective(&"scan_stack")
	dialogue_box.show_lines([
		"You slot the cortical stack into the terminal.",
		"The scan reveals an async infection buried in the ego backup.",
		"The signal must be vented before it reaches the mesh.",
		"Objective complete: Stack scanned.",
	])

# -- Airlock Control (Airlock Corridor, requires VACUUM_SEAL) --

func _on_airlock() -> void:
	var morph := MorphManager.get_current_morph()
	if morph.ability != MorphManager.Ability.VACUUM_SEAL:
		dialogue_box.show_lines([
			"The airlock requires vacuum-sealed hardware to operate.",
			"Your current morph would not survive depressurisation.",
			"Try resleeving into the Synth at the Med Bay pod.",
		])
		return
	if not MissionManager.is_complete(&"scan_stack"):
		dialogue_box.show_lines([
			"You could open the airlock, but the threat hasn't been identified.",
			"Scan the cortical stack at the Server Alcove terminal first.",
		])
		return
	if MissionManager.is_complete(&"vent_signal"):
		dialogue_box.show_lines(["The async signal has already been vented."])
		return
	MissionManager.complete_objective(&"vent_signal")
	dialogue_box.show_lines([
		"You cycle the airlock and vent the async signal into vacuum.",
		"The corrupted data stream disperses harmlessly into space.",
		"Objective complete: Async signal neutralised.",
	])

# -- Lore Terminal (Lounge, multiple choice) --

func _on_lore_terminal() -> void:
	dialogue_box.show_lines_with_choices(
		["A data pad sits on the lounge table. What do you want to read?"],
		["Station Manifest", "Firewall Briefing", "Never mind"],
	)
	dialogue_box.choice_made.connect(_on_lore_choice, CONNECT_ONE_SHOT)

func _on_lore_choice(index: int) -> void:
	match index:
		0:
			dialogue_box.show_lines([
				"MANIFEST: Orbital hab module KE-7.",
				"Crew complement: 4 (currently: 1 active, 3 sleeved).",
				"Last inspection: 14 days ago.",
			])
		1:
			dialogue_box.show_lines([
				"FIREWALL BRIEFING: Suspect async contamination detected.",
				"Retrieve and scan the cortical stack in Med Bay.",
				"Neutralise any threat before it reaches the mesh.",
			])
		2:
			pass

# -- Moxie (resleeve stress) --

func _on_resleeve_moxie(_morph_id: StringName) -> void:
	player.reduce_moxie(15)

# -- Suspicious Device / Nanite Swarm --

func _on_device_scanned() -> void:
	dialogue_box.show_lines([
		"Scan complete. The device is emitting an unknown signal.",
		"Warning: nanite swarm detected — hostile entity emerging!",
	])
	await dialogue_box.dialogue_finished
	_spawn_nanite_swarm()

func _spawn_nanite_swarm() -> void:
	var swarm := NaniteSwarmScene.instantiate()
	swarm.global_position = suspicious_device.global_position + Vector2(0, 40)
	add_child(swarm)

# -- Player Death / Respawn --

func _on_player_died() -> void:
	for swarm in get_tree().get_nodes_in_group("nanite_swarm"):
		swarm.queue_free()
	player.reduce_moxie(10)
	if player.current_moxie <= 0:
		end_screen.show_end("EGO DEATH", [
			"Your ego fractures beyond recovery.",
			"The last resleeving tore something that cannot be repaired.",
			"Somewhere, a backup of you still exists — but it is no longer you.",
		], Color(0.15, 0.02, 0.02))
		return
	dialogue_box.show_lines([
		"Your morph has been destroyed.",
		"Emergency resleeving initiated...",
		"You wake up in the Med Bay pod.",
	])
	await dialogue_box.dialogue_finished
	player.global_position = Vector2(159, 361)
	player.restore_health()

# -- Win condition --

func _on_all_complete() -> void:
	await dialogue_box.dialogue_finished
	end_screen.show_end("MISSION COMPLETE", [
		"All objectives fulfilled. The async threat is contained.",
		"Firewall will scrub the station records. You were never here.",
		"Your ego backup updates. You survived. This time.",
	], Color(0.02, 0.1, 0.12))
