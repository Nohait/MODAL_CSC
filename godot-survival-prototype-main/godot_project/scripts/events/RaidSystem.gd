extends Node
class_name RaidSystemClass
## Manages base raids by hostile NPCs and zombie hordes
## Handles raid scheduling, attack patterns, and defenses

signal raid_warning(time_until: float, raid_type: int)
signal raid_started(raid_data: Dictionary)
signal raid_phase_changed(phase: int, phase_name: String)
signal raider_spawned(raider_data: Dictionary)
signal structure_attacked(structure_id: String, damage: float)
signal structure_destroyed(structure_id: String)
signal loot_stolen(items: Array)
signal raid_repelled(rewards: Dictionary)
signal raid_failed(losses: Dictionary)

# ============================================================================
# RAID CONFIGURATION
# ============================================================================

enum RaidType {
	ZOMBIE_RAID,        # Standard zombie attack on base
	BANDIT_RAID,        # Human raiders
	MUTANT_RAID,        # Mutated creatures
	MILITARY_RAID,      # Hostile military
	SCAVENGER_RAID,     # Thieves targeting loot
	SIEGE,              # Extended siege event
	COMBINED_ASSAULT,   # Multiple factions
}

enum RaidPhase {
	SCOUTING,     # Pre-raid scouting (can be detected)
	APPROACH,     # Raiders approaching
	BREACH,       # Attempting to breach defenses
	ASSAULT,      # Main attack
	LOOTING,      # Attempting to steal
	RETREAT,      # Raiders retreating
}

enum RaiderType {
	# Bandits
	BANDIT_SCOUT,
	BANDIT_GRUNT,
	BANDIT_SNIPER,
	BANDIT_HEAVY,
	BANDIT_LEADER,
	
	# Military
	SOLDIER_BASIC,
	SOLDIER_ELITE,
	SOLDIER_HEAVY,
	COMMANDER,
	
	# Scavengers
	SCAVENGER,
	THIEF,
	
	# Special
	DEMOLISHER,
	TECHNICIAN,
}

