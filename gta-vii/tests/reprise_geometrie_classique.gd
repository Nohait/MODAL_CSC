extends SceneTree

var jeu: Node3D
var gestion: Node
var sauvegarde: Node

func _initialize() -> void:
	verifier.call_deferred()

func _charger() -> void:
	jeu = load("res://scenes/jeu/main.tscn").instantiate()
	jeu.get_node("Salles/RoomManager").nombre_etages = 2
	root.add_child(jeu)
	current_scene = jeu
	gestion = jeu.get_node("Salles/RoomManager")
	await gestion.partie_prete
	paused = true

func _fermer() -> void:
	current_scene = null
	jeu.free()
	jeu = null
	gestion = null
	await process_frame
	await process_frame
	paused = false

func _exiger(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func _verifier_sol() -> bool:
	var joueur: CharacterBody3D = jeu.get_node("player")
	if not _exiger(jeu.get_node("PointRepriseClassique")._sur_sol_jouable(joueur, gestion.salle_actuelle), "Pas de sol jouable sous le joueur : %s" % joueur.global_position): return false
	var debut := joueur.global_position
	# Le joueur simule réellement plusieurs images, sans lancer le combat ni l'escorte.
	gestion.salle_actuelle.get_node("Ennemis").process_mode = Node.PROCESS_MODE_DISABLED
	gestion.salle_actuelle.get_node("Victimes").process_mode = Node.PROCESS_MODE_DISABLED
	jeu.get_node("Escorte").process_mode = Node.PROCESS_MODE_DISABLED
	paused = false
	for image in range(12): await physics_frame
	paused = true
	if not _exiger(joueur.is_on_floor(), "Joueur hors du sol après simulation : %s -> %s" % [debut, joueur.global_position]): return false
	return _exiger(absf(joueur.global_position.y - debut.y) < 0.1, "Déplacement vertical excessif après la reprise.")

func _verifier_position(attendue: Vector3) -> bool:
	var actuelle: Vector3 = jeu.get_node("player").global_position
	# La marge de collision relève la capsule de quelques millimètres à la restauration.
	print("POSITION_REPRISE : attendue=%s, obtenue=%s" % [attendue, actuelle])
	return _exiger(actuelle.distance_to(attendue) < 0.01, "La reprise a déplacé le joueur hors de sa position sauvegardée.")

func verifier() -> void:
	create_timer(120.0).timeout.connect(func():
		push_error("Délai dépassé pour la reprise géométrique classique.")
		quit(1))
	sauvegarde = root.get_node("SauvegardeClassique")
	sauvegarde.chemin_fichier = "user://reprise_geometrie_test.save"
	sauvegarde.supprimer()
	await _charger()
	var maximum: Vector2i = gestion.generateur.roomSizeMax
	jeu.get_node("PointRepriseClassique").graines[6] = 2790730209
	paused = false
	await gestion.activer_salle(5)
	var tutoriel: Control = gestion.get_node("InterfaceSalle/HUD/Bouche_Incendie")
	if tutoriel.visible:
		tutoriel.call("fermer")
		await process_frame
	await gestion.activer_salle(6)
	paused = true
	if not _exiger(gestion.generateur.roomSizeMax == maximum, "Les limites du générateur ont été modifiées."): return
	var geometrie: Array = gestion.salle_actuelle.points_spawn.duplicate()
	var entree: Transform3D = gestion.salle_actuelle.entree.global_transform
	var point: Dictionary = sauvegarde.dernier_point.duplicate(true)
	if not _exiger(point.has("limites_generation"), "Limites de génération absentes de la sauvegarde."): return
	if not await _verifier_sol(): return
	if not _exiger(sauvegarde.preparer_reprise(), "Reprise indisponible."): return
	await _fermer()
	await _charger()
	if not _exiger(gestion.salle_actuelle.points_spawn == geometrie, "La géométrie a changé à la reprise."): return
	if not _exiger(gestion.salle_actuelle.entree.global_transform.is_equal_approx(entree), "L'entrée a changé à la reprise."): return
	if not _verifier_position(point.joueur.position): return
	if not await _verifier_sol(): return
	print("REPRISE_GEOMETRIE_ETAGE_2_OK")
	await _fermer()

	# Une position devenue invalide doit revenir au seuil, sans modifier les PV ni les cartes.
	point.joueur.position = Vector3(4000, -10, 4000)
	if not _exiger(sauvegarde.enregistrer(point), "Échec d'écriture du point de test."): return
	if not _exiger(sauvegarde.preparer_reprise(), "Point de test indisponible."): return
	await _charger()
	if not _exiger(jeu.get_node("player").BarreDeVie.value == point.joueur.vie, "Les PV ont changé à la reprise."): return
	if not _exiger(gestion.salle_actuelle.points_spawn == geometrie, "La géométrie a changé au retour au seuil."): return
	if not await _verifier_sol(): return
	print("REPRISE_POSITION_INVALIDE_SECURISÉE_OK")
	await _fermer()

	# Le lanceur QA peut fournir une copie ancienne ; aucun accès aux données réelles ici.
	if FileAccess.file_exists("res://qa/reprise_reference.save"):
		var ancien: Dictionary = sauvegarde._lire("res://qa/reprise_reference.save")
		if not _exiger(not ancien.is_empty() and not ancien.has("limites_generation"), "Référence ancienne absente ou invalide."): return
		if not _exiger(sauvegarde.enregistrer(ancien), "Échec d'écriture de la copie ancienne."): return
		if not _exiger(sauvegarde.preparer_reprise(), "Copie ancienne indisponible."): return
		await _charger()
		if not _verifier_position(ancien.joueur.position): return
		if not _exiger(sauvegarde.dernier_point.population == ancien.population, "La population sauvegardée a changé."): return
		for emplacement in ancien.population.mobiles:
			if not _exiger(gestion.salle_actuelle.points_spawn.has(emplacement), "Ancien emplacement d'ennemi hors du plan reconstruit : %s" % emplacement): return
		if not await _verifier_sol(): return
		print("REPRISE_REFERENCE_ANCIENNE_OK")
		await _fermer()
	sauvegarde.supprimer()
	print("REPRISE_SOL_CLASSIQUE_OK")
	quit(0)
