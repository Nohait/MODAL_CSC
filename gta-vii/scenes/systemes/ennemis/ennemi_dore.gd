extends Node

var materiaux_initiaux: Array[Material] = []

func _ready() -> void:
	# Remplacer les matériaux, et pas seulement ajouter un contour jaune.
	var materiau_or := ShaderMaterial.new()
	materiau_or.shader = preload("res://scenes/systemes/ennemis/ennemi_dore.gdshader")
	for mesh in get_parent().find_children("*", "MeshInstance3D", true, false):
		# Les lasers et zones d'attaque gardent leur lisibilité et leur transparence.
		if mesh.name in ["Laser", "Disque", "Cercle"] or str(mesh.name).begins_with("Zone"): continue
		var initial = mesh.material_override
		if initial != null: materiaux_initiaux.append(initial)
		if initial is ShaderMaterial and initial.shader.resource_path.ends_with("visuel_flaque.gdshader"):
			# Garder le contour irrégulier et transparent des flaques.
			var flaque = initial.duplicate()
			flaque.set_shader_parameter("couleur_sombre", Color("8b5a10"))
			flaque.set_shader_parameter("couleur_braise", Color("ffdb55"))
			mesh.material_override = flaque
		elif initial != null:
			mesh.material_override = materiau_or
		else:
			# Préparer toutes les surfaces avant d'afficher la copie évite les matériaux manquants des imports.
			var copie = mesh.mesh.duplicate()
			for surface in range(copie.get_surface_count()):
				copie.surface_set_material(surface, materiau_or)
			mesh.mesh = copie
	for particules in get_parent().find_children("*", "GPUParticles3D", true, false):
		if particules.process_material is ParticleProcessMaterial:
			particules.process_material = particules.process_material.duplicate()
			particules.process_material.color = Color(2.0, 1.6, 0.3, 1.0)
	# Les flammes CPU gardent aussi la couleur de la variante dorée.
	for particules in get_parent().find_children("*", "CPUParticles3D", true, false):
		particules.color = Color(2.0, 1.6, 0.3, 1.0)
