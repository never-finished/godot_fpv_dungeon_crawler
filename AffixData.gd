extends Resource
class_name AffixData

enum Type { PREFIX, SUFFIX }

@export var affix_name: String = "of Power"
@export var type: Type = Type.SUFFIX

@export var required_level: int = 1

# What stat does this affix buff? (Corresponds to StatManager variable names)
@export var stat_target: String = "strength" 
@export var modifier_type: StatModifier.Type = StatModifier.Type.FLAT

# Range for Random Number Generator when item drops
@export var min_roll: float = 1.0
@export var max_roll: float = 5.0

func generate_modifier() -> StatModifier:
	var val = round(randf_range(min_roll, max_roll))
	return StatModifier.new(val, modifier_type, self)
