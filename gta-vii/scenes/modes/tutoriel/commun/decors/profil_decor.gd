extends Resource

@export var sol: Material = preload("res://assets/materiaux/sol_appartements.tres")
@export var mur: Material = preload("res://assets/materiaux/mur_appartements.tres")
@export var bois: Material = preload("res://assets/materiaux/appartements/bois_finitions.tres")
@export var soubassement: Material = preload("res://assets/materiaux/appartements/beige_wall_001.tres")
@export_range(0.1, 1.0, 0.05) var hauteur_soubassement := 0.55
@export_range(0.04, 0.2, 0.01) var hauteur_plinthe := 0.1
@export_range(0.8, 2.0, 0.05) var hauteur_murs := 1.35
@export_range(0.0, 3.0, 0.05) var energie_lumieres := 0.8
@export_range(2.0, 10.0, 0.5) var portee_lumieres := 5.0
@export var couleur_lumieres := Color(1, 0.78, 0.49)
