extends Control

signal commandes_changees
@export var integre_options := false

var noms_souris = {
	MOUSE_BUTTON_LEFT: "Clic Gauche",
	MOUSE_BUTTON_RIGHT: "Clic Droit",
	MOUSE_BUTTON_MIDDLE: "Clic Molette",
	MOUSE_BUTTON_WHEEL_UP: "Molette haut",
	MOUSE_BUTTON_WHEEL_DOWN: "Molette bas",
	MOUSE_BUTTON_WHEEL_LEFT: "Molette gauche",
	MOUSE_BUTTON_WHEEL_RIGHT: "Molette droite",
	MOUSE_BUTTON_XBUTTON1: "Bouton souris 4",
	MOUSE_BUTTON_XBUTTON2: "Bouton souris 5",
}

var images_manette = {
	JOY_BUTTON_A: "res://assets/textures/controles/a.png",
	JOY_BUTTON_B: "res://assets/textures/controles/b.png",
	JOY_BUTTON_X: "res://assets/textures/controles/x.png",
	JOY_BUTTON_Y: "res://assets/textures/controles/y.png",

	JOY_BUTTON_BACK: "res://assets/textures/controles/back.png",
	JOY_BUTTON_START: "res://assets/textures/controles/start.png",

	JOY_BUTTON_LEFT_STICK: "res://assets/textures/controles/l_stick_click.png",
	JOY_BUTTON_RIGHT_STICK: "res://assets/textures/controles/r_stick_click.png",
	
	[JOY_AXIS_LEFT_Y, -1]: "res://assets/textures/controles/l_stick_up.png",
	[JOY_AXIS_LEFT_Y, 1]: "res://assets/textures/controles/l_stick_down.png",
	[JOY_AXIS_LEFT_X, -1]: "res://assets/textures/controles/l_stick_left.png",
	[JOY_AXIS_LEFT_X, 1]: "res://assets/textures/controles/l_stick_right.png",
	[JOY_AXIS_RIGHT_Y, -1]: "res://assets/textures/controles/r_stick_up.png",
	[JOY_AXIS_RIGHT_Y, 1]: "res://assets/textures/controles/r_stick_down.png",
	[JOY_AXIS_RIGHT_X, -1]: "res://assets/textures/controles/r_stick_left.png",
	[JOY_AXIS_RIGHT_X, 1]: "res://assets/textures/controles/r_stick_right.png",
	
	[5, 1] : "res://assets/textures/controles/rt.png",
	[4, 1] : "res://assets/textures/controles/lt.png",
	
	JOY_BUTTON_LEFT_SHOULDER: "res://assets/textures/controles/lb.png",
	JOY_BUTTON_RIGHT_SHOULDER: "res://assets/textures/controles/rb.png",

	JOY_BUTTON_DPAD_UP: "res://assets/textures/controles/dpad_up.png",
	JOY_BUTTON_DPAD_DOWN: "res://assets/textures/controles/dpad_down.png",
	JOY_BUTTON_DPAD_LEFT: "res://assets/textures/controles/dpad_left.png",
	JOY_BUTTON_DPAD_RIGHT: "res://assets/textures/controles/dpad_right.png",

	JOY_BUTTON_GUIDE: "res://assets/textures/controles/guide.png",
	JOY_BUTTON_TOUCHPAD: "res://assets/textures/controles/touchpad.png",
}

var touches_par_defaut_clavier ={
		"move_forward": KEY_Z,
		"move_backward": KEY_S,
		"move_left": KEY_Q,
		"move_right": KEY_D,
		"primary_attack" : MOUSE_BUTTON_LEFT,
		"dash": KEY_SPACE,
		}
var touches_par_defaut_manette = {
		"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
		"move_backward": [JOY_AXIS_LEFT_Y, 1.0],
		"move_left": [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X, 1.0],
		"primary_attack": JOY_BUTTON_Y,
		"dash": JOY_BUTTON_LEFT_SHOULDER,
		}
