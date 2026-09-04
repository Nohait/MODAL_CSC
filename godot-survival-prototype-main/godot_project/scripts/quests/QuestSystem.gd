extends Node

## QuestSystem - Dynamic quest and event system for engaging gameplay
## Daily/weekly quests, random events, and story progression

signal quest_added(quest_id: String)
signal quest_updated(quest_id: String, progress: Dictionary)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal quest_failed(quest_id: String)
signal event_started(event_id: String)
signal event_ended(event_id: String)

const GameConfig = preload("res://scripts/core/GameConfig.gd")

# ============================================================================
# QUEST DEFINITIONS
# ============================================================================

const QUEST_TEMPLATES := {
	# Daily quests
	"daily_kill_zombies": {
		"name": "Clear the Area",
		"description": "Kill {target} zombies",
		"type": "daily",
		"objectives": [
			{"type": "kill", "target": "zombie", "amount": 10, "variable": true}
		],
		"rewards": {"xp": 100, "loot_category": "consumables", "loot_quality": "uncommon"},
		"difficulty_scaling": true
	},
	"daily_gather_resources": {
		"name": "Resource Run",
		"description": "Gather {target} resources",
		"type": "daily",
		"objectives": [
			{"type": "gather", "target": "any", "amount": 25, "variable": true}
		],
		"rewards": {"xp": 80, "loot_category": "resources", "loot_quality": "uncommon"},
		"difficulty_scaling": true
	},
	"daily_craft_items": {
		"name": "Workshop Duty",
		"description": "Craft {target} items",
		"type": "daily",
		"objectives": [
			{"type": "craft", "target": "any", "amount": 5, "variable": true}
		],
		"rewards": {"xp": 120, "loot_category": "blueprints"},
		"difficulty_scaling": true
	},
	"daily_explore_zone": {
		"name": "Scouting Mission",
		"description": "Explore a {zone} zone",
		"type": "daily",
		"objectives": [
			{"type": "explore", "zone_type": "any", "time": 120}
		],
		"rewards": {"xp": 150, "loot_category": "weapons"},
		"difficulty_scaling": false
	},
	"daily_build_structures": {
		"name": "Home Improvement",
		"description": "Build {target} structures at your base",
		"type": "daily",
		"objectives": [
			{"type": "build", "target": "any", "amount": 3, "variable": true}
		],
		"rewards": {"xp": 100, "resources": {"wood": 50, "stone": 30}},
		"difficulty_scaling": true
	},
	
	# Weekly quests
	"weekly_zone_clear": {
		"name": "Zone Domination",
		"description": "Clear all enemies in a {zone} zone",
		"type": "weekly",
		"objectives": [
			{"type": "zone_clear", "zone_type": "yellow"},
			{"type": "zone_clear", "zone_type": "red"}
		],
		"rewards": {"xp": 500, "loot_category": "armor", "loot_quality": "rare", "skill_points": 1},
		"difficulty_scaling": false
	},
	"weekly_boss_hunt": {
		"name": "Boss Hunter",
		"description": "Defeat {target} boss enemies",
		"type": "weekly",
		"objectives": [
			{"type": "kill", "target": "boss", "amount": 3}
		],
		"rewards": {"xp": 750, "loot_category": "weapons", "loot_quality": "epic", "skill_points": 2},
		"difficulty_scaling": false
	},
	"weekly_trader": {
		"name": "Merchant's Friend",
		"description": "Complete {target} trades with NPCs",
		"type": "weekly",
		"objectives": [
			{"type": "trade", "amount": 10}
		],
		"rewards": {"xp": 400, "gold": 500, "reputation": 50},
		"difficulty_scaling": true
	},
	"weekly_survival": {
		"name": "Survivor",
		"description": "Survive {target} horde nights",
		"type": "weekly",
		"objectives": [
			{"type": "survive_horde", "amount": 3}
		],
		"rewards": {"xp": 600, "loot_category": "armor", "loot_quality": "rare", "attribute_points": 1},
		"difficulty_scaling": false
	},
	"weekly_master_crafter": {
		"name": "Master Crafter",
		"description": "Craft {target} rare or better items",
		"type": "weekly",
		"objectives": [
			{"type": "craft", "target": "rare+", "amount": 5}
		],
		"rewards": {"xp": 500, "loot_category": "blueprints", "loot_quality": "epic"},
		"difficulty_scaling": true
	},
	
	# Story quests
	"story_beginning": {
		"name": "A New Beginning",
		"description": "Establish your base and survive the first night",
		"type": "story",
		"chapter": 1,
		"objectives": [
			{"type": "build", "target": "floor", "amount": 4},
			{"type": "build", "target": "wall", "amount": 4},
			{"type": "build", "target": "campfire", "amount": 1},
			{"type": "survive_horde", "amount": 1}
		],
		"rewards": {"xp": 300, "items": {"wood": 100, "stone": 50}},
		"next_quest": "story_first_weapon"
	},
	"story_first_weapon": {
		"name": "Armed and Ready",
		"description": "Craft your first weapon",
		"type": "story",
		"chapter": 1,
		"objectives": [
			{"type": "craft", "target": "weapon", "amount": 1}
		],
		"rewards": {"xp": 200, "loot_category": "weapons", "loot_quality": "uncommon"},
		"next_quest": "story_first_kill"
	},
	"story_first_kill": {
		"name": "First Blood",
		"description": "Defeat your first zombie",
		"type": "story",
		"chapter": 1,
		"objectives": [
			{"type": "kill", "target": "zombie", "amount": 1}
		],
		"rewards": {"xp": 100, "skill_points": 1},
		"next_quest": "story_explore_green"
	},
	"story_explore_green": {
		"name": "Into the Unknown",
		"description": "Explore a green zone and return safely",
		"type": "story",
		"chapter": 2,
		"objectives": [
			{"type": "explore", "zone_type": "green", "time": 60},
			{"type": "return_to_base"}
		],
		"rewards": {"xp": 250, "loot_category": "resources", "loot_quality": "uncommon"},
		"next_quest": "story_workbench"
	},
	"story_workbench": {
		"name": "Upgrading the Workshop",
		"description": "Build an advanced workbench",
		"type": "story",
		"chapter": 2,
		"objectives": [
			{"type": "build", "target": "workbench_advanced", "amount": 1}
		],
		"rewards": {"xp": 400, "loot_category": "blueprints", "loot_quality": "rare"},
		"next_quest": "story_yellow_zone"
	},
	"story_yellow_zone": {
		"name": "Dangerous Territory",
		"description": "Venture into a yellow zone",
		"type": "story",
		"chapter": 3,
		"objectives": [
			{"type": "explore", "zone_type": "yellow", "time": 120},
			{"type": "gather", "target": "any", "amount": 20}
		],
		"rewards": {"xp": 500, "loot_category": "armor", "loot_quality": "rare", "attribute_points": 1},
		"next_quest": "story_first_boss"
	},
	"story_first_boss": {
		"name": "The Big One",
		"description": "Defeat your first boss enemy",
		"type": "story",
		"chapter": 3,
		"objectives": [
			{"type": "kill", "target": "boss", "amount": 1}
		],
		"rewards": {"xp": 750, "loot_category": "weapons", "loot_quality": "epic", "skill_points": 3},
		"next_quest": "story_red_zone"
	}
}

