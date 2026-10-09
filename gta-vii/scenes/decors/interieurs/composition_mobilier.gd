@tool
extends Resource
class_name CompositionMobilier

const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")

@export var titre := "Salon"
@export var modeles: Array[PackedScene] = []
@export var positions: Array[Vector3] = []
@export var hauteurs: Array[float] = []
@export var orientations: Array[float] = []
@export var sol: Material
@export var lampes: Array[int] = []
@export_range(0.0, 2.0, 0.05) var energie_lampes := 0.6
@export_range(1.0, 5.0, 0.1) var portee_lampes := 2.5

func construire() -> Node3D:
	var ensemble := Node3D.new()
	ensemble.set_script(preload("res://scenes/decors/interieurs/ensemble_mobilier.gd"))
	ensemble.name = titre.validate_node_name()
	if sol != null: ensemble.set_meta("revetement_sol", sol)
	for i in range(modeles.size()):
		if modeles[i] == null: continue
		var support := Node3D.new()
		support.position = positions[i] if i < positions.size() else Vector3.ZERO
		support.rotation_degrees.y = orientations[i] if i < orientations.size() else 0.0
		ensemble.add_child(support)
		var modele: Node3D = modeles[i].instantiate()
		support.add_child(modele)
		# Centrer le modèle et poser sa base sur le support, sans déformer ses proportions.
		GEOMETRIE.normaliser(modele, hauteurs[i] if i < hauteurs.size() else 1.0, true)
		if i == 0: ensemble.foyer = support.position + Vector3.UP * (hauteurs[i] if i < hauteurs.size() else 1.0) * 0.65
		if i in lampes:
			# La lampe éclaire son meuble, avec une courte portée et sans ombres coûteuses.
			var lumiere := OmniLight3D.new()
			lumiere.position.y = (hauteurs[i] if i < hauteurs.size() else 1.0) * 0.8
			lumiere.light_color = Color(1.0, 0.79, 0.52)
			lumiere.light_energy = energie_lampes
			lumiere.omni_range = portee_lampes
			support.add_child(lumiere)
	return ensemble

func limites(ensemble: Node3D) -> AABB:
	var boite := AABB()
	var premiere := true
	for surface: MeshInstance3D in ensemble.find_children("*", "MeshInstance3D", true, false):
		var transfo := Transform3D.IDENTITY
		var noeud: Node3D = surface
		while noeud != ensemble:
			transfo = noeud.transform * transfo
			noeud = noeud.get_parent()
		var volume := transfo * surface.get_aabb()
		boite = volume if premiere else boite.merge(volume)
		premiere = false
	return boite
