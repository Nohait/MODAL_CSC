extends Node
class_name MultiplayerSyncClass
## Handles state synchronization, entity interpolation, and networked game state
## Manages syncing players, enemies, items, and world state across network

signal entity_spawned(entity_id: String, entity_type: int, data: Dictionary)
signal entity_despawned(entity_id: String)
signal entity_state_updated(entity_id: String, state: Dictionary)
signal world_state_synced()
signal inventory_synced(peer_id: int)
signal combat_event_synced(event: Dictionary)
signal sync_error(error: String)

# ============================================================================
# SYNC CONFIGURATION
# ============================================================================

enum SyncEntityType {
	PLAYER,
	ENEMY,
	NPC,
	VEHICLE,
	PROJECTILE,
	ITEM_DROP,
	RESOURCE_NODE,
	STRUCTURE,
}

enum SyncPriority {
	LOW,       # Update every 500ms
	MEDIUM,    # Update every 200ms
	HIGH,      # Update every 100ms
	CRITICAL,  # Update every frame
}

enum SyncMode {
	AUTHORITATIVE,   # Server controls all
	OWNER_AUTHORITY, # Owner controls their entity
	REPLICATED,      # Read-only copy
}

const SYNC_RATES := {
	SyncPriority.LOW: 0.5,
	SyncPriority.MEDIUM: 0.2,
	SyncPriority.HIGH: 0.1,
	SyncPriority.CRITICAL: 0.0,
}

const INTERPOLATION_SPEED := 15.0
const POSITION_SNAP_THRESHOLD := 5.0  # Teleport if difference > this
const MAX_HISTORY_SIZE := 20


# ============================================================================
# STATE
# ============================================================================

var _synced_entities: Dictionary = {}  # entity_id -> entity data
var _entity_history: Dictionary = {}  # entity_id -> Array of past states
var _sync_timers: Dictionary = {}  # SyncPriority -> timer
var _pending_spawns: Array = []
var _pending_despawns: Array = []
var _world_state_dirty: bool = false
var _last_world_sync: float = 0.0

# Entity counters
var _entity_id_counter: int = 0


func _ready() -> void:
	# Initialize sync timers
	for priority in SyncPriority.values():
		_sync_timers[priority] = 0.0


func _process(delta: float) -> void:
	if not _is_networked():
		return
	
	# Update sync timers
	for priority in _sync_timers:
		_sync_timers[priority] += delta
	
	# Process syncs by priority
	_process_syncs()
	
	# Interpolate remote entities
	_interpolate_entities(delta)


# ============================================================================
# ENTITY REGISTRATION
# ============================================================================

func register_entity(node: Node, entity_type: int, priority: int = SyncPriority.MEDIUM, sync_mode: int = SyncMode.OWNER_AUTHORITY) -> String:
	var entity_id := _generate_entity_id(entity_type)
	
	var entity_data := {
		"id": entity_id,
		"type": entity_type,
		"type_name": SyncEntityType.keys()[entity_type],
		"node": node,
		"node_path": node.get_path(),
		"priority": priority,
		"sync_mode": sync_mode,
		"owner_peer": _get_owner_peer(node),
		
		# State (3D)
		"position": Vector3.ZERO,
		"velocity": Vector3.ZERO,
		"rotation": Vector3.ZERO,  # Euler angles
		"health": 100.0,
		"custom_data": {},
		
		# Sync tracking
		"last_sync": 0.0,
		"dirty": true,
	}
	
	_synced_entities[entity_id] = entity_data
	_entity_history[entity_id] = []
	
	# If we're host, notify clients
	if _is_host():
		_rpc_spawn_entity.rpc(entity_id, entity_type, _serialize_entity_data(entity_data))
	
	emit_signal("entity_spawned", entity_id, entity_type, entity_data)
	
	return entity_id


func unregister_entity(entity_id: String) -> void:
	if entity_id not in _synced_entities:
		return
	
	_synced_entities.erase(entity_id)
	_entity_history.erase(entity_id)
	
	if _is_host():
		_rpc_despawn_entity.rpc(entity_id)
	
	emit_signal("entity_despawned", entity_id)


