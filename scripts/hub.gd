extends Node2D
## The Firewall safehouse. Persistent space between ops; its stations expose the
## meta layer (op board, resleeving, quartermaster, psychosurgery, handler,
## debrief). Reuses the field interactable + dialogue systems. Cross-op state
## lives in GameState; transitions go through SceneFlow.

@onready var player: CharacterBody2D = $Player
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var moxie_bar: ProgressBar = $UI/MoxieBar
@onready var op_board: Area2D = $OpBoard
@onready var resleeving_bay: Area2D = $ResleevingBay
@onready var quartermaster: Area2D = $Quartermaster
@onready var psychosurgery: Area2D = $Psychosurgery
@onready var handler: Area2D = $Handler
@onready var debrief_terminal: Area2D = $DebriefTerminal

var _resleeve_ids: Array[StringName] = []
var _board_ops: Array = []
var _shop_ids: Array[StringName] = []

func _ready() -> void:
	# Mirror persistent ego moxie onto the live Player and back (same contract
	# as the op scenes), so the ego carries through the hub.
	player.current_moxie = GameState.moxie
	player.moxie_changed.emit(player.current_moxie, player.max_moxie)
	player.moxie_changed.connect(func(c: int, _m: int) -> void: GameState.moxie = c)
	moxie_bar.setup(player)
	op_board.interact_requested.connect(_on_op_board)
	resleeving_bay.interact_requested.connect(_on_resleeving_bay)
	quartermaster.interact_requested.connect(_on_quartermaster)
	psychosurgery.interact_requested.connect(_on_psychosurgery)
	handler.interact_requested.connect(_on_handler)
	debrief_terminal.interact_requested.connect(_on_debrief)

# -- Op board: pick the next op -> deploy --

func _on_op_board() -> void:
	# Contracts surface progressively: an op stays off the board until its
	# unlock_after prerequisite is resolved.
	_board_ops = []
	var choices: Array = []
	for op: Op in OpCatalog.all_ops():
		if op.unlock_after != &"" and not GameState.is_op_complete(op.unlock_after):
			continue
		_board_ops.append(op)
		var done: String = "  [resolved]" if GameState.is_op_complete(op.id) else ""
		choices.append(op.title + done)
	choices.append("Stand down")
	dialogue_box.show_lines_with_choices(["Firewall op board. Active contracts:"], choices)
	dialogue_box.choice_made.connect(_on_op_chosen, CONNECT_ONE_SHOT)

func _on_op_chosen(index: int) -> void:
	if index >= _board_ops.size():
		return  # "Stand down"
	SceneFlow.deploy_op(_board_ops[index].id)

# -- Resleeving bay: set loadout (free in the safehouse) --

func _on_resleeving_bay() -> void:
	var choices: Array = []
	_resleeve_ids = []
	for id: StringName in GameState.unlocked_morphs:
		var data := MorphManager.get_morph(id)
		var worn: String = "  [worn]" if id == MorphManager.current_morph_id else ""
		choices.append("%s  |  SPD %d  HP %d%s" % [data.display_name, int(data.speed), data.max_health, worn])
		_resleeve_ids.append(id)
	choices.append("Cancel")
	dialogue_box.show_lines_with_choices(
		["Resleeving bay. Set your loadout — no stress cost in the safehouse."],
		choices,
	)
	dialogue_box.choice_made.connect(_on_resleeve_chosen, CONNECT_ONE_SHOT)

func _on_resleeve_chosen(index: int) -> void:
	if index < _resleeve_ids.size():
		MorphManager.switch_morph(_resleeve_ids[index])

# -- Quartermaster / fabber: buy field gear with op credits --

func _on_quartermaster() -> void:
	_shop_ids = []
	var choices: Array = []
	for id: StringName in GearCatalog.all_ids():
		var g := GearCatalog.get_gear(id)
		choices.append("%s — %d cr  (%s)" % [g["name"], g["cost"], g["desc"]])
		_shop_ids.append(id)
	choices.append("Leave")
	dialogue_box.show_lines_with_choices(
		[
			"The fabber's reservoirs are charged. \"What do you need, sentinel?\"",
			"Credits: %d    ·    Loadout: %d/%d slots" % [
				GameState.credits, GameState.gear.size(), GameState.MAX_GEAR_SLOTS],
		],
		choices,
	)
	dialogue_box.choice_made.connect(_on_quartermaster_choice, CONNECT_ONE_SHOT)

func _on_quartermaster_choice(index: int) -> void:
	if index >= _shop_ids.size():
		return  # "Leave"
	var id := _shop_ids[index]
	if GameState.gear.size() >= GameState.MAX_GEAR_SLOTS:
		dialogue_box.show_lines(["\"Your loadout's full, sentinel. Spend something in the field first.\""])
		return
	if GameState.credits < GearCatalog.cost(id):
		dialogue_box.show_lines(["\"Not enough scrip for that. Run another op and come back.\""])
		return
	GameState.buy_gear(id, GearCatalog.cost(id))
	dialogue_box.show_lines([
		"The fabber spins up. Fabricated: %s." % GearCatalog.display_name(id),
		"Credits remaining: %d." % GameState.credits,
	])

