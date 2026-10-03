extends Node

signal succes_obtenu(succes: Dictionary)
signal succes_reinitialises

const CATALOGUE = preload("res://scenes/systemes/succes/catalogue_succes.gd")
const NOTIFICATIONS = preload("res://scenes/interfaces/succes/notifications_succes.tscn")
const SAUVEGARDE := "user://succes.cfg"
var chemin_sauvegarde := SAUVEGARDE
var obtenus: Dictionary = {}

func _ready() -> void:
	# Cet Autoload survit aux changements de scène, comme ses notifications.
	var fichier := ConfigFile.new()
	if fichier.load(chemin_sauvegarde) == OK:
		for succes in CATALOGUE.SUCCES:
			if fichier.get_value("succes", succes.id, false) == true:
				obtenus[succes.id] = true
	add_child(NOTIFICATIONS.instantiate())

func est_obtenu(identifiant: String) -> bool:
	return obtenus.has(identifiant)

func valider_victoire(nombre_victimes: int) -> void:
	for succes in CATALOGUE.SUCCES:
		if nombre_victimes >= succes.escorte_minimum:
			debloquer(succes)

func debloquer(succes: Dictionary) -> void:
	# Une seconde victoire ne doit ni doubler le compteur ni rejouer la notification.
	if est_obtenu(succes.id):
		return
	obtenus[succes.id] = true
	_sauvegarder()
	succes_obtenu.emit(succes)

func reinitialiser() -> void:
	# Écrire une sauvegarde vide empêche les anciens succès de revenir au lancement.
	obtenus.clear()
	_sauvegarder()
	succes_reinitialises.emit()

func _sauvegarder() -> void:
	var fichier := ConfigFile.new()
	for identifiant in obtenus:
		fichier.set_value("succes", identifiant, true)
	var erreur := fichier.save(chemin_sauvegarde)
	if erreur != OK:
		push_warning("Impossible de sauvegarder les succès : " + error_string(erreur))
