extends Node

## EnemySpawnSystem - Dynamic enemy spawning with wave mechanics, horde events, and difficulty scaling
## Creates challenging and rewarding combat encounters

class_name EnemySpawnSystem

# ============================================================================
# SIGNALS
# ============================================================================

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal horde_started()
signal horde_completed()
signal boss_spawned(boss: Node)
signal boss_killed(boss: Node)
signal enemy_spawned(enemy: Node)
signal enemy_killed(enemy: Node)
signal difficulty_changed(new_level: float)

# ============================================================================
# ENEMY TYPES
# ============================================================================

const ENEMY_DATA := {
	# Basic zombies
	"zombie_walker": {
		"name": "Walker",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 30,
		"damage": 5,
		"speed": 50.0,
		"xp_reward": 10,
		"loot_tier": 0,
		"weight": 100,  # Spawn weight
		"min_day": 1
	},
	"zombie_runner": {
		"name": "Runner",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 25,
		"damage": 8,
		"speed": 100.0,
		"xp_reward": 15,
		"loot_tier": 0,
		"weight": 60,
		"min_day": 3
	},
	"zombie_bloater": {
		"name": "Bloater",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 80,
		"damage": 15,
		"speed": 30.0,
		"xp_reward": 25,
		"loot_tier": 1,
		"weight": 30,
		"min_day": 5,
		"explode_on_death": true,
		"explode_damage": 20,
		"explode_radius": 64.0
	},
	"zombie_spitter": {
		"name": "Spitter",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 20,
		"damage": 3,
		"speed": 40.0,
		"xp_reward": 20,
		"loot_tier": 1,
		"weight": 25,
		"min_day": 7,
		"ranged_attack": true,
		"projectile_damage": 10
	},
	"zombie_brute": {
		"name": "Brute",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 150,
		"damage": 25,
		"speed": 45.0,
		"xp_reward": 50,
		"loot_tier": 2,
		"weight": 15,
		"min_day": 10,
		"armor": 10
	},
	"zombie_screamer": {
		"name": "Screamer",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 15,
		"damage": 2,
		"speed": 60.0,
		"xp_reward": 30,
		"loot_tier": 1,
		"weight": 20,
		"min_day": 8,
		"calls_horde": true
	},
	
	# Special enemies
	"mutant_crawler": {
		"name": "Crawler",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 40,
		"damage": 12,
		"speed": 80.0,
		"xp_reward": 35,
		"loot_tier": 2,
		"weight": 15,
		"min_day": 15
	},
	"toxic_zombie": {
		"name": "Toxic Zombie",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 50,
		"damage": 8,
		"speed": 40.0,
		"xp_reward": 40,
		"loot_tier": 2,
		"weight": 10,
		"min_day": 20,
		"toxic_aura": true,
		"toxic_damage": 2
	},
	
	# Bosses
	"boss_giant": {
		"name": "The Giant",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 500,
		"damage": 40,
		"speed": 35.0,
		"xp_reward": 200,
		"loot_tier": 4,
		"is_boss": true,
		"min_day": 14
	},
	"boss_matriarch": {
		"name": "Matriarch",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 400,
		"damage": 25,
		"speed": 50.0,
		"xp_reward": 250,
		"loot_tier": 4,
		"is_boss": true,
		"min_day": 21,
		"spawns_minions": true
	},
	"boss_abomination": {
		"name": "The Abomination",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 1000,
		"damage": 60,
		"speed": 25.0,
		"xp_reward": 500,
		"loot_tier": 5,
		"is_boss": true,
		"min_day": 35
	}
}

# Wildlife (non-zombie enemies)
const WILDLIFE_DATA := {
	"wolf": {
		"name": "Wolf",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 40,
		"damage": 10,
		"speed": 90.0,
		"xp_reward": 20,
		"loot": ["leather", "raw_meat"],
		"weight": 30,
		"pack_size": [2, 4]
	},
	"bear": {
		"name": "Bear",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 150,
		"damage": 30,
		"speed": 60.0,
		"xp_reward": 75,
		"loot": ["leather", "raw_meat", "fat"],
		"weight": 10
	},
	"wild_dog": {
		"name": "Wild Dog",
		"scene": "res://scenes/enemies/Enemy.tscn",
		"health": 25,
		"damage": 6,
		"speed": 80.0,
		"xp_reward": 12,
		"loot": ["leather"],
		"weight": 40,
		"pack_size": [3, 6]
	}
}

# ============================================================================
# WAVE CONFIGURATION
# ============================================================================

const WAVE_CONFIG := {
	"base_enemies": 5,
	"enemies_per_wave": 2,
	"wave_interval": 180.0,  # 3 minutes between waves
	"horde_night_interval": 7,  # Horde every 7 days
	"boss_interval": 7,  # Boss every 7 waves
	"max_concurrent_enemies": 30
}

