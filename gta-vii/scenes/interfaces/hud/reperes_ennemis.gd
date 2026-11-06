extends Control

@export var couleur := Color("ff2424")
@export var couleur_contour := Color.BLACK
@export_range(1.0, 4.0, 0.5) var epaisseur_contour := 2.0
@export_range(8.0, 28.0, 1.0) var taille_fleche := 14.0
@export_range(16.0, 100.0, 1.0) var marge := 28.0
@export_range(0.0, 4.0, 0.1) var hauteur_repere := 1.8
@export_range(0.05, 1.0, 0.05) var intervalle_recherche := 0.2

var joueur: Node3D
var ennemis: Array[WeakRef] = []
var attente_recherche := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	visible = is_instance_valid(joueur) and joueur.is_inside_tree() and joueur.is_visible_in_tree()
	if visible:
		visible = not get_tree().paused and joueur.can_process() and not joueur.get("est_mort")
	if not visible:
		attente_recherche = 0.0
		return
	attente_recherche -= delta
	if attente_recherche <= 0.0:
		attente_recherche = intervalle_recherche
		ennemis.clear()
		# Les références faibles ne retiennent pas les ennemis d'une salle quittée.
		for ennemi in get_tree().get_nodes_in_group("enemies"):
			if _admissible(ennemi):
				ennemis.append(weakref(ennemi))
	queue_redraw()

func _admissible(ennemi: Node) -> bool:
	return is_instance_valid(ennemi) and ennemi is Node3D \
		and ennemi.is_inside_tree() and not ennemi.is_queued_for_deletion() \
		and ennemi.get_viewport() == get_viewport() \
		and ennemi.is_visible_in_tree() and ennemi.can_process() \
		and not ennemi.get("est_mort")

func _projection(camera: Camera3D, monde: Vector3) -> Dictionary:
	# La projection de la caméra est en pixels du viewport, le dessin en coordonnées locales.
	var inverse := get_global_transform_with_canvas().affine_inverse()
	var projection := inverse * camera.unproject_position(monde)
	var cadre := Rect2(Vector2.ZERO, size)
	var zone := cadre.grow(-marge)
	var centre := zone.get_center()
	var derriere := camera.is_position_behind(monde)
	var hors_champ := derriere or not cadre.has_point(projection)
	var direction := Vector2.UP
	if hors_champ:
		var vers_bord := projection - centre
		# Seule la perspective inverse la projection des points derrière la caméra.
		if derriere and camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
			vers_bord = -vers_bord
		if vers_bord.is_zero_approx():
			vers_bord = Vector2.DOWN
		direction = vers_bord.normalized()
		var distance_bord := minf(zone.size.x * 0.5 / maxf(absf(direction.x), 0.001), zone.size.y * 0.5 / maxf(absf(direction.y), 0.001))
		projection = centre + direction * distance_bord
	else:
		projection = projection.clamp(zone.position, zone.end)
	return {"position": projection, "direction": direction, "hors_champ": hors_champ}

func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or size.x <= marge * 2.0 or size.y <= marge * 2.0:
		return
	for reference in ennemis:
		var ennemi: Node3D = reference.get_ref()
		# Une mort est prise en compte au prochain dessin, sans attendre la recherche périodique.
		if not _admissible(ennemi):
			continue
		var repere := _projection(camera, ennemi.global_position + Vector3.UP * hauteur_repere)
		var centre: Vector2 = repere.position
		if repere.hors_champ:
			var direction: Vector2 = repere.direction
			var cote := direction.orthogonal() * taille_fleche * 0.35
			var pointe := centre + direction * taille_fleche * 0.5
			var base := centre - direction * taille_fleche * 0.5
			var points := PackedVector2Array([pointe, base + cote, base - cote])
			draw_colored_polygon(points, couleur)
			points.append(pointe)
			draw_polyline(points, couleur_contour, epaisseur_contour, true)
