extends Node2D

## EnemyAI - Advanced Behavior Tree AI System
## Superior to LDOE's simple "walk and attack" with tactical behaviors
## Features: Dodging, flanking, retreating, pack tactics, unique behaviors per type

class_name EnemyAI

# ============================================================================
# SIGNALS
# ============================================================================

signal state_changed(old_state: String, new_state: String)
signal target_acquired(target: Node2D)
signal target_lost
signal attack_started(attack_type: String)
signal attack_finished
signal damaged(amount: int, attacker: Node)
signal died
signal alerted(alert_position: Vector2)
signal called_for_help(allies: Array)

# ============================================================================
# ENUMS
# ============================================================================

enum AIState {
	IDLE,
	PATROL,
	INVESTIGATE,
	CHASE,
	COMBAT,
	ATTACK,
	DODGE,
	FLANK,
	RETREAT,
	STUNNED,
	DEAD
}

enum EnemyType {
	# Zombies
	ZOMBIE_WALKER,
	ZOMBIE_RUNNER,
	ZOMBIE_CRAWLER,
	BLOATER,
	SPITTER,
	SCREAMER,
	BRUTE,
	RAVAGER,
	THE_FORSAKEN,  # Unique name instead of "The Blind One"
	
	# Wildlife
	FERAL_DOG,
	WOLF,
	BEAR,
	
	# Hostile Survivors
	RAIDER_SCOUT,
	RAIDER_GUNNER,
	RAIDER_HEAVY
}

enum CombatStyle {
	AGGRESSIVE,     # Always pushes forward
	DEFENSIVE,      # Maintains distance, waits for openings
	TACTICAL,       # Flanks, uses cover
	BERSERKER,      # Charges when low health
	SNIPER,         # Stays at range
	PACK_HUNTER     # Coordinates with allies
}

# ============================================================================
# EXPORTS
# ============================================================================

@export var enemy_type: EnemyType = EnemyType.ZOMBIE_WALKER
@export var max_health := 100
@export var move_speed := 80.0
@export var detection_range := 200.0
@export var attack_range := 50.0
@export var attack_damage := 15
@export var attack_cooldown := 1.0

# ============================================================================
# CONSTANTS
# ============================================================================

