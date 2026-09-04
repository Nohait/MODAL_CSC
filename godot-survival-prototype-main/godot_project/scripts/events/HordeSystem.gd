extends Node
class_name HordeSystemClass
## Manages zombie horde events, waves, and survival mechanics
## Handles spawning, difficulty scaling, and rewards

signal horde_announced(time_until: float)
signal horde_started(wave_count: int)
signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int)
signal horde_completed(total_kills: int, rewards: Dictionary)
signal horde_failed()
signal enemy_spawned(enemy_data: Dictionary)
signal special_enemy_spawned(enemy_type: int)

# ============================================================================
# HORDE CONFIGURATION
# ============================================================================

enum HordeType {
	NORMAL,           # Standard zombie horde
	BLOOD_MOON,       # Special powerful horde
	FERAL,            # Fast aggressive zombies
	TOXIC,            # Poison/acid zombies
	ARMORED,          # Heavy armored zombies
	MIXED,            # All types combined
	BOSS_HORDE,       # Horde with boss
	MEGA_HORDE,       # Massive overwhelming horde
}

enum EnemyType {
	ZOMBIE_WALKER,
	ZOMBIE_RUNNER,
	ZOMBIE_CRAWLER,
	ZOMBIE_SPITTER,
	ZOMBIE_BLOATER,
	ZOMBIE_SCREAMER,
	ZOMBIE_BRUTE,
	ZOMBIE_FERAL,
	ZOMBIE_IRRADIATED,
	ZOMBIE_ARMORED,
	ZOMBIE_GIANT,
	ZOMBIE_BOSS,
}

enum SpawnPattern {
	RANDOM,           # Random positions around base
	DIRECTIONAL,      # From one direction
	SURROUND,         # From all directions
	WAVES,            # Timed waves from multiple points
	CRESCENDO,        # Increasing intensity
}