const RAIDER_DEFINITIONS := {
	RaiderType.BANDIT_SCOUT: {
		"display_name": "Bandit Scout",
		"health": 60,
		"damage": 15,
		"speed": 70.0,
		"armor": 5,
		"weapon": "pistol",
		"xp_value": 20,
		"behavior": "scout",
		"loot_table": "bandit_common",
	},
	RaiderType.BANDIT_GRUNT: {
		"display_name": "Bandit",
		"health": 80,
		"damage": 20,
		"speed": 50.0,
		"armor": 10,
		"weapon": "shotgun",
		"xp_value": 25,
		"behavior": "assault",
		"loot_table": "bandit_common",
	},
	RaiderType.BANDIT_SNIPER: {
		"display_name": "Bandit Sniper",
		"health": 50,
		"damage": 45,
		"speed": 40.0,
		"armor": 5,
		"weapon": "rifle",
		"xp_value": 35,
		"behavior": "ranged",
		"attack_range": 400.0,
		"loot_table": "bandit_uncommon",
	},
	RaiderType.BANDIT_HEAVY: {
		"display_name": "Bandit Heavy",
		"health": 150,
		"damage": 30,
		"speed": 35.0,
		"armor": 30,
		"weapon": "lmg",
		"xp_value": 50,
		"behavior": "assault",
		"loot_table": "bandit_uncommon",
	},
	RaiderType.BANDIT_LEADER: {
		"display_name": "Bandit Leader",
		"health": 200,
		"damage": 35,
		"speed": 45.0,
		"armor": 25,
		"weapon": "assault_rifle",
		"xp_value": 100,
		"behavior": "leader",
		"buffs_allies": true,
		"loot_table": "bandit_rare",
	},
	RaiderType.SOLDIER_BASIC: {
		"display_name": "Soldier",
		"health": 100,
		"damage": 25,
		"speed": 55.0,
		"armor": 20,
		"weapon": "assault_rifle",
		"xp_value": 40,
		"behavior": "tactical",
		"loot_table": "military_common",
	},
	RaiderType.SOLDIER_ELITE: {
		"display_name": "Elite Soldier",
		"health": 150,
		"damage": 35,
		"speed": 60.0,
		"armor": 35,
		"weapon": "assault_rifle",
		"xp_value": 75,
		"behavior": "tactical",
		"loot_table": "military_uncommon",
	},
	RaiderType.SOLDIER_HEAVY: {
		"display_name": "Heavy Soldier",
		"health": 250,
		"damage": 40,
		"speed": 30.0,
		"armor": 50,
		"weapon": "lmg",
		"xp_value": 100,
		"behavior": "suppression",
		"loot_table": "military_rare",
	},
	RaiderType.COMMANDER: {
		"display_name": "Commander",
		"health": 300,
		"damage": 45,
		"speed": 50.0,
		"armor": 40,
		"weapon": "assault_rifle",
		"xp_value": 200,
		"behavior": "leader",
		"buffs_allies": true,
		"loot_table": "military_rare",
	},
	RaiderType.SCAVENGER: {
		"display_name": "Scavenger",
		"health": 50,
		"damage": 10,
		"speed": 80.0,
		"armor": 0,
		"weapon": "knife",
		"xp_value": 15,
		"behavior": "thief",
		"loot_capacity": 5,
		"loot_table": "scavenger",
	},
	RaiderType.THIEF: {
		"display_name": "Thief",
		"health": 40,
		"damage": 8,
		"speed": 90.0,
		"armor": 0,
		"weapon": "knife",
		"xp_value": 20,
		"behavior": "thief",
		"loot_capacity": 10,
		"stealth": true,
		"loot_table": "scavenger",
	},
	RaiderType.DEMOLISHER: {
		"display_name": "Demolisher",
		"health": 120,
		"damage": 15,
		"speed": 40.0,
		"armor": 15,
		"weapon": "explosives",
		"xp_value": 60,
		"behavior": "demolition",
		"structure_damage_mult": 5.0,
		"loot_table": "bandit_uncommon",
	},
	RaiderType.TECHNICIAN: {
		"display_name": "Technician",
		"health": 60,
		"damage": 12,
		"speed": 50.0,
		"armor": 5,
		"weapon": "pistol",
		"xp_value": 45,
		"behavior": "hack",
		"can_disable_turrets": true,
		"can_unlock_doors": true,
		"loot_table": "bandit_uncommon",
	},
}

