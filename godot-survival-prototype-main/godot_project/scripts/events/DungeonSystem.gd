extends Node
class_name DungeonSystemClass
## Manages procedural dungeons, bunkers, and instanced content
## Handles floor generation, enemy placement, loot, and bosses

signal dungeon_entered(dungeon_data: Dictionary)
signal dungeon_exited(completed: bool, rewards: Dictionary)
signal floor_changed(floor_number: int, floor_data: Dictionary)
signal room_entered(room_data: Dictionary)
signal room_cleared(room_id: String)
signal chest_opened(chest_data: Dictionary)
signal boss_spawned(boss_data: Dictionary)
signal boss_defeated(boss_data: Dictionary)
signal dungeon_timer_warning(time_remaining: float)

# ============================================================================
# DUNGEON CONFIGURATION
# ============================================================================

enum DungeonType {
	BUNKER,             # Military bunker
	SEWER,              # Underground sewers
	HOSPITAL,           # Abandoned hospital
	POLICE_STATION,     # Police HQ
	MILITARY_BASE,      # Military compound
	LABORATORY,         # Research lab
	FACTORY,            # Industrial facility
	MALL,               # Shopping center
	PRISON,             # Prison complex
	VAULT,              # Underground vault
	SUBWAY,             # Metro tunnels
	MINE,               # Abandoned mine
}

enum RoomType {
	ENTRANCE,
	CORRIDOR,
	SMALL_ROOM,
	MEDIUM_ROOM,
	LARGE_ROOM,
	STORAGE,
	ARMORY,
	MEDICAL,
	LABORATORY,
	OFFICE,
	GENERATOR_ROOM,
	CAFETERIA,
	CELL_BLOCK,
	BOSS_ROOM,
	TREASURE_ROOM,
	SAFE_ROOM,
	EXIT,
}

enum DungeonDifficulty {
	EASY,
	NORMAL,
	HARD,
	NIGHTMARE,
	HELL,
}

