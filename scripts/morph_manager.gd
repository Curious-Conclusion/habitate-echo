extends Node

signal morph_changed(morph_id: StringName)

enum Ability { NONE, CYBERBRAIN, VACUUM_SEAL, WALL_CLING }

class MorphData:
	var id: StringName
	var display_name: String
	var speed: float
	var max_health: int
	var ability: Ability
	var color: Color  ## placeholder tint until real sprites exist

	func _init(
		p_id: StringName,
		p_name: String,
		p_speed: float,
		p_health: int,
		p_ability: Ability,
		p_color: Color,
	) -> void:
		id = p_id
		display_name = p_name
		speed = p_speed
		max_health = p_health
		ability = p_ability
		color = p_color

var morphs: Dictionary = {}  # StringName -> MorphData
var current_morph_id: StringName = &"octomorph"

func _ready() -> void:
	_register_morphs()

func _register_morphs() -> void:
	_add(MorphData.new(
		&"octomorph", "Octomorph", 150.0, 80, Ability.WALL_CLING,
		Color(0.25, 0.75, 0.45),
	))
	_add(MorphData.new(
		&"synth", "Synth", 120.0, 150, Ability.VACUUM_SEAL,
		Color(0.55, 0.55, 0.6),
	))
	_add(MorphData.new(
		&"biomorph", "Biomorph", 170.0, 100, Ability.CYBERBRAIN,
		Color(0.8, 0.45, 0.25),
	))

func _add(data: MorphData) -> void:
	morphs[data.id] = data

func get_morph(morph_id: StringName) -> MorphData:
	return morphs.get(morph_id)

func get_current_morph() -> MorphData:
	return morphs.get(current_morph_id)

func switch_morph(morph_id: StringName) -> bool:
	if morph_id == current_morph_id:
		return false
	if not morphs.has(morph_id):
		return false
	current_morph_id = morph_id
	morph_changed.emit(morph_id)
	return true

func get_all_ids() -> Array:
	return morphs.keys()
