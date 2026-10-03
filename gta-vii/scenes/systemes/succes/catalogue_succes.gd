extends RefCounted

# Un identifiant stable sert à la sauvegarde ; le titre peut changer librement.
# Ces premiers succès se vérifient à la victoire, selon la taille de l'escorte.
const SUCCES := [
	{"id": "victoire", "titre": "Victoire !", "description": "Remporter une partie.",
		"rarete": "RARE", "couleur": Color("63a9db"), "escorte_minimum": 0},
	{"id": "sauveteur", "titre": "Sauveteur hors pair", "description": "Remporter une partie avec au moins 10 victimes vivantes dans votre escorte.",
		"rarete": "ÉPIQUE", "couleur": Color("bc83dd"), "escorte_minimum": 10},
]
