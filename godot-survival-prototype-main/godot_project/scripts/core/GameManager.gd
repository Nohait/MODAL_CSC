extends Node
## GameManager autoload - manages scene transitions, persistent inventory, and save/load

signal scene_changing(destination: String)
signal scene_changed(location: String)

# Static singleton instance
static var instance: GameManager = null

# Current state
var current_location := "home"  # "home", "green_zone", "yellow_zone", "red_zone"
var player_inventory: Array = []  # Persists across scenes
var storage_contents: Array = []  # Home base storage

# Transition overlay
var _transition_overlay: ColorRect
var _canvas_layer: CanvasLayer

const SAVE_PATH := "user://save_data.json"

func _ready() -> void:
	instance = self
	_setup_transition_overlay()
	load_game()
	print("[GameManager] Ready - Location: ", current_location)


func _setup_transition_overlay() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	
	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color(0, 0, 0, 0)
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_canvas_layer.add_child(_transition_overlay)
	add_child(_canvas_layer)


func travel_to(destination: String) -> void:
	scene_changing.emit(destination)
	
	# Fade out
	var tween := create_tween()
	tween.tween_property(_transition_overlay, "color:a", 1.0, 0.3)
	await tween.finished
	
	# Change scene
	current_location = destination
	var scene_path := _get_scene_path(destination)
	
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
		# Wait for scene to load
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Fade in
		tween = create_tween()
		tween.tween_property(_transition_overlay, "color:a", 0.0, 0.3)
		
		scene_changed.emit(destination)
		save_game()  # Auto-save on travel
	else:
		push_error("[GameManager] Scene not found: " + scene_path)
		# Fade back in
		tween = create_tween()
		tween.tween_property(_transition_overlay, "color:a", 0.0, 0.3)


func return_home() -> void:
	travel_to("home")


func _get_scene_path(destination: String) -> String:
	match destination:
		"home":
			return "res://scenes/zones/HomeBase.tscn"
		"green_zone":
			return "res://scenes/zones/GreenZone3D.tscn"
		"yellow_zone":
			return "res://scenes/zones/YellowZone3D.tscn"
		"red_zone":
			return "res://scenes/zones/RedZone3D.tscn"
	return "res://scenes/zones/HomeBase.tscn"


# --------------------------------------------------------------------------
# Inventory Management
# --------------------------------------------------------------------------

func add_to_inventory(item: Dictionary) -> bool:
	# Check for stackable items
	for i in range(player_inventory.size()):
		var existing = player_inventory[i]
		if existing.get("id") == item.get("id") and existing.get("stackable", false):
			existing["count"] = existing.get("count", 1) + item.get("count", 1)
			return true
	
	# Add as new item
	player_inventory.append(item.duplicate())
	return true


func remove_from_inventory(index: int) -> Dictionary:
	if index >= 0 and index < player_inventory.size():
		return player_inventory.pop_at(index)
	return {}


func transfer_to_storage(inventory_index: int) -> void:
	if inventory_index >= 0 and inventory_index < player_inventory.size():
		var item = player_inventory.pop_at(inventory_index)
		storage_contents.append(item)


func transfer_from_storage(storage_index: int) -> void:
	if storage_index >= 0 and storage_index < storage_contents.size():
		var item = storage_contents.pop_at(storage_index)
		player_inventory.append(item)


# --------------------------------------------------------------------------
# Save/Load
# --------------------------------------------------------------------------

func save_game() -> void:
	var data := {
		"version": 1,
		"player_inventory": player_inventory,
		"storage_contents": storage_contents,
		"current_location": current_location
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		print("[GameManager] Game saved")
	else:
		push_error("[GameManager] Failed to save game")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[GameManager] No save file found, starting fresh")
		# Add some starter items
		_add_starter_items()
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_text := file.get_as_text()
		var data = JSON.parse_string(json_text)
		if data:
			player_inventory = data.get("player_inventory", [])
			storage_contents = data.get("storage_contents", [])
			# Don't load location - always start at home
			print("[GameManager] Game loaded - Inventory: %d items, Storage: %d items" % [player_inventory.size(), storage_contents.size()])
		else:
			push_error("[GameManager] Failed to parse save file")
			_add_starter_items()
	else:
		push_error("[GameManager] Failed to open save file")
		_add_starter_items()


func _add_starter_items() -> void:
	# Give player some starter resources
	player_inventory = [
		{"id": "wood", "name": "Wood", "count": 10, "stackable": true, "icon": "wood"},
		{"id": "stone", "name": "Stone", "count": 5, "stackable": true, "icon": "stone"},
	]


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		player_inventory.clear()
		storage_contents.clear()
		current_location = "home"
		print("[GameManager] Save deleted")
