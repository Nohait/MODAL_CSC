extends Node3D

@export_range(0.0, 3.0, 0.01) var hauteur_pivot_modele := 1.35
@export_range(0.5, 5.0, 0.1) var duree_chute := 2.0
@export_range(0.1, 0.95, 0.05) var moment_choc := 0.65
@export_range(0.0, 2.0, 0.1) var attente_au_sol := 0.4
@export_range(0.2, 2.0, 0.1) var duree_dissolution := 1.0
@export_range(-30.0, 6.0, 1.0) var volume_chute := 0.0
@export_range(0.0, 1.0, 0.05) var secousse_chute := 0.25
@export_range(0.5, 4.0, 0.1) var rayon_butin := 2.2
@export_range(0, 80, 1) var braises_chute := 36

var visuel: Node3D
var lecteur: AnimationPlayer
var maillages: Array[Node] = []
var joueur: Node3D

func commencer(modele: Node3D) -> void:
	visuel = modele
	# Garder le vrai squelette : une copie de maillage perdrait la pose de la chute.
	visuel.reparent(self, true)
	# Le pivot du CharacterBody n'est pas le sol : recaler le corps même après un saut.
	var rayon := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, global_position - Vector3.UP * 6.0, 1)
	var sol := get_world_3d().direct_space_state.intersect_ray(rayon)
	if not sol.is_empty():
		global_position.y = sol.position.y + hauteur_pivot_modele
	maillages = visuel.find_children("*", "MeshInstance3D", true, false)
	lecteur = visuel.find_child("AnimationPlayer", true, false)
	joueur = get_tree().get_first_node_in_group("player")
	lecteur.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	lecteur.play("mort", 0.12)
	lecteur.speed_scale = lecteur.get_animation("mort").length / duree_chute
	var refroidissement := create_tween().set_parallel(true)
	for maillage in maillages:
		for surface in range(maillage.mesh.get_surface_count()):
			var original = maillage.get_active_material(surface)
			if original is StandardMaterial3D:
				# Ne modifier ni les autres boss ni le matériau importé partagé.
				var mat := original.duplicate() as StandardMaterial3D
				maillage.set_surface_override_material(surface, mat)
				refroidissement.tween_property(mat, "emission_energy_multiplier", 0.0, duree_chute)
				refroidissement.tween_property(mat, "albedo_color", Color(0.3, 0.27, 0.25), duree_chute)
	var sequence := create_tween()
	sequence.tween_interval(duree_chute * moment_choc)
	sequence.tween_callback(_choc)
	sequence.tween_interval(duree_chute * (1.0 - moment_choc) + attente_au_sol)
	sequence.tween_callback(_dissoudre)

func _choc() -> void:
	var son := AudioStreamPlayer3D.new()
	son.bus = &"Effets"
	son.stream = preload("res://assets/sounds/ennemis/monstre_lave/impact_sol.wav")
	son.volume_db = volume_chute
	son.unit_size = 9.0
	son.max_distance = 30.0
	add_child(son)
	son.play()
	if is_instance_valid(joueur) and joueur.has_method("secouer_camera"):
		joueur.secouer_camera(secousse_chute, 0.3)
	# Réutiliser les braises de contact, à faible intensité et sans second son.
	var braises = preload("res://scenes/effets/combat/impact_boule_feu.tscn").instantiate()
	braises.nombre_braises = braises_chute
	braises.son_impact = null
	add_child(braises)
	var point_chute := global_position + global_basis.z
	var rayon := PhysicsRayQueryParameters3D.create(point_chute + Vector3.UP, point_chute - Vector3.UP * 4.0, 1)
	var sol := get_world_3d().direct_space_state.intersect_ray(rayon)
	point_chute.y = sol.position.y if not sol.is_empty() else global_position.y - 1.35
	son.global_position = point_chute + Vector3.UP * 0.1
	braises.lancer(point_chute, Vector3.UP)

func _dissoudre() -> void:
	lecteur.pause()
	var materiaux: Array[ShaderMaterial] = []
	for maillage in maillages:
		for surface in range(maillage.mesh.get_surface_count()):
			var ancien = maillage.get_active_material(surface)
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scenes/effets/combat/disparition_cendres.gdshader")
			var volume: AABB = maillage.mesh.get_aabb()
			mat.set_shader_parameter("minimum_modele", volume.position)
			mat.set_shader_parameter("dimensions_modele", volume.size)
			if ancien is StandardMaterial3D:
				mat.set_shader_parameter("couleur_depart", ancien.albedo_color)
				if ancien.albedo_texture:
					mat.set_shader_parameter("texture_depart", ancien.albedo_texture)
					mat.set_shader_parameter("texture_depart_active", true)
			maillage.set_surface_override_material(surface, mat)
			materiaux.append(mat)
	var poussieres = preload("res://scenes/effets/combat/disparition_cendres.tscn").instantiate()
	poussieres.duree = duree_dissolution
	add_child(poussieres)
	poussieres.position = Vector3(0.0, -0.8, 1.0)
	poussieres.get_node("Poussieres").emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	poussieres.get_node("Poussieres").emission_box_extents = Vector3(1.2, 0.2, 1.0)
	poussieres.lancer()
	# Appliquer les cendres au corps couché lui-même, sans recréer un modèle debout.
	var disparition := create_tween()
	disparition.tween_method(func(progres: float):
		for mat in materiaux: mat.set_shader_parameter("progression", progres)
	, 0.0, 1.0, duree_dissolution)
	disparition.tween_interval(0.3)
	disparition.tween_callback(queue_free)
