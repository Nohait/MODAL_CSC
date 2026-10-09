@tool
extends Resource
class_name ExterieurEtage

# La salle reste à la même altitude de jeu ; c'est la ville qui descend autour d'elle.
@export_range(3.0, 30.0, 0.5) var hauteur_sur_rue := 4.5
@export_group("Ville commune — réglages du profil étage 1")
@export_range(0.1, 1.0, 0.05) var detail_immeubles := 0.35
@export_range(8.0, 18.0, 0.5) var largeur_chaussee := 12.0
@export_range(1.5, 5.0, 0.5) var largeur_trottoir := 3.0
@export_range(12.0, 35.0, 0.5) var hauteur_immeubles := 20.0
@export_range(35.0, 70.0, 1.0) var hauteur_tour_moderne := 54.0
@export_range(2, 4) var immeubles_par_ligne := 3
@export_range(2, 3) var rangees_par_ilot := 2
@export var couleur_lampadaires := Color(1.0, 0.64, 0.31)
@export_range(0.0, 4.0, 0.1) var energie_lampadaires := 2.2
@export_range(0.5, 6.0, 0.1) var taille_texture_rue := 1.7
@export_range(0, 8) var nombre_lampadaires := 4
@export_range(3.0, 7.0, 0.1) var hauteur_lampadaires := 3.8
@export_range(4.0, 15.0, 0.5) var portee_lampadaires := 8.0
@export_range(0.0, 2.0, 0.05) var intensite_fenetres_eclairees := 0.35
@export_range(0, 4) var incendies_exterieurs := 2
