extends Node3D

@export_range(2, 24, 1) var quantite := 8
@export_range(0.5, 3.0, 0.1) var taille := 1.6

func _ready() -> void:
	# Réutiliser seulement la fumée du foyer, sans flamme, lumière ou crépitement.
	var source := preload("res://scenes/decors/hall_incendie/foyer_incendie.tscn").instantiate()
	var fumee: CPUParticles3D = source.get_node("Fumee")
	source.remove_child(fumee)
	source.free()
	fumee.amount = quantite
	fumee.scale = Vector3.ONE * taille
	fumee.position = Vector3.ZERO
	fumee.direction = Vector3(0, 1, 0.2)
	add_child(fumee)
