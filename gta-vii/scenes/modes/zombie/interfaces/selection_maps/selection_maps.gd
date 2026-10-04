extends Control

const CATALOGUE = preload("res://scenes/modes/zombie/maps/catalogue_maps.gd")
const CARTE = preload("res://scenes/modes/zombie/interfaces/selection_maps/carte_map.tscn")
var changement_en_cours := false

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Retour.pressed.connect(_retour)
	for definition in CATALOGUE.MAPS:
		var carte = CARTE.instantiate()
		%Cartes.add_child(carte)
		carte.afficher(definition)
		carte.pressed.connect(_choisir.bind(definition.scene))

func _choisir(map: PackedScene) -> void:
	# Conserver la map choisie pour rejouer la même après une mort ou avec R.
	get_tree().set_meta("map_zombie", map)
	_changer_scene("res://scenes/modes/zombie/mode_zombie.tscn")

func _retour() -> void:
	_changer_scene("res://scenes/interfaces/menus/ecran_titre.tscn")

func _changer_scene(chemin: String) -> void:
	if changement_en_cours:
		return
	changement_en_cours = true
	var erreur := get_tree().change_scene_to_file(chemin)
	if erreur != OK:
		changement_en_cours = false
		push_error("Impossible d'ouvrir la scène : " + chemin)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour()
		get_viewport().set_input_as_handled()