const DUNGEON_DEFINITIONS := {
	DungeonType.BUNKER: {
		"display_name": "Military Bunker",
		"description": "An abandoned military bunker with valuable supplies.",
		"min_level": 5,
		"floors": {"min": 3, "max": 5},
		"rooms_per_floor": {"min": 6, "max": 10},
		"enemy_types": ["soldier_zombie", "zombie_armored", "zombie_walker"],
		"loot_table": "military_bunker",
		"boss": "bunker_commander",
		"time_limit": 1800,  # 30 minutes
		"environment": "bunker",
		"hazards": ["radiation", "security_turrets"],
	},
	DungeonType.SEWER: {
		"display_name": "Sewer Network",
		"description": "Dark tunnels infested with mutants.",
		"min_level": 3,
		"floors": {"min": 2, "max": 4},
		"rooms_per_floor": {"min": 8, "max": 12},
		"enemy_types": ["zombie_crawler", "zombie_bloater", "mutant_rat"],
		"loot_table": "sewer",
		"boss": "sewer_beast",
		"time_limit": 1200,
		"environment": "sewer",
		"hazards": ["toxic_water", "gas_pockets"],
	},
	DungeonType.HOSPITAL: {
		"display_name": "Abandoned Hospital",
		"description": "Medical supplies and infected patients.",
		"min_level": 8,
		"floors": {"min": 4, "max": 6},
		"rooms_per_floor": {"min": 8, "max": 14},
		"enemy_types": ["zombie_nurse", "zombie_doctor", "zombie_patient", "zombie_crawler"],
		"loot_table": "hospital",
		"boss": "the_surgeon",
		"time_limit": 2400,
		"environment": "hospital",
		"hazards": ["darkness", "biohazard"],
	},
	DungeonType.POLICE_STATION: {
		"display_name": "Police Station",
		"description": "Weapons cache and armored zombies.",
		"min_level": 6,
		"floors": {"min": 2, "max": 3},
		"rooms_per_floor": {"min": 10, "max": 15},
		"enemy_types": ["zombie_cop", "zombie_swat", "zombie_prisoner"],
		"loot_table": "police",
		"boss": "riot_chief",
		"time_limit": 1500,
		"environment": "police",
		"hazards": ["locked_cells", "alarms"],
	},
	DungeonType.MILITARY_BASE: {
		"display_name": "Military Base",
		"description": "Heavy military presence with top-tier loot.",
		"min_level": 15,
		"floors": {"min": 4, "max": 7},
		"rooms_per_floor": {"min": 10, "max": 16},
		"enemy_types": ["soldier_zombie", "zombie_armored", "zombie_heavy", "turret"],
		"loot_table": "military_base",
		"boss": "infected_general",
		"time_limit": 3000,
		"environment": "military",
		"hazards": ["turrets", "landmines", "radiation"],
	},
	DungeonType.LABORATORY: {
		"display_name": "Research Laboratory",
		"description": "Experimental horrors and rare blueprints.",
		"min_level": 12,
		"floors": {"min": 5, "max": 8},
		"rooms_per_floor": {"min": 8, "max": 12},
		"enemy_types": ["zombie_scientist", "mutant_experiment", "zombie_irradiated"],
		"loot_table": "laboratory",
		"boss": "experiment_zero",
		"time_limit": 2700,
		"environment": "lab",
		"hazards": ["acid", "radiation", "lockdown"],
	},
	DungeonType.FACTORY: {
		"display_name": "Industrial Factory",
		"description": "Machinery and worker zombies.",
		"min_level": 7,
		"floors": {"min": 2, "max": 4},
		"rooms_per_floor": {"min": 12, "max": 18},
		"enemy_types": ["zombie_worker", "zombie_brute", "zombie_walker"],
		"loot_table": "factory",
		"boss": "foreman",
		"time_limit": 1800,
		"environment": "factory",
		"hazards": ["machinery", "fire"],
	},
	DungeonType.MALL: {
		"display_name": "Shopping Mall",
		"description": "Massive horde territory with scattered loot.",
		"min_level": 4,
		"floors": {"min": 2, "max": 3},
		"rooms_per_floor": {"min": 15, "max": 25},
		"enemy_types": ["zombie_walker", "zombie_runner", "zombie_shopper"],
		"loot_table": "mall",
		"boss": "mall_alpha",
		"time_limit": 2100,
		"environment": "mall",
		"hazards": ["glass", "escalators"],
	},
	DungeonType.PRISON: {
		"display_name": "Maximum Security Prison",
		"description": "Dangerous inmates turned deadly zombies.",
		"min_level": 10,
		"floors": {"min": 3, "max": 5},
		"rooms_per_floor": {"min": 12, "max": 20},
		"enemy_types": ["zombie_prisoner", "zombie_guard", "zombie_brute"],
		"loot_table": "prison",
		"boss": "warden",
		"time_limit": 2400,
		"environment": "prison",
		"hazards": ["locked_doors", "solitary"],
	},
	DungeonType.VAULT: {
		"display_name": "Underground Vault",
		"description": "Sealed vault with legendary loot.",
		"min_level": 20,
		"floors": {"min": 6, "max": 10},
		"rooms_per_floor": {"min": 8, "max": 12},
		"enemy_types": ["vault_dweller", "vault_guardian", "security_bot"],
		"loot_table": "vault",
		"boss": "vault_overseer",
		"time_limit": 3600,
		"environment": "vault",
		"hazards": ["security_systems", "radiation"],
	},
	DungeonType.SUBWAY: {
		"display_name": "Metro Tunnels",
		"description": "Dark underground rail network.",
		"min_level": 5,
		"floors": {"min": 3, "max": 5},
		"rooms_per_floor": {"min": 10, "max": 16},
		"enemy_types": ["zombie_commuter", "zombie_crawler", "tunnel_rat"],
		"loot_table": "subway",
		"boss": "tunnel_king",
		"time_limit": 1500,
		"environment": "subway",
		"hazards": ["trains", "darkness", "collapse"],
	},
	DungeonType.MINE: {
		"display_name": "Abandoned Mine",
		"description": "Deep shafts with mineral deposits.",
		"min_level": 8,
		"floors": {"min": 4, "max": 7},
		"rooms_per_floor": {"min": 6, "max": 10},
		"enemy_types": ["zombie_miner", "cave_creature", "zombie_crawler"],
		"loot_table": "mine",
		"boss": "deep_dweller",
		"time_limit": 2100,
		"environment": "mine",
		"hazards": ["cave_in", "gas", "darkness"],
	},
}

