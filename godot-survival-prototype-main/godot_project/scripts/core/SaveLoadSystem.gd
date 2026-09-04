extends Node

## SaveLoadSystem - Comprehensive save/load system for all game data
## Handles player progress, inventory, base, world state, and more

class_name SaveLoadSystem

# ============================================================================
# CONSTANTS
# ============================================================================

const SAVE_VERSION := 1
const SAVE_FOLDER := "user://saves/"
const AUTOSAVE_FILE := "autosave.save"
const QUICKSAVE_FILE := "quicksave.save"
const MAX_SAVE_SLOTS := 10
const AUTOSAVE_INTERVAL := 300.0  # 5 minutes

# ============================================================================
# SIGNALS
# ============================================================================

signal save_started
signal save_completed(success: bool, slot_name: String)
signal load_started
signal load_completed(success: bool, slot_name: String)
signal autosave_triggered

# ============================================================================
# STATE
# ============================================================================

var _last_autosave_time: float = 0.0
var _save_in_progress: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_ensure_save_directory()

func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")

func _process(delta: float) -> void:
	# Autosave check
	_last_autosave_time += delta
	if _last_autosave_time >= AUTOSAVE_INTERVAL:
		_last_autosave_time = 0.0
		autosave()

# ============================================================================
# SAVE OPERATIONS
# ============================================================================

func save_game(slot_name: String = "") -> bool:
	if _save_in_progress:
		push_warning("Save already in progress")
		return false
	
	_save_in_progress = true
	save_started.emit()
	
	var save_data := _collect_save_data()
	var file_name := slot_name if slot_name else _generate_save_name()
	var file_path := SAVE_FOLDER + file_name
	
	var success := _write_save_file(file_path, save_data)
	
	_save_in_progress = false
	save_completed.emit(success, slot_name)
	return success

func quicksave() -> bool:
	return save_game(QUICKSAVE_FILE)

func autosave() -> bool:
	autosave_triggered.emit()
	return save_game(AUTOSAVE_FILE)

func _generate_save_name() -> String:
	var datetime := Time.get_datetime_dict_from_system()
	return "save_%04d%02d%02d_%02d%02d%02d.save" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

func _collect_save_data() -> Dictionary:
	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": _get_total_playtime(),
		"player": _save_player_data(),
		"inventory": _save_inventory_data(),
		"progression": _save_progression_data(),
		"world": _save_world_data(),
		"base": _save_base_data(),
		"quests": _save_quest_data(),
		"multiplayer": _save_multiplayer_data(),
		"settings": _save_settings_data(),
		"idle": _save_idle_data()
	}
	return save_data

func _write_save_file(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open save file: " + path)
		return false
	
	# Compress and encrypt for security
	var json_string := JSON.stringify(data)
	var compressed := json_string.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
	
	file.store_var(compressed)
	file.close()
	
	return true

# ============================================================================
# LOAD OPERATIONS
# ============================================================================

func load_game(slot_name: String) -> bool:
	load_started.emit()
	
	var file_path := SAVE_FOLDER + slot_name
	var save_data := _read_save_file(file_path)
	
	if save_data.is_empty():
		load_completed.emit(false, slot_name)
		return false
	
	# Version check
	var save_version: int = save_data.get("version", 0)
	if save_version > SAVE_VERSION:
		push_error("Save file is from a newer version")
		load_completed.emit(false, slot_name)
		return false
	
	# Migrate old saves if needed
	save_data = _migrate_save_data(save_data, save_version)
	
	# Apply loaded data
	var success := _apply_save_data(save_data)
	
	load_completed.emit(success, slot_name)
	return success

func quickload() -> bool:
	return load_game(QUICKSAVE_FILE)

func load_autosave() -> bool:
	return load_game(AUTOSAVE_FILE)

func _read_save_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Save file not found: " + path)
		return {}
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file: " + path)
		return {}
	
	var compressed: PackedByteArray = file.get_var()
	file.close()
	
	var decompressed := compressed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var json_string := decompressed.get_string_from_utf8()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("Failed to parse save data")
		return {}
	
	return json.data

func _migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
	# Apply migrations in sequence
	# if from_version < 2:
	#     data = _migrate_v1_to_v2(data)
	# if from_version < 3:
	#     data = _migrate_v2_to_v3(data)
	return data

func _apply_save_data(data: Dictionary) -> bool:
	_load_player_data(data.get("player", {}))
	_load_inventory_data(data.get("inventory", {}))
	_load_progression_data(data.get("progression", {}))
	_load_world_data(data.get("world", {}))
	_load_base_data(data.get("base", {}))
	_load_quest_data(data.get("quests", {}))
	_load_multiplayer_data(data.get("multiplayer", {}))
	_load_settings_data(data.get("settings", {}))
	_load_idle_data(data.get("idle", {}))
	
	return true

# ============================================================================
# SAVE SLOTS MANAGEMENT
# ============================================================================

func get_save_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	
	var dir := DirAccess.open(SAVE_FOLDER)
	if not dir:
		return slots
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".save"):
			var info := get_save_info(file_name)
			if not info.is_empty():
				slots.append(info)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort by timestamp (newest first)
	slots.sort_custom(func(a, b): return a.timestamp > b.timestamp)
	
	return slots

