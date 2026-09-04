extends Node
class_name WorldTravelSystemClass
## Manages world map travel, locations, routes, and travel encounters
## Handles region discovery, travel time, fuel costs, and random events

signal travel_started(from_location: String, to_location: String)
signal travel_progress(percent: float, time_remaining: float)
signal travel_encounter(encounter_data: Dictionary)
signal travel_completed(location_id: String)
signal travel_cancelled(reason: String)
signal location_discovered(location_id: String)
signal region_unlocked(region_id: String)
signal route_discovered(from_id: String, to_id: String)

# ============================================================================
# WORLD CONFIGURATION
# ============================================================================

enum RegionType {
	SAFE_ZONE,
	GREEN_ZONE,
	YELLOW_ZONE,
	RED_ZONE,
	BLACK_ZONE,
	SPECIAL_ZONE,
}

enum LocationType {
	# Safe Areas
	HOME_BASE,
	SAFE_HOUSE,
	BUNKER,
	SETTLEMENT,
	
	# Resource Locations
	GAS_STATION,
	WAREHOUSE,
	FARM,
	WATER_SOURCE,
	POWER_PLANT,
	
	# Danger Zones
	CITY_RUINS,
	MILITARY_BASE,
	HOSPITAL,
	POLICE_STATION,
	FACTORY,
	SHOPPING_MALL,
	AIRPORT,
	PORT,
	
	# Special
	LABORATORY,
	QUARANTINE_ZONE,
	RADIATION_ZONE,
	BOSS_ARENA,
	DUNGEON_ENTRANCE,
	TRADER_OUTPOST,
}

enum TravelMethod {
	ON_FOOT,
	BICYCLE,
	MOTORCYCLE,
	CAR,
	TRUCK,
	HELICOPTER,
	BOAT,
}

enum EncounterType {
	NONE,
	ZOMBIE_AMBUSH,
	BANDIT_ATTACK,
	VEHICLE_BREAKDOWN,
	FUEL_SHORTAGE,
	SURVIVOR_HELP,
	TRADER_MEETING,
	WILDLIFE,
	WEATHER_EVENT,
	ROAD_BLOCK,
	MILITARY_CHECKPOINT,
	TREASURE_FOUND,
}

