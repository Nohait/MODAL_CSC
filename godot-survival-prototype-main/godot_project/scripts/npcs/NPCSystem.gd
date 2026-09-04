extends Node
class_name NPCSystemClass
## Manages all NPCs - spawning, AI behavior, dialogue, schedules, and interactions
## Handles NPC types, moods, needs, and relationships with the player

signal npc_spawned(npc_data: Dictionary)
signal npc_despawned(npc_id: String, reason: String)
signal npc_interaction_started(npc_id: String)
signal npc_interaction_ended(npc_id: String)
signal npc_dialogue_started(npc_id: String, dialogue_id: String)
signal npc_mood_changed(npc_id: String, old_mood: int, new_mood: int)
signal npc_relationship_changed(npc_id: String, old_value: int, new_value: int)
signal npc_quest_available(npc_id: String, quest_id: String)
signal npc_died(npc_id: String)

# ============================================================================
# NPC CONFIGURATION
# ============================================================================

enum NPCType {
	# Friendly
	SURVIVOR,
	TRADER,
	WANDERING_MERCHANT,
	MECHANIC,
	DOCTOR,
	SOLDIER,
	SCIENTIST,
	FARMER,
	CRAFTSMAN,
	SCOUT,
	
	# Neutral
	SCAVENGER,
	DRIFTER,
	REFUGEE,
	
	# Hostile
	BANDIT,
	RAIDER,
	CULTIST,
	DESERTER,
}

enum NPCMood {
	HOSTILE,
	ANGRY,
	WARY,
	NEUTRAL,
	FRIENDLY,
	GRATEFUL,
	LOYAL,
}

enum NPCState {
	IDLE,
	WALKING,
	WORKING,
	TRADING,
	TALKING,
	COMBAT,
	FLEEING,
	PATROLLING,
	SLEEPING,
	EATING,
	CRAFTING,
}

enum NPCSchedule {
	ALWAYS_AVAILABLE,
	DAY_ONLY,
	NIGHT_ONLY,
	WORKING_HOURS,
	CUSTOM,
}

