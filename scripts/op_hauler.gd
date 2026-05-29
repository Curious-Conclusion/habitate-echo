extends Node2D
## Op 1 — the derelict hauler. A powerless, partly-breached freighter; recover a
## stranded ego (a cortical stack) from a vacuum-exposed hold, then reach the
## egocast point to extract. Hand-built site (DESIGN_OUTLINE.md §5) reusing the
## field systems: resleeving, morphs, Moxie/derangement, dialogue, the swarm.

const NaniteSwarmScene := preload("res://scenes/nanite_swarm.tscn")

const OP_ID := &"hauler"
const POD_SPAWN := Vector2(120, 120)

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var resleeving_pod: Area2D = $ResleevingPod
@onready var morph_select_ui: PanelContainer = $UI/MorphSelectUI
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var hp_bar: ProgressBar = $UI/HpBar
@onready var moxie_bar: ProgressBar = $UI/MoxieBar
@onready var glitch_layer: CanvasLayer = $GlitchLayer
@onready var data_log: Area2D = $DataLog
@onready var cortical_stack: Area2D = $CorticalStack
@onready var extract_point: Area2D = $ExtractPoint

func _ready() -> void:
	# Bootstrap when launched directly (not deployed from the hub).
	if GameState.current_op_id != OP_ID:
		SceneFlow.begin_op(OP_ID)
	player.current_moxie = GameState.moxie
	player.moxie_changed.emit(player.current_moxie, player.max_moxie)
	player.moxie_changed.connect(func(c: int, _m: int) -> void: GameState.moxie = c)

	resleeving_pod.interact_requested.connect(morph_select_ui.open)
	data_log.interact_requested.connect(_on_data_log)
	cortical_stack.interact_requested.connect(_on_cortical_stack)
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

# -- Data log (Entry Bay, investigate) --

func _on_data_log() -> void:
	dialogue_box.show_lines([
		"A cracked data slate flickers to life — the hauler's last log.",
		"\"Hull breach, aft hold. We sealed the bulkheads and ran.\"",
		"\"Couldn't reach Petrov in time. Their stack's still jacked into the",
		"hold's cradle, exposed to vacuum. If anyone finds this — get them out.\"",
		"A faint async whine threads under the static. Something's still aboard.",
	])

# -- Cortical stack (Breached Hold, requires VACUUM_SEAL) --

func _on_cortical_stack() -> void:
	if MissionManager.is_complete(&"recover_ego"):
		dialogue_box.show_lines(["The cradle is empty. You already pulled Petrov's stack."])
		return
	var morph := MorphManager.get_current_morph()
	if morph.ability != MorphManager.Ability.VACUUM_SEAL:
		dialogue_box.show_lines([
			"Petrov's cortical stack sits in a cradle, rimed with frost, open to vacuum.",
			"Bare flesh won't last out here — handling it needs a vacuum-sealed morph.",
			"Resleeve into the Synth at the entry pod.",
		])
		return
	MissionManager.complete_objective(&"recover_ego")
	dialogue_box.show_lines([
		"Your sealed chassis shrugs off the cold. You ease the stack from its cradle.",
		"Petrov's ego — intact. The async whine spikes as the cradle releases.",
		"Stranded ego recovered. Get to the egocast point on the bridge.",
	])
	await dialogue_box.dialogue_finished
	_spawn_swarm(cortical_stack.global_position + Vector2(0, -40))

# -- Extract point (Bridge, egocast out) --

func _on_extract_point() -> void:
	if not MissionManager.is_complete(&"recover_ego"):
		dialogue_box.show_lines([
			"The egocast relay still holds a trickle of charge — enough for one cast.",
			"But you can't leave Petrov's ego stranded. Recover it first.",
		])
		return
	MissionManager.complete_objective(&"extract")

# -- Resleeve stress --

func _on_resleeve_moxie(_morph_id: StringName) -> void:
	player.reduce_moxie(15)

# -- Threat --

func _spawn_swarm(at: Vector2) -> void:
	var swarm := NaniteSwarmScene.instantiate()
	swarm.global_position = at
	add_child(swarm)

# -- Death / respawn (lose-continuity fork on ego death) --

func _on_player_died() -> void:
	for swarm in get_tree().get_nodes_in_group("nanite_swarm"):
		swarm.queue_free()
	player.reduce_moxie(10)
	if player.current_moxie <= 0:
		dialogue_box.show_lines([
			"The hauler claims your morph — and the resleeve tears the thread loose.",
			"Firewall restores you from an older backup. Something is missing, always.",
		])
		await dialogue_box.dialogue_finished
		SceneFlow.ego_death_fork()
		return
	dialogue_box.show_lines([
		"Your morph fails. Emergency resleeving fires.",
		"You wake at the entry pod, ego intact — barely.",
	])
	await dialogue_box.dialogue_finished
	player.global_position = POD_SPAWN
	player.restore_health()

# -- Op complete --

func _on_all_complete() -> void:
	await dialogue_box.dialogue_finished
	var op_id := GameState.current_op_id
	GameState.complete_op(op_id)
	dialogue_box.show_lines(OpCatalog.get_op(op_id).debrief)
	await dialogue_box.dialogue_finished
	SceneFlow.go_to_hub()
