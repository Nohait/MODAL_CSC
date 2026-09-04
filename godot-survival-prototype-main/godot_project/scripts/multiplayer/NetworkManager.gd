extends Node
class_name NetworkManagerClass
## Core networking manager - handles connections, host/client, and network events
## Manages peer connections, authentication, and network state

signal connection_started()
signal connection_failed(reason: String)
signal connection_closed(reason: String)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal server_started()
signal server_stopped()
signal client_connected_to_server()
signal client_disconnected_from_server()
signal player_joined(player_id: int, player_data: Dictionary)
signal player_left(player_id: int)
signal player_kicked(player_id: int, reason: String)
signal latency_updated(peer_id: int, latency_ms: int)
signal network_error(error: String)
signal authentication_required(peer_id: int)
signal authentication_success(peer_id: int)
signal authentication_failed(peer_id: int, reason: String)

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

enum NetworkMode {
	OFFLINE,
	HOST,
	CLIENT,
	DEDICATED_SERVER,
}

enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	AUTHENTICATING,
	CONNECTED,
	RECONNECTING,
}

enum DisconnectReason {
	NONE,
	USER_REQUEST,
	KICKED,
	BANNED,
	SERVER_CLOSED,
	TIMEOUT,
	CONNECTION_LOST,
	AUTHENTICATION_FAILED,
	VERSION_MISMATCH,
	SERVER_FULL,
}

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 8
const HEARTBEAT_INTERVAL := 1.0  # seconds
const CONNECTION_TIMEOUT := 10.0  # seconds
const RECONNECT_ATTEMPTS := 3
const RECONNECT_DELAY := 2.0  # seconds

const GAME_VERSION := "1.0.0"
const PROTOCOL_VERSION := 1


# ============================================================================
# STATE
# ============================================================================

var _network_mode: int = NetworkMode.OFFLINE
var _connection_state: int = ConnectionState.DISCONNECTED
var _peer: ENetMultiplayerPeer = null
var _server_info: Dictionary = {}
var _connected_players: Dictionary = {}  # peer_id -> player data
var _player_latencies: Dictionary = {}  # peer_id -> latency in ms
var _local_player_id: int = 0
var _local_player_data: Dictionary = {}
var _heartbeat_timer: float = 0.0
var _reconnect_attempts: int = 0
var _pending_authentication: Dictionary = {}  # peer_id -> auth state
var _banned_ips: Array = []
var _server_password: String = ""


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(delta: float) -> void:
	if _network_mode == NetworkMode.OFFLINE:
		return
	
	_heartbeat_timer += delta
	if _heartbeat_timer >= HEARTBEAT_INTERVAL:
		_heartbeat_timer = 0.0
		_send_heartbeat()


# ============================================================================
# HOST / SERVER
# ============================================================================

func host_game(port: int = DEFAULT_PORT, max_players: int = MAX_CLIENTS, password: String = "") -> Dictionary:
	if _network_mode != NetworkMode.OFFLINE:
		return {"success": false, "error": "Already connected"}
	
	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_server(port, max_players)
	
	if error != OK:
		return {"success": false, "error": "Failed to create server: %s" % error_string(error)}
	
	multiplayer.multiplayer_peer = _peer
	
	_network_mode = NetworkMode.HOST
	_connection_state = ConnectionState.CONNECTED
	_local_player_id = 1  # Server is always peer 1
	_server_password = password
	
	_server_info = {
		"host_name": _local_player_data.get("name", "Host"),
		"port": port,
		"max_players": max_players,
		"current_players": 1,
		"password_protected": password != "",
		"version": GAME_VERSION,
		"protocol": PROTOCOL_VERSION,
	}
	
	# Add host as first player
	_connected_players[1] = _local_player_data.duplicate()
	_connected_players[1]["peer_id"] = 1
	_connected_players[1]["is_host"] = true
	
	emit_signal("server_started")
	emit_signal("player_joined", 1, _connected_players[1])
	
	return {"success": true, "peer_id": 1}


