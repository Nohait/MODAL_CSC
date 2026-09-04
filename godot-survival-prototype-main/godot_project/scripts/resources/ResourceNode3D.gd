extends StaticBody3D
class_name ResourceNode3D
## Base class for harvestable 3D resource nodes (trees, rocks, bushes, etc.)

signal depleted(node: ResourceNode3D)
signal harvested(item_type: String, amount: int)
signal health_changed(current: int, max_hp: int)

@export_group("Resource Settings")
@export var max_hp := 3
@export var loot_type := "resource"
@export var loot_amount := 1
@export var loot_scene: PackedScene
@export var drop_spread := 1.0

@export_group("Visual Settings")
@export var model_name := ""
@export var hit_flash_color := Color(1, 0.7, 0.5, 1)
@export var hit_scale_punch := 0.1

@export_group("Respawn")
@export var can_respawn := true
@export var respawn_time := 60.0

var current_hp := 0
var is_depleted := false
var _flash_timer := 0.0
var _original_scale := Vector3.ONE

@onready var mesh_instance: MeshInstance3D = $MeshPivot/MeshInstance3D
@onready var mesh_pivot: Node3D = $MeshPivot
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interact_area: Area3D = $InteractArea


func _ready() -> void:
	current_hp = max_hp
	_original_scale = mesh_pivot.scale if mesh_pivot else Vector3.ONE
	
	# Load model if specified
	if model_name and not model_name.is_empty():
		_load_model()
	
	add_to_group("resource")
	add_to_group("interactable")


func _load_model() -> void:
	if not ModelManager.is_loaded():
		ModelManager.instance.models_loaded.connect(_on_models_loaded, CONNECT_ONE_SHOT)
		return
	
	var model := ModelManager.create_mesh_instance(model_name)
	if model and mesh_pivot:
		# Remove placeholder if exists
		if mesh_instance:
			mesh_instance.queue_free()
		
		mesh_pivot.add_child(model)
		mesh_instance = model
		model.position = Vector3.ZERO


func _on_models_loaded() -> void:
	_load_model()


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		
		# Scale punch effect
		var punch_progress := _flash_timer / 0.2
		if mesh_pivot:
			mesh_pivot.scale = _original_scale * (1.0 + hit_scale_punch * punch_progress)
		
		if _flash_timer <= 0.0:
			_reset_visual()


func _reset_visual() -> void:
	if mesh_pivot:
		mesh_pivot.scale = _original_scale


func interact(player: Node) -> void:
	"""Called when player interacts with this resource."""
	take_damage(1, player, true)


func take_damage(amount: int, source: Node = null, is_harvest := false) -> bool:
	"""Deal damage to this resource node."""
	if current_hp <= 0 or is_depleted:
		return false
	
	current_hp = max(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)
	
	# Visual feedback
	_play_hit_effect()
	
	if current_hp <= 0:
		_deplete(source)
	else:
		# Drop partial loot on hit
		if is_harvest:
			_drop_single_loot()
			harvested.emit(loot_type, 1)
	
	return true


func _play_hit_effect() -> void:
	_flash_timer = 0.2
	
	# Tint mesh
	if mesh_instance:
		var mat := mesh_instance.get_active_material(0)
		if mat and mat is StandardMaterial3D:
			var tinted := mat.duplicate()
			tinted.albedo_color = hit_flash_color
			mesh_instance.set_surface_override_material(0, tinted)
			
			# Reset after delay
			await get_tree().create_timer(0.15).timeout
			mesh_instance.set_surface_override_material(0, null)


func _deplete(source: Node) -> void:
	is_depleted = true
	depleted.emit(self)
	
	# Drop remaining loot
	_drop_loot()
	
	# Hide or destroy
	if can_respawn:
		visible = false
		collision_shape.disabled = true
		if interact_area:
			interact_area.monitoring = false
		
		# Schedule respawn
		await get_tree().create_timer(respawn_time).timeout
		_respawn()
	else:
		queue_free()


func _respawn() -> void:
	current_hp = max_hp
	is_depleted = false
	visible = true
	collision_shape.disabled = false
	if interact_area:
		interact_area.monitoring = true
	health_changed.emit(current_hp, max_hp)


func _drop_loot() -> void:
	var loot_to_drop := loot_amount
	# Subtract any already dropped during harvesting
	for i in range(loot_to_drop):
		_drop_single_loot()


func _drop_single_loot() -> void:
	if not loot_scene:
		# Use LootItem if no custom scene
		loot_scene = load("res://scenes/resources/LootItem3D.tscn")
		if not loot_scene:
			push_warning("No loot scene available for " + name)
			return
	
	var loot := loot_scene.instantiate()
	
	if loot.has_method("set_item"):
		loot.set_item(loot_type, 1)
	elif "item_type" in loot:
		loot.item_type = loot_type
		loot.quantity = 1
	
	# Random offset
	var offset := Vector3(
		randf_range(-drop_spread, drop_spread),
		0.5,
		randf_range(-drop_spread, drop_spread)
	)
	loot.global_position = global_position + offset
	
	# Add to scene
	var parent := get_parent()
	if parent:
		parent.add_child(loot)
	else:
		get_tree().current_scene.add_child(loot)


func reset() -> void:
	"""Reset resource to full health."""
	current_hp = max_hp
	is_depleted = false
	visible = true
	if collision_shape:
		collision_shape.disabled = false
	if interact_area:
		interact_area.monitoring = true
	_reset_visual()
	health_changed.emit(current_hp, max_hp)


func set_model(new_model_name: String) -> void:
	"""Change the model dynamically."""
	model_name = new_model_name
	if is_inside_tree():
		_load_model()
