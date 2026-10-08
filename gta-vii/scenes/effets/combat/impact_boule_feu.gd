extends Node3D

@export_range(4, 40, 1) var nombre_braises := 14
@export_range(0.1, 1.0, 0.05) var duree_braises := 0.45
@export_range(0.2, 2.0, 0.1) var duree_fumee := 0.9
@export_range(0.5, 8.0, 0.5) var vitesse_braises := 3.0
@export_range(0.1, 1.0, 0.05) var taille_eclat := 0.35
@export var son_impact: AudioStream = preload("res://assets/sounds/design/magie/spell_fire_03.ogg")
@export_range(-40.0, 0.0, 1.0) var volume_impact := -18.0

func lancer(point: Vector3, normale: Vector3) -> void:
	global_position = point + normale * 0.04
	var braises := CPUParticles3D.new()
	braises.emitting = false
	braises.amount = nombre_braises
	braises.lifetime = duree_braises
	braises.one_shot = true
	braises.explosiveness = 1.0
	# La normale pointe hors de la surface : les braises repartent vers l'espace libre.
	braises.direction = normale
	braises.spread = 65.0
	braises.gravity = Vector3(0, -3, 0)
	braises.initial_velocity_min = vitesse_braises * 0.5
	braises.initial_velocity_max = vitesse_braises
	braises.damping_min = 1.0
	braises.damping_max = 2.0
	braises.scale_amount_min = 0.5
	braises.scale_amount_max = 1.0
	var grain := SphereMesh.new()
	grain.radius = 0.025
	grain.height = 0.05
	grain.radial_segments = 8
	grain.rings = 4
	grain.material = _matiere(Color(1, 0.55, 0.08), true)
	braises.mesh = grain
	braises.color_ramp = _degrade(Color(1, 0.85, 0.3, 1), Color(1, 0.12, 0.01, 0))
	braises.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(braises)
	braises.restart()

	var fumee := CPUParticles3D.new()
	fumee.emitting = false
	fumee.amount = 5
	fumee.lifetime = duree_fumee
	fumee.one_shot = true
	fumee.explosiveness = 0.9
	fumee.direction = (normale + Vector3.UP * 0.8).normalized()
	fumee.spread = 30.0
	fumee.gravity = Vector3(0, 0.15, 0)
	fumee.initial_velocity_min = 0.3
	fumee.initial_velocity_max = 0.6
	var nuage := QuadMesh.new()
	nuage.size = Vector2(0.45, 0.45)
	var mat := _matiere(Color.WHITE, false)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var texture := GradientTexture2D.new()
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = _degrade(Color(1, 1, 1, 1), Color(1, 1, 1, 0))
	mat.albedo_texture = texture
	nuage.material = mat
	fumee.mesh = nuage
	fumee.color_ramp = _degrade(Color(0.35, 0.25, 0.2, 0.3), Color(0.2, 0.2, 0.2, 0))
	var expansion := Curve.new()
	expansion.add_point(Vector2(0, 0.4))
	expansion.add_point(Vector2(1, 1.5))
	fumee.scale_amount_curve = expansion
	fumee.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fumee)
	fumee.restart()

	# Un éclat visuel court, sans ajouter une lumière dynamique à chaque impact.
	var eclat := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = taille_eclat
	sphere.height = taille_eclat * 2.0
	eclat.mesh = sphere
	var mat_eclat := _matiere(Color(1, 0.65, 0.15, 0.6), true)
	eclat.material_override = mat_eclat
	eclat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(eclat)
	var disparition := create_tween().set_parallel(true)
	disparition.tween_property(eclat, "scale", Vector3.ONE * 0.1, 0.15)
	disparition.tween_property(mat_eclat, "albedo_color:a", 0.0, 0.15)
	if son_impact:
		var son := AudioStreamPlayer3D.new()
		son.stream = son_impact
		son.bus = &"Effets"
		son.volume_db = volume_impact
		son.max_distance = 20.0
		son.unit_size = 6.0
		add_child(son)
		son.play()
	# L'effet survit à la boule, puis libère particules, son et éclat ensemble.
	var nettoyage := create_tween()
	nettoyage.tween_interval(maxf(duree_fumee + 0.2, son_impact.get_length() if son_impact else 0.0))
	nettoyage.tween_callback(queue_free)

func _matiere(couleur: Color, lumineuse: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = couleur
	if lumineuse:
		mat.emission_enabled = true
		mat.emission = couleur
		mat.emission_energy_multiplier = 1.5
	return mat

func _degrade(debut: Color, fin: Color) -> Gradient:
	var degrade := Gradient.new()
	degrade.colors = PackedColorArray([debut, fin])
	return degrade
