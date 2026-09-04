extends Node
class_name CompanionSystemClass
## Manages companion NPCs - recruitment, AI, equipment, commands, and loyalty
## Handles companion skills, morale, and relationship with the player

signal companion_recruited(companion_id: String, companion_data: Dictionary)
signal companion_dismissed(companion_id: String, reason: String)
signal companion_died(companion_id: String)
signal companion_level_up(companion_id: String, new_level: int)
signal companion_skill_unlocked(companion_id: String, skill_id: String)
signal companion_mood_changed(companion_id: String, old_mood: int, new_mood: int)
signal companion_injured(companion_id: String, health_percent: float)
signal companion_order_given(companion_id: String, order: int)
signal companion_item_equipped(companion_id: String, slot: int, item_id: String)
signal max_companions_reached()

# ============================================================================
# COMPANION CONFIGURATION
# ============================================================================

enum CompanionClass {
	SURVIVOR,
	SOLDIER,
	MEDIC,
	SCOUT,
	ENGINEER,
	HUNTER,
	BRAWLER,
}

enum CompanionMood {
	MISERABLE,
	UNHAPPY,
	NEUTRAL,
	CONTENT,
	HAPPY,
	LOYAL,
}

enum CompanionState {
	FOLLOWING,
	COMBAT,
	GUARDING,
	LOOTING,
	HEALING,
	RESTING,
	WAITING,
	PATROLLING,
	DEAD,
}

enum CompanionOrder {
	FOLLOW,
	STAY,
	ATTACK,
	DEFEND,
	LOOT,
	HEAL,
	PATROL,
	RETURN_TO_BASE,
	DISMISS,
}

enum CompanionSlot {
	WEAPON,
	ARMOR,
	ACCESSORY,
	CONSUMABLE,
}

const CLASS_DEFINITIONS := {
	CompanionClass.SURVIVOR: {
		"name": "Survivor",
		"description": "A well-rounded survivor with basic skills.",
		"base_health": 100,
		"base_damage": 10,
		"base_defense": 5,
		"skills": ["scavenging", "basic_combat"],
		"stat_growth": {"health": 10, "damage": 2, "defense": 1},
		"preferred_weapons": ["any"],
	},
	CompanionClass.SOLDIER: {
		"name": "Soldier",
		"description": "A trained fighter with high combat skills.",
		"base_health": 120,
		"base_damage": 15,
		"base_defense": 8,
		"skills": ["advanced_combat", "tactical"],
		"stat_growth": {"health": 12, "damage": 3, "defense": 2},
		"preferred_weapons": ["rifle", "assault_rifle"],
	},
	CompanionClass.MEDIC: {
		"name": "Medic",
		"description": "A healer who can treat wounds and illness.",
		"base_health": 80,
		"base_damage": 8,
		"base_defense": 4,
		"skills": ["first_aid", "medicine"],
		"stat_growth": {"health": 8, "damage": 1, "defense": 1},
		"preferred_weapons": ["pistol"],
		"special_ability": "heal_allies",
	},
	CompanionClass.SCOUT: {
		"name": "Scout",
		"description": "A stealthy explorer with detection skills.",
		"base_health": 90,
		"base_damage": 12,
		"base_defense": 5,
		"skills": ["stealth", "tracking"],
		"stat_growth": {"health": 9, "damage": 2, "defense": 1},
		"preferred_weapons": ["bow", "knife"],
		"special_ability": "detect_enemies",
	},
	CompanionClass.ENGINEER: {
		"name": "Engineer",
		"description": "A technical expert who can repair and build.",
		"base_health": 95,
		"base_damage": 8,
		"base_defense": 6,
		"skills": ["repair", "crafting"],
		"stat_growth": {"health": 10, "damage": 1, "defense": 2},
		"preferred_weapons": ["any"],
		"special_ability": "quick_repair",
	},
	CompanionClass.HUNTER: {
		"name": "Hunter",
		"description": "An expert marksman and tracker.",
		"base_health": 100,
		"base_damage": 18,
		"base_defense": 4,
		"skills": ["marksmanship", "hunting"],
		"stat_growth": {"health": 10, "damage": 4, "defense": 1},
		"preferred_weapons": ["rifle", "bow"],
		"special_ability": "critical_shot",
	},
	CompanionClass.BRAWLER: {
		"name": "Brawler",
		"description": "A tough melee fighter who can take hits.",
		"base_health": 150,
		"base_damage": 14,
		"base_defense": 10,
		"skills": ["melee_combat", "intimidation"],
		"stat_growth": {"health": 15, "damage": 2, "defense": 3},
		"preferred_weapons": ["machete", "bat"],
		"special_ability": "taunt",
	},
}