const DIFFICULTY_MODIFIERS := {
	DungeonDifficulty.EASY: {
		"enemy_health_mult": 0.75,
		"enemy_damage_mult": 0.75,
		"enemy_count_mult": 0.8,
		"loot_mult": 0.8,
		"xp_mult": 0.75,
	},
	DungeonDifficulty.NORMAL: {
		"enemy_health_mult": 1.0,
		"enemy_damage_mult": 1.0,
		"enemy_count_mult": 1.0,
		"loot_mult": 1.0,
		"xp_mult": 1.0,
	},
	DungeonDifficulty.HARD: {
		"enemy_health_mult": 1.5,
		"enemy_damage_mult": 1.25,
		"enemy_count_mult": 1.25,
		"loot_mult": 1.3,
		"xp_mult": 1.5,
	},
	DungeonDifficulty.NIGHTMARE: {
		"enemy_health_mult": 2.0,
		"enemy_damage_mult": 1.5,
		"enemy_count_mult": 1.5,
		"loot_mult": 1.75,
		"xp_mult": 2.0,
	},
	DungeonDifficulty.HELL: {
		"enemy_health_mult": 3.0,
		"enemy_damage_mult": 2.0,
		"enemy_count_mult": 2.0,
		"loot_mult": 2.5,
		"xp_mult": 3.0,
	},
}

const ROOM_TEMPLATES := {
	RoomType.ENTRANCE: {
		"size": Vector2i(3, 3),
		"enemy_count": 0,
		"chest_chance": 0.0,
		"connections": 1,
	},
	RoomType.CORRIDOR: {
		"size": Vector2i(2, 5),
		"enemy_count": 2,
		"chest_chance": 0.1,
		"connections": 2,
	},
	RoomType.SMALL_ROOM: {
		"size": Vector2i(3, 3),
		"enemy_count": 3,
		"chest_chance": 0.2,
		"connections": 2,
	},
	RoomType.MEDIUM_ROOM: {
		"size": Vector2i(4, 4),
		"enemy_count": 5,
		"chest_chance": 0.3,
		"connections": 3,
	},
	RoomType.LARGE_ROOM: {
		"size": Vector2i(6, 5),
		"enemy_count": 8,
		"chest_chance": 0.4,
		"connections": 4,
	},
	RoomType.STORAGE: {
		"size": Vector2i(3, 4),
		"enemy_count": 2,
		"chest_chance": 0.8,
		"connections": 1,
		"chest_type": "storage",
	},
	RoomType.ARMORY: {
		"size": Vector2i(4, 3),
		"enemy_count": 4,
		"chest_chance": 1.0,
		"connections": 1,
		"chest_type": "armory",
		"locked": true,
	},
	RoomType.MEDICAL: {
		"size": Vector2i(3, 3),
		"enemy_count": 3,
		"chest_chance": 1.0,
		"connections": 1,
		"chest_type": "medical",
	},
	RoomType.LABORATORY: {
		"size": Vector2i(5, 4),
		"enemy_count": 4,
		"chest_chance": 0.6,
		"connections": 2,
		"chest_type": "laboratory",
		"hazard": "chemical",
	},
	RoomType.OFFICE: {
		"size": Vector2i(4, 3),
		"enemy_count": 2,
		"chest_chance": 0.3,
		"connections": 2,
	},
	RoomType.GENERATOR_ROOM: {
		"size": Vector2i(4, 4),
		"enemy_count": 3,
		"chest_chance": 0.4,
		"connections": 1,
		"power_source": true,
	},
	RoomType.CAFETERIA: {
		"size": Vector2i(6, 4),
		"enemy_count": 8,
		"chest_chance": 0.5,
		"connections": 3,
		"chest_type": "food",
	},
	RoomType.CELL_BLOCK: {
		"size": Vector2i(5, 6),
		"enemy_count": 10,
		"chest_chance": 0.3,
		"connections": 2,
	},
	RoomType.BOSS_ROOM: {
		"size": Vector2i(8, 8),
		"enemy_count": 0,  # Boss only
		"chest_chance": 1.0,
		"connections": 1,
		"chest_type": "boss",
		"is_boss": true,
	},
	RoomType.TREASURE_ROOM: {
		"size": Vector2i(3, 3),
		"enemy_count": 0,
		"chest_chance": 1.0,
		"connections": 1,
		"chest_type": "treasure",
		"locked": true,
		"hidden": true,
	},
	RoomType.SAFE_ROOM: {
		"size": Vector2i(2, 2),
		"enemy_count": 0,
		"chest_chance": 0.5,
		"connections": 1,
		"safe_zone": true,
	},
	RoomType.EXIT: {
		"size": Vector2i(3, 3),
		"enemy_count": 0,
		"chest_chance": 0.0,
		"connections": 1,
		"is_exit": true,
	},
}


