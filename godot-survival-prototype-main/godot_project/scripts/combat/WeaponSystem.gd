extends Node

## WeaponSystem - Complete weapon combat with melee combos, ranged mechanics, and durability
## Designed to be superior to LDOE's basic combat

class_name WeaponSystem

# ============================================================================
# SIGNALS
# ============================================================================

signal weapon_equipped(weapon_data: Dictionary)
signal weapon_unequipped
signal attack_started(attack_type: String)
signal attack_hit(target: Node, damage: int)
signal combo_advanced(combo_step: int)
signal combo_reset
signal weapon_durability_changed(current: int, maximum: int)
signal weapon_broke(weapon_id: String)
signal ammo_changed(current: int, reserve: int)
signal reload_started(duration: float)
signal reload_finished

# ============================================================================
# CONSTANTS
# ============================================================================

const COMBO_WINDOW := 0.6  # Seconds to chain next attack
const COMBO_RESET_DELAY := 1.0  # Seconds before combo fully resets

# Attack types
enum AttackType { NONE, LIGHT, HEAVY, CHARGED, SPECIAL }

# Weapon categories with different behaviors
const WEAPON_CATEGORIES := {
	"unarmed": {
		"type": "melee",
		"combo_max": 3,
		"base_damage": 5,
		"attack_speed": 0.3,
		"range": 40.0,
		"stamina_cost": 5,
		"can_block": false
	},
	"one_handed": {
		"type": "melee",
		"combo_max": 4,
		"base_damage": 15,
		"attack_speed": 0.4,
		"range": 60.0,
		"stamina_cost": 8,
		"can_block": true
	},
	"two_handed": {
		"type": "melee",
		"combo_max": 3,
		"base_damage": 30,
		"attack_speed": 0.7,
		"range": 80.0,
		"stamina_cost": 15,
		"can_block": true,
		"can_charge": true
	},
	"pistol": {
		"type": "ranged",
		"fire_rate": 0.3,
		"base_damage": 20,
		"range": 400.0,
		"accuracy": 0.85,
		"reload_time": 1.5,
		"mag_size": 12
	},
	"rifle": {
		"type": "ranged",
		"fire_rate": 0.15,
		"base_damage": 35,
		"range": 600.0,
		"accuracy": 0.75,
		"reload_time": 2.5,
		"mag_size": 30,
		"auto_fire": true
	},
	"shotgun": {
		"type": "ranged",
		"fire_rate": 0.8,
		"base_damage": 12,
		"pellets": 8,
		"range": 200.0,
		"accuracy": 0.6,
		"spread": 15.0,
		"reload_time": 0.5,
		"reload_type": "single",
		"mag_size": 6
	},
	"bow": {
		"type": "ranged",
		"draw_time": 1.0,
		"base_damage": 25,
		"range": 350.0,
		"accuracy": 0.9,
		"projectile": true
	}
}

# ============================================================================
# STATE
# ============================================================================

var equipped_weapon: Dictionary = {}
var current_combo_step := 0
var combo_timer := 0.0
var is_attacking := false
var is_blocking := false
var is_charging := false
var charge_time := 0.0
var attack_cooldown := 0.0

# Ranged specific
var current_ammo := 0
var reserve_ammo := 0
var is_reloading := false
var reload_timer := 0.0
var is_aiming := false
var aim_accuracy_bonus := 0.0

# Durability
var current_durability := 0
var max_durability := 0

# References
var owner_node: Node2D = null
var hitbox: Area2D = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("weapon_system")

func _process(delta: float) -> void:
	_update_timers(delta)
	_update_charging(delta)
	_update_aiming(delta)

func initialize(owner: Node2D) -> void:
	owner_node = owner
	_create_hitbox()

func _create_hitbox() -> void:
	if hitbox:
		return
	
	hitbox = Area2D.new()
	hitbox.name = "WeaponHitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 6  # Enemies + Hurtboxes
	hitbox.monitoring = false
	
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(60, 40)
	shape.position = Vector2(40, 0)
	hitbox.add_child(shape)
	
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	if owner_node:
		owner_node.add_child(hitbox)

# ============================================================================
# TIMERS
# ============================================================================

func _update_timers(delta: float) -> void:
	# Attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Combo window
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0 and current_combo_step > 0:
			_reset_combo()
	
	# Reload
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			_finish_reload()

func _update_charging(delta: float) -> void:
	if not is_charging:
		return
	
	charge_time += delta
	# Visual feedback could be added here