const REGION_DEFINITIONS := {
	"home_region": {
		"display_name": "Home Region",
		"type": RegionType.SAFE_ZONE,
		"danger_level": 0,
		"unlocked": true,
		"position": Vector2(0, 0),
		"size": Vector2(2000, 2000),
	},
	"forest_region": {
		"display_name": "Dark Forest",
		"type": RegionType.GREEN_ZONE,
		"danger_level": 1,
		"unlocked": true,
		"position": Vector2(2000, 0),
		"size": Vector2(3000, 2500),
		"terrain": "forest",
		"special_resources": ["wood", "herbs", "wildlife"],
	},
	"farm_region": {
		"display_name": "Abandoned Farmlands",
		"type": RegionType.GREEN_ZONE,
		"danger_level": 1,
		"unlocked": true,
		"position": Vector2(0, 2000),
		"size": Vector2(2500, 2000),
		"terrain": "farmland",
		"special_resources": ["food", "seeds", "fuel"],
	},
	"suburbs": {
		"display_name": "Suburban Ruins",
		"type": RegionType.YELLOW_ZONE,
		"danger_level": 2,
		"unlocked": false,
		"unlock_requirements": {"level": 5},
		"position": Vector2(5000, 0),
		"size": Vector2(3000, 3000),
		"terrain": "urban",
		"special_resources": ["supplies", "electronics", "weapons"],
	},
	"industrial": {
		"display_name": "Industrial District",
		"type": RegionType.YELLOW_ZONE,
		"danger_level": 3,
		"unlocked": false,
		"unlock_requirements": {"level": 10},
		"position": Vector2(2500, 2500),
		"size": Vector2(3500, 3000),
		"terrain": "industrial",
		"special_resources": ["metal", "fuel", "machinery"],
	},
	"city_center": {
		"display_name": "City Center",
		"type": RegionType.RED_ZONE,
		"danger_level": 4,
		"unlocked": false,
		"unlock_requirements": {"level": 20, "quest": "explore_city"},
		"position": Vector2(8000, 0),
		"size": Vector2(4000, 4000),
		"terrain": "urban_dense",
		"special_resources": ["rare_loot", "military_gear", "blueprints"],
	},
	"military_zone": {
		"display_name": "Military Exclusion Zone",
		"type": RegionType.RED_ZONE,
		"danger_level": 5,
		"unlocked": false,
		"unlock_requirements": {"level": 30, "reputation": 100},
		"position": Vector2(6000, 4000),
		"size": Vector2(3000, 3000),
		"terrain": "military",
		"radiation": true,
		"special_resources": ["military_parts", "advanced_weapons", "vehicles"],
	},
	"quarantine": {
		"display_name": "Quarantine Zone",
		"type": RegionType.BLACK_ZONE,
		"danger_level": 6,
		"unlocked": false,
		"unlock_requirements": {"level": 40, "hazmat_gear": true},
		"position": Vector2(9000, 4000),
		"size": Vector2(2500, 2500),
		"terrain": "hazard",
		"radiation": true,
		"toxic": true,
		"special_resources": ["mutant_samples", "experimental_tech", "rare_blueprints"],
	},
	"coastal": {
		"display_name": "Coastal Region",
		"type": RegionType.YELLOW_ZONE,
		"danger_level": 2,
		"unlocked": false,
		"unlock_requirements": {"level": 8, "has_boat": true},
		"position": Vector2(0, 4000),
		"size": Vector2(4000, 2000),
		"terrain": "coastal",
		"water_access": true,
		"special_resources": ["fish", "salt", "ship_parts"],
	},
}


const LOCATION_DEFINITIONS := {
	# Home Base
	"home_base": {
		"display_name": "Home Base",
		"type": LocationType.HOME_BASE,
		"region": "home_region",
		"position": Vector2(500, 500),
		"discovered": true,
		"safe": true,
		"has_storage": true,
		"has_crafting": true,
	},
	
	# Gas Stations
	"gas_station_1": {
		"display_name": "Highway Gas Station",
		"type": LocationType.GAS_STATION,
		"region": "home_region",
		"position": Vector2(1500, 800),
		"discovered": false,
		"fuel_types": ["gasoline", "diesel"],
		"has_shop": true,
		"danger_level": 1,
	},
	"gas_station_2": {
		"display_name": "Abandoned Gas Station",
		"type": LocationType.GAS_STATION,
		"region": "suburbs",
		"position": Vector2(5500, 1000),
		"discovered": false,
		"fuel_types": ["gasoline"],
		"danger_level": 2,
	},
	
	# Farms
	"farm_main": {
		"display_name": "Old MacDonald's Farm",
		"type": LocationType.FARM,
		"region": "farm_region",
		"position": Vector2(1000, 3000),
		"discovered": false,
		"resources": ["food", "seeds", "animals"],
		"danger_level": 1,
		"clearable": true,
	},
	
	# Warehouses
	"warehouse_1": {
		"display_name": "Distribution Warehouse",
		"type": LocationType.WAREHOUSE,
		"region": "industrial",
		"position": Vector2(3000, 3500),
		"discovered": false,
		"loot_quality": "medium",
		"danger_level": 3,
		"zombie_count": 15,
	},
	
	# Military
	"military_base_1": {
		"display_name": "Fort Sentinel",
		"type": LocationType.MILITARY_BASE,
		"region": "military_zone",
		"position": Vector2(7000, 5000),
		"discovered": false,
		"loot_quality": "high",
		"danger_level": 5,
		"zombie_count": 40,
		"has_vehicles": true,
		"clearable": true,
	},
	
	# Cities
	"city_hospital": {
		"display_name": "Memorial Hospital",
		"type": LocationType.HOSPITAL,
		"region": "city_center",
		"position": Vector2(9000, 2000),
		"discovered": false,
		"resources": ["medical", "chemicals"],
		"danger_level": 4,
		"zombie_count": 30,
		"has_dungeon": true,
	},
	"city_mall": {
		"display_name": "Mega Mall",
		"type": LocationType.SHOPPING_MALL,
		"region": "city_center",
		"position": Vector2(8500, 1500),
		"discovered": false,
		"loot_quality": "varied",
		"danger_level": 4,
		"zombie_count": 50,
		"multi_floor": true,
	},
	
	# Special
	"laboratory": {
		"display_name": "Prometheus Labs",
		"type": LocationType.LABORATORY,
		"region": "quarantine",
		"position": Vector2(10000, 5000),
		"discovered": false,
		"loot_quality": "rare",
		"danger_level": 6,
		"has_boss": true,
		"radiation": true,
	},
	"trader_outpost": {
		"display_name": "Trader's Haven",
		"type": LocationType.TRADER_OUTPOST,
		"region": "suburbs",
		"position": Vector2(6000, 2500),
		"discovered": false,
		"safe": true,
		"has_trader": true,
		"special_deals": true,
	},
}


