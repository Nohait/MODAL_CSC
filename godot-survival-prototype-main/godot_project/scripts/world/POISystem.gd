extends Node
class_name POISystemClass
## Points of Interest management system
## Handles special locations, events, rewards, and discovery mechanics

signal poi_discovered(poi_id: String, poi_data: Dictionary)
signal poi_entered(poi_id: String)
signal poi_exited(poi_id: String)
signal poi_completed(poi_id: String, rewards: Dictionary)
signal poi_event_triggered(poi_id: String, event_type: String)

# ============================================================================
# POI TYPES & DEFINITIONS
# ============================================================================

enum POIType {
	# Exploration
	ABANDONED_HOUSE,
	CRASHED_VEHICLE,
	SURVIVOR_CAMP,
	RAIDER_OUTPOST,
	
	# Resource Rich
	LUMBER_YARD,
	QUARRY,
	SCRAPYARD,
	FARM_FIELD,
	
	# Military/High Value
	MILITARY_CHECKPOINT,
	CRASHED_HELICOPTER,
	SUPPLY_DROP,
	BUNKER_ENTRANCE,
	
	# Special
	TRADER_POST,
	SAFE_HOUSE,
	RADIO_TOWER,
	HOSPITAL,
	
	# Events
	HORDE_SPAWN,
	BOSS_ARENA,
	MYSTERY_BOX,
	AIRDROP,
	
	# Dungeons
	UNDERGROUND_BUNKER,
	SEWER_ENTRANCE,
	CAVE_SYSTEM,
	RESEARCH_FACILITY,
}

enum POIState {
	UNDISCOVERED,
	DISCOVERED,
	IN_PROGRESS,
	COMPLETED,
	LOCKED,
	RESPAWNING,
}