# ============================================================================
# STATE
# ============================================================================

var is_in_dungeon: bool = false
var current_dungeon_type: int = DungeonType.BUNKER
var current_difficulty: int = DungeonDifficulty.NORMAL
var current_floor: int = 0
var total_floors: int = 0

var _dungeon_data: Dictionary = {}
var _floor_data: Dictionary = {}
var _rooms: Dictionary = {}  # room_id -> room data
var _current_room_id: String = ""

var _time_remaining: float = 0.0
var _time_limit: float = 0.0
var _enemies_killed: int = 0
var _chests_opened: int = 0
var _boss_defeated: bool = false
var _collected_loot: Array = []

var _generation_seed: int = 0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if is_in_dungeon and _time_limit > 0:
		_time_remaining -= delta
		
		# Warnings at 5, 2, 1 minutes
		if _time_remaining <= 300.0 and _time_remaining > 299.0:
			emit_signal("dungeon_timer_warning", 300.0)
		elif _time_remaining <= 120.0 and _time_remaining > 119.0:
			emit_signal("dungeon_timer_warning", 120.0)
		elif _time_remaining <= 60.0 and _time_remaining > 59.0:
			emit_signal("dungeon_timer_warning", 60.0)
		
		if _time_remaining <= 0.0:
			_force_exit()


# ============================================================================
# DUNGEON GENERATION
# ============================================================================

func enter_dungeon(dungeon_type: int, difficulty: int = DungeonDifficulty.NORMAL, seed_value: int = -1) -> Dictionary:
	if is_in_dungeon:
		return {"success": false, "error": "Already in dungeon"}
	
	var definition: Dictionary = DUNGEON_DEFINITIONS.get(dungeon_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown dungeon type"}
	
	_generation_seed = seed_value if seed_value >= 0 else randi()
	seed(_generation_seed)
	
	current_dungeon_type = dungeon_type
	current_difficulty = difficulty
	current_floor = 0
	
	# Generate dungeon structure
	var floors_range: Dictionary = definition.get("floors", {"min": 3, "max": 5})
	total_floors = randi_range(floors_range["min"], floors_range["max"])
	
	_dungeon_data = {
		"type": dungeon_type,
		"type_name": DungeonType.keys()[dungeon_type],
		"display_name": definition.get("display_name", "Dungeon"),
		"difficulty": difficulty,
		"difficulty_name": DungeonDifficulty.keys()[difficulty],
		"total_floors": total_floors,
		"seed": _generation_seed,
		"entered_at": Time.get_unix_time_from_system(),
		"boss": definition.get("boss", ""),
		"environment": definition.get("environment", "generic"),
	}
	
	_time_limit = definition.get("time_limit", 1800)
	_time_remaining = _time_limit
	_enemies_killed = 0
	_chests_opened = 0
	_boss_defeated = false
	_collected_loot.clear()
	
	is_in_dungeon = true
	
	# Generate and enter first floor
	_generate_floor(1)
	current_floor = 1
	
	emit_signal("dungeon_entered", _dungeon_data)
	emit_signal("floor_changed", current_floor, _floor_data)
	
	return {"success": true, "dungeon": _dungeon_data}


func _generate_floor(floor_number: int) -> void:
	var definition: Dictionary = DUNGEON_DEFINITIONS.get(current_dungeon_type, {})
	var rooms_range: Dictionary = definition.get("rooms_per_floor", {"min": 8, "max": 12})
	var room_count := randi_range(rooms_range["min"], rooms_range["max"])
	
	var difficulty_mod: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, {})
	
	_floor_data = {
		"floor_number": floor_number,
		"room_count": room_count,
		"is_boss_floor": floor_number == total_floors,
		"rooms_cleared": 0,
		"total_enemies": 0,
		"enemies_killed": 0,
	}
	
	_rooms.clear()
	
	# Generate room layout
	var room_types := _generate_room_layout(room_count, floor_number == total_floors)
	
	for i in range(room_types.size()):
		var room_type: int = room_types[i]
		var room_id := "room_%d_%d" % [floor_number, i]
		var template: Dictionary = ROOM_TEMPLATES.get(room_type, {})
		
		var enemy_count := int(template.get("enemy_count", 0) * difficulty_mod.get("enemy_count_mult", 1.0))
		
		var room := {
			"id": room_id,
			"type": room_type,
			"type_name": RoomType.keys()[room_type],
			"floor": floor_number,
			"index": i,
			"size": template.get("size", Vector2i(4, 4)),
			"enemies": _generate_room_enemies(enemy_count, room_type),
			"enemies_alive": enemy_count,
			"chests": _generate_room_chests(template),
			"cleared": false,
			"discovered": i == 0,  # Entrance is discovered
			"locked": template.get("locked", false),
			"hidden": template.get("hidden", false),
			"is_boss": template.get("is_boss", false),
			"is_exit": template.get("is_exit", false),
			"safe_zone": template.get("safe_zone", false),
			"hazard": template.get("hazard", ""),
			"connections": [],
		}
		
		_floor_data["total_enemies"] += enemy_count
		_rooms[room_id] = room
	
	# Connect rooms
	_connect_rooms()
	
	# Enter first room
	var entrance_id := "room_%d_0" % floor_number
	_current_room_id = entrance_id
	emit_signal("room_entered", _rooms[entrance_id])


