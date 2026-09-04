extends Node
class_name DefenseSystemClass
## Manages defensive structures: walls, turrets, traps, and base defenses
## Handles damage, durability, and attack behavior

signal structure_placed(structure_id: String, structure_type: int)
signal structure_damaged(structure_id: String, damage: float, remaining_hp: float)
signal structure_destroyed(structure_id: String)
signal structure_repaired(structure_id: String, new_hp: float)
signal turret_fired(turret_id: String, target_id: String)
signal trap_triggered(trap_id: String, target_id: String)

# ============================================================================
# STRUCTURE TYPES
# ============================================================================

enum StructureType {
	# Walls
	WOOD_WALL,
	STONE_WALL,
	METAL_WALL,
	REINFORCED_WALL,
	
	# Doors & Gates
	WOOD_DOOR,
	METAL_DOOR,
	REINFORCED_DOOR,
	GATE,
	
	# Windows
	WOOD_WINDOW,
	METAL_WINDOW,
	BARRED_WINDOW,
	
	# Turrets
	BASIC_TURRET,
	SHOTGUN_TURRET,
	SNIPER_TURRET,
	FLAME_TURRET,
	
	# Traps
	SPIKE_TRAP,
	BEAR_TRAP,
	LANDMINE,
	TRIPWIRE,
	ELECTRIC_TRAP,
	
	# Barriers
	SANDBAG,
	BARRICADE,
	BARBED_WIRE,
	CONCRETE_BARRIER,
	
	# Utility
	WATCHTOWER,
	SPOTLIGHT,
	ALARM,
	GENERATOR_DEFENSE,
}

enum StructureCategory {
	WALL,
	DOOR,
	WINDOW,
	TURRET,
	TRAP,
	BARRIER,
	UTILITY,
}

enum DamageType {
	PHYSICAL,
	EXPLOSIVE,
	FIRE,
	ELECTRIC,
}