const ENEMY_DEFINITIONS := {
	EnemyType.ZOMBIE_WALKER: {
		"display_name": "Walker",
		"health": 50,
		"damage": 10,
		"speed": 40.0,
		"xp_value": 5,
		"spawn_weight": 100,
		"min_day": 1,
		"loot_table": "zombie_common",
	},
	EnemyType.ZOMBIE_RUNNER: {
		"display_name": "Runner",
		"health": 35,
		"damage": 12,
		"speed": 80.0,
		"xp_value": 8,
		"spawn_weight": 50,
		"min_day": 3,
		"loot_table": "zombie_common",
	},
	EnemyType.ZOMBIE_CRAWLER: {
		"display_name": "Crawler",
		"health": 25,
		"damage": 8,
		"speed": 30.0,
		"xp_value": 4,
		"spawn_weight": 40,
		"min_day": 1,
		"loot_table": "zombie_common",
		"special": "low_profile",
	},
	EnemyType.ZOMBIE_SPITTER: {
		"display_name": "Spitter",
		"health": 40,
		"damage": 15,
		"speed": 45.0,
		"xp_value": 12,
		"spawn_weight": 25,
		"min_day": 7,
		"loot_table": "zombie_special",
		"special": "ranged_attack",
		"attack_range": 200.0,
	},
	EnemyType.ZOMBIE_BLOATER: {
		"display_name": "Bloater",
		"health": 80,
		"damage": 5,
		"speed": 25.0,
		"xp_value": 15,
		"spawn_weight": 20,
		"min_day": 10,
		"loot_table": "zombie_special",
		"special": "explode_on_death",
		"explosion_radius": 100.0,
		"explosion_damage": 30,
	},
	EnemyType.ZOMBIE_SCREAMER: {
		"display_name": "Screamer",
		"health": 30,
		"damage": 5,
		"speed": 50.0,
		"xp_value": 20,
		"spawn_weight": 15,
		"min_day": 14,
		"loot_table": "zombie_special",
		"special": "summon_horde",
		"summon_count": 5,
	},
	EnemyType.ZOMBIE_BRUTE: {
		"display_name": "Brute",
		"health": 200,
		"damage": 35,
		"speed": 35.0,
		"xp_value": 30,
		"spawn_weight": 10,
		"min_day": 21,
		"loot_table": "zombie_rare",
		"special": "structure_damage",
		"structure_damage_mult": 3.0,
	},
	EnemyType.ZOMBIE_FERAL: {
		"display_name": "Feral",
		"health": 60,
		"damage": 25,
		"speed": 100.0,
		"xp_value": 25,
		"spawn_weight": 15,
		"min_day": 14,
		"loot_table": "zombie_rare",
		"special": "leap_attack",
		"leap_range": 150.0,
	},
	EnemyType.ZOMBIE_IRRADIATED: {
		"display_name": "Irradiated",
		"health": 100,
		"damage": 20,
		"speed": 45.0,
		"xp_value": 35,
		"spawn_weight": 8,
		"min_day": 28,
		"loot_table": "zombie_rare",
		"special": "radiation_aura",
		"aura_damage": 5,
		"aura_radius": 80.0,
	},
	EnemyType.ZOMBIE_ARMORED: {
		"display_name": "Armored Zombie",
		"health": 150,
		"damage": 20,
		"speed": 30.0,
		"armor": 50,
		"xp_value": 40,
		"spawn_weight": 8,
		"min_day": 21,
		"loot_table": "zombie_rare",
		"special": "armored",
	},
	EnemyType.ZOMBIE_GIANT: {
		"display_name": "Giant",
		"health": 500,
		"damage": 50,
		"speed": 25.0,
		"xp_value": 100,
		"spawn_weight": 3,
		"min_day": 35,
		"loot_table": "zombie_epic",
		"special": "ground_slam",
		"slam_radius": 120.0,
		"slam_damage": 40,
		"scale": 2.0,
	},
	EnemyType.ZOMBIE_BOSS: {
		"display_name": "Horde Boss",
		"health": 1000,
		"damage": 60,
		"speed": 40.0,
		"armor": 30,
		"xp_value": 500,
		"spawn_weight": 0,  # Only spawned specially
		"min_day": 42,
		"loot_table": "zombie_boss",
		"special": "boss",
		"abilities": ["summon", "rage", "ground_slam"],
		"scale": 2.5,
	},
}

const HORDE_SCHEDULES := {
	# Day -> Horde config
	7: {"type": HordeType.NORMAL, "waves": 3, "base_count": 15},
	14: {"type": HordeType.FERAL, "waves": 4, "base_count": 20},
	21: {"type": HordeType.ARMORED, "waves": 4, "base_count": 25},
	28: {"type": HordeType.BLOOD_MOON, "waves": 5, "base_count": 30},
	35: {"type": HordeType.TOXIC, "waves": 5, "base_count": 35},
	42: {"type": HordeType.BOSS_HORDE, "waves": 6, "base_count": 40},
	49: {"type": HordeType.MEGA_HORDE, "waves": 7, "base_count": 50},
}

const WAVE_REWARDS := {
	1: {"xp_mult": 1.0, "loot_mult": 1.0},
	2: {"xp_mult": 1.2, "loot_mult": 1.1},
	3: {"xp_mult": 1.5, "loot_mult": 1.2},
	4: {"xp_mult": 1.8, "loot_mult": 1.4},
	5: {"xp_mult": 2.0, "loot_mult": 1.6},
	6: {"xp_mult": 2.5, "loot_mult": 1.8},
	7: {"xp_mult": 3.0, "loot_mult": 2.0},
}


# ============================================================================
# STATE
# ============================================================================

var is_horde_active: bool = false
var current_horde_type: int = HordeType.NORMAL
var current_wave: int = 0
var total_waves: int = 0
var current_day: int = 1