const TRAVEL_SPEEDS := {
	TravelMethod.ON_FOOT: 50.0,
	TravelMethod.BICYCLE: 100.0,
	TravelMethod.MOTORCYCLE: 200.0,
	TravelMethod.CAR: 250.0,
	TravelMethod.TRUCK: 180.0,
	TravelMethod.HELICOPTER: 400.0,
	TravelMethod.BOAT: 120.0,
}


const ENCOUNTER_DEFINITIONS := {
	EncounterType.ZOMBIE_AMBUSH: {
		"display_name": "Zombie Ambush",
		"description": "Zombies attack your vehicle!",
		"base_chance": 0.15,
		"danger_mult": 1.5,
		"can_flee": true,
		"flee_chance": 0.7,
		"combat_required": true,
		"rewards": {"xp": 50, "loot": "zombie_drops"},
	},
	EncounterType.BANDIT_ATTACK: {
		"display_name": "Bandit Ambush",
		"description": "Bandits try to stop you!",
		"base_chance": 0.08,
		"danger_mult": 1.0,
		"can_flee": true,
		"flee_chance": 0.5,
		"can_negotiate": true,
		"combat_required": false,
		"rewards": {"xp": 75, "loot": "bandit_drops"},
	},
	EncounterType.VEHICLE_BREAKDOWN: {
		"display_name": "Vehicle Breakdown",
		"description": "Your vehicle has broken down!",
		"base_chance": 0.1,
		"requires_vehicle": true,
		"repair_required": true,
	},
	EncounterType.FUEL_SHORTAGE: {
		"display_name": "Low Fuel",
		"description": "You're running low on fuel!",
		"base_chance": 0.05,
		"requires_vehicle": true,
		"fuel_required": true,
	},
	EncounterType.SURVIVOR_HELP: {
		"display_name": "Survivor in Need",
		"description": "A survivor needs your help!",
		"base_chance": 0.06,
		"optional": true,
		"rewards": {"reputation": 10, "possible_recruit": true},
	},
	EncounterType.TRADER_MEETING: {
		"display_name": "Wandering Trader",
		"description": "You encounter a traveling merchant.",
		"base_chance": 0.04,
		"optional": true,
		"has_trade": true,
	},
	EncounterType.TREASURE_FOUND: {
		"display_name": "Hidden Cache",
		"description": "You spot something valuable!",
		"base_chance": 0.03,
		"optional": true,
		"rewards": {"loot": "treasure_cache"},
	},
	EncounterType.ROAD_BLOCK: {
		"display_name": "Road Blocked",
		"description": "The road ahead is blocked.",
		"base_chance": 0.1,
		"requires_vehicle": true,
		"detour_required": true,
		"time_penalty": 0.2,
	},
	EncounterType.WEATHER_EVENT: {
		"display_name": "Bad Weather",
		"description": "Weather conditions worsen.",
		"base_chance": 0.08,
		"speed_reduction": 0.5,
		"duration": 60.0,
	},
}


