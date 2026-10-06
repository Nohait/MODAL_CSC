class_name NavigationManette
extends Node

var menu: Control
var etait_visible := false
var delai := 0.0

static func installer(racine: Control) -> void:
	var navigation := NavigationManette.new()
	navigation.menu = racine
	navigation.process_mode = Node.PROCESS_MODE_ALWAYS
	racine.add_child(navigation)

func _process(delta: float) -> void:
	delai -= delta
	if delai > 0.0:
		return
	delai = 0.1
	var visible := menu.is_visible_in_tree()
	var vient_ouvrir := visible and not etait_visible
	etait_visible = visible
	var manette := _manette_detectee()
	var options: Array[Control] = []
	_collecter(menu, options, manette)
	if not visible or not manette or options.is_empty():
		return
	var selection := menu.get_viewport().gui_get_focus_owner()
	# Conserver le choix courant et le focus d'un sous-menu déjà ouvert.
	if vient_ouvrir or selection == null or not selection.is_visible_in_tree():
		var premier := options[0]
		# Privilégier la première carte proposée, avant les boutons de retour.
		for option in options:
			if option.has_signal("selected") or option.has_signal("selectionne"):
				premier = option
				break
		premier.grab_focus()

func _collecter(noeud: Node, options: Array[Control], manette: bool) -> void:
	if noeud is ScrollContainer:
		noeud.follow_focus = true
	var carte := noeud is Control and (noeud.has_signal("selected") or noeud.has_signal("selectionne"))
	if carte and (noeud.get("lecture_seule") == true or noeud.get_meta("revelation_bloquee", false)):
		carte = false
	if noeud is BaseButton or carte:
		noeud.focus_mode = Control.FOCUS_ALL if manette else Control.FOCUS_NONE
		if noeud.is_visible_in_tree() and not noeud.is_queued_for_deletion():
			if not noeud is BaseButton or not noeud.disabled:
				options.append(noeud)
	for enfant in noeud.get_children():
		_collecter(enfant, options, manette)

func _manette_detectee() -> bool:
	return not Input.get_connected_joypads().is_empty()
