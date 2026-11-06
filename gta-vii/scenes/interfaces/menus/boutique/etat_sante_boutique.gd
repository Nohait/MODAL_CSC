extends VBoxContainer

const JAUGE = preload("res://scenes/interfaces/hud/jauge_equipement.tscn")
const ICONE_VICTIMES = preload("res://assets/textures/interfaces/ameliorations/icone_victimes.svg")

@export_range(0.1, 1.0, 0.1) var intervalle_actualisation := 0.2
var joueur: Node
var escorte: Node
var liste: HBoxContainer
var plus: Button
var fenetre: Window
var details: VBoxContainer
var fermer: Button
var capacite := -1
@export_range(0.5, 0.8, 0.05) var echelle_apercu := 0.65
var dernier_etat: Array = []
var attente := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var titre := Label.new()
	titre.text = "ÉTAT DE SANTÉ"
	titre.add_theme_font_size_override("font_size", 14)
	add_child(titre)
	liste = HBoxContainer.new()
	liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	liste.add_theme_constant_override("separation", 8)
	add_child(liste)
	plus = Button.new()
	plus.text = "Afficher plus"
	plus.custom_minimum_size = Vector2(180, 32)
	plus.add_theme_font_size_override("font_size", 14)
	plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plus.pressed.connect(_ouvrir)
	liste.add_child(plus)
	_creer_fenetre()
	visibility_changed.connect(_actualiser)
	_actualiser()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	attente -= delta
	if attente > 0.0: return
	attente = intervalle_actualisation
	_actualiser()

func _actualiser() -> void:
	if not is_node_ready(): return
	if not is_visible_in_tree():
		fenetre.hide()
		return
	var etat: Array = []
	if is_instance_valid(joueur):
		etat.append(["Pompier", float(joueur.BarreDeVie.value), float(joueur.BarreDeVie.max_value)])
	var nombre := 0
	if is_instance_valid(escorte):
		for victime in escorte.freed_victims:
			if not is_instance_valid(victime) or victime.is_queued_for_deletion() or victime.est_morte: continue
			nombre += 1
			etat.append(["Victime %d" % nombre, float(victime.vie), float(victime.vie_max)])
	var largeur := 320.0 * echelle_apercu + 8.0
	var nombre_visible := maxi(1, floori(size.x / largeur))
	if nombre_visible < etat.size():
		nombre_visible = maxi(1, floori((size.x - 188.0) / largeur))
	if etat == dernier_etat and capacite == nombre_visible: return
	dernier_etat = etat
	capacite = nombre_visible
	for enfant in liste.get_children():
		if enfant == plus: continue
		liste.remove_child(enfant)
		enfant.queue_free()
	for i in range(mini(capacite, etat.size())):
		var donnees: Array = etat[i]
		_ajouter_sante(donnees[0], donnees[1], donnees[2], liste, true)
	liste.move_child(plus, liste.get_child_count() - 1)
	plus.visible = etat.size() > capacite
	plus.text = "Afficher plus (+%d)" % maxi(0, etat.size() - capacite)
	if fenetre.visible: _remplir_details()

func _ajouter_sante(nom: String, vie: float, maximum: float, parent: Control, compact: bool = false) -> void:
	var barre = JAUGE.instantiate()
	barre.titre = nom
	if nom != "Pompier":
		barre.couleur = Color(0.38, 0.86, 0.50)
		barre.pictogramme = ICONE_VICTIMES
	barre.max_value = maxf(maximum, 1.0)
	barre.value = vie
	if compact:
		var support := Control.new()
		support.custom_minimum_size = Vector2(320, 70) * echelle_apercu
		support.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(support)
		barre.size = Vector2(320, 70)
		support.add_child(barre)
		barre.scale = Vector2.ONE * echelle_apercu
	else:
		parent.add_child(barre)

func _creer_fenetre() -> void:
	fenetre = Window.new()
	fenetre.borderless = true
	fenetre.size = Vector2i(390, 460)
	fenetre.transient = true
	fenetre.exclusive = true
	fenetre.visible = false
	add_child(fenetre)
	fenetre.close_requested.connect(_fermer)
	fenetre.window_input.connect(func(event: InputEvent):
		if event.is_action_pressed("ui_cancel"):
			fenetre.set_input_as_handled()
			_fermer())
	var panneau := PanelContainer.new()
	panneau.theme = preload("res://scenes/interfaces/theme_intervention/theme.tres")
	fenetre.add_child(panneau)
	panneau.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var colonne := VBoxContainer.new()
	panneau.add_child(colonne)
	var defilement := ScrollContainer.new()
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonne.add_child(defilement)
	details = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defilement.add_child(details)
	fermer = Button.new()
	fermer.text = "Retour à la boutique"
	fermer.custom_minimum_size.y = 40
	fermer.pressed.connect(_fermer)
	colonne.add_child(fermer)

func _remplir_details() -> void:
	for enfant in details.get_children():
		details.remove_child(enfant)
		enfant.queue_free()
	for donnees: Array in dernier_etat:
		_ajouter_sante(donnees[0], donnees[1], donnees[2], details)

func _ouvrir() -> void:
	_remplir_details()
	fenetre.popup_centered()
	fermer.grab_focus()

func _fermer() -> void:
	fenetre.hide()
	if plus.is_visible_in_tree(): plus.grab_focus()
