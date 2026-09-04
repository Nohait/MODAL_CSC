extends Node

## ProgressionSystem - Meaningful character advancement
## Skills, attributes, levels, and unlocks that matter

signal level_up(new_level: int, rewards: Dictionary)
signal skill_leveled(skill_name: String, new_level: int)
signal attribute_increased(attribute: String, new_value: int)
signal perk_unlocked(perk_id: String)
signal achievement_earned(achievement_id: String)

const GameConfig = preload("res://scripts/core/GameConfig.gd")

# ============================================================================
# PLAYER DATA
# ============================================================================

var player_data := {
	"level": 1,
	"current_xp": 0,
	"total_xp": 0,
	"skill_points": 0,
	"attribute_points": 0,
	
	# Core attributes
	"attributes": {
		"strength": 5,      # Melee damage, carry capacity
		"agility": 5,       # Move speed, attack speed, dodge
		"vitality": 5,      # Health, stamina, resistance
		"intelligence": 5,  # Crafting bonuses, skill XP
		"luck": 5           # Loot quality, critical hits
	},
	
	# Skills (0-100)
	"skills": {
		# Combat
		"melee": 0,
		"ranged": 0,
		"defense": 0,
		"critical": 0,
		# Survival
		"gathering": 0,
		"cooking": 0,
		"medicine": 0,
		"stealth": 0,
		# Crafting
		"weaponsmithing": 0,
		"armorsmithing": 0,
		"construction": 0,
		"electronics": 0,
		# Social
		"trading": 0,
		"leadership": 0,
		"persuasion": 0,
		"intimidation": 0
	},
	
	# Unlocked perks
	"perks": [],
	
	# Achievements
	"achievements": [],
	
	# Statistics tracking
	"stats": {
		"zombies_killed": 0,
		"animals_killed": 0,
		"resources_gathered": 0,
		"items_crafted": 0,
		"structures_built": 0,
		"quests_completed": 0,
		"zones_explored": [],
		"bosses_killed": 0,
		"deaths": 0,
		"playtime_seconds": 0,
		"distance_traveled": 0.0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"healing_done": 0
	}
}

# ============================================================================
# PERKS DEFINITION
# ============================================================================

