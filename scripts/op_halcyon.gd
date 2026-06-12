extends Node2D
## Op 3 — Halcyon Station (Act 2). Three stacked decks joined by a maintenance
## spine: crawlway vents (Octomorph, quiet) and an elevator (needs power, fast,
## LOUD). A blackout concourse, an info-hazard vault, fire and vacuum sections,
## sealable bulkheads — and the Skriker, an exsurgent that hunts the decks by
## sound and sight. Climax: a three-way containment decision that remembers
## what you did to Dr. Okafor, then a flight back up to the relay with the
## hunter loose. Design doc: site_halcyon_layout.md.

const NaniteSwarmScene := preload("res://scenes/nanite_swarm.tscn")

const OP_ID := &"halcyon"
const POD_SPAWN := Vector2(100, 120)

const VAULT_BLEED := 15        ## Moxie cost of pulling the payload (x difficulty)
const COUNTERSCRIPT_RISK := 30 ## Moxie cost of running Sava's script unaided
const COUNTERSCRIPT_CAP := 40  ## one-shot spikes stay survivable on RELENTLESS
const VENT_TOLL := 20          ## reading the manifest costs you NOW (x difficulty)

## Spine stops: deck id -> [station position, player landing position]
const ELEVATOR_STOPS := {
	&"A": [Vector2(640, 240), Vector2(586, 240)],
	&"B": [Vector2(640, 780), Vector2(586, 780)],
	&"C": [Vector2(640, 1300), Vector2(586, 1300)],
}
const VENT_STOPS := {
	&"A": [Vector2(860, 420), Vector2(806, 420)],
	&"B": [Vector2(860, 960), Vector2(806, 960)],
	&"C": [Vector2(860, 1500), Vector2(806, 1500)],
}

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var morph_select_ui: PanelContainer = $UI/MorphSelectUI
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var hp_bar: ProgressBar = $UI/HpBar
@onready var moxie_bar: ProgressBar = $UI/MoxieBar
@onready var glitch_layer: CanvasLayer = $GlitchLayer
@onready var blackout: ColorRect = $Room/BlackoutA
@onready var hunter: CharacterBody2D = $Hunter
@onready var brief_slate: Area2D = $BriefSlate
@onready var bridge_log: Area2D = $BridgeLog
@onready var egocast_relay: Area2D = $EgocastRelay
@onready var vault: Area2D = $Vault
@onready var crew_bunks: Area2D = $CrewBunks
@onready var autodoc: Area2D = $Autodoc
@onready var hydro_tank: Area2D = $HydroTank
@onready var hydro_cache: Area2D = $HydroCache
@onready var generator: Area2D = $Generator
@onready var core: Area2D = $Core

var _travel_kind := ""        ## which spine system the open choice belongs to
var _travel_options: Array[StringName] = []
var _autodoc_doses := 2

func _ready() -> void:
	if GameState.current_op_id != OP_ID:
		SceneFlow.begin_op(OP_ID)
	player.current_moxie = GameState.moxie
	player.moxie_changed.emit(player.current_moxie, player.max_moxie)
	player.moxie_changed.connect(func(c: int, _m: int) -> void: GameState.moxie = c)

	for pod_name: String in ["PodA", "PodB", "PodC"]:
		get_node(pod_name).interact_requested.connect(morph_select_ui.open)
	brief_slate.interact_requested.connect(_on_brief_slate)
	bridge_log.interact_requested.connect(_on_bridge_log)
	egocast_relay.interact_requested.connect(_on_relay)
	vault.interact_requested.connect(_on_vault)
	crew_bunks.interact_requested.connect(_on_crew_bunks)
	autodoc.interact_requested.connect(_on_autodoc)
	hydro_tank.interact_requested.connect(_on_hydro_tank)
	hydro_cache.interact_requested.connect(_on_hydro_cache)
	generator.interact_requested.connect(_on_generator)
	core.interact_requested.connect(_on_core)
	for ev: String in ["ElevatorA", "ElevatorB", "ElevatorC"]:
		get_node(ev).interact_requested.connect(_on_elevator)
	for vt: String in ["VentA", "VentB", "VentC"]:
		get_node(vt).interact_requested.connect(_on_vent)

	player.player_died.connect(_on_player_died)
	player.moxie_flavor.connect(moxie_bar.show_flavor)
	MorphManager.morph_changed.connect(_on_resleeve_moxie)
	hp_bar.setup(player)
	moxie_bar.setup(player)
	glitch_layer.setup(player)
	MissionManager.all_objectives_completed.connect(_on_all_complete)

	var anchors: Array[Vector2] = [
		Vector2(640, 120), Vector2(840, 400),     # deck A spine side
		Vector2(560, 700), Vector2(840, 900),     # deck B
		Vector2(640, 1200), Vector2(820, 1450),   # deck C
	]
	hunter.anchors = anchors
	hunter.relocated.connect(func() -> void:
		moxie_bar.show_flavor("Somewhere on another deck, metal shrieks and gives."))

