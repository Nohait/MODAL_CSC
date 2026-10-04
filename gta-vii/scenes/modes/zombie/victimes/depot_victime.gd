extends Node3D

static func creer(victime: CharacterBody3D, parent: Node3D) -> void:
	var effet := Node3D.new()
	effet.name = "DepotVictime"
	parent.add_child(effet, true)
	# Une copie graphique termine le fondu ; la vraie victime n'est plus attaquable.
	var copie: MeshInstance3D = victime.visuel.duplicate()
	effet.add_child(copie)
	copie.global_transform = victime.visuel.global_transform
	var mat: StandardMaterial3D = victime.materiau.duplicate()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	copie.material_override = mat
	for surface in range(copie.mesh.get_surface_count()):
		copie.set_surface_override_material(surface, mat)

	var braises := CPUParticles3D.new()
	braises.amount = 9
	braises.lifetime = 0.55
	braises.one_shot = true
	braises.explosiveness = 0.9
	braises.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	braises.emission_sphere_radius = 0.2
	braises.direction = Vector3.UP
	braises.spread = 30.0
	braises.initial_velocity_min = 0.25
	braises.initial_velocity_max = 0.65
	braises.gravity = Vector3(0, -0.1, 0)
	var bille := SphereMesh.new()
	bille.radius = 0.025
	bille.height = 0.05
	var chaud := StandardMaterial3D.new()
	chaud.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chaud.albedo_color = Color("d6a465")
	bille.material = chaud
	braises.mesh = bille
	effet.add_child(braises)
	braises.global_position = victime.global_position + Vector3(0, 0.55, 0)

	var animation := effet.create_tween().set_parallel(true)
	# Le personnage s'efface et se resserre légèrement en même temps, en 0,35 seconde.
	animation.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	animation.tween_property(copie, "scale", copie.scale * 0.92, 0.35)
	# Laisser finir les neuf petites braises avant de retirer toute la copie.
	animation.chain().tween_interval(0.3)
	animation.chain().tween_callback(effet.queue_free)
