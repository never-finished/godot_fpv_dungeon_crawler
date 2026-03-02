extends Node
class_name StatManager

# Core RPG Attributes
var health: Stat = Stat.new(100)
var max_health: Stat = Stat.new(100)
var mana: Stat = Stat.new(50)
var max_mana: Stat = Stat.new(50)

# Combat Stats
var strength: Stat = Stat.new(10) # Increases raw melee damage
var dexterity: Stat = Stat.new(10) # Increases crit chance / ranged
var intelligence: Stat = Stat.new(10) # Increases spell damage / mana

var armor: Stat = Stat.new(0) # Physical damage reduction
var movement_speed: Stat = Stat.new(5.0) # Base movement speed

signal on_died
signal damage_taken(amount: float)

func _ready():
	# Make sure current resources match their max.
	health.set_base_value(max_health.get_value())
	mana.set_base_value(max_mana.get_value())

func take_damage(amount: float, type: String = "Physical"):
	var final_damage = amount
	
	if type == "Physical":
		# Simple armor mitigation formula
		var mitigation = armor.get_value() / (armor.get_value() + 50.0) 
		final_damage -= (final_damage * mitigation)
		
	final_damage = max(1.0, round(final_damage))
	print(get_parent().name + " took " + str(final_damage) + " damage!")
	
	damage_taken.emit(final_damage)
	
	var cur_health = health.get_value() - final_damage
	if cur_health <= 0:
		cur_health = 0
		health.set_base_value(cur_health)
		die()
	else:
		health.set_base_value(cur_health)

func die():
	print(get_parent().name + " has died!")
	on_died.emit()
