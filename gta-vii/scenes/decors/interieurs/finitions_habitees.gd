@tool
extends Resource
class_name FinitionsHabitees

const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")
const HORLOGE = preload("res://assets/modeles/appartements/wall_clock/wall_clock_1k.gltf")

@export var bois: Material = preload("res://assets/materiaux/appartements/bois_finitions.tres")
@export var peinture: Material = preload("res://assets/materiaux/appartements/white_plaster_02.tres")
@export var peinture_secondaire: Material = preload("res://assets/materiaux/appartements/beige_wall_001.tres")
@export var papiers_peints: Array[Material] = [preload("res://assets/materiaux/appartements/Pattern01.tres"), preload("res://assets/materiaux/appartements/Pattern04.tres")]
@export var teintes_etages: Array[Color] = [Color(0.94, 0.9, 0.81), Color(0.82, 0.9, 0.9), Color(0.88, 0.89, 0.92)]
@export_range(0.0, 1.0, 0.05) var chance_papier_peint := 0.25
@export_range(0.0, 1.0, 0.05) var chance_peinture_secondaire := 0.35
@export_range(0.0, 1.0, 0.05) var chance_horloge := 0.15
@export_range(0.05, 0.25, 0.01) var hauteur_plinthe := 0.1

func cloison(parent: Node3D, zone: Rect2, etage: int, hasard: RandomNumberGenerator) -> void:
	var base := peinture_secondaire if peinture_secondaire != null and hasard.randf() < chance_peinture_secondaire else peinture
	var materiau: Material = base.duplicate()
	if materiau is StandardMaterial3D and not teintes_etages.is_empty():
		materiau.albedo_color *= teintes_etages[clampi(etage - 1, 0, teintes_etages.size() - 1)]
	if not papiers_peints.is_empty() and hasard.randf() < chance_papier_peint:
		materiau = papiers_peints[hasard.randi_range(0, papiers_peints.size() - 1)]
	var centre := zone.get_center()
	GEOMETRIE.bloc(parent, "Cloison", Vector3(centre.x, 1.6, centre.y), Vector3(zone.size.x, 3, zone.size.y), materiau)
	var horizontal := zone.size.x > zone.size.y
	var longueur := maxf(zone.size.x, zone.size.y)
	# Deux plinthes suivent les faces de la cloison, sans surface coplanaire avec le mur.
	var plinthe := bois
	for cote in [-1, 1]:
		var position := Vector3(centre.x, 0.1 + hauteur_plinthe / 2, centre.y)
		position += (Vector3.BACK if horizontal else Vector3.RIGHT) * cote * 0.077
		var taille := Vector3(longueur, hauteur_plinthe, 0.025) if horizontal else Vector3(0.025, hauteur_plinthe, longueur)
		GEOMETRIE.bloc(parent, "Plinthe", position, taille, plinthe)
	if longueur > 2.8 and hasard.randf() < chance_horloge:
		var support := Node3D.new()
		support.position = Vector3(centre.x, 1.85, centre.y) + (Vector3.BACK if horizontal else Vector3.RIGHT) * 0.09
		support.rotation.y = 0 if horizontal else PI / 2
		parent.add_child(support)
		var modele: Node3D = HORLOGE.instantiate()
		support.add_child(modele)
		GEOMETRIE.normaliser(modele, 0.3, true)
