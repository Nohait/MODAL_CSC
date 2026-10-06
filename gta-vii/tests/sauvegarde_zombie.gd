extends SceneTree
var chemin := ProjectSettings.globalize_path("res://.godot/gta_vii_reprise_test_%d.save" % OS.get_process_id())
func _initialize() -> void:
	verifier.call_deferred()
func verifier() -> void:
	create_timer(60.0).timeout.connect(func():
		push_error("Le test de reprise a dépassé son délai.")
		quit(1))
	var sauvegarde = root.get_node("SauvegardeZombie")
	sauvegarde.chemin_fichier = chemin
	sauvegarde.supprimer()
	var jeu = load("res://scenes/modes/zombie/mode_zombie.tscn").instantiate()
	root.add_child(jeu)
	current_scene = jeu
	var gestion = jeu.get_node("main/Salles/RoomManager")
	await gestion.partie_prete
	paused = true
	assert(sauvegarde.disponible())
	assert(sauvegarde.dernier_point.vague == 1)
	var niveau = jeu.get_node("main")
	var ameliorations = niveau.get_node("UpgradeManager")
	ameliorations.appliquer_amelioration(&"jet_givre")
	ameliorations.appliquer_amelioration(&"reserve")
	ameliorations.appliquer_amelioration(&"bouclier_camion")
	ameliorations.appliquer_amelioration(&"mousse_protectrice")
	ameliorations.appliquer_amelioration(&"dash_assaut")
	ameliorations.appliquer_amelioration(&"freinage_urgence")
	assert(not ameliorations.synergy_manager.decouvertes.is_empty())
	var joueur = niveau.get_node("player")
	joueur.BarreDeVie.value = 42.5
	joueur.extincteur.charge = 36.5
	for protection in ameliorations.boucliers_joueur: protection.bouclier_restant = 7.5
	for protection in gestion.refuge.boucliers: protection.bouclier_restant = 13.5
	var escort = niveau.get_node("VictimManager")
	var victime = load("res://scenes/victimes/victime.tscn").instantiate()
	gestion.salle_actuelle.get_node("Victimes").add_child(victime)
	escort.surveiller_victime(victime)
	victime.vie = 21.5
	victime.free_victim()
	victime.set_meta("extraction_utilisee", true)
	gestion.refuge.victimes.assign([{"vie": 17.25, "vie_max": 100.0, "ordre": 0}])
	var sprinkler = get_first_node_in_group("sprinkler")
	sprinkler.armer()
	var mural = get_first_node_in_group("extincteur_mural")
	mural.disponible = false
	var monnaie = niveau.get_node("Monnaie")
	monnaie.solde = 123
	var arene = niveau.get_node("ArenaEventManager")
	var palier = arene.paliers[0]
	arene._appliquer(palier, gestion.salle_actuelle.get_node(palier.cible))
	arene.effectues[palier] = true
	gestion.vague_actuelle = 6
	gestion.vagues_terminees = 5
	var point = niveau.get_node("PointRepriseZombie")
	assert(point.enregistrer(gestion, gestion.difficulte.composition_classique, 123456))
	var debut = sauvegarde.dernier_point.duplicate(true)
	assert(debut.escorte.victimes[0].vie == 21.5)
	var comptes = debut.statistiques.duplicate(true)
	# Changer les valeurs en combat ne doit pas toucher au point déjà écrit.
	joueur.BarreDeVie.value = 2.0
	monnaie.solde = 9999
	gestion.refuge.victimes.clear()
	assert(sauvegarde.preparer_reprise())
	assert(sauvegarde.reprise.joueur.vie == 42.5)
	current_scene = null
	jeu.queue_free()
	await process_frame
	await process_frame
	jeu = load("res://scenes/modes/zombie/mode_zombie.tscn").instantiate()
	root.add_child(jeu)
	current_scene = jeu
	gestion = jeu.get_node("main/Salles/RoomManager")
	paused = false
	await gestion.partie_prete
	paused = true
	niveau = jeu.get_node("main")
	joueur = niveau.get_node("player")
	ameliorations = niveau.get_node("UpgradeManager")
	assert(gestion.vague_actuelle == 6)
	assert(gestion.vagues_terminees == 5)
	assert(joueur.BarreDeVie.value == 42.5)
	assert(is_equal_approx(joueur.extincteur.charge, 36.5))
	assert(niveau.get_node("Monnaie").solde == 123)
	assert(gestion.refuge.victimes[0].vie == 17.25)
	assert(gestion.refuge.boucliers[0].bouclier_restant == 13.5)
	assert(ameliorations.boucliers_joueur[0].bouclier_restant == 7.5)
	assert(not ameliorations.synergy_manager.decouvertes.is_empty())
	assert(ameliorations.synergy_manager.en_attente.is_empty())
	escort = niveau.get_node("VictimManager")
	assert(escort.freed_victims.size() == 1)
	assert(escort.freed_victims[0].vie == 21.5)
	assert(escort.freed_victims[0].has_meta("extraction_utilisee"))
	assert(get_first_node_in_group("sprinkler").arme)
	assert(not get_first_node_in_group("extincteur_mural").disponible)
	assert(niveau.get_node("ArenaEventManager").effectues.has(niveau.get_node("ArenaEventManager").paliers[0]))
	assert(sauvegarde.dernier_point.graine == 123456)
	assert(sauvegarde.dernier_point.statistiques == comptes)
	assert(ameliorations.acquisitions.size() == debut.ameliorations.acquisitions.size())
	var carnet = niveau.get_node("MenuBonus")
	carnet._demander_retour_titre()
	assert(carnet.confirmation.get_node("Contenu/Marge/Disposition/Avertissement").text.contains("vague 6"))
	carnet._annuler_retour_titre()
	print("REPRISE_ZOMBIE_ETAT_COMPLET_OK")
	gestion.vague_actuelle = 7
	assert(niveau.get_node("PointRepriseZombie").enregistrer(gestion, gestion.difficulte.composition_classique, 654321))
	assert(sauvegarde.dernier_point.vague == 7)
	sauvegarde.dernier_point.clear()
	sauvegarde.charger()
	assert(sauvegarde.dernier_point.vague == 7)
	# Un fichier interrompu retombe sur le point complet précédent.
	var fichier := FileAccess.open(chemin, FileAccess.WRITE)
	fichier.store_string("interruption")
	fichier.close()
	sauvegarde.charger()
	assert(sauvegarde.disponible())
	assert(sauvegarde.dernier_point.vague == 6)
	print("RECUPERATION_FICHIER_INTERRUPPU_OK")
	joueur.mourir()
	assert(not sauvegarde.disponible())
	assert(not FileAccess.file_exists(chemin))
	print("MORT_TERMINE_LA_SAUVEGARDE_OK")
	assert(sauvegarde.supprimer())
	print("SUPPRESSION_SAUVEGARDE_OK")
	quit()
