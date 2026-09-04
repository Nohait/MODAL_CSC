extends Node
class_name FastTravelSystemClass
## Manages fast travel points, unlocking, costs, and restrictions
## Handles waypoints, safe houses, and instant travel mechanics

signal fast_travel_point_discovered(point_id: String)
signal fast_travel_point_unlocked(point_id: String)
signal fast_travel_started(from_id: String, to_id: String)
signal fast_travel_completed(point_id: String)
signal fast_travel_failed(reason: String)
signal safe_house_claimed(safe_house_id: String)
signal waypoint_placed(waypoint_id: String, position: Vector2)
signal waypoint_removed(waypoint_id: String)

# ============================================================================
# FAST TRAVEL CONFIGURATION
# ============================================================================

enum FastTravelType {
	SAFE_HOUSE,
	WAYPOINT,
	LANDMARK,
	SETTLEMENT,
	TRADER_POST,
	BUNKER_ENTRANCE,
}

enum UnlockMethod {
	DISCOVER,
	CLEAR,
	PURCHASE,
	QUEST,
	CRAFT,
}

const FAST_TRAVEL_DEFINITIONS := {
	# Safe Houses
	"home_base": {
		"display_name": "Home Base",
		"type": FastTravelType.SAFE_HOUSE,
		"position": Vector2(500, 500),
		"region": "home_region",
		"unlocked": true,
		"can_spawn": true,
		"has_storage": true,
		"has_crafting": true,
		"icon": "icon_home",
	},
	"safe_house_forest": {
		"display_name": "Forest Hideout",
		"type": FastTravelType.SAFE_HOUSE,
		"position": Vector2(3000, 1500),
		"region": "forest_region",
		"unlocked": false,
		"unlock_method": UnlockMethod.CLEAR,
		"unlock_requirements": {"zombie_kills": 10},
		"can_spawn": true,
		"has_storage": true,
		"icon": "icon_safehouse",
	},
	"safe_house_farm": {
		"display_name": "Farmhouse Shelter",
		"type": FastTravelType.SAFE_HOUSE,
		"position": Vector2(1200, 3200),
		"region": "farm_region",
		"unlocked": false,
		"unlock_method": UnlockMethod.CLEAR,
		"unlock_requirements": {"zombie_kills": 15},
		"can_spawn": true,
		"has_storage": true,
		"icon": "icon_safehouse",
	},
	"safe_house_suburbs": {
		"display_name": "Suburban Bunker",
		"type": FastTravelType.SAFE_HOUSE,
		"position": Vector2(5800, 1800),
		"region": "suburbs",
		"unlocked": false,
		"unlock_method": UnlockMethod.PURCHASE,
		"unlock_cost": {"coins": 500, "materials": 50},
		"can_spawn": true,
		"has_storage": true,
		"has_crafting": true,
		"icon": "icon_bunker",
	},
	
	# Landmarks
	"landmark_tower": {
		"display_name": "Radio Tower",
		"type": FastTravelType.LANDMARK,
		"position": Vector2(4000, 500),
		"region": "suburbs",
		"unlocked": false,
		"unlock_method": UnlockMethod.DISCOVER,
		"reveals_map": true,
		"reveal_radius": 2000,
		"icon": "icon_tower",
	},
	"landmark_bridge": {
		"display_name": "Collapsed Bridge",
		"type": FastTravelType.LANDMARK,
		"position": Vector2(2500, 2000),
		"region": "industrial",
		"unlocked": false,
		"unlock_method": UnlockMethod.DISCOVER,
		"icon": "icon_landmark",
	},
	"landmark_monument": {
		"display_name": "War Memorial",
		"type": FastTravelType.LANDMARK,
		"position": Vector2(8000, 2500),
		"region": "city_center",
		"unlocked": false,
		"unlock_method": UnlockMethod.DISCOVER,
		"icon": "icon_landmark",
	},
	
	# Settlements
	"settlement_traders": {
		"display_name": "Trader's Haven",
		"type": FastTravelType.SETTLEMENT,
		"position": Vector2(6000, 2500),
		"region": "suburbs",
		"unlocked": false,
		"unlock_method": UnlockMethod.QUEST,
		"unlock_quest": "find_traders_haven",
		"has_traders": true,
		"protected": true,
		"icon": "icon_settlement",
	},
	"settlement_survivors": {
		"display_name": "Survivor Camp",
		"type": FastTravelType.SETTLEMENT,
		"position": Vector2(3500, 4000),
		"region": "industrial",
		"unlocked": false,
		"unlock_method": UnlockMethod.QUEST,
		"unlock_quest": "help_survivors",
		"has_traders": true,
		"has_quests": true,
		"icon": "icon_camp",
	},
	
	# Trader Posts
	"trader_post_highway": {
		"display_name": "Highway Trading Post",
		"type": FastTravelType.TRADER_POST,
		"position": Vector2(1800, 1200),
		"region": "home_region",
		"unlocked": false,
		"unlock_method": UnlockMethod.DISCOVER,
		"has_traders": true,
		"special_inventory": "highway_goods",
		"icon": "icon_trader",
	},
	
	# Bunker Entrances
	"bunker_alpha": {
		"display_name": "Bunker Alpha Entrance",
		"type": FastTravelType.BUNKER_ENTRANCE,
		"position": Vector2(4500, 3000),
		"region": "industrial",
		"unlocked": false,
		"unlock_method": UnlockMethod.CLEAR,
		"unlock_requirements": {"level": 10},
		"dungeon_id": "bunker_alpha",
		"danger_level": 3,
		"icon": "icon_bunker",
	},
	"bunker_bravo": {
		"display_name": "Bunker Bravo Entrance",
		"type": FastTravelType.BUNKER_ENTRANCE,
		"position": Vector2(7500, 5500),
		"region": "military_zone",
		"unlocked": false,
		"unlock_method": UnlockMethod.CLEAR,
		"unlock_requirements": {"level": 25, "keycard": "military"},
		"dungeon_id": "bunker_bravo",
		"danger_level": 5,
		"icon": "icon_bunker",
	},
}