const POI_DEFINITIONS := {
	POIType.ABANDONED_HOUSE: {
		"name": "Abandoned House",
		"description": "A boarded-up house that might contain supplies.",
		"icon": "poi_house",
		"min_difficulty": 0,
		"enemy_count": [2, 5],
		"loot_tier": 1,
		"loot_count": [3, 6],
		"completion_xp": 50,
		"respawn_time": 3600,  # 1 hour
		"search_time": 120,
	},
	POIType.CRASHED_VEHICLE: {
		"name": "Crashed Vehicle",
		"description": "A wrecked vehicle with potential salvage.",
		"icon": "poi_vehicle",
		"min_difficulty": 0,
		"enemy_count": [0, 2],
		"loot_tier": 1,
		"loot_count": [2, 4],
		"special_loot": ["gasoline", "engine_parts", "rubber", "scrap_metal"],
		"completion_xp": 30,
		"respawn_time": 1800,
	},
	POIType.SURVIVOR_CAMP: {
		"name": "Survivor Camp",
		"description": "An abandoned survivor camp. Something drove them away.",
		"icon": "poi_camp",
		"min_difficulty": 0,
		"enemy_count": [1, 4],
		"loot_tier": 2,
		"loot_count": [4, 7],
		"has_campfire": true,
		"completion_xp": 60,
		"respawn_time": 5400,
	},
	POIType.RAIDER_OUTPOST: {
		"name": "Raider Outpost",
		"description": "A fortified position held by hostile raiders.",
		"icon": "poi_raider",
		"min_difficulty": 1,
		"enemy_count": [4, 8],
		"enemy_types": ["raider_scout", "raider_gunner", "raider_heavy"],
		"loot_tier": 2,
		"loot_count": [5, 10],
		"completion_xp": 150,
		"respawn_time": 7200,
		"is_hostile": true,
	},
	POIType.LUMBER_YARD: {
		"name": "Lumber Yard",
		"description": "An old logging operation with plenty of wood.",
		"icon": "poi_lumber",
		"min_difficulty": 0,
		"enemy_count": [2, 4],
		"resource_type": "wood",
		"resource_amount": [20, 40],
		"loot_tier": 1,
		"loot_count": [2, 4],
		"completion_xp": 40,
		"respawn_time": 3600,
	},
	POIType.QUARRY: {
		"name": "Quarry",
		"description": "An abandoned stone quarry rich with minerals.",
		"icon": "poi_quarry",
		"min_difficulty": 1,
		"enemy_count": [3, 6],
		"resource_type": "stone",
		"resource_amount": [15, 30],
		"bonus_resources": ["iron_ore", "copper_ore", "coal"],
		"loot_tier": 2,
		"loot_count": [3, 5],
		"completion_xp": 80,
		"respawn_time": 5400,
	},
	POIType.SCRAPYARD: {
		"name": "Scrapyard",
		"description": "Mountains of scrap metal and discarded tech.",
		"icon": "poi_scrap",
		"min_difficulty": 1,
		"enemy_count": [4, 7],
		"resource_type": "scrap_metal",
		"resource_amount": [25, 50],
		"bonus_resources": ["electronics", "rubber", "glass"],
		"loot_tier": 2,
		"loot_count": [4, 8],
		"completion_xp": 100,
		"respawn_time": 4800,
	},
	POIType.FARM_FIELD: {
		"name": "Farm Field",
		"description": "Overgrown crops that might still be harvestable.",
		"icon": "poi_farm",
		"min_difficulty": 0,
		"enemy_count": [1, 3],
		"resource_type": "food",
		"resource_amount": [10, 25],
		"bonus_resources": ["carrot", "potato", "corn", "berries"],
		"loot_tier": 1,
		"loot_count": [2, 4],
		"completion_xp": 35,
		"respawn_time": 2700,
	},
	POIType.MILITARY_CHECKPOINT: {
		"name": "Military Checkpoint",
		"description": "An abandoned military roadblock with high-tier gear.",
		"icon": "poi_military",
		"min_difficulty": 2,
		"enemy_count": [5, 10],
		"enemy_types": ["zombie_runner", "brute", "raider_gunner"],
		"loot_tier": 3,
		"loot_count": [6, 12],
		"special_loot": ["rifle_ammo", "9mm_ammo", "medkit", "military_vest"],
		"completion_xp": 200,
		"respawn_time": 10800,
		"is_hostile": true,
	},
	POIType.CRASHED_HELICOPTER: {
		"name": "Crashed Helicopter",
		"description": "Military helicopter crash site with valuable cargo.",
		"icon": "poi_helicopter",
		"min_difficulty": 2,
		"enemy_count": [6, 10],
		"loot_tier": 3,
		"loot_count": [8, 15],
		"special_loot": ["assault_rifle", "tactical_armor", "medkit"],
		"completion_xp": 300,
		"respawn_time": 14400,
		"triggers_horde": true,
	},
	POIType.SUPPLY_DROP: {
		"name": "Supply Drop",
		"description": "A recent airdrop with supplies. Others will come for it.",
		"icon": "poi_airdrop",
		"min_difficulty": 2,
		"enemy_count": [4, 8],
		"loot_tier": 3,
		"loot_count": [10, 20],
		"completion_xp": 250,
		"respawn_time": 0,  # One-time event
		"time_limit": 300,
		"is_event": true,
	},
	POIType.BUNKER_ENTRANCE: {
		"name": "Bunker Entrance",
		"description": "A heavy blast door leading underground. Requires keycard.",
		"icon": "poi_bunker",
		"min_difficulty": 3,
		"requires_item": "keycard",
		"leads_to_dungeon": true,
		"dungeon_type": "bunker",
		"completion_xp": 500,
		"respawn_time": 86400,  # 24 hours
	},
	POIType.TRADER_POST: {
		"name": "Trader Post",
		"description": "A fortified trading outpost. Safe zone.",
		"icon": "poi_trader",
		"min_difficulty": 0,
		"is_safe_zone": true,
		"has_trader": true,
		"trader_inventory_refresh": 7200,
		"completion_xp": 0,
		"respawn_time": 0,
	},
	POIType.SAFE_HOUSE: {
		"name": "Safe House",
		"description": "A secured location. Can be claimed as a respawn point.",
		"icon": "poi_safehouse",
		"min_difficulty": 1,
		"enemy_count": [3, 6],
		"is_safe_zone": true,
		"can_claim": true,
		"has_storage": true,
		"completion_xp": 100,
		"respawn_time": 0,
	},
	POIType.RADIO_TOWER: {
		"name": "Radio Tower",
		"description": "A communications tower. Reveals nearby POIs when activated.",
		"icon": "poi_radio",
		"min_difficulty": 1,
		"enemy_count": [2, 5],
		"reveals_map_radius": 500,
		"requires_power": true,
		"completion_xp": 75,
		"respawn_time": 0,
	},
	POIType.HOSPITAL: {
		"name": "Hospital",
		"description": "An overrun hospital. Medical supplies inside.",
		"icon": "poi_hospital",
		"min_difficulty": 2,
		"enemy_count": [8, 15],
		"loot_tier": 3,
		"loot_count": [10, 20],
		"special_loot": ["medkit", "antibiotics", "adrenaline", "antidote", "painkillers"],
		"completion_xp": 200,
		"respawn_time": 10800,
		"has_hazards": true,
	},
	POIType.HORDE_SPAWN: {
		"name": "Horde Gathering",
		"description": "A large concentration of infected. Very dangerous.",
		"icon": "poi_horde",
		"min_difficulty": 2,
		"enemy_count": [15, 30],
		"loot_tier": 2,
		"loot_count": [5, 10],
		"completion_xp": 300,
		"respawn_time": 7200,
		"is_event": true,
	},
	POIType.BOSS_ARENA: {
		"name": "Boss Arena",
		"description": "Something powerful lurks here. Come prepared.",
		"icon": "poi_boss",
		"min_difficulty": 3,
		"has_boss": true,
		"boss_type": "ravager",
		"loot_tier": 4,
		"loot_count": [15, 25],
		"completion_xp": 1000,
		"respawn_time": 86400,
	},
	POIType.MYSTERY_BOX: {
		"name": "Mystery Crate",
		"description": "A strange container. Could be anything inside.",
		"icon": "poi_mystery",
		"min_difficulty": 0,
		"enemy_count": [0, 0],
		"loot_tier": -1,  # Random tier
		"loot_count": [1, 3],
		"completion_xp": 25,
		"respawn_time": 1800,
	},
	POIType.UNDERGROUND_BUNKER: {
		"name": "Underground Bunker",
		"description": "A multi-level underground facility.",
		"icon": "poi_dungeon",
		"min_difficulty": 3,
		"is_dungeon": true,
		"dungeon_floors": 3,
		"has_boss": true,
		"loot_tier": 4,
		"completion_xp": 1500,
		"respawn_time": 86400,
	},
	POIType.SEWER_ENTRANCE: {
		"name": "Sewer Entrance",
		"description": "Dark tunnels beneath the city. Who knows what's down there.",
		"icon": "poi_sewer",
		"min_difficulty": 2,
		"is_dungeon": true,
		"dungeon_floors": 2,
		"enemy_types": ["zombie_crawler", "bloater", "spitter"],
		"loot_tier": 2,
		"completion_xp": 400,
		"respawn_time": 43200,
	},
	POIType.CAVE_SYSTEM: {
		"name": "Cave System",
		"description": "A network of natural caves. Rich in minerals.",
		"icon": "poi_cave",
		"min_difficulty": 2,
		"is_dungeon": true,
		"dungeon_floors": 2,
		"resource_type": "ore",
		"resource_amount": [30, 60],
		"loot_tier": 3,
		"completion_xp": 350,
		"respawn_time": 28800,
	},
	POIType.RESEARCH_FACILITY: {
		"name": "Research Facility",
		"description": "A high-security lab. The infection might have started here.",
		"icon": "poi_lab",
		"min_difficulty": 3,
		"is_dungeon": true,
		"dungeon_floors": 4,
		"has_boss": true,
		"boss_type": "the_forsaken",
		"requires_item": "keycard",
		"loot_tier": 4,
		"special_loot": ["titanium_bar", "electronics", "sniper_rifle"],
		"completion_xp": 2000,
		"respawn_time": 172800,  # 48 hours
	},
}


