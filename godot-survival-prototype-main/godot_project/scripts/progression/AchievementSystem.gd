extends Node
class_name AchievementSystemClass
## Comprehensive achievement and trophy system
## Tracks player progress, unlocks achievements, and provides rewards

signal achievement_unlocked(achievement_id: String)
signal achievement_progress(achievement_id: String, current: float, target: float)
signal tier_unlocked(achievement_id: String, tier: int)
signal achievement_points_changed(total_points: int)
signal reward_claimed(achievement_id: String, rewards: Array)

# ============================================================================
# ACHIEVEMENT CONFIGURATION
# ============================================================================

enum AchievementCategory {
	COMBAT,
	SURVIVAL,
	EXPLORATION,
	CRAFTING,
	BUILDING,
	SOCIAL,
	COLLECTION,
	CHALLENGE,
	STORY,
	SECRET,
}

enum AchievementRarity {
	COMMON,      # 10 points
	UNCOMMON,    # 25 points
	RARE,        # 50 points
	EPIC,        # 100 points
	LEGENDARY,   # 250 points
}

enum RewardType {
	ITEM,
	CURRENCY,
	EXPERIENCE,
	COSMETIC,
	BLUEPRINT,
	TITLE,
	BADGE,
}

const RARITY_POINTS := {
	AchievementRarity.COMMON: 10,
	AchievementRarity.UNCOMMON: 25,
	AchievementRarity.RARE: 50,
	AchievementRarity.EPIC: 100,
	AchievementRarity.LEGENDARY: 250,
}

const RARITY_COLORS := {
	AchievementRarity.COMMON: Color(0.7, 0.7, 0.7),
	AchievementRarity.UNCOMMON: Color(0.3, 0.8, 0.3),
	AchievementRarity.RARE: Color(0.3, 0.5, 0.9),
	AchievementRarity.EPIC: Color(0.7, 0.3, 0.9),
	AchievementRarity.LEGENDARY: Color(1.0, 0.6, 0.1),
}