var _enemies_spawned: int = 0
var _enemies_killed: int = 0
var _enemies_remaining: int = 0
var _wave_enemies: Array = []
var _spawn_queue: Array = []
var _spawn_timer: float = 0.0
var _wave_timer: float = 0.0
var _announcement_timer: float = 0.0
var _horde_pending: bool = false

var _spawn_points: Array = []
var _base_center: Vector2 = Vector2.ZERO
var _spawn_radius: float = 800.0

var _total_xp_earned: int = 0
var _loot_drops: Array = []


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _horde_pending:
		_announcement_timer -= delta
		if _announcement_timer <= 0.0:
			_start_horde()
	
	if is_horde_active:
		_update_horde(delta)


# ============================================================================
# HORDE MANAGEMENT
# ============================================================================

func schedule_horde(delay: float, horde_type: int = HordeType.NORMAL, waves: int = 3, base_count: int = 20) -> void:
	if is_horde_active or _horde_pending:
		return
	
	_horde_pending = true
	_announcement_timer = delay
	current_horde_type = horde_type
	total_waves = waves
	
	_enemies_spawned = 0
	_enemies_killed = 0
	_total_xp_earned = 0
	_loot_drops.clear()
	
	# Calculate spawn based on base_count and type
	_spawn_queue = _generate_spawn_queue(horde_type, waves, base_count)
	
	emit_signal("horde_announced", delay)


func check_scheduled_horde(day: int) -> void:
	current_day = day
	
	# Check weekly hordes (every 7 days)
	if day % 7 == 0:
		var schedule: Dictionary = HORDE_SCHEDULES.get(day, {})
		if schedule.is_empty():
			# Default horde for days not in schedule
			var wave_count := 3 + (day / 14)
			var base_count := 15 + (day / 7) * 5
			schedule_horde(120.0, HordeType.NORMAL, wave_count, base_count)
		else:
			schedule_horde(120.0, schedule["type"], schedule["waves"], schedule["base_count"])


func _start_horde() -> void:
	_horde_pending = false
	is_horde_active = true
	current_wave = 0
	
	emit_signal("horde_started", total_waves)
	_start_next_wave()


func _start_next_wave() -> void:
	current_wave += 1
	
	if current_wave > total_waves:
		_complete_horde()
		return
	
	# Get enemies for this wave
	var wave_index := current_wave - 1
	if wave_index < _spawn_queue.size():
		_wave_enemies = _spawn_queue[wave_index].duplicate()
	else:
		_wave_enemies = []
	
	_enemies_remaining = _wave_enemies.size()
	_spawn_timer = 0.0
	_wave_timer = 0.0
	
	emit_signal("wave_started", current_wave, _enemies_remaining)


func _update_horde(delta: float) -> void:
	# Spawn enemies
	if _wave_enemies.size() > 0:
		_spawn_timer += delta
		var spawn_interval := _get_spawn_interval()
		
		while _spawn_timer >= spawn_interval and _wave_enemies.size() > 0:
			_spawn_timer -= spawn_interval
			_spawn_enemy(_wave_enemies.pop_front())
	
	# Check wave completion
	if _wave_enemies.is_empty() and _enemies_remaining <= 0:
		emit_signal("wave_completed", current_wave)
		
		# Brief pause between waves
		_wave_timer += delta
		if _wave_timer >= 5.0:
			_start_next_wave()


func _complete_horde() -> void:
	is_horde_active = false
	
	var rewards := _calculate_rewards()
	emit_signal("horde_completed", _enemies_killed, rewards)


func fail_horde() -> void:
	is_horde_active = false
	_horde_pending = false
	_wave_enemies.clear()
	_spawn_queue.clear()
	
	emit_signal("horde_failed")


