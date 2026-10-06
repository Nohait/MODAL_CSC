extends Node3D

# Effet seulement visuel : aucune collision ni modification des dégâts.
static func jouer(parent: Node3D, origine: Vector3, teinte: Color, rayon: float = 1.0) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree(): return
	var effet := Node3D.new()
	parent.add_child(effet)
	effet.global_position = origine
	var anneau := MeshInstance3D.new()
	var forme := TorusMesh.new()
	forme.inner_radius = 0.94
	forme.outer_radius = 1.0
	forme.rings = 16
	forme.ring_segments = 24
	anneau.mesh = forme
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = teinte
	anneau.material_override = mat
	effet.add_child(anneau)
	anneau.scale = Vector3.ONE * 0.12
	# Agrandissement et disparition simultanés, puis suppression de l'effet.
	var animation := effet.create_tween().set_parallel(true)
	animation.tween_property(anneau, "scale", Vector3(rayon, 0.12, rayon), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(mat, "albedo_color:a", 0.0, 0.45)
	animation.chain().tween_callback(effet.queue_free)
