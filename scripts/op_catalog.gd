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
	var obj_labels: Array[String] = [
		"Retrieve the cortical stack", "Scan the stack", "Vent the exsurgent signal",
	]
	ke7.objective_labels = obj_labels
	var briefing: Array[String] = [
		"FIREWALL BRIEFING: Suspect exsurgent contamination detected.",
		"The cortical stack was hidden in a Server Alcove crawlspace —",
		"only an octomorph can reach it. Retrieve and scan it.",
		"Neutralize any threat before it reaches the mesh.",
	]
	ke7.briefing = briefing
	var debrief: Array[String] = [
		"All objectives fulfilled. The exsurgent threat is contained.",
		"Firewall sanitizes the station logs. You were never here.",
		"Your ego backup updates. Egocasting back to the safehouse...",
	]
	ke7.debrief = debrief
	ke7.reward_credits = 40
	_add(ke7)

	var hauler := Op.new()
	hauler.id = &"hauler"
	hauler.title = "Drift — derelict hauler (recover stranded ego)"
	hauler.scene_path = "res://scenes/op_hauler.tscn"
	var h_objs: Array[StringName] = [&"recover_ego", &"extract"]
	hauler.objectives = h_objs
	var h_labels: Array[String] = [
		"Recover the stranded ego", "Reach the egocast point",
	]
	hauler.objective_labels = h_labels
	var h_briefing: Array[String] = [
		"FIREWALL BRIEFING: A powerless hauler drifts off the lane, hull breached.",
		"A crew ego — Petrov — is stranded on a cortical stack in the aft hold,",
		"exposed to vacuum. Recover the stack (a sealed morph survives the breach),",
		"then reach the egocast point on the bridge to extract.",
		"Watch for exsurgent activity.",
	]
	hauler.briefing = h_briefing
	var h_debrief: Array[String] = [
		"Petrov's ego is secured. Firewall logs the hauler as lost with all hands.",
		"Whatever nests aboard is somebody else's problem now.",
		"The relay takes you home. Petrov rides in your buffer, lighter than a thought.",
	]
	hauler.debrief = h_debrief
	hauler.reward_credits = 55
	hauler.unlock_after = &"ke7"
	_add(hauler)

	var lab := Op.new()
	lab.id = &"lab"
	lab.title = "Threshold — Aphelion research lab (info-hazard)"
	lab.scene_path = "res://scenes/op_lab.tscn"
	var l_objs: Array[StringName] = [&"recover_protocol", &"resolve_researcher", &"extract"]
	lab.objectives = l_objs
	var l_labels: Array[String] = [
		"Recover the containment protocol", "Resolve Dr. Okafor", "Egocast out",
	]
	lab.objective_labels = l_labels
	var l_briefing: Array[String] = [
		"FIREWALL BRIEFING: The Aphelion exobiology lab went dark 47 days ago.",
		"Dr. Okafor was developing an async containment protocol when the lab's",
		"own archive turned info-hazardous. Recover the protocol — WITHOUT",
		"reading anything else — and resolve whatever is left of Okafor.",
		"How you resolve her is, regrettably, at your discretion.",
	]
	lab.briefing = l_briefing
	var l_debrief: Array[String] = [
		"The Aphelion files are in Firewall's hands. The lab goes back to being",
		"a dark spot on the charts — one more thing nobody talks about.",
		"You cast out carrying the protocol, and try to carry nothing else.",
	]
	lab.debrief = l_debrief
	lab.reward_credits = 70
	lab.unlock_after = &"hauler"
	_add(lab)

	var halcyon := Op.new()
	halcyon.id = &"halcyon"
	halcyon.title = "Undertow — Halcyon Station (something hunts the decks)"
	halcyon.scene_path = "res://scenes/op_halcyon.tscn"
	var hc_objs: Array[StringName] = [
		&"restore_power", &"extract_infohazard", &"contain", &"egocast_out",
	]
	halcyon.objectives = hc_objs
	var hc_labels: Array[String] = [
		"Restore station power", "Extract the vault payload",
		"Contain the source", "Egocast out",
	]
	halcyon.objective_labels = hc_labels
	var hc_briefing: Array[String] = [
		"FIREWALL BRIEFING: Halcyon Station went dark 61 days ago, mid-evacuation.",
		"Our sentinel aboard — SAVA — stopped reporting on day 9. The source is",
		"in the containment core on deck C; the research that matters is vaulted",
		"on deck B. Power is down. The spine crawlway still runs.",
		"One more thing, sentinel: the survivors' last transmissions described",
		"something moving between decks. It was counting. We don't know what.",
	]
	halcyon.briefing = hc_briefing
	var hc_debrief: Array[String] = [
		"Halcyon is contained — by your definition of the word, anyway.",
		"Firewall scrubs the records, reassigns the grief, and moves on.",
		"You still hear it sometimes, in elevators: something keeping count.",
	]
	halcyon.debrief = hc_debrief
	halcyon.reward_credits = 100
	halcyon.unlock_after = &"lab"
	_add(halcyon)

func _add(op: Op) -> void:
	_ops[op.id] = op

func get_op(op_id: StringName) -> Op:
	return _ops.get(op_id)

func all_ops() -> Array:
	return _ops.values()