func _generate_entity_id(entity_type: int) -> String:
	_entity_id_counter += 1
	var peer_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
	return "%s_%d_%d" % [SyncEntityType.keys()[entity_type], peer_id, _entity_id_counter]


func _get_owner_peer(node: Node) -> int:
	if node.has_method("get_multiplayer_authority"):
		return node.get_multiplayer_authority()
	return 1  # Default to server


# ============================================================================
# STATE SYNCHRONIZATION
# ============================================================================

func update_entity_state(entity_id: String, state: Dictionary) -> void:
	if entity_id not in _synced_entities:
		return
	
	var entity: Dictionary = _synced_entities[entity_id]
	
	# Only owner can update in OWNER_AUTHORITY mode
	if entity["sync_mode"] == SyncMode.OWNER_AUTHORITY:
		var local_peer: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
		if entity["owner_peer"] != local_peer and not _is_host():
			return
	
	# Update local state
	for key in state:
		entity[key] = state[key]
	
	entity["dirty"] = true


func _process_syncs() -> void:
	for priority in _sync_timers:
		var rate: float = SYNC_RATES[priority]
		if _sync_timers[priority] >= rate:
			_sync_timers[priority] = 0.0
			_sync_entities_by_priority(priority)


func _sync_entities_by_priority(priority: int) -> void:
	for entity_id in _synced_entities:
		var entity: Dictionary = _synced_entities[entity_id]
		
		if entity["priority"] != priority:
			continue
		
		if not entity["dirty"]:
			continue
		
		_sync_entity(entity_id)


func _sync_entity(entity_id: String) -> void:
	var entity: Dictionary = _synced_entities[entity_id]
	var state := _get_entity_state(entity)
	
	if _is_host():
		# Server broadcasts to all clients
		_rpc_entity_state.rpc(entity_id, state)
	elif entity["owner_peer"] == multiplayer.get_unique_id():
		# Owner sends to server
		_rpc_entity_state_to_server.rpc_id(1, entity_id, state)
	
	entity["dirty"] = false
	entity["last_sync"] = Time.get_unix_time_from_system()


func _get_entity_state(entity: Dictionary) -> Dictionary:
	var state := {
		"position": {"x": entity["position"].x, "y": entity["position"].y, "z": entity["position"].z},
		"velocity": {"x": entity["velocity"].x, "y": entity["velocity"].y, "z": entity["velocity"].z},
		"rotation": {"x": entity["rotation"].x, "y": entity["rotation"].y, "z": entity["rotation"].z},
		"health": entity["health"],
		"timestamp": Time.get_ticks_msec(),
	}
	
	# Include custom data
	state.merge(entity.get("custom_data", {}))
	
	return state


func _serialize_entity_data(entity: Dictionary) -> Dictionary:
	return {
		"type": entity["type"],
		"priority": entity["priority"],
		"sync_mode": entity["sync_mode"],
		"owner_peer": entity["owner_peer"],
		"position": {"x": entity["position"].x, "y": entity["position"].y, "z": entity["position"].z},
		"rotation": {"x": entity["rotation"].x, "y": entity["rotation"].y, "z": entity["rotation"].z},
		"health": entity["health"],
		"custom_data": entity.get("custom_data", {}),
	}


# ============================================================================
# NETWORK RPCS - ENTITY SYNC
# ============================================================================

@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_entity(entity_id: String, entity_type: int, data: Dictionary) -> void:
	if entity_id in _synced_entities:
		return  # Already exists
	
	var entity_data := {
		"id": entity_id,
		"type": entity_type,
		"type_name": SyncEntityType.keys()[entity_type],
		"node": null,  # Will be created by game logic
		"priority": data.get("priority", SyncPriority.MEDIUM),
		"sync_mode": data.get("sync_mode", SyncMode.REPLICATED),
		"owner_peer": data.get("owner_peer", 1),
		"position": Vector3(data["position"]["x"], data["position"]["y"], data["position"].get("z", 0.0)),
		"velocity": Vector3.ZERO,
		"rotation": Vector3(data.get("rotation", {}).get("x", 0.0), data.get("rotation", {}).get("y", 0.0), data.get("rotation", {}).get("z", 0.0)),
		"health": data.get("health", 100.0),
		"custom_data": data.get("custom_data", {}),
		"last_sync": 0.0,
		"dirty": false,
	}
	
	_synced_entities[entity_id] = entity_data
	_entity_history[entity_id] = []
	
	emit_signal("entity_spawned", entity_id, entity_type, entity_data)


