extends Node
class_name VehicleSystemClass
## Manages all vehicles - spawning, ownership, stats, upgrades, and interactions
## Handles vehicle inventory, fuel consumption, damage, and repairs

signal vehicle_spawned(vehicle_data: Dictionary)
signal vehicle_entered(vehicle_id: String, player_id: String)
signal vehicle_exited(vehicle_id: String, player_id: String)
signal vehicle_damaged(vehicle_id: String, damage: float, source: String)
signal vehicle_repaired(vehicle_id: String, amount: float)
signal vehicle_destroyed(vehicle_id: String)
signal vehicle_refueled(vehicle_id: String, amount: float)
signal vehicle_upgraded(vehicle_id: String, upgrade: String)
signal vehicle_inventory_changed(vehicle_id: String)
signal vehicle_unlocked(vehicle_type: int)

# ============================================================================
# VEHICLE CONFIGURATION
# ============================================================================

enum VehicleType {
	# Ground Vehicles - Light
	BICYCLE,
	MOTORCYCLE,
	QUAD_BIKE,
	GOLF_CART,
	
	# Ground Vehicles - Medium
	SEDAN,
	PICKUP_TRUCK,
	SUV,
	VAN,
	
	# Ground Vehicles - Heavy
	MILITARY_TRUCK,
	ARMORED_VAN,
	BUS,
	SEMI_TRUCK,
	
	# Special Vehicles
	BOAT,
	HELICOPTER,
	TANK,
	ATV_TRAILER,
}

enum VehicleState {
	PARKED,
	DRIVING,
	DAMAGED,
	DESTROYED,
	BEING_REPAIRED,
}

enum UpgradeSlot {
	ENGINE,
	ARMOR,
	STORAGE,
	FUEL_TANK,
	TIRES,
	WEAPONS,
	SPECIAL,
}

