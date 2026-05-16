extends ProgressBar

func setup(player: CharacterBody2D) -> void:
	player.health_changed.connect(_on_health_changed)
	var data := MorphManager.get_current_morph()
	max_value = data.max_health
	value = data.max_health
	visible = true

func _on_health_changed(current: int, maximum: int) -> void:
	max_value = maximum
	value = current
