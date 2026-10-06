@tool
extends Node3D

@export var modele: PackedScene
@export_range(0.05, 10.0, 0.05) var largeur := 2.0
@export var centrer_verticalement := false
@export var morceau_choisi := ""
@export var prefixe_morceaux := ""
@export var collision := false
@export var aligner_avant := false

func _ready() -> void:
	if modele == null: return
	var objet := modele.instantiate() as Node3D
	add_child(objet)
	var boite := AABB()
	var premier := true
	for morceau: MeshInstance3D in objet.find_children("*", "MeshInstance3D", true, false):
		# Un pack modulaire contient toutes les pièces : ne garder que celle voulue.
		if (not morceau_choisi.is_empty() and morceau.name != morceau_choisi) or (not prefixe_morceaux.is_empty() and not morceau.name.begins_with(prefixe_morceaux)):
			morceau.free()
			continue
		var transformation: Transform3D = objet.global_transform.affine_inverse() * morceau.global_transform
		var bounds: AABB = transformation * morceau.get_aabb()
		boite = bounds if premier else boite.merge(bounds)
		premier = false
	if premier:
		push_warning("Aucun morceau trouvé pour cet accessoire : " + morceau_choisi)
		objet.queue_free()
		return
	# Les grilles se centrent au mur ; la barrière repose sur le plancher.
	var facteur := largeur / maxf(boite.size.x, 0.01)
	objet.scale = Vector3.ONE * facteur
	objet.position = -boite.get_center() * facteur
	# Un rideau doit rester au seuil ; ses rails s'étendent derrière lui.
	if aligner_avant: objet.position.z = -boite.end.z * facteur
	if not centrer_verticalement: objet.position.y += boite.size.y * facteur / 2.0
	if collision:
		# Une seule boîte suffit pour contourner un objet posé au sol.
		var corps := StaticBody3D.new()
		corps.collision_layer = 1
		corps.collision_mask = 0
		var enveloppe := CollisionShape3D.new()
		var forme := BoxShape3D.new()
		forme.size = boite.size * facteur
		enveloppe.shape = forme
		if not centrer_verticalement: enveloppe.position.y = forme.size.y / 2.0
		add_child(corps)
		corps.add_child(enveloppe)
