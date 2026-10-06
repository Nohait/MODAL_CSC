extends RefCounted

static func jouer(parent: Node3D, origine: Vector3) -> void:
	if not is_instance_valid(parent): return
	var rayon := PhysicsRayQueryParameters3D.create(origine, origine - Vector3.UP * 4.0, 1)
	var contact := parent.get_world_3d().direct_space_state.intersect_ray(rayon)
	if contact.is_empty() or contact.normal.y < 0.8: return
	var gouttes := CPUParticles3D.new()
	gouttes.amount = 10
	gouttes.lifetime = 0.45
	gouttes.one_shot = true
	gouttes.explosiveness = 1.0
	gouttes.direction = Vector3.UP
	gouttes.spread = 70.0
	gouttes.gravity = Vector3(0, -8, 0)
	gouttes.initial_velocity_min = 0.6
	gouttes.initial_velocity_max = 1.3
	var forme := SphereMesh.new()
	forme.radius = 0.012
	forme.height = 0.035
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.8, 0.9, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	forme.material = mat
	gouttes.mesh = forme
	gouttes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(gouttes)
	gouttes.global_position = contact.position + Vector3.UP * 0.04
	# Le signal finished nettoie le petit émetteur après son unique éclaboussure.
	gouttes.finished.connect(gouttes.queue_free)
	gouttes.restart()
