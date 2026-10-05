extends RefCounted

# Définitions partagées par le glossaire et le sélecteur de debug.
# Les compositions de vagues continuent de décider des types disponibles.
# hauteur correspond au décalage de la racine au-dessus du sol.
const ENNEMIS = [
	{"id": "sbire", "cout_difficulte": 1, "description": "Poursuit le pompier ou les victimes et frappe au corps à corps. Ses flammes annoncent le coup.", "elite_possible": true, "nom": "Sbire", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/sbire.tscn"), "hauteur": 0.85},
	{"id": "chien", "cout_difficulte": 1, "description": "Court vers le pompier, bondit avec son élan puis mord lorsqu’il est très proche.", "elite_possible": true, "nom": "Chien de magma", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/chien_magma/chien_magma.tscn"), "hauteur": 0.85},
	{"id": "demolisseur", "cout_difficulte": 3, "description": "Ennemi lent et robuste. Privilégie le camion lorsqu’il est présent.", "nom": "Démolisseur", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/demolisseur/demolisseur.tscn"), "hauteur": 1.45},
	{"id": "artilleur", "cout_difficulte": 2, "description": "Tire des boules de feu annoncées depuis son sceptre.", "nom": "Artilleur", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/artilleur/artilleur.tscn"), "hauteur": 1.45},
	{"id": "kamikaze", "cout_difficulte": 1, "description": "Crâne volant qui poursuit le pompier avec un retard de direction et explose au contact.", "elite_possible": true, "nom": "Kamikaze", "categorie": "Mobiles", "scene": preload("res://scenes/ennemis/mobiles/kamikaze/kamikaze.tscn"), "hauteur": 1.2},
	{"id": "tourelle", "cout_difficulte": 1, "description": "Ennemi fixe. Son laser annonce le tir ; sortir de sa portée interrompt la visée.", "nom": "Tour enflammée", "categorie": "Immobiles", "scene": preload("res://scenes/ennemis/tourelles/tour_enflammee.tscn"), "hauteur": 0.1},
	{"id": "flaque", "cout_difficulte": 1, "description": "Zone de feu qui blesse les personnages à son contact.", "nom": "Flaque de feu", "categorie": "Immobiles", "scene": preload("res://scenes/ennemis/dangers/flaque_de_feu.tscn"), "hauteur": 0.2},
	{"id": "mini_boss", "cout_difficulte": 8, "description": "Mini-boss qui alterne une frappe proche et une salve de boules de feu.", "nom": "Monstre de lave", "categorie": "Mini-boss", "scene": preload("res://scenes/ennemis/mini_boss/monstre_lave/monstre_lave.tscn"), "hauteur": 1.45}
]

static func trouver(identifiant: String) -> Dictionary:
	for ennemi in ENNEMIS:
		if ennemi.id == identifiant: return ennemi
	return {}

