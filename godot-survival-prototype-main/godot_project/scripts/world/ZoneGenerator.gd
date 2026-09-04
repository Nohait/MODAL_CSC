extends Node
class_name ZoneGeneratorClass
## Procedural zone generation system
## Creates explorable areas with varied terrain, obstacles, and points of interest

signal zone_generated(zone_data: Dictionary)
signal generation_progress(percent: float, stage: String)

# ============================================================================
# ZONE TYPES & BIOMES
# ============================================================================

enum ZoneType {
	FOREST,
	CITY,
	INDUSTRIAL,
	MILITARY,
	FARM,
	HIGHWAY,
	BUNKER,
	SWAMP,
	DESERT,
	WINTER,
}

enum ZoneDifficulty {
	GREEN,   # Safe, low-tier loot
	YELLOW,  # Medium danger, decent loot
	RED,     # High danger, good loot
	BLACK,   # Extreme danger, best loot
}

const ZONE_CONFIGS := {
	ZoneType.FOREST: {
		"name": "Forest",
		"tile_set": "forest",
		"tree_density": 0.3,
		"rock_density": 0.1,
		"bush_density": 0.2,
		"enemy_types": ["zombie_walker", "zombie_runner", "feral_dog", "wolf"],
		"resource_types": ["wood", "plant_fiber", "berries", "mushroom"],
		"ambient_color": Color(0.2, 0.4, 0.2),
	},
	ZoneType.CITY: {
		"name": "City",
		"tile_set": "urban",
		"building_density": 0.4,
		"car_density": 0.15,
		"debris_density": 0.2,
		"enemy_types": ["zombie_walker", "zombie_runner", "zombie_crawler", "bloater", "screamer"],
		"resource_types": ["scrap_metal", "electronics", "cloth", "canned_food"],
		"ambient_color": Color(0.4, 0.4, 0.45),
	},
	ZoneType.INDUSTRIAL: {
		"name": "Industrial Zone",
		"tile_set": "industrial",
		"building_density": 0.3,
		"container_density": 0.25,
		"hazard_density": 0.1,
		"enemy_types": ["zombie_walker", "bloater", "brute", "spitter"],
		"resource_types": ["iron_ore", "copper_ore", "coal", "rubber", "acid"],
		"ambient_color": Color(0.45, 0.4, 0.35),
	},
	ZoneType.MILITARY: {
		"name": "Military Base",
		"tile_set": "military",
		"building_density": 0.25,
		"bunker_count": 2,
		"fence_perimeter": true,
		"enemy_types": ["zombie_runner", "brute", "raider_scout", "raider_gunner", "raider_heavy"],
		"resource_types": ["9mm_ammo", "rifle_ammo", "shotgun_shells", "medkit", "military_vest"],
		"ambient_color": Color(0.35, 0.4, 0.3),
	},
	ZoneType.FARM: {
		"name": "Farm",
		"tile_set": "farm",
		"field_density": 0.4,
		"barn_count": 2,
		"silo_count": 1,
		"enemy_types": ["zombie_walker", "feral_dog", "zombie_crawler"],
		"resource_types": ["carrot", "potato", "corn", "raw_meat", "leather", "plant_fiber"],
		"ambient_color": Color(0.5, 0.5, 0.3),
	},
	ZoneType.HIGHWAY: {
		"name": "Highway",
		"tile_set": "road",
		"car_density": 0.35,
		"gas_station_count": 1,
		"rest_stop_count": 1,
		"enemy_types": ["zombie_walker", "zombie_runner", "raider_scout"],
		"resource_types": ["gasoline", "engine_parts", "scrap_metal", "rubber"],
		"ambient_color": Color(0.5, 0.5, 0.5),
	},
	ZoneType.BUNKER: {
		"name": "Underground Bunker",
		"tile_set": "bunker",
		"room_count": 12,
		"corridor_width": 2,
		"has_boss": true,
		"enemy_types": ["zombie_runner", "bloater", "spitter", "brute", "the_forsaken"],
		"resource_types": ["titanium_bar", "electronics", "assault_rifle", "tactical_armor"],
		"ambient_color": Color(0.3, 0.3, 0.35),
	},
	ZoneType.SWAMP: {
		"name": "Swamp",
		"tile_set": "swamp",
		"water_density": 0.3,
		"tree_density": 0.2,
		"fog_density": 0.5,
		"enemy_types": ["zombie_crawler", "spitter", "bloater"],
		"resource_types": ["plant_fiber", "mushroom", "raw_fish", "acid"],
		"ambient_color": Color(0.3, 0.4, 0.3),
	},
	ZoneType.DESERT: {
		"name": "Desert",
		"tile_set": "desert",
		"rock_density": 0.15,
		"cactus_density": 0.1,
		"ruin_density": 0.05,
		"enemy_types": ["zombie_walker", "raider_scout", "raider_gunner"],
		"resource_types": ["stone", "iron_ore", "copper_ore", "coal"],
		"ambient_color": Color(0.6, 0.5, 0.35),
	},
	ZoneType.WINTER: {
		"name": "Winter Forest",
		"tile_set": "winter",
		"tree_density": 0.25,
		"snow_depth": 0.3,
		"cabin_count": 2,
		"enemy_types": ["zombie_walker", "wolf", "bear"],
		"resource_types": ["wood", "leather", "raw_meat", "plant_fiber"],
		"ambient_color": Color(0.7, 0.75, 0.8),
	},
}

