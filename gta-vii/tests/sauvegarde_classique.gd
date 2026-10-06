extends SceneTree

var chemin := ProjectSettings.globalize_path("res://.godot/reprise_classique_test_%d.save" % OS.get_process_id())

func _initialize() -> void:
	verifier.call_deferred()

func verifier() -> void:
	create_timer(90.0).timeout.connect(func():
		push_error("Délai dépassé pour le test de reprise classique.")
		quit(1))
	var sauvegarde = root.get_node("SauvegardeClassique")
	sauvegarde.chemin_fichier = chemin
	sauvegarde.supprimer()
	var jeu = load("res://scenes/jeu/main.tscn").instantiate()
	jeu.get_node("Salles/RoomManager").nombre_etages = 1
	root.add_child(jeu)
	current_scene = jeu
	var gestion = jeu.get_node("Salles/RoomManager")
	await gestion.partie_prete
	paused = true
	assert(sauvegarde.disponible())
	var upgrades = jeu.get_node("UpgradeManager")
	upgrades.appliquer_amelioration(&"reserve")
	upgrades.appliquer_amelioration(&"mousse_protectrice")
	for protection in upgrades.boucliers_joueur: protection.bouclier_restant = 7.5
	var defis = upgrades.defis
	assert(defis.accepter(&"fragile"))
	assert(defis.accepter(&"sans_degats"))
	assert(defis.accepter(&"population"))
	var victime = jeu.get_node("VictimManager").freed_victims[0]
	victime.vie = 12.5
	jeu.get_node("player").BarreDeVie.value = 42.5
	jeu.get_node("player").extincteur.charge = 36.5
	jeu.get_node("Monnaie").solde = 123
	# Passer réellement à la salle suivante pour capturer les ajouts du défi de population.
	paused = false
	await gestion.activer_salle(1)
	paused = true
	var point = sauvegarde.dernier_point.duplicate(true)
	assert(point.indice == 1)
	var geometrie = gestion.salle_actuelle.points_spawn.duplicate()
	var duree: float = gestion.salle_actuelle.duree_sauvetage
	assert(sauvegarde.preparer_reprise())
	await process_frame
	current_scene = null
	jeu.free()
	await process_frame
	await process_frame
	paused = false
	jeu = load("res://scenes/jeu/main.tscn").instantiate()
	root.add_child(jeu)
	current_scene = jeu
	gestion = jeu.get_node("Salles/RoomManager")
	await gestion.partie_prete
	paused = true
	assert(gestion.indice_salle == 1)
	assert(gestion.nombre_etages == 1)
	assert(gestion.salle_actuelle.points_spawn == geometrie)
	assert(is_equal_approx(gestion.salle_actuelle.duree_sauvetage, duree))
	assert(is_equal_approx(jeu.get_node("player").BarreDeVie.value, point.joueur.vie))
	assert(is_equal_approx(jeu.get_node("player").extincteur.charge, point.joueur.arme.charge))
	assert(jeu.get_node("Monnaie").solde == 123)
	upgrades = jeu.get_node("UpgradeManager")
	assert(upgrades.acquisitions.size() == point.ameliorations.acquisitions.size())
	assert(is_equal_approx(upgrades.boucliers_joueur[0].bouclier_restant, 7.5))
	defis = upgrades.defis
	assert(defis.actifs.size() == 3)
	victime = jeu.get_node("VictimManager").freed_victims[0]
	assert(victime.defi_fragile and victime.points_boutique == 2)
	assert(is_equal_approx(victime.vie, point.escorte.victimes[0].vie))
	assert(defis.actifs[0].victime == victime)
	assert(sauvegarde.dernier_point.population == point.population)
	var carnet = jeu.get_node("MenuBonus")
	carnet._demander_retour_titre()
	assert("salle 2" in carnet.confirmation.get_node("Contenu/Marge/Disposition/Avertissement").text)
	carnet._annuler_retour_titre()
	print("REPRISE_CLASSIQUE_ETAT_PARCOURS_DEFIS_OK")
	await process_frame
	current_scene = null
	jeu.free()
	await process_frame
	paused = false
	var titre = load("res://scenes/interfaces/menus/ecran_titre.tscn").instantiate()
	root.add_child(titre)
	current_scene = titre
	assert(titre.get_node("%NouvellePartie").text == "Continuer")
	assert(titre.get_node("%SupprimerClassique").visible)
	titre.nouvelle_partie()
	while current_scene == null or current_scene == titre: await process_frame
	jeu = current_scene
	gestion = jeu.get_node("Salles/RoomManager")
	if not gestion.initialized or gestion.transition_en_cours: await gestion.partie_prete
	paused = true
	assert(gestion.indice_salle == 1)
	assert(is_equal_approx(jeu.get_node("player").BarreDeVie.value, point.joueur.vie))
	print("CONTINUER_CLASSIQUE_DEPUIS_TITRE_OK")
	await process_frame
	var zombie_avant: Dictionary = root.get_node("SauvegardeZombie").dernier_point.duplicate(true)
	jeu.get_node("player").mourir()
	assert(not sauvegarde.disponible())
	assert(root.get_node("SauvegardeZombie").dernier_point == zombie_avant)
	assert(sauvegarde.enregistrer(point))
	print("MORT_CLASSIQUE_ET_INDEPENDANCE_MODES_OK")
	current_scene = null
	jeu.free()
	await process_frame
	paused = false
	titre = load("res://scenes/interfaces/menus/ecran_titre.tscn").instantiate()
	root.add_child(titre)
	titre._demander_suppression("classique")
	titre._supprimer_sauvegarde()
	assert(not sauvegarde.disponible())
	assert(titre.get_node("%NouvellePartie").text == "Nouvelle partie")
	assert(not titre.get_node("%SupprimerClassique").visible)
	titre.free()
	print("TITRE_CLASSIQUE_ET_SUPPRESSION_OK")
	quit(0)
