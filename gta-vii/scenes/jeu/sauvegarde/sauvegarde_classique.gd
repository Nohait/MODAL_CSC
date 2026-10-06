extends "res://scenes/systemes/sauvegarde/fichier_sauvegarde.gd"

func _init() -> void:
	chemin_fichier = "user://partie_classique.save"

func _valide(point: Dictionary) -> bool:
	if point.get("version") != VERSION: return false
	if not point.get("indice") is int or not point.get("etages") is int: return false
	if point.etages < 1 or point.etages > 10 or point.indice < 0 or point.indice >= point.etages * 5: return false
	if not point.get("graines") is Array or point.graines.size() != point.etages * 5: return false
	for graine in point.graines:
		if not graine is int: return false
	for cle in ["joueur", "ameliorations", "escorte", "defis", "population"]:
		if not point.get(cle) is Dictionary: return false
	if not point.get("graine_combat") is int or not point.get("pieces") is int: return false
	if not point.joueur.get("position") is Vector3 or not point.joueur.get("arme") is Dictionary or not point.joueur.has("vie"): return false
	if not point.escorte.get("victimes") is Array: return false
	if not point.ameliorations.get("acquisitions") is Array: return false
	for cle in ["cartes_obtenues", "synergies", "effets", "branches"]:
		if not point.ameliorations.get(cle) is Dictionary: return false
	if not point.population.get("mobiles") is Array or not point.population.get("victimes") is Array: return false
	if not point.defis.get("actifs") is Array or not point.defis.has_all(["gratuits", "bilan"]): return false
	if not point.escorte.has_all(["ordre_liberation", "destination"]): return false
	for carte in point.ameliorations.acquisitions:
		if not carte is Dictionary or not carte.has_all(["id", "rarete", "gain", "restant", "commence"]): return false
	for victime in point.escorte.victimes:
		if not victime is Dictionary or not victime.has_all(["position", "rotation", "vie", "vie_max", "ordre", "depot", "extraction_utilisee", "protection", "prochaine_protection"]): return false
		if not victime.position is Vector3 or not victime.protection is Dictionary: return false
	for victime in point.population.victimes:
		if not victime is Dictionary or not victime.has_all(["position", "vie", "vie_max"]): return false
		if not victime.position is Vector3: return false
	for position in point.population.mobiles:
		if not position is Vector3: return false
	for defi in point.defis.actifs:
		if not defi is Dictionary or not defi.has_all(["id", "en_attente", "echec", "progression"]): return false
	return true