# ============================================================================
# EVENT DEFINITIONS
# ============================================================================

const EVENT_TEMPLATES := {
	"supply_drop": {
		"name": "Supply Drop",
		"description": "A supply plane has dropped cargo nearby!",
		"duration": 300.0,  # 5 minutes
		"spawn_type": "loot_crate",
		"loot_quality": "rare",
		"notification": true
	},
	"trader_caravan": {
		"name": "Trader Caravan",
		"description": "A traveling merchant has arrived!",
		"duration": 600.0,  # 10 minutes
		"spawn_type": "npc_trader",
		"special_deals": true,
		"notification": true
	},
	"infected_horde": {
		"name": "Wandering Horde",
		"description": "A massive zombie horde is approaching!",
		"duration": 180.0,  # 3 minutes
		"spawn_type": "enemy_wave",
		"enemy_count": 25,
		"rewards_on_clear": true,
		"notification": true
	},
	"resource_surge": {
		"name": "Resource Surge",
		"description": "Resources are abundant in this area!",
		"duration": 480.0,  # 8 minutes
		"effect": "double_resources",
		"notification": true
	},
	"boss_spawn": {
		"name": "Boss Sighting",
		"description": "A powerful enemy has been spotted!",
		"duration": 600.0,
		"spawn_type": "boss",
		"loot_quality": "epic",
		"notification": true
	},
	"weather_fog": {
		"name": "Dense Fog",
		"description": "Visibility is severely reduced",
		"duration": 300.0,
		"effect": "reduced_visibility",
		"enemy_detection_range_mult": 0.5,
		"notification": true
	},
	"weather_storm": {
		"name": "Thunderstorm",
		"description": "A dangerous storm is raging",
		"duration": 240.0,
		"effect": "storm",
		"damage_per_tick": 2.0,
		"tick_interval": 10.0,
		"notification": true
	},
	"rescue_mission": {
		"name": "Survivor Rescue",
		"description": "A survivor needs help!",
		"duration": 420.0,
		"spawn_type": "rescue_npc",
		"reward_on_complete": {"xp": 300, "reputation": 100},
		"notification": true
	}
}