"""
		"interact" : KEY_E,
		"menu_bonus" : KEY_B,
		"victim_control" : MOUSE_BUTTON_MIDDLE,
		"victim_nav_auto" : KEY_A,
		
		"interact": JOY_BUTTON_RIGHT_SHOULDER,
		"menu_bonus": JOY_BUTTON_X,
		"victim_control": JOY_BUTTON_LEFT_STICK,
		"victim_nav_auto": JOY_BUTTON_RIGHT_STICK,
		
		"interact" : $"Menu/MenuTouches/J1ClavierTouches/Interagir",
		"menu_bonus" : $"Menu/MenuTouches/J1ClavierTouches/MenuBonus",
		"victim_control" : $"Menu/MenuTouches/J1ClavierTouches/ControlVictime",
		"victim_nav_auto" : $"Menu/MenuTouches/J1ClavierTouches/NavAutoVictime",
		
		"interact" : $"Menu/MenuTouches/J1ManetteTouches/Interagir",
		"menu_bonus" : $"Menu/MenuTouches/J1ManetteTouches/MenuBonus",
		"victim_control" : $"Menu/MenuTouches/J1ManetteTouches/ControlVictime",
		"victim_nav_auto" : $"Menu/MenuTouches/J1ManetteTouches/NavAutoVictime",
"""

var boutons_actions = {"clavier":{}, "manette":{}}

	
func _ready() -> void:
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(self)
	
	boutons_actions["clavier"] = {
		"move_forward": $"Menu/MenuTouches/J1ClavierTouches/Haut",
		"move_backward": $"Menu/MenuTouches/J1ClavierTouches/Bas",
		"move_left": $"Menu/MenuTouches/J1ClavierTouches/Gauche",
		"move_right": $"Menu/MenuTouches/J1ClavierTouches/Droit",
		"primary_attack" : $"Menu/MenuTouches/J1ClavierTouches/AttaquePrimaire",
		"dash": $"Menu/MenuTouches/J1ClavierTouches/Dash",
		
	}
	boutons_actions["manette"] = {
		"move_forward": $"Menu/MenuTouches/J1ManetteTouches/Haut",
		"move_backward": $"Menu/MenuTouches/J1ManetteTouches/Bas",
		"move_left": $"Menu/MenuTouches/J1ManetteTouches/Gauche",
		"move_right": $"Menu/MenuTouches/J1ManetteTouches/Droit",
		"primary_attack" : $"Menu/MenuTouches/J1ManetteTouches/AttaquePrimaire",
		"dash": $"Menu/MenuTouches/J1ManetteTouches/Dash",
		
	}
	
	%Fermer.pressed.connect(fermer)
	%ReinitialiserClavier.visible = OS.is_debug_build()
	%ReinitialiserClavier.pressed.connect(reinitialiser_clavier)
	%ReinitialiserManette.visible = OS.is_debug_build()
	%ReinitialiserManette.pressed.connect(reinitialiser_manette)
	mettre_a_jour_affichage_clavier()
	mettre_a_jour_affichage_manette()
	if integre_options: _adapter_options()

	hide()


func ouvrir() -> void:
	show()

func fermer() -> void:
	hide()
	%Fermer.release_focus()

func _input(event: InputEvent) -> void:
	if not integre_options and is_visible_in_tree() and not rebind_en_cours() and event.is_action_pressed("ui_cancel"):
		fermer()
		get_viewport().set_input_as_handled()

func reinitialiser_clavier():
	for action in touches_par_defaut_clavier:
		_retablir_action(action, false)
	mettre_a_jour_affichage_clavier()
	commandes_changees.emit()

func reinitialiser_manette():
	for action in touches_par_defaut_manette:
		_retablir_action(action, true)
	mettre_a_jour_affichage_manette()
	commandes_changees.emit()

func _retablir_action(action: String, manette: bool) -> void:
	# Reprendre les vrais réglages du projet, en conservant l'autre périphérique.
	for event in InputMap.action_get_events(action):
		if (event is InputEventJoypadButton or event is InputEventJoypadMotion) == manette:
			InputMap.action_erase_event(action, event)
	var origine: Dictionary = ProjectSettings.get_setting("input/" + action, {})
	for event in origine.get("events", []):
		if (event is InputEventJoypadButton or event is InputEventJoypadMotion) == manette:
			InputMap.action_add_event(action, event.duplicate())

func rebind_en_cours() -> bool:
	return $Menu/MenuTouches/J1ClavierTouches.en_attente or $Menu/MenuTouches/J1ManetteTouches.en_attente

func annuler_rebind() -> void:
	$Menu/MenuTouches/J1ClavierTouches.annuler_rebind()
	$Menu/MenuTouches/J1ManetteTouches.annuler_rebind()

