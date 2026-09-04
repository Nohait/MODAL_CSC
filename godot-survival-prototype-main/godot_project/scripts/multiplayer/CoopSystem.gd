extends Node
class_name CoopSystemClass
## Handles cooperative gameplay features - shared resources, reviving, ping system, and team mechanics
## Manages co-op specific interactions between players

signal player_downed(peer_id: int, position: Vector3)
signal player_reviving(reviver_id: int, downed_id: int, progress: float)
signal player_revived(reviver_id: int, downed_id: int)
signal player_died(peer_id: int)
signal resource_shared(from_peer: int, to_peer: int, item_id: String, quantity: int)
signal ping_placed(peer_id: int, ping_type: int, position: Vector3, data: Dictionary)
signal ping_removed(ping_id: String)
signal team_objective_updated(objective_id: String, progress: float)
signal team_objective_completed(objective_id: String)
signal proximity_bonus_activated(bonus_type: int)
signal proximity_bonus_deactivated(bonus_type: int)
signal coop_event_triggered(event_type: String, data: Dictionary)

# ============================================================================
# COOP CONFIGURATION
# ============================================================================

enum DownedState {
	ALIVE,
	DOWNED,
	DEAD,
}

enum PingType {
	GENERIC,
	ENEMY,
	LOOT,
	DANGER,
	GO_HERE,
	HELP,
	RESOURCE,
	VEHICLE,
}

enum ProximityBonus {
	DAMAGE_BOOST,
	DEFENSE_BOOST,
	HEALTH_REGEN,
	STAMINA_REGEN,
	XP_BONUS,
	LOOT_BONUS,
}

enum ShareType {
	ITEMS,
	AMMO,
	RESOURCES,
	CURRENCY,
}

const REVIVE_TIME := 5.0  # seconds to revive
const BLEEDOUT_TIME := 60.0  # seconds before downed becomes dead
const MAX_DOWNS_PER_LIFE := 3  # Maximum times can be downed before instant death
const REVIVE_HEALTH_PERCENT := 0.25  # Health restored on revive
const REVIVE_RANGE := 2.0  # meters

const PING_DURATION := 10.0  # seconds before ping expires
const MAX_PINGS_PER_PLAYER := 3
const PING_COOLDOWN := 1.0  # seconds between pings

const PROXIMITY_RANGE := 10.0  # Range for proximity bonuses
const PROXIMITY_BONUS_VALUES := {
	ProximityBonus.DAMAGE_BOOST: 0.1,  # 10% per nearby player
	ProximityBonus.DEFENSE_BOOST: 0.05,  # 5% per nearby player
	ProximityBonus.HEALTH_REGEN: 1.0,  # HP per second per nearby player
	ProximityBonus.STAMINA_REGEN: 2.0,  # Stamina per second per nearby player
	ProximityBonus.XP_BONUS: 0.15,  # 15% XP bonus per nearby player
	ProximityBonus.LOOT_BONUS: 0.1,  # 10% better loot per nearby player
}

const PING_DEFINITIONS := {
	PingType.GENERIC: {
		"name": "Ping",
		"color": Color.WHITE,
		"icon": "ping_generic",
		"sound": "ping_default",
	},
	PingType.ENEMY: {
		"name": "Enemy",
		"color": Color.RED,
		"icon": "ping_enemy",
		"sound": "ping_alert",
	},
	PingType.LOOT: {
		"name": "Loot",
		"color": Color.YELLOW,
		"icon": "ping_loot",
		"sound": "ping_loot",
	},
	PingType.DANGER: {
		"name": "Danger",
		"color": Color.ORANGE,
		"icon": "ping_danger",
		"sound": "ping_danger",
	},
	PingType.GO_HERE: {
		"name": "Go Here",
		"color": Color.BLUE,
		"icon": "ping_waypoint",
		"sound": "ping_default",
	},
	PingType.HELP: {
		"name": "Help!",
		"color": Color.MAGENTA,
		"icon": "ping_help",
		"sound": "ping_urgent",
	},
	PingType.RESOURCE: {
		"name": "Resource",
		"color": Color.GREEN,
		"icon": "ping_resource",
		"sound": "ping_default",
	},
	PingType.VEHICLE: {
		"name": "Vehicle",
		"color": Color.CYAN,
		"icon": "ping_vehicle",
		"sound": "ping_default",
	},
}


# ============================================================================
# STATE
# ============================================================================