# ============================================================================
# POI DATA
# ============================================================================

# Active POIs in current zone
var _active_pois: Dictionary = {}  # poi_id -> POI data

# Discovered POIs (persistent across zones)
var _discovered_pois: Dictionary = {}  # poi_id -> discovery timestamp

# Completed POIs with respawn timers
var _completed_pois: Dictionary = {}  # poi_id -> completion timestamp

# Currently active POI (player is inside)
var _current_poi_id: String = ""

# RNG for POI generation
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


# ============================================================================
# POI GENERATION
# ============================================================================

func generate_pois_for_zone(zone_data: Dictionary) -> Array[Dictionary]:
	## Generate POIs for a zone based on type and difficulty
	var pois: Array[Dictionary] = []
	var zone_type: int = zone_data.get("type", 0)
	var difficulty: int = zone_data.get("difficulty", 0)
	var zone_size: Vector2i = zone_data.get("size", Vector2i(64, 64))
	
	_rng.seed = zone_data.get("seed", randi())
	
	# Determine POI count based on zone size
	var base_poi_count := int((zone_size.x * zone_size.y) / 400)
	var poi_count := base_poi_count + _rng.randi_range(-2, 3)
	poi_count = clampi(poi_count, 3, 15)
	
	# Get valid POI types for this zone
	var valid_types := _get_valid_poi_types(zone_type, difficulty)
	
	# Track placed positions to avoid overlap
	var placed_positions: Array[Vector2i] = []
	var min_distance := 8  # Minimum tiles between POIs
	
	for i in range(poi_count):
		var poi_type: POIType = valid_types[_rng.randi() % valid_types.size()]
		var poi_def: Dictionary = POI_DEFINITIONS[poi_type]
		
		# Skip if difficulty too high
		if poi_def.get("min_difficulty", 0) > difficulty:
			continue
		
		# Find valid position
		var position := _find_poi_position(zone_data, placed_positions, min_distance)
		if position == Vector2i(-1, -1):
			continue
		
		placed_positions.append(position)
		
		# Generate unique POI ID
		var poi_id := "%s_%d_%d_%d" % [POIType.keys()[poi_type].to_lower(), zone_data.get("seed", 0), position.x, position.y]
		
		# Create POI data
		var poi_data := {
			"id": poi_id,
			"type": poi_type,
			"type_name": POIType.keys()[poi_type],
			"name": poi_def.get("name", "Unknown"),
			"description": poi_def.get("description", ""),
			"position": position,
			"world_position": Vector2(position.x * 32, position.y * 32),
			"radius": _rng.randi_range(3, 6),
			"state": POIState.UNDISCOVERED,
			"discovery_reward_xp": 10,
			"completion_xp": poi_def.get("completion_xp", 50),
			"loot_tier": poi_def.get("loot_tier", 1),
			"loot_count_range": poi_def.get("loot_count", [2, 5]),
			"enemy_count_range": poi_def.get("enemy_count", [0, 0]),
			"enemy_types": poi_def.get("enemy_types", []),
			"special_loot": poi_def.get("special_loot", []),
			"resource_type": poi_def.get("resource_type", ""),
			"resource_amount": poi_def.get("resource_amount", [0, 0]),
			"is_safe_zone": poi_def.get("is_safe_zone", false),
			"is_dungeon": poi_def.get("is_dungeon", false),
			"is_hostile": poi_def.get("is_hostile", false),
			"is_event": poi_def.get("is_event", false),
			"has_boss": poi_def.get("has_boss", false),
			"boss_type": poi_def.get("boss_type", ""),
			"has_trader": poi_def.get("has_trader", false),
			"requires_item": poi_def.get("requires_item", ""),
			"respawn_time": poi_def.get("respawn_time", 3600),
			"time_limit": poi_def.get("time_limit", 0),
			"triggers_horde": poi_def.get("triggers_horde", false),
		}
		
		# Check if already discovered/completed
		if poi_id in _discovered_pois:
			poi_data["state"] = POIState.DISCOVERED
		if poi_id in _completed_pois:
			var completion_time: int = _completed_pois[poi_id]
			var respawn_time: int = poi_def.get("respawn_time", 3600)
			var current_time := int(Time.get_unix_time_from_system())
			
			if respawn_time > 0 and current_time - completion_time < respawn_time:
				poi_data["state"] = POIState.RESPAWNING
				poi_data["respawn_remaining"] = respawn_time - (current_time - completion_time)
			elif respawn_time == 0:
				poi_data["state"] = POIState.COMPLETED
		
		pois.append(poi_data)
		_active_pois[poi_id] = poi_data
	
	# Always add one guaranteed safe zone or trader in larger zones
	if poi_count >= 5 and not _has_safe_zone(pois):
		var safe_poi := _generate_guaranteed_poi(zone_data, placed_positions, POIType.TRADER_POST)
		if safe_poi:
			pois.append(safe_poi)
	
	return pois


