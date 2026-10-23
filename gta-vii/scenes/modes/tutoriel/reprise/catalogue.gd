extends RefCounted

const SALLES: Array[Resource] = [
	preload("res://scenes/modes/tutoriel/reprise/00_parvis.tres"),
	preload("res://scenes/modes/tutoriel/reprise/04_sauvetage.tres"),
	preload("res://scenes/modes/tutoriel/reprise/05_combat.tres"),
	preload("res://scenes/modes/tutoriel/reprise/06_pratique.tres"),
	preload("res://scenes/modes/tutoriel/reprise/07_poste.tres"),
	preload("res://scenes/modes/tutoriel/reprise/08_menace.tres"),
	preload("res://scenes/modes/tutoriel/reprise/09_points_1.tres"),
	preload("res://scenes/modes/tutoriel/reprise/10_points_2.tres")]

static func trouver(identifiant: StringName) -> Resource:
	for salle in SALLES:
		if salle.identifiant == identifiant: return salle
	return null