func _process(_delta: float) -> void:
	camera.global_position = player.global_position

# ---------------------------------------------------------------------------
# Deck A — arrival, the bridge, the way home
# ---------------------------------------------------------------------------

func _on_brief_slate() -> void:
	dialogue_box.show_lines([
		"HALCYON STATION — arrival manifest, 61 days stale.",
		"· Main power: OFFLINE. Elevator inoperative. Backup generator: deck C.",
		"· Maintenance crawlway runs all three decks — rated for slitheroid",
		"  and octomorph chassis only.",
		"Under the manifest, in dried brown ink, someone wrote:",
		"\"IT COUNTS OUR HEARTBEATS. WALK SOFT.\"",
	])

func _on_bridge_log() -> void:
	dialogue_box.show_lines([
		"The bridge log is still warm — someone kept it alive on trickle charge.",
		"Final entry, Firewall cipher. Sentinel SAVA — your contact aboard:",
		"\"The source is in the containment core. I wrote a counter-script.",
		"It will work. Trust me. TRUST ME. trust me trust me trust me\"",
		"The last line repeats for nine hundred pages.",
	])

func _on_relay() -> void:
	if not MissionManager.is_complete(&"contain"):
		dialogue_box.show_lines([
			"The egocast relay is dark, its capacitors bled into the emergency ring.",
			"Casting out with the source live below would carry it home in your",
			"own ego like a passenger. Contain it first.",
		])
		return
	dialogue_box.show_lines([
		"The relay drinks the last of Halcyon's power and opens the sky.",
		"Behind you, something screams up through three decks of dark.",
		"You do not look back. You cast.",
	])
	MissionManager.complete_objective(&"egocast_out")

# ---------------------------------------------------------------------------
# Deck B — the vault, the bunks, the med bay
# ---------------------------------------------------------------------------

func _on_vault() -> void:
	if MissionManager.is_complete(&"extract_infohazard"):
		dialogue_box.show_lines(["The vault stands open and empty. The light through the seam is out."])
		return
	var morph := MorphManager.get_current_morph()
	if morph.ability != MorphManager.Ability.CYBERBRAIN:
		dialogue_box.show_lines([
			"The vault's lock wants a cyberbrain handshake and a steady mind.",
			"This morph's wetware has nothing to plug in. There are resleeving",
			"pods on every deck — the worker pod sleeve carries a cyberbrain.",
		])
		return
	player.reduce_moxie(int(VAULT_BLEED * GameState.hazard_moxie_mult()))
	MissionManager.complete_objective(&"extract_infohazard")
	dialogue_box.show_lines([
		"The vault opens on a single storage lattice, warm as a wound.",
		"You pull the payload through your own cyberbrain to package it —",
		"there is no other way — and for one long second it pulls back.",
		"Payload extracted. You are carrying it now. Try not to think about it.",
	])

func _on_crew_bunks() -> void:
	dialogue_box.show_lines([
		"Crew quarters. Forty bunks, blankets still creased from bodies.",
		"Every cortical cradle at every headboard hangs open and empty.",
		"Not ejected. Harvested.",
	])

func _on_autodoc() -> void:
	if _autodoc_doses <= 0:
		dialogue_box.show_lines(["The automed's medichine reservoir is dry."])
		return
	if player.current_moxie >= player.max_moxie:
		dialogue_box.show_lines(["The automed scans you twice. \"No intervention indicated,\" it lies."])
		return
	_autodoc_doses -= 1
	player.restore_moxie(40)
	dialogue_box.show_lines([
		"The automed floods you with calming medichines.",
		"The station's sounds sort themselves back into machinery. Mostly.",
		"Doses remaining: %d." % _autodoc_doses,
	])

# ---------------------------------------------------------------------------
# Deck C — hydroponics, the generator, the core
# ---------------------------------------------------------------------------

func _on_hydro_tank() -> void:
	dialogue_box.show_lines([
		"Hydroponics grew on after the breach — vacuum-burned vines in rows,",
		"frozen mid-reach toward a sun that was never in here.",
		"Something has been eating them anyway.",
	])

