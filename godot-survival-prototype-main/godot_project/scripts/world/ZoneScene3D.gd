extends Node3D

class_name ZoneScene3D

## Zone configuration
@export var zone_name: String = "Zone"
@export var zone_difficulty: int = 1  # 1=Green, 2=Yellow, 3=Red
@export var enemy_count: int = 1
@export var resource_layout: Array = []

## Terrain configuration
@export var zone_size: Vector2 = Vector2(50, 50)  # World units
@export var ground_texture: Texture2D
@export var ground_color: Color = Color(0.4, 0.6, 0.3)
@export var ambient_light_color: Color = Color(1, 1, 1)
@export var ambient_light_energy: float = 0.5

## Environment settings
@export var fog_enabled: bool = false
@export var fog_color: Color = Color(0.5, 0.5, 0.5)
@export var fog_density: float = 0.01

## Scene references (3D versions)
const TREE_3D := preload("res://scenes/resources/TreeNode3D.tscn")
const ROCK_3D := preload("res://scenes/resources/RockNode3D.tscn")
const BUSH_3D := preload("res://scenes/resources/BushNode3D.tscn")

func get_ground_plane() -> MeshInstance3D:
	return get_node_or_null("GroundPlane") as MeshInstance3D

func get_spawn_point() -> Marker3D:
	return get_node_or_null("SpawnPoint") as Marker3D

func get_zone_bounds() -> AABB:
	return AABB(
		Vector3(-zone_size.x / 2, 0, -zone_size.y / 2),
		Vector3(zone_size.x, 10, zone_size.y)
	)
