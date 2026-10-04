class_name DifficulteZombie
extends Resource

@export_group("Budget des ennemis mobiles")
@export_range(1, 20, 1) var budget_premiere_vague := 3
@export_range(0, 10, 1) var budget_ajoute_par_vague := 2
@export_range(1, 100, 1) var budget_maximum := 30

@export_group("Compositions")
@export var composition_classique: CompositionVague = preload("res://scenes/modes/zombie/equilibrage/compositions/classique.tres")
@export_range(0.0, 1.0, 0.05) var probabilite_vague_speciale := 0.35
@export var compositions_speciales: Array[CompositionVague] = [
	preload("res://scenes/modes/zombie/equilibrage/compositions/meute.tres"),
	preload("res://scenes/modes/zombie/equilibrage/compositions/siege.tres"),
	preload("res://scenes/modes/zombie/equilibrage/compositions/embuscade.tres")
]
@export var composition_boss: CompositionVague = preload("res://scenes/modes/zombie/equilibrage/compositions/mini_boss.tres")
@export_range(1, 100, 1) var intervalle_vagues_boss := 10

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

func budget_mobiles(vague: int) -> int:
	return clampi(budget_premiere_vague + (vague - 1) * budget_ajoute_par_vague, 1, maxi(1, budget_maximum))

func taille_groupe(vague: int) -> int:
	var ajout := floori(float(maxi(0, vague - 1)) / maxi(1, vagues_entre_augmentations_groupe))
	return clampi(taille_initiale_groupe + ajout, 1, maxi(1, taille_maximale_groupe))

func nombre_tourelles(vague: int) -> int:
	if vague < premiere_vague_tourelles:
		return 0
	# Ce nombre ne dépend pas de la progression : jamais plus de deux tourelles.
	var maximum := clampi(maximum_tourelles, 0, 2)
	return randi_range(clampi(minimum_tourelles, 0, maximum), maximum)

func choisir_composition(vague: int) -> CompositionVague:
	if composition_boss != null and vague >= composition_boss.premiere_vague and vague % maxi(1, intervalle_vagues_boss) == 0:
		return composition_boss
	var possibles: Array[CompositionVague] = []
	var somme := 0.0
	for composition in compositions_speciales:
		if composition != null and vague >= composition.premiere_vague and composition.poids > 0:
			possibles.append(composition)
			somme += composition.poids
	if possibles.is_empty() or randf() >= probabilite_vague_speciale:
		return composition_classique
	var tirage := randf() * somme
	for composition in possibles:
		tirage -= composition.poids
		if tirage <= 0: return composition
	return possibles.back()
