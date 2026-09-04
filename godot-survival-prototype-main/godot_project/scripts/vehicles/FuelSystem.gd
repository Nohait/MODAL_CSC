extends Node
class_name FuelSystemClass
## Manages fuel types, parts, and vehicle maintenance
## Handles fuel consumption, gas stations, and part durability

signal fuel_consumed(vehicle_id: String, amount: float, fuel_type: int)
signal fuel_added(vehicle_id: String, amount: float, fuel_type: int)
signal part_damaged(vehicle_id: String, part_type: int, durability: float)
signal part_broken(vehicle_id: String, part_type: int)
signal part_repaired(vehicle_id: String, part_type: int, amount: float)
signal part_replaced(vehicle_id: String, part_type: int)
signal gas_station_discovered(station_id: String)
signal maintenance_required(vehicle_id: String, parts: Array)

# ============================================================================
# FUEL CONFIGURATION
# ============================================================================

enum FuelType {
	NONE,
	GASOLINE,
	DIESEL,
	AVIATION,
	BIOFUEL,
	ELECTRICITY,
}

enum PartType {
	ENGINE,
	TRANSMISSION,
	BRAKES,
	SUSPENSION,
	TIRES,
	BATTERY,
	RADIATOR,
	FUEL_PUMP,
	EXHAUST,
	ALTERNATOR,
}

enum PartQuality {
	JUNK,
	WORN,
	STANDARD,
	QUALITY,
	MILITARY,
	PRISTINE,
}

const FUEL_DEFINITIONS := {
	FuelType.GASOLINE: {
		"display_name": "Gasoline",
		"description": "Standard fuel for most vehicles.",
		"efficiency": 1.0,
		"rarity": 0.7,
		"price_per_unit": 5,
		"icon": "fuel_gasoline",
		"flammable": true,
		"crafting_recipe": {
			"crude_oil": 3,
			"empty_canister": 1,
		},
	},
	FuelType.DIESEL: {
		"display_name": "Diesel",
		"description": "Heavy-duty fuel for trucks and military vehicles.",
		"efficiency": 1.2,
		"rarity": 0.5,
		"price_per_unit": 8,
		"icon": "fuel_diesel",
		"flammable": true,
		"crafting_recipe": {
			"crude_oil": 4,
			"empty_canister": 1,
			"chemicals": 1,
		},
	},
	FuelType.AVIATION: {
		"display_name": "Aviation Fuel",
		"description": "High-octane fuel for helicopters.",
		"efficiency": 1.5,
		"rarity": 0.2,
		"price_per_unit": 25,
		"icon": "fuel_aviation",
		"flammable": true,
		"explosive": true,
		"crafting_recipe": {
			"crude_oil": 6,
			"chemicals": 3,
			"empty_canister": 1,
			"military_parts": 1,
		},
	},
	FuelType.BIOFUEL: {
		"display_name": "Biofuel",
		"description": "Renewable fuel made from organic materials.",
		"efficiency": 0.8,
		"rarity": 0.6,
		"price_per_unit": 3,
		"icon": "fuel_biofuel",
		"flammable": true,
		"crafting_recipe": {
			"plant_matter": 10,
			"water": 5,
			"empty_canister": 1,
		},
	},
	FuelType.ELECTRICITY: {
		"display_name": "Battery Charge",
		"description": "Electric power for battery-powered vehicles.",
		"efficiency": 1.3,
		"rarity": 0.3,
		"price_per_unit": 15,
		"icon": "fuel_electric",
		"flammable": false,
		"requires_generator": true,
	},
}


