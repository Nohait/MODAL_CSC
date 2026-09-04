extends Node

## MultiplayerManager - Foundation for co-op and PvP gameplay
## Handles networking, parties, clans, trading, and raids

signal connected_to_server()
signal disconnected_from_server()
signal player_joined(player_id: int, player_data: Dictionary)
signal player_left(player_id: int)
signal party_updated(party_data: Dictionary)
signal clan_updated(clan_data: Dictionary)
signal trade_requested(from_player: int, offer: Dictionary)
signal trade_completed(with_player: int, received: Dictionary)
signal raid_started(attacker_clan: String)
signal raid_ended(result: String)
signal chat_message(player_id: int, message: String, channel: String)

const GameConfig = preload("res://scripts/core/GameConfig.gd")

# ============================================================================
# NETWORK STATE
# ============================================================================

enum NetworkState { OFFLINE, CONNECTING, CONNECTED, IN_GAME }

var network_state := NetworkState.OFFLINE
var peer: ENetMultiplayerPeer = null
var server_address := "127.0.0.1"
var server_port := 7777
var local_player_id := 0
var is_server := false

# ============================================================================
# PLAYER DATA
# ============================================================================

var connected_players := {}  # player_id -> player_data
var local_player_data := {
	"name": "Player",
	"level": 1,
	"clan": "",
	"party_id": "",
	"position": Vector3.ZERO,
	"zone": "base",
	"status": "online"  # online, away, busy, invisible
}

# ============================================================================
# PARTY SYSTEM
# ============================================================================

var current_party := {
	"id": "",
	"leader": 0,
	"members": [],
	"max_size": GameConfig.MAX_PARTY_SIZE,
	"settings": {
		"loot_share": "round_robin",  # round_robin, need_greed, free_for_all
		"xp_share": true,
		"auto_accept": false
	}
}

var party_invites := []  # List of pending party invites

# ============================================================================
# CLAN SYSTEM
# ============================================================================

var current_clan := {
	"id": "",
	"name": "",
	"tag": "",
	"leader": 0,
	"officers": [],
	"members": [],
	"max_size": GameConfig.MAX_CLAN_SIZE,
	"level": 1,
	"xp": 0,
	"bank": {},  # Shared resources
	"permissions": {
		"invite": ["leader", "officer"],
		"kick": ["leader", "officer"],
		"promote": ["leader"],
		"withdraw_bank": ["leader", "officer"],
		"start_raid": ["leader"]
	},
	"settings": {
		"auto_accept": false,
		"min_level_to_join": 1,
		"raid_protection": false
	}
}

var clan_invites := []

# ============================================================================
# TRADING SYSTEM
# ============================================================================

var active_trade := {
	"partner_id": 0,
	"my_offer": {},  # item_id -> quantity
	"their_offer": {},
	"my_confirmed": false,
	"their_confirmed": false,
	"locked": false
}

var trade_cooldowns := {}  # player_id -> timestamp

# ============================================================================
# RAID SYSTEM
# ============================================================================

var raid_state := {
	"active": false,
	"attacking": false,  # true if we're the attacker
	"opponent_clan": "",
	"start_time": 0.0,
	"time_remaining": 0.0,
	"objectives_completed": 0,
	"loot_collected": {}
}

var raid_cooldown := 0.0
var raid_protection_until := 0.0

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(delta: float) -> void:
	if network_state == NetworkState.IN_GAME:
		_sync_player_position()
		_update_raid_timer(delta)

# ============================================================================
# CONNECTION
# ============================================================================

func host_server(port: int = 7777, max_clients: int = 32) -> bool:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, max_clients)
	
	if error != OK:
		push_error("Failed to create server: " + str(error))
		return false
	
	multiplayer.multiplayer_peer = peer
	is_server = true
	network_state = NetworkState.CONNECTED
	local_player_id = 1
	
	# Add self to connected players
	connected_players[local_player_id] = local_player_data.duplicate()
	
	print("Server started on port ", port)
	return true

