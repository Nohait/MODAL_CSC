extends RefCounted

# Matériaux du premier étage classique ; toutes les positions restent fixes.
const SOL = preload("res://assets/materiaux/sol_appartements.tres")
const MUR = preload("res://assets/materiaux/mur_appartements.tres")
const PROFIL = preload("res://scenes/modes/tutoriel/commun/decors/profil_decor.tres")
const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")

static func bloc(parent: Node3D, nom: String, emplacement: Vector3, taille: Vector3, materiau: Material) -> StaticBody3D:
	var corps := StaticBody3D.new()
	corps.name = nom
	corps.position = emplacement
	corps.collision_mask = 0
	var visuel := MeshInstance3D.new()
	visuel.name = "Visuel"
	var mesh := BoxMesh.new()
	mesh.size = taille
	mesh.material = materiau
	visuel.mesh = mesh
	corps.add_child(visuel)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var forme := BoxShape3D.new()
	forme.size = taille
	collision.shape = forme
	corps.add_child(collision)
	parent.add_child(corps)
	if taille.y > 0.7 and minf(taille.x, taille.z) < 0.5:
		_finitions(corps, taille)
	return corps

static func meuble(parent: Node3D, scene: PackedScene, emplacement: Vector3, angle := 0.0) -> Node3D:
	var objet: Node3D = scene.instantiate()
	objet.position = emplacement
	objet.rotation.y = angle
	parent.add_child(objet)
	return objet

static func _surface(parent: Node3D, position_locale: Vector3, taille: Vector3, materiau: Material) -> void:
	var surface := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = taille
	mesh.material = materiau
	surface.mesh = mesh
	surface.position = position_locale
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(surface)

static func _finitions(mur: Node3D, taille: Vector3) -> void:
	if mur.has_meta("finitions_tutoriel"): return
	mur.set_meta("finitions_tutoriel", true)
	var horizontal := taille.x > taille.z
	var longueur := maxf(taille.x, taille.z)
	for cote in [-1, 1]:
		var hauteur: float = PROFIL.hauteur_soubassement
		var position_locale := Vector3(0, -taille.y / 2 + hauteur / 2, 0)
		if horizontal: position_locale.z = (taille.z / 2 + 0.014) * cote
		else: position_locale.x = (taille.x / 2 + 0.014) * cote
		_surface(mur, position_locale, Vector3(longueur, hauteur, 0.02) if horizontal else Vector3(0.02, hauteur, longueur), PROFIL.soubassement)
		for y in [PROFIL.hauteur_plinthe / 2, hauteur]:
			position_locale.y = -taille.y / 2 + y
			_surface(mur, position_locale, Vector3(longueur, PROFIL.hauteur_plinthe, 0.045) if horizontal else Vector3(0.045, PROFIL.hauteur_plinthe, longueur), PROFIL.bois)

static func habiller_existants(parent: Node3D) -> void:
	for mur in parent.find_children("*", "StaticBody3D", true, false):
		var surface := mur.get_node_or_null("Visuel") as MeshInstance3D
		if surface != null and surface.mesh is BoxMesh and surface.mesh.size.y > 0.7 and minf(surface.mesh.size.x, surface.mesh.size.z) < 0.5:
			_finitions(mur, surface.mesh.size)