const PART_DEFINITIONS := {
	PartType.ENGINE: {
		"display_name": "Engine",
		"description": "The heart of the vehicle.",
		"max_durability": 1000,
		"degradation_rate": 0.1,
		"critical": true,
		"effects_when_damaged": {"speed": -0.3, "fuel_consumption": 0.3},
		"effects_when_broken": {"speed": -1.0},  # Vehicle cannot move
		"repair_materials": {"engine_parts": 2, "oil": 1},
		"replacement_materials": {"engine_parts": 10, "electronics": 3},
	},
	PartType.TRANSMISSION: {
		"display_name": "Transmission",
		"description": "Transfers power to wheels.",
		"max_durability": 800,
		"degradation_rate": 0.08,
		"critical": true,
		"effects_when_damaged": {"acceleration": -0.4, "handling": -0.2},
		"effects_when_broken": {"acceleration": -1.0},
		"repair_materials": {"engine_parts": 1, "oil": 1},
		"replacement_materials": {"engine_parts": 6, "metal_scrap": 10},
	},
	PartType.BRAKES: {
		"display_name": "Brakes",
		"description": "Stops the vehicle.",
		"max_durability": 500,
		"degradation_rate": 0.15,
		"critical": false,
		"effects_when_damaged": {"handling": -0.3},
		"effects_when_broken": {"handling": -0.6},
		"repair_materials": {"metal_scrap": 3, "rubber": 1},
		"replacement_materials": {"metal_scrap": 8, "rubber": 4},
	},
	PartType.SUSPENSION: {
		"display_name": "Suspension",
		"description": "Absorbs shocks from rough terrain.",
		"max_durability": 600,
		"degradation_rate": 0.12,
		"critical": false,
		"effects_when_damaged": {"handling": -0.2, "speed": -0.1},
		"effects_when_broken": {"handling": -0.5, "speed": -0.2},
		"repair_materials": {"metal_scrap": 2, "rubber": 2},
		"replacement_materials": {"metal_scrap": 10, "rubber": 6},
	},
	PartType.TIRES: {
		"display_name": "Tires",
		"description": "Grip the road.",
		"max_durability": 400,
		"degradation_rate": 0.2,
		"critical": false,
		"effects_when_damaged": {"speed": -0.15, "handling": -0.15},
		"effects_when_broken": {"speed": -0.5, "handling": -0.4},
		"repair_materials": {"rubber": 2},
		"replacement_materials": {"rubber": 8},
	},
	PartType.BATTERY: {
		"display_name": "Battery",
		"description": "Powers electronics and starting.",
		"max_durability": 300,
		"degradation_rate": 0.05,
		"critical": false,
		"effects_when_damaged": {},
		"effects_when_broken": {"cannot_start": true},
		"repair_materials": {"electronics": 1, "chemicals": 1},
		"replacement_materials": {"electronics": 4, "chemicals": 2, "metal_scrap": 3},
	},
	PartType.RADIATOR: {
		"display_name": "Radiator",
		"description": "Cools the engine.",
		"max_durability": 400,
		"degradation_rate": 0.1,
		"critical": false,
		"effects_when_damaged": {"fuel_consumption": 0.2},
		"effects_when_broken": {"overheating": true, "fuel_consumption": 0.5},
		"repair_materials": {"metal_scrap": 3, "rubber": 1},
		"replacement_materials": {"metal_scrap": 8, "rubber": 3, "water": 5},
	},
	PartType.FUEL_PUMP: {
		"display_name": "Fuel Pump",
		"description": "Delivers fuel to engine.",
		"max_durability": 500,
		"degradation_rate": 0.08,
		"critical": true,
		"effects_when_damaged": {"fuel_consumption": 0.25},
		"effects_when_broken": {"cannot_use_fuel": true},
		"repair_materials": {"engine_parts": 1, "rubber": 1},
		"replacement_materials": {"engine_parts": 4, "rubber": 2, "metal_scrap": 3},
	},
	PartType.EXHAUST: {
		"display_name": "Exhaust System",
		"description": "Vents engine gases.",
		"max_durability": 350,
		"degradation_rate": 0.1,
		"critical": false,
		"effects_when_damaged": {"noise_level": 0.3},
		"effects_when_broken": {"noise_level": 0.6, "fuel_consumption": 0.1},
		"repair_materials": {"metal_scrap": 2},
		"replacement_materials": {"metal_scrap": 6},
	},
	PartType.ALTERNATOR: {
		"display_name": "Alternator",
		"description": "Charges the battery while driving.",
		"max_durability": 400,
		"degradation_rate": 0.06,
		"critical": false,
		"effects_when_damaged": {},
		"effects_when_broken": {"battery_drain": true},
		"repair_materials": {"electronics": 2, "metal_scrap": 1},
		"replacement_materials": {"electronics": 5, "metal_scrap": 4},
	},
}


const QUALITY_MULTIPLIERS := {
	PartQuality.JUNK: {"durability": 0.3, "price": 0.2},
	PartQuality.WORN: {"durability": 0.6, "price": 0.5},
	PartQuality.STANDARD: {"durability": 1.0, "price": 1.0},
	PartQuality.QUALITY: {"durability": 1.3, "price": 1.8},
	PartQuality.MILITARY: {"durability": 1.6, "price": 3.0},
	PartQuality.PRISTINE: {"durability": 2.0, "price": 5.0},
}


