extends CharacterBody3D
class_name Player3D
## Player Controller - Isometric WASD movement, dodge, attack

@onready var animation_player = $MeshPivot/Pompier/AnimationPlayer

signal damaged(amount: float, remaining: float)
signal died()
signal attack_hit(targets: Array)

# Movement
const SPEED := 5.0
const SPRINT_SPEED := 8.0
const ROTATION_SPEED := 10.0
const GRAVITY := 20.0

# Dodge
const DODGE_DISTANCE := 3.0
const DODGE_DURATION := 0.3
const DODGE_COOLDOWN := 1.0

# Combat
const ATTACK_DAMAGE := 30.0
const ATTACK_RANGE := 1.5
const ATTACK_ARC := 90.0  # degrees
const ATTACK_COOLDOWN := 0.5

# Stats
const HEALTH_MAX := 100.0

# LDOE-style camera settings (behind and above player)
const CAMERA_OFFSET := Vector3(0, 8, 16)  # Directly behind, 8 up, 16 back (more zoomed out)
const CAMERA_SMOOTHING := 5.0

# Camera tilt (juice) - DISABLED
const CAMERA_TILT_AMOUNT := 0.0  # Max degrees (0 = disabled)
const CAMERA_TILT_SPEED := 5.0   # Lerp speed

# Combat FOV - DISABLED
const COMBAT_FOV := 35.0  # Same as normal (disabled)
const NORMAL_FOV := 35.0
const FOV_LERP_SPEED := 3.0

# Sprint camera - DISABLED
const SPRINT_OFFSET_BONUS := 0.0  # Extra distance when sprinting (0 = disabled)

# Edge look (scout mode) - DISABLED
const EDGE_LOOK_THRESHOLD := 0.15  # 15% from edge
const EDGE_LOOK_DISTANCE := 0.0    # Max pan distance (0 = disabled)

var health := HEALTH_MAX
var _last_move_direction := Vector3(0, 0, -1)  # Default facing up-screen
var _attack_timer := 0.0
var _dodge_timer := 0.0
var _dodge_cooldown_timer := 0.0
var _is_dodging := false
var _is_invincible := false
var _dodge_velocity := Vector3.ZERO

# Camera state
var _camera_tilt := Vector3.ZERO
var _target_fov := NORMAL_FOV
var _combat_check_timer := 0.0
var _is_sprinting := false
var _current_offset_z := 12.0
var _edge_look_offset := Vector3.ZERO
var _current_move_direction := Vector3.ZERO

# References
@onready var mesh_pivot: Node3D = $MeshPivot
@onready var camera: Camera3D = $IsometricCamera


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_to_group("player")
	
	# Create placeholder mesh if MeshPivot is empty
	if mesh_pivot.get_child_count() == 0:
		_create_placeholder_mesh()
	
	# Setup isometric camera
	_setup_camera()
	
	print("[Player3D] Ready - HP: ", health)


func _setup_camera() -> void:
	if camera:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = NORMAL_FOV
		camera.rotation_degrees = Vector3(-30, 0, 0)  # 30° down, looks straight at player's back
		camera.global_position = global_position + CAMERA_OFFSET
		camera.current = true


func _create_placeholder_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.6
	mesh_instance.mesh = capsule
	mesh_instance.position.y = 0.8
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.9)
	mesh_instance.material_override = material
	
	mesh_pivot.add_child(mesh_instance)


func _input(event: InputEvent) -> void:
	if health <= 0.0:
		return
	
	# Attack - Left mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_attempt_attack()
	
	# Dodge - Spacebar
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_attempt_dodge()
	
	# Interact - E key
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_attempt_interact()


func _process(delta: float) -> void:
	if not camera:
		return
	
	# Update dynamic camera features
	_check_combat_state(delta)
	_process_sprint(delta)
	_update_edge_look(delta)
	_update_camera_tilt(delta, _current_move_direction)
	
	# Calculate final camera position
	var base_offset := Vector3(CAMERA_OFFSET.x, CAMERA_OFFSET.y, _current_offset_z)
	var final_offset := base_offset + _edge_look_offset
	var target_pos := global_position + final_offset
	camera.global_position = camera.global_position.lerp(target_pos, CAMERA_SMOOTHING * delta)
	
	# Apply FOV
	camera.fov = lerp(camera.fov, _target_fov, FOV_LERP_SPEED * delta)


