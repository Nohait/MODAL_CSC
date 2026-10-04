extends Control

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
	reinitialiser_manette()

	hide()


func ouvrir() -> void:
	show()

func fermer() -> void:
	hide()
	%Fermer.release_focus()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		fermer()
		get_viewport().set_input_as_handled()

func reinitialiser_clavier():
	for action in touches_par_defaut_clavier:
		InputMap.action_erase_events(action)
		var evenement
		if touches_par_defaut_clavier[action] in noms_souris:
			evenement = InputEventMouseButton.new()
			evenement.button_index = touches_par_defaut_clavier[action]
		else:
			evenement = InputEventKey.new()
			evenement.keycode = touches_par_defaut_clavier[action]
		InputMap.action_add_event(action, evenement)

		mettre_a_jour_affichage_clavier()

func reinitialiser_manette():
	mettre_a_jour_affichage_manette()


func mettre_a_jour_affichage_clavier() -> void:
	for action in boutons_actions["clavier"]:
		var evenements := InputMap.action_get_events(action)

		for evenement in evenements:
			if evenement is InputEventKey:
				boutons_actions["clavier"][action].text = en_francais(OS.get_keycode_string(evenement.keycode))
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