func _generate_room_layout(room_count: int, is_boss_floor: bool) -> Array:
	var layout: Array = []
	
	# Always start with entrance
	layout.append(RoomType.ENTRANCE)
	
	# Generate middle rooms
	var room_pool: Array = [
		RoomType.CORRIDOR, RoomType.CORRIDOR,
		RoomType.SMALL_ROOM, RoomType.SMALL_ROOM, RoomType.SMALL_ROOM,
		RoomType.MEDIUM_ROOM, RoomType.MEDIUM_ROOM,
		RoomType.LARGE_ROOM,
		RoomType.STORAGE,
		RoomType.OFFICE,
	]
	
	# Add special rooms based on dungeon type
	match current_dungeon_type:
		DungeonType.HOSPITAL:
			room_pool.append_array([RoomType.MEDICAL, RoomType.MEDICAL, RoomType.LABORATORY])
		DungeonType.LABORATORY:
			room_pool.append_array([RoomType.LABORATORY, RoomType.LABORATORY])
		DungeonType.POLICE_STATION, DungeonType.MILITARY_BASE:
			room_pool.append_array([RoomType.ARMORY, RoomType.CELL_BLOCK])
		DungeonType.PRISON:
			room_pool.append_array([RoomType.CELL_BLOCK, RoomType.CELL_BLOCK])
		DungeonType.MALL, DungeonType.FACTORY:
			room_pool.append_array([RoomType.CAFETERIA, RoomType.LARGE_ROOM])
	
	# Fill middle rooms
	for i in range(room_count - 2):  # -2 for entrance and exit/boss
		layout.append(room_pool[randi() % room_pool.size()])
	
	# Add special rooms
	if is_boss_floor:
		layout.append(RoomType.BOSS_ROOM)
	else:
		layout.append(RoomType.EXIT)
	
	# Maybe add treasure room
	if randf() < 0.2:
		var insert_pos := randi_range(2, layout.size() - 1)
		layout.insert(insert_pos, RoomType.TREASURE_ROOM)
	
	# Maybe add safe room
	if randf() < 0.3:
		var insert_pos := randi_range(2, layout.size() - 1)
		layout.insert(insert_pos, RoomType.SAFE_ROOM)
	
	return layout


