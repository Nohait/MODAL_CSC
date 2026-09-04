extends Node
class_name BossSystemClass
## Manages boss encounters, arenas, mechanics, and rewards
## Handles boss spawning, phases, abilities, and loot

signal boss_encounter_started(boss_data: Dictionary)
signal boss_phase_changed(boss_id: String, phase: int)
signal boss_ability_used(boss_id: String, ability: String)
signal boss_enraged(boss_id: String)
signal boss_stunned(boss_id: String, duration: float)
signal boss_health_threshold(boss_id: String, percent: float)
signal boss_defeated(boss_id: String, rewards: Dictionary)
signal boss_despawned(boss_id: String, reason: String)
signal arena_activated(arena_id: String)
signal arena_hazard_spawned(hazard_type: String)

# ============================================================================
# BOSS CONFIGURATION
# ============================================================================

enum BossType {
	# Zombie Bosses
	BLOAT_KING,
	FERAL_ALPHA,
	SCREAMER_QUEEN,
	IRRADIATED_HULK,
	HORDE_OVERLORD,
	
	# Military Bosses
	INFECTED_GENERAL,
	ROGUE_COMMANDER,
	MECH_OPERATOR,
	
	# Dungeon Bosses
	BUNKER_COMMANDER,
	SEWER_BEAST,
	THE_SURGEON,
	RIOT_CHIEF,
	EXPERIMENT_ZERO,
	VAULT_OVERSEER,
	TUNNEL_KING,
	DEEP_DWELLER,
	
	# World Bosses
	THE_COLOSSUS,
	PLAGUE_BEARER,
	MUTANT_TITAN,
	DEATH_MACHINE,
}

enum BossPhase {
	PHASE_1,
	PHASE_2,
	PHASE_3,
	ENRAGED,
}

enum AbilityType {
	MELEE_ATTACK,
	RANGED_ATTACK,
	AOE_ATTACK,
	SUMMON,
	BUFF,
	DEBUFF,
	CHARGE,
	LEAP,
	GROUND_SLAM,
	PROJECTILE_BARRAGE,
	SHIELD,
	HEAL,
	ENRAGE,
	TELEPORT,
}

