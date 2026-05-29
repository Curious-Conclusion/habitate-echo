extends CanvasLayer
## Full-screen derangement glitch. When the player's Moxie drops below their
## derangement threshold, a red wash flickers over the screen — the lower the
## Moxie, the more violent the flicker.

@onready var rect: ColorRect = $Rect

var _player: CharacterBody2D
var _intensity: float = 0.0  ## 0 = stable, 1 = fully deranged

func setup(player: CharacterBody2D) -> void:
	_player = player
	player.moxie_changed.connect(_on_moxie_changed)
	rect.color = Color(0.55, 0.0, 0.12, 0.0)
	_recompute(player.current_moxie)

func _on_moxie_changed(current: int, _maximum: int) -> void:
	_recompute(current)

func _recompute(current: int) -> void:
	var threshold: int = _player.DERANGE_THRESHOLD
	if current >= threshold:
		_intensity = 0.0
	else:
		_intensity = clampf(1.0 - float(current) / float(threshold), 0.0, 1.0)

func _process(_delta: float) -> void:
	if _intensity <= 0.0:
		rect.color.a = 0.0
		return
	# Flicker: random alpha scaled by how deranged we are.
	rect.color.a = randf_range(0.0, 0.22 * _intensity)
