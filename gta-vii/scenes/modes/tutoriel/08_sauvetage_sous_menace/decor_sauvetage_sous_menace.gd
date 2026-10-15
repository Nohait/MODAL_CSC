extends Node3D

@export var plan: Resource = preload("res://scenes/modes/tutoriel/08_sauvetage_sous_menace/plan_sauvetage_sous_menace.tres")

const STYLE = preload("res://scenes/modes/tutoriel/commun/decors/construction_interieur.gd")
const ARRIVEE := Vector3(10, 0, -64)
var ennemis: Node3D
var porte: StaticBody3D
var liaison: NavigationRegion3D
const PORTE_POSITION := Vector3(0, 1.8, -54)

func _ready() -> void:
	STYLE.construire_plan(self, plan)
	for cote in [-1, 1]: STYLE.bloc(self, "Cloison" + str(cote), Vector3(cote * 3.8425, 0.6, -54), Vector3(4.315, 1.2, 0.3), STYLE.MUR)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/loungeSofa.glb"), Vector3(-5.3, 0, -50), PI * 0.5)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/tableCoffee.glb"), Vector3(-5, 0, -48))
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/cabinetBed.glb"), Vector3(3.3, 0, -48))
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/kitchenSink.glb"), Vector3(13.3, 0, -61.5), -PI * 0.5)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/kitchenStove.glb"), Vector3(13.3, 0, -63.5), -PI * 0.5)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/kitchenFridge.glb"), Vector3(12, 0, -65.3))
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/loungeSofa.glb"), Vector3(-3.3, 0, -61.5), PI * 0.5)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/tableCoffee.glb"), Vector3(-3, 0, -64.5))
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/table.glb"), Vector3(9, 0, -60.7))
	porte = preload("res://scenes/modes/tutoriel/commun/decors/double_porte.tscn").instantiate()
	porte.position = PORTE_POSITION
	add_child(porte)
	var repere = preload("res://scenes/modes/tutoriel/commun/decors/zone_securite.tscn").instantiate()
	repere.position = ARRIVEE
	add_child(repere)
	var nav := NavigationRegion3D.new()
	var mesh := NavigationMesh.new()
	# Bords subdivisés : le corridor de porte partage exactement ses arêtes avec les pièces.
	mesh.vertices = PackedVector3Array([
		Vector3(-4.7, 0, -46.4), Vector3(2.7, 0, -46.4), Vector3(2.7, 0, -53.3),
		Vector3(0.85, 0, -53.3), Vector3(-0.85, 0, -53.3), Vector3(-4.7, 0, -53.3),
		Vector3(-2.7, 0, -54.7), Vector3(-0.85, 0, -54.7), Vector3(0.85, 0, -54.7),
		Vector3(4.7, 0, -54.7), Vector3(4.7, 0, -60.6), Vector3(4.7, 0, -64.8),
		Vector3(4.7, 0, -65.3), Vector3(-2.7, 0, -65.3),
		Vector3(12.6, 0, -60.6), Vector3(12.6, 0, -64.8)])
	mesh.add_polygon(PackedInt32Array([0, 1, 2, 3, 4, 5]))
	mesh.add_polygon(PackedInt32Array([6, 7, 8, 9, 10, 11, 12, 13]))
	mesh.add_polygon(PackedInt32Array([10, 14, 15, 11]))
	nav.navigation_mesh = mesh
	add_child(nav)
	liaison = NavigationRegion3D.new()
	liaison.enabled = false
	var seuil := NavigationMesh.new()
	seuil.vertices = PackedVector3Array([Vector3(-0.85, 0, -53.3), Vector3(0.85, 0, -53.3), Vector3(0.85, 0, -54.7), Vector3(-0.85, 0, -54.7)])
	seuil.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	liaison.navigation_mesh = seuil
	add_child(liaison)
	ennemis = Node3D.new()
	ennemis.name = "Ennemis"
	add_child(ennemis)