# Achievement definitions
const ACHIEVEMENT_DEFINITIONS := {
	# ==================== COMBAT ====================
	"first_blood": {
		"name": "First Blood",
		"description": "Kill your first enemy",
		"category": AchievementCategory.COMBAT,
		"rarity": AchievementRarity.COMMON,
		"icon": "achievement_first_blood",
		"stat": "enemies_killed",
		"target": 1,
		"rewards": [
			{"type": RewardType.EXPERIENCE, "amount": 100},
		],
	},
	"zombie_slayer": {
		"name": "Zombie Slayer",
		"description": "Kill 100 zombies",
		"category": AchievementCategory.COMBAT,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_zombie_slayer",
		"stat": "zombies_killed",
		"target": 100,
		"tiers": [10, 50, 100, 500, 1000],  # Tiered achievement
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "ammo_9mm", "amount": 50},
			{"type": RewardType.TITLE, "title": "Zombie Slayer"},
		],
	},
	"headhunter": {
		"name": "Headhunter",
		"description": "Get 50 headshot kills",
		"category": AchievementCategory.COMBAT,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_headhunter",
		"stat": "headshot_kills",
		"target": 50,
		"tiers": [10, 25, 50, 100, 250],
		"rewards": [
			{"type": RewardType.BLUEPRINT, "blueprint_id": "scope_advanced"},
		],
	},
	"melee_master": {
		"name": "Melee Master",
		"description": "Kill 100 enemies with melee weapons",
		"category": AchievementCategory.COMBAT,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_melee_master",
		"stat": "melee_kills",
		"target": 100,
		"rewards": [
			{"type": RewardType.BLUEPRINT, "blueprint_id": "machete_legendary"},
		],
	},
	"boss_hunter": {
		"name": "Boss Hunter",
		"description": "Defeat 10 boss enemies",
		"category": AchievementCategory.COMBAT,
		"rarity": AchievementRarity.EPIC,
		"icon": "achievement_boss_hunter",
		"stat": "bosses_killed",
		"target": 10,
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "weapon_crate_epic", "amount": 1},
			{"type": RewardType.TITLE, "title": "Boss Slayer"},
		],
	},
	"pacifist_run": {
		"name": "Pacifist",
		"description": "Complete a zone without killing anything",
		"category": AchievementCategory.COMBAT,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_pacifist",
		"stat": "pacifist_zones_completed",
		"target": 1,
		"secret": true,
		"rewards": [
			{"type": RewardType.COSMETIC, "cosmetic_id": "outfit_peaceful"},
		],
	},
	"combo_master": {
		"name": "Combo Master",
		"description": "Get a 20 kill streak without taking damage",
		"category": AchievementCategory.COMBAT,
		"rarity": AchievementRarity.EPIC,
		"icon": "achievement_combo",
		"stat": "highest_killstreak",
		"target": 20,
		"rewards": [
			{"type": RewardType.BADGE, "badge_id": "badge_killstreak"},
		],
	},
	
	# ==================== SURVIVAL ====================
	"survivor_day_1": {
		"name": "Day One",
		"description": "Survive your first day",
		"category": AchievementCategory.SURVIVAL,
		"rarity": AchievementRarity.COMMON,
		"icon": "achievement_day1",
		"stat": "days_survived",
		"target": 1,
		"rewards": [
			{"type": RewardType.EXPERIENCE, "amount": 50},
		],
	},
	"survivor_week": {
		"name": "One Week Later",
		"description": "Survive 7 days",
		"category": AchievementCategory.SURVIVAL,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_week",
		"stat": "days_survived",
		"target": 7,
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "supply_crate", "amount": 1},
		],
	},
	"survivor_month": {
		"name": "30 Days of Survival",
		"description": "Survive 30 days",
		"category": AchievementCategory.SURVIVAL,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_month",
		"stat": "days_survived",
		"target": 30,
		"rewards": [
			{"type": RewardType.TITLE, "title": "Veteran Survivor"},
		],
	},
	"survivor_100": {
		"name": "Centenarian",
		"description": "Survive 100 days",
		"category": AchievementCategory.SURVIVAL,
		"rarity": AchievementRarity.LEGENDARY,
		"icon": "achievement_100days",
		"stat": "days_survived",
		"target": 100,
		"rewards": [
			{"type": RewardType.COSMETIC, "cosmetic_id": "outfit_veteran"},
			{"type": RewardType.TITLE, "title": "Centenarian"},
		],
	},
	"horde_survivor": {
		"name": "Horde Night Survivor",
		"description": "Survive 10 horde nights",
		"category": AchievementCategory.SURVIVAL,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_horde",
		"stat": "hordes_survived",
		"target": 10,
		"tiers": [1, 5, 10, 25, 50],
		"rewards": [
			{"type": RewardType.BLUEPRINT, "blueprint_id": "turret_advanced"},
		],
	},
	"close_call": {
		"name": "Close Call",
		"description": "Survive with less than 5% health",
		"category": AchievementCategory.SURVIVAL,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_close_call",
		"stat": "near_death_survivals",
		"target": 1,
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "medkit", "amount": 5},
		],
	},
	"iron_stomach": {
		"name": "Iron Stomach",
		"description": "Eat 50 spoiled food items without dying",
		"category": AchievementCategory.SURVIVAL,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_iron_stomach",
		"stat": "spoiled_food_eaten",
		"target": 50,
		"secret": true,
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "antidote", "amount": 10},
		],
	},
	
	# ==================== EXPLORATION ====================
	"explorer_green": {
		"name": "Green Zone Explorer",
		"description": "Explore all green zone locations",
		"category": AchievementCategory.EXPLORATION,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_green_zone",
		"stat": "green_zones_explored",
		"target": 10,
		"rewards": [
			{"type": RewardType.EXPERIENCE, "amount": 200},
		],
	},
	"explorer_yellow": {
		"name": "Yellow Zone Explorer",
		"description": "Explore all yellow zone locations",
		"category": AchievementCategory.EXPLORATION,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_yellow_zone",
		"stat": "yellow_zones_explored",
		"target": 10,
		"rewards": [
			{"type": RewardType.BLUEPRINT, "blueprint_id": "armor_medium"},
		],
	},
	"explorer_red": {
		"name": "Red Zone Explorer",
		"description": "Explore all red zone locations",
		"category": AchievementCategory.EXPLORATION,
		"rarity": AchievementRarity.EPIC,
		"icon": "achievement_red_zone",
		"stat": "red_zones_explored",
		"target": 10,
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "weapon_crate_rare", "amount": 3},
		],
	},
	"dungeon_crawler": {
		"name": "Dungeon Crawler",
		"description": "Complete 20 dungeons",
		"category": AchievementCategory.EXPLORATION,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_dungeon",
		"stat": "dungeons_completed",
		"target": 20,
		"tiers": [1, 5, 10, 20, 50],
		"rewards": [
			{"type": RewardType.TITLE, "title": "Dungeon Master"},
		],
	},
	"treasure_hunter": {
		"name": "Treasure Hunter",
		"description": "Open 100 loot containers",
		"category": AchievementCategory.EXPLORATION,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_treasure",
		"stat": "containers_looted",
		"target": 100,
		"tiers": [10, 50, 100, 500, 1000],
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "lockpick", "amount": 20},
		],
	},
	"world_traveler": {
		"name": "World Traveler",
		"description": "Travel 100km total distance",
		"category": AchievementCategory.EXPLORATION,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_traveler",
		"stat": "distance_traveled_km",
		"target": 100,
		"tiers": [10, 50, 100, 500, 1000],
		"rewards": [
			{"type": RewardType.BLUEPRINT, "blueprint_id": "vehicle_atv"},
		],
	},
	
	# ==================== CRAFTING ====================
	"first_craft": {
		"name": "DIY Survivor",
		"description": "Craft your first item",
		"category": AchievementCategory.CRAFTING,
		"rarity": AchievementRarity.COMMON,
		"icon": "achievement_first_craft",
		"stat": "items_crafted",
		"target": 1,
		"rewards": [
			{"type": RewardType.EXPERIENCE, "amount": 25},
		],
	},
	"master_crafter": {
		"name": "Master Crafter",
		"description": "Craft 500 items",
		"category": AchievementCategory.CRAFTING,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_master_crafter",
		"stat": "items_crafted",
		"target": 500,
		"tiers": [10, 50, 100, 250, 500],
		"rewards": [
			{"type": RewardType.TITLE, "title": "Master Crafter"},
			{"type": RewardType.ITEM, "item_id": "crafting_kit", "amount": 1},
		],
	},
	"recipe_collector": {
		"name": "Recipe Collector",
		"description": "Unlock 50 crafting recipes",
		"category": AchievementCategory.CRAFTING,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_recipes",
		"stat": "recipes_unlocked",
		"target": 50,
		"rewards": [
			{"type": RewardType.BLUEPRINT, "blueprint_id": "random_rare"},
		],
	},
	"weaponsmith": {
		"name": "Weaponsmith",
		"description": "Craft 25 weapons",
		"category": AchievementCategory.CRAFTING,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_weaponsmith",
		"stat": "weapons_crafted",
		"target": 25,
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "weapon_parts", "amount": 50},
		],
	},
	"chemist": {
		"name": "Chemist",
		"description": "Craft 50 medical items",
		"category": AchievementCategory.CRAFTING,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_chemist",
		"stat": "medical_items_crafted",
		"target": 50,
		"rewards": [
			{"type": RewardType.BLUEPRINT, "blueprint_id": "medkit_advanced"},
		],
	},
	
	# ==================== BUILDING ====================
	"home_builder": {
		"name": "Home Sweet Home",
		"description": "Build your first structure",
		"category": AchievementCategory.BUILDING,
		"rarity": AchievementRarity.COMMON,
		"icon": "achievement_first_build",
		"stat": "structures_built",
		"target": 1,
		"rewards": [
			{"type": RewardType.EXPERIENCE, "amount": 50},
		],
	},
	"architect": {
		"name": "Architect",
		"description": "Build 100 structures",
		"category": AchievementCategory.BUILDING,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_architect",
		"stat": "structures_built",
		"target": 100,
		"tiers": [10, 25, 50, 100, 250],
		"rewards": [
			{"type": RewardType.TITLE, "title": "Master Architect"},
		],
	},
	"fortress": {
		"name": "Fortress",
		"description": "Upgrade your base to maximum level",
		"category": AchievementCategory.BUILDING,
		"rarity": AchievementRarity.EPIC,
		"icon": "achievement_fortress",
		"stat": "base_max_level",
		"target": 1,
		"rewards": [
			{"type": RewardType.COSMETIC, "cosmetic_id": "base_flag_gold"},
		],
	},
	"defense_specialist": {
		"name": "Defense Specialist",
		"description": "Build 20 defense structures",
		"category": AchievementCategory.BUILDING,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_defense",
		"stat": "defenses_built",
		"target": 20,
		"rewards": [
			{"type": RewardType.BLUEPRINT, "blueprint_id": "turret_basic"},
		],
	},
	
	# ==================== SOCIAL ====================
	"team_player": {
		"name": "Team Player",
		"description": "Complete a mission with other players",
		"category": AchievementCategory.SOCIAL,
		"rarity": AchievementRarity.COMMON,
		"icon": "achievement_team",
		"stat": "coop_missions_completed",
		"target": 1,
		"rewards": [
			{"type": RewardType.EXPERIENCE, "amount": 100},
		],
	},
	"lifesaver": {
		"name": "Lifesaver",
		"description": "Revive other players 25 times",
		"category": AchievementCategory.SOCIAL,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_lifesaver",
		"stat": "players_revived",
		"target": 25,
		"tiers": [1, 5, 10, 25, 50],
		"rewards": [
			{"type": RewardType.TITLE, "title": "Lifesaver"},
		],
	},
	"generous": {
		"name": "Generous",
		"description": "Share 100 items with other players",
		"category": AchievementCategory.SOCIAL,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_generous",
		"stat": "items_shared",
		"target": 100,
		"rewards": [
			{"type": RewardType.CURRENCY, "amount": 500},
		],
	},
	"trader": {
		"name": "Trader",
		"description": "Complete 50 trades with NPCs",
		"category": AchievementCategory.SOCIAL,
		"rarity": AchievementRarity.UNCOMMON,
		"icon": "achievement_trader",
		"stat": "npc_trades",
		"target": 50,
		"tiers": [5, 15, 30, 50, 100],
		"rewards": [
			{"type": RewardType.CURRENCY, "amount": 1000},
		],
	},
	"faction_ally": {
		"name": "Faction Ally",
		"description": "Reach maximum reputation with a faction",
		"category": AchievementCategory.SOCIAL,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_faction",
		"stat": "max_faction_rep",
		"target": 1,
		"rewards": [
			{"type": RewardType.TITLE, "title": "Faction Champion"},
		],
	},
	
	# ==================== COLLECTION ====================
	"collector": {
		"name": "Collector",
		"description": "Collect 100 unique items",
		"category": AchievementCategory.COLLECTION,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_collector",
		"stat": "unique_items_collected",
		"target": 100,
		"tiers": [25, 50, 75, 100, 150],
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "mystery_box", "amount": 1},
		],
	},
	"weapon_collector": {
		"name": "Arsenal",
		"description": "Collect 25 different weapons",
		"category": AchievementCategory.COLLECTION,
		"rarity": AchievementRarity.RARE,
		"icon": "achievement_arsenal",
		"stat": "unique_weapons_collected",
		"target": 25,
		"rewards": [
			{"type": RewardType.COSMETIC, "cosmetic_id": "weapon_skin_gold"},
		],
	},
	"vehicle_collector": {
		"name": "Motorhead",
		"description": "Own all vehicle types",
		"category": AchievementCategory.COLLECTION,
		"rarity": AchievementRarity.LEGENDARY,
		"icon": "achievement_motorhead",
		"stat": "unique_vehicles_owned",
		"target": 10,
		"rewards": [
			{"type": RewardType.COSMETIC, "cosmetic_id": "vehicle_skin_legendary"},
		],
	},
	
	# ==================== SECRET ====================
	"easter_egg_1": {
		"name": "???",
		"description": "Find the hidden bunker",
		"category": AchievementCategory.SECRET,
		"rarity": AchievementRarity.EPIC,
		"icon": "achievement_secret",
		"stat": "secret_bunker_found",
		"target": 1,
		"secret": true,
		"hidden_name": "Underground Discovery",
		"hidden_description": "You found the secret bunker!",
		"rewards": [
			{"type": RewardType.ITEM, "item_id": "legendary_loot_box", "amount": 1},
		],
	},
}


