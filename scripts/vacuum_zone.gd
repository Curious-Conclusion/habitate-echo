extends Area2D
## An environmental hazard volume — vacuum breach, cryo leak, reactor fire.
## Drains HP (and a little Moxie) over time from any morph without the immune
## ability; the Synth's sealed chassis (VACUUM_SEAL) shrugs off all of them.
## This is the morph-gating hazard pattern: you resleeve to cross, or you bleed.

@export var damage: int = 8
@export var moxie_drain: int = 2
@export var tick_interval: float = 0.6
## Which morph ability negates this hazard entirely.
@export var immune_ability: MorphManager.Ability = MorphManager.Ability.VACUUM_SEAL

var _player: CharacterBody2D
var _inside := false
var _timer := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if not _inside or not is_instance_valid(_player) or _player.is_dead:
		return
	if _is_sealed():
		return
	# overlaps_body is authoritative: a teleport out (travel, respawn) must
	# never land a phantom tick before body_exited catches up.
	if not overlaps_body(_player):
		return
	_timer -= delta
	if _timer <= 0.0:
		_player.take_damage(damage)
		_player.reduce_moxie(moxie_drain)
		_timer = tick_interval

func _is_sealed() -> bool:
	return MorphManager.get_current_morph().ability == immune_ability

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_inside = true
		_timer = 0.0  # immediate first tick

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside = false
