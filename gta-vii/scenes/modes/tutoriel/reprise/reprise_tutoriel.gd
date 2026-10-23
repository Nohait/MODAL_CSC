extends "res://scenes/systemes/sauvegarde/fichier_sauvegarde.gd"

const CATALOGUE = preload("res://scenes/modes/tutoriel/reprise/catalogue.gd")
var point_courant: Dictionary = {}
var en_attente: Dictionary = {}
var transition_en_cours := false

static func obtenir(arbre: SceneTree) -> Node:
	var service := arbre.root.get_node_or_null("RepriseTutoriel")
	if service == null:
		service = load("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").new()
		service.name = "RepriseTutoriel"
		service.chemin_fichier = "user://partie_tutoriel.save"
		arbre.root.add_child.call_deferred(service)
	return service

func _valide(point: Dictionary) -> bool:
	if point.get("version") != VERSION or not point.get("salle") is String: return false
	if CATALOGUE.trouver(StringName(point.salle)) == null: return false
	var etat = point.get("etat")
	if not etat is Dictionary or not etat.get("cartes") is Dictionary: return false
	for cle in ["vie", "charge"]:
		if not etat.get(cle) is float and not etat.get(cle) is int: return false
		if not is_finite(float(etat[cle])) or float(etat[cle]) < 0.0: return false
	if not etat.get("formation") is bool or not etat.get("surchauffe") is bool: return false
	return not etat.has("escorte") or _escorte_valide(etat.escorte)

func _escorte_valide(etat) -> bool:
	if not etat is Dictionary or not etat.get("victimes") is Array or not etat.get("ordre_liberation") is int:
		return false
	var destination = etat.get("destination")
	if destination != null and not destination is Vector3: return false
	for victime in etat.victimes:
		if not victime is Dictionary: return false
		if not victime.get("position") is Vector3 or not victime.get("rotation") is Vector3: return false
		for cle in ["vie", "vie_max", "prochaine_protection"]:
			if not victime.get(cle) is float and not victime.get(cle) is int: return false
		for cle in ["ordre", "points"]:
			if not victime.get(cle) is int: return false
		for cle in ["fragile", "depot", "extraction_utilisee"]:
			if not victime.get(cle) is bool: return false
		if not victime.get("protection") is Dictionary: return false
	return true

func _debug() -> bool:
	return Engine.get_meta("tutoriel_debug_actif", false) or Engine.has_meta("tutoriel_debug_depart")

func _capturer(niveau: Node, conserver_escorte := true) -> Dictionary:
	var joueur = niveau.get_node("player")
	var gestion = niveau.get_node("UpgradeManager")
	var etat := {"cartes": gestion.capturer_sauvegarde(), "vie": joueur.BarreDeVie.value,
		"charge": joueur.extincteur.charge, "surchauffe": joueur.extincteur.is_overheated,
		"formation": gestion.formation_utilisee}
	if conserver_escorte and niveau.has_node("VictimManager"):
		etat.escorte = niveau.get_node("VictimManager").capturer_sauvegarde()
	return etat

func salle_en_attente() -> StringName:
	return StringName(en_attente.get("salle", ""))

func installer(niveau: Node, salle: StringName) -> void:
	transition_en_cours = false
	var reprise_debug: bool = en_attente.get("reprise_debug", false)
	if en_attente.get("salle", "") == String(salle) and (not _debug() or reprise_debug):
		var etat: Dictionary = en_attente.etat
		var gestion = niveau.get_node("UpgradeManager")
		gestion.restaurer_sauvegarde(etat.cartes)
		gestion.formation_utilisee = etat.formation
		var joueur = niveau.get_node("player")
		joueur.BarreDeVie.value = clampf(etat.vie, 0.0, joueur.BarreDeVie.max_value)
		joueur.extincteur.charge = clampf(etat.charge, 0.0, joueur.extincteur.max_charge)
		joueur.extincteur.is_overheated = etat.surchauffe
		var salles = niveau.get_node_or_null("Salles/RoomManager")
		if etat.has("escorte") and salles != null and is_instance_valid(salles.salle_actuelle):
			niveau.get_node("VictimManager").restaurer_sauvegarde(etat.escorte, salles.salle_actuelle)
	en_attente.clear()
	# Reconstruire les objectifs depuis le début de la salle, jamais depuis un combat interrompu.
	point_courant = {"version": VERSION, "salle": String(salle), "etat": _capturer(niveau)}
	if not _debug() and not enregistrer(point_courant):
		push_warning("Le point de reprise du tutoriel n’a pas pu être enregistré.")

func actualiser_point_debug(niveau: Node, salle: StringName) -> void:
	if not _debug(): return
	# Le point reste en mémoire : les données synthétiques ne sont jamais écrites dans la progression.
	point_courant = {"version": VERSION, "salle": String(salle), "etat": _capturer(niveau)}

func ouvrir_salle(niveau: Node, identifiant: StringName, conserver_escorte := false) -> void:
	var definition := CATALOGUE.trouver(identifiant)
	if definition == null or transition_en_cours: return
	en_attente = {"version": VERSION, "salle": String(identifiant), "etat": _capturer(niveau, conserver_escorte)}
	_charger(definition.scene)

func chemin_reprise() -> String:
	charger()
	if disponible():
		en_attente = dernier_point.duplicate(true)
		return CATALOGUE.trouver(StringName(dernier_point.salle)).scene
	en_attente.clear()
	return CATALOGUE.trouver(&"parvis").scene

func recommencer() -> void:
	if transition_en_cours or point_courant.is_empty(): return
	en_attente = point_courant.duplicate(true)
	if _debug(): en_attente.reprise_debug = true
	_charger(CATALOGUE.trouver(StringName(point_courant.salle)).scene)

func reinitialiser() -> bool:
	if not supprimer(): return false
	point_courant.clear()
	en_attente.clear()
	transition_en_cours = false
	return true

func _charger(chemin: String) -> void:
	if Reglages.chargement.en_cours: return
	transition_en_cours = true
	get_tree().paused = false
	if not Reglages.chargement.chargement_echoue.is_connected(_echec_chargement):
		Reglages.chargement.chargement_echoue.connect(_echec_chargement)
	Reglages.chargement.ouvrir(chemin)

func _echec_chargement() -> void:
	transition_en_cours = false
	en_attente.clear()

func afficher_echec(niveau: Node, message: String) -> void:
	if niveau.has_node("EchecTutoriel"): return
	var joueur = niveau.get_node("player")
	joueur.extincteur.stop_primary_attack()
	get_tree().paused = true
	var interface = preload("res://scenes/modes/tutoriel/commun/interface/echec_tutoriel.gd").new()
	interface.name = "EchecTutoriel"
	niveau.add_child(interface)
	interface.recommencer.connect(recommencer)
	interface.afficher(message)
