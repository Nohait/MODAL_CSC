extends Node
class_name BaseUpgradeSystemClass
## Manages base progression, upgrades, expansions, and automation
## Handles base level, unlocks, and facility improvements

signal base_level_up(new_level: int)
signal facility_unlocked(facility_type: int)
signal facility_upgraded(facility_id: String, new_level: int)
signal expansion_completed(expansion_id: String)
signal automation_enabled(facility_id: String)
signal defense_rating_changed(new_rating: float)

# ============================================================================
# BASE CONFIGURATION
# ============================================================================

enum FacilityType {
	# Core Facilities
	COMMAND_CENTER,
	STORAGE_DEPOT,
	POWER_GRID,
	WATER_SUPPLY,
	FOOD_PRODUCTION,
	
	# Production
	WORKSHOP,
	FORGE,
	LABORATORY,
	ARMORY,
	MEDICAL_BAY,
	
	# Defense
	PERIMETER_WALL,
	GUARD_TOWER,
	DEFENSE_NETWORK,
	BUNKER,
	
	# Utility
	TRADING_POST,
	GARAGE,
	COMMUNICATION_CENTER,
	RECYCLING_CENTER,
	FARM,
}

enum UpgradeStat {
	STORAGE_CAPACITY,
	CRAFTING_SPEED,
	POWER_OUTPUT,
	WATER_OUTPUT,
	FOOD_OUTPUT,
	DEFENSE_RATING,
	WORKSTATION_SLOTS,
	AUTOMATION_LEVEL,
	RESEARCH_SPEED,
	REPAIR_EFFICIENCY,
}

const BASE_LEVEL_REQUIREMENTS := {
	1: {"experience": 0, "unlocks": [FacilityType.COMMAND_CENTER]},
	2: {"experience": 100, "unlocks": [FacilityType.STORAGE_DEPOT, FacilityType.WORKSHOP]},
	3: {"experience": 300, "unlocks": [FacilityType.WATER_SUPPLY, FacilityType.FOOD_PRODUCTION]},
	4: {"experience": 600, "unlocks": [FacilityType.PERIMETER_WALL]},
	5: {"experience": 1000, "unlocks": [FacilityType.FORGE, FacilityType.POWER_GRID]},
	6: {"experience": 1500, "unlocks": [FacilityType.GUARD_TOWER, FacilityType.MEDICAL_BAY]},
	7: {"experience": 2200, "unlocks": [FacilityType.ARMORY]},
	8: {"experience": 3000, "unlocks": [FacilityType.TRADING_POST, FacilityType.LABORATORY]},
	9: {"experience": 4000, "unlocks": [FacilityType.DEFENSE_NETWORK, FacilityType.GARAGE]},
	10: {"experience": 5500, "unlocks": [FacilityType.COMMUNICATION_CENTER]},
	11: {"experience": 7000, "unlocks": [FacilityType.BUNKER]},
	12: {"experience": 9000, "unlocks": [FacilityType.RECYCLING_CENTER]},
	13: {"experience": 12000, "unlocks": [FacilityType.FARM]},
	14: {"experience": 15000, "unlocks": []},
	15: {"experience": 20000, "unlocks": []},  # Max level
}