func _on_hydro_cache() -> void:
	if GameState.get_flag(&"halcyon_cache_taken"):
		dialogue_box.show_lines(["The emergency cache hangs open, empty."])
		return
	if GameState.grant_gear(&"medichine"):
		GameState.set_flag(&"halcyon_cache_taken")
		dialogue_box.show_lines([
			"An emergency cache, miraculously sealed against the vacuum.",
			"Inside: one medichine dose, still viable. Pocketed.",
		])
	else:
		dialogue_box.show_lines(["A sealed medichine dose — but your loadout has no room for it."])

func _on_generator() -> void:
	if MissionManager.is_complete(&"restore_power"):
		dialogue_box.show_lines(["The generator turns over steadily, pretending it never stopped."])
		return
	var morph := MorphManager.get_current_morph()
	if morph.ability != MorphManager.Ability.CYBERBRAIN:
		dialogue_box.show_lines([
			"The generator's start sequence is keyed to a cyberbrain interface.",
			"This morph can't shake its hand. There's a resleeving pod across",
			"the reactor floor — the worker pod sleeve will do.",
		])
		return
	MissionManager.complete_objective(&"restore_power")
	dialogue_box.show_lines([
		"You thread the start sequence and the generator catches with a shudder",
		"that rolls up through all three decks like something waking.",
		"Lights stutter on. The elevator chimes, polite and wrong.",
		"And every dead speaker on the station crackles — once — like a breath.",
	])
	await dialogue_box.dialogue_finished
	var tw := create_tween()
	tw.tween_property(blackout, "color:a", 0.0, 1.5)
	hunter.alert_to(generator.global_position)
	moxie_bar.show_flavor("Below the engine note: footsteps, hurrying somewhere.")

func _on_core() -> void:
	if MissionManager.is_complete(&"contain"):
		dialogue_box.show_lines(["The core is silent. Whatever answer you gave it, it keeps."])
		return
	if not MissionManager.is_complete(&"restore_power") \
			or not MissionManager.is_complete(&"extract_infohazard"):
		dialogue_box.show_lines([
			"The containment core hangs in its cage, beating light.",
			"Its seals need station power, and its purge logic needs the vault",
			"payload as a reference key. You are not ready to answer it yet.",
		])
		return
	dialogue_box.show_lines_with_choices(
		[
			"The core's light slows to match your heartbeat.",
			"Three ways to end Halcyon, and no fourth where everyone is fine:",
		],
		[
			"Vent the station to space",
			"Run Sava's counter-script",
			"Burn the vault payload",
			"Step back",
		],
	)
	dialogue_box.choice_made.connect(_on_core_choice, CONNECT_ONE_SHOT)

func _on_core_choice(index: int) -> void:
	match index:
		0:
			_contain_vent()
		1:
			_contain_counterscript()
		2:
			_contain_burn()
		3:
			dialogue_box.show_lines(["The core's light speeds back up, disappointed. Or eager."])

func _contain_vent() -> void:
	GameState.firewall_rep += 1
	GameState.set_flag(&"halcyon_vented")
	GameState.add_trauma(&"hundred_names")
	player.reduce_moxie(int(VENT_TOLL * GameState.hazard_moxie_mult()))
	MissionManager.complete_objective(&"contain")
	dialogue_box.show_lines([
		"You key the emergency vent sequence, every deck at once.",
		"Halcyon exhales. The source's signal shreds into hard vacuum —",
		"along with every stored ego still aboard, wherever they were hiding.",
		"You read the crew manifest first. You wish you hadn't. All those names.",
		"Firewall will call this decisive. Firewall isn't the one who counted.",
	])
	await dialogue_box.dialogue_finished
	_finale()

func _contain_counterscript() -> void:
	GameState.set_flag(&"halcyon_counterscript")
	MissionManager.complete_objective(&"contain")
	if GameState.get_flag(&"researcher_saved"):
		GameState.firewall_rep += 2
		dialogue_box.show_lines([
			"You load Sava's counter-script — and a second pair of hands steadies yours.",
			"Okafor's stabilized pattern, riding your backup like a second opinion.",
			"She has seen this signal from the inside. She edits as you run it.",
			"The core's light gutters, flares... and goes out, clean.",
			"Two of you saved each other today. Firewall will never know how.",
		])
	else:
		GameState.firewall_rep += 1
		GameState.set_flag(&"network_exposed")
		player.reduce_moxie(mini(int(COUNTERSCRIPT_RISK * GameState.hazard_moxie_mult()), COUNTERSCRIPT_CAP))
		dialogue_box.show_lines([
			"You load Sava's counter-script and it fights you the whole way down —",
			"nine hundred pages of TRUST ME wrapped around a knife of real code.",
			"It works. The core goes dark. But something in the script lingered",
			"over your mesh credentials on its way through.",
		])
	await dialogue_box.dialogue_finished
	_finale()