const RAID_TEMPLATES := {
	RaidType.ZOMBIE_RAID: {
		"display_name": "Zombie Raid",
		"min_day": 1,
		"base_raiders": 10,
		"phases": [RaidPhase.APPROACH, RaidPhase.BREACH, RaidPhase.ASSAULT, RaidPhase.RETREAT],
		"duration_minutes": 10,
		"composition": {"zombie_walker": 0.6, "zombie_runner": 0.3, "zombie_brute": 0.1},
		"targets": ["walls", "doors", "players"],
	},
	RaidType.BANDIT_RAID: {
		"display_name": "Bandit Raid",
		"min_day": 7,
		"base_raiders": 6,
		"phases": [RaidPhase.SCOUTING, RaidPhase.APPROACH, RaidPhase.BREACH, RaidPhase.ASSAULT, RaidPhase.LOOTING, RaidPhase.RETREAT],
		"duration_minutes": 15,
		"composition": {
			RaiderType.BANDIT_SCOUT: 0.15,
			RaiderType.BANDIT_GRUNT: 0.5,
			RaiderType.BANDIT_SNIPER: 0.15,
			RaiderType.BANDIT_HEAVY: 0.15,
			RaiderType.BANDIT_LEADER: 0.05,
		},
		"targets": ["storage", "workstations", "players"],
	},
	RaidType.MUTANT_RAID: {
		"display_name": "Mutant Attack",
		"min_day": 21,
		"base_raiders": 8,
		"phases": [RaidPhase.APPROACH, RaidPhase.ASSAULT, RaidPhase.RETREAT],
		"duration_minutes": 12,
		"composition": {"mutant_dog": 0.4, "mutant_beast": 0.4, "mutant_alpha": 0.2},
		"targets": ["players", "walls"],
	},
	RaidType.MILITARY_RAID: {
		"display_name": "Military Incursion",
		"min_day": 35,
		"base_raiders": 8,
		"phases": [RaidPhase.SCOUTING, RaidPhase.APPROACH, RaidPhase.BREACH, RaidPhase.ASSAULT, RaidPhase.RETREAT],
		"duration_minutes": 20,
		"composition": {
			RaiderType.SOLDIER_BASIC: 0.5,
			RaiderType.SOLDIER_ELITE: 0.25,
			RaiderType.SOLDIER_HEAVY: 0.15,
			RaiderType.COMMANDER: 0.1,
		},
		"targets": ["turrets", "generators", "players"],
	},
	RaidType.SCAVENGER_RAID: {
		"display_name": "Scavenger Raid",
		"min_day": 14,
		"base_raiders": 8,
		"phases": [RaidPhase.SCOUTING, RaidPhase.APPROACH, RaidPhase.BREACH, RaidPhase.LOOTING, RaidPhase.RETREAT],
		"duration_minutes": 8,
		"composition": {
			RaiderType.SCAVENGER: 0.6,
			RaiderType.THIEF: 0.3,
			RaiderType.DEMOLISHER: 0.1,
		},
		"targets": ["storage", "loot"],
		"stealth_raid": true,
	},
	RaidType.SIEGE: {
		"display_name": "Siege",
		"min_day": 42,
		"base_raiders": 20,
		"phases": [RaidPhase.SCOUTING, RaidPhase.APPROACH, RaidPhase.BREACH, RaidPhase.ASSAULT, RaidPhase.LOOTING, RaidPhase.RETREAT],
		"duration_minutes": 30,
		"composition": {
			RaiderType.BANDIT_GRUNT: 0.35,
			RaiderType.BANDIT_HEAVY: 0.2,
			RaiderType.BANDIT_SNIPER: 0.15,
			RaiderType.DEMOLISHER: 0.15,
			RaiderType.TECHNICIAN: 0.1,
			RaiderType.BANDIT_LEADER: 0.05,
		},
		"targets": ["all"],
		"waves": 3,
	},
	RaidType.COMBINED_ASSAULT: {
		"display_name": "Combined Assault",
		"min_day": 56,
		"base_raiders": 25,
		"phases": [RaidPhase.APPROACH, RaidPhase.BREACH, RaidPhase.ASSAULT, RaidPhase.LOOTING, RaidPhase.RETREAT],
		"duration_minutes": 25,
		"composition": "mixed",  # Multiple factions
		"targets": ["all"],
		"waves": 2,
	},
}


# ============================================================================
# STATE
# ============================================================================

var is_raid_active: bool = false
var current_raid_type: int = RaidType.ZOMBIE_RAID
var current_phase: int = RaidPhase.SCOUTING
var raid_start_time: float = 0.0

var _raid_pending: bool = false
var _warning_timer: float = 0.0
var _phase_timer: float = 0.0
var _phase_duration: float = 0.0
var _current_wave: int = 0
var _total_waves: int = 1

var _active_raiders: Array = []  # Currently alive raiders
var _spawn_queue: Array = []
var _spawn_timer: float = 0.0
var _raiders_killed: int = 0
var _raiders_escaped: int = 0

var _structures_damaged: Dictionary = {}  # structure_id -> total damage
var _structures_destroyed: Array = []
var _loot_stolen: Array = []

var _base_center: Vector2 = Vector2.ZERO
var _defense_rating: float = 0.0
var current_day: int = 1


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _raid_pending:
		_warning_timer -= delta
		if _warning_timer <= 0.0:
			_start_raid()
	
	if is_raid_active:
		_update_raid(delta)


# ============================================================================
# RAID MANAGEMENT
# ============================================================================

func trigger_raid(raid_type: int = RaidType.BANDIT_RAID, delay: float = 120.0) -> bool:
	if is_raid_active or _raid_pending:
		return false
	
	var template: Dictionary = RAID_TEMPLATES.get(raid_type, {})
	if template.is_empty():
		return false
	
	if current_day < template.get("min_day", 1):
		return false
	
	_raid_pending = true
	_warning_timer = delay
	current_raid_type = raid_type
	
	emit_signal("raid_warning", delay, raid_type)
	return true