func _get_valid_poi_types(zone_type: int, difficulty: int) -> Array[POIType]:
	## Get POI types valid for this zone type
	var valid: Array[POIType] = []
	
	# Common POIs for all zones
	var common: Array[POIType] = [
		POIType.ABANDONED_HOUSE,
		POIType.CRASHED_VEHICLE,
		POIType.SURVIVOR_CAMP,
		POIType.MYSTERY_BOX,
	]
	valid.append_array(common)
	
	# Zone-specific POIs
	match zone_type:
		0:  # FOREST
			valid.append_array([POIType.LUMBER_YARD, POIType.FARM_FIELD, POIType.CAVE_SYSTEM])
		1:  # CITY
			valid.append_array([POIType.SCRAPYARD, POIType.HOSPITAL, POIType.SEWER_ENTRANCE, POIType.RAIDER_OUTPOST])
		2:  # INDUSTRIAL
			valid.append_array([POIType.SCRAPYARD, POIType.QUARRY, POIType.RAIDER_OUTPOST])
		3:  # MILITARY
			valid.append_array([POIType.MILITARY_CHECKPOINT, POIType.CRASHED_HELICOPTER, POIType.BUNKER_ENTRANCE, POIType.RESEARCH_FACILITY])
		4:  # FARM
			valid.append_array([POIType.FARM_FIELD, POIType.LUMBER_YARD])
		5:  # HIGHWAY
			valid.append_array([POIType.CRASHED_VEHICLE, POIType.RAIDER_OUTPOST])
	
	# High difficulty POIs
	if difficulty >= 2:
		valid.append_array([POIType.HORDE_SPAWN, POIType.BOSS_ARENA, POIType.SUPPLY_DROP])
	
	if difficulty >= 3:
		valid.append_array([POIType.UNDERGROUND_BUNKER, POIType.RESEARCH_FACILITY])
	
	# Add safe zones occasionally
	if _rng.randf() < 0.3:
		valid.append(POIType.TRADER_POST)
	if _rng.randf() < 0.2:
		valid.append(POIType.SAFE_HOUSE)
	if _rng.randf() < 0.15:
		valid.append(POIType.RADIO_TOWER)
	
	return valid