const NPC_DEFINITIONS := {
	NPCType.SURVIVOR: {
		"display_name": "Survivor",
		"description": "A fellow survivor trying to make it in this world.",
		"base_health": 100,
		"base_mood": NPCMood.NEUTRAL,
		"hostile": false,
		"can_trade": false,
		"can_recruit": true,
		"dialogue_pool": "survivor_dialogue",
		"schedule": NPCSchedule.ALWAYS_AVAILABLE,
		"loot_table": "survivor_loot",
		"spawn_zones": ["green", "yellow"],
	},
	NPCType.TRADER: {
		"display_name": "Trader",
		"description": "A merchant dealing in various goods.",
		"base_health": 80,
		"base_mood": NPCMood.FRIENDLY,
		"hostile": false,
		"can_trade": true,
		"can_recruit": false,
		"trade_inventory": "trader_general",
		"dialogue_pool": "trader_dialogue",
		"schedule": NPCSchedule.DAY_ONLY,
		"protected": true,
		"spawn_zones": ["green", "yellow"],
	},
	NPCType.WANDERING_MERCHANT: {
		"display_name": "Wandering Merchant",
		"description": "A mysterious trader with rare goods.",
		"base_health": 100,
		"base_mood": NPCMood.NEUTRAL,
		"hostile": false,
		"can_trade": true,
		"can_recruit": false,
		"trade_inventory": "merchant_rare",
		"dialogue_pool": "merchant_dialogue",
		"schedule": NPCSchedule.CUSTOM,
		"rare_items": true,
		"spawn_zones": ["yellow", "red"],
	},
	NPCType.MECHANIC: {
		"display_name": "Mechanic",
		"description": "An expert in vehicle repairs and modifications.",
		"base_health": 100,
		"base_mood": NPCMood.NEUTRAL,
		"hostile": false,
		"can_trade": true,
		"can_recruit": true,
		"trade_inventory": "mechanic_parts",
		"services": ["repair_vehicle", "upgrade_vehicle"],
		"dialogue_pool": "mechanic_dialogue",
		"schedule": NPCSchedule.WORKING_HOURS,
		"spawn_zones": ["yellow"],
	},
	NPCType.DOCTOR: {
		"display_name": "Doctor",
		"description": "A medical professional who can heal injuries.",
		"base_health": 80,
		"base_mood": NPCMood.FRIENDLY,
		"hostile": false,
		"can_trade": true,
		"can_recruit": true,
		"trade_inventory": "medical_supplies",
		"services": ["heal", "cure_infection", "surgery"],
		"dialogue_pool": "doctor_dialogue",
		"schedule": NPCSchedule.ALWAYS_AVAILABLE,
		"spawn_zones": ["green", "yellow"],
	},
	NPCType.SOLDIER: {
		"display_name": "Soldier",
		"description": "A military survivor with combat training.",
		"base_health": 150,
		"base_mood": NPCMood.WARY,
		"hostile": false,
		"can_trade": true,
		"can_recruit": true,
		"trade_inventory": "military_goods",
		"dialogue_pool": "soldier_dialogue",
		"schedule": NPCSchedule.ALWAYS_AVAILABLE,
		"combat_capable": true,
		"spawn_zones": ["yellow", "red"],
	},
	NPCType.SCIENTIST: {
		"display_name": "Scientist",
		"description": "A researcher studying the outbreak.",
		"base_health": 70,
		"base_mood": NPCMood.NEUTRAL,
		"hostile": false,
		"can_trade": true,
		"can_recruit": true,
		"trade_inventory": "research_items",
		"services": ["analyze_sample", "craft_serum"],
		"dialogue_pool": "scientist_dialogue",
		"schedule": NPCSchedule.WORKING_HOURS,
		"quest_giver": true,
		"spawn_zones": ["yellow", "red"],
	},
	NPCType.FARMER: {
		"display_name": "Farmer",
		"description": "A survivor growing food to survive.",
		"base_health": 90,
		"base_mood": NPCMood.FRIENDLY,
		"hostile": false,
		"can_trade": true,
		"can_recruit": true,
		"trade_inventory": "farm_goods",
		"dialogue_pool": "farmer_dialogue",
		"schedule": NPCSchedule.DAY_ONLY,
		"spawn_zones": ["green"],
	},
	NPCType.CRAFTSMAN: {
		"display_name": "Craftsman",
		"description": "A skilled builder and crafter.",
		"base_health": 100,
		"base_mood": NPCMood.NEUTRAL,
		"hostile": false,
		"can_trade": true,
		"can_recruit": true,
		"trade_inventory": "crafting_materials",
		"services": ["craft_item", "repair_gear"],
		"dialogue_pool": "craftsman_dialogue",
		"schedule": NPCSchedule.WORKING_HOURS,
		"spawn_zones": ["green", "yellow"],
	},
	NPCType.SCOUT: {
		"display_name": "Scout",
		"description": "An explorer with knowledge of the area.",
		"base_health": 110,
		"base_mood": NPCMood.NEUTRAL,
		"hostile": false,
		"can_trade": true,
		"can_recruit": true,
		"trade_inventory": "exploration_gear",
		"services": ["reveal_map", "mark_locations"],
		"dialogue_pool": "scout_dialogue",
		"schedule": NPCSchedule.DAY_ONLY,
		"spawn_zones": ["green", "yellow", "red"],
	},
	NPCType.SCAVENGER: {
		"display_name": "Scavenger",
		"description": "A survivor who picks through ruins.",
		"base_health": 80,
		"base_mood": NPCMood.WARY,
		"hostile": false,
		"can_trade": true,
		"can_recruit": false,
		"trade_inventory": "scavenger_finds",
		"dialogue_pool": "scavenger_dialogue",
		"schedule": NPCSchedule.ALWAYS_AVAILABLE,
		"spawn_zones": ["yellow", "red"],
	},
	NPCType.BANDIT: {
		"display_name": "Bandit",
		"description": "A hostile survivor who takes what they want.",
		"base_health": 100,
		"base_mood": NPCMood.HOSTILE,
		"hostile": true,
		"can_trade": false,
		"can_recruit": false,
		"dialogue_pool": "bandit_dialogue",
		"schedule": NPCSchedule.ALWAYS_AVAILABLE,
		"loot_table": "bandit_loot",
		"combat_capable": true,
		"spawn_zones": ["yellow", "red"],
	},
	NPCType.RAIDER: {
		"display_name": "Raider",
		"description": "A violent survivor who lives by attacking others.",
		"base_health": 120,
		"base_mood": NPCMood.HOSTILE,
		"hostile": true,
		"can_trade": false,
		"can_recruit": false,
		"dialogue_pool": "raider_dialogue",
		"schedule": NPCSchedule.ALWAYS_AVAILABLE,
		"loot_table": "raider_loot",
		"combat_capable": true,
		"spawn_zones": ["red"],
	},
}