func _get_spawn_interval() -> float:
	# Faster spawning in later waves and harder horde types
	var base_interval := 1.5
	
	match current_horde_type:
		HordeType.FERAL:
			base_interval = 1.0
		HordeType.BLOOD_MOON:
			base_interval = 0.8
		HordeType.MEGA_HORDE:
			base_interval = 0.5
	
	# Faster in later waves
	base_interval *= pow(0.9, current_wave - 1)
	
	return maxf(base_interval, 0.3)


# ============================================================================
# SPAWN GENERATION
# ============================================================================

func _generate_spawn_queue(horde_type: int, waves: int, base_count: int) -> Array:
	var queue: Array = []
	
	for wave in range(1, waves + 1):
		var wave_enemies: Array = []
		var wave_count := int(base_count * (1.0 + (wave - 1) * 0.3))
		
		# Get available enemy types for this day
		var available_types := _get_available_enemies(horde_type)
		
		# Special enemies for later waves
		var special_count := 0
		if wave >= 3:
			special_count = wave - 2
		
		# Generate enemy list
		for i in range(wave_count):
			var enemy_type: int
			
			if i < special_count:
				enemy_type = _pick_special_enemy(horde_type, wave)
			else:
				enemy_type = _pick_weighted_enemy(available_types)
			
			wave_enemies.append(enemy_type)
		
		# Add boss to final wave of boss hordes
		if horde_type == HordeType.BOSS_HORDE and wave == waves:
			wave_enemies.append(EnemyType.ZOMBIE_BOSS)
		
		# Shuffle for variety
		wave_enemies.shuffle()
		queue.append(wave_enemies)
	
	return queue


func _get_available_enemies(horde_type: int) -> Array:
	var available: Array = []
	
	for enemy_type in ENEMY_DEFINITIONS:
		var def: Dictionary = ENEMY_DEFINITIONS[enemy_type]
		
		if current_day < def.get("min_day", 1):
			continue
		
		if def.get("spawn_weight", 0) <= 0:
			continue
		
		# Filter by horde type
		match horde_type:
			HordeType.FERAL:
				if enemy_type in [EnemyType.ZOMBIE_RUNNER, EnemyType.ZOMBIE_FERAL, EnemyType.ZOMBIE_CRAWLER]:
					available.append(enemy_type)
			HordeType.TOXIC:
				if enemy_type in [EnemyType.ZOMBIE_SPITTER, EnemyType.ZOMBIE_BLOATER, EnemyType.ZOMBIE_IRRADIATED]:
					available.append(enemy_type)
			HordeType.ARMORED:
				if enemy_type in [EnemyType.ZOMBIE_ARMORED, EnemyType.ZOMBIE_BRUTE]:
					available.append(enemy_type)
			_:
				available.append(enemy_type)
	
	# Ensure at least basic zombies
	if available.is_empty():
		available.append(EnemyType.ZOMBIE_WALKER)
	
	return available


func _pick_weighted_enemy(available: Array) -> int:
	var total_weight := 0
	for enemy_type in available:
		total_weight += ENEMY_DEFINITIONS[enemy_type].get("spawn_weight", 10)
	
	var roll := randi() % total_weight
	var current := 0
	
	for enemy_type in available:
		current += ENEMY_DEFINITIONS[enemy_type].get("spawn_weight", 10)
		if roll < current:
			return enemy_type
	
	return available[0]


func _pick_special_enemy(horde_type: int, wave: int) -> int:
	var specials: Array = []
	
	match horde_type:
		HordeType.BLOOD_MOON:
			specials = [EnemyType.ZOMBIE_FERAL, EnemyType.ZOMBIE_BRUTE, EnemyType.ZOMBIE_GIANT]
		HordeType.FERAL:
			specials = [EnemyType.ZOMBIE_FERAL, EnemyType.ZOMBIE_RUNNER]
		HordeType.TOXIC:
			specials = [EnemyType.ZOMBIE_BLOATER, EnemyType.ZOMBIE_IRRADIATED]
		HordeType.ARMORED:
			specials = [EnemyType.ZOMBIE_ARMORED, EnemyType.ZOMBIE_BRUTE]
		HordeType.MEGA_HORDE:
			specials = [EnemyType.ZOMBIE_GIANT, EnemyType.ZOMBIE_BRUTE, EnemyType.ZOMBIE_SCREAMER]
		_:
			specials = [EnemyType.ZOMBIE_SCREAMER, EnemyType.ZOMBIE_BRUTE]
	
	# Filter by day
	specials = specials.filter(func(t): return current_day >= ENEMY_DEFINITIONS[t].get("min_day", 1))
	
	if specials.is_empty():
		return EnemyType.ZOMBIE_WALKER
	
	return specials[randi() % specials.size()]