func _update_camera_tilt(delta: float, move_direction: Vector3) -> void:
	var target_tilt := Vector3.ZERO
	if move_direction.length() > 0.1:
		# Tilt forward/back based on Z movement
		target_tilt.x = move_direction.z * CAMERA_TILT_AMOUNT
		# Roll based on X movement
		target_tilt.z = -move_direction.x * CAMERA_TILT_AMOUNT
	
	_camera_tilt = _camera_tilt.lerp(target_tilt, CAMERA_TILT_SPEED * delta)
	
	# Apply base rotation + tilt
	var base_rotation := Vector3(-30, 0, 0)
	camera.rotation_degrees = base_rotation + _camera_tilt


func _check_combat_state(delta: float) -> void:
	_combat_check_timer -= delta
	if _combat_check_timer <= 0:
		_combat_check_timer = 0.5  # Check every 0.5 sec
		
		var enemies_nearby := false
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if global_position.distance_to(enemy.global_position) < 15.0:
				enemies_nearby = true
				break
		
		_target_fov = COMBAT_FOV if enemies_nearby else NORMAL_FOV


func _process_sprint(delta: float) -> void:
	_is_sprinting = Input.is_key_pressed(KEY_SHIFT) and velocity.length() > 0.5
	
	var target_z := CAMERA_OFFSET.z
	if _is_sprinting:
		target_z += SPRINT_OFFSET_BONUS
	
	_current_offset_z = lerp(_current_offset_z, target_z, 5.0 * delta)


