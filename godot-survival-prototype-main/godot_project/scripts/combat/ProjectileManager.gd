extends Node

## ProjectileManager - Handles all projectiles (bullets, arrows, acid, grenades)
## Object pooling for performance, various projectile behaviors

# ============================================================================
# SIGNALS
# ============================================================================

signal projectile_fired(projectile: Node, shooter: Node)
signal projectile_hit(projectile: Node, target: Node, damage: int)
signal projectile_expired(projectile: Node)

# ============================================================================
# CONSTANTS
# ============================================================================

enum ProjectileType {
	BULLET,
	ARROW,
	BOLT,
	ACID_SPIT,
	GRENADE,
	MOLOTOV,
	ROCKET,
	THROWABLE
}

const PROJECTILE_CONFIGS := {
	ProjectileType.BULLET: {
		"name": "Bullet",
		"speed": 800.0,
		"gravity": 0.0,
		"lifetime": 2.0,
		"pierce": 0,
		"size": Vector2(4, 2),
		"trail": false,
		"hitscan": true,
		"collision_mask": 6  # Enemies + Environment
	},
	ProjectileType.ARROW: {
		"name": "Arrow",
		"speed": 500.0,
		"gravity": 200.0,
		"lifetime": 5.0,
		"pierce": 1,
		"size": Vector2(20, 3),
		"trail": false,
		"hitscan": false,
		"collision_mask": 6,
		"stick_on_hit": true
	},
	ProjectileType.BOLT: {
		"name": "Crossbow Bolt",
		"speed": 600.0,
		"gravity": 100.0,
		"lifetime": 4.0,
		"pierce": 2,
		"size": Vector2(16, 3),
		"trail": false,
		"hitscan": false,
		"collision_mask": 6,
		"stick_on_hit": true
	},
	ProjectileType.ACID_SPIT: {
		"name": "Acid Spit",
		"speed": 300.0,
		"gravity": 150.0,
		"lifetime": 3.0,
		"pierce": 0,
		"size": Vector2(12, 12),
		"trail": true,
		"trail_color": Color(0.2, 0.8, 0.2, 0.7),
		"hitscan": false,
		"collision_mask": 1,  # Player
		"create_pool_on_hit": true,
		"pool_damage": 5,
		"pool_duration": 5.0
	},
	ProjectileType.GRENADE: {
		"name": "Grenade",
		"speed": 350.0,
		"gravity": 400.0,
		"lifetime": 3.0,
		"pierce": 0,
		"size": Vector2(10, 10),
		"trail": false,
		"hitscan": false,
		"collision_mask": 7,
		"explode_on_timer": true,
		"fuse_time": 2.5,
		"explosion_radius": 100.0,
		"explosion_damage": 50
	},
	ProjectileType.MOLOTOV: {
		"name": "Molotov",
		"speed": 300.0,
		"gravity": 450.0,
		"lifetime": 5.0,
		"pierce": 0,
		"size": Vector2(12, 16),
		"trail": false,
		"hitscan": false,
		"collision_mask": 7,
		"explode_on_impact": true,
		"create_fire_on_hit": true,
		"fire_radius": 60.0,
		"fire_duration": 8.0,
		"fire_damage": 8
	},
	ProjectileType.ROCKET: {
		"name": "Rocket",
		"speed": 500.0,
		"gravity": 0.0,
		"lifetime": 4.0,
		"pierce": 0,
		"size": Vector2(24, 8),
		"trail": true,
		"trail_color": Color(1.0, 0.5, 0.2, 0.8),
		"hitscan": false,
		"collision_mask": 6,
		"explode_on_impact": true,
		"explosion_radius": 120.0,
		"explosion_damage": 80
	},
	ProjectileType.THROWABLE: {
		"name": "Thrown Object",
		"speed": 400.0,
		"gravity": 300.0,
		"lifetime": 3.0,
		"pierce": 0,
		"size": Vector2(8, 8),
		"trail": false,
		"hitscan": false,
		"collision_mask": 6
	}
}