# ============================================================================
# DIALOGUE CONFIGURATION
# ============================================================================

const DIALOGUE_POOLS := {
	"survivor_dialogue": {
		"greetings": [
			"Hey there, fellow survivor.",
			"You made it this far? Impressive.",
			"Another day alive. That's something.",
			"Watch your back out there.",
		],
		"farewells": [
			"Stay safe out there.",
			"Good luck.",
			"Hope to see you again.",
		],
		"topics": {
			"situation": [
				"Things are getting worse every day.",
				"I heard there's a safe zone up north.",
				"The hordes are getting bigger.",
			],
			"trade": [
				"I don't have much, but maybe we can work something out.",
				"Got anything useful?",
			],
			"help": [
				"Could use some help if you're willing.",
				"There's something I need done...",
			],
		},
	},
	"trader_dialogue": {
		"greetings": [
			"Welcome! Take a look at my wares.",
			"Ah, a customer! What can I get you?",
			"Buying or selling today?",
		],
		"farewells": [
			"Come back anytime!",
			"Safe travels, and bring more goods next time!",
			"Pleasure doing business.",
		],
		"topics": {
			"prices": [
				"Fair prices, I assure you.",
				"Supply and demand, my friend.",
			],
			"special": [
				"Got something special in the back, if you're interested...",
				"Looking for rare items? I might have what you need.",
			],
		},
	},
	"bandit_dialogue": {
		"greetings": [
			"Give me everything you got!",
			"Wrong place to be, friend.",
			"This is our territory!",
		],
		"surrender": [
			"Alright, alright! I give up!",
			"Please, don't kill me!",
		],
	},
}


# ============================================================================
# STATE
# ============================================================================

var _npcs: Dictionary = {}  # npc_id -> npc data
var _npc_relationships: Dictionary = {}  # npc_id -> relationship value (-100 to 100)
var _npc_id_counter: int = 0
var _active_dialogues: Dictionary = {}  # npc_id -> dialogue state
var _current_time_of_day: float = 12.0  # 0-24 hours


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_update_npcs(delta)


# ============================================================================
# NPC SPAWNING
# ============================================================================

