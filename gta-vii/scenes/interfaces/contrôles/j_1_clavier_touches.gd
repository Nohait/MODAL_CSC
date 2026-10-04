extends VBoxContainer


var boutons_actions = {}

var action_a_modifier := ""
var en_attente := false

func _ready() -> void:
	await get_parent().get_parent().ready
	boutons_actions =get_parent().get_parent().boutons_actions
	#On relie les boutons à l'activation de la fonction rebind
	for action in boutons_actions:
		boutons_actions[action].pressed.connect(commencer_rebind.bind(action))

func commencer_rebind(action: String) -> void:
	boutons_actions[action].text = "..."
	action_a_modifier = action
	en_attente = true

func changer_touche(event: InputEventKey) -> void:
	InputMap.action_erase_events(action_a_modifier)
	InputMap.action_add_event(action_a_modifier, event)
	
	boutons_actions[action_a_modifier].text = OS.get_keycode_string(event.keycode)
	
	en_attente = false
	action_a_modifier = ""

func _input(event: InputEvent) -> void:
	if not en_attente:
		return

	if event is InputEventKey and event.pressed:
		changer_touche(event)
