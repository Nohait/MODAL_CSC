extends Node
class_name LootContainerSystemClass
## Manages loot containers, loot tables, and random item generation
## Supports tiered loot, guaranteed drops, and location-specific rewards

signal container_opened(container_id: String, loot: Array)
signal container_looted(container_id: String)
signal rare_item_found(item_id: String, container_id: String)

# ============================================================================
# CONTAINER TYPES
# ============================================================================

enum ContainerType {
	BASIC_CRATE,
	WOODEN_CHEST,
	METAL_CHEST,
	MILITARY_CRATE,
	MEDICAL_BOX,
	FOOD_CACHE,
	WEAPON_RACK,
	TOOL_CABINET,
	SAFE,
	RARE_CHEST,
	BOSS_CHEST,
	EVENT_CHEST,
	AIRDROP,
	BURIED_CACHE,
	VEHICLE_TRUNK,
}

enum LootRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

# Container definitions
const CONTAINER_DEFINITIONS := {
	ContainerType.BASIC_CRATE: {
		"display_name": "Basic Crate",
		"loot_table": "basic",
		"item_count": [1, 3],
		"lock_type": null,
		"respawn_time": 300,
		"sprite": "basic_crate",
	},
	ContainerType.WOODEN_CHEST: {
		"display_name": "Wooden Chest",
		"loot_table": "common",
		"item_count": [2, 4],
		"lock_type": null,
		"respawn_time": 600,
		"sprite": "wooden_chest",
	},
	ContainerType.METAL_CHEST: {
		"display_name": "Metal Chest",
		"loot_table": "uncommon",
		"item_count": [2, 5],
		"lock_type": "basic",
		"respawn_time": 900,
		"sprite": "metal_chest",
	},
	ContainerType.MILITARY_CRATE: {
		"display_name": "Military Crate",
		"loot_table": "military",
		"item_count": [3, 6],
		"lock_type": "military",
		"respawn_time": 3600,
		"sprite": "military_crate",
	},
	ContainerType.MEDICAL_BOX: {
		"display_name": "Medical Box",
		"loot_table": "medical",
		"item_count": [2, 4],
		"lock_type": null,
		"respawn_time": 1200,
		"sprite": "medical_box",
	},
	ContainerType.FOOD_CACHE: {
		"display_name": "Food Cache",
		"loot_table": "food",
		"item_count": [2, 5],
		"lock_type": null,
		"respawn_time": 600,
		"sprite": "food_cache",
	},
	ContainerType.WEAPON_RACK: {
		"display_name": "Weapon Rack",
		"loot_table": "weapons",
		"item_count": [1, 3],
		"lock_type": "basic",
		"respawn_time": 1800,
		"sprite": "weapon_rack",
	},
	ContainerType.TOOL_CABINET: {
		"display_name": "Tool Cabinet",
		"loot_table": "tools",
		"item_count": [2, 4],
		"lock_type": null,
		"respawn_time": 900,
		"sprite": "tool_cabinet",
	},
	ContainerType.SAFE: {
		"display_name": "Safe",
		"loot_table": "rare",
		"item_count": [3, 5],
		"lock_type": "combination",
		"respawn_time": 7200,
		"sprite": "safe",
	},
	ContainerType.RARE_CHEST: {
		"display_name": "Rare Chest",
		"loot_table": "rare",
		"item_count": [3, 6],
		"lock_type": "key",
		"respawn_time": 10800,
		"sprite": "rare_chest",
	},
	ContainerType.BOSS_CHEST: {
		"display_name": "Boss Chest",
		"loot_table": "boss",
		"item_count": [4, 8],
		"lock_type": null,
		"respawn_time": 0,  # One-time
		"sprite": "boss_chest",
	},
	ContainerType.EVENT_CHEST: {
		"display_name": "Event Chest",
		"loot_table": "event",
		"item_count": [3, 6],
		"lock_type": null,
		"respawn_time": 0,  # One-time
		"sprite": "event_chest",
	},
	ContainerType.AIRDROP: {
		"display_name": "Airdrop",
		"loot_table": "airdrop",
		"item_count": [4, 7],
		"lock_type": null,
		"respawn_time": 0,  # One-time
		"sprite": "airdrop",
	},
	ContainerType.BURIED_CACHE: {
		"display_name": "Buried Cache",
		"loot_table": "buried",
		"item_count": [2, 5],
		"lock_type": null,
		"respawn_time": 86400,  # 24 hours
		"sprite": "buried_cache",
	},
	ContainerType.VEHICLE_TRUNK: {
		"display_name": "Vehicle Trunk",
		"loot_table": "vehicle",
		"item_count": [1, 4],
		"lock_type": null,
		"respawn_time": 3600,
		"sprite": "vehicle_trunk",
	},
}

