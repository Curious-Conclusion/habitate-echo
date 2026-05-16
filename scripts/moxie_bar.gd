extends ProgressBar

const NANITE_TEXTS: Array[String] = [
	"They're inside your skin.",
	"You feel them rearranging something.",
	"Your flesh crawls. Literally.",
	"Tiny mouths, chewing.",
	"Part of you wants to let them finish.",
	"Your edges are dissolving.",
]

const FLAVOR_COOLDOWN := 3.0
const FLAVOR_DISPLAY := 2.0

@onready var flavor_label: Label = $"../MoxieFlavor"

var _cooldown: float = 0.0
var _prev_moxie: int = -1

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

func setup(player: CharacterBody2D) -> void:
	player.moxie_changed.connect(_on_moxie_changed)
	max_value = player.max_moxie
	value = player.current_moxie
	_prev_moxie = player.current_moxie
	flavor_label.modulate.a = 0.0

func _on_moxie_changed(current: int, maximum: int) -> void:
	max_value = maximum
	value = current
	if current < _prev_moxie and _cooldown <= 0.0:
		show_flavor(NANITE_TEXTS[randi() % NANITE_TEXTS.size()])
		_cooldown = FLAVOR_COOLDOWN
	_prev_moxie = current

func show_flavor(text: String) -> void:
	flavor_label.text = text
	flavor_label.modulate.a = 1.0
	var tw := flavor_label.create_tween()
	tw.tween_interval(FLAVOR_DISPLAY)
	tw.tween_property(flavor_label, "modulate:a", 0.0, 0.5)
