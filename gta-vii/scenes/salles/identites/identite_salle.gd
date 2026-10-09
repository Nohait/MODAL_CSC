@tool
extends AmbianceEtage
class_name IdentiteSalle

@export_group("IdentitÃ©")
@export var titre := "Salon"
@export_range(1, 3) var etage := 1
@export_range(0.0, 10.0, 0.1) var poids := 1.0
@export var couleur_soubassement := Color(0.59, 0.62, 0.57)
@export var pieces: Array[PackedScene] = []
@export var compositions_annexes: Array[Resource] = []

@export_group("Incendie")
@export var incendie: IncendieSalle = preload("res://scenes/salles/incendies/habitation.tres")
