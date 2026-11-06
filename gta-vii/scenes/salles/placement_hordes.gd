extends Resource

@export var actif := true
## Total prévu à l'entrée : mobiles, tourelles et flaques, sans les victimes.
@export_range(2, 100, 1) var seuil_population := 8
@export_range(2, 10, 1) var taille_min_vague := 2
@export_range(2.0, 8.0, 0.25) var rayon := 3.5
@export_range(1.5, 4.0, 0.1) var espacement := 2.2
## Volume libre conservateur pour les différents mobiles du catalogue classique.
@export_range(0.5, 2.0, 0.05) var rayon_collision := 0.95
@export_range(1.0, 4.0, 0.1) var hauteur_collision := 2.6
@export_range(0.1, 1.0, 0.05) var tolerance_navigation := 0.35
## Neuf candidats par case de 5 m : centre, côtés et diagonales.
## La collision décide lesquels peuvent être occupés simultanément.
@export_range(0.8, 1.6, 0.1) var ecartement_points := 1.4

func est_active(population: int) -> bool:
	return actif and population >= seuil_population

func points_mobiles(centres: Array[Vector3]) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for centre in centres:
		points.append(centre)
		for z in [-1, 0, 1]:
			for x in [-1, 0, 1]:
				if x != 0 or z != 0:
					points.append(centre + Vector3(x, 0, z) * ecartement_points)
	return points

func placer(origines: Array[Vector3], reserves: Array[Vector3], salle: Node3D, carte: RID, joueur: Vector3, distance_joueur: float, nombre := -1, regrouper := true) -> Array[Vector3]:
	if nombre < 0: nombre = origines.size()
	if nombre == 0 or not carte.is_valid() or NavigationServer3D.map_get_iteration_id(carte) == 0:
		return []
	var espace := salle.get_world_3d().direct_space_state
	var requete := _requete_volume()
	var meilleur: Array[Vector3] = []
	var candidats := points_mobiles(origines)
	var contacts: Dictionary = {}
	var centres: Array[Vector3] = []
	if regrouper and nombre > 1:
		centres.assign(candidats)
	for origine in centres:
		var centre := salle.to_global(origine)
		if not _espacement_libre(salle, centre, reserves): continue
		if not contacts.has(origine): contacts[origine] = _contact_libre(salle, carte, centre, joueur, distance_joueur, requete)
		if contacts[origine].is_empty(): continue
		var groupe: Array[Vector3] = [origine]
		for point in candidats:
			var candidat := salle.to_global(point)
			if candidat.distance_squared_to(centre) > rayon * rayon: continue
			if not _espacement_libre(salle, candidat, groupe) or not _espacement_libre(salle, candidat, reserves): continue
			# Une même position n'interroge la physique qu'une fois pour toute la vague.
			if not contacts.has(point): contacts[point] = _contact_libre(salle, carte, candidat, joueur, distance_joueur, requete)
			var sol: Dictionary = contacts[point]
			if sol.is_empty(): continue
			var surface: Vector3 = sol.position
			# Ne pas constituer une horde à cheval sur un mur ou autour d'un grand trou.
			if not groupe.is_empty():
				var premier := salle.to_global(groupe[0])
				premier.y = surface.y
				var obstacle := espace.intersect_ray(PhysicsRayQueryParameters3D.create(premier + Vector3.UP, surface + Vector3.UP, 1))
				if not obstacle.is_empty(): continue
				var trajet := NavigationServer3D.map_get_path(carte, premier, surface, true)
				if trajet.is_empty(): continue
				var longueur := 0.0
				for j in range(1, trajet.size()): longueur += trajet[j - 1].distance_to(trajet[j])
				if longueur > premier.distance_to(surface) + tolerance_navigation * 2.0: continue
			groupe.append(point)
			if groupe.size() == nombre: return groupe
		if groupe.size() > meilleur.size(): meilleur = groupe
	# Si une horde complète ne tient pas, compléter avec les autres points sûrs.
	# Un résultat partiel laisse le reste de la vague en attente.
	for origine in candidats:
		var candidat := salle.to_global(origine)
		if not _espacement_libre(salle, candidat, meilleur) or not _espacement_libre(salle, candidat, reserves): continue
		if not contacts.has(origine): contacts[origine] = _contact_libre(salle, carte, candidat, joueur, distance_joueur, requete)
		if contacts[origine].is_empty(): continue
		meilleur.append(origine)
		if meilleur.size() == nombre: break
	return meilleur

func emplacement_libre(salle: Node3D, carte: RID, emplacement: Vector3, joueur: Vector3, distance_joueur: float) -> bool:
	if not carte.is_valid() or NavigationServer3D.map_get_iteration_id(carte) == 0: return false
	return not _contact_libre(salle, carte, salle.to_global(emplacement), joueur, distance_joueur, _requete_volume()).is_empty()

func _requete_volume() -> PhysicsShapeQueryParameters3D:
	var volume := CylinderShape3D.new()
	volume.radius = rayon_collision
	volume.height = maxf(hauteur_collision, rayon_collision * 2.0)
	var requete := PhysicsShapeQueryParameters3D.new()
	requete.shape = volume
	requete.collision_mask = 15 # Décor, joueur, ennemis et victimes.
	return requete

func _contact_libre(salle: Node3D, carte: RID, candidat: Vector3, joueur: Vector3, distance_joueur: float, requete: PhysicsShapeQueryParameters3D) -> Dictionary:
	if not _assez_loin(candidat, joueur, distance_joueur): return {}
	var espace := salle.get_world_3d().direct_space_state
	var sol := espace.intersect_ray(PhysicsRayQueryParameters3D.create(candidat + Vector3.UP * 3.0, candidat - Vector3.UP * 2.0, 1))
	if sol.is_empty() or sol.normal.y < 0.9: return {}
	var surface: Vector3 = sol.position
	var ecart := NavigationServer3D.map_get_closest_point(carte, surface) - surface
	# La cuisson relève le maillage par pas de hauteur : ce décalage n'est pas un trou.
	var marge_verticale := maxf(tolerance_navigation, NavigationServer3D.map_get_cell_height(carte) * 2.0)
	if absf(ecart.y) > marge_verticale: return {}
	ecart.y = 0.0
	if ecart.length() > tolerance_navigation: return {}
	var volume := requete.shape as CylinderShape3D
	requete.transform = Transform3D(Basis.IDENTITY, surface + Vector3.UP * (volume.height * 0.5 + 0.05))
	if not espace.intersect_shape(requete, 1).is_empty(): return {}
	return sol

func _espacement_libre(salle: Node3D, candidat: Vector3, reserves: Array[Vector3]) -> bool:
	for point in reserves:
		if not _assez_loin(candidat, salle.to_global(point), maxf(espacement, rayon_collision * 2.0)): return false
	return true

func _assez_loin(a: Vector3, b: Vector3, minimum: float) -> bool:
	var ecart := Vector2(a.x - b.x, a.z - b.z)
	return ecart.length_squared() >= minimum * minimum
