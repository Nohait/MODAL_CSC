extends RefCounted

const MOUSSE = preload("res://scenes/effets/combat/impact_mousse.tscn")
const CENDRES = preload("res://scenes/effets/combat/disparition_cendres.tscn")


static func creer_impact(cible: Node3D, depart_jet: Vector3) -> void:
	var normale := depart_jet - cible.global_position
	normale.y = 0.0
	if normale.length_squared() < 0.001:
		return
	normale = normale.normalized()
	var position_impact := cible.global_position + normale * minf(cible.hitbox_radius, 0.45)
	position_impact.y = depart_jet.y
	# Le rayon sert seulement à placer l'effet sur la collision, jamais à décider des dégâts.
	var requete := PhysicsRayQueryParameters3D.create(depart_jet, cible.global_position, cible.collision_layer)
	requete.collide_with_areas = true
	var contact := cible.get_world_3d().direct_space_state.intersect_ray(requete)
	if not contact.is_empty() and contact.collider == cible:
		position_impact = contact.position
	var effet = MOUSSE.instantiate()
	cible.get_parent().add_child(effet)
	effet.global_position = position_impact
	effet.lancer(normale)


static func creer_cendres(cible: Node3D, racines: Array[Node3D], duree: float) -> void:
	var effet = CENDRES.instantiate()
	effet.duree = duree
	# L'effet devient un voisin de l'ennemi : il survit à queue_free, mais pas à la salle.
	cible.get_parent().add_child(effet)
	effet.global_position = cible.global_position
	effet.capturer(racines)
	effet.lancer()