const TRAVEL_COSTS := {
	FastTravelType.SAFE_HOUSE: {"fuel": 0, "coins": 0},  # Free to safe houses
	FastTravelType.WAYPOINT: {"fuel": 5, "coins": 0},
	FastTravelType.LANDMARK: {"fuel": 10, "coins": 0},
	FastTravelType.SETTLEMENT: {"fuel": 5, "coins": 10},
	FastTravelType.TRADER_POST: {"fuel": 5, "coins": 5},
	FastTravelType.BUNKER_ENTRANCE: {"fuel": 15, "coins": 0},
}


const TRAVEL_RESTRICTIONS := {
	"combat_cooldown": 30.0,  # Seconds after combat before fast travel
	"max_waypoints": 5,
	"waypoint_craft_cost": {"electronics": 2, "metal_scrap": 5},
	"safe_house_claim_cost": {"wood": 50, "metal_scrap": 30, "nails": 20},
}


# ============================================================================
# STATE
# ============================================================================

var _fast_travel_points: Dictionary = {}  # point_id -> point data
var _player_waypoints: Dictionary = {}  # waypoint_id -> waypoint data
var _claimed_safe_houses: Array = []
var _last_combat_time: float = 0.0
var _current_time: float = 0.0
var _spawn_point: String = "home_base"


func _ready() -> void:
	_initialize_points()


func _initialize_points() -> void:
	for point_id in FAST_TRAVEL_DEFINITIONS:
		_fast_travel_points[point_id] = FAST_TRAVEL_DEFINITIONS[point_id].duplicate(true)


func _process(delta: float) -> void:
	_current_time += delta


# ============================================================================
# FAST TRAVEL
# ============================================================================