# ============================================================================
# STATE
# ============================================================================

var _regions: Dictionary = {}
var _locations: Dictionary = {}
var _discovered_locations: Array = []
var _discovered_routes: Dictionary = {}  # "from_to" -> route data
var _current_location: String = "home_base"
var _is_traveling: bool = false
var _travel_data: Dictionary = {}
var _travel_timer: float = 0.0


func _ready() -> void:
	_initialize_world()


func _initialize_world() -> void:
	# Copy definitions to state
	for region_id in REGION_DEFINITIONS:
		_regions[region_id] = REGION_DEFINITIONS[region_id].duplicate(true)
	
	for location_id in LOCATION_DEFINITIONS:
		_locations[location_id] = LOCATION_DEFINITIONS[location_id].duplicate(true)
		if _locations[location_id].get("discovered", false):
			_discovered_locations.append(location_id)


func _process(delta: float) -> void:
	if _is_traveling:
		_update_travel(delta)


# ============================================================================
# TRAVEL
# ============================================================================

func start_travel(to_location: String, travel_method: int = TravelMethod.ON_FOOT) -> Dictionary:
	if _is_traveling:
		return {"success": false, "error": "Already traveling"}
	
	if to_location not in _locations:
		return {"success": false, "error": "Unknown location"}
	
	if to_location not in _discovered_locations:
		return {"success": false, "error": "Location not discovered"}
	
	var from_loc: Dictionary = _locations.get(_current_location, {})
	var to_loc: Dictionary = _locations.get(to_location, {})
	
	# Check region access
	var to_region: String = to_loc.get("region", "")
	if to_region != "" and to_region in _regions:
		var region: Dictionary = _regions[to_region]
		if not region.get("unlocked", false):
			return {"success": false, "error": "Region is locked"}
	
	# Calculate travel time
	var from_pos: Vector2 = from_loc.get("position", Vector2.ZERO)
	var to_pos: Vector2 = to_loc.get("position", Vector2.ZERO)
	var distance: float = from_pos.distance_to(to_pos)
	var speed: float = TRAVEL_SPEEDS.get(travel_method, 50.0)
	var travel_time: float = distance / speed
	
	# Calculate fuel cost if using vehicle
	var fuel_cost: float = 0.0
	if travel_method != TravelMethod.ON_FOOT:
		fuel_cost = distance * 0.01  # 1 fuel per 100 distance
	
	_travel_data = {
		"from": _current_location,
		"to": to_location,
		"method": travel_method,
		"distance": distance,
		"total_time": travel_time,
		"elapsed_time": 0.0,
		"fuel_cost": fuel_cost,
		"encounters_checked": [],
		"speed_modifier": 1.0,
	}
	
	_is_traveling = true
	_travel_timer = 0.0
	
	emit_signal("travel_started", _current_location, to_location)
	
	# Discover route
	var route_key := "%s_%s" % [_current_location, to_location]
	if route_key not in _discovered_routes:
		_discovered_routes[route_key] = {
			"from": _current_location,
			"to": to_location,
			"distance": distance,
		}
		emit_signal("route_discovered", _current_location, to_location)
	
	return {"success": true, "travel_time": travel_time, "fuel_cost": fuel_cost}