# ============================================================================
# LOOT TABLES
# ============================================================================

const LOOT_TABLES := {
	"basic": {
		"common": 70, "uncommon": 25, "rare": 5,
		"items": {
			LootRarity.COMMON: [
				{"id": "wood", "count": [1, 5], "weight": 10},
				{"id": "stone", "count": [1, 5], "weight": 10},
				{"id": "plant_fiber", "count": [1, 3], "weight": 10},
				{"id": "cloth", "count": [1, 2], "weight": 8},
				{"id": "rope", "count": [1, 2], "weight": 6},
			],
			LootRarity.UNCOMMON: [
				{"id": "iron_ore", "count": [1, 3], "weight": 10},
				{"id": "leather", "count": [1, 2], "weight": 8},
				{"id": "bandage", "count": [1, 2], "weight": 7},
			],
			LootRarity.RARE: [
				{"id": "nails", "count": [5, 15], "weight": 10},
				{"id": "duct_tape", "count": [1, 2], "weight": 8},
			],
		},
	},
	"common": {
		"common": 60, "uncommon": 30, "rare": 10,
		"items": {
			LootRarity.COMMON: [
				{"id": "wood", "count": [2, 8], "weight": 10},
				{"id": "stone", "count": [2, 8], "weight": 10},
				{"id": "cloth", "count": [1, 4], "weight": 8},
				{"id": "plant_fiber", "count": [2, 5], "weight": 8},
				{"id": "empty_bottle", "count": [1, 2], "weight": 6},
			],
			LootRarity.UNCOMMON: [
				{"id": "iron_ore", "count": [2, 5], "weight": 10},
				{"id": "leather", "count": [1, 3], "weight": 8},
				{"id": "scrap_metal", "count": [1, 4], "weight": 9},
				{"id": "nails", "count": [5, 20], "weight": 7},
			],
			LootRarity.RARE: [
				{"id": "copper_ore", "count": [1, 3], "weight": 10},
				{"id": "electronics", "count": [1, 2], "weight": 8},
				{"id": "duct_tape", "count": [1, 3], "weight": 7},
			],
		},
	},
	"uncommon": {
		"common": 45, "uncommon": 40, "rare": 15,
		"items": {
			LootRarity.COMMON: [
				{"id": "iron_ore", "count": [2, 6], "weight": 10},
				{"id": "scrap_metal", "count": [2, 6], "weight": 10},
				{"id": "nails", "count": [10, 30], "weight": 8},
			],
			LootRarity.UNCOMMON: [
				{"id": "copper_ore", "count": [2, 4], "weight": 10},
				{"id": "electronics", "count": [1, 3], "weight": 9},
				{"id": "aluminum_bar", "count": [1, 2], "weight": 8},
				{"id": "steel_plate", "count": [1, 2], "weight": 7},
			],
			LootRarity.RARE: [
				{"id": "titanium_bar", "count": [1, 2], "weight": 10},
				{"id": "circuit_board", "count": [1, 2], "weight": 9},
				{"id": "battery", "count": [1, 2], "weight": 8},
			],
		},
	},
	"military": {
		"common": 30, "uncommon": 45, "rare": 20, "epic": 5,
		"items": {
			LootRarity.COMMON: [
				{"id": "scrap_metal", "count": [3, 8], "weight": 10},
				{"id": "steel_plate", "count": [1, 3], "weight": 9},
				{"id": "9mm_ammo", "count": [5, 15], "weight": 8},
				{"id": "5.56mm_ammo", "count": [3, 10], "weight": 7},
			],
			LootRarity.UNCOMMON: [
				{"id": "military_grade_steel", "count": [1, 3], "weight": 10},
				{"id": "kevlar_fiber", "count": [1, 2], "weight": 9},
				{"id": "gun_oil", "count": [1, 2], "weight": 8},
				{"id": "weapon_parts", "count": [1, 3], "weight": 9},
				{"id": "7.62mm_ammo", "count": [3, 8], "weight": 7},
			],
			LootRarity.RARE: [
				{"id": "military_knife", "count": [1, 1], "weight": 10},
				{"id": "combat_pistol", "count": [1, 1], "weight": 8},
				{"id": "tactical_vest", "count": [1, 1], "weight": 7},
				{"id": "night_vision_parts", "count": [1, 1], "weight": 5},
			],
			LootRarity.EPIC: [
				{"id": "assault_rifle", "count": [1, 1], "weight": 10},
				{"id": "sniper_rifle", "count": [1, 1], "weight": 6},
				{"id": "military_backpack", "count": [1, 1], "weight": 8},
			],
		},
	},
	"medical": {
		"common": 50, "uncommon": 35, "rare": 15,
		"items": {
			LootRarity.COMMON: [
				{"id": "bandage", "count": [2, 5], "weight": 10},
				{"id": "alcohol", "count": [1, 3], "weight": 9},
				{"id": "herb", "count": [2, 4], "weight": 8},
			],
			LootRarity.UNCOMMON: [
				{"id": "first_aid_kit", "count": [1, 2], "weight": 10},
				{"id": "painkillers", "count": [1, 3], "weight": 9},
				{"id": "antibiotics", "count": [1, 2], "weight": 8},
				{"id": "blood_bag", "count": [1, 1], "weight": 6},
			],
			LootRarity.RARE: [
				{"id": "medkit", "count": [1, 1], "weight": 10},
				{"id": "antidote", "count": [1, 2], "weight": 9},
				{"id": "adrenaline", "count": [1, 1], "weight": 7},
			],
		},
	},
	"food": {
		"common": 65, "uncommon": 30, "rare": 5,
		"items": {
			LootRarity.COMMON: [
				{"id": "canned_beans", "count": [1, 3], "weight": 10},
				{"id": "water_bottle", "count": [1, 2], "weight": 10},
				{"id": "berries", "count": [3, 8], "weight": 8},
				{"id": "raw_meat", "count": [1, 2], "weight": 7},
			],
			LootRarity.UNCOMMON: [
				{"id": "cooked_meat", "count": [1, 2], "weight": 10},
				{"id": "mre", "count": [1, 2], "weight": 9},
				{"id": "energy_drink", "count": [1, 2], "weight": 8},
			],
			LootRarity.RARE: [
				{"id": "premium_food", "count": [1, 1], "weight": 10},
				{"id": "survival_ration", "count": [1, 2], "weight": 8},
			],
		},
	},
	"weapons": {
		"common": 40, "uncommon": 40, "rare": 15, "epic": 5,
		"items": {
			LootRarity.COMMON: [
				{"id": "baseball_bat", "count": [1, 1], "weight": 10},
				{"id": "pipe_wrench", "count": [1, 1], "weight": 10},
				{"id": "machete", "count": [1, 1], "weight": 8},
				{"id": "crowbar", "count": [1, 1], "weight": 9},
			],
			LootRarity.UNCOMMON: [
				{"id": "hunting_knife", "count": [1, 1], "weight": 10},
				{"id": "compound_bow", "count": [1, 1], "weight": 8},
				{"id": "revolver", "count": [1, 1], "weight": 7},
				{"id": "shotgun", "count": [1, 1], "weight": 6},
			],
			LootRarity.RARE: [
				{"id": "katana", "count": [1, 1], "weight": 10},
				{"id": "combat_shotgun", "count": [1, 1], "weight": 8},
				{"id": "smg", "count": [1, 1], "weight": 9},
			],
			LootRarity.EPIC: [
				{"id": "assault_rifle", "count": [1, 1], "weight": 10},
				{"id": "sniper_rifle", "count": [1, 1], "weight": 7},
			],
		},
	},
	"tools": {
		"common": 50, "uncommon": 40, "rare": 10,
		"items": {
			LootRarity.COMMON: [
				{"id": "wooden_hatchet", "count": [1, 1], "weight": 10},
				{"id": "stone_pickaxe", "count": [1, 1], "weight": 10},
				{"id": "torch", "count": [1, 3], "weight": 8},
			],
			LootRarity.UNCOMMON: [
				{"id": "iron_hatchet", "count": [1, 1], "weight": 10},
				{"id": "iron_pickaxe", "count": [1, 1], "weight": 10},
				{"id": "fishing_rod", "count": [1, 1], "weight": 7},
				{"id": "repair_kit", "count": [1, 2], "weight": 8},
			],
			LootRarity.RARE: [
				{"id": "steel_hatchet", "count": [1, 1], "weight": 10},
				{"id": "steel_pickaxe", "count": [1, 1], "weight": 10},
				{"id": "chainsaw", "count": [1, 1], "weight": 5},
			],
		},
	},
	"rare": {
		"common": 20, "uncommon": 40, "rare": 30, "epic": 10,
		"items": {
			LootRarity.COMMON: [
				{"id": "copper_ore", "count": [3, 8], "weight": 10},
				{"id": "electronics", "count": [2, 5], "weight": 10},
				{"id": "aluminum_bar", "count": [2, 4], "weight": 9},
			],
			LootRarity.UNCOMMON: [
				{"id": "titanium_bar", "count": [2, 4], "weight": 10},
				{"id": "circuit_board", "count": [2, 4], "weight": 9},
				{"id": "military_grade_steel", "count": [2, 4], "weight": 8},
			],
			LootRarity.RARE: [
				{"id": "modular_parts", "count": [1, 3], "weight": 10},
				{"id": "weapon_mod_kit", "count": [1, 2], "weight": 9},
				{"id": "rare_blueprint", "count": [1, 1], "weight": 7},
			],
			LootRarity.EPIC: [
				{"id": "legendary_material", "count": [1, 2], "weight": 10},
				{"id": "epic_weapon", "count": [1, 1], "weight": 6},
			],
		},
	},
	"boss": {
		"uncommon": 30, "rare": 45, "epic": 20, "legendary": 5,
		"guaranteed": ["boss_trophy"],
		"items": {
			LootRarity.UNCOMMON: [
				{"id": "titanium_bar", "count": [5, 10], "weight": 10},
				{"id": "military_grade_steel", "count": [3, 6], "weight": 10},
			],
			LootRarity.RARE: [
				{"id": "modular_parts", "count": [2, 5], "weight": 10},
				{"id": "weapon_mod_kit", "count": [1, 3], "weight": 9},
				{"id": "rare_blueprint", "count": [1, 2], "weight": 8},
			],
			LootRarity.EPIC: [
				{"id": "legendary_material", "count": [1, 3], "weight": 10},
				{"id": "epic_weapon", "count": [1, 1], "weight": 8},
				{"id": "epic_armor", "count": [1, 1], "weight": 7},
			],
			LootRarity.LEGENDARY: [
				{"id": "legendary_weapon", "count": [1, 1], "weight": 10},
				{"id": "legendary_armor", "count": [1, 1], "weight": 8},
				{"id": "unique_item", "count": [1, 1], "weight": 5},
			],
		},
	},
	"airdrop": {
		"uncommon": 25, "rare": 50, "epic": 25,
		"items": {
			LootRarity.UNCOMMON: [
				{"id": "assault_rifle", "count": [1, 1], "weight": 10},
				{"id": "military_backpack", "count": [1, 1], "weight": 8},
				{"id": "5.56mm_ammo", "count": [30, 60], "weight": 10},
			],
			LootRarity.RARE: [
				{"id": "sniper_rifle", "count": [1, 1], "weight": 10},
				{"id": "combat_armor", "count": [1, 1], "weight": 9},
				{"id": "medkit", "count": [2, 4], "weight": 8},
				{"id": "7.62mm_ammo", "count": [30, 50], "weight": 9},
			],
			LootRarity.EPIC: [
				{"id": "legendary_material", "count": [2, 4], "weight": 10},
				{"id": "epic_weapon", "count": [1, 1], "weight": 8},
				{"id": "vehicle_part", "count": [1, 2], "weight": 9},
			],
		},
	},
	"event": {
		"uncommon": 30, "rare": 45, "epic": 25,
		"items": {
			LootRarity.UNCOMMON: [
				{"id": "event_token", "count": [5, 15], "weight": 10},
				{"id": "titanium_bar", "count": [3, 6], "weight": 9},
			],
			LootRarity.RARE: [
				{"id": "event_token", "count": [10, 25], "weight": 10},
				{"id": "rare_blueprint", "count": [1, 2], "weight": 8},
				{"id": "modular_parts", "count": [2, 4], "weight": 9},
			],
			LootRarity.EPIC: [
				{"id": "event_exclusive_item", "count": [1, 1], "weight": 10},
				{"id": "legendary_material", "count": [1, 3], "weight": 8},
			],
		},
	},
	"buried": {
		"uncommon": 35, "rare": 45, "epic": 20,
		"items": {
			LootRarity.UNCOMMON: [
				{"id": "gold_coin", "count": [5, 15], "weight": 10},
				{"id": "jewelry", "count": [1, 3], "weight": 9},
			],
			LootRarity.RARE: [
				{"id": "gold_bar", "count": [1, 2], "weight": 10},
				{"id": "rare_artifact", "count": [1, 1], "weight": 8},
				{"id": "treasure_map", "count": [1, 1], "weight": 5},
			],
			LootRarity.EPIC: [
				{"id": "ancient_relic", "count": [1, 1], "weight": 10},
				{"id": "legendary_material", "count": [1, 2], "weight": 8},
			],
		},
	},
	"vehicle": {
		"common": 45, "uncommon": 40, "rare": 15,
		"items": {
			LootRarity.COMMON: [
				{"id": "scrap_metal", "count": [3, 8], "weight": 10},
				{"id": "rubber", "count": [1, 3], "weight": 9},
				{"id": "gasoline", "count": [5, 15], "weight": 10},
			],
			LootRarity.UNCOMMON: [
				{"id": "vehicle_part", "count": [1, 2], "weight": 10},
				{"id": "engine_part", "count": [1, 1], "weight": 8},
				{"id": "battery", "count": [1, 1], "weight": 7},
			],
			LootRarity.RARE: [
				{"id": "turbine_part", "count": [1, 1], "weight": 10},
				{"id": "transmission", "count": [1, 1], "weight": 7},
			],
		},
	},
}