func check_random_raid(day: int, defense_rating: float) -> bool:
	current_day = day
	_defense_rating = defense_rating
	
	# Base chance increases with days, decreases with defense
	var base_chance := 0.05 + (day * 0.005)
	var defense_reduction := defense_rating * 0.001
	var final_chance := maxf(base_chance - defense_reduction, 0.01)
	
	if randf() < final_chance:
		var raid_type := _pick_random_raid_type()
		trigger_raid(raid_type, randf_range(60.0, 180.0))
		return true
	
	return false


func _pick_random_raid_type() -> int:
	var available: Array = []
	
	for raid_type in RAID_TEMPLATES:
		var template: Dictionary = RAID_TEMPLATES[raid_type]
		if current_day >= template.get("min_day", 1):
			available.append(raid_type)
	
	if available.is_empty():
		return RaidType.ZOMBIE_RAID
	
	return available[randi() % available.size()]


func _start_raid() -> void:
	_raid_pending = false
	is_raid_active = true
	raid_start_time = Time.get_unix_time_from_system()
	
	var template: Dictionary = RAID_TEMPLATES.get(current_raid_type, {})
	
	_current_wave = 1
	_total_waves = template.get("waves", 1)
	_raiders_killed = 0
	_raiders_escaped = 0
	_structures_damaged.clear()
	_structures_destroyed.clear()
	_loot_stolen.clear()
	
	# Generate raiders
	var raider_count := _calculate_raider_count(template)
	_spawn_queue = _generate_raider_queue(template, raider_count)
	
	# Start first phase
	var phases: Array = template.get("phases", [RaidPhase.ASSAULT])
	if phases.size() > 0:
		_start_phase(phases[0])
	
	emit_signal("raid_started", {
		"type": current_raid_type,
		"type_name": RaidType.keys()[current_raid_type],
		"display_name": template.get("display_name", "Raid"),
		"raider_count": raider_count,
		"waves": _total_waves,
	})


func _calculate_raider_count(template: Dictionary) -> int:
	var base_count: int = template.get("base_raiders", 6)
	
	# Scale with day
	var day_mult := 1.0 + (current_day - 1) * 0.03
	
	# Reduce with defense rating
	var defense_mult := maxf(1.0 - _defense_rating * 0.002, 0.5)
	
	return int(base_count * day_mult * defense_mult)


func _generate_raider_queue(template: Dictionary, count: int) -> Array:
	var queue: Array = []
	var composition = template.get("composition", {})
	
	if composition == "mixed":
		# Combined assault - mix of different factions
		composition = {
			RaiderType.BANDIT_GRUNT: 0.3,
			RaiderType.SOLDIER_BASIC: 0.3,
			RaiderType.SCAVENGER: 0.2,
			RaiderType.DEMOLISHER: 0.1,
			RaiderType.BANDIT_LEADER: 0.1,
		}
	
	for i in range(count):
		var roll := randf()
		var cumulative := 0.0
		
		for raider_type in composition:
			cumulative += composition[raider_type]
			if roll <= cumulative:
				queue.append(raider_type)
				break
	
	queue.shuffle()
	return queue


# ============================================================================
# PHASE MANAGEMENT
# ============================================================================

func _start_phase(phase: int) -> void:
	current_phase = phase
	_phase_timer = 0.0
	
	match phase:
		RaidPhase.SCOUTING:
			_phase_duration = 60.0  # 1 minute
		RaidPhase.APPROACH:
			_phase_duration = 30.0
		RaidPhase.BREACH:
			_phase_duration = 120.0  # 2 minutes
		RaidPhase.ASSAULT:
			_phase_duration = 300.0  # 5 minutes
		RaidPhase.LOOTING:
			_phase_duration = 60.0
		RaidPhase.RETREAT:
			_phase_duration = 30.0
	
	emit_signal("raid_phase_changed", phase, RaidPhase.keys()[phase])


