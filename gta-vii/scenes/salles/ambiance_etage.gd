@tool
extends Resource
class_name AmbianceEtage

# Les deux étages utilisent les mêmes règles de placement, avec des contenus différents.
@export_range(0, 8) var nombre_fenetres := 2
@export var fenetres_incendie := false
@export_range(0, 10) var nombre_appliques := 5
@export var couleur_appliques := Color(0.75, 0.85, 1.0)
@export_range(0.0, 5.0, 0.1) var energie_appliques := 1.6
@export_range(0, 6) var nombre_meubles_en_feu := 3
@export_range(0.2, 2.0, 0.05) var taille_foyers := 0.85
@export_range(0.0, 5.0, 0.1) var energie_foyers := 2.2
@export_range(0.0, 1.0, 0.05) var densite_fumee := 0.4
@export var meubles_incendies: Array[PackedScene] = []
@export_range(0, 8) var nombre_tuyauteries := 3
@export_range(0, 6) var nombre_portes_decoratives := 2
@export_range(0, 6) var nombre_armoires := 0
@export_range(0.0, 2.0, 0.05) var energie_voyants := 0.45
@export_range(0.5, 5.0, 0.1) var portee_voyants := 2.0
@export_range(0, 6) var nombre_gravats := 2
@export_range(0, 6) var nombre_zones_humides := 1
@export_range(0.0, 1.0, 0.05) var opacite_suie := 0.5
@export_range(0.0, 1.0, 0.05) var intensite_reflets := 0.5