# ============================================================================
# STATE
# ============================================================================

var _containers: Dictionary = {}  # container_id -> container data
var _looted_containers: Dictionary = {}  # container_id -> loot timestamp
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func _process(_delta: float) -> void:
	_check_respawns()


# ============================================================================
# CONTAINER MANAGEMENT
# ============================================================================

func spawn_container(container_type: int, position: Vector2, zone_difficulty: int = 0) -> Dictionary:
	## Spawn a loot container at the given position
	var definition: Dictionary = CONTAINER_DEFINITIONS.get(container_type, {})
	if definition.is_empty():
		return {}
	
	var container_id := "%d_%d_%d_%d" % [container_type, int(position.x), int(position.y), randi()]
	
	# Check if already looted
	var is_looted := container_id in _looted_containers
	var respawn_remaining := 0.0
	
	if is_looted:
		var looted_time: int = _looted_containers[container_id]
		var respawn_time: int = definition.get("respawn_time", 600)
		var current_time := int(Time.get_unix_time_from_system())
		
		if respawn_time > 0 and current_time - looted_time >= respawn_time:
			_looted_containers.erase(container_id)
			is_looted = false
		else:
			respawn_remaining = respawn_time - (current_time - looted_time)
	
	var container := {
		"id": container_id,
		"type": container_type,
		"display_name": definition.get("display_name", "Container"),
		"position": position,
		"loot_table": definition.get("loot_table", "basic"),
		"item_count": definition.get("item_count", [1, 3]),
		"lock_type": definition.get("lock_type", null),
		"respawn_time": definition.get("respawn_time", 600),
		"sprite": definition.get("sprite", "basic_crate"),
		"zone_difficulty": zone_difficulty,
		"is_looted": is_looted,
		"respawn_remaining": respawn_remaining,
		"contents": [],
		"generated": false,
	}
	
	_containers[container_id] = container
	return container