func _update_raid(delta: float) -> void:
	_phase_timer += delta
	
	# Spawn raiders during approach/breach/assault
	if current_phase in [RaidPhase.APPROACH, RaidPhase.BREACH, RaidPhase.ASSAULT]:
		_update_spawning(delta)
	
	# Update raider AI
	_update_raiders(delta)
	
	# Handle looting phase
	if current_phase == RaidPhase.LOOTING:
		_update_looting(delta)
	
	# Check phase completion
	if _phase_timer >= _phase_duration:
		_advance_phase()
	
	# Check raid end conditions
	_check_raid_end()


func _advance_phase() -> void:
	var template: Dictionary = RAID_TEMPLATES.get(current_raid_type, {})
	var phases: Array = template.get("phases", [])
	
	var current_index := phases.find(current_phase)
	if current_index >= 0 and current_index < phases.size() - 1:
		_start_phase(phases[current_index + 1])
	else:
		# Check for additional waves
		if _current_wave < _total_waves:
			_current_wave += 1
			var raider_count := _calculate_raider_count(template)
			_spawn_queue.append_array(_generate_raider_queue(template, raider_count))
			_start_phase(phases[0])
		else:
			_end_raid(true)  # Raiders retreat


func _check_raid_end() -> void:
	# All raiders eliminated
	if _spawn_queue.is_empty() and _active_raiders.is_empty():
		_end_raid(true)


# ============================================================================
# RAIDER SPAWNING
# ============================================================================

func _update_spawning(delta: float) -> void:
	if _spawn_queue.is_empty():
		return
	
	_spawn_timer += delta
	
	var spawn_interval := 2.0
	if current_phase == RaidPhase.ASSAULT:
		spawn_interval = 1.0
	
	while _spawn_timer >= spawn_interval and _spawn_queue.size() > 0:
		_spawn_timer -= spawn_interval
		_spawn_raider(_spawn_queue.pop_front())


func _spawn_raider(raider_type) -> void:
	var definition: Dictionary = RAIDER_DEFINITIONS.get(raider_type, {})
	if definition.is_empty():
		return
	
	var spawn_pos := _get_raider_spawn_position()
	
	var raider_data := {
		"id": "raider_%d" % randi(),
		"type": raider_type,
		"type_name": RaiderType.keys()[raider_type] if raider_type is int else str(raider_type),
		"display_name": definition.get("display_name", "Raider"),
		"position": spawn_pos,
		"health": _scale_raider_stat(definition.get("health", 80)),
		"max_health": _scale_raider_stat(definition.get("health", 80)),
		"damage": _scale_raider_stat(definition.get("damage", 20)),
		"speed": definition.get("speed", 50.0),
		"armor": definition.get("armor", 10),
		"weapon": definition.get("weapon", "rifle"),
		"xp_value": definition.get("xp_value", 25),
		"behavior": definition.get("behavior", "assault"),
		"loot_table": definition.get("loot_table", "bandit_common"),
		"target": null,
		"state": "approaching",
		"carried_loot": [],
	}
	
	# Copy special properties
	for key in ["attack_range", "buffs_allies", "loot_capacity", "stealth",
				"structure_damage_mult", "can_disable_turrets", "can_unlock_doors"]:
		if key in definition:
			raider_data[key] = definition[key]
	
	_active_raiders.append(raider_data)
	emit_signal("raider_spawned", raider_data)


func _get_raider_spawn_position() -> Vector2:
	var angle := randf() * TAU
	var distance := 800.0 + randf_range(0, 200)
	return _base_center + Vector2(cos(angle), sin(angle)) * distance


func _scale_raider_stat(base_value: int) -> int:
	var day_mult := 1.0 + (current_day - 1) * 0.025
	return int(base_value * day_mult)


# ============================================================================
# RAIDER AI
# ============================================================================

