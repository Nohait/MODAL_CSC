extends Node

## ZoneManager - Handles zone loading/unloading and transitions
## Autoload singleton for managing game zones

signal zone_changed(zone_key: String)
signal zone_loading(zone_key: String)
signal zone_loaded(zone_key: String)

# Zone definitions - paths relative to scenes folder
const ZONE_SCENES := {
	"green": "res://scenes/zones/GreenZone.tscn",
	"yellow": "res://scenes/zones/YellowZone.tscn",
	"red": "res://scenes/zones/RedZone.tscn",
}

const ZONE_DATA := {
	"green": {
		"name": "Green Zone",
		"difficulty": 1,
		"energy_cost": 0,
		"description": "Safe starting area with basic resources"
	},
	"yellow": {
		"name": "Yellow Zone",
		"difficulty": 2,
		"energy_cost": 5,
		"description": "Moderate danger with better loot"
	},
	"red": {
		"name": "Red Zone",
		"difficulty": 3,
		"energy_cost": 10,
		"description": "High danger area with rare resources"
	}
}

var current_zone_key := ""
var current_zone_node: Node = null
var zone_holder: Node = null
var is_transitioning := false

# Cached loaded scenes
var _scene_cache: Dictionary = {}

func _ready() -> void:
	add_to_group("zone_manager")

func set_zone_holder(holder: Node) -> void:
	zone_holder = holder

func get_current_zone() -> String:
	return current_zone_key

func get_zone_data(zone_key: String) -> Dictionary:
	return ZONE_DATA.get(zone_key.to_lower(), {})

func get_zone_difficulty() -> int:
	var data := get_zone_data(current_zone_key)
	return data.get("difficulty", 1)

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
		_transition_to_zone(zone_key)

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
	
	# Load new zone
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
	
	current_zone_node = scene.instantiate()
	
	if zone_holder:
		zone_holder.add_child(current_zone_node)
	else:
		get_tree().current_scene.add_child(current_zone_node)
	
	current_zone_key = zone_key
	
	zone_changed.emit(zone_key)
	zone_loaded.emit(zone_key)

func preload_zone(zone_key: String) -> void:
	zone_key = zone_key.to_lower()
	if not ZONE_SCENES.has(zone_key):
		return
	if _scene_cache.has(zone_key):
		return
	
	var scene_path: String = ZONE_SCENES[zone_key]
	_scene_cache[zone_key] = load(scene_path)

func unload_cached_zones() -> void:
	_scene_cache.clear()

func get_available_zones() -> Array[String]:
	var zones: Array[String] = []
	for key in ZONE_SCENES.keys():
		zones.append(key)
	return zones