const ENEMY_PROFILES := {
	EnemyType.ZOMBIE_WALKER: {
		"name": "Shambler",
		"health": 80,
		"speed": 50.0,
		"detection_range": 150.0,
		"attack_range": 45.0,
		"attack_damage": 12,
		"attack_cooldown": 1.5,
		"combat_style": CombatStyle.AGGRESSIVE,
		"can_dodge": false,
		"can_block": false,
		"attacks": ["bite", "grab"],
		"special_ability": null,
		"aggro_memory": 5.0,
		"wander_radius": 100.0
	},
	EnemyType.ZOMBIE_RUNNER: {
		"name": "Sprinter",
		"health": 60,
		"speed": 140.0,
		"detection_range": 250.0,
		"attack_range": 40.0,
		"attack_damage": 10,
		"attack_cooldown": 0.8,
		"combat_style": CombatStyle.AGGRESSIVE,
		"can_dodge": true,
		"dodge_chance": 0.2,
		"can_block": false,
		"attacks": ["lunge", "slash"],
		"special_ability": "leap_attack",
		"aggro_memory": 8.0
	},
	EnemyType.ZOMBIE_CRAWLER: {
		"name": "Creeper",
		"health": 40,
		"speed": 35.0,
		"detection_range": 100.0,
		"attack_range": 35.0,
		"attack_damage": 8,
		"attack_cooldown": 0.6,
		"combat_style": CombatStyle.PACK_HUNTER,
		"can_dodge": false,
		"can_block": false,
		"attacks": ["ankle_bite"],
		"special_ability": "ambush",
		"low_profile": true
	},
	EnemyType.BLOATER: {
		"name": "Bloated Horror",
		"health": 250,
		"speed": 30.0,
		"detection_range": 120.0,
		"attack_range": 60.0,
		"attack_damage": 25,
		"attack_cooldown": 2.0,
		"combat_style": CombatStyle.BERSERKER,
		"can_dodge": false,
		"can_block": false,
		"attacks": ["slam", "vomit"],
		"special_ability": "toxic_explosion",
		"explode_on_death": true,
		"explosion_radius": 80.0,
		"explosion_damage": 40
	},
	EnemyType.SPITTER: {
		"name": "Spitter",
		"health": 70,
		"speed": 60.0,
		"detection_range": 300.0,
		"attack_range": 200.0,
		"attack_damage": 15,
		"attack_cooldown": 2.5,
		"combat_style": CombatStyle.SNIPER,
		"can_dodge": true,
		"dodge_chance": 0.3,
		"can_block": false,
		"attacks": ["acid_spit"],
		"special_ability": "acid_pool",
		"preferred_range": 150.0,
		"projectile_speed": 250.0
	},
	EnemyType.SCREAMER: {
		"name": "The Wailing",
		"health": 50,
		"speed": 90.0,
		"detection_range": 400.0,
		"attack_range": 30.0,
		"attack_damage": 5,
		"attack_cooldown": 1.0,
		"combat_style": CombatStyle.DEFENSIVE,
		"can_dodge": true,
		"dodge_chance": 0.5,
		"can_block": false,
		"attacks": ["scratch"],
		"special_ability": "scream",
		"scream_radius": 500.0,
		"scream_cooldown": 10.0,
		"flees_when_close": true
	},
	EnemyType.BRUTE: {
		"name": "Devastator",
		"health": 400,
		"speed": 45.0,
		"detection_range": 180.0,
		"attack_range": 70.0,
		"attack_damage": 45,
		"attack_cooldown": 2.5,
		"combat_style": CombatStyle.BERSERKER,
		"can_dodge": false,
		"can_block": true,
		"block_chance": 0.3,
		"attacks": ["ground_pound", "charge", "grab_throw"],
		"special_ability": "enrage",
		"enrage_threshold": 0.3,
		"armor_rating": 0.3
	},
	EnemyType.RAVAGER: {
		"name": "Ravager",
		"health": 200,
		"speed": 100.0,
		"detection_range": 250.0,
		"attack_range": 55.0,
		"attack_damage": 30,
		"attack_cooldown": 1.2,
		"combat_style": CombatStyle.TACTICAL,
		"can_dodge": true,
		"dodge_chance": 0.4,
		"can_block": false,
		"attacks": ["claw_combo", "pounce"],
		"special_ability": "frenzy",
		"combo_attacks": 3
	},
	EnemyType.THE_FORSAKEN: {
		"name": "The Forsaken",  # Unique boss - not "The Blind One"
		"health": 2000,
		"speed": 55.0,
		"detection_range": 500.0,
		"attack_range": 100.0,
		"attack_damage": 80,
		"attack_cooldown": 3.0,
		"combat_style": CombatStyle.BERSERKER,
		"can_dodge": false,
		"can_block": true,
		"block_chance": 0.5,
		"attacks": ["devastating_slam", "charge", "ground_shake"],
		"special_ability": "roar",
		"is_boss": true,
		"phases": 3,
		"armor_rating": 0.5,
		"uses_sound_detection": true
	},
	EnemyType.FERAL_DOG: {
		"name": "Feral Dog",
		"health": 45,
		"speed": 160.0,
		"detection_range": 300.0,
		"attack_range": 40.0,
		"attack_damage": 12,
		"attack_cooldown": 0.7,
		"combat_style": CombatStyle.PACK_HUNTER,
		"can_dodge": true,
		"dodge_chance": 0.35,
		"can_block": false,
		"attacks": ["bite", "tackle"],
		"special_ability": "pack_howl",
		"pack_size": 4
	},
	EnemyType.WOLF: {
		"name": "Grey Wolf",
		"health": 80,
		"speed": 150.0,
		"detection_range": 350.0,
		"attack_range": 50.0,
		"attack_damage": 20,
		"attack_cooldown": 0.9,
		"combat_style": CombatStyle.TACTICAL,
		"can_dodge": true,
		"dodge_chance": 0.4,
		"can_block": false,
		"attacks": ["bite", "lunge", "circle"],
		"special_ability": "coordinated_attack",
		"pack_size": 3,
		"alpha_bonus": true
	},
	EnemyType.BEAR: {
		"name": "Grizzly Bear",
		"health": 500,
		"speed": 70.0,
		"detection_range": 200.0,
		"attack_range": 80.0,
		"attack_damage": 55,
		"attack_cooldown": 2.0,
		"combat_style": CombatStyle.BERSERKER,
		"can_dodge": false,
		"can_block": false,
		"attacks": ["swipe", "maul", "charge"],
		"special_ability": "intimidate",
		"armor_rating": 0.2,
		"enrage_threshold": 0.4
	},
	EnemyType.RAIDER_SCOUT: {
		"name": "Raider Scout",
		"health": 100,
		"speed": 100.0,
		"detection_range": 350.0,
		"attack_range": 250.0,
		"attack_damage": 18,
		"attack_cooldown": 0.8,
		"combat_style": CombatStyle.TACTICAL,
		"can_dodge": true,
		"dodge_chance": 0.45,
		"can_block": false,
		"attacks": ["pistol_shot", "knife_slash"],
		"special_ability": "call_reinforcements",
		"uses_cover": true,
		"is_human": true,
		"ranged_weapon": true
	},
	EnemyType.RAIDER_GUNNER: {
		"name": "Raider Gunner",
		"health": 120,
		"speed": 70.0,
		"detection_range": 400.0,
		"attack_range": 350.0,
		"attack_damage": 12,
		"attack_cooldown": 0.15,
		"combat_style": CombatStyle.SNIPER,
		"can_dodge": true,
		"dodge_chance": 0.25,
		"can_block": false,
		"attacks": ["rifle_burst", "grenade"],
		"special_ability": "suppressing_fire",
		"uses_cover": true,
		"is_human": true,
		"ranged_weapon": true,
		"burst_count": 5
	},
	EnemyType.RAIDER_HEAVY: {
		"name": "Raider Heavy",
		"health": 300,
		"speed": 50.0,
		"detection_range": 250.0,
		"attack_range": 80.0,
		"attack_damage": 40,
		"attack_cooldown": 1.8,
		"combat_style": CombatStyle.AGGRESSIVE,
		"can_dodge": false,
		"can_block": true,
		"block_chance": 0.4,
		"attacks": ["shotgun_blast", "shield_bash"],
		"special_ability": "fortify",
		"armor_rating": 0.4,
		"is_human": true,
		"has_shield": true
	}
}

