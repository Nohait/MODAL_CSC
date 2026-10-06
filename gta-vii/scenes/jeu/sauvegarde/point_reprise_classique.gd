extends Node

const ETAT = preload("res://scenes/systemes/sauvegarde/etat_sauvegarde.gd")
const CHAMPS_JOUEUR = ["rotation", "last_direction", "dash_cooldown_left", "protection_secours"]
const CHAMPS_ARME = ["charge", "is_overheated", "attente_recharge", "attack_timer"]
var reprise: Dictionary = {}
var graines: Array = []
var graine_combat := 0
var mode_joueur := Node.PROCESS_MODE_INHERIT

func preparer_parcours(gestion: Node) -> void:
	reprise = SauvegardeClassique.consommer_reprise()
	if not reprise.is_empty():
		gestion.nombre_etages = reprise.etages
		graines = reprise.graines.duplicate()
	else:
		for i in range(gestion.nombre_salles): graines.append(randi())

func preparer_entree(gestion: Node) -> bool:
	if reprise.is_empty(): return true
	var niveau := get_parent()
	var joueur = gestion.joueur
	niveau.get_node("UpgradeManager").restaurer_sauvegarde(reprise.ameliorations)
	niveau.get_node("VictimManager").restaurer_sauvegarde(reprise.escorte, gestion.salle_actuelle)
	niveau.get_node("UpgradeManager/DefiManager").restaurer_sauvegarde(reprise.defis)
	_restaurer_population(gestion, reprise.population)
	ETAT.appliquer_champs(joueur, reprise.joueur, CHAMPS_JOUEUR)
	joueur.global_position = reprise.joueur.position
	joueur.velocity = Vector3.ZERO
	joueur.is_dashing = false
	joueur.BarreDeVie.value = reprise.joueur.vie
	ETAT.appliquer_champs(joueur.extincteur, reprise.joueur.arme)
	joueur.extincteur.vider_jet()
	var monnaie = niveau.get_node("Monnaie")
	monnaie.solde = reprise.pieces
	monnaie.compteur.text = str(monnaie.solde)
	monnaie.solde_change.emit(monnaie.solde)
	niveau.get_node("VictimManager").evacuated_count = reprise.get("evacuees", 0)
	niveau.get_node("CameraRig").recentrer()
	# Empêcher la recharge et les délais de protection de tourner derrière le fondu.
	mode_joueur = joueur.process_mode
	joueur.process_mode = Node.PROCESS_MODE_DISABLED
	return false

func commencer_salle(gestion: Node) -> void:
	if not reprise.is_empty():
		gestion.joueur.process_mode = mode_joueur
		graine_combat = reprise.graine_combat
		reprise = {}
	else:
		graine_combat = randi()
	var niveau := get_parent()
	var joueur = gestion.joueur
	var etat := ETAT.lire_champs(joueur, CHAMPS_JOUEUR)
	etat.position = joueur.global_position
	etat.vie = joueur.BarreDeVie.value
	etat.arme = ETAT.lire_champs(joueur.extincteur, CHAMPS_ARME)
	var point := {"version": SauvegardeClassique.VERSION, "indice": gestion.indice_salle,
		"etages": gestion.nombre_etages, "graines": graines.duplicate(), "graine_combat": graine_combat,
		"joueur": etat, "pieces": niveau.get_node("Monnaie").solde,
		"ameliorations": niveau.get_node("UpgradeManager").capturer_sauvegarde(),
		"escorte": niveau.get_node("VictimManager").capturer_sauvegarde(),
		"evacuees": niveau.get_node("VictimManager").evacuated_count,
		"defis": niveau.get_node("UpgradeManager/DefiManager").capturer_sauvegarde(),
		"population": _capturer_population(gestion.salle_actuelle)}
	if not SauvegardeClassique.enregistrer(point):
		gestion.afficher_message("Sauvegarde impossible · reprise non garantie")
	# Même durée de sauvetage et même planification des vagues lors d'une reprise.
	seed(graine_combat)

func _capturer_population(salle: Node3D) -> Dictionary:
	var victimes: Array[Dictionary] = []
	for victime in salle.get_node("Victimes").get_children():
		if victime.is_in_group("victime"):
			victimes.append({"position": victime.position, "vie": victime.vie, "vie_max": victime.vie_max})
	return {"mobiles": salle.mobiles_a_creer.duplicate(), "victimes": victimes}

func _restaurer_population(gestion: Node, population: Dictionary) -> void:
	var salle = gestion.salle_actuelle
	# Le défi de population a pu ajouter des captifs au-delà de la génération normale.
	for victime in salle.get_node("Victimes").get_children(): victime.free()
	salle.remaining_victims = 0
	for donnees in population.victimes:
		var victime = gestion.VICTIME_SCENE.instantiate()
		victime.vie_max = donnees.vie_max
		salle.get_node("Victimes").add_child(victime)
		victime.position = donnees.position
		victime.vie = donnees.vie
		victime.set_ennemis_container(salle.get_node("Ennemis"))
		gestion.victim_manager.surveiller_victime(victime)
		victime.freed.connect(gestion._on_victim_freed.bind(salle), CONNECT_ONE_SHOT)
		victime.died.connect(gestion._on_victim_died.bind(salle), CONNECT_ONE_SHOT)
		salle.remaining_victims += 1
	salle.mobiles_a_creer.assign(population.mobiles)
	salle.remaining_enemies = salle.get_node("Ennemis").get_child_count() + salle.mobiles_a_creer.size()
