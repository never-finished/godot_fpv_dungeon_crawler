extends ItemData
class_name WeaponData

@export var min_damage: float = 1.0
@export var max_damage: float = 3.0
@export var attack_speed: float = 1.0

# Returns a random integer between min and max damage
func roll_base_damage() -> float:
	return round(randf_range(min_damage, max_damage))
