extends Node3D
class_name DungeonGenerator

# Grid settings
@export var width: int = 20
@export var depth: int = 20
@export var num_steps: int = 150 # How long the random walker goes

# TILE CONSTANTS
const TILE_EMPTY = 0
const TILE_FLOOR = 1
const TILE_WALL = 2

var grid = []

# Spawn references
@export var player_scene: PackedScene
@export var chest_scene: PackedScene
@export var enemy_scene: PackedScene
@export var extra_enemy_scenes: Array[PackedScene] = []
@export var stairs_scene: PackedScene

@export var floor_mesh: Mesh
@export var wall_mesh: Mesh
@export var cell_size: float = 2.0

@onready var geometry_container = Node3D.new()
@onready var nav_region = NavigationRegion3D.new()

func _ready():
	add_child(nav_region)
	nav_region.add_child(geometry_container)
	
	# Setup NavMesh parameters for our grid size (4x4 tiles, 8 tall walls)
	var nav_mesh = NavigationMesh.new()
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_radius = 0.5
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_region.navigation_mesh = nav_mesh
	
	geometry_container.name = "Geometry"
	generate_dungeon()

func generate_dungeon():
	# Lock the global random number generator to the GameManager's seed
	# This guarantees the exact same dungeon layout if the player dies and reloads
	seed(GameManager.current_floor_seed)
	
	# 1. Initialize grid with empty space
	grid.clear()
	for x in range(width):
		var column = []
		for z in range(depth):
			column.append(TILE_EMPTY)
		grid.append(column)

	# 2. Random Walk (Drunkard's Walk) algorithm
	var x = width / 2
	var z = depth / 2
	var steps_taken = 0
	
	grid[x][z] = TILE_FLOOR # Starting tile
	
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	while steps_taken < num_steps:
		var dir = directions[randi() % directions.size()]
		# Convert Vector2 back to grid indices (using vector y as z depth)
		var next_x = x + int(dir.x)
		var next_z = z + int(dir.y)
		
		# Bounds check (keep a buffer of 1 for outer walls)
		if next_x > 1 and next_x < width - 2 and next_z > 1 and next_z < depth - 2:
			x = next_x
			z = next_z
			if grid[x][z] != TILE_FLOOR:
				grid[x][z] = TILE_FLOOR
				steps_taken += 1

	# 3. Build Walls around the generated floors
	build_walls()
	
	# 4. Instantiate Geometry
	instantiate_geometry()
	
	# 5. Bake Navigation Mesh based on the generated geometry
	nav_region.bake_navigation_mesh(false)
	
	# 6. Spawn Player at center (where walk started)
	var spawn_pos = Vector3(width/2.0 * cell_size, 1.0, depth/2.0 * cell_size)
	spawn_entity(player_scene, spawn_pos)
	
	# 7. Spawn Chest
	spawn_item_at_furthest_point(chest_scene, spawn_pos)
	
	# 8. Spawn Extraction Stairs
	spawn_item_at_furthest_point(stairs_scene, spawn_pos)
	
	# 9. Spawn Enemies (Placeholder list logic)
	_spawn_enemies(5 + GameManager.current_depth)

func build_walls():
	for x in range(width):
		for z in range(depth):
			if grid[x][z] == TILE_FLOOR:
				# Check 8 neighbors. If a neighbor is EMPTY, make it a WALL.
				for nx in range(x-1, x+2):
					for nz in range(z-1, z+2):
						if nx >= 0 and nx < width and nz >= 0 and nz < depth:
							if grid[nx][nz] == TILE_EMPTY:
								grid[nx][nz] = TILE_WALL

func instantiate_geometry():
	for x in range(width):
		for z in range(depth):
			if grid[x][z] == TILE_FLOOR:
				create_tile(floor_mesh, x, z, true, 0.0)
				# Create a ceiling directly above the floor (height = 8.0, same as wall height)
				create_tile(floor_mesh, x, z, true, 8.0)
			elif grid[x][z] == TILE_WALL:
				# Walls are centered at Y = 0 (size 8), so Y extents are -4 to 4. 
				# Let's shift walls up by 4 so their base is at 0.
				create_tile(wall_mesh, x, z, true, 4.0)

func create_tile(mesh_to_use: Mesh, grid_x: int, grid_z: int, create_collision: bool, y_pos: float):
	if mesh_to_use == null:
		return
		
	var mi = MeshInstance3D.new()
	mi.mesh = mesh_to_use
	
	# Position in world space
	mi.position = Vector3(grid_x * cell_size, y_pos, grid_z * cell_size)
	
	if create_collision:
		mi.create_trimesh_collision()
		
	geometry_container.add_child(mi)

func spawn_entity(scene: PackedScene, world_pos: Vector3):
	if scene == null: return
	
	var inst = scene.instantiate()
	# Hack for the player so we don't spawn a second TestLevel player
	var existing_player = get_tree().get_first_node_in_group("player")
	if existing_player and scene == player_scene: return
	
	if scene == player_scene:
		inst.add_to_group("player")
		
	inst.position = world_pos
	add_child(inst)

func spawn_item_at_furthest_point(scene: PackedScene, start_pos: Vector3):
	var furthest_dist = 0.0
	var furthest_pos = start_pos
	
	for x in range(width):
		for z in range(depth):
			if grid[x][z] == TILE_FLOOR:
				var wp = Vector3(x * cell_size, 1.0, z * cell_size)
				var dist = start_pos.distance_to(wp)
				if dist > furthest_dist:
					furthest_dist = dist
					furthest_pos = wp
					
	spawn_entity(scene, furthest_pos)

func _spawn_enemies(count: int):
	var floors = []
	for x in range(width):
		for z in range(depth):
			if grid[x][z] == TILE_FLOOR:
				floors.append(Vector3(x * cell_size, 1.0, z * cell_size))
				
	# Pick random floors and spawn enemies
	for i in range(count):
		if floors.size() > 0:
			var rand_idx = randi() % floors.size()
			var pos = floors[rand_idx]
			# Ensure we don't spawn right on top of the player's 0,0 center
			if pos.distance_to(Vector3(width/2.0 * cell_size, 1.0, depth/2.0 * cell_size)) > 8.0:
				var spawn_pool: Array[PackedScene] = []
				if enemy_scene != null:
					spawn_pool.append(enemy_scene)
				for escene in extra_enemy_scenes:
					if escene != null:
						spawn_pool.append(escene)
						
				if spawn_pool.size() > 0:
					var chosen_enemy = spawn_pool[randi() % spawn_pool.size()]
					spawn_entity(chosen_enemy, pos)
