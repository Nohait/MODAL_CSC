extends VBoxContainer

signal accepte

# Chaque ligne garde son propre état ; plusieurs descriptions peuvent rester ouvertes.
var en_cours := false
var prix := 0
var titre := ""
var description := ""
var objectif := 1
var progression := 0
var details: VBoxContainer
var accepter: Button
var entete: Button


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	# Un thème local laisse les textes des boosters inchangés.
	theme = Theme.new()
	theme.set_color("font_color", "Label", Color("3e2d20"))
	for etat in ["normal", "hover", "pressed", "disabled"]:
		var fond := StyleBoxFlat.new()
		fond.bg_color = Color("bba17a") if etat == "normal" else Color("dac199")
		if etat == "disabled":
			fond.bg_color = Color("bea989")
		fond.set_corner_radius_all(4)
		fond.content_margin_left = 10
		fond.content_margin_right = 10
		fond.content_margin_top = 8
		fond.content_margin_bottom = 8
		theme.set_stylebox(etat, "Button", fond)
		theme.set_color("font_" + etat + "_color" if etat != "normal" else "font_color", "Button", Color("78674f") if etat == "disabled" else Color("38291d"))
	var contour := StyleBoxFlat.new()
	contour.bg_color = Color(0, 0, 0, 0)
	contour.border_color = Color("79562d")
	contour.set_border_width_all(2)
	contour.set_corner_radius_all(4)
	theme.set_stylebox("focus", "Button", contour)
	entete = Button.new()
	entete.alignment = HORIZONTAL_ALIGNMENT_LEFT
	entete.focus_mode = Control.FOCUS_NONE
	entete.custom_minimum_size.y = 38
	add_child(entete)
	details = VBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	add_child(details)
	var texte := Label.new()
	texte.text = description
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texte.add_theme_font_size_override("font_size", 15)
	details.add_child(texte)
	accepter = Button.new()
	accepter.focus_mode = Control.FOCUS_NONE
	accepter.text = "Accepter le défi · %d point%s" % [prix, "s" if prix > 1 else ""] if prix > 0 else "Accepter le défi · gratuit"
	details.add_child(accepter)
	accepter.pressed.connect(func(): accepte.emit())
	entete.pressed.connect(_deplier)
	details.hide()
	_actualiser()


func afficher_progression() -> void:
	# Déplacer la ligne vers les défis actifs conserve la description dépliable.
	en_cours = true
	_actualiser()
	if objectif <= 0:
		var survie := Label.new()
		survie.text = "Salles survécues : %d" % progression
		survie.add_theme_font_size_override("font_size", 12)
		add_child(survie)
		return
	var ligne := HBoxContainer.new()
	var barre := ProgressBar.new()
	barre.custom_minimum_size = Vector2(0, 5)
	barre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barre.max_value = objectif
	barre.value = progression
	barre.show_percentage = false
	# Une piste discrète et un remplissage vert rendent l'avancement identifiable.
	var piste := StyleBoxFlat.new()
	piste.bg_color = Color("99825f")
	piste.set_corner_radius_all(2)
	var remplissage := StyleBoxFlat.new()
	remplissage.bg_color = Color("4c873d")
	remplissage.set_corner_radius_all(2)
	barre.add_theme_stylebox_override("background", piste)
	barre.add_theme_stylebox_override("fill", remplissage)
	ligne.add_child(barre)
	var nombre := Label.new()
	nombre.text = "%d/%d" % [progression, objectif]
	nombre.add_theme_font_size_override("font_size", 12)
	ligne.add_child(nombre)
	add_child(ligne)


func _actualiser() -> void:
	entete.text = ("▾ " if details.visible else "▸ ") + titre
	accepter.visible = not en_cours


func _deplier() -> void:
	details.visible = not details.visible
	_actualiser()


func actualiser_budget(points: int) -> void:
	accepter.disabled = prix > points
	accepter.tooltip_text = "Points insuffisants" if accepter.disabled else ""