func _find_poi_position(zone_data: Dictionary, placed: Array[Vector2i], min_dist: int) -> Vector2i:
	## Find valid position for POI
	var zone_size: Vector2i = zone_data.get("size", Vector2i(64, 64))
	var tiles: Array = zone_data.get("tiles", [])
	var margin := 5
	
	for _attempt in range(50):
		var x := _rng.randi_range(margin, zone_size.x - margin)
		var y := _rng.randi_range(margin, zone_size.y - margin)
		var pos := Vector2i(x, y)
		
		# Check distance from other POIs
		var too_close := false
		for placed_pos in placed:
			if pos.distance_to(placed_pos) < min_dist:
				too_close = true
				break
		
		if too_close:
			continue
		
		# Check tile is walkable
		if tiles.size() > y and tiles[y].size() > x:
			var tile: int = tiles[y][x]
			if tile == 4 or tile == 7:  # WATER or WALL
				continue
		
		return pos
	
	return Vector2i(-1, -1)


func _has_safe_zone(pois: Array[Dictionary]) -> bool:
	for poi in pois:
		if poi.get("is_safe_zone", false):
			return true
	return false


func _generate_guaranteed_poi(zone_data: Dictionary, placed: Array[Vector2i], poi_type: POIType) -> Dictionary:
	var position := _find_poi_position(zone_data, placed, 10)
	if position == Vector2i(-1, -1):
		return {}
	
	var poi_def: Dictionary = POI_DEFINITIONS[poi_type]
	var poi_id := "%s_%d_%d_%d" % [POIType.keys()[poi_type].to_lower(), zone_data.get("seed", 0), position.x, position.y]
	
	return {
		"id": poi_id,
		"type": poi_type,
		"type_name": POIType.keys()[poi_type],
		"name": poi_def.get("name", "Unknown"),
		"position": position,
		"world_position": Vector2(position.x * 32, position.y * 32),
		"radius": 4,
		"state": POIState.UNDISCOVERED,
		"is_safe_zone": poi_def.get("is_safe_zone", false),
		"has_trader": poi_def.get("has_trader", false),
	}