func fast_travel_to(point_id: String) -> Dictionary:
	# Check if point exists
	var point: Dictionary = _fast_travel_points.get(point_id, {})
	if point.is_empty():
		# Check player waypoints
		point = _player_waypoints.get(point_id, {})
	
	if point.is_empty():
		emit_signal("fast_travel_failed", "Unknown destination")
		return {"success": false, "error": "Unknown destination"}
	
	# Check if unlocked
	if not point.get("unlocked", false):
		emit_signal("fast_travel_failed", "Destination not unlocked")
		return {"success": false, "error": "Destination not unlocked"}
	
	# Check combat cooldown
	if _current_time - _last_combat_time < TRAVEL_RESTRICTIONS["combat_cooldown"]:
		var remaining: float = TRAVEL_RESTRICTIONS["combat_cooldown"] - (_current_time - _last_combat_time)
		emit_signal("fast_travel_failed", "In combat cooldown")
		return {"success": false, "error": "Cannot fast travel during or shortly after combat", "cooldown": remaining}
	
	# Check costs
	var travel_type: int = point.get("type", FastTravelType.LANDMARK)
	var costs: Dictionary = TRAVEL_COSTS.get(travel_type, {})
	
	# Would check player resources here
	# For now, assume player can afford it
	
	emit_signal("fast_travel_started", _spawn_point, point_id)
	
	# Teleport player
	var position: Vector2 = point.get("position", Vector2.ZERO)
	
	emit_signal("fast_travel_completed", point_id)
	
	return {
		"success": true,
		"position": position,
		"point_id": point_id,
		"costs_paid": costs,
	}


func can_fast_travel() -> Dictionary:
	# Check combat cooldown
	if _current_time - _last_combat_time < TRAVEL_RESTRICTIONS["combat_cooldown"]:
		var remaining: float = TRAVEL_RESTRICTIONS["combat_cooldown"] - (_current_time - _last_combat_time)
		return {"can_travel": false, "reason": "combat_cooldown", "cooldown": remaining}
	
	return {"can_travel": true}


func get_available_destinations() -> Array:
	var destinations: Array = []
	
	# Add unlocked fast travel points
	for point_id in _fast_travel_points:
		var point: Dictionary = _fast_travel_points[point_id]
		if point.get("unlocked", false):
			var dest: Dictionary = point.duplicate()
			dest["id"] = point_id
			dest["cost"] = TRAVEL_COSTS.get(point.get("type", FastTravelType.LANDMARK), {})
			destinations.append(dest)
	
	# Add player waypoints
	for waypoint_id in _player_waypoints:
		var waypoint: Dictionary = _player_waypoints[waypoint_id].duplicate()
		waypoint["id"] = waypoint_id
		waypoint["cost"] = TRAVEL_COSTS.get(FastTravelType.WAYPOINT, {})
		destinations.append(waypoint)
	
	return destinations


# ============================================================================
# POINT DISCOVERY & UNLOCKING
# ============================================================================

func discover_point(point_id: String) -> bool:
	if point_id not in _fast_travel_points:
		return false
	
	var point: Dictionary = _fast_travel_points[point_id]
	
	if point.get("discovered", false):
		return false
	
	point["discovered"] = true
	emit_signal("fast_travel_point_discovered", point_id)
	
	# Auto-unlock if discovery is the unlock method
	if point.get("unlock_method") == UnlockMethod.DISCOVER:
		unlock_point(point_id)
	
	# Handle map reveal
	if point.get("reveals_map", false):
		var radius: float = point.get("reveal_radius", 1000)
		_reveal_nearby_locations(point.get("position", Vector2.ZERO), radius)
	
	return true


func unlock_point(point_id: String) -> Dictionary:
	if point_id not in _fast_travel_points:
		return {"success": false, "error": "Point not found"}
	
	var point: Dictionary = _fast_travel_points[point_id]
	
	if point.get("unlocked", false):
		return {"success": false, "error": "Already unlocked"}
	
	var unlock_method: int = point.get("unlock_method", UnlockMethod.DISCOVER)
	
	# Check requirements based on method
	match unlock_method:
		UnlockMethod.CLEAR:
			var requirements: Dictionary = point.get("unlock_requirements", {})
			# Would check if requirements are met
			pass
		
		UnlockMethod.PURCHASE:
			var cost: Dictionary = point.get("unlock_cost", {})
			# Would deduct resources from player
			pass
		
		UnlockMethod.QUEST:
			var quest_id: String = point.get("unlock_quest", "")
			# Would check if quest is completed
			pass
		
		UnlockMethod.CRAFT:
			# Would check crafting materials
			pass
	
	point["unlocked"] = true
	emit_signal("fast_travel_point_unlocked", point_id)
	
	return {"success": true}


func _reveal_nearby_locations(center: Vector2, radius: float) -> void:
	for point_id in _fast_travel_points:
		var point: Dictionary = _fast_travel_points[point_id]
		var pos: Vector2 = point.get("position", Vector2.ZERO)
		
		if center.distance_to(pos) <= radius:
			discover_point(point_id)


