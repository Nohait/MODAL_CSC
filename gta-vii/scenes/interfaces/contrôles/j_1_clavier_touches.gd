@tool
extends VBoxContainer

@export var taille_minimale_boutons := Vector2(132, 74):
	set(valeur):
		taille_minimale_boutons = valeur
		mettre_a_jour_boutons()

@onready var menu_controles = get_parent().get_parent().get_parent()
var boutons_actions = {}

var action_a_modifier := ""
var en_attente := false


func _ready() -> void:
	mettre_a_jour_boutons()
	
	#On attend que tout soit prêt, et on récupère l'ensemble des paires actions/boutons
	await menu_controles.ready
	boutons_actions = menu_controles.boutons_actions["clavier"]
	
	#On relie les boutons à l'activation de la fonction rebind
	for action in boutons_actions:
		boutons_actions[action].pressed.connect(commencer_rebind.bind(action))

func commencer_rebind(action: String) -> void:
	#en attendant que le joueur choisisse, on affiche '...'
	boutons_actions[action].text = "..."
	
	action_a_modifier = action
	en_attente = true
	boutons_actions[action].focus_mode = Control.FOCUS_NONE
	boutons_actions[action].button_mask = 0

func changer_touche(event: InputEvent) -> void:
	#On supprime l'ancien controle clavier
	var evenements_og := InputMap.action_get_events(action_a_modifier)
	for evenement in evenements_og:
		if evenement is InputEventMouseButton or evenement is InputEventKey:
			InputMap.action_erase_event(action_a_modifier, evenement)
	InputMap.action_add_event(action_a_modifier, event)
	
	#On renomme le bouton après avoir changer de touche
	if event is InputEventMouseButton:
		boutons_actions[action_a_modifier].text = menu_controles.noms_souris[event.button_index]
	else:
		boutons_actions[action_a_modifier].text = menu_controles.en_francais(OS.get_keycode_string(event.keycode))
	
	boutons_actions[action_a_modifier].button_mask = MOUSE_BUTTON_MASK_LEFT
	boutons_actions[action_a_modifier].focus_mode = Control.FOCUS_ALL
	
	en_attente = false
	action_a_modifier = ""
	

func mettre_a_jour_boutons() -> void:
	#Pour avoir une taille minimale de boutons custum
	for enfant in get_children():
		if enfant is Button:
			enfant.custom_minimum_size = taille_minimale_boutons

func _input(event: InputEvent) -> void:
	if not en_attente:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		changer_touche(event)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		changer_touche(event)
		get_viewport().set_input_as_handled()