# ============================================================================
# STATE
# ============================================================================

var current_wave: int = 0
var wave_active: bool = false
var wave_enemies_remaining: int = 0
var wave_timer: float = 0.0

var horde_active: bool = false
var horde_enemies_spawned: int = 0
var horde_max_enemies: int = 50

var active_enemies: Array[Node] = []
var active_bosses: Array[Node] = []

var current_day: int = 1
var difficulty_level: float = 1.0
var spawn_multiplier: float = 1.0

var spawn_points: Array[Node2D] = []
var player_ref: Node2D = null

# Zone-specific spawning
var zone_enemy_weights: Dictionary = {
	"green": {"zombie_walker": 80, "zombie_runner": 20},
	"yellow": {"zombie_walker": 40, "zombie_runner": 30, "zombie_bloater": 20, "zombie_spitter": 10},
	"red": {"zombie_walker": 20, "zombie_runner": 25, "zombie_bloater": 20, "zombie_spitter": 15, "zombie_brute": 15, "zombie_screamer": 5}
}

var current_zone: String = "green"

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("enemy_spawn_system")
	_find_references()
	_connect_signals()

func _find_references() -> void:
	player_ref = get_tree().get_first_node_in_group("player") as Node2D
	
	# Find spawn points in the scene
	spawn_points = []
	for node in get_tree().get_nodes_in_group("spawn_point"):
		if node is Node2D:
			spawn_points.append(node)

func _connect_signals() -> void:
	var day_night := get_tree().get_first_node_in_group("day_night_system")
	if day_night:
		if day_night.has_signal("day_changed"):
			day_night.day_changed.connect(_on_day_changed)
		if day_night.has_signal("period_changed"):
			day_night.period_changed.connect(_on_period_changed)

# ============================================================================
# MAIN LOOP
# ============================================================================

func _process(delta: float) -> void:
	# Update wave timer
	if not wave_active and not horde_active:
		wave_timer += delta
		
		if wave_timer >= WAVE_CONFIG.wave_interval:
			start_wave()
	
	# Check wave completion
	if wave_active and wave_enemies_remaining <= 0 and active_enemies.is_empty():
		_complete_wave()
	
	# Check horde completion
	if horde_active and active_enemies.is_empty() and horde_enemies_spawned >= horde_max_enemies:
		_complete_horde()
	
	# Clean up dead enemy references
	_cleanup_dead_enemies()

func _cleanup_dead_enemies() -> void:
	for i in range(active_enemies.size() - 1, -1, -1):
		if not is_instance_valid(active_enemies[i]):
			active_enemies.remove_at(i)
	
	for i in range(active_bosses.size() - 1, -1, -1):
		if not is_instance_valid(active_bosses[i]):
			active_bosses.remove_at(i)

# ============================================================================
# WAVE SYSTEM
# ============================================================================

func start_wave() -> void:
	if wave_active or horde_active:
		return
	
	current_wave += 1
	wave_active = true
	wave_timer = 0.0
	
	# Calculate wave size
	var wave_size := WAVE_CONFIG.base_enemies + (current_wave * WAVE_CONFIG.enemies_per_wave)
	wave_size = int(wave_size * difficulty_level * spawn_multiplier)
	wave_size = min(wave_size, WAVE_CONFIG.max_concurrent_enemies)
	
	wave_enemies_remaining = wave_size
	
	wave_started.emit(current_wave)
	
	# Spawn enemies over time
	_spawn_wave_enemies(wave_size)
	
	# Check for boss wave
	if current_wave % WAVE_CONFIG.boss_interval == 0:
		_spawn_boss()

func _spawn_wave_enemies(count: int) -> void:
	var spawn_delay := 0.0
	
	for i in range(count):
		if active_enemies.size() >= WAVE_CONFIG.max_concurrent_enemies:
			wave_enemies_remaining = 0
			break
		
		var timer := get_tree().create_timer(spawn_delay)
		timer.timeout.connect(_spawn_random_enemy.bind(current_zone))
		spawn_delay += randf_range(0.5, 2.0)

func _complete_wave() -> void:
	wave_active = false
	wave_completed.emit(current_wave)
	
	# Grant wave completion rewards
	var reward_xp := 50 + (current_wave * 10)
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_xp"):
		player.add_xp(reward_xp)

# ============================================================================
# HORDE SYSTEM
# ============================================================================

func start_horde() -> void:
	if horde_active:
		return
	
	horde_active = true
	horde_enemies_spawned = 0
	horde_max_enemies = 50 + (current_day * 5)
	horde_max_enemies = int(horde_max_enemies * difficulty_level)
	
	horde_started.emit()
	
	_spawn_horde()

