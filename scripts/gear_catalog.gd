extends Node
## Catalog of buyable field gear, mirroring OpCatalog/MorphManager. The hub
## quartermaster reads this to stock the shop; FieldGear reads it to label and
## resolve the effect of a carried item. Gear is consumable — one use per item.
##
## effect ids (applied in field_gear.gd):
##   "heal"   — flush damage and restore some Moxie
##   "emp"    — disperse every nanite swarm on the site
##   "extract"— panic farcaster: emergency egocast back to the safehouse

var _gear: Dictionary = {}  # StringName -> Dictionary{name, desc, cost, effect}

func _ready() -> void:
	_register_gear()

func _register_gear() -> void:
	_add(&"medichine", "Medichine Dose", "Knits wounds and steadies the ego (heal + Moxie).", 20, "heal")
	_add(&"emp_charge", "EMP Charge", "Discharges a pulse that scatters nearby nanite swarms.", 25, "emp")
	_add(&"panic_farcaster", "Panic Farcaster", "One-shot emergency egocast — bail out to the safehouse.", 40, "extract")

func _add(id: StringName, gear_name: String, desc: String, cost: int, effect: String) -> void:
	_gear[id] = {"name": gear_name, "desc": desc, "cost": cost, "effect": effect}

func get_gear(gear_id: StringName) -> Dictionary:
	return _gear.get(gear_id, {})

func all_ids() -> Array:
	return _gear.keys()

func display_name(gear_id: StringName) -> String:
	return _gear.get(gear_id, {}).get("name", String(gear_id))

func cost(gear_id: StringName) -> int:
	return _gear.get(gear_id, {}).get("cost", 0)

func effect(gear_id: StringName) -> String:
	return _gear.get(gear_id, {}).get("effect", "")
