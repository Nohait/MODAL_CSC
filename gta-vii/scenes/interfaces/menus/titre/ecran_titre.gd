extends "res://scenes/interfaces/menus/navigation_menus.gd"

var confirmation_suppression: Window
var message_sauvegarde: Label
var mode_suppression := "zombie"

func _ready() -> void:
	super._ready()
	%ModeZombie.pressed.connect(_jouer_zombie)
	%SupprimerZombie.pressed.connect(_demander_suppression.bind("zombie"))
	%SupprimerClassique.pressed.connect(_demander_suppression.bind("classique"))
	_creer_confirmation_suppression()
	SauvegardeClassique.charger()
	SauvegardeClassique.sauvegarde_changee.connect(_actualiser_classique)
	_actualiser_classique()
	SauvegardeZombie.charger()
	SauvegardeZombie.sauvegarde_changee.connect(_actualiser_zombie)
	for bouton in [%SupprimerZombie, %SupprimerClassique]:
		# Une icône remplit le bouton sans dépendre de la taille du caractère dans la police.
		bouton.text = ""
		bouton.icone.texture = preload("res://assets/textures/interfaces/titre/croix_suppression.svg")
		bouton.icone.custom_minimum_size = Vector2.ZERO
		bouton.icone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bouton.icone.offset_left = 22.0
		bouton.icone.offset_top = 22.0
		bouton.icone.offset_right = -22.0
		bouton.icone.offset_bottom = -22.0
		var fond: TextureRect = bouton.fond
		fond.material = ShaderMaterial.new()
		fond.material.shader = preload("res://scenes/interfaces/menus/titre/bouton_supprimer.gdshader")
		for etat in ["font_color", "font_hover_color", "font_pressed_color"]:
			bouton.add_theme_color_override(etat, Color.WHITE)
	_actualiser_zombie()
	%Succes.pressed.connect($MenuSucces.ouvrir)
	%Options.pressed.connect(Reglages.ouvrir)
	%Quitter.pressed.connect(get_tree().quit)
	# Faire apparaître le menu doucement, pendant que le décor 3D vit déjà.
	$Menu.modulate.a = 0.0
	var animation := create_tween()
	animation.tween_property($Menu, "modulate:a", 1.0, 0.45)

func _actualiser_zombie() -> void:
	var disponible := SauvegardeZombie.disponible()
	%ModeZombie.text = "Continuer" if disponible else "Nouvelle partie"
	%ModeZombie.tooltip_text = "Reprendre au début de la vague %d" % SauvegardeZombie.dernier_point.vague if disponible else "Choisir une map et commencer une partie zombie"
	%SupprimerZombie.visible = disponible

func _jouer_zombie() -> void:
	if SauvegardeZombie.disponible():
		if SauvegardeZombie.preparer_reprise():
			changer_scene("res://scenes/modes/zombie/mode_zombie.tscn")
		else:
			_actualiser_zombie()
	else:
		SauvegardeZombie.reprise.clear()
		changer_scene("res://scenes/modes/zombie/interfaces/selection_maps/selection_maps.tscn")

func _creer_confirmation_suppression() -> void:
	confirmation_suppression = Window.new()
	confirmation_suppression.title = "Supprimer la sauvegarde"
	confirmation_suppression.size = Vector2i(620, 300)
	confirmation_suppression.exclusive = true
	confirmation_suppression.transient = true
	confirmation_suppression.unresizable = true
	confirmation_suppression.borderless = true
	add_child(confirmation_suppression)
	var panneau := PanelContainer.new()
	panneau.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirmation_suppression.add_child(panneau)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c232d")
	style.border_color = Color("b78f62")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panneau.add_theme_stylebox_override("panel", style)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 20)
	panneau.add_child(colonne)
	message_sauvegarde = Label.new()
	message_sauvegarde.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_sauvegarde.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_sauvegarde.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_sauvegarde.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_sauvegarde.add_theme_font_override("font", preload("res://assets/fonts/Oswald-SemiBold.ttf"))
	message_sauvegarde.add_theme_font_size_override("font_size", 23)
	message_sauvegarde.add_theme_color_override("font_color", Color("f0e5cf"))
	colonne.add_child(message_sauvegarde)
	var boutons := HBoxContainer.new()
	boutons.alignment = BoxContainer.ALIGNMENT_CENTER
	boutons.add_theme_constant_override("separation", 16)
	colonne.add_child(boutons)
	for texte in ["Annuler", "Supprimer"]:
		var bouton = preload("res://scenes/interfaces/menus/titre/bouton_menu.tscn").instantiate()
		bouton.taille_minimale = Vector2(245, 60)
		bouton.taille_police = 24
		bouton.text = texte
		boutons.add_child(bouton)
		if texte == "Annuler": bouton.pressed.connect(confirmation_suppression.hide)
		else: bouton.pressed.connect(_supprimer_sauvegarde)
	confirmation_suppression.close_requested.connect(confirmation_suppression.hide)
	confirmation_suppression.window_input.connect(func(event: InputEvent):
		if event.is_action_pressed("ui_cancel"):
			confirmation_suppression.set_input_as_handled()
			confirmation_suppression.hide())
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(panneau)
	confirmation_suppression.hide()

func _demander_suppression(mode: String = "zombie") -> void:
	mode_suppression = mode
	message_sauvegarde.text = "Supprimer cette partie %s ?\nVotre progression sera perdue.\nLes succès et les records seront conservés." % mode
	confirmation_suppression.popup_centered()

func _supprimer_sauvegarde() -> void:
	var sauvegarde = SauvegardeZombie if mode_suppression == "zombie" else SauvegardeClassique
	if sauvegarde.supprimer():
		confirmation_suppression.hide()
	else:
		message_sauvegarde.text = "Impossible de supprimer la sauvegarde.\nVérifiez les droits d’accès au fichier."

func _actualiser_classique() -> void:
	var disponible := SauvegardeClassique.disponible()
	%NouvellePartie.text = "Continuer" if disponible else "Nouvelle partie"
	%SupprimerClassique.visible = disponible
	if disponible:
		var indice: int = SauvegardeClassique.dernier_point.indice
		%NouvellePartie.tooltip_text = "Reprendre la salle %d de l’étage %d" % [indice % 5 + 1, indice / 5 + 1]
	else:
		%NouvellePartie.tooltip_text = "Commencer une partie classique"

func nouvelle_partie() -> void:
	# Le bouton commun est relié par navigation_menus ; seul le titre propose une reprise.
	if SauvegardeClassique.disponible():
		if not SauvegardeClassique.preparer_reprise():
			_actualiser_classique()
			return
	else:
		SauvegardeClassique.reprise.clear()
	changer_scene("res://scenes/jeu/main.tscn")