# Difficulty multipliers
const DIFFICULTY_CONFIGS := {
	ZoneDifficulty.GREEN: {
		"enemy_count_mult": 0.5,
		"enemy_level_range": [1, 3],
		"loot_tier_max": 1,
		"boss_chance": 0.0,
		"color": Color(0.2, 0.7, 0.2),
	},
	ZoneDifficulty.YELLOW: {
		"enemy_count_mult": 1.0,
		"enemy_level_range": [3, 6],
		"loot_tier_max": 2,
		"boss_chance": 0.1,
		"color": Color(0.8, 0.7, 0.2),
	},
	ZoneDifficulty.RED: {
		"enemy_count_mult": 1.5,
		"enemy_level_range": [5, 10],
		"loot_tier_max": 3,
		"boss_chance": 0.25,
		"color": Color(0.8, 0.2, 0.2),
	},
	ZoneDifficulty.BLACK: {
		"enemy_count_mult": 2.0,
		"enemy_level_range": [8, 15],
		"loot_tier_max": 4,
		"boss_chance": 0.5,
		"color": Color(0.2, 0.2, 0.2),
	},
}


# ============================================================================
# GENERATION PARAMETERS
# ============================================================================

const ZONE_SIZE := Vector2i(64, 64)  # Tiles
const TILE_SIZE := 32  # Pixels
const CHUNK_SIZE := 16  # Tiles per chunk

var _rng: RandomNumberGenerator
var _current_seed: int
var _generation_thread: Thread


# ============================================================================
# PUBLIC API
# ============================================================================

func generate_zone(
	zone_type: ZoneType,
	difficulty: ZoneDifficulty,
	seed_value: int = -1
) -> Dictionary:
	## Generate a complete zone synchronously
	if seed_value < 0:
		seed_value = randi()
	
	_current_seed = seed_value
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	
	var zone_config: Dictionary = ZONE_CONFIGS[zone_type].duplicate(true)
	var diff_config: Dictionary = DIFFICULTY_CONFIGS[difficulty].duplicate(true)
	
	var zone_data := {
		"seed": seed_value,
		"type": zone_type,
		"difficulty": difficulty,
		"size": ZONE_SIZE,
		"tile_size": TILE_SIZE,
		"config": zone_config,
		"difficulty_config": diff_config,
		"tiles": [],
		"objects": [],
		"enemies": [],
		"loot_containers": [],
		"pois": [],
		"spawn_point": Vector2.ZERO,
		"exit_points": [],
	}
	
	# Generation stages
	emit_signal("generation_progress", 0.0, "Generating terrain...")
	_generate_terrain(zone_data)
	
	emit_signal("generation_progress", 0.2, "Placing structures...")
	_generate_structures(zone_data)
	
	emit_signal("generation_progress", 0.4, "Adding objects...")
	_generate_objects(zone_data)
	
	emit_signal("generation_progress", 0.6, "Spawning enemies...")
	_generate_enemies(zone_data)
	
	emit_signal("generation_progress", 0.8, "Placing loot...")
	_generate_loot(zone_data)
	
	emit_signal("generation_progress", 0.95, "Finalizing...")
	_generate_spawn_exit_points(zone_data)
	
	emit_signal("generation_progress", 1.0, "Complete!")
	emit_signal("zone_generated", zone_data)
	
	return zone_data


func generate_zone_async(
	zone_type: ZoneType,
	difficulty: ZoneDifficulty,
	seed_value: int = -1
) -> void:
	## Generate zone in background thread
	if _generation_thread and _generation_thread.is_started():
		push_warning("Zone generation already in progress")
		return
	
	_generation_thread = Thread.new()
	_generation_thread.start(_thread_generate.bind(zone_type, difficulty, seed_value))