func _update_raiders(delta: float) -> void:
	for raider in _active_raiders:
		match raider.get("behavior", "assault"):
			"scout":
				_update_scout_ai(raider, delta)
			"assault":
				_update_assault_ai(raider, delta)
			"ranged":
				_update_ranged_ai(raider, delta)
			"thief":
				_update_thief_ai(raider, delta)
			"demolition":
				_update_demolition_ai(raider, delta)
			"hack":
				_update_hack_ai(raider, delta)
			"leader":
				_update_leader_ai(raider, delta)
			"tactical":
				_update_tactical_ai(raider, delta)
			"suppression":
				_update_suppression_ai(raider, delta)


func _update_scout_ai(raider: Dictionary, _delta: float) -> void:
	# Scouts observe and report, then engage
	if current_phase == RaidPhase.SCOUTING:
		raider["state"] = "scouting"
	else:
		raider["state"] = "attacking"


func _update_assault_ai(raider: Dictionary, _delta: float) -> void:
	# Direct assault on structures and players
	raider["state"] = "attacking"


func _update_ranged_ai(raider: Dictionary, _delta: float) -> void:
	# Stay at range and shoot
	raider["state"] = "ranged_attack"


func _update_thief_ai(raider: Dictionary, _delta: float) -> void:
	# Sneak to storage, grab loot, escape
	var capacity: int = raider.get("loot_capacity", 5)
	var carried: Array = raider.get("carried_loot", [])
	
	if carried.size() >= capacity:
		raider["state"] = "escaping"
	elif current_phase == RaidPhase.LOOTING:
		raider["state"] = "stealing"
	else:
		raider["state"] = "hiding"


func _update_demolition_ai(raider: Dictionary, _delta: float) -> void:
	# Target structures for destruction
	raider["state"] = "demolishing"


func _update_hack_ai(raider: Dictionary, _delta: float) -> void:
	# Disable turrets and unlock doors
	raider["state"] = "hacking"


func _update_leader_ai(raider: Dictionary, _delta: float) -> void:
	# Buff allies and coordinate
	raider["state"] = "commanding"


func _update_tactical_ai(raider: Dictionary, _delta: float) -> void:
	# Use cover and flanking
	raider["state"] = "tactical"


func _update_suppression_ai(raider: Dictionary, _delta: float) -> void:
	# Suppressive fire
	raider["state"] = "suppressing"


# ============================================================================
# LOOTING
# ============================================================================

func _update_looting(_delta: float) -> void:
	for raider in _active_raiders:
		if raider.get("behavior", "") != "thief":
			continue
		
		if raider.get("state", "") == "stealing":
			var capacity: int = raider.get("loot_capacity", 5)
			var carried: Array = raider.get("carried_loot", [])
			
			if carried.size() < capacity:
				# Attempt to steal item
				var stolen := _attempt_steal()
				if not stolen.is_empty():
					carried.append(stolen)
					raider["carried_loot"] = carried


func _attempt_steal() -> Dictionary:
	# This would interface with StorageSystem
	# Returns stolen item or empty dict
	return {}


# ============================================================================
# COMBAT & DAMAGE
# ============================================================================

func on_raider_killed(raider_id: String) -> void:
	for i in range(_active_raiders.size() - 1, -1, -1):
		if _active_raiders[i].get("id", "") == raider_id:
			var raider: Dictionary = _active_raiders[i]
			_raiders_killed += 1
			
			# Check for carried loot recovery
			var carried: Array = raider.get("carried_loot", [])
			# Loot would be dropped at raider position
			
			_active_raiders.remove_at(i)
			break


func on_raider_escaped(raider_id: String) -> void:
	for i in range(_active_raiders.size() - 1, -1, -1):
		if _active_raiders[i].get("id", "") == raider_id:
			var raider: Dictionary = _active_raiders[i]
			_raiders_escaped += 1
			
			# Track stolen loot
			var carried: Array = raider.get("carried_loot", [])
			_loot_stolen.append_array(carried)
			
			_active_raiders.remove_at(i)
			break


func on_structure_damaged(structure_id: String, damage: float) -> void:
	var current: float = _structures_damaged.get(structure_id, 0.0)
	_structures_damaged[structure_id] = current + damage
	
	emit_signal("structure_attacked", structure_id, damage)


