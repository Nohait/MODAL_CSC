class_name DifficulteZombie
extends Resource

@export_group("Sbires")
@export_range(1, 20, 1) var ennemis_premiere_vague := 3
@export_range(0, 10, 1) var ennemis_ajoutes_par_vague := 2
@export_range(1, 100, 1) var maximum_sbires := 30

@export_group("Groupes d'apparition")
@export_range(1, 5, 1) var taille_initiale_groupe := 2
## Nombre de vagues entre deux augmentations de 1 du groupe d'apparition.
@export_range(1, 10, 1) var vagues_entre_augmentations_groupe := 3
@export_range(1, 10, 1) var taille_maximale_groupe := 5

@export_group("Sauvetage et boutique")
@export_range(1, 10) var victimes_minimum := 1
@export_range(1, 10) var victimes_maximum := 3
@export_range(5.0, 60.0, 1.0) var duree_minimum_vague := 15.0
@export_range(5.0, 60.0, 1.0) var duree_maximum_vague := 30.0
@export_range(1.0, 10.0, 0.5) var delai_avant_boutique := 3.0
@export_range(1.0, 10.0, 0.5) var delai_apres_boutique := 3.0

@export_group("Tourelles")
@export_range(1, 100, 1) var premiere_vague_tourelles := 5
@export_range(0, 2, 1) var minimum_tourelles := 1
@export_range(0, 2, 1) var maximum_tourelles := 2

func nombre_sbires(vague: int) -> int:
	return clampi(ennemis_premiere_vague + (vague - 1) * ennemis_ajoutes_par_vague, 1, maxi(1, maximum_sbires))

func taille_groupe(vague: int) -> int:
	var ajout := floori(float(maxi(0, vague - 1)) / maxi(1, vagues_entre_augmentations_groupe))
	return clampi(taille_initiale_groupe + ajout, 1, maxi(1, taille_maximale_groupe))

func nombre_tourelles(vague: int) -> int:
	if vague < premiere_vague_tourelles:
		return 0
	# Ce nombre ne dépend pas de la progression : jamais plus de deux tourelles.
	var maximum := clampi(maximum_tourelles, 0, 2)
	return randi_range(clampi(minimum_tourelles, 0, maximum), maximum)