func _thread_generate(zone_type: ZoneType, difficulty: ZoneDifficulty, seed_value: int) -> void:
	var zone_data := generate_zone(zone_type, difficulty, seed_value)
	call_deferred("_on_generation_complete", zone_data)


func _on_generation_complete(zone_data: Dictionary) -> void:
	if _generation_thread:
		_generation_thread.wait_to_finish()
		_generation_thread = null
	emit_signal("zone_generated", zone_data)


# ============================================================================
# TERRAIN GENERATION
# ============================================================================

func _generate_terrain(zone_data: Dictionary) -> void:
	## Generate base terrain tiles using noise
	var tiles: Array[Array] = []
	var noise := FastNoiseLite.new()
	noise.seed = _current_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	
	var zone_type: ZoneType = zone_data["type"]
	
	for y in range(ZONE_SIZE.y):
		var row: Array[int] = []
		for x in range(ZONE_SIZE.x):
			var noise_val := noise.get_noise_2d(x, y)
			var tile_type := _get_tile_from_noise(noise_val, zone_type)
			row.append(tile_type)
		tiles.append(row)
	
	# Apply cellular automata smoothing for natural look
	tiles = _smooth_terrain(tiles, 2)
	
	zone_data["tiles"] = tiles


enum TileType {
	GROUND,
	GRASS,
	DIRT,
	STONE,
	WATER,
	ROAD,
	FLOOR,
	WALL,
	SAND,
	SNOW,
	MUD,
}

func _get_tile_from_noise(noise_val: float, zone_type: ZoneType) -> int:
	## Convert noise value to tile type based on zone
	match zone_type:
		ZoneType.FOREST, ZoneType.FARM:
			if noise_val < -0.3:
				return TileType.WATER
			elif noise_val < 0.0:
				return TileType.DIRT
			else:
				return TileType.GRASS
		
		ZoneType.CITY, ZoneType.INDUSTRIAL:
			if noise_val < -0.2:
				return TileType.ROAD
			elif noise_val < 0.3:
				return TileType.GROUND
			else:
				return TileType.DIRT
		
		ZoneType.DESERT:
			if noise_val < -0.4:
				return TileType.STONE
			else:
				return TileType.SAND
		
		ZoneType.WINTER:
			if noise_val < -0.3:
				return TileType.WATER
			else:
				return TileType.SNOW
		
		ZoneType.SWAMP:
			if noise_val < 0.1:
				return TileType.WATER
			else:
				return TileType.MUD
		
		ZoneType.BUNKER:
			return TileType.FLOOR
		
		_:
			return TileType.GROUND


func _smooth_terrain(tiles: Array[Array], iterations: int) -> Array[Array]:
	## Apply cellular automata smoothing
	var result := tiles.duplicate(true)
	
	for _i in range(iterations):
		var new_tiles: Array[Array] = []
		for y in range(ZONE_SIZE.y):
			var row: Array[int] = []
			for x in range(ZONE_SIZE.x):
				var neighbor_counts := _count_neighbors(result, x, y)
				var current: int = result[y][x]
				
				# Smooth water edges
				if current == TileType.WATER:
					if neighbor_counts.get(TileType.WATER, 0) < 3:
						row.append(TileType.DIRT)
					else:
						row.append(current)
				else:
					row.append(current)
			new_tiles.append(row)
		result = new_tiles
	
	return result


func _count_neighbors(tiles: Array[Array], x: int, y: int) -> Dictionary:
	## Count tile types in 8-neighborhood
	var counts := {}
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and nx < ZONE_SIZE.x and ny >= 0 and ny < ZONE_SIZE.y:
				var tile: int = tiles[ny][nx]
				counts[tile] = counts.get(tile, 0) + 1
	return counts


# ============================================================================
# STRUCTURE GENERATION
# ============================================================================

func _generate_structures(zone_data: Dictionary) -> void:
	## Generate buildings, ruins, and other structures
	var config: Dictionary = zone_data["config"]
	var zone_type: ZoneType = zone_data["type"]
	var structures: Array[Dictionary] = []
	
	match zone_type:
		ZoneType.CITY:
			structures.append_array(_generate_city_buildings(config))
		ZoneType.INDUSTRIAL:
			structures.append_array(_generate_industrial_buildings(config))
		ZoneType.MILITARY:
			structures.append_array(_generate_military_base(config))
		ZoneType.FARM:
			structures.append_array(_generate_farm_buildings(config))
		ZoneType.HIGHWAY:
			structures.append_array(_generate_highway_structures(config))
		ZoneType.BUNKER:
			structures.append_array(_generate_bunker_rooms(config))
		ZoneType.FOREST, ZoneType.WINTER:
			structures.append_array(_generate_wilderness_structures(config))
	
	# Add structures to zone data and mark tiles as blocked
	for structure in structures:
		_place_structure(zone_data, structure)
	
	zone_data["structures"] = structures


