@tool
extends Node3D

enum Composition { VALISE, SAC, CHAISE }
@export var composition := Composition.VALISE
@export var modele: PackedScene
@export_range(0.2, 1.5, 0.05) var largeur_objet := 0.85
@export var couleur_papiers := Color(0.57, 0.53, 0.42)

const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")

func _ready() -> void:
	if modele == null: return
	var support := Node3D.new()
	support.name = "ObjetAbandonne"
	add_child(support)
	var objet: Node3D = modele.instantiate()
	support.add_child(objet)
	var dimensions := GEOMETRIE.normaliser(objet, largeur_objet, false)
	if composition == Composition.CHAISE:
		# Poser la chaise renversée sur le sol au lieu d'enfoncer son dossier dedans.
		support.rotation = Vector3(-1.3, 0.2, 0.12)
		var boite := support.transform * AABB(Vector3(-dimensions.x / 2, 0, -dimensions.z / 2), dimensions)
		support.position.y = -boite.position.y
	var papier := StandardMaterial3D.new()
	papier.albedo_color = couleur_papiers
	papier.roughness = 1.0
	for i in range(5):
		# Une disposition fixe et irrégulière, reproductible au chargement de la scène.
		var feuille := MeshInstance3D.new()
		feuille.name = "Document%d" % i
		var forme := PlaneMesh.new()
		forme.size = Vector2(0.19, 0.27)
		forme.material = papier
		feuille.mesh = forme
		feuille.position = Vector3(0.35 + i * 0.11, 0.005 + i * 0.001, sin(i * 2.3) * 0.38)
		feuille.rotation.y = i * 1.7
		feuille.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(feuille)
