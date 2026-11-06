extends RefCounted

const PROGRESSION = preload("res://scenes/systemes/sauvegarde/progression_interventions.gd")

static func reinitialiser(arbre: SceneTree, inclure_reglages: bool) -> PackedStringArray:
	var erreurs := PackedStringArray()
	# Aucun effacement pendant une partie : elle pourrait réécrire son point de reprise.
	if arbre.current_scene == null or not arbre.current_scene.is_in_group("debug_titre"):
		erreurs.append("La remise à zéro est disponible uniquement depuis le titre.")
		return erreurs
	var reglages := arbre.root.get_node("Reglages")
	if reglages.chargement.en_cours:
		erreurs.append("Un chargement est en cours.")
		return erreurs
	for nom in ["SauvegardeClassique", "SauvegardeZombie", "RepriseTutoriel"]:
		var sauvegarde := arbre.root.get_node(nom)
		var efface: bool = sauvegarde.reinitialiser() if nom == "RepriseTutoriel" else sauvegarde.supprimer()
		if not efface: erreurs.append("Suppression impossible : " + nom)
	var progression := PROGRESSION.new()
	if not progression.supprimer(): erreurs.append("Suppression impossible : progression durable")
	progression.free()
	# Liste explicite : ne jamais vider user://, qui contient aussi journaux et caches.
	for entree in [["SuccesManager", arbre.root.get_node("SuccesManager").chemin_sauvegarde],
		["CatalogueEnnemis", arbre.root.get_node("CatalogueEnnemis").SAUVEGARDE],
		["StatistiquesZombie", arbre.root.get_node("StatistiquesZombie").FICHIER_RECORDS]]:
		var service := arbre.root.get_node(entree[0])
		var chemin: String = entree[1]
		if _effacer(chemin):
			service.reinitialiser_memoire()
		else:
			erreurs.append("Suppression impossible : " + chemin.get_file())
	if inclure_reglages:
		if _effacer(reglages.FICHIER): reglages.reinitialiser()
		else: erreurs.append("Suppression impossible : réglages")
	for cle in ["tutoriel_debug_actif", "tutoriel_debug_depart", "tutoriel_debug_historique"]:
		if Engine.has_meta(cle): Engine.remove_meta(cle)
	if arbre.has_meta("map_zombie"): arbre.remove_meta("map_zombie")
	Engine.time_scale = 1.0
	return erreurs

static func _effacer(chemin: String) -> bool:
	if not chemin.begins_with("user://") or chemin.contains("..") or chemin.trim_prefix("user://").contains("/"):
		return false
	for suffixe in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(chemin + suffixe) and DirAccess.remove_absolute(chemin + suffixe) != OK:
			return false
	return true