const COMPANION_SKILLS := {
	"scavenging": {
		"name": "Scavenging",
		"description": "Better loot finding",
		"unlock_level": 1,
		"effect": {"loot_bonus": 0.1},
	},
	"basic_combat": {
		"name": "Basic Combat",
		"description": "Can use basic weapons",
		"unlock_level": 1,
		"effect": {"can_use_weapons": true},
	},
	"advanced_combat": {
		"name": "Advanced Combat",
		"description": "Higher damage and accuracy",
		"unlock_level": 1,
		"effect": {"damage_bonus": 0.15, "accuracy_bonus": 0.1},
	},
	"tactical": {
		"name": "Tactical Training",
		"description": "Better positioning in combat",
		"unlock_level": 3,
		"effect": {"defense_bonus": 0.1, "crit_chance": 0.05},
	},
	"first_aid": {
		"name": "First Aid",
		"description": "Can heal minor wounds",
		"unlock_level": 1,
		"effect": {"can_heal": true, "heal_amount": 25},
	},
	"medicine": {
		"name": "Medicine",
		"description": "Advanced healing abilities",
		"unlock_level": 5,
		"effect": {"heal_amount": 50, "can_cure_infection": true},
	},
	"stealth": {
		"name": "Stealth",
		"description": "Harder for enemies to detect",
		"unlock_level": 1,
		"effect": {"detection_reduction": 0.3},
	},
	"tracking": {
		"name": "Tracking",
		"description": "Can find enemies and resources",
		"unlock_level": 3,
		"effect": {"detect_range": 50, "track_enemies": true},
	},
	"repair": {
		"name": "Repair",
		"description": "Can repair items and vehicles",
		"unlock_level": 1,
		"effect": {"can_repair": true, "repair_efficiency": 1.2},
	},
	"crafting": {
		"name": "Crafting",
		"description": "Better crafting results",
		"unlock_level": 3,
		"effect": {"craft_bonus": 0.2, "material_savings": 0.1},
	},
	"marksmanship": {
		"name": "Marksmanship",
		"description": "Expert with ranged weapons",
		"unlock_level": 1,
		"effect": {"ranged_damage": 0.2, "accuracy": 0.15},
	},
	"hunting": {
		"name": "Hunting",
		"description": "Better at finding animals and resources",
		"unlock_level": 2,
		"effect": {"animal_damage": 0.3, "meat_bonus": 0.25},
	},
	"melee_combat": {
		"name": "Melee Combat",
		"description": "Expert with melee weapons",
		"unlock_level": 1,
		"effect": {"melee_damage": 0.25, "block_chance": 0.1},
	},
	"intimidation": {
		"name": "Intimidation",
		"description": "Can scare away weak enemies",
		"unlock_level": 4,
		"effect": {"fear_chance": 0.2, "fear_range": 30},
	},
}

const MAX_COMPANIONS := 3
const MAX_LEVEL := 20
const XP_PER_LEVEL := 100

# ============================================================================
# STATE
# ============================================================================

var _companions: Dictionary = {}  # companion_id -> companion data
var _active_companions: Array = []  # Currently following player (up to MAX_COMPANIONS)
var _base_companions: Array = []  # Companions at the base
var _companion_id_counter: int = 0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_update_companions(delta)


# ============================================================================
# COMPANION RECRUITMENT
# ============================================================================

