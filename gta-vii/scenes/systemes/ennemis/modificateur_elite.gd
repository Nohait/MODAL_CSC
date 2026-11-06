class_name ModificateurElite
extends Resource

@export var identifiant := ""
@export var titre := ""
@export_multiline var description := ""
@export var couleur := Color.ORANGE
@export var symbole := "!"
@export_range(0.0, 100.0) var poids := 1.0
@export var taille := 1.0
@export var vie := 1.0
@export var vitesse := 1.0
@export var degats := 1.0
@export_range(0.0, 1.0) var seuil_rage := 0.0
@export_enum("aucune", "vitesse", "resistance", "degats") var aura := "aucune"
@export var rayon_aura := 5.0
@export var bonus_aura := 0.25

@export_group("Signature visuelle")
## Couleur stable sur tout le corps, indépendante de la luminosité du contour.
@export_range(0.0, 0.8, 0.05) var opacite_couleur_corps := 0.45
## Transparence du halo et émission lumineuse indépendantes des zones au sol.
@export_range(0.0, 2.0, 0.05) var intensite_halo := 0.65
@export_range(0.0, 2.0, 0.05) var emission_halo := 0.1
@export_range(1.0, 2.0, 0.05) var halo_rage := 1.25
@export_range(0.0, 2.0, 0.05) var intensite_visuelle := 0.8
@export_range(0, 30, 1) var particules_visuelles := 8
@export_range(0.0, 1.5, 0.05) var intensite_zone_aura := 0.65