# ============================================================================
# POI INTERACTION
# ============================================================================

func discover_poi(poi_id: String) -> void:
	## Mark POI as discovered
	if poi_id not in _active_pois:
		return
	
	var poi := _active_pois[poi_id]
	if poi["state"] == POIState.UNDISCOVERED:
		poi["state"] = POIState.DISCOVERED
		_discovered_pois[poi_id] = int(Time.get_unix_time_from_system())
		
		emit_signal("poi_discovered", poi_id, poi)
		
		# Award discovery XP
		if "discovery_reward_xp" in poi:
			# ProgressionSystem.add_xp(poi["discovery_reward_xp"])
			pass


func enter_poi(poi_id: String) -> Dictionary:
	## Called when player enters POI area
	if poi_id not in _active_pois:
		return {}
	
	var poi := _active_pois[poi_id]
	
	# Auto-discover on entry
	if poi["state"] == POIState.UNDISCOVERED:
		discover_poi(poi_id)
	
	_current_poi_id = poi_id
	poi["state"] = POIState.IN_PROGRESS
	
	emit_signal("poi_entered", poi_id)
	
	# Generate POI content
	var content := _generate_poi_content(poi)
	
	return content


func exit_poi(poi_id: String) -> void:
	## Called when player leaves POI area
	if _current_poi_id == poi_id:
		_current_poi_id = ""
		emit_signal("poi_exited", poi_id)


func complete_poi(poi_id: String) -> Dictionary:
	## Mark POI as completed and generate rewards
	if poi_id not in _active_pois:
		return {}
	
	var poi := _active_pois[poi_id]
	poi["state"] = POIState.COMPLETED
	_completed_pois[poi_id] = int(Time.get_unix_time_from_system())
	
	# Generate rewards
	var rewards := _generate_poi_rewards(poi)
	
	emit_signal("poi_completed", poi_id, rewards)
	
	return rewards


func _generate_poi_content(poi: Dictionary) -> Dictionary:
	## Generate enemies, loot, and events for POI
	var content := {
		"enemies": [],
		"loot_containers": [],
		"resource_nodes": [],
		"hazards": [],
	}
	
	# Generate enemies
	var enemy_range: Array = poi.get("enemy_count_range", [0, 0])
	var enemy_count := _rng.randi_range(enemy_range[0], enemy_range[1])
	var enemy_types: Array = poi.get("enemy_types", ["zombie_walker", "zombie_runner"])
	
	if enemy_types.is_empty():
		enemy_types = ["zombie_walker", "zombie_runner"]
	
	for i in range(enemy_count):
		content["enemies"].append({
			"type": enemy_types[_rng.randi() % enemy_types.size()],
			"level": _rng.randi_range(1, 5),
			"position_offset": Vector2(_rng.randf_range(-3, 3), _rng.randf_range(-3, 3)) * 32,
		})
	
	# Generate boss if applicable
	if poi.get("has_boss", false):
		content["enemies"].append({
			"type": poi.get("boss_type", "ravager"),
			"level": 10,
			"is_boss": true,
			"position_offset": Vector2.ZERO,
		})
	
	# Generate loot containers
	var loot_range: Array = poi.get("loot_count_range", [2, 5])
	var loot_count := _rng.randi_range(loot_range[0], loot_range[1])
	
	for i in range(loot_count):
		content["loot_containers"].append({
			"tier": poi.get("loot_tier", 1),
			"position_offset": Vector2(_rng.randf_range(-2, 2), _rng.randf_range(-2, 2)) * 32,
			"special_items": poi.get("special_loot", []),
		})
	
	# Generate resource nodes
	var resource_type: String = poi.get("resource_type", "")
	if resource_type:
		var amount_range: Array = poi.get("resource_amount", [0, 0])
		var amount := _rng.randi_range(amount_range[0], amount_range[1])
		
		content["resource_nodes"].append({
			"type": resource_type,
			"amount": amount,
		})
	
	# Trigger horde if applicable
	if poi.get("triggers_horde", false):
		emit_signal("poi_event_triggered", poi["id"], "horde")
	
	return content