func _update_travel(delta: float) -> void:
	_travel_timer += delta
	_travel_data["elapsed_time"] = _travel_timer
	
	var total_time: float = _travel_data.get("total_time", 60.0)
	var speed_mod: float = _travel_data.get("speed_modifier", 1.0)
	var effective_time: float = total_time / speed_mod
	
	var progress: float = _travel_timer / effective_time
	var time_remaining: float = maxf(effective_time - _travel_timer, 0.0)
	
	emit_signal("travel_progress", progress, time_remaining)
	
	# Check for encounters at intervals
	var check_interval: float = effective_time / 5.0
	var checks_done: int = _travel_data.get("encounters_checked", []).size()
	
	if _travel_timer >= check_interval * (checks_done + 1) and checks_done < 4:
		_check_travel_encounter()
	
	# Check completion
	if _travel_timer >= effective_time:
		_complete_travel()


func _check_travel_encounter() -> void:
	var to_loc: Dictionary = _locations.get(_travel_data.get("to", ""), {})
	var danger_level: int = to_loc.get("danger_level", 1)
	var method: int = _travel_data.get("method", TravelMethod.ON_FOOT)
	
	for encounter_type in EncounterType.values():
		if encounter_type == EncounterType.NONE:
			continue
		
		var def: Dictionary = ENCOUNTER_DEFINITIONS.get(encounter_type, {})
		if def.is_empty():
			continue
		
		# Skip vehicle-only encounters if on foot
		if def.get("requires_vehicle", false) and method == TravelMethod.ON_FOOT:
			continue
		
		var base_chance: float = def.get("base_chance", 0.1)
		var danger_mult: float = def.get("danger_mult", 1.0)
		var final_chance: float = base_chance * (1.0 + danger_level * 0.2 * danger_mult)
		
		if randf() < final_chance:
			_trigger_encounter(encounter_type)
			break
	
	_travel_data["encounters_checked"].append(Time.get_unix_time_from_system())


func _trigger_encounter(encounter_type: int) -> void:
	var def: Dictionary = ENCOUNTER_DEFINITIONS.get(encounter_type, {})
	
	var encounter_data := {
		"type": encounter_type,
		"type_name": EncounterType.keys()[encounter_type],
		"display_name": def.get("display_name", "Encounter"),
		"description": def.get("description", ""),
		"can_flee": def.get("can_flee", false),
		"can_negotiate": def.get("can_negotiate", false),
		"optional": def.get("optional", false),
		"combat_required": def.get("combat_required", false),
		"rewards": def.get("rewards", {}),
	}
	
	# Handle encounter effects
	match encounter_type:
		EncounterType.WEATHER_EVENT:
			var reduction: float = def.get("speed_reduction", 0.5)
			_travel_data["speed_modifier"] *= reduction
		EncounterType.ROAD_BLOCK:
			var penalty: float = def.get("time_penalty", 0.2)
			_travel_data["total_time"] *= (1.0 + penalty)
		EncounterType.VEHICLE_BREAKDOWN:
			_is_traveling = false  # Pause travel
		EncounterType.FUEL_SHORTAGE:
			_is_traveling = false
	
	emit_signal("travel_encounter", encounter_data)


func resolve_encounter(action: String) -> Dictionary:
	# Resume travel if it was paused
	if not _is_traveling and not _travel_data.is_empty():
		_is_traveling = true
	
	match action:
		"flee":
			# Fleeing adds time penalty
			_travel_data["total_time"] *= 1.1
			return {"success": true, "message": "You fled the encounter"}
		"fight":
			return {"success": true, "message": "Combat initiated", "start_combat": true}
		"negotiate":
			if randf() < 0.5:
				return {"success": true, "message": "Negotiation successful"}
			else:
				return {"success": false, "message": "Negotiation failed", "start_combat": true}
		"repair":
			return {"success": true, "message": "Vehicle repaired", "requires_parts": true}
		"refuel":
			return {"success": true, "message": "Refueling required", "requires_fuel": true}
		"help":
			return {"success": true, "message": "You helped the survivor", "reputation": 10}
		"ignore":
			return {"success": true, "message": "You continued on your way"}
		_:
			return {"success": false, "error": "Unknown action"}


