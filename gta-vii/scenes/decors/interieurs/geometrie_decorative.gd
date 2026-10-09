extends RefCounted

static func normaliser(modele: Node3D, dimension: float, par_hauteur: bool) -> Vector3:
	var boite := AABB()
	var premier := true
	for surface: MeshInstance3D in modele.find_children("*", "MeshInstance3D", true, false):
		# Calcul local valable aussi avant l'ajout de la salle à l'arbre du jeu.
		var transfo := Transform3D.IDENTITY
		var parent: Node3D = surface
		while parent != modele:
			transfo = parent.transform * transfo
			parent = parent.get_parent()
		var limites := transfo * surface.get_aabb()
		boite = limites if premier else boite.merge(limites)
		premier = false
	var facteur := dimension / maxf(boite.size.y if par_hauteur else boite.size.x, 0.01)
	modele.scale = Vector3.ONE * facteur
	modele.position = Vector3(-boite.get_center().x, -boite.position.y, -boite.get_center().z) * facteur
	return boite.size * facteur

static func bloc(parent: Node3D, nom: String, position: Vector3, taille: Vector3, materiau: Material) -> MeshInstance3D:
	var surface := MeshInstance3D.new()
	surface.name = nom
	surface.position = position
	var forme := BoxMesh.new()
	forme.size = taille
	forme.material = materiau
	surface.mesh = forme
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(surface)
	return surface
