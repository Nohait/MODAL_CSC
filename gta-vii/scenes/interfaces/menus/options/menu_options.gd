extends CanvasLayer

const BOUTON = preload("res://scenes/interfaces/menus/titre/bouton_menu.tscn")
@onready var menu: Control = $Menu
@onready var panneau: Control = $Menu/Panneau
@onready var papier: TextureRect = $Menu/Panneau/Papier
@onready var contenu: VBoxContainer = %ContenuReglages
@onready var controles: Control = %Controles
@onready var onglet_reglages: Button = %OngletReglages
@onready var onglet_controles: Button = %OngletControles
var curseurs: Dictionary = {}
var plein_ecran: Button
var pause_avant := false
var souris_avant: int
var focus_avant: Control
var entrees_suspendues: Array[Dictionary] = []
var animation: Tween
var horloge := 0.0

func _ready() -> void:
	menu.hide()
	_creer_titre("AMBIANCE SONORE")
	_creer_curseur("general", "Volume général", 0.0, 100.0, 1.0)
	_creer_curseur("ambiance", "Crépitement des incendies", 0.0, 100.0, 1.0)
	_creer_curseur("effets", "Effets sonores", 0.0, 100.0, 1.0)
	_creer_curseur("musique", "Musique", 0.0, 100.0, 1.0)
	_creer_titre("AFFICHAGE ET VISÉE")
	var ligne := HBoxContainer.new()
	contenu.add_child(ligne)
	ligne.add_child(_libelle("Mode d’affichage"))
	plein_ecran = BOUTON.instantiate()
	plein_ecran.taille_minimale = Vector2(260, 48)
	plein_ecran.taille_police = 22
	plein_ecran.toggle_mode = true
	ligne.add_child(plein_ecran)
	plein_ecran.toggled.connect(_changer_affichage)
	_creer_curseur("sensibilite", "Sensibilité de visée · manette", 0.25, 2.5, 0.05)
	%Fermer.pressed.connect(fermer)
	onglet_reglages.pressed.connect(_choisir_onglet.bind(false))
	onglet_controles.pressed.connect(_choisir_onglet.bind(true))
	controles.commandes_changees.connect(Reglages.sauvegarder)
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(menu)
	papier.material = papier.material.duplicate()
	_choisir_onglet(false)

func _creer_titre(texte: String) -> void:
	var titre := Label.new()
	titre.text = texte
	titre.add_theme_color_override("font_color", Color("d5a76d"))
	titre.add_theme_font_size_override("font_size", 20)
	contenu.add_child(titre)

func _libelle(texte: String) -> Label:
	var libelle := Label.new()
	libelle.text = texte
	libelle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	libelle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return libelle

func _creer_curseur(id: String, texte: String, minimum: float, maximum: float, pas: float) -> void:
	var ligne := HBoxContainer.new()
	ligne.custom_minimum_size.y = 48
	ligne.add_theme_constant_override("separation", 24)
	contenu.add_child(ligne)
	ligne.add_child(_libelle(texte))
	var curseur := HSlider.new()
	curseur.custom_minimum_size = Vector2(300, 36)
	curseur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	curseur.min_value = minimum
	curseur.max_value = maximum
	curseur.step = pas
	ligne.add_child(curseur)
	var valeur := Label.new()
	valeur.custom_minimum_size.x = 90
	valeur.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	valeur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ligne.add_child(valeur)
	curseurs[id] = {"curseur": curseur, "valeur": valeur}
	curseur.value_changed.connect(_changer_curseur.bind(id))

func _changer_curseur(valeur: float, id: String) -> void:
	_afficher_valeur(id, valeur)
	if id == "sensibilite": Reglages.regler_sensibilite(valeur)
	else: Reglages.regler_volume(id, valeur / 100.0)

func _afficher_valeur(id: String, valeur: float) -> void:
	curseurs[id].valeur.text = "× %.2f" % valeur if id == "sensibilite" else "%d %%" % roundi(valeur)

func _changer_affichage(actif: bool) -> void:
	Reglages.regler_plein_ecran(actif)
	plein_ecran.text = "Plein écran" if actif else "Fenêtré"

