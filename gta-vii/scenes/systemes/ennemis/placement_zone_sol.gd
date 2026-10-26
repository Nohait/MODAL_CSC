extends RefCounted

const COUCHE_DECOR := 1
const HAUTEUR_RAYON := 0.5
const PROFONDEUR_RAYON := 5.0

static func hauteur_locale(corps: Node3D, marge_monde: float, repli: float) -> float:
	if corps.is_inside_tree():
		var origine := corps.global_position + Vector3.UP * HAUTEUR_RAYON
		var destination := corps.global_position + Vector3.DOWN * PROFONDEUR_RAYON
		var requete := PhysicsRayQueryParameters3D.create(origine, destination)
		requete.collision_mask = COUCHE_DECOR
		requete.collide_with_areas = false
		if corps is CollisionObject3D:
			requete.exclude = [corps.get_rid()]
		var contact := corps.get_world_3d().direct_space_state.intersect_ray(requete)
		if not contact.is_empty():
			return corps.to_local(contact.position + Vector3.UP * marge_monde).y
	return _hauteur_collision(corps, marge_monde, repli)

static func _hauteur_collision(corps: Node3D, marge_monde: float, repli: float) -> float:
	var collision := corps.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or collision.shape == null:
		return repli
	var demi_hauteur := 0.0
	if collision.shape is CapsuleShape3D:
		demi_hauteur = collision.shape.height * 0.5
	elif collision.shape is SphereShape3D:
		demi_hauteur = collision.shape.radius
	elif collision.shape is BoxShape3D:
		demi_hauteur = collision.shape.size.y * 0.5
	else:
		return repli
	var echelle_y := maxf(absf(corps.global_transform.basis.get_scale().y), 0.001)
	return collision.position.y - demi_hauteur + marge_monde / echelle_y
