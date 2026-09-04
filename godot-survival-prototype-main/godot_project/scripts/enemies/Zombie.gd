extends CharacterBody3D
class_name Zombie
## Simple Zombie enemy - chase player, attack, drop loot on death

signal died(zombie: Zombie)
signal damaged(amount: float, remaining: float)

enum State { IDLE, CHASE, ATTACK, HIT, DEAD }

# Stats
const MAX_HEALTH := 50.0
const MOVE_SPEED := 2.5
const DETECTION_RANGE := 8.0
const ATTACK_RANGE := 1.5
const ATTACK_DAMAGE := 10.0
const ATTACK_COOLDOWN := 1.0
const KNOCKBACK_FORCE := 2.0

var health := MAX_HEALTH
var state := State.IDLE
var _attack_timer := 0.0
var _target: Node3D = null

@onready var mesh_pivot: Node3D = $MeshPivot


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemies")
	
	# Create placeholder mesh
	_create_placeholder_mesh()
	
	print("[Zombie] Spawned at ", global_position)


func _create_placeholder_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	mesh_instance.mesh = capsule
	mesh_instance.position.y = 0.8
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.6, 0.3)  # Zombie green
	mesh_instance.material_override = material
	mesh_instance.name = "ZombieMesh"
	
	mesh_pivot.add_child(mesh_instance)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	_attack_timer = max(_attack_timer - delta, 0.0)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	
	# Find player if no target
	if not _target or not is_instance_valid(_target):
		_find_player()
	
	# State machine
	match state:
		State.IDLE:
			_process_idle(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HIT:
			pass  # Wait for hit stun to end
	
	move_and_slide()


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0]


func _process_idle(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	
	if _target and is_instance_valid(_target):
		var distance := global_position.distance_to(_target.global_position)
		if distance <= DETECTION_RANGE:
			state = State.CHASE
			print("[Zombie] Player detected!")


func _process_chase(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		state = State.IDLE
		return
	
	var distance := global_position.distance_to(_target.global_position)
	
	# Lost player
	if distance > DETECTION_RANGE * 2:
		state = State.IDLE
		_target = null
		return
	
	# In attack range
	if distance <= ATTACK_RANGE:
		state = State.ATTACK
		return
	
	# Chase
	var direction := (_target.global_position - global_position)
	direction.y = 0
	direction = direction.normalized()
	
	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED
	
	# Face movement direction
	if direction.length() > 0.1:
		var target_rotation := atan2(direction.x, direction.z)
		mesh_pivot.rotation.y = lerp_angle(mesh_pivot.rotation.y, target_rotation, 8.0 * delta)


func _process_attack(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	
	if not _target or not is_instance_valid(_target):
		state = State.IDLE
		return
	
	var distance := global_position.distance_to(_target.global_position)
	
	# Out of range, chase again
	if distance > ATTACK_RANGE * 1.5:
		state = State.CHASE
		return
	
	# Attack
	if _attack_timer <= 0.0:
		_perform_attack()


func _perform_attack() -> void:
	_attack_timer = ATTACK_COOLDOWN
	
	# Visual feedback
	var tween := create_tween()
	var original_pos := mesh_pivot.position
	var attack_dir := (_target.global_position - global_position).normalized()
	tween.tween_property(mesh_pivot, "position", original_pos + attack_dir * 0.3, 0.1)
	tween.tween_property(mesh_pivot, "position", original_pos, 0.2)
	
	# Deal damage
	if _target and _target.has_method("take_damage"):
		var distance := global_position.distance_to(_target.global_position)
		if distance <= ATTACK_RANGE * 1.2:
			_target.take_damage(ATTACK_DAMAGE, self)
			print("[Zombie] Attacked player for ", ATTACK_DAMAGE, " damage")


func take_damage(amount: float, source: Node = null) -> void:
	if state == State.DEAD:
		return
	
	health -= amount
	damaged.emit(amount, health)
	
	print("[Zombie] Took ", amount, " damage. HP: ", health)
	
	# Flash red
	_flash_damage()
	
	# Knockback away from source
	if source and is_instance_valid(source):
		var knockback_dir: Vector3 = (global_position - source.global_position).normalized()
		knockback_dir.y = 0
		velocity = knockback_dir * KNOCKBACK_FORCE
		
		# Also instantly move a bit
		global_position += knockback_dir * 0.2
	
	if health <= 0:
		_die()
	else:
		_enter_hit_stun()


func _enter_hit_stun() -> void:
	state = State.HIT
	velocity.x = 0
	velocity.z = 0
	
	# Return to chase after stun
	await get_tree().create_timer(0.3).timeout
	if state == State.HIT and health > 0:
		state = State.CHASE


func _flash_damage() -> void:
	var mesh := mesh_pivot.get_node_or_null("ZombieMesh") as MeshInstance3D
	if mesh:
		var mat := mesh.material_override as StandardMaterial3D
		if mat:
			var original_color := mat.albedo_color
			var tween := create_tween()
			tween.tween_property(mat, "albedo_color", Color.RED, 0.05)
			tween.tween_property(mat, "albedo_color", original_color, 0.15)


func _die() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	
	print("[Zombie] Died!")
	
	# Emit death signal (for loot spawning)
	died.emit(self)
	
	# Death animation
	var tween := create_tween()
	tween.tween_property(mesh_pivot, "rotation_degrees:x", -90, 0.3)
	tween.tween_property(mesh_pivot, "modulate" if mesh_pivot.has_method("set_modulate") else "scale", Vector3(1, 0.1, 1), 1.0)
	tween.tween_callback(queue_free)