func spawn_containers_for_zone(zone_data: Dictionary) -> Array[Dictionary]:
	## Generate containers for a zone
	var containers: Array[Dictionary] = []
	var zone_type: int = zone_data.get("type", 0)
	var difficulty: int = zone_data.get("difficulty", 0)
	var zone_seed: int = zone_data.get("seed", randi())
	var zone_size: Vector2i = zone_data.get("size", Vector2i(64, 64))
	
	_rng.seed = zone_seed + 12345
	
	# Determine container counts by zone type
	var container_counts := _get_zone_container_weights(zone_type, difficulty)
	var placed: Dictionary = {}
	
	for container_type in container_counts:
		var count: int = container_counts[container_type]
		
		for i in range(count):
			var pos := _find_container_position(zone_data, placed)
			if pos == Vector2(-1, -1):
				continue
			
			placed[pos] = true
			var container := spawn_container(container_type, pos * 32, difficulty)
			if not container.is_empty():
				containers.append(container)
	
	return containers


func _get_zone_container_weights(zone_type: int, difficulty: int) -> Dictionary:
	var base_counts := {
		0: {  # FOREST
			ContainerType.BASIC_CRATE: 3,
			ContainerType.WOODEN_CHEST: 2,
			ContainerType.FOOD_CACHE: 1,
		},
		1: {  # CITY
			ContainerType.BASIC_CRATE: 5,
			ContainerType.WOODEN_CHEST: 3,
			ContainerType.METAL_CHEST: 2,
			ContainerType.FOOD_CACHE: 2,
			ContainerType.MEDICAL_BOX: 1,
		},
		2: {  # INDUSTRIAL
			ContainerType.METAL_CHEST: 4,
			ContainerType.TOOL_CABINET: 3,
			ContainerType.BASIC_CRATE: 2,
		},
		3: {  # MILITARY
			ContainerType.MILITARY_CRATE: 4,
			ContainerType.WEAPON_RACK: 2,
			ContainerType.MEDICAL_BOX: 2,
			ContainerType.SAFE: 1,
		},
		4: {  # FARM
			ContainerType.FOOD_CACHE: 4,
			ContainerType.WOODEN_CHEST: 2,
			ContainerType.BASIC_CRATE: 2,
		},
		5: {  # HIGHWAY
			ContainerType.VEHICLE_TRUNK: 3,
			ContainerType.BASIC_CRATE: 2,
		},
		6: {  # BUNKER
			ContainerType.MILITARY_CRATE: 5,
			ContainerType.RARE_CHEST: 2,
			ContainerType.SAFE: 2,
			ContainerType.MEDICAL_BOX: 2,
		},
		7: {  # SWAMP
			ContainerType.BASIC_CRATE: 2,
			ContainerType.BURIED_CACHE: 2,
		},
		8: {  # DESERT
			ContainerType.BURIED_CACHE: 3,
			ContainerType.BASIC_CRATE: 2,
		},
		9: {  # WINTER
			ContainerType.BASIC_CRATE: 2,
			ContainerType.FOOD_CACHE: 2,
		},
	}
	
	var counts: Dictionary = base_counts.get(zone_type, {ContainerType.BASIC_CRATE: 2})
	
	# Modify by difficulty
	var multiplier := 1.0 + difficulty * 0.2
	for container_type in counts:
		counts[container_type] = int(counts[container_type] * multiplier)
	
	# Add rare containers at higher difficulties
	if difficulty >= 2:
		counts[ContainerType.RARE_CHEST] = counts.get(ContainerType.RARE_CHEST, 0) + 1
	if difficulty >= 3:
		counts[ContainerType.SAFE] = counts.get(ContainerType.SAFE, 0) + 1
	
	return counts