var _player_states: Dictionary = {}  # peer_id -> {downed_state, down_count, bleedout_timer, position}
var _revive_progress: Dictionary = {}  # downed_peer_id -> {reviver_id, progress}
var _active_pings: Dictionary = {}  # ping_id -> ping data
var _player_pings: Dictionary = {}  # peer_id -> [ping_ids]
var _ping_cooldowns: Dictionary = {}  # peer_id -> cooldown timer
var _team_objectives: Dictionary = {}  # objective_id -> {progress, target, contributors}
var _active_proximity_bonuses: Dictionary = {}  # bonus_type -> active
var _shared_inventory: Dictionary = {}  # For shared loot mode
var _coop_stats: Dictionary = {}  # Statistics for end-of-session
var _ping_id_counter: int = 0


func _ready() -> void:
	_initialize_coop_stats()


func _process(delta: float) -> void:
	_update_bleedout_timers(delta)
	_update_revive_progress(delta)
	_update_pings(delta)
	_update_ping_cooldowns(delta)
	_check_proximity_bonuses()


func _initialize_coop_stats() -> void:
	_coop_stats = {
		"total_revives": 0,
		"items_shared": 0,
		"pings_placed": 0,
		"objectives_completed": 0,
		"time_near_teammates": 0.0,
	}


# ============================================================================
# PLAYER REGISTRATION
# ============================================================================

func register_player(peer_id: int) -> void:
	_player_states[peer_id] = {
		"downed_state": DownedState.ALIVE,
		"down_count": 0,
		"bleedout_timer": 0.0,
		"position": Vector3.ZERO,
		"health": 100.0,
		"max_health": 100.0,
	}
	
	_player_pings[peer_id] = []
	_ping_cooldowns[peer_id] = 0.0


func unregister_player(peer_id: int) -> void:
	_player_states.erase(peer_id)
	
	# Remove player's pings
	for ping_id in _player_pings.get(peer_id, []):
		_remove_ping(ping_id)
	_player_pings.erase(peer_id)
	_ping_cooldowns.erase(peer_id)
	
	# Cancel any revives involving this player
	_revive_progress.erase(peer_id)
	for downed_id in _revive_progress:
		if _revive_progress[downed_id].get("reviver_id") == peer_id:
			_revive_progress.erase(downed_id)


func update_player_position(peer_id: int, position: Vector3) -> void:
	if peer_id in _player_states:
		_player_states[peer_id]["position"] = position


# ============================================================================
# DOWNED / REVIVE SYSTEM
# ============================================================================

func down_player(peer_id: int, position: Vector3) -> void:
	if peer_id not in _player_states:
		return
	
	var state: Dictionary = _player_states[peer_id]
	
	# Check if instant death (too many downs)
	if state["down_count"] >= MAX_DOWNS_PER_LIFE:
		kill_player(peer_id)
		return
	
	state["downed_state"] = DownedState.DOWNED
	state["down_count"] += 1
	state["bleedout_timer"] = BLEEDOUT_TIME
	state["position"] = position
	
	if _is_host():
		_rpc_player_downed.rpc(peer_id, {"x": position.x, "y": position.y, "z": position.z})
	
	emit_signal("player_downed", peer_id, position)


func kill_player(peer_id: int) -> void:
	if peer_id not in _player_states:
		return
	
	var state: Dictionary = _player_states[peer_id]
	state["downed_state"] = DownedState.DEAD
	state["bleedout_timer"] = 0.0
	
	# Cancel any revive in progress
	_revive_progress.erase(peer_id)
	
	if _is_host():
		_rpc_player_died.rpc(peer_id)
	
	emit_signal("player_died", peer_id)


func start_revive(reviver_id: int, downed_id: int) -> Dictionary:
	if reviver_id not in _player_states or downed_id not in _player_states:
		return {"success": false, "error": "Player not found"}
	
	var reviver_state: Dictionary = _player_states[reviver_id]
	var downed_state: Dictionary = _player_states[downed_id]
	
	if reviver_state["downed_state"] != DownedState.ALIVE:
		return {"success": false, "error": "Cannot revive while downed"}
	
	if downed_state["downed_state"] != DownedState.DOWNED:
		return {"success": false, "error": "Player is not downed"}
	
	# Check range
	var distance: float = reviver_state["position"].distance_to(downed_state["position"])
	if distance > REVIVE_RANGE:
		return {"success": false, "error": "Too far away"}
	
	_revive_progress[downed_id] = {
		"reviver_id": reviver_id,
		"progress": 0.0,
	}
	
	return {"success": true}