# -- Psychosurgery: restore Moxie, clear sticky trauma. Not free: ego repair
# -- is skilled work, and the bill is how the cull choice keeps its weight. --

const PSYCHOSURGERY_COST := 25

func _on_psychosurgery() -> void:
	var has_trauma := not GameState.traumas.is_empty()
	var weighted_max := GameState.MAX_MOXIE - 10 * GameState.traumas.size()
	var needs_moxie := GameState.moxie < weighted_max
	if not has_trauma and not needs_moxie:
		dialogue_box.show_lines(["The psychosurgery suite scans your ego. \"You're stable. Nothing to mend.\""])
		return
	# Pay what you can — Firewall doesn't leave sentinels broken, just indebted.
	var cost := mini(PSYCHOSURGERY_COST, GameState.credits)
	GameState.credits -= cost
	GameState.credits_changed.emit(GameState.credits)
	var cleared := ""
	if has_trauma:
		var t: StringName = GameState.traumas[0]
		GameState.clear_trauma(t)
		cleared = "\nThe suite excises a lingering trauma (%s)." % String(t)
	player.restore_moxie(GameState.MAX_MOXIE)  # mirrors into GameState via signal
	dialogue_box.show_lines([
		"You sink into the cradle. The suite spins up a slow-time simulspace",
		"and unpicks the knot, one thread at a time. You don't ask how long.",
		"Your Moxie is restored." + cleared,
		"Billed: %d cr." % cost if cost > 0 else "Billed to your marker. Firewall remembers.",
	])

# -- Handler & contacts --

var _handler_actions: Array[StringName] = []

func _on_handler() -> void:
	_handler_actions = []
	var choices: Array = []
	# After Halcyon, the campaign can close: the final report is waiting.
	if GameState.is_op_complete(&"halcyon"):
		_handler_actions.append(&"epilogue")
		choices.append("\"It's done.\"" if not GameState.get_flag(&"epilogue_seen")
				else "\"Read me the final report again.\"")
	_handler_actions.append(&"situation")
	choices.append("\"What's the situation?\"")
	_handler_actions.append(&"contracts")
	choices.append("\"Any new contracts?\"")
	_handler_actions.append(&"checking_in")
	choices.append("\"Just checking in.\"")
	dialogue_box.show_lines_with_choices(
		[
			"Your proxy's icon resolves on the comm.",
			"\"Welcome back to the safehouse, sentinel. Still breathing — good.\"",
		],
		choices,
	)
	dialogue_box.choice_made.connect(_on_handler_choice, CONNECT_ONE_SHOT)

func _on_handler_choice(index: int) -> void:
	if index >= _handler_actions.size():
		return
	match _handler_actions[index]:
		&"epilogue":
			dialogue_box.show_lines([
				"A long pause on the comm. When your proxy speaks again, the",
				"handler-voice is gone; what's left sounds almost like a person.",
				"\"Yeah. I'm closing your sentinel record — go be someone",
				"for a while. I'll send the final report.\"",
			])
			await dialogue_box.dialogue_finished
			SceneFlow.go_to_ending()
		&"situation":
			var lines: Array = [
				"\"The mesh is thick with exsurgent chatter. We contain what we can.\"",
				"\"You're deniable. Off the books. That's the job.\"",
			]
			# The handler remembers what you did at Aphelion.
			if GameState.get_flag(&"researcher_saved"):
				lines.append("\"Okafor's ego is stabilizing in our care. You did right by her.\"")
			elif GameState.get_flag(&"researcher_culled"):
				lines.append("\"We logged Okafor as unrecoverable. Nobody's questioning it.\"")
				lines.append("\"Nobody but you, I'd guess.\"")
			dialogue_box.show_lines(lines)
		&"contracts":
			dialogue_box.show_lines(["\"Check the op board. I post what clears legal — and what doesn't.\""])
		&"checking_in":
			dialogue_box.show_lines(["\"Rest while you can. The next one's always coming.\""])

# -- Debrief terminal: recap persistent state --

func _on_debrief() -> void:
	var names: Array[String] = []
	for t: StringName in GameState.traumas:
		names.append(String(t))
	var traumas := "none" if names.is_empty() else ", ".join(names)
	dialogue_box.show_lines([
		"— Debrief terminal —",
		"Firewall standing (i-rep): %d" % GameState.firewall_rep,
		"Credits: %d" % GameState.credits,
		"Ops resolved: %d" % GameState.completed_ops.size(),
		"Continuity breaks: %d" % GameState.continuity_breaks,
		"Active trauma: %s" % traumas,
	])
