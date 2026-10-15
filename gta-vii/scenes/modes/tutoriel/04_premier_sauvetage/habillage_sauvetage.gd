extends RefCounted

const STYLE = preload("res://scenes/modes/tutoriel/commun/decors/construction_interieur.gd")

static func installer(salle: Node3D) -> void:
	# Les chambres mitoyennes ont déjà leur sol et leur mobilier.
	STYLE.porte_fictive(salle, Vector3(-3.96, 0, 0.5), PI / 2)
	STYLE.annexe(salle, preload("res://scenes/decors/interieurs/pieces/cuisine_incendie.tscn"), Vector3(-4.15, 0, -15), PI / 2)
	STYLE.plafonnier(salle, Vector3(0, 2.4, 1))
	STYLE.plafonnier(salle, Vector3(0, 2.4, -14.5))
	STYLE.habiller_existants(salle)