func _update_aiming(delta: float) -> void:
	if is_aiming:
		aim_accuracy_bonus = min(aim_accuracy_bonus + delta * 0.5, 0.15)
	else:
		aim_accuracy_bonus = max(aim_accuracy_bonus - delta * 1.0, 0.0)

# ============================================================================
# WEAPON MANAGEMENT
# ============================================================================

func equip_weapon(weapon_data: Dictionary) -> void:
	if not weapon_data.is_empty():
		equipped_weapon = weapon_data.duplicate()
		
		var category: String = weapon_data.get("category", "one_handed")
		var cat_data: Dictionary = WEAPON_CATEGORIES.get(category, WEAPON_CATEGORIES["one_handed"])
		
		# Set durability
		max_durability = weapon_data.get("max_durability", 100)
		current_durability = weapon_data.get("durability", max_durability)
		
		# Set ammo for ranged
		if cat_data.get("type") == "ranged":
			current_ammo = weapon_data.get("current_ammo", cat_data.get("mag_size", 10))
			reserve_ammo = weapon_data.get("reserve_ammo", 0)
		
		# Update hitbox size based on range
		_update_hitbox_range(cat_data.get("range", 60.0))
		
		weapon_equipped.emit(equipped_weapon)
	else:
		unequip_weapon()

func unequip_weapon() -> void:
	equipped_weapon = {}
	current_combo_step = 0
	is_attacking = false
	is_blocking = false
	is_charging = false
	weapon_unequipped.emit()

func _update_hitbox_range(attack_range: float) -> void:
	if hitbox and hitbox.get_child_count() > 0:
		var shape: CollisionShape2D = hitbox.get_child(0)
		if shape and shape.shape is RectangleShape2D:
			shape.shape.size = Vector2(attack_range * 0.8, 40)
			shape.position = Vector2(attack_range * 0.4, 0)

# ============================================================================
# MELEE COMBAT
# ============================================================================

func attack_light() -> bool:
	if not _can_attack():
		return false
	
	var category := _get_weapon_category()
	if category.get("type") != "melee":
		return fire_weapon()
	
	_perform_melee_attack(AttackType.LIGHT)
	return true

func attack_heavy() -> bool:
	if not _can_attack():
		return false
	
	var category := _get_weapon_category()
	if category.get("type") != "melee":
		return false
	
	_perform_melee_attack(AttackType.HEAVY)
	return true

func start_charge() -> void:
	var category := _get_weapon_category()
	if not category.get("can_charge", false):
		return
	
	if not _can_attack():
		return
	
	is_charging = true
	charge_time = 0.0

func release_charge() -> void:
	if not is_charging:
		return
	
	is_charging = false
	
	if charge_time >= 1.0:
		_perform_melee_attack(AttackType.CHARGED)
	elif charge_time >= 0.3:
		_perform_melee_attack(AttackType.HEAVY)
	else:
		_perform_melee_attack(AttackType.LIGHT)
	
	charge_time = 0.0

func _perform_melee_attack(attack_type: AttackType) -> void:
	var category := _get_weapon_category()
	var combo_max: int = category.get("combo_max", 3)
	
	# Advance combo
	if combo_timer > 0 and current_combo_step < combo_max:
		current_combo_step += 1
		combo_advanced.emit(current_combo_step)
	else:
		current_combo_step = 1
	
	is_attacking = true
	
	# Calculate attack properties
	var base_speed: float = category.get("attack_speed", 0.4)
	var stamina_cost: int = category.get("stamina_cost", 10)
	
	# Modify based on attack type
	var speed_mult := 1.0
	var damage_mult := 1.0
	
	match attack_type:
		AttackType.LIGHT:
			speed_mult = 1.0
			damage_mult = 1.0
		AttackType.HEAVY:
			speed_mult = 1.5
			damage_mult = 1.5
			stamina_cost = int(stamina_cost * 1.5)
		AttackType.CHARGED:
			speed_mult = 2.0
			damage_mult = 2.5
			stamina_cost = int(stamina_cost * 2)
	
	# Combo damage scaling
	damage_mult *= 1.0 + (current_combo_step - 1) * 0.15
	
	# Apply stamina cost
	if owner_node and owner_node.has_method("use_stamina"):
		if not owner_node.use_stamina(stamina_cost):
			is_attacking = false
			return
	
	attack_cooldown = base_speed * speed_mult
	combo_timer = COMBO_WINDOW
	
	# Store damage multiplier for hit detection
	equipped_weapon["_current_damage_mult"] = damage_mult
	equipped_weapon["_current_attack_type"] = attack_type
	
	attack_started.emit(_attack_type_string(attack_type))
	
	# Enable hitbox briefly
	_activate_hitbox(base_speed * speed_mult * 0.5)
	
	# Reduce durability
	_reduce_durability(1)

