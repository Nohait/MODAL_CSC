extends RefCounted
class_name PlanEspacesDecoratifs

var limites: Rect2
var libres: Array[Rect2] = []
var obstacles: Array[Rect2] = []
var reservations: Array[Dictionary] = []

func initialiser(generateur: Node3D, cadre: Rect2) -> void:
	limites = cadre
	libres.assign([cadre.grow(-0.15)])
	obstacles.clear()
	reservations.clear()
	# Réserver d'abord le parcours et les trous ; aucune annexe ne peut les remplir.
	for y in range(generateur.roomSize.y):
		for x in range(generateur.roomSize.x):
			if generateur.grid[y][x] or generateur.cellules_trous.has(Vector2i(x, y)):
				_bloquer(Rect2(Vector2(x, y) * 5.0 - Vector2.ONE * 2.5, Vector2.ONE * 5.0).grow(0.12))
	actualiser_obstacles(generateur)

func actualiser_obstacles(generateur: Node3D) -> void:
	# Inclure les couloirs et escaliers hors grille, puis les meubles ajoutés en cours de placement.
	for corps in generateur.salle_en_creation.get_node("Navigation/Decor").get_children():
		for collision in corps.get_children():
			if not collision is CollisionShape3D or collision.disabled or not collision.shape is BoxShape3D: continue
			var taille: Vector3 = collision.shape.size
			var boite: AABB = corps.transform * collision.transform * AABB(-taille / 2, taille)
			var zone := Rect2(Vector2(boite.position.x, boite.position.z), Vector2(boite.size.x, boite.size.z)).grow(0.03)
			if zone not in obstacles: _bloquer(zone)

func peut_placer(zones: Array[Rect2]) -> bool:
	if zones.is_empty(): return false
	for zone in zones:
		if not limites.grow(-0.2).encloses(zone): return false
		for obstacle in obstacles:
			if zone.intersects(obstacle): return false
	return true

func reserver(origine: String, zones: Array[Rect2]) -> void:
	reservations.append({"origine": origine, "zones": zones.duplicate()})
	for zone in zones: _bloquer(zone.grow(0.03))

static func empreintes(piece: Node3D, raccord_porte := false) -> Array[Rect2]:
	var zones: Array[Rect2] = []
	for surface in piece.surfaces():
		var boite: AABB = surface.transform * surface.get_aabb()
		if raccord_porte:
			# Le seuil d'une pièce préparée rejoint volontairement le mur de sa porte.
			var fin := minf(boite.end.z, -0.25)
			if fin <= boite.position.z: continue
			boite.size.z = fin - boite.position.z
		boite = piece.transform * boite
		zones.append(Rect2(Vector2(boite.position.x, boite.position.z), Vector2(boite.size.x, boite.size.z)))
	return zones

func espaces_restants() -> Array[Rect2]:
	var resultat: Array[Rect2] = libres.duplicate()
	var changement := true
	while changement:
		changement = false
		for i in range(resultat.size()):
			for j in range(i + 1, resultat.size()):
				var a := resultat[i]
				var b := resultat[j]
				var horizontal := is_equal_approx(a.position.y, b.position.y) and is_equal_approx(a.size.y, b.size.y) and (is_equal_approx(a.end.x, b.position.x) or is_equal_approx(b.end.x, a.position.x))
				var vertical := is_equal_approx(a.position.x, b.position.x) and is_equal_approx(a.size.x, b.size.x) and (is_equal_approx(a.end.y, b.position.y) or is_equal_approx(b.end.y, a.position.y))
				if not horizontal and not vertical: continue
				# Fusionner uniquement une union rectangulaire entièrement disponible.
				resultat[i] = a.merge(b)
				resultat.remove_at(j)
				changement = true
				break
			if changement: break
	return resultat

func _bloquer(obstacle: Rect2) -> void:
	obstacles.append(obstacle)
	var resultat: Array[Rect2] = []
	for zone in libres:
		var intersection := zone.intersection(obstacle)
		if not intersection.has_area():
			resultat.append(zone)
			continue
		# Ces quatre bandes couvrent le reste sans se chevaucher.
		var morceaux := [Rect2(zone.position, Vector2(zone.size.x, intersection.position.y - zone.position.y)), Rect2(Vector2(zone.position.x, intersection.end.y), Vector2(zone.size.x, zone.end.y - intersection.end.y)), Rect2(Vector2(zone.position.x, intersection.position.y), Vector2(intersection.position.x - zone.position.x, intersection.size.y)), Rect2(Vector2(intersection.end.x, intersection.position.y), Vector2(zone.end.x - intersection.end.x, intersection.size.y))]
		for morceau: Rect2 in morceaux:
			if morceau.size.x > 0.01 and morceau.size.y > 0.01: resultat.append(morceau)
	libres = resultat