func _complete_travel() -> void:
	var to_location: String = _travel_data.get("to", "")
	
	_current_location = to_location
	_is_traveling = false
	_travel_data.clear()
	_travel_timer = 0.0
	
	emit_signal("travel_completed", to_location)


func cancel_travel() -> bool:
	if not _is_traveling:
		return false
	
	_is_traveling = false
	_travel_data.clear()
	_travel_timer = 0.0
	
	emit_signal("travel_cancelled", "User cancelled")
	return true


# ============================================================================
# DISCOVERY
# ============================================================================

func discover_location(location_id: String) -> bool:
	if location_id not in _locations:
		return false
	
	if location_id in _discovered_locations:
		return false
	
	_discovered_locations.append(location_id)
	emit_signal("location_discovered", location_id)
	return true


func unlock_region(region_id: String) -> bool:
	if region_id not in _regions:
		return false
	
	var region: Dictionary = _regions[region_id]
	if region.get("unlocked", false):
		return false
	
	region["unlocked"] = true
	emit_signal("region_unlocked", region_id)
	
	# Discover initial location in region
	for loc_id in _locations:
		var loc: Dictionary = _locations[loc_id]
		if loc.get("region") == region_id:
			discover_location(loc_id)
			break
	
	return true


func can_unlock_region(region_id: String) -> Dictionary:
	if region_id not in _regions:
		return {"can_unlock": false, "error": "Region not found"}
	
	var region: Dictionary = _regions[region_id]
	if region.get("unlocked", false):
		return {"can_unlock": false, "error": "Already unlocked"}
	
	var requirements: Dictionary = region.get("unlock_requirements", {})
	var missing: Array = []
	
	# Check level
	if requirements.has("level"):
		# Would check player level here
		pass
	
	# Check reputation
	if requirements.has("reputation"):
		# Would check player reputation here
		pass
	
	# Check special requirements
	if requirements.has("hazmat_gear"):
		# Would check inventory here
		pass
	
	if requirements.has("has_boat"):
		# Would check vehicle ownership here
		pass
	
	if not missing.is_empty():
		return {"can_unlock": false, "missing": missing}
	
	return {"can_unlock": true}


# ============================================================================
# QUERIES
# ============================================================================

func get_current_location() -> Dictionary:
	return _locations.get(_current_location, {})


func get_current_location_id() -> String:
	return _current_location


func get_location(location_id: String) -> Dictionary:
	return _locations.get(location_id, {})


func get_discovered_locations() -> Array:
	var locations: Array = []
	for loc_id in _discovered_locations:
		if loc_id in _locations:
			var loc: Dictionary = _locations[loc_id].duplicate()
			loc["id"] = loc_id
			locations.append(loc)
	return locations


func get_locations_in_region(region_id: String) -> Array:
	var locations: Array = []
	for loc_id in _locations:
		var loc: Dictionary = _locations[loc_id]
		if loc.get("region") == region_id and loc_id in _discovered_locations:
			var loc_copy: Dictionary = loc.duplicate()
			loc_copy["id"] = loc_id
			locations.append(loc_copy)
	return locations


func get_region(region_id: String) -> Dictionary:
	return _regions.get(region_id, {})


func get_all_regions() -> Array:
	var regions: Array = []
	for region_id in _regions:
		var region: Dictionary = _regions[region_id].duplicate()
		region["id"] = region_id
		regions.append(region)
	return regions


func get_unlocked_regions() -> Array:
	var regions: Array = []
	for region_id in _regions:
		if _regions[region_id].get("unlocked", false):
			var region: Dictionary = _regions[region_id].duplicate()
			region["id"] = region_id
			regions.append(region)
	return regions


func is_traveling() -> bool:
	return _is_traveling


