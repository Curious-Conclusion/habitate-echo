extends Node

signal objective_completed(objective_id: StringName)
signal all_objectives_completed

var _objectives: Dictionary = {
	&"retrieve_stack": false,
	&"scan_stack": false,
	&"vent_signal": false,
}

func complete_objective(id: StringName) -> void:
	if _objectives.has(id) and not _objectives[id]:
		_objectives[id] = true
		objective_completed.emit(id)
		if _all_done():
			all_objectives_completed.emit()

func is_complete(id: StringName) -> bool:
	return _objectives.get(id, false)

func _all_done() -> bool:
	for v: bool in _objectives.values():
		if not v:
			return false
	return true
