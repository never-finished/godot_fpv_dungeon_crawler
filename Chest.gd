extends Interactable

# A simple mock chest for testing interaction.
# Later we will tie this into the Loot Generator.

@export var is_open: bool = false
@onready var mesh: MeshInstance3D = $MeshInstance3D

var ground_item_scene = preload("res://GroundItem.tscn")

func interact(player: Node):
	if is_open:
		print("Chest is already empty.")
		return
		
	is_open = true
	print("Chest opened!")
	
	# --- LOOT DROP LOGIC ---
	var base_sword = WeaponData.new()
	base_sword.item_name = "Rusty Sword"
	base_sword.min_damage = 2 * GameManager.current_depth
	base_sword.max_damage = 5 * GameManager.current_depth
	
	# Ask the global LootGenerator to roll rarity and add affixes
	# For chests, let's pretend it's a higher level area for slightly better rolls
	var generated_sword = LootGenerator.generate_loot(base_sword, GameManager.current_depth + 1) 
	
	# Spawn the Physical item in the world slightly in front of the chest
	var drop = ground_item_scene.instantiate()
	get_parent().add_child(drop)
	# Push the drop outward slightly so it doesn't clip perfectly inside the chest mesh
	drop.global_position = global_position + Vector3(0, 1, 1.5)
	drop.initialize(generated_sword)
	
	# Visual feedback: change color to show it was opened
	var material = mesh.get_active_material(0)
	if material == null:
		material = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, material)
	material.albedo_color = Color(0.3, 0.3, 0.3) # Darken it to look 'looted'
	
	super.interact(player)