const PERKS := {
	# Combat perks
	"berserker": {
		"name": "Berserker",
		"description": "+15% melee damage when below 30% health",
		"requirement": {"skill": "melee", "level": 25},
		"effect": {"melee_damage_low_hp": 0.15}
	},
	"quick_hands": {
		"name": "Quick Hands",
		"description": "+20% attack speed with melee weapons",
		"requirement": {"skill": "melee", "level": 50},
		"effect": {"melee_attack_speed": 0.20}
	},
	"executioner": {
		"name": "Executioner",
		"description": "+50% damage to enemies below 25% health",
		"requirement": {"skill": "melee", "level": 75},
		"effect": {"execute_damage": 0.50}
	},
	"sharpshooter": {
		"name": "Sharpshooter",
		"description": "+15% headshot damage",
		"requirement": {"skill": "ranged", "level": 25},
		"effect": {"headshot_bonus": 0.15}
	},
	"steady_aim": {
		"name": "Steady Aim",
		"description": "-30% weapon sway while aiming",
		"requirement": {"skill": "ranged", "level": 50},
		"effect": {"weapon_sway": -0.30}
	},
	"penetration": {
		"name": "Armor Penetration",
		"description": "Bullets ignore 20% of enemy armor",
		"requirement": {"skill": "ranged", "level": 75},
		"effect": {"armor_pierce": 0.20}
	},
	"thick_skin": {
		"name": "Thick Skin",
		"description": "+10% damage resistance",
		"requirement": {"skill": "defense", "level": 25},
		"effect": {"damage_resistance": 0.10}
	},
	"second_wind": {
		"name": "Second Wind",
		"description": "Recover 25% health when dropping below 10%",
		"requirement": {"skill": "defense", "level": 50},
		"effect": {"second_wind": true}
	},
	"iron_will": {
		"name": "Iron Will",
		"description": "Cannot be killed by a single hit",
		"requirement": {"skill": "defense", "level": 75},
		"effect": {"one_shot_protection": true}
	},
	
	# Survival perks
	"efficient_gatherer": {
		"name": "Efficient Gatherer",
		"description": "+25% resources from gathering",
		"requirement": {"skill": "gathering", "level": 25},
		"effect": {"gather_bonus": 0.25}
	},
	"master_forager": {
		"name": "Master Forager",
		"description": "Find rare materials while gathering",
		"requirement": {"skill": "gathering", "level": 50},
		"effect": {"rare_gather_chance": 0.15}
	},
	"one_with_nature": {
		"name": "One With Nature",
		"description": "Passive animals don't flee from you",
		"requirement": {"skill": "gathering", "level": 75},
		"effect": {"animal_calm": true}
	},
	"gourmet": {
		"name": "Gourmet",
		"description": "+30% effectiveness from food",
		"requirement": {"skill": "cooking", "level": 25},
		"effect": {"food_bonus": 0.30}
	},
	"master_chef": {
		"name": "Master Chef",
		"description": "Cooked food provides temporary buffs",
		"requirement": {"skill": "cooking", "level": 50},
		"effect": {"food_buffs": true}
	},
	"field_medic": {
		"name": "Field Medic",
		"description": "+25% healing effectiveness",
		"requirement": {"skill": "medicine", "level": 25},
		"effect": {"heal_bonus": 0.25}
	},
	"surgeon": {
		"name": "Surgeon",
		"description": "Medkits restore full health",
		"requirement": {"skill": "medicine", "level": 50},
		"effect": {"full_heal_medkit": true}
	},
	"ghost": {
		"name": "Ghost",
		"description": "+40% stealth effectiveness",
		"requirement": {"skill": "stealth", "level": 25},
		"effect": {"stealth_bonus": 0.40}
	},
	"assassin": {
		"name": "Assassin",
		"description": "+100% damage from stealth attacks",
		"requirement": {"skill": "stealth", "level": 50},
		"effect": {"stealth_damage": 1.0}
	},
	
	# Crafting perks
	"efficient_crafter": {
		"name": "Efficient Crafter",
		"description": "-15% crafting material costs",
		"requirement": {"skill": "weaponsmithing", "level": 25},
		"effect": {"craft_cost_reduction": 0.15}
	},
	"master_smith": {
		"name": "Master Smith",
		"description": "Crafted weapons have +10% damage",
		"requirement": {"skill": "weaponsmithing", "level": 50},
		"effect": {"crafted_weapon_bonus": 0.10}
	},
	"legendary_forger": {
		"name": "Legendary Forger",
		"description": "Chance to craft items at higher quality",
		"requirement": {"skill": "weaponsmithing", "level": 75},
		"effect": {"quality_upgrade_chance": 0.15}
	},
	"reinforced": {
		"name": "Reinforced",
		"description": "Crafted armor has +15% durability",
		"requirement": {"skill": "armorsmithing", "level": 25},
		"effect": {"armor_durability": 0.15}
	},
	"architect": {
		"name": "Architect",
		"description": "-20% building material costs",
		"requirement": {"skill": "construction", "level": 25},
		"effect": {"build_cost_reduction": 0.20}
	},
	"fortress_builder": {
		"name": "Fortress Builder",
		"description": "+30% structure health",
		"requirement": {"skill": "construction", "level": 50},
		"effect": {"structure_health": 0.30}
	},
	"tech_savvy": {
		"name": "Tech Savvy",
		"description": "Electronic devices last 50% longer",
		"requirement": {"skill": "electronics", "level": 25},
		"effect": {"electronic_durability": 0.50}
	},
	
	# Social perks
	"haggler": {
		"name": "Haggler",
		"description": "+15% better trade prices",
		"requirement": {"skill": "trading", "level": 25},
		"effect": {"trade_bonus": 0.15}
	},
	"inspiring_leader": {
		"name": "Inspiring Leader",
		"description": "+10% stats for all party members",
		"requirement": {"skill": "leadership", "level": 25},
		"effect": {"party_buff": 0.10}
	},
	"smooth_talker": {
		"name": "Smooth Talker",
		"description": "Better NPC quest rewards",
		"requirement": {"skill": "persuasion", "level": 25},
		"effect": {"quest_reward_bonus": 0.20}
	}
}