func cancel_revive(downed_id: int) -> void:
	_revive_progress.erase(downed_id)


func _update_revive_progress(delta: float) -> void:
	var completed: Array = []
	
	for downed_id in _revive_progress:
		var revive_data: Dictionary = _revive_progress[downed_id]
		var reviver_id: int = revive_data["reviver_id"]
		
		# Check if reviver is still valid and in range
		if not _can_continue_revive(reviver_id, downed_id):
			completed.append(downed_id)
			continue
		
		revive_data["progress"] += delta / REVIVE_TIME
		
		emit_signal("player_reviving", reviver_id, downed_id, revive_data["progress"])
		
		if revive_data["progress"] >= 1.0:
			_complete_revive(reviver_id, downed_id)
			completed.append(downed_id)
	
	for downed_id in completed:
		_revive_progress.erase(downed_id)


func _can_continue_revive(reviver_id: int, downed_id: int) -> bool:
	if reviver_id not in _player_states or downed_id not in _player_states:
		return false
	
	var reviver_state: Dictionary = _player_states[reviver_id]
	var downed_state: Dictionary = _player_states[downed_id]
	
	if reviver_state["downed_state"] != DownedState.ALIVE:
		return false
	
	if downed_state["downed_state"] != DownedState.DOWNED:
		return false
	
	var distance: float = reviver_state["position"].distance_to(downed_state["position"])
	return distance <= REVIVE_RANGE


func _complete_revive(reviver_id: int, downed_id: int) -> void:
	var downed_state: Dictionary = _player_states[downed_id]
	
	downed_state["downed_state"] = DownedState.ALIVE
	downed_state["bleedout_timer"] = 0.0
	downed_state["health"] = downed_state["max_health"] * REVIVE_HEALTH_PERCENT
	
	_coop_stats["total_revives"] += 1
	
	if _is_host():
		_rpc_player_revived.rpc(reviver_id, downed_id)
	
	emit_signal("player_revived", reviver_id, downed_id)


func _update_bleedout_timers(delta: float) -> void:
	for peer_id in _player_states:
		var state: Dictionary = _player_states[peer_id]
		
		if state["downed_state"] == DownedState.DOWNED:
			state["bleedout_timer"] -= delta
			
			if state["bleedout_timer"] <= 0:
				kill_player(peer_id)


# ============================================================================
# REVIVE RPCS
# ============================================================================

@rpc("authority", "call_remote", "reliable")
func _rpc_player_downed(peer_id: int, position: Dictionary) -> void:
	if peer_id in _player_states:
		var pos := Vector3(position["x"], position["y"], position.get("z", 0.0))
		_player_states[peer_id]["downed_state"] = DownedState.DOWNED
		_player_states[peer_id]["position"] = pos
		_player_states[peer_id]["bleedout_timer"] = BLEEDOUT_TIME
		emit_signal("player_downed", peer_id, pos)