func _activate_hitbox(duration: float) -> void:
	if not hitbox:
		return
	
	hitbox.monitoring = true
	
	# Deactivate after duration
	get_tree().create_timer(duration).timeout.connect(func():
		if hitbox:
			hitbox.monitoring = false
			is_attacking = false
	)

func _reset_combo() -> void:
	current_combo_step = 0
	combo_reset.emit()

func _attack_type_string(attack_type: AttackType) -> String:
	match attack_type:
		AttackType.LIGHT: return "light"
		AttackType.HEAVY: return "heavy"
		AttackType.CHARGED: return "charged"
		AttackType.SPECIAL: return "special"
		_: return "none"

# ============================================================================
# BLOCKING
# ============================================================================

func start_block() -> void:
	var category := _get_weapon_category()
	if not category.get("can_block", false):
		return
	
	is_blocking = true

func stop_block() -> void:
	is_blocking = false

func is_blocking_attack() -> bool:
	return is_blocking

func calculate_blocked_damage(incoming_damage: int) -> int:
	if not is_blocking:
		return incoming_damage
	
	# Block reduces damage by 60-80% based on weapon
	var block_efficiency := 0.7
	var blocked := int(incoming_damage * block_efficiency)
	
	# Blocking costs stamina
	if owner_node and owner_node.has_method("use_stamina"):
		owner_node.use_stamina(blocked / 2)
	
	# Reduce durability when blocking
	_reduce_durability(1)
	
	return incoming_damage - blocked

# ============================================================================
# RANGED COMBAT
# ============================================================================

func fire_weapon() -> bool:
	var category := _get_weapon_category()
	if category.get("type") != "ranged":
		return false
	
	if not _can_attack():
		return false
	
	if current_ammo <= 0:
		start_reload()
		return false
	
	if is_reloading:
		return false
	
	# Consume ammo
	current_ammo -= 1
	ammo_changed.emit(current_ammo, reserve_ammo)
	
	# Set cooldown
	attack_cooldown = category.get("fire_rate", 0.3)
	
	# Calculate accuracy
	var base_accuracy: float = category.get("accuracy", 0.8)
	var final_accuracy := base_accuracy + aim_accuracy_bonus
	
	# Calculate damage
	var base_damage: int = category.get("base_damage", 20)
	var weapon_bonus: int = equipped_weapon.get("damage_bonus", 0)
	var total_damage := base_damage + weapon_bonus
	
	# Handle pellets for shotguns
	var pellets: int = category.get("pellets", 1)
	var spread: float = category.get("spread", 0.0)
	
	if category.get("projectile", false):
		# Bow - spawn arrow projectile
		_spawn_projectile(total_damage, category.get("range", 300.0))
	else:
		# Hitscan weapons
		for i in range(pellets):
			var pellet_spread := 0.0
			if pellets > 1:
				pellet_spread = randf_range(-spread, spread)
			_perform_hitscan(total_damage / pellets, final_accuracy, category.get("range", 400.0), pellet_spread)
	
	attack_started.emit("fire")
	
	# Reduce durability
	_reduce_durability(1)
	
	# Auto-fire check
	if category.get("auto_fire", false) and Input.is_action_pressed("attack"):
		# Will continue firing on next frame via attack_cooldown
		pass
	
	return true

func _perform_hitscan(damage: int, accuracy: float, max_range: float, spread_angle: float) -> void:
	if not owner_node:
		return
	
	var direction := Vector2.RIGHT.rotated(owner_node.rotation)
	
	# Apply spread
	if spread_angle != 0:
		direction = direction.rotated(deg_to_rad(spread_angle))
	
	# Apply accuracy (random deviation)
	var accuracy_deviation := (1.0 - accuracy) * 10.0
	direction = direction.rotated(deg_to_rad(randf_range(-accuracy_deviation, accuracy_deviation)))
	
	# Raycast
	var space := owner_node.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		owner_node.global_position,
		owner_node.global_position + direction * max_range,
		6  # Enemies + Hurtboxes
	)
	query.exclude = [owner_node]
	
	var result := space.intersect_ray(query)
	if result:
		var hit_target: Node = result.collider
		if hit_target.has_method("take_damage"):
			hit_target.take_damage(damage, owner_node)
			attack_hit.emit(hit_target, damage)

