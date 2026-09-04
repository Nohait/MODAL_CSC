extends Harvestable
class_name RockResource
## Harvestable rock - drops stone when destroyed

var _original_material: StandardMaterial3D
var _mesh_instance: MeshInstance3D


func _init() -> void:
	hp = 80.0
	drops = [{"item_id": "stone", "min_count": 2, "max_count": 4}]


func _ready() -> void:
	super._ready()
	
	# Cache mesh reference for flash effect
	if mesh_pivot and mesh_pivot.get_child_count() > 0:
		_mesh_instance = mesh_pivot.get_child(0) as MeshInstance3D
		if _mesh_instance and _mesh_instance.material_override:
			_original_material = _mesh_instance.material_override


func _play_hit_effect() -> void:
	if not _mesh_instance:
		# Fallback: find mesh dynamically
		if mesh_pivot and mesh_pivot.get_child_count() > 0:
			_mesh_instance = mesh_pivot.get_child(0) as MeshInstance3D
	
	if not _mesh_instance:
		return
	
	# Store original if not cached
	if not _original_material and _mesh_instance.material_override:
		_original_material = _mesh_instance.material_override
	
	# Flash white
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color.WHITE
	flash_mat.emission_enabled = true
	flash_mat.emission = Color.WHITE
	flash_mat.emission_energy_multiplier = 0.5
	_mesh_instance.material_override = flash_mat
	
	# Restore after delay
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(_mesh_instance):
		_mesh_instance.material_override = _original_material