const BOSS_DEFINITIONS := {
	BossType.BLOAT_KING: {
		"display_name": "The Bloat King",
		"description": "Massive bloated zombie that explodes into smaller enemies.",
		"health": 5000,
		"damage": 40,
		"speed": 20.0,
		"armor": 20,
		"phases": 3,
		"phase_thresholds": [0.7, 0.4, 0.15],
		"abilities": {
			BossPhase.PHASE_1: ["toxic_spray", "bloat_summon"],
			BossPhase.PHASE_2: ["toxic_spray", "bloat_summon", "ground_slam"],
			BossPhase.PHASE_3: ["toxic_spray", "bloat_summon", "ground_slam", "explosive_charge"],
			BossPhase.ENRAGED: ["toxic_barrage", "mass_summon"],
		},
		"enrage_timer": 300.0,
		"loot_table": "boss_bloat_king",
		"arena_type": "toxic_arena",
		"music": "boss_grotesque",
		"min_level": 10,
	},
	BossType.FERAL_ALPHA: {
		"display_name": "The Feral Alpha",
		"description": "Lightning-fast pack leader with devastating attacks.",
		"health": 3500,
		"damage": 60,
		"speed": 120.0,
		"armor": 10,
		"phases": 3,
		"phase_thresholds": [0.65, 0.35, 0.1],
		"abilities": {
			BossPhase.PHASE_1: ["claw_swipe", "leap_attack"],
			BossPhase.PHASE_2: ["claw_swipe", "leap_attack", "pack_howl"],
			BossPhase.PHASE_3: ["frenzy", "leap_attack", "pack_howl"],
			BossPhase.ENRAGED: ["berserker_rampage"],
		},
		"enrage_timer": 240.0,
		"loot_table": "boss_feral_alpha",
		"arena_type": "forest_clearing",
		"music": "boss_feral",
		"min_level": 8,
	},
	BossType.SCREAMER_QUEEN: {
		"display_name": "The Screamer Queen",
		"description": "Horrifying matriarch that controls the horde.",
		"health": 4000,
		"damage": 30,
		"speed": 40.0,
		"armor": 15,
		"phases": 3,
		"phase_thresholds": [0.7, 0.4, 0.15],
		"abilities": {
			BossPhase.PHASE_1: ["sonic_scream", "summon_screamers"],
			BossPhase.PHASE_2: ["sonic_scream", "summon_screamers", "fear_wave"],
			BossPhase.PHASE_3: ["banshee_wail", "mass_summon", "fear_wave"],
			BossPhase.ENRAGED: ["endless_scream", "horde_frenzy"],
		},
		"enrage_timer": 360.0,
		"loot_table": "boss_screamer_queen",
		"arena_type": "echo_chamber",
		"music": "boss_horror",
		"min_level": 15,
	},
	BossType.IRRADIATED_HULK: {
		"display_name": "The Irradiated Hulk",
		"description": "Massive mutant leaking deadly radiation.",
		"health": 8000,
		"damage": 80,
		"speed": 25.0,
		"armor": 40,
		"phases": 3,
		"phase_thresholds": [0.6, 0.3, 0.1],
		"abilities": {
			BossPhase.PHASE_1: ["radiation_pulse", "ground_slam"],
			BossPhase.PHASE_2: ["radiation_pulse", "ground_slam", "radioactive_breath"],
			BossPhase.PHASE_3: ["meltdown", "ground_slam", "radioactive_breath"],
			BossPhase.ENRAGED: ["nuclear_explosion"],
		},
		"passive": "radiation_aura",
		"enrage_timer": 420.0,
		"loot_table": "boss_irradiated_hulk",
		"arena_type": "reactor_room",
		"music": "boss_menacing",
		"min_level": 25,
	},
	BossType.HORDE_OVERLORD: {
		"display_name": "The Horde Overlord",
		"description": "Ancient zombie commanding the endless horde.",
		"health": 10000,
		"damage": 70,
		"speed": 35.0,
		"armor": 35,
		"phases": 4,
		"phase_thresholds": [0.75, 0.5, 0.25, 0.1],
		"abilities": {
			BossPhase.PHASE_1: ["command_horde", "dark_strike"],
			BossPhase.PHASE_2: ["command_horde", "dark_strike", "corruption_wave"],
			BossPhase.PHASE_3: ["endless_summon", "dark_strike", "corruption_wave", "death_grip"],
			BossPhase.ENRAGED: ["apocalypse"],
		},
		"enrage_timer": 480.0,
		"loot_table": "boss_horde_overlord",
		"arena_type": "throne_room",
		"music": "boss_epic",
		"min_level": 40,
	},
	BossType.INFECTED_GENERAL: {
		"display_name": "Infected General",
		"description": "Former military leader turned powerful zombie.",
		"health": 6000,
		"damage": 55,
		"speed": 45.0,
		"armor": 45,
		"phases": 3,
		"phase_thresholds": [0.65, 0.35, 0.1],
		"abilities": {
			BossPhase.PHASE_1: ["tactical_strike", "grenade_barrage"],
			BossPhase.PHASE_2: ["tactical_strike", "grenade_barrage", "call_reinforcements"],
			BossPhase.PHASE_3: ["airstrike", "tactical_strike", "call_reinforcements"],
			BossPhase.ENRAGED: ["full_assault"],
		},
		"enrage_timer": 360.0,
		"loot_table": "boss_military",
		"arena_type": "military_base",
		"music": "boss_military",
		"min_level": 35,
	},
	BossType.THE_SURGEON: {
		"display_name": "The Surgeon",
		"description": "Demented doctor who experiments on the living.",
		"health": 4500,
		"damage": 45,
		"speed": 55.0,
		"armor": 15,
		"phases": 3,
		"phase_thresholds": [0.7, 0.4, 0.15],
		"abilities": {
			BossPhase.PHASE_1: ["scalpel_throw", "sedative_cloud"],
			BossPhase.PHASE_2: ["scalpel_throw", "sedative_cloud", "summon_patients"],
			BossPhase.PHASE_3: ["surgery", "mass_sedation", "summon_patients"],
			BossPhase.ENRAGED: ["experimental_serum"],
		},
		"enrage_timer": 300.0,
		"loot_table": "boss_hospital",
		"arena_type": "operating_room",
		"music": "boss_horror",
		"min_level": 12,
	},
	BossType.EXPERIMENT_ZERO: {
		"display_name": "Experiment Zero",
		"description": "The first and most dangerous lab experiment.",
		"health": 7000,
		"damage": 65,
		"speed": 60.0,
		"armor": 25,
		"phases": 4,
		"phase_thresholds": [0.75, 0.5, 0.25, 0.1],
		"abilities": {
			BossPhase.PHASE_1: ["acid_spit", "mutant_strike"],
			BossPhase.PHASE_2: ["acid_spit", "mutant_strike", "regeneration"],
			BossPhase.PHASE_3: ["acid_spray", "mutation_burst", "regeneration"],
			BossPhase.ENRAGED: ["final_mutation", "unstable_form"],
		},
		"passive": "adaptive_resistance",
		"enrage_timer": 420.0,
		"loot_table": "boss_laboratory",
		"arena_type": "containment_chamber",
		"music": "boss_menacing",
		"min_level": 20,
	},
	BossType.THE_COLOSSUS: {
		"display_name": "The Colossus",
		"description": "Towering titan that dominates the wasteland.",
		"health": 15000,
		"damage": 100,
		"speed": 15.0,
		"armor": 60,
		"phases": 4,
		"phase_thresholds": [0.75, 0.5, 0.25, 0.1],
		"abilities": {
			BossPhase.PHASE_1: ["stomp", "boulder_throw"],
			BossPhase.PHASE_2: ["stomp", "boulder_throw", "earthquake"],
			BossPhase.PHASE_3: ["mega_stomp", "meteor_shower", "earthquake"],
			BossPhase.ENRAGED: ["world_breaker"],
		},
		"scale": 4.0,
		"enrage_timer": 600.0,
		"loot_table": "boss_world",
		"arena_type": "open_arena",
		"music": "boss_epic",
		"min_level": 50,
		"world_boss": true,
	},
}