const VEHICLE_DEFINITIONS := {
	VehicleType.BICYCLE: {
		"display_name": "Bicycle",
		"description": "Silent and requires no fuel, but slow and fragile.",
		"max_health": 50,
		"max_fuel": 0,  # No fuel needed
		"fuel_consumption": 0.0,
		"speed": 80.0,
		"acceleration": 40.0,
		"handling": 0.9,
		"storage_slots": 4,
		"passenger_seats": 0,
		"noise_level": 0.0,
		"armor": 0,
		"unlock_level": 1,
		"craft_requirements": {
			"metal_scrap": 10,
			"rubber": 4,
			"rope": 2,
		},
		"repair_materials": {"metal_scrap": 2},
		"terrain_types": ["road", "grass", "dirt"],
		"upgrades_available": [UpgradeSlot.STORAGE],
	},
	VehicleType.MOTORCYCLE: {
		"display_name": "Motorcycle",
		"description": "Fast and agile, perfect for quick runs.",
		"max_health": 100,
		"max_fuel": 20,
		"fuel_consumption": 0.8,
		"speed": 160.0,
		"acceleration": 80.0,
		"handling": 0.85,
		"storage_slots": 6,
		"passenger_seats": 1,
		"noise_level": 0.6,
		"armor": 5,
		"unlock_level": 5,
		"craft_requirements": {
			"metal_scrap": 30,
			"engine_parts": 2,
			"rubber": 4,
			"fuel_tank": 1,
		},
		"repair_materials": {"metal_scrap": 5, "engine_parts": 1},
		"terrain_types": ["road", "grass", "dirt"],
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK],
	},
	VehicleType.QUAD_BIKE: {
		"display_name": "Quad Bike",
		"description": "All-terrain vehicle with decent storage.",
		"max_health": 120,
		"max_fuel": 25,
		"fuel_consumption": 1.0,
		"speed": 100.0,
		"acceleration": 60.0,
		"handling": 0.75,
		"storage_slots": 12,
		"passenger_seats": 1,
		"noise_level": 0.7,
		"armor": 10,
		"unlock_level": 8,
		"craft_requirements": {
			"metal_scrap": 40,
			"engine_parts": 3,
			"rubber": 8,
			"fuel_tank": 1,
		},
		"repair_materials": {"metal_scrap": 8, "engine_parts": 1},
		"terrain_types": ["road", "grass", "dirt", "sand", "mud"],
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK, UpgradeSlot.TIRES],
	},
	VehicleType.SEDAN: {
		"display_name": "Sedan",
		"description": "Reliable car with good fuel efficiency.",
		"max_health": 200,
		"max_fuel": 50,
		"fuel_consumption": 1.2,
		"speed": 140.0,
		"acceleration": 50.0,
		"handling": 0.7,
		"storage_slots": 16,
		"passenger_seats": 3,
		"noise_level": 0.5,
		"armor": 15,
		"unlock_level": 10,
		"craft_requirements": {
			"metal_scrap": 80,
			"engine_parts": 5,
			"rubber": 8,
			"fuel_tank": 2,
			"glass": 6,
		},
		"repair_materials": {"metal_scrap": 15, "engine_parts": 2},
		"terrain_types": ["road", "grass"],
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.ARMOR, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK],
	},
	VehicleType.PICKUP_TRUCK: {
		"display_name": "Pickup Truck",
		"description": "Tough truck with excellent cargo capacity.",
		"max_health": 300,
		"max_fuel": 80,
		"fuel_consumption": 2.0,
		"speed": 110.0,
		"acceleration": 35.0,
		"handling": 0.6,
		"storage_slots": 32,
		"passenger_seats": 2,
		"noise_level": 0.7,
		"armor": 25,
		"unlock_level": 15,
		"craft_requirements": {
			"metal_scrap": 120,
			"engine_parts": 8,
			"rubber": 8,
			"fuel_tank": 3,
			"glass": 4,
		},
		"repair_materials": {"metal_scrap": 25, "engine_parts": 3},
		"terrain_types": ["road", "grass", "dirt", "mud"],
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.ARMOR, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK, UpgradeSlot.TIRES],
	},
	VehicleType.SUV: {
		"display_name": "SUV",
		"description": "Versatile vehicle balancing speed, armor, and capacity.",
		"max_health": 350,
		"max_fuel": 70,
		"fuel_consumption": 2.5,
		"speed": 130.0,
		"acceleration": 45.0,
		"handling": 0.65,
		"storage_slots": 24,
		"passenger_seats": 4,
		"noise_level": 0.6,
		"armor": 30,
		"unlock_level": 18,
		"craft_requirements": {
			"metal_scrap": 150,
			"engine_parts": 10,
			"rubber": 8,
			"fuel_tank": 3,
			"glass": 8,
			"electronics": 4,
		},
		"repair_materials": {"metal_scrap": 30, "engine_parts": 4},
		"terrain_types": ["road", "grass", "dirt", "mud", "sand"],
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.ARMOR, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK, UpgradeSlot.TIRES, UpgradeSlot.SPECIAL],
	},
	VehicleType.VAN: {
		"display_name": "Cargo Van",
		"description": "Maximum storage capacity for hauling supplies.",
		"max_health": 250,
		"max_fuel": 60,
		"fuel_consumption": 2.2,
		"speed": 100.0,
		"acceleration": 30.0,
		"handling": 0.5,
		"storage_slots": 48,
		"passenger_seats": 2,
		"noise_level": 0.6,
		"armor": 20,
		"unlock_level": 12,
		"craft_requirements": {
			"metal_scrap": 100,
			"engine_parts": 6,
			"rubber": 8,
			"fuel_tank": 2,
			"glass": 4,
		},
		"repair_materials": {"metal_scrap": 20, "engine_parts": 3},
		"terrain_types": ["road", "grass"],
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.ARMOR, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK],
	},
	VehicleType.MILITARY_TRUCK: {
		"display_name": "Military Truck",
		"description": "Heavy-duty transport with excellent off-road capability.",
		"max_health": 500,
		"max_fuel": 150,
		"fuel_consumption": 4.0,
		"speed": 90.0,
		"acceleration": 25.0,
		"handling": 0.45,
		"storage_slots": 64,
		"passenger_seats": 6,
		"noise_level": 0.9,
		"armor": 50,
		"unlock_level": 25,
		"craft_requirements": {
			"metal_scrap": 250,
			"engine_parts": 15,
			"rubber": 12,
			"fuel_tank": 5,
			"military_parts": 10,
		},
		"repair_materials": {"metal_scrap": 50, "engine_parts": 5, "military_parts": 2},
		"terrain_types": ["road", "grass", "dirt", "mud", "sand", "rocky"],
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.ARMOR, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK, UpgradeSlot.TIRES, UpgradeSlot.WEAPONS],
	},
	VehicleType.ARMORED_VAN: {
		"display_name": "Armored Van",
		"description": "Heavily reinforced for dangerous zones.",
		"max_health": 600,
		"max_fuel": 80,
		"fuel_consumption": 3.5,
		"speed": 80.0,
		"acceleration": 20.0,
		"handling": 0.4,
		"storage_slots": 24,
		"passenger_seats": 4,
		"noise_level": 0.7,
		"armor": 80,
		"unlock_level": 30,
		"craft_requirements": {
			"metal_scrap": 300,
			"engine_parts": 12,
			"rubber": 8,
			"fuel_tank": 3,
			"steel_plate": 20,
			"military_parts": 8,
		},
		"repair_materials": {"metal_scrap": 60, "engine_parts": 4, "steel_plate": 5},
		"terrain_types": ["road", "grass", "dirt"],
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.ARMOR, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK, UpgradeSlot.WEAPONS, UpgradeSlot.SPECIAL],
	},
	VehicleType.BOAT: {
		"display_name": "Motor Boat",
		"description": "Navigate waterways to access remote locations.",
		"max_health": 150,
		"max_fuel": 40,
		"fuel_consumption": 1.5,
		"speed": 80.0,
		"acceleration": 30.0,
		"handling": 0.6,
		"storage_slots": 20,
		"passenger_seats": 3,
		"noise_level": 0.8,
		"armor": 10,
		"unlock_level": 20,
		"craft_requirements": {
			"wood_plank": 50,
			"metal_scrap": 40,
			"engine_parts": 5,
			"rubber": 4,
			"fuel_tank": 2,
		},
		"repair_materials": {"wood_plank": 10, "metal_scrap": 8},
		"terrain_types": ["water"],
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK],
	},
	VehicleType.HELICOPTER: {
		"display_name": "Helicopter",
		"description": "Ultimate mobility - fly over any terrain.",
		"max_health": 400,
		"max_fuel": 100,
		"fuel_consumption": 8.0,
		"speed": 200.0,
		"acceleration": 60.0,
		"handling": 0.7,
		"storage_slots": 16,
		"passenger_seats": 3,
		"noise_level": 1.0,
		"armor": 20,
		"unlock_level": 50,
		"craft_requirements": {
			"metal_scrap": 400,
			"engine_parts": 30,
			"electronics": 25,
			"fuel_tank": 5,
			"military_parts": 20,
			"rotor_blade": 4,
		},
		"repair_materials": {"metal_scrap": 80, "engine_parts": 10, "electronics": 5},
		"terrain_types": ["air"],
		"can_fly": true,
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.ARMOR, UpgradeSlot.STORAGE, UpgradeSlot.FUEL_TANK, UpgradeSlot.WEAPONS, UpgradeSlot.SPECIAL],
	},
	VehicleType.TANK: {
		"display_name": "Tank",
		"description": "Unstoppable armored assault vehicle.",
		"max_health": 2000,
		"max_fuel": 200,
		"fuel_consumption": 10.0,
		"speed": 50.0,
		"acceleration": 15.0,
		"handling": 0.3,
		"storage_slots": 12,
		"passenger_seats": 2,
		"noise_level": 1.0,
		"armor": 200,
		"unlock_level": 60,
		"craft_requirements": {
			"steel_plate": 100,
			"engine_parts": 40,
			"military_parts": 50,
			"fuel_tank": 10,
			"electronics": 20,
			"tank_treads": 2,
		},
		"repair_materials": {"steel_plate": 20, "engine_parts": 10, "military_parts": 10},
		"terrain_types": ["road", "grass", "dirt", "mud", "sand", "rocky"],
		"has_weapon": true,
		"weapon_type": "cannon",
		"upgrades_available": [UpgradeSlot.ENGINE, UpgradeSlot.ARMOR, UpgradeSlot.FUEL_TANK, UpgradeSlot.WEAPONS, UpgradeSlot.SPECIAL],
	},
}