func _spawn_projectile(damage: int, max_range: float) -> void:
	# Projectile spawning would be handled by a separate ProjectileManager
	# For now, emit signal for external handling
	pass

func start_aim() -> void:
	is_aiming = true

func stop_aim() -> void:
	is_aiming = false

func start_reload() -> void:
	var category := _get_weapon_category()
	if category.get("type") != "ranged":
		return
	
	if is_reloading:
		return
	
	if reserve_ammo <= 0:
		return
	
	var mag_size: int = category.get("mag_size", 10)
	if current_ammo >= mag_size:
		return
	
	is_reloading = true
	reload_timer = category.get("reload_time", 2.0)
	
	reload_started.emit(reload_timer)

func _finish_reload() -> void:
	var category := _get_weapon_category()
	var mag_size: int = category.get("mag_size", 10)
	var reload_type: String = category.get("reload_type", "magazine")
	
	if reload_type == "single":
		# Shotgun-style reload one shell at a time
		if reserve_ammo > 0 and current_ammo < mag_size:
			current_ammo += 1
			reserve_ammo -= 1
			
			# Continue reloading if not full and has ammo
			if reserve_ammo > 0 and current_ammo < mag_size:
				reload_timer = category.get("reload_time", 0.5)
				return
	else:
		# Magazine reload
		var needed := mag_size - current_ammo
		var loaded := min(needed, reserve_ammo)
		current_ammo += loaded
		reserve_ammo -= loaded
	
	is_reloading = false
	ammo_changed.emit(current_ammo, reserve_ammo)
	reload_finished.emit()

func add_ammo(amount: int) -> void:
	reserve_ammo += amount
	ammo_changed.emit(current_ammo, reserve_ammo)

# ============================================================================
# DURABILITY
# ============================================================================

func _reduce_durability(amount: int) -> void:
	if max_durability <= 0:
		return
	
	current_durability = max(0, current_durability - amount)
	weapon_durability_changed.emit(current_durability, max_durability)
	
	if current_durability <= 0:
		_break_weapon()

func _break_weapon() -> void:
	var weapon_id: String = equipped_weapon.get("id", "")
	weapon_broke.emit(weapon_id)
	unequip_weapon()

func repair_weapon(amount: int) -> void:
	current_durability = min(max_durability, current_durability + amount)
	weapon_durability_changed.emit(current_durability, max_durability)

func get_durability_percent() -> float:
	if max_durability <= 0:
		return 1.0
	return float(current_durability) / float(max_durability)

# ============================================================================
# HIT DETECTION
# ============================================================================

func _on_hitbox_area_entered(area: Area2D) -> void:
	_process_hit(area.get_parent())

func _on_hitbox_body_entered(body: Node2D) -> void:
	_process_hit(body)

func _process_hit(target: Node) -> void:
	if target == owner_node:
		return
	
	if not target.has_method("take_damage"):
		return
	
	# Calculate damage
	var category := _get_weapon_category()
	var base_damage: int = category.get("base_damage", 10)
	var weapon_bonus: int = equipped_weapon.get("damage_bonus", 0)
	var damage_mult: float = equipped_weapon.get("_current_damage_mult", 1.0)
	
	var total_damage := int((base_damage + weapon_bonus) * damage_mult)
	
	# Critical hit chance
	var crit_chance := equipped_weapon.get("crit_chance", 0.05)
	if randf() < crit_chance:
		total_damage = int(total_damage * 1.5)
	
	target.take_damage(total_damage, owner_node)
	attack_hit.emit(target, total_damage)

# ============================================================================
# HELPERS
# ============================================================================

func _can_attack() -> bool:
	if attack_cooldown > 0:
		return false
	if is_reloading:
		return false
	if equipped_weapon.is_empty():
		# Allow unarmed attacks
		pass
	return true

func _get_weapon_category() -> Dictionary:
	var category_name: String = equipped_weapon.get("category", "unarmed")
	return WEAPON_CATEGORIES.get(category_name, WEAPON_CATEGORIES["unarmed"])

func get_equipped_weapon() -> Dictionary:
	return equipped_weapon

func has_weapon_equipped() -> bool:
	return not equipped_weapon.is_empty()

func get_current_ammo() -> int:
	return current_ammo

func get_reserve_ammo() -> int:
	return reserve_ammo
