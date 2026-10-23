extends "res://scenes/jeu/main.gd"

const REPRISE = preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd")
@onready var gestion_salles = $Salles/RoomManager
var introduction: Node

func _ready() -> void:
	session_tutoriel = true
	var reprise = REPRISE.obtenir(get_tree())
	var depart: StringName = reprise.salle_en_attente()
	var depart_debug := String(Engine.get_meta("tutoriel_debug_depart", ""))
	var boutique_debug := _parametres_boutique_debug(depart_debug)
	if depart == &"points_2" or depart_debug == "points_2" or boutique_debug.x == 2:
		gestion_salles.indice_salle_depart = 1
	gestion_salles.salle_preparee.connect(_salle_preparee)
	gestion_salles.salle_commencee.connect(_salle_commencee)
	gestion_salles.room_cleared.connect(_actualiser_briefing)
	gestion_salles.boutique_preparee.connect(_boutique_preparee)
	gestion_salles.parcours_termine.connect(_ouvrir_conclusion)
	gestion_salles.partie_prete.connect(_partie_prete)
	$VictimManager.escort_changed.connect(_actualiser_briefing)
	super._ready()
	$InterfaceTest.hide()
	$MenuDebug.process_mode = Node.PROCESS_MODE_DISABLED
	$player/SecondaryAttack.process_mode = Node.PROCESS_MODE_DISABLED
	var attaque = $player/SecondaryAttack.get_child(0)
	if is_instance_valid(attaque.icone): attaque.icone.hide()

func _salle_preparee(_salle: Node3D) -> void:
	var identifiant: StringName = &"points_1" if gestion_salles.indice_salle == 0 else &"points_2"
	# Restaurer avant l'entrée place naturellement toute l'escorte dans le couloir.
	REPRISE.obtenir(get_tree()).installer(self, identifiant)

func _salle_commencee(salle: Node3D) -> void:
	_brancher_population(salle)
	_actualiser_briefing()
	var debug_actif: bool = Engine.get_meta("tutoriel_debug_actif", false) \
		or Engine.has_meta("tutoriel_debug_depart")
	if gestion_salles.indice_salle == 0 and not debug_actif:
		introduction = preload("res://scenes/modes/tutoriel/09_10_points_boutique/introduction_points.gd").new()
		introduction.name = "IntroductionPoints"
		add_child(introduction)
		introduction.terminee.connect(gestion_salles.confirmer_introduction, CONNECT_ONE_SHOT)

func _brancher_population(salle: Node3D) -> void:
	for victime in salle.get_node("Victimes").get_children():
		victime.freed.connect(_actualiser_briefing.unbind(1), CONNECT_ONE_SHOT)
		victime.died.connect(_actualiser_briefing.unbind(1), CONNECT_ONE_SHOT)
	for ennemi in salle.get_node("Ennemis").get_children():
		if ennemi.has_signal("died") and not ennemi.died.is_connected(_actualiser_briefing):
			ennemi.died.connect(_actualiser_briefing)

func _actualiser_briefing() -> void:
	if not is_instance_valid(gestion_salles.salle_actuelle): return
	var seconde: bool = gestion_salles.indice_salle == 1
	$Briefing/Panneau/Disposition/Titre.text = "10 · RENFORCER L’ESCORTE" if seconde else "09 · VICTIMES ET RAVITAILLEMENT"
	var salle = gestion_salles.salle_actuelle
	var texte := ""
	if salle.liberee:
		texte = "Rejoignez le passage avec les victimes encore en vie."
	elif salle.remaining_victims > 0:
		texte = "Libérez la nouvelle victime et gardez-la à l’écart des créatures."
	elif salle.remaining_enemies > 0:
		texte = "Protégez votre escorte et sécurisez la salle."
	else:
		texte = "Rejoignez le passage avec votre escorte."
	$Briefing/Panneau/Disposition/Consigne.text = texte
	var vivantes: int = gestion_salles.compter_victimes_escorte_vivantes()
	$Briefing/Panneau/Disposition/Rappel.text = "%d victime%s dans l’escorte · %d point%s à la prochaine boutique" % [vivantes, "s" if vivantes != 1 else "", vivantes, "s" if vivantes != 1 else ""]
	$Briefing/Panneau/Disposition/Rappel.show()

func _boutique_preparee(numero: int, _victimes_vivantes: int) -> void:
	$UpgradeManager.configurer_boutique_tutoriel(numero)

func _ouvrir_conclusion() -> void:
	if has_node("ConclusionTutoriel"): return
	var conclusion = preload("res://scenes/modes/tutoriel/commun/interface/conclusion_tutoriel.gd").new()
	conclusion.name = "ConclusionTutoriel"
	add_child(conclusion)