# ============================================================================
# SAFE HOUSES
# ============================================================================

func claim_safe_house(point_id: String) -> Dictionary:
	if point_id not in _fast_travel_points:
		return {"success": false, "error": "Point not found"}
	
	var point: Dictionary = _fast_travel_points[point_id]
	
	if point.get("type") != FastTravelType.SAFE_HOUSE:
		return {"success": false, "error": "Not a safe house"}
	
	if point_id in _claimed_safe_houses:
		return {"success": false, "error": "Already claimed"}
	
	# Check claim cost
	var cost: Dictionary = TRAVEL_RESTRICTIONS.get("safe_house_claim_cost", {})
	# Would deduct resources here
	
	_claimed_safe_houses.append(point_id)
	point["claimed"] = true
	point["unlocked"] = true
	
	emit_signal("safe_house_claimed", point_id)
	emit_signal("fast_travel_point_unlocked", point_id)
	
	return {"success": true}


func set_spawn_point(point_id: String) -> Dictionary:
	if point_id not in _fast_travel_points and point_id not in _player_waypoints:
		return {"success": false, "error": "Point not found"}
	
	var point: Dictionary = _fast_travel_points.get(point_id, _player_waypoints.get(point_id, {}))
	
	if not point.get("can_spawn", false):
		return {"success": false, "error": "Cannot spawn at this location"}
	
	_spawn_point = point_id
	
	return {"success": true, "spawn_point": point_id}


func get_spawn_point() -> Dictionary:
	var point: Dictionary = _fast_travel_points.get(_spawn_point, {})
	if point.is_empty():
		point = _player_waypoints.get(_spawn_point, {})
	
	if not point.is_empty():
		point = point.duplicate()
		point["id"] = _spawn_point
	
	return point


func get_claimed_safe_houses() -> Array:
	var houses: Array = []
	for point_id in _claimed_safe_houses:
		if point_id in _fast_travel_points:
			var house: Dictionary = _fast_travel_points[point_id].duplicate()
			house["id"] = point_id
			houses.append(house)
	return houses


# ============================================================================
# PLAYER WAYPOINTS
# ============================================================================

func place_waypoint(position: Vector2, name: String = "") -> Dictionary:
	var current_count: int = _player_waypoints.size()
	var max_waypoints: int = TRAVEL_RESTRICTIONS.get("max_waypoints", 5)
	
	if current_count >= max_waypoints:
		return {"success": false, "error": "Maximum waypoints reached (%d)" % max_waypoints}
	
	# Check craft cost
	var cost: Dictionary = TRAVEL_RESTRICTIONS.get("waypoint_craft_cost", {})
	# Would deduct resources here
	
	var waypoint_id := "waypoint_%d" % (current_count + 1)
	var display_name: String = name if name != "" else "Waypoint %d" % (current_count + 1)
	
	var waypoint_data := {
		"display_name": display_name,
		"type": FastTravelType.WAYPOINT,
		"position": position,
		"unlocked": true,
		"can_spawn": false,
		"created_at": Time.get_unix_time_from_system(),
		"icon": "icon_waypoint",
	}
	
	_player_waypoints[waypoint_id] = waypoint_data
	
	emit_signal("waypoint_placed", waypoint_id, position)
	
	return {"success": true, "waypoint_id": waypoint_id}


func remove_waypoint(waypoint_id: String) -> bool:
	if waypoint_id not in _player_waypoints:
		return false
	
	_player_waypoints.erase(waypoint_id)
	
	emit_signal("waypoint_removed", waypoint_id)
	
	return true


func rename_waypoint(waypoint_id: String, new_name: String) -> bool:
	if waypoint_id not in _player_waypoints:
		return false
	
	_player_waypoints[waypoint_id]["display_name"] = new_name
	return true


func get_player_waypoints() -> Array:
	var waypoints: Array = []
	for waypoint_id in _player_waypoints:
		var waypoint: Dictionary = _player_waypoints[waypoint_id].duplicate()
		waypoint["id"] = waypoint_id
		waypoints.append(waypoint)
	return waypoints


func get_waypoint_count() -> int:
	return _player_waypoints.size()


func get_max_waypoints() -> int:
	return TRAVEL_RESTRICTIONS.get("max_waypoints", 5)


# ============================================================================
# COMBAT TRACKING
# ============================================================================