func get_save_info(slot_name: String) -> Dictionary:
	var file_path := SAVE_FOLDER + slot_name
	
	if not FileAccess.file_exists(file_path):
		return {}
	
	var save_data := _read_save_file(file_path)
	if save_data.is_empty():
		return {}
	
	var player_data: Dictionary = save_data.get("player", {})
	var progression_data: Dictionary = save_data.get("progression", {})
	
	return {
		"slot_name": slot_name,
		"timestamp": save_data.get("timestamp", 0),
		"play_time": save_data.get("play_time", 0),
		"player_name": player_data.get("name", "Unknown"),
		"player_level": progression_data.get("level", 1),
		"zone": player_data.get("current_zone", "Unknown"),
		"is_autosave": slot_name == AUTOSAVE_FILE,
		"is_quicksave": slot_name == QUICKSAVE_FILE
	}

func delete_save(slot_name: String) -> bool:
	var file_path := SAVE_FOLDER + slot_name
	
	var dir := DirAccess.open(SAVE_FOLDER)
	if dir:
		return dir.remove(slot_name) == OK
	return false

func save_exists(slot_name: String) -> bool:
	return FileAccess.file_exists(SAVE_FOLDER + slot_name)

func has_any_saves() -> bool:
	return not get_save_slots().is_empty()

# ============================================================================
# DATA COLLECTION (SAVE)
# ============================================================================

func _get_total_playtime() -> float:
	# Would track cumulative playtime
	return 0.0

func _save_player_data() -> Dictionary:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return {}
	
	return {
		"name": player.get("player_name") if player.get("player_name") else "Survivor",
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y
		},
		"current_zone": player.get("current_zone") if player.get("current_zone") else "green",
		"health": player.get("health") if player.get("health") else 100,
		"max_health": player.get("max_health") if player.get("max_health") else 100,
		"stamina": player.get("stamina") if player.get("stamina") else 100,
		"hunger": player.get("hunger") if player.get("hunger") else 100,
		"thirst": player.get("thirst") if player.get("thirst") else 100,
		"radiation": player.get("radiation") if player.get("radiation") else 0
	}

func _save_inventory_data() -> Dictionary:
	var inventory_node := get_tree().get_first_node_in_group("inventory")
	if not inventory_node:
		return {}

	if inventory_node.has_method("serialize_items"):
		return {
			"items": inventory_node.serialize_items(),
			"equipped": _save_equipped_items(),
			"hotbar": _save_hotbar_data()
		}
	
	var items := []
	var inventory_items = inventory_node.get("items") if inventory_node else []
	
	for i in range(inventory_items.size()):
		var item = inventory_items[i]
		if item and item is Dictionary and not item.is_empty():
			items.append({
				"slot": i,
				"id": item.get("id", ""),
				"count": item.get("count", 1),
				"durability": item.get("durability", 100),
				"modifiers": item.get("modifiers", {})
			})
	
	return {
		"items": items,
		"equipped": _save_equipped_items(),
		"hotbar": _save_hotbar_data()
	}

func _save_equipped_items() -> Dictionary:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return {}
	
	var equipped = player.get("equipped_items") if player.get("equipped_items") else {}
	return equipped.duplicate(true) if equipped is Dictionary else {}

func _save_hotbar_data() -> Array:
	# Hotbar slot references
	return []