# ============================================================================
# ACHIEVEMENTS
# ============================================================================

const ACHIEVEMENTS := {
	"first_blood": {
		"name": "First Blood",
		"description": "Kill your first zombie",
		"condition": {"stat": "zombies_killed", "value": 1},
		"reward": {"xp": 50}
	},
	"zombie_slayer": {
		"name": "Zombie Slayer",
		"description": "Kill 100 zombies",
		"condition": {"stat": "zombies_killed", "value": 100},
		"reward": {"xp": 500, "skill_points": 1}
	},
	"zombie_nightmare": {
		"name": "Zombie Nightmare",
		"description": "Kill 1000 zombies",
		"condition": {"stat": "zombies_killed", "value": 1000},
		"reward": {"xp": 2500, "skill_points": 3, "perk": "zombie_hunter"}
	},
	"gatherer": {
		"name": "Gatherer",
		"description": "Gather 500 resources",
		"condition": {"stat": "resources_gathered", "value": 500},
		"reward": {"xp": 300}
	},
	"master_crafter": {
		"name": "Master Crafter",
		"description": "Craft 100 items",
		"condition": {"stat": "items_crafted", "value": 100},
		"reward": {"xp": 400, "skill_points": 1}
	},
	"home_builder": {
		"name": "Home Builder",
		"description": "Build 50 structures",
		"condition": {"stat": "structures_built", "value": 50},
		"reward": {"xp": 350}
	},
	"explorer": {
		"name": "Explorer",
		"description": "Explore all zone types",
		"condition": {"stat": "zones_explored", "value": ["green", "yellow", "red", "purple", "black"]},
		"reward": {"xp": 1000, "attribute_points": 1}
	},
	"boss_hunter": {
		"name": "Boss Hunter",
		"description": "Kill 10 bosses",
		"condition": {"stat": "bosses_killed", "value": 10},
		"reward": {"xp": 1500, "skill_points": 2}
	},
	"survivor": {
		"name": "Survivor",
		"description": "Survive for 24 in-game hours",
		"condition": {"stat": "playtime_seconds", "value": 864000},
		"reward": {"xp": 2000, "attribute_points": 1}
	},
	"unstoppable": {
		"name": "Unstoppable",
		"description": "Reach level 50",
		"condition": {"level": 50},
		"reward": {"skill_points": 5, "attribute_points": 2}
	}
}

# ============================================================================
# XP AND LEVELING
# ============================================================================

func add_xp(amount: int, source: String = "") -> void:
	var modified_amount := _apply_xp_modifiers(amount)
	player_data["current_xp"] += modified_amount
	player_data["total_xp"] += modified_amount
	
	# Check for level up
	while _can_level_up():
		_perform_level_up()

func _apply_xp_modifiers(base_amount: int) -> int:
	var modifier := 1.0
	
	# Intelligence bonus
	var intel: int = player_data["attributes"]["intelligence"]
	modifier += (intel - 5) * 0.02  # 2% per point above 5
	
	# Check for XP boost perks
	if has_perk("quick_learner"):
		modifier += 0.15
	
	return int(base_amount * modifier)

func _can_level_up() -> bool:
	if player_data["level"] >= GameConfig.MAX_PLAYER_LEVEL:
		return false
	var required := GameConfig.xp_for_level(player_data["level"])
	return player_data["current_xp"] >= required

func _perform_level_up() -> void:
	var required := GameConfig.xp_for_level(player_data["level"])
	player_data["current_xp"] -= required
	player_data["level"] += 1
	
	var rewards := {
		"skill_points": GameConfig.SKILL_POINTS_PER_LEVEL,
		"attribute_points": GameConfig.ATTRIBUTE_POINTS_PER_LEVEL
	}
	
	player_data["skill_points"] += rewards["skill_points"]
	player_data["attribute_points"] += rewards["attribute_points"]
	
	# Bonus rewards at milestone levels
	if player_data["level"] % 10 == 0:
		rewards["bonus_skill_points"] = 3
		player_data["skill_points"] += 3
	
	emit_signal("level_up", player_data["level"], rewards)
	_check_achievements()