# ============================================================================
# STATE
# ============================================================================

var active_quests := {}  # quest_id -> quest_data
var completed_quests := []  # List of completed quest IDs
var failed_quests := []
var active_events := {}  # event_id -> event_data
var last_daily_refresh := 0.0
var last_weekly_refresh := 0.0
var current_day := 1

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	_initialize_story_quests()

func _process(delta: float) -> void:
	_update_events(delta)
	_check_quest_timers(delta)

func _initialize_story_quests() -> void:
	# Start the first story quest if not already done
	if "story_beginning" not in completed_quests and "story_beginning" not in active_quests:
		add_quest("story_beginning")

# ============================================================================
# QUEST MANAGEMENT
# ============================================================================

func add_quest(quest_id: String, params: Dictionary = {}) -> bool:
	if active_quests.has(quest_id):
		return false
	
	if not QUEST_TEMPLATES.has(quest_id):
		push_warning("Unknown quest: " + quest_id)
		return false
	
	var template: Dictionary = QUEST_TEMPLATES[quest_id]
	
	# Create quest instance
	var quest := {
		"id": quest_id,
		"template": template,
		"progress": {},
		"started_at": Time.get_unix_time_from_system(),
		"params": params
	}
	
	# Initialize progress for each objective
	for i in range(template["objectives"].size()):
		var obj: Dictionary = template["objectives"][i]
		var target_amount: int = obj.get("amount", 1)
		
		# Apply difficulty scaling if applicable
		if template.get("difficulty_scaling", false) and obj.get("variable", false):
			var player_level: int = params.get("player_level", 1)
			target_amount = int(target_amount * (1.0 + player_level * 0.1))
		
		quest["progress"][i] = {
			"current": 0,
			"target": target_amount,
			"completed": false
		}
	
	active_quests[quest_id] = quest
	emit_signal("quest_added", quest_id)
	return true