func _spawn_horde() -> void:
	# Spawn in waves
	var spawn_batch_size := 10
	var batches := ceili(float(horde_max_enemies) / spawn_batch_size)
	
	for batch in range(batches):
		var timer := get_tree().create_timer(batch * 5.0)  # 5 seconds between batches
		timer.timeout.connect(_spawn_horde_batch.bind(spawn_batch_size))

func _spawn_horde_batch(count: int) -> void:
	if not horde_active:
		return
	
	for i in range(count):
		if active_enemies.size() >= WAVE_CONFIG.max_concurrent_enemies:
			await get_tree().create_timer(2.0).timeout
		
		if horde_enemies_spawned < horde_max_enemies:
			_spawn_random_enemy(current_zone)
			horde_enemies_spawned += 1

func _complete_horde() -> void:
	horde_active = false
	horde_completed.emit()
	
	# Major rewards for surviving horde
	var reward_xp := 500 + (current_day * 25)
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_xp"):
		player.add_xp(reward_xp)

# ============================================================================
# SPAWNING
# ============================================================================

func _spawn_random_enemy(zone: String) -> Node:
	var weights: Dictionary = zone_enemy_weights.get(zone, zone_enemy_weights.green)
	var enemy_type := _weighted_random(weights)
	
	return spawn_enemy(enemy_type)

func spawn_enemy(enemy_type: String) -> Node:
	if not ENEMY_DATA.has(enemy_type):
		push_error("Unknown enemy type: " + enemy_type)
		return null
	
	var enemy_info: Dictionary = ENEMY_DATA[enemy_type]
	
	# Check day requirement
	if current_day < enemy_info.get("min_day", 1):
		# Fall back to basic zombie
		enemy_type = "zombie_walker"
		enemy_info = ENEMY_DATA[enemy_type]
	
	# Load and instantiate enemy
	var scene_path: String = enemy_info.get("scene", "")
	if scene_path.is_empty():
		return null
	
	var scene := load(scene_path)
	if not scene:
		return null
	
	var enemy := scene.instantiate()
	
	# Apply stats with difficulty scaling
	_apply_enemy_stats(enemy, enemy_info)
	
	# Position enemy
	var spawn_pos := _get_spawn_position()
	enemy.global_position = spawn_pos
	
	# Add to scene
	var enemies_container := get_tree().get_first_node_in_group("enemies_container")
	if enemies_container:
		enemies_container.add_child(enemy)
	else:
		get_parent().add_child(enemy)
	
	# Track enemy
	active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_died.bind(enemy, enemy_info))
	
	enemy_spawned.emit(enemy)
	return enemy

func _apply_enemy_stats(enemy: Node, info: Dictionary) -> void:
	# Apply base stats with difficulty scaling
	if "health" in enemy:
		enemy.health = info.get("health", 30) * difficulty_level
	if "max_health" in enemy:
		enemy.max_health = info.get("health", 30) * difficulty_level
	if "damage" in enemy:
		enemy.damage = info.get("damage", 5) * difficulty_level
	if "move_speed" in enemy:
		enemy.move_speed = info.get("speed", 50.0)
	if "speed" in enemy:
		enemy.speed = info.get("speed", 50.0)
	
	# Store XP reward and loot tier for death handling
	enemy.set_meta("xp_reward", info.get("xp_reward", 10))
	enemy.set_meta("loot_tier", info.get("loot_tier", 0))
	enemy.set_meta("is_boss", info.get("is_boss", false))

func _spawn_boss() -> void:
	# Select appropriate boss
	var available_bosses := []
	for boss_id in ENEMY_DATA:
		var info: Dictionary = ENEMY_DATA[boss_id]
		if info.get("is_boss", false) and current_day >= info.get("min_day", 1):
			available_bosses.append(boss_id)
	
	if available_bosses.is_empty():
		return
	
	var boss_type: String = available_bosses.pick_random()
	var boss := spawn_enemy(boss_type)
	
	if boss:
		active_bosses.append(boss)
		boss_spawned.emit(boss)

func spawn_wildlife(zone: String) -> Node:
	var weights: Dictionary = {}
	for wildlife_id in WILDLIFE_DATA:
		weights[wildlife_id] = WILDLIFE_DATA[wildlife_id].get("weight", 10)
	
	var wildlife_type := _weighted_random(weights)
	var info: Dictionary = WILDLIFE_DATA[wildlife_type]
	
	# Load scene
	var scene: PackedScene = load(info.get("scene", ""))
	if not scene:
		return null
	
	var wildlife := scene.instantiate()
	_apply_enemy_stats(wildlife, info)
	
	wildlife.global_position = _get_spawn_position()
	
	var container := get_tree().get_first_node_in_group("enemies_container")
	if container:
		container.add_child(wildlife)
	else:
		get_parent().add_child(wildlife)
	
	# Spawn pack if applicable
	var pack_size: Array = info.get("pack_size", [])
	if not pack_size.is_empty():
		var pack_count: int = randi_range(pack_size[0], pack_size[1]) - 1
		for i in range(pack_count):
			var pack_member := scene.instantiate()
			_apply_enemy_stats(pack_member, info)
			pack_member.global_position = wildlife.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
			if container:
				container.add_child(pack_member)
			else:
				get_parent().add_child(pack_member)
	
	return wildlife

