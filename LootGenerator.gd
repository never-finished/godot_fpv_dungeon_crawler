extends Node
# This is a global Autoload / Singleton manager

var possible_prefixes: Array[AffixData] = []
var possible_suffixes: Array[AffixData] = []

func _ready():
	# In a full game, you'd load these from a folder or JSON.
	# For now, let's hardcode a few test affixes into memory to get the loop working.
	
	var pref1 = AffixData.new()
	pref1.affix_name = "Savage"
	pref1.type = AffixData.Type.PREFIX
	pref1.stat_target = "strength"
	pref1.min_roll = 2
	pref1.max_roll = 6
	possible_prefixes.append(pref1)
	
	var pref2 = AffixData.new()
	pref2.affix_name = "Stout"
	pref2.type = AffixData.Type.PREFIX
	pref2.stat_target = "health"
	pref2.min_roll = 10
	pref2.max_roll = 25
	possible_prefixes.append(pref2)
	
	var suff1 = AffixData.new()
	suff1.affix_name = "of the Bear"
	suff1.type = AffixData.Type.SUFFIX
	suff1.stat_target = "strength"
	suff1.min_roll = 5
	suff1.max_roll = 15
	possible_suffixes.append(suff1)
	
	var suff2 = AffixData.new()
	suff2.affix_name = "of the Cheetah"
	suff2.type = AffixData.Type.SUFFIX
	suff2.stat_target = "movement_speed"
	suff2.min_roll = 1
	suff2.max_roll = 3
	possible_suffixes.append(suff2)

func generate_loot(base_item: ItemData, monster_level: int) -> ItemData:
	# Duplicate the base structure so we don't overwrite the original Master blueprint
	var new_item = base_item.duplicate() 
	
	# Determine Rarity (Placeholder math)
	var roll = randf()
	if roll < 0.05:
		new_item.rarity = ItemData.Rarity.RARE      # 5% chance
	elif roll < 0.25:
		new_item.rarity = ItemData.Rarity.MAGIC     # 20% chance
	else:
		new_item.rarity = ItemData.Rarity.COMMON    # 75% chance
		
	# Apply Affixes based on Rarity
	var prefix_count = 0
	var suffix_count = 0
	
	if new_item.rarity == ItemData.Rarity.MAGIC:
		# Magic items get 1 affix (either prefix or suffix)
		if randf() > 0.5: prefix_count = 1 
		else: suffix_count = 1
	elif new_item.rarity == ItemData.Rarity.RARE:
		# Rare items get up to 3 affixes (max 2 prefix, max 2 suffix)
		prefix_count = randi_range(1, 2)
		suffix_count = randi_range(1, 2)
		
	# Assign Prefixes
	var name_prefix = ""
	for i in range(prefix_count):
		var aff = _get_random_affix(possible_prefixes, monster_level)
		if aff:
			new_item.applied_modifiers.append(aff.generate_modifier())
			name_prefix = aff.affix_name + " "
			
	# Assign Suffixes
	var name_suffix = ""
	for i in range(suffix_count):
		var aff = _get_random_affix(possible_suffixes, monster_level)
		if aff:
			new_item.applied_modifiers.append(aff.generate_modifier())
			name_suffix = " " + aff.affix_name
			
	# Generate Final Name
	new_item.generated_name = name_prefix + new_item.item_name + name_suffix
	new_item.item_level = monster_level
	
	return new_item

func _get_random_affix(pool: Array[AffixData], level: int) -> AffixData:
	var valid_affixes = []
	for aff in pool:
		if aff.required_level <= level:
			valid_affixes.append(aff)
			
	if valid_affixes.size() == 0:
		return null
		
	return valid_affixes[randi() % valid_affixes.size()]
