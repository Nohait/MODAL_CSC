extends AudioStreamPlayer3D

## Limite commune à toutes les apparitions, dans les deux modes.
@export_range(1, 8, 1) var maximum_simultanes := 3
## Un seul souffle représente les ennemis qui apparaissent au même endroit.
@export_range(0.0, 10.0, 0.25) var distance_regroupement := 3.0

const GROUPE := &"sons_apparition_actifs"

func _ready() -> void:
	if stream == null:
		queue_free()
		return
	# Le souffle reste au point d'apparition, même si l'ennemi se déplace.
	var origine := global_transform
	top_level = true
	global_transform = origine
	var ecoute: Node3D = get_viewport().get_audio_listener_3d()
	if ecoute == null:
		ecoute = get_viewport().get_camera_3d()
	if ecoute != null and max_distance > 0.0 and global_position.distance_to(ecoute.global_position) >= max_distance:
		queue_free()
		return
	var nombre := 0
	for autre in get_tree().get_nodes_in_group(GROUPE):
		if not autre.is_inside_tree() or autre.is_queued_for_deletion():
			continue
		nombre += 1
		if global_position.distance_to(autre.global_position) < distance_regroupement:
			queue_free()
			return
	if nombre >= maximum_simultanes:
		queue_free()
		return
	# Ne pas différer les sons refusés : ils annonceraient des ennemis déjà présents.
	add_to_group(GROUPE)
	finished.connect(_terminer)
	play()

func _terminer() -> void:
	remove_from_group(GROUPE)
	queue_free()
