extends Node3D

signal consigne_changee
signal salle_reussie
@export_range(1.5, 4.0, 0.1) var distance_ouverture_sortie := 2.4
const SBIRE = preload("res://scenes/ennemis/mobiles/sbire.tscn")
const COMMANDE = preload("res://scenes/interfaces/libelle_commande.gd")
var progression = preload("res://scenes/modes/tutoriel/08_sauvetage_sous_menace/progression_sauvetage_sous_menace.gd").new()
var decor
var joueur
var escorte
var victime
var ennemi
var rappel := ""
var temps_rappel := 0.0
var vie_precedente := 100.0
var victime_blessee := false
var interface_echec
var cartes_depart: Dictionary
var ouverture_en_cours := false
var sortie_en_cours := false
var instructeur: Node3D
var depart_victime := Vector3.ZERO

func preparer(personnage, gestion_escorte, ameliorations) -> void:
	joueur = personnage
	escorte = gestion_escorte
	cartes_depart = ameliorations.capturer_sauvegarde().duplicate(true)
	decor = preload("res://scenes/modes/tutoriel/08_sauvetage_sous_menace/decor_sauvetage_sous_menace.gd").new()
	add_child(decor)
	instructeur = preload("res://scenes/modes/tutoriel/commun/figurants/figurant_pompier.gd").new()
	instructeur.position = Vector3(3, 1, -51)
	add_child(instructeur)
	instructeur.installer_modele(joueur)
	victime = preload("res://scenes/victimes/victime.tscn").instantiate()
	victime.position = Vector3(-2, 0.75, -51)
	add_child(victime)
	victime.set_ennemis_container(decor.ennemis)
	escorte.surveiller_victime(victime)
	victime.freed.connect(_liberee, CONNECT_ONE_SHOT)
	victime.died.connect(_perte_victime, CONNECT_ONE_SHOT)
	vie_precedente = victime.vie
	ennemi = SBIRE.instantiate()
	ennemi.position = Vector3(3, 0, -58)
	ennemi.vie_max = 65.0
	ennemi.vitesse_sbire = 2.4
	ennemi.degats_sbire = 8.0
	ennemi.duree_preparation = 0.6
	ennemi.attaque_cooldown = 1.4
	ennemi.distance_detection = 12.0
	ennemi.collision_layer = 0
	ennemi.remove_from_group("enemies")
	var forme = ennemi.get_node("SurfaceDetection/CollisionShape3D")
	forme.shape = forme.shape.duplicate()
	decor.ennemis.add_child(ennemi)
	ennemi.set_physics_process(false)
	ennemi.died.connect(_vaincu, CONNECT_ONE_SHOT)
	consigne_changee.emit()

func _liberee(_habitante) -> void:
	if progression.liberee or progression.perdu: return
	progression.liberee = true
	preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.gd").jouer(get_tree())
	rappel = "Donnez un point de rendez-vous à la victime."
	_instructions_rassemblement()
	consigne_changee.emit()

func _instructions_rassemblement() -> void:
	var commande := COMMANDE.nom(&"victim_control", joueur)
	var introduction := "Tu peux indiquer aux victimes où se rassembler pour les mettre à l’abri. "
	var texte := "Maintiens %s, vise un point éloigné, puis relâche pour envoyer la victime." % commande
	if joueur.usingController:
		texte = "Maintiens %s, vise avec le joystick droit, puis relâche %s pour envoyer la victime." % [commande, commande]
	instructeur.parler(introduction + texte, joueur, joueur.camera)

func _nom_rappel() -> String:
	if joueur.usingController:
		for evenement in InputMap.action_get_events("victime_nav_auto"):
			if evenement is InputEventJoypadButton and evenement.button_index == JOY_BUTTON_LEFT_STICK: return "L3"
			if evenement is InputEventJoypadButton and evenement.button_index == JOY_BUTTON_RIGHT_STICK: return "R3"
	return COMMANDE.nom(&"victime_nav_auto", joueur)

func _ouvrir_porte() -> void:
	if ouverture_en_cours or decor.porte.ouverte: return
	if not progression.liberee:
		rappel = "Il reste encore une victime à secourir avant d’ouvrir cette porte."
		consigne_changee.emit()
		return
	if progression.exercice_rassemblement < 3:
		rappel = "Entraînez-vous d’abord à envoyer la victime à un point de rendez-vous, puis à la rappeler."
		consigne_changee.emit()
		return
	ouverture_en_cours = true
	decor.masquer_repere_porte()
	decor.porte.ouvrir()
	await decor.porte.ouverture_terminee
	if progression.perdu or joueur.est_mort: return
	decor.liaison.enabled = true
	progression.porte_ouverte = true
	preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.gd").jouer(get_tree())
	ennemi.collision_layer = 4
	ennemi.add_to_group("enemies")
	ennemi.attaque_timer = 1.2
	rappel = ""
	_activer_rencontre.call_deferred()
	consigne_changee.emit()

