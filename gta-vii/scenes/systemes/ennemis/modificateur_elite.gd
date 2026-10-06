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
@export_range(0.0, 2.0, 0.05) var intensite_visuelle := 0.8
@export_range(0, 30, 1) var particules_visuelles := 8
@export_range(0.0, 1.5, 0.05) var intensite_zone_aura := 0.65
