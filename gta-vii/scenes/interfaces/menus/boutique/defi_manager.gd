extends Node

signal defis_changes

@export_group("Prix des défis")
@export_range(0, 20) var prix_victime_fragile := 3
@export_range(0, 20) var prix_sans_degats := 1
@export_range(0, 1) var prix_population := 0
@export_group("Équilibrage des défis")
@export_range(1, 100) var vie_victime_fragile := 20
@export_range(1, 10) var points_victime_fragile := 2
@export_range(1, 10) var ennemis_supplementaires := 2
@export_range(1, 5) var victimes_supplementaires := 1

const VICTIME = preload("res://scenes/victimes/victime.tscn")
@onready var salles = get_node("../../Salles/RoomManager")
@onready var joueur = get_node("../../player")
@onready var escorte = get_node("../../VictimManager")
var actifs: Array[Dictionary] = []
var salle_en_cours: Node3D
var salles_validees: Array[int] = []
var boosters_rares_gratuits := 0
var bilan := ""


func _ready() -> void:
	# Les trois étapes évitent de lancer un objectif pendant la boutique précédente.
	salles.salle_preparee.connect(_preparer_salle)
	salles.salle_commencee.connect(_commencer_salle)
	salles.salle_terminee.connect(_terminer_salle)
	joueur.degats_recus.connect(_recevoir_degats)


func propositions() -> Array[Dictionary]:
	# Un identifiant stable permet de changer le titre sans casser la règle du défi.
	var liste: Array[Dictionary] = [
		{
			"id": &"fragile",
			"titre": "Une vie précieuse",
			"prix": prix_victime_fragile,
			"description": "Une petite victime fragile (%d PV) rejoint l'escorte. Vivante, elle rapporte %d points à chaque prochaine boutique." % [vie_victime_fragile, points_victime_fragile],
			"objectif": 0 # Zéro signifie une durée illimitée, jusqu'à la mort de la victime.
		},
		{
			"id": &"sans_degats",
			"titre": "Sans une égratignure",
			"prix": prix_sans_degats,
			"description": "Terminez la prochaine salle sans perdre de vie : vous recevrez un booster rare gratuit.",
			"objectif": 1
		},
		{
			"id": &"population",
			"titre": "Sauvetage sous pression",
			"prix": prix_population,
			"description": "La prochaine salle contient jusqu'à %d ennemis mobiles et %d victime(s) supplémentaires, selon les emplacements libres." % [ennemis_supplementaires, victimes_supplementaires],
			"objectif": 1
		}
	]
	# filter construit une nouvelle liste contenant uniquement les défis disponibles.
	return liste.filter(func(defi): return not possede(defi.id))


func possede(id: StringName) -> bool:
	for defi in actifs:
		if defi.id == id:
			return true
	return false


func accepter(id: StringName) -> bool:
	# La boutique a vérifié et payé le prix ; ici on prépare seulement la règle.
	for proposition in propositions():
		if proposition.id != id:
			continue
		var defi: Dictionary = proposition.duplicate()
		defi.progression = 0
		defi.en_attente = true
		defi.echec = false
		if id == &"fragile":
			defi.victime = _creer_victime_fragile()
		actifs.append(defi)
		defis_changes.emit()
		return true
	return false


func _creer_victime_fragile() -> CharacterBody3D:
	var victime = VICTIME.instantiate()
	victime.name = "VictimeFragile"
	victime.defi_fragile = true
	victime.vie_max = vie_victime_fragile
	victime.points_boutique = points_victime_fragile
	# Ajouter hors des salles, puis utiliser la libération habituelle pour former la file.
	get_node("../..").add_child(victime)
	victime.global_position = joueur.global_position
	victime.set_ennemis_container(salles.salle_actuelle.get_node("Ennemis"))
	victime.navigation_agent.set_navigation_map(salles.salle_actuelle.get_node("Navigation").get_navigation_map())
	escorte.surveiller_victime(victime)
	victime.free_victim()
	victime.died.connect(_victime_fragile_morte)
	return victime


func _victime_fragile_morte(_victime: CharacterBody3D) -> void:
	actifs = actifs.filter(func(defi): return defi.id != &"fragile")
	defis_changes.emit()


func _preparer_salle(salle: Node3D) -> void:
	for defi in actifs:
		if defi.id == &"population" and defi.en_attente:
			salles.ajouter_population_defi(salle, ennemis_supplementaires, victimes_supplementaires)


func _commencer_salle(salle: Node3D) -> void:
	salle_en_cours = salle
	# Un défi acheté dans la boutique concerne le combat qui commence maintenant.
	for defi in actifs:
		defi.en_attente = false
		defi.echec = false


func _recevoir_degats(_quantite: float) -> void:
	# L'invincibilité et les impacts sans perte de PV n'émettent pas ce signal.
	for defi in actifs:
		if defi.id == &"sans_degats" and not defi.en_attente:
			defi.echec = true


func _terminer_salle(salle: Node3D) -> void:
	# Le debug peut revisiter une salle : elle ne doit jamais payer deux récompenses.
	if salle != salle_en_cours or salles_validees.has(salle.get_instance_id()):
		return
	salles_validees.append(salle.get_instance_id())
	bilan = ""
	for defi in actifs.duplicate():
		if defi.en_attente:
			continue
		if defi.id == &"sans_degats":
			if not defi.echec:
				boosters_rares_gratuits += 1
				bilan += "Sans une égratignure réussi : un booster rare offert. "
			else:
				bilan += "Sans une égratignure échoué. "
			actifs.erase(defi)
		elif defi.id == &"population":
			actifs.erase(defi)
		else:
			# La victime fragile n'a pas de durée limite : compter les salles survécues.
			defi.progression += 1
	defis_changes.emit()

func capturer_sauvegarde() -> Dictionary:
	var liste: Array[Dictionary] = []
	for defi in actifs:
		var copie: Dictionary = defi.duplicate()
		if copie.has("victime"):
			copie.indice_victime = escorte.freed_victims.find(copie.victime)
			copie.erase("victime")
		liste.append(copie)
	return {"actifs": liste, "gratuits": boosters_rares_gratuits, "bilan": bilan}

func restaurer_sauvegarde(etat: Dictionary) -> void:
	actifs.clear()
	for donnees in etat.actifs:
		var defi: Dictionary = donnees.duplicate()
		if defi.has("indice_victime"):
			var indice: int = defi.indice_victime
			if indice < 0 or indice >= escorte.freed_victims.size(): continue
			defi.victime = escorte.freed_victims[indice]
			defi.victime.died.connect(_victime_fragile_morte)
			defi.erase("indice_victime")
		actifs.append(defi)
	boosters_rares_gratuits = etat.gratuits
	bilan = etat.bilan
	defis_changes.emit()
