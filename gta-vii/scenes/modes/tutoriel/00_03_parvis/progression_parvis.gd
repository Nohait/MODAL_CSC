extends Node

signal etat_change
signal preparation_terminee

const ETAPE = preload("res://scenes/modes/tutoriel/00_03_parvis/etapes/etape_tutoriel.gd")
@export var etapes: Array[Resource] = []
@export_range(0.1, 0.8, 0.05) var seuil_reserve_basse := 0.65
@export_range(0.85, 1.0, 0.05) var seuil_recharge := 0.95
@export_range(0.5, 5.0, 0.1) var rayon_exercice_dash := 2.0

var indice := 0
var indice_replique := -1
var dialogue_termine := false
var reserve_sollicitee := false
var dash_en_cours := false
var dash_reussi := false
var foyers: Array[Node] = []
var joueur: CharacterBody3D
var repere_dash: Node3D

func preparer(personnage: CharacterBody3D, cibles: Array[Node], arrivee_dash: Node3D) -> void:
	joueur = personnage
	foyers = cibles
	repere_dash = arrivee_dash
	for foyer in foyers:
		foyer.foyer_eteint.connect(_foyer_eteint)
	joueur.dash_commence.connect(_dash_commence)
	etat_change.emit()

func etape() -> Resource:
	return etapes[indice] if indice < etapes.size() else null

func replique() -> String:
	var actuelle := etape()
	if actuelle == null or indice_replique < 0 or dialogue_termine: return ""
	return actuelle.repliques[indice_replique]

func parler() -> void:
	var actuelle := etape()
	if actuelle == null: return
	if dialogue_termine:
		# Le supérieur peut répéter sa consigne, sans réinitialiser l'exercice.
		etat_change.emit()
		return
	indice_replique += 1
	if indice_replique >= actuelle.repliques.size():
		dialogue_termine = true
	etat_change.emit()
	_verifier()

func foyers_eteints() -> int:
	var total := 0
	for foyer in foyers:
		if foyer.intensite <= 0.0: total += 1
	return total

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(joueur) or not dialogue_termine or etape() == null: return
	if etape().objectif == ETAPE.Objectif.RESERVE:
		var arme = joueur.extincteur
		var ratio: float = arme.charge / maxf(arme.max_charge, 0.01)
		if not reserve_sollicitee and ratio <= seuil_reserve_basse:
			reserve_sollicitee = true
			etat_change.emit()
	if dash_en_cours and not joueur.is_dashing:
		dash_en_cours = false
		var distance := Vector2(joueur.global_position.x - repere_dash.global_position.x, joueur.global_position.z - repere_dash.global_position.z)
		dash_reussi = distance.length() <= rayon_exercice_dash
		_verifier()
	if etape().objectif == ETAPE.Objectif.RESERVE: _verifier()

func _foyer_eteint() -> void:
	etat_change.emit()
	_verifier()

func _dash_commence(_direction: Vector3) -> void:
	if etape() != null and etape().objectif == ETAPE.Objectif.DASH and dialogue_termine:
		dash_en_cours = true

func _verifier() -> void:
	if not dialogue_termine or etape() == null: return
	var reussi := false
	match etape().objectif:
		ETAPE.Objectif.CONVERSATION: reussi = true
		ETAPE.Objectif.FOYERS: reussi = foyers_eteints() == foyers.size()
		ETAPE.Objectif.RESERVE:
			reussi = reserve_sollicitee and not joueur.extincteur.is_attacking and joueur.extincteur.charge >= joueur.extincteur.max_charge * seuil_recharge
		ETAPE.Objectif.DASH: reussi = dash_reussi
	if reussi:
		indice += 1
		indice_replique = -1
		dialogue_termine = false
		dash_reussi = false
		dash_en_cours = false
		etat_change.emit()

func entrer() -> void:
	if etape() != null and etape().objectif == ETAPE.Objectif.ENTREE and dialogue_termine:
		preparation_terminee.emit()