func ouvrir() -> void:
	if menu.visible or get_tree().current_scene == null: return
	var joueur := get_tree().get_first_node_in_group("player")
	if is_instance_valid(joueur):
		var salles := joueur.get_parent().get_node_or_null("Salles/RoomManager")
		if salles != null and salles.transition_en_cours: return
		joueur.extincteur.stop_primary_attack()
	pause_avant = get_tree().paused
	souris_avant = Input.mouse_mode
	focus_avant = get_viewport().gui_get_focus_owner()
	# Les menus derrière restent affichés, mais ne reçoivent plus Échap ou B.
	_suspendre_entrees(get_tree().current_scene)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for id in curseurs:
		var valeur: float = Reglages.sensibilite if id == "sensibilite" else Reglages.volumes[id] * 100.0
		curseurs[id].curseur.set_value_no_signal(valeur)
		_afficher_valeur(id, valeur)
	var actif := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	plein_ecran.set_pressed_no_signal(actif)
	plein_ecran.text = "Plein écran" if actif else "Fenêtré"
	controles.mettre_a_jour_affichage_clavier()
	controles.mettre_a_jour_affichage_manette()
	_choisir_onglet(false)
	menu.show()
	if animation: animation.kill()
	menu.modulate.a = 0.0
	panneau.pivot_offset = panneau.size / 2.0
	panneau.scale = Vector2(0.97, 0.97)
	animation = create_tween().set_parallel(true)
	# Le fondu et le léger agrandissement vivent aussi pendant la pause.
	animation.tween_property(menu, "modulate:a", 1.0, 0.16)
	animation.tween_property(panneau, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not Input.get_connected_joypads().is_empty(): onglet_reglages.grab_focus()

func fermer() -> void:
	if not menu.visible: return
	controles.annuler_rebind()
	Reglages.sauvegarder()
	if animation: animation.kill()
	menu.hide()
	get_viewport().gui_release_focus()
	# Une boutique ou le Carnet déjà ouvert doit rester en pause au retour.
	get_tree().paused = pause_avant
	Input.mouse_mode = souris_avant
	for entree in entrees_suspendues:
		if is_instance_valid(entree.noeud):
			entree.noeud.set_process_input(entree.input)
			entree.noeud.set_process_unhandled_input(entree.unhandled)
			entree.noeud.set_process_unhandled_key_input(entree.key)
			if entree.navigation: entree.noeud.set_process(entree.process)
	entrees_suspendues.clear()
	if is_instance_valid(focus_avant) and focus_avant.is_visible_in_tree(): focus_avant.grab_focus()

func _suspendre_entrees(noeud: Node) -> void:
	entrees_suspendues.append({"noeud": noeud, "input": noeud.is_processing_input(), "unhandled": noeud.is_processing_unhandled_input(), "key": noeud.is_processing_unhandled_key_input(), "navigation": noeud is NavigationManette, "process": noeud.is_processing()})
	noeud.set_process_input(false)
	noeud.set_process_unhandled_input(false)
	noeud.set_process_unhandled_key_input(false)
	# Un menu derrière ne doit pas reprendre le focus de la manette.
	if noeud is NavigationManette: noeud.set_process(false)
	for enfant in noeud.get_children(): _suspendre_entrees(enfant)

func _choisir_onglet(commandes: bool) -> void:
	controles.annuler_rebind()
	contenu.visible = not commandes
	%PageControles.visible = commandes
	controles.visible = commandes
	onglet_reglages.set_pressed_no_signal(not commandes)
	onglet_controles.set_pressed_no_signal(commandes)
	onglet_reglages.modulate = Color.WHITE if not commandes else Color(0.7, 0.65, 0.6)
	onglet_controles.modulate = Color.WHITE if commandes else Color(0.7, 0.65, 0.6)
	%Defilement.scroll_vertical = 0

func _input(event: InputEvent) -> void:
	if not menu.visible or event.is_echo() or controles.rebind_en_cours(): return
	var raccourci: bool = event is InputEventKey and event.pressed and event.physical_keycode == KEY_F2
	var start: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
	if event.is_action_pressed("ui_cancel") or raccourci or start:
		get_viewport().set_input_as_handled()
		fermer()

func _process(delta: float) -> void:
	if not menu.visible: return
	horloge += delta
	papier.material.set_shader_parameter("horloge", horloge)
	papier.material.set_shader_parameter("taille", papier.size)