func _get_spawn_position() -> Vector2:
	if spawn_points.is_empty() and player_ref:
		# Spawn at random position around player
		var angle := randf() * TAU
		var distance := randf_range(300, 500)
		return player_ref.global_position + Vector2.from_angle(angle) * distance
	elif not spawn_points.is_empty():
		return spawn_points.pick_random().global_position
	else:
		return Vector2(randf_range(-500, 500), randf_range(-500, 500))

# ============================================================================
# ENEMY DEATH HANDLING
# ============================================================================

func _on_enemy_died(enemy: Node, info: Dictionary) -> void:
	active_enemies.erase(enemy)
	
	if wave_active:
		wave_enemies_remaining = max(wave_enemies_remaining - 1, 0)
	
	# Grant XP
	var xp_reward: int = enemy.get_meta("xp_reward", info.get("xp_reward", 10))
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)
	
	# Handle boss death
	if enemy.get_meta("is_boss", false):
		active_bosses.erase(enemy)
		boss_killed.emit(enemy)
	
	# Spawn loot
	_spawn_enemy_loot(enemy.global_position if is_instance_valid(enemy) else Vector2.ZERO, info)
	
	enemy_killed.emit(enemy)

func _spawn_enemy_loot(position: Vector2, enemy_info: Dictionary) -> void:
	var loot_tier: int = enemy_info.get("loot_tier", 0)
	
	# Get loot from LootSystem if available
	var loot_system := get_tree().get_first_node_in_group("loot_system")
	if loot_system and loot_system.has_method("generate_loot"):
		var loot: Array = loot_system.generate_loot("enemy", loot_tier)
		for item in loot:
			_spawn_loot_item(position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), item)

func _spawn_loot_item(position: Vector2, item: Dictionary) -> void:
	var loot_scene := load("res://scenes/resources/LootItem.tscn")
	if not loot_scene:
		return
	
	var loot_node := loot_scene.instantiate()
	loot_node.global_position = position
	
	if "item_id" in loot_node:
		loot_node.item_id = item.get("id", "")
	if "item_count" in loot_node:
		loot_node.item_count = item.get("count", 1)
	
	get_parent().add_child(loot_node)

# ============================================================================
# UTILITY
# ============================================================================

func _weighted_random(weights: Dictionary) -> String:
	var total_weight := 0
	for key in weights:
		total_weight += weights[key]
	
	var roll := randi() % total_weight
	var current := 0
	
	for key in weights:
		current += weights[key]
		if roll < current:
			return key
	
	return weights.keys()[0]

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_day_changed(day: int) -> void:
	current_day = day
	
	# Scale difficulty
	difficulty_level = 1.0 + (day - 1) * 0.1
	difficulty_changed.emit(difficulty_level)
	
	# Check for horde night
	if day % WAVE_CONFIG.horde_night_interval == 0:
		# Delay horde until night
		var day_night := get_tree().get_first_node_in_group("day_night_system")
		if day_night and day_night.has_method("is_night") and day_night.is_night():
			start_horde()

func _on_period_changed(period: String) -> void:
	if period == "Night":
		# Increase spawn rate at night
		spawn_multiplier = 1.5
		
		# Check for horde night
		if current_day % WAVE_CONFIG.horde_night_interval == 0:
			start_horde()
	else:
		spawn_multiplier = 1.0

# ============================================================================
# API
# ============================================================================

func set_zone(zone: String) -> void:
	current_zone = zone
	_find_references()  # Refresh spawn points

func get_active_enemy_count() -> int:
	return active_enemies.size()

func get_current_wave() -> int:
	return current_wave

func is_horde_active() -> bool:
	return horde_active

func is_wave_active() -> bool:
	return wave_active

func kill_all_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy.has_method("die"):
			enemy.die()
	
	active_enemies.clear()
	active_bosses.clear()
	wave_enemies_remaining = 0

func force_spawn(enemy_type: String, count: int = 1) -> Array[Node]:
	var spawned: Array[Node] = []
	for i in range(count):
		var enemy := spawn_enemy(enemy_type)
		if enemy:
			spawned.append(enemy)
	return spawned

func set_difficulty(level: float) -> void:
	difficulty_level = max(level, 0.5)
	difficulty_changed.emit(difficulty_level)
