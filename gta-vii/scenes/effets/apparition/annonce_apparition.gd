extends Node3D

signal terminee
@export_range(0.2, 3.0, 0.1) var duree := 1.0
@onready var cercle = $CercleApparition

func _ready() -> void:
	# Poser l'annonce sur la surface réelle, même si le sol a une épaisseur.
	var rayon := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 2.0, global_position - Vector3.UP * 5.0, 1)
	var sol := get_world_3d().direct_space_state.intersect_ray(rayon)
	if not sol.is_empty(): global_position.y = sol.position.y + 0.035
	var animation := create_tween()
	animation.tween_method(cercle.charger, 0.0, 1.0, duree)
	animation.tween_callback(terminee.emit)
	animation.tween_callback(queue_free)