const FACILITY_DEFINITIONS := {
	FacilityType.COMMAND_CENTER: {
		"display_name": "Command Center",
		"description": "Central hub of your base. Determines maximum base level.",
		"max_level": 5,
		"base_build_cost": {"wood": 50, "stone": 30, "nails": 20},
		"upgrade_cost_multiplier": 2.0,
		"size": Vector2i(4, 4),
		"unique": true,
		"bonuses": {
			1: {UpgradeStat.WORKSTATION_SLOTS: 2},
			2: {UpgradeStat.WORKSTATION_SLOTS: 3, UpgradeStat.STORAGE_CAPACITY: 50},
			3: {UpgradeStat.WORKSTATION_SLOTS: 4, UpgradeStat.STORAGE_CAPACITY: 100},
			4: {UpgradeStat.WORKSTATION_SLOTS: 5, UpgradeStat.STORAGE_CAPACITY: 150, UpgradeStat.AUTOMATION_LEVEL: 1},
			5: {UpgradeStat.WORKSTATION_SLOTS: 6, UpgradeStat.STORAGE_CAPACITY: 200, UpgradeStat.AUTOMATION_LEVEL: 2},
		},
	},
	FacilityType.STORAGE_DEPOT: {
		"display_name": "Storage Depot",
		"description": "Increases base storage capacity.",
		"max_level": 5,
		"base_build_cost": {"wood": 30, "nails": 15},
		"upgrade_cost_multiplier": 1.5,
		"size": Vector2i(3, 3),
		"unique": false,
		"max_count": 4,
		"bonuses": {
			1: {UpgradeStat.STORAGE_CAPACITY: 100},
			2: {UpgradeStat.STORAGE_CAPACITY: 200},
			3: {UpgradeStat.STORAGE_CAPACITY: 350},
			4: {UpgradeStat.STORAGE_CAPACITY: 500},
			5: {UpgradeStat.STORAGE_CAPACITY: 700},
		},
	},
	FacilityType.POWER_GRID: {
		"display_name": "Power Grid",
		"description": "Provides electricity to facilities.",
		"max_level": 5,
		"base_build_cost": {"steel_plate": 20, "electronics": 10, "copper_wire": 30},
		"upgrade_cost_multiplier": 2.0,
		"size": Vector2i(3, 3),
		"unique": true,
		"bonuses": {
			1: {UpgradeStat.POWER_OUTPUT: 100},
			2: {UpgradeStat.POWER_OUTPUT: 200},
			3: {UpgradeStat.POWER_OUTPUT: 350},
			4: {UpgradeStat.POWER_OUTPUT: 500, UpgradeStat.AUTOMATION_LEVEL: 1},
			5: {UpgradeStat.POWER_OUTPUT: 700, UpgradeStat.AUTOMATION_LEVEL: 2},
		},
	},
	FacilityType.WATER_SUPPLY: {
		"display_name": "Water Supply",
		"description": "Provides clean water to the base.",
		"max_level": 4,
		"base_build_cost": {"stone": 25, "pipe": 10, "cloth": 5},
		"upgrade_cost_multiplier": 1.8,
		"size": Vector2i(2, 2),
		"unique": true,
		"bonuses": {
			1: {UpgradeStat.WATER_OUTPUT: 10},  # Units per hour
			2: {UpgradeStat.WATER_OUTPUT: 20},
			3: {UpgradeStat.WATER_OUTPUT: 35},
			4: {UpgradeStat.WATER_OUTPUT: 50},
		},
	},
	FacilityType.FOOD_PRODUCTION: {
		"display_name": "Food Production",
		"description": "Grows and stores food.",
		"max_level": 4,
		"base_build_cost": {"wood": 20, "plant_fiber": 30, "cloth": 10},
		"upgrade_cost_multiplier": 1.6,
		"size": Vector2i(4, 3),
		"unique": false,
		"max_count": 3,
		"bonuses": {
			1: {UpgradeStat.FOOD_OUTPUT: 5},
			2: {UpgradeStat.FOOD_OUTPUT: 10},
			3: {UpgradeStat.FOOD_OUTPUT: 18},
			4: {UpgradeStat.FOOD_OUTPUT: 25},
		},
	},
	FacilityType.WORKSHOP: {
		"display_name": "Workshop",
		"description": "Improves crafting speed and unlocks workstations.",
		"max_level": 5,
		"base_build_cost": {"wood": 40, "nails": 25, "steel_plate": 5},
		"upgrade_cost_multiplier": 1.7,
		"size": Vector2i(3, 3),
		"unique": true,
		"bonuses": {
			1: {UpgradeStat.CRAFTING_SPEED: 0.1, UpgradeStat.WORKSTATION_SLOTS: 1},
			2: {UpgradeStat.CRAFTING_SPEED: 0.2, UpgradeStat.WORKSTATION_SLOTS: 2},
			3: {UpgradeStat.CRAFTING_SPEED: 0.35, UpgradeStat.WORKSTATION_SLOTS: 3},
			4: {UpgradeStat.CRAFTING_SPEED: 0.5, UpgradeStat.WORKSTATION_SLOTS: 4},
			5: {UpgradeStat.CRAFTING_SPEED: 0.7, UpgradeStat.WORKSTATION_SLOTS: 5, UpgradeStat.AUTOMATION_LEVEL: 1},
		},
	},
	FacilityType.FORGE: {
		"display_name": "Forge",
		"description": "Advanced metalworking facility.",
		"max_level": 4,
		"base_build_cost": {"stone": 40, "iron_bar": 20, "coal": 30},
		"upgrade_cost_multiplier": 2.0,
		"size": Vector2i(3, 3),
		"unique": true,
		"unlocks_workstations": ["furnace", "stone_cutter"],
		"bonuses": {
			1: {UpgradeStat.CRAFTING_SPEED: 0.15},
			2: {UpgradeStat.CRAFTING_SPEED: 0.3},
			3: {UpgradeStat.CRAFTING_SPEED: 0.5},
			4: {UpgradeStat.CRAFTING_SPEED: 0.7, UpgradeStat.AUTOMATION_LEVEL: 1},
		},
	},
	FacilityType.LABORATORY: {
		"display_name": "Laboratory",
		"description": "Research facility for advanced recipes.",
		"max_level": 4,
		"base_build_cost": {"steel_plate": 30, "glass": 15, "electronics": 20},
		"upgrade_cost_multiplier": 2.2,
		"size": Vector2i(3, 3),
		"unique": true,
		"unlocks_workstations": ["chemistry_station"],
		"bonuses": {
			1: {UpgradeStat.RESEARCH_SPEED: 0.1},
			2: {UpgradeStat.RESEARCH_SPEED: 0.25},
			3: {UpgradeStat.RESEARCH_SPEED: 0.4},
			4: {UpgradeStat.RESEARCH_SPEED: 0.6, UpgradeStat.AUTOMATION_LEVEL: 1},
		},
	},
	FacilityType.ARMORY: {
		"display_name": "Armory",
		"description": "Weapons and armor production.",
		"max_level": 4,
		"base_build_cost": {"steel_plate": 40, "wood": 20, "nails": 30},
		"upgrade_cost_multiplier": 2.0,
		"size": Vector2i(3, 3),
		"unique": true,
		"unlocks_workstations": ["weapons_bench", "armor_bench"],
		"bonuses": {
			1: {UpgradeStat.CRAFTING_SPEED: 0.1, UpgradeStat.WORKSTATION_SLOTS: 1},
			2: {UpgradeStat.CRAFTING_SPEED: 0.2, UpgradeStat.WORKSTATION_SLOTS: 2},
			3: {UpgradeStat.CRAFTING_SPEED: 0.35, UpgradeStat.WORKSTATION_SLOTS: 2},
			4: {UpgradeStat.CRAFTING_SPEED: 0.5, UpgradeStat.WORKSTATION_SLOTS: 3},
		},
	},
	FacilityType.MEDICAL_BAY: {
		"display_name": "Medical Bay",
		"description": "Medical treatment and production.",
		"max_level": 4,
		"base_build_cost": {"steel_plate": 20, "cloth": 30, "electronics": 5},
		"upgrade_cost_multiplier": 1.8,
		"size": Vector2i(3, 2),
		"unique": true,
		"unlocks_workstations": ["medical_table"],
		"bonuses": {
			1: {UpgradeStat.CRAFTING_SPEED: 0.1},
			2: {UpgradeStat.CRAFTING_SPEED: 0.2},
			3: {UpgradeStat.CRAFTING_SPEED: 0.35},
			4: {UpgradeStat.CRAFTING_SPEED: 0.5},
		},
	},
	FacilityType.PERIMETER_WALL: {
		"display_name": "Perimeter Wall",
		"description": "Outer defense walls.",
		"max_level": 5,
		"base_build_cost": {"wood": 50, "stone": 30},
		"upgrade_cost_multiplier": 1.5,
		"size": Vector2i(1, 1),  # Per segment
		"unique": false,
		"max_count": 50,
		"bonuses": {
			1: {UpgradeStat.DEFENSE_RATING: 5},
			2: {UpgradeStat.DEFENSE_RATING: 12},
			3: {UpgradeStat.DEFENSE_RATING: 20},
			4: {UpgradeStat.DEFENSE_RATING: 30},
			5: {UpgradeStat.DEFENSE_RATING: 45},
		},
	},
	FacilityType.GUARD_TOWER: {
		"display_name": "Guard Tower",
		"description": "Defensive tower for surveillance.",
		"max_level": 4,
		"base_build_cost": {"wood": 40, "stone": 20, "nails": 20},
		"upgrade_cost_multiplier": 1.8,
		"size": Vector2i(2, 2),
		"unique": false,
		"max_count": 4,
		"bonuses": {
			1: {UpgradeStat.DEFENSE_RATING: 15},
			2: {UpgradeStat.DEFENSE_RATING: 30},
			3: {UpgradeStat.DEFENSE_RATING: 50},
			4: {UpgradeStat.DEFENSE_RATING: 75},
		},
	},
	FacilityType.DEFENSE_NETWORK: {
		"display_name": "Defense Network",
		"description": "Automated turret control system.",
		"max_level": 3,
		"base_build_cost": {"steel_plate": 50, "electronics": 30, "copper_wire": 40},
		"upgrade_cost_multiplier": 2.5,
		"size": Vector2i(2, 2),
		"unique": true,
		"bonuses": {
			1: {UpgradeStat.DEFENSE_RATING: 30, UpgradeStat.AUTOMATION_LEVEL: 1},
			2: {UpgradeStat.DEFENSE_RATING: 60, UpgradeStat.AUTOMATION_LEVEL: 2},
			3: {UpgradeStat.DEFENSE_RATING: 100, UpgradeStat.AUTOMATION_LEVEL: 3},
		},
	},
	FacilityType.BUNKER: {
		"display_name": "Bunker",
		"description": "Safe room for emergencies.",
		"max_level": 3,
		"base_build_cost": {"concrete": 50, "steel_plate": 40, "electronics": 10},
		"upgrade_cost_multiplier": 2.5,
		"size": Vector2i(3, 3),
		"unique": true,
		"bonuses": {
			1: {UpgradeStat.DEFENSE_RATING: 50, UpgradeStat.STORAGE_CAPACITY: 50},
			2: {UpgradeStat.DEFENSE_RATING: 100, UpgradeStat.STORAGE_CAPACITY: 100},
			3: {UpgradeStat.DEFENSE_RATING: 150, UpgradeStat.STORAGE_CAPACITY: 200},
		},
	},
	FacilityType.TRADING_POST: {
		"display_name": "Trading Post",
		"description": "Enables trading with NPCs.",
		"max_level": 3,
		"base_build_cost": {"wood": 50, "cloth": 20, "electronics": 5},
		"upgrade_cost_multiplier": 2.0,
		"size": Vector2i(3, 2),
		"unique": true,
		"bonuses": {
			1: {},  # Trading unlocked
			2: {},  # Better prices
			3: {},  # Rare traders
		},
	},
	FacilityType.GARAGE: {
		"display_name": "Garage",
		"description": "Vehicle storage and repair.",
		"max_level": 3,
		"base_build_cost": {"steel_plate": 40, "concrete": 30, "gears": 10},
		"upgrade_cost_multiplier": 2.0,
		"size": Vector2i(5, 4),
		"unique": true,
		"bonuses": {
			1: {UpgradeStat.REPAIR_EFFICIENCY: 0.2},
			2: {UpgradeStat.REPAIR_EFFICIENCY: 0.4},
			3: {UpgradeStat.REPAIR_EFFICIENCY: 0.6},
		},
	},
	FacilityType.COMMUNICATION_CENTER: {
		"display_name": "Communication Center",
		"description": "Long-range radio communications.",
		"max_level": 2,
		"base_build_cost": {"electronics": 40, "copper_wire": 50, "steel_plate": 20},
		"upgrade_cost_multiplier": 2.5,
		"size": Vector2i(2, 2),
		"unique": true,
		"bonuses": {
			1: {},  # Radio unlocked
			2: {},  # Long range
		},
	},
	FacilityType.RECYCLING_CENTER: {
		"display_name": "Recycling Center",
		"description": "Automated material recycling.",
		"max_level": 3,
		"base_build_cost": {"steel_plate": 30, "gears": 20, "electronics": 15},
		"upgrade_cost_multiplier": 2.0,
		"size": Vector2i(3, 3),
		"unique": true,
		"unlocks_workstations": ["recycler"],
		"bonuses": {
			1: {UpgradeStat.CRAFTING_SPEED: 0.1},
			2: {UpgradeStat.CRAFTING_SPEED: 0.25, UpgradeStat.AUTOMATION_LEVEL: 1},
			3: {UpgradeStat.CRAFTING_SPEED: 0.4, UpgradeStat.AUTOMATION_LEVEL: 2},
		},
	},
	FacilityType.FARM: {
		"display_name": "Farm",
		"description": "Large-scale food production.",
		"max_level": 4,
		"base_build_cost": {"wood": 60, "plant_fiber": 50, "pipe": 20},
		"upgrade_cost_multiplier": 1.5,
		"size": Vector2i(6, 4),
		"unique": true,
		"unlocks_workstations": ["garden_bed"],
		"bonuses": {
			1: {UpgradeStat.FOOD_OUTPUT: 15},
			2: {UpgradeStat.FOOD_OUTPUT: 30},
			3: {UpgradeStat.FOOD_OUTPUT: 50, UpgradeStat.AUTOMATION_LEVEL: 1},
			4: {UpgradeStat.FOOD_OUTPUT: 80, UpgradeStat.AUTOMATION_LEVEL: 2},
		},
	},
}


