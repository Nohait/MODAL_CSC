extends Node3D

@export var plan: Resource = preload("res://scenes/modes/tutoriel/08_sauvetage_sous_menace/plan_sauvetage_sous_menace.tres")

const STYLE = preload("res://scenes/modes/tutoriel/commun/decors/construction_interieur.gd")
const DOUBLE_PORTE = preload("res://scenes/modes/tutoriel/commun/decors/double_porte.tscn")
const PORTE_SORTIE = preload("res://scenes/decors/porte_sortie.tscn")
const REPERE_PASSAGE = preload("res://scenes/modes/tutoriel/commun/decors/repere_passage.tscn")
const ARRIVEE := Vector3(10, 0, -64)
var ennemis: Node3D
var porte: StaticBody3D
var sortie: Node3D
var repere_sortie: Node3D
var liaison: NavigationRegion3D
const PORTE_POSITION := Vector3(0, 1.8, -54)

func _ready() -> void:
	STYLE.construire_plan(self, plan)
	STYLE.ouvrir_mur(self, &"MurFixe0", Vector3(0, 0, -46), 3.6)
	var porte_arrivee = DOUBLE_PORTE.instantiate()
	porte_arrivee.name = "PorteArrivee"
	porte_arrivee.position = Vector3(0, 1.8, -46)
	porte_arrivee.rotation.y = PI
	add_child(porte_arrivee)
	STYLE.ouvrir_mur(self, &"MurFixe5", Vector3(14, 0, -63), 2.5)
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
	porte = DOUBLE_PORTE.instantiate()
	porte.position = PORTE_POSITION
	add_child(porte)
	var repere = preload("res://scenes/modes/tutoriel/commun/decors/zone_securite.tscn").instantiate()
	repere.position = ARRIVEE
	add_child(repere)
	sortie = PORTE_SORTIE.instantiate()
	sortie.name = "PorteSortie"
	sortie.position = Vector3(13.88, 0.1, -63)
	sortie.rotation.y = -PI * 0.5
	add_child(sortie)
	sortie.get_node("Voyant").hide()
	sortie.get_node("BoitierSortie").hide()
	repere_sortie = REPERE_PASSAGE.instantiate()
	repere_sortie.position = Vector3(0, 0, 1.65)
	repere_sortie.hide()
	sortie.add_child(repere_sortie)
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

func autoriser_sortie() -> void:
	sortie.autoriser()
	repere_sortie.show()

func masquer_repere_sortie() -> void:
	repere_sortie.hide()
