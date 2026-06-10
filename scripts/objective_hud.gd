extends CanvasLayer
## Always-visible objective checklist for the current op. Self-contained: drop
## into any op scene; reads the Op from the catalog via GameState.current_op_id
## and refreshes on MissionManager.objective_completed.

@onready var label: Label = $ObjectivesLabel

func _ready() -> void:
	MissionManager.objective_completed.connect(func(_id: StringName) -> void: _refresh())
	_refresh()

func _refresh() -> void:
	var op: Op = OpCatalog.get_op(GameState.current_op_id)
	if op == null:
		label.text = ""
		return
	var lines: Array[String] = []
	for i in op.objectives.size():
		var done := MissionManager.is_complete(op.objectives[i])
		var obj_name := op.objective_labels[i] if i < op.objective_labels.size() \
				else String(op.objectives[i])
		lines.append(("[x] " if done else "[  ] ") + obj_name)
	label.text = "\n".join(lines)