func _connect_rooms() -> void:
	var room_ids := _rooms.keys()
	
	# Linear connection for basic layout
	for i in range(room_ids.size() - 1):
		var current_id: String = room_ids[i]
		var next_id: String = room_ids[i + 1]
		
		_rooms[current_id]["connections"].append(next_id)
		_rooms[next_id]["connections"].append(current_id)
	
	# Add some additional connections for variety
	for i in range(room_ids.size()):
		var room: Dictionary = _rooms[room_ids[i]]
		var template: Dictionary = ROOM_TEMPLATES.get(room["type"], {})
		var max_connections: int = template.get("connections", 2)
		
		if room["connections"].size() < max_connections and randf() < 0.3:
			# Try to connect to a nearby room
			var potential: Array = []
			for j in range(max(0, i - 3), min(room_ids.size(), i + 4)):
				if j != i and room_ids[j] not in room["connections"]:
					potential.append(room_ids[j])
			
			if potential.size() > 0:
				var target: String = potential[randi() % potential.size()]
				room["connections"].append(target)
				_rooms[target]["connections"].append(room_ids[i])


func _generate_room_enemies(count: int, room_type: int) -> Array:
	var enemies: Array = []
	var definition: Dictionary = DUNGEON_DEFINITIONS.get(current_dungeon_type, {})
	var enemy_types: Array = definition.get("enemy_types", ["zombie_walker"])
	var difficulty_mod: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, {})
	
	for i in range(count):
		var enemy_type: String = enemy_types[randi() % enemy_types.size()]
		enemies.append({
			"type": enemy_type,
			"health_mult": difficulty_mod.get("enemy_health_mult", 1.0),
			"damage_mult": difficulty_mod.get("enemy_damage_mult", 1.0),
			"alive": true,
		})
	
	return enemies


func _generate_room_chests(template: Dictionary) -> Array:
	var chests: Array = []
	var chest_chance: float = template.get("chest_chance", 0.0)
	var difficulty_mod: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, {})
	
	if randf() < chest_chance:
		var chest_type: String = template.get("chest_type", "common")
		chests.append({
			"id": "chest_%d" % randi(),
			"type": chest_type,
			"loot_mult": difficulty_mod.get("loot_mult", 1.0),
			"opened": false,
			"locked": template.get("locked", false),
		})
	
	return chests


# ============================================================================
# NAVIGATION
# ============================================================================

func move_to_room(room_id: String) -> Dictionary:
	if not is_in_dungeon:
		return {"success": false, "error": "Not in dungeon"}
	
	if room_id not in _rooms:
		return {"success": false, "error": "Room not found"}
	
	var current_room: Dictionary = _rooms.get(_current_room_id, {})
	
	# Check if rooms are connected
	if room_id not in current_room.get("connections", []):
		return {"success": false, "error": "Rooms not connected"}
	
	var target_room: Dictionary = _rooms[room_id]
	
	# Check if locked
	if target_room.get("locked", false):
		return {"success": false, "error": "Room is locked", "needs_key": true}
	
	_current_room_id = room_id
	target_room["discovered"] = true
	
	emit_signal("room_entered", target_room)
	
	# Check for boss room
	if target_room.get("is_boss", false) and not _boss_defeated:
		_spawn_boss()
	
	return {"success": true, "room": target_room}


func go_to_next_floor() -> Dictionary:
	if not is_in_dungeon:
		return {"success": false, "error": "Not in dungeon"}
	
	var current_room: Dictionary = _rooms.get(_current_room_id, {})
	
	if not current_room.get("is_exit", false):
		return {"success": false, "error": "Not at exit"}
	
	if current_floor >= total_floors:
		return {"success": false, "error": "Already at final floor"}
	
	current_floor += 1
	_generate_floor(current_floor)
	
	emit_signal("floor_changed", current_floor, _floor_data)
	
	return {"success": true, "floor": current_floor}


func unlock_room(room_id: String) -> bool:
	if room_id not in _rooms:
		return false
	
	_rooms[room_id]["locked"] = false
	return true


# ============================================================================
# COMBAT
# ============================================================================

func on_enemy_killed(room_id: String, enemy_index: int) -> void:
	if room_id not in _rooms:
		return
	
	var room: Dictionary = _rooms[room_id]
	
	if enemy_index >= 0 and enemy_index < room["enemies"].size():
		room["enemies"][enemy_index]["alive"] = false
		room["enemies_alive"] -= 1
		_floor_data["enemies_killed"] += 1
		_enemies_killed += 1
		
		if room["enemies_alive"] <= 0:
			_clear_room(room_id)


