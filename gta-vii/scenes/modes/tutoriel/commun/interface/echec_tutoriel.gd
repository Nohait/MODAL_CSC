extends CanvasLayer

signal recommencer

func afficher(texte: String) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	var centre := CenterContainer.new()
	add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panneau := PanelContainer.new()
	centre.add_child(panneau)
	var marge := MarginContainer.new()
	for bord in ["left", "right", "top", "bottom"]: marge.add_theme_constant_override("margin_" + bord, 24)
	panneau.add_child(marge)
	var contenu := VBoxContainer.new()
	contenu.add_theme_constant_override("separation", 16)
	marge.add_child(contenu)
	var message := Label.new()
	message.text = texte + "\nReprenez à l’entrée de cette zone, avec le matériel que vous aviez en arrivant."
	contenu.add_child(message)
	var bouton := Button.new()
	bouton.text = "Recommencer cette salle"
	bouton.pressed.connect(func(): recommencer.emit())
	contenu.add_child(bouton)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	bouton.grab_focus()
