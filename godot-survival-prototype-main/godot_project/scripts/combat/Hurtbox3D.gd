extends Area3D

signal damaged(amount, remaining_health, source)
signal died(source)

@export var max_health := 120.0
@export var group_name := "hurtbox_enemy"
@export var invulnerable_time := 0.1
@export var flash_on_damage := true

var current_health := max_health
var _invulnerable_timer := 0.0
var _owner_node: Node3D

func _ready() -> void:
	current_health = max_health
	add_to_group(group_name)
	set_physics_process(true)
	
	# Get the owner node (usually parent or parent's parent)
	_owner_node = get_parent()
	if _owner_node is CollisionShape3D:
		_owner_node = _owner_node.get_parent()

func _physics_process(delta: float) -> void:
	if _invulnerable_timer > 0.0:
		_invulnerable_timer = maxf(_invulnerable_timer - delta, 0.0)

func take_damage(amount: float, source: Node = null) -> bool:
	if current_health <= 0.0:
		return false
	if _invulnerable_timer > 0.0:
		return false
	
	current_health = clampf(current_health - amount, 0.0, max_health)
	_invulnerable_timer = invulnerable_time
	
	# Visual feedback
	if flash_on_damage:
		_flash_damage()
	
	emit_signal("damaged", amount, current_health, source)
	
	if current_health <= 0.0:
		emit_signal("died", source)
	
	return true

func heal(amount: float) -> void:
	current_health = clampf(current_health + amount, 0.0, max_health)

func reset_health() -> void:
	current_health = max_health
	_invulnerable_timer = 0.0

func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0

func is_alive() -> bool:
	return current_health > 0.0

func _flash_damage() -> void:
	# Find mesh to flash
	var mesh = _find_mesh(_owner_node)
	if not mesh:
		return
	
	# Store original material
	var original_material = mesh.get_surface_override_material(0)
	
	# Create flash material
	var flash_mat = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1, 0.3, 0.3)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1, 0, 0)
	flash_mat.emission_energy_multiplier = 2.0
	
	mesh.set_surface_override_material(0, flash_mat)
	
	# Reset after delay
	await get_tree().create_timer(0.1).timeout
	
	if is_instance_valid(mesh):
		mesh.set_surface_override_material(0, original_material)

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	
	for child in node.get_children():
		var result = _find_mesh(child)
		if result:
			return result
	
	return null