func join_server(address: String = "127.0.0.1", port: int = 7777) -> bool:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	
	if error != OK:
		push_error("Failed to connect to server: " + str(error))
		return false
	
	multiplayer.multiplayer_peer = peer
	is_server = false
	network_state = NetworkState.CONNECTING
	server_address = address
	server_port = port
	
	print("Connecting to ", address, ":", port)
	return true

func disconnect_from_server() -> void:
	if peer:
		peer.close()
		peer = null
	
	multiplayer.multiplayer_peer = null
	network_state = NetworkState.OFFLINE
	connected_players.clear()
	_reset_party()
	_reset_trade()
	emit_signal("disconnected_from_server")

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	if is_server:
		# Send current state to new player
		rpc_id(id, "_receive_server_state", _get_server_state())

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	
	if connected_players.has(id):
		emit_signal("player_left", id)
		connected_players.erase(id)
	
	# Handle party member leaving
	if id in current_party["members"]:
		_remove_from_party(id)
	
	# Handle active trade cancellation
	if active_trade["partner_id"] == id:
		_cancel_trade()

func _on_connected_to_server() -> void:
	print("Connected to server")
	network_state = NetworkState.CONNECTED
	local_player_id = multiplayer.get_unique_id()
	emit_signal("connected_to_server")
	
	# Send our player data to server
	rpc("_register_player", local_player_data)

func _on_connection_failed() -> void:
	print("Connection failed")
	network_state = NetworkState.OFFLINE
	peer = null

func _on_server_disconnected() -> void:
	print("Server disconnected")
	disconnect_from_server()

# ============================================================================
# PLAYER SYNC
# ============================================================================

@rpc("any_peer", "reliable")
func _register_player(player_data: Dictionary) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	connected_players[sender_id] = player_data
	emit_signal("player_joined", sender_id, player_data)
	
	if is_server:
		# Broadcast to all other players
		for player_id in connected_players:
			if player_id != sender_id and player_id != 1:
				rpc_id(player_id, "_player_joined", sender_id, player_data)

@rpc("authority", "reliable")
func _receive_server_state(state: Dictionary) -> void:
	connected_players = state.get("players", {})
	# Additional state sync...

@rpc("authority", "reliable")
func _player_joined(player_id: int, player_data: Dictionary) -> void:
	connected_players[player_id] = player_data
	emit_signal("player_joined", player_id, player_data)

func _get_server_state() -> Dictionary:
	return {
		"players": connected_players,
		# Add more state as needed
	}

func _sync_player_position() -> void:
	if network_state != NetworkState.IN_GAME:
		return
	
	# This would be called regularly to sync position
	# Using unreliable for performance
	# rpc("_update_position", local_player_data["position"], local_player_data["zone"])

