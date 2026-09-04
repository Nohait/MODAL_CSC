extends Node

## GameConfig - Central configuration for all game systems
## This makes balancing and tuning easy without touching code

# ============================================================================
# PLAYER STATS
# ============================================================================
const PLAYER_BASE_HEALTH := 100.0
const PLAYER_BASE_STAMINA := 100.0
const PLAYER_BASE_HUNGER := 100.0
const PLAYER_BASE_THIRST := 100.0
const PLAYER_BASE_MOVE_SPEED := 220.0
const PLAYER_SPRINT_MULTIPLIER := 1.6
const PLAYER_STAMINA_DRAIN_SPRINT := 18.0
const PLAYER_STAMINA_RECOVERY := 12.0
const PLAYER_HUNGER_DECAY_RATE := 0.08  # per second
const PLAYER_THIRST_DECAY_RATE := 0.12  # per second
const PLAYER_HEALTH_REGEN_RATE := 0.5   # when fed and hydrated

# ============================================================================
# EXPERIENCE AND LEVELING
# ============================================================================
const XP_PER_LEVEL_BASE := 100
const XP_LEVEL_MULTIPLIER := 1.35  # Each level requires more XP
const MAX_PLAYER_LEVEL := 150
const SKILL_POINTS_PER_LEVEL := 2
const ATTRIBUTE_POINTS_PER_LEVEL := 1

# XP rewards for activities
const XP_KILL_ZOMBIE := 15
const XP_KILL_ANIMAL := 10
const XP_HARVEST_RESOURCE := 5
const XP_CRAFT_ITEM := 8
const XP_BUILD_STRUCTURE := 12
const XP_COMPLETE_QUEST := 50
const XP_EXPLORE_NEW_ZONE := 25
const XP_BOSS_KILL := 100

# ============================================================================
# LOOT SYSTEM - More rewarding than LDOE
# ============================================================================
const LOOT_QUALITY_WEIGHTS := {
	"common": 45.0,
	"uncommon": 30.0,
	"rare": 15.0,
	"epic": 7.0,
	"legendary": 2.5,
	"mythic": 0.5
}

const LOOT_QUALITY_MULTIPLIERS := {
	"common": 1.0,
	"uncommon": 1.25,
	"rare": 1.6,
	"epic": 2.0,
	"legendary": 2.8,
	"mythic": 4.0
}

# Guaranteed rare+ loot every X chests
const LOOT_PITY_TIMER_THRESHOLD := 8

# Zone loot quality bonuses
const ZONE_LOOT_BONUSES := {
	"green": 0.0,
	"yellow": 0.15,
	"red": 0.35,
	"purple": 0.55,  # End-game zones
	"black": 0.80    # Raid zones
}

# ============================================================================
# BASE BUILDING
# ============================================================================
const BASE_GRID_SIZE := 32  # pixels
const BASE_MAX_SIZE := Vector2i(50, 50)  # tiles
const BASE_STARTING_SIZE := Vector2i(10, 10)
const BASE_EXPANSION_COST := {"wood": 50, "stone": 30}

# Structure durability multipliers by material
const STRUCTURE_MATERIALS := {
	"wood": {"durability": 1.0, "defense": 1.0},
	"stone": {"durability": 2.5, "defense": 2.0},
	"metal": {"durability": 4.0, "defense": 3.5},
	"reinforced": {"durability": 6.0, "defense": 5.0},
	"titanium": {"durability": 10.0, "defense": 8.0}
}

# ============================================================================
# COMBAT
# ============================================================================
const CRITICAL_HIT_BASE_CHANCE := 0.05
const CRITICAL_HIT_MULTIPLIER := 2.0
const HEADSHOT_MULTIPLIER := 3.0
const ARMOR_DAMAGE_REDUCTION_CAP := 0.75  # Max 75% damage reduction
const WEAPON_DURABILITY_ENABLED := true
const WEAPON_REPAIR_COST_MULTIPLIER := 0.3