# ============================================================================
# EXPANSION SYSTEM
# ============================================================================

const EXPANSION_ZONES := {
	"zone_0": {
		"display_name": "Core Base",
		"size": Vector2i(20, 20),
		"position": Vector2i(0, 0),
		"unlock_level": 1,
		"build_cost": {},
		"unlocked_by_default": true,
	},
	"zone_1": {
		"display_name": "Northern Expansion",
		"size": Vector2i(15, 15),
		"position": Vector2i(0, -20),
		"unlock_level": 5,
		"build_cost": {"wood": 100, "stone": 50, "nails": 40},
	},
	"zone_2": {
		"display_name": "Eastern Expansion",
		"size": Vector2i(15, 15),
		"position": Vector2i(20, 0),
		"unlock_level": 7,
		"build_cost": {"wood": 120, "stone": 60, "steel_plate": 20},
	},
	"zone_3": {
		"display_name": "Southern Expansion",
		"size": Vector2i(15, 15),
		"position": Vector2i(0, 20),
		"unlock_level": 9,
		"build_cost": {"wood": 150, "stone": 80, "steel_plate": 30},
	},
	"zone_4": {
		"display_name": "Western Expansion",
		"size": Vector2i(15, 15),
		"position": Vector2i(-20, 0),
		"unlock_level": 11,
		"build_cost": {"wood": 180, "stone": 100, "steel_plate": 40},
	},
	"zone_5": {
		"display_name": "Outer Compound",
		"size": Vector2i(25, 25),
		"position": Vector2i(-5, -25),
		"unlock_level": 14,
		"build_cost": {"wood": 250, "concrete": 100, "steel_plate": 80},
	},
}