func get_travel_progress() -> Dictionary:
	if not _is_traveling:
		return {}
	
	var total: float = _travel_data.get("total_time", 1.0)
	var elapsed: float = _travel_data.get("elapsed_time", 0.0)
	
	return {
		"from": _travel_data.get("from", ""),
		"to": _travel_data.get("to", ""),
		"progress": elapsed / total,
		"elapsed": elapsed,
		"remaining": maxf(total - elapsed, 0.0),
		"method": _travel_data.get("method", TravelMethod.ON_FOOT),
	}


func get_travel_time(from_id: String, to_id: String, method: int = TravelMethod.ON_FOOT) -> float:
	var from_loc: Dictionary = _locations.get(from_id, {})
	var to_loc: Dictionary = _locations.get(to_id, {})
	
	if from_loc.is_empty() or to_loc.is_empty():
		return -1.0
	
	var distance: float = from_loc.get("position", Vector2.ZERO).distance_to(to_loc.get("position", Vector2.ZERO))
	var speed: float = TRAVEL_SPEEDS.get(method, 50.0)
	
	return distance / speed


func get_distance_to(location_id: String) -> float:
	var current: Dictionary = _locations.get(_current_location, {})
	var target: Dictionary = _locations.get(location_id, {})
	
	if current.is_empty() or target.is_empty():
		return -1.0
	
	return current.get("position", Vector2.ZERO).distance_to(target.get("position", Vector2.ZERO))


func get_nearest_location(location_type: int = -1, discovered_only: bool = true) -> Dictionary:
	var current_pos: Vector2 = _locations.get(_current_location, {}).get("position", Vector2.ZERO)
	var nearest: Dictionary = {}
	var min_dist: float = INF
	
	for loc_id in _locations:
		if discovered_only and loc_id not in _discovered_locations:
			continue
		
		var loc: Dictionary = _locations[loc_id]
		
		if location_type >= 0 and loc.get("type", -1) != location_type:
			continue
		
		var dist: float = current_pos.distance_to(loc.get("position", Vector2.ZERO))
		if dist < min_dist and dist > 0:
			min_dist = dist
			nearest = loc.duplicate()
			nearest["id"] = loc_id
			nearest["distance"] = dist
	
	return nearest


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var regions_save: Dictionary = {}
	for rid in _regions:
		var region: Dictionary = _regions[rid].duplicate(true)
		if region.has("position"):
			region["position"] = {"x": region["position"].x, "y": region["position"].y}
		if region.has("size"):
			region["size"] = {"x": region["size"].x, "y": region["size"].y}
		regions_save[rid] = region
	
	var locations_save: Dictionary = {}
	for lid in _locations:
		var loc: Dictionary = _locations[lid].duplicate(true)
		if loc.has("position"):
			loc["position"] = {"x": loc["position"].x, "y": loc["position"].y}
		locations_save[lid] = loc
	
	return {
		"regions": regions_save,
		"locations": locations_save,
		"discovered_locations": _discovered_locations.duplicate(),
		"discovered_routes": _discovered_routes.duplicate(true),
		"current_location": _current_location,
	}


func load_data(data: Dictionary) -> void:
	_regions.clear()
	for rid in data.get("regions", {}):
		var region: Dictionary = data["regions"][rid]
		if region.has("position") and region["position"] is Dictionary:
			region["position"] = Vector2(region["position"]["x"], region["position"]["y"])
		if region.has("size") and region["size"] is Dictionary:
			region["size"] = Vector2(region["size"]["x"], region["size"]["y"])
		_regions[rid] = region
	
	_locations.clear()
	for lid in data.get("locations", {}):
		var loc: Dictionary = data["locations"][lid]
		if loc.has("position") and loc["position"] is Dictionary:
			loc["position"] = Vector2(loc["position"]["x"], loc["position"]["y"])
		_locations[lid] = loc
	
	_discovered_locations = data.get("discovered_locations", [])
	_discovered_routes = data.get("discovered_routes", {})
	_current_location = data.get("current_location", "home_base")
