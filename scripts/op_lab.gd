extends Node2D
## Op 2 — Aphelion research lab. An async-infected researcher and an
## info-hazard archive (DESIGN_OUTLINE.md §3, Act 1). The archive is a choice:
## three partitions, one safe — clues point to the right one, the wrong one
## reads you back. The researcher is the first big ethics fork: rehabilitate
## (costs Moxie now) or cull (instant, but a sticky trauma comes home).
## Hand-built site on the Op template; threat scales with GameState.difficulty.

const NaniteSwarmScene := preload("res://scenes/nanite_swarm.tscn")

const OP_ID := &"lab"
const POD_SPAWN := Vector2(120, 120)

const HAZARD_PRIMARY := 30    ## Moxie seared by the basilisk archive (x difficulty)
const HAZARD_PERSONNEL := 10  ## migraine sting for the partial hint
const REHAB_BACKLASH := 25    ## psychic cost of administering the counter-protocol

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var resleeving_pod: Area2D = $ResleevingPod
@onready var morph_select_ui: PanelContainer = $UI/MorphSelectUI
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var hp_bar: ProgressBar = $UI/HpBar
@onready var moxie_bar: ProgressBar = $UI/MoxieBar
@onready var glitch_layer: CanvasLayer = $GlitchLayer
@onready var data_slate: Area2D = $DataSlate
@onready var archive_terminal: Area2D = $ArchiveTerminal
@onready var specimen_tanks: Area2D = $SpecimenTanks
@onready var crawl_hatch: Area2D = $CrawlHatch
@onready var researcher: Area2D = $Researcher
@onready var extract_point: Area2D = $ExtractPoint

func _ready() -> void:
	if GameState.current_op_id != OP_ID:
		SceneFlow.begin_op(OP_ID)
	player.current_moxie = GameState.moxie
	player.moxie_changed.emit(player.current_moxie, player.max_moxie)
	player.moxie_changed.connect(func(c: int, _m: int) -> void: GameState.moxie = c)

	resleeving_pod.interact_requested.connect(morph_select_ui.open)
	data_slate.interact_requested.connect(_on_data_slate)
	archive_terminal.interact_requested.connect(_on_archive)
	specimen_tanks.interact_requested.connect(_on_specimen_tanks)
	crawl_hatch.interact_requested.connect(_on_crawl_hatch)
	researcher.interact_requested.connect(_on_researcher)
	extract_point.interact_requested.connect(_on_extract_point)
	player.player_died.connect(_on_player_died)
	player.moxie_flavor.connect(moxie_bar.show_flavor)
	MorphManager.morph_changed.connect(_on_resleeve_moxie)
	hp_bar.setup(player)
	moxie_bar.setup(player)
	glitch_layer.setup(player)
	MissionManager.all_objectives_completed.connect(_on_all_complete)

func _process(_delta: float) -> void:
	camera.global_position = player.global_position

# -- Atrium data slate (orientation + teaches the cryo gate) --

func _on_data_slate() -> void:
	dialogue_box.show_lines([
		"APHELION LAB — STATUS BOARD (47 days stale):",
		"· Archive wing: LOCKED to cyberbrain-keyed staff.",
		"· Cold storage: cryo containment venting. Sealed chassis advised.",
		"Someone has scratched a line into the screen, deep enough to feel:",
		"\"DON'T READ THE PRIMARY. IT READS BACK.\"",
	])

# -- Specimen lab (set dressing; the dread is in what's missing) --

func _on_specimen_tanks() -> void:
	dialogue_box.show_lines([
		"Rows of specimen tanks, most gone dark.",
		"The nearest one is cracked from the inside.",
		"Whatever it held is not inside anymore.",
	])

# -- Crawl hatch (Octomorph): the assistant's note — the clean clue --

func _on_crawl_hatch() -> void:
	if GameState.get_flag(&"lab_note_found"):
		dialogue_box.show_lines(["The crawlspace beyond the hatch is empty now. You took the note."])
		return
	var morph := MorphManager.get_current_morph()
	if morph.ability != MorphManager.Ability.WALL_CLING:
		dialogue_box.show_lines([
			"A maintenance hatch behind the tank racks — somebody hid in there.",
			"The crawlspace is far too tight for this morph.",
			"An octomorph could fold itself through.",
		])
		return
	GameState.set_flag(&"lab_note_found")
	dialogue_box.show_lines([
		"You pour yourself through the hatch. Someone slept in this crawlspace —",
		"a thermal blanket, ration wrappers, and a note in a fast, scared hand:",
		"\"Okafor never trusted the primary server. The real containment",
		"protocol lives on the MAINTENANCE PARTITION. Don't read anything else.\"",
	])