# ============================================================================
# STATE
# ============================================================================

var _achievement_progress: Dictionary = {}  # achievement_id -> current value
var _unlocked_achievements: Dictionary = {}  # achievement_id -> unlock timestamp
var _tier_progress: Dictionary = {}  # achievement_id -> current tier (0-based)
var _claimed_rewards: Dictionary = {}  # achievement_id -> true/false
var _total_points: int = 0
var _stats: Dictionary = {}  # stat_name -> value


func _ready() -> void:
	_initialize_achievements()


func _initialize_achievements() -> void:
	for achievement_id in ACHIEVEMENT_DEFINITIONS:
		_achievement_progress[achievement_id] = 0
		_tier_progress[achievement_id] = -1  # -1 = no tier unlocked


# ============================================================================
# STAT TRACKING
# ============================================================================

func increment_stat(stat_name: String, amount: int = 1) -> void:
	if stat_name not in _stats:
		_stats[stat_name] = 0
	
	_stats[stat_name] += amount
	
	_check_achievements_for_stat(stat_name)


func set_stat(stat_name: String, value: int) -> void:
	var old_value: int = _stats.get(stat_name, 0)
	_stats[stat_name] = value
	
	if value > old_value:
		_check_achievements_for_stat(stat_name)


func get_stat(stat_name: String) -> int:
	return _stats.get(stat_name, 0)