# ============================================================================
# GAS STATION CONFIGURATION
# ============================================================================

const GAS_STATION_TYPES := {
	"small_station": {
		"display_name": "Small Gas Station",
		"fuel_capacity": 200,
		"refill_rate": 0.5,  # Per in-game hour
		"fuel_types": [FuelType.GASOLINE],
		"has_shop": false,
		"has_mechanic": false,
	},
	"medium_station": {
		"display_name": "Gas Station",
		"fuel_capacity": 500,
		"refill_rate": 1.0,
		"fuel_types": [FuelType.GASOLINE, FuelType.DIESEL],
		"has_shop": true,
		"has_mechanic": false,
	},
	"large_station": {
		"display_name": "Truck Stop",
		"fuel_capacity": 1000,
		"refill_rate": 2.0,
		"fuel_types": [FuelType.GASOLINE, FuelType.DIESEL],
		"has_shop": true,
		"has_mechanic": true,
	},
	"military_depot": {
		"display_name": "Military Fuel Depot",
		"fuel_capacity": 2000,
		"refill_rate": 0.2,  # Rare refills
		"fuel_types": [FuelType.GASOLINE, FuelType.DIESEL, FuelType.AVIATION],
		"has_shop": false,
		"has_mechanic": true,
		"requires_clearance": true,
	},
	"charging_station": {
		"display_name": "Charging Station",
		"fuel_capacity": 500,
		"refill_rate": 0.1,  # Requires power
		"fuel_types": [FuelType.ELECTRICITY],
		"has_shop": false,
		"has_mechanic": false,
		"requires_power": true,
	},
}


# ============================================================================
# STATE
# ============================================================================

var _vehicle_parts: Dictionary = {}  # vehicle_id -> {part_type -> part_data}
var _vehicle_fuel_types: Dictionary = {}  # vehicle_id -> fuel_type
var _gas_stations: Dictionary = {}  # station_id -> station_data
var _discovered_stations: Array = []
var _fuel_inventory: Dictionary = {}  # fuel_type -> amount in player inventory
var _parts_inventory: Array = []  # Array of part items


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_update_gas_stations(delta)


# ============================================================================
# VEHICLE PARTS MANAGEMENT
# ============================================================================

func initialize_vehicle_parts(vehicle_id: String) -> void:
	if vehicle_id in _vehicle_parts:
		return
	
	var parts: Dictionary = {}
	for part_type in PartType.values():
		var def: Dictionary = PART_DEFINITIONS.get(part_type, {})
		parts[part_type] = {
			"type": part_type,
			"quality": PartQuality.STANDARD,
			"durability": def.get("max_durability", 500),
			"max_durability": def.get("max_durability", 500),
		}
	
	_vehicle_parts[vehicle_id] = parts


func get_vehicle_parts(vehicle_id: String) -> Dictionary:
	return _vehicle_parts.get(vehicle_id, {})


func get_part_status(vehicle_id: String, part_type: int) -> Dictionary:
	var parts: Dictionary = _vehicle_parts.get(vehicle_id, {})
	return parts.get(part_type, {})


func degrade_parts(vehicle_id: String, delta: float, terrain: String = "road") -> void:
	if vehicle_id not in _vehicle_parts:
		return
	
	var terrain_mult := 1.0
	match terrain:
		"road":
			terrain_mult = 1.0
		"grass":
			terrain_mult = 1.2
		"dirt":
			terrain_mult = 1.5
		"mud":
			terrain_mult = 2.0
		"sand":
			terrain_mult = 1.8
		"rocky":
			terrain_mult = 2.5
	
	var parts: Dictionary = _vehicle_parts[vehicle_id]
	
	for part_type in parts:
		var part: Dictionary = parts[part_type]
		var def: Dictionary = PART_DEFINITIONS.get(part_type, {})
		var degradation: float = def.get("degradation_rate", 0.1) * terrain_mult * delta
		
		part["durability"] = maxf(part["durability"] - degradation, 0.0)
		
		# Check for breakage
		if part["durability"] <= 0 and part.get("was_working", true):
			part["was_working"] = false
			emit_signal("part_broken", vehicle_id, part_type)


