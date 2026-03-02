extends Resource
class_name ItemData

enum Rarity {
	COMMON,     # White
	MAGIC,      # Blue
	RARE,       # Yellow
	LEGENDARY   # Orange
}

@export var item_name: String = "Unknown Item"
@export var description: String = ""
@export var level_requirement: int = 1
@export var visual_mesh: Mesh

# We don't export these, they are generated at runtime by the Loot system
var rarity: Rarity = Rarity.COMMON
var generated_name: String = "" # e.g., "Flaming Rusty Sword of the Bear"
var applied_modifiers: Array[StatModifier] = []
var item_level: int = 1

func get_full_name() -> String:
	var prefix = "(Lvl. " + str(item_level) + ") "
	if generated_name != "":
		return prefix + generated_name
	return prefix + item_name
