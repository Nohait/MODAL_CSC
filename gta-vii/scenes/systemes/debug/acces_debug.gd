extends Node

# Les interfaces au premier plan priment sur la partie qui reste chargée derrière.
const CONTEXTES = ["debug_glossaire", "debug_modal", "debug_carnet", "debug_boutique", "debug_tutoriel", "debug_partie", "debug_titre"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

static func est_raccourci(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo \
		and (event.physical_keycode == KEY_F12 or event.keycode == KEY_F12) \
		and event.ctrl_pressed and event.shift_pressed and not event.alt_pressed and not event.meta_pressed

func _input(event: InputEvent) -> void:
	if not est_raccourci(event): return
	get_viewport().set_input_as_handled()
	var reglages := get_node("/root/Reglages")
	if reglages.chargement.en_cours: return
	if is_instance_valid(reglages.menu) and reglages.menu.menu.visible: return
	for groupe in CONTEXTES:
		for contexte in get_tree().get_nodes_in_group(groupe):
			if contexte.debug_contextuel(): return