# ============================================================================
# UPGRADE DEFINITIONS
# ============================================================================

const UPGRADE_DEFINITIONS := {
	# Engine Upgrades
	"engine_tuned": {
		"slot": UpgradeSlot.ENGINE,
		"tier": 1,
		"display_name": "Tuned Engine",
		"effects": {"speed": 1.1, "acceleration": 1.15},
		"requirements": {"engine_parts": 5, "tools": 2},
	},
	"engine_performance": {
		"slot": UpgradeSlot.ENGINE,
		"tier": 2,
		"display_name": "Performance Engine",
		"effects": {"speed": 1.25, "acceleration": 1.3, "fuel_consumption": 1.1},
		"requirements": {"engine_parts": 15, "electronics": 5, "military_parts": 3},
	},
	"engine_turbo": {
		"slot": UpgradeSlot.ENGINE,
		"tier": 3,
		"display_name": "Turbo Engine",
		"effects": {"speed": 1.5, "acceleration": 1.5, "fuel_consumption": 1.25},
		"requirements": {"engine_parts": 30, "electronics": 15, "military_parts": 10, "rare_parts": 2},
	},
	
	# Armor Upgrades
	"armor_reinforced": {
		"slot": UpgradeSlot.ARMOR,
		"tier": 1,
		"display_name": "Reinforced Plating",
		"effects": {"armor": 1.25, "max_health": 1.1, "speed": 0.95},
		"requirements": {"steel_plate": 10, "metal_scrap": 20},
	},
	"armor_military": {
		"slot": UpgradeSlot.ARMOR,
		"tier": 2,
		"display_name": "Military Armor",
		"effects": {"armor": 1.5, "max_health": 1.25, "speed": 0.9},
		"requirements": {"steel_plate": 25, "military_parts": 10},
	},
	"armor_composite": {
		"slot": UpgradeSlot.ARMOR,
		"tier": 3,
		"display_name": "Composite Armor",
		"effects": {"armor": 2.0, "max_health": 1.5, "speed": 0.95},
		"requirements": {"steel_plate": 50, "military_parts": 25, "rare_parts": 5},
	},
	
	# Storage Upgrades
	"storage_expanded": {
		"slot": UpgradeSlot.STORAGE,
		"tier": 1,
		"display_name": "Expanded Storage",
		"effects": {"storage_slots": 1.25},
		"requirements": {"metal_scrap": 15, "wood_plank": 10},
	},
	"storage_cargo": {
		"slot": UpgradeSlot.STORAGE,
		"tier": 2,
		"display_name": "Cargo Rack",
		"effects": {"storage_slots": 1.5},
		"requirements": {"metal_scrap": 35, "rope": 10},
	},
	"storage_maximum": {
		"slot": UpgradeSlot.STORAGE,
		"tier": 3,
		"display_name": "Maximum Storage",
		"effects": {"storage_slots": 2.0, "speed": 0.95},
		"requirements": {"metal_scrap": 60, "steel_plate": 15},
	},
	
	# Fuel Tank Upgrades
	"fuel_extended": {
		"slot": UpgradeSlot.FUEL_TANK,
		"tier": 1,
		"display_name": "Extended Tank",
		"effects": {"max_fuel": 1.25},
		"requirements": {"fuel_tank": 1, "metal_scrap": 10},
	},
	"fuel_large": {
		"slot": UpgradeSlot.FUEL_TANK,
		"tier": 2,
		"display_name": "Large Tank",
		"effects": {"max_fuel": 1.5},
		"requirements": {"fuel_tank": 2, "metal_scrap": 25},
	},
	"fuel_reserve": {
		"slot": UpgradeSlot.FUEL_TANK,
		"tier": 3,
		"display_name": "Reserve Tank System",
		"effects": {"max_fuel": 2.0, "fuel_consumption": 0.9},
		"requirements": {"fuel_tank": 4, "metal_scrap": 50, "electronics": 5},
	},
	
	# Tire Upgrades
	"tires_offroad": {
		"slot": UpgradeSlot.TIRES,
		"tier": 1,
		"display_name": "Off-Road Tires",
		"effects": {"handling": 1.1},
		"terrain_bonus": ["dirt", "mud", "sand"],
		"requirements": {"rubber": 8, "metal_scrap": 5},
	},
	"tires_allterrain": {
		"slot": UpgradeSlot.TIRES,
		"tier": 2,
		"display_name": "All-Terrain Tires",
		"effects": {"handling": 1.2},
		"terrain_bonus": ["dirt", "mud", "sand", "rocky"],
		"requirements": {"rubber": 16, "metal_scrap": 15, "military_parts": 2},
	},
	"tires_military": {
		"slot": UpgradeSlot.TIRES,
		"tier": 3,
		"display_name": "Military Run-Flat Tires",
		"effects": {"handling": 1.3, "armor": 1.1},
		"terrain_bonus": ["all"],
		"puncture_resistant": true,
		"requirements": {"rubber": 24, "military_parts": 8, "steel_plate": 5},
	},
	
	# Weapon Upgrades
	"weapon_mounted_gun": {
		"slot": UpgradeSlot.WEAPONS,
		"tier": 1,
		"display_name": "Mounted Machine Gun",
		"weapon": {"type": "machine_gun", "damage": 15, "fire_rate": 10.0, "ammo_type": "7.62mm"},
		"requirements": {"weapon_parts": 15, "metal_scrap": 30, "ammo_762": 100},
	},
	"weapon_turret": {
		"slot": UpgradeSlot.WEAPONS,
		"tier": 2,
		"display_name": "Auto Turret",
		"weapon": {"type": "turret", "damage": 25, "fire_rate": 8.0, "ammo_type": "7.62mm", "auto_aim": true},
		"requirements": {"weapon_parts": 30, "electronics": 20, "military_parts": 15},
	},
	"weapon_rocket": {
		"slot": UpgradeSlot.WEAPONS,
		"tier": 3,
		"display_name": "Rocket Launcher",
		"weapon": {"type": "rocket", "damage": 200, "fire_rate": 0.5, "ammo_type": "rocket"},
		"requirements": {"weapon_parts": 50, "electronics": 30, "military_parts": 30, "rare_parts": 10},
	},
	
	# Special Upgrades
	"special_nitro": {
		"slot": UpgradeSlot.SPECIAL,
		"tier": 1,
		"display_name": "Nitro Boost",
		"ability": {"type": "boost", "speed_mult": 2.0, "duration": 3.0, "cooldown": 30.0},
		"requirements": {"electronics": 10, "fuel_tank": 2, "chemicals": 5},
	},
	"special_ram": {
		"slot": UpgradeSlot.SPECIAL,
		"tier": 1,
		"display_name": "Reinforced Ramming Bar",
		"ability": {"type": "ram", "damage": 100, "self_damage_reduction": 0.5},
		"requirements": {"steel_plate": 20, "metal_scrap": 40},
	},
	"special_stealth": {
		"slot": UpgradeSlot.SPECIAL,
		"tier": 2,
		"display_name": "Noise Suppressor",
		"effects": {"noise_level": 0.5},
		"requirements": {"electronics": 25, "rubber": 15, "military_parts": 10},
	},
}


