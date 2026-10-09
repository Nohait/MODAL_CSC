extends CanvasLayer

signal chargement_echoue

@export_range(4, 40, 1) var nombre_braises := 24
@export_range(0.1, 2.0, 0.1) var vitesse_braises := 0.5
@export_range(0.1, 3.0, 0.1) var vitesse_feu := 0.8
@export_range(2.0, 20.0, 1.0) var debordement_feu := 20.0

var en_cours := false
var fond: ColorRect
var etape: Label
var barre: ProgressBar
var echec: Button
var feu_barre: ColorRect

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	fond = ColorRect.new()
	fond.color = Color("11151c")
	var ambiance := ShaderMaterial.new()
	ambiance.shader = preload("res://assets/shaders/interfaces/chargement_braises.gdshader")
	ambiance.set_shader_parameter("nombre_braises", nombre_braises)
	ambiance.set_shader_parameter("vitesse", vitesse_braises)
	fond.material = ambiance
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
	barre.custom_minimum_size.y = 34
	barre.show_percentage = false
	for nom in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT if nom == "fill" else Color("171b22")
		style.set_corner_radius_all(4)
		if nom == "background":
			style.set_border_width_all(2)
			style.border_color = Color("685346")
		barre.add_theme_stylebox_override(nom, style)
	colonne.add_child(barre)
	feu_barre = ColorRect.new()
	feu_barre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barre.add_child(feu_barre)
	feu_barre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Le rectangle dépasse du cadre pour laisser de la place aux flammes et à leur lueur.
	feu_barre.offset_left = -debordement_feu
	feu_barre.offset_right = debordement_feu
	feu_barre.offset_top = -debordement_feu
	feu_barre.offset_bottom = debordement_feu
	var feu := ShaderMaterial.new()
	feu.shader = preload("res://assets/shaders/interfaces/chargement_barre.gdshader")
	feu_barre.material = feu
	feu.set_shader_parameter("vitesse", vitesse_feu)
	feu.set_shader_parameter("debordement", debordement_feu)
	feu.set_shader_parameter("animation_flamme", load("res://assets/textures/feu/flamme_chargement.png"))
	# Texture continue et filtrée : les flammes ne reposent plus sur des pointes répétées.
	var bruit := FastNoiseLite.new()
	bruit.seed = 73
	bruit.frequency = 0.006
	bruit.fractal_octaves = 2
	var texture_bruit := NoiseTexture2D.new()
	texture_bruit.width = 512
	texture_bruit.height = 512
	texture_bruit.seamless = true
	texture_bruit.noise = bruit
	feu.set_shader_parameter("noise_tex", texture_bruit)
	feu_barre.resized.connect(func(): feu.set_shader_parameter("dimensions", feu_barre.size))
	# Le shader suit la valeur réelle, y compris lors de la remise à zéro.
	barre.value_changed.connect(func(valeur: float): feu.set_shader_parameter("progression", valeur / barre.max_value))
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
	if chemin == "res://scenes/modes/zombie/mode_zombie.tscn":
		var carte: Variant = get_tree().get_meta("map_zombie", "res://scenes/modes/zombie/maps/hall.tscn")
		if carte is String:
			etape.text = "Chargement de l’arène…"
			barre.value = 0.0
			if ResourceLoader.load_threaded_request(carte, "PackedScene") != OK:
				_signaler_echec()
				return
			while ResourceLoader.load_threaded_get_status(carte) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var progression_carte: Array = []
				ResourceLoader.load_threaded_get_status(carte, progression_carte)
				if not progression_carte.is_empty(): barre.value = progression_carte[0] * 100.0
				await get_tree().process_frame
			if ResourceLoader.load_threaded_get_status(carte) != ResourceLoader.THREAD_LOAD_LOADED:
				_signaler_echec()
				return
			# Une référence forte garde l'arène en cache jusqu'à son instanciation.
			get_tree().set_meta("map_zombie_chargee", ResourceLoader.load_threaded_get(carte))
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