func start_dedicated_server(port: int = DEFAULT_PORT, max_players: int = MAX_CLIENTS) -> Dictionary:
	var result := host_game(port, max_players)
	if result["success"]:
		_network_mode = NetworkMode.DEDICATED_SERVER
		# Remove host from players list for dedicated server
		_connected_players.erase(1)
	return result


func stop_server(reason: String = "Server closed") -> void:
	if _network_mode != NetworkMode.HOST and _network_mode != NetworkMode.DEDICATED_SERVER:
		return
	
	# Notify all clients
	for peer_id in _connected_players:
		if peer_id != 1:
			_rpc_disconnect_client.rpc_id(peer_id, DisconnectReason.SERVER_CLOSED, reason)
	
	_cleanup_network()
	emit_signal("server_stopped")


func kick_player(peer_id: int, reason: String = "Kicked by host") -> void:
	if not is_host():
		return
	
	if peer_id == 1:
		return  # Can't kick host
	
	if peer_id in _connected_players:
		_rpc_disconnect_client.rpc_id(peer_id, DisconnectReason.KICKED, reason)
		_peer.disconnect_peer(peer_id)
		emit_signal("player_kicked", peer_id, reason)


func ban_player(peer_id: int, reason: String = "Banned") -> void:
	if not is_host():
		return
	
	# Would need IP tracking for real bans
	kick_player(peer_id, reason)


# ============================================================================
# CLIENT / JOIN
# ============================================================================

func join_game(address: String, port: int = DEFAULT_PORT, password: String = "") -> Dictionary:
	if _network_mode != NetworkMode.OFFLINE:
		return {"success": false, "error": "Already connected"}
	
	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_client(address, port)
	
	if error != OK:
		return {"success": false, "error": "Failed to connect: %s" % error_string(error)}
	
	multiplayer.multiplayer_peer = _peer
	
	_network_mode = NetworkMode.CLIENT
	_connection_state = ConnectionState.CONNECTING
	_server_password = password
	
	emit_signal("connection_started")
	
	return {"success": true}


func disconnect_from_server(reason: String = "User disconnected") -> void:
	if _network_mode == NetworkMode.OFFLINE:
		return
	
	if is_client():
		_rpc_client_disconnecting.rpc_id(1, reason)
	
	_cleanup_network()
	emit_signal("connection_closed", reason)


func _cleanup_network() -> void:
	if _peer:
		_peer.close()
		_peer = null
	
	multiplayer.multiplayer_peer = null
	
	_network_mode = NetworkMode.OFFLINE
	_connection_state = ConnectionState.DISCONNECTED
	_connected_players.clear()
	_player_latencies.clear()
	_pending_authentication.clear()
	_server_info.clear()
	_local_player_id = 0


# ============================================================================
# CONNECTION CALLBACKS
# ============================================================================