func _activer_rencontre() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if progression.perdu or progression.vaincu or not is_instance_valid(ennemi): return
	ennemi.set_physics_process(true)

func _vaincu() -> void:
	progression.vaincu = true
	preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.gd").jouer(get_tree())
	rappel = ""
	consigne_changee.emit()

func _perte_victime(_habitante) -> void:
	echouer("La personne n’a pas survécu. Le sauvetage a échoué.")

func echouer(texte: String) -> void:
	if progression.perdu or progression.reussi: return
	progression.perdu = true
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).afficher_echec(get_tree().current_scene, texte)

func recommencer() -> void:
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).recommencer()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(joueur) or progression.perdu: return
	if progression.liberee and progression.exercice_rassemblement < 3 and is_instance_valid(victime):
		_actualiser_exercice()
	if progression.reussi:
		var ecart_sortie: Vector3 = joueur.global_position - decor.sortie.global_position
		ecart_sortie.y = 0.0
		if ecart_sortie.length() < distance_ouverture_sortie and Input.is_action_just_pressed("interact"):
			_ouvrir_sortie()
		return
	var porte_proche: bool = joueur.global_position.distance_to(Vector3(0, 1, -53.2)) < 2.0
	if porte_proche and Input.is_action_just_pressed("interact"): _ouvrir_porte()
	if is_instance_valid(victime) and victime.vie < vie_precedente: victime_blessee = true
	if is_instance_valid(victime): vie_precedente = victime.vie
	if progression.verifier(joueur, victime, escorte):
		preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.gd").jouer(get_tree())
		rappel = ""
		decor.autoriser_sortie()
		consigne_changee.emit()
		return
	temps_rappel += delta
	if temps_rappel < 12.0: return
	temps_rappel = 0.0
	if not progression.liberee: rappel = "L’habitant est coincé. Approchez-vous et aidez-le à se dégager."
	elif progression.exercice_rassemblement < 3:
		if progression.exercice_rassemblement == 0: rappel = "Envoyez la victime vers un point de rendez-vous éloigné."
		elif progression.exercice_rassemblement == 1: rappel = "Attendez que la victime se déplace vers le point choisi."
		else: rappel = "Rappelez la victime avec %s." % _nom_rappel()
	elif not progression.porte_ouverte: rappel = "Ouvrez la porte pour poursuivre avec la personne."
	elif victime_blessee:
		rappel = "L’habitant est blessé ! Écartez la créature de lui."
		victime_blessee = false
	elif not progression.vaincu:
		if joueur.extincteur.charge < joueur.extincteur.max_charge * 0.25: rappel = "Relâchez le jet pour récupérer de la réserve."
		elif is_instance_valid(ennemi) and joueur.global_position.distance_to(ennemi.global_position) > joueur.extincteur.portee_jet: rappel = "Rapprochez-vous : le jet doit atteindre le sbire."
		else: rappel = "Gardez vos distances pendant la préparation du coup."
	elif progression.dans_zone(joueur.global_position): rappel = "L’habitant est encore derrière vous. Attendez-le ou allez le chercher."
	else: rappel = "Rejoignez ensemble la zone sécurisée."
	consigne_changee.emit()

func _actualiser_exercice() -> void:
	if progression.exercice_rassemblement == 0 and is_instance_valid(escorte.cible_deplacement):
		var cible: Vector3 = escorte.cible_deplacement.global_position
		if Vector2(cible.x - victime.global_position.x, cible.z - victime.global_position.z).length() < 1.5:
			rappel = "Choisissez un point un peu plus éloigné pour voir la victime se déplacer."
			consigne_changee.emit()
			return
		depart_victime = victime.global_position
		progression.exercice_rassemblement = 1
		rappel = "Observez la victime rejoindre le point indiqué."
		consigne_changee.emit()
	elif progression.exercice_rassemblement == 1:
		var ecart: Vector3 = victime.global_position - depart_victime
		ecart.y = 0.0
		if ecart.length() >= 1.0:
			progression.exercice_rassemblement = 2
			rappel = "Rappelle maintenant la victime avec %s." % _nom_rappel()
			instructeur.parler(rappel, joueur, joueur.camera)
			consigne_changee.emit()
	elif progression.exercice_rassemblement == 2 and Input.is_action_just_pressed("victime_nav_auto"):
		progression.exercice_rassemblement = 3
		decor.autoriser_porte_interieure()
		preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.gd").jouer(get_tree())
		rappel = "Bien joué ! Ouvre la porte et protège la victime face à la créature."
		instructeur.parler(rappel, joueur, joueur.camera)
		consigne_changee.emit()

func _ouvrir_sortie() -> void:
	if sortie_en_cours or decor.sortie.est_ouverte: return
	sortie_en_cours = true
	decor.masquer_repere_sortie()
	decor.sortie.ouvrir()
	if not decor.sortie.est_ouverte: await decor.sortie.ouverte
	if progression.perdu or joueur.est_mort: return
	salle_reussie.emit()
