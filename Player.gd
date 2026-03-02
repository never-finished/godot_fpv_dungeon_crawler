extends CharacterBody3D

@export var acceleration : float = 10.0
@export var jump_velocity : float = 4.5
@export var mouse_sensitivity : float = 0.002

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var weapon_pivot: Node3D = $Head/Camera3D/WeaponPivot
@onready var weapon_mesh: MeshInstance3D = $Head/Camera3D/WeaponPivot/WeaponMesh
@onready var stats: StatManager = $StatManager
@onready var character_sheet: Control = $HUD/CharacterSheet
@onready var death_screen: Control = $HUD/DeathScreen
@onready var crosshair: ColorRect = $HUD/Crosshair

var attack_cooldown: float = 0.5
var current_attack_timer: float = 0.0
var shake_timer: float = 0.0
var shake_intensity: float = 0.0

var inventory: Array[ItemData] = []
var equipped_weapon: WeaponData = null
var is_dead: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	stats.on_died.connect(_on_death)
	stats.damage_taken.connect(_on_damage_taken)
	
	GameManager.load_player_state(self)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead: return
	
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if event.is_action_pressed("interact") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if interaction_ray.is_colliding():
			var target = interaction_ray.get_collider()
			if target and target.has_method("interact"):
				target.interact(self)
			elif target and target.get_parent().has_method("interact"):
				# Useful if the script is on the parent but we hit a child CollisionShape
				target.get_parent().interact(self)

func _input(event: InputEvent) -> void:
	if is_dead: return
	
	if event.is_action_pressed("character_sheet"):
		character_sheet.toggle_ui(self)
		# Tell Godot we handled this input so the UI doesn't tab-target
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if is_dead: return
	
	# Handle Screen Shake
	if shake_timer > 0:
		shake_timer -= delta
		# Generate random offset
		var offset = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity * (shake_timer / 0.3)
		camera.h_offset = offset.x
		camera.v_offset = offset.y
	else:
		camera.h_offset = 0
		camera.v_offset = 0

	# Handle Attack Timer
	if current_attack_timer > 0:
		current_attack_timer -= delta
		
	if Input.is_action_pressed("attack") and current_attack_timer <= 0:
		_perform_attack()

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Calculate desired direction based on head rotation (so we walk where we look)
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Smooth acceleration/deceleration
	var current_speed = stats.movement_speed.get_value()
	if Input.is_action_pressed("sprint"):
		current_speed *= 1.6
		
	if direction:
		velocity.x = lerp(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)

	move_and_slide()

func _perform_attack():
	if is_dead: return
	
	current_attack_timer = attack_cooldown
	
	# Visual swing animation using Tweens
	if weapon_mesh.visible:
		var tween = get_tree().create_tween()
		# Slash down-left quickly
		tween.tween_property(weapon_pivot, "rotation_degrees", Vector3(-45, 45, -30), attack_cooldown * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Recover back to resting position over the remaining cooldown
		tween.tween_property(weapon_pivot, "rotation_degrees", Vector3(0, 0, 0), attack_cooldown * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Very basic melee implementation using the same interaction ray for now
	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		if target.is_in_group("enemy") and target.has_node("StatManager"):
			var target_stats = target.get_node("StatManager")
			
			# Base damage from strength + Weapon Roll
			var damage = stats.strength.get_value()
			if equipped_weapon:
				damage += equipped_weapon.roll_base_damage()
				
			target_stats.take_damage(damage, "Physical")
			print("Player hit " + target.name + " for " + str(damage) + " damage!")

func _on_death():
	is_dead = true
	print("Player died! Showing death screen...")
	crosshair.hide()
	death_screen.trigger_death()
	
func _on_damage_taken(_amount: float):
	shake_intensity = 0.2
	shake_timer = 0.3 # Fade out over 0.3 seconds
	
func _pickup_item(item: ItemData):
	print("Picked up: ", item.get_full_name(), " (Rarity: ", item.rarity, ")")
	inventory.append(item)
	
	# Auto-equip logic for testing
	if item is WeaponData and equipped_weapon == null:
		_equip_weapon(item)

func _equip_weapon(weapon: WeaponData):
	if equipped_weapon:
		_unequip_weapon(equipped_weapon)
		
	equipped_weapon = weapon
	print("Equipped: ", weapon.get_full_name())
	weapon_mesh.visible = true
	
	# Apply new weapon affix modifiers to player's StatManager
	for mod in weapon.applied_modifiers:
		if not mod.source or not mod.source.get("stat_target"): continue
		
		var target_stat_name = mod.source.stat_target
		# Match the affix's string target to the actual Stat object
		var stat_obj = stats.get(target_stat_name)
		if stat_obj and stat_obj is Stat:
			stat_obj.add_modifier(mod)
			print("  -> Applied Affix: ", str(mod.value), " to ", target_stat_name)

func _unequip_weapon(weapon: WeaponData):
	for mod in weapon.applied_modifiers:
		if not mod.source or not mod.source.get("stat_target"): continue
		
		var target_stat_name = mod.source.stat_target
		var stat_obj = stats.get(target_stat_name)
		if stat_obj and stat_obj is Stat:
			stat_obj.remove_modifier(mod)
			print("  <- Removed Affix: ", str(mod.value), " from ", target_stat_name)
	
	weapon_mesh.visible = false
