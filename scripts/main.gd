extends Node2D

const NaniteSwarmScene := preload("res://scenes/nanite_swarm.tscn")

@onready var resleeving_pod: Area2D = $ResleevingPod
@onready var morph_select_ui: PanelContainer = $UI/MorphSelectUI
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var sample_locker: Area2D = $SampleLocker
@onready var terminal: Area2D = $Terminal
@onready var airlock_control: Area2D = $AirlockControl
@onready var lore_terminal: Area2D = $LoreTerminal
@onready var maintenance_hatch: Area2D = $MaintenanceHatch
@onready var autodoc: Area2D = $Autodoc
@onready var glitch_layer: CanvasLayer = $GlitchLayer
@onready var hacking_minigame: CanvasLayer = $HackingMinigame
@onready var suspicious_device: Area2D = $SuspiciousDevice
@onready var player: CharacterBody2D = $Player
@onready var hp_bar: ProgressBar = $UI/HpBar
@onready var moxie_bar: ProgressBar = $UI/MoxieBar
@onready var end_screen: CanvasLayer = $EndScreen
@onready var camera: Camera2D = $Camera2D
@onready var crew_npc: Area2D = $CrewNPC

func _ready() -> void:
	# Bootstrap: if this op scene was launched directly (not deployed from the
	# hub), arm KE-7 as Op 0 so objectives + checkpoint exist.
	if GameState.current_op_id != &"ke7":
		SceneFlow.begin_op(&"ke7")
	# Load persistent ego moxie into the live Player, then mirror in-op changes
	# back to GameState so the ego carries between ops.
	player.current_moxie = GameState.moxie
	player.moxie_changed.emit(player.current_moxie, player.max_moxie)
	player.moxie_changed.connect(func(c: int, _m: int) -> void: GameState.moxie = c)
	resleeving_pod.interact_requested.connect(morph_select_ui.open)
	sample_locker.interact_requested.connect(_on_sample_locker)
	terminal.interact_requested.connect(_on_terminal)
	airlock_control.interact_requested.connect(_on_airlock)
	lore_terminal.interact_requested.connect(_on_lore_terminal)
	maintenance_hatch.interact_requested.connect(_on_maintenance_hatch)
	autodoc.interact_requested.connect(_on_autodoc)
	crew_npc.interact_requested.connect(_on_crew_npc)
	suspicious_device.scan_completed.connect(_on_device_scanned)
	player.player_died.connect(_on_player_died)
	player.moxie_flavor.connect(moxie_bar.show_flavor)
	MorphManager.morph_changed.connect(_on_resleeve_moxie)
	hp_bar.setup(player)
	moxie_bar.setup(player)
	glitch_layer.setup(player)
	hacking_minigame.setup(player)
	hacking_minigame.hack_succeeded.connect(_on_hack_succeeded)
	hacking_minigame.hack_failed.connect(_on_hack_failed)
	MissionManager.all_objectives_completed.connect(_on_all_complete)

func _process(_delta: float) -> void:
	# Camera trails the player; Camera2D limits keep it inside the station.
	camera.global_position = player.global_position

# -- Crew NPC (Crew Quarters, branching dialogue + Firewall reputation) --

func _on_crew_npc() -> void:
	if GameState.get_flag(&"has_override"):
		dialogue_box.show_lines(["\"The override's 77-ALEPH. Use it at the terminal — hurry.\""])
		return
	if GameState.get_flag(&"npc_talked"):
		if GameState.firewall_rep > 0:
			_npc_offer_help()
		else:
			dialogue_box.show_lines(["The crew member won't meet your eyes. \"...Just leave me alone.\""])
		return
	GameState.set_flag(&"npc_talked")
	dialogue_box.show_lines_with_choices(
		[
			"A sleeved crew member is wedged into the corner, shaking.",
			"\"Stay back! Are you one of them? One of the infected?\"",
		],
		[
			"\"I'm Firewall. I'm here to help.\"",
			"\"Tell me what you know. Now.\"",
			"\"Who are you?\"",
		],
	)
	dialogue_box.choice_made.connect(_on_npc_choice, CONNECT_ONE_SHOT)

func _on_npc_choice(index: int) -> void:
	match index:
		0:  # reassure -> trust
			GameState.firewall_rep += 1
			dialogue_box.show_lines(["The tension drains from their shoulders. \"Firewall. Oh, thank god.\""])
			await dialogue_box.dialogue_finished
			_npc_offer_help()
		1:  # intimidate -> hostile
			GameState.firewall_rep -= 1
			dialogue_box.show_lines(["They flinch away. \"I don't know anything. Leave me ALONE.\""])
		2:  # neutral -> lore, no trust earned
			dialogue_box.show_lines([
				"\"I was the station's mesh tech. Before the async tore through us.\"",
				"\"Stop it, and maybe this nightmare ends. That's all I've got.\"",
			])

func _npc_offer_help() -> void:
	GameState.set_flag(&"has_override")
	dialogue_box.show_lines([
		"\"Listen — I rerouted the async's lockout before I hid in here.\"",
		"\"Override code: 77-ALEPH. Punch it into the Server Alcove terminal.\"",
		"\"It skips the intrusion gauntlet entirely. Just end this.\"",
	])

# -- Sample Locker (Med Bay, breadcrumb hint) --

