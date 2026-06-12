extends SceneTree
## Headless functional verification — runs the live-verification checklist
## from HANDOFF.md inside the real engine, no window needed:
##   godot --headless --path . -s res://tests/headless_check.gd
## Exit code 0 = all passed. Exercises autoloads, scene instantiation, the
## gear economy, the op_flags save/load fix, unlock gating, the full lab op
## (archive hazard, Okafor fork, extract chain), replay, and the ego fork.
## NOTE: overwrites user://habitat_echo.save (dev save).

var _passed := 0
var _failed := 0

# Autoload identifiers don't resolve at compile time in a -s script; fetch them.
var GS: Node
var SF: Node
var OC: Node
var GC: Node
var MM: Node
var MORPH: Node

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame  # let autoloads settle

	GS = root.get_node_or_null("GameState")
	SF = root.get_node_or_null("SceneFlow")
	OC = root.get_node_or_null("OpCatalog")
	GC = root.get_node_or_null("GearCatalog")
	MM = root.get_node_or_null("MissionManager")
	MORPH = root.get_node_or_null("MorphManager")
	_check(GS != null, "autoload GameState present")
	_check(SF != null, "autoload SceneFlow present")
	_check(OC != null, "autoload OpCatalog present")
	_check(GC != null, "autoload GearCatalog present")
	if GS == null or SF == null or OC == null or GC == null:
		print("RESULT: aborting, autoloads missing")
		quit(1)
		return

	await _test_scene_instantiation()
	_test_economy_and_gear()
	_test_save_load_op_flags()
	await _test_unlock_gating()
	await _test_lab_flow()
	await _test_halcyon_flow()
	await _test_halcyon_branches()
	_test_fork_and_difficulty()

	print("")
	print("RESULT: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("PASS  " + label)
	else:
		_failed += 1
		print("FAIL  " + label)

## Emit dialogue_finished to resume any coroutine awaiting it, then unpause.
func _pump_dialogue(scene: Node, times: int = 1) -> void:
	var db: Node = scene.get_node("DialogueBox")
	for i in times:
		db.dialogue_finished.emit()
	paused = false

# ---------------------------------------------------------------------------

func _test_scene_instantiation() -> void:
	for path: String in [
		"res://scenes/title.tscn", "res://scenes/hub.tscn", "res://scenes/main.tscn",
		"res://scenes/op_hauler.tscn", "res://scenes/op_lab.tscn",
		"res://scenes/op_halcyon.tscn",
	]:
		GS.reset_new_game()
		var ps: PackedScene = load(path)
		if ps == null:
			_check(false, "load " + path)
			continue
		var inst := ps.instantiate()
		root.add_child(inst)
		await process_frame  # let _ready chains run
		_check(is_instance_valid(inst), "instantiate + ready " + path)
		paused = false
		inst.free()
		await process_frame

func _test_economy_and_gear() -> void:
	GS.reset_new_game()
	GS.complete_op(&"hauler")
	_check(GS.credits == 55, "first completion awards 55 cr (got %d)" % GS.credits)
	GS.complete_op(&"hauler")
	_check(GS.credits == 70, "replay completion pays flat salvage 15 (got %d)" % GS.credits)
	_check(GS.buy_gear(&"medichine", GC.cost(&"medichine")), "buy medichine")
	_check(GS.credits == 50 and GS.gear.size() == 1, "credits 50, 1 item carried")
	_check(GS.consume_gear(&"medichine"), "consume medichine")
	_check(GS.gear.is_empty(), "loadout empty after consume")
	_check(not GS.consume_gear(&"medichine"), "consuming what you lack fails")
	GS.credits = 1000
	for i in GS.MAX_GEAR_SLOTS:
		GS.buy_gear(&"emp_charge", 25)
	_check(not GS.buy_gear(&"emp_charge", 25), "5th item rejected (slots full)")
	GS.gear.clear()
	GS.credits = 5
	_check(not GS.buy_gear(&"panic_farcaster", 40), "too poor to buy")

func _test_save_load_op_flags() -> void:
	GS.reset_new_game()
	GS.set_flag(&"has_override")
	GS.set_moxie(77)
	GS.add_trauma(&"executioners_echo")
	GS.complete_op(&"ke7")
	GS.save()
	GS.reset_new_game()
	_check(GS.get_flag(&"has_override") == false, "state cleared before load")
	_check(GS.load_game(), "load_game succeeds")
	_check(GS.get_flag(&"has_override") == true, "op_flags survive JSON round-trip (the fix)")
	_check(GS.moxie == 77, "moxie survives save/load")
	_check(GS.traumas.has(&"executioners_echo"), "trauma survives save/load")
	_check(GS.is_op_complete(&"ke7"), "completed ops survive save/load")

func _test_unlock_gating() -> void:
	GS.reset_new_game()
	var hub := (load("res://scenes/hub.tscn") as PackedScene).instantiate()
	root.add_child(hub)
	await process_frame
	hub._on_op_board()
	_check(hub._board_ops.size() == 1, "fresh game: board shows only KE-7 (got %d)" % hub._board_ops.size())
	hub.get_node("DialogueBox").choice_made.emit(hub._board_ops.size())  # "Stand down"
	paused = false
	GS.completed_ops.append(&"ke7")
	hub._on_op_board()
	_check(hub._board_ops.size() == 2, "after KE-7: hauler appears (got %d)" % hub._board_ops.size())
	hub.get_node("DialogueBox").choice_made.emit(hub._board_ops.size())
	paused = false
	GS.completed_ops.append(&"hauler")
	hub._on_op_board()
	_check(hub._board_ops.size() == 3, "after hauler: lab appears (got %d)" % hub._board_ops.size())
	hub.get_node("DialogueBox").choice_made.emit(hub._board_ops.size())
	paused = false
	GS.completed_ops.append(&"lab")
	hub._on_op_board()
	_check(hub._board_ops.size() == 4, "after lab: Halcyon appears (got %d)" % hub._board_ops.size())
	hub.get_node("DialogueBox").choice_made.emit(hub._board_ops.size())
	paused = false
	hub.free()
	await process_frame

func _test_lab_flow() -> void:
	GS.reset_new_game()
	GS.difficulty = GS.Difficulty.STANDARD
	var lab := (load("res://scenes/op_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	await process_frame
	_check(GS.current_op_id == &"lab", "lab bootstrap arms the op")
	var db: Node = lab.get_node("DialogueBox")
	var player: Node = lab.get_node("Player")

	# Archive gating: octomorph refused.
	MORPH.switch_morph(&"octomorph")
	lab._on_archive()
	paused = false
	_check(not MM.is_complete(&"recover_protocol"), "octomorph cannot use the archive")

	# Personnel sting: -10 Moxie at STANDARD.
	MORPH.switch_morph(&"biomorph")
	await process_frame
	var moxie_before: int = player.current_moxie
	lab._on_archive()
	db.choice_made.emit(1)  # personnel records
	paused = false
	_check(player.current_moxie == moxie_before - 10, "personnel costs 10 moxie (got %d->%d)" % [moxie_before, player.current_moxie])

	# Primary basilisk: -30 Moxie, swarms wake on STANDARD.
	moxie_before = player.current_moxie
	lab._on_archive()
	db.choice_made.emit(0)  # primary archive (coroutine suspends awaiting dialogue)
	_pump_dialogue(lab, 2)  # hazard text, then the drones line -> spawn
	await process_frame
	_check(player.current_moxie == moxie_before - 30, "primary sears 30 moxie")
	var swarms := root.get_tree().get_nodes_in_group("nanite_swarm")
	_check(swarms.size() == 1, "STANDARD wakes 1 swarm (got %d)" % swarms.size())
	for s in swarms:
		s.free()

	# Maintenance partition: the protocol.
	lab._on_archive()
	db.choice_made.emit(2)
	paused = false
	_check(MM.is_complete(&"recover_protocol"), "maintenance partition yields the protocol")

	# Okafor: rehab requires the protocol (have it) -> rep +1, flag, backlash.
	var rep_before: int = GS.firewall_rep
	moxie_before = player.current_moxie
	lab._on_researcher()
	db.choice_made.emit(0)  # rehabilitate (suspends at post-resolution await)
	_pump_dialogue(lab, 2)
	await process_frame
	_check(MM.is_complete(&"resolve_researcher"), "rehabilitation resolves Okafor")
	_check(GS.firewall_rep == rep_before + 1, "rehab grants +1 rep")
	_check(GS.get_flag(&"researcher_saved") == true, "researcher_saved flag set")
	_check(player.current_moxie == moxie_before - 25, "rehab backlash costs 25 moxie")
	for s in root.get_tree().get_nodes_in_group("nanite_swarm"):
		s.free()

	# Extract: dialogue opens BEFORE completion (the hang fix), chain ends in
	# complete_op + debrief.
	lab._on_extract_point()
	_check(MM.is_complete(&"extract"), "extract completes at the relay")
	_check(db.get_node("Panel").visible, "extract leaves a dialogue open (hang fix)")
	_pump_dialogue(lab, 2)  # extract beat -> debrief -> go_to_hub (deferred)
	_check(GS.is_op_complete(&"lab"), "lab marked complete")
	_check(GS.credits == 70, "lab awards 70 cr (got %d)" % GS.credits)
	lab.free()
	await process_frame
	# go_to_hub's deferred change_scene fires now and instantiates the hub as
	# current_scene — free it, or its Player pollutes the "player" group and
	# the whispers assertions below read the wrong body.
	await process_frame
	if current_scene != null:
		current_scene.free()
		await process_frame

	# Replay: persistent researcher flags must not deadlock the op.
	SF.begin_op(&"lab")
	var lab2 := (load("res://scenes/op_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab2)
	await process_frame
	_check(not MM.is_complete(&"resolve_researcher"), "replay re-arms objectives")
	lab2._on_researcher()
	paused = false
	_check(MM.is_complete(&"resolve_researcher"), "replay auto-resolves the empty rack (deadlock fix)")

	# Whispers pools on the lab's own instance.
	var wh: Node = lab2.get_node("Whispers")
	var p2: Node = lab2.get_node("Player")
	GS.traumas.clear()
	p2.current_moxie = 80
	_check(wh._build_pool().is_empty(), "stable + clean = silence")
	GS.add_trauma(&"executioners_echo")
	p2.current_moxie = 50
	var pool: Array = wh._build_pool()
	_check(pool.size() == 3 and String(pool[0]).contains("Finally"), "shaken + trauma = trauma voice only")
	p2.current_moxie = 20
	_check(wh._build_pool().size() == 13, "deranged = full chorus + trauma lines")
	lab2.free()
	await process_frame

func _test_halcyon_flow() -> void:
	GS.reset_new_game()
	GS.difficulty = GS.Difficulty.STANDARD
	var op := (load("res://scenes/op_halcyon.tscn") as PackedScene).instantiate()
	root.add_child(op)
	await process_frame
	_check(GS.current_op_id == &"halcyon", "halcyon bootstrap arms the op")
	var db: Node = op.get_node("DialogueBox")
	var player: Node = op.get_node("Player")
	var hunter: Node = op.get_node("Hunter")
	hunter.global_position = Vector2(-3000, -3000)  # park it; tested separately

	# Relay refuses before containment.
	op._on_relay()
	paused = false
	_check(not MM.is_complete(&"egocast_out"), "relay refuses before contain")

	# Elevator is dead before power.
	var pos_before: Vector2 = player.global_position
	op._on_elevator()
	paused = false
	_check(player.global_position == pos_before, "elevator dead before power")

	# Generator needs cyberbrain, then power comes on and the blackout lifts.
	MORPH.switch_morph(&"octomorph")
	op._on_generator()
	paused = false
	_check(not MM.is_complete(&"restore_power"), "generator refuses non-cyberbrain")
	MORPH.switch_morph(&"biomorph")
	op._on_generator()
	_check(MM.is_complete(&"restore_power"), "generator restores power (biomorph)")
	_pump_dialogue(op, 1)
	for i in 8:
		await process_frame
	var blackout: ColorRect = op.get_node("Room/BlackoutA")
	_check(blackout.color.a < 0.55, "blackout lifting after power (a=%.2f)" % blackout.color.a)
	_check(hunter.state == hunter.State.HUNT, "the generator noise draws the hunter")

	# Elevator now works — and is loud.
	op._on_elevator()
	db.choice_made.emit(0)  # nearest is A; first option is B
	paused = false
	_check(player.global_position == Vector2(586, 780), "elevator rides to deck B")

	# Vault: cyberbrain, costs Moxie, yields the payload.
	var moxie_before: int = player.current_moxie
	op._on_vault()
	paused = false
	_check(MM.is_complete(&"extract_infohazard"), "vault yields the payload")
	_check(player.current_moxie == moxie_before - 15, "vault bleed costs 15 moxie")

	# Crawlway: octomorph only, silent travel to deck C.
	op._on_vent()
	paused = false
	_check(player.global_position == Vector2(586, 780), "vent refuses non-octomorph")
	MORPH.switch_morph(&"octomorph")
	op._on_vent()
	db.choice_made.emit(1)  # from B: options [A, C] -> C
	paused = false
	_check(player.global_position == Vector2(806, 1500), "crawlway climbs to deck C")

	# Cache in the vacuum section grants a medichine.
	op._on_hydro_cache()
	paused = false
	_check(GS.gear.has(&"medichine"), "hydro cache grants a medichine")

	# Core: counter-script WITHOUT Okafor saved = it works, but it costs you.
	var rep_before: int = GS.firewall_rep
	moxie_before = player.current_moxie
	op._on_core()
	db.choice_made.emit(1)
	_pump_dialogue(op, 2)
	await process_frame
	_check(MM.is_complete(&"contain"), "counter-script contains the source")
	_check(GS.firewall_rep == rep_before + 1, "unaided counter-script grants +1 rep")
	_check(GS.get_flag(&"network_exposed") == true, "unaided counter-script exposes the network")
	_check(player.current_moxie == moxie_before - 30, "unaided counter-script costs 30 moxie")
	_check(hunter._berserk, "containment sends the hunter berserk")
	_check(root.get_tree().get_nodes_in_group("nanite_swarm").size() == 1, "finale spawns pressure on STANDARD")
	for s in root.get_tree().get_nodes_in_group("nanite_swarm"):
		s.free()

	# Relay extracts; the op completes and pays out.
	op._on_relay()
	_check(db.get_node("Panel").visible, "relay extract leaves a dialogue open (hang fix)")
	_pump_dialogue(op, 2)
	_check(GS.is_op_complete(&"halcyon"), "halcyon marked complete")
	_check(GS.credits == 100, "halcyon awards 100 cr (got %d)" % GS.credits)
	op.free()
	await process_frame
	if current_scene != null:  # go_to_hub's deferred hub spawn
		current_scene.free()
		await process_frame

func _test_halcyon_branches() -> void:
	# Vent branch: decisive, rep up, and the manifest haunts you.
	var op := await _fresh_halcyon_at_core()
	var rep: int = GS.firewall_rep
	op._contain_vent()
	_pump_dialogue(op, 2)
	_check(GS.get_flag(&"halcyon_vented") == true, "vent branch sets its flag")
	_check(GS.firewall_rep == rep + 1, "vent branch grants +1 rep")
	_check(GS.traumas.has(&"hundred_names"), "vent branch leaves the manifest trauma")
	op.free()
	await process_frame

	# Burn branch: nobody dies, Firewall is displeased.
	op = await _fresh_halcyon_at_core()
	rep = GS.firewall_rep
	op._contain_burn()
	_pump_dialogue(op, 2)
	_check(GS.get_flag(&"halcyon_burned") == true, "burn branch sets its flag")
	_check(GS.firewall_rep == rep - 1, "burn branch costs 1 rep")
	_check(GS.traumas.is_empty(), "burn branch leaves no trauma")
	op.free()
	await process_frame

	# Counter-script WITH Okafor saved: the cross-op payoff.
	op = await _fresh_halcyon_at_core()
	GS.set_flag(&"researcher_saved")
	rep = GS.firewall_rep
	var player: Node = op.get_node("Player")
	var moxie_before: int = player.current_moxie
	op._contain_counterscript()
	_pump_dialogue(op, 2)
	_check(GS.firewall_rep == rep + 2, "Okafor-assisted counter-script grants +2 rep")
	_check(player.current_moxie == moxie_before, "Okafor-assisted counter-script costs nothing")
	_check(not GS.get_flag(&"network_exposed"), "Okafor-assisted counter-script stays clean")

	# Hunter behavior unit checks on this instance.
	var hunter: Node = op.get_node("Hunter")
	hunter.stun(2.0)
	_check(hunter.state == hunter.State.STUNNED, "EMP stun freezes the hunter")
	hunter.alert_to(Vector2.ZERO)
	_check(hunter.state == hunter.State.STUNNED, "a stunned hunter ignores noise")
	hunter.relocate_far_from(player.global_position)
	_check(hunter.global_position.distance_to(player.global_position) > 600.0,
			"relocate_far_from puts it on a distant anchor")
	op.free()
	await process_frame

	# Difficulty tunes the hunter at spawn.
	GS.reset_new_game()
	GS.difficulty = GS.Difficulty.RELENTLESS
	var op2 := (load("res://scenes/op_halcyon.tscn") as PackedScene).instantiate()
	root.add_child(op2)
	await process_frame
	_check(op2.get_node("Hunter")._speed == 130.0, "RELENTLESS hunter is faster")
	op2.free()
	await process_frame
	GS.difficulty = GS.Difficulty.STANDARD

## A halcyon instance with prereqs met, hunter parked, ready for a core branch.
func _fresh_halcyon_at_core() -> Node:
	GS.reset_new_game()
	GS.difficulty = GS.Difficulty.STORY  # no finale spawns during branch tests
	var op := (load("res://scenes/op_halcyon.tscn") as PackedScene).instantiate()
	root.add_child(op)
	await process_frame
	op.get_node("Hunter").global_position = Vector2(-3000, -3000)
	MM.complete_objective(&"restore_power")
	MM.complete_objective(&"extract_infohazard")
	paused = false
	return op

func _test_fork_and_difficulty() -> void:
	GS.reset_new_game()
	SF.begin_op(&"hauler")
	GS.set_moxie(40)
	GS.gear.append(&"medichine")
	GS.fork_from_checkpoint()
	_check(GS.continuity_breaks == 1, "fork counts a continuity break")
	_check(GS.traumas.has(&"fork_dissonance"), "fork leaves fork_dissonance")
	_check(GS.moxie == GS.MAX_MOXIE, "fork restores moxie")
	_check(GS.gear.has(&"medichine"), "fork keeps mechanical progress (gear)")

	GS.difficulty = GS.Difficulty.STORY
	_check(GS.swarm_count() == 1 and GS.hazard_moxie_mult() == 0.75, "STORY pacing")
	GS.difficulty = GS.Difficulty.RELENTLESS
	_check(GS.swarm_count() == 2 and GS.hazard_moxie_mult() == 1.5, "RELENTLESS pacing")
	GS.difficulty = GS.Difficulty.STANDARD
	_check(GS.swarm_count() == 1 and GS.hazard_moxie_mult() == 1.0, "STANDARD pacing")
