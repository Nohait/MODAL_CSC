extends CanvasLayer

signal terminee

var pause_avant := false
var souris_avant := Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 104
	pause_avant = get_tree().paused
	souris_avant = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.04, 0.05, 0.72)
	add_child(voile)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	voile.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panneau := PanelContainer.new()
	panneau.theme = preload("res://scenes/interfaces/theme_intervention/theme.tres")
	panneau.add_theme_stylebox_override("panel", preload("res://scenes/interfaces/theme_intervention/panneau.tres"))
	panneau.custom_minimum_size.x = 690
	centre.add_child(panneau)
	var contenu := VBoxContainer.new()
	contenu.add_theme_constant_override("separation", 18)
	panneau.add_child(contenu)
	var titre := Label.new()
	titre.text = "09 · VICTIMES ET RAVITAILLEMENT"
	titre.theme_type_variation = &"TitreIntervention"
	titre.add_theme_font_size_override("font_size", 25)
	contenu.add_child(titre)
	var texte := Label.new()
	texte.text = "Chaque victime encore avec vous au passage compte pour le ravitaillement : une victime vivante rapporte un point.\nLes victimes encore en vie continueront avec vous dans la salle suivante. Le compte à rebours indique le temps restant avant que le feu n’épuise les victimes encore captives."
	texte.custom_minimum_size = Vector2(630, 105)
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texte.add_theme_font_size_override("font_size", 20)
	contenu.add_child(texte)
	var bouton = preload("res://scenes/interfaces/menus/titre/bouton_menu.tscn").instantiate()
	bouton.text = "Entrer dans la salle"
	bouton.taille_minimale = Vector2(630, 56)
	bouton.taille_police = 22
	contenu.add_child(bouton)
	bouton.pressed.connect(fermer)
	bouton.focus_mode = Control.FOCUS_ALL
	bouton.grab_focus()

func fermer() -> void:
	if is_queued_for_deletion(): return
	get_tree().paused = pause_avant
	Input.mouse_mode = souris_avant
	terminee.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		fermer()
