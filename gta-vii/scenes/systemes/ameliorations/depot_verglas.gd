extends Node

@export_range(0.05, 0.5, 0.01) var intervalle_depot := 0.18
@export_range(0.5, 10.0, 0.1) var duree_trace := 4.0
@export_range(4, 24, 1) var segments_cone := 10
@export_flags_3d_physics var masque_obstacles := 1
@export_range(0.01, 0.2, 0.01) var tolerance_reutilisation := 0.04
var attente := 0.0
var precedentes: Array[Dictionary] = []
@onready var effets = get_parent()

func _ready() -> void:
	# Lire les portions après leur déplacement par l'extincteur.
	process_physics_priority = 2

func reinitialiser() -> void:
	precedentes.clear()
	attente = 0.0

func _physics_process(delta: float) -> void:
	attente -= delta
	if attente > 0.0 or effets.valeur("verglas") <= 0.0: return
	if effets.joueur.est_mort or effets.joueur.entree_automatique: return
	var arme = effets.gestion.extincteur
	if arme.portions_jet.is_empty(): return
	attente = intervalle_depot
	var directions: Array[Vector3] = [arme.direction_jet()]
	var angle: float = arme.demi_angle_jet
	if arme.double_lance:
		directions = [directions[0].rotated(Vector3.UP, deg_to_rad(angle * 0.65)), directions[0].rotated(Vector3.UP, deg_to_rad(-angle * 0.65))]
		angle *= 0.35
	var nouvelles: Array[Dictionary] = []
	for portion: Vector2 in arme.portions_jet:
		if portion.y - portion.x < 0.05: continue
		for direction in directions:
			var contour := _contour(arme.muzzle.global_position, direction, angle, portion)
			if contour.points.size() < 3: continue
			var origine: Vector3 = arme.muzzle.global_position
			var zone = _retrouver_trace(origine, contour.points, portion.y)
			if zone == null:
				# Le polygone est orienté dans le monde, pas attaché à la rotation du joueur.
				zone = effets.creer_zone(origine, "verglas", 0.0, portion.y, duree_trace, effets.valeur("verglas"), contour.points, contour.uv)
			elif is_instance_valid(zone):
				zone.temps = 0.0
			if zone != null:
				nouvelles.append({"origine": origine, "points": contour.points, "zone": weakref(zone)})
	precedentes = nouvelles

func _contour(origine: Vector3, axe: Vector3, angle: float, portion: Vector2) -> Dictionary:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var interieurs := PackedVector2Array()
	var uv_interieurs := PackedVector2Array()
	var surface_visible := false
	for i in range(segments_cone + 1):
		var fraction := float(i) / segments_cone
		var direction := axe.rotated(Vector3.UP, deg_to_rad(lerpf(-angle, angle, fraction)))
		var distance := portion.y
		var requete := PhysicsRayQueryParameters3D.create(origine, origine + direction * portion.y, masque_obstacles)
		var contact: Dictionary = effets.joueur.get_world_3d().direct_space_state.intersect_ray(requete)
		if not contact.is_empty(): distance = minf(distance, maxf(0.0, origine.distance_to(contact.position) - 0.03))
		# Un rayon bloqué avant la portion n'a aucune surface à déposer.
		# Ses deux bords se rejoignent, sans inverser le contour du polygone.
		if distance > portion.x + 0.01: surface_visible = true
		# Un écart d'un millimètre évite les sommets doublés à la triangulation.
		distance = maxf(portion.x + 0.001, distance)
		var proche := portion.x
		points.append(Vector2(direction.x, direction.z) * distance / portion.y)
		uv.append(Vector2(fraction, 1.0))
		if proche > 0.001:
			interieurs.append(Vector2(direction.x, direction.z) * proche / portion.y)
			uv_interieurs.append(Vector2(fraction, 0.0))
	if portion.x <= 0.001:
		points.append(Vector2.ZERO)
		uv.append(Vector2(0.5, 0.0))
	else:
		for i in range(interieurs.size() - 1, -1, -1):
			points.append(interieurs[i])
			uv.append(uv_interieurs[i])
	# Une portion entièrement derrière un mur ne doit pas produire de trace.
	if not surface_visible or Geometry2D.triangulate_polygon(points).is_empty(): points.clear()
	return {"points": points, "uv": uv}

func _retrouver_trace(origine: Vector3, points: PackedVector2Array, rayon: float) -> Area3D:
	for precedente in precedentes:
		var zone = precedente.zone.get_ref()
		if zone == null or zone.is_queued_for_deletion() or zone.temps > intervalle_depot * 2.0: continue
		if absf(zone.rayon - rayon) > tolerance_reutilisation: continue
		if origine.distance_to(precedente.origine) > tolerance_reutilisation or points.size() != precedente.points.size(): continue
		var identique := true
		for i in range(points.size()):
			if points[i].distance_to(precedente.points[i]) * zone.rayon > tolerance_reutilisation:
				identique = false
				break
		if identique: return zone
	return null