func _find_container_position(zone_data: Dictionary, placed: Dictionary) -> Vector2:
	var zone_size: Vector2i = zone_data.get("size", Vector2i(64, 64))
	var structures: Array = zone_data.get("structures", [])
	
	# Try placing near or inside structures first
	for structure in structures:
		if _rng.randf() > 0.5:
			continue
		
		var struct_pos: Vector2i = structure.get("position", Vector2i.ZERO)
		var struct_size: Vector2i = structure.get("size", Vector2i(3, 3))
		
		for _attempt in range(5):
			var offset := Vector2i(
				_rng.randi_range(-1, struct_size.x + 1),
				_rng.randi_range(-1, struct_size.y + 1)
			)
			var pos := Vector2(struct_pos.x + offset.x, struct_pos.y + offset.y)
			
			if pos not in placed and pos.x >= 1 and pos.y >= 1 and pos.x < zone_size.x - 1 and pos.y < zone_size.y - 1:
				return pos
	
	# Random placement
	for _attempt in range(20):
		var pos := Vector2(
			_rng.randi_range(2, zone_size.x - 2),
			_rng.randi_range(2, zone_size.y - 2)
		)
		
		if pos not in placed:
			return pos
	
	return Vector2(-1, -1)


# ============================================================================
# LOOTING
# ============================================================================