func _update_edge_look(delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var mouse_pos := get_viewport().get_mouse_position()
	
	# Normalize mouse position to -1 to 1
	var normalized := Vector2(
		(mouse_pos.x / viewport_size.x) * 2.0 - 1.0,
		(mouse_pos.y / viewport_size.y) * 2.0 - 1.0
	)
	
	var target_offset := Vector3.ZERO
	
	# Check if near edges (beyond threshold)
	if abs(normalized.x) > (1.0 - EDGE_LOOK_THRESHOLD):
		var edge_factor: float = (abs(normalized.x) - (1.0 - EDGE_LOOK_THRESHOLD)) / EDGE_LOOK_THRESHOLD
		target_offset.x = sign(normalized.x) * edge_factor * EDGE_LOOK_DISTANCE
	
	if abs(normalized.y) > (1.0 - EDGE_LOOK_THRESHOLD):
		var edge_factor: float = (abs(normalized.y) - (1.0 - EDGE_LOOK_THRESHOLD)) / EDGE_LOOK_THRESHOLD
		target_offset.z = sign(normalized.y) * edge_factor * EDGE_LOOK_DISTANCE
	
	_edge_look_offset = _edge_look_offset.lerp(target_offset, 5.0 * delta)


func _physics_process(delta: float) -> void:
	if health <= 0.0:
		return
	
	_attack_timer = max(_attack_timer - delta, 0.0)
	_dodge_cooldown_timer = max(_dodge_cooldown_timer - delta, 0.0)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Dodging
	if _is_dodging:
		_process_dodge(delta)
	else:
		_process_movement(delta)
		
	#Animation de marche
	if Vector2(velocity.x, velocity.z).length() > 0.1 :
		if animation_player.current_animation != "Take 001":
			animation_player.play("Take 001")
	else:
		animation_player.stop()
	
	move_and_slide()


func _process_movement(delta: float) -> void:
	# LDOE-style movement - camera behind player, WASD matches screen directions
	# W = forward (away from camera) = -Z in world
	# S = backward (toward camera) = +Z in world
	# A = left = -X in world
	# D = right = +X in world
	var direction := Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("move_up"):
		direction.z -= 1  # Forward (up on screen)
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("move_down"):
		direction.z += 1  # Backward (down on screen)
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("move_left"):
		direction.x -= 1  # Left
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("move_right"):
		direction.x += 1  # Right
	
	direction = direction.normalized()
	_current_move_direction = direction  # Store for camera tilt
	
	if direction.length() > 0.1:
		_last_move_direction = direction
		
		# Apply sprint speed if sprinting
		var current_speed := SPRINT_SPEED if _is_sprinting else SPEED
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		# Rotate mesh to face movement direction
		var target_rotation := atan2(direction.x, direction.z)
		mesh_pivot.rotation.y = lerp_angle(mesh_pivot.rotation.y, target_rotation, ROTATION_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)


func _process_dodge(delta: float) -> void:
	_dodge_timer -= delta
	
	if _dodge_timer <= 0.0:
		_end_dodge()
		return
	
	velocity.x = _dodge_velocity.x
	velocity.z = _dodge_velocity.z


func _attempt_dodge() -> void:
	if _is_dodging or _dodge_cooldown_timer > 0.0:
		return
	
	_is_dodging = true
	_is_invincible = true
	_dodge_timer = DODGE_DURATION
	_dodge_cooldown_timer = DODGE_COOLDOWN
	
	# Dash in current move direction (or forward if stationary)
	var dodge_dir := _last_move_direction.normalized()
	if dodge_dir.length() < 0.1:
		dodge_dir = Vector3(0, 0, -1)  # Default: forward (up-screen)
	
	_dodge_velocity = dodge_dir * (DODGE_DISTANCE / DODGE_DURATION)
	
	# Visual feedback - tween scale
	var tween := create_tween()
	tween.tween_property(mesh_pivot, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property(mesh_pivot, "scale", Vector3(1, 1, 1), 0.2)
	
	print("[Player3D] Dodge!")


func _end_dodge() -> void:
	_is_dodging = false
	_is_invincible = false
	_dodge_velocity = Vector3.ZERO



const INTERACT_RANGE := 2.0

func _attempt_interact() -> void:
	"""Find and interact with the closest interactable in range."""
	var interactables := get_tree().get_nodes_in_group("interactable")
	var closest: Node = null
	var closest_dist := INTERACT_RANGE
	
	for interactable in interactables:
		if not is_instance_valid(interactable):
			continue
		
		var dist: float = global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = interactable
	
	if closest and closest.has_method("interact"):
		closest.interact(self)
		print("[Player3D] Interacted with ", closest.name)


func _attempt_attack() -> void:
	if _attack_timer > 0.0 or _is_dodging:
		return
	
	_attack_timer = ATTACK_COOLDOWN
	
	# Visual feedback - lunge forward
	var tween := create_tween()
	var original_pos := mesh_pivot.position
	tween.tween_property(mesh_pivot, "position", original_pos + _last_move_direction * 0.3, 0.1)
	tween.tween_property(mesh_pivot, "position", original_pos, 0.2)
	
	# Find enemies in attack arc
	var hit_targets := []
	var enemies := get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0
		var distance: float = to_enemy.length()
		
		if distance > ATTACK_RANGE:
			continue
		
		# Check if within arc
		var facing: Vector3 = _last_move_direction.normalized()
		var to_enemy_norm: Vector3 = to_enemy.normalized()
		var dot_product: float = facing.dot(to_enemy_norm)
		var angle: float = rad_to_deg(acos(clamp(dot_product, -1.0, 1.0)))
		
		if angle <= ATTACK_ARC / 2.0:
			hit_targets.append(enemy)
	
	# Deal damage to enemies
	for target in hit_targets:
		if target.has_method("take_damage"):
			target.take_damage(ATTACK_DAMAGE, self)
			print("[Player3D] Hit enemy for ", ATTACK_DAMAGE, " damage")
	
	# Also check harvestables in attack arc
	var harvestables := get_tree().get_nodes_in_group("harvestable")
	
	for harvestable in harvestables:
		if not is_instance_valid(harvestable):
			continue
		
		var to_target: Vector3 = harvestable.global_position - global_position
		to_target.y = 0
		var distance: float = to_target.length()
		
		if distance > ATTACK_RANGE:
			continue
		
		# Check if within arc
		var facing: Vector3 = _last_move_direction.normalized()
		var to_target_norm: Vector3 = to_target.normalized()
		var dot_product: float = facing.dot(to_target_norm)
		var angle: float = rad_to_deg(acos(clamp(dot_product, -1.0, 1.0)))
		
		if angle <= ATTACK_ARC / 2.0:
			if harvestable.has_method("take_damage"):
				harvestable.take_damage(ATTACK_DAMAGE)
				print("[Player3D] Hit harvestable for ", ATTACK_DAMAGE, " damage")
	
	attack_hit.emit(hit_targets)


func take_damage(amount: float, _source: Node = null) -> void:
	if health <= 0.0 or _is_invincible:
		return
	
	health = max(health - amount, 0.0)
	damaged.emit(amount, health)
	
	# Flash red
	_flash_damage()
	
	print("[Player3D] Took ", amount, " damage. HP: ", health)
	
	if health <= 0.0:
		_die()


func _flash_damage() -> void:
	for child in mesh_pivot.get_children():
		if child is MeshInstance3D:
			var mat := child.material_override as StandardMaterial3D
			if mat:
				var original_color := mat.albedo_color
				var tween := create_tween()
				tween.tween_property(mat, "albedo_color", Color.RED, 0.05)
				tween.tween_property(mat, "albedo_color", original_color, 0.15)


func heal(amount: float) -> void:
	health = min(health + amount, HEALTH_MAX)


func _die() -> void:
	died.emit()
	print("[Player3D] Died!")
	
	# Simple death animation
	var tween := create_tween()
	tween.tween_property(mesh_pivot, "rotation_degrees:x", -90, 0.5)