func damage_part(vehicle_id: String, part_type: int, amount: float) -> void:
	if vehicle_id not in _vehicle_parts:
		return
	
	var parts: Dictionary = _vehicle_parts[vehicle_id]
	if part_type not in parts:
		return
	
	var part: Dictionary = parts[part_type]
	var old_durability: float = part["durability"]
	part["durability"] = maxf(part["durability"] - amount, 0.0)
	
	emit_signal("part_damaged", vehicle_id, part_type, part["durability"])
	
	if old_durability > 0 and part["durability"] <= 0:
		part["was_working"] = false
		emit_signal("part_broken", vehicle_id, part_type)


func repair_part(vehicle_id: String, part_type: int, amount: float) -> Dictionary:
	if vehicle_id not in _vehicle_parts:
		return {"success": false, "error": "Vehicle not found"}
	
	var parts: Dictionary = _vehicle_parts[vehicle_id]
	if part_type not in parts:
		return {"success": false, "error": "Part not found"}
	
	var part: Dictionary = parts[part_type]
	var old_durability: float = part["durability"]
	part["durability"] = minf(part["durability"] + amount, part["max_durability"])
	var repaired: float = part["durability"] - old_durability
	
	if old_durability <= 0 and part["durability"] > 0:
		part["was_working"] = true
	
	emit_signal("part_repaired", vehicle_id, part_type, repaired)
	
	return {"success": true, "repaired": repaired}


func replace_part(vehicle_id: String, part_type: int, quality: int = PartQuality.STANDARD) -> Dictionary:
	if vehicle_id not in _vehicle_parts:
		return {"success": false, "error": "Vehicle not found"}
	
	var parts: Dictionary = _vehicle_parts[vehicle_id]
	var def: Dictionary = PART_DEFINITIONS.get(part_type, {})
	var quality_mult: Dictionary = QUALITY_MULTIPLIERS.get(quality, {})
	
	var max_durability: float = def.get("max_durability", 500) * quality_mult.get("durability", 1.0)
	
	parts[part_type] = {
		"type": part_type,
		"quality": quality,
		"durability": max_durability,
		"max_durability": max_durability,
		"was_working": true,
	}
	
	emit_signal("part_replaced", vehicle_id, part_type)
	
	return {"success": true}


func get_part_effects(vehicle_id: String) -> Dictionary:
	if vehicle_id not in _vehicle_parts:
		return {}
	
	var effects: Dictionary = {
		"speed": 0.0,
		"acceleration": 0.0,
		"handling": 0.0,
		"fuel_consumption": 0.0,
		"noise_level": 0.0,
	}
	
	var parts: Dictionary = _vehicle_parts[vehicle_id]
	
	for part_type in parts:
		var part: Dictionary = parts[part_type]
		var def: Dictionary = PART_DEFINITIONS.get(part_type, {})
		
		var part_effects: Dictionary
		if part["durability"] <= 0:
			part_effects = def.get("effects_when_broken", {})
		elif part["durability"] < part["max_durability"] * 0.3:
			part_effects = def.get("effects_when_damaged", {})
		else:
			continue
		
		for effect in part_effects:
			if effect in effects:
				effects[effect] += part_effects[effect]
	
	return effects


func get_maintenance_needed(vehicle_id: String) -> Array:
	if vehicle_id not in _vehicle_parts:
		return []
	
	var needed: Array = []
	var parts: Dictionary = _vehicle_parts[vehicle_id]
	
	for part_type in parts:
		var part: Dictionary = parts[part_type]
		if part["durability"] < part["max_durability"] * 0.5:
			var def: Dictionary = PART_DEFINITIONS.get(part_type, {})
			needed.append({
				"part_type": part_type,
				"part_name": def.get("display_name", "Unknown"),
				"durability": part["durability"],
				"max_durability": part["max_durability"],
				"critical": def.get("critical", false),
			})
	
	if not needed.is_empty():
		emit_signal("maintenance_required", vehicle_id, needed)
	
	return needed


# ============================================================================
# FUEL MANAGEMENT
# ============================================================================

func set_vehicle_fuel_type(vehicle_id: String, fuel_type: int) -> void:
	_vehicle_fuel_types[vehicle_id] = fuel_type


func get_vehicle_fuel_type(vehicle_id: String) -> int:
	return _vehicle_fuel_types.get(vehicle_id, FuelType.GASOLINE)