func set_stat_max(stat_name: String, value: int) -> void:
	var current: int = _stats.get(stat_name, 0)
	if value > current:
		set_stat(stat_name, value)


# ============================================================================
# ACHIEVEMENT CHECKING
# ============================================================================

func _check_achievements_for_stat(stat_name: String) -> void:
	for achievement_id in ACHIEVEMENT_DEFINITIONS:
		var achievement: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id]
		
		if achievement.get("stat", "") != stat_name:
			continue
		
		var current: int = _stats.get(stat_name, 0)
		var target: int = achievement.get("target", 1)
		
		_achievement_progress[achievement_id] = current
		
		# Check tiers
		if "tiers" in achievement:
			_check_tiers(achievement_id, current, achievement["tiers"])
		
		# Check main unlock
		if achievement_id not in _unlocked_achievements:
			if current >= target:
				_unlock_achievement(achievement_id)
			else:
				emit_signal("achievement_progress", achievement_id, current, target)


func _check_tiers(achievement_id: String, current: int, tiers: Array) -> void:
	var current_tier: int = _tier_progress.get(achievement_id, -1)
	
	for i in range(tiers.size()):
		if i <= current_tier:
			continue
		
		if current >= tiers[i]:
			_tier_progress[achievement_id] = i
			emit_signal("tier_unlocked", achievement_id, i)


