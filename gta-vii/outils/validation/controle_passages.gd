extends RefCounted

static func verifier(salle: Node3D, rayon: float, hauteur: float, cartes: Array[RID]) -> Array[Dictionary]:
	var problemes: Array[Dictionary] = []
	var forme := CapsuleShape3D.new()
	forme.radius = rayon
	forme.height = hauteur
	var requete := PhysicsShapeQueryParameters3D.new()
	requete.shape = forme
	requete.collision_mask = 1 | 16
	var physique := salle.get_world_3d().direct_space_state
	for categorie in ["spawn", "arrivee"]:
		var points: Array = salle.points_spawn if categorie == "spawn" else salle.points_arrivee
		for point in points:
			requete.transform = Transform3D(Basis.IDENTITY, point + Vector3.UP * (0.12 + hauteur / 2))
			var contacts := physique.intersect_shape(requete, 8)
			if not contacts.is_empty():
				problemes.append({"type": categorie + "_obstrue", "position": str(point), "objet": str(contacts[0].collider.name)})
	var depart: Vector3 = salle.entree.to_global(Vector3(0, 0.15, -1.4))
	var entree: Vector3 = salle.entree.to_global(Vector3(0, 0.15, 1.6))
	for donnees in [{"carte": cartes[0], "nom": "victimes"}, {"carte": cartes[1], "nom": "ennemis"}]:
		var chemin_entree := NavigationServer3D.map_get_path(donnees.carte, entree, depart, true)
		if not _atteint(chemin_entree, entree, depart):
			problemes.append({"type": "entree_inaccessible", "navigation": donnees.nom, "position": str(depart)})
		for point in salle.points_spawn:
			var cible: Vector3 = point + Vector3.UP * 0.15
			var chemin := NavigationServer3D.map_get_path(donnees.carte, depart, cible, true)
			if not _atteint(chemin, depart, cible):
				problemes.append({"type": "spawn_inaccessible", "navigation": donnees.nom, "position": str(point)})
		for point in salle.points_arrivee:
			var cible: Vector3 = point + Vector3.UP * 0.15
			var chemin := NavigationServer3D.map_get_path(donnees.carte, depart, cible, true)
			if not _atteint(chemin, depart, cible):
				problemes.append({"type": "arrivee_inaccessible", "navigation": donnees.nom, "position": str(point)})
		for porte in salle.get_node("Portes").get_children():
			# Le seuil est testé avant l'escalier : le passage de salle téléporte le joueur.
			var cible: Vector3 = porte.to_global(Vector3(0, 0.05, -0.65))
			var chemin := NavigationServer3D.map_get_path(donnees.carte, depart, cible, true)
			if not _atteint(chemin, depart, cible):
				problemes.append({"type": "sortie_inaccessible", "navigation": donnees.nom, "objet": str(porte.name), "position": str(cible)})
	# Le battant est déjà placé à son angle ouvert dans la scène de test.
	for porte in salle.get_node("Portes").get_children():
		for distance in [-0.65, 0.0, 0.65]:
			var centre: Vector3 = porte.to_global(Vector3(0, hauteur / 2 + 0.02, distance))
			requete.transform = Transform3D(Basis.IDENTITY, centre)
			var contacts := physique.intersect_shape(requete, 8)
			if not contacts.is_empty():
				problemes.append({"type": "passage_porte_obstrue", "objet": str(porte.name), "autre": str(contacts[0].collider.name), "position": str(centre)})
	return problemes

static func _atteint(chemin: PackedVector3Array, depart: Vector3, cible: Vector3) -> bool:
	if chemin.is_empty(): return false
	# Un chemin partiel n'est pas une réussite ; vérifier ses deux extrémités en X/Z.
	return _distance_sol(chemin[0], depart) < 0.7 and _distance_sol(chemin[-1], cible) < 0.7

static func _distance_sol(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