func consume_fuel(vehicle_id: String, base_amount: float) -> float:
	var fuel_type: int = get_vehicle_fuel_type(vehicle_id)
	var def: Dictionary = FUEL_DEFINITIONS.get(fuel_type, {})
	var efficiency: float = def.get("efficiency", 1.0)
	
	var actual_consumption: float = base_amount / efficiency
	
	emit_signal("fuel_consumed", vehicle_id, actual_consumption, fuel_type)
	
	return actual_consumption


func add_fuel_to_inventory(fuel_type: int, amount: float) -> void:
	_fuel_inventory[fuel_type] = _fuel_inventory.get(fuel_type, 0.0) + amount


func get_fuel_inventory(fuel_type: int = -1) -> float:
	if fuel_type < 0:
		var total: float = 0.0
		for ft in _fuel_inventory:
			total += _fuel_inventory[ft]
		return total
	return _fuel_inventory.get(fuel_type, 0.0)


func use_fuel_from_inventory(fuel_type: int, amount: float) -> Dictionary:
	var available: float = _fuel_inventory.get(fuel_type, 0.0)
	if available < amount:
		return {"success": false, "error": "Not enough fuel", "available": available}
	
	_fuel_inventory[fuel_type] = available - amount
	return {"success": true, "used": amount}


func craft_fuel(fuel_type: int) -> Dictionary:
	var def: Dictionary = FUEL_DEFINITIONS.get(fuel_type, {})
	if def.is_empty():
		return {"success": false, "error": "Unknown fuel type"}
	
	# Check recipe requirements with inventory system
	# For now, just add fuel
	add_fuel_to_inventory(fuel_type, 10.0)
	
	return {"success": true, "amount": 10.0}


func get_fuel_definition(fuel_type: int) -> Dictionary:
	return FUEL_DEFINITIONS.get(fuel_type, {}).duplicate()


# ============================================================================
# GAS STATIONS
# ============================================================================

func register_gas_station(station_id: String, station_type: String, position: Vector2) -> Dictionary:
	var type_def: Dictionary = GAS_STATION_TYPES.get(station_type, {})
	if type_def.is_empty():
		return {"success": false, "error": "Unknown station type"}
	
	var station_data := {
		"id": station_id,
		"type": station_type,
		"display_name": type_def.get("display_name", "Gas Station"),
		"position": position,
		"fuel_capacity": type_def.get("fuel_capacity", 500),
		"current_fuel": {},
		"refill_rate": type_def.get("refill_rate", 1.0),
		"fuel_types": type_def.get("fuel_types", [FuelType.GASOLINE]),
		"has_shop": type_def.get("has_shop", false),
		"has_mechanic": type_def.get("has_mechanic", false),
		"requires_clearance": type_def.get("requires_clearance", false),
		"requires_power": type_def.get("requires_power", false),
		"powered": not type_def.get("requires_power", false),
	}
	
	# Initialize fuel levels
	for fuel_type in station_data["fuel_types"]:
		station_data["current_fuel"][fuel_type] = station_data["fuel_capacity"] * randf_range(0.2, 0.8)
	
	_gas_stations[station_id] = station_data
	
	return {"success": true, "station": station_data}


func discover_station(station_id: String) -> void:
	if station_id not in _discovered_stations and station_id in _gas_stations:
		_discovered_stations.append(station_id)
		emit_signal("gas_station_discovered", station_id)


func _update_gas_stations(delta: float) -> void:
	# Slowly refill gas stations over time
	var refill_delta: float = delta / 3600.0  # Convert to hours
	
	for station_id in _gas_stations:
		var station: Dictionary = _gas_stations[station_id]
		
		if station.get("requires_power", false) and not station.get("powered", false):
			continue
		
		var refill_rate: float = station.get("refill_rate", 1.0)
		var capacity: float = station.get("fuel_capacity", 500)
		
		for fuel_type in station.get("fuel_types", []):
			var current: float = station["current_fuel"].get(fuel_type, 0.0)
			station["current_fuel"][fuel_type] = minf(current + refill_rate * refill_delta, capacity)


func get_station_fuel(station_id: String, fuel_type: int) -> float:
	if station_id not in _gas_stations:
		return 0.0
	
	return _gas_stations[station_id].get("current_fuel", {}).get(fuel_type, 0.0)