# -- Archive terminal (Biomorph): three partitions, one safe --

func _on_archive() -> void:
	var morph := MorphManager.get_current_morph()
	if morph.ability != MorphManager.Ability.CYBERBRAIN:
		dialogue_box.show_lines([
			"The archive crowns want a direct cyberbrain handshake.",
			"This morph's wetware has nothing to offer them.",
			"Resleeve into the worker pod at the atrium pod station.",
		])
		return
	if MissionManager.is_complete(&"recover_protocol"):
		dialogue_box.show_lines(["You have what you came for. The rest of this archive can stay buried."])
		return
	dialogue_box.show_lines_with_choices(
		[
			"The archive offers three partitions. The index is corrupted —",
			"each entry is just a name and a wrongness you can't place.",
		],
		["Primary research archive", "Personnel records", "Maintenance partition", "Disconnect"],
	)
	dialogue_box.choice_made.connect(_on_archive_choice, CONNECT_ONE_SHOT)

func _on_archive_choice(index: int) -> void:
	match index:
		0:
			_read_primary()
		1:
			_read_personnel()
		2:
			MissionManager.complete_objective(&"recover_protocol")
			dialogue_box.show_lines([
				"Buried in the maintenance logs, disguised as a defrag schedule:",
				"Okafor's counter-protocol. Clean, complete, and signed with her",
				"private key — from three days after the lab went dark.",
				"Objective complete: containment protocol recovered.",
			])
		3:
			pass

func _read_primary() -> void:
	if GameState.get_flag(&"lab_primary_read"):
		dialogue_box.show_lines(["The primary archive hangs scorched and empty. Nothing sane remains."])
		return
	GameState.set_flag(&"lab_primary_read")
	player.reduce_moxie(int(HAZARD_PRIMARY * GameState.hazard_moxie_mult()))
	dialogue_box.show_lines([
		"You open the primary archive.",
		"The data is looking back.",
		"BASILISK HAZARD — glyphs crawl up the optic feed and in. You wrench",
		"the connection closed, but some of it came with you.",
	])
	if GameState.difficulty != GameState.Difficulty.STORY:
		await dialogue_box.dialogue_finished
		dialogue_box.show_lines(["Somewhere in the walls, containment drones wake up."])
		await dialogue_box.dialogue_finished
		_spawn_swarm(archive_terminal.global_position + Vector2(0, 60))

func _read_personnel() -> void:
	player.reduce_moxie(int(HAZARD_PERSONNEL * GameState.hazard_moxie_mult()))
	dialogue_box.show_lines([
		"Personnel records. A migraine of half-corrupted faces — you surface",
		"with your eyes watering and one clean line of log data:",
		"\"Dr. Okafor — last login: MAINTENANCE PARTITION, 03:14, day 47.\"",
	])

# -- Dr. Okafor (Cold Storage): the ethics fork --

func _on_researcher() -> void:
	if MissionManager.is_complete(&"resolve_researcher") \
			or GameState.get_flag(&"researcher_saved") or GameState.get_flag(&"researcher_culled"):
		# On a replay the choice was already made in this playthrough — it
		# stays made. Complete the objective so the op remains finishable.
		if not MissionManager.is_complete(&"resolve_researcher"):
			MissionManager.complete_objective(&"resolve_researcher")
		dialogue_box.show_lines(["The cryo rack where she stood is empty. The cold keeps no opinion."])
		return
	dialogue_box.show_lines_with_choices(
		[
			"A figure in a lab coat stands among the cryo racks. Too still.",
			"Frost has grown up her sleeves. She is smiling at nothing.",
			"\"You hear it too too, don't you? The signal. It sings in the meat meat.\"",
			"\"I tried to transcribe it. It transcribed me back back.\"",
		],
		[
			"Administer the counter-protocol",
			"Purge her ego  (cull)",
			"Step back",
		],
	)
	dialogue_box.choice_made.connect(_on_researcher_choice, CONNECT_ONE_SHOT)

