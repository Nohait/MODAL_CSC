@tool
extends StaticBody3D

@export var modele: PackedScene
@export_range(2.0, 8.0, 0.1) var longueur := 4.5
@export var peinture := Color("687a88")
@export_range(0.0, 1.0, 0.05) var salissure := 0.25
@export var incendie := false
@export var recolorer := true
@export var retirer_sol_presentation := false
@export var portiere_ouverte := false
@export_range(-180.0, 180.0, 1.0) var orientation_modele := 0.0
const SURFACE = preload("res://assets/shaders/decors/voiture_parking.gdshader")

func _ready() -> void:
	if modele == null: return
	# Une enveloppe commune ramène les modèles à une taille réelle, sans les étirer.
	var pivot := Node3D.new()
	add_child(pivot)
	var visuel := modele.instantiate() as Node3D
	pivot.add_child(visuel)
	var morceaux := visuel.find_children("*", "MeshInstance3D", true, false)
	var boite := AABB()
	var premiere := true
	for morceau: MeshInstance3D in morceaux:
		var decor := false
		for surface in morceau.mesh.get_surface_count():
			var original := morceau.mesh.surface_get_material(surface)
			if original != null and "Concrete_pattern" in original.resource_name: decor = true
		if retirer_sol_presentation and decor:
			morceau.hide()
			continue
		var locale: Transform3D = visuel.global_transform.affine_inverse() * morceau.global_transform
		# Un véhicule articulé peut avoir des sommets stockés dans le repère du squelette.
		# Mesurer sa pose réelle évite de lui donner une échelle différente des autres voitures.
		var maillage := morceau.mesh
		# Sans rendu (tests headless), Godot ne prépare pas les données de skinning.
		if morceau.skin != null and DisplayServer.get_name() != "headless":
			var pose := morceau.bake_mesh_from_current_skeleton_pose()
			if pose != null: maillage = pose
		var bounds: AABB = locale * maillage.get_aabb()
		boite = bounds if premiere else boite.merge(bounds)
		premiere = false
		_habiller(morceau)
	var facteur := longueur / maxf(0.01, maxf(boite.size.x, boite.size.z))
	visuel.position = -boite.get_center() + Vector3.UP * boite.size.y / 2.0
	pivot.scale = Vector3.ONE * facteur
	pivot.rotation.y = deg_to_rad(orientation_modele) + (PI / 2.0 if boite.size.x > boite.size.z else 0.0)
	# Collision simple, indépendante des détails du capot, des roues et de l'intérieur.
	var collision := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(minf(boite.size.x, boite.size.z) * facteur * 0.86, boite.size.y * facteur, longueur * 0.92)
	collision.shape = forme
	collision.position.y = forme.size.y / 2.0
	add_child(collision)
	if portiere_ouverte:
		# La Clio fournit une vraie articulation : ouvrir sa portière sans déformer la caisse.
		for squelette: Skeleton3D in visuel.find_children("*", "Skeleton3D", true, false):
			for os in squelette.get_bone_count():
				if "DoorF.L" not in squelette.get_bone_name(os): continue
				var repere: Basis = squelette.global_basis * squelette.get_bone_global_rest(os).basis
				var axe := (repere.inverse() * Vector3.UP).normalized()
				squelette.set_bone_pose_rotation(os, Quaternion(axe, deg_to_rad(58)))
	if incendie:
		var feu = preload("res://scenes/decors/hall_incendie/foyer_incendie.tscn").instantiate()
		feu.position = Vector3(0, forme.size.y * 0.72, -longueur * 0.25)
		feu.taille = 1.2
		feu.energie = 2.2
		feu.portee_lumiere = 9.0
		feu.densite_fumee = 0.55
		add_child(feu)

func _habiller(morceau: MeshInstance3D) -> void:
	for surface in morceau.mesh.get_surface_count():
		var original := morceau.mesh.surface_get_material(surface) as StandardMaterial3D
		if original == null: continue
		var nom := original.resource_name.to_lower()
		if "shadow" in nom:
			# Supprimer l'ombre dessinée : nos lumières produisent leurs propres ombres.
			morceau.hide()
			continue
		if "glass" in nom:
			var vitre := original.duplicate() as StandardMaterial3D
			vitre.roughness = maxf(0.18, vitre.roughness)
			morceau.set_surface_override_material(surface, vitre)
			continue
		var materiau := ShaderMaterial.new()
		materiau.shader = SURFACE
		materiau.set_shader_parameter("couleur_base", original.albedo_color)
		materiau.set_shader_parameter("texture_presente", original.albedo_texture != null)
		if original.albedo_texture != null: materiau.set_shader_parameter("texture_couleur", original.albedo_texture)
		materiau.set_shader_parameter("relief_present", original.normal_enabled and original.normal_texture != null)
		if original.normal_texture != null: materiau.set_shader_parameter("texture_normale", original.normal_texture)
		var carrosserie := "paint" in nom or nom == "body" or nom == "hatchback_1988" or nom == "material.001"
		materiau.set_shader_parameter("peinture", peinture)
		materiau.set_shader_parameter("recolorer", recolorer and carrosserie)
		materiau.set_shader_parameter("salissure", salissure)
		materiau.set_shader_parameter("rugosite", clampf(original.roughness, 0.3, 1.0))
		materiau.set_shader_parameter("metal", original.metallic)
		morceau.set_surface_override_material(surface, materiau)
