@tool
extends Resource
class_name DetailsInterieurs

@export_range(0, 8) var nombre_traces_evacuation := 3
@export var traces: Array[PackedScene] = [preload("res://scenes/decors/interieurs/evacuation_valise.tscn"), preload("res://scenes/decors/interieurs/evacuation_sac.tscn"), preload("res://scenes/decors/interieurs/evacuation_chaise.tscn")]
@export var plinthes_actives := true
@export_range(0.04, 0.25, 0.01) var hauteur_plinthes := 0.12
@export_range(0.02, 0.1, 0.01) var epaisseur_plinthes := 0.045
@export var corniches_actives := true
@export_range(0.02, 0.15, 0.01) var hauteur_corniches := 0.06

const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")

func appliquer(generateur: Node3D, decor: Node3D, bords: Array, etage: int, hasard: RandomNumberGenerator) -> void:
	var details := Node3D.new()
	details.name = "DetailsInterieurs"
	details.add_to_group("details_decor")
	decor.add_child(details)
	_evacuation(generateur, details, bords, hasard)
	_raccords(generateur, details, bords, etage)

func _evacuation(generateur: Node3D, parent: Node3D, bords: Array, hasard: RandomNumberGenerator) -> void:
	if traces.is_empty(): return
	var cellules_utilisees: Array[Vector2i] = []
	for bord in bords:
		if cellules_utilisees.size() >= nombre_traces_evacuation: break
		var cellule: Vector2i = bord[0]
		# Laisser libres les meubles imposants, les arrivées et les portes déjà réservées.
		if cellule not in generateur.cellules_disponibles or cellule in cellules_utilisees: continue
		var normale := Vector3(bord[1].x, 0, bord[1].y)
		var modele: PackedScene = traces[cellules_utilisees.size() % traces.size()]
		if modele == null: continue
		var trace: Node3D = modele.instantiate()
		trace.position = generateur.position_cellule(cellule) + normale * 1.25 + Vector3.UP * 0.105
		trace.rotation.y = atan2(-normale.x, -normale.z) + hasard.randf_range(-0.6, 0.6)
		parent.add_child(trace)
		# Ces petits objets restent traversables et ne retirent pas de point de spawn.
		cellules_utilisees.append(cellule)

func _raccords(generateur: Node3D, parent: Node3D, bords: Array, etage: int) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = [Color(0.25, 0.22, 0.19), Color(0.27, 0.23, 0.2), Color(0.3, 0.33, 0.36)][clampi(etage - 1, 0, 2)]
	mat.roughness = 0.7
	mat.metallic = 0.25 if etage == 3 else 0.0
	for bord in bords:
		var normale := Vector3(bord[1].x, 0, bord[1].y)
		var centre: Vector3 = generateur.position_cellule(bord[0]) + normale * 2.5 + Vector3.UP * 1.6
		for corps in generateur.salle_en_creation.get_node("Navigation/Decor").get_children():
			if not corps.position.is_equal_approx(centre): continue
			for panneau in corps.get_children():
				if not panneau is MeshInstance3D or not panneau.mesh is BoxMesh: continue
				var taille: Vector3 = panneau.mesh.size
				var position: Vector3 = corps.position + panneau.position
				var largeur := taille.x if normale.x == 0 else taille.z
				if largeur <= 0.15: continue
				var decalage := normale * (0.1 + epaisseur_plinthes / 2.0 + 0.006)
				# Suivre chaque panneau réel : ne pas traverser les ouvertures des portes.
				if plinthes_actives and is_equal_approx(position.y - taille.y / 2.0, 0.1):
					var section := Vector3(largeur - 0.02, hauteur_plinthes, epaisseur_plinthes) if normale.x == 0 else Vector3(epaisseur_plinthes, hauteur_plinthes, largeur - 0.02)
					GEOMETRIE.bloc(parent, "Plinthe", Vector3(position.x, 0.1 + hauteur_plinthes / 2.0, position.z) - decalage, section, mat)
				if corniches_actives and is_equal_approx(position.y + taille.y / 2.0, 3.1):
					var section := Vector3(largeur - 0.02, hauteur_corniches, epaisseur_plinthes) if normale.x == 0 else Vector3(epaisseur_plinthes, hauteur_corniches, largeur - 0.02)
					GEOMETRIE.bloc(parent, "Corniche", Vector3(position.x, 3.1 - hauteur_corniches / 2.0, position.z) - decalage, section, mat)
