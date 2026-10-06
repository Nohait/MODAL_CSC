extends Node

signal sauvegarde_changee
const VERSION := 1
# Un seul emplacement de reprise, indépendant des succès et des records.
@export var chemin_fichier := "user://partie.save"
var dernier_point: Dictionary = {}
var reprise: Dictionary = {}
var erreur_lecture := ""

func _ready() -> void:
	charger()

func disponible() -> bool:
	return not dernier_point.is_empty()

func charger() -> void:
	dernier_point = _lire(chemin_fichier)
	if dernier_point.is_empty():
		# Si une écriture a été interrompue, conserver le précédent fichier complet.
		dernier_point = _lire(chemin_fichier + ".bak")
	erreur_lecture = "Sauvegarde indisponible ou incompatible." if dernier_point.is_empty() and FileAccess.file_exists(chemin_fichier) else ""

func enregistrer(point: Dictionary) -> bool:
	if not _valide(point): return false
	var temporaire := chemin_fichier + ".tmp"
	var fichier := FileAccess.open(temporaire, FileAccess.WRITE)
	if fichier == null: return false
	var contenu := var_to_bytes(point)
	# Ne sérialiser aucun nœud ni Resource ; le contrôle détecte un fichier incomplet.
	fichier.store_var({"donnees": point, "controle": _controle(contenu)}, false)
	fichier.flush()
	var erreur := fichier.get_error()
	fichier.close()
	if erreur != OK: return false
	var precedent := chemin_fichier + ".bak"
	if FileAccess.file_exists(chemin_fichier):
		if FileAccess.file_exists(precedent) and DirAccess.remove_absolute(precedent) != OK: return false
		if DirAccess.rename_absolute(chemin_fichier, precedent) != OK: return false
	if DirAccess.rename_absolute(temporaire, chemin_fichier) != OK:
		return false
	dernier_point = point.duplicate(true)
	erreur_lecture = ""
	sauvegarde_changee.emit()
	return true

func preparer_reprise() -> bool:
	charger()
	if not disponible(): return false
	reprise = dernier_point.duplicate(true)
	_preparer_mode(reprise)
	return true

func consommer_reprise() -> Dictionary:
	var point := reprise
	reprise = {}
	return point

func supprimer() -> bool:
	for suffixe in ["", ".bak", ".tmp"]:
		var chemin: String = chemin_fichier + suffixe
		if FileAccess.file_exists(chemin) and DirAccess.remove_absolute(chemin) != OK:
			push_warning("Impossible de supprimer la sauvegarde.")
			charger()
			return false
	dernier_point.clear()
	reprise.clear()
	erreur_lecture = ""
	sauvegarde_changee.emit()
	return true

func _lire(chemin: String) -> Dictionary:
	if not FileAccess.file_exists(chemin): return {}
	var fichier := FileAccess.open(chemin, FileAccess.READ)
	if fichier == null or fichier.get_length() > 8 * 1024 * 1024: return {}
	# store_var préfixe les données par leur taille : refuser une taille incohérente.
	var taille := fichier.get_32()
	if taille <= 0 or taille != fichier.get_length() - 4: return {}
	var enveloppe = bytes_to_var(fichier.get_buffer(taille))
	if not enveloppe is Dictionary: return {}
	var point = enveloppe.get("donnees")
	if not point is Dictionary or not _valide(point): return {}
	if _controle(var_to_bytes(point)) != enveloppe.get("controle", ""): return {}
	return point

func _valide(_point: Dictionary) -> bool:
	return false

func _controle(contenu: PackedByteArray) -> String:
	var contexte := HashingContext.new()
	contexte.start(HashingContext.HASH_SHA256)
	contexte.update(contenu)
	return contexte.finish().hex_encode()

func _preparer_mode(_point: Dictionary) -> void:
	pass
