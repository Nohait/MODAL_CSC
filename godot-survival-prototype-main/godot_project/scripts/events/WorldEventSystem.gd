extends Node
class_name WorldEventSystemClass
## Manages random world events like airdrops, trader caravans, meteor strikes
## Handles event spawning, timers, and rewards

signal world_event_started(event_data: Dictionary)
signal world_event_updated(event_id: String, update_type: String)
signal world_event_completed(event_id: String, rewards: Dictionary)
signal world_event_expired(event_id: String)
signal airdrop_incoming(position: Vector2)
signal airdrop_landed(position: Vector2, contents: Array)
signal trader_arrived(trader_data: Dictionary)
signal meteor_incoming(impact_zone: Vector2)
signal supply_run_available(location: Dictionary)
signal special_infected_spawned(enemy_data: Dictionary)

# ============================================================================
# EVENT CONFIGURATION
# ============================================================================

enum EventType {
	# Supply Events
	AIRDROP,
	SUPPLY_CONVOY,
	EMERGENCY_CACHE,
	MILITARY_SUPPLY,
	
	# NPC Events
	TRADER_CARAVAN,
	WANDERING_MERCHANT,
	SURVIVOR_RESCUE,
	BANDIT_AMBUSH,
	REFUGEE_CAMP,
	
	# Combat Events
	SPECIAL_INFECTED,
	MINI_BOSS_SPAWN,
	HORDE_MIGRATION,
	MILITARY_PATROL,
	
	# Environmental
	METEOR_SHOWER,
	RADIATION_STORM,
	SUPPLY_PLANE_CRASH,
	HELICOPTER_CRASH,
	
	# Exploration
	TREASURE_MAP,
	HIDDEN_BUNKER,
	ABANDONED_CONVOY,
	SECRET_STASH,
}

enum EventRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

