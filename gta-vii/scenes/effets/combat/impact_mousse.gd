extends Node3D

@onready var vapeur: CPUParticles3D = $Vapeur


func lancer(_normale: Vector3) -> void:
	# UP vaut (0, 1, 0) : la montée reste verticale, quelle que soit la direction du jet.
	# Le petit spread du nœud ajoute seulement une dispersion autour de cet axe.
	vapeur.direction = Vector3.UP
	# Chaque particule est un rectangle orienté vers la caméra, aux bords transparents.
	# La courbe de taille le dilate ; le dégradé de couleur fait apparaître puis fondre le nuage.
	vapeur.finished.connect(queue_free)
	vapeur.restart()
