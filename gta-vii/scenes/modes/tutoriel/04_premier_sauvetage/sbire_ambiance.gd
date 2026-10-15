extends "res://scenes/ennemis/mobiles/sbire.gd"

# Parcours local de l'appartement : conserver déplacement, orientation et repos du sbire.
@export var parcours := PackedVector3Array([
	Vector3(6.2, 0, -1.6), Vector3(7.3, 0, -5.4),
	Vector3(8.2, 0, -8.5), Vector3(7.3, 0, -5.4),
	Vector3(8.8, 0, -1.6)])
var point_parcours := 0

func choisir_destination_idle() -> Vector3:
	if parcours.is_empty(): return global_position
	var destination: Vector3 = get_parent().to_global(parcours[point_parcours])
	# Le comportement commun s'arrête à distance_attaque de sa cible de repos.
	if global_position.distance_to(destination) <= distance_attaque + 0.2:
		point_parcours = (point_parcours + 1) % parcours.size()
		destination = get_parent().to_global(parcours[point_parcours])
	return destination