# ============================================================================
# ATTRIBUTES
# ============================================================================

func increase_attribute(attribute: String) -> bool:
	if player_data["attribute_points"] <= 0:
		return false
	if not player_data["attributes"].has(attribute):
		return false
	
	player_data["attributes"][attribute] += 1
	player_data["attribute_points"] -= 1
	
	emit_signal("attribute_increased", attribute, player_data["attributes"][attribute])
	return true

func get_attribute(attribute: String) -> int:
	return player_data["attributes"].get(attribute, 0)

func get_attribute_bonus(attribute: String) -> float:
	var base := get_attribute(attribute)
	return (base - 5) * 0.05  # 5% bonus per point above 5

# ============================================================================
# SKILLS
# ============================================================================

func add_skill_xp(skill: String, amount: int = 1) -> void:
	if not player_data["skills"].has(skill):
		return
	
	var current: int = player_data["skills"][skill]
	if current >= GameConfig.MAX_SKILL_LEVEL:
		return
	
	# Intelligence modifier for skill XP
	var intel_bonus := get_attribute_bonus("intelligence")
	var modified := int(ceil(amount * (1.0 + intel_bonus)))
	
	player_data["skills"][skill] = min(current + modified, GameConfig.MAX_SKILL_LEVEL)
	
	# Check for perk unlocks
	_check_perk_unlocks(skill)
	
	if player_data["skills"][skill] != current:
		emit_signal("skill_leveled", skill, player_data["skills"][skill])

func get_skill(skill: String) -> int:
	return player_data["skills"].get(skill, 0)

func get_skill_bonus(skill: String) -> float:
	var level := get_skill(skill)
	return level * 0.01  # 1% per skill level

# ============================================================================
# PERKS
# ============================================================================

func _check_perk_unlocks(skill: String) -> void:
	var skill_level: int = player_data["skills"][skill]
	
	for perk_id in PERKS:
		if has_perk(perk_id):
			continue
		
		var perk: Dictionary = PERKS[perk_id]
		var req: Dictionary = perk.get("requirement", {})
		
		if req.get("skill", "") == skill and req.get("level", 0) <= skill_level:
			_unlock_perk(perk_id)

func _unlock_perk(perk_id: String) -> void:
	if has_perk(perk_id):
		return
	
	player_data["perks"].append(perk_id)
	emit_signal("perk_unlocked", perk_id)

func has_perk(perk_id: String) -> bool:
	return perk_id in player_data["perks"]

func get_perk_effect(perk_id: String, effect_key: String) -> Variant:
	if not has_perk(perk_id):
		return null
	
	var perk: Dictionary = PERKS.get(perk_id, {})
	return perk.get("effect", {}).get(effect_key)

# ============================================================================
# STATISTICS
# ============================================================================

func increment_stat(stat: String, amount: int = 1) -> void:
	if player_data["stats"].has(stat):
		if player_data["stats"][stat] is int:
			player_data["stats"][stat] += amount
		elif player_data["stats"][stat] is float:
			player_data["stats"][stat] += float(amount)
	_check_achievements()

func add_zone_explored(zone: String) -> void:
	if zone not in player_data["stats"]["zones_explored"]:
		player_data["stats"]["zones_explored"].append(zone)
		add_xp(GameConfig.XP_EXPLORE_NEW_ZONE, "zone_explore")
	_check_achievements()

func get_stat(stat: String) -> Variant:
	return player_data["stats"].get(stat, 0)

# ============================================================================
# ACHIEVEMENTS
# ============================================================================

func _check_achievements() -> void:
	for ach_id in ACHIEVEMENTS:
		if ach_id in player_data["achievements"]:
			continue
		
		var ach: Dictionary = ACHIEVEMENTS[ach_id]
		var cond: Dictionary = ach.get("condition", {})
		
		if _check_achievement_condition(cond):
			_earn_achievement(ach_id)

