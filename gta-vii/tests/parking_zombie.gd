extends SceneTree

func _initialize() -> void:
	verifier.call_deferred()

func verifier() -> void:
	create_timer(60).timeout.connect(func():
		push_error("Délai dépassé pour le parking.")
		quit(1))
	var sauvegarde = root.get_node("SauvegardeZombie")
	sauvegarde.chemin_fichier = ProjectSettings.globalize_path("res://.godot/parking_test_%d.save" % OS.get_process_id())
	sauvegarde.supprimer()
	set_meta("map_zombie", "res://scenes/modes/zombie/maps/parking.tscn")
	var jeu = load("res://scenes/modes/zombie/mode_zombie.tscn").instantiate()
	root.add_child(jeu)
	current_scene = jeu
	var gestion = jeu.get_node("main/Salles/RoomManager")
	await gestion.partie_prete
	paused = true
	var salle = gestion.salle_actuelle
	assert(gestion.refuge.position == Vector3(0, 0, 12))
	assert(gestion.entrees.size() == 4)
	assert(salle.points_spawn.size() >= 40)
	# Les jets muraux doivent partir dans les allées, pas dans le noyau central.
	for nom in ["SprinklerOuest", "SprinklerEst"]:
		var sprinkler: Node3D = salle.get_node("Navigation/Decor/Equipements/" + nom)
		var jet: Node3D = sprinkler.get_node("Eau")
		assert(absf(jet.global_position.x) > 10.3)
		var zone: Node3D = sprinkler.get_node("Zone")
		assert(absf(zone.global_position.x) > absf(sprinkler.global_position.x))
	# Une ventilation laisse une ouverture haute, jamais un passage à pied dans le mur.
	var physique: PhysicsDirectSpaceState3D = salle.get_world_3d().direct_space_state
	for ouverture in [Vector3(-30, 1, -7), Vector3(30, 1, 18)]:
		var rayon := PhysicsRayQueryParameters3D.create(ouverture + Vector3.RIGHT * 2, ouverture - Vector3.RIGHT * 2, 1)
		assert(not physique.intersect_ray(rayon).is_empty())
	var carte: RID = salle.carte_ennemis
	var chemin := NavigationServer3D.map_get_path(carte, Vector3(-17, 0, -20), Vector3(17, 0, -20), true)
	assert(chemin.size() > 2)
	var contourne := false
	for point in chemin:
		if point.z > -5.75: contourne = true
	assert(contourne)
	# Aucun captif ne doit naître dans le noyau technique ni au-dessus d'une voiture.
	for point in salle.points_spawn:
		assert(not (absf(point.x) < 10 and point.z < -6))
		var proche := NavigationServer3D.map_get_closest_point(carte, point)
		assert(proche.distance_to(point) < 1.1)
	assert(sauvegarde.dernier_point.map == "res://scenes/modes/zombie/maps/parking.tscn")
	gestion.liberer_salle_debug()
	assert(sauvegarde.preparer_reprise())
	await process_frame
	current_scene = null
	jeu.free()
	await process_frame
	await process_frame
	paused = false
	jeu = load("res://scenes/modes/zombie/mode_zombie.tscn").instantiate()
	root.add_child(jeu)
	current_scene = jeu
	gestion = jeu.get_node("main/Salles/RoomManager")
	await gestion.partie_prete
	paused = true
	assert(gestion.salle_actuelle.scene_file_path.ends_with("parking.tscn"))
	assert(gestion.refuge.position == Vector3(0, 0, 12))
	assert(gestion.vague_actuelle == 1)
	sauvegarde.supprimer()
	print("PARKING_NAVIGATION_ENTREES_REPRISE_OK")
	await process_frame
	current_scene = null
	jeu.free()
	quit(0)