# ============================================================================
# ABILITY DEFINITIONS
# ============================================================================

const ABILITY_DEFINITIONS := {
	# Bloat King
	"toxic_spray": {
		"type": AbilityType.RANGED_ATTACK,
		"damage": 25,
		"range": 200.0,
		"cooldown": 5.0,
		"effect": "poison",
		"duration": 5.0,
	},
	"bloat_summon": {
		"type": AbilityType.SUMMON,
		"summon_type": "zombie_bloater",
		"count": 2,
		"cooldown": 15.0,
	},
	"explosive_charge": {
		"type": AbilityType.CHARGE,
		"damage": 60,
		"range": 300.0,
		"cooldown": 12.0,
		"leaves_pool": "toxic_pool",
	},
	"toxic_barrage": {
		"type": AbilityType.PROJECTILE_BARRAGE,
		"damage": 20,
		"projectile_count": 8,
		"cooldown": 8.0,
	},
	
	# Feral Alpha
	"claw_swipe": {
		"type": AbilityType.MELEE_ATTACK,
		"damage": 50,
		"range": 80.0,
		"cooldown": 2.0,
		"combo": 3,
	},
	"leap_attack": {
		"type": AbilityType.LEAP,
		"damage": 70,
		"range": 400.0,
		"cooldown": 8.0,
		"aoe_radius": 100.0,
	},
	"pack_howl": {
		"type": AbilityType.BUFF,
		"effect": "attack_speed",
		"value": 0.5,
		"duration": 10.0,
		"cooldown": 20.0,
		"affects_summons": true,
	},
	"frenzy": {
		"type": AbilityType.BUFF,
		"effect": "damage_boost",
		"value": 1.0,
		"duration": 15.0,
		"cooldown": 30.0,
	},
	"berserker_rampage": {
		"type": AbilityType.ENRAGE,
		"damage_mult": 2.0,
		"speed_mult": 1.5,
		"duration": 20.0,
	},
	
	# Generic
	"ground_slam": {
		"type": AbilityType.GROUND_SLAM,
		"damage": 80,
		"radius": 200.0,
		"cooldown": 10.0,
		"stun_duration": 1.5,
	},
	"mass_summon": {
		"type": AbilityType.SUMMON,
		"summon_type": "mixed",
		"count": 6,
		"cooldown": 25.0,
	},
	
	# Screamer Queen
	"sonic_scream": {
		"type": AbilityType.AOE_ATTACK,
		"damage": 35,
		"radius": 300.0,
		"cooldown": 6.0,
		"effect": "confusion",
		"duration": 3.0,
	},
	"summon_screamers": {
		"type": AbilityType.SUMMON,
		"summon_type": "zombie_screamer",
		"count": 2,
		"cooldown": 18.0,
	},
	"fear_wave": {
		"type": AbilityType.DEBUFF,
		"effect": "fear",
		"radius": 400.0,
		"duration": 4.0,
		"cooldown": 15.0,
	},
	"banshee_wail": {
		"type": AbilityType.AOE_ATTACK,
		"damage": 60,
		"radius": 500.0,
		"cooldown": 12.0,
		"piercing": true,
	},
	
	# Irradiated Hulk
	"radiation_pulse": {
		"type": AbilityType.AOE_ATTACK,
		"damage": 40,
		"radius": 250.0,
		"cooldown": 8.0,
		"effect": "radiation",
		"stacks": true,
	},
	"radioactive_breath": {
		"type": AbilityType.RANGED_ATTACK,
		"damage": 30,
		"range": 350.0,
		"width": 100.0,
		"cooldown": 10.0,
		"duration": 3.0,
		"effect": "radiation",
	},
	"meltdown": {
		"type": AbilityType.AOE_ATTACK,
		"damage": 100,
		"radius": 400.0,
		"cooldown": 30.0,
		"self_damage": 500,
		"leaves_pool": "radiation_zone",
	},
	"nuclear_explosion": {
		"type": AbilityType.AOE_ATTACK,
		"damage": 200,
		"radius": 600.0,
		"cooldown": 60.0,
		"warning_time": 3.0,
	},
	
	# Military
	"tactical_strike": {
		"type": AbilityType.MELEE_ATTACK,
		"damage": 55,
		"range": 100.0,
		"cooldown": 3.0,
	},
	"grenade_barrage": {
		"type": AbilityType.PROJECTILE_BARRAGE,
		"damage": 45,
		"projectile_count": 3,
		"cooldown": 12.0,
		"aoe_radius": 80.0,
	},
	"call_reinforcements": {
		"type": AbilityType.SUMMON,
		"summon_type": "soldier_zombie",
		"count": 4,
		"cooldown": 20.0,
	},
	"airstrike": {
		"type": AbilityType.AOE_ATTACK,
		"damage": 150,
		"radius": 200.0,
		"cooldown": 45.0,
		"warning_time": 2.5,
		"multi_strike": 3,
	},
}


