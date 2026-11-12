extends RefCounted

const STYLE = preload("res://scenes/modes/tutoriel/commun/decors/construction_interieur.gd")

static func installer(salle: Node3D) -> void:
	# Les chambres mitoyennes ont déjà leur sol et leur mobilier.
	
	STYLE.eclairage_local(salle, Vector3(0, 2.4, 1))
	STYLE.eclairage_local(salle, Vector3(0, 2.4, -14.5))
	STYLE.habiller_existants(salle)
