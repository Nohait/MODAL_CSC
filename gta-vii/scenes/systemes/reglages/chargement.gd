extends CanvasLayer

signal chargement_echoue

var en_cours := false
var fond: ColorRect
var etape: Label
var barre: ProgressBar
var echec: Button

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	fond = ColorRect.new()
	fond.color = Color("11151c")
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	fond.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var colonne := VBoxContainer.new()
	colonne.custom_minimum_size = Vector2(540, 0)
	colonne.add_theme_constant_override("separation", 22)
	centre.add_child(colonne)
	var titre := Label.new()
	titre.text = "GTA VII"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_override("font", preload("res://assets/fonts/Almendra-Bold.ttf"))
	titre.add_theme_font_size_override("font_size", 68)
	titre.add_theme_color_override("font_color", Color("e7b16c"))
	colonne.add_child(titre)
	etape = Label.new()
	etape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etape.add_theme_font_size_override("font_size", 22)
	colonne.add_child(etape)
	barre = ProgressBar.new()
	barre.custom_minimum_size.y = 8
	barre.show_percentage = false
	for nom in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("d99851") if nom == "fill" else Color("303640")
		style.set_corner_radius_all(4)
		barre.add_theme_stylebox_override(nom, style)
	colonne.add_child(barre)
	echec = preload("res://scenes/interfaces/menus/titre/bouton_menu.tscn").instantiate()
	echec.text = "Retour"
	echec.pressed.connect(terminer)
	colonne.add_child(echec)
	fond.hide()

func ouvrir(chemin: String) -> void:
	if en_cours: return
	en_cours = true
	get_tree().paused = false
	fond.show()
	echec.hide()
	barre.show()
	barre.value = 0.0
	etape.text = "Chargement des ressources…"
	# Dessiner le panneau avant de lancer la lecture des modèles et textures.
	await get_tree().process_frame
	await get_tree().process_frame
	var erreur := ResourceLoader.load_threaded_request(chemin, "PackedScene")
	if erreur != OK:
		_signaler_echec()
		return
	while true:
		var progression: Array = []
		var statut := ResourceLoader.load_threaded_get_status(chemin, progression)
		if not progression.is_empty(): barre.value = float(progression[0]) * 100.0
		if statut == ResourceLoader.THREAD_LOAD_LOADED: break
		if statut != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_signaler_echec()
			return
		await get_tree().process_frame
	var scene := ResourceLoader.load_threaded_get(chemin) as PackedScene
	etape.text = "Préparation du niveau et de la navigation…"
	# La barre mesure les ressources, pas une estimation fictive de la navigation.
	barre.hide()
	await get_tree().process_frame
	erreur = get_tree().change_scene_to_packed(scene)
	if erreur != OK: _signaler_echec()
	# RoomManager retire le panneau lorsque l'entrée du joueur est prête.

func terminer() -> void:
	fond.hide()
	en_cours = false

func _signaler_echec() -> void:
	etape.text = "Impossible de charger le niveau."
	barre.hide()
	echec.show()
	chargement_echoue.emit()
	push_error("Échec du chargement du niveau.")

func _input(_evenement: InputEvent) -> void:
	if en_cours and not echec.visible:
		get_viewport().set_input_as_handled()