@rpc("authority", "call_remote", "reliable")
func _rpc_despawn_entity(entity_id: String) -> void:
	if entity_id not in _synced_entities:
		return
	
	_synced_entities.erase(entity_id)
	_entity_history.erase(entity_id)
	
	emit_signal("entity_despawned", entity_id)


@rpc("authority", "call_remote", "unreliable")
func _rpc_entity_state(entity_id: String, state: Dictionary) -> void:
	if entity_id not in _synced_entities:
		return
	
	_apply_entity_state(entity_id, state)


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_entity_state_to_server(entity_id: String, state: Dictionary) -> void:
	if not _is_host():
		return
	
	if entity_id not in _synced_entities:
		return
	
	var entity: Dictionary = _synced_entities[entity_id]
	var sender := multiplayer.get_remote_sender_id()
	
	# Verify sender owns this entity
	if entity["sync_mode"] == SyncMode.OWNER_AUTHORITY and entity["owner_peer"] != sender:
		return
	
	_apply_entity_state(entity_id, state)
	
	# Broadcast to other clients
	for peer_id in _get_other_peers(sender):
		_rpc_entity_state.rpc_id(peer_id, entity_id, state)


func _apply_entity_state(entity_id: String, state: Dictionary) -> void:
	var entity: Dictionary = _synced_entities[entity_id]
	
	# Store in history for interpolation
	var history: Array = _entity_history.get(entity_id, [])
	history.append(state)
	if history.size() > MAX_HISTORY_SIZE:
		history.pop_front()
	_entity_history[entity_id] = history
	
	# Apply state (3D)
	if state.has("position"):
		entity["target_position"] = Vector3(state["position"]["x"], state["position"]["y"], state["position"].get("z", 0.0))
	if state.has("velocity"):
		entity["velocity"] = Vector3(state["velocity"]["x"], state["velocity"]["y"], state["velocity"].get("z", 0.0))
	if state.has("rotation"):
		if state["rotation"] is Dictionary:
			entity["target_rotation"] = Vector3(state["rotation"].get("x", 0.0), state["rotation"].get("y", 0.0), state["rotation"].get("z", 0.0))
		else:
			entity["target_rotation"] = Vector3(0, state["rotation"], 0)  # Legacy 2D rotation as Y
	if state.has("health"):
		entity["health"] = state["health"]
	
	emit_signal("entity_state_updated", entity_id, state)


# ============================================================================
# INTERPOLATION
# ============================================================================

func _interpolate_entities(delta: float) -> void:
	for entity_id in _synced_entities:
		var entity: Dictionary = _synced_entities[entity_id]
		
		# Only interpolate remote entities
		var local_peer: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
		if entity["owner_peer"] == local_peer:
			continue
		
		_interpolate_entity(entity, delta)


func _interpolate_entity(entity: Dictionary, delta: float) -> void:
	# Position interpolation (3D)
	if entity.has("target_position"):
		var current: Vector3 = entity["position"]
		var target: Vector3 = entity["target_position"]
		var distance: float = current.distance_to(target)
		
		if distance > POSITION_SNAP_THRESHOLD:
			# Teleport if too far
			entity["position"] = target
		else:
			# Smooth interpolation
			entity["position"] = current.lerp(target, delta * INTERPOLATION_SPEED)
	
	# Rotation interpolation (3D Euler angles)
	if entity.has("target_rotation"):
		var current: Vector3 = entity["rotation"]
		var target: Vector3 = entity["target_rotation"]
		entity["rotation"] = Vector3(
			lerp_angle(current.x, target.x, delta * INTERPOLATION_SPEED),
			lerp_angle(current.y, target.y, delta * INTERPOLATION_SPEED),
			lerp_angle(current.z, target.z, delta * INTERPOLATION_SPEED)
		)
	
	# Apply to node if exists (3D)
	var node: Node = entity.get("node")
	if node and is_instance_valid(node):
		if node is Node3D:
			node.global_position = entity["position"]
			node.rotation = entity["rotation"]
		elif node is Node2D:  # Legacy 2D support
			node.position = Vector2(entity["position"].x, entity["position"].z)
			node.rotation = entity["rotation"].y