# Object pool sizes
const POOL_SIZE := {
	ProjectileType.BULLET: 50,
	ProjectileType.ARROW: 20,
	ProjectileType.BOLT: 15,
	ProjectileType.ACID_SPIT: 10,
	ProjectileType.GRENADE: 5,
	ProjectileType.MOLOTOV: 5,
	ProjectileType.ROCKET: 3,
	ProjectileType.THROWABLE: 10
}

# ============================================================================
# STATE
# ============================================================================

var projectile_pools: Dictionary = {}  # ProjectileType -> Array[Projectile]
var active_projectiles: Array = []
var hazard_zones: Array = []  # Acid pools, fire zones, etc.

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("projectile_manager")
	_initialize_pools()

func _initialize_pools() -> void:
	for proj_type in ProjectileType.values():
		var pool_size: int = POOL_SIZE.get(proj_type, 10)
		projectile_pools[proj_type] = []
		
		for i in range(pool_size):
			var projectile := _create_projectile_node(proj_type)
			projectile.set_process(false)
			projectile.visible = false
			projectile_pools[proj_type].append(projectile)
			add_child(projectile)

func _create_projectile_node(proj_type: ProjectileType) -> Node2D:
	var projectile := Area2D.new()
	projectile.name = "Projectile_%d" % proj_type
	projectile.collision_layer = 0
	
	var config: Dictionary = PROJECTILE_CONFIGS.get(proj_type, {})
	projectile.collision_mask = config.get("collision_mask", 6)
	
	# Add collision shape
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = config.get("size", Vector2(8, 4))
	collision.shape = shape
	projectile.add_child(collision)
	
	# Add sprite
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	# Would load actual texture based on type
	projectile.add_child(sprite)
	
	# Add metadata
	projectile.set_meta("type", proj_type)
	projectile.set_meta("config", config)
	projectile.set_meta("active", false)
	
	# Connect signals
	projectile.body_entered.connect(_on_projectile_body_entered.bind(projectile))
	projectile.area_entered.connect(_on_projectile_area_entered.bind(projectile))
	
	return projectile

# ============================================================================
# PROCESS
# ============================================================================

func _physics_process(delta: float) -> void:
	_update_projectiles(delta)
	_update_hazard_zones(delta)

func _update_projectiles(delta: float) -> void:
	var to_deactivate: Array = []
	
	for projectile in active_projectiles:
		if not is_instance_valid(projectile):
			to_deactivate.append(projectile)
			continue
		
		var config: Dictionary = projectile.get_meta("config")
		var velocity: Vector2 = projectile.get_meta("velocity")
		var lifetime: float = projectile.get_meta("lifetime")
		
		# Apply gravity
		var gravity: float = config.get("gravity", 0.0)
		velocity.y += gravity * delta
		projectile.set_meta("velocity", velocity)
		
		# Move projectile
		projectile.global_position += velocity * delta
		
		# Rotate to face direction
		if velocity.length() > 0:
			projectile.rotation = velocity.angle()
		
		# Update lifetime
		lifetime -= delta
		projectile.set_meta("lifetime", lifetime)
		
		if lifetime <= 0:
			to_deactivate.append(projectile)
			continue
		
		# Check fuse timer for grenades
		if config.get("explode_on_timer", false):
			var fuse: float = projectile.get_meta("fuse_time") - delta
			projectile.set_meta("fuse_time", fuse)
			if fuse <= 0:
				_trigger_explosion(projectile)
				to_deactivate.append(projectile)
	
	for projectile in to_deactivate:
		_deactivate_projectile(projectile)

