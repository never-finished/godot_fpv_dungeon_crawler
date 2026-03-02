extends Node
# A global Autoload to track run metadata across scene reloads

var current_depth: int = 1
var saved_inventory: Array[ItemData] = []
var saved_equipped_weapon: WeaponData = null
var current_floor_seed: int = 0

func _ready():
	randomize()
	current_floor_seed = randi()

func reset_run():
	# We intentionally do NOT reset current_floor_seed here so they can replay the same layout
	current_depth = 1
	saved_inventory.clear()
	saved_equipped_weapon = null

func save_player_state(player: Node):
	if player:
		saved_inventory = player.inventory.duplicate()
		saved_equipped_weapon = player.equipped_weapon

func load_player_state(player: Node):
	if player:
		player.inventory = saved_inventory.duplicate()
		if saved_equipped_weapon != null:
			# Find the identical weapon in the new duplicated inventory list
			var idx = saved_inventory.find(saved_equipped_weapon)
			if idx != -1:
				player._equip_weapon(player.inventory[idx])
			else:
				player._equip_weapon(saved_equipped_weapon)

func go_deeper(player: Node = null):
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			
	save_player_state(player)
	current_depth += 1
	current_floor_seed = randi() # Generate a brand new layout for the new floor
	get_tree().reload_current_scene()