func update_quest_progress(quest_id: String, objective_index: int, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest: Dictionary = active_quests[quest_id]
	var progress: Dictionary = quest["progress"]
	
	if not progress.has(objective_index):
		return
	
	var obj_progress: Dictionary = progress[objective_index]
	if obj_progress["completed"]:
		return
	
	obj_progress["current"] += amount
	
	if obj_progress["current"] >= obj_progress["target"]:
		obj_progress["current"] = obj_progress["target"]
		obj_progress["completed"] = true
	
	emit_signal("quest_updated", quest_id, quest["progress"])
	
	# Check if all objectives are complete
	_check_quest_completion(quest_id)

func _check_quest_completion(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest: Dictionary = active_quests[quest_id]
	
	for obj_index in quest["progress"]:
		if not quest["progress"][obj_index]["completed"]:
			return
	
	# All objectives complete!
	_complete_quest(quest_id)

func _complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest: Dictionary = active_quests[quest_id]
	var template: Dictionary = quest["template"]
	var rewards: Dictionary = template.get("rewards", {})
	
	# Award rewards
	_grant_rewards(rewards)
	
	# Move to completed
	completed_quests.append(quest_id)
	active_quests.erase(quest_id)
	
	emit_signal("quest_completed", quest_id, rewards)
	
	# Start next quest in chain if applicable
	if template.has("next_quest"):
		add_quest(template["next_quest"])

func fail_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	
	failed_quests.append(quest_id)
	active_quests.erase(quest_id)
	emit_signal("quest_failed", quest_id)

func _grant_rewards(rewards: Dictionary) -> void:
	# This would connect to other systems
	# For now, just log
	print("Granting rewards: ", rewards)

# ============================================================================
# OBJECTIVE TRACKING
# ============================================================================

func on_enemy_killed(enemy_type: String, zone: String) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var template: Dictionary = quest["template"]
		
		for i in range(template["objectives"].size()):
			var obj: Dictionary = template["objectives"][i]
			if obj["type"] == "kill":
				if obj["target"] == enemy_type or obj["target"] == "any":
					update_quest_progress(quest_id, i, 1)

func on_resource_gathered(resource_type: String, amount: int) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var template: Dictionary = quest["template"]
		
		for i in range(template["objectives"].size()):
			var obj: Dictionary = template["objectives"][i]
			if obj["type"] == "gather":
				if obj["target"] == resource_type or obj["target"] == "any":
					update_quest_progress(quest_id, i, amount)

func on_item_crafted(item_type: String, quality: String) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var template: Dictionary = quest["template"]
		
		for i in range(template["objectives"].size()):
			var obj: Dictionary = template["objectives"][i]
			if obj["type"] == "craft":
				var matches := false
				if obj["target"] == "any":
					matches = true
				elif obj["target"] == "weapon" and _is_weapon(item_type):
					matches = true
				elif obj["target"] == "armor" and _is_armor(item_type):
					matches = true
				elif obj["target"] == "rare+" and _is_quality_or_better(quality, "rare"):
					matches = true
				elif obj["target"] == item_type:
					matches = true
				
				if matches:
					update_quest_progress(quest_id, i, 1)

func on_structure_built(structure_type: String, category: String) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var template: Dictionary = quest["template"]
		
		for i in range(template["objectives"].size()):
			var obj: Dictionary = template["objectives"][i]
			if obj["type"] == "build":
				if obj["target"] == structure_type or obj["target"] == category or obj["target"] == "any":
					update_quest_progress(quest_id, i, 1)

func on_zone_explored(zone_type: String, time_spent: float) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var template: Dictionary = quest["template"]
		
		for i in range(template["objectives"].size()):
			var obj: Dictionary = template["objectives"][i]
			if obj["type"] == "explore":
				if obj.get("zone_type", "any") == zone_type or obj.get("zone_type", "any") == "any":
					var required_time: float = obj.get("time", 0)
					if time_spent >= required_time:
						update_quest_progress(quest_id, i, 1)

func on_zone_cleared(zone_type: String) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var template: Dictionary = quest["template"]
		
		for i in range(template["objectives"].size()):
			var obj: Dictionary = template["objectives"][i]
			if obj["type"] == "zone_clear":
				if obj.get("zone_type", "any") == zone_type or obj.get("zone_type", "any") == "any":
					update_quest_progress(quest_id, i, 1)

func on_horde_survived() -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var template: Dictionary = quest["template"]
		
		for i in range(template["objectives"].size()):
			var obj: Dictionary = template["objectives"][i]
			if obj["type"] == "survive_horde":
				update_quest_progress(quest_id, i, 1)

func on_trade_completed() -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var template: Dictionary = quest["template"]
		
		for i in range(template["objectives"].size()):
			var obj: Dictionary = template["objectives"][i]
			if obj["type"] == "trade":
				update_quest_progress(quest_id, i, 1)

func on_returned_to_base() -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var template: Dictionary = quest["template"]
		
		for i in range(template["objectives"].size()):
			var obj: Dictionary = template["objectives"][i]
			if obj["type"] == "return_to_base":
				update_quest_progress(quest_id, i, 1)

# ============================================================================
# HELPERS
# ============================================================================

func _is_weapon(item_type: String) -> bool:
	var weapon_keywords := ["sword", "knife", "axe", "bow", "gun", "rifle", "pistol", "club", "spear"]
	for keyword in weapon_keywords:
		if keyword in item_type.to_lower():
			return true
	return false

func _is_armor(item_type: String) -> bool:
	var armor_keywords := ["armor", "vest", "helmet", "boots", "gloves", "pants", "jacket", "suit"]
	for keyword in armor_keywords:
		if keyword in item_type.to_lower():
			return true
	return false

func _is_quality_or_better(quality: String, min_quality: String) -> bool:
	var quality_order := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
	var quality_idx := quality_order.find(quality)
	var min_idx := quality_order.find(min_quality)
	return quality_idx >= min_idx

func _check_quest_timers(_delta: float) -> void:
	# Daily/weekly quest refresh logic would go here
	pass

# ============================================================================
# EVENT MANAGEMENT
# ============================================================================

func start_event(event_type: String, location: Vector2 = Vector2.ZERO) -> String:
	if not EVENT_TEMPLATES.has(event_type):
		push_warning("Unknown event type: " + event_type)
		return ""
	
	var template: Dictionary = EVENT_TEMPLATES[event_type]
	var event_id := event_type + "_" + str(Time.get_unix_time_from_system())
	
	var event := {
		"id": event_id,
		"type": event_type,
		"template": template,
		"location": location,
		"started_at": Time.get_unix_time_from_system(),
		"remaining_time": template.get("duration", 300.0),
		"spawned_entities": []
	}
	
	active_events[event_id] = event
	
	# Spawn event entities
	_spawn_event_entities(event)
	
	emit_signal("event_started", event_id)
	return event_id

func _spawn_event_entities(event: Dictionary) -> void:
	var template: Dictionary = event["template"]
	var spawn_type: String = template.get("spawn_type", "")
	
	match spawn_type:
		"loot_crate":
			# Would spawn a loot crate at event location
			pass
		"npc_trader":
			# Would spawn a trader NPC
			pass
		"enemy_wave":
			# Would spawn enemies
			pass
		"boss":
			# Would spawn a boss enemy
			pass
		"rescue_npc":
			# Would spawn a survivor to rescue
			pass

func _update_events(delta: float) -> void:
	var events_to_end := []
	
	for event_id in active_events:
		var event: Dictionary = active_events[event_id]
		event["remaining_time"] -= delta
		
		if event["remaining_time"] <= 0:
			events_to_end.append(event_id)
	
	for event_id in events_to_end:
		end_event(event_id)

func end_event(event_id: String) -> void:
	if not active_events.has(event_id):
		return
	
	var event: Dictionary = active_events[event_id]
	
	# Clean up spawned entities
	for entity in event.get("spawned_entities", []):
		if is_instance_valid(entity):
			entity.queue_free()
	
	active_events.erase(event_id)
	emit_signal("event_ended", event_id)

func trigger_random_event(zone: String = "") -> void:
	var possible_events := EVENT_TEMPLATES.keys()
	var event_type: String = possible_events[randi() % possible_events.size()]
	start_event(event_type)

# ============================================================================
# DAILY/WEEKLY REFRESH
# ============================================================================

func refresh_daily_quests(player_level: int) -> void:
	# Remove old daily quests
	var to_remove := []
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		if quest["template"].get("type", "") == "daily":
			to_remove.append(quest_id)
	
	for quest_id in to_remove:
		active_quests.erase(quest_id)
	
	# Add new daily quests
	var daily_templates := []
	for template_id in QUEST_TEMPLATES:
		if QUEST_TEMPLATES[template_id].get("type", "") == "daily":
			daily_templates.append(template_id)
	
	daily_templates.shuffle()
	
	for i in range(min(GameConfig.DAILY_QUEST_COUNT, daily_templates.size())):
		add_quest(daily_templates[i], {"player_level": player_level})
	
	last_daily_refresh = Time.get_unix_time_from_system()

func refresh_weekly_quests(player_level: int) -> void:
	# Remove old weekly quests
	var to_remove := []
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		if quest["template"].get("type", "") == "weekly":
			to_remove.append(quest_id)
	
	for quest_id in to_remove:
		active_quests.erase(quest_id)
	
	# Add new weekly quests
	var weekly_templates := []
	for template_id in QUEST_TEMPLATES:
		if QUEST_TEMPLATES[template_id].get("type", "") == "weekly":
			weekly_templates.append(template_id)
	
	weekly_templates.shuffle()
	
	for i in range(min(GameConfig.WEEKLY_QUEST_COUNT, weekly_templates.size())):
		add_quest(weekly_templates[i], {"player_level": player_level})
	
	last_weekly_refresh = Time.get_unix_time_from_system()

# ============================================================================
# QUERIES
# ============================================================================

func get_active_quests_by_type(quest_type: String) -> Array:
	var result := []
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		if quest["template"].get("type", "") == quest_type:
			result.append(quest)
	return result

func get_quest_progress(quest_id: String) -> Dictionary:
	if active_quests.has(quest_id):
		return active_quests[quest_id]["progress"]
	return {}

func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

func get_active_events() -> Array:
	return active_events.values()

# ============================================================================
# SAVE/LOAD
# ============================================================================

func get_save_data() -> Dictionary:
	return {
		"active_quests": active_quests.duplicate(true),
		"completed_quests": completed_quests.duplicate(),
		"failed_quests": failed_quests.duplicate(),
		"last_daily_refresh": last_daily_refresh,
		"last_weekly_refresh": last_weekly_refresh,
		"current_day": current_day
	}

func load_save_data(data: Dictionary) -> void:
	active_quests = data.get("active_quests", {})
	completed_quests = data.get("completed_quests", [])
	failed_quests = data.get("failed_quests", [])
	last_daily_refresh = data.get("last_daily_refresh", 0.0)
	last_weekly_refresh = data.get("last_weekly_refresh", 0.0)
	current_day = data.get("current_day", 1)
