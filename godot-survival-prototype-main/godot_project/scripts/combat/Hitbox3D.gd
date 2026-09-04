extends Area3D

signal damage_dealt(target, amount)

@export var lifetime := 0.2
@export var damage := 25.0
@export var knockback_force := 5.0
@export var target_groups: Array[String] = []

var attacker: Node3D
var _time_left := 0.0
var _active := false

@onready var _shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	monitoring = false
	set_physics_process(false)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func activate(attack_range: float, direction: Vector3) -> void:
	_configure_shape(attack_range)
	
	# Rotate hitbox to face attack direction
	if direction.length() > 0.01:
		var flat_dir = Vector3(direction.x, 0, direction.z).normalized()
		if flat_dir.length() > 0.01:
			look_at(global_position + flat_dir, Vector3.UP)
	
	_time_left = lifetime
	_active = true
	monitoring = true
	monitorable = true
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		deactivate()

func deactivate() -> void:
	_active = false
	monitoring = false
	monitorable = false
	set_physics_process(false)
	queue_free()

func _configure_shape(attack_range: float) -> void:
	if not _shape:
		return
	
	var shape = _shape.shape
	if shape is SphereShape3D:
		shape.radius = attack_range
	elif shape is BoxShape3D:
		shape.size = Vector3(attack_range, attack_range, attack_range)
	elif shape is CapsuleShape3D:
		shape.radius = attack_range * 0.5
		shape.height = attack_range

func _on_area_entered(area: Area3D) -> void:
	_try_damage(area)

func _on_body_entered(body: Node3D) -> void:
	_try_damage(body)

func _try_damage(target: Node) -> void:
	if not _active:
		return
	
	# Don't hit the attacker
	if attacker and target == attacker:
		return
	if attacker and target.get_parent() == attacker:
		return
	
	# Check target groups
	if target_groups.size() > 0:
		var matches := false
		for group in target_groups:
			if target.is_in_group(group):
				matches = true
				break
		if not matches:
			return
	
	# Apply damage
	if target.has_method("take_damage"):
		var applied: bool = target.take_damage(damage, attacker)
		if applied:
			emit_signal("damage_dealt", target, damage)
			_apply_knockback(target)

func _apply_knockback(target: Node) -> void:
	if knockback_force <= 0:
		return
	
	if target is CharacterBody3D and target.has_method("apply_knockback"):
		var direction := Vector3.ZERO
		if attacker:
			direction = (target.global_position - attacker.global_position).normalized()
		else:
			direction = -global_transform.basis.z
		target.apply_knockback(direction * knockback_force)
