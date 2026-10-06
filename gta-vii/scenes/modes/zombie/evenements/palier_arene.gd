class_name PalierArene
extends Resource

@export var titre := "L'arène change"
@export_range(1, 100) var vague := 5
@export_enum("ouvrir_entree", "eteindre_lumiere", "allumer_lumiere", "declencher") var evenement := "ouvrir_entree"
@export var cible: NodePath
@export_range(0.0, 100.0, 1.0) var probabilite := 100.0
@export var unique := true
