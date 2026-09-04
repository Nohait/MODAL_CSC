extends Node
class_name LobbySystemClass
## Manages game lobbies, matchmaking, player slots, and game session setup
## Handles lobby creation, joining, ready states, and game start conditions

signal lobby_created(lobby_id: String, lobby_data: Dictionary)
signal lobby_joined(lobby_id: String)
signal lobby_left(lobby_id: String)
signal lobby_closed(lobby_id: String, reason: String)
signal lobby_updated(lobby_id: String, lobby_data: Dictionary)
signal player_slot_updated(slot_index: int, player_data: Dictionary)
signal player_ready_changed(peer_id: int, is_ready: bool)
signal all_players_ready()
signal game_starting(countdown: int)
signal game_started()
signal lobby_list_updated(lobbies: Array)
signal matchmaking_started()
signal matchmaking_found(lobby_id: String)
signal matchmaking_cancelled()
signal chat_message_received(sender_id: int, sender_name: String, message: String)

# ============================================================================
# LOBBY CONFIGURATION
# ============================================================================

enum LobbyState {
	IDLE,
	WAITING,
	STARTING,
	IN_GAME,
	CLOSED,
}

enum LobbyVisibility {
	PUBLIC,
	PRIVATE,
	FRIENDS_ONLY,
}

enum GameMode {
	COOP_SURVIVAL,
	COOP_STORY,
	RAID,
	PVP_SURVIVAL,
	CUSTOM,
}

enum MatchmakingState {
	IDLE,
	SEARCHING,
	FOUND,
	JOINING,
}

const MAX_LOBBY_PLAYERS := 4
const MIN_PLAYERS_TO_START := 1
const GAME_START_COUNTDOWN := 5
const MATCHMAKING_TIMEOUT := 60.0
const LOBBY_REFRESH_INTERVAL := 5.0

const GAME_MODE_DEFINITIONS := {
	GameMode.COOP_SURVIVAL: {
		"name": "Co-op Survival",
		"description": "Work together to survive as long as possible.",
		"min_players": 1,
		"max_players": 4,
		"pvp_enabled": false,
		"shared_loot": true,
		"respawn_enabled": true,
	},
	GameMode.COOP_STORY: {
		"name": "Co-op Story",
		"description": "Play through the story campaign together.",
		"min_players": 1,
		"max_players": 4,
		"pvp_enabled": false,
		"shared_loot": false,
		"respawn_enabled": true,
	},
	GameMode.RAID: {
		"name": "Raid",
		"description": "Team up to complete challenging raid dungeons.",
		"min_players": 2,
		"max_players": 4,
		"pvp_enabled": false,
		"shared_loot": true,
		"respawn_enabled": false,
	},
	GameMode.PVP_SURVIVAL: {
		"name": "PvP Survival",
		"description": "Survival mode with player vs player combat enabled.",
		"min_players": 2,
		"max_players": 4,
		"pvp_enabled": true,
		"shared_loot": false,
		"respawn_enabled": true,
	},
	GameMode.CUSTOM: {
		"name": "Custom",
		"description": "Customized game rules.",
		"min_players": 1,
		"max_players": 4,
		"pvp_enabled": false,
		"shared_loot": false,
		"respawn_enabled": true,
	},
}


# ============================================================================
# STATE
# ============================================================================

var _current_lobby: Dictionary = {}
var _lobby_state: int = LobbyState.IDLE
var _player_slots: Array = []  # Array of player slot data
var _ready_players: Dictionary = {}  # peer_id -> is_ready
var _available_lobbies: Array = []  # List of public lobbies
var _matchmaking_state: int = MatchmakingState.IDLE
var _matchmaking_timer: float = 0.0
var _matchmaking_preferences: Dictionary = {}
var _game_start_countdown: int = 0
var _countdown_timer: float = 0.0
var _lobby_refresh_timer: float = 0.0
var _chat_history: Array = []