const EVENT_DEFINITIONS := {
	EventType.AIRDROP: {
		"display_name": "Supply Airdrop",
		"description": "A supply plane is dropping cargo nearby!",
		"rarity": EventRarity.COMMON,
		"duration": 600.0,  # 10 minutes
		"warning_time": 30.0,
		"spawn_weight": 20,
		"min_day": 1,
		"zones": ["green", "yellow", "red"],
		"loot_table": "airdrop_supplies",
		"loot_count": {"min": 4, "max": 8},
		"attracts_zombies": true,
		"zombie_count": 5,
	},
	EventType.SUPPLY_CONVOY: {
		"display_name": "Supply Convoy",
		"description": "An abandoned supply convoy has been spotted.",
		"rarity": EventRarity.UNCOMMON,
		"duration": 900.0,
		"spawn_weight": 12,
		"min_day": 3,
		"zones": ["yellow", "red"],
		"loot_table": "convoy_supplies",
		"vehicle_count": 3,
		"guarded": true,
		"guard_type": "zombie_soldier",
		"guard_count": 8,
	},
	EventType.EMERGENCY_CACHE: {
		"display_name": "Emergency Cache",
		"description": "Emergency supplies have been located.",
		"rarity": EventRarity.COMMON,
		"duration": 1200.0,
		"spawn_weight": 15,
		"min_day": 1,
		"zones": ["green", "yellow"],
		"loot_table": "emergency_cache",
		"requires_tool": false,
	},
	EventType.MILITARY_SUPPLY: {
		"display_name": "Military Supply Drop",
		"description": "Military supplies incoming. High value, high danger.",
		"rarity": EventRarity.RARE,
		"duration": 480.0,
		"warning_time": 45.0,
		"spawn_weight": 5,
		"min_day": 10,
		"zones": ["red"],
		"loot_table": "military_supplies",
		"loot_count": {"min": 6, "max": 12},
		"attracts_zombies": true,
		"zombie_count": 15,
		"has_mini_boss": true,
	},
	EventType.TRADER_CARAVAN: {
		"display_name": "Trader Caravan",
		"description": "A wandering trader has set up camp nearby.",
		"rarity": EventRarity.UNCOMMON,
		"duration": 1800.0,  # 30 minutes
		"spawn_weight": 10,
		"min_day": 5,
		"zones": ["green", "yellow"],
		"trader_type": "caravan",
		"special_deals": true,
		"protected": true,
	},
	EventType.WANDERING_MERCHANT: {
		"display_name": "Wandering Merchant",
		"description": "A mysterious merchant appears.",
		"rarity": EventRarity.RARE,
		"duration": 900.0,
		"spawn_weight": 5,
		"min_day": 7,
		"zones": ["green", "yellow", "red"],
		"trader_type": "wandering",
		"sells_rare_items": true,
		"accepts_special_currency": true,
	},
	EventType.SURVIVOR_RESCUE: {
		"display_name": "Survivor in Distress",
		"description": "A survivor is calling for help!",
		"rarity": EventRarity.UNCOMMON,
		"duration": 600.0,
		"spawn_weight": 10,
		"min_day": 3,
		"zones": ["green", "yellow", "red"],
		"rescue_reward": "reputation",
		"potential_recruit": true,
		"surrounded_by_zombies": true,
		"zombie_count": 10,
	},
	EventType.BANDIT_AMBUSH: {
		"display_name": "Bandit Ambush",
		"description": "Bandits are targeting a location. Fight or avoid.",
		"rarity": EventRarity.UNCOMMON,
		"duration": 720.0,
		"spawn_weight": 8,
		"min_day": 5,
		"zones": ["yellow", "red"],
		"bandit_count": 6,
		"loot_on_clear": true,
		"loot_table": "bandit_stash",
	},
	EventType.SPECIAL_INFECTED: {
		"display_name": "Mutant Sighting",
		"description": "A dangerous mutant has been spotted!",
		"rarity": EventRarity.RARE,
		"duration": 900.0,
		"spawn_weight": 6,
		"min_day": 7,
		"zones": ["yellow", "red"],
		"enemy_type": "special_infected",
		"guaranteed_rare_drop": true,
	},
	EventType.MINI_BOSS_SPAWN: {
		"display_name": "Threat Detected",
		"description": "A powerful enemy is rampaging nearby.",
		"rarity": EventRarity.RARE,
		"duration": 1200.0,
		"spawn_weight": 4,
		"min_day": 10,
		"zones": ["red"],
		"boss_type": "mini",
		"loot_table": "mini_boss_loot",
	},
	EventType.HORDE_MIGRATION: {
		"display_name": "Horde Migration",
		"description": "A massive horde is moving through the area!",
		"rarity": EventRarity.UNCOMMON,
		"duration": 600.0,
		"spawn_weight": 8,
		"min_day": 4,
		"zones": ["green", "yellow", "red"],
		"horde_size": 30,
		"direction": "random",
		"avoid_recommended": true,
	},
	EventType.METEOR_SHOWER: {
		"display_name": "Meteor Shower",
		"description": "Meteors are falling from the sky!",
		"rarity": EventRarity.EPIC,
		"duration": 300.0,
		"warning_time": 60.0,
		"spawn_weight": 2,
		"min_day": 14,
		"zones": ["yellow", "red"],
		"meteor_count": 5,
		"contains_rare_materials": true,
		"impact_damage": 200,
	},
	EventType.RADIATION_STORM: {
		"display_name": "Radiation Storm",
		"description": "Dangerous radiation levels detected!",
		"rarity": EventRarity.UNCOMMON,
		"duration": 600.0,
		"warning_time": 30.0,
		"spawn_weight": 6,
		"min_day": 7,
		"zones": ["yellow", "red"],
		"radiation_dps": 5,
		"requires_protection": true,
		"spawns_mutants": true,
	},
	EventType.HELICOPTER_CRASH: {
		"display_name": "Helicopter Crash",
		"description": "A helicopter has crashed nearby!",
		"rarity": EventRarity.RARE,
		"duration": 1200.0,
		"spawn_weight": 4,
		"min_day": 8,
		"zones": ["yellow", "red"],
		"loot_table": "helicopter_crash",
		"military_grade": true,
		"fire_hazard": true,
		"attracts_zombies": true,
		"zombie_count": 12,
	},
	EventType.TREASURE_MAP: {
		"display_name": "Treasure Map Found",
		"description": "You found a map leading to hidden treasure!",
		"rarity": EventRarity.RARE,
		"duration": 3600.0,  # 1 hour
		"spawn_weight": 3,
		"min_day": 5,
		"zones": ["green", "yellow", "red"],
		"requires_digging": true,
		"loot_table": "buried_treasure",
		"high_value": true,
	},
	EventType.HIDDEN_BUNKER: {
		"display_name": "Hidden Bunker Entrance",
		"description": "An entrance to an unexplored bunker!",
		"rarity": EventRarity.EPIC,
		"duration": 1800.0,
		"spawn_weight": 2,
		"min_day": 12,
		"zones": ["red"],
		"dungeon_entrance": true,
		"guaranteed_blueprint": true,
	},
	EventType.ABANDONED_CONVOY: {
		"display_name": "Abandoned Convoy",
		"description": "Military vehicles left behind.",
		"rarity": EventRarity.UNCOMMON,
		"duration": 900.0,
		"spawn_weight": 8,
		"min_day": 6,
		"zones": ["yellow", "red"],
		"vehicle_lootable": true,
		"fuel_available": true,
		"loot_table": "military_convoy",
	},
}


