extends Node3D

@onready var vapeur: CPUParticles3D = $Vapeur
@onready var gouttes: CPUParticles3D = $Gouttes
@export_range(0, 16, 1) var nombre_gouttes := 9
@export_range(0.1, 2.0, 0.1) var vitesse_gouttes := 0.8


func lancer(_normale: Vector3) -> void:
	if nombre_gouttes > 0:
		gouttes.amount = nombre_gouttes
		gouttes.direction = (_normale + Vector3.UP * 0.35).normalized()
		gouttes.initial_velocity_min = vitesse_gouttes * 0.5
		gouttes.initial_velocity_max = vitesse_gouttes
		gouttes.restart()
	# UP vaut (0, 1, 0) : la montée reste verticale, quelle que soit la direction du jet.
	# Le petit spread du nœud ajoute seulement une dispersion autour de cet axe.
	vapeur.direction = Vector3.UP
	# Chaque particule est un rectangle orienté vers la caméra, aux bords transparents.
	# La courbe de taille le dilate ; le dégradé de couleur fait apparaître puis fondre le nuage.
	vapeur.finished.connect(queue_free)
	vapeur.restart()
