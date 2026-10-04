extends Control
var touches_par_defaut ={
		"move_forward": KEY_Z,
		"move_backward": KEY_S,
		"move_left": KEY_Q,
		"move_right": KEY_D
	}
var boutons_actions = {}

	
func _ready() -> void:
	boutons_actions = {
		"move_forward": $"Menu/J1ClavierTouches/ClavierJ1Haut",
		"move_backward": $"Menu/J1ClavierTouches/ClavierJ1Bas",
		"move_left": $"Menu/J1ClavierTouches/ClavierJ1Gauche",
		"move_right": $"Menu/J1ClavierTouches/ClavierJ1Droit"
	}
	
	%Fermer.pressed.connect(fermer)
	%Reinitialiser.visible = OS.is_debug_build()
	%Reinitialiser.pressed.connect(reinitialiser)
	hide()


func ouvrir() -> void:
	show()
	%Fermer.grab_focus()

func fermer() -> void:
	hide()
	%Fermer.release_focus()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		fermer()
		get_viewport().set_input_as_handled()

func reinitialiser() -> void:
	for action in touches_par_defaut:
		InputMap.action_erase_events(action)

		var evenement := InputEventKey.new()
		evenement.keycode = touches_par_defaut[action]
		InputMap.action_add_event(action, evenement)
		
		#On réecrit la bonne touche
		boutons_actions[action].text = OS.get_keycode_string(touches_par_defaut[action])