# ============================================================================
# LOOT TABLES
# ============================================================================

const LOOT_TABLES := {
	"airdrop_supplies": {
		"items": [
			{"id": "food_ration", "weight": 20, "count": [2, 5]},
			{"id": "water_bottle", "weight": 20, "count": [2, 4]},
			{"id": "bandage", "weight": 15, "count": [3, 6]},
			{"id": "medkit", "weight": 8, "count": [1, 2]},
			{"id": "ammo_9mm", "weight": 12, "count": [20, 40]},
			{"id": "ammo_556", "weight": 8, "count": [15, 30]},
			{"id": "weapon_pistol", "weight": 5, "count": [1, 1]},
			{"id": "armor_vest", "weight": 3, "count": [1, 1]},
		],
	},
	"military_supplies": {
		"items": [
			{"id": "ammo_556", "weight": 20, "count": [30, 60]},
			{"id": "ammo_762", "weight": 15, "count": [20, 40]},
			{"id": "weapon_rifle", "weight": 8, "count": [1, 1]},
			{"id": "weapon_smg", "weight": 8, "count": [1, 1]},
			{"id": "grenade", "weight": 10, "count": [2, 4]},
			{"id": "armor_tactical", "weight": 5, "count": [1, 1]},
			{"id": "medkit_military", "weight": 10, "count": [2, 3]},
			{"id": "weapon_mod", "weight": 6, "count": [1, 2]},
			{"id": "blueprint_weapon", "weight": 3, "count": [1, 1]},
		],
	},
	"emergency_cache": {
		"items": [
			{"id": "food_canned", "weight": 25, "count": [2, 4]},
			{"id": "water_bottle", "weight": 25, "count": [2, 3]},
			{"id": "bandage", "weight": 20, "count": [2, 4]},
			{"id": "flashlight", "weight": 10, "count": [1, 1]},
			{"id": "rope", "weight": 10, "count": [1, 2]},
			{"id": "tools_basic", "weight": 5, "count": [1, 1]},
		],
	},
	"helicopter_crash": {
		"items": [
			{"id": "weapon_sniper", "weight": 5, "count": [1, 1]},
			{"id": "weapon_rifle", "weight": 10, "count": [1, 1]},
			{"id": "ammo_762", "weight": 15, "count": [20, 50]},
			{"id": "military_supplies", "weight": 20, "count": [1, 3]},
			{"id": "medkit_military", "weight": 15, "count": [1, 2]},
			{"id": "armor_tactical", "weight": 8, "count": [1, 1]},
			{"id": "fuel_can", "weight": 12, "count": [1, 2]},
			{"id": "rare_component", "weight": 5, "count": [1, 2]},
		],
	},
	"buried_treasure": {
		"items": [
			{"id": "gold_bar", "weight": 10, "count": [1, 3]},
			{"id": "rare_gem", "weight": 8, "count": [1, 2]},
			{"id": "old_coins", "weight": 20, "count": [5, 15]},
			{"id": "rare_blueprint", "weight": 5, "count": [1, 1]},
			{"id": "legendary_weapon", "weight": 2, "count": [1, 1]},
			{"id": "supply_crate", "weight": 25, "count": [1, 2]},
			{"id": "ancient_artifact", "weight": 3, "count": [1, 1]},
		],
	},
	"bandit_stash": {
		"items": [
			{"id": "weapon_pistol", "weight": 15, "count": [1, 1]},
			{"id": "ammo_mixed", "weight": 20, "count": [20, 50]},
			{"id": "stolen_goods", "weight": 25, "count": [2, 5]},
			{"id": "food_stolen", "weight": 20, "count": [3, 6]},
			{"id": "cash", "weight": 15, "count": [50, 200]},
			{"id": "weapon_melee", "weight": 10, "count": [1, 1]},
		],
	},
	"mini_boss_loot": {
		"items": [
			{"id": "rare_material", "weight": 25, "count": [2, 5]},
			{"id": "epic_weapon", "weight": 10, "count": [1, 1]},
			{"id": "armor_rare", "weight": 10, "count": [1, 1]},
			{"id": "special_ammo", "weight": 15, "count": [10, 25]},
			{"id": "mutant_sample", "weight": 20, "count": [1, 3]},
			{"id": "skill_book", "weight": 5, "count": [1, 1]},
		],
	},
}