# ============================================================================
# STATE VARIABLES
# ============================================================================

var current_state: AIState = AIState.IDLE
var previous_state: AIState = AIState.IDLE
var profile: Dictionary = {}

# Health
var current_health: int = 100

# Target tracking
var current_target: Node2D = null
var last_known_position: Vector2 = Vector2.ZERO
var aggro_timer: float = 0.0
var threat_table: Dictionary = {}  # target -> threat_value

# Combat
var attack_timer: float = 0.0
var combo_count: int = 0
var current_attack: String = ""
var is_attacking: bool = false

# Special abilities
var special_cooldown: float = 0.0
var enraged: bool = false
var boss_phase: int = 1

# Movement
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var home_position: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

# Tactical
var dodge_cooldown: float = 0.0
var flank_direction: int = 1  # 1 or -1
var preferred_distance: float = 0.0
var cover_position: Vector2 = Vector2.ZERO
var nearby_allies: Array = []

# Stun/Status
var stun_timer: float = 0.0
var status_effects: Dictionary = {}

# Navigation
var navigation_agent: NavigationAgent2D = null
var velocity: Vector2 = Vector2.ZERO

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("enemies")
	home_position = global_position
	
	_load_profile()
	_setup_navigation()
	_setup_detection()
	
	# Start in patrol or idle
	if patrol_points.size() > 0:
		_change_state(AIState.PATROL)
	else:
		_change_state(AIState.IDLE)

func _load_profile() -> void:
	if ENEMY_PROFILES.has(enemy_type):
		profile = ENEMY_PROFILES[enemy_type].duplicate(true)
		
		# Apply profile stats
		max_health = profile.get("health", max_health)
		current_health = max_health
		move_speed = profile.get("speed", move_speed)
		detection_range = profile.get("detection_range", detection_range)
		attack_range = profile.get("attack_range", attack_range)
		attack_damage = profile.get("attack_damage", attack_damage)
		attack_cooldown = profile.get("attack_cooldown", attack_cooldown)
		preferred_distance = profile.get("preferred_range", attack_range * 0.8)

func _setup_navigation() -> void:
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	add_child(navigation_agent)

func _setup_detection() -> void:
	# Create detection area
	var detection_area := Area2D.new()
	detection_area.name = "DetectionArea"
	detection_area.collision_layer = 0
	detection_area.collision_mask = 1  # Player layer
	
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = detection_range
	detection_area.add_child(shape)
	
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	
	add_child(detection_area)

# ============================================================================
# PROCESS
# ============================================================================

