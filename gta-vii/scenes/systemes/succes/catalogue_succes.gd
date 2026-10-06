extends RefCounted
const PROGRESSION = [
	preload("res://scenes/systemes/succes/definitions/dixieme.tres"),
	preload("res://scenes/systemes/succes/definitions/cent.tres"),
	preload("res://scenes/systemes/succes/definitions/elites.tres"),
	preload("res://scenes/systemes/succes/definitions/boss.tres"),
	preload("res://scenes/systemes/succes/definitions/intact.tres"),
	preload("res://scenes/systemes/succes/definitions/fusion.tres")
]

static func liste() -> Array:
	var resultat := SUCCES.duplicate()
	for definition in PROGRESSION: resultat.append(definition.fiche())
	return resultat

# Un identifiant stable sert à la sauvegarde ; le titre peut changer librement.
# Ces premiers succès se vérifient à la victoire, selon la taille de l'escorte.
const SUCCES := [
	{"id": "victoire", "titre": "Victoire !", "description": "Remporter une partie.",
		"rarete": "RARE", "couleur": Color("63a9db"), "escorte_minimum": 0},
	{"id": "sauveteur", "titre": "Sauveteur hors pair", "description": "Remporter une partie avec au moins 10 victimes vivantes dans votre escorte.",
		"rarete": "ÉPIQUE", "couleur": Color("bc83dd"), "escorte_minimum": 10},
]