func _check_achievement_condition(condition: Dictionary) -> bool:
	if condition.has("stat"):
		var stat: String = condition["stat"]
		var required = condition["value"]
		var current = player_data["stats"].get(stat, 0)
		
		if required is Array:
			# All items must be present
			if current is Array:
				for item in required:
					if item not in current:
						return false
				return true
			return false
		else:
			return current >= required
	
	if condition.has("level"):
		return player_data["level"] >= condition["level"]
	
	return false

func _earn_achievement(achievement_id: String) -> void:
	player_data["achievements"].append(achievement_id)
	
	var ach: Dictionary = ACHIEVEMENTS[achievement_id]
	var reward: Dictionary = ach.get("reward", {})
	
	if reward.has("xp"):
		add_xp(reward["xp"], "achievement")
	if reward.has("skill_points"):
		player_data["skill_points"] += reward["skill_points"]
	if reward.has("attribute_points"):
		player_data["attribute_points"] += reward["attribute_points"]
	if reward.has("perk"):
		_unlock_perk(reward["perk"])
	
	emit_signal("achievement_earned", achievement_id)

func has_achievement(achievement_id: String) -> bool:
	return achievement_id in player_data["achievements"]

# ============================================================================
# COMPUTED STATS (for Player script to use)
# ============================================================================

func get_max_health() -> float:
	var base := GameConfig.PLAYER_BASE_HEALTH
	var vitality_bonus := get_attribute_bonus("vitality")
	var defense_bonus := get_skill_bonus("defense")
	return base * (1.0 + vitality_bonus + defense_bonus * 0.5)

func get_max_stamina() -> float:
	var base := GameConfig.PLAYER_BASE_STAMINA
	var agility_bonus := get_attribute_bonus("agility")
	return base * (1.0 + agility_bonus)

func get_move_speed() -> float:
	var base := GameConfig.PLAYER_BASE_MOVE_SPEED
	var agility_bonus := get_attribute_bonus("agility")
	return base * (1.0 + agility_bonus * 0.5)

func get_melee_damage_mult() -> float:
	var strength_bonus := get_attribute_bonus("strength")
	var melee_bonus := get_skill_bonus("melee")
	var total := 1.0 + strength_bonus + melee_bonus
	
	if has_perk("quick_hands"):
		total += 0.20
	
	return total

func get_ranged_damage_mult() -> float:
	var agility_bonus := get_attribute_bonus("agility")
	var ranged_bonus := get_skill_bonus("ranged")
	return 1.0 + agility_bonus * 0.5 + ranged_bonus

func get_crit_chance() -> float:
	var base := GameConfig.CRITICAL_HIT_BASE_CHANCE
	var luck_bonus := get_attribute_bonus("luck")
	var crit_bonus := get_skill_bonus("critical")
	return base + luck_bonus * 0.5 + crit_bonus * 0.5

func get_loot_luck_bonus() -> float:
	var luck := get_attribute_bonus("luck")
	var gather := get_skill_bonus("gathering") * 0.5
	return luck + gather

func get_craft_cost_reduction() -> float:
	var intel_bonus := get_attribute_bonus("intelligence")
	var ws_bonus := get_skill_bonus("weaponsmithing") * 0.5
	var total := intel_bonus * 0.5 + ws_bonus
	
	if has_perk("efficient_crafter"):
		total += 0.15
	
	return min(total, 0.5)  # Cap at 50% reduction

func get_gather_bonus() -> float:
	var bonus := get_skill_bonus("gathering")
	if has_perk("efficient_gatherer"):
		bonus += 0.25
	return bonus

# ============================================================================
# SAVE/LOAD
# ============================================================================

func get_save_data() -> Dictionary:
	return player_data.duplicate(true)

func load_save_data(data: Dictionary) -> void:
	player_data = data.duplicate(true)
	# Ensure all keys exist (for save compatibility)
	_ensure_data_integrity()

func _ensure_data_integrity() -> void:
	# Add any missing keys from the default structure
	if not player_data.has("perks"):
		player_data["perks"] = []
	if not player_data.has("achievements"):
		player_data["achievements"] = []
	# Add other integrity checks as needed