func _physics_process(delta: float) -> void:
	if current_state == AIState.DEAD:
		return
	
	_update_timers(delta)
	_update_threat_table(delta)
	_update_nearby_allies()
	
	match current_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.PATROL:
			_process_patrol(delta)
		AIState.INVESTIGATE:
			_process_investigate(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.COMBAT:
			_process_combat(delta)
		AIState.ATTACK:
			_process_attack(delta)
		AIState.DODGE:
			_process_dodge(delta)
		AIState.FLANK:
			_process_flank(delta)
		AIState.RETREAT:
			_process_retreat(delta)
		AIState.STUNNED:
			_process_stunned(delta)
	
	_apply_movement(delta)

func _update_timers(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
	if dodge_cooldown > 0:
		dodge_cooldown -= delta
	if special_cooldown > 0:
		special_cooldown -= delta
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0 and current_state == AIState.STUNNED:
			_recover_from_stun()
	if aggro_timer > 0:
		aggro_timer -= delta
		if aggro_timer <= 0:
			_lose_target()
	
	wander_timer -= delta

func _update_threat_table(delta: float) -> void:
	# Decay threat over time
	for target in threat_table.keys():
		if is_instance_valid(target):
			threat_table[target] = max(0, threat_table[target] - delta * 5)
		else:
			threat_table.erase(target)
	
	# Switch to highest threat target
	var highest_threat := 0.0
	var new_target: Node2D = null
	
	for target in threat_table.keys():
		if threat_table[target] > highest_threat:
			highest_threat = threat_table[target]
			new_target = target
	
	if new_target and new_target != current_target:
		current_target = new_target
		target_acquired.emit(current_target)

func _update_nearby_allies() -> void:
	nearby_allies.clear()
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self:
			continue
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) < 200.0:
			nearby_allies.append(enemy)

# ============================================================================
# STATE PROCESSORS
# ============================================================================

func _process_idle(delta: float) -> void:
	# Random wandering
	if wander_timer <= 0:
		wander_timer = randf_range(2.0, 5.0)
		var wander_radius: float = profile.get("wander_radius", 50.0)
		var wander_target := home_position + Vector2(
			randf_range(-wander_radius, wander_radius),
			randf_range(-wander_radius, wander_radius)
		)
		navigation_agent.target_position = wander_target

func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_change_state(AIState.IDLE)
		return
	
	var target_point := patrol_points[current_patrol_index]
	navigation_agent.target_position = target_point
	
	if global_position.distance_to(target_point) < 20.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		wander_timer = randf_range(1.0, 3.0)  # Pause at patrol point

func _process_investigate(delta: float) -> void:
	navigation_agent.target_position = last_known_position
	
	if global_position.distance_to(last_known_position) < 30.0:
		# Reached investigation point, look around
		wander_timer -= delta
		if wander_timer <= 0:
			if current_target:
				_change_state(AIState.CHASE)
			else:
				_change_state(AIState.PATROL if patrol_points.size() > 0 else AIState.IDLE)

func _process_chase(delta: float) -> void:
	if not is_instance_valid(current_target):
		_lose_target()
		return
	
	var distance := global_position.distance_to(current_target.global_position)
	last_known_position = current_target.global_position
	aggro_timer = profile.get("aggro_memory", 5.0)
	
	# Check if in attack range
	if distance <= attack_range:
		_change_state(AIState.COMBAT)
		return
	
	# Check for special behaviors
	var combat_style: CombatStyle = profile.get("combat_style", CombatStyle.AGGRESSIVE)
	
	if combat_style == CombatStyle.TACTICAL and profile.get("uses_cover", false):
		# Try to find cover while approaching
		_find_cover_position()
	
	navigation_agent.target_position = current_target.global_position

func _process_combat(delta: float) -> void:
	if not is_instance_valid(current_target):
		_lose_target()
		return
	
	var distance := global_position.distance_to(current_target.global_position)
	var combat_style: CombatStyle = profile.get("combat_style", CombatStyle.AGGRESSIVE)
	
	# Behavior based on combat style
	match combat_style:
		CombatStyle.AGGRESSIVE:
			_combat_aggressive(distance)
		CombatStyle.DEFENSIVE:
			_combat_defensive(distance)
		CombatStyle.TACTICAL:
			_combat_tactical(distance)
		CombatStyle.BERSERKER:
			_combat_berserker(distance)
		CombatStyle.SNIPER:
			_combat_sniper(distance)
		CombatStyle.PACK_HUNTER:
			_combat_pack(distance)

func _combat_aggressive(distance: float) -> void:
	if distance > attack_range:
		navigation_agent.target_position = current_target.global_position
	elif attack_timer <= 0:
		_start_attack()
	else:
		# Circle strafe while waiting for cooldown
		_circle_strafe()

func _combat_defensive(distance: float) -> void:
	var ideal_distance := attack_range * 0.8
	
	if distance < ideal_distance * 0.5:
		# Too close, back up
		var retreat_dir := (global_position - current_target.global_position).normalized()
		navigation_agent.target_position = global_position + retreat_dir * 50.0
	elif distance > attack_range:
		navigation_agent.target_position = current_target.global_position
	elif attack_timer <= 0:
		_start_attack()

func _combat_tactical(distance: float) -> void:
	# Flanking behavior
	if nearby_allies.size() > 0 and randf() < 0.3:
		_change_state(AIState.FLANK)
		return
	
	if distance > attack_range:
		navigation_agent.target_position = current_target.global_position
	elif attack_timer <= 0:
		_start_attack()
	else:
		_circle_strafe()

func _combat_berserker(distance: float) -> void:
	var health_percent := float(current_health) / float(max_health)
	var enrage_threshold: float = profile.get("enrage_threshold", 0.3)
	
	if health_percent <= enrage_threshold and not enraged:
		_trigger_enrage()
	
	# Berserkers always charge
	if distance > attack_range:
		navigation_agent.target_position = current_target.global_position
	elif attack_timer <= 0:
		_start_attack()

func _combat_sniper(distance: float) -> void:
	var preferred: float = profile.get("preferred_range", 150.0)
	
	if distance < preferred * 0.5:
		# Too close, retreat
		_change_state(AIState.RETREAT)
	elif distance > attack_range:
		# Move closer but not too close
		var target_pos := current_target.global_position
		var dir := (target_pos - global_position).normalized()
		navigation_agent.target_position = target_pos - dir * preferred
	elif attack_timer <= 0:
		_start_attack()

func _combat_pack(distance: float) -> void:
	# Coordinate with pack
	if nearby_allies.size() >= 2:
		# Attack together
		var pack_ready := true
		for ally in nearby_allies:
			if not ally.is_in_combat():
				pack_ready = false
				break
		
		if pack_ready and attack_timer <= 0:
			_start_attack()
			# Signal allies to attack too
			for ally in nearby_allies:
				if ally.has_method("_pack_attack_signal"):
					ally._pack_attack_signal()
	else:
		# Solo behavior - be cautious
		_combat_defensive(distance)

func _process_attack(delta: float) -> void:
	# Attack animation/execution handled here
	# Transition back to combat when done
	pass

func _process_dodge(delta: float) -> void:
	# Dodge in progress
	if navigation_agent.is_navigation_finished():
		_change_state(AIState.COMBAT if current_target else AIState.IDLE)

func _process_flank(delta: float) -> void:
	if not is_instance_valid(current_target):
		_change_state(AIState.IDLE)
		return
	
	# Calculate flank position
	var to_target := current_target.global_position - global_position
	var perpendicular := to_target.rotated(PI / 2 * flank_direction).normalized()
	var flank_pos := current_target.global_position + perpendicular * attack_range * 0.8
	
	navigation_agent.target_position = flank_pos
	
	if global_position.distance_to(flank_pos) < 30.0:
		_change_state(AIState.COMBAT)

func _process_retreat(delta: float) -> void:
	if not is_instance_valid(current_target):
		_change_state(AIState.IDLE)
		return
	
	var distance := global_position.distance_to(current_target.global_position)
	var retreat_distance: float = profile.get("preferred_range", 150.0)
	
	if distance >= retreat_distance:
		_change_state(AIState.COMBAT)
		return
	
	var retreat_dir := (global_position - current_target.global_position).normalized()
	navigation_agent.target_position = global_position + retreat_dir * 100.0

func _process_stunned(delta: float) -> void:
	velocity = Vector2.ZERO

# ============================================================================
# COMBAT ACTIONS
# ============================================================================

func _start_attack() -> void:
	if is_attacking:
		return
	
	is_attacking = true
	var attacks: Array = profile.get("attacks", ["basic_attack"])
	
	# Choose attack based on situation
	current_attack = _choose_attack(attacks)
	
	attack_started.emit(current_attack)
	_change_state(AIState.ATTACK)
	
	# Execute attack after wind-up
	var wind_up := 0.3  # Gives player time to react!
	
	if profile.get("is_human", false):
		wind_up = 0.1  # Humans attack faster
	
	await get_tree().create_timer(wind_up).timeout
	
	if current_state == AIState.ATTACK:
		_execute_attack()

func _choose_attack(attacks: Array) -> String:
	if attacks.is_empty():
		return "basic_attack"
	
	var distance := 0.0
	if is_instance_valid(current_target):
		distance = global_position.distance_to(current_target.global_position)
	
	# Choose contextually appropriate attack
	var valid_attacks := attacks.duplicate()
	
	# Filter by range
	if distance > attack_range * 0.5:
		valid_attacks = valid_attacks.filter(func(a): 
			return a in ["lunge", "charge", "leap_attack", "acid_spit", "pistol_shot", "rifle_burst"]
		)
		if valid_attacks.is_empty():
			valid_attacks = attacks.duplicate()
	
	# Combo attacks
	if combo_count > 0 and "claw_combo" in attacks:
		return "claw_combo"
	
	return valid_attacks.pick_random()

func _execute_attack() -> void:
	if not is_instance_valid(current_target):
		_finish_attack()
		return
	
	var distance := global_position.distance_to(current_target.global_position)
	
	# Check if target dodged/moved away
	if distance > attack_range * 1.5:
		_finish_attack()
		return
	
	# Deal damage based on attack type
	var damage := attack_damage
	
	match current_attack:
		"claw_combo":
			combo_count += 1
			if combo_count >= profile.get("combo_attacks", 3):
				damage = int(damage * 1.5)
				combo_count = 0
		"charge", "ground_pound":
			damage = int(damage * 1.5)
		"acid_spit", "pistol_shot", "rifle_burst":
			_fire_projectile(damage)
			_finish_attack()
			return
		"grab", "grab_throw":
			_attempt_grab()
			_finish_attack()
			return
	
	# Apply damage if target is in range
	if distance <= attack_range and current_target.has_method("take_damage"):
		# Check if target is blocking
		if current_target.has_method("is_blocking") and current_target.is_blocking():
			damage = int(damage * 0.3)
		
		# Check if target dodges
		if current_target.has_method("try_dodge") and current_target.try_dodge():
			damage = 0
		
		if damage > 0:
			current_target.take_damage(damage, self)
	
	_finish_attack()

func _finish_attack() -> void:
	is_attacking = false
	attack_timer = attack_cooldown
	
	if enraged:
		attack_timer *= 0.6  # Faster attacks when enraged
	
	attack_finished.emit()
	_change_state(AIState.COMBAT if current_target else AIState.IDLE)

func _fire_projectile(damage: int) -> void:
	if not is_instance_valid(current_target):
		return
	
	# Spawn projectile (simplified - would need ProjectileManager)
	var direction := (current_target.global_position - global_position).normalized()
	var speed: float = profile.get("projectile_speed", 300.0)
	
	# For now, use hitscan with accuracy falloff
	var accuracy := 0.8 - (global_position.distance_to(current_target.global_position) / attack_range) * 0.3
	
	if randf() <= accuracy:
		if current_target.has_method("take_damage"):
			current_target.take_damage(damage, self)

func _attempt_grab() -> void:
	if not is_instance_valid(current_target):
		return
	
	# Grab mechanic - immobilizes target briefly
	if current_target.has_method("apply_grabbed"):
		current_target.apply_grabbed(1.5)  # 1.5 second grab

# ============================================================================
# SPECIAL ABILITIES
# ============================================================================

func _trigger_special_ability() -> void:
	if special_cooldown > 0:
		return
	
	var ability: String = profile.get("special_ability", "")
	if ability.is_empty():
		return
	
	match ability:
		"scream":
			_ability_scream()
		"toxic_explosion":
			# Only on death
			pass
		"enrage":
			_trigger_enrage()
		"leap_attack":
			_ability_leap()
		"acid_pool":
			_ability_acid_pool()
		"pack_howl":
			_ability_pack_howl()
		"call_reinforcements":
			_ability_call_reinforcements()
		"roar":
			_ability_boss_roar()
		"frenzy":
			_ability_frenzy()

func _ability_scream() -> void:
	special_cooldown = profile.get("scream_cooldown", 10.0)
	var radius: float = profile.get("scream_radius", 500.0)
	
	# Alert all zombies in radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self:
			continue
		if global_position.distance_to(enemy.global_position) <= radius:
			if enemy.has_method("alert_to_position"):
				enemy.alert_to_position(current_target.global_position if current_target else global_position)
	
	# Stun player briefly
	if is_instance_valid(current_target) and current_target.has_method("apply_stun"):
		current_target.apply_stun(0.5)

func _trigger_enrage() -> void:
	if enraged:
		return
	
	enraged = true
	move_speed *= 1.5
	attack_damage = int(attack_damage * 1.3)
	attack_cooldown *= 0.6
	
	# Visual indicator would go here

func _ability_leap() -> void:
	if not is_instance_valid(current_target):
		return
	
	special_cooldown = 5.0
	var leap_target := current_target.global_position
	
	# Quick movement to target
	global_position = global_position.lerp(leap_target, 0.8)
	
	# Area damage on landing
	for body in get_tree().get_nodes_in_group("players"):
		if global_position.distance_to(body.global_position) <= 60.0:
			if body.has_method("take_damage"):
				body.take_damage(attack_damage, self)

func _ability_acid_pool() -> void:
	special_cooldown = 8.0
	# Would spawn acid pool area that damages over time
	pass

func _ability_pack_howl() -> void:
	special_cooldown = 15.0
	
	# Summon pack members
	var pack_size: int = profile.get("pack_size", 3)
	for ally in nearby_allies:
		if ally.has_method("alert_to_position") and is_instance_valid(current_target):
			ally.alert_to_position(current_target.global_position)

func _ability_call_reinforcements() -> void:
	special_cooldown = 30.0
	called_for_help.emit(nearby_allies)
	# Game would spawn additional raiders

func _ability_boss_roar() -> void:
	special_cooldown = 20.0
	# Screen shake, fear effect on player
	if is_instance_valid(current_target) and current_target.has_method("apply_fear"):
		current_target.apply_fear(3.0)

func _ability_frenzy() -> void:
	special_cooldown = 15.0
	enraged = true
	combo_count = 0
	
	# Rapid attacks for duration
	attack_cooldown *= 0.3
	
	get_tree().create_timer(5.0).timeout.connect(func():
		attack_cooldown = profile.get("attack_cooldown", 1.0)
		enraged = false
	)

# ============================================================================
# DEFENSIVE ACTIONS
# ============================================================================

func _try_dodge() -> bool:
	if not profile.get("can_dodge", false):
		return false
	
	if dodge_cooldown > 0:
		return false
	
	var dodge_chance: float = profile.get("dodge_chance", 0.2)
	if randf() > dodge_chance:
		return false
	
	# Execute dodge
	dodge_cooldown = 2.0
	
	var dodge_dir := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	if is_instance_valid(current_target):
		# Dodge perpendicular to attack direction
		var to_target := (current_target.global_position - global_position).normalized()
		dodge_dir = to_target.rotated(PI / 2 * (1 if randf() > 0.5 else -1))
	
	navigation_agent.target_position = global_position + dodge_dir * 60.0
	_change_state(AIState.DODGE)
	
	return true

func _try_block() -> bool:
	if not profile.get("can_block", false):
		return false
	
	var block_chance: float = profile.get("block_chance", 0.3)
	return randf() <= block_chance

func _circle_strafe() -> void:
	if not is_instance_valid(current_target):
		return
	
	var to_target := current_target.global_position - global_position
	var perpendicular := to_target.rotated(PI / 2 * flank_direction).normalized()
	var strafe_pos := global_position + perpendicular * 30.0
	
	navigation_agent.target_position = strafe_pos
	
	# Occasionally switch direction
	if randf() < 0.02:
		flank_direction *= -1

func _find_cover_position() -> void:
	# Simplified cover finding - would need actual cover detection
	if is_instance_valid(current_target):
		var away_from_target := (global_position - current_target.global_position).normalized()
		cover_position = global_position + away_from_target * 50.0

# ============================================================================
# DAMAGE & DEATH
# ============================================================================

func take_damage(amount: int, attacker: Node = null) -> void:
	if current_state == AIState.DEAD:
		return
	
	# Check for block
	if _try_block():
		amount = int(amount * 0.4)
	
	# Apply armor
	var armor: float = profile.get("armor_rating", 0.0)
	amount = int(amount * (1.0 - armor))
	
	current_health -= amount
	damaged.emit(amount, attacker)
	
	# Add to threat table
	if attacker:
		if not threat_table.has(attacker):
			threat_table[attacker] = 0.0
		threat_table[attacker] += amount
		
		# Acquire target if not in combat
		if current_state in [AIState.IDLE, AIState.PATROL]:
			current_target = attacker
			last_known_position = attacker.global_position
			target_acquired.emit(attacker)
			_change_state(AIState.CHASE)
	
	# Try to dodge next attack
	if profile.get("can_dodge", false) and dodge_cooldown <= 0:
		_try_dodge()
	
	# Check for death
	if current_health <= 0:
		_die()

func apply_stun(duration: float) -> void:
	stun_timer = duration
	_change_state(AIState.STUNNED)

func _recover_from_stun() -> void:
	if current_target:
		_change_state(AIState.COMBAT)
	else:
		_change_state(AIState.IDLE)

func _die() -> void:
	_change_state(AIState.DEAD)
	
	# Explode if bloater
	if profile.get("explode_on_death", false):
		var radius: float = profile.get("explosion_radius", 80.0)
		var damage: int = profile.get("explosion_damage", 40)
		
		for body in get_tree().get_nodes_in_group("players"):
			if global_position.distance_to(body.global_position) <= radius:
				if body.has_method("take_damage"):
					body.take_damage(damage, self)
	
	died.emit()
	
	# Drop loot
	if has_node("/root/LootSystem"):
		get_node("/root/LootSystem").drop_loot(global_position, profile.get("name", "zombie"))
	
	queue_free()

# ============================================================================
# UTILITY
# ============================================================================

func _change_state(new_state: AIState) -> void:
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	state_changed.emit(_state_name(previous_state), _state_name(current_state))

func _state_name(state: AIState) -> String:
	match state:
		AIState.IDLE: return "idle"
		AIState.PATROL: return "patrol"
		AIState.INVESTIGATE: return "investigate"
		AIState.CHASE: return "chase"
		AIState.COMBAT: return "combat"
		AIState.ATTACK: return "attack"
		AIState.DODGE: return "dodge"
		AIState.FLANK: return "flank"
		AIState.RETREAT: return "retreat"
		AIState.STUNNED: return "stunned"
		AIState.DEAD: return "dead"
		_: return "unknown"

func _apply_movement(delta: float) -> void:
	if current_state in [AIState.ATTACK, AIState.STUNNED, AIState.DEAD]:
		return
	
	if navigation_agent.is_navigation_finished():
		return
	
	var next_pos := navigation_agent.get_next_path_position()
	velocity = (next_pos - global_position).normalized() * move_speed
	
	# Move
	global_position += velocity * delta

func _lose_target() -> void:
	current_target = null
	aggro_timer = 0.0
	target_lost.emit()
	_change_state(AIState.INVESTIGATE)
	wander_timer = 3.0  # Look around for 3 seconds

func alert_to_position(pos: Vector2) -> void:
	last_known_position = pos
	alerted.emit(pos)
	
	if current_state in [AIState.IDLE, AIState.PATROL]:
		_change_state(AIState.INVESTIGATE)
		aggro_timer = 5.0

func is_in_combat() -> bool:
	return current_state in [AIState.COMBAT, AIState.ATTACK, AIState.CHASE]

func _pack_attack_signal() -> void:
	if current_target and current_state == AIState.COMBAT and attack_timer <= 0:
		_start_attack()

# ============================================================================
# DETECTION
# ============================================================================

func _on_detection_body_entered(body: Node2D) -> void:
	if not body.is_in_group("players"):
		return
	
	# Line of sight check (simplified)
	if profile.get("uses_sound_detection", false):
		# Boss uses sound - always detects
		pass
	elif profile.get("low_profile", false):
		# Crawlers only detect at close range
		if global_position.distance_to(body.global_position) > detection_range * 0.5:
			return
	
	current_target = body
	last_known_position = body.global_position
	aggro_timer = profile.get("aggro_memory", 5.0)
	
	threat_table[body] = 10.0
	
	target_acquired.emit(body)
	_change_state(AIState.CHASE)

func _on_detection_body_exited(body: Node2D) -> void:
	if body == current_target:
		last_known_position = body.global_position
		# Don't immediately lose target, use aggro timer

# ============================================================================
# BOSS MECHANICS
# ============================================================================

func advance_boss_phase() -> void:
	if not profile.get("is_boss", false):
		return
	
	var max_phases: int = profile.get("phases", 3)
	if boss_phase >= max_phases:
		return
	
	boss_phase += 1
	
	# Each phase gets stronger
	move_speed *= 1.2
	attack_damage = int(attack_damage * 1.3)
	attack_cooldown *= 0.8
	
	# Heal slightly between phases
	current_health = min(max_health, current_health + int(max_health * 0.1))
	
	# Trigger roar
	_ability_boss_roar()
