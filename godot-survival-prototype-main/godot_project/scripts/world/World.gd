extends Node2D

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
var tilemap: TileMap
var player_instance: CharacterBody2D
var zone_name := "Zone"

@export var map_size := Vector2i(12, 12)
@export var tile_size := Vector2(32, 32)
@export var enemy_count := 1
@export var resource_layout := []

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var players_container: Node2D = $Players
@onready var enemies_container: Node2D = $Enemies
@onready var resources_container: Node2D = $ResourceNodes

func _ready() -> void:
    GameState.stats_changed.connect(_on_stats_changed)
    GameState.zone_changed.connect(_on_zone_changed)

func setup_from_zone(zone: ZoneScene) -> void:
    if not zone:
        push_warning("ZoneScene is missing, cannot build world")
        return
    tilemap = zone.get_ground_map()
    var tile_map_size = zone.map_size
    var cell_size = zone.tile_size
    _setup_tilemap(zone.ground_texture, tile_map_size, cell_size, zone.tile_tint)
    enemy_count = max(0, zone.enemy_count)
    resource_layout = []
    for entry in zone.resource_layout:
        resource_layout.append(entry)
    zone_name = zone.zone_name
    _reset_existing_nodes()
    _spawn_player()
    _spawn_enemies()
    _spawn_resource_nodes()
    GameState.update_zone(zone_name)

func _reset_existing_nodes() -> void:
    if player_instance:
        player_instance.queue_free()
        player_instance = null
    _clear_container(players_container)
    _clear_container(enemies_container)
    _clear_container(resources_container)

func _clear_container(container: Node) -> void:
    for child in container.get_children():
        child.queue_free()

func _setup_tilemap(texture: Texture2D, size: Vector2i, cell_size: Vector2, tint: Color) -> void:
    if not tilemap:
        push_warning("Missing GroundMap node in zone to paint tiles")
        return
    var used_size = size if size != Vector2i.ZERO else map_size
    var used_tile_size = cell_size if cell_size != Vector2.ZERO else tile_size
    tilemap.cell_size = used_tile_size
    tilemap.modulate = tint
    tilemap.z_index = -10
    tilemap.centered_textures = true
    tilemap.tile_set = _build_tile_set(texture, used_tile_size)
    tilemap.clear()
    for x in range(used_size.x):
        for y in range(used_size.y):
            tilemap.set_cellv(Vector2i(x, y), 0)

func _build_tile_set(texture: Texture2D, cell_size: Vector2) -> TileSet:
    var tile_set = TileSet.new()
    if texture:
        var atlas_source = TileSetAtlasSource.new()
        atlas_source.set_texture(texture)
        atlas_source.set_texture_region_size(Vector2i(int(cell_size.x), int(cell_size.y)))
        atlas_source.set_margins(Vector2i.ZERO)
        atlas_source.set_separation(Vector2i.ZERO)
        tile_set.add_source(atlas_source)
    return tile_set

func _spawn_player() -> void:
    player_instance = PLAYER_SCENE.instantiate()
    players_container.add_child(player_instance)
    player_instance.global_position = spawn_point.global_position
    var camera = player_instance.get_node_or_null("Camera2D")
    if camera:
        camera.make_current()

func _spawn_enemies() -> void:
    for i in range(max(1, enemy_count)):
        var enemy = ENEMY_SCENE.instantiate()
        enemies_container.add_child(enemy)
        var offset = Vector2(120 + i * 40, -60 - i * 20)
        enemy.global_position = spawn_point.global_position + offset
        if player_instance:
            enemy.assign_target(player_instance)

func _spawn_resource_nodes() -> void:
    for entry in resource_layout:
        if not entry or not entry.has("scene"):
            continue
        var node = entry.scene.instantiate()
        resources_container.add_child(node)
        var offset = entry.offset if entry.has("offset") else Vector2.ZERO
        node.global_position = spawn_point.global_position + offset

func _on_stats_changed(health: float, stamina: float) -> void:
    print("Stats -> Health: %0.1f Stamina: %0.1f" % [health, stamina])

func _on_zone_changed(zone_name: String) -> void:
    print("Entered zone:", zone_name)
