extends StaticBody3D
class_name StorageBox
## Interactable storage box for home base

signal storage_opened

@export var interaction_range := 2.5
@export var highlight_color := Color(1.0, 0.8, 0.2, 0.5)

var player_nearby := false
var _material: StandardMaterial3D
var _highlight_material: StandardMaterial3D
var _mesh_instance: MeshInstance3D

func _ready() -> void:
	add_to_group("interactable")
	_setup_visuals()


func _setup_visuals() -> void:
	# Create collision
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.0, 0.6, 0.6)
	collision.shape = box_shape
	collision.position.y = 0.3
	add_child(collision)
	
	# Create mesh
	_mesh_instance = MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1.0, 0.6, 0.6)
	_mesh_instance.mesh = box_mesh
	_mesh_instance.position.y = 0.3
	
	# Material - wooden crate look
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.35, 0.25, 0.15)  # Dark brown wood
	_mesh_instance.material_override = _material
	
	# Highlight material
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.albedo_color = Color(0.5, 0.4, 0.25)  # Lighter when highlighted
	_highlight_material.emission_enabled = true
	_highlight_material.emission = highlight_color
	_highlight_material.emission_energy_multiplier = 0.3
	
	add_child(_mesh_instance)
	
	# Add lid detail
	var lid := MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.9, 0.05, 0.5)
	lid.mesh = lid_mesh
	lid.position = Vector3(0, 0.625, 0)
	
	var lid_mat := StandardMaterial3D.new()
	lid_mat.albedo_color = Color(0.4, 0.3, 0.18)
	lid.material_override = lid_mat
	add_child(lid)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var was_nearby := player_nearby
		player_nearby = global_position.distance_to(player.global_position) < interaction_range
		
		# Update visual highlight
		if player_nearby != was_nearby:
			if player_nearby:
				_mesh_instance.material_override = _highlight_material
			else:
				_mesh_instance.material_override = _material


func interact(_player: Node = null) -> void:
	if player_nearby:
		storage_opened.emit()


func can_interact() -> bool:
	return player_nearby
