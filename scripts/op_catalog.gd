extends Node
## Registry of all ops, mirroring how MorphManager registers morphs. The hub's
## op board reads this; SceneFlow.deploy_op resolves an op_id to its Op here.

var _ops: Dictionary = {}  # StringName -> Op

func _ready() -> void:
	_register_ops()

func _register_ops() -> void:
	var ke7 := Op.new()
	ke7.id = &"ke7"
	ke7.title = "Echo — KE-7 habitat (onboarding)"
	ke7.scene_path = "res://scenes/main.tscn"
	var objs: Array[StringName] = [&"retrieve_stack", &"scan_stack", &"vent_signal"]
	ke7.objectives = objs
	var briefing: Array[String] = [
		"FIREWALL BRIEFING: Suspect async contamination detected.",
		"The cortical stack was hidden in a Server Alcove crawlspace —",
		"only an Octomorph can reach it. Retrieve and scan it.",
		"Neutralise any threat before it reaches the mesh.",
	]
	ke7.briefing = briefing
	var debrief: Array[String] = [
		"All objectives fulfilled. The async threat is contained.",
		"Firewall will scrub the station records. You were never here.",
		"Your ego backup updates. Egocasting back to the safehouse...",
	]
	ke7.debrief = debrief
	_add(ke7)

	var hauler := Op.new()
	hauler.id = &"hauler"
	hauler.title = "Drift — derelict hauler (recover stranded ego)"
	hauler.scene_path = "res://scenes/op_hauler.tscn"
	var h_objs: Array[StringName] = [&"recover_ego", &"extract"]
	hauler.objectives = h_objs
	var h_briefing: Array[String] = [
		"FIREWALL BRIEFING: A powerless hauler drifts off the lane, hull breached.",
		"A crew ego — Petrov — is stranded on a cortical stack in the aft hold,",
		"exposed to vacuum. Recover the stack (a sealed morph survives the breach),",
		"then reach the egocast point on the bridge to extract. Watch for async.",
	]
	hauler.briefing = h_briefing
	var h_debrief: Array[String] = [
		"Petrov's ego is secured. Firewall logs the hauler as lost with all hands.",
		"One stranded self, carried home. The async aboard is somebody else's problem now.",
		"Egocasting back to the safehouse...",
	]
	hauler.debrief = h_debrief
	_add(hauler)

func _add(op: Op) -> void:
	_ops[op.id] = op

func get_op(op_id: StringName) -> Op:
	return _ops.get(op_id)

func all_ops() -> Array:
	return _ops.values()