func _on_peer_connected(peer_id: int) -> void:
	print("[Network] Peer connected: ", peer_id)
	emit_signal("peer_connected", peer_id)
	
	if is_host():
		# Server: request authentication from new peer
		_pending_authentication[peer_id] = {
			"state": "pending",
			"timestamp": Time.get_unix_time_from_system(),
		}
		_rpc_request_authentication.rpc_id(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("[Network] Peer disconnected: ", peer_id)
	
	if peer_id in _connected_players:
		var player_data: Dictionary = _connected_players[peer_id]
		_connected_players.erase(peer_id)
		emit_signal("player_left", peer_id)
		
		# Notify other players
		if is_host():
			_rpc_player_left.rpc(peer_id)
	
	_player_latencies.erase(peer_id)
	_pending_authentication.erase(peer_id)
	
	emit_signal("peer_disconnected", peer_id)


func _on_connected_to_server() -> void:
	print("[Network] Connected to server")
	_connection_state = ConnectionState.AUTHENTICATING
	_local_player_id = multiplayer.get_unique_id()
	emit_signal("client_connected_to_server")


func _on_connection_failed() -> void:
	print("[Network] Connection failed")
	
	if _reconnect_attempts < RECONNECT_ATTEMPTS:
		_reconnect_attempts += 1
		_connection_state = ConnectionState.RECONNECTING
		# Would set up timer for reconnect
	else:
		_cleanup_network()
		emit_signal("connection_failed", "Connection failed after %d attempts" % RECONNECT_ATTEMPTS)


func _on_server_disconnected() -> void:
	print("[Network] Server disconnected")
	_cleanup_network()
	emit_signal("client_disconnected_from_server")


# ============================================================================
# AUTHENTICATION
# ============================================================================

@rpc("authority", "call_remote", "reliable")
func _rpc_request_authentication() -> void:
	# Client receives auth request from server
	var auth_data := {
		"version": GAME_VERSION,
		"protocol": PROTOCOL_VERSION,
		"password": _server_password,
		"player_name": _local_player_data.get("name", "Player"),
		"player_data": _local_player_data,
	}
	_rpc_submit_authentication.rpc_id(1, auth_data)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_submit_authentication(auth_data: Dictionary) -> void:
	if not is_host():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	
	# Validate authentication
	var result := _validate_authentication(peer_id, auth_data)
	
	if result["success"]:
		_pending_authentication.erase(peer_id)
		
		# Add player to connected list
		var player_data: Dictionary = auth_data.get("player_data", {})
		player_data["peer_id"] = peer_id
		player_data["name"] = auth_data.get("player_name", "Player")
		player_data["is_host"] = false
		_connected_players[peer_id] = player_data
		
		# Send success to client
		_rpc_authentication_result.rpc_id(peer_id, true, "", _get_server_state())
		
		# Notify all players of new player
		_rpc_player_joined.rpc(peer_id, player_data)
		
		emit_signal("authentication_success", peer_id)
		emit_signal("player_joined", peer_id, player_data)
	else:
		_rpc_authentication_result.rpc_id(peer_id, false, result["error"], {})
		_peer.disconnect_peer(peer_id)
		emit_signal("authentication_failed", peer_id, result["error"])


func _validate_authentication(peer_id: int, auth_data: Dictionary) -> Dictionary:
	# Check version
	if auth_data.get("version", "") != GAME_VERSION:
		return {"success": false, "error": "Version mismatch"}
	
	# Check protocol
	if auth_data.get("protocol", 0) != PROTOCOL_VERSION:
		return {"success": false, "error": "Protocol mismatch"}
	
	# Check password
	if _server_password != "" and auth_data.get("password", "") != _server_password:
		return {"success": false, "error": "Invalid password"}
	
	# Check player limit
	if _connected_players.size() >= _server_info.get("max_players", MAX_CLIENTS):
		return {"success": false, "error": "Server full"}
	
	return {"success": true}


@rpc("authority", "call_remote", "reliable")
func _rpc_authentication_result(success: bool, error: String, server_state: Dictionary) -> void:
	if success:
		_connection_state = ConnectionState.CONNECTED
		_apply_server_state(server_state)
		emit_signal("authentication_success", _local_player_id)
	else:
		_cleanup_network()
		emit_signal("authentication_failed", _local_player_id, error)


func _get_server_state() -> Dictionary:
	return {
		"server_info": _server_info,
		"players": _connected_players,
		"game_time": 0.0,  # Would get from game state
	}


func _apply_server_state(state: Dictionary) -> void:
	_server_info = state.get("server_info", {})
	_connected_players = state.get("players", {})


# ============================================================================
# PLAYER SYNC
# ============================================================================

@rpc("authority", "call_remote", "reliable")
func _rpc_player_joined(peer_id: int, player_data: Dictionary) -> void:
	_connected_players[peer_id] = player_data
	emit_signal("player_joined", peer_id, player_data)


@rpc("authority", "call_remote", "reliable")
func _rpc_player_left(peer_id: int) -> void:
	if peer_id in _connected_players:
		_connected_players.erase(peer_id)
		emit_signal("player_left", peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_disconnecting(reason: String) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	print("[Network] Client %d disconnecting: %s" % [peer_id, reason])


@rpc("authority", "call_remote", "reliable")
func _rpc_disconnect_client(reason_code: int, message: String) -> void:
	print("[Network] Disconnected by server: %s" % message)
	_cleanup_network()
	emit_signal("connection_closed", message)


# ============================================================================
# HEARTBEAT & LATENCY
# ============================================================================

func _send_heartbeat() -> void:
	if is_host():
		# Server sends heartbeat to all clients
		for peer_id in _connected_players:
			if peer_id != 1:
				_rpc_heartbeat.rpc_id(peer_id, Time.get_ticks_msec())
	elif is_client():
		# Client responds to heartbeat
		pass


@rpc("authority", "call_remote", "unreliable")
func _rpc_heartbeat(server_time: int) -> void:
	# Client receives heartbeat, respond immediately
	_rpc_heartbeat_response.rpc_id(1, server_time)


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_heartbeat_response(original_time: int) -> void:
	if not is_host():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	var latency := (Time.get_ticks_msec() - original_time) / 2
	_player_latencies[peer_id] = latency
	emit_signal("latency_updated", peer_id, latency)


# ============================================================================
# PLAYER DATA
# ============================================================================

func set_local_player_data(data: Dictionary) -> void:
	_local_player_data = data.duplicate()
	_local_player_data["peer_id"] = _local_player_id
	
	if is_connected_to_network():
		# Update other players
		if is_host():
			_connected_players[1] = _local_player_data
			_rpc_player_data_updated.rpc(1, _local_player_data)
		else:
			_rpc_update_player_data.rpc_id(1, _local_player_data)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_update_player_data(data: Dictionary) -> void:
	if not is_host():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id in _connected_players:
		_connected_players[peer_id].merge(data, true)
		_rpc_player_data_updated.rpc(peer_id, _connected_players[peer_id])


@rpc("authority", "call_remote", "reliable")
func _rpc_player_data_updated(peer_id: int, data: Dictionary) -> void:
	_connected_players[peer_id] = data
	emit_signal("player_joined", peer_id, data)  # Reuse signal for updates


# ============================================================================
# QUERIES
# ============================================================================

func is_host() -> bool:
	return _network_mode == NetworkMode.HOST or _network_mode == NetworkMode.DEDICATED_SERVER


func is_client() -> bool:
	return _network_mode == NetworkMode.CLIENT


func is_online() -> bool:
	return _network_mode != NetworkMode.OFFLINE


func is_connected_to_network() -> bool:
	return _connection_state == ConnectionState.CONNECTED


func get_network_mode() -> int:
	return _network_mode


func get_connection_state() -> int:
	return _connection_state


func get_local_player_id() -> int:
	return _local_player_id


func get_player_count() -> int:
	return _connected_players.size()


func get_connected_players() -> Dictionary:
	return _connected_players.duplicate()


func get_player_data(peer_id: int) -> Dictionary:
	return _connected_players.get(peer_id, {})


func get_player_latency(peer_id: int) -> int:
	return _player_latencies.get(peer_id, -1)


func get_server_info() -> Dictionary:
	return _server_info.duplicate()


func get_average_latency() -> float:
	if _player_latencies.is_empty():
		return 0.0
	
	var total: int = 0
	for latency in _player_latencies.values():
		total += latency
	return float(total) / _player_latencies.size()


# ============================================================================
# NETWORK AUTHORITY
# ============================================================================

func is_authority_for(node: Node) -> bool:
	return node.is_multiplayer_authority()


func set_authority(node: Node, peer_id: int) -> void:
	node.set_multiplayer_authority(peer_id)


func get_authority(node: Node) -> int:
	return node.get_multiplayer_authority()


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"local_player_data": _local_player_data.duplicate(),
		"banned_ips": _banned_ips.duplicate(),
	}


func load_data(data: Dictionary) -> void:
	_local_player_data = data.get("local_player_data", {})
	_banned_ips = data.get("banned_ips", [])
