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
@export_range(8, 64, 1) var essais_par_centre := 32

func est_active(population: int) -> bool:
	return actif and population >= seuil_population

func placer(origines: Array[Vector3], reserves: Array[Vector3], salle: Node3D, carte: RID, joueur: Vector3, distance_joueur: float) -> Array[Vector3]:
	if origines.size() < 2 or not carte.is_valid() or NavigationServer3D.map_get_iteration_id(carte) == 0:
		return origines
	var espace := salle.get_world_3d().direct_space_state
	var volume := CylinderShape3D.new()
	volume.radius = rayon_collision
	volume.height = maxf(hauteur_collision, rayon_collision * 2.0)
	var requete := PhysicsShapeQueryParameters3D.new()
	requete.shape = volume
	requete.collision_mask = 15 # Décor, joueur, ennemis et victimes.
	for origine in origines:
		var centre := salle.to_global(origine)
		var groupe: Array[Vector3] = []
		for i in range(essais_par_centre + 1):
			# Une spirale déterministe teste d'abord le centre, puis sa proximité.
			var distance := rayon * sqrt(float(i) / essais_par_centre)
			var angle := i * PI * (3.0 - sqrt(5.0))
			var candidat := centre + Vector3(cos(angle), 0.0, sin(angle)) * distance
			if not _assez_loin(candidat, joueur, distance_joueur): continue
			var libre := true
			for point in groupe:
				if not _assez_loin(candidat, salle.to_global(point), maxf(espacement, rayon_collision * 2.0)):
					libre = false
					break
			if not libre: continue
			for point in reserves:
				if not _assez_loin(candidat, salle.to_global(point), maxf(espacement, rayon_collision * 2.0)):
					libre = false
					break
			if not libre: continue
			var sol := espace.intersect_ray(PhysicsRayQueryParameters3D.create(candidat + Vector3.UP * 3.0, candidat - Vector3.UP * 2.0, 1))
			if sol.is_empty() or sol.normal.y < 0.9: continue
			var surface: Vector3 = sol.position
			var navigable := NavigationServer3D.map_get_closest_point(carte, surface)
			if navigable.distance_to(surface) > tolerance_navigation: continue
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
			requete.transform = Transform3D(Basis.IDENTITY, surface + Vector3.UP * (volume.height * 0.5 + 0.05))
			if not espace.intersect_shape(requete, 1).is_empty(): continue
			# Conserver la hauteur de référence des points initiaux et le décalage propre au modèle.
			candidat.y = centre.y
			groupe.append(salle.to_local(candidat))
			if groupe.size() == origines.size(): return groupe
	# Ne jamais perdre un ennemi ni forcer une apparition dans un obstacle.
	return origines

func _assez_loin(a: Vector3, b: Vector3, minimum: float) -> bool:
	var ecart := Vector2(a.x - b.x, a.z - b.z)
	return ecart.length_squared() >= minimum * minimum