func _unlock_achievement(achievement_id: String) -> void:
	if achievement_id in _unlocked_achievements:
		return
	
	var achievement: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id]
	
	_unlocked_achievements[achievement_id] = Time.get_unix_time_from_system()
	
	# Add points
	var rarity: int = achievement.get("rarity", AchievementRarity.COMMON)
	var points: int = RARITY_POINTS.get(rarity, 10)
	_total_points += points
	
	emit_signal("achievement_unlocked", achievement_id)
	emit_signal("achievement_points_changed", _total_points)


# ============================================================================
# MANUAL UNLOCK
# ============================================================================

func unlock_achievement(achievement_id: String) -> Dictionary:
	if achievement_id not in ACHIEVEMENT_DEFINITIONS:
		return {"success": false, "error": "Unknown achievement"}
	
	if achievement_id in _unlocked_achievements:
		return {"success": false, "error": "Already unlocked"}
	
	_unlock_achievement(achievement_id)
	
	return {"success": true}


# ============================================================================
# REWARDS
# ============================================================================

func claim_reward(achievement_id: String) -> Dictionary:
	if achievement_id not in ACHIEVEMENT_DEFINITIONS:
		return {"success": false, "error": "Unknown achievement"}
	
	if achievement_id not in _unlocked_achievements:
		return {"success": false, "error": "Achievement not unlocked"}
	
	if _claimed_rewards.get(achievement_id, false):
		return {"success": false, "error": "Reward already claimed"}
	
	var achievement: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id]
	var rewards: Array = achievement.get("rewards", [])
	
	_claimed_rewards[achievement_id] = true
	
	# Actually grant rewards via other systems
	for reward in rewards:
		_grant_reward(reward)
	
	emit_signal("reward_claimed", achievement_id, rewards)
	
	return {"success": true, "rewards": rewards}


func _grant_reward(reward: Dictionary) -> void:
	var reward_type: int = reward.get("type", RewardType.EXPERIENCE)
	
	match reward_type:
		RewardType.ITEM:
			# Would call InventorySystem
			pass
		RewardType.CURRENCY:
			# Would call economy system
			pass
		RewardType.EXPERIENCE:
			# Would call ProgressionSystem
			pass
		RewardType.COSMETIC:
			# Would call cosmetics system
			pass
		RewardType.BLUEPRINT:
			# Would call CraftingManager
			pass
		RewardType.TITLE:
			# Would call profile system
			pass
		RewardType.BADGE:
			# Would call profile system
			pass


# ============================================================================
# QUERIES
# ============================================================================

func is_achievement_unlocked(achievement_id: String) -> bool:
	return achievement_id in _unlocked_achievements


func is_reward_claimed(achievement_id: String) -> bool:
	return _claimed_rewards.get(achievement_id, false)