func spawn_npc(npc_type: int, position: Vector2, name: String = "") -> Dictionary:
	var definition: Dictionary = NPC_DEFINITIONS.get(npc_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown NPC type"}
	
	_npc_id_counter += 1
	var npc_id := "npc_%d" % _npc_id_counter
	
	var display_name: String = name if name != "" else _generate_npc_name(npc_type)
	
	var npc_data := {
		"id": npc_id,
		"type": npc_type,
		"type_name": NPCType.keys()[npc_type],
		"display_name": display_name,
		"description": definition.get("description", ""),
		"position": position,
		
		# Stats
		"health": definition.get("base_health", 100),
		"max_health": definition.get("base_health", 100),
		"mood": definition.get("base_mood", NPCMood.NEUTRAL),
		"state": NPCState.IDLE,
		
		# Behavior
		"hostile": definition.get("hostile", false),
		"can_trade": definition.get("can_trade", false),
		"can_recruit": definition.get("can_recruit", false),
		"protected": definition.get("protected", false),
		"combat_capable": definition.get("combat_capable", false),
		
		# Inventory/Services
		"trade_inventory": definition.get("trade_inventory", ""),
		"services": definition.get("services", []),
		
		# Dialogue
		"dialogue_pool": definition.get("dialogue_pool", ""),
		"dialogue_state": {},
		
		# Schedule
		"schedule": definition.get("schedule", NPCSchedule.ALWAYS_AVAILABLE),
		"available": true,
		
		# Quests
		"quest_giver": definition.get("quest_giver", false),
		"available_quests": [],
		
		# Faction
		"faction": "",
		
		# Metadata
		"spawned_at": Time.get_unix_time_from_system(),
		"interactions": 0,
		"last_interaction": 0.0,
	}
	
	_npcs[npc_id] = npc_data
	_npc_relationships[npc_id] = 0  # Start neutral
	
	emit_signal("npc_spawned", npc_data)
	
	return {"success": true, "npc_id": npc_id, "npc": npc_data}


func _generate_npc_name(npc_type: int) -> String:
	var first_names := ["Alex", "Jordan", "Sam", "Riley", "Casey", "Morgan", "Taylor", "Quinn", "Avery", "Jamie", "Marcus", "Elena", "Viktor", "Chen", "Rosa", "Dmitri"]
	var last_names := ["Smith", "Johnson", "Brown", "Williams", "Jones", "Davis", "Miller", "Wilson", "Moore", "Taylor", "Anderson", "Thomas", "Jackson", "White", "Harris"]
	
	var first: String = first_names[randi() % first_names.size()]
	
	# Some NPCs just use titles
	match npc_type:
		NPCType.TRADER:
			return "Trader " + first
		NPCType.DOCTOR:
			return "Dr. " + first
		NPCType.SOLDIER:
			return "Sgt. " + first
		NPCType.BANDIT, NPCType.RAIDER:
			return first
		_:
			return first + " " + last_names[randi() % last_names.size()]


func despawn_npc(npc_id: String, reason: String = "removed") -> void:
	if npc_id not in _npcs:
		return
	
	_npcs.erase(npc_id)
	_active_dialogues.erase(npc_id)
	
	emit_signal("npc_despawned", npc_id, reason)


# ============================================================================
# NPC UPDATE
# ============================================================================

func _update_npcs(delta: float) -> void:
	for npc_id in _npcs:
		var npc: Dictionary = _npcs[npc_id]
		
		# Update availability based on schedule
		_update_availability(npc)
		
		# Update AI state
		_update_npc_ai(npc, delta)


func _update_availability(npc: Dictionary) -> void:
	var schedule: int = npc.get("schedule", NPCSchedule.ALWAYS_AVAILABLE)
	
	match schedule:
		NPCSchedule.ALWAYS_AVAILABLE:
			npc["available"] = true
		NPCSchedule.DAY_ONLY:
			npc["available"] = _current_time_of_day >= 6.0 and _current_time_of_day < 20.0
		NPCSchedule.NIGHT_ONLY:
			npc["available"] = _current_time_of_day < 6.0 or _current_time_of_day >= 20.0
		NPCSchedule.WORKING_HOURS:
			npc["available"] = _current_time_of_day >= 8.0 and _current_time_of_day < 18.0


func _update_npc_ai(npc: Dictionary, _delta: float) -> void:
	if npc.get("state") == NPCState.TALKING or npc.get("state") == NPCState.TRADING:
		return  # Don't update AI during player interaction
	
	# Simple state machine
	match npc.get("state"):
		NPCState.IDLE:
			# Randomly transition to walking or working
			if randf() < 0.001:
				npc["state"] = NPCState.WALKING
		NPCState.WALKING:
			# Return to idle after a while
			if randf() < 0.01:
				npc["state"] = NPCState.IDLE


# ============================================================================
# NPC INTERACTION
# ============================================================================

func start_interaction(npc_id: String) -> Dictionary:
	if npc_id not in _npcs:
		return {"success": false, "error": "NPC not found"}
	
	var npc: Dictionary = _npcs[npc_id]
	
	if not npc.get("available", true):
		return {"success": false, "error": "NPC is not available right now"}
	
	if npc.get("hostile", false):
		return {"success": false, "error": "NPC is hostile", "hostile": true}
	
	npc["state"] = NPCState.TALKING
	npc["interactions"] += 1
	npc["last_interaction"] = Time.get_unix_time_from_system()
	
	emit_signal("npc_interaction_started", npc_id)
	
	var greeting := _get_dialogue(npc, "greetings")
	
	return {
		"success": true,
		"npc": npc,
		"greeting": greeting,
		"options": _get_interaction_options(npc),
	}


func end_interaction(npc_id: String) -> void:
	if npc_id not in _npcs:
		return
	
	var npc: Dictionary = _npcs[npc_id]
	npc["state"] = NPCState.IDLE
	
	_active_dialogues.erase(npc_id)
	
	emit_signal("npc_interaction_ended", npc_id)


func _get_interaction_options(npc: Dictionary) -> Array:
	var options: Array = []
	
	# Trade option
	if npc.get("can_trade", false):
		options.append({"id": "trade", "label": "Trade"})
	
	# Services
	for service in npc.get("services", []):
		match service:
			"repair_vehicle":
				options.append({"id": "repair_vehicle", "label": "Repair Vehicle"})
			"upgrade_vehicle":
				options.append({"id": "upgrade_vehicle", "label": "Upgrade Vehicle"})
			"heal":
				options.append({"id": "heal", "label": "Heal Me"})
			"cure_infection":
				options.append({"id": "cure_infection", "label": "Cure Infection"})
			"reveal_map":
				options.append({"id": "reveal_map", "label": "Show Me the Area"})
			"craft_item":
				options.append({"id": "craft_item", "label": "Craft Something"})
	
	# Quest option
	if npc.get("quest_giver", false) and not npc.get("available_quests", []).is_empty():
		options.append({"id": "quest", "label": "Any work available?"})
	
	# Recruit option
	if npc.get("can_recruit", false):
		options.append({"id": "recruit", "label": "Join me"})
	
	# Talk option (always available)
	options.append({"id": "talk", "label": "Talk"})
	
	# Leave option
	options.append({"id": "leave", "label": "Goodbye"})
	
	return options


func select_option(npc_id: String, option_id: String) -> Dictionary:
	if npc_id not in _npcs:
		return {"success": false, "error": "NPC not found"}
	
	var npc: Dictionary = _npcs[npc_id]
	
	match option_id:
		"trade":
			npc["state"] = NPCState.TRADING
			return {"success": true, "action": "open_trade", "inventory": npc.get("trade_inventory", "")}
		
		"heal":
			return _perform_service(npc, "heal")
		
		"cure_infection":
			return _perform_service(npc, "cure_infection")
		
		"repair_vehicle":
			return _perform_service(npc, "repair_vehicle")
		
		"reveal_map":
			return _perform_service(npc, "reveal_map")
		
		"quest":
			var quests: Array = npc.get("available_quests", [])
			if quests.is_empty():
				return {"success": true, "response": "Nothing right now. Check back later."}
			return {"success": true, "action": "show_quests", "quests": quests}
		
		"recruit":
			return _attempt_recruit(npc)
		
		"talk":
			var topic_response := _get_random_topic_dialogue(npc)
			return {"success": true, "response": topic_response}
		
		"leave":
			end_interaction(npc_id)
			var farewell := _get_dialogue(npc, "farewells")
			return {"success": true, "response": farewell, "ended": true}
		
		_:
			return {"success": false, "error": "Unknown option"}


func _perform_service(npc: Dictionary, service: String) -> Dictionary:
	# Service costs would be calculated here
	var costs := {
		"heal": {"coins": 50},
		"cure_infection": {"coins": 100, "antibiotics": 1},
		"repair_vehicle": {"coins": 75, "parts": 2},
		"reveal_map": {"coins": 25},
	}
	
	var cost: Dictionary = costs.get(service, {})
	
	# Would check player can afford here
	
	return {
		"success": true,
		"action": service,
		"cost": cost,
		"response": "Done. That'll cost you %s." % str(cost),
	}


func _attempt_recruit(npc: Dictionary) -> Dictionary:
	if not npc.get("can_recruit", false):
		return {"success": false, "response": "I'm not interested in joining you."}
	
	var relationship: int = _npc_relationships.get(npc["id"], 0)
	
	if relationship < 30:
		return {"success": false, "response": "I don't know you well enough for that."}
	
	# Would handle recruitment logic here
	return {
		"success": true,
		"action": "recruit",
		"response": "Alright, I'll come with you.",
	}


# ============================================================================
# DIALOGUE
# ============================================================================

func _get_dialogue(npc: Dictionary, category: String) -> String:
	var pool_name: String = npc.get("dialogue_pool", "")
	var pool: Dictionary = DIALOGUE_POOLS.get(pool_name, {})
	
	var lines: Array = pool.get(category, [])
	if lines.is_empty():
		return "..."
	
	return lines[randi() % lines.size()]


func _get_random_topic_dialogue(npc: Dictionary) -> String:
	var pool_name: String = npc.get("dialogue_pool", "")
	var pool: Dictionary = DIALOGUE_POOLS.get(pool_name, {})
	var topics: Dictionary = pool.get("topics", {})
	
	if topics.is_empty():
		return "I don't have much to say."
	
	var topic_keys: Array = topics.keys()
	var random_topic: String = topic_keys[randi() % topic_keys.size()]
	var lines: Array = topics[random_topic]
	
	if lines.is_empty():
		return "..."
	
	return lines[randi() % lines.size()]


# ============================================================================
# RELATIONSHIPS
# ============================================================================

func modify_relationship(npc_id: String, amount: int) -> void:
	if npc_id not in _npcs:
		return
	
	var old_value: int = _npc_relationships.get(npc_id, 0)
	var new_value: int = clampi(old_value + amount, -100, 100)
	
	_npc_relationships[npc_id] = new_value
	
	# Update mood based on relationship
	_update_mood_from_relationship(npc_id, new_value)
	
	emit_signal("npc_relationship_changed", npc_id, old_value, new_value)


func _update_mood_from_relationship(npc_id: String, relationship: int) -> void:
	if npc_id not in _npcs:
		return
	
	var npc: Dictionary = _npcs[npc_id]
	var old_mood: int = npc.get("mood", NPCMood.NEUTRAL)
	var new_mood: int
	
	if relationship >= 80:
		new_mood = NPCMood.LOYAL
	elif relationship >= 50:
		new_mood = NPCMood.GRATEFUL
	elif relationship >= 20:
		new_mood = NPCMood.FRIENDLY
	elif relationship >= -20:
		new_mood = NPCMood.NEUTRAL
	elif relationship >= -50:
		new_mood = NPCMood.WARY
	elif relationship >= -80:
		new_mood = NPCMood.ANGRY
	else:
		new_mood = NPCMood.HOSTILE
	
	if new_mood != old_mood:
		npc["mood"] = new_mood
		emit_signal("npc_mood_changed", npc_id, old_mood, new_mood)


func get_relationship(npc_id: String) -> int:
	return _npc_relationships.get(npc_id, 0)


# ============================================================================
# COMBAT
# ============================================================================

func damage_npc(npc_id: String, damage: float, source: String = "unknown") -> Dictionary:
	if npc_id not in _npcs:
		return {"success": false, "error": "NPC not found"}
	
	var npc: Dictionary = _npcs[npc_id]
	
	if npc.get("protected", false):
		return {"success": false, "error": "NPC is protected"}
	
	npc["health"] -= damage
	
	# Relationship penalty
	modify_relationship(npc_id, -20)
	
	if npc["health"] <= 0:
		_kill_npc(npc_id)
		return {"success": true, "killed": true}
	
	# Become hostile or flee
	if npc.get("combat_capable", false):
		npc["hostile"] = true
		npc["state"] = NPCState.COMBAT
	else:
		npc["state"] = NPCState.FLEEING
	
	return {"success": true, "killed": false, "health": npc["health"]}


func _kill_npc(npc_id: String) -> void:
	if npc_id not in _npcs:
		return
	
	emit_signal("npc_died", npc_id)
	despawn_npc(npc_id, "killed")


# ============================================================================
# QUESTS
# ============================================================================

func add_quest_to_npc(npc_id: String, quest_id: String) -> void:
	if npc_id not in _npcs:
		return
	
	var npc: Dictionary = _npcs[npc_id]
	var quests: Array = npc.get("available_quests", [])
	
	if quest_id not in quests:
		quests.append(quest_id)
		npc["available_quests"] = quests
		emit_signal("npc_quest_available", npc_id, quest_id)


func remove_quest_from_npc(npc_id: String, quest_id: String) -> void:
	if npc_id not in _npcs:
		return
	
	var npc: Dictionary = _npcs[npc_id]
	var quests: Array = npc.get("available_quests", [])
	quests.erase(quest_id)
	npc["available_quests"] = quests


# ============================================================================
# QUERIES
# ============================================================================

func get_npc(npc_id: String) -> Dictionary:
	return _npcs.get(npc_id, {})


func get_all_npcs() -> Array:
	return _npcs.values()


func get_npcs_by_type(npc_type: int) -> Array:
	var npcs: Array = []
	for npc in _npcs.values():
		if npc.get("type") == npc_type:
			npcs.append(npc)
	return npcs


func get_npcs_in_range(position: Vector2, radius: float) -> Array:
	var npcs: Array = []
	for npc in _npcs.values():
		var npc_pos: Vector2 = npc.get("position", Vector2.ZERO)
		if position.distance_to(npc_pos) <= radius:
			npcs.append(npc)
	return npcs


func get_nearest_npc(position: Vector2, npc_type: int = -1, friendly_only: bool = false) -> Dictionary:
	var nearest: Dictionary = {}
	var min_dist: float = INF
	
	for npc in _npcs.values():
		if npc_type >= 0 and npc.get("type") != npc_type:
			continue
		
		if friendly_only and npc.get("hostile", false):
			continue
		
		var dist: float = position.distance_to(npc.get("position", Vector2.ZERO))
		if dist < min_dist:
			min_dist = dist
			nearest = npc
	
	return nearest


func get_traders() -> Array:
	var traders: Array = []
	for npc in _npcs.values():
		if npc.get("can_trade", false):
			traders.append(npc)
	return traders


func set_time_of_day(hour: float) -> void:
	_current_time_of_day = fmod(hour, 24.0)


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var npcs_save: Dictionary = {}
	for npc_id in _npcs:
		var npc: Dictionary = _npcs[npc_id].duplicate(true)
		npc["position"] = {"x": npc["position"].x, "y": npc["position"].y}
		npcs_save[npc_id] = npc
	
	return {
		"npcs": npcs_save,
		"npc_relationships": _npc_relationships.duplicate(),
		"npc_id_counter": _npc_id_counter,
	}


func load_data(data: Dictionary) -> void:
	_npcs.clear()
	for npc_id in data.get("npcs", {}):
		var npc: Dictionary = data["npcs"][npc_id]
		if npc.has("position") and npc["position"] is Dictionary:
			npc["position"] = Vector2(npc["position"]["x"], npc["position"]["y"])
		_npcs[npc_id] = npc
	
	_npc_relationships = data.get("npc_relationships", {})
	_npc_id_counter = data.get("npc_id_counter", 0)