func _update_hazard_zones(delta: float) -> void:
	var to_remove: Array = []
	
	for hazard in hazard_zones:
		if not is_instance_valid(hazard):
			to_remove.append(hazard)
			continue
		
		var duration: float = hazard.get_meta("duration") - delta
		hazard.set_meta("duration", duration)
		
		if duration <= 0:
			to_remove.append(hazard)
			hazard.queue_free()
			continue
		
		# Damage tick
		var tick_timer: float = hazard.get_meta("tick_timer") - delta
		if tick_timer <= 0:
			tick_timer = 0.5  # Damage every 0.5 seconds
			_apply_hazard_damage(hazard)
		hazard.set_meta("tick_timer", tick_timer)
	
	for hazard in to_remove:
		hazard_zones.erase(hazard)

# ============================================================================
# FIRING
# ============================================================================

func fire_projectile(
	proj_type: ProjectileType,
	start_pos: Vector2,
	direction: Vector2,
	shooter: Node,
	damage: int,
	accuracy: float = 1.0
) -> Node2D:
	var projectile := _get_from_pool(proj_type)
	if not projectile:
		return null
	
	var config: Dictionary = PROJECTILE_CONFIGS.get(proj_type, {})
	
	# Apply accuracy deviation
	if accuracy < 1.0:
		var deviation := (1.0 - accuracy) * 15.0  # Up to 15 degrees at 0% accuracy
		direction = direction.rotated(deg_to_rad(randf_range(-deviation, deviation)))
	
	# Setup projectile
	projectile.global_position = start_pos
	projectile.rotation = direction.angle()
	projectile.visible = true
	projectile.set_process(true)
	projectile.monitoring = true
	
	var speed: float = config.get("speed", 500.0)
	var lifetime: float = config.get("lifetime", 2.0)
	
	projectile.set_meta("active", true)
	projectile.set_meta("velocity", direction.normalized() * speed)
	projectile.set_meta("lifetime", lifetime)
	projectile.set_meta("damage", damage)
	projectile.set_meta("shooter", shooter)
	projectile.set_meta("pierce_remaining", config.get("pierce", 0))
	projectile.set_meta("hit_targets", [])
	
	if config.get("explode_on_timer", false):
		projectile.set_meta("fuse_time", config.get("fuse_time", 2.5))
	
	active_projectiles.append(projectile)
	projectile_fired.emit(projectile, shooter)
	
	# Hitscan weapons do instant raycast
	if config.get("hitscan", false):
		_perform_hitscan(projectile, start_pos, direction, damage, shooter)
		_deactivate_projectile(projectile)
		return null
	
	return projectile

func fire_bullet(start_pos: Vector2, direction: Vector2, shooter: Node, damage: int, accuracy: float = 0.9) -> void:
	fire_projectile(ProjectileType.BULLET, start_pos, direction, shooter, damage, accuracy)

func fire_arrow(start_pos: Vector2, direction: Vector2, shooter: Node, damage: int) -> Node2D:
	return fire_projectile(ProjectileType.ARROW, start_pos, direction, shooter, damage, 1.0)

func fire_acid(start_pos: Vector2, direction: Vector2, shooter: Node, damage: int) -> Node2D:
	return fire_projectile(ProjectileType.ACID_SPIT, start_pos, direction, shooter, damage, 0.9)

func throw_grenade(start_pos: Vector2, direction: Vector2, shooter: Node, damage: int) -> Node2D:
	return fire_projectile(ProjectileType.GRENADE, start_pos, direction, shooter, damage, 1.0)

func throw_molotov(start_pos: Vector2, direction: Vector2, shooter: Node, damage: int) -> Node2D:
	return fire_projectile(ProjectileType.MOLOTOV, start_pos, direction, shooter, damage, 1.0)

# ============================================================================
# COLLISION HANDLING
# ============================================================================

func _on_projectile_body_entered(body: Node2D, projectile: Area2D) -> void:
	_handle_projectile_hit(projectile, body)

func _on_projectile_area_entered(area: Area2D, projectile: Area2D) -> void:
	# Check if it's a hurtbox
	if area.is_in_group("hurtbox"):
		var target := area.get_parent()
		_handle_projectile_hit(projectile, target)