# ============================================================================
# ARENA CONFIGURATION
# ============================================================================

const ARENA_DEFINITIONS := {
	"toxic_arena": {
		"size": Vector2(800, 600),
		"hazards": ["toxic_pools", "exploding_barrels"],
		"cover_points": 4,
		"spawn_points": 8,
		"environmental_damage": {"type": "poison", "dps": 5},
	},
	"forest_clearing": {
		"size": Vector2(1000, 800),
		"hazards": ["falling_trees", "pack_dens"],
		"cover_points": 6,
		"spawn_points": 12,
	},
	"echo_chamber": {
		"size": Vector2(600, 600),
		"hazards": ["sonic_crystals", "echo_zones"],
		"cover_points": 2,
		"spawn_points": 6,
		"amplifies_sonic": true,
	},
	"reactor_room": {
		"size": Vector2(700, 700),
		"hazards": ["radiation_vents", "coolant_pipes"],
		"cover_points": 4,
		"spawn_points": 4,
		"environmental_damage": {"type": "radiation", "dps": 3},
	},
	"military_base": {
		"size": Vector2(1200, 800),
		"hazards": ["turrets", "mines", "barricades"],
		"cover_points": 10,
		"spawn_points": 8,
	},
	"operating_room": {
		"size": Vector2(500, 400),
		"hazards": ["surgical_tools", "gurneys"],
		"cover_points": 3,
		"spawn_points": 4,
	},
	"containment_chamber": {
		"size": Vector2(600, 600),
		"hazards": ["containment_breach", "acid_vats"],
		"cover_points": 2,
		"spawn_points": 4,
		"lockdown_possible": true,
	},
	"throne_room": {
		"size": Vector2(1000, 800),
		"hazards": ["summoning_circles", "dark_pillars"],
		"cover_points": 6,
		"spawn_points": 16,
	},
	"open_arena": {
		"size": Vector2(1500, 1200),
		"hazards": ["craters", "debris"],
		"cover_points": 8,
		"spawn_points": 12,
	},
}