func recruit_companion(npc_id: String, companion_class: int, name: String = "") -> Dictionary:
	var class_def: Dictionary = CLASS_DEFINITIONS.get(companion_class, {})
	if class_def.is_empty():
		return {"success": false, "error": "Unknown companion class"}
	
	if _active_companions.size() >= MAX_COMPANIONS:
		emit_signal("max_companions_reached")
		return {"success": false, "error": "Maximum companions reached"}
	
	_companion_id_counter += 1
	var companion_id: String = npc_id if npc_id != "" else "companion_%d" % _companion_id_counter
	
	var companion_name: String = name if name != "" else _generate_companion_name()
	
	var companion_data := {
		"id": companion_id,
		"name": companion_name,
		"class": companion_class,
		"class_name": CompanionClass.keys()[companion_class],
		"description": class_def.get("description", ""),
		
		# Stats
		"level": 1,
		"xp": 0,
		"xp_to_next": XP_PER_LEVEL,
		"health": class_def.get("base_health", 100),
		"max_health": class_def.get("base_health", 100),
		"damage": class_def.get("base_damage", 10),
		"defense": class_def.get("base_defense", 5),
		
		# State
		"state": CompanionState.FOLLOWING,
		"mood": CompanionMood.NEUTRAL,
		"loyalty": 50,  # 0-100
		
		# Position
		"position": Vector2.ZERO,
		"target": null,
		
		# Skills
		"skills": class_def.get("skills", []).duplicate(),
		"unlocked_skills": [],
		"special_ability": class_def.get("special_ability", ""),
		
		# Equipment
		"equipment": {
			CompanionSlot.WEAPON: "",
			CompanionSlot.ARMOR: "",
			CompanionSlot.ACCESSORY: "",
			CompanionSlot.CONSUMABLE: "",
		},
		
		# Preferences
		"preferred_weapons": class_def.get("preferred_weapons", ["any"]),
		
		# Inventory (limited)
		"inventory": [],
		"inventory_slots": 6,
		
		# Combat stats
		"kills": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		
		# Timers
		"heal_cooldown": 0.0,
		"ability_cooldown": 0.0,
		
		# Meta
		"recruited_at": Time.get_unix_time_from_system(),
		"time_with_player": 0.0,
	}
	
	# Initialize base skills as unlocked
	for skill in companion_data["skills"]:
		companion_data["unlocked_skills"].append(skill)
	
	_companions[companion_id] = companion_data
	_active_companions.append(companion_id)
	
	emit_signal("companion_recruited", companion_id, companion_data)
	
	return {"success": true, "companion_id": companion_id, "companion": companion_data}


func _generate_companion_name() -> String:
	var first_names := ["Alex", "Jordan", "Sam", "Riley", "Casey", "Morgan", "Taylor", "Quinn", "Jake", "Sarah", "Mike", "Emma", "Lucas", "Mia", "Ethan", "Olivia"]
	return first_names[randi() % first_names.size()]


func dismiss_companion(companion_id: String, reason: String = "dismissed") -> void:
	if companion_id not in _companions:
		return
	
	_active_companions.erase(companion_id)
	_base_companions.erase(companion_id)
	_companions.erase(companion_id)
	
	emit_signal("companion_dismissed", companion_id, reason)


func send_to_base(companion_id: String) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	if companion_id in _base_companions:
		return {"success": false, "error": "Companion already at base"}
	
	_active_companions.erase(companion_id)
	_base_companions.append(companion_id)
	
	var companion: Dictionary = _companions[companion_id]
	companion["state"] = CompanionState.RESTING
	
	return {"success": true}


func recall_from_base(companion_id: String) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	if companion_id not in _base_companions:
		return {"success": false, "error": "Companion not at base"}
	
	if _active_companions.size() >= MAX_COMPANIONS:
		return {"success": false, "error": "Maximum active companions reached"}
	
	_base_companions.erase(companion_id)
	_active_companions.append(companion_id)
	
	var companion: Dictionary = _companions[companion_id]
	companion["state"] = CompanionState.FOLLOWING
	
	return {"success": true}


# ============================================================================
# COMPANION UPDATE
# ============================================================================

func _update_companions(delta: float) -> void:
	for companion_id in _active_companions:
		var companion: Dictionary = _companions.get(companion_id, {})
		if companion.is_empty():
			continue
		
		companion["time_with_player"] += delta
		
		# Update cooldowns
		if companion["heal_cooldown"] > 0:
			companion["heal_cooldown"] -= delta
		if companion["ability_cooldown"] > 0:
			companion["ability_cooldown"] -= delta
		
		# Update based on state
		_update_companion_state(companion, delta)
		
		# Update mood based on conditions
		_update_companion_mood(companion)


func _update_companion_state(companion: Dictionary, _delta: float) -> void:
	match companion.get("state"):
		CompanionState.FOLLOWING:
			# Would update position to follow player
			pass
		
		CompanionState.COMBAT:
			# AI combat behavior
			_companion_combat_ai(companion)
		
		CompanionState.GUARDING:
			# Stay in position, attack nearby enemies
			pass
		
		CompanionState.LOOTING:
			# Search for nearby loot
			pass
		
		CompanionState.HEALING:
			# Heal self or player
			_companion_heal_ai(companion)
		
		CompanionState.RESTING:
			# Slowly recover health
			if companion["health"] < companion["max_health"]:
				companion["health"] = mini(companion["health"] + 1, companion["max_health"])


