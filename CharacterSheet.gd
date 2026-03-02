extends Control

@onready var str_label: Label = $Panel/VBoxContainer/StrengthLabel
@onready var hp_label: Label = $Panel/VBoxContainer/HealthLabel
@onready var wpn_label: Label = $Panel/VBoxContainer/WeaponLabel
@onready var dmg_label: Label = $Panel/VBoxContainer/DamageLabel
@onready var inv_list: ItemList = $Panel/InventoryList

var player: Node3D

func _ready():
	inv_list.item_activated.connect(_on_inventory_item_activated)
	hide()
	
func toggle_ui(p_player: Node3D):
	if visible:
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		player = p_player
		update_stats()
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
func update_stats():
	if not player or not player.has_node("StatManager"): return
	
	var stats = player.get_node("StatManager")
	str_label.text = "Strength: " + str(stats.strength.get_value())
	hp_label.text = "Health: " + str(stats.health.get_value()) + " / " + str(stats.max_health.get_value())
	
	var equipped = player.equipped_weapon
	if equipped:
		wpn_label.text = "Equipped: " + equipped.get_full_name()
		
		# Show the expected damage ranges
		var base_dmg = stats.strength.get_value()
		var min_tot = base_dmg + equipped.min_damage
		var max_tot = base_dmg + equipped.max_damage
		dmg_label.text = "Melee Damage: " + str(min_tot) + " - " + str(max_tot)
	else:
		wpn_label.text = "Equipped: None (Fists)"
		dmg_label.text = "Melee Damage: " + str(stats.strength.get_value())
		
	# Populate visual inventory block
	inv_list.clear()
	for item in player.inventory:
		inv_list.add_item(item.get_full_name())

func _on_inventory_item_activated(index: int):
	if not player: return
	
	var item = player.inventory[index]
	if item is WeaponData:
		if player.equipped_weapon == item:
			# Toggle off: Unequip the weapon
			player._unequip_weapon(item)
			player.equipped_weapon = null
		else:
			# Equip the new weapon
			player._equip_weapon(item)
			
		update_stats() # Refresh the UI numbers immediately