func _on_sample_locker() -> void:
	dialogue_box.show_lines([
		"You pry open the sample locker. It's empty.",
		"A maintenance log is taped inside:",
		"\"Stack moved to the crawlspace hatch in the Server Alcove — too sensitive to leave in Med Bay.\"",
	])

# -- Med Autodoc (Med Bay, restores Moxie, limited doses) --

const AUTODOC_RESTORE := 40
var _autodoc_doses := 2

func _on_autodoc() -> void:
	if _autodoc_doses <= 0:
		dialogue_box.show_lines(["The autodoc's medichine reservoir is empty."])
		return
	if player.current_moxie >= player.max_moxie:
		dialogue_box.show_lines(["Your ego is stable. The autodoc finds nothing to mend."])
		return
	_autodoc_doses -= 1
	player.restore_moxie(AUTODOC_RESTORE)
	dialogue_box.show_lines([
		"The autodoc administers a course of calming medichines.",
		"Your thoughts settle; the static at the edges recedes.",
		"Moxie restored. Doses remaining: %d." % _autodoc_doses,
	])

# -- Maintenance Hatch (Server Alcove, requires WALL_CLING) --

func _on_maintenance_hatch() -> void:
	if MissionManager.is_complete(&"retrieve_stack"):
		dialogue_box.show_lines(["The maintenance hatch hangs open. The crawlspace beyond is empty."])
		return
	var morph := MorphManager.get_current_morph()
	if morph.ability != MorphManager.Ability.WALL_CLING:
		dialogue_box.show_lines([
			"A narrow maintenance hatch is wedged behind the server racks.",
			"The crawlspace beyond is too tight for this morph to navigate.",
			"Try resleeving into the Octomorph at the Med Bay pod.",
		])
		return
	MissionManager.complete_objective(&"retrieve_stack")
	dialogue_box.show_lines([
		"You fold your Octomorph limbs and slip into the crawlspace.",
		"Wedged behind a coolant line, a cortical stack glints in the dark.",
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
	# With the crew override, you can skip the intrusion gauntlet entirely.
	if GameState.get_flag(&"has_override"):
		dialogue_box.show_lines_with_choices(
			["The crew override (77-ALEPH) is ready. Use it, or crack the lockout yourself?"],
			["Use override — skip the hack", "Hack it manually"],
		)
		dialogue_box.choice_made.connect(_on_terminal_choice, CONNECT_ONE_SHOT)
		return
	# Otherwise, break the async's lockout via the intrusion minigame.
	hacking_minigame.open()

func _on_terminal_choice(index: int) -> void:
	if index == 0:
		MissionManager.complete_objective(&"scan_stack")
		dialogue_box.show_lines([
			"You enter the crew override: 77-ALEPH.",
			"The async's lockout folds open without a fight.",
			"The scan reveals an async infection buried in the ego backup.",
			"The signal must be vented before it reaches the mesh.",
			"Objective complete: Stack scanned.",
		])
	else:
		hacking_minigame.open()

func _on_hack_succeeded() -> void:
	MissionManager.complete_objective(&"scan_stack")
	dialogue_box.show_lines([
		"You trace the lockout route and crack the async's defences.",
		"The scan reveals an async infection buried in the ego backup.",
		"The signal must be vented before it reaches the mesh.",
		"Objective complete: Stack scanned.",
	])

func _on_hack_failed() -> void:
	player.reduce_moxie(15)
	dialogue_box.show_lines([
		"INTRUSION DETECTED. The async lashes back through the mesh.",
		"The feedback sears your mind — and it's summoning defenders.",
	])
	await dialogue_box.dialogue_finished
	_spawn_nanite_swarm()

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
			dialogue_box.show_lines(OpCatalog.get_op(&"ke7").briefing)
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
	for i in GameState.swarm_count():
		var swarm := NaniteSwarmScene.instantiate()
		swarm.global_position = suspicious_device.global_position + Vector2(i * 30, 40)
		add_child(swarm)

# -- Player Death / Respawn --

func _on_player_died() -> void:
	for swarm in get_tree().get_nodes_in_group("nanite_swarm"):
		swarm.queue_free()
	player.reduce_moxie(10)
	if player.current_moxie <= 0:
		# Ego death = lose-continuity fork (DESIGN_OUTLINE.md §9): restore an
		# older backup, restart the op, carry a sticky trauma. Not a game-over.
		dialogue_box.show_lines([
			"Your morph dies — and the emergency resleeve tears something loose.",
			"Firewall restores you from an older backup. The thread of who you were frays.",
			"You wake at the deploy point. Something is missing, and it always will be.",
		])
		await dialogue_box.dialogue_finished
		SceneFlow.ego_death_fork()
		return
	dialogue_box.show_lines([
		"Your morph has been destroyed.",
		"Emergency resleeving initiated...",
		"You wake up in the Med Bay pod.",
	])
	await dialogue_box.dialogue_finished
	player.global_position = Vector2(159, 361)
	player.restore_health()
	if suspicious_device.scan_done and not MissionManager.is_complete(&"vent_signal"):
		_spawn_nanite_swarm()

# -- Win condition --

func _on_all_complete() -> void:
	await dialogue_box.dialogue_finished
	var op_id := GameState.current_op_id
	GameState.complete_op(op_id)
	dialogue_box.show_lines(OpCatalog.get_op(op_id).debrief)
	await dialogue_box.dialogue_finished
	SceneFlow.go_to_hub()
