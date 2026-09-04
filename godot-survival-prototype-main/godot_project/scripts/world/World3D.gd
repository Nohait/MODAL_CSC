extends Node3D

const PLAYER_SCENE := preload("res://scenes/Player3D.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/Enemy3D.tscn")
const TREE_SCENE := preload("res://scenes/resources/TreeNode3D.tscn")
const ROCK_SCENE := preload("res://scenes/resources/RockNode3D.tscn")
const BUSH_SCENE := preload("res://scenes/resources/BushNode3D.tscn")

var player_instance: CharacterBody3D
var zone_name := "Zone"
var current_zone: ZoneScene3D

@export var default_zone_size := Vector2(50, 50)
@export var enemy_count := 1
@export var resource_layout := []

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var players_container: Node3D = $Players
@onready var enemies_container: Node3D = $Enemies
@onready var resources_container: Node3D = $ResourceNodes
@onready var ground_mesh: MeshInstance3D = $GroundPlane
@onready var directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var environment_node: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	# Connect to GameState signals if available
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if game_state.has_signal("stats_changed"):
			game_state.stats_changed.connect(_on_stats_changed)
		if game_state.has_signal("zone_changed"):
			game_state.zone_changed.connect(_on_zone_changed)

func setup_from_zone(zone: ZoneScene3D) -> void:
	if not zone:
		push_warning("ZoneScene3D is missing, cannot build world")
		return
	
	current_zone = zone
	zone_name = zone.zone_name
	enemy_count = maxi(0, zone.enemy_count)
	resource_layout = zone.resource_layout.duplicate()
	
	# Setup ground
	_setup_ground(zone.zone_size, zone.ground_color, zone.ground_texture)
	
	# Setup lighting/environment
	_setup_environment(zone)
	
	# Reset and spawn entities
	_reset_existing_nodes()
	_spawn_player()
	_spawn_enemies()
	_spawn_resource_nodes()
	
	# Update game state
	if has_node("/root/GameState"):
		get_node("/root/GameState").update_zone(zone_name)

func _setup_ground(size: Vector2, color: Color, texture: Texture2D) -> void:
	if not ground_mesh:
		ground_mesh = MeshInstance3D.new()
		ground_mesh.name = "GroundPlane"
		add_child(ground_mesh)
	
	# Create plane mesh
	var plane = PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = 4
	plane.subdivide_depth = 4
	ground_mesh.mesh = plane
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	
	if texture:
		material.albedo_texture = texture
		material.uv1_scale = Vector3(size.x / 4, size.y / 4, 1)
	
	# Add some roughness for realistic look
	material.roughness = 0.9
	material.metallic = 0.0
	
	ground_mesh.material_override = material
	ground_mesh.create_trimesh_collision()

func _setup_environment(zone: ZoneScene3D) -> void:
	# Setup directional light (sun)
	if directional_light:
		directional_light.light_color = Color(1, 0.95, 0.9)
		directional_light.light_energy = 1.2
		directional_light.shadow_enabled = true
		directional_light.rotation_degrees = Vector3(-45, -30, 0)
	
	# Setup world environment
	if environment_node and environment_node.environment:
		var env = environment_node.environment
		
		# Ambient light
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = zone.ambient_light_color
		env.ambient_light_energy = zone.ambient_light_energy
		
		# Fog
		if zone.fog_enabled:
			env.fog_enabled = true
			env.fog_light_color = zone.fog_color
			env.fog_density = zone.fog_density
		else:
			env.fog_enabled = false
		
		# Sky
		env.background_mode = Environment.BG_SKY
		if not env.sky:
			var sky = Sky.new()
			var sky_material = ProceduralSkyMaterial.new()
			sky_material.sky_top_color = Color(0.4, 0.6, 0.9)
			sky_material.sky_horizon_color = Color(0.7, 0.8, 0.9)
			sky_material.ground_bottom_color = Color(0.2, 0.15, 0.1)
			sky_material.ground_horizon_color = Color(0.4, 0.35, 0.3)
			sky.sky_material = sky_material
			env.sky = sky

func _reset_existing_nodes() -> void:
	if player_instance and is_instance_valid(player_instance):
		player_instance.queue_free()
		player_instance = null
	
	_clear_container(players_container)
	_clear_container(enemies_container)
	_clear_container(resources_container)

func _clear_container(container: Node) -> void:
	if not container:
		return
	for child in container.get_children():
		child.queue_free()

func _spawn_player() -> void:
	player_instance = PLAYER_SCENE.instantiate()
	players_container.add_child(player_instance)
	
	# Set spawn position
	if spawn_point:
		player_instance.global_position = spawn_point.global_position
	else:
		player_instance.global_position = Vector3(0, 0.5, 0)
	
	# Ensure camera is active
	var camera = player_instance.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if camera:
		camera.make_current()

func _spawn_enemies() -> void:
	for i in range(maxi(1, enemy_count)):
		var enemy = ENEMY_SCENE.instantiate()
		enemies_container.add_child(enemy)
		
		# Position enemies around spawn point
		var angle = (i * TAU) / float(enemy_count)
		var distance = 15.0 + randf() * 10.0
		var offset = Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)
		
		if spawn_point:
			enemy.global_position = spawn_point.global_position + offset
		else:
			enemy.global_position = offset
		
		# Assign player as target
		if player_instance and enemy.has_method("assign_target"):
			enemy.assign_target(player_instance)

func _spawn_resource_nodes() -> void:
	for entry in resource_layout:
		if not entry or not entry.has("scene"):
			continue
		
		var scene_path = entry.scene
		var resource_scene: PackedScene
		
		# Map 2D scenes to 3D scenes
		if scene_path is String:
			match scene_path:
				"tree": resource_scene = TREE_SCENE
				"rock": resource_scene = ROCK_SCENE
				"bush": resource_scene = BUSH_SCENE
				_: continue
		elif scene_path is PackedScene:
			resource_scene = scene_path
		else:
			continue
		
		var instance = resource_scene.instantiate()
		resources_container.add_child(instance)
		
		# Convert 2D offset to 3D position
		var offset = entry.get("offset", Vector2.ZERO)
		var offset_3d = Vector3(offset.x * 0.1, 0, offset.y * 0.1)
		
		if spawn_point:
			instance.global_position = spawn_point.global_position + offset_3d
		else:
			instance.global_position = offset_3d

func spawn_resource_at(resource_type: String, position: Vector3) -> Node3D:
	var scene: PackedScene
	match resource_type:
		"tree": scene = TREE_SCENE
		"rock": scene = ROCK_SCENE
		"bush": scene = BUSH_SCENE
		_: return null
	
	var instance = scene.instantiate()
	resources_container.add_child(instance)
	instance.global_position = position
	return instance

func spawn_enemy_at(position: Vector3) -> Node3D:
	var enemy = ENEMY_SCENE.instantiate()
	enemies_container.add_child(enemy)
	enemy.global_position = position
	
	if player_instance and enemy.has_method("assign_target"):
		enemy.assign_target(player_instance)
	
	return enemy

func get_player() -> CharacterBody3D:
	return player_instance

func get_zone_bounds() -> AABB:
	if current_zone:
		return current_zone.get_zone_bounds()
	return AABB(Vector3(-25, 0, -25), Vector3(50, 10, 50))

func _on_stats_changed() -> void:
	pass  # Override in subclass

func _on_zone_changed(_new_zone: String) -> void:
	pass  # Override in subclass