func can_open_container(container_id: String, player_data: Dictionary = {}) -> Dictionary:
	if container_id not in _containers:
		return {"can_open": false, "reason": "Container not found"}
	
	var container: Dictionary = _containers[container_id]
	
	if container["is_looted"]:
		return {"can_open": false, "reason": "Already looted"}
	
	var lock_type: String = container.get("lock_type", "")
	if not lock_type or lock_type == "":
		return {"can_open": true}
	
	# Check for required items based on lock type
	match lock_type:
		"basic":
			if not player_data.get("has_lockpick", false):
				return {"can_open": false, "reason": "Requires lockpick"}
		"military":
			if not player_data.get("has_military_keycard", false):
				return {"can_open": false, "reason": "Requires military keycard"}
		"combination":
			if not player_data.get("has_safe_code", false):
				return {"can_open": false, "reason": "Requires safe combination"}
		"key":
			var key_id: String = container.get("key_id", "rare_key")
			if key_id not in player_data.get("keys", []):
				return {"can_open": false, "reason": "Requires " + key_id}
	
	return {"can_open": true}


func open_container(container_id: String) -> Array[Dictionary]:
	## Generate and return loot from container
	if container_id not in _containers:
		return []
	
	var container: Dictionary = _containers[container_id]
	
	if container["is_looted"]:
		return []
	
	# Generate contents if not already done
	if not container.get("generated", false):
		container["contents"] = _generate_loot(container)
		container["generated"] = true
	
	var loot: Array[Dictionary] = []
	for item in container["contents"]:
		loot.append(item)
	
	emit_signal("container_opened", container_id, loot)
	return loot