func _on_researcher_choice(index: int) -> void:
	match index:
		0:
			_rehabilitate()
		1:
			_cull()
		2:
			dialogue_box.show_lines(["She watches you retreat. \"Soon soon,\" she agrees, kindly."])

func _rehabilitate() -> void:
	if not MissionManager.is_complete(&"recover_protocol"):
		dialogue_box.show_lines([
			"You have nothing to offer her but sympathy, and the async already",
			"speaks louder than that. Find Okafor's counter-protocol first.",
		])
		return
	player.reduce_moxie(int(REHAB_BACKLASH * GameState.hazard_moxie_mult()))
	GameState.firewall_rep += 1
	GameState.set_flag(&"researcher_saved")
	MissionManager.complete_objective(&"resolve_researcher")
	dialogue_box.show_lines([
		"You jack the counter-protocol into her stack. She screams in two",
		"voices — then, slowly, in one.",
		"The backlash claws through your own ego on the way out.",
		"\"...it's quiet,\" she whispers. \"Thank you. Get me home.\"",
		"Objective complete: Dr. Okafor stabilized for transport.",
	])
	await dialogue_box.dialogue_finished
	_post_resolution_pressure()

func _cull() -> void:
	GameState.set_flag(&"researcher_culled")
	GameState.add_trauma(&"executioners_echo")
	MissionManager.complete_objective(&"resolve_researcher")
	dialogue_box.show_lines([
		"You press the purge wand to her stack. She doesn't resist.",
		"\"Finally finally,\" she says, and is gone.",
		"It takes three seconds. Something of those three seconds stays",
		"lodged in you, and does not melt with the frost.",
		"Objective complete: the infection will not spread.",
	])
	await dialogue_box.dialogue_finished
	_post_resolution_pressure()

## Either way, the lab notices the async signal cut off. Pressure on the way out.
func _post_resolution_pressure() -> void:
	if GameState.difficulty == GameState.Difficulty.STORY:
		return
	dialogue_box.show_lines(["The lab goes very quiet. Then every vent starts whispering at once."])
	await dialogue_box.dialogue_finished
	_spawn_swarm(researcher.global_position + Vector2(-80, -60))

# -- Egocast relay (Atrium): extract --

func _on_extract_point() -> void:
	if not MissionManager.is_complete(&"recover_protocol") \
			or not MissionManager.is_complete(&"resolve_researcher"):
		dialogue_box.show_lines([
			"The relay hums, ready to cast you home.",
			"But the contract isn't closed: the protocol, and Dr. Okafor.",
		])
		return
	# Show the extract beat BEFORE completing: _on_all_complete awaits
	# dialogue_finished, so the last objective must leave a dialogue open.
	dialogue_box.show_lines([
		"You key the relay. Aphelion's lights gutter as it draws power.",
		"Last one out. Nobody will know you were ever here.",
	])
	MissionManager.complete_objective(&"extract")

# -- Shared op plumbing (same patterns as op_hauler.gd) --

func _on_resleeve_moxie(_morph_id: StringName) -> void:
	player.reduce_moxie(15)

func _spawn_swarm(at: Vector2) -> void:
	for i in GameState.swarm_count():
		var swarm := NaniteSwarmScene.instantiate()
		swarm.global_position = at + Vector2(i * 30, 0)
		add_child(swarm)

func _on_player_died() -> void:
	for swarm in get_tree().get_nodes_in_group("nanite_swarm"):
		swarm.queue_free()
	player.reduce_moxie(10)
	if player.current_moxie <= 0:
		dialogue_box.show_lines([
			"The lab takes your morph — and the backup Firewall wakes is days",
			"younger than the you who died. Something is missing, always.",
		])
		await dialogue_box.dialogue_finished
		SceneFlow.ego_death_fork()
		return
	dialogue_box.show_lines([
		"Your morph fails. Emergency resleeving fires.",
		"You wake at the atrium pod, ego intact — barely.",
	])
	await dialogue_box.dialogue_finished
	player.global_position = POD_SPAWN
	player.restore_health()

func _on_all_complete() -> void:
	await dialogue_box.dialogue_finished
	var op_id := GameState.current_op_id
	GameState.complete_op(op_id)
	dialogue_box.show_lines(OpCatalog.get_op(op_id).debrief)
	await dialogue_box.dialogue_finished
	SceneFlow.go_to_hub()