static func construire_plan(parent: Node3D, plan: Resource) -> void:
	for i in plan.sols.size():
		var rect: Rect2 = plan.sols[i]
		var centre := rect.get_center()
		bloc(parent, "SolFixe%d" % i, Vector3(centre.x, -0.15, centre.y), Vector3(rect.size.x, 0.3, rect.size.y), PROFIL.sol)
	for i in plan.contour.size():
		var a: Vector2 = plan.contour[i]
		var b: Vector2 = plan.contour[(i + 1) % plan.contour.size()]
		var centre := (a + b) / 2
		var delta := (a - b).abs()
		bloc(parent, "MurFixe%d" % i, Vector3(centre.x, PROFIL.hauteur_murs / 2, centre.y), Vector3(maxf(delta.x, 0.25), PROFIL.hauteur_murs, maxf(delta.y, 0.25)), PROFIL.mur)
	if plan.navigation:
		var contours := Geometry2D.offset_polygon(plan.contour, -plan.marge_navigation)
		if not contours.is_empty():
			var polygon: PackedVector2Array = contours[0]
			var triangles := Geometry2D.triangulate_polygon(polygon)
			var mesh := NavigationMesh.new()
			var sommets := PackedVector3Array()
			for point in polygon: sommets.append(Vector3(point.x, 0, point.y))
			mesh.vertices = sommets
			for i in range(0, triangles.size(), 3): mesh.add_polygon(PackedInt32Array([triangles[i], triangles[i + 2], triangles[i + 1]]))
			var region := NavigationRegion3D.new()
			region.navigation_mesh = mesh
			parent.add_child(region)
	for i in plan.annexes.size():
		annexe(parent, plan.annexes[i], plan.positions_annexes[i], plan.orientations_annexes[i])
	for position_lumiere in plan.lumieres:
		plafonnier(parent, position_lumiere)

static func plafonnier(parent: Node3D, emplacement: Vector3) -> void:
	var support := Node3D.new()
	support.name = "Plafonnier"
	support.position = emplacement
	parent.add_child(support)
	var modele = preload("res://assets/modeles/appartements/modern_ceiling_lamp_01/modern_ceiling_lamp_01_1k.gltf").instantiate()
	support.add_child(modele)
	GEOMETRIE.normaliser(modele, 0.55, true)
	for surface in modele.find_children("*", "MeshInstance3D", true, false):
		for i in range(surface.mesh.get_surface_count()):
			var original: Material = surface.get_active_material(i)
			if original is StandardMaterial3D and "glass" in original.resource_name.to_lower():
				var verre: StandardMaterial3D = original.duplicate()
				verre.emission_enabled = true
				verre.emission = PROFIL.couleur_lumieres
				verre.emission_energy_multiplier = PROFIL.energie_lumieres
				surface.set_surface_override_material(i, verre)
	var lumiere := OmniLight3D.new()
	lumiere.light_energy = PROFIL.energie_lumieres
	lumiere.light_color = PROFIL.couleur_lumieres
	lumiere.omni_range = PROFIL.portee_lumieres
	lumiere.shadow_enabled = false
	support.add_child(lumiere)

static func annexe(parent: Node3D, scene: PackedScene, position_piece: Vector3, angle: float) -> void:
	var piece: Node3D = scene.instantiate()
	piece.position = position_piece
	piece.rotation.y = angle
	piece.add_to_group("details_decor")
	parent.add_child(piece)
	porte_fictive(piece, Vector3(0, 0, 0.2), 0.0)
	for surface in piece.find_children("Mur*", "MeshInstance3D", true, false):
		surface.scale.y *= 0.45
		surface.position.y *= 0.45
	for extinction in piece.find_children("Extinction", "Node3D", true, false): extinction.extinguible = false

static func porte_fictive(parent: Node3D, emplacement: Vector3, angle: float) -> void:
	# Une porte fermée explique l'accès sans ouvrir le décor à la navigation.
	var porte := Node3D.new()
	porte.name = "PorteAppartement"
	porte.position = emplacement
	porte.rotation.y = angle
	parent.add_child(porte)
	_surface(porte, Vector3(0, 1.05, 0), Vector3(1.3, 2.1, 0.07), PROFIL.bois)
	for cote in [-1, 1]:
		_surface(porte, Vector3(cote * 0.69, 1.08, 0), Vector3(0.08, 2.16, 0.12), PROFIL.soubassement)
	_surface(porte, Vector3(0, 2.14, 0), Vector3(1.46, 0.08, 0.12), PROFIL.soubassement)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.5, 0.46, 0.35)
	metal.metallic = 0.7
	metal.roughness = 0.4
	for cote in [-1, 1]:
		_surface(porte, Vector3(0.47, 1.0, cote * 0.065), Vector3(0.18, 0.035, 0.06), metal)
