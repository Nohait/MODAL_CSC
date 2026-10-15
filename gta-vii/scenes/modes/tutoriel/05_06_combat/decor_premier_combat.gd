extends Node3D

@export var plan: Resource = preload("res://scenes/modes/tutoriel/05_06_combat/plan_premier_combat.tres")

const STYLE = preload("res://scenes/modes/tutoriel/commun/decors/construction_interieur.gd")
var porte_combat: StaticBody3D
var sortie: StaticBody3D
var ennemis: Node3D
var repere_sortie: Node3D

func _ready() -> void:
	var niveau := get_parent()
	if niveau.get("debut_autonome") == true or niveau.get("debut_ravitaillement") == true or niveau.get("debut_sauvetage_menace") == true: return
	STYLE.construire_plan(self, plan)
	for cote in [-1, 1]:
		_bloc("Separation" + str(cote), Vector3(cote * 3.85, 0.6, 3.5), Vector3(4.3, 1.2, 0.3))
	porte_combat = preload("res://scenes/modes/tutoriel/commun/decors/double_porte.tscn").instantiate()
	porte_combat.position = Vector3(0, 1.8, 3.5)
	# Une vitre locale laisse apercevoir le sbire avant d'ouvrir la porte.
	var vitre := StandardMaterial3D.new()
	vitre.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vitre.albedo_color = Color(0.62, 0.76, 0.8, 0.2)
	for cote in ["Gauche", "Droit"]:
		porte_combat.get_node("Vantail" + cote).material_override = vitre
	add_child(porte_combat)
	for cote in [-1, 1]:
		_bloc("SeparationSortie" + str(cote), Vector3(cote * 3.85, 0.675, -7.5), Vector3(4.3, 1.35, 0.25))
	sortie = preload("res://scenes/modes/tutoriel/commun/decors/double_porte.tscn").instantiate()
	sortie.position = Vector3(0, 1.8, -7.5)
	add_child(sortie)
	var porte = preload("res://scenes/modes/tutoriel/commun/decors/double_porte.tscn").instantiate()
	porte.position = Vector3(0, 1.8, 9.8)
	porte.rotation.y = PI
	add_child(porte)
	ennemis = Node3D.new()
	ennemis.name = "Ennemis"
	add_child(ennemis)
	repere_sortie = preload("res://scenes/modes/tutoriel/commun/decors/zone_securite.tscn").instantiate()
	repere_sortie.position = Vector3(0, 0, -8.8)
	add_child(repere_sortie)
	repere_sortie.hide()
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/loungeSofa.glb"), Vector3(-2.2, 0, 6.5), PI * 0.5)
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/tableCoffee.glb"), Vector3(-1.0, 0, 6.5))
	STYLE.meuble(self, preload("res://assets/modeles/decors/appartements/cabinetBed.glb"), Vector3(4.8, 0, -5.8))
	var bibliotheque = preload("res://scenes/decors/interieurs/compositions/bureau.tres").construire()
	bibliotheque.position = Vector3(-8, 0, 0)
	add_child(bibliotheque)
	_panneau("SORTIE", Vector3(0, 2.8, -9.7))

func _bloc(nom: String, position_bloc: Vector3, taille: Vector3) -> StaticBody3D:
	return STYLE.bloc(self, nom, position_bloc, taille, STYLE.SOL if nom == "Sol" else STYLE.MUR)

func _panneau(texte: String, emplacement: Vector3) -> void:
	var label := Label3D.new()
	label.text = texte
	label.position = emplacement
	label.font_size = 48
	label.pixel_size = 0.008
	add_child(label)

func ouvrir_palier() -> void:
	porte_combat.ouvrir()

func ouvrir_sortie() -> void:
	sortie.ouvrir()
	repere_sortie.show()
