extends CanvasLayer

signal chargement_echoue

@export_range(30.0, 600.0, 10.0) var delai_sans_progression := 120.0
@export_range(60.0, 1800.0, 30.0) var duree_max_ressources := 600.0

var en_cours := false
var fond: ColorRect
var etape: Label
var barre: ProgressBar
var echec: Button

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	fond = ColorRect.new()
	fond.color = Color("101010")
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	fond.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var colonne := VBoxContainer.new()
	colonne.custom_minimum_size = Vector2(580, 0)
	colonne.add_theme_constant_override("separation", 22)
	centre.add_child(colonne)
	colonne.theme = preload("res://scenes/interfaces/theme_intervention/theme.tres")
	var titre := Label.new()
	titre.text = "GTA VII"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_override("font", preload("res://assets/fonts/Almendra-Bold.ttf"))
	titre.add_theme_font_size_override("font_size", 68)
	titre.add_theme_color_override("font_color", Color("f5f5f0"))
	colonne.add_child(titre)
	etape = Label.new()
	etape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etape.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etape.add_theme_color_override("font_color", Color("bdbdbd"))
	etape.add_theme_font_size_override("font_size", 22)
	colonne.add_child(etape)
	barre = ProgressBar.new()
	barre.custom_minimum_size.y = 12
	barre.show_percentage = false
	for nom in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("c52d2f") if nom == "fill" else Color("222222")
		style.set_corner_radius_all(4)
		if nom == "background":
			style.set_border_width_all(2)
			style.border_color = Color("565656")
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
	var scene: PackedScene = await _charger_scene(chemin)
	if scene == null: return
	if chemin == "res://scenes/modes/zombie/mode_zombie.tscn":
		var carte: Variant = get_tree().get_meta("map_zombie", "res://scenes/modes/zombie/maps/hall.tscn")
		if carte is String:
			etape.text = "Chargement de l’arène…"
			barre.value = 0.0
			var scene_carte: PackedScene = await _charger_scene(carte)
			if scene_carte == null: return
			# Une référence forte garde l'arène en cache jusqu'à son instanciation.
			get_tree().set_meta("map_zombie_chargee", scene_carte)
	etape.text = "Préparation du niveau et de la navigation…"
	# La barre mesure les ressources, pas une estimation fictive de la navigation.
	barre.hide()
	await get_tree().process_frame
	var erreur := get_tree().change_scene_to_packed(scene)
	if erreur != OK: _signaler_echec()
	# RoomManager retire le panneau lorsque l'entrée du joueur est prête.

func _charger_scene(chemin: String) -> PackedScene:
	var debut := Time.get_ticks_msec()
	print("[Chargement] Début : ", chemin)
	# Une requête abandonnée peut encore tourner : ne pas en lancer une seconde.
	var statut := ResourceLoader.load_threaded_get_status(chemin)
	if statut != ResourceLoader.THREAD_LOAD_IN_PROGRESS and statut != ResourceLoader.THREAD_LOAD_LOADED:
		var erreur := ResourceLoader.load_threaded_request(chemin, "PackedScene")
		print("[Chargement] Requête retournée : %s, code %d, %.2f s" % [chemin, erreur, (Time.get_ticks_msec() - debut) / 1000.0])
		if erreur != OK:
			_signaler_echec("Requête refusée : %s (erreur %d)." % [chemin, erreur])
			return null
	var derniere_avance := debut
	var prochain_journal := debut + 10000
	var maximum := -1.0
	while true:
		var progression: Array = []
		statut = ResourceLoader.load_threaded_get_status(chemin, progression)
		if not progression.is_empty():
			var valeur := float(progression[0])
			barre.value = valeur * 100.0
			if valeur > maximum:
				maximum = valeur
				derniere_avance = Time.get_ticks_msec()
		if statut == ResourceLoader.THREAD_LOAD_LOADED:
			print("[Chargement] Ressource prête, récupération : ", chemin)
			var scene := ResourceLoader.load_threaded_get(chemin) as PackedScene
			print("[Chargement] Récupération terminée : %s, %.2f s" % [chemin, (Time.get_ticks_msec() - debut) / 1000.0])
			if scene == null:
				_signaler_echec("La ressource chargée n'est pas une scène : " + chemin)
			return scene
		if statut != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_signaler_echec("Chargement interrompu : %s (statut %d)." % [chemin, statut])
			return null
		var maintenant := Time.get_ticks_msec()
		if maintenant >= prochain_journal:
			print("[Chargement] %s : %.1f %%, %.1f s écoulées, %.1f s sans progression" % [chemin, maxf(maximum, 0.0) * 100.0, (maintenant - debut) / 1000.0, (maintenant - derniere_avance) / 1000.0])
			prochain_journal = maintenant + 10000
		if maintenant - derniere_avance >= delai_sans_progression * 1000.0 or maintenant - debut >= duree_max_ressources * 1000.0:
			_signaler_echec("Délai dépassé : %s, progression %.1f %%, durée %.1f s, moteur %s." % [chemin, maxf(maximum, 0.0) * 100.0, (maintenant - debut) / 1000.0, Engine.get_version_info().string])
			return null
		await get_tree().process_frame
	return null

func terminer() -> void:
	fond.hide()
	en_cours = false

func _signaler_echec(detail: String = "Échec du changement de scène.") -> void:
	etape.text = "Le chargement n’a pas abouti.\nRevenez à l’écran précédent pour réessayer."
	barre.hide()
	echec.show()
	echec.grab_focus()
	chargement_echoue.emit()
	push_error("Échec du chargement du niveau. " + detail)

func _input(_evenement: InputEvent) -> void:
	if en_cours and not echec.visible:
		get_viewport().set_input_as_handled()