func _companion_combat_ai(companion: Dictionary) -> void:
	# Simplified combat AI
	# Would target nearest enemy, attack based on weapon
	pass


func _companion_heal_ai(companion: Dictionary) -> void:
	if "first_aid" not in companion.get("unlocked_skills", []):
		return
	
	if companion["heal_cooldown"] > 0:
		return
	
	# Would heal player or self if health is low
	var skill_data: Dictionary = COMPANION_SKILLS.get("first_aid", {})
	var heal_amount: int = skill_data.get("effect", {}).get("heal_amount", 25)
	
	if "medicine" in companion.get("unlocked_skills", []):
		var med_data: Dictionary = COMPANION_SKILLS.get("medicine", {})
		heal_amount = med_data.get("effect", {}).get("heal_amount", 50)
	
	companion["heal_cooldown"] = 10.0  # 10 second cooldown


func _update_companion_mood(companion: Dictionary) -> void:
	var old_mood: int = companion.get("mood", CompanionMood.NEUTRAL)
	var new_mood: int = old_mood
	
	var health_percent: float = float(companion["health"]) / float(companion["max_health"])
	var loyalty: int = companion.get("loyalty", 50)
	
	# Calculate mood based on factors
	var mood_score: float = 50.0
	
	# Health affects mood
	mood_score += (health_percent - 0.5) * 30
	
	# Loyalty affects mood
	mood_score += (loyalty - 50) * 0.3
	
	# Time with player increases mood
	var time_bonus: float = minf(companion.get("time_with_player", 0) / 3600.0, 10.0)  # Max 10 hours bonus
	mood_score += time_bonus
	
	# Convert score to mood
	if mood_score >= 80:
		new_mood = CompanionMood.LOYAL
	elif mood_score >= 65:
		new_mood = CompanionMood.HAPPY
	elif mood_score >= 50:
		new_mood = CompanionMood.CONTENT
	elif mood_score >= 35:
		new_mood = CompanionMood.NEUTRAL
	elif mood_score >= 20:
		new_mood = CompanionMood.UNHAPPY
	else:
		new_mood = CompanionMood.MISERABLE
	
	if new_mood != old_mood:
		companion["mood"] = new_mood
		emit_signal("companion_mood_changed", companion["id"], old_mood, new_mood)


# ============================================================================
# ORDERS
# ============================================================================

func give_order(companion_id: String, order: int, target = null) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	if companion_id not in _active_companions:
		return {"success": false, "error": "Companion not active"}
	
	var companion: Dictionary = _companions[companion_id]
	
	if companion.get("state") == CompanionState.DEAD:
		return {"success": false, "error": "Companion is dead"}
	
	match order:
		CompanionOrder.FOLLOW:
			companion["state"] = CompanionState.FOLLOWING
			companion["target"] = null
		
		CompanionOrder.STAY:
			companion["state"] = CompanionState.GUARDING
			companion["target"] = companion["position"]  # Guard current position
		
		CompanionOrder.ATTACK:
			companion["state"] = CompanionState.COMBAT
			companion["target"] = target
		
		CompanionOrder.DEFEND:
			companion["state"] = CompanionState.GUARDING
			companion["target"] = target  # Defend this position/person
		
		CompanionOrder.LOOT:
			companion["state"] = CompanionState.LOOTING
		
		CompanionOrder.HEAL:
			if "first_aid" in companion.get("unlocked_skills", []):
				companion["state"] = CompanionState.HEALING
			else:
				return {"success": false, "error": "Companion cannot heal"}
		
		CompanionOrder.PATROL:
			companion["state"] = CompanionState.PATROLLING
			companion["target"] = target  # Patrol path
		
		CompanionOrder.RETURN_TO_BASE:
			send_to_base(companion_id)
		
		CompanionOrder.DISMISS:
			dismiss_companion(companion_id, "player_dismissed")
	
	emit_signal("companion_order_given", companion_id, order)
	
	return {"success": true, "state": companion["state"]}


# ============================================================================
# EXPERIENCE & LEVELING
# ============================================================================

func add_xp(companion_id: String, amount: int) -> void:
	if companion_id not in _companions:
		return
	
	var companion: Dictionary = _companions[companion_id]
	
	if companion["level"] >= MAX_LEVEL:
		return
	
	companion["xp"] += amount
	
	while companion["xp"] >= companion["xp_to_next"] and companion["level"] < MAX_LEVEL:
		companion["xp"] -= companion["xp_to_next"]
		_level_up(companion)