# ============================================================================
# STATE
# ============================================================================

var base_level: int = 1
var base_experience: int = 0
var base_name: String = "Home Base"

var _facilities: Dictionary = {}  # facility_id -> facility data
var _unlocked_facilities: Array = []
var _unlocked_expansions: Array = ["zone_0"]
var _total_stats: Dictionary = {}  # UpgradeStat -> total value
var _automation_tasks: Array = []


func _ready() -> void:
	_recalculate_stats()


func _process(delta: float) -> void:
	_update_automation(delta)
	_update_passive_production(delta)


# ============================================================================
# BASE LEVEL
# ============================================================================

func add_base_experience(amount: int) -> void:
	base_experience += amount
	_check_level_up()


func _check_level_up() -> void:
	var next_level := base_level + 1
	
	if next_level > BASE_LEVEL_REQUIREMENTS.size():
		return
	
	var requirements: Dictionary = BASE_LEVEL_REQUIREMENTS.get(next_level, {})
	var required_xp: int = requirements.get("experience", 999999)
	
	while base_experience >= required_xp and next_level <= BASE_LEVEL_REQUIREMENTS.size():
		base_level = next_level
		
		# Unlock new facilities
		var unlocks: Array = requirements.get("unlocks", [])
		for facility_type in unlocks:
			if facility_type not in _unlocked_facilities:
				_unlocked_facilities.append(facility_type)
				emit_signal("facility_unlocked", facility_type)
		
		emit_signal("base_level_up", base_level)
		
		next_level += 1
		requirements = BASE_LEVEL_REQUIREMENTS.get(next_level, {})
		required_xp = requirements.get("experience", 999999)