func _handle_projectile_hit(projectile: Area2D, target: Node) -> void:
	if not projectile.get_meta("active"):
		return
	
	var shooter: Node = projectile.get_meta("shooter")
	if target == shooter:
		return  # Don't hit self
	
	var hit_targets: Array = projectile.get_meta("hit_targets")
	if target in hit_targets:
		return  # Already hit this target
	
	var config: Dictionary = projectile.get_meta("config")
	var damage: int = projectile.get_meta("damage")
	
	# Apply damage
	if target.has_method("take_damage"):
		target.take_damage(damage, shooter)
		projectile_hit.emit(projectile, target, damage)
	
	hit_targets.append(target)
	projectile.set_meta("hit_targets", hit_targets)
	
	# Check piercing
	var pierce_remaining: int = projectile.get_meta("pierce_remaining")
	if pierce_remaining > 0:
		projectile.set_meta("pierce_remaining", pierce_remaining - 1)
		return  # Continue through
	
	# Handle special on-hit effects
	if config.get("explode_on_impact", false):
		_trigger_explosion(projectile)
	
	if config.get("create_pool_on_hit", false):
		_create_acid_pool(projectile.global_position, config)
	
	if config.get("create_fire_on_hit", false):
		_create_fire_zone(projectile.global_position, config)
	
	if config.get("stick_on_hit", false):
		_stick_projectile(projectile, target)
	else:
		_deactivate_projectile(projectile)

# ============================================================================
# SPECIAL EFFECTS
# ============================================================================

func _trigger_explosion(projectile: Area2D) -> void:
	var config: Dictionary = projectile.get_meta("config")
	var position := projectile.global_position
	var radius: float = config.get("explosion_radius", 100.0)
	var damage: int = config.get("explosion_damage", 50)
	var shooter: Node = projectile.get_meta("shooter")
	
	# Find all targets in radius
	var space := get_tree().root.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	query.shape = circle
	query.transform = Transform2D(0, position)
	query.collision_mask = config.get("collision_mask", 6)
	
	var results := space.intersect_shape(query)
	
	for result in results:
		var target: Node = result.collider
		if target == shooter:
			continue
		
		# Damage falloff based on distance
		var dist := position.distance_to(target.global_position)
		var falloff := 1.0 - (dist / radius)
		var final_damage := int(damage * falloff)
		
		if target.has_method("take_damage") and final_damage > 0:
			target.take_damage(final_damage, shooter)
	
	# Spawn explosion effect
	_spawn_explosion_effect(position, radius)

func _create_acid_pool(position: Vector2, config: Dictionary) -> void:
	var pool := Area2D.new()
	pool.name = "AcidPool"
	pool.collision_layer = 0
	pool.collision_mask = 1  # Player
	
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	pool.add_child(shape)
	
	pool.global_position = position
	pool.set_meta("damage", config.get("pool_damage", 5))
	pool.set_meta("duration", config.get("pool_duration", 5.0))
	pool.set_meta("tick_timer", 0.0)
	pool.set_meta("type", "acid")
	
	get_tree().current_scene.add_child(pool)
	hazard_zones.append(pool)

func _create_fire_zone(position: Vector2, config: Dictionary) -> void:
	var fire := Area2D.new()
	fire.name = "FireZone"
	fire.collision_layer = 0
	fire.collision_mask = 7  # Player + Enemies
	
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = config.get("fire_radius", 60.0)
	shape.shape = circle
	fire.add_child(shape)
	
	fire.global_position = position
	fire.set_meta("damage", config.get("fire_damage", 8))
	fire.set_meta("duration", config.get("fire_duration", 8.0))
	fire.set_meta("tick_timer", 0.0)
	fire.set_meta("type", "fire")
	
	get_tree().current_scene.add_child(fire)
	hazard_zones.append(fire)