func on_combat_started() -> void:
	_last_combat_time = _current_time


func on_combat_ended() -> void:
	_last_combat_time = _current_time


func get_combat_cooldown_remaining() -> float:
	var elapsed: float = _current_time - _last_combat_time
	return maxf(TRAVEL_RESTRICTIONS["combat_cooldown"] - elapsed, 0.0)


# ============================================================================
# QUERIES
# ============================================================================

func get_point(point_id: String) -> Dictionary:
	var point: Dictionary = _fast_travel_points.get(point_id, {})
	if point.is_empty():
		point = _player_waypoints.get(point_id, {})
	
	if not point.is_empty():
		point = point.duplicate()
		point["id"] = point_id
	
	return point


func get_points_by_type(travel_type: int) -> Array:
	var points: Array = []
	
	for point_id in _fast_travel_points:
		var point: Dictionary = _fast_travel_points[point_id]
		if point.get("type") == travel_type:
			var p: Dictionary = point.duplicate()
			p["id"] = point_id
			points.append(p)
	
	if travel_type == FastTravelType.WAYPOINT:
		for waypoint_id in _player_waypoints:
			var waypoint: Dictionary = _player_waypoints[waypoint_id].duplicate()
			waypoint["id"] = waypoint_id
			points.append(waypoint)
	
	return points


func get_points_in_region(region_id: String) -> Array:
	var points: Array = []
	
	for point_id in _fast_travel_points:
		var point: Dictionary = _fast_travel_points[point_id]
		if point.get("region") == region_id:
			var p: Dictionary = point.duplicate()
			p["id"] = point_id
			points.append(p)
	
	return points


func get_nearest_safe_house(position: Vector2) -> Dictionary:
	var nearest: Dictionary = {}
	var min_dist: float = INF
	
	for point_id in _fast_travel_points:
		var point: Dictionary = _fast_travel_points[point_id]
		
		if point.get("type") != FastTravelType.SAFE_HOUSE:
			continue
		
		if not point.get("unlocked", false):
			continue
		
		var dist: float = position.distance_to(point.get("position", Vector2.ZERO))
		if dist < min_dist:
			min_dist = dist
			nearest = point.duplicate()
			nearest["id"] = point_id
			nearest["distance"] = dist
	
	return nearest


func get_unlocked_count() -> int:
	var count: int = 0
	for point_id in _fast_travel_points:
		if _fast_travel_points[point_id].get("unlocked", false):
			count += 1
	return count + _player_waypoints.size()


func get_total_point_count() -> int:
	return _fast_travel_points.size()


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var points_save: Dictionary = {}
	for pid in _fast_travel_points:
		var point: Dictionary = _fast_travel_points[pid].duplicate(true)
		if point.has("position"):
			point["position"] = {"x": point["position"].x, "y": point["position"].y}
		points_save[pid] = point
	
	var waypoints_save: Dictionary = {}
	for wid in _player_waypoints:
		var waypoint: Dictionary = _player_waypoints[wid].duplicate(true)
		if waypoint.has("position"):
			waypoint["position"] = {"x": waypoint["position"].x, "y": waypoint["position"].y}
		waypoints_save[wid] = waypoint
	
	return {
		"fast_travel_points": points_save,
		"player_waypoints": waypoints_save,
		"claimed_safe_houses": _claimed_safe_houses.duplicate(),
		"spawn_point": _spawn_point,
	}


func load_data(data: Dictionary) -> void:
	_fast_travel_points.clear()
	for pid in data.get("fast_travel_points", {}):
		var point: Dictionary = data["fast_travel_points"][pid]
		if point.has("position") and point["position"] is Dictionary:
			point["position"] = Vector2(point["position"]["x"], point["position"]["y"])
		_fast_travel_points[pid] = point
	
	_player_waypoints.clear()
	for wid in data.get("player_waypoints", {}):
		var waypoint: Dictionary = data["player_waypoints"][wid]
		if waypoint.has("position") and waypoint["position"] is Dictionary:
			waypoint["position"] = Vector2(waypoint["position"]["x"], waypoint["position"]["y"])
		_player_waypoints[wid] = waypoint
	
	_claimed_safe_houses = data.get("claimed_safe_houses", [])
	_spawn_point = data.get("spawn_point", "home_base")
