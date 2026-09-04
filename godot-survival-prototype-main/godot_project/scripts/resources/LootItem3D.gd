extends Area3D

signal picked_up(item_type, quantity)

@export var item_type := "resource"
@export var quantity := 1
@export var float_amplitude := 0.15
@export var float_speed := 3.0
@export var attract_speed := 8.0
@export var attract_distance := 2.5

var _base_position := Vector3.ZERO
var _bob_timer := 0.0
var _attracted_to: Node3D = null
var _mesh_instance: MeshInstance3D

func _ready() -> void:
	monitoring = true
	set_process(true)
	_base_position = global_position
	
	# Create visual mesh
	_create_loot_visual()
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Add to group
	add_to_group("loot_items")

func _create_loot_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	
	# Try to load item-specific model
	var model_name: String = _get_model_for_item(item_type)
	if ModelManager and model_name:
		var model: MeshInstance3D = ModelManager.create_mesh_instance(model_name)
		if model:
			add_child(model)
			model.scale = Vector3(0.3, 0.3, 0.3)
			return
	
	# Fallback: simple box mesh
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	_mesh_instance.mesh = box
	
	# Color based on item type
	var material = StandardMaterial3D.new()
	material.albedo_color = _get_color_for_item(item_type)
	material.emission_enabled = true
	material.emission = _get_color_for_item(item_type)
	material.emission_energy_multiplier = 0.5
	_mesh_instance.material_override = material
	
	add_child(_mesh_instance)

func _get_model_for_item(item: String) -> String:
	match item:
		"wood": return "log"
		"stone": return "rock_small"
		"iron_ore": return "rock_ore"
		"fiber": return "grass_tuft"
		"berries": return "berry_bush"
		"cloth": return "crate_small"
		"leather": return "crate_small"
		_: return ""

func _get_color_for_item(item: String) -> Color:
	match item:
		"wood": return Color(0.6, 0.4, 0.2)
		"stone": return Color(0.5, 0.5, 0.5)
		"iron_ore": return Color(0.4, 0.3, 0.3)
		"fiber": return Color(0.4, 0.7, 0.3)
		"berries": return Color(0.8, 0.2, 0.2)
		"cloth": return Color(0.8, 0.8, 0.7)
		"leather": return Color(0.5, 0.3, 0.2)
		"scrap": return Color(0.6, 0.6, 0.6)
		"weapon_parts": return Color(0.3, 0.3, 0.4)
		_: return Color(1, 1, 1)

func _process(delta: float) -> void:
	# Float animation
	_bob_timer += delta * float_speed
	var offset_y = sin(_bob_timer) * float_amplitude
	
	# Rotation
	if _mesh_instance:
		_mesh_instance.rotation.y += delta * 2.0
	
	# Attraction to player
	if _attracted_to and is_instance_valid(_attracted_to):
		var direction = (_attracted_to.global_position - global_position).normalized()
		global_position += direction * attract_speed * delta
		
		# Check if close enough to collect
		if global_position.distance_to(_attracted_to.global_position) < 0.5:
			_collect()
	else:
		global_position = _base_position + Vector3(0, offset_y, 0)

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_interact"):
		_start_attraction(area.get_parent())

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_start_attraction(body)

func _start_attraction(target: Node3D) -> void:
	if _attracted_to:
		return
	_attracted_to = target

func _collect() -> void:
	# Try to add to inventory
	var inventory = _get_inventory()
	var collected := true
	
	if inventory and inventory.has_method("add_item"):
		collected = inventory.add_item(item_type, quantity)
	
	if collected:
		emit_signal("picked_up", item_type, quantity)
		print("Collected %s x%d" % [item_type, quantity])
		
		# Spawn pickup particle effect
		_spawn_pickup_effect()
		
		queue_free()

func _get_inventory():
	# Try autoload
	if has_node("/root/Inventory"):
		return get_node("/root/Inventory")
	
	# Try current scene
	var current = get_tree().current_scene
	if current:
		return current.get_node_or_null("Inventory")
	
	return null

func _spawn_pickup_effect() -> void:
	# Create a simple particle burst
	var particles = GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.5
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 4.0
	material.gravity = Vector3(0, -5, 0)
	material.color = _get_color_for_item(item_type)
	particles.process_material = material
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	particles.draw_pass_1 = mesh
	
	# Add to parent so it persists after queue_free
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Auto cleanup
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(timer)
