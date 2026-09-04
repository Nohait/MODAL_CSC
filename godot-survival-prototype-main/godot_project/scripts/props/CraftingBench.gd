extends StaticBody3D
class_name CraftingBench
## Crafting bench prop - visual only for V1

func _ready() -> void:
	_setup_visuals()


func _setup_visuals() -> void:
	# Create collision
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.5, 0.8, 0.8)
	collision.shape = box_shape
	collision.position.y = 0.4
	add_child(collision)
	
	# Create main bench
	var bench := MeshInstance3D.new()
	var bench_mesh := BoxMesh.new()
	bench_mesh.size = Vector3(1.5, 0.8, 0.8)
	bench.mesh = bench_mesh
	bench.position.y = 0.4
	
	var bench_mat := StandardMaterial3D.new()
	bench_mat.albedo_color = Color(0.5, 0.35, 0.2)  # Brown wood
	bench.material_override = bench_mat
	add_child(bench)
	
	# Add small boxes on top to suggest tools
	var tool_box := MeshInstance3D.new()
	var tool_mesh := BoxMesh.new()
	tool_mesh.size = Vector3(0.3, 0.2, 0.2)
	tool_box.mesh = tool_mesh
	tool_box.position = Vector3(-0.4, 0.9, 0.1)
	
	var tool_mat := StandardMaterial3D.new()
	tool_mat.albedo_color = Color(0.6, 0.6, 0.6)  # Metal gray
	tool_box.material_override = tool_mat
	add_child(tool_box)
	
	var tool_box2 := tool_box.duplicate()
	tool_box2.position = Vector3(0.2, 0.9, -0.15)
	tool_box2.scale = Vector3(1.2, 0.8, 1.0)
	add_child(tool_box2)
	
	var tool_box3 := tool_box.duplicate()
	tool_box3.position = Vector3(0.5, 0.9, 0.2)
	tool_box3.scale = Vector3(0.7, 1.2, 0.8)
	add_child(tool_box3)
	
	# Add legs
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.4, 0.28, 0.15)
	
	for x in [-0.6, 0.6]:
		for z in [-0.3, 0.3]:
			var leg := MeshInstance3D.new()
			var leg_mesh := BoxMesh.new()
			leg_mesh.size = Vector3(0.1, 0.4, 0.1)
			leg.mesh = leg_mesh
			leg.position = Vector3(x, -0.2, z)
			leg.material_override = leg_mat
			add_child(leg)
