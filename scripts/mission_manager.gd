extends Node
## Tracks objective state for the op currently in progress. Initialized from an
## Op's objective list via start_op() (called on deploy), so ops reset cleanly
## and are replayable — no hard-coded objective set.

signal objective_completed(objective_id: StringName)
signal all_objectives_completed

var current_op_id: StringName = &""
var _objectives: Dictionary = {}  # StringName -> bool

## Arm objectives for an op. Clears any prior state.
func start_op(op: Op) -> void:
	current_op_id = op.id
	_objectives.clear()
	for obj_id: StringName in op.objectives:
		_objectives[obj_id] = false

func complete_objective(id: StringName) -> void:
	if _objectives.has(id) and not _objectives[id]:
		_objectives[id] = true
		objective_completed.emit(id)
		if _all_done():
			all_objectives_completed.emit()

func is_complete(id: StringName) -> bool:
	return _objectives.get(id, false)

func _all_done() -> bool:
	if _objectives.is_empty():
		return false
	for v: bool in _objectives.values():
		if not v:
			return false
	return true