func _generate_city_buildings(config: Dictionary) -> Array[Dictionary]:
	## Generate urban buildings
	var buildings: Array[Dictionary] = []
	var density: float = config.get("building_density", 0.3)
	var num_buildings := int(ZONE_SIZE.x * ZONE_SIZE.y * density / 64)  # Approx building count
	
	for i in range(num_buildings):
		var width := _rng.randi_range(3, 8)
		var height := _rng.randi_range(3, 8)
		var x := _rng.randi_range(2, ZONE_SIZE.x - width - 2)
		var y := _rng.randi_range(2, ZONE_SIZE.y - height - 2)
		
		buildings.append({
			"type": "building",
			"subtype": ["house", "store", "apartment", "office"][_rng.randi() % 4],
			"position": Vector2i(x, y),
			"size": Vector2i(width, height),
			"floors": _rng.randi_range(1, 3),
			"has_loot": true,
			"entry_points": [Vector2i(x + width / 2, y + height)],
		})
	
	return buildings


func _generate_industrial_buildings(config: Dictionary) -> Array[Dictionary]:
	## Generate factories, warehouses
	var buildings: Array[Dictionary] = []
	var density: float = config.get("building_density", 0.25)
	var num_buildings := int(ZONE_SIZE.x * ZONE_SIZE.y * density / 100)
	
	for i in range(num_buildings):
		var width := _rng.randi_range(6, 12)
		var height := _rng.randi_range(6, 12)
		var x := _rng.randi_range(2, ZONE_SIZE.x - width - 2)
		var y := _rng.randi_range(2, ZONE_SIZE.y - height - 2)
		
		buildings.append({
			"type": "building",
			"subtype": ["warehouse", "factory", "refinery"][_rng.randi() % 3],
			"position": Vector2i(x, y),
			"size": Vector2i(width, height),
			"has_hazards": _rng.randf() < 0.3,
			"has_loot": true,
		})
	
	return buildings


func _generate_military_base(config: Dictionary) -> Array[Dictionary]:
	## Generate military compound
	var structures: Array[Dictionary] = []
	
	# Main command building
	structures.append({
		"type": "building",
		"subtype": "command_center",
		"position": Vector2i(ZONE_SIZE.x / 2 - 5, ZONE_SIZE.y / 2 - 5),
		"size": Vector2i(10, 10),
		"is_poi": true,
		"has_loot": true,
	})
	
	# Barracks
	for i in range(2):
		structures.append({
			"type": "building",
			"subtype": "barracks",
			"position": Vector2i(10 + i * 20, 10),
			"size": Vector2i(8, 6),
			"has_loot": true,
		})
	
	# Bunkers
	var bunker_count: int = config.get("bunker_count", 2)
	for i in range(bunker_count):
		structures.append({
			"type": "bunker_entrance",
			"subtype": "bunker",
			"position": Vector2i(15 + i * 25, ZONE_SIZE.y - 15),
			"size": Vector2i(4, 4),
			"leads_to": "bunker_instance",
			"is_poi": true,
		})
	
	# Perimeter fence
	if config.get("fence_perimeter", false):
		structures.append({
			"type": "fence",
			"subtype": "chain_link",
			"bounds": Rect2i(5, 5, ZONE_SIZE.x - 10, ZONE_SIZE.y - 10),
			"gate_positions": [Vector2i(ZONE_SIZE.x / 2, 5), Vector2i(ZONE_SIZE.x / 2, ZONE_SIZE.y - 5)],
		})
	
	return structures