func _ready() -> void:
	_initialize_player_slots()


func _process(delta: float) -> void:
	# Matchmaking timeout
	if _matchmaking_state == MatchmakingState.SEARCHING:
		_matchmaking_timer += delta
		if _matchmaking_timer >= MATCHMAKING_TIMEOUT:
			cancel_matchmaking()
	
	# Game start countdown
	if _lobby_state == LobbyState.STARTING:
		_countdown_timer += delta
		if _countdown_timer >= 1.0:
			_countdown_timer = 0.0
			_game_start_countdown -= 1
			emit_signal("game_starting", _game_start_countdown)
			
			if _game_start_countdown <= 0:
				_start_game()
	
	# Lobby list refresh
	if _lobby_state == LobbyState.IDLE:
		_lobby_refresh_timer += delta
		if _lobby_refresh_timer >= LOBBY_REFRESH_INTERVAL:
			_lobby_refresh_timer = 0.0
			_refresh_lobby_list()


func _initialize_player_slots() -> void:
	_player_slots.clear()
	for i in range(MAX_LOBBY_PLAYERS):
		_player_slots.append({
			"slot_index": i,
			"peer_id": 0,
			"player_name": "",
			"is_host": false,
			"is_ready": false,
			"character_data": {},
			"team": 0,
			"empty": true,
		})


# ============================================================================
# LOBBY CREATION
# ============================================================================

func create_lobby(lobby_name: String, game_mode: int, visibility: int = LobbyVisibility.PUBLIC, password: String = "") -> Dictionary:
	if _lobby_state != LobbyState.IDLE:
		return {"success": false, "error": "Already in a lobby"}
	
	var mode_def: Dictionary = GAME_MODE_DEFINITIONS.get(game_mode, {})
	if mode_def.is_empty():
		return {"success": false, "error": "Invalid game mode"}
	
	var lobby_id := _generate_lobby_id()
	
	_current_lobby = {
		"id": lobby_id,
		"name": lobby_name,
		"game_mode": game_mode,
		"game_mode_name": GameMode.keys()[game_mode],
		"visibility": visibility,
		"password_protected": password != "",
		"password": password,
		"host_peer_id": 1,
		"host_name": _get_local_player_name(),
		"max_players": mode_def.get("max_players", MAX_LOBBY_PLAYERS),
		"min_players": mode_def.get("min_players", MIN_PLAYERS_TO_START),
		"current_players": 1,
		"settings": mode_def.duplicate(),
		"created_at": Time.get_unix_time_from_system(),
	}
	
	_initialize_player_slots()
	
	# Add host to first slot
	_player_slots[0] = {
		"slot_index": 0,
		"peer_id": 1,
		"player_name": _get_local_player_name(),
		"is_host": true,
		"is_ready": true,  # Host is always ready
		"character_data": {},
		"team": 0,
		"empty": false,
	}
	
	_ready_players[1] = true
	_lobby_state = LobbyState.WAITING
	
	emit_signal("lobby_created", lobby_id, _current_lobby)
	emit_signal("player_slot_updated", 0, _player_slots[0])
	
	return {"success": true, "lobby_id": lobby_id, "lobby": _current_lobby}


func _generate_lobby_id() -> String:
	var chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var id := ""
	for i in range(6):
		id += chars[randi() % chars.length()]
	return id


# ============================================================================
# LOBBY JOINING
# ============================================================================

func join_lobby(lobby_id: String, password: String = "") -> Dictionary:
	if _lobby_state != LobbyState.IDLE:
		return {"success": false, "error": "Already in a lobby"}
	
	# Would connect to host and request join
	# For now, simulate joining via RPC
	_lobby_state = LobbyState.WAITING
	
	emit_signal("lobby_joined", lobby_id)
	
	return {"success": true}


func join_lobby_by_code(code: String, password: String = "") -> Dictionary:
	# Find lobby by code
	for lobby in _available_lobbies:
		if lobby["id"] == code:
			return join_lobby(code, password)
	
	return {"success": false, "error": "Lobby not found"}


