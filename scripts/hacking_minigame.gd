extends CanvasLayer
## Cyberbrain intrusion minigame.
##
## The async's lockout is a connection route across a 3x3 node grid. The system
## reveals the route node-by-node; the player must retrace it in order using the
## number keys 1-9. A cyberbrain can burn Moxie ([F]) to auto-trace the next
## node. A wrong node trips the intrusion alarm (the async strikes back).

signal hack_succeeded
signal hack_failed

const COLS := 4
const ROWS := 4
const BASE_PATH_LEN := 4
const MAX_PATH_LEN := 7
const ASSIST_COST := 20
const REVEAL_ON := 0.45
const REVEAL_OFF := 0.18

const COL_IDLE := Color(0.12, 0.16, 0.22)
const COL_REVEAL := Color(0.2, 0.8, 0.95)
const COL_DONE := Color(0.25, 0.9, 0.45)
const COL_FAIL := Color(0.9, 0.2, 0.2)

var _player: Node = null
var _route: Array[int] = []
var _input_idx := 0
var _state := "idle"  ## idle | revealing | input | resolved
var _nodes: Array[ColorRect] = []
var _cursor := 0
var _fails := 0  ## each failed hack hardens the async (longer route next time)
var _status: Label
var _hint: Label

const CURSOR_TINT := Color(1.6, 1.6, 1.6)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_build_ui()
	visible = false

func setup(player: Node) -> void:
	_player = player

# ---------------------------------------------------------------------------
# UI (built procedurally so the scene stays a single node)
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "// CYBERBRAIN INTRUSION //"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	for i in COLS * ROWS:
		var cell := ColorRect.new()
		cell.color = COL_IDLE
		cell.custom_minimum_size = Vector2(64, 64)
		var lbl := Label.new()
		lbl.text = str(i + 1)
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(lbl)
		grid.add_child(cell)
		_nodes.append(cell)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint)

# ---------------------------------------------------------------------------
# Flow
# ---------------------------------------------------------------------------

func open() -> void:
	visible = true
	get_tree().paused = true
	var length := clampi(BASE_PATH_LEN + _fails, BASE_PATH_LEN, MAX_PATH_LEN)
	_route = _gen_route(length)
	_input_idx = 0
	_state = "revealing"
	_reset_nodes()
	if _fails > 0:
		_status.text = "Async hardened — tracing %d-node route..." % length
	else:
		_status.text = "Tracing lockout route... (%d nodes)" % length
	_hint.text = ""
	await _reveal()
	_state = "input"
	_cursor = 0
	_update_cursor(-1)
	_status.text = "Retrace the route  (%d nodes)" % length
	_hint.text = "[arrows] move   [E] select   [F] assist (-%d)" % ASSIST_COST

func _reveal() -> void:
	for idx in _route:
		_nodes[idx].color = COL_REVEAL
		await _wait(REVEAL_ON)
		_nodes[idx].color = COL_IDLE
		await _wait(REVEAL_OFF)

func _select(idx: int) -> void:
	if _state != "input":
		return
	if idx == _route[_input_idx]:
		_nodes[idx].color = COL_DONE
		_input_idx += 1
		if _input_idx >= _route.size():
			_succeed()
	else:
		_fail(idx)

func _assist() -> void:
	if _state != "input":
		return
	if _player == null or _player.current_moxie < ASSIST_COST:
		_status.text = "Not enough Moxie to assist."
		return
	_player.reduce_moxie(ASSIST_COST)
	_select(_route[_input_idx])

func _succeed() -> void:
	_state = "resolved"
	_status.text = "ACCESS GRANTED"
	await _wait(0.8)
	_close()
	hack_succeeded.emit()

func _fail(idx: int) -> void:
	_state = "resolved"
	_fails += 1  # async hardens — next attempt's route is longer
	if idx >= 0 and idx < _nodes.size():
		_nodes[idx].color = COL_FAIL
	_status.text = "INTRUSION DETECTED"
	await _wait(0.9)
	_close()
	hack_failed.emit()

func _close() -> void:
	visible = false
	get_tree().paused = false

# ---------------------------------------------------------------------------
# Input — only while the player phase is active
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _state != "input":
		return
	# Arrow-cursor navigation.
	if event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_move_cursor(-1, 0)
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_move_cursor(1, 0)
	elif event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_move_cursor(0, -1)
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_move_cursor(0, 1)
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_select(_cursor)
	elif event.is_action_pressed("moxie_burn"):
		get_viewport().set_input_as_handled()
		_assist()

func _move_cursor(dx: int, dy: int) -> void:
	var x := clampi(_cursor % COLS + dx, 0, COLS - 1)
	var y := clampi(_cursor / COLS + dy, 0, ROWS - 1)
	var prev := _cursor
	_cursor = y * COLS + x
	_update_cursor(prev)

func _update_cursor(prev: int) -> void:
	if prev >= 0 and prev < _nodes.size():
		_nodes[prev].modulate = Color.WHITE
	_nodes[_cursor].modulate = CURSOR_TINT

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _reset_nodes() -> void:
	for n in _nodes:
		n.color = COL_IDLE
		n.modulate = Color.WHITE

func _wait(t: float) -> void:
	# process_always = true so timers tick while the tree is paused.
	await get_tree().create_timer(t, true).timeout

func _neighbors(idx: int) -> Array[int]:
	var x := idx % COLS
	var y := idx / COLS
	var out: Array[int] = []
	if x > 0: out.append(idx - 1)
	if x < COLS - 1: out.append(idx + 1)
	if y > 0: out.append(idx - COLS)
	if y < ROWS - 1: out.append(idx + COLS)
	return out

func _gen_route(length: int) -> Array[int]:
	# A random connected path (orthogonal steps, no repeats) of `length` nodes.
	while true:
		var path: Array[int] = [randi() % (COLS * ROWS)]
		var ok := true
		while path.size() < length:
			var options := _neighbors(path[-1]).filter(
				func(n: int) -> bool: return n not in path
			)
			if options.is_empty():
				ok = false
				break
			path.append(options[randi() % options.size()])
		if ok:
			return path
	return []