# ============================================================================
# STATE
# ============================================================================

var _active_events: Dictionary = {}  # event_id -> event data
var _event_history: Array = []  # Recently completed/expired events
var _spawn_timers: Dictionary = {}  # event_type -> cooldown remaining
var _current_day: int = 1
var _base_spawn_interval: float = 300.0  # 5 minutes base
var _spawn_timer: float = 0.0
var _max_concurrent_events: int = 3


func _ready() -> void:
	_initialize_spawn_timers()


func _initialize_spawn_timers() -> void:
	for event_type in EventType.values():
		_spawn_timers[event_type] = 0.0


func _process(delta: float) -> void:
	_update_spawn_timer(delta)
	_update_active_events(delta)
	_update_event_cooldowns(delta)


# ============================================================================
# EVENT SPAWNING
# ============================================================================

func _update_spawn_timer(delta: float) -> void:
	_spawn_timer += delta
	
	if _spawn_timer >= _base_spawn_interval:
		_spawn_timer = 0.0
		_try_spawn_random_event()


func _try_spawn_random_event() -> void:
	if _active_events.size() >= _max_concurrent_events:
		return
	
	var available_events := _get_available_events()
	if available_events.is_empty():
		return
	
	var selected: int = _weighted_random_select(available_events)
	if selected >= 0:
		spawn_event(selected)


func _get_available_events() -> Array:
	var available: Array = []
	
	for event_type in EventType.values():
		var definition: Dictionary = EVENT_DEFINITIONS.get(event_type, {})
		
		# Check day requirement
		if _current_day < definition.get("min_day", 1):
			continue
		
		# Check cooldown
		if _spawn_timers.get(event_type, 0.0) > 0:
			continue
		
		# Check if already active
		var already_active := false
		for event in _active_events.values():
			if event.get("type", -1) == event_type:
				already_active = true
				break
		
		if already_active:
			continue
		
		available.append({
			"type": event_type,
			"weight": definition.get("spawn_weight", 10),
		})
	
	return available


func _weighted_random_select(items: Array) -> int:
	var total_weight: float = 0.0
	for item in items:
		total_weight += item.get("weight", 1.0)
	
	var roll: float = randf() * total_weight
	var current: float = 0.0
	
	for item in items:
		current += item.get("weight", 1.0)
		if roll <= current:
			return item.get("type", -1)
	
	return -1


