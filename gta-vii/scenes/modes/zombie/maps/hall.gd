extends "res://scenes/salles/salle.gd"

func _ready() -> void:
	# Des marqueurs éditables remplacent les positions tirées par le générateur.
	entree = $Entree
	for point in $PointsApparition.get_children():
		points_spawn.append(point.position)
	super._ready()