const STRUCTURE_DEFINITIONS := {
	# ========== WALLS ==========
	StructureType.WOOD_WALL: {
		"display_name": "Wooden Wall",
		"category": StructureCategory.WALL,
		"description": "Basic wooden wall section",
		"unlock_level": 1,
		"build_cost": {"wood": 20},
		"hp": 200,
		"armor": 0,
		"resistances": {DamageType.PHYSICAL: 0.0, DamageType.FIRE: -0.5, DamageType.EXPLOSIVE: -0.3},
		"size": Vector2i(1, 1),
		"blocks_movement": true,
		"blocks_vision": true,
		"blocks_projectiles": true,
		"can_upgrade": true,
		"upgrade_to": StructureType.STONE_WALL,
		"repair_cost": {"wood": 5},
		"sprite": "wood_wall",
	},
	StructureType.STONE_WALL: {
		"display_name": "Stone Wall",
		"category": StructureCategory.WALL,
		"description": "Sturdy stone wall section",
		"unlock_level": 5,
		"build_cost": {"stone": 30, "wood": 5},
		"hp": 500,
		"armor": 10,
		"resistances": {DamageType.PHYSICAL: 0.2, DamageType.FIRE: 0.5, DamageType.EXPLOSIVE: -0.1},
		"size": Vector2i(1, 1),
		"blocks_movement": true,
		"blocks_vision": true,
		"blocks_projectiles": true,
		"can_upgrade": true,
		"upgrade_to": StructureType.METAL_WALL,
		"repair_cost": {"stone": 8},
		"sprite": "stone_wall",
	},
	StructureType.METAL_WALL: {
		"display_name": "Metal Wall",
		"category": StructureCategory.WALL,
		"description": "Strong metal wall section",
		"unlock_level": 10,
		"build_cost": {"steel_plate": 15, "nails": 20},
		"hp": 1000,
		"armor": 25,
		"resistances": {DamageType.PHYSICAL: 0.4, DamageType.FIRE: 0.3, DamageType.EXPLOSIVE: 0.1},
		"size": Vector2i(1, 1),
		"blocks_movement": true,
		"blocks_vision": true,
		"blocks_projectiles": true,
		"can_upgrade": true,
		"upgrade_to": StructureType.REINFORCED_WALL,
		"repair_cost": {"steel_plate": 3},
		"sprite": "metal_wall",
	},
	StructureType.REINFORCED_WALL: {
		"display_name": "Reinforced Wall",
		"category": StructureCategory.WALL,
		"description": "Maximum protection wall",
		"unlock_level": 20,
		"build_cost": {"steel_plate": 25, "titanium_bar": 5, "concrete": 10},
		"hp": 2500,
		"armor": 50,
		"resistances": {DamageType.PHYSICAL: 0.6, DamageType.FIRE: 0.7, DamageType.EXPLOSIVE: 0.4},
		"size": Vector2i(1, 1),
		"blocks_movement": true,
		"blocks_vision": true,
		"blocks_projectiles": true,
		"can_upgrade": false,
		"repair_cost": {"steel_plate": 5, "titanium_bar": 1},
		"sprite": "reinforced_wall",
	},
	
	# ========== DOORS ==========
	StructureType.WOOD_DOOR: {
		"display_name": "Wooden Door",
		"category": StructureCategory.DOOR,
		"description": "Basic wooden door",
		"unlock_level": 1,
		"build_cost": {"wood": 15, "nails": 5},
		"hp": 150,
		"armor": 0,
		"resistances": {DamageType.FIRE: -0.5},
		"size": Vector2i(1, 1),
		"blocks_movement": true,
		"blocks_vision": true,
		"blocks_projectiles": true,
		"can_open": true,
		"lock_type": "none",
		"repair_cost": {"wood": 4},
		"sprite": "wood_door",
	},
	StructureType.METAL_DOOR: {
		"display_name": "Metal Door",
		"category": StructureCategory.DOOR,
		"description": "Strong metal door with lock",
		"unlock_level": 8,
		"build_cost": {"steel_plate": 10, "nails": 10},
		"hp": 600,
		"armor": 15,
		"resistances": {DamageType.PHYSICAL: 0.3, DamageType.FIRE: 0.2},
		"size": Vector2i(1, 1),
		"blocks_movement": true,
		"blocks_vision": true,
		"blocks_projectiles": true,
		"can_open": true,
		"lock_type": "code",
		"repair_cost": {"steel_plate": 2},
		"sprite": "metal_door",
	},
	StructureType.REINFORCED_DOOR: {
		"display_name": "Reinforced Door",
		"category": StructureCategory.DOOR,
		"description": "Maximum security door",
		"unlock_level": 18,
		"build_cost": {"steel_plate": 20, "titanium_bar": 3, "electronics": 2},
		"hp": 1500,
		"armor": 40,
		"resistances": {DamageType.PHYSICAL: 0.5, DamageType.EXPLOSIVE: 0.3},
		"size": Vector2i(1, 1),
		"blocks_movement": true,
		"blocks_vision": true,
		"blocks_projectiles": true,
		"can_open": true,
		"lock_type": "keycard",
		"repair_cost": {"steel_plate": 4, "titanium_bar": 1},
		"sprite": "reinforced_door",
	},
	StructureType.GATE: {
		"display_name": "Gate",
		"category": StructureCategory.DOOR,
		"description": "Large vehicle gate",
		"unlock_level": 12,
		"build_cost": {"steel_plate": 30, "nails": 30, "gears": 5},
		"hp": 800,
		"armor": 20,
		"resistances": {DamageType.PHYSICAL: 0.2},
		"size": Vector2i(3, 1),
		"blocks_movement": true,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"can_open": true,
		"lock_type": "code",
		"repair_cost": {"steel_plate": 6},
		"sprite": "gate",
	},
	
	# ========== TURRETS ==========
	StructureType.BASIC_TURRET: {
		"display_name": "Basic Turret",
		"category": StructureCategory.TURRET,
		"description": "Automated defense turret",
		"unlock_level": 12,
		"build_cost": {"steel_plate": 20, "electronics": 5, "weapon_parts": 3},
		"hp": 300,
		"armor": 10,
		"resistances": {},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"attack_range": 300.0,
		"attack_damage": 15.0,
		"attack_rate": 0.5,  # Seconds between shots
		"ammo_type": "9mm_ammo",
		"ammo_capacity": 100,
		"rotation_speed": 180.0,  # Degrees per second
		"detection_angle": 360.0,
		"needs_power": true,
		"power_consumption": 10.0,
		"repair_cost": {"steel_plate": 5, "electronics": 1},
		"sprite": "basic_turret",
	},
	StructureType.SHOTGUN_TURRET: {
		"display_name": "Shotgun Turret",
		"category": StructureCategory.TURRET,
		"description": "Close-range spread turret",
		"unlock_level": 15,
		"build_cost": {"steel_plate": 25, "electronics": 8, "weapon_parts": 5},
		"hp": 350,
		"armor": 12,
		"resistances": {},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"attack_range": 150.0,
		"attack_damage": 8.0,  # Per pellet
		"pellet_count": 8,
		"attack_rate": 1.2,
		"ammo_type": "shotgun_ammo",
		"ammo_capacity": 50,
		"rotation_speed": 120.0,
		"detection_angle": 180.0,
		"needs_power": true,
		"power_consumption": 15.0,
		"repair_cost": {"steel_plate": 6, "electronics": 2},
		"sprite": "shotgun_turret",
	},
	StructureType.SNIPER_TURRET: {
		"display_name": "Sniper Turret",
		"category": StructureCategory.TURRET,
		"description": "Long-range precision turret",
		"unlock_level": 20,
		"build_cost": {"steel_plate": 30, "electronics": 12, "weapon_parts": 8, "optics": 2},
		"hp": 250,
		"armor": 8,
		"resistances": {},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"attack_range": 600.0,
		"attack_damage": 80.0,
		"attack_rate": 3.0,
		"ammo_type": "7.62mm_ammo",
		"ammo_capacity": 30,
		"rotation_speed": 60.0,
		"detection_angle": 90.0,
		"needs_power": true,
		"power_consumption": 20.0,
		"repair_cost": {"steel_plate": 8, "electronics": 3},
		"sprite": "sniper_turret",
	},
	StructureType.FLAME_TURRET: {
		"display_name": "Flame Turret",
		"category": StructureCategory.TURRET,
		"description": "Area denial flame thrower",
		"unlock_level": 18,
		"build_cost": {"steel_plate": 25, "electronics": 6, "rubber": 10},
		"hp": 280,
		"armor": 10,
		"resistances": {DamageType.FIRE: 0.5},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"attack_range": 100.0,
		"attack_damage": 25.0,
		"damage_type": DamageType.FIRE,
		"attack_rate": 0.1,  # Continuous
		"ammo_type": "fuel",
		"ammo_capacity": 200,
		"rotation_speed": 90.0,
		"detection_angle": 120.0,
		"needs_power": true,
		"power_consumption": 25.0,
		"repair_cost": {"steel_plate": 6, "rubber": 3},
		"sprite": "flame_turret",
	},
	
	# ========== TRAPS ==========
	StructureType.SPIKE_TRAP: {
		"display_name": "Spike Trap",
		"category": StructureCategory.TRAP,
		"description": "Hidden floor spikes",
		"unlock_level": 3,
		"build_cost": {"wood": 10, "iron_bar": 5},
		"hp": 50,
		"armor": 0,
		"resistances": {},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"trap_damage": 30.0,
		"trap_type": "instant",
		"rearm_time": 5.0,
		"max_triggers": -1,  # Unlimited
		"hidden": true,
		"affects_player": false,
		"repair_cost": {"iron_bar": 1},
		"sprite": "spike_trap",
	},
	StructureType.BEAR_TRAP: {
		"display_name": "Bear Trap",
		"category": StructureCategory.TRAP,
		"description": "Immobilizing trap",
		"unlock_level": 5,
		"build_cost": {"iron_bar": 8, "gears": 2},
		"hp": 80,
		"armor": 5,
		"resistances": {},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"trap_damage": 50.0,
		"trap_type": "immobilize",
		"immobilize_time": 5.0,
		"rearm_time": 10.0,
		"max_triggers": 1,
		"hidden": true,
		"affects_player": true,
		"repair_cost": {"iron_bar": 2},
		"sprite": "bear_trap",
	},
	StructureType.LANDMINE: {
		"display_name": "Landmine",
		"category": StructureCategory.TRAP,
		"description": "Explosive trap",
		"unlock_level": 10,
		"build_cost": {"iron_bar": 5, "gunpowder": 10, "electronics": 1},
		"hp": 20,
		"armor": 0,
		"resistances": {},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"trap_damage": 150.0,
		"damage_type": DamageType.EXPLOSIVE,
		"blast_radius": 80.0,
		"trap_type": "explosive",
		"rearm_time": 0,  # One-time use
		"max_triggers": 1,
		"hidden": true,
		"affects_player": true,
		"repair_cost": {},
		"sprite": "landmine",
	},
	StructureType.TRIPWIRE: {
		"display_name": "Tripwire Alarm",
		"category": StructureCategory.TRAP,
		"description": "Detection and alarm trigger",
		"unlock_level": 4,
		"build_cost": {"rope": 3, "electronics": 1},
		"hp": 10,
		"armor": 0,
		"resistances": {},
		"size": Vector2i(2, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"trap_damage": 0,
		"trap_type": "alarm",
		"alarm_radius": 500.0,
		"rearm_time": 3.0,
		"max_triggers": -1,
		"hidden": true,
		"affects_player": false,
		"repair_cost": {"rope": 1},
		"sprite": "tripwire",
	},
	StructureType.ELECTRIC_TRAP: {
		"display_name": "Electric Trap",
		"category": StructureCategory.TRAP,
		"description": "Stunning electric floor",
		"unlock_level": 15,
		"build_cost": {"steel_plate": 10, "electronics": 5, "copper_wire": 20},
		"hp": 100,
		"armor": 5,
		"resistances": {},
		"size": Vector2i(2, 2),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"trap_damage": 40.0,
		"damage_type": DamageType.ELECTRIC,
		"trap_type": "stun",
		"stun_time": 3.0,
		"rearm_time": 8.0,
		"max_triggers": -1,
		"hidden": false,
		"affects_player": true,
		"needs_power": true,
		"power_consumption": 30.0,
		"repair_cost": {"electronics": 1, "copper_wire": 5},
		"sprite": "electric_trap",
	},
	
	# ========== BARRIERS ==========
	StructureType.SANDBAG: {
		"display_name": "Sandbag",
		"category": StructureCategory.BARRIER,
		"description": "Low cover barrier",
		"unlock_level": 1,
		"build_cost": {"cloth": 5, "sand": 10},
		"hp": 100,
		"armor": 5,
		"resistances": {DamageType.PHYSICAL: 0.3},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": true,
		"cover_bonus": 0.3,
		"repair_cost": {"cloth": 1, "sand": 2},
		"sprite": "sandbag",
	},
	StructureType.BARRICADE: {
		"display_name": "Barricade",
		"category": StructureCategory.BARRIER,
		"description": "Quick wooden barrier",
		"unlock_level": 2,
		"build_cost": {"wood": 15},
		"hp": 120,
		"armor": 0,
		"resistances": {DamageType.FIRE: -0.3},
		"size": Vector2i(2, 1),
		"blocks_movement": true,
		"blocks_vision": false,
		"blocks_projectiles": true,
		"repair_cost": {"wood": 4},
		"sprite": "barricade",
	},
	StructureType.BARBED_WIRE: {
		"display_name": "Barbed Wire",
		"category": StructureCategory.BARRIER,
		"description": "Slows and damages enemies",
		"unlock_level": 4,
		"build_cost": {"iron_bar": 5, "wire": 10},
		"hp": 50,
		"armor": 0,
		"resistances": {},
		"size": Vector2i(2, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"slow_amount": 0.5,
		"contact_damage": 5.0,
		"damage_interval": 0.5,
		"repair_cost": {"wire": 3},
		"sprite": "barbed_wire",
	},
	StructureType.CONCRETE_BARRIER: {
		"display_name": "Concrete Barrier",
		"category": StructureCategory.BARRIER,
		"description": "Heavy duty barrier",
		"unlock_level": 12,
		"build_cost": {"concrete": 20, "steel_plate": 5},
		"hp": 800,
		"armor": 30,
		"resistances": {DamageType.PHYSICAL: 0.4, DamageType.EXPLOSIVE: 0.2},
		"size": Vector2i(2, 1),
		"blocks_movement": true,
		"blocks_vision": true,
		"blocks_projectiles": true,
		"repair_cost": {"concrete": 5},
		"sprite": "concrete_barrier",
	},
	
	# ========== UTILITY ==========
	StructureType.WATCHTOWER: {
		"display_name": "Watchtower",
		"category": StructureCategory.UTILITY,
		"description": "Elevated lookout platform",
		"unlock_level": 8,
		"build_cost": {"wood": 40, "nails": 30, "rope": 10},
		"hp": 400,
		"armor": 5,
		"resistances": {DamageType.FIRE: -0.3},
		"size": Vector2i(2, 2),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"detection_range": 400.0,
		"provides_high_ground": true,
		"accuracy_bonus": 0.2,
		"repair_cost": {"wood": 10},
		"sprite": "watchtower",
	},
	StructureType.SPOTLIGHT: {
		"display_name": "Spotlight",
		"category": StructureCategory.UTILITY,
		"description": "Illuminates area at night",
		"unlock_level": 10,
		"build_cost": {"steel_plate": 5, "electronics": 3, "glass": 2},
		"hp": 80,
		"armor": 0,
		"resistances": {},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"light_range": 300.0,
		"light_angle": 60.0,
		"rotation_speed": 45.0,
		"needs_power": true,
		"power_consumption": 5.0,
		"repair_cost": {"glass": 1},
		"sprite": "spotlight",
	},
	StructureType.ALARM: {
		"display_name": "Alarm System",
		"category": StructureCategory.UTILITY,
		"description": "Alerts when enemies detected",
		"unlock_level": 6,
		"build_cost": {"electronics": 5, "copper_wire": 10},
		"hp": 50,
		"armor": 0,
		"resistances": {},
		"size": Vector2i(1, 1),
		"blocks_movement": false,
		"blocks_vision": false,
		"blocks_projectiles": false,
		"detection_range": 200.0,
		"alarm_duration": 10.0,
		"needs_power": true,
		"power_consumption": 2.0,
		"repair_cost": {"electronics": 1},
		"sprite": "alarm",
	},
}


# ============================================================================
# STATE
# ============================================================================

var _structures: Dictionary = {}  # structure_id -> structure data
var _turret_targets: Dictionary = {}  # turret_id -> target entity
var _trap_cooldowns: Dictionary = {}  # trap_id -> cooldown remaining
var _power_consumers: Array = []


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_update_turrets(delta)
	_update_traps(delta)
	_update_barriers(delta)


# ============================================================================
# STRUCTURE MANAGEMENT
# ============================================================================

func place_structure(structure_type: int, position: Vector2, player_level: int = 1) -> Dictionary:
	var definition: Dictionary = STRUCTURE_DEFINITIONS.get(structure_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown structure type"}
	
	var required_level: int = definition.get("unlock_level", 1)
	if player_level < required_level:
		return {"success": false, "error": "Requires level %d" % required_level}
	
	# Check placement validity
	var size: Vector2i = definition.get("size", Vector2i(1, 1))
	if not _can_place_at(position, size):
		return {"success": false, "error": "Cannot place here"}
	
	var structure_id := "%d_%d_%d_%d" % [structure_type, int(position.x), int(position.y), randi() % 1000]
	
	var structure := {
		"id": structure_id,
		"type": structure_type,
		"type_name": StructureType.keys()[structure_type],
		"category": definition.get("category", StructureCategory.WALL),
		"display_name": definition.get("display_name", "Structure"),
		"position": position,
		"size": size,
		"hp": definition.get("hp", 100),
		"max_hp": definition.get("hp", 100),
		"armor": definition.get("armor", 0),
		"resistances": definition.get("resistances", {}),
		"blocks_movement": definition.get("blocks_movement", false),
		"blocks_vision": definition.get("blocks_vision", false),
		"blocks_projectiles": definition.get("blocks_projectiles", false),
		"level": 1,
		"placed_time": Time.get_unix_time_from_system(),
	}
	
	# Category-specific properties
	var category: int = definition.get("category", StructureCategory.WALL)
	
	match category:
		StructureCategory.DOOR:
			structure["is_open"] = false
			structure["is_locked"] = false
			structure["lock_type"] = definition.get("lock_type", "none")
			structure["lock_code"] = ""
		
		StructureCategory.TURRET:
			structure["current_ammo"] = definition.get("ammo_capacity", 100)
			structure["max_ammo"] = definition.get("ammo_capacity", 100)
			structure["ammo_type"] = definition.get("ammo_type", "")
			structure["attack_range"] = definition.get("attack_range", 200.0)
			structure["attack_damage"] = definition.get("attack_damage", 10.0)
			structure["attack_rate"] = definition.get("attack_rate", 0.5)
			structure["rotation"] = 0.0
			structure["rotation_speed"] = definition.get("rotation_speed", 180.0)
			structure["detection_angle"] = definition.get("detection_angle", 360.0)
			structure["is_active"] = true
			structure["attack_cooldown"] = 0.0
			structure["needs_power"] = definition.get("needs_power", false)
			structure["power_consumption"] = definition.get("power_consumption", 0)
			if definition.has("pellet_count"):
				structure["pellet_count"] = definition["pellet_count"]
		
		StructureCategory.TRAP:
			structure["is_armed"] = true
			structure["trigger_count"] = 0
			structure["max_triggers"] = definition.get("max_triggers", -1)
			structure["trap_damage"] = definition.get("trap_damage", 0)
			structure["trap_type"] = definition.get("trap_type", "instant")
			structure["rearm_time"] = definition.get("rearm_time", 5.0)
			structure["hidden"] = definition.get("hidden", false)
			structure["affects_player"] = definition.get("affects_player", false)
			if definition.has("immobilize_time"):
				structure["immobilize_time"] = definition["immobilize_time"]
			if definition.has("stun_time"):
				structure["stun_time"] = definition["stun_time"]
			if definition.has("blast_radius"):
				structure["blast_radius"] = definition["blast_radius"]
			if definition.has("alarm_radius"):
				structure["alarm_radius"] = definition["alarm_radius"]
		
		StructureCategory.BARRIER:
			if definition.has("slow_amount"):
				structure["slow_amount"] = definition["slow_amount"]
			if definition.has("contact_damage"):
				structure["contact_damage"] = definition["contact_damage"]
				structure["damage_interval"] = definition.get("damage_interval", 0.5)
			if definition.has("cover_bonus"):
				structure["cover_bonus"] = definition["cover_bonus"]
		
		StructureCategory.UTILITY:
			if definition.has("detection_range"):
				structure["detection_range"] = definition["detection_range"]
			if definition.has("light_range"):
				structure["light_range"] = definition["light_range"]
				structure["light_angle"] = definition.get("light_angle", 360.0)
				structure["spotlight_rotation"] = 0.0
	
	# Power requirements
	if definition.get("needs_power", false):
		structure["needs_power"] = true
		structure["power_consumption"] = definition.get("power_consumption", 10.0)
		structure["is_powered"] = false
		_power_consumers.append(structure_id)
	
	_structures[structure_id] = structure
	
	emit_signal("structure_placed", structure_id, structure_type)
	
	return {"success": true, "structure_id": structure_id, "structure": structure}


func remove_structure(structure_id: String) -> Dictionary:
	if structure_id not in _structures:
		return {"success": false, "error": "Structure not found"}
	
	var structure: Dictionary = _structures[structure_id]
	
	# Calculate salvage (50% of build cost)
	var structure_type: int = structure["type"]
	var definition: Dictionary = STRUCTURE_DEFINITIONS.get(structure_type, {})
	var build_cost: Dictionary = definition.get("build_cost", {})
	var salvage: Dictionary = {}
	
	for item_id in build_cost:
		salvage[item_id] = int(build_cost[item_id] * 0.5)
	
	_structures.erase(structure_id)
	_power_consumers.erase(structure_id)
	
	emit_signal("structure_destroyed", structure_id)
	
	return {"success": true, "salvage": salvage}


func _can_place_at(position: Vector2, size: Vector2i) -> bool:
	# Check for overlapping structures
	for structure in _structures.values():
		var s_pos: Vector2 = structure["position"]
		var s_size: Vector2i = structure["size"]
		
		# Simple AABB check
		if position.x < s_pos.x + s_size.x * 32 and \
		   position.x + size.x * 32 > s_pos.x and \
		   position.y < s_pos.y + s_size.y * 32 and \
		   position.y + size.y * 32 > s_pos.y:
			return false
	
	return true


# ============================================================================
# DAMAGE & REPAIR
# ============================================================================

func damage_structure(structure_id: String, damage: float, damage_type: int = DamageType.PHYSICAL) -> Dictionary:
	if structure_id not in _structures:
		return {}
	
	var structure: Dictionary = _structures[structure_id]
	
	# Calculate resistance
	var resistances: Dictionary = structure.get("resistances", {})
	var resistance: float = resistances.get(damage_type, 0.0)
	
	# Apply armor
	var armor: float = structure.get("armor", 0)
	var armor_reduction := armor / (armor + 100.0)
	
	# Calculate final damage
	var final_damage := damage * (1.0 - resistance) * (1.0 - armor_reduction)
	final_damage = maxf(1.0, final_damage)  # Minimum 1 damage
	
	structure["hp"] -= final_damage
	
	emit_signal("structure_damaged", structure_id, final_damage, structure["hp"])
	
	if structure["hp"] <= 0:
		structure["hp"] = 0
		_destroy_structure(structure_id)
		return {"destroyed": true}
	
	return {"damaged": true, "damage": final_damage, "remaining_hp": structure["hp"]}


func _destroy_structure(structure_id: String) -> void:
	if structure_id not in _structures:
		return
	
	var structure: Dictionary = _structures[structure_id]
	
	# Special handling for explosive traps
	if structure.get("trap_type", "") == "explosive":
		var blast_radius: float = structure.get("blast_radius", 80.0)
		var damage: float = structure.get("trap_damage", 100.0)
		_apply_explosion(structure["position"], blast_radius, damage)
	
	_structures.erase(structure_id)
	_power_consumers.erase(structure_id)
	
	emit_signal("structure_destroyed", structure_id)


func repair_structure(structure_id: String, repair_amount: float = -1) -> Dictionary:
	if structure_id not in _structures:
		return {"success": false, "error": "Structure not found"}
	
	var structure: Dictionary = _structures[structure_id]
	
	if repair_amount < 0:
		# Full repair
		structure["hp"] = structure["max_hp"]
	else:
		structure["hp"] = minf(structure["hp"] + repair_amount, structure["max_hp"])
	
	emit_signal("structure_repaired", structure_id, structure["hp"])
	
	return {"success": true, "new_hp": structure["hp"]}


func upgrade_structure(structure_id: String) -> Dictionary:
	if structure_id not in _structures:
		return {"success": false, "error": "Structure not found"}
	
	var structure: Dictionary = _structures[structure_id]
	var structure_type: int = structure["type"]
	var definition: Dictionary = STRUCTURE_DEFINITIONS.get(structure_type, {})
	
	if not definition.get("can_upgrade", false):
		return {"success": false, "error": "Cannot upgrade this structure"}
	
	var upgrade_to: int = definition.get("upgrade_to", -1)
	if upgrade_to < 0:
		return {"success": false, "error": "No upgrade available"}
	
	# Get new definition
	var new_def: Dictionary = STRUCTURE_DEFINITIONS.get(upgrade_to, {})
	if new_def.is_empty():
		return {"success": false, "error": "Invalid upgrade target"}
	
	# Apply upgrade
	structure["type"] = upgrade_to
	structure["type_name"] = StructureType.keys()[upgrade_to]
	structure["display_name"] = new_def.get("display_name", "Structure")
	structure["max_hp"] = new_def.get("hp", structure["max_hp"])
	structure["hp"] = structure["max_hp"]
	structure["armor"] = new_def.get("armor", 0)
	structure["resistances"] = new_def.get("resistances", {})
	structure["level"] += 1
	
	return {"success": true, "new_type": upgrade_to}


# ============================================================================
# TURRET LOGIC
# ============================================================================

func _update_turrets(delta: float) -> void:
	for structure_id in _structures:
		var structure: Dictionary = _structures[structure_id]
		
		if structure.get("category", -1) != StructureCategory.TURRET:
			continue
		
		if not structure.get("is_active", false):
			continue
		
		# Check power
		if structure.get("needs_power", false) and not structure.get("is_powered", false):
			continue
		
		# Check ammo
		if structure.get("current_ammo", 0) <= 0:
			continue
		
		# Update cooldown
		if structure.get("attack_cooldown", 0) > 0:
			structure["attack_cooldown"] -= delta
		
		# Find target
		var target := _find_turret_target(structure)
		
		if target.is_empty():
			_turret_targets.erase(structure_id)
			continue
		
		_turret_targets[structure_id] = target
		
		# Rotate towards target
		var target_pos: Vector2 = target.get("position", Vector2.ZERO)
		var turret_pos: Vector2 = structure["position"]
		var target_angle := rad_to_deg(turret_pos.angle_to_point(target_pos))
		var current_rotation: float = structure.get("rotation", 0.0)
		var rotation_speed: float = structure.get("rotation_speed", 180.0)
		
		var angle_diff := fmod(target_angle - current_rotation + 540.0, 360.0) - 180.0
		var rotation_step := rotation_speed * delta
		
		if absf(angle_diff) <= rotation_step:
			structure["rotation"] = target_angle
		else:
			structure["rotation"] += signf(angle_diff) * rotation_step
		
		# Fire if aimed and cooldown ready
		if absf(angle_diff) < 10.0 and structure.get("attack_cooldown", 0) <= 0:
			_turret_fire(structure_id, structure, target)


func _find_turret_target(turret: Dictionary) -> Dictionary:
	var turret_pos: Vector2 = turret["position"]
	var attack_range: float = turret.get("attack_range", 200.0)
	var detection_angle: float = turret.get("detection_angle", 360.0)
	var turret_rotation: float = turret.get("rotation", 0.0)
	
	var closest_target := {}
	var closest_dist := attack_range
	
	# Query enemies in range (this would integrate with enemy system)
	var enemies := _get_enemies_in_range(turret_pos, attack_range)
	
	for enemy in enemies:
		var enemy_pos: Vector2 = enemy.get("position", Vector2.ZERO)
		var dist := turret_pos.distance_to(enemy_pos)
		
		# Check angle
		if detection_angle < 360.0:
			var angle_to_enemy := rad_to_deg(turret_pos.angle_to_point(enemy_pos))
			var angle_diff := absf(fmod(angle_to_enemy - turret_rotation + 540.0, 360.0) - 180.0)
			if angle_diff > detection_angle / 2.0:
				continue
		
		if dist < closest_dist:
			closest_dist = dist
			closest_target = enemy
	
	return closest_target


func _turret_fire(turret_id: String, turret: Dictionary, target: Dictionary) -> void:
	var damage: float = turret.get("attack_damage", 10.0)
	var pellet_count: int = turret.get("pellet_count", 1)
	
	# Consume ammo
	turret["current_ammo"] -= 1
	
	# Set cooldown
	turret["attack_cooldown"] = turret.get("attack_rate", 0.5)
	
	# Apply damage
	var total_damage := damage * pellet_count
	
	emit_signal("turret_fired", turret_id, target.get("id", ""))
	
	# Signal for actual damage application would go to combat system


func _get_enemies_in_range(position: Vector2, radius: float) -> Array:
	# Placeholder - would integrate with enemy/entity system
	return []


func reload_turret(turret_id: String, ammo_items: Array) -> Dictionary:
	if turret_id not in _structures:
		return {"success": false, "error": "Turret not found"}
	
	var turret: Dictionary = _structures[turret_id]
	
	if turret.get("category", -1) != StructureCategory.TURRET:
		return {"success": false, "error": "Not a turret"}
	
	var ammo_type: String = turret.get("ammo_type", "")
	var max_ammo: int = turret.get("max_ammo", 100)
	var current_ammo: int = turret.get("current_ammo", 0)
	var ammo_needed := max_ammo - current_ammo
	
	var ammo_added := 0
	
	for item in ammo_items:
		if item.get("id", "") != ammo_type:
			continue
		
		var count: int = item.get("count", 0)
		var to_add := mini(count, ammo_needed - ammo_added)
		ammo_added += to_add
		
		if ammo_added >= ammo_needed:
			break
	
	turret["current_ammo"] = current_ammo + ammo_added
	
	return {"success": true, "ammo_loaded": ammo_added, "current_ammo": turret["current_ammo"]}


# ============================================================================
# TRAP LOGIC
# ============================================================================

func _update_traps(delta: float) -> void:
	# Update cooldowns
	var to_remove: Array = []
	for trap_id in _trap_cooldowns:
		_trap_cooldowns[trap_id] -= delta
		if _trap_cooldowns[trap_id] <= 0:
			to_remove.append(trap_id)
			if trap_id in _structures:
				_structures[trap_id]["is_armed"] = true
	
	for trap_id in to_remove:
		_trap_cooldowns.erase(trap_id)


func check_trap_trigger(position: Vector2, entity_id: String, is_player: bool = false) -> Dictionary:
	## Check if an entity at position triggers any traps
	for structure_id in _structures:
		var structure: Dictionary = _structures[structure_id]
		
		if structure.get("category", -1) != StructureCategory.TRAP:
			continue
		
		if not structure.get("is_armed", false):
			continue
		
		# Check player immunity
		if is_player and not structure.get("affects_player", false):
			continue
		
		# Check position overlap
		var trap_pos: Vector2 = structure["position"]
		var trap_size: Vector2i = structure.get("size", Vector2i(1, 1))
		var trap_rect := Rect2(trap_pos, Vector2(trap_size.x * 32, trap_size.y * 32))
		
		if trap_rect.has_point(position):
			return _trigger_trap(structure_id, structure, entity_id)
	
	return {}


func _trigger_trap(trap_id: String, trap: Dictionary, entity_id: String) -> Dictionary:
	var result := {
		"triggered": true,
		"trap_id": trap_id,
		"trap_type": trap.get("trap_type", "instant"),
		"damage": trap.get("trap_damage", 0),
	}
	
	# Handle trap type
	match trap["trap_type"]:
		"instant":
			result["effects"] = ["damage"]
		
		"immobilize":
			result["effects"] = ["damage", "immobilize"]
			result["immobilize_time"] = trap.get("immobilize_time", 3.0)
		
		"explosive":
			result["effects"] = ["explosion"]
			result["blast_radius"] = trap.get("blast_radius", 80.0)
			_apply_explosion(trap["position"], result["blast_radius"], result["damage"])
		
		"stun":
			result["effects"] = ["damage", "stun"]
			result["stun_time"] = trap.get("stun_time", 2.0)
		
		"alarm":
			result["effects"] = ["alarm"]
			result["alarm_radius"] = trap.get("alarm_radius", 500.0)
			result["damage"] = 0
	
	# Update trap state
	trap["is_armed"] = false
	trap["trigger_count"] += 1
	
	var max_triggers: int = trap.get("max_triggers", -1)
	var rearm_time: float = trap.get("rearm_time", 5.0)
	
	if max_triggers > 0 and trap["trigger_count"] >= max_triggers:
		# Trap destroyed
		if trap["trap_type"] != "explosive":
			_structures.erase(trap_id)
			emit_signal("structure_destroyed", trap_id)
	elif rearm_time > 0:
		_trap_cooldowns[trap_id] = rearm_time
	
	emit_signal("trap_triggered", trap_id, entity_id)
	
	return result


func _apply_explosion(position: Vector2, radius: float, damage: float) -> void:
	# Damage nearby structures
	for structure_id in _structures.keys():
		var structure: Dictionary = _structures[structure_id]
		var dist := position.distance_to(structure["position"])
		
		if dist <= radius:
			var falloff := 1.0 - (dist / radius)
			damage_structure(structure_id, damage * falloff, DamageType.EXPLOSIVE)
	
	# Entity damage would be handled by combat system


func rearm_trap(trap_id: String) -> bool:
	if trap_id not in _structures:
		return false
	
	var trap: Dictionary = _structures[trap_id]
	
	if trap.get("category", -1) != StructureCategory.TRAP:
		return false
	
	var max_triggers: int = trap.get("max_triggers", -1)
	if max_triggers > 0 and trap.get("trigger_count", 0) >= max_triggers:
		return false
	
	trap["is_armed"] = true
	_trap_cooldowns.erase(trap_id)
	
	return true


# ============================================================================
# BARRIER LOGIC
# ============================================================================

func _update_barriers(_delta: float) -> void:
	# Barriers are mostly passive, handled by collision checks
	pass


func get_barrier_effects(position: Vector2) -> Dictionary:
	## Get any effects from barriers at this position
	var effects := {
		"slow": 0.0,
		"contact_damage": 0.0,
		"cover_bonus": 0.0,
	}
	
	for structure in _structures.values():
		if structure.get("category", -1) != StructureCategory.BARRIER:
			continue
		
		var s_pos: Vector2 = structure["position"]
		var s_size: Vector2i = structure.get("size", Vector2i(1, 1))
		var rect := Rect2(s_pos, Vector2(s_size.x * 32, s_size.y * 32))
		
		if rect.has_point(position):
			if structure.has("slow_amount"):
				effects["slow"] = maxf(effects["slow"], structure["slow_amount"])
			if structure.has("contact_damage"):
				effects["contact_damage"] += structure["contact_damage"]
			if structure.has("cover_bonus"):
				effects["cover_bonus"] = maxf(effects["cover_bonus"], structure["cover_bonus"])
	
	return effects


# ============================================================================
# DOOR LOGIC
# ============================================================================

func toggle_door(door_id: String, has_key: bool = false, code: String = "") -> Dictionary:
	if door_id not in _structures:
		return {"success": false, "error": "Door not found"}
	
	var door: Dictionary = _structures[door_id]
	
	if door.get("category", -1) != StructureCategory.DOOR:
		return {"success": false, "error": "Not a door"}
	
	# Check lock
	if door.get("is_locked", false):
		var lock_type: String = door.get("lock_type", "none")
		
		match lock_type:
			"code":
				if code != door.get("lock_code", ""):
					return {"success": false, "error": "Wrong code"}
			"key", "keycard":
				if not has_key:
					return {"success": false, "error": "Requires key"}
	
	door["is_open"] = not door.get("is_open", false)
	door["blocks_movement"] = not door["is_open"]
	
	return {"success": true, "is_open": door["is_open"]}


func set_door_lock(door_id: String, locked: bool, code: String = "") -> bool:
	if door_id not in _structures:
		return false
	
	var door: Dictionary = _structures[door_id]
	
	if door.get("category", -1) != StructureCategory.DOOR:
		return false
	
	door["is_locked"] = locked
	if not code.is_empty():
		door["lock_code"] = code
	
	return true


# ============================================================================
# POWER INTEGRATION
# ============================================================================

func update_power_status(powered_ids: Array) -> void:
	## Called by power system to update which structures have power
	for consumer_id in _power_consumers:
		if consumer_id in _structures:
			_structures[consumer_id]["is_powered"] = consumer_id in powered_ids


# ============================================================================
# QUERIES
# ============================================================================

func get_structure(structure_id: String) -> Dictionary:
	return _structures.get(structure_id, {})


func get_all_structures() -> Array:
	return _structures.values()


func get_structures_by_category(category: int) -> Array:
	var matching: Array = []
	for s in _structures.values():
		if s.get("category", -1) == category:
			matching.append(s)
	return matching


func get_structures_in_radius(position: Vector2, radius: float) -> Array:
	var nearby: Array = []
	for s in _structures.values():
		if position.distance_to(s["position"]) <= radius:
			nearby.append(s)
	return nearby


func get_blocking_structures(position: Vector2) -> Array:
	## Get structures that block movement at this position
	var blocking: Array = []
	
	for s in _structures.values():
		if not s.get("blocks_movement", false):
			continue
		
		var s_pos: Vector2 = s["position"]
		var s_size: Vector2i = s.get("size", Vector2i(1, 1))
		var rect := Rect2(s_pos, Vector2(s_size.x * 32, s_size.y * 32))
		
		if rect.has_point(position):
			blocking.append(s)
	
	return blocking


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"structures": _structures.duplicate(true),
		"trap_cooldowns": _trap_cooldowns.duplicate(),
	}


func load_data(data: Dictionary) -> void:
	_structures = data.get("structures", {})
	_trap_cooldowns = data.get("trap_cooldowns", {})
	
	# Rebuild power consumers list
	_power_consumers.clear()
	for structure_id in _structures:
		if _structures[structure_id].get("needs_power", false):
			_power_consumers.append(structure_id)