func loot_container(container_id: String) -> void:
	## Mark container as fully looted
	if container_id not in _containers:
		return
	
	var container: Dictionary = _containers[container_id]
	container["is_looted"] = true
	container["contents"].clear()
	
	_looted_containers[container_id] = int(Time.get_unix_time_from_system())
	
	emit_signal("container_looted", container_id)


func _generate_loot(container: Dictionary) -> Array[Dictionary]:
	var loot: Array[Dictionary] = []
	var table_name: String = container.get("loot_table", "basic")
	var loot_table: Dictionary = LOOT_TABLES.get(table_name, LOOT_TABLES["basic"])
	var item_count_range: Array = container.get("item_count", [1, 3])
	var zone_difficulty: int = container.get("zone_difficulty", 0)
	
	var item_count := _rng.randi_range(item_count_range[0], item_count_range[1])
	
	# Add difficulty bonus items
	item_count += int(zone_difficulty * 0.5)
	
	# Add guaranteed items
	var guaranteed: Array = loot_table.get("guaranteed", [])
	for item_id in guaranteed:
		loot.append({
			"id": item_id,
			"count": 1,
			"rarity": LootRarity.RARE,
		})
	
	# Generate random items
	for i in range(item_count):
		var rarity := _roll_rarity(loot_table, zone_difficulty)
		var items_of_rarity: Array = loot_table.get("items", {}).get(rarity, [])
		
		if items_of_rarity.is_empty():
			# Fall back to lower rarity
			for r in range(rarity - 1, -1, -1):
				items_of_rarity = loot_table.get("items", {}).get(r, [])
				if not items_of_rarity.is_empty():
					rarity = r
					break
		
		if items_of_rarity.is_empty():
			continue
		
		var item := _select_weighted_item(items_of_rarity)
		if item.is_empty():
			continue
		
		var count_range: Array = item.get("count", [1, 1])
		var count := _rng.randi_range(count_range[0], count_range[1])
		
		# Apply difficulty bonus to counts
		count = int(count * (1.0 + zone_difficulty * 0.1))
		
		loot.append({
			"id": item["id"],
			"count": count,
			"rarity": rarity,
		})
		
		# Check for rare item signal
		if rarity >= LootRarity.EPIC:
			emit_signal("rare_item_found", item["id"], container.get("id", ""))
	
	return loot