func get_achievement_progress(achievement_id: String) -> float:
	if achievement_id not in ACHIEVEMENT_DEFINITIONS:
		return 0.0
	
	var achievement: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id]
	var current: float = _achievement_progress.get(achievement_id, 0)
	var target: float = achievement.get("target", 1)
	
	return current / target if target > 0 else 1.0


func get_achievement_data(achievement_id: String) -> Dictionary:
	if achievement_id not in ACHIEVEMENT_DEFINITIONS:
		return {}
	
	var achievement: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id].duplicate()
	var is_secret: bool = achievement.get("secret", false)
	var is_unlocked: bool = is_achievement_unlocked(achievement_id)
	
	# Reveal secret achievement details if unlocked
	if is_secret and is_unlocked:
		if "hidden_name" in achievement:
			achievement["name"] = achievement["hidden_name"]
		if "hidden_description" in achievement:
			achievement["description"] = achievement["hidden_description"]
	
	achievement["unlocked"] = is_unlocked
	achievement["progress"] = _achievement_progress.get(achievement_id, 0)
	achievement["reward_claimed"] = is_reward_claimed(achievement_id)
	achievement["current_tier"] = _tier_progress.get(achievement_id, -1)
	
	if is_unlocked:
		achievement["unlock_time"] = _unlocked_achievements[achievement_id]
	
	return achievement


func get_achievements_by_category(category: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for achievement_id in ACHIEVEMENT_DEFINITIONS:
		var achievement: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id]
		
		if achievement.get("category", -1) != category:
			continue
		
		# Skip hidden secret achievements
		if achievement.get("secret", false) and not is_achievement_unlocked(achievement_id):
			continue
		
		result.append(get_achievement_data(achievement_id))
	
	return result


func get_all_achievements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for achievement_id in ACHIEVEMENT_DEFINITIONS:
		var achievement: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id]
		
		# Include secret achievements but with hidden info
		result.append(get_achievement_data(achievement_id))
	
	return result


func get_unlocked_achievements() -> Array[String]:
	var result: Array[String] = []
	for achievement_id in _unlocked_achievements:
		result.append(achievement_id)
	return result


func get_unclaimed_rewards() -> Array[String]:
	var result: Array[String] = []
	for achievement_id in _unlocked_achievements:
		if not _claimed_rewards.get(achievement_id, false):
			result.append(achievement_id)
	return result


func get_total_points() -> int:
	return _total_points


func get_completion_percent() -> float:
	var total := ACHIEVEMENT_DEFINITIONS.size()
	var unlocked := _unlocked_achievements.size()
	return float(unlocked) / float(total) if total > 0 else 0.0


func get_recent_achievements(count: int = 5) -> Array[Dictionary]:
	var unlocked: Array[Dictionary] = []
	
	for achievement_id in _unlocked_achievements:
		unlocked.append({
			"id": achievement_id,
			"time": _unlocked_achievements[achievement_id],
		})
	
	# Sort by unlock time descending
	unlocked.sort_custom(func(a, b): return a["time"] > b["time"])
	
	var result: Array[Dictionary] = []
	for i in range(min(count, unlocked.size())):
		result.append(get_achievement_data(unlocked[i]["id"]))
	
	return result


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"stats": _stats.duplicate(),
		"progress": _achievement_progress.duplicate(),
		"unlocked": _unlocked_achievements.duplicate(),
		"tiers": _tier_progress.duplicate(),
		"claimed": _claimed_rewards.duplicate(),
		"total_points": _total_points,
	}


func load_data(data: Dictionary) -> void:
	_stats = data.get("stats", {})
	_achievement_progress = data.get("progress", {})
	_unlocked_achievements = data.get("unlocked", {})
	_tier_progress = data.get("tiers", {})
	_claimed_rewards = data.get("claimed", {})
	_total_points = data.get("total_points", 0)
	
	# Initialize any new achievements
	for achievement_id in ACHIEVEMENT_DEFINITIONS:
		if achievement_id not in _achievement_progress:
			_achievement_progress[achievement_id] = 0
		if achievement_id not in _tier_progress:
			_tier_progress[achievement_id] = -1


# ============================================================================
# DEBUG
# ============================================================================

func unlock_all() -> void:
	for achievement_id in ACHIEVEMENT_DEFINITIONS:
		if achievement_id not in _unlocked_achievements:
			_unlock_achievement(achievement_id)


func reset_all() -> void:
	_stats.clear()
	_achievement_progress.clear()
	_unlocked_achievements.clear()
	_tier_progress.clear()
	_claimed_rewards.clear()
	_total_points = 0
	_initialize_achievements()