func _generate_poi_rewards(poi: Dictionary) -> Dictionary:
	## Generate completion rewards
	var rewards := {
		"xp": poi.get("completion_xp", 50),
		"items": [],
		"resources": {},
		"unlocks": [],
	}
	
	# XP bonus for first completion
	if poi["id"] not in _completed_pois:
		rewards["xp"] = int(rewards["xp"] * 1.5)
		rewards["first_clear_bonus"] = true
	
	# Generate item rewards based on loot tier
	var loot_tier: int = poi.get("loot_tier", 1)
	var item_count := _rng.randi_range(1, 3)
	
	# This would connect to LootSystem
	for i in range(item_count):
		rewards["items"].append({
			"tier": loot_tier,
			"quantity": _rng.randi_range(1, 3),
		})
	
	# Resource rewards
	var resource_type: String = poi.get("resource_type", "")
	if resource_type:
		var amount_range: Array = poi.get("resource_amount", [0, 0])
		rewards["resources"][resource_type] = _rng.randi_range(amount_range[0], amount_range[1])
	
	# Special unlocks
	if poi.get("is_dungeon", false):
		rewards["unlocks"].append("dungeon_access")
	if poi.get("reveals_map_radius", 0) > 0:
		rewards["unlocks"].append("map_reveal")
		rewards["map_reveal_radius"] = poi["reveals_map_radius"]
	
	return rewards


# ============================================================================
# POI QUERIES
# ============================================================================

func get_poi(poi_id: String) -> Dictionary:
	return _active_pois.get(poi_id, {})


func get_active_pois() -> Array[Dictionary]:
	var pois: Array[Dictionary] = []
	for poi in _active_pois.values():
		pois.append(poi)
	return pois


func get_discovered_pois() -> Array[Dictionary]:
	var pois: Array[Dictionary] = []
	for poi in _active_pois.values():
		if poi["state"] != POIState.UNDISCOVERED:
			pois.append(poi)
	return pois


func get_nearby_pois(position: Vector2, radius: float) -> Array[Dictionary]:
	var nearby: Array[Dictionary] = []
	for poi in _active_pois.values():
		var poi_pos: Vector2 = poi.get("world_position", Vector2.ZERO)
		if position.distance_to(poi_pos) <= radius:
			nearby.append(poi)
	return nearby


func get_current_poi() -> Dictionary:
	if _current_poi_id:
		return _active_pois.get(_current_poi_id, {})
	return {}


func is_in_safe_zone() -> bool:
	var current := get_current_poi()
	return current.get("is_safe_zone", false)


func get_poi_state_name(state: POIState) -> String:
	return POIState.keys()[state]


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"discovered_pois": _discovered_pois.duplicate(),
		"completed_pois": _completed_pois.duplicate(),
	}


func load_data(data: Dictionary) -> void:
	_discovered_pois = data.get("discovered_pois", {})
	_completed_pois = data.get("completed_pois", {})


func clear_zone_pois() -> void:
	## Clear active POIs when leaving zone
	_active_pois.clear()
	_current_poi_id = ""
