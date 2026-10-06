extends RefCounted

static func creer(parent: Node3D, points: Array[Vector3], rayon: float, couleur: Color) -> MeshInstance3D:
	var courbe := Curve3D.new()
	for i in points.size():
		# Des tangentes communes donnent un tuyau arrondi, sans angles entre les points.
		var avant := points[maxi(0, i - 1)]
		var apres := points[mini(points.size() - 1, i + 1)]
		var tangente := (apres - avant) * 0.18
		courbe.add_point(points[i], -tangente, tangente)
	courbe.bake_interval = 0.15
	var trajet := courbe.get_baked_points()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in trajet.size() - 1:
		var direction := (trajet[i + 1] - trajet[i]).normalized()
		var axe := direction.cross(Vector3.UP).normalized()
		if axe.length_squared() < 0.01:
			axe = Vector3.RIGHT
		var second_axe := direction.cross(axe).normalized()
		for cote in 10:
			var angle := TAU * cote / 10.0
			var suivant := TAU * (cote + 1) / 10.0
			var bord := (axe * cos(angle) + second_axe * sin(angle)) * rayon
			var bord_suivant := (axe * cos(suivant) + second_axe * sin(suivant)) * rayon
			var sommets := [trajet[i] + bord, trajet[i + 1] + bord, trajet[i] + bord_suivant,
				trajet[i] + bord_suivant, trajet[i + 1] + bord, trajet[i + 1] + bord_suivant]
			var coordonnees := [Vector2(cote, i), Vector2(cote, i + 1), Vector2(cote + 1, i),
				Vector2(cote + 1, i), Vector2(cote, i + 1), Vector2(cote + 1, i + 1)]
			for sommet in sommets.size():
				# Ces coordonnées permettent au shader d'animer l'eau le long du tube.
				surface.set_uv(coordonnees[sommet] / Vector2(10, trajet.size() - 1))
				surface.add_vertex(sommets[sommet])
	surface.generate_normals()
	var materiau := StandardMaterial3D.new()
	materiau.albedo_color = couleur
	materiau.roughness = 0.85
	materiau.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tuyau := MeshInstance3D.new()
	tuyau.mesh = surface.commit()
	tuyau.material_override = materiau
	parent.add_child(tuyau)
	return tuyau
