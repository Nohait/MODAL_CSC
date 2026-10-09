@tool
extends Node3D
class_name EspaceDecoratif

@export var aspect: AspectPieceInaccessible = preload("res://scenes/salles/aspect_pieces_inaccessibles.tres")
@export_range(-35.0, 0.0, 1.0) var volume_foyers := -14.0

func _ready() -> void:
	# Même règle pour une pièce préparée et un espace construit : aucun obstacle de navigation.
	for collision in find_children("*", "CollisionShape3D", true, false): collision.disabled = true
	for corps in find_children("*", "CollisionObject3D", true, false):
		corps.collision_layer = 0
		corps.collision_mask = 0
		corps.remove_from_group("collider")
	_preparer_foyers()
	if aspect != null: aspect.appliquer(self)

func _preparer_foyers() -> void:
	var meubles: Array[Node3D] = []
	for noeud in find_children("*", "Node3D", true, false):
		if noeud.has_method("position_foyer"): meubles.append(noeud)
	for foyer in find_children("*", "Node3D", true, false):
		if not foyer.scene_file_path.ends_with("foyer_incendie.tscn"): continue
		foyer.get_node("Lumiere").shadow_enabled = false
		foyer.get_node("Crepitement").volume_db = volume_foyers
		var extinction := foyer.get_node("Extinction")
		if is_instance_valid(extinction.mobilier): continue
		var distance := INF
		for meuble in meubles:
			var ecart: float = foyer.global_position.distance_squared_to(meuble.to_global(meuble.position_foyer()))
			if ecart < distance:
				distance = ecart
				extinction.mobilier = meuble

func surfaces() -> Array[MeshInstance3D]:
	var resultat: Array[MeshInstance3D] = []
	for enfant in get_children():
		if enfant is MeshInstance3D and (enfant.name.begins_with("Sol") or enfant.name.begins_with("Mur")):
			resultat.append(enfant)
	return resultat

func adapter_materiaux(sol: Material, murs: Material) -> void:
	for surface in surfaces():
		surface.mesh = surface.mesh.duplicate()
		surface.mesh.material = sol if surface.name.begins_with("Sol") else murs
