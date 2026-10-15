extends Node3D

@export var plan: Resource = preload("res://scenes/modes/tutoriel/07_ravitaillement/plan_ravitaillement.tres")

const STYLE = preload("res://scenes/modes/tutoriel/commun/decors/construction_interieur.gd")
var sortie

func _ready() -> void:
	STYLE.construire_plan(self, plan)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/table.glb"), Vector3(-3, 0, -35), PI * 0.5)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/cardboardBoxClosed.glb"), Vector3(-4, 0, -36))
	var mannequin = preload("res://scenes/modes/tutoriel/07_ravitaillement/mannequin_entrainement.gd").new()
	mannequin.position = Vector3(3, 0, -37)
	add_child(mannequin)
	sortie = preload("res://scenes/decors/porte_sortie.tscn").instantiate()
	sortie.position = Vector3(0, 0, -44)
	add_child(sortie)
	var lecture = preload("res://scenes/decors/interieurs/compositions/chambre_lecture.tres").construire()
	lecture.position = Vector3(-8, 0, -37)
	add_child(lecture)
