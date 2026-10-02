extends Node3D

const SHADER = preload("res://scenes/effets/combat/disparition_cendres.gdshader")
var materiaux: Array[ShaderMaterial] = []
@export_range(0.2, 2.0, 0.05) var duree := 0.7
@onready var poussieres: CPUParticles3D = $Poussieres


func capturer(racines: Array[Node3D]) -> void:
	# Copier uniquement les maillages : aucun script d'ennemi, agent, lumière ou collision.
	var volume := AABB()
	var premier_maillage := true
	for racine in racines:
		var maillages: Array[Node] = racine.find_children("*", "MeshInstance3D", true, false)
		if racine is MeshInstance3D:
			maillages.append(racine)
		for original in maillages:
			if original.mesh == null or not original.is_visible_in_tree():
				continue
			var copie := MeshInstance3D.new()
			copie.mesh = original.mesh # La géométrie est partagée, pas recalculée.
			copie.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(copie)
			copie.global_transform = original.global_transform
			var volume_maillage: AABB = copie.transform * original.mesh.get_aabb()
			volume = volume_maillage if premier_maillage else volume.merge(volume_maillage)
			premier_maillage = false
			var mat := ShaderMaterial.new()
			mat.shader = SHADER
			var bounds: AABB = original.mesh.get_aabb()
			mat.set_shader_parameter("minimum_modele", bounds.position)
			mat.set_shader_parameter("dimensions_modele", bounds.size)
			var ancien = original.get_active_material(0)
			if ancien is StandardMaterial3D:
				mat.set_shader_parameter("couleur_depart", ancien.albedo_color)
				if ancien.albedo_texture:
					mat.set_shader_parameter("texture_depart", ancien.albedo_texture)
					mat.set_shader_parameter("texture_depart_active", true)
			copie.material_override = mat
			materiaux.append(mat)
	# Émettre autour de tout le corps, plutôt qu'uniquement au pied d'une grande tour.
	if not premier_maillage:
		poussieres.position = volume.get_center()
		poussieres.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		poussieres.emission_box_extents = volume.size * 0.4


func lancer() -> void:
	poussieres.restart()
	var animation := create_tween()
	# tween_method appelle notre fonction avec toutes les valeurs de 0 à 1.
	# Le même progrès est transmis à chaque maillage du corps pendant la dissolution.
	animation.tween_method(_actualiser_dissolution, 0.0, 1.0, duree)
	# Laisser finir les poussières avant de supprimer l'effet. Ce Tween respecte la pause.
	animation.tween_interval(maxf(0.0, poussieres.lifetime - duree) + 0.1)
	animation.tween_callback(queue_free)


func _actualiser_dissolution(progression: float) -> void:
	for mat in materiaux:
		mat.set_shader_parameter("progression", progression)
