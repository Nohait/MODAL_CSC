extends Node3D

@export var action: StringName = &"interact"
@export var verbe := "Ouvrir"
@export_range(0.1, 1.0, 0.05) var intervalle_actualisation := 0.25
var attente_actualisation := 0.0

func _ready() -> void:
	_actualiser_texte()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	attente_actualisation -= delta
	if attente_actualisation > 0.0: return
	attente_actualisation = intervalle_actualisation
	_actualiser_texte()

func _actualiser_texte() -> void:
	$Indication.text = "%s - [%s]" % [verbe, _nom_commande()]

func _nom_commande() -> String:
	for evenement in InputMap.action_get_events(action):
		if evenement is InputEventKey:
			var code: int = evenement.keycode
			if code == 0:
				code = evenement.physical_keycode if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(evenement.physical_keycode)
			var nom := OS.get_keycode_string(code)
			if not nom.is_empty(): return nom
		if evenement is InputEventMouseButton:
			return String({
				MOUSE_BUTTON_LEFT: "Clic gauche",
				MOUSE_BUTTON_RIGHT: "Clic droit",
				MOUSE_BUTTON_MIDDLE: "Clic milieu",
			}.get(evenement.button_index, evenement.as_text()))
	return "Interagir"