func _generate_farm_buildings(config: Dictionary) -> Array[Dictionary]:
	## Generate farm structures
	var structures: Array[Dictionary] = []
	
	# Farmhouse
	structures.append({
		"type": "building",
		"subtype": "farmhouse",
		"position": Vector2i(ZONE_SIZE.x / 2 - 4, ZONE_SIZE.y / 2 - 4),
		"size": Vector2i(8, 8),
		"has_loot": true,
	})
	
	# Barns
	var barn_count: int = config.get("barn_count", 2)
	for i in range(barn_count):
		structures.append({
			"type": "building",
			"subtype": "barn",
			"position": Vector2i(10 + i * 25, 15),
			"size": Vector2i(10, 8),
			"has_loot": true,
		})
	
	# Silo
	var silo_count: int = config.get("silo_count", 1)
	for i in range(silo_count):
		structures.append({
			"type": "structure",
			"subtype": "silo",
			"position": Vector2i(ZONE_SIZE.x - 15, 10 + i * 15),
			"size": Vector2i(4, 4),
		})
	
	# Crop fields
	var field_positions := [
		Vector2i(5, ZONE_SIZE.y / 2),
		Vector2i(ZONE_SIZE.x - 20, ZONE_SIZE.y / 2),
	]
	for pos in field_positions:
		structures.append({
			"type": "field",
			"subtype": ["wheat", "corn", "vegetables"][_rng.randi() % 3],
			"position": pos,
			"size": Vector2i(12, 10),
			"harvestable": true,
		})
	
	return structures


func _generate_highway_structures(config: Dictionary) -> Array[Dictionary]:
	## Generate highway rest stops
	var structures: Array[Dictionary] = []
	
	# Main road
	structures.append({
		"type": "road",
		"subtype": "highway",
		"start": Vector2i(0, ZONE_SIZE.y / 2 - 2),
		"end": Vector2i(ZONE_SIZE.x, ZONE_SIZE.y / 2 - 2),
		"width": 4,
	})
	
	# Gas station
	if config.get("gas_station_count", 0) > 0:
		structures.append({
			"type": "building",
			"subtype": "gas_station",
			"position": Vector2i(ZONE_SIZE.x / 4, ZONE_SIZE.y / 2 + 5),
			"size": Vector2i(8, 6),
			"has_loot": true,
			"is_poi": true,
		})
	
	# Rest stop
	if config.get("rest_stop_count", 0) > 0:
		structures.append({
			"type": "building",
			"subtype": "rest_stop",
			"position": Vector2i(ZONE_SIZE.x * 3 / 4, ZONE_SIZE.y / 2 + 5),
			"size": Vector2i(10, 6),
			"has_loot": true,
		})
	
	return structures


func _generate_bunker_rooms(config: Dictionary) -> Array[Dictionary]:
	## Generate dungeon-like bunker layout
	var rooms: Array[Dictionary] = []
	var room_count: int = config.get("room_count", 12)
	var corridor_width: int = config.get("corridor_width", 2)
	
	# BSP-style room generation
	var placed_rooms: Array[Rect2i] = []
	
	for i in range(room_count):
		var width := _rng.randi_range(5, 10)
		var height := _rng.randi_range(5, 10)
		var attempts := 50
		
		while attempts > 0:
			var x := _rng.randi_range(2, ZONE_SIZE.x - width - 2)
			var y := _rng.randi_range(2, ZONE_SIZE.y - height - 2)
			var room_rect := Rect2i(x, y, width, height)
			
			var overlaps := false
			for placed in placed_rooms:
				if placed.grow(2).intersects(room_rect):
					overlaps = true
					break
			
			if not overlaps:
				placed_rooms.append(room_rect)
				rooms.append({
					"type": "room",
					"subtype": _get_bunker_room_type(i, room_count),
					"position": Vector2i(x, y),
					"size": Vector2i(width, height),
					"has_loot": true,
				})
				break
			
			attempts -= 1
	
	# Connect rooms with corridors
	for i in range(len(placed_rooms) - 1):
		var room_a := placed_rooms[i]
		var room_b := placed_rooms[i + 1]
		rooms.append(_create_corridor(room_a, room_b, corridor_width))
	
	# Boss room
	if config.get("has_boss", false) and placed_rooms.size() > 0:
		rooms[-1]["is_boss_room"] = true
		rooms[-1]["subtype"] = "boss_chamber"
	
	return rooms


func _get_bunker_room_type(index: int, total: int) -> String:
	if index == 0:
		return "entrance"
	elif index == total - 1:
		return "boss_chamber"
	else:
		var types := ["storage", "barracks", "lab", "armory", "server_room", "medical"]
		return types[_rng.randi() % types.size()]


func _create_corridor(room_a: Rect2i, room_b: Rect2i, width: int) -> Dictionary:
	var center_a := room_a.get_center()
	var center_b := room_b.get_center()
	
	return {
		"type": "corridor",
		"start": center_a,
		"end": center_b,
		"width": width,
	}