func leave_lobby() -> void:
	if _lobby_state == LobbyState.IDLE:
		return
	
	var lobby_id: String = _current_lobby.get("id", "")
	
	if _is_host():
		# Host leaving closes the lobby
		_close_lobby("Host left")
	else:
		# Client leaving just removes from slot
		_rpc_leave_lobby.rpc_id(1)
	
	_reset_lobby_state()
	emit_signal("lobby_left", lobby_id)


func _close_lobby(reason: String) -> void:
	if not _is_host():
		return
	
	var lobby_id: String = _current_lobby.get("id", "")
	
	# Notify all clients
	_rpc_lobby_closed.rpc(reason)
	
	_reset_lobby_state()
	emit_signal("lobby_closed", lobby_id, reason)


func _reset_lobby_state() -> void:
	_current_lobby.clear()
	_initialize_player_slots()
	_ready_players.clear()
	_lobby_state = LobbyState.IDLE
	_game_start_countdown = 0
	_chat_history.clear()


# ============================================================================
# LOBBY RPCS
# ============================================================================

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_join(player_data: Dictionary, password: String) -> void:
	if not _is_host():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	
	# Validate join request
	var result := _validate_join_request(peer_id, password)
	
	if result["success"]:
		# Find empty slot
		var slot_index := _find_empty_slot()
		if slot_index == -1:
			_rpc_join_result.rpc_id(peer_id, false, "Lobby is full", {})
			return
		
		# Add player to slot
		_player_slots[slot_index] = {
			"slot_index": slot_index,
			"peer_id": peer_id,
			"player_name": player_data.get("name", "Player"),
			"is_host": false,
			"is_ready": false,
			"character_data": player_data.get("character", {}),
			"team": 0,
			"empty": false,
		}
		
		_ready_players[peer_id] = false
		_current_lobby["current_players"] += 1
		
		# Send success to joining player
		_rpc_join_result.rpc_id(peer_id, true, "", _get_lobby_state_for_sync())
		
		# Notify all players of slot update
		_rpc_slot_updated.rpc(slot_index, _player_slots[slot_index])
		
		emit_signal("player_slot_updated", slot_index, _player_slots[slot_index])
	else:
		_rpc_join_result.rpc_id(peer_id, false, result["error"], {})


func _validate_join_request(peer_id: int, password: String) -> Dictionary:
	if _lobby_state != LobbyState.WAITING:
		return {"success": false, "error": "Lobby not accepting players"}
	
	if _current_lobby["current_players"] >= _current_lobby["max_players"]:
		return {"success": false, "error": "Lobby is full"}
	
	if _current_lobby["password_protected"] and password != _current_lobby["password"]:
		return {"success": false, "error": "Invalid password"}
	
	return {"success": true}