func on_structure_destroyed(structure_id: String) -> void:
	if structure_id not in _structures_destroyed:
		_structures_destroyed.append(structure_id)
	emit_signal("structure_destroyed", structure_id)


# ============================================================================
# RAID END
# ============================================================================

func _end_raid(repelled: bool) -> void:
	is_raid_active = false
	
	if repelled:
		var rewards := _calculate_rewards()
		emit_signal("raid_repelled", rewards)
	else:
		var losses := {
			"structures_destroyed": _structures_destroyed.duplicate(),
			"loot_stolen": _loot_stolen.duplicate(),
			"raiders_escaped": _raiders_escaped,
		}
		if not _loot_stolen.is_empty():
			emit_signal("loot_stolen", _loot_stolen)
		emit_signal("raid_failed", losses)
	
	_active_raiders.clear()
	_spawn_queue.clear()


func _calculate_rewards() -> Dictionary:
	var base_xp := 0
	for killed in range(_raiders_killed):
		base_xp += 25  # Average XP per raider
	
	# Bonus for defending structures
	var defense_bonus := 1.0
	if _structures_destroyed.is_empty():
		defense_bonus = 1.5  # No structures lost
	
	# Bonus for preventing theft
	var loot_bonus := 1.0
	if _loot_stolen.is_empty():
		loot_bonus = 1.25
	
	return {
		"xp": int(base_xp * defense_bonus * loot_bonus),
		"raiders_killed": _raiders_killed,
		"raiders_escaped": _raiders_escaped,
		"structures_lost": _structures_destroyed.size(),
		"loot_protected": _loot_stolen.is_empty(),
		"raid_type": current_raid_type,
	}


# ============================================================================
# QUERIES
# ============================================================================

func get_raid_status() -> Dictionary:
	return {
		"is_active": is_raid_active,
		"is_pending": _raid_pending,
		"time_until": _warning_timer if _raid_pending else 0.0,
		"raid_type": current_raid_type,
		"raid_type_name": RaidType.keys()[current_raid_type],
		"current_phase": current_phase,
		"phase_name": RaidPhase.keys()[current_phase],
		"phase_progress": _phase_timer / _phase_duration if _phase_duration > 0 else 0.0,
		"active_raiders": _active_raiders.size(),
		"raiders_killed": _raiders_killed,
		"current_wave": _current_wave,
		"total_waves": _total_waves,
	}


func set_base_center(center: Vector2) -> void:
	_base_center = center


func set_defense_rating(rating: float) -> void:
	_defense_rating = rating


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"is_raid_active": is_raid_active,
		"current_raid_type": current_raid_type,
		"current_phase": current_phase,
		"raid_pending": _raid_pending,
		"warning_timer": _warning_timer,
		"phase_timer": _phase_timer,
		"current_wave": _current_wave,
		"total_waves": _total_waves,
		"active_raiders": _active_raiders.duplicate(true),
		"spawn_queue": _spawn_queue.duplicate(),
		"raiders_killed": _raiders_killed,
		"structures_damaged": _structures_damaged.duplicate(),
		"structures_destroyed": _structures_destroyed.duplicate(),
		"loot_stolen": _loot_stolen.duplicate(true),
		"current_day": current_day,
	}


func load_data(data: Dictionary) -> void:
	is_raid_active = data.get("is_raid_active", false)
	current_raid_type = data.get("current_raid_type", RaidType.ZOMBIE_RAID)
	current_phase = data.get("current_phase", RaidPhase.SCOUTING)
	_raid_pending = data.get("raid_pending", false)
	_warning_timer = data.get("warning_timer", 0.0)
	_phase_timer = data.get("phase_timer", 0.0)
	_current_wave = data.get("current_wave", 1)
	_total_waves = data.get("total_waves", 1)
	_active_raiders = data.get("active_raiders", [])
	_spawn_queue = data.get("spawn_queue", [])
	_raiders_killed = data.get("raiders_killed", 0)
	_structures_damaged = data.get("structures_damaged", {})
	_structures_destroyed = data.get("structures_destroyed", [])
	_loot_stolen = data.get("loot_stolen", [])
	current_day = data.get("current_day", 1)
