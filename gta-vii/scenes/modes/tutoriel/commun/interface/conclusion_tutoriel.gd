extends CanvasLayer

const CLASSIQUE := "res://scenes/jeu/main.tscn"
const TITRE := "res://scenes/interfaces/menus/ecran_titre.tscn"
const PROGRESSION = preload("res://scenes/systemes/sauvegarde/progression_interventions.gd")
var depart_en_cours := false
var remplacement_demande := false
var message: Label
var commencer: Button
var retour: Button
var annuler: Button
var reprise_precedente: Dictionary = {}
var progression_enregistree := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 105
	var niveau := get_parent()
	niveau.get_node("player").extincteur.stop_primary_attack()
	# Le chargement rétablit la pause globale : figer aussi la scène quittée pendant son attente.
	niveau.process_mode = Node.PROCESS_MODE_DISABLED
	for nom in ["MenuBonus", "MenuDebug", "DebugTutoriel"]:
		var menu := niveau.get_node_or_null(nom)
		if menu != null:
			menu.process_mode = Node.PROCESS_MODE_DISABLED
			if menu is CanvasLayer: menu.hide()
	niveau.get_node("Briefing").hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var fond := ColorRect.new()
	fond.color = Color(0.02, 0.04, 0.05, 0.8)
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	fond.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panneau := PanelContainer.new()
	panneau.theme = preload("res://scenes/interfaces/theme_intervention/theme.tres")
	panneau.add_theme_stylebox_override("panel", preload("res://scenes/interfaces/theme_intervention/panneau.tres"))
	panneau.custom_minimum_size.x = 650
	centre.add_child(panneau)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 18)
	panneau.add_child(colonne)
	var titre := Label.new()
	titre.text = "FORMATION · PARCOURS DISPONIBLE TERMINÉ"
	titre.add_theme_font_size_override("font_size", 24)
	colonne.add_child(titre)
	message = Label.new()
	message.custom_minimum_size = Vector2(600, 100)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	colonne.add_child(message)
	commencer = _bouton(colonne, "Commencer une intervention", _demander_depart)
	retour = _bouton(colonne, "Retour au titre", _retour_titre)
	annuler = _bouton(colonne, "Annuler", _annuler_remplacement)
	annuler.hide()
	progression_enregistree = PROGRESSION.enregistrer_formation()
	_afficher_conclusion()
	# Ces trois actions restent accessibles au clavier, même sans manette branchée.
	for bouton in [commencer, retour, annuler]: bouton.focus_mode = Control.FOCUS_ALL
	commencer.grab_focus()

func _bouton(parent: Node, texte: String, action: Callable) -> Button:
	var bouton = preload("res://scenes/interfaces/menus/titre/bouton_menu.tscn").instantiate()
	bouton.text = texte
	bouton.taille_minimale = Vector2(600, 58)
	bouton.taille_police = 24
	parent.add_child(bouton)
	bouton.pressed.connect(action)
	return bouton

func _afficher_conclusion() -> void:
	message.text = "Votre parcours de formation actuel est terminé.\nVous pouvez commencer une nouvelle intervention classique ou revenir au titre."
	if not progression_enregistree:
		message.text += "\nLa progression n’a pas pu être enregistrée. Réessayez avant de commencer."

func _demander_depart() -> void:
	if depart_en_cours or Reglages.chargement.en_cours: return
	if not progression_enregistree:
		progression_enregistree = PROGRESSION.enregistrer_formation()
		if not progression_enregistree:
			_afficher_conclusion()
			return
	SauvegardeClassique.charger()
	var fichier_existant := SauvegardeClassique.disponible() or not SauvegardeClassique.erreur_lecture.is_empty()
	if fichier_existant and not remplacement_demande:
		remplacement_demande = true
		message.text = "Une partie classique est déjà enregistrée. Commencer cette intervention remplacera son point de reprise.\nLes succès et les déblocages seront conservés."
		commencer.text = "Remplacer et commencer"
		annuler.show()
		annuler.grab_focus()
		return
	depart_en_cours = true
	_activer_boutons(false)
	# L'ancien fichier reste intact jusqu'au premier point de reprise du nouveau niveau.
	reprise_precedente = SauvegardeClassique.reprise.duplicate(true)
	SauvegardeClassique.reprise.clear()
	Reglages.chargement.chargement_echoue.connect(_echec_depart, CONNECT_ONE_SHOT)
	Reglages.chargement.ouvrir(CLASSIQUE)

func _annuler_remplacement() -> void:
	if depart_en_cours: return
	remplacement_demande = false
	commencer.text = "Commencer une intervention"
	annuler.hide()
	_afficher_conclusion()
	commencer.grab_focus()

func _activer_boutons(actifs: bool) -> void:
	for bouton in [commencer, retour, annuler]: bouton.disabled = not actifs

func _echec_depart() -> void:
	SauvegardeClassique.reprise = reprise_precedente
	Reglages.chargement.terminer()
	depart_en_cours = false
	get_tree().paused = true
	message.text = "L’intervention n’a pas pu être chargée. Votre ancienne reprise est conservée.\nVous pouvez réessayer ou revenir au titre."
	_activer_boutons(true)
	commencer.grab_focus()

func _retour_titre() -> void:
	if depart_en_cours or Reglages.chargement.en_cours: return
	depart_en_cours = true
	_activer_boutons(false)
	var arbre := get_tree()
	var erreur := arbre.change_scene_to_file(TITRE)
	if erreur == OK:
		arbre.paused = false
		Engine.time_scale = 1.0
	else:
		depart_en_cours = false
		message.text = "Impossible d’ouvrir l’écran titre. Vous pouvez réessayer."
		_activer_boutons(true)
		retour.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not depart_en_cours:
		get_viewport().set_input_as_handled()
		if remplacement_demande: _annuler_remplacement()
		else: retour.grab_focus()