func _level_up(companion: Dictionary) -> void:
	companion["level"] += 1
	
	var class_def: Dictionary = CLASS_DEFINITIONS.get(companion["class"], {})
	var growth: Dictionary = class_def.get("stat_growth", {})
	
	# Apply stat growth
	companion["max_health"] += growth.get("health", 10)
	companion["health"] = companion["max_health"]
	companion["damage"] += growth.get("damage", 2)
	companion["defense"] += growth.get("defense", 1)
	
	# XP requirement increases
	companion["xp_to_next"] = XP_PER_LEVEL * companion["level"]
	
	# Check for skill unlocks
	_check_skill_unlocks(companion)
	
	emit_signal("companion_level_up", companion["id"], companion["level"])


func _check_skill_unlocks(companion: Dictionary) -> void:
	for skill_id in COMPANION_SKILLS:
		var skill: Dictionary = COMPANION_SKILLS[skill_id]
		var unlock_level: int = skill.get("unlock_level", 1)
		
		if companion["level"] >= unlock_level and skill_id not in companion["unlocked_skills"]:
			# Check if this skill is available to this class
			if skill_id in companion["skills"] or _can_learn_skill(companion, skill_id):
				companion["unlocked_skills"].append(skill_id)
				emit_signal("companion_skill_unlocked", companion["id"], skill_id)


func _can_learn_skill(companion: Dictionary, _skill_id: String) -> bool:
	# Generic skills anyone can learn at certain levels
	return companion["level"] >= 10


# ============================================================================
# EQUIPMENT
# ============================================================================

func equip_item(companion_id: String, slot: int, item_id: String) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	var companion: Dictionary = _companions[companion_id]
	var equipment: Dictionary = companion.get("equipment", {})
	
	var old_item: String = equipment.get(slot, "")
	equipment[slot] = item_id
	
	# Apply equipment stats (would lookup from ItemDatabase)
	_recalculate_stats(companion)
	
	emit_signal("companion_item_equipped", companion_id, slot, item_id)
	
	return {"success": true, "old_item": old_item}


func unequip_item(companion_id: String, slot: int) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	var companion: Dictionary = _companions[companion_id]
	var equipment: Dictionary = companion.get("equipment", {})
	
	var old_item: String = equipment.get(slot, "")
	equipment[slot] = ""
	
	_recalculate_stats(companion)
	
	return {"success": true, "item": old_item}


func _recalculate_stats(companion: Dictionary) -> void:
	var class_def: Dictionary = CLASS_DEFINITIONS.get(companion["class"], {})
	var level: int = companion["level"]
	var growth: Dictionary = class_def.get("stat_growth", {})
	
	# Base stats at current level
	companion["max_health"] = class_def.get("base_health", 100) + growth.get("health", 10) * (level - 1)
	companion["damage"] = class_def.get("base_damage", 10) + growth.get("damage", 2) * (level - 1)
	companion["defense"] = class_def.get("base_defense", 5) + growth.get("defense", 1) * (level - 1)
	
	# Equipment bonuses would be added here
	# Would lookup each equipped item and add its stats


# ============================================================================
# COMBAT
# ============================================================================

func damage_companion(companion_id: String, damage: float) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	var companion: Dictionary = _companions[companion_id]
	
	# Apply defense
	var reduced_damage: float = damage * (100.0 / (100.0 + companion["defense"]))
	companion["health"] -= int(reduced_damage)
	companion["damage_taken"] += int(reduced_damage)
	
	var health_percent: float = float(companion["health"]) / float(companion["max_health"])
	emit_signal("companion_injured", companion_id, health_percent)
	
	if companion["health"] <= 0:
		companion["health"] = 0
		companion["state"] = CompanionState.DEAD
		emit_signal("companion_died", companion_id)
		return {"success": true, "killed": true}
	
	return {"success": true, "killed": false, "health": companion["health"]}


func heal_companion(companion_id: String, amount: int) -> void:
	if companion_id not in _companions:
		return
	
	var companion: Dictionary = _companions[companion_id]
	companion["health"] = mini(companion["health"] + amount, companion["max_health"])


