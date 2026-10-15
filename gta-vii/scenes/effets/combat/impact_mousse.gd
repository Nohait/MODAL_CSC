extends Node3D

@onready var vapeur: CPUParticles3D = $Vapeur
@export_range(0, 16, 1) var nombre_gouttes := 9
@export_range(0.1, 2.0, 0.1) var vitesse_gouttes := 0.8


func lancer(_normale: Vector3) -> void:
	if nombre_gouttes > 0:
		var gouttes := CPUParticles3D.new()
		gouttes.emitting = false
		gouttes.amount = nombre_gouttes
		gouttes.one_shot = true
		gouttes.explosiveness = 1.0
		gouttes.lifetime = 0.3
		gouttes.direction = (_normale + Vector3.UP * 0.35).normalized()
		gouttes.spread = 65.0
		gouttes.initial_velocity_min = vitesse_gouttes * 0.5
		gouttes.initial_velocity_max = vitesse_gouttes
		gouttes.gravity = Vector3(0, -3, 0)
		gouttes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var grain := SphereMesh.new()
		grain.radius = 0.022
		grain.height = 0.044
		grain.radial_segments = 6
		grain.rings = 3
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.93, 0.97, 1.0)
		mat.roughness = 0.85
		grain.material = mat
		gouttes.mesh = grain
		add_child(gouttes)
		gouttes.restart()
	# UP vaut (0, 1, 0) : la montée reste verticale, quelle que soit la direction du jet.
	# Le petit spread du nœud ajoute seulement une dispersion autour de cet axe.
	vapeur.direction = Vector3.UP
	# Chaque particule est un rectangle orienté vers la caméra, aux bords transparents.
	# La courbe de taille le dilate ; le dégradé de couleur fait apparaître puis fondre le nuage.
	vapeur.finished.connect(queue_free)
	vapeur.restart()