func spawn_event(event_type: int, position: Vector2 = Vector2.ZERO, zone: String = "") -> Dictionary:
	var definition: Dictionary = EVENT_DEFINITIONS.get(event_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown event type"}
	
	var event_id := "event_%d_%d" % [event_type, randi()]
	
	# Determine position if not provided
	if position == Vector2.ZERO:
		position = _generate_random_position(zone if zone != "" else _pick_random_zone(definition))
	
	var event_data := {
		"id": event_id,
		"type": event_type,
		"type_name": EventType.keys()[event_type],
		"display_name": definition.get("display_name", "Unknown Event"),
		"description": definition.get("description", ""),
		"rarity": definition.get("rarity", EventRarity.COMMON),
		"position": position,
		"zone": zone,
		"duration": definition.get("duration", 600.0),
		"time_remaining": definition.get("duration", 600.0),
		"warning_time": definition.get("warning_time", 0.0),
		"state": "warning" if definition.has("warning_time") else "active",
		"started_at": Time.get_unix_time_from_system(),
		"interacted": false,
		"completed": false,
		"data": definition.duplicate(),
	}
	
	_active_events[event_id] = event_data
	
	# Set cooldown for this event type
	var cooldown := definition.get("duration", 600.0) * 2.0
	_spawn_timers[event_type] = cooldown
	
	emit_signal("world_event_started", event_data)
	_emit_specific_event_signal(event_data)
	
	return {"success": true, "event_id": event_id, "event": event_data}


func _pick_random_zone(definition: Dictionary) -> String:
	var zones: Array = definition.get("zones", ["green", "yellow", "red"])
	return zones[randi() % zones.size()]


func _generate_random_position(zone: String) -> Vector2:
	# Generate position based on zone
	var zone_ranges := {
		"green": {"x": [0, 2000], "y": [0, 2000]},
		"yellow": {"x": [2000, 5000], "y": [0, 3000]},
		"red": {"x": [5000, 8000], "y": [0, 4000]},
	}
	
	var zone_range: Dictionary = zone_ranges.get(zone, zone_ranges["green"])
	var x_range: Array = zone_range.get("x", [0, 2000])
	var y_range: Array = zone_range.get("y", [0, 2000])
	
	return Vector2(
		randf_range(x_range[0], x_range[1]),
		randf_range(y_range[0], y_range[1])
	)


func _emit_specific_event_signal(event_data: Dictionary) -> void:
	var event_type: int = event_data.get("type", -1)
	
	match event_type:
		EventType.AIRDROP, EventType.MILITARY_SUPPLY:
			emit_signal("airdrop_incoming", event_data.get("position", Vector2.ZERO))
		EventType.TRADER_CARAVAN, EventType.WANDERING_MERCHANT:
			emit_signal("trader_arrived", event_data)
		EventType.METEOR_SHOWER:
			emit_signal("meteor_incoming", event_data.get("position", Vector2.ZERO))
		EventType.SPECIAL_INFECTED, EventType.MINI_BOSS_SPAWN:
			emit_signal("special_infected_spawned", event_data)


# ============================================================================
# EVENT UPDATE
# ============================================================================

func _update_active_events(delta: float) -> void:
	var events_to_remove: Array = []
	
	for event_id in _active_events:
		var event: Dictionary = _active_events[event_id]
		
		# Handle warning phase
		if event.get("state", "active") == "warning":
			event["warning_time"] -= delta
			if event["warning_time"] <= 0:
				event["state"] = "active"
				emit_signal("world_event_updated", event_id, "activated")
				_activate_event(event)
			continue
		
		# Update duration
		event["time_remaining"] -= delta
		
		if event["time_remaining"] <= 0:
			if event.get("completed", false):
				_complete_event(event_id)
			else:
				_expire_event(event_id)
			events_to_remove.append(event_id)
	
	for event_id in events_to_remove:
		_active_events.erase(event_id)


func _activate_event(event: Dictionary) -> void:
	var event_type: int = event.get("type", -1)
	var position: Vector2 = event.get("position", Vector2.ZERO)
	
	match event_type:
		EventType.AIRDROP, EventType.MILITARY_SUPPLY:
			emit_signal("airdrop_landed", position, [])
		EventType.METEOR_SHOWER:
			# Spawn meteors
			var data: Dictionary = event.get("data", {})
			var meteor_count: int = data.get("meteor_count", 5)
			for i in range(meteor_count):
				var offset := Vector2(randf_range(-200, 200), randf_range(-200, 200))
				# Meteor impact logic would go here


func _update_event_cooldowns(delta: float) -> void:
	for event_type in _spawn_timers.keys():
		_spawn_timers[event_type] = maxf(_spawn_timers[event_type] - delta, 0.0)


# ============================================================================
# EVENT INTERACTION
# ============================================================================

func interact_with_event(event_id: String, interaction_type: String = "loot") -> Dictionary:
	if event_id not in _active_events:
		return {"success": false, "error": "Event not found"}
	
	var event: Dictionary = _active_events[event_id]
	
	if event.get("state", "active") != "active":
		return {"success": false, "error": "Event not yet active"}
	
	event["interacted"] = true
	
	match interaction_type:
		"loot":
			return _loot_event(event)
		"trade":
			return _start_trade(event)
		"rescue":
			return _rescue_survivor(event)
		"clear":
			return _clear_enemies(event)
		"explore":
			return _explore_event(event)
		_:
			return {"success": false, "error": "Unknown interaction type"}


func _loot_event(event: Dictionary) -> Dictionary:
	var data: Dictionary = event.get("data", {})
	var loot_table_name: String = data.get("loot_table", "")
	
	if loot_table_name == "":
		return {"success": false, "error": "No loot available"}
	
	var loot_table: Dictionary = LOOT_TABLES.get(loot_table_name, {})
	var loot_count_range: Dictionary = data.get("loot_count", {"min": 3, "max": 6})
	var loot_count: int = randi_range(loot_count_range.get("min", 3), loot_count_range.get("max", 6))
	
	var loot: Array = _generate_loot(loot_table, loot_count)
	
	event["completed"] = true
	
	return {"success": true, "loot": loot}


func _generate_loot(loot_table: Dictionary, count: int) -> Array:
	var items: Array = loot_table.get("items", [])
	if items.is_empty():
		return []
	
	var total_weight: float = 0.0
	for item in items:
		total_weight += item.get("weight", 1.0)
	
	var loot: Array = []
	
	for i in range(count):
		var roll: float = randf() * total_weight
		var current: float = 0.0
		
		for item in items:
			current += item.get("weight", 1.0)
			if roll <= current:
				var item_count_range: Array = item.get("count", [1, 1])
				var item_count: int = randi_range(item_count_range[0], item_count_range[1])
				loot.append({
					"id": item.get("id", "unknown"),
					"count": item_count,
				})
				break
	
	return loot


func _start_trade(event: Dictionary) -> Dictionary:
	var data: Dictionary = event.get("data", {})
	var trader_type: String = data.get("trader_type", "generic")
	
	return {
		"success": true,
		"action": "open_trade",
		"trader_type": trader_type,
		"special_deals": data.get("special_deals", false),
		"accepts_special": data.get("accepts_special_currency", false),
	}


func _rescue_survivor(event: Dictionary) -> Dictionary:
	var data: Dictionary = event.get("data", {})
	
	# Check if zombies cleared
	if data.get("surrounded_by_zombies", false) and not event.get("enemies_cleared", false):
		return {"success": false, "error": "Clear the zombies first!"}
	
	event["completed"] = true
	
	var rewards := {
		"reputation": randi_range(10, 30),
		"potential_recruit": data.get("potential_recruit", false),
	}
	
	return {"success": true, "rewards": rewards}


func _clear_enemies(event: Dictionary) -> Dictionary:
	event["enemies_cleared"] = true
	emit_signal("world_event_updated", event.get("id", ""), "enemies_cleared")
	return {"success": true, "message": "Enemies cleared"}


func _explore_event(event: Dictionary) -> Dictionary:
	var data: Dictionary = event.get("data", {})
	
	if data.get("dungeon_entrance", false):
		event["completed"] = true
		return {
			"success": true,
			"action": "enter_dungeon",
			"guaranteed_blueprint": data.get("guaranteed_blueprint", false),
		}
	
	return {"success": true, "action": "explore"}


# ============================================================================
# EVENT COMPLETION
# ============================================================================

func _complete_event(event_id: String) -> void:
	if event_id not in _active_events:
		return
	
	var event: Dictionary = _active_events[event_id]
	var rewards := _calculate_event_rewards(event)
	
	_event_history.append({
		"event_id": event_id,
		"type": event.get("type", -1),
		"completed": true,
		"time": Time.get_unix_time_from_system(),
	})
	
	# Keep history limited
	if _event_history.size() > 50:
		_event_history.pop_front()
	
	emit_signal("world_event_completed", event_id, rewards)


func _expire_event(event_id: String) -> void:
	if event_id not in _active_events:
		return
	
	var event: Dictionary = _active_events[event_id]
	
	_event_history.append({
		"event_id": event_id,
		"type": event.get("type", -1),
		"completed": false,
		"expired": true,
		"time": Time.get_unix_time_from_system(),
	})
	
	if _event_history.size() > 50:
		_event_history.pop_front()
	
	emit_signal("world_event_expired", event_id)


func _calculate_event_rewards(event: Dictionary) -> Dictionary:
	var rarity: int = event.get("rarity", EventRarity.COMMON)
	var base_xp := 50
	
	match rarity:
		EventRarity.COMMON:
			base_xp = 50
		EventRarity.UNCOMMON:
			base_xp = 100
		EventRarity.RARE:
			base_xp = 200
		EventRarity.EPIC:
			base_xp = 400
		EventRarity.LEGENDARY:
			base_xp = 800
	
	return {
		"xp": base_xp,
		"reputation": rarity * 5,
	}


# ============================================================================
# QUERIES
# ============================================================================

func get_active_events() -> Array:
	return _active_events.values()


func get_event(event_id: String) -> Dictionary:
	return _active_events.get(event_id, {})


func get_events_in_zone(zone: String) -> Array:
	var events: Array = []
	for event in _active_events.values():
		if event.get("zone", "") == zone:
			events.append(event)
	return events


func get_events_by_type(event_type: int) -> Array:
	var events: Array = []
	for event in _active_events.values():
		if event.get("type", -1) == event_type:
			events.append(event)
	return events


func get_nearest_event(position: Vector2) -> Dictionary:
	var nearest: Dictionary = {}
	var min_distance: float = INF
	
	for event in _active_events.values():
		var event_pos: Vector2 = event.get("position", Vector2.ZERO)
		var distance: float = position.distance_to(event_pos)
		if distance < min_distance:
			min_distance = distance
			nearest = event
	
	return nearest


func is_event_active(event_type: int) -> bool:
	for event in _active_events.values():
		if event.get("type", -1) == event_type:
			return true
	return false


func get_event_definition(event_type: int) -> Dictionary:
	return EVENT_DEFINITIONS.get(event_type, {}).duplicate()


func get_loot_table(table_name: String) -> Dictionary:
	return LOOT_TABLES.get(table_name, {}).duplicate()


# ============================================================================
# CONFIGURATION
# ============================================================================

func set_current_day(day: int) -> void:
	_current_day = day


func set_spawn_interval(interval: float) -> void:
	_base_spawn_interval = interval


func set_max_concurrent_events(max_events: int) -> void:
	_max_concurrent_events = max_events


func force_spawn_event(event_type: int, position: Vector2 = Vector2.ZERO) -> Dictionary:
	# Force spawn ignoring cooldowns
	return spawn_event(event_type, position)


func cancel_event(event_id: String) -> bool:
	if event_id not in _active_events:
		return false
	
	_active_events.erase(event_id)
	emit_signal("world_event_expired", event_id)
	return true


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var events_save: Dictionary = {}
	for event_id in _active_events:
		var event: Dictionary = _active_events[event_id].duplicate()
		event["position"] = {"x": event["position"].x, "y": event["position"].y}
		events_save[event_id] = event
	
	return {
		"active_events": events_save,
		"event_history": _event_history.duplicate(),
		"spawn_timers": _spawn_timers.duplicate(),
		"current_day": _current_day,
		"spawn_timer": _spawn_timer,
	}


func load_data(data: Dictionary) -> void:
	_active_events.clear()
	for event_id in data.get("active_events", {}):
		var event: Dictionary = data["active_events"][event_id]
		if event.has("position") and event["position"] is Dictionary:
			event["position"] = Vector2(event["position"]["x"], event["position"]["y"])
		_active_events[event_id] = event
	
	_event_history = data.get("event_history", [])
	_spawn_timers = data.get("spawn_timers", {})
	_current_day = data.get("current_day", 1)
	_spawn_timer = data.get("spawn_timer", 0.0)
	
	_initialize_spawn_timers()  # Ensure all event types have entries