func _adapter_options() -> void:
	# Conserver la hiérarchie utilisée par les scripts du collègue, adapter l'habillage.
	for chemin in ["Fond", "Menu/Flammes", "Menu/Titre", "Menu/Surtitre", "Menu/Accroche", "Menu/MenuTouches/ColonneNoms/Signature"]:
		get_node(chemin).hide()
	$Menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Menu/MenuTouches.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Menu/MenuTouches.offset_bottom = -64.0
	for colonne in [$Menu/MenuTouches/ColonneNoms, $Menu/MenuTouches/J1ClavierTouches, $Menu/MenuTouches/J1ManetteTouches]:
		colonne.add_theme_constant_override("separation", 8)
		colonne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if colonne != $Menu/MenuTouches/ColonneNoms:
			colonne.taille_minimale_boutons = Vector2(180, 44)
		for enfant in colonne.get_children():
			if enfant is Button:
				enfant.taille_minimale = Vector2(180, 44)
				enfant.custom_minimum_size = Vector2(180, 44)
				enfant.add_theme_font_size_override("font_size", 20)
				var icone: TextureRect = enfant.get_node("Icone")
				icone.custom_minimum_size = Vector2.ZERO
				icone.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
				icone.offset_left = -19.0
				icone.offset_top = -19.0
				icone.offset_right = 19.0
				icone.offset_bottom = 19.0
				if colonne == $Menu/MenuTouches/ColonneNoms:
					enfant.disabled = true
					enfant.add_theme_color_override("font_disabled_color", Color("e9d8b4"))
					enfant.mouse_filter = Control.MOUSE_FILTER_IGNORE
					enfant.focus_mode = Control.FOCUS_NONE
			elif enfant.name == "Espace":
				enfant.custom_minimum_size.y = 26
		var titre := Label.new()
		titre.text = "Commande" if colonne == $Menu/MenuTouches/ColonneNoms else ("Clavier / souris" if colonne == $Menu/MenuTouches/J1ClavierTouches else "Manette")
		titre.add_theme_font_size_override("font_size", 18)
		colonne.get_node("Espace").add_child(titre)
	$Bas.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	$Bas.offset_top = -54.0
	$Bas.offset_bottom = 0.0
	%Fermer.hide()
	for bouton in [%ReinitialiserClavier, %ReinitialiserManette]:
		bouton.show()
		bouton.taille_minimale = Vector2(240, 48)
		bouton.custom_minimum_size = Vector2(240, 48)
		bouton.add_theme_font_size_override("font_size", 18)
	%ReinitialiserClavier.text = "Réinitialiser le clavier"
	%ReinitialiserManette.text = "Réinitialiser la manette"


func mettre_a_jour_affichage_clavier() -> void:
	for action in boutons_actions["clavier"]:
		var evenements := InputMap.action_get_events(action)

		for evenement in evenements:
			if evenement is InputEventKey:
				var code: int = evenement.keycode
				if code == 0:
					code = evenement.physical_keycode if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(evenement.physical_keycode)
				boutons_actions["clavier"][action].text = en_francais(OS.get_keycode_string(code))
				break

			if evenement is InputEventMouseButton:
				boutons_actions["clavier"][action].text = noms_souris[evenement.button_index]
				break


func mettre_a_jour_affichage_manette() -> void:
	for action in boutons_actions["manette"]:
		var bouton = boutons_actions["manette"][action]
		var evenements := InputMap.action_get_events(action)

		for evenement in evenements:
			if evenement is InputEventJoypadButton:
				afficher_image_manette_bouton(bouton,evenement.button_index)
				break
			elif evenement is InputEventJoypadMotion:
				afficher_image_manette_motion(bouton, evenement.axis, evenement.axis_value)


func afficher_image_manette_bouton(bouton: Button, button_index: int) -> void:
	var chemin = images_manette.get(button_index, "")
	if chemin == "":
		bouton.text = "?"
		return
	var texture := load(chemin)
	if texture:
		var icone: TextureRect = bouton.get_node("Icone")
		icone.texture = texture
		bouton.text = ""

func afficher_image_manette_motion(bouton: Button, axis, axis_value) -> void:
	
	var direction := -1 if axis_value < 0.0 else 1
	var chemin = images_manette.get([axis, direction],"")
	
	if chemin == "":
		bouton.text = "?"
		return
	var texture := load(chemin)
	if texture:
		var icone: TextureRect = bouton.get_node("Icone")
		icone.texture = texture
		bouton.text = ""

func en_francais(keycode: String)-> String:
	match keycode:
		"Shift":
			return "Maj"
		"Ctrl":
			return "Ctrl"
		"Alt":
			return "Alt"
		"Space":
			return "Espace"
		"Enter":
			return "Entrée"
		"Escape":
			return "Échap"
		"Tab":
			return "Tab"
		"Backspace":
			return "Retour arrière"
		"Delete":
			return "Suppr"
		"Up":
			return "Flèche haut"
		"Down":
			return "Flèche bas"
		"Left":
			return "Flèche gauche"
		"Right":
			return "Flèche droite"
		_:
			return keycode
