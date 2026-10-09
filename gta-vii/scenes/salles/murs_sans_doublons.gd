extends RefCounted

const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")

static func nettoyer(salle: Node3D) -> void:
	var surfaces: Array[MeshInstance3D] = []
	# Les murs jouables ont priorité. Leurs collisions ne sont jamais modifiées.
	for corps in salle.get_node("Navigation/Decor").get_children():
		if not corps.scene_file_path.is_empty(): continue
		for enfant in corps.get_children():
			if enfant is MeshInstance3D and enfant.mesh is BoxMesh:
				surfaces.append(enfant)
	for enfant in salle.get_node("Habillage").get_children():
		if enfant.has_method("surfaces"):
			for surface in enfant.surfaces():
				surfaces.append(surface)
		elif enfant.name == "EspacesInaccessibles":
			for surface in enfant.get_children():
				if surface is MeshInstance3D and surface.mesh is BoxMesh:
					surfaces.append(surface)
	var occupees: Array[AABB] = []
	for surface in surfaces:
		var transfo := Transform3D.IDENTITY
		var ancetre: Node3D = surface
		while ancetre != salle:
			transfo = ancetre.transform * transfo
			ancetre = ancetre.get_parent()
		var boite: AABB = transfo * surface.get_aabb()
		var morceaux: Array[AABB] = [boite]
		for autre in occupees:
			morceaux = _soustraire(morceaux, autre)
		if morceaux.size() == 1 and morceaux[0].is_equal_approx(boite):
			occupees.append(boite)
			continue
		var parent: Node3D = surface.get_parent()
		var vers_parent := surface.transform * transfo.affine_inverse()
		var materiau: Material = surface.get_active_material(0)
		# Découper seulement le visuel permet de garder portes, fenêtres et navigation intactes.
		for morceau in morceaux:
			var local: AABB = vers_parent * morceau
			GEOMETRIE.bloc(parent, str(surface.name) + "Raccord", local.get_center(), local.size, materiau)
			occupees.append(morceau)
		parent.remove_child(surface)
		surface.free()

static func _soustraire(zones: Array[AABB], obstacle: AABB) -> Array[AABB]:
	var resultat: Array[AABB] = []
	for zone in zones:
		var intersection := zone.intersection(obstacle)
		if intersection.size.x < 0.001 or intersection.size.y < 0.001 or intersection.size.z < 0.001:
			resultat.append(zone)
			continue
		# Les six morceaux entourent l'intersection sans jamais se chevaucher.
		var milieu := zone
		for axe in range(3):
			var avant := milieu
			avant.size[axe] = intersection.position[axe] - milieu.position[axe]
			if avant.size[axe] > 0.001: resultat.append(avant)
			var apres := milieu
			apres.position[axe] = intersection.end[axe]
			apres.size[axe] = milieu.end[axe] - intersection.end[axe]
			if apres.size[axe] > 0.001: resultat.append(apres)
			milieu.position[axe] = intersection.position[axe]
			milieu.size[axe] = intersection.size[axe]
	return resultat
