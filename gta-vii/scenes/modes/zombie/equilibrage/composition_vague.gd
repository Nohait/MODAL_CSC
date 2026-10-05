class_name CompositionVague
extends Resource

@export var titre := "Classique"
@export_range(1, 100, 1) var premiere_vague := 1
@export_range(0.0, 100.0, 1.0) var poids := 1.0
@export var ennemis: Array[TypeEnnemiVague] = []
@export var autoriser_tourelles := true
# Zéro conserve le nombre de mobiles donné par la difficulté.
@export_range(0, 100, 1) var limite_mobiles := 0
@export var ennemi_initial: TypeEnnemiVague

@export_group("Effet de la vague spéciale")
@export_enum("aucun", "blackout", "double_horde", "brouillard", "chaleur", "panne", "doree", "mutation") var evenement := "aucun"
@export var composition_base: CompositionVague
# Zéro : jusqu'à la fin de la vague. La mutation dure 60 secondes de jeu.
@export_range(0.0, 120.0, 1.0) var duree_effet := 0.0
@export_range(1.0, 3.0, 0.1) var multiplicateur_budget := 1.0
@export_range(1.0, 3.0, 0.1) var multiplicateur_consommation := 1.0

func repartir(budget: int, vague: int) -> Array[TypeEnnemiVague]:
	if composition_base != null: return composition_base.repartir(budget, vague)
	var resultat: Array[TypeEnnemiVague] = []
	var comptes := {}
	var restant := maxi(1, budget)
	var limite := limite_mobiles if limite_mobiles > 0 else budget
	for type in ennemis:
		if type == null or type.scene == null or vague < type.premiere_vague: continue
		comptes[type] = 0
		for i in range(mini(type.minimum, type.maximum)):
			if resultat.size() >= limite or type.cout_difficulte > restant: break
			resultat.append(type)
			comptes[type] += 1
			restant -= type.cout_difficulte
	# Tirer seulement parmi les types qui rentrent dans le budget et leur plafond.
	while resultat.size() < limite and restant > 0:
		var possibles: Array[TypeEnnemiVague] = []
		var somme := 0.0
		for type in comptes:
			if comptes[type] < type.maximum and type.poids_tirage > 0 and type.cout_difficulte <= restant:
				possibles.append(type)
				somme += type.poids_tirage
		if possibles.is_empty(): break
		var tirage := randf() * somme
		var choisi: TypeEnnemiVague = possibles.back()
		for type in possibles:
			tirage -= type.poids_tirage
			if tirage <= 0:
				choisi = type
				break
		resultat.append(choisi)
		comptes[choisi] += 1
		restant -= choisi.cout_difficulte
	resultat.shuffle()
	# Faire apparaître le boss immédiatement, plutôt qu'à la fin du timer.
	if ennemi_initial != null and resultat.has(ennemi_initial):
		resultat.erase(ennemi_initial)
		resultat.push_front(ennemi_initial)
	return resultat