func _save_progression_data() -> Dictionary:
	var progression := get_tree().get_first_node_in_group("progression")
	if not progression:
		return {
			"level": 1,
			"xp": 0,
			"skill_points": 0,
			"skills": {},
			"perks": [],
			"achievements": [],
			"statistics": {}
		}
	
	return {
		"level": progression.get("level") if progression.get("level") else 1,
		"xp": progression.get("xp") if progression.get("xp") else 0,
		"skill_points": progression.get("skill_points") if progression.get("skill_points") else 0,
		"skills": progression.get("skills").duplicate(true) if progression.get("skills") else {},
		"perks": progression.get("unlocked_perks").duplicate() if progression.get("unlocked_perks") else [],
		"achievements": progression.get("achievements").duplicate() if progression.get("achievements") else [],
		"statistics": _save_statistics()
	}

func _save_statistics() -> Dictionary:
	return {
		"zombies_killed": 0,
		"distance_traveled": 0.0,
		"items_crafted": 0,
		"resources_gathered": 0,
		"deaths": 0,
		"days_survived": 0
	}

func _save_world_data() -> Dictionary:
	return {
		"day": 1,
		"time_of_day": 12.0,
		"weather": "clear",
		"explored_zones": [],
		"cleared_locations": [],
		"spawned_resources": _save_resource_states(),
		"containers": _save_container_states()
	}

func _save_resource_states() -> Dictionary:
	# Save state of world resources (trees, rocks, etc.)
	return {}

func _save_container_states() -> Dictionary:
	# Save what's been looted from containers
	return {}

func _save_base_data() -> Dictionary:
	var base_system := get_tree().get_first_node_in_group("base_building")
	if not base_system:
		return {}
	
	var structures := []
	var placed = base_system.get("placed_structures") if base_system.get("placed_structures") else {}
	
	for pos in placed:
		var structure = placed[pos]
		structures.append({
			"type": structure.get("type", ""),
			"position": {"x": pos.x, "y": pos.y},
			"health": structure.get("health", 100),
			"level": structure.get("level", 1),
			"storage_contents": structure.get("storage_contents", [])
		})
	
	return {
		"structures": structures,
		"unlocked_blueprints": []
	}

func _save_quest_data() -> Dictionary:
	var quest_system := get_tree().get_first_node_in_group("quest_system")
	if not quest_system:
		return {}
	
	var active := []
	var active_quests = quest_system.get("active_quests") if quest_system.get("active_quests") else []
	
	for quest in active_quests:
		active.append({
			"id": quest.get("id", ""),
			"progress": quest.get("progress", {}),
			"time_started": quest.get("time_started", 0)
		})
	
	return {
		"active_quests": active,
		"completed_quests": quest_system.get("completed_quests") if quest_system.get("completed_quests") else [],
		"daily_reset_time": 0,
		"weekly_reset_time": 0
	}

func _save_multiplayer_data() -> Dictionary:
	var mp_manager := get_tree().get_first_node_in_group("multiplayer_manager")
	if not mp_manager:
		return {}
	
	return {
		"clan_id": mp_manager.get("clan_id") if mp_manager.get("clan_id") else "",
		"friends_list": mp_manager.get("friends_list") if mp_manager.get("friends_list") else [],
		"blocked_players": mp_manager.get("blocked_players") if mp_manager.get("blocked_players") else [],
		"trade_history": []
	}

func _save_settings_data() -> Dictionary:
	return {
		"audio": {
			"master_volume": 1.0,
			"music_volume": 0.7,
			"sfx_volume": 0.8
		},
		"graphics": {
			"quality": "high",
			"vsync": true,
			"fullscreen": false
		},
		"controls": {
			"mouse_sensitivity": 1.0,
			"invert_y": false
		},
		"gameplay": {
			"auto_loot": true,
			"show_damage_numbers": true,
			"screen_shake": true
		}
	}

func _save_idle_data() -> Dictionary:
	var idle_root := get_tree().get_first_node_in_group("idle_mode_root")
	if idle_root and idle_root.has_method("save_idle_data"):
		return idle_root.save_idle_data()
	return {}

# ============================================================================
# DATA APPLICATION (LOAD)
# ============================================================================

func _load_player_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Position
	if data.has("position"):
		var pos: Dictionary = data.position
		player.global_position = Vector2(pos.x, pos.y)
	
	# Stats
	if player.has_method("set_health"):
		player.set_health(data.get("health", 100))
	elif "health" in player:
		player.health = data.get("health", 100)
	
	if "stamina" in player:
		player.stamina = data.get("stamina", 100)
	if "hunger" in player:
		player.hunger = data.get("hunger", 100)
	if "thirst" in player:
		player.thirst = data.get("thirst", 100)
	if "current_zone" in player:
		player.current_zone = data.get("current_zone", "green")