@rpc("authority", "call_remote", "reliable")
func _rpc_join_result(success: bool, error: String, lobby_state: Dictionary) -> void:
	if success:
		_apply_lobby_state(lobby_state)
		emit_signal("lobby_joined", _current_lobby.get("id", ""))
	else:
		_reset_lobby_state()
		emit_signal("lobby_closed", "", error)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_leave_lobby() -> void:
	if not _is_host():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	_remove_player_from_slots(peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_lobby_closed(reason: String) -> void:
	var lobby_id: String = _current_lobby.get("id", "")
	_reset_lobby_state()
	emit_signal("lobby_closed", lobby_id, reason)


@rpc("authority", "call_remote", "reliable")
func _rpc_slot_updated(slot_index: int, slot_data: Dictionary) -> void:
	_player_slots[slot_index] = slot_data
	emit_signal("player_slot_updated", slot_index, slot_data)


@rpc("authority", "call_remote", "reliable")
func _rpc_lobby_state(state: Dictionary) -> void:
	_apply_lobby_state(state)
	emit_signal("lobby_updated", _current_lobby.get("id", ""), _current_lobby)


func _get_lobby_state_for_sync() -> Dictionary:
	return {
		"lobby": _current_lobby.duplicate(),
		"slots": _player_slots.duplicate(true),
		"ready_players": _ready_players.duplicate(),
	}


func _apply_lobby_state(state: Dictionary) -> void:
	_current_lobby = state.get("lobby", {})
	_player_slots = state.get("slots", [])
	_ready_players = state.get("ready_players", {})
	_lobby_state = LobbyState.WAITING


func _find_empty_slot() -> int:
	for i in range(_player_slots.size()):
		if _player_slots[i]["empty"]:
			return i
	return -1


func _remove_player_from_slots(peer_id: int) -> void:
	for i in range(_player_slots.size()):
		if _player_slots[i]["peer_id"] == peer_id:
			_player_slots[i] = {
				"slot_index": i,
				"peer_id": 0,
				"player_name": "",
				"is_host": false,
				"is_ready": false,
				"character_data": {},
				"team": 0,
				"empty": true,
			}
			
			_ready_players.erase(peer_id)
			_current_lobby["current_players"] -= 1
			
			# Notify all players
			_rpc_slot_updated.rpc(i, _player_slots[i])
			
			emit_signal("player_slot_updated", i, _player_slots[i])
			
			# Check if we need to cancel starting
			if _lobby_state == LobbyState.STARTING:
				_cancel_game_start()
			
			break


# ============================================================================
# READY SYSTEM
# ============================================================================

func set_ready(is_ready: bool) -> void:
	var local_peer: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	
	if _is_host():
		_update_ready_state(local_peer, is_ready)
	else:
		_rpc_set_ready.rpc_id(1, is_ready)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_set_ready(is_ready: bool) -> void:
	if not _is_host():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	_update_ready_state(peer_id, is_ready)


func _update_ready_state(peer_id: int, is_ready: bool) -> void:
	_ready_players[peer_id] = is_ready
	
	# Update slot
	for i in range(_player_slots.size()):
		if _player_slots[i]["peer_id"] == peer_id:
			_player_slots[i]["is_ready"] = is_ready
			_rpc_slot_updated.rpc(i, _player_slots[i])
			emit_signal("player_slot_updated", i, _player_slots[i])
			break
	
	emit_signal("player_ready_changed", peer_id, is_ready)
	
	# Check if all ready
	if _check_all_ready():
		emit_signal("all_players_ready")
		
		# Auto-start if enabled
		if _lobby_state == LobbyState.WAITING:
			start_countdown()


func _check_all_ready() -> bool:
	var ready_count: int = 0
	var player_count: int = 0
	
	for slot in _player_slots:
		if not slot["empty"]:
			player_count += 1
			if slot["is_ready"]:
				ready_count += 1
	
	return ready_count == player_count and player_count >= _current_lobby.get("min_players", 1)


# ============================================================================
# GAME START
# ============================================================================

func start_countdown() -> void:
	if not _is_host():
		return
	
	if _lobby_state != LobbyState.WAITING:
		return
	
	if not _check_all_ready():
		return
	
	_lobby_state = LobbyState.STARTING
	_game_start_countdown = GAME_START_COUNTDOWN
	_countdown_timer = 0.0
	
	_rpc_start_countdown.rpc(_game_start_countdown)
	emit_signal("game_starting", _game_start_countdown)


func cancel_countdown() -> void:
	if not _is_host():
		return
	
	_cancel_game_start()


func _cancel_game_start() -> void:
	_lobby_state = LobbyState.WAITING
	_game_start_countdown = 0
	
	_rpc_cancel_countdown.rpc()


@rpc("authority", "call_remote", "reliable")
func _rpc_start_countdown(countdown: int) -> void:
	_lobby_state = LobbyState.STARTING
	_game_start_countdown = countdown
	emit_signal("game_starting", countdown)


@rpc("authority", "call_remote", "reliable")
func _rpc_cancel_countdown() -> void:
	_lobby_state = LobbyState.WAITING
	_game_start_countdown = 0


func _start_game() -> void:
	_lobby_state = LobbyState.IN_GAME
	
	_rpc_game_started.rpc()
	emit_signal("game_started")


@rpc("authority", "call_remote", "reliable")
func _rpc_game_started() -> void:
	_lobby_state = LobbyState.IN_GAME
	emit_signal("game_started")


# ============================================================================
# MATCHMAKING
# ============================================================================

func start_matchmaking(preferences: Dictionary) -> void:
	if _matchmaking_state != MatchmakingState.IDLE:
		return
	
	_matchmaking_preferences = preferences
	_matchmaking_state = MatchmakingState.SEARCHING
	_matchmaking_timer = 0.0
	
	emit_signal("matchmaking_started")
	
	# Would send matchmaking request to master server
	# For now, simulate by searching local lobbies
	_search_for_match()


func cancel_matchmaking() -> void:
	if _matchmaking_state == MatchmakingState.IDLE:
		return
	
	_matchmaking_state = MatchmakingState.IDLE
	_matchmaking_timer = 0.0
	_matchmaking_preferences.clear()
	
	emit_signal("matchmaking_cancelled")


func _search_for_match() -> void:
	var game_mode: int = _matchmaking_preferences.get("game_mode", GameMode.COOP_SURVIVAL)
	
	for lobby in _available_lobbies:
		if lobby["game_mode"] == game_mode:
			if lobby["current_players"] < lobby["max_players"]:
				if not lobby["password_protected"]:
					_matchmaking_state = MatchmakingState.FOUND
					emit_signal("matchmaking_found", lobby["id"])
					return
	
	# No match found, would continue searching or create new lobby


# ============================================================================
# LOBBY BROWSER
# ============================================================================

func refresh_lobbies() -> void:
	_refresh_lobby_list()


func _refresh_lobby_list() -> void:
	# Would query master server for lobby list
	# For now, use local list
	emit_signal("lobby_list_updated", _available_lobbies)


func get_available_lobbies() -> Array:
	return _available_lobbies.duplicate()


func filter_lobbies(filters: Dictionary) -> Array:
	var filtered: Array = []
	
	for lobby in _available_lobbies:
		var matches := true
		
		if filters.has("game_mode") and lobby["game_mode"] != filters["game_mode"]:
			matches = false
		
		if filters.has("has_space") and filters["has_space"]:
			if lobby["current_players"] >= lobby["max_players"]:
				matches = false
		
		if filters.has("no_password") and filters["no_password"]:
			if lobby["password_protected"]:
				matches = false
		
		if matches:
			filtered.append(lobby)
	
	return filtered


# ============================================================================
# CHAT
# ============================================================================

func send_chat_message(message: String) -> void:
	if _lobby_state == LobbyState.IDLE:
		return
	
	var local_peer: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var player_name: String = _get_local_player_name()
	
	_add_chat_message(local_peer, player_name, message)
	
	if _is_host():
		_rpc_chat_message.rpc(local_peer, player_name, message)
	else:
		_rpc_send_chat.rpc_id(1, message)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_send_chat(message: String) -> void:
	if not _is_host():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	var player_name := _get_player_name(peer_id)
	
	_add_chat_message(peer_id, player_name, message)
	_rpc_chat_message.rpc(peer_id, player_name, message)


@rpc("authority", "call_remote", "reliable")
func _rpc_chat_message(sender_id: int, sender_name: String, message: String) -> void:
	_add_chat_message(sender_id, sender_name, message)


func _add_chat_message(sender_id: int, sender_name: String, message: String) -> void:
	var chat_entry := {
		"sender_id": sender_id,
		"sender_name": sender_name,
		"message": message,
		"timestamp": Time.get_unix_time_from_system(),
	}
	
	_chat_history.append(chat_entry)
	
	# Limit history size
	if _chat_history.size() > 100:
		_chat_history.pop_front()
	
	emit_signal("chat_message_received", sender_id, sender_name, message)


func get_chat_history() -> Array:
	return _chat_history.duplicate()


# ============================================================================
# PLAYER SLOT MANAGEMENT
# ============================================================================

func swap_slots(slot_a: int, slot_b: int) -> void:
	if not _is_host():
		return
	
	var temp: Dictionary = _player_slots[slot_a]
	_player_slots[slot_a] = _player_slots[slot_b]
	_player_slots[slot_b] = temp
	
	# Update slot indices
	_player_slots[slot_a]["slot_index"] = slot_a
	_player_slots[slot_b]["slot_index"] = slot_b
	
	_rpc_slot_updated.rpc(slot_a, _player_slots[slot_a])
	_rpc_slot_updated.rpc(slot_b, _player_slots[slot_b])


func set_player_team(peer_id: int, team: int) -> void:
	if not _is_host():
		return
	
	for i in range(_player_slots.size()):
		if _player_slots[i]["peer_id"] == peer_id:
			_player_slots[i]["team"] = team
			_rpc_slot_updated.rpc(i, _player_slots[i])
			break


func kick_from_lobby(peer_id: int) -> void:
	if not _is_host():
		return
	
	if peer_id == 1:
		return  # Can't kick host
	
	_remove_player_from_slots(peer_id)
	# NetworkManager would disconnect the peer


# ============================================================================
# LOBBY SETTINGS
# ============================================================================

func update_lobby_settings(settings: Dictionary) -> void:
	if not _is_host():
		return
	
	_current_lobby["settings"].merge(settings, true)
	
	_rpc_lobby_state.rpc(_get_lobby_state_for_sync())
	emit_signal("lobby_updated", _current_lobby.get("id", ""), _current_lobby)


func set_lobby_visibility(visibility: int) -> void:
	if not _is_host():
		return
	
	_current_lobby["visibility"] = visibility
	_rpc_lobby_state.rpc(_get_lobby_state_for_sync())


func set_max_players(max_players: int) -> void:
	if not _is_host():
		return
	
	max_players = clampi(max_players, 1, MAX_LOBBY_PLAYERS)
	_current_lobby["max_players"] = max_players
	_rpc_lobby_state.rpc(_get_lobby_state_for_sync())


# ============================================================================
# HELPERS
# ============================================================================

func _is_host() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()


func _get_local_player_name() -> String:
	# Would get from player profile
	return "Player"


func _get_player_name(peer_id: int) -> String:
	for slot in _player_slots:
		if slot["peer_id"] == peer_id:
			return slot["player_name"]
	return "Unknown"


# ============================================================================
# QUERIES
# ============================================================================

func get_current_lobby() -> Dictionary:
	return _current_lobby.duplicate()


func get_lobby_state() -> int:
	return _lobby_state


func get_player_slots() -> Array:
	return _player_slots.duplicate(true)


func get_player_count() -> int:
	return _current_lobby.get("current_players", 0)


func get_max_players() -> int:
	return _current_lobby.get("max_players", MAX_LOBBY_PLAYERS)


func is_in_lobby() -> bool:
	return _lobby_state != LobbyState.IDLE


func is_host() -> bool:
	return _is_host()


func is_all_ready() -> bool:
	return _check_all_ready()


func get_game_mode() -> int:
	return _current_lobby.get("game_mode", GameMode.COOP_SURVIVAL)


func get_game_mode_settings() -> Dictionary:
	return _current_lobby.get("settings", {})


func get_matchmaking_state() -> int:
	return _matchmaking_state


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"matchmaking_preferences": _matchmaking_preferences.duplicate(),
	}


func load_data(data: Dictionary) -> void:
	_matchmaking_preferences = data.get("matchmaking_preferences", {})
