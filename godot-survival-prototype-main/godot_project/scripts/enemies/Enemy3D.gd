extends CharacterBody3D
class_name Enemy3D
## 3D Enemy Controller for Godot Survival Prototype
## Supports AI behavior, combat, and model loading

signal damaged(amount: float, remaining: float, source: Node)
signal died(enemy: Enemy3D)
signal state_changed(new_state: State)

enum State { IDLE, WANDER, CHASE, ATTACK, HIT, DEAD }

# Movement
@export var move_speed := 3.0
@export var run_speed := 5.0
@export var rotation_speed := 8.0

# Detection
@export var detection_radius := 15.0
@export var attack_range := 2.0
@export var lose_interest_range := 25.0

# Combat
@export var damage := 15.0
@export var attack_speed := 1.4
@export var max_health := 100.0

# Wander behavior
@export var wander_interval := 2.0
@export var wander_radius := 8.0

# Model
@export var enemy_type := "zombie_walker"

# State
var state := State.IDLE
var current_health: float
var attack_cooldown := 0.0
var wander_timer := 0.0
var wander_target := Vector3.ZERO
var target: Node3D
var home_position := Vector3.ZERO

# References
@onready var mesh_pivot: Node3D = $MeshPivot
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Area3D = $Hurtbox
@onready var detection_area: Area3D = $DetectionArea

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	current_health = max_health
	home_position = global_position
	
	# Load enemy model
	_load_enemy_model()
	
	# Setup detection
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered_detection)
		detection_area.body_exited.connect(_on_body_exited_detection)
	
	add_to_group("enemies")
	add_to_group("enemy")
	
	# Start in wander state
	_enter_wander()


func _load_enemy_model() -> void:
	if not ModelManager.is_loaded():
		ModelManager.instance.models_loaded.connect(_on_models_loaded, CONNECT_ONE_SHOT)
		return
	
	var model := ModelManager.create_mesh_instance(enemy_type)
	if model:
		mesh_pivot.add_child(model)
		model.position = Vector3.ZERO
	else:
		# Fallback - try generic zombie
		model = ModelManager.create_mesh_instance("zombie_walker")
		if model:
			mesh_pivot.add_child(model)


func _on_models_loaded() -> void:
	_load_enemy_model()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	attack_cooldown = max(attack_cooldown - delta, 0.0)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	
	# State machine
	match state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HIT:
			_process_hit(delta)
	
	move_and_slide()


func _process_idle(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	
	wander_timer -= delta
	if wander_timer <= 0.0:
		_enter_wander()
	
	# Check for player in range
	if target and _can_see_target():
		_enter_chase()


func _process_wander(delta: float) -> void:
	wander_timer -= delta
	
	if wander_timer <= 0.0:
		_pick_wander_target()
		wander_timer = wander_interval + rng.randf_range(0.5, 1.5)
	
	# Move towards wander target
	var direction := (wander_target - global_position)
	direction.y = 0
	
	if direction.length() > 1.0:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		_rotate_towards(direction, delta)
	else:
		velocity.x = 0
		velocity.z = 0
	
	# Check for player
	if target and _can_see_target():
		_enter_chase()


func _process_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		_enter_wander()
		return
	
	var distance := global_position.distance_to(target.global_position)
	
	# Lost interest
	if distance > lose_interest_range:
		target = null
		_enter_wander()
		return
	
	# In attack range
	if distance <= attack_range:
		_enter_attack()
		return
	
	# Chase target
	var direction := (target.global_position - global_position)
	direction.y = 0
	direction = direction.normalized()
	
	velocity.x = direction.x * run_speed
	velocity.z = direction.z * run_speed
	_rotate_towards(direction, delta)


func _process_attack(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	
	if not target or not is_instance_valid(target):
		_enter_wander()
		return
	
	var distance := global_position.distance_to(target.global_position)
	
	# Face target
	var direction := (target.global_position - global_position)
	direction.y = 0
	if direction.length() > 0.1:
		_rotate_towards(direction.normalized(), delta)
	
	# Out of range
	if distance > attack_range * 1.5:
		_enter_chase()
		return
	
	# Attack
	if attack_cooldown <= 0.0:
		_perform_attack()


func _process_hit(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	# Hit stun handled by timer, will return to appropriate state


func _enter_idle() -> void:
	state = State.IDLE
	wander_timer = rng.randf_range(1.0, 3.0)
	velocity.x = 0
	velocity.z = 0
	state_changed.emit(state)


func _enter_wander() -> void:
	state = State.WANDER
	_pick_wander_target()
	wander_timer = wander_interval
	state_changed.emit(state)


func _enter_chase() -> void:
	state = State.CHASE
	state_changed.emit(state)


func _enter_attack() -> void:
	state = State.ATTACK
	velocity.x = 0
	velocity.z = 0
	state_changed.emit(state)


func _enter_hit() -> void:
	state = State.HIT
	velocity.x = 0
	velocity.z = 0
	state_changed.emit(state)
	
	# Return to appropriate state after stun
	await get_tree().create_timer(0.5).timeout
	if state == State.HIT and current_health > 0:
		if target:
			_enter_chase()
		else:
			_enter_wander()


func _enter_dead() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	state_changed.emit(state)
	died.emit(self)
	
	# Fade out and remove
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(queue_free)


func _pick_wander_target() -> void:
	var angle := rng.randf() * TAU
	var distance := rng.randf_range(2.0, wander_radius)
	wander_target = home_position + Vector3(
		cos(angle) * distance,
		0,
		sin(angle) * distance
	)


func _rotate_towards(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.1:
		return
	var target_angle := atan2(direction.x, direction.z)
	mesh_pivot.rotation.y = lerp_angle(mesh_pivot.rotation.y, target_angle, rotation_speed * delta)


func _can_see_target() -> bool:
	if not target or not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) <= detection_radius


func _perform_attack() -> void:
	attack_cooldown = attack_speed
	
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# Deal damage to target
	if target and target.has_method("take_damage"):
		var distance := global_position.distance_to(target.global_position)
		if distance <= attack_range * 1.2:
			target.take_damage(damage, self)


func take_damage(amount: float, source: Node = null) -> void:
	if state == State.DEAD:
		return
	
	current_health -= amount
	damaged.emit(amount, current_health, source)
	
	if current_health <= 0:
		_enter_dead()
	else:
		_enter_hit()
		# Aggro on attacker
		if source and source.is_in_group("player"):
			target = source


func assign_target(node: Node3D) -> void:
	target = node


func set_enemy_type(type: String) -> void:
	enemy_type = type
	# Reload model if already in scene
	if is_inside_tree():
		for child in mesh_pivot.get_children():
			child.queue_free()
		_load_enemy_model()


func _on_body_entered_detection(body: Node3D) -> void:
	if body.is_in_group("player") and not target:
		target = body
		if state in [State.IDLE, State.WANDER]:
			_enter_chase()


func _on_body_exited_detection(body: Node3D) -> void:
	if body == target:
		# Keep chasing for a bit, handled by lose_interest_range
		pass