func _apply_hazard_damage(hazard: Area2D) -> void:
	var damage: int = hazard.get_meta("damage")
	var hazard_type: String = hazard.get_meta("type")
	
	for body in hazard.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage, null)
		
		# Apply status effects
		if hazard_type == "fire" and body.has_method("apply_status_effect"):
			body.apply_status_effect("burning", {"duration": 3.0, "health_drain": 2})
		elif hazard_type == "acid" and body.has_method("apply_status_effect"):
			body.apply_status_effect("acid_burn", {"duration": 2.0, "health_drain": 3})

func _stick_projectile(projectile: Area2D, target: Node) -> void:
	# Stick arrow/bolt to target or environment
	projectile.set_meta("active", false)
	projectile.monitoring = false
	active_projectiles.erase(projectile)
	
	if target is Node2D:
		# Parent to target so it moves with them
		var local_pos := target.to_local(projectile.global_position)
		projectile.get_parent().remove_child(projectile)
		target.add_child(projectile)
		projectile.position = local_pos
	
	# Queue for cleanup after delay
	get_tree().create_timer(10.0).timeout.connect(func():
		if is_instance_valid(projectile):
			_return_to_pool(projectile)
	)

func _spawn_explosion_effect(position: Vector2, radius: float) -> void:
	# Would spawn particle effect
	# For now, create simple visual
	var effect := Sprite2D.new()
	effect.global_position = position
	effect.modulate = Color(1, 0.5, 0, 0.8)
	effect.scale = Vector2(radius / 50, radius / 50)
	get_tree().current_scene.add_child(effect)
	
	# Fade out
	var tween := create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

# ============================================================================
# HITSCAN
# ============================================================================

func _perform_hitscan(projectile: Area2D, start: Vector2, direction: Vector2, damage: int, shooter: Node) -> void:
	var config: Dictionary = projectile.get_meta("config")
	var max_range := 1000.0
	
	var space := get_tree().root.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		start,
		start + direction.normalized() * max_range,
		config.get("collision_mask", 6)
	)
	
	if shooter is PhysicsBody2D:
		query.exclude = [shooter]
	
	var result := space.intersect_ray(query)
	
	if result:
		var target: Node = result.collider
		if target.has_method("take_damage"):
			target.take_damage(damage, shooter)
			projectile_hit.emit(projectile, target, damage)
		
		# Spawn hit effect at impact point
		_spawn_hit_effect(result.position)

func _spawn_hit_effect(position: Vector2) -> void:
	# Would spawn bullet impact particle
	pass

# ============================================================================
# OBJECT POOLING
# ============================================================================

func _get_from_pool(proj_type: ProjectileType) -> Area2D:
	var pool: Array = projectile_pools.get(proj_type, [])
	
	for projectile in pool:
		if not projectile.get_meta("active"):
			return projectile
	
	# Pool exhausted, create new one
	var new_proj := _create_projectile_node(proj_type)
	add_child(new_proj)
	pool.append(new_proj)
	return new_proj

func _return_to_pool(projectile: Area2D) -> void:
	projectile.set_meta("active", false)
	projectile.visible = false
	projectile.set_process(false)
	projectile.monitoring = false
	
	# Reset position
	if projectile.get_parent() != self:
		projectile.get_parent().remove_child(projectile)
		add_child(projectile)
	
	projectile.global_position = Vector2(-9999, -9999)

func _deactivate_projectile(projectile: Area2D) -> void:
	if projectile in active_projectiles:
		active_projectiles.erase(projectile)
	
	projectile_expired.emit(projectile)
	_return_to_pool(projectile)

# ============================================================================
# UTILITY
# ============================================================================

func clear_all_projectiles() -> void:
	for projectile in active_projectiles:
		_return_to_pool(projectile)
	active_projectiles.clear()
	
	for hazard in hazard_zones:
		if is_instance_valid(hazard):
			hazard.queue_free()
	hazard_zones.clear()

func get_active_projectile_count() -> int:
	return active_projectiles.size()