@rpc("authority", "call_remote", "reliable")
func _rpc_player_died(peer_id: int) -> void:
	if peer_id in _player_states:
		_player_states[peer_id]["downed_state"] = DownedState.DEAD
		emit_signal("player_died", peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_player_revived(reviver_id: int, downed_id: int) -> void:
	if downed_id in _player_states:
		_player_states[downed_id]["downed_state"] = DownedState.ALIVE
		emit_signal("player_revived", reviver_id, downed_id)


# ============================================================================
# PING SYSTEM
# ============================================================================

func place_ping(peer_id: int, ping_type: int, position: Vector3, extra_data: Dictionary = {}) -> Dictionary:
	if peer_id not in _player_pings:
		return {"success": false, "error": "Player not registered"}
	
	# Check cooldown
	if _ping_cooldowns.get(peer_id, 0.0) > 0:
		return {"success": false, "error": "Ping on cooldown"}
	
	# Check max pings
	if _player_pings[peer_id].size() >= MAX_PINGS_PER_PLAYER:
		# Remove oldest ping
		var oldest_id: String = _player_pings[peer_id][0]
		_remove_ping(oldest_id)
	
	_ping_id_counter += 1
	var ping_id := "ping_%d_%d" % [peer_id, _ping_id_counter]
	
	var ping_def: Dictionary = PING_DEFINITIONS.get(ping_type, PING_DEFINITIONS[PingType.GENERIC])
	
	var ping_data := {
		"id": ping_id,
		"peer_id": peer_id,
		"type": ping_type,
		"type_name": PingType.keys()[ping_type],
		"position": position,
		"color": ping_def["color"],
		"icon": ping_def["icon"],
		"duration": PING_DURATION,
		"extra_data": extra_data,
		"created_at": Time.get_unix_time_from_system(),
	}
	
	_active_pings[ping_id] = ping_data
	_player_pings[peer_id].append(ping_id)
	_ping_cooldowns[peer_id] = PING_COOLDOWN
	_coop_stats["pings_placed"] += 1
	
	if _is_host():
		_rpc_ping_placed.rpc(peer_id, ping_type, {"x": position.x, "y": position.y, "z": position.z}, ping_id, extra_data)
	else:
		_rpc_request_ping.rpc_id(1, ping_type, {"x": position.x, "y": position.y, "z": position.z}, extra_data)
	
	emit_signal("ping_placed", peer_id, ping_type, position, ping_data)
	
	return {"success": true, "ping_id": ping_id}


func remove_ping(ping_id: String) -> void:
	_remove_ping(ping_id)
	
	if _is_host():
		_rpc_ping_removed.rpc(ping_id)


func _remove_ping(ping_id: String) -> void:
	if ping_id not in _active_pings:
		return
	
	var ping: Dictionary = _active_pings[ping_id]
	var peer_id: int = ping["peer_id"]
	
	_active_pings.erase(ping_id)
	
	if peer_id in _player_pings:
		_player_pings[peer_id].erase(ping_id)
	
	emit_signal("ping_removed", ping_id)


func _update_pings(delta: float) -> void:
	var expired: Array = []
	
	for ping_id in _active_pings:
		var ping: Dictionary = _active_pings[ping_id]
		ping["duration"] -= delta
		
		if ping["duration"] <= 0:
			expired.append(ping_id)
	
	for ping_id in expired:
		_remove_ping(ping_id)
		if _is_host():
			_rpc_ping_removed.rpc(ping_id)


func _update_ping_cooldowns(delta: float) -> void:
	for peer_id in _ping_cooldowns:
		if _ping_cooldowns[peer_id] > 0:
			_ping_cooldowns[peer_id] -= delta


# ============================================================================
# PING RPCS
# ============================================================================

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_ping(ping_type: int, position: Dictionary, extra_data: Dictionary) -> void:
	if not _is_host():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	var pos := Vector3(position["x"], position["y"], position.get("z", 0.0))
	place_ping(peer_id, ping_type, pos, extra_data)


@rpc("authority", "call_remote", "reliable")
func _rpc_ping_placed(peer_id: int, ping_type: int, position: Dictionary, ping_id: String, extra_data: Dictionary) -> void:
	var pos := Vector3(position["x"], position["y"], position.get("z", 0.0))
	
	var ping_def: Dictionary = PING_DEFINITIONS.get(ping_type, PING_DEFINITIONS[PingType.GENERIC])
	
	var ping_data := {
		"id": ping_id,
		"peer_id": peer_id,
		"type": ping_type,
		"position": pos,
		"color": ping_def["color"],
		"icon": ping_def["icon"],
		"duration": PING_DURATION,
		"extra_data": extra_data,
	}
	
	_active_pings[ping_id] = ping_data
	
	if peer_id not in _player_pings:
		_player_pings[peer_id] = []
	_player_pings[peer_id].append(ping_id)
	
	emit_signal("ping_placed", peer_id, ping_type, pos, ping_data)


@rpc("authority", "call_remote", "reliable")
func _rpc_ping_removed(ping_id: String) -> void:
	_remove_ping(ping_id)


# ============================================================================
# RESOURCE SHARING
# ============================================================================

func share_item(from_peer: int, to_peer: int, item_id: String, quantity: int) -> Dictionary:
	if from_peer not in _player_states or to_peer not in _player_states:
		return {"success": false, "error": "Player not found"}
	
	# Check range (3D)
	var from_pos: Vector3 = _player_states[from_peer]["position"]
	var to_pos: Vector3 = _player_states[to_peer]["position"]
	
	if from_pos.distance_to(to_pos) > 5.0:
		return {"success": false, "error": "Too far away to share"}
	
	# Would actually transfer items via inventory system
	_coop_stats["items_shared"] += quantity
	
	if _is_host():
		_rpc_item_shared.rpc(from_peer, to_peer, item_id, quantity)
	else:
		_rpc_request_share.rpc_id(1, to_peer, item_id, quantity)
	
	emit_signal("resource_shared", from_peer, to_peer, item_id, quantity)
	
	return {"success": true}


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_share(to_peer: int, item_id: String, quantity: int) -> void:
	if not _is_host():
		return
	
	var from_peer := multiplayer.get_remote_sender_id()
	share_item(from_peer, to_peer, item_id, quantity)


@rpc("authority", "call_remote", "reliable")
func _rpc_item_shared(from_peer: int, to_peer: int, item_id: String, quantity: int) -> void:
	emit_signal("resource_shared", from_peer, to_peer, item_id, quantity)


# ============================================================================
# SHARED LOOT
# ============================================================================

func add_to_shared_loot(item_id: String, quantity: int) -> void:
	if item_id in _shared_inventory:
		_shared_inventory[item_id] += quantity
	else:
		_shared_inventory[item_id] = quantity
	
	if _is_host():
		_rpc_shared_loot_updated.rpc(_shared_inventory)


func take_from_shared_loot(peer_id: int, item_id: String, quantity: int) -> Dictionary:
	if item_id not in _shared_inventory:
		return {"success": false, "error": "Item not in shared loot"}
	
	var available: int = _shared_inventory[item_id]
	if available < quantity:
		return {"success": false, "error": "Insufficient quantity"}
	
	_shared_inventory[item_id] -= quantity
	if _shared_inventory[item_id] <= 0:
		_shared_inventory.erase(item_id)
	
	# Would add to player inventory
	
	if _is_host():
		_rpc_shared_loot_updated.rpc(_shared_inventory)
	
	return {"success": true}


@rpc("authority", "call_remote", "reliable")
func _rpc_shared_loot_updated(loot: Dictionary) -> void:
	_shared_inventory = loot


func get_shared_loot() -> Dictionary:
	return _shared_inventory.duplicate()


# ============================================================================
# PROXIMITY BONUSES
# ============================================================================

func _check_proximity_bonuses() -> void:
	# Count nearby players for each player
	var nearby_counts: Dictionary = {}
	
	for peer_id in _player_states:
		nearby_counts[peer_id] = 0
		var my_pos: Vector3 = _player_states[peer_id]["position"]
		
		for other_id in _player_states:
			if other_id == peer_id:
				continue
			
			if _player_states[other_id]["downed_state"] != DownedState.ALIVE:
				continue
			
			var other_pos: Vector3 = _player_states[other_id]["position"]
			if my_pos.distance_to(other_pos) <= PROXIMITY_RANGE:
				nearby_counts[peer_id] += 1
	
	# Update active bonuses
	var any_nearby := false
	for peer_id in nearby_counts:
		if nearby_counts[peer_id] > 0:
			any_nearby = true
			break
	
	for bonus_type in ProximityBonus.values():
		var was_active: bool = _active_proximity_bonuses.get(bonus_type, false)
		var is_active: bool = any_nearby
		
		if is_active and not was_active:
			_active_proximity_bonuses[bonus_type] = true
			emit_signal("proximity_bonus_activated", bonus_type)
		elif not is_active and was_active:
			_active_proximity_bonuses[bonus_type] = false
			emit_signal("proximity_bonus_deactivated", bonus_type)


func get_proximity_bonus(peer_id: int, bonus_type: int) -> float:
	if peer_id not in _player_states:
		return 0.0
	
	var my_pos: Vector3 = _player_states[peer_id]["position"]
	var nearby_count: int = 0
	
	for other_id in _player_states:
		if other_id == peer_id:
			continue
		
		if _player_states[other_id]["downed_state"] != DownedState.ALIVE:
			continue
		
		var other_pos: Vector3 = _player_states[other_id]["position"]
		if my_pos.distance_to(other_pos) <= PROXIMITY_RANGE:
			nearby_count += 1
	
	return PROXIMITY_BONUS_VALUES.get(bonus_type, 0.0) * nearby_count


# ============================================================================
# TEAM OBJECTIVES
# ============================================================================

func create_objective(objective_id: String, target: float, description: String = "") -> void:
	_team_objectives[objective_id] = {
		"id": objective_id,
		"description": description,
		"progress": 0.0,
		"target": target,
		"contributors": {},
		"completed": false,
	}


func add_objective_progress(objective_id: String, peer_id: int, amount: float) -> void:
	if objective_id not in _team_objectives:
		return
	
	var objective: Dictionary = _team_objectives[objective_id]
	
	if objective["completed"]:
		return
	
	objective["progress"] += amount
	
	if peer_id not in objective["contributors"]:
		objective["contributors"][peer_id] = 0.0
	objective["contributors"][peer_id] += amount
	
	var progress_percent: float = objective["progress"] / objective["target"]
	emit_signal("team_objective_updated", objective_id, progress_percent)
	
	if objective["progress"] >= objective["target"]:
		objective["completed"] = true
		_coop_stats["objectives_completed"] += 1
		emit_signal("team_objective_completed", objective_id)
		
		if _is_host():
			_rpc_objective_completed.rpc(objective_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_objective_completed(objective_id: String) -> void:
	if objective_id in _team_objectives:
		_team_objectives[objective_id]["completed"] = true
		emit_signal("team_objective_completed", objective_id)


func get_objective(objective_id: String) -> Dictionary:
	return _team_objectives.get(objective_id, {})


func get_all_objectives() -> Dictionary:
	return _team_objectives.duplicate()


# ============================================================================
# COOP EVENTS
# ============================================================================

func trigger_coop_event(event_type: String, data: Dictionary) -> void:
	emit_signal("coop_event_triggered", event_type, data)
	
	if _is_host():
		_rpc_coop_event.rpc(event_type, data)


@rpc("authority", "call_remote", "reliable")
func _rpc_coop_event(event_type: String, data: Dictionary) -> void:
	emit_signal("coop_event_triggered", event_type, data)


# ============================================================================
# RESPAWN
# ============================================================================

func respawn_player(peer_id: int, position: Vector3) -> void:
	if peer_id not in _player_states:
		return
	
	var state: Dictionary = _player_states[peer_id]
	state["downed_state"] = DownedState.ALIVE
	state["down_count"] = 0
	state["bleedout_timer"] = 0.0
	state["position"] = position
	state["health"] = state["max_health"]
	
	if _is_host():
		_rpc_player_respawned.rpc(peer_id, {"x": position.x, "y": position.y, "z": position.z})


@rpc("authority", "call_remote", "reliable")
func _rpc_player_respawned(peer_id: int, position: Dictionary) -> void:
	if peer_id in _player_states:
		_player_states[peer_id]["downed_state"] = DownedState.ALIVE
		_player_states[peer_id]["down_count"] = 0
		_player_states[peer_id]["position"] = Vector3(position["x"], position["y"], position.get("z", 0.0))


# ============================================================================
# HELPERS
# ============================================================================

func _is_host() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()


# ============================================================================
# QUERIES
# ============================================================================

func get_player_state(peer_id: int) -> Dictionary:
	return _player_states.get(peer_id, {})


func is_player_alive(peer_id: int) -> bool:
	var state: Dictionary = _player_states.get(peer_id, {})
	return state.get("downed_state", DownedState.DEAD) == DownedState.ALIVE


func is_player_downed(peer_id: int) -> bool:
	var state: Dictionary = _player_states.get(peer_id, {})
	return state.get("downed_state", DownedState.DEAD) == DownedState.DOWNED


func is_player_dead(peer_id: int) -> bool:
	var state: Dictionary = _player_states.get(peer_id, {})
	return state.get("downed_state", DownedState.ALIVE) == DownedState.DEAD


func get_downed_players() -> Array:
	var downed: Array = []
	for peer_id in _player_states:
		if _player_states[peer_id]["downed_state"] == DownedState.DOWNED:
			downed.append(peer_id)
	return downed


func get_alive_players() -> Array:
	var alive: Array = []
	for peer_id in _player_states:
		if _player_states[peer_id]["downed_state"] == DownedState.ALIVE:
			alive.append(peer_id)
	return alive


func get_all_pings() -> Dictionary:
	return _active_pings.duplicate()


func get_player_pings(peer_id: int) -> Array:
	return _player_pings.get(peer_id, []).duplicate()


func get_coop_stats() -> Dictionary:
	return _coop_stats.duplicate()


func get_bleedout_time(peer_id: int) -> float:
	var state: Dictionary = _player_states.get(peer_id, {})
	return state.get("bleedout_timer", 0.0)


func get_revive_progress(downed_id: int) -> float:
	var revive_data: Dictionary = _revive_progress.get(downed_id, {})
	return revive_data.get("progress", 0.0)


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"coop_stats": _coop_stats.duplicate(),
		"team_objectives": _team_objectives.duplicate(true),
	}


func load_data(data: Dictionary) -> void:
	_coop_stats = data.get("coop_stats", {})
	if _coop_stats.is_empty():
		_initialize_coop_stats()
	_team_objectives = data.get("team_objectives", {})