func get_level_progress() -> Dictionary:
	var next_level := base_level + 1
	var requirements: Dictionary = BASE_LEVEL_REQUIREMENTS.get(next_level, {})
	var required_xp: int = requirements.get("experience", base_experience)
	var current_req: Dictionary = BASE_LEVEL_REQUIREMENTS.get(base_level, {})
	var current_xp: int = current_req.get("experience", 0)
	
	var progress := float(base_experience - current_xp) / float(required_xp - current_xp)
	
	return {
		"level": base_level,
		"experience": base_experience,
		"next_level_xp": required_xp,
		"progress": clampf(progress, 0.0, 1.0),
	}


# ============================================================================
# FACILITY MANAGEMENT
# ============================================================================

func build_facility(facility_type: int, position: Vector2) -> Dictionary:
	var definition: Dictionary = FACILITY_DEFINITIONS.get(facility_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown facility type"}
	
	# Check if unlocked
	if facility_type not in _unlocked_facilities:
		return {"success": false, "error": "Facility not unlocked"}
	
	# Check unique constraint
	if definition.get("unique", false):
		for f in _facilities.values():
			if f["type"] == facility_type:
				return {"success": false, "error": "Facility already exists"}
	
	# Check max count
	var max_count: int = definition.get("max_count", -1)
	if max_count > 0:
		var count := 0
		for f in _facilities.values():
			if f["type"] == facility_type:
				count += 1
		if count >= max_count:
			return {"success": false, "error": "Maximum count reached"}
	
	# Check placement in expansion zone
	if not _is_position_in_expansion(position, definition.get("size", Vector2i(1, 1))):
		return {"success": false, "error": "Position outside base area"}
	
	var facility_id := "%d_%d_%d" % [facility_type, int(position.x), int(position.y)]
	
	var facility := {
		"id": facility_id,
		"type": facility_type,
		"type_name": FacilityType.keys()[facility_type],
		"display_name": definition.get("display_name", "Facility"),
		"position": position,
		"size": definition.get("size", Vector2i(1, 1)),
		"level": 1,
		"max_level": definition.get("max_level", 1),
		"automation_enabled": false,
		"is_active": true,
		"built_time": Time.get_unix_time_from_system(),
	}
	
	_facilities[facility_id] = facility
	_recalculate_stats()
	
	# Grant base XP for building
	add_base_experience(10 * facility["level"])
	
	return {"success": true, "facility_id": facility_id, "facility": facility}


func upgrade_facility(facility_id: String) -> Dictionary:
	if facility_id not in _facilities:
		return {"success": false, "error": "Facility not found"}
	
	var facility: Dictionary = _facilities[facility_id]
	var definition: Dictionary = FACILITY_DEFINITIONS.get(facility["type"], {})
	
	if facility["level"] >= facility.get("max_level", 1):
		return {"success": false, "error": "Already max level"}
	
	# Check command center level (limits other facility levels)
	var cc_level := _get_command_center_level()
	if facility["type"] != FacilityType.COMMAND_CENTER and facility["level"] >= cc_level:
		return {"success": false, "error": "Upgrade Command Center first"}
	
	facility["level"] += 1
	_recalculate_stats()
	
	# Grant base XP
	add_base_experience(15 * facility["level"])
	
	emit_signal("facility_upgraded", facility_id, facility["level"])
	
	return {"success": true, "new_level": facility["level"]}


func demolish_facility(facility_id: String) -> Dictionary:
	if facility_id not in _facilities:
		return {"success": false, "error": "Facility not found"}
	
	var facility: Dictionary = _facilities[facility_id]
	
	# Cannot demolish command center if other facilities exist
	if facility["type"] == FacilityType.COMMAND_CENTER and _facilities.size() > 1:
		return {"success": false, "error": "Remove other facilities first"}
	
	# Calculate salvage
	var definition: Dictionary = FACILITY_DEFINITIONS.get(facility["type"], {})
	var base_cost: Dictionary = definition.get("base_build_cost", {})
	var salvage: Dictionary = {}
	
	for item_id in base_cost:
		salvage[item_id] = int(base_cost[item_id] * 0.5 * facility["level"])
	
	_facilities.erase(facility_id)
	_recalculate_stats()
	
	return {"success": true, "salvage": salvage}


func get_upgrade_cost(facility_id: String) -> Dictionary:
	if facility_id not in _facilities:
		return {}
	
	var facility: Dictionary = _facilities[facility_id]
	var definition: Dictionary = FACILITY_DEFINITIONS.get(facility["type"], {})
	
	if facility["level"] >= facility.get("max_level", 1):
		return {}
	
	var base_cost: Dictionary = definition.get("base_build_cost", {})
	var multiplier: float = definition.get("upgrade_cost_multiplier", 2.0)
	var level_mult := pow(multiplier, facility["level"])
	
	var cost: Dictionary = {}
	for item_id in base_cost:
		cost[item_id] = int(base_cost[item_id] * level_mult)
	
	return cost


func _get_command_center_level() -> int:
	for f in _facilities.values():
		if f["type"] == FacilityType.COMMAND_CENTER:
			return f["level"]
	return 0


func _is_position_in_expansion(position: Vector2, size: Vector2i) -> bool:
	for zone_id in _unlocked_expansions:
		var zone: Dictionary = EXPANSION_ZONES.get(zone_id, {})
		var zone_pos: Vector2i = zone.get("position", Vector2i.ZERO)
		var zone_size: Vector2i = zone.get("size", Vector2i(20, 20))
		
		var zone_rect := Rect2(
			Vector2(zone_pos.x * 32, zone_pos.y * 32),
			Vector2(zone_size.x * 32, zone_size.y * 32)
		)
		
		var facility_rect := Rect2(position, Vector2(size.x * 32, size.y * 32))
		
		if zone_rect.encloses(facility_rect):
			return true
	
	return false


# ============================================================================
# EXPANSION
# ============================================================================

func unlock_expansion(zone_id: String) -> Dictionary:
	if zone_id in _unlocked_expansions:
		return {"success": false, "error": "Already unlocked"}
	
	var zone: Dictionary = EXPANSION_ZONES.get(zone_id, {})
	if zone.is_empty():
		return {"success": false, "error": "Unknown expansion zone"}
	
	var required_level: int = zone.get("unlock_level", 1)
	if base_level < required_level:
		return {"success": false, "error": "Base level %d required" % required_level}
	
	_unlocked_expansions.append(zone_id)
	
	# Grant base XP
	add_base_experience(50)
	
	emit_signal("expansion_completed", zone_id)
	
	return {"success": true, "zone": zone}


func get_available_expansions() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	
	for zone_id in EXPANSION_ZONES:
		if zone_id in _unlocked_expansions:
			continue
		
		var zone: Dictionary = EXPANSION_ZONES[zone_id].duplicate()
		zone["id"] = zone_id
		zone["can_unlock"] = base_level >= zone.get("unlock_level", 1)
		available.append(zone)
	
	return available


func get_base_area() -> Rect2:
	var min_x := 0
	var min_y := 0
	var max_x := 0
	var max_y := 0
	
	for zone_id in _unlocked_expansions:
		var zone: Dictionary = EXPANSION_ZONES.get(zone_id, {})
		var pos: Vector2i = zone.get("position", Vector2i.ZERO)
		var size: Vector2i = zone.get("size", Vector2i(20, 20))
		
		min_x = mini(min_x, pos.x)
		min_y = mini(min_y, pos.y)
		max_x = maxi(max_x, pos.x + size.x)
		max_y = maxi(max_y, pos.y + size.y)
	
	return Rect2(
		Vector2(min_x * 32, min_y * 32),
		Vector2((max_x - min_x) * 32, (max_y - min_y) * 32)
	)


# ============================================================================
# STATS CALCULATION
# ============================================================================

func _recalculate_stats() -> void:
	_total_stats.clear()
	
	# Initialize all stats to 0
	for stat in UpgradeStat.values():
		_total_stats[stat] = 0.0
	
	# Sum bonuses from all facilities
	for facility in _facilities.values():
		var definition: Dictionary = FACILITY_DEFINITIONS.get(facility["type"], {})
		var bonuses: Dictionary = definition.get("bonuses", {})
		var level_bonuses: Dictionary = bonuses.get(facility["level"], {})
		
		for stat in level_bonuses:
			_total_stats[stat] = _total_stats.get(stat, 0.0) + level_bonuses[stat]
	
	# Emit defense rating change
	emit_signal("defense_rating_changed", _total_stats.get(UpgradeStat.DEFENSE_RATING, 0.0))


func get_stat(stat: int) -> float:
	return _total_stats.get(stat, 0.0)


func get_all_stats() -> Dictionary:
	return _total_stats.duplicate()


func get_defense_rating() -> float:
	return _total_stats.get(UpgradeStat.DEFENSE_RATING, 0.0)


func get_storage_capacity() -> int:
	return int(_total_stats.get(UpgradeStat.STORAGE_CAPACITY, 100.0))


func get_crafting_speed_bonus() -> float:
	return _total_stats.get(UpgradeStat.CRAFTING_SPEED, 0.0)


func get_workstation_slots() -> int:
	return int(_total_stats.get(UpgradeStat.WORKSTATION_SLOTS, 2.0))


# ============================================================================
# AUTOMATION
# ============================================================================

func enable_automation(facility_id: String) -> bool:
	if facility_id not in _facilities:
		return false
	
	var facility: Dictionary = _facilities[facility_id]
	var automation_level := int(_total_stats.get(UpgradeStat.AUTOMATION_LEVEL, 0))
	
	if automation_level <= 0:
		return false
	
	facility["automation_enabled"] = true
	emit_signal("automation_enabled", facility_id)
	
	return true


func disable_automation(facility_id: String) -> bool:
	if facility_id not in _facilities:
		return false
	
	_facilities[facility_id]["automation_enabled"] = false
	return true


func add_automation_task(task: Dictionary) -> void:
	## Add automated crafting/production task
	_automation_tasks.append({
		"type": task.get("type", ""),
		"facility_id": task.get("facility_id", ""),
		"recipe_id": task.get("recipe_id", ""),
		"repeat": task.get("repeat", false),
		"priority": task.get("priority", 0),
	})


func _update_automation(_delta: float) -> void:
	if _total_stats.get(UpgradeStat.AUTOMATION_LEVEL, 0) <= 0:
		return
	
	# Process automation tasks
	# This would integrate with WorkstationSystem
	pass


func _update_passive_production(delta: float) -> void:
	# Water production
	var water_rate: float = _total_stats.get(UpgradeStat.WATER_OUTPUT, 0.0) / 3600.0
	# Food production
	var food_rate: float = _total_stats.get(UpgradeStat.FOOD_OUTPUT, 0.0) / 3600.0
	
	# These would add to storage over time


# ============================================================================
# QUERIES
# ============================================================================

func get_facility(facility_id: String) -> Dictionary:
	return _facilities.get(facility_id, {})


func get_all_facilities() -> Array:
	return _facilities.values()


func get_facilities_by_type(facility_type: int) -> Array:
	var matching: Array = []
	for f in _facilities.values():
		if f["type"] == facility_type:
			matching.append(f)
	return matching


func is_facility_unlocked(facility_type: int) -> bool:
	return facility_type in _unlocked_facilities


func get_unlocked_workstations() -> Array:
	var workstations: Array = ["campfire", "workbench"]  # Default
	
	for facility in _facilities.values():
		var definition: Dictionary = FACILITY_DEFINITIONS.get(facility["type"], {})
		var unlocks: Array = definition.get("unlocks_workstations", [])
		for ws in unlocks:
			if ws not in workstations:
				workstations.append(ws)
	
	return workstations


func get_base_summary() -> Dictionary:
	return {
		"name": base_name,
		"level": base_level,
		"experience": base_experience,
		"facility_count": _facilities.size(),
		"expansion_count": _unlocked_expansions.size(),
		"defense_rating": get_defense_rating(),
		"storage_capacity": get_storage_capacity(),
		"workstation_slots": get_workstation_slots(),
		"area": get_base_area(),
	}


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"base_name": base_name,
		"base_level": base_level,
		"base_experience": base_experience,
		"facilities": _facilities.duplicate(true),
		"unlocked_facilities": _unlocked_facilities.duplicate(),
		"unlocked_expansions": _unlocked_expansions.duplicate(),
		"automation_tasks": _automation_tasks.duplicate(true),
	}


func load_data(data: Dictionary) -> void:
	base_name = data.get("base_name", "Home Base")
	base_level = data.get("base_level", 1)
	base_experience = data.get("base_experience", 0)
	_facilities = data.get("facilities", {})
	_unlocked_facilities = data.get("unlocked_facilities", [])
	_unlocked_expansions = data.get("unlocked_expansions", ["zone_0"])
	_automation_tasks = data.get("automation_tasks", [])
	
	_recalculate_stats()