# ============================================================================
# ENEMIES
# ============================================================================
const ENEMY_SCALING := {
	"green": {"health_mult": 1.0, "damage_mult": 1.0, "xp_mult": 1.0},
	"yellow": {"health_mult": 1.5, "damage_mult": 1.3, "xp_mult": 1.4},
	"red": {"health_mult": 2.5, "damage_mult": 1.8, "xp_mult": 2.0},
	"purple": {"health_mult": 4.0, "damage_mult": 2.5, "xp_mult": 3.0},
	"black": {"health_mult": 7.0, "damage_mult": 3.5, "xp_mult": 5.0}
}

const HORDE_INTERVAL_HOURS := 24.0  # Real-time hours between hordes
const HORDE_BASE_ENEMY_COUNT := 15
const HORDE_SCALING_PER_DAY := 3  # Extra enemies per in-game day survived

# ============================================================================
# WORLD AND ZONES
# ============================================================================
const DAY_LENGTH_SECONDS := 600.0  # 10 real minutes = 1 game day
const NIGHT_DANGER_MULTIPLIER := 1.5

const ZONE_TRAVEL_TIMES := {
	"green": 30.0,
	"yellow": 60.0,
	"red": 120.0,
	"purple": 180.0,
	"black": 300.0
}

const ZONE_ENERGY_COSTS := {
	"green": 5,
	"yellow": 10,
	"red": 15,
	"purple": 25,
	"black": 40
}

const MAX_ENERGY := 100
const ENERGY_REGEN_RATE := 1  # per minute
const ENERGY_REGEN_RATE_VIP := 2  # for supporters

# ============================================================================
# MULTIPLAYER
# ============================================================================
const MAX_CLAN_SIZE := 30
const MAX_PARTY_SIZE := 4
const TRADE_COOLDOWN_SECONDS := 30.0
const PVP_ENABLED_ZONES := ["red", "purple", "black"]
const RAID_COOLDOWN_HOURS := 24.0
const RAID_PROTECTION_HOURS := 12.0  # After being raided

# ============================================================================
# SKILLS AND PERKS
# ============================================================================
const SKILL_CATEGORIES := {
	"combat": ["melee", "ranged", "defense", "critical"],
	"survival": ["gathering", "cooking", "medicine", "stealth"],
	"crafting": ["weapons", "armor", "construction", "electronics"],
	"social": ["trading", "leadership", "persuasion", "intimidation"]
}

const MAX_SKILL_LEVEL := 100
const SKILL_XP_PER_USE := 1

# ============================================================================
# QUESTS AND EVENTS
# ============================================================================
const DAILY_QUEST_COUNT := 3
const WEEKLY_QUEST_COUNT := 5
const QUEST_REFRESH_HOURS := 24.0

const EVENT_TYPES := [
	"supply_drop",
	"trader_caravan", 
	"infected_horde",
	"resource_surge",
	"boss_spawn",
	"weather_event",
	"rescue_mission"
]

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

static func xp_for_level(level: int) -> int:
	return int(XP_PER_LEVEL_BASE * pow(XP_LEVEL_MULTIPLIER, level - 1))

static func total_xp_for_level(level: int) -> int:
	var total := 0
	for i in range(1, level + 1):
		total += xp_for_level(i)
	return total

static func get_loot_quality(zone: String, luck_bonus: float = 0.0) -> String:
	var zone_bonus: float = ZONE_LOOT_BONUSES.get(zone, 0.0)
	var total_bonus: float = zone_bonus + luck_bonus
	
	var weights := LOOT_QUALITY_WEIGHTS.duplicate()
	# Shift weights toward better loot
	weights["common"] *= max(0.1, 1.0 - total_bonus)
	weights["uncommon"] *= 1.0 + total_bonus * 0.5
	weights["rare"] *= 1.0 + total_bonus
	weights["epic"] *= 1.0 + total_bonus * 1.5
	weights["legendary"] *= 1.0 + total_bonus * 2.0
	weights["mythic"] *= 1.0 + total_bonus * 3.0
	
	var total_weight := 0.0
	for w in weights.values():
		total_weight += w
	
	var roll := randf() * total_weight
	var cumulative := 0.0
	for quality in weights.keys():
		cumulative += weights[quality]
		if roll <= cumulative:
			return quality
	
	return "common"