# ============================================================================
# PLAYER SYNC
# ============================================================================

func sync_player_state(peer_id: int, state: Dictionary) -> void:
	if _is_host():
		_rpc_player_state.rpc(peer_id, state)
	else:
		_rpc_player_state_to_server.rpc_id(1, state)


@rpc("authority", "call_remote", "unreliable")
func _rpc_player_state(peer_id: int, state: Dictionary) -> void:
	# Apply remote player state
	pass  # Would update player node


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_player_state_to_server(state: Dictionary) -> void:
	if not _is_host():
		return
	
	var sender := multiplayer.get_remote_sender_id()
	
	# Validate and broadcast to others
	for peer_id in _get_other_peers(sender):
		_rpc_player_state.rpc_id(peer_id, sender, state)


# ============================================================================
# WORLD STATE SYNC
# ============================================================================

func request_world_state() -> void:
	if _is_host():
		return  # Host has authoritative state
	
	_rpc_request_world_state.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_world_state() -> void:
	if not _is_host():
		return
	
	var sender := multiplayer.get_remote_sender_id()
	var world_state := _build_world_state()
	_rpc_world_state.rpc_id(sender, world_state)


@rpc("authority", "call_remote", "reliable")
func _rpc_world_state(state: Dictionary) -> void:
	_apply_world_state(state)
	emit_signal("world_state_synced")


func _build_world_state() -> Dictionary:
	var entities := {}
	for entity_id in _synced_entities:
		entities[entity_id] = _serialize_entity_data(_synced_entities[entity_id])
	
	return {
		"entities": entities,
		"game_time": 0.0,  # Would get from game systems
		"weather": {},  # Would get from WeatherSystem
		"timestamp": Time.get_ticks_msec(),
	}


func _apply_world_state(state: Dictionary) -> void:
	# Clear existing entities
	_synced_entities.clear()
	_entity_history.clear()
	
	# Recreate entities from state
	for entity_id in state.get("entities", {}):
		var entity_data: Dictionary = state["entities"][entity_id]
		_rpc_spawn_entity(entity_id, entity_data["type"], entity_data)


# ============================================================================
# COMBAT SYNC
# ============================================================================

func sync_damage(attacker_id: String, target_id: String, damage: float, damage_type: String = "normal") -> void:
	var combat_event := {
		"type": "damage",
		"attacker": attacker_id,
		"target": target_id,
		"damage": damage,
		"damage_type": damage_type,
		"timestamp": Time.get_ticks_msec(),
	}
	
	if _is_host():
		# Apply damage and broadcast
		_apply_combat_event(combat_event)
		_rpc_combat_event.rpc(combat_event)
	else:
		# Send to server for validation
		_rpc_combat_event_to_server.rpc_id(1, combat_event)


func sync_death(entity_id: String, killer_id: String = "") -> void:
	var combat_event := {
		"type": "death",
		"entity": entity_id,
		"killer": killer_id,
		"timestamp": Time.get_ticks_msec(),
	}
	
	if _is_host():
		_apply_combat_event(combat_event)
		_rpc_combat_event.rpc(combat_event)
	else:
		_rpc_combat_event_to_server.rpc_id(1, combat_event)