func _roll_rarity(loot_table: Dictionary, difficulty_bonus: int = 0) -> int:
	var roll := _rng.randi() % 100 + difficulty_bonus * 3
	
	var legendary := loot_table.get("legendary", 0)
	var epic := loot_table.get("epic", 0)
	var rare := loot_table.get("rare", 0)
	var uncommon := loot_table.get("uncommon", 0)
	
	var cumulative := 0
	
	if legendary > 0:
		cumulative += legendary
		if roll >= 100 - cumulative:
			return LootRarity.LEGENDARY
	
	if epic > 0:
		cumulative += epic
		if roll >= 100 - cumulative:
			return LootRarity.EPIC
	
	if rare > 0:
		cumulative += rare
		if roll >= 100 - cumulative:
			return LootRarity.RARE
	
	if uncommon > 0:
		cumulative += uncommon
		if roll >= 100 - cumulative:
			return LootRarity.UNCOMMON
	
	return LootRarity.COMMON


func _select_weighted_item(items: Array) -> Dictionary:
	var total_weight := 0
	for item in items:
		total_weight += item.get("weight", 10)
	
	var roll := _rng.randi() % total_weight
	var cumulative := 0
	
	for item in items:
		cumulative += item.get("weight", 10)
		if roll < cumulative:
			return item
	
	return items[0] if items.size() > 0 else {}


# ============================================================================
# RESPAWNING
# ============================================================================

func _check_respawns() -> void:
	var current_time := int(Time.get_unix_time_from_system())
	var to_respawn: Array[String] = []
	
	for container_id in _looted_containers:
		if container_id in _containers:
			var container: Dictionary = _containers[container_id]
			var respawn_time: int = container.get("respawn_time", 0)
			
			if respawn_time > 0:
				var looted_time: int = _looted_containers[container_id]
				if current_time - looted_time >= respawn_time:
					to_respawn.append(container_id)
	
	for container_id in to_respawn:
		_respawn_container(container_id)


func _respawn_container(container_id: String) -> void:
	if container_id not in _containers:
		return
	
	var container: Dictionary = _containers[container_id]
	container["is_looted"] = false
	container["generated"] = false
	container["contents"].clear()
	
	_looted_containers.erase(container_id)


# ============================================================================
# SPECIAL CONTAINERS
# ============================================================================

func spawn_airdrop(position: Vector2, guaranteed_items: Array = []) -> Dictionary:
	## Spawn a special airdrop container
	var container := spawn_container(ContainerType.AIRDROP, position, 3)
	
	if guaranteed_items.size() > 0:
		container["guaranteed_items"] = guaranteed_items
	
	return container


func spawn_boss_chest(position: Vector2, boss_type: String) -> Dictionary:
	## Spawn a boss loot chest
	var container := spawn_container(ContainerType.BOSS_CHEST, position, 3)
	container["boss_type"] = boss_type
	
	# Add boss-specific guaranteed loot
	container["guaranteed_items"] = [
		{"id": boss_type + "_trophy", "count": 1},
	]
	
	return container


func spawn_event_chest(position: Vector2, event_type: String) -> Dictionary:
	## Spawn an event-specific chest
	var container := spawn_container(ContainerType.EVENT_CHEST, position, 2)
	container["event_type"] = event_type
	
	return container


# ============================================================================
# QUERIES
# ============================================================================

func get_container(container_id: String) -> Dictionary:
	return _containers.get(container_id, {})


func get_nearby_containers(position: Vector2, radius: float) -> Array[Dictionary]:
	var nearby: Array[Dictionary] = []
	
	for container in _containers.values():
		var dist := position.distance_to(container.get("position", Vector2.ZERO))
		if dist <= radius:
			nearby.append(container)
	
	return nearby


func get_unlootable_containers() -> Array[Dictionary]:
	var unlootable: Array[Dictionary] = []
	
	for container in _containers.values():
		if not container.get("is_looted", false):
			unlootable.append(container)
	
	return unlootable


# ============================================================================
# ZONE MANAGEMENT
# ============================================================================

func clear_zone_containers() -> void:
	_containers.clear()


func get_zone_loot_summary() -> Dictionary:
	var summary := {
		"total": 0,
		"available": 0,
		"looted": 0,
		"by_type": {},
	}
	
	for container in _containers.values():
		summary["total"] += 1
		
		if container.get("is_looted", false):
			summary["looted"] += 1
		else:
			summary["available"] += 1
		
		var type_name: String = ContainerType.keys()[container.get("type", 0)]
		summary["by_type"][type_name] = summary["by_type"].get(type_name, 0) + 1
	
	return summary


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"looted_containers": _looted_containers.duplicate(),
	}


func load_data(data: Dictionary) -> void:
	_looted_containers = data.get("looted_containers", {})