func _contain_burn() -> void:
	GameState.firewall_rep -= 1
	GameState.set_flag(&"halcyon_burned")
	MissionManager.complete_objective(&"contain")
	dialogue_box.show_lines([
		"You feed the vault payload into the core's purge logic and burn both.",
		"The source starves without its reference key. The light dims to nothing.",
		"No one else dies today. Nothing comes home with you, either —",
		"not the research, not the proof, not the reason any of this happened.",
		"You leave empty-handed. Everyone still hiding aboard leaves alive.",
		"Call it a trade.",
	])
	await dialogue_box.dialogue_finished
	_finale()

## Containment is done and the Skriker knows. Get back to the relay.
func _finale() -> void:
	dialogue_box.show_lines([
		"Three decks up, the egocast relay thrums to life.",
		"Much closer, the dark answers it. RUN.",
	])
	await dialogue_box.dialogue_finished
	hunter.berserk()
	if GameState.difficulty != GameState.Difficulty.STORY:
		_spawn_swarm(core.global_position + Vector2(-60, -40))

# ---------------------------------------------------------------------------
# The spine — vents (quiet, Octomorph) and the elevator (fast, loud)
# ---------------------------------------------------------------------------

func _on_vent() -> void:
	var morph := MorphManager.get_current_morph()
	if morph.ability != MorphManager.Ability.WALL_CLING:
		dialogue_box.show_lines([
			"The crawlway vent gapes, pried from the inside.",
			"Only an octomorph could fold itself through and climb the spine.",
		])
		return
	_open_travel_choices("vent", VENT_STOPS, "The crawlway runs the station's spine. Climb to:")

func _on_elevator() -> void:
	if not MissionManager.is_complete(&"restore_power"):
		dialogue_box.show_lines([
			"The elevator is dead. Its call panel doesn't even pretend.",
			"Backup generator: deck C. The crawlway still works — for some bodies.",
		])
		return
	_open_travel_choices("elevator", ELEVATOR_STOPS,
			"The elevator waits, bright and loud as a confession. Ride to:")

func _open_travel_choices(kind: String, stops: Dictionary, prompt: String) -> void:
	_travel_kind = kind
	_travel_options = []
	var choices: Array = []
	var here := _nearest_deck(stops)
	for deck: StringName in stops:
		if deck == here:
			continue
		_travel_options.append(deck)
		choices.append("Deck %s" % deck)
	choices.append("Stay")
	dialogue_box.show_lines_with_choices([prompt], choices)
	dialogue_box.choice_made.connect(_on_travel_chosen, CONNECT_ONE_SHOT)

func _on_travel_chosen(index: int) -> void:
	if index >= _travel_options.size():
		return  # "Stay"
	var stops: Dictionary = ELEVATOR_STOPS if _travel_kind == "elevator" else VENT_STOPS
	var deck: StringName = _travel_options[index]
	player.global_position = stops[deck][1]
	if _travel_kind == "elevator":
		hunter.alert_to(player.global_position)
		moxie_bar.show_flavor("The elevator announces you to every deck at once.")
	else:
		moxie_bar.show_flavor("You climb the spine in silence. Walk soft.")

func _nearest_deck(stops: Dictionary) -> StringName:
	var best: StringName = &"A"
	var best_d := INF
	for deck: StringName in stops:
		var d: float = (stops[deck][0] as Vector2).distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = deck
	return best

# ---------------------------------------------------------------------------
# Shared op plumbing
# ---------------------------------------------------------------------------

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
			"Halcyon takes your morph — and the resleeve tears the thread loose.",
			"Firewall restores you from an older backup. Something is missing, always.",
		])
		await dialogue_box.dialogue_finished
		SceneFlow.ego_death_fork()
		return
	dialogue_box.show_lines([
		"Your morph fails. Emergency resleeving fires.",
		"You wake in the docking bay pod, three decks from where you died.",
		"Listen. It's still moving down there.",
	])
	await dialogue_box.dialogue_finished
	player.global_position = POD_SPAWN
	player.restore_health()
	hunter.relocate_far_from(player.global_position)

func _on_all_complete() -> void:
	await dialogue_box.dialogue_finished
	var op_id := GameState.current_op_id
	# Burned the payload? The payload WAS the payday. Firewall docks the bounty.
	var reward := 60 if GameState.get_flag(&"halcyon_burned") else -1
	GameState.complete_op(op_id, reward)
	dialogue_box.show_lines(OpCatalog.get_op(op_id).debrief)
	await dialogue_box.dialogue_finished
	SceneFlow.go_to_hub()