@rpc("authority", "call_remote", "reliable")
func _rpc_combat_event(event: Dictionary) -> void:
	_apply_combat_event(event)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_combat_event_to_server(event: Dictionary) -> void:
	if not _is_host():
		return
	
	# Validate combat event
	if _validate_combat_event(event):
		_apply_combat_event(event)
		_rpc_combat_event.rpc(event)


func _validate_combat_event(event: Dictionary) -> bool:
	# Would validate distances, line of sight, etc.
	return true


func _apply_combat_event(event: Dictionary) -> void:
	emit_signal("combat_event_synced", event)
	
	match event.get("type"):
		"damage":
			var target_id: String = event.get("target", "")
			if target_id in _synced_entities:
				var entity: Dictionary = _synced_entities[target_id]
				entity["health"] -= event.get("damage", 0)
		
		"death":
			var entity_id: String = event.get("entity", "")
			# Would trigger death handling


# ============================================================================
# INVENTORY SYNC
# ============================================================================

func sync_inventory_change(peer_id: int, item_id: String, quantity_change: int, slot: int = -1) -> void:
	var inv_event := {
		"peer_id": peer_id,
		"item_id": item_id,
		"quantity_change": quantity_change,
		"slot": slot,
	}
	
	if _is_host():
		_rpc_inventory_change.rpc(inv_event)
	else:
		_rpc_inventory_change_to_server.rpc_id(1, inv_event)


@rpc("authority", "call_remote", "reliable")
func _rpc_inventory_change(event: Dictionary) -> void:
	# Would apply inventory change
	emit_signal("inventory_synced", event.get("peer_id", 0))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_inventory_change_to_server(event: Dictionary) -> void:
	if not _is_host():
		return
	
	var sender := multiplayer.get_remote_sender_id()
	event["peer_id"] = sender  # Ensure correct peer
	
	# Validate and broadcast
	_rpc_inventory_change.rpc(event)


# ============================================================================
# RESOURCE NODE SYNC
# ============================================================================

func sync_resource_harvested(resource_id: String, harvester_id: int, amount: int) -> void:
	var event := {
		"resource_id": resource_id,
		"harvester_id": harvester_id,
		"amount": amount,
	}
	
	if _is_host():
		_rpc_resource_harvested.rpc(event)


@rpc("authority", "call_remote", "reliable")
func _rpc_resource_harvested(event: Dictionary) -> void:
	# Would update resource node state
	pass


func sync_resource_depleted(resource_id: String) -> void:
	if _is_host():
		_rpc_resource_depleted.rpc(resource_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_resource_depleted(resource_id: String) -> void:
	# Would remove or disable resource node
	pass


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _is_host() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()


func _is_networked() -> bool:
	return multiplayer.has_multiplayer_peer()


func _get_other_peers(exclude_peer: int) -> Array:
	var peers: Array = []
	if not multiplayer.has_multiplayer_peer():
		return peers
	
	for peer_id in multiplayer.get_peers():
		if peer_id != exclude_peer:
			peers.append(peer_id)
	
	return peers


# ============================================================================
# QUERIES
# ============================================================================

func get_entity(entity_id: String) -> Dictionary:
	return _synced_entities.get(entity_id, {})


func get_entities_by_type(entity_type: int) -> Array:
	var entities: Array = []
	for entity_id in _synced_entities:
		if _synced_entities[entity_id]["type"] == entity_type:
			entities.append(_synced_entities[entity_id])
	return entities


func get_all_entities() -> Dictionary:
	return _synced_entities.duplicate()


func get_entity_count() -> int:
	return _synced_entities.size()


func is_entity_local(entity_id: String) -> bool:
	if entity_id not in _synced_entities:
		return false
	
	var entity: Dictionary = _synced_entities[entity_id]
	var local_peer: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
	return entity["owner_peer"] == local_peer


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var entities := {}
	for entity_id in _synced_entities:
		entities[entity_id] = _serialize_entity_data(_synced_entities[entity_id])
	
	return {
		"entities": entities,
		"entity_id_counter": _entity_id_counter,
	}


func load_data(data: Dictionary) -> void:
	_entity_id_counter = data.get("entity_id_counter", 0)
	# Entities would be recreated through game logic
