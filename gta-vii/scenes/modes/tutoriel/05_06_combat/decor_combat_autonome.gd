extends Node3D

@export var plan: Resource = preload("res://scenes/modes/tutoriel/05_06_combat/plan_combat_autonome.tres")

const STYLE = preload("res://scenes/modes/tutoriel/commun/decors/construction_interieur.gd")
const PORTE = preload("res://scenes/modes/tutoriel/commun/decors/double_porte.tscn")
var porte_combat: StaticBody3D
var sortie: Node3D
var sortie_ouverte := false
var ennemis: Node3D
var repere_sortie: Node3D
const POSITION_CREATURE := Vector3(3, 0, -22)

func _ready() -> void:
	STYLE.construire_plan(self, plan)
	porte_combat = PORTE.instantiate()
	porte_combat.position = Vector3(0, 1.8, -16)
	var vitre := StandardMaterial3D.new()
	vitre.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vitre.albedo_color = Color(0.62, 0.76, 0.8, 0.2)
	for cote in ["Gauche", "Droit"]:
		porte_combat.get_node("Vantail" + cote).material_override = vitre
	add_child(porte_combat)
	for cote in [-1, 1]:
		STYLE.bloc(self, "MurSortie" + str(cote), Vector3(cote * 4.125, 0.6, -28), Vector3(5.75, 1.2, 0.3), STYLE.MUR)
	sortie = preload("res://scenes/decors/porte_sortie.tscn").instantiate()
	sortie.position = Vector3(0, 0, -28)
	add_child(sortie)
	sortie.ouverte.connect(_sortie_prete)
	ennemis = Node3D.new()
	ennemis.name = "Ennemis"
	add_child(ennemis)
	# Mobilier sur les côtés, pour conserver une aire de combat ouverte et plus large.
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/loungeSofa.glb"), Vector3(-5.5, 0, -23), PI * 0.5)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/cabinetBed.glb"), Vector3(5.5, 0, -26))
	var repas = preload("res://scenes/decors/interieurs/compositions/coin_repas.tres").construire()
	repas.position = Vector3(9, 0, -21.5)
	add_child(repas)
	repere_sortie = preload("res://scenes/modes/tutoriel/commun/decors/zone_securite.tscn").instantiate()
	repere_sortie.position = Vector3(0, 0, -29)
	add_child(repere_sortie)
	repere_sortie.hide()

func ouvrir_palier() -> void:
	porte_combat.ouvrir()

func ouvrir_sortie() -> void:
	sortie.ouvrir()

func _sortie_prete() -> void:
	sortie_ouverte = true
	repere_sortie.show()