func _generate_wilderness_structures(config: Dictionary) -> Array[Dictionary]:
	## Generate forest/winter structures (cabins, camps)
	var structures: Array[Dictionary] = []
	
	var cabin_count: int = config.get("cabin_count", 2)
	for i in range(cabin_count):
		var x := _rng.randi_range(10, ZONE_SIZE.x - 15)
		var y := _rng.randi_range(10, ZONE_SIZE.y - 15)
		structures.append({
			"type": "building",
			"subtype": "cabin",
			"position": Vector2i(x, y),
			"size": Vector2i(5, 5),
			"has_loot": true,
		})
	
	# Random camps
	var camp_count := _rng.randi_range(1, 3)
	for i in range(camp_count):
		var x := _rng.randi_range(5, ZONE_SIZE.x - 10)
		var y := _rng.randi_range(5, ZONE_SIZE.y - 10)
		structures.append({
			"type": "camp",
			"subtype": ["survivor_camp", "raider_camp", "abandoned_camp"][_rng.randi() % 3],
			"position": Vector2i(x, y),
			"size": Vector2i(4, 4),
			"has_loot": true,
		})
	
	return structures


func _place_structure(zone_data: Dictionary, structure: Dictionary) -> void:
	## Mark tiles as occupied by structure
	var tiles: Array = zone_data["tiles"]
	var pos: Vector2i = structure.get("position", Vector2i.ZERO)
	var size: Vector2i = structure.get("size", Vector2i(1, 1))
	
	for y in range(pos.y, min(pos.y + size.y, ZONE_SIZE.y)):
		for x in range(pos.x, min(pos.x + size.x, ZONE_SIZE.x)):
			if structure["type"] == "building" or structure["type"] == "room":
				tiles[y][x] = TileType.FLOOR
			elif structure["type"] == "road":
				tiles[y][x] = TileType.ROAD


# ============================================================================
# OBJECT GENERATION
# ============================================================================

func _generate_objects(zone_data: Dictionary) -> void:
	## Generate trees, rocks, bushes, props
	var config: Dictionary = zone_data["config"]
	var objects: Array[Dictionary] = []
	var tiles: Array = zone_data["tiles"]
	var blocked := _get_blocked_positions(zone_data)
	
	# Trees
	var tree_density: float = config.get("tree_density", 0.0)
	if tree_density > 0:
		objects.append_array(_scatter_objects("tree", tree_density, tiles, blocked))
	
	# Rocks
	var rock_density: float = config.get("rock_density", 0.0)
	if rock_density > 0:
		objects.append_array(_scatter_objects("rock", rock_density, tiles, blocked))
	
	# Bushes
	var bush_density: float = config.get("bush_density", 0.0)
	if bush_density > 0:
		objects.append_array(_scatter_objects("bush", bush_density, tiles, blocked))
	
	# Cars (for urban areas)
	var car_density: float = config.get("car_density", 0.0)
	if car_density > 0:
		objects.append_array(_scatter_objects("car", car_density, tiles, blocked, [TileType.ROAD, TileType.GROUND]))
	
	# Debris
	var debris_density: float = config.get("debris_density", 0.0)
	if debris_density > 0:
		objects.append_array(_scatter_objects("debris", debris_density, tiles, blocked))
	
	# Containers
	var container_density: float = config.get("container_density", 0.0)
	if container_density > 0:
		objects.append_array(_scatter_objects("container", container_density, tiles, blocked))
	
	zone_data["objects"] = objects


func _scatter_objects(
	obj_type: String,
	density: float,
	tiles: Array,
	blocked: Dictionary,
	allowed_tiles: Array[int] = []
) -> Array[Dictionary]:
	## Scatter objects using Poisson disk sampling approximation
	var objects: Array[Dictionary] = []
	var count := int(ZONE_SIZE.x * ZONE_SIZE.y * density)
	
	for i in range(count):
		var x := _rng.randi_range(1, ZONE_SIZE.x - 2)
		var y := _rng.randi_range(1, ZONE_SIZE.y - 2)
		var pos := Vector2i(x, y)
		
		# Skip if blocked
		if pos in blocked:
			continue
		
		# Check allowed tiles
		var tile_type: int = tiles[y][x]
		if allowed_tiles.size() > 0 and tile_type not in allowed_tiles:
			continue
		
		# Skip water
		if tile_type == TileType.WATER:
			continue
		
		objects.append({
			"type": obj_type,
			"position": pos,
			"variant": _rng.randi() % 4,
			"rotation": _rng.randf() * TAU,
		})
		
		blocked[pos] = true
	
	return objects