func _partie_prete() -> void:
	await preload("res://scenes/modes/tutoriel/debug/menu_tutoriel.gd").installer(self)

func afficher_ecran_mort() -> void:
	REPRISE.obtenir(get_tree()).afficher_echec(self, "Vous n’avez pas pu poursuivre l’intervention.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		REPRISE.obtenir(get_tree()).recommencer()

func debug_contexte() -> Dictionary:
	var salle = gestion_salles.salle_actuelle
	var victime: Node = null
	for candidate in salle.get_node("Victimes").get_children():
		if candidate.is_in_group("victime"):
			victime = candidate
			break
	var ennemi: Node = null
	for candidate in salle.get_node("Ennemis").get_children():
		if candidate.has_method("choisir_cible") and not candidate.est_mort:
			ennemi = candidate
			break
	var boutique_ouverte: bool = $UpgradeManager.boutique_ouverte
	var identifiant := "points_2" if gestion_salles.indice_salle == 1 else "points_1"
	if boutique_ouverte:
		identifiant = "boutique_points:%d:%d" % [$UpgradeManager.numero_boutique_tutoriel,
			gestion_salles.compter_victimes_escorte_vivantes()]
	var conditions := {
		"Victime traitée": salle.remaining_victims == 0,
		"Salle sécurisée": salle.remaining_enemies == 0,
		"Boutique ouverte": boutique_ouverte,
		"Carte acquise": $UpgradeManager.carte_choisie_boutique_tutoriel}
	var resultat := {"salle": "Ravitaillement %d" % (gestion_salles.indice_salle + 1), "etape": "boutique" if boutique_ouverte else "sauvetage", "objectif": $Briefing/Panneau/Disposition/Consigne.text, "joueur": $player, "victime": victime, "escorte": $VictimManager, "ennemi": ennemi, "foyers": [], "sortie": "ouverte" if salle.liberee else "verrouillée", "restart_etape": identifiant, "restart_salle": "points_2" if gestion_salles.indice_salle == 1 else "points_1", "reperes": [salle.entree.global_position, salle.to_global(salle.points_spawn[0]) if not salle.points_spawn.is_empty() else salle.global_position], "ennemis_restants": salle.remaining_enemies}
	resultat.merge(preload("res://scenes/modes/tutoriel/debug/etapes_debug.gd").conditions(conditions))
	return resultat

func debug_reconstruire(identifiant: String) -> void:
	if is_instance_valid(introduction): introduction.fermer()
	if not $UpgradeManager.formation_utilisee:
		$UpgradeManager.acquerir_formation_debug(&"pression")
	if identifiant == "points_2":
		await _configurer_escorte_debug(1)
		REPRISE.obtenir(get_tree()).actualiser_point_debug(self, &"points_2")
		_actualiser_briefing()
		return
	var parametres := _parametres_boutique_debug(identifiant)
	if parametres.x == 0: return
	var numero_boutique := parametres.x
	var nombre := parametres.y
	await _configurer_escorte_debug(nombre)
	REPRISE.obtenir(get_tree()).actualiser_point_debug(self,
		&"points_2" if numero_boutique == 2 else &"points_1")
	gestion_salles.transition_en_cours = true
	_boutique_preparee(numero_boutique, nombre)
	$UpgradeManager.ouvrir_choix(nombre)

func _parametres_boutique_debug(identifiant: String) -> Vector2i:
	var morceaux := identifiant.split(":")
	if morceaux.size() != 3 or morceaux[0] != "boutique_points": return Vector2i.ZERO
	return Vector2i(clampi(int(morceaux[1]), 1, 2), clampi(int(morceaux[2]), 0, 2))

func _configurer_escorte_debug(nombre: int) -> void:
	for victime in $VictimManager.freed_victims.duplicate():
		if is_instance_valid(victime): victime.queue_free()
	await get_tree().process_frame
	$VictimManager.freed_victims.clear()
	var donnees: Array[Dictionary] = []
	for i in range(nombre):
		donnees.append({"position": $player.global_position + Vector3(-1.2 + i * 1.2, -0.35, 1.8), "rotation": Vector3.ZERO, "vie": 100.0, "vie_max": 100.0, "fragile": false, "points": 1, "ordre": i + 1, "depot": false, "extraction_utilisee": false, "protection": {}, "prochaine_protection": 0.0})
	$VictimManager.restaurer_sauvegarde({"victimes": donnees, "ordre_liberation": nombre, "destination": null}, gestion_salles.salle_actuelle)
