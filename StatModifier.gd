extends Resource
class_name StatModifier

enum Type {
	FLAT,          # e.g., +5 Damage
	PERCENT_ADD,   # e.g., +10% Damage
	PERCENT_MULT   # e.g., x1.5 Damage (Rare multiplicative modifiers)
}

@export var value: float
@export var type: Type
var source: Object # The item/buff that gave this stat (cannot be exported generic)

func _init(v: float = 0.0, t: Type = Type.FLAT, src: Object = null):
	value = v
	type = t
	source = src
