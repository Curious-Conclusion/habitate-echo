extends Area2D
## A breached, depressurized section. Drains HP (and a little Moxie) over time
## from any morph that isn't vacuum-sealed; Synth (VACUUM_SEAL) is safe. This is
## the morph-gating hazard for Op 1's breached hold — you must resleeve to cross.

@export var damage: int = 8
@export var moxie_drain: int = 2
@export var tick_interval: float = 0.6

var _player: CharacterBody2D
var _inside := false
var _timer := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not _inside or not is_instance_valid(_player) or _player.is_dead:
		return
	if _is_sealed():
		return
	_timer -= delta
	if _timer <= 0.0:
		_player.take_damage(damage)
		_player.reduce_moxie(moxie_drain)
		_timer = tick_interval

func _is_sealed() -> bool:
	return MorphManager.get_current_morph().ability == MorphManager.Ability.VACUUM_SEAL

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_inside = true
		_timer = 0.0  # immediate first tick

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside = false
