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

const HOLD := 2.6           ## seconds a whisper stays before fading
const GAP_MIN := 7.0        ## seconds between whispers (randomized)
const GAP_MAX := 14.0

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
	if not _player.is_deranged():
		_timer = maxf(_timer, 4.0)  # stabilizing resets the build-up
		return
	_timer -= delta
	if _timer <= 0.0:
		_show_whisper()
		_timer = randf_range(GAP_MIN, GAP_MAX)

func _show_whisper() -> void:
	var i := randi() % LINES.size()
	if i == _last_index:
		i = (i + 1) % LINES.size()
	_last_index = i
	label.text = LINES[i]
	# Drift the line a little so it never sits in the same spot twice.
	label.offset_left = randf_range(-60.0, 60.0)
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 0.85, 0.8)
	tw.tween_interval(HOLD)
	tw.tween_property(label, "modulate:a", 0.0, 1.2)