func _get_blocked_positions(zone_data: Dictionary) -> Dictionary:
	## Get all positions blocked by structures
	var blocked := {}
	
	for structure in zone_data.get("structures", []):
		var pos: Vector2i = structure.get("position", Vector2i.ZERO)
		var size: Vector2i = structure.get("size", Vector2i(1, 1))
		
		for y in range(pos.y - 1, pos.y + size.y + 1):
			for x in range(pos.x - 1, pos.x + size.x + 1):
				blocked[Vector2i(x, y)] = true
	
	return blocked


# ============================================================================
# ENEMY GENERATION
# ============================================================================

func _generate_enemies(zone_data: Dictionary) -> void:
	## Spawn enemies throughout the zone
	var config: Dictionary = zone_data["config"]
	var diff_config: Dictionary = zone_data["difficulty_config"]
	var enemies: Array[Dictionary] = []
	
	var enemy_types: Array = config.get("enemy_types", ["zombie_walker"])
	var count_mult: float = diff_config.get("enemy_count_mult", 1.0)
	var level_range: Array = diff_config.get("enemy_level_range", [1, 5])
	
	var base_count := int(ZONE_SIZE.x * ZONE_SIZE.y / 100)
	var enemy_count := int(base_count * count_mult)
	
	var blocked := _get_blocked_positions(zone_data)
	var tiles: Array = zone_data["tiles"]
	
	for i in range(enemy_count):
		var attempts := 20
		while attempts > 0:
			var x := _rng.randi_range(5, ZONE_SIZE.x - 5)
			var y := _rng.randi_range(5, ZONE_SIZE.y - 5)
			var pos := Vector2i(x, y)
			
			if pos in blocked:
				attempts -= 1
				continue
			
			var tile_type: int = tiles[y][x]
			if tile_type == TileType.WATER or tile_type == TileType.WALL:
				attempts -= 1
				continue
			
			var enemy_type: String = enemy_types[_rng.randi() % enemy_types.size()]
			var level := _rng.randi_range(level_range[0], level_range[1])
			
			enemies.append({
				"type": enemy_type,
				"position": pos,
				"level": level,
				"patrol_radius": _rng.randi_range(3, 8),
				"is_sleeping": _rng.randf() < 0.2,
			})
			
			blocked[pos] = true
			break
	
	# Boss spawn
	var boss_chance: float = diff_config.get("boss_chance", 0.0)
	if _rng.randf() < boss_chance:
		var boss_types := ["ravager", "the_forsaken", "brute"]
		var boss_type: String = boss_types[_rng.randi() % boss_types.size()]
		
		# Place boss in a POI or center
		var boss_pos := Vector2i(ZONE_SIZE.x / 2, ZONE_SIZE.y / 2)
		for structure in zone_data.get("structures", []):
			if structure.get("is_boss_room", false) or structure.get("is_poi", false):
				boss_pos = structure["position"] + structure["size"] / 2
				break
		
		enemies.append({
			"type": boss_type,
			"position": boss_pos,
			"level": level_range[1] + 5,
			"is_boss": true,
		})
	
	zone_data["enemies"] = enemies


# ============================================================================
# LOOT GENERATION
# ============================================================================

func _generate_loot(zone_data: Dictionary) -> void:
	## Generate loot containers and resource nodes
	var config: Dictionary = zone_data["config"]
	var diff_config: Dictionary = zone_data["difficulty_config"]
	var loot_containers: Array[Dictionary] = []
	var resource_nodes: Array[Dictionary] = []
	
	var resource_types: Array = config.get("resource_types", [])
	var loot_tier_max: int = diff_config.get("loot_tier_max", 2)
	
	# Place loot in structures
	for structure in zone_data.get("structures", []):
		if structure.get("has_loot", false):
			var container_count := _rng.randi_range(1, 4)
			var pos: Vector2i = structure["position"]
			var size: Vector2i = structure["size"]
			
			for i in range(container_count):
				var loot_x := _rng.randi_range(pos.x + 1, pos.x + size.x - 2)
				var loot_y := _rng.randi_range(pos.y + 1, pos.y + size.y - 2)
				
				loot_containers.append({
					"type": _get_container_type(structure["subtype"]),
					"position": Vector2i(loot_x, loot_y),
					"tier": mini(_rng.randi_range(1, loot_tier_max + 1), loot_tier_max),
					"is_locked": _rng.randf() < 0.2,
					"searched": false,
				})
	
	# Scatter resource nodes
	var blocked := _get_blocked_positions(zone_data)
	var tiles: Array = zone_data["tiles"]
	var resource_count := int(ZONE_SIZE.x * ZONE_SIZE.y / 80)
	
	for i in range(resource_count):
		var x := _rng.randi_range(2, ZONE_SIZE.x - 2)
		var y := _rng.randi_range(2, ZONE_SIZE.y - 2)
		var pos := Vector2i(x, y)
		
		if pos in blocked:
			continue
		
		var tile_type: int = tiles[y][x]
		if tile_type == TileType.WATER or tile_type == TileType.WALL:
			continue
		
		if resource_types.size() > 0:
			var res_type: String = resource_types[_rng.randi() % resource_types.size()]
			resource_nodes.append({
				"type": res_type,
				"position": pos,
				"amount": _rng.randi_range(1, 5),
				"respawn_time": _rng.randi_range(300, 900),
			})
			blocked[pos] = true
	
	zone_data["loot_containers"] = loot_containers
	zone_data["resource_nodes"] = resource_nodes


