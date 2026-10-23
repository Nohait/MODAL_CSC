extends "res://scenes/systemes/sauvegarde/fichier_sauvegarde.gd"

# Les déblocages ne font pas partie des points de reprise supprimés à la mort.
func _init() -> void:
	chemin_fichier = "user://progression_interventions.save"

func _valide(point: Dictionary) -> bool:
	return point.get("version") == VERSION and point.get("formation") is bool \
		and point.get("victoires_apres_formation") is int and point.victoires_apres_formation >= 0 \
		and point.get("zombie_debloque") is bool

static func lire() -> Dictionary:
	var fichier = load("res://scenes/systemes/sauvegarde/progression_interventions.gd").new()
	fichier.charger()
	var etat: Dictionary = fichier.dernier_point.duplicate(true)
	fichier.free()
	return etat

static func enregistrer_formation() -> bool:
	return _enregistrer(false)

static func enregistrer_victoire() -> bool:
	return _enregistrer(true)

static func _enregistrer(victoire: bool) -> bool:
	if Engine.get_meta("tutoriel_debug_actif", false): return true
	var fichier = load("res://scenes/systemes/sauvegarde/progression_interventions.gd").new()
	fichier.charger()
	if not fichier.erreur_lecture.is_empty():
		fichier.free()
		return false
	var etat: Dictionary = fichier.dernier_point.duplicate(true)
	if etat.is_empty():
		etat = {"version": VERSION, "formation": false, "victoires_apres_formation": 0, "zombie_debloque": false}
	if victoire:
		if not etat.formation:
			fichier.free()
			return true
		etat.victoires_apres_formation += 1
		etat.zombie_debloque = true
	else:
		etat.formation = true
	var resultat: bool = fichier.enregistrer(etat)
	fichier.free()
	return resultat