# ============================================================================
# ENEMY SPAWNING
# ============================================================================

func set_spawn_config(base_center: Vector2, spawn_radius: float, spawn_points: Array = []) -> void:
	_base_center = base_center
	_spawn_radius = spawn_radius
	_spawn_points = spawn_points


func _spawn_enemy(enemy_type: int) -> void:
	var definition: Dictionary = ENEMY_DEFINITIONS.get(enemy_type, {})
	if definition.is_empty():
		return
	
	var spawn_pos := _get_spawn_position()
	
	var enemy_data := {
		"type": enemy_type,
		"type_name": EnemyType.keys()[enemy_type],
		"display_name": definition.get("display_name", "Zombie"),
		"position": spawn_pos,
		"health": _scale_stat(definition.get("health", 50)),
		"max_health": _scale_stat(definition.get("health", 50)),
		"damage": _scale_stat(definition.get("damage", 10)),
		"speed": definition.get("speed", 40.0),
		"armor": definition.get("armor", 0),
		"xp_value": definition.get("xp_value", 5),
		"loot_table": definition.get("loot_table", "zombie_common"),
		"special": definition.get("special", ""),
		"scale": definition.get("scale", 1.0),
		"horde_id": randi(),
	}
	
	# Copy special properties
	for key in ["attack_range", "explosion_radius", "explosion_damage", "summon_count",
				"structure_damage_mult", "leap_range", "aura_damage", "aura_radius",
				"slam_radius", "slam_damage", "abilities"]:
		if key in definition:
			enemy_data[key] = definition[key]
	
	_enemies_spawned += 1
	
	if definition.get("special", "") != "":
		emit_signal("special_enemy_spawned", enemy_type)
	
	emit_signal("enemy_spawned", enemy_data)


func _get_spawn_position() -> Vector2:
	if _spawn_points.size() > 0:
		return _spawn_points[randi() % _spawn_points.size()]
	
	# Random position around base
	var angle := randf() * TAU
	var distance := _spawn_radius + randf_range(0, 100)
	
	return _base_center + Vector2(cos(angle), sin(angle)) * distance


func _scale_stat(base_value: int) -> int:
	# Scale stats based on day and wave
	var day_mult := 1.0 + (current_day - 1) * 0.02
	var wave_mult := 1.0 + (current_wave - 1) * 0.1
	
	match current_horde_type:
		HordeType.BLOOD_MOON:
			day_mult *= 1.5
		HordeType.MEGA_HORDE:
			day_mult *= 2.0
	
	return int(base_value * day_mult * wave_mult)


# ============================================================================
# ENEMY EVENTS
# ============================================================================

func on_enemy_killed(enemy_data: Dictionary) -> void:
	_enemies_remaining -= 1
	_enemies_killed += 1
	
	var xp := enemy_data.get("xp_value", 5)
	var wave_data: Dictionary = WAVE_REWARDS.get(current_wave, {"xp_mult": 1.0})
	xp = int(xp * wave_data.get("xp_mult", 1.0))
	
	_total_xp_earned += xp
	
	# Handle special death effects
	var special: String = enemy_data.get("special", "")
	
	match special:
		"explode_on_death":
			_handle_bloater_explosion(enemy_data)
		"summon_horde":
			_handle_screamer_death(enemy_data)


