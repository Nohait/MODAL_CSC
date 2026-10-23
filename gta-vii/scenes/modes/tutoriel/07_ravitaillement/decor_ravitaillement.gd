extends Node3D

@export var plan: Resource = preload("res://scenes/modes/tutoriel/07_ravitaillement/plan_ravitaillement.tres")

const STYLE = preload("res://scenes/modes/tutoriel/commun/decors/construction_interieur.gd")
const PORTE = preload("res://scenes/modes/tutoriel/commun/decors/double_porte.tscn")
const REPERE_PASSAGE = preload("res://scenes/modes/tutoriel/commun/decors/repere_passage.tscn")
var sortie
var repere_sortie: Node3D

func _ready() -> void:
	STYLE.construire_plan(self, plan)
	STYLE.ouvrir_mur(self, &"MurFixe0", Vector3(0, 0, -30), 3.6)
	var porte_arrivee = PORTE.instantiate()
	porte_arrivee.name = "PorteArrivee"
	porte_arrivee.position = Vector3(0, 1.8, -30)
	porte_arrivee.rotation.y = PI
	add_child(porte_arrivee)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/table.glb"), Vector3(-3, 0, -35), PI * 0.5)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/cardboardBoxClosed.glb"), Vector3(-4, 0, -36))
	var mannequin = preload("res://scenes/modes/tutoriel/07_ravitaillement/mannequin_entrainement.gd").new()
	mannequin.position = Vector3(3, 0, -37)
	add_child(mannequin)
	STYLE.ouvrir_mur(self, &"MurFixe4", Vector3(0, 0, -46), 3.6)
	sortie = PORTE.instantiate()
	sortie.name = "PorteSortie"
	sortie.position = Vector3(0, 1.8, -46)
	add_child(sortie)
	repere_sortie = REPERE_PASSAGE.instantiate()
	repere_sortie.position = Vector3(0, 0, -44.35)
	repere_sortie.hide()
	add_child(repere_sortie)
	var lecture = preload("res://scenes/decors/interieurs/compositions/chambre_lecture.tres").construire()
	lecture.position = Vector3(-8, 0, -37)
	add_child(lecture)

func autoriser_sortie() -> void:
	repere_sortie.show()

func masquer_repere_sortie() -> void:
	repere_sortie.hide()
