extends RefCounted

static func choisir(ennemi: Node3D, cible: Node3D, portee: float) -> Node3D:
	var resultat := cible if is_instance_valid(cible) and not cible.is_queued_for_deletion() else null
	var distance := minf(portee, ennemi.global_position.distance_to(resultat.global_position)) if resultat != null else portee
	for leurre in ennemi.get_tree().get_nodes_in_group("leurres_mousse"):
		if leurre.is_queued_for_deletion() or leurre.termine: continue
		var ecart: float = ennemi.global_position.distance_to(leurre.global_position)
		if ecart > distance or ecart > leurre.rayon_attraction: continue
		var rayon := PhysicsRayQueryParameters3D.create(ennemi.global_position + Vector3.UP * 0.5, leurre.global_position + Vector3.UP * 0.5, 1)
		rayon.exclude = [ennemi.get_rid()]
		if not ennemi.get_world_3d().direct_space_state.intersect_ray(rayon).is_empty(): continue
		resultat = leurre
		distance = ecart
	return resultat

static func frapper(cible: Node3D, degats: float, auteur: Node3D) -> void:
	if not is_instance_valid(cible) or cible.is_queued_for_deletion(): return
	if cible.is_in_group("leurres_mousse"):
		cible.recevoir_coup(auteur if is_instance_valid(auteur) else null)
	else:
		cible.prendre_degats(degats)