func revive_companion(companion_id: String, health_percent: float = 0.25) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	var companion: Dictionary = _companions[companion_id]
	
	if companion["state"] != CompanionState.DEAD:
		return {"success": false, "error": "Companion is not dead"}
	
	companion["health"] = int(companion["max_health"] * health_percent)
	companion["state"] = CompanionState.FOLLOWING
	
	return {"success": true}


func companion_attack(companion_id: String, enemy_id: String) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	var companion: Dictionary = _companions[companion_id]
	var damage: int = companion["damage"]
	
	# Equipment and skill bonuses would be applied here
	
	companion["damage_dealt"] += damage
	
	return {"success": true, "damage": damage, "enemy_id": enemy_id}


func register_kill(companion_id: String) -> void:
	if companion_id not in _companions:
		return
	
	var companion: Dictionary = _companions[companion_id]
	companion["kills"] += 1
	
	# XP for kills
	add_xp(companion_id, 10)
	
	# Loyalty boost
	companion["loyalty"] = mini(companion["loyalty"] + 1, 100)


# ============================================================================
# INVENTORY
# ============================================================================

func add_to_inventory(companion_id: String, item_id: String, quantity: int = 1) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	var companion: Dictionary = _companions[companion_id]
	var inventory: Array = companion.get("inventory", [])
	var slots: int = companion.get("inventory_slots", 6)
	
	# Check for existing stack
	for item in inventory:
		if item["item_id"] == item_id:
			item["quantity"] += quantity
			return {"success": true}
	
	# Add new item
	if inventory.size() >= slots:
		return {"success": false, "error": "Inventory full"}
	
	inventory.append({"item_id": item_id, "quantity": quantity})
	return {"success": true}


func remove_from_inventory(companion_id: String, item_id: String, quantity: int = 1) -> Dictionary:
	if companion_id not in _companions:
		return {"success": false, "error": "Companion not found"}
	
	var companion: Dictionary = _companions[companion_id]
	var inventory: Array = companion.get("inventory", [])
	
	for i in range(inventory.size() - 1, -1, -1):
		var item: Dictionary = inventory[i]
		if item["item_id"] == item_id:
			item["quantity"] -= quantity
			if item["quantity"] <= 0:
				inventory.remove_at(i)
			return {"success": true}
	
	return {"success": false, "error": "Item not found"}


# ============================================================================
# QUERIES
# ============================================================================

func get_companion(companion_id: String) -> Dictionary:
	return _companions.get(companion_id, {})


func get_active_companions() -> Array:
	var companions: Array = []
	for companion_id in _active_companions:
		companions.append(_companions.get(companion_id, {}))
	return companions


func get_base_companions() -> Array:
	var companions: Array = []
	for companion_id in _base_companions:
		companions.append(_companions.get(companion_id, {}))
	return companions


func get_all_companions() -> Array:
	return _companions.values()


func get_companion_count() -> int:
	return _active_companions.size()


func can_recruit_more() -> bool:
	return _active_companions.size() < MAX_COMPANIONS


func get_skill_effect(companion_id: String, skill_id: String) -> Dictionary:
	if companion_id not in _companions:
		return {}
	
	var companion: Dictionary = _companions[companion_id]
	
	if skill_id not in companion.get("unlocked_skills", []):
		return {}
	
	var skill: Dictionary = COMPANION_SKILLS.get(skill_id, {})
	return skill.get("effect", {})


func has_skill(companion_id: String, skill_id: String) -> bool:
	if companion_id not in _companions:
		return false
	
	var companion: Dictionary = _companions[companion_id]
	return skill_id in companion.get("unlocked_skills", [])


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var companions_save: Dictionary = {}
	for companion_id in _companions:
		var companion: Dictionary = _companions[companion_id].duplicate(true)
		companion["position"] = {"x": companion["position"].x, "y": companion["position"].y}
		companions_save[companion_id] = companion
	
	return {
		"companions": companions_save,
		"active_companions": _active_companions.duplicate(),
		"base_companions": _base_companions.duplicate(),
		"companion_id_counter": _companion_id_counter,
	}


func load_data(data: Dictionary) -> void:
	_companions.clear()
	for companion_id in data.get("companions", {}):
		var companion: Dictionary = data["companions"][companion_id]
		if companion.has("position") and companion["position"] is Dictionary:
			companion["position"] = Vector2(companion["position"]["x"], companion["position"]["y"])
		_companions[companion_id] = companion
	
	_active_companions = data.get("active_companions", [])
	_base_companions = data.get("base_companions", [])
	_companion_id_counter = data.get("companion_id_counter", 0)
