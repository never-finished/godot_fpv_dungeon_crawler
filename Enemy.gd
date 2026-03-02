extends CharacterBody3D

@export var speed: float = 2.0
@export var detection_range: float = 10.0

@onready var stats: StatManager = $StatManager
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

# Simple state machine
enum State { IDLE, WANDER, CHASE, ATTACK }
var current_state: State = State.IDLE

var player: Node3D = null
var wander_target: Vector3

var float_text_scene = preload("res://FloatingText.tscn")

var attack_cooldown: float = 1.5
var current_attack_timer: float = 0.0

@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
var flash_timer: float = 0.0

func _ready():
	add_to_group("enemy")
	
	# Scale difficulty based on depth
	var depth_multi = GameManager.current_depth
	stats.max_health.set_base_value(100.0 * depth_multi)
	stats.health.set_base_value(100.0 * depth_multi)
	stats.strength.set_base_value(10.0 * depth_multi)
	
	stats.on_died.connect(_on_death)
	stats.damage_taken.connect(_on_damage_taken)
	stats.health.on_value_changed.connect(_on_health_changed)
	
	# Wait a frame to find player in case we spawned before them
	call_deferred("_find_player")
	_pick_new_wander_target()

func _find_player():
	var group = get_tree().get_nodes_in_group("player")
	if group.size() > 0:
		player = group[0]

func _physics_process(delta):
	if current_attack_timer > 0:
		current_attack_timer -= delta
		
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			# Reset material color back to base after flashing (only for default capsule)
			if mesh and mesh.get_active_material(0):
				mesh.get_active_material(0).albedo_color = Color(0.8, 0.1, 0.1) # Base Red
				
	# Gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	match current_state:
		State.IDLE:
			velocity.x = 0
			velocity.z = 0
			if _can_see_player():
				current_state = State.CHASE
			elif randf() < 0.01: # Small chance per frame to wander
				current_state = State.WANDER
				_pick_new_wander_target()
				
		State.WANDER:
			if _can_see_player():
				current_state = State.CHASE
				return
				
			nav_agent.target_position = wander_target
			if nav_agent.is_navigation_finished():
				current_state = State.IDLE
			else:
				_move_towards_target()
				
		State.CHASE:
			if player == null or not _can_see_player():
				current_state = State.WANDER
				_pick_new_wander_target()
				return
				
			var dist = global_position.distance_to(player.global_position)
			if dist < 1.5:
				current_state = State.ATTACK
			else:
				nav_agent.target_position = player.global_position
				_move_towards_target()
				
		State.ATTACK:
			velocity.x = 0
			velocity.z = 0
			
			if player and global_position.distance_to(player.global_position) > 1.6:
				current_state = State.CHASE
			elif current_attack_timer <= 0 and player:
				_perform_attack()

	move_and_slide()

func _move_towards_target():
	var next_path_pos = nav_agent.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_pos) * speed
	velocity.x = new_velocity.x
	velocity.z = new_velocity.z
	
	# Look where we are going
	var look_pos = next_path_pos
	look_pos.y = global_position.y
	if global_position.distance_to(look_pos) > 0.1:
		look_at(look_pos, Vector3.UP)

func _can_see_player() -> bool:
	if not player: return false
	return global_position.distance_to(player.global_position) <= detection_range

func _pick_new_wander_target():
	# For now, just pick a random spot nearby. 
	# A real NavigationRegion3D is required for actual pathing to work properly.
	var rand_offset = Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
	wander_target = global_position + rand_offset

var ground_item_scene = preload("res://GroundItem.tscn")

func _on_death():
	print("Enemy defeated!")
	
	# --- LOOT DROP LOGIC ---
	# In a real game, enemies have drop tables. For testing, we just generate a random Rusty Sword.
	var base_sword = WeaponData.new()
	base_sword.item_name = "Rusty Sword"
	base_sword.min_damage = 2 * GameManager.current_depth
	base_sword.max_damage = 5 * GameManager.current_depth
	
	# Ask the global LootGenerator to roll rarity and add affixes
	var generated_sword = LootGenerator.generate_loot(base_sword, GameManager.current_depth)
	
	# Spawn the Physical item in the world
	var drop = ground_item_scene.instantiate()
	get_parent().add_child(drop)
	drop.global_position = global_position
	drop.initialize(generated_sword)
		
	queue_free()

func _on_health_changed(new_val: float):
	# Visual cue that they took damage (only for default capsule)
	if mesh and mesh.get_active_material(0):
		mesh.get_active_material(0).albedo_color = Color(1.0, 1.0, 1.0) # Flash white
	flash_timer = 0.1

func _on_damage_taken(amount: float):
	var float_text = float_text_scene.instantiate()
	get_parent().add_child(float_text)
	float_text.global_position = global_position + Vector3(0, 1.5, 0)
	float_text.initialize(str(amount), Color.RED)

func _perform_attack():
	current_attack_timer = attack_cooldown
	if player and player.has_node("StatManager"):
		var p_stats = player.get_node("StatManager")
		var damage = stats.strength.get_value()
		p_stats.take_damage(damage, "Physical")
		print("Enemy hit Player for " + str(damage) + " damage!")