# ============================================================================
# STATE
# ============================================================================

var _vehicles: Dictionary = {}  # vehicle_id -> vehicle data
var _player_vehicles: Dictionary = {}  # player_id -> [vehicle_ids]
var _active_vehicle: String = ""  # Currently driven vehicle
var _unlocked_types: Array = [VehicleType.BICYCLE]  # Start with bicycle unlocked
var _vehicle_id_counter: int = 0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_update_vehicles(delta)


# ============================================================================
# VEHICLE CREATION
# ============================================================================

func spawn_vehicle(vehicle_type: int, position: Vector2, owner_id: String = "player") -> Dictionary:
	var definition: Dictionary = VEHICLE_DEFINITIONS.get(vehicle_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown vehicle type"}
	
	if vehicle_type not in _unlocked_types:
		return {"success": false, "error": "Vehicle type not unlocked"}
	
	_vehicle_id_counter += 1
	var vehicle_id := "vehicle_%d" % _vehicle_id_counter
	
	var vehicle_data := {
		"id": vehicle_id,
		"type": vehicle_type,
		"type_name": VehicleType.keys()[vehicle_type],
		"display_name": definition.get("display_name", "Vehicle"),
		"owner_id": owner_id,
		"position": position,
		"rotation": 0.0,
		"velocity": Vector2.ZERO,
		
		# Stats (can be modified by upgrades)
		"health": definition.get("max_health", 100),
		"max_health": definition.get("max_health", 100),
		"fuel": definition.get("max_fuel", 50),
		"max_fuel": definition.get("max_fuel", 50),
		"speed": definition.get("speed", 100.0),
		"acceleration": definition.get("acceleration", 50.0),
		"handling": definition.get("handling", 0.7),
		"fuel_consumption": definition.get("fuel_consumption", 1.0),
		"armor": definition.get("armor", 10),
		"noise_level": definition.get("noise_level", 0.5),
		"storage_slots": definition.get("storage_slots", 10),
		
		# State
		"state": VehicleState.PARKED,
		"driver_id": "",
		"passengers": [],
		"inventory": [],
		"terrain_types": definition.get("terrain_types", ["road"]),
		
		# Upgrades
		"upgrades": {},
		"upgrades_available": definition.get("upgrades_available", []),
		
		# Special
		"can_fly": definition.get("can_fly", false),
		"has_weapon": definition.get("has_weapon", false),
		"weapon_type": definition.get("weapon_type", ""),
		
		# Metadata
		"total_distance": 0.0,
		"created_at": Time.get_unix_time_from_system(),
	}
	
	_vehicles[vehicle_id] = vehicle_data
	
	# Add to player's vehicle list
	if owner_id not in _player_vehicles:
		_player_vehicles[owner_id] = []
	_player_vehicles[owner_id].append(vehicle_id)
	
	emit_signal("vehicle_spawned", vehicle_data)
	
	return {"success": true, "vehicle_id": vehicle_id, "vehicle": vehicle_data}


func craft_vehicle(vehicle_type: int, owner_id: String = "player") -> Dictionary:
	var definition: Dictionary = VEHICLE_DEFINITIONS.get(vehicle_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown vehicle type"}
	
	# Check requirements would be done here with inventory system
	var requirements: Dictionary = definition.get("craft_requirements", {})
	
	# For now, just spawn the vehicle at a default position
	return spawn_vehicle(vehicle_type, Vector2.ZERO, owner_id)


func unlock_vehicle_type(vehicle_type: int) -> void:
	if vehicle_type not in _unlocked_types:
		_unlocked_types.append(vehicle_type)
		emit_signal("vehicle_unlocked", vehicle_type)


# ============================================================================
# VEHICLE INTERACTION
# ============================================================================

func enter_vehicle(vehicle_id: String, player_id: String, as_driver: bool = true) -> Dictionary:
	if vehicle_id not in _vehicles:
		return {"success": false, "error": "Vehicle not found"}
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	
	if vehicle.get("state") == VehicleState.DESTROYED:
		return {"success": false, "error": "Vehicle is destroyed"}
	
	if as_driver:
		if vehicle.get("driver_id", "") != "":
			return {"success": false, "error": "Vehicle already has a driver"}
		
		vehicle["driver_id"] = player_id
		vehicle["state"] = VehicleState.DRIVING
		_active_vehicle = vehicle_id
	else:
		var passengers: Array = vehicle.get("passengers", [])
		var max_passengers: int = VEHICLE_DEFINITIONS.get(vehicle["type"], {}).get("passenger_seats", 0)
		
		if passengers.size() >= max_passengers:
			return {"success": false, "error": "Vehicle is full"}
		
		passengers.append(player_id)
		vehicle["passengers"] = passengers
	
	emit_signal("vehicle_entered", vehicle_id, player_id)
	
	return {"success": true}


func exit_vehicle(vehicle_id: String, player_id: String) -> Dictionary:
	if vehicle_id not in _vehicles:
		return {"success": false, "error": "Vehicle not found"}
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	
	if vehicle.get("driver_id") == player_id:
		vehicle["driver_id"] = ""
		vehicle["state"] = VehicleState.PARKED
		vehicle["velocity"] = Vector2.ZERO
		if _active_vehicle == vehicle_id:
			_active_vehicle = ""
	else:
		var passengers: Array = vehicle.get("passengers", [])
		passengers.erase(player_id)
		vehicle["passengers"] = passengers
	
	emit_signal("vehicle_exited", vehicle_id, player_id)
	
	return {"success": true}


# ============================================================================
# VEHICLE UPDATE
# ============================================================================

func _update_vehicles(delta: float) -> void:
	for vehicle_id in _vehicles:
		var vehicle: Dictionary = _vehicles[vehicle_id]
		
		if vehicle.get("state") == VehicleState.DRIVING:
			_update_driving_vehicle(vehicle, delta)


func _update_driving_vehicle(vehicle: Dictionary, delta: float) -> void:
	# Consume fuel
	if vehicle.get("max_fuel", 0) > 0:
		var speed_factor: float = vehicle.get("velocity", Vector2.ZERO).length() / vehicle.get("speed", 100.0)
		var fuel_used: float = vehicle.get("fuel_consumption", 1.0) * speed_factor * delta
		vehicle["fuel"] = maxf(vehicle["fuel"] - fuel_used, 0.0)
		
		# Out of fuel
		if vehicle["fuel"] <= 0:
			vehicle["state"] = VehicleState.PARKED
			vehicle["velocity"] = Vector2.ZERO
	
	# Track distance
	var distance: float = vehicle.get("velocity", Vector2.ZERO).length() * delta
	vehicle["total_distance"] = vehicle.get("total_distance", 0.0) + distance


func drive_vehicle(vehicle_id: String, direction: Vector2, delta: float) -> void:
	if vehicle_id not in _vehicles:
		return
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	
	if vehicle.get("state") != VehicleState.DRIVING:
		return
	
	if vehicle.get("fuel", 0) <= 0 and vehicle.get("max_fuel", 0) > 0:
		return
	
	var acceleration: float = vehicle.get("acceleration", 50.0)
	var max_speed: float = vehicle.get("speed", 100.0)
	var handling: float = vehicle.get("handling", 0.7)
	
	# Apply acceleration
	var target_velocity: Vector2 = direction.normalized() * max_speed
	vehicle["velocity"] = vehicle.get("velocity", Vector2.ZERO).lerp(target_velocity, acceleration * delta * 0.01)
	
	# Update position
	vehicle["position"] = vehicle.get("position", Vector2.ZERO) + vehicle["velocity"] * delta
	
	# Update rotation based on movement
	if vehicle["velocity"].length() > 1.0:
		var target_rotation: float = vehicle["velocity"].angle()
		vehicle["rotation"] = lerp_angle(vehicle.get("rotation", 0.0), target_rotation, handling * delta)


# ============================================================================
# DAMAGE & REPAIR
# ============================================================================

func damage_vehicle(vehicle_id: String, damage: float, source: String = "unknown") -> Dictionary:
	if vehicle_id not in _vehicles:
		return {"success": false, "error": "Vehicle not found"}
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	
	# Apply armor reduction
	var armor: float = vehicle.get("armor", 0)
	var damage_reduction: float = armor / (armor + 50.0)
	var actual_damage: float = damage * (1.0 - damage_reduction)
	
	vehicle["health"] = maxf(vehicle["health"] - actual_damage, 0.0)
	
	emit_signal("vehicle_damaged", vehicle_id, actual_damage, source)
	
	# Check destruction
	if vehicle["health"] <= 0:
		_destroy_vehicle(vehicle_id)
		return {"success": true, "destroyed": true, "damage_dealt": actual_damage}
	
	# Update state if heavily damaged
	if vehicle["health"] < vehicle["max_health"] * 0.25:
		vehicle["state"] = VehicleState.DAMAGED
	
	return {"success": true, "destroyed": false, "damage_dealt": actual_damage}


func repair_vehicle(vehicle_id: String, amount: float) -> Dictionary:
	if vehicle_id not in _vehicles:
		return {"success": false, "error": "Vehicle not found"}
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	
	if vehicle.get("state") == VehicleState.DESTROYED:
		return {"success": false, "error": "Cannot repair destroyed vehicle"}
	
	var old_health: float = vehicle["health"]
	vehicle["health"] = minf(vehicle["health"] + amount, vehicle["max_health"])
	var repaired: float = vehicle["health"] - old_health
	
	# Update state
	if vehicle["health"] >= vehicle["max_health"] * 0.25:
		if vehicle.get("driver_id", "") != "":
			vehicle["state"] = VehicleState.DRIVING
		else:
			vehicle["state"] = VehicleState.PARKED
	
	emit_signal("vehicle_repaired", vehicle_id, repaired)
	
	return {"success": true, "repaired": repaired, "health": vehicle["health"]}


func _destroy_vehicle(vehicle_id: String) -> void:
	if vehicle_id not in _vehicles:
		return
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	vehicle["state"] = VehicleState.DESTROYED
	vehicle["health"] = 0
	vehicle["driver_id"] = ""
	vehicle["passengers"] = []
	vehicle["velocity"] = Vector2.ZERO
	
	if _active_vehicle == vehicle_id:
		_active_vehicle = ""
	
	emit_signal("vehicle_destroyed", vehicle_id)


# ============================================================================
# FUEL
# ============================================================================

func refuel_vehicle(vehicle_id: String, amount: float) -> Dictionary:
	if vehicle_id not in _vehicles:
		return {"success": false, "error": "Vehicle not found"}
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	
	if vehicle.get("max_fuel", 0) <= 0:
		return {"success": false, "error": "Vehicle does not use fuel"}
	
	var old_fuel: float = vehicle["fuel"]
	vehicle["fuel"] = minf(vehicle["fuel"] + amount, vehicle["max_fuel"])
	var added: float = vehicle["fuel"] - old_fuel
	
	emit_signal("vehicle_refueled", vehicle_id, added)
	
	return {"success": true, "added": added, "fuel": vehicle["fuel"]}


func get_fuel_needed(vehicle_id: String) -> float:
	if vehicle_id not in _vehicles:
		return 0.0
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	return vehicle.get("max_fuel", 0) - vehicle.get("fuel", 0)


# ============================================================================
# INVENTORY
# ============================================================================

func add_to_vehicle_inventory(vehicle_id: String, item_id: String, count: int = 1) -> Dictionary:
	if vehicle_id not in _vehicles:
		return {"success": false, "error": "Vehicle not found"}
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	var inventory: Array = vehicle.get("inventory", [])
	var slots: int = vehicle.get("storage_slots", 10)
	
	if inventory.size() >= slots:
		return {"success": false, "error": "Vehicle inventory full"}
	
	inventory.append({"id": item_id, "count": count})
	vehicle["inventory"] = inventory
	
	emit_signal("vehicle_inventory_changed", vehicle_id)
	
	return {"success": true}


func remove_from_vehicle_inventory(vehicle_id: String, item_index: int) -> Dictionary:
	if vehicle_id not in _vehicles:
		return {"success": false, "error": "Vehicle not found"}
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	var inventory: Array = vehicle.get("inventory", [])
	
	if item_index < 0 or item_index >= inventory.size():
		return {"success": false, "error": "Invalid item index"}
	
	var item: Dictionary = inventory[item_index]
	inventory.remove_at(item_index)
	vehicle["inventory"] = inventory
	
	emit_signal("vehicle_inventory_changed", vehicle_id)
	
	return {"success": true, "item": item}


func get_vehicle_inventory(vehicle_id: String) -> Array:
	if vehicle_id not in _vehicles:
		return []
	return _vehicles[vehicle_id].get("inventory", [])


# ============================================================================
# UPGRADES
# ============================================================================

func install_upgrade(vehicle_id: String, upgrade_id: String) -> Dictionary:
	if vehicle_id not in _vehicles:
		return {"success": false, "error": "Vehicle not found"}
	
	var upgrade_def: Dictionary = UPGRADE_DEFINITIONS.get(upgrade_id, {})
	if upgrade_def.is_empty():
		return {"success": false, "error": "Unknown upgrade"}
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	var slot: int = upgrade_def.get("slot", UpgradeSlot.SPECIAL)
	
	# Check if slot is available for this vehicle
	if slot not in vehicle.get("upgrades_available", []):
		return {"success": false, "error": "Upgrade slot not available for this vehicle"}
	
	# Apply upgrade effects
	var effects: Dictionary = upgrade_def.get("effects", {})
	for stat in effects:
		if vehicle.has(stat):
			if stat == "storage_slots":
				vehicle[stat] = int(vehicle[stat] * effects[stat])
			else:
				vehicle[stat] = vehicle[stat] * effects[stat]
	
	# Store upgrade
	vehicle["upgrades"][slot] = upgrade_id
	
	emit_signal("vehicle_upgraded", vehicle_id, upgrade_id)
	
	return {"success": true, "upgrade": upgrade_id}


func get_installed_upgrades(vehicle_id: String) -> Dictionary:
	if vehicle_id not in _vehicles:
		return {}
	return _vehicles[vehicle_id].get("upgrades", {})


# ============================================================================
# QUERIES
# ============================================================================

func get_vehicle(vehicle_id: String) -> Dictionary:
	return _vehicles.get(vehicle_id, {})


func get_player_vehicles(player_id: String) -> Array:
	var vehicle_ids: Array = _player_vehicles.get(player_id, [])
	var vehicles: Array = []
	for vid in vehicle_ids:
		if vid in _vehicles:
			vehicles.append(_vehicles[vid])
	return vehicles


func get_active_vehicle() -> Dictionary:
	return get_vehicle(_active_vehicle)


func get_active_vehicle_id() -> String:
	return _active_vehicle


func is_vehicle_driveable(vehicle_id: String) -> bool:
	if vehicle_id not in _vehicles:
		return false
	
	var vehicle: Dictionary = _vehicles[vehicle_id]
	return vehicle.get("state") != VehicleState.DESTROYED and vehicle.get("health", 0) > 0


func get_vehicle_definition(vehicle_type: int) -> Dictionary:
	return VEHICLE_DEFINITIONS.get(vehicle_type, {}).duplicate()


func get_unlocked_vehicle_types() -> Array:
	return _unlocked_types.duplicate()


func get_all_vehicles() -> Array:
	return _vehicles.values()


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var vehicles_save: Dictionary = {}
	for vid in _vehicles:
		var vehicle: Dictionary = _vehicles[vid].duplicate(true)
		vehicle["position"] = {"x": vehicle["position"].x, "y": vehicle["position"].y}
		vehicle["velocity"] = {"x": vehicle["velocity"].x, "y": vehicle["velocity"].y}
		vehicles_save[vid] = vehicle
	
	return {
		"vehicles": vehicles_save,
		"player_vehicles": _player_vehicles.duplicate(true),
		"unlocked_types": _unlocked_types.duplicate(),
		"vehicle_id_counter": _vehicle_id_counter,
	}


func load_data(data: Dictionary) -> void:
	_vehicles.clear()
	for vid in data.get("vehicles", {}):
		var vehicle: Dictionary = data["vehicles"][vid]
		if vehicle.has("position") and vehicle["position"] is Dictionary:
			vehicle["position"] = Vector2(vehicle["position"]["x"], vehicle["position"]["y"])
		if vehicle.has("velocity") and vehicle["velocity"] is Dictionary:
			vehicle["velocity"] = Vector2(vehicle["velocity"]["x"], vehicle["velocity"]["y"])
		_vehicles[vid] = vehicle
	
	_player_vehicles = data.get("player_vehicles", {})
	_unlocked_types = data.get("unlocked_types", [VehicleType.BICYCLE])
	_vehicle_id_counter = data.get("vehicle_id_counter", 0)
