extends "res://scenes/systemes/sauvegarde/fichier_sauvegarde.gd"

func _init() -> void:
	chemin_fichier = "user://partie_zombie.save"

func _preparer_mode(point: Dictionary) -> void:
	get_tree().set_meta("map_zombie", point.map)

func _valide(point: Dictionary) -> bool:
	if point.get("version") != VERSION or not point.get("vague") is int or point.vague < 1: return false
	for cle in ["map", "composition"]:
		var chemin = point.get(cle)
		if not chemin is String or not chemin.begins_with("res://scenes/modes/zombie/") or not ResourceLoader.exists(chemin): return false
	if not point.get("graine") is int: return false
	for cle in ["joueur", "ameliorations", "escorte", "refuge", "statistiques", "score", "succes", "arene"]:
		if not point.get(cle) is Dictionary: return false
	if not point.get("pieces") is int or not point.get("vagues_terminees") is int: return false
	if not point.joueur.get("position") is Vector3 or not point.joueur.get("arme") is Dictionary: return false
	if not point.escorte.get("victimes") is Array or not point.refuge.get("victimes") is Array: return false
	if not point.ameliorations.get("acquisitions") is Array or not point.get("equipements") is Array: return false
	for cle in ["cartes_obtenues", "synergies", "effets", "branches"]:
		if not point.ameliorations.get(cle) is Dictionary: return false
	if not point.arene.get("paliers") is Array: return false
	for carte in point.ameliorations.acquisitions:
		if not carte is Dictionary or not carte.has_all(["id", "rarete", "gain", "restant", "commence"]): return false
	for victime in point.escorte.victimes:
		if not victime is Dictionary or not victime.has_all(["position", "rotation", "vie", "vie_max", "ordre", "depot", "extraction_utilisee", "protection", "prochaine_protection"]): return false
		if not victime.position is Vector3 or not victime.protection is Dictionary: return false
	for victime in point.refuge.victimes:
		if not victime is Dictionary or not victime.has_all(["vie", "vie_max", "ordre"]): return false
	return point.joueur.has("vie") and point.escorte.has("ordre_liberation") and point.escorte.has("destination")