# ============================================================================
# STATE
# ============================================================================

var _active_bosses: Dictionary = {}  # boss_instance_id -> boss data
var _active_arenas: Dictionary = {}  # arena_id -> arena data
var _ability_cooldowns: Dictionary = {}  # boss_id -> {ability -> remaining_cooldown}
var _summons: Dictionary = {}  # boss_id -> [summoned_enemy_ids]


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_update_bosses(delta)
	_update_cooldowns(delta)
	_update_arenas(delta)


# ============================================================================
# BOSS SPAWNING
# ============================================================================

func spawn_boss(boss_type: int, position: Vector2, arena_id: String = "") -> Dictionary:
	var definition: Dictionary = BOSS_DEFINITIONS.get(boss_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown boss type"}
	
	var boss_id := "boss_%d_%d" % [boss_type, randi()]
	
	var boss_data := {
		"id": boss_id,
		"type": boss_type,
		"type_name": BossType.keys()[boss_type],
		"display_name": definition.get("display_name", "Boss"),
		"position": position,
		"health": definition.get("health", 5000),
		"max_health": definition.get("health", 5000),
		"damage": definition.get("damage", 50),
		"speed": definition.get("speed", 30.0),
		"armor": definition.get("armor", 20),
		"current_phase": BossPhase.PHASE_1,
		"phase_thresholds": definition.get("phase_thresholds", [0.7, 0.4, 0.15]),
		"abilities": definition.get("abilities", {}),
		"passive": definition.get("passive", ""),
		"enrage_timer": definition.get("enrage_timer", 300.0),
		"time_alive": 0.0,
		"is_enraged": false,
		"is_stunned": false,
		"stun_timer": 0.0,
		"arena_id": arena_id,
		"scale": definition.get("scale", 1.0),
		"loot_table": definition.get("loot_table", "boss_generic"),
		"spawned_at": Time.get_unix_time_from_system(),
	}
	
	_active_bosses[boss_id] = boss_data
	_ability_cooldowns[boss_id] = {}
	_summons[boss_id] = []
	
	# Activate arena if provided
	if arena_id != "" and arena_id not in _active_arenas:
		_activate_arena(arena_id, definition.get("arena_type", "open_arena"))
	
	emit_signal("boss_encounter_started", boss_data)
	
	return {"success": true, "boss_id": boss_id, "boss": boss_data}


func _activate_arena(arena_id: String, arena_type: String) -> void:
	var definition: Dictionary = ARENA_DEFINITIONS.get(arena_type, {})
	
	var arena_data := {
		"id": arena_id,
		"type": arena_type,
		"size": definition.get("size", Vector2(800, 600)),
		"hazards": definition.get("hazards", []),
		"active_hazards": [],
		"cover_points": definition.get("cover_points", 4),
		"spawn_points": definition.get("spawn_points", 8),
		"environmental_damage": definition.get("environmental_damage", {}),
	}
	
	_active_arenas[arena_id] = arena_data
	emit_signal("arena_activated", arena_id)


# ============================================================================
# BOSS UPDATE
# ============================================================================

func _update_bosses(delta: float) -> void:
	for boss_id in _active_bosses:
		var boss: Dictionary = _active_bosses[boss_id]
		
		# Update timers
		boss["time_alive"] += delta
		
		# Check stun
		if boss.get("is_stunned", false):
			boss["stun_timer"] -= delta
			if boss["stun_timer"] <= 0:
				boss["is_stunned"] = false
			continue
		
		# Check enrage
		if not boss.get("is_enraged", false):
			if boss["time_alive"] >= boss.get("enrage_timer", 300.0):
				_enrage_boss(boss_id)
		
		# Update passive abilities
		_update_passive(boss, delta)


func _update_passive(boss: Dictionary, _delta: float) -> void:
	var passive: String = boss.get("passive", "")
	
	match passive:
		"radiation_aura":
			# Deal damage to nearby players
			pass
		"adaptive_resistance":
			# Build resistance to recently received damage types
			pass


func _update_cooldowns(delta: float) -> void:
	for boss_id in _ability_cooldowns:
		var cooldowns: Dictionary = _ability_cooldowns[boss_id]
		for ability in cooldowns.keys():
			cooldowns[ability] = maxf(cooldowns[ability] - delta, 0.0)


func _update_arenas(delta: float) -> void:
	for arena_id in _active_arenas:
		var arena: Dictionary = _active_arenas[arena_id]
		
		# Spawn random hazards
		if randf() < 0.01:  # 1% chance per frame
			var hazards: Array = arena.get("hazards", [])
			if hazards.size() > 0:
				var hazard: String = hazards[randi() % hazards.size()]
				_spawn_arena_hazard(arena_id, hazard)


func _spawn_arena_hazard(arena_id: String, hazard_type: String) -> void:
	emit_signal("arena_hazard_spawned", hazard_type)


# ============================================================================
# BOSS COMBAT
# ============================================================================

func damage_boss(boss_id: String, damage: float, damage_type: String = "physical") -> Dictionary:
	if boss_id not in _active_bosses:
		return {"success": false, "error": "Boss not found"}
	
	var boss: Dictionary = _active_bosses[boss_id]
	
	# Apply armor reduction
	var armor: float = boss.get("armor", 0)
	var damage_reduction := armor / (armor + 100.0)
	var actual_damage := damage * (1.0 - damage_reduction)
	
	boss["health"] -= actual_damage
	
	# Check phase transitions
	_check_phase_transition(boss_id)
	
	# Check death
	if boss["health"] <= 0:
		_defeat_boss(boss_id)
		return {"success": true, "defeated": true, "damage_dealt": actual_damage}
	
	return {"success": true, "defeated": false, "damage_dealt": actual_damage, "health_remaining": boss["health"]}


func _check_phase_transition(boss_id: String) -> void:
	var boss: Dictionary = _active_bosses[boss_id]
	var health_percent: float = boss["health"] / boss["max_health"]
	var thresholds: Array = boss.get("phase_thresholds", [])
	var current_phase: int = boss.get("current_phase", BossPhase.PHASE_1)
	
	for i in range(thresholds.size()):
		if health_percent <= thresholds[i] and current_phase <= i:
			var new_phase: int = i + 1  # PHASE_2, PHASE_3, etc.
			if new_phase < BossPhase.ENRAGED:
				boss["current_phase"] = new_phase
				emit_signal("boss_phase_changed", boss_id, new_phase)
				emit_signal("boss_health_threshold", boss_id, thresholds[i])
			break


func _enrage_boss(boss_id: String) -> void:
	if boss_id not in _active_bosses:
		return
	
	var boss: Dictionary = _active_bosses[boss_id]
	boss["is_enraged"] = true
	boss["current_phase"] = BossPhase.ENRAGED
	boss["damage"] = int(boss["damage"] * 1.5)
	boss["speed"] *= 1.3
	
	emit_signal("boss_enraged", boss_id)
	emit_signal("boss_phase_changed", boss_id, BossPhase.ENRAGED)


func stun_boss(boss_id: String, duration: float) -> bool:
	if boss_id not in _active_bosses:
		return false
	
	var boss: Dictionary = _active_bosses[boss_id]
	
	# Bosses have stun resistance
	var stun_resist := 0.5  # 50% duration reduction
	if boss.get("is_enraged", false):
		stun_resist = 0.75  # 75% when enraged
	
	var actual_duration := duration * (1.0 - stun_resist)
	
	if actual_duration > 0.5:  # Minimum stun threshold
		boss["is_stunned"] = true
		boss["stun_timer"] = actual_duration
		emit_signal("boss_stunned", boss_id, actual_duration)
		return true
	
	return false


# ============================================================================
# BOSS ABILITIES
# ============================================================================

func use_ability(boss_id: String, ability_name: String) -> Dictionary:
	if boss_id not in _active_bosses:
		return {"success": false, "error": "Boss not found"}
	
	var boss: Dictionary = _active_bosses[boss_id]
	
	if boss.get("is_stunned", false):
		return {"success": false, "error": "Boss is stunned"}
	
	# Check cooldown
	var cooldowns: Dictionary = _ability_cooldowns.get(boss_id, {})
	if cooldowns.get(ability_name, 0.0) > 0:
		return {"success": false, "error": "Ability on cooldown"}
	
	var ability_def: Dictionary = ABILITY_DEFINITIONS.get(ability_name, {})
	if ability_def.is_empty():
		return {"success": false, "error": "Unknown ability"}
	
	# Execute ability
	var result := _execute_ability(boss, ability_name, ability_def)
	
	# Set cooldown
	cooldowns[ability_name] = ability_def.get("cooldown", 10.0)
	_ability_cooldowns[boss_id] = cooldowns
	
	emit_signal("boss_ability_used", boss_id, ability_name)
	
	return result


func _execute_ability(boss: Dictionary, ability_name: String, ability_def: Dictionary) -> Dictionary:
	var ability_type: int = ability_def.get("type", AbilityType.MELEE_ATTACK)
	
	match ability_type:
		AbilityType.MELEE_ATTACK:
			return {"success": true, "type": "melee", "damage": ability_def.get("damage", 50)}
		
		AbilityType.RANGED_ATTACK:
			return {"success": true, "type": "ranged", "damage": ability_def.get("damage", 30), "range": ability_def.get("range", 200)}
		
		AbilityType.AOE_ATTACK:
			return {"success": true, "type": "aoe", "damage": ability_def.get("damage", 40), "radius": ability_def.get("radius", 150)}
		
		AbilityType.SUMMON:
			var count: int = ability_def.get("count", 2)
			_summons[boss["id"]] = _summons.get(boss["id"], [])
			for i in range(count):
				_summons[boss["id"]].append("summon_%d" % randi())
			return {"success": true, "type": "summon", "count": count, "summon_type": ability_def.get("summon_type", "zombie")}
		
		AbilityType.BUFF:
			return {"success": true, "type": "buff", "effect": ability_def.get("effect", ""), "value": ability_def.get("value", 0.5)}
		
		AbilityType.CHARGE:
			return {"success": true, "type": "charge", "damage": ability_def.get("damage", 60), "range": ability_def.get("range", 300)}
		
		AbilityType.LEAP:
			return {"success": true, "type": "leap", "damage": ability_def.get("damage", 70), "range": ability_def.get("range", 400)}
		
		AbilityType.GROUND_SLAM:
			return {"success": true, "type": "ground_slam", "damage": ability_def.get("damage", 80), "radius": ability_def.get("radius", 200)}
		
		AbilityType.PROJECTILE_BARRAGE:
			return {"success": true, "type": "barrage", "damage": ability_def.get("damage", 25), "count": ability_def.get("projectile_count", 5)}
		
		_:
			return {"success": true, "type": "unknown"}


func get_available_abilities(boss_id: String) -> Array:
	if boss_id not in _active_bosses:
		return []
	
	var boss: Dictionary = _active_bosses[boss_id]
	var current_phase: int = boss.get("current_phase", BossPhase.PHASE_1)
	var abilities: Dictionary = boss.get("abilities", {})
	var cooldowns: Dictionary = _ability_cooldowns.get(boss_id, {})
	
	var phase_abilities: Array = abilities.get(current_phase, [])
	var available: Array = []
	
	for ability_name in phase_abilities:
		if cooldowns.get(ability_name, 0.0) <= 0:
			available.append(ability_name)
	
	return available


# ============================================================================
# BOSS DEFEAT
# ============================================================================

func _defeat_boss(boss_id: String) -> void:
	if boss_id not in _active_bosses:
		return
	
	var boss: Dictionary = _active_bosses[boss_id]
	var rewards := _generate_boss_rewards(boss)
	
	# Clean up summons
	_summons.erase(boss_id)
	_ability_cooldowns.erase(boss_id)
	
	# Deactivate arena
	var arena_id: String = boss.get("arena_id", "")
	if arena_id in _active_arenas:
		_active_arenas.erase(arena_id)
	
	_active_bosses.erase(boss_id)
	
	emit_signal("boss_defeated", boss_id, rewards)


func _generate_boss_rewards(boss: Dictionary) -> Dictionary:
	var base_xp := 500 + boss.get("max_health", 5000) / 10
	
	# Bonus for speed
	var time_bonus := 1.0
	var enrage_time: float = boss.get("enrage_timer", 300.0)
	var time_taken: float = boss.get("time_alive", 0.0)
	if time_taken < enrage_time * 0.5:
		time_bonus = 1.5
	elif time_taken < enrage_time:
		time_bonus = 1.25
	
	return {
		"xp": int(base_xp * time_bonus),
		"loot_table": boss.get("loot_table", "boss_generic"),
		"guaranteed_drops": 3,
		"bonus_chance": 0.5,
		"time_taken": time_taken,
		"no_enrage": not boss.get("is_enraged", false),
	}


func despawn_boss(boss_id: String, reason: String = "timeout") -> void:
	if boss_id not in _active_bosses:
		return
	
	var boss: Dictionary = _active_bosses[boss_id]
	var arena_id: String = boss.get("arena_id", "")
	
	_summons.erase(boss_id)
	_ability_cooldowns.erase(boss_id)
	
	if arena_id in _active_arenas:
		_active_arenas.erase(arena_id)
	
	_active_bosses.erase(boss_id)
	
	emit_signal("boss_despawned", boss_id, reason)


# ============================================================================
# QUERIES
# ============================================================================

func get_boss(boss_id: String) -> Dictionary:
	return _active_bosses.get(boss_id, {})


func get_all_active_bosses() -> Array:
	return _active_bosses.values()


func is_boss_active(boss_type: int) -> bool:
	for boss in _active_bosses.values():
		if boss.get("type", -1) == boss_type:
			return true
	return false


func get_boss_health_percent(boss_id: String) -> float:
	var boss: Dictionary = _active_bosses.get(boss_id, {})
	if boss.is_empty():
		return 0.0
	return boss["health"] / boss["max_health"]


func get_boss_definition(boss_type: int) -> Dictionary:
	return BOSS_DEFINITIONS.get(boss_type, {}).duplicate()


func get_arena(arena_id: String) -> Dictionary:
	return _active_arenas.get(arena_id, {})


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"active_bosses": _active_bosses.duplicate(true),
		"active_arenas": _active_arenas.duplicate(true),
		"ability_cooldowns": _ability_cooldowns.duplicate(true),
		"summons": _summons.duplicate(true),
	}


func load_data(data: Dictionary) -> void:
	_active_bosses = data.get("active_bosses", {})
	_active_arenas = data.get("active_arenas", {})
	_ability_cooldowns = data.get("ability_cooldowns", {})
	_summons = data.get("summons", {})
