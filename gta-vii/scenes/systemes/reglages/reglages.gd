extends Node

const FICHIER = "user://reglages.cfg"
const MENU = preload("res://scenes/interfaces/menus/options/menu_options.tscn")
const BUS_VOLUMES = {"general": "Master", "ambiance": "Ambiance", "effets": "Effets"}
var volumes := {"general": 1.0, "ambiance": 1.0, "effets": 1.0}
var sensibilite := 1.0
var mode_fenetre: int
var menu: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mode_fenetre = DisplayServer.window_get_mode()
	charger()
	# Le curseur est un autre autoload : attendre que tous soient prêts.
	_preparer_menu.call_deferred()

func _preparer_menu() -> void:
	get_node("/root/CursorManager").vitesse = 1000.0 * sensibilite
	menu = MENU.instantiate()
	add_child(menu)

func _unhandled_input(event: InputEvent) -> void:
	var raccourci: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F2
	var bouton_start: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
	if (raccourci or bouton_start) and is_instance_valid(menu):
		menu.ouvrir()
		get_viewport().set_input_as_handled()

func ouvrir() -> void:
	if is_instance_valid(menu): menu.ouvrir()

func regler_volume(categorie: String, valeur: float) -> void:
	volumes[categorie] = clampf(valeur, 0.0, 1.0)
	_appliquer_volume(categorie)
	sauvegarder()

func _appliquer_volume(categorie: String) -> void:
	var indice := AudioServer.get_bus_index(BUS_VOLUMES[categorie])
	if indice < 0: return
	var volume: float = volumes[categorie]
	# 0 % coupe réellement le bus ; les autres valeurs deviennent des décibels.
	AudioServer.set_bus_mute(indice, volume <= 0.0)
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(volume, 0.0001)))

func regler_sensibilite(valeur: float) -> void:
	sensibilite = clampf(valeur, 0.25, 2.5)
	get_node("/root/CursorManager").vitesse = 1000.0 * sensibilite
	sauvegarder()

func regler_plein_ecran(actif: bool) -> void:
	mode_fenetre = DisplayServer.WINDOW_MODE_FULLSCREEN if actif else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode_fenetre)
	sauvegarder()

func charger() -> void:
	var fichier := ConfigFile.new()
	if fichier.load(FICHIER) == OK:
		for categorie in volumes:
			volumes[categorie] = clampf(float(fichier.get_value("audio", categorie, 1.0)), 0.0, 1.0)
		sensibilite = clampf(float(fichier.get_value("manette", "sensibilite", 1.0)), 0.25, 2.5)
		mode_fenetre = int(fichier.get_value("affichage", "mode", mode_fenetre))
		if mode_fenetre not in [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_MAXIMIZED, DisplayServer.WINDOW_MODE_FULLSCREEN]:
			mode_fenetre = DisplayServer.WINDOW_MODE_MAXIMIZED
		DisplayServer.window_set_mode(mode_fenetre)
		var actions := fichier.get_section_keys("commandes") if fichier.has_section("commandes") else PackedStringArray()
		for action in actions:
			if not InputMap.has_action(action): continue
			var evenements: Array = fichier.get_value("commandes", action, [])
			var charges: Array[InputEvent] = []
			for donnees in evenements:
				var evenement := _lire_evenement(donnees)
				if evenement != null: charges.append(evenement)
			if charges.is_empty(): continue
			InputMap.action_erase_events(action)
			for evenement in charges: InputMap.action_add_event(action, evenement)
	for categorie in volumes: _appliquer_volume(categorie)

func sauvegarder() -> void:
	var fichier := ConfigFile.new()
	for categorie in volumes: fichier.set_value("audio", categorie, volumes[categorie])
	fichier.set_value("manette", "sensibilite", sensibilite)
	fichier.set_value("affichage", "mode", mode_fenetre)
	# Garder les deux périphériques : changer une touche ne doit pas effacer la manette.
	for action in InputMap.get_actions():
		if action.begins_with("ui_"): continue
		var evenements: Array[Dictionary] = []
		for evenement in InputMap.action_get_events(action):
			var donnees := _decrire_evenement(evenement)
			if not donnees.is_empty(): evenements.append(donnees)
		fichier.set_value("commandes", action, evenements)
	var erreur := fichier.save(FICHIER)
	if erreur != OK: push_warning("Impossible de sauvegarder les options : %s" % error_string(erreur))

func _decrire_evenement(event: InputEvent) -> Dictionary:
	# Des données simples dans le fichier, plutôt que des objets sérialisés.
	if event is InputEventKey:
		return {"type": "clavier", "touche": event.keycode, "physique": event.physical_keycode, "maj": event.shift_pressed, "ctrl": event.ctrl_pressed, "alt": event.alt_pressed, "meta": event.meta_pressed}
	if event is InputEventMouseButton: return {"type": "souris", "bouton": event.button_index}
	if event is InputEventJoypadButton: return {"type": "bouton", "bouton": event.button_index, "device": event.device}
	if event is InputEventJoypadMotion: return {"type": "axe", "axe": event.axis, "valeur": event.axis_value, "device": event.device}
	return {}

func _lire_evenement(donnees: Dictionary) -> InputEvent:
	match donnees.get("type", ""):
		"clavier":
			var event := InputEventKey.new()
			event.keycode = int(donnees.get("touche", 0))
			event.physical_keycode = int(donnees.get("physique", 0))
			event.shift_pressed = donnees.get("maj", false)
			event.ctrl_pressed = donnees.get("ctrl", false)
			event.alt_pressed = donnees.get("alt", false)
			event.meta_pressed = donnees.get("meta", false)
			return event
		"souris":
			var event := InputEventMouseButton.new()
			event.button_index = int(donnees.get("bouton", 1))
			return event
		"bouton":
			var event := InputEventJoypadButton.new()
			event.button_index = int(donnees.get("bouton", 0))
			event.device = int(donnees.get("device", -1))
			return event
		"axe":
			var event := InputEventJoypadMotion.new()
			event.axis = int(donnees.get("axe", 0))
			event.axis_value = float(donnees.get("valeur", 1.0))
			event.device = int(donnees.get("device", -1))
			return event
	return null
