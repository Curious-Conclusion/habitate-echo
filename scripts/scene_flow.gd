extends Node
## Scene-flow: hub <-> op <-> debrief transitions, wired to GameState's save
## model (hub + op-start checkpoint) and the ego-death fork (DESIGN_OUTLINE.md §9).
##
## Owns the *mechanism* of transitions and checkpointing. The op_id -> scene
## mapping lives in the Op layer (OpCatalog), resolved by begin_op().

const HUB_SCENE := "res://scenes/hub.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"

var _current_op_scene: String = ""   ## for restart / ego-death reload

## Enter the safehouse between ops. Hub entry is a save point.
func go_to_hub() -> void:
	GameState.current_op_id = &""
	_current_op_scene = ""
	GameState.snapshot_checkpoint()
	GameState.save()
	_change_scene(HUB_SCENE)

## The campaign epilogue — the handler sends you home after Halcyon.
func go_to_ending() -> void:
	GameState.current_op_id = &""
	_current_op_scene = ""
	_change_scene(ENDING_SCENE)

## Commit loadout and egocast into an op. Op-start is the checkpoint + backup
## the ego-death fork restores from.
func deploy_op(op_id: StringName) -> void:
	if not begin_op(op_id):
		return
	GameState.save()
	_change_scene(_current_op_scene)

## Arm an op's state (objectives, current id, checkpoint) without changing scene.
## Used by deploy_op and by an op scene launched directly as the bootstrap.
## Returns false if the op is unknown.
func begin_op(op_id: StringName) -> bool:
	var op: Op = OpCatalog.get_op(op_id)
	if op == null:
		push_error("SceneFlow.begin_op: unknown op %s" % op_id)
		return false
	GameState.current_op_id = op_id
	_current_op_scene = op.scene_path
	MissionManager.start_op(op)
	GameState.snapshot_checkpoint()
	return true

## Ego death: fork from the op-start backup (keeps mechanical progress, costs a
## continuity break + sticky trauma) and restart the op from deploy.
func ego_death_fork() -> void:
	GameState.fork_from_checkpoint()
	var op_id := GameState.current_op_id
	if op_id != &"" and begin_op(op_id):  # re-arm objectives for the retry
		_change_scene(_current_op_scene)
	else:
		go_to_hub()

func restart_op() -> void:
	if _current_op_scene != "":
		_change_scene(_current_op_scene)

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)
