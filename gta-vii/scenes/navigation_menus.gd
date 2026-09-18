extends Control

# Les écrans titre et mort partagent seulement la navigation entre les scènes.
var changement_en_cours := false


func _ready() -> void:
	# Le niveau a mis le combat en pause lors de la mort. Ces écrans sont autonomes.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%NouvellePartie.pressed.connect(nouvelle_partie)
	%NouvellePartie.grab_focus()
	# L'écran titre n'a pas de bouton pour revenir vers lui-même.
	var retour_titre := get_node_or_null("%EcranTitre")
	if retour_titre != null:
		retour_titre.pressed.connect(ecran_titre)


func nouvelle_partie() -> void:
	# Une nouvelle instance de main remet à zéro vie, charge, escorte et objectifs.
	changer_scene("res://scenes/main.tscn")


func ecran_titre() -> void:
	changer_scene("res://scenes/ecran_titre.tscn")


func changer_scene(chemin: String) -> void:
	# Éviter deux changements si le joueur clique plusieurs fois rapidement.
	if changement_en_cours:
		return
	changement_en_cours = true
	var erreur := get_tree().change_scene_to_file(chemin)
	if erreur != OK:
		changement_en_cours = false
		push_error("Impossible d'ouvrir l'écran : " + chemin)