func _handle_bloater_explosion(enemy_data: Dictionary) -> void:
	# Explosion damage to nearby entities
	# This would be handled by the game world
	pass


func _handle_screamer_death(enemy_data: Dictionary) -> void:
	# Spawn additional enemies
	var summon_count: int = enemy_data.get("summon_count", 5)
	for i in range(summon_count):
		_wave_enemies.append(EnemyType.ZOMBIE_WALKER)
		_enemies_remaining += 1


func on_enemy_reached_base(enemy_data: Dictionary) -> void:
	# Handle enemy attacking base
	pass


# ============================================================================
# REWARDS
# ============================================================================

func _calculate_rewards() -> Dictionary:
	var wave_data: Dictionary = WAVE_REWARDS.get(total_waves, {"loot_mult": 1.0})
	var loot_mult: float = wave_data.get("loot_mult", 1.0)
	
	# Bonus for horde type
	match current_horde_type:
		HordeType.BLOOD_MOON:
			loot_mult *= 1.5
		HordeType.BOSS_HORDE:
			loot_mult *= 2.0
		HordeType.MEGA_HORDE:
			loot_mult *= 2.5
	
	# Calculate completion bonus
	var completion_bonus := 1.0
	if _enemies_killed >= _enemies_spawned:
		completion_bonus = 1.5  # Full clear bonus
	
	return {
		"xp": int(_total_xp_earned * completion_bonus),
		"loot_multiplier": loot_mult * completion_bonus,
		"enemies_killed": _enemies_killed,
		"waves_completed": current_wave,
		"full_clear": _enemies_killed >= _enemies_spawned,
		"horde_type": current_horde_type,
	}


# ============================================================================
# QUERIES
# ============================================================================

func get_horde_status() -> Dictionary:
	return {
		"is_active": is_horde_active,
		"is_pending": _horde_pending,
		"time_until": _announcement_timer if _horde_pending else 0.0,
		"current_wave": current_wave,
		"total_waves": total_waves,
		"enemies_remaining": _enemies_remaining,
		"enemies_killed": _enemies_killed,
		"horde_type": current_horde_type,
		"horde_type_name": HordeType.keys()[current_horde_type],
	}


func get_next_horde_day(current: int) -> int:
	for day in HORDE_SCHEDULES:
		if day > current:
			return day
	# Weekly hordes after schedule
	return ((current / 7) + 1) * 7


func get_enemy_definition(enemy_type: int) -> Dictionary:
	return ENEMY_DEFINITIONS.get(enemy_type, {}).duplicate()


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"is_horde_active": is_horde_active,
		"current_horde_type": current_horde_type,
		"current_wave": current_wave,
		"total_waves": total_waves,
		"current_day": current_day,
		"enemies_spawned": _enemies_spawned,
		"enemies_killed": _enemies_killed,
		"enemies_remaining": _enemies_remaining,
		"horde_pending": _horde_pending,
		"announcement_timer": _announcement_timer,
		"spawn_queue": _spawn_queue.duplicate(true),
		"wave_enemies": _wave_enemies.duplicate(),
	}


func load_data(data: Dictionary) -> void:
	is_horde_active = data.get("is_horde_active", false)
	current_horde_type = data.get("current_horde_type", HordeType.NORMAL)
	current_wave = data.get("current_wave", 0)
	total_waves = data.get("total_waves", 0)
	current_day = data.get("current_day", 1)
	_enemies_spawned = data.get("enemies_spawned", 0)
	_enemies_killed = data.get("enemies_killed", 0)
	_enemies_remaining = data.get("enemies_remaining", 0)
	_horde_pending = data.get("horde_pending", false)
	_announcement_timer = data.get("announcement_timer", 0.0)
	_spawn_queue = data.get("spawn_queue", [])
	_wave_enemies = data.get("wave_enemies", [])