@rpc("any_peer", "unreliable")
func _update_position(position: Vector3, zone: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if connected_players.has(sender_id):
		connected_players[sender_id]["position"] = position
		connected_players[sender_id]["zone"] = zone

# ============================================================================
# PARTY SYSTEM
# ============================================================================

func create_party() -> bool:
	if current_party["id"] != "":
		push_warning("Already in a party")
		return false
	
	current_party["id"] = str(local_player_id) + "_" + str(Time.get_unix_time_from_system())
	current_party["leader"] = local_player_id
	current_party["members"] = [local_player_id]
	
	emit_signal("party_updated", current_party)
	return true

func invite_to_party(player_id: int) -> bool:
	if current_party["id"] == "":
		create_party()
	
	if current_party["leader"] != local_player_id:
		push_warning("Only party leader can invite")
		return false
	
	if current_party["members"].size() >= current_party["max_size"]:
		push_warning("Party is full")
		return false
	
	rpc_id(player_id, "_receive_party_invite", current_party["id"], local_player_id)
	return true

@rpc("any_peer", "reliable")
func _receive_party_invite(party_id: String, from_player: int) -> void:
	party_invites.append({
		"party_id": party_id,
		"from": from_player,
		"timestamp": Time.get_unix_time_from_system()
	})

func accept_party_invite(party_id: String) -> void:
	var invite: Dictionary = {}
	for inv in party_invites:
		if inv["party_id"] == party_id:
			invite = inv
			break
	
	if invite.is_empty():
		push_warning("Invite not found")
		return
	
	party_invites.erase(invite)
	rpc_id(invite["from"], "_party_invite_accepted", local_player_id)

func decline_party_invite(party_id: String) -> void:
	for inv in party_invites:
		if inv["party_id"] == party_id:
			party_invites.erase(inv)
			break

@rpc("any_peer", "reliable")
func _party_invite_accepted(player_id: int) -> void:
	if current_party["leader"] != local_player_id:
		return
	
	if current_party["members"].size() >= current_party["max_size"]:
		return
	
	current_party["members"].append(player_id)
	
	# Sync party state to all members
	for member_id in current_party["members"]:
		rpc_id(member_id, "_sync_party", current_party)
	
	emit_signal("party_updated", current_party)

@rpc("any_peer", "reliable")
func _sync_party(party_data: Dictionary) -> void:
	current_party = party_data
	emit_signal("party_updated", current_party)

func leave_party() -> void:
	if current_party["id"] == "":
		return
	
	var was_leader := current_party["leader"] == local_player_id
	
	# Notify other members
	for member_id in current_party["members"]:
		if member_id != local_player_id:
			rpc_id(member_id, "_party_member_left", local_player_id)
	
	_reset_party()
	emit_signal("party_updated", current_party)

@rpc("any_peer", "reliable")
func _party_member_left(player_id: int) -> void:
	_remove_from_party(player_id)

func _remove_from_party(player_id: int) -> void:
	current_party["members"].erase(player_id)
	
	# If leader left, promote next member
	if current_party["leader"] == player_id and current_party["members"].size() > 0:
		current_party["leader"] = current_party["members"][0]
	
	# Disband if empty
	if current_party["members"].size() == 0:
		_reset_party()
	
	emit_signal("party_updated", current_party)

func _reset_party() -> void:
	current_party["id"] = ""
	current_party["leader"] = 0
	current_party["members"] = []

func kick_from_party(player_id: int) -> bool:
	if current_party["leader"] != local_player_id:
		push_warning("Only leader can kick")
		return false
	
	if player_id not in current_party["members"]:
		return false
	
	rpc_id(player_id, "_kicked_from_party")
	_remove_from_party(player_id)
	
	# Sync to remaining members
	for member_id in current_party["members"]:
		rpc_id(member_id, "_sync_party", current_party)
	
	return true

@rpc("authority", "reliable")
func _kicked_from_party() -> void:
	_reset_party()
	emit_signal("party_updated", current_party)

# ============================================================================
# TRADING SYSTEM
# ============================================================================

func request_trade(player_id: int) -> bool:
	# Check cooldown
	if trade_cooldowns.has(player_id):
		var elapsed := Time.get_unix_time_from_system() - trade_cooldowns[player_id]
		if elapsed < GameConfig.TRADE_COOLDOWN_SECONDS:
			push_warning("Trade on cooldown")
			return false
	
	if active_trade["partner_id"] != 0:
		push_warning("Already in a trade")
		return false
	
	rpc_id(player_id, "_receive_trade_request", local_player_id)
	return true

@rpc("any_peer", "reliable")
func _receive_trade_request(from_player: int) -> void:
	emit_signal("trade_requested", from_player, {})

func accept_trade(player_id: int) -> void:
	active_trade["partner_id"] = player_id
	active_trade["my_offer"] = {}
	active_trade["their_offer"] = {}
	active_trade["my_confirmed"] = false
	active_trade["their_confirmed"] = false
	active_trade["locked"] = false
	
	rpc_id(player_id, "_trade_accepted", local_player_id)

@rpc("any_peer", "reliable")
func _trade_accepted(player_id: int) -> void:
	active_trade["partner_id"] = player_id
	active_trade["my_offer"] = {}
	active_trade["their_offer"] = {}
	active_trade["my_confirmed"] = false
	active_trade["their_confirmed"] = false
	active_trade["locked"] = false

func update_trade_offer(items: Dictionary) -> void:
	if active_trade["partner_id"] == 0:
		return
	
	if active_trade["locked"]:
		return
	
	active_trade["my_offer"] = items
	active_trade["my_confirmed"] = false
	active_trade["their_confirmed"] = false
	
	rpc_id(active_trade["partner_id"], "_receive_trade_offer", items)

@rpc("any_peer", "reliable")
func _receive_trade_offer(items: Dictionary) -> void:
	active_trade["their_offer"] = items
	active_trade["my_confirmed"] = false
	active_trade["their_confirmed"] = false

func confirm_trade() -> void:
	if active_trade["partner_id"] == 0:
		return
	
	active_trade["my_confirmed"] = true
	rpc_id(active_trade["partner_id"], "_trade_confirmed")
	
	_check_trade_completion()

@rpc("any_peer", "reliable")
func _trade_confirmed() -> void:
	active_trade["their_confirmed"] = true
	_check_trade_completion()

func _check_trade_completion() -> void:
	if active_trade["my_confirmed"] and active_trade["their_confirmed"]:
		_complete_trade()

func _complete_trade() -> void:
	# Here we would actually exchange items
	# This would connect to the inventory system
	
	var received := active_trade["their_offer"].duplicate()
	var partner := active_trade["partner_id"]
	
	trade_cooldowns[partner] = Time.get_unix_time_from_system()
	
	emit_signal("trade_completed", partner, received)
	_reset_trade()

func cancel_trade() -> void:
	if active_trade["partner_id"] != 0:
		rpc_id(active_trade["partner_id"], "_trade_cancelled")
	_cancel_trade()

@rpc("any_peer", "reliable")
func _trade_cancelled() -> void:
	_cancel_trade()

func _cancel_trade() -> void:
	_reset_trade()

func _reset_trade() -> void:
	active_trade["partner_id"] = 0
	active_trade["my_offer"] = {}
	active_trade["their_offer"] = {}
	active_trade["my_confirmed"] = false
	active_trade["their_confirmed"] = false
	active_trade["locked"] = false

# ============================================================================
# CLAN SYSTEM
# ============================================================================

func create_clan(name: String, tag: String) -> bool:
	if current_clan["id"] != "":
		push_warning("Already in a clan")
		return false
	
	if name.length() < 3 or name.length() > 24:
		push_warning("Clan name must be 3-24 characters")
		return false
	
	if tag.length() < 2 or tag.length() > 5:
		push_warning("Clan tag must be 2-5 characters")
		return false
	
	current_clan["id"] = str(local_player_id) + "_" + str(Time.get_unix_time_from_system())
	current_clan["name"] = name
	current_clan["tag"] = tag
	current_clan["leader"] = local_player_id
	current_clan["members"] = [local_player_id]
	current_clan["officers"] = []
	
	local_player_data["clan"] = current_clan["id"]
	
	emit_signal("clan_updated", current_clan)
	
	# Sync to server
	if not is_server:
		rpc("_register_clan", current_clan)
	
	return true

@rpc("any_peer", "reliable")
func _register_clan(clan_data: Dictionary) -> void:
	# Server would validate and store clan
	pass

func invite_to_clan(player_id: int) -> bool:
	if current_clan["id"] == "":
		push_warning("Not in a clan")
		return false
	
	var role := _get_clan_role(local_player_id)
	if role not in current_clan["permissions"]["invite"]:
		push_warning("No permission to invite")
		return false
	
	if current_clan["members"].size() >= current_clan["max_size"]:
		push_warning("Clan is full")
		return false
	
	rpc_id(player_id, "_receive_clan_invite", current_clan["id"], current_clan["name"], local_player_id)
	return true

@rpc("any_peer", "reliable")
func _receive_clan_invite(clan_id: String, clan_name: String, from_player: int) -> void:
	clan_invites.append({
		"clan_id": clan_id,
		"clan_name": clan_name,
		"from": from_player,
		"timestamp": Time.get_unix_time_from_system()
	})

func accept_clan_invite(clan_id: String) -> void:
	var invite: Dictionary = {}
	for inv in clan_invites:
		if inv["clan_id"] == clan_id:
			invite = inv
			break
	
	if invite.is_empty():
		return
	
	clan_invites.erase(invite)
	rpc_id(invite["from"], "_clan_invite_accepted", local_player_id)

@rpc("any_peer", "reliable")
func _clan_invite_accepted(player_id: int) -> void:
	if current_clan["members"].size() >= current_clan["max_size"]:
		return
	
	current_clan["members"].append(player_id)
	
	# Sync to all clan members
	for member_id in current_clan["members"]:
		rpc_id(member_id, "_sync_clan", current_clan)
	
	emit_signal("clan_updated", current_clan)

@rpc("any_peer", "reliable")
func _sync_clan(clan_data: Dictionary) -> void:
	current_clan = clan_data
	local_player_data["clan"] = current_clan["id"]
	emit_signal("clan_updated", current_clan)

func leave_clan() -> void:
	if current_clan["id"] == "":
		return
	
	# Can't leave if you're the only leader
	if current_clan["leader"] == local_player_id and current_clan["officers"].size() == 0:
		if current_clan["members"].size() > 1:
			push_warning("Must promote someone before leaving")
			return
	
	for member_id in current_clan["members"]:
		if member_id != local_player_id:
			rpc_id(member_id, "_clan_member_left", local_player_id)
	
	_reset_clan()
	emit_signal("clan_updated", current_clan)

@rpc("any_peer", "reliable")
func _clan_member_left(player_id: int) -> void:
	current_clan["members"].erase(player_id)
	current_clan["officers"].erase(player_id)
	
	if current_clan["leader"] == player_id:
		# Promote first officer, or first member
		if current_clan["officers"].size() > 0:
			current_clan["leader"] = current_clan["officers"][0]
			current_clan["officers"].erase(current_clan["leader"])
		elif current_clan["members"].size() > 0:
			current_clan["leader"] = current_clan["members"][0]
	
	emit_signal("clan_updated", current_clan)

func _reset_clan() -> void:
	current_clan["id"] = ""
	current_clan["name"] = ""
	current_clan["tag"] = ""
	current_clan["leader"] = 0
	current_clan["officers"] = []
	current_clan["members"] = []
	local_player_data["clan"] = ""

func _get_clan_role(player_id: int) -> String:
	if player_id == current_clan["leader"]:
		return "leader"
	if player_id in current_clan["officers"]:
		return "officer"
	if player_id in current_clan["members"]:
		return "member"
	return ""

func promote_to_officer(player_id: int) -> bool:
	if current_clan["leader"] != local_player_id:
		return false
	
	if player_id not in current_clan["members"]:
		return false
	
	if player_id in current_clan["officers"]:
		return false
	
	current_clan["officers"].append(player_id)
	
	for member_id in current_clan["members"]:
		rpc_id(member_id, "_sync_clan", current_clan)
	
	return true

func demote_from_officer(player_id: int) -> bool:
	if current_clan["leader"] != local_player_id:
		return false
	
	current_clan["officers"].erase(player_id)
	
	for member_id in current_clan["members"]:
		rpc_id(member_id, "_sync_clan", current_clan)
	
	return true

# ============================================================================
# RAID SYSTEM
# ============================================================================

func start_raid(target_clan_id: String) -> bool:
	if current_clan["id"] == "":
		push_warning("Must be in a clan to raid")
		return false
	
	if current_clan["leader"] != local_player_id:
		push_warning("Only clan leader can start raids")
		return false
	
	if raid_cooldown > 0:
		push_warning("Raid on cooldown")
		return false
	
	if raid_state["active"]:
		push_warning("Already in a raid")
		return false
	
	raid_state["active"] = true
	raid_state["attacking"] = true
	raid_state["opponent_clan"] = target_clan_id
	raid_state["start_time"] = Time.get_unix_time_from_system()
	raid_state["time_remaining"] = 1800.0  # 30 minutes
	raid_state["objectives_completed"] = 0
	raid_state["loot_collected"] = {}
	
	# Notify server and target clan
	rpc("_raid_initiated", current_clan["id"], target_clan_id)
	
	emit_signal("raid_started", target_clan_id)
	return true

@rpc("any_peer", "reliable")
func _raid_initiated(attacker_clan: String, defender_clan: String) -> void:
	if local_player_data["clan"] == defender_clan:
		raid_state["active"] = true
		raid_state["attacking"] = false
		raid_state["opponent_clan"] = attacker_clan
		raid_state["start_time"] = Time.get_unix_time_from_system()
		raid_state["time_remaining"] = 1800.0
		
		emit_signal("raid_started", attacker_clan)

func _update_raid_timer(delta: float) -> void:
	if not raid_state["active"]:
		return
	
	raid_state["time_remaining"] -= delta
	
	if raid_state["time_remaining"] <= 0:
		_end_raid("timeout")

func _end_raid(result: String) -> void:
	if raid_state["attacking"]:
		raid_cooldown = GameConfig.RAID_COOLDOWN_HOURS * 3600
	else:
		raid_protection_until = Time.get_unix_time_from_system() + GameConfig.RAID_PROTECTION_HOURS * 3600
	
	raid_state["active"] = false
	emit_signal("raid_ended", result)
	
	rpc("_raid_ended", result)

@rpc("any_peer", "reliable")
func _raid_ended(result: String) -> void:
	raid_state["active"] = false
	emit_signal("raid_ended", result)

# ============================================================================
# CHAT
# ============================================================================

func send_chat_message(message: String, channel: String = "global") -> void:
	if message.strip_edges() == "":
		return
	
	# Sanitize message
	message = message.substr(0, 256)  # Limit length
	
	match channel:
		"global":
			rpc("_receive_chat", local_player_id, message, channel)
		"party":
			for member_id in current_party["members"]:
				rpc_id(member_id, "_receive_chat", local_player_id, message, channel)
		"clan":
			for member_id in current_clan["members"]:
				rpc_id(member_id, "_receive_chat", local_player_id, message, channel)
		"whisper":
			# Would need target player id
			pass

@rpc("any_peer", "reliable")
func _receive_chat(player_id: int, message: String, channel: String) -> void:
	emit_signal("chat_message", player_id, message, channel)

# ============================================================================
# QUERIES
# ============================================================================

func get_players_in_zone(zone: String) -> Array:
	var players := []
	for player_id in connected_players:
		if connected_players[player_id].get("zone", "") == zone:
			players.append(player_id)
	return players

func get_party_members() -> Array:
	return current_party["members"].duplicate()

func get_clan_members() -> Array:
	return current_clan["members"].duplicate()

func is_in_party() -> bool:
	return current_party["id"] != ""

func is_in_clan() -> bool:
	return current_clan["id"] != ""

func is_party_leader() -> bool:
	return current_party["leader"] == local_player_id

func is_clan_leader() -> bool:
	return current_clan["leader"] == local_player_id

func can_be_raided() -> bool:
	if not is_in_clan():
		return false
	if raid_protection_until > Time.get_unix_time_from_system():
		return false
	return true

# ============================================================================
# SAVE/LOAD
# ============================================================================

func get_save_data() -> Dictionary:
	return {
		"player_data": local_player_data,
		"clan": current_clan if current_clan["id"] != "" else {},
		"raid_cooldown": raid_cooldown,
		"raid_protection_until": raid_protection_until
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("player_data"):
		local_player_data.merge(data["player_data"], true)
	if data.has("clan") and data["clan"].has("id"):
		current_clan = data["clan"]
	raid_cooldown = data.get("raid_cooldown", 0.0)
	raid_protection_until = data.get("raid_protection_until", 0.0)
