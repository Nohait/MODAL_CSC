extends StaticBody3D
class_name MapStation
## Interactable map station for zone travel

signal map_opened

@export var interaction_range := 2.5
@export var highlight_color := Color(0.8, 0.2, 0.2, 0.5)

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
	box_shape.size = Vector3(1.5, 1.0, 0.8)
	collision.shape = box_shape
	collision.position.y = 0.5
	add_child(collision)
	
	# Create main mesh - table/desk
	_mesh_instance = MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1.5, 0.8, 0.8)
	_mesh_instance.mesh = box_mesh
	_mesh_instance.position.y = 0.4
	
	# Material - metal/industrial look
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.3, 0.35, 0.4)  # Gray metal
	_mesh_instance.material_override = _material
	
	# Highlight material
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.albedo_color = Color(0.4, 0.45, 0.5)
	_highlight_material.emission_enabled = true
	_highlight_material.emission = highlight_color
	_highlight_material.emission_energy_multiplier = 0.3
	
	add_child(_mesh_instance)
	
	# Add red accent on top (map/screen)
	var accent := MeshInstance3D.new()
	var accent_mesh := BoxMesh.new()
	accent_mesh.size = Vector3(1.2, 0.1, 0.5)
	accent.mesh = accent_mesh
	accent.position = Vector3(0, 0.85, 0)
	
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.7, 0.2, 0.15)  # Red accent
	accent_mat.emission_enabled = true
	accent_mat.emission = Color(0.5, 0.1, 0.1)
	accent_mat.emission_energy_multiplier = 0.5
	accent.material_override = accent_mat
	add_child(accent)
	
	# Add stand/legs
	var leg := MeshInstance3D.new()
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.1, 0.4, 0.6)
	leg.mesh = leg_mesh
	leg.position = Vector3(0.6, 0.0, 0)
	
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.25, 0.25, 0.3)
	leg.material_override = leg_mat
	add_child(leg)
	
	var leg2 := leg.duplicate()
	leg2.position.x = -0.6
	add_child(leg2)


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
		map_opened.emit()


func can_interact() -> bool:
	return player_nearby
