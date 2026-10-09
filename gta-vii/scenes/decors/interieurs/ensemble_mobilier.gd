@tool
extends Node3D

var foyer := Vector3(0, 0.6, 0)

func position_foyer() -> Vector3:
	# Le générateur conserve son propre budget d'incendies pour toute la salle.
	return foyer
