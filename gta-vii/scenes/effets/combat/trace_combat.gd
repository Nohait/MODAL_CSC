extends RefCounted

const SHADER = preload("res://scenes/effets/combat/trace_combat.gdshader")
const LIMITE = 70

static func creer(parent: Node3D, point: Vector3, normale: Vector3, couleur: Color, taille: float, duree: float = 5.0) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree(): return
	# Un plafond commun évite d'accumuler des centaines de surfaces transparentes.
	var traces := parent.get_tree().get_nodes_in_group("traces_combat")
	if traces.size() >= LIMITE: traces[0].queue_free()
	var trace := MeshInstance3D.new()
	trace.add_to_group("traces_combat")
	var plan := PlaneMesh.new()
	plan.size = Vector2.ONE * taille
	trace.mesh = plan
	trace.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("teinte", couleur)
	mat.set_shader_parameter("graine", randf() * 30.0)
	trace.material_override = mat
	parent.add_child(trace)
	# Décaler de quelques millimètres empêche le scintillement contre le sol ou le mur.
	trace.global_position = point + normale * randf_range(0.012, 0.018)
	trace.global_basis = Basis(Quaternion(Vector3.UP, normale.normalized()))
	trace.rotate_object_local(Vector3.UP, randf() * TAU)
	var disparition := trace.create_tween()
	disparition.tween_interval(maxf(0.0, duree - 1.5))
	disparition.tween_method(func(alpha: float): mat.set_shader_parameter("opacite", alpha), 1.0, 0.0, 1.5)
	disparition.tween_callback(trace.queue_free)

static func sur_sol(parent: Node3D, origine: Vector3, couleur: Color, taille: float, duree: float = 5.0) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree(): return
	var rayon := PhysicsRayQueryParameters3D.create(origine + Vector3.UP * 0.2, origine - Vector3.UP * 5.0, 1)
	var contact := parent.get_world_3d().direct_space_state.intersect_ray(rayon)
	# Ne pas déposer une trace dans le vide ou sur une paroi verticale.
	if not contact.is_empty() and contact.normal.y > 0.8:
		creer(parent, contact.position, contact.normal, couleur, taille, duree)
