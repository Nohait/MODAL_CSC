extends Node

## ZoneManager3D - Handles 3D zone loading/unloading and transitions
## Manages zone switching for 3D world

class_name ZoneManager3D

signal zone_changed(zone_key: String)
signal zone_loading(zone_key: String)
signal zone_loaded(zone_key: String)

# Zone definitions - 3D versions
const ZONE_SCENES := {
	"green": "res://scenes/zones/GreenZone3D.tscn",
	"yellow": "res://scenes/zones/YellowZone3D.tscn",
	"red": "res://scenes/zones/RedZone3D.tscn",
}

const ZONE_DATA := {
	"green": {
		"name": "Green Zone",
		"difficulty": 1,
		"energy_cost": 0,
		"description": "Safe starting area with basic resources",
		"enemy_types": ["zombie_walker"],
		"resource_multiplier": 1.0,
	},
	"yellow": {
		"name": "Yellow Zone",
		"difficulty": 2,
		"energy_cost": 5,
		"description": "Moderate danger with better loot",
		"enemy_types": ["zombie_walker", "zombie_runner"],
		"resource_multiplier": 1.5,
	},
	"red": {
		"name": "Red Zone",
		"difficulty": 3,
		"energy_cost": 10,
		"description": "High danger area with rare resources",
		"enemy_types": ["zombie_walker", "zombie_runner", "zombie_bloater"],
		"resource_multiplier": 2.0,
	}
}

var current_zone_key := ""
var current_zone_node: ZoneScene3D = null
var world_node: Node3D = null
var zone_holder: Node3D = null
var is_transitioning := false

# Cached loaded scenes
var _scene_cache: Dictionary = {}

func _ready() -> void:
	add_to_group("zone_manager")

func set_world(world: Node3D) -> void:
	world_node = world

func set_zone_holder(holder: Node3D) -> void:
	zone_holder = holder

func get_current_zone() -> String:
	return current_zone_key

func get_current_zone_node() -> ZoneScene3D:
	return current_zone_node

func get_zone_data(zone_key: String) -> Dictionary:
	return ZONE_DATA.get(zone_key.to_lower(), {})

func get_zone_difficulty() -> int:
	var data := get_zone_data(current_zone_key)
	return data.get("difficulty", 1)

func get_available_zones() -> Array:
	return ZONE_DATA.keys()

func can_enter_zone(zone_key: String) -> bool:
	var data := get_zone_data(zone_key)
	var energy_cost = data.get("energy_cost", 0)
	
	# Check player energy (if GameState exists)
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if game_state.has_method("get_energy"):
			return game_state.get_energy() >= energy_cost
	
	return true

func load_zone(zone_key: String, instant := false) -> void:
	zone_key = zone_key.to_lower()
	
	if not ZONE_SCENES.has(zone_key):
		push_error("Unknown zone: " + zone_key)
		return
	
	if zone_key == current_zone_key and current_zone_node:
		return
	
	if is_transitioning:
		return
	
	zone_loading.emit(zone_key)
	
	if instant:
		_swap_zone(zone_key)
	else:
		await _transition_to_zone(zone_key)

func _transition_to_zone(zone_key: String) -> void:
	is_transitioning = true
	
	# Fade out (handled by UI if available)
	var ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if ui_manager and ui_manager.has_method("show_loading_screen"):
		ui_manager.show_loading_screen()
	
	# Wait a frame then swap
	await get_tree().create_timer(0.3).timeout
	_swap_zone(zone_key)
	await get_tree().create_timer(0.2).timeout
	
	if ui_manager and ui_manager.has_method("hide_loading_screen"):
		ui_manager.hide_loading_screen()
	
	is_transitioning = false

func _swap_zone(zone_key: String) -> void:
	# Unload current zone
	if current_zone_node and is_instance_valid(current_zone_node):
		current_zone_node.queue_free()
		current_zone_node = null
	
	# Load new zone scene
	var scene_path: String = ZONE_SCENES[zone_key]
	var scene: PackedScene
	
	if _scene_cache.has(zone_key):
		scene = _scene_cache[zone_key]
	else:
		scene = load(scene_path)
		_scene_cache[zone_key] = scene
	
	if not scene:
		push_error("Failed to load zone scene: " + scene_path)
		return
	
	# Instantiate zone
	current_zone_node = scene.instantiate() as ZoneScene3D
	
	if zone_holder:
		zone_holder.add_child(current_zone_node)
	else:
		add_child(current_zone_node)
	
	current_zone_key = zone_key
	
	# Setup world with zone data
	if world_node and world_node.has_method("setup_from_zone"):
		world_node.setup_from_zone(current_zone_node)
	
	# Deduct energy cost
	var data := get_zone_data(zone_key)
	var energy_cost = data.get("energy_cost", 0)
	if energy_cost > 0 and has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if game_state.has_method("use_energy"):
			game_state.use_energy(energy_cost)
	
	zone_changed.emit(zone_key)
	zone_loaded.emit(zone_key)
	
	print("[ZoneManager3D] Loaded zone: %s" % zone_key)

func reload_current_zone() -> void:
	if current_zone_key.is_empty():
		load_zone("green")
	else:
		var temp_key = current_zone_key
		current_zone_key = ""
		load_zone(temp_key)

func get_random_spawn_position() -> Vector3:
	if current_zone_node:
		var bounds = current_zone_node.get_zone_bounds()
		return Vector3(
			randf_range(bounds.position.x + 5, bounds.end.x - 5),
			0.5,
			randf_range(bounds.position.z + 5, bounds.end.z - 5)
		)
	return Vector3.ZERO