func _clear_room(room_id: String) -> void:
	if room_id not in _rooms:
		return
	
	var room: Dictionary = _rooms[room_id]
	room["cleared"] = true
	_floor_data["rooms_cleared"] += 1
	
	emit_signal("room_cleared", room_id)


func _spawn_boss() -> void:
	var definition: Dictionary = DUNGEON_DEFINITIONS.get(current_dungeon_type, {})
	var boss_id: String = definition.get("boss", "boss")
	var difficulty_mod: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, {})
	
	var boss_data := {
		"id": boss_id,
		"display_name": boss_id.replace("_", " ").capitalize(),
		"dungeon_type": current_dungeon_type,
		"difficulty": current_difficulty,
		"health_mult": difficulty_mod.get("enemy_health_mult", 1.0) * 2.0,
		"damage_mult": difficulty_mod.get("enemy_damage_mult", 1.0) * 1.5,
	}
	
	emit_signal("boss_spawned", boss_data)


func on_boss_defeated() -> void:
	_boss_defeated = true
	
	var definition: Dictionary = DUNGEON_DEFINITIONS.get(current_dungeon_type, {})
	
	var boss_data := {
		"id": definition.get("boss", "boss"),
		"dungeon_type": current_dungeon_type,
	}
	
	emit_signal("boss_defeated", boss_data)
	
	# Boss room becomes exit
	var current_room: Dictionary = _rooms.get(_current_room_id, {})
	current_room["is_exit"] = true


# ============================================================================
# LOOT
# ============================================================================

func open_chest(room_id: String, chest_index: int) -> Dictionary:
	if room_id not in _rooms:
		return {"success": false, "error": "Room not found"}
	
	var room: Dictionary = _rooms[room_id]
	
	if chest_index < 0 or chest_index >= room["chests"].size():
		return {"success": false, "error": "Chest not found"}
	
	var chest: Dictionary = room["chests"][chest_index]
	
	if chest.get("opened", false):
		return {"success": false, "error": "Already opened"}
	
	if chest.get("locked", false):
		return {"success": false, "error": "Chest is locked"}
	
	chest["opened"] = true
	_chests_opened += 1
	
	# Generate loot
	var loot := _generate_chest_loot(chest)
	_collected_loot.append_array(loot)
	
	emit_signal("chest_opened", {
		"chest": chest,
		"room_id": room_id,
		"loot": loot,
	})
	
	return {"success": true, "loot": loot}


func _generate_chest_loot(chest: Dictionary) -> Array:
	var loot: Array = []
	var chest_type: String = chest.get("type", "common")
	var loot_mult: float = chest.get("loot_mult", 1.0)
	
	var item_count := 1
	match chest_type:
		"common":
			item_count = randi_range(1, 3)
		"storage":
			item_count = randi_range(2, 4)
		"armory":
			item_count = randi_range(2, 3)
		"medical":
			item_count = randi_range(2, 4)
		"laboratory":
			item_count = randi_range(1, 3)
		"treasure":
			item_count = randi_range(3, 5)
		"boss":
			item_count = randi_range(4, 6)
	
	item_count = int(item_count * loot_mult)
	
	for i in range(item_count):
		loot.append({
			"type": chest_type,
			"quality": _get_loot_quality(),
		})
	
	return loot


func _get_loot_quality() -> String:
	var roll := randf()
	var difficulty_mod: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, {})
	var loot_mult: float = difficulty_mod.get("loot_mult", 1.0)
	
	# Better difficulty = better loot chances
	roll -= (loot_mult - 1.0) * 0.1
	
	if roll < 0.01:
		return "legendary"
	elif roll < 0.05:
		return "epic"
	elif roll < 0.15:
		return "rare"
	elif roll < 0.40:
		return "uncommon"
	else:
		return "common"


# ============================================================================
# EXIT
# ============================================================================

func exit_dungeon() -> Dictionary:
	if not is_in_dungeon:
		return {"success": false, "error": "Not in dungeon"}
	
	var current_room: Dictionary = _rooms.get(_current_room_id, {})
	
	# Can exit from entrance or exit rooms
	if not current_room.get("is_exit", false) and current_room.get("type", -1) != RoomType.ENTRANCE:
		return {"success": false, "error": "Not at exit point"}
	
	var completed := _boss_defeated or current_floor < total_floors
	var rewards := _calculate_rewards(completed)
	
	is_in_dungeon = false
	emit_signal("dungeon_exited", completed, rewards)
	
	return {"success": true, "completed": completed, "rewards": rewards}


