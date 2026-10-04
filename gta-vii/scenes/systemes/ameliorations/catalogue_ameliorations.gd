class_name CatalogueAmeliorations
extends Resource

@export var cartes: Array[Amelioration] = []

func disponibles(mode: String, type_bonus: String = "") -> Array[Amelioration]:
	var resultat: Array[Amelioration] = []
	var drapeau := 2 if mode == "zombie" else 1
	for carte in cartes:
		if carte == null or not carte.active or (carte.modes & drapeau) == 0:
			continue
		if type_bonus.is_empty() or carte.type_bonus == type_bonus:
			resultat.append(carte)
	return resultat

func trouver(identifiant: StringName) -> Amelioration:
	for carte in cartes:
		if carte != null and carte.identifiant == identifiant:
			return carte
	return null
