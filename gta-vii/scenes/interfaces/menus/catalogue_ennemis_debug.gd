extends RefCounted

# Le catalogue sert seulement au debug : il ne modifie pas les vagues automatiques.
# hauteur correspond au décalage de la racine au-dessus du sol.
const ENNEMIS = [
	{"id": "sbire", "nom": "Sbire", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/sbire.tscn"), "hauteur": 0.85},
	{"id": "chien", "nom": "Chien de magma", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/chien_magma/chien_magma.tscn"), "hauteur": 0.85},
	{"id": "demolisseur", "nom": "Démolisseur", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/demolisseur/demolisseur.tscn"), "hauteur": 1.45},
	{"id": "artilleur", "nom": "Artilleur", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/artilleur/artilleur.tscn"), "hauteur": 1.45},
	{"id": "kamikaze", "nom": "Kamikaze", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/kamikaze/kamikaze.tscn"), "hauteur": 1.2},
	{"id": "tourelle", "nom": "Tour enflammée", "categorie": "Immobiles", "scene": preload("res://scenes/ennemis/tourelles/tour_enflammee.tscn"), "hauteur": 0.1},
	{"id": "flaque", "nom": "Flaque de feu", "categorie": "Immobiles", "scene": preload("res://scenes/ennemis/dangers/flaque_de_feu.tscn"), "hauteur": 0.2},
	{"id": "mini_boss", "nom": "Monstre de lave", "categorie": "Mini-boss", "scene": preload("res://scenes/ennemis/mini_boss/monstre_lave/monstre_lave.tscn"), "hauteur": 1.45}
]

static func trouver(identifiant: String) -> Dictionary:
	for ennemi in ENNEMIS:
		if ennemi.id == identifiant: return ennemi
	return {}