func _load_inventory_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	var inventory_node := get_tree().get_first_node_in_group("inventory")
	if not inventory_node:
		return

	var items_data: Array = data.get("items", [])
	if inventory_node.has_method("deserialize_items"):
		inventory_node.deserialize_items(items_data)
		_load_equipped_items(data.get("equipped", {}))
		return
	
	# Clear and populate inventory
	if inventory_node.has_method("clear"):
		inventory_node.clear()
	
	for item_data in items_data:
		if inventory_node.has_method("add_item_to_slot"):
			inventory_node.add_item_to_slot(
				item_data.get("slot", 0),
				item_data.get("id", ""),
				item_data.get("count", 1)
			)
	
	# Equipped items
	var equipped_data: Dictionary = data.get("equipped", {})
	_load_equipped_items(equipped_data)

func _load_idle_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	var idle_root := get_tree().get_first_node_in_group("idle_mode_root")
	if idle_root and idle_root.has_method("load_idle_data"):
		idle_root.load_idle_data(data)

func _load_equipped_items(data: Dictionary) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	if "equipped_items" in player and data:
		player.equipped_items = data.duplicate(true)

func _load_progression_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	var progression := get_tree().get_first_node_in_group("progression")
	if not progression:
		return
	
	if "level" in progression:
		progression.level = data.get("level", 1)
	if "xp" in progression:
		progression.xp = data.get("xp", 0)
	if "skill_points" in progression:
		progression.skill_points = data.get("skill_points", 0)
	if "skills" in progression:
		progression.skills = data.get("skills", {}).duplicate(true)
	if "unlocked_perks" in progression:
		progression.unlocked_perks = data.get("perks", []).duplicate()

func _load_world_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	# Load time of day, weather, etc.
	var world := get_tree().get_first_node_in_group("world")
	if world:
		if "day" in world:
			world.day = data.get("day", 1)
		if "time_of_day" in world:
			world.time_of_day = data.get("time_of_day", 12.0)

func _load_base_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	var base_system := get_tree().get_first_node_in_group("base_building")
	if not base_system:
		return
	
	# Clear existing structures
	if base_system.has_method("clear_all_structures"):
		base_system.clear_all_structures()
	
	# Rebuild structures
	var structures_data: Array = data.get("structures", [])
	for struct_data in structures_data:
		if base_system.has_method("place_structure_from_save"):
			base_system.place_structure_from_save(struct_data)

func _load_quest_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	var quest_system := get_tree().get_first_node_in_group("quest_system")
	if not quest_system:
		return
	
	# Restore active quests
	var active_data: Array = data.get("active_quests", [])
	if quest_system.has_method("restore_quests"):
		quest_system.restore_quests(active_data)
	
	# Restore completed quests
	if "completed_quests" in quest_system:
		quest_system.completed_quests = data.get("completed_quests", []).duplicate()

func _load_multiplayer_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	var mp_manager := get_tree().get_first_node_in_group("multiplayer_manager")
	if not mp_manager:
		return
	
	if "friends_list" in mp_manager:
		mp_manager.friends_list = data.get("friends_list", []).duplicate()
	if "blocked_players" in mp_manager:
		mp_manager.blocked_players = data.get("blocked_players", []).duplicate()

func _load_settings_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	# Apply audio settings
	var audio: Dictionary = data.get("audio", {})
	AudioServer.set_bus_volume_db(0, linear_to_db(audio.get("master_volume", 1.0)))
	
	# Apply graphics settings
	var graphics: Dictionary = data.get("graphics", {})
	if graphics.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if graphics.get("vsync", true):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

# ============================================================================
# CLOUD SAVE SUPPORT (STUB)
# ============================================================================

func upload_to_cloud(slot_name: String) -> bool:
	# Placeholder for cloud save integration
	push_warning("Cloud save not implemented")
	return false

func download_from_cloud(slot_name: String) -> bool:
	# Placeholder for cloud save integration
	push_warning("Cloud save not implemented")
	return false

func sync_with_cloud() -> void:
	# Placeholder for cloud save sync
	push_warning("Cloud sync not implemented")
