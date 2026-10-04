class_name TypeEnnemiVague
extends Resource

@export var scene: PackedScene
@export var hauteur := 0.85
# Les volants peuvent entrer par une fenêtre ; les autres restent au sol.
@export var volant := false
@export_range(1, 100, 1) var premiere_vague := 1
# Un ennemi difficile consomme plusieurs points du budget de la vague.
@export_range(1, 30, 1) var cout_difficulte := 1
# Probabilité relative de choisir ce type parmi les ennemis disponibles.
@export_range(0.0, 100.0, 1.0) var poids_tirage := 1.0
@export_range(0, 100, 1) var minimum := 0
@export_range(0, 100, 1) var maximum := 30
# Certains ennemis reprennent une variante d'aggro adaptée au camion.
@export var script_zombie: Script