func purchase_fuel(station_id: String, fuel_type: int, amount: float) -> Dictionary:
	if station_id not in _gas_stations:
		return {"success": false, "error": "Station not found"}
	
	var station: Dictionary = _gas_stations[station_id]
	
	if fuel_type not in station.get("fuel_types", []):
		return {"success": false, "error": "Fuel type not available"}
	
	var available: float = station["current_fuel"].get(fuel_type, 0.0)
	var actual_amount: float = minf(amount, available)
	
	if actual_amount <= 0:
		return {"success": false, "error": "No fuel available"}
	
	var fuel_def: Dictionary = FUEL_DEFINITIONS.get(fuel_type, {})
	var cost: int = int(actual_amount * fuel_def.get("price_per_unit", 5))
	
	station["current_fuel"][fuel_type] = available - actual_amount
	
	emit_signal("fuel_added", "", actual_amount, fuel_type)
	
	return {"success": true, "amount": actual_amount, "cost": cost}


func get_discovered_stations() -> Array:
	var stations: Array = []
	for station_id in _discovered_stations:
		if station_id in _gas_stations:
			stations.append(_gas_stations[station_id])
	return stations


func get_all_stations() -> Array:
	return _gas_stations.values()


func get_station(station_id: String) -> Dictionary:
	return _gas_stations.get(station_id, {})


func get_nearest_station(position: Vector2, fuel_type: int = -1) -> Dictionary:
	var nearest: Dictionary = {}
	var min_distance: float = INF
	
	for station_id in _discovered_stations:
		if station_id not in _gas_stations:
			continue
		
		var station: Dictionary = _gas_stations[station_id]
		
		# Check fuel type if specified
		if fuel_type >= 0 and fuel_type not in station.get("fuel_types", []):
			continue
		
		var distance: float = position.distance_to(station.get("position", Vector2.ZERO))
		if distance < min_distance:
			min_distance = distance
			nearest = station
	
	return nearest


# ============================================================================
# PARTS INVENTORY
# ============================================================================

func add_part_to_inventory(part_type: int, quality: int = PartQuality.STANDARD) -> void:
	var def: Dictionary = PART_DEFINITIONS.get(part_type, {})
	var quality_mult: Dictionary = QUALITY_MULTIPLIERS.get(quality, {})
	
	_parts_inventory.append({
		"part_type": part_type,
		"quality": quality,
		"durability": def.get("max_durability", 500) * quality_mult.get("durability", 1.0),
		"display_name": def.get("display_name", "Unknown Part"),
	})


func get_parts_inventory() -> Array:
	return _parts_inventory.duplicate()


func use_part_from_inventory(index: int) -> Dictionary:
	if index < 0 or index >= _parts_inventory.size():
		return {"success": false, "error": "Invalid index"}
	
	var part: Dictionary = _parts_inventory[index]
	_parts_inventory.remove_at(index)
	
	return {"success": true, "part": part}


func find_part_in_inventory(part_type: int, min_quality: int = PartQuality.JUNK) -> int:
	for i in range(_parts_inventory.size()):
		var part: Dictionary = _parts_inventory[i]
		if part["part_type"] == part_type and part["quality"] >= min_quality:
			return i
	return -1


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var stations_save: Dictionary = {}
	for sid in _gas_stations:
		var station: Dictionary = _gas_stations[sid].duplicate(true)
		station["position"] = {"x": station["position"].x, "y": station["position"].y}
		stations_save[sid] = station
	
	return {
		"vehicle_parts": _vehicle_parts.duplicate(true),
		"vehicle_fuel_types": _vehicle_fuel_types.duplicate(),
		"gas_stations": stations_save,
		"discovered_stations": _discovered_stations.duplicate(),
		"fuel_inventory": _fuel_inventory.duplicate(),
		"parts_inventory": _parts_inventory.duplicate(true),
	}


func load_data(data: Dictionary) -> void:
	_vehicle_parts = data.get("vehicle_parts", {})
	_vehicle_fuel_types = data.get("vehicle_fuel_types", {})
	
	_gas_stations.clear()
	for sid in data.get("gas_stations", {}):
		var station: Dictionary = data["gas_stations"][sid]
		if station.has("position") and station["position"] is Dictionary:
			station["position"] = Vector2(station["position"]["x"], station["position"]["y"])
		_gas_stations[sid] = station
	
	_discovered_stations = data.get("discovered_stations", [])
	_fuel_inventory = data.get("fuel_inventory", {})
	_parts_inventory = data.get("parts_inventory", [])
