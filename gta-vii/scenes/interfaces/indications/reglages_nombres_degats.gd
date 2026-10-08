extends Resource

@export_range(0.0, 1000.0, 0.5) var seuil_petits_degats := 5.0
@export_range(0.0, 1000.0, 0.5) var seuil_gros_degats := 20.0
@export var couleur_faible := Color("fff0cb")
@export var couleur_moyenne := Color("ffad45")
@export var couleur_forte := Color("ff5555")
@export_range(0.0, 1.0, 0.05) var eclaircissement_initial := 0.25

func couleur_pour(degats: float) -> Color:
	# Les deux seuils encadrent un dégradé crème → orange → rouge.
	var progression := clampf((degats - seuil_petits_degats) / maxf(seuil_gros_degats - seuil_petits_degats, 0.01), 0.0, 1.0)
	if progression <= 0.5:
		return couleur_faible.lerp(couleur_moyenne, progression * 2.0)
	return couleur_moyenne.lerp(couleur_forte, (progression - 0.5) * 2.0)
