extends Node
## Persistent meta-state across scenes (hub <-> op <-> debrief).
##
## Single source of truth for everything that survives a scene change. During an
## op the Player owns live moxie/health (for bars, burn, derangement); it syncs
## to/from here at scene boundaries so the ego persists between ops.
##
## Save model: hub + op-start checkpoint. snapshot_checkpoint() is called on
## deploy and on hub entry; that snapshot doubles as the ego-death "backup".
## Ego death = fork_from_checkpoint(): keep mechanical progress, lose narrative
## continuity + accrue a sticky trauma (see DESIGN_OUTLINE.md §9).

signal moxie_changed(current: int, maximum: int)
signal trauma_changed(traumas: Array)
signal continuity_broken(count: int)

const SAVE_PATH := "user://habitat_echo.save"
const MAX_MOXIE := 100

## Threat pacing scales with difficulty (DESIGN_OUTLINE.md §9):
## STORY = static threats, STANDARD = escalating, RELENTLESS = escalating + timer.
enum Difficulty { STORY, STANDARD, RELENTLESS }

# --- Persistent ego state (survives ops; mirrored onto Player during an op) ---
var moxie: int = MAX_MOXIE
var traumas: Array[StringName] = []        ## sticky derangements; psychosurgery clears
var continuity_breaks: int = 0             ## ego-death forks accrued

# --- Progression ---
var firewall_rep: int = 0
var unlocked_morphs: Array[StringName] = [&"octomorph", &"synth", &"biomorph"]
var gear: Array[StringName] = []           ## loadout slots (Phase 4)
var intel: Array[StringName] = []          ## unlocked site maps / threat data

# --- Op progress ---
var completed_ops: Array[StringName] = []
var current_op_id: StringName = &""
var op_flags: Dictionary = {}              ## per-op narrative flags (e.g. has_override)

# --- Settings ---
var difficulty: Difficulty = Difficulty.STANDARD

# --- Checkpoint snapshot (op-start save + ego-death backup) ---
var _checkpoint: Dictionary = {}

# ---------------------------------------------------------------------------
# Ego / Moxie
# ---------------------------------------------------------------------------

func set_moxie(value: int) -> void:
	moxie = clampi(value, 0, MAX_MOXIE)
	moxie_changed.emit(moxie, MAX_MOXIE)

func add_trauma(trauma_id: StringName) -> void:
	if not traumas.has(trauma_id):
		traumas.append(trauma_id)
		trauma_changed.emit(traumas)

func clear_trauma(trauma_id: StringName) -> void:
	if traumas.has(trauma_id):
		traumas.erase(trauma_id)
		trauma_changed.emit(traumas)

# ---------------------------------------------------------------------------
# Op progress / flags
# ---------------------------------------------------------------------------

func complete_op(op_id: StringName) -> void:
	if not completed_ops.has(op_id):
		completed_ops.append(op_id)

func is_op_complete(op_id: StringName) -> bool:
	return completed_ops.has(op_id)

func set_flag(flag: StringName, value: Variant = true) -> void:
	op_flags[flag] = value

func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return op_flags.get(flag, default)

func unlock_morph(morph_id: StringName) -> void:
	if not unlocked_morphs.has(morph_id):
		unlocked_morphs.append(morph_id)

# ---------------------------------------------------------------------------
# Checkpoint + ego-death fork
# ---------------------------------------------------------------------------

## Capture the clean state at op-start / hub entry. Doubles as the fork backup.
func snapshot_checkpoint() -> void:
	_checkpoint = _serialize()

## Ego death: restore the op-start checkpoint (op restarts), but keep mechanical
## progress and pay the continuity cost — a permanent break + a sticky trauma.
func fork_from_checkpoint() -> void:
	if not _checkpoint.is_empty():
		var keep_morphs := unlocked_morphs.duplicate()
		var keep_gear := gear.duplicate()
		var keep_intel := intel.duplicate()
		_deserialize(_checkpoint)
		# Mechanical progress survives the fork even if it post-dates the checkpoint.
		unlocked_morphs = keep_morphs
		gear = keep_gear
		intel = keep_intel
	continuity_breaks += 1
	add_trauma(&"fork_dissonance")
	set_moxie(MAX_MOXIE)
	continuity_broken.emit(continuity_breaks)

# ---------------------------------------------------------------------------
# Save / load (JSON; StringNames stored as plain strings)
# ---------------------------------------------------------------------------

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("GameState.save: cannot open %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(_serialize(), "\t"))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("GameState.load_game: corrupt save")
		return false
	_deserialize(data)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func reset_new_game() -> void:
	moxie = MAX_MOXIE
	traumas.clear()
	continuity_breaks = 0
	firewall_rep = 0
	var starting_morphs: Array[StringName] = [&"octomorph", &"synth", &"biomorph"]
	unlocked_morphs = starting_morphs
	gear.clear()
	intel.clear()
	completed_ops.clear()
	current_op_id = &""
	op_flags.clear()
	_checkpoint.clear()

func _serialize() -> Dictionary:
	return {
		"moxie": moxie,
		"traumas": _names_to_strings(traumas),
		"continuity_breaks": continuity_breaks,
		"firewall_rep": firewall_rep,
		"unlocked_morphs": _names_to_strings(unlocked_morphs),
		"gear": _names_to_strings(gear),
		"intel": _names_to_strings(intel),
		"completed_ops": _names_to_strings(completed_ops),
		"current_op_id": String(current_op_id),
		"op_flags": op_flags.duplicate(true),
		"difficulty": int(difficulty),
	}

func _deserialize(d: Dictionary) -> void:
	moxie = int(d.get("moxie", MAX_MOXIE))
	traumas = _strings_to_names(d.get("traumas", []))
	continuity_breaks = int(d.get("continuity_breaks", 0))
	firewall_rep = int(d.get("firewall_rep", 0))
	unlocked_morphs = _strings_to_names(d.get("unlocked_morphs", ["octomorph", "synth", "biomorph"]))
	gear = _strings_to_names(d.get("gear", []))
	intel = _strings_to_names(d.get("intel", []))
	completed_ops = _strings_to_names(d.get("completed_ops", []))
	current_op_id = StringName(d.get("current_op_id", ""))
	op_flags = (d.get("op_flags", {}) as Dictionary).duplicate(true)
	difficulty = int(d.get("difficulty", Difficulty.STANDARD))

func _names_to_strings(arr: Array) -> Array:
	var out: Array = []
	for n in arr:
		out.append(String(n))
	return out

func _strings_to_names(arr: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for s in arr:
		out.append(StringName(s))
	return out