func _get_container_type(structure_type: String) -> String:
	match structure_type:
		"warehouse", "factory", "industrial":
			return ["crate", "barrel", "toolbox"][_rng.randi() % 3]
		"house", "apartment", "farmhouse", "cabin":
			return ["dresser", "cabinet", "fridge", "chest"][_rng.randi() % 4]
		"barracks", "command_center", "armory":
			return ["military_crate", "locker", "weapon_rack"][_rng.randi() % 3]
		"gas_station", "rest_stop":
			return ["shelf", "register", "cooler"][_rng.randi() % 3]
		"lab", "server_room", "medical":
			return ["medical_cabinet", "safe", "desk"][_rng.randi() % 3]
		_:
			return "crate"


# ============================================================================
# SPAWN & EXIT POINTS
# ============================================================================

func _generate_spawn_exit_points(zone_data: Dictionary) -> void:
	## Set player spawn and zone exit points
	var tiles: Array = zone_data["tiles"]
	var blocked := _get_blocked_positions(zone_data)
	
	# Spawn point - edge of map, on walkable tile
	var spawn_found := false
	var spawn_pos := Vector2i(5, ZONE_SIZE.y / 2)
	
	for x in range(3, 10):
		for y in range(ZONE_SIZE.y / 2 - 5, ZONE_SIZE.y / 2 + 5):
			var pos := Vector2i(x, y)
			if pos not in blocked:
				var tile: int = tiles[y][x]
				if tile != TileType.WATER and tile != TileType.WALL:
					spawn_pos = pos
					spawn_found = true
					break
		if spawn_found:
			break
	
	zone_data["spawn_point"] = spawn_pos
	
	# Exit points - at edges of map
	var exits: Array[Dictionary] = []
	
	# North exit
	exits.append({
		"direction": "north",
		"position": Vector2i(ZONE_SIZE.x / 2, 0),
		"leads_to": null,  # Will be set by world manager
	})
	
	# South exit
	exits.append({
		"direction": "south",
		"position": Vector2i(ZONE_SIZE.x / 2, ZONE_SIZE.y - 1),
		"leads_to": null,
	})
	
	# East exit
	exits.append({
		"direction": "east",
		"position": Vector2i(ZONE_SIZE.x - 1, ZONE_SIZE.y / 2),
		"leads_to": null,
	})
	
	# West exit
	exits.append({
		"direction": "west",
		"position": Vector2i(0, ZONE_SIZE.y / 2),
		"leads_to": null,
	})
	
	zone_data["exit_points"] = exits


# ============================================================================
# UTILITY
# ============================================================================

func get_zone_name(zone_type: ZoneType) -> String:
	return ZONE_CONFIGS.get(zone_type, {}).get("name", "Unknown")


func get_difficulty_color(difficulty: ZoneDifficulty) -> Color:
	return DIFFICULTY_CONFIGS.get(difficulty, {}).get("color", Color.WHITE)


func serialize_zone(zone_data: Dictionary) -> Dictionary:
	## Convert zone data to saveable format
	var save_data := zone_data.duplicate(true)
	# Convert Vector2i to arrays for JSON
	save_data["spawn_point"] = [zone_data["spawn_point"].x, zone_data["spawn_point"].y]
	save_data["size"] = [zone_data["size"].x, zone_data["size"].y]
	return save_data


func deserialize_zone(save_data: Dictionary) -> Dictionary:
	## Restore zone data from save
	var zone_data := save_data.duplicate(true)
	zone_data["spawn_point"] = Vector2i(save_data["spawn_point"][0], save_data["spawn_point"][1])
	zone_data["size"] = Vector2i(save_data["size"][0], save_data["size"][1])
	return zone_data
