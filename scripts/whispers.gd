extends CanvasLayer
## Ambient dread: while the player is deranged (low Moxie), intrusive lines
## surface at irregular intervals — the async, or your own fraying ego; the
## game never says which. Self-contained: drop into any op scene; finds the
## player by group. Pauses with the tree (dialogue suppresses it), and the
## label fades rather than popping so it reads as half-noticed.

const LINES: Array[String] = [
	"You left something in the last body.",
	"Who is wearing you?",
	"The walls remember your old name.",
	"Your hands are the wrong hands.",
	"Backups dream. You were the dream.",
	"Something is reading you.",
	"The static knows your face.",
	"It's quieter inside the stack.",
	"Stop running. You are already here.",
	"One of your memories is new.",
]

## Traumas carry their own voices. These surface mixed in while deranged, and
## alone at merely-shaken Moxie — wounds whisper even when you're "fine".
## Psychosurgery clearing the trauma silences them, which is the point.
const TRAUMA_LINES: Dictionary = {
	&"fork_dissonance": [
		"The other you got further than this.",
		"You remember dying. You remember not dying. Both feel true.",
		"This body never met the people you miss.",
	],
	&"executioners_echo": [
		"Finally finally.",
		"She didn't resist. That's the part that stays.",
		"Three seconds. You counted.",
	],
}

const HOLD := 2.6           ## seconds a whisper stays before fading
const GAP_MIN := 7.0        ## seconds between whispers (randomized)
const GAP_MAX := 14.0
const SHAKEN_MOXIE := 55    ## below this, carried traumas whisper on their own

@onready var label: Label = $WhisperLabel

var _player: CharacterBody2D
var _timer: float = 5.0     ## first whisper comes a little sooner
var _last_index: int = -1

func _ready() -> void:
	label.modulate = Color(1.0, 0.62, 0.62, 0.0)
	_player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if not is_instance_valid(_player) or _player.is_dead:
		return
	var pool := _build_pool()
	if pool.is_empty():
		_timer = maxf(_timer, 4.0)  # stabilizing resets the build-up
		return
	_timer -= delta
	if _timer <= 0.0:
		_show_whisper(pool)
		_timer = randf_range(GAP_MIN, GAP_MAX)
		if not _player.is_deranged():
			_timer *= 1.6  # trauma-only whispers come slower

## Deranged: the full chorus, traumas mixed in. Merely shaken but carrying
## trauma: only the trauma's own voice. Stable and clean: silence.
func _build_pool() -> Array:
	var trauma_pool: Array = []
	for t: StringName in GameState.traumas:
		trauma_pool.append_array(TRAUMA_LINES.get(t, []))
	if _player.is_deranged():
		var chorus: Array = []
		chorus.append_array(LINES)
		chorus.append_array(trauma_pool)
		return chorus
	if not trauma_pool.is_empty() and _player.current_moxie < SHAKEN_MOXIE:
		return trauma_pool
	return []

func _show_whisper(pool: Array) -> void:
	var i := randi() % pool.size()
	if i == _last_index and pool.size() > 1:
		i = (i + 1) % pool.size()
	_last_index = i
	label.text = pool[i]
	# Drift the line a little so it never sits in the same spot twice.
	label.offset_left = randf_range(-60.0, 60.0)
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 0.85, 0.8)
	tw.tween_interval(HOLD)
	tw.tween_property(label, "modulate:a", 0.0, 1.2)
