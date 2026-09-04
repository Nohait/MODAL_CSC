extends Node2D

class_name ZoneScene

@export var zone_name: String = "Zone"
@export var enemy_count: int = 1
@export var resource_layout: Array = []
@export var map_size: Vector2i = Vector2i(14, 14)
@export var tile_size: Vector2 = Vector2(32, 32)
@export var ground_texture: Texture2D
@export var tile_tint: Color = Color(1, 1, 1, 1)
@export var tile_variation: int = 0

func get_ground_map() -> TileMap:
    return get_node_or_null("GroundMap") as TileMap