func _force_exit() -> void:
	# Time ran out
	var rewards := _calculate_rewards(false)
	rewards["time_expired"] = true
	
	is_in_dungeon = false
	emit_signal("dungeon_exited", false, rewards)


func _calculate_rewards(completed: bool) -> Dictionary:
	var difficulty_mod: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, {})
	var xp_mult: float = difficulty_mod.get("xp_mult", 1.0)
	
	var base_xp := _enemies_killed * 10
	base_xp += _chests_opened * 25
	base_xp += current_floor * 50
	
	if _boss_defeated:
		base_xp += 500
	
	if completed:
		base_xp = int(base_xp * 1.5)
	
	return {
		"xp": int(base_xp * xp_mult),
		"enemies_killed": _enemies_killed,
		"chests_opened": _chests_opened,
		"floors_completed": current_floor,
		"boss_defeated": _boss_defeated,
		"loot": _collected_loot.duplicate(),
		"time_taken": _time_limit - _time_remaining,
		"completed": completed,
	}


# ============================================================================
# QUERIES
# ============================================================================

func get_dungeon_status() -> Dictionary:
	return {
		"is_active": is_in_dungeon,
		"dungeon_type": current_dungeon_type,
		"difficulty": current_difficulty,
		"current_floor": current_floor,
		"total_floors": total_floors,
		"current_room": _current_room_id,
		"time_remaining": _time_remaining,
		"enemies_killed": _enemies_killed,
		"chests_opened": _chests_opened,
		"boss_defeated": _boss_defeated,
	}


func get_current_room() -> Dictionary:
	return _rooms.get(_current_room_id, {})


func get_floor_rooms() -> Array:
	return _rooms.values()


func get_connected_rooms() -> Array:
	var current: Dictionary = _rooms.get(_current_room_id, {})
	var connected: Array = []
	
	for room_id in current.get("connections", []):
		if room_id in _rooms:
			connected.append(_rooms[room_id])
	
	return connected


func get_available_dungeons(player_level: int) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	
	for dungeon_type in DUNGEON_DEFINITIONS:
		var def: Dictionary = DUNGEON_DEFINITIONS[dungeon_type]
		if player_level >= def.get("min_level", 1):
			var entry := def.duplicate()
			entry["type"] = dungeon_type
			entry["type_name"] = DungeonType.keys()[dungeon_type]
			available.append(entry)
	
	return available


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"is_in_dungeon": is_in_dungeon,
		"current_dungeon_type": current_dungeon_type,
		"current_difficulty": current_difficulty,
		"current_floor": current_floor,
		"total_floors": total_floors,
		"dungeon_data": _dungeon_data.duplicate(true),
		"floor_data": _floor_data.duplicate(true),
		"rooms": _rooms.duplicate(true),
		"current_room_id": _current_room_id,
		"time_remaining": _time_remaining,
		"time_limit": _time_limit,
		"enemies_killed": _enemies_killed,
		"chests_opened": _chests_opened,
		"boss_defeated": _boss_defeated,
		"collected_loot": _collected_loot.duplicate(true),
		"generation_seed": _generation_seed,
	}


func load_data(data: Dictionary) -> void:
	is_in_dungeon = data.get("is_in_dungeon", false)
	current_dungeon_type = data.get("current_dungeon_type", DungeonType.BUNKER)
	current_difficulty = data.get("current_difficulty", DungeonDifficulty.NORMAL)
	current_floor = data.get("current_floor", 0)
	total_floors = data.get("total_floors", 0)
	_dungeon_data = data.get("dungeon_data", {})
	_floor_data = data.get("floor_data", {})
	_rooms = data.get("rooms", {})
	_current_room_id = data.get("current_room_id", "")
	_time_remaining = data.get("time_remaining", 0.0)
	_time_limit = data.get("time_limit", 0.0)
	_enemies_killed = data.get("enemies_killed", 0)
	_chests_opened = data.get("chests_opened", 0)
	_boss_defeated = data.get("boss_defeated", false)
	_collected_loot = data.get("collected_loot", [])
	_generation_seed = data.get("generation_seed", 0)
