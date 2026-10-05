@tool
extends Node3D

@export var modele_scene: PackedScene
@export_range(0.1, 3.0, 0.05) var hauteur := 1.0:
	set(valeur):
		hauteur = valeur
		if is_node_ready(): _ajuster_taille()
@export_range(0.0, 1.0, 0.05) var suie := 0.25:
	set(valeur):
		suie = valeur
		if is_node_ready() and materiau_suie != null:
			materiau_suie.set_shader_parameter("quantite", suie)

var modele: Node3D
var bornes := AABB()
var materiau_suie: ShaderMaterial

func _ready() -> void:
	if modele_scene == null: return
	modele = modele_scene.instantiate()
	add_child(modele)
	materiau_suie = ShaderMaterial.new()
	materiau_suie.shader = preload("res://assets/shaders/decors/suie_mobilier.gdshader")
	materiau_suie.set_shader_parameter("quantite", suie)
	var premiere := true
	for enfant in modele.find_children("*", "MeshInstance3D", true, false):
		# Mesurer dans le repère du modèle, même si l'import contient plusieurs sous-objets.
		var transformation: Transform3D = modele.global_transform.affine_inverse() * enfant.global_transform
		var boite: AABB = transformation * enfant.get_aabb()
		bornes = boite if premiere else bornes.merge(boite)
		premiere = false
		enfant.material_overlay = materiau_suie
	_ajuster_taille()

func _ajuster_taille() -> void:
	if modele == null or bornes.size.y <= 0.001: return
	# Un facteur unique conserve les proportions ; poser le bas du modèle au sol.
	var facteur := hauteur / bornes.size.y
	modele.scale = Vector3.ONE * facteur
	var centre := bornes.get_center()
	modele.position = -Vector3(centre.x, bornes.position.y, centre.z) * facteur
