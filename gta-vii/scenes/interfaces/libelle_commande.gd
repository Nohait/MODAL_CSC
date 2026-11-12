extends RefCounted

const ECHELLE_ICONE := 1.6

static func icone(action: StringName, joueur: Node) -> Texture2D:
	if not is_instance_valid(joueur) or joueur.get("usingController") != true: return null
	for evenement in InputMap.action_get_events(action):
		var fichier := ""
		if evenement is InputEventJoypadButton:
			fichier = {JOY_BUTTON_A: "a", JOY_BUTTON_B: "b", JOY_BUTTON_X: "x", JOY_BUTTON_Y: "y", JOY_BUTTON_LEFT_SHOULDER: "lb", JOY_BUTTON_RIGHT_SHOULDER: "rb", JOY_BUTTON_LEFT_STICK: "l_stick_click", JOY_BUTTON_RIGHT_STICK: "r_stick_click", JOY_BUTTON_START: "menu", JOY_BUTTON_BACK: "view"}.get(evenement.button_index, "")
		elif evenement is InputEventJoypadMotion:
			fichier = {JOY_AXIS_TRIGGER_LEFT: "lt", JOY_AXIS_TRIGGER_RIGHT: "rt"}.get(evenement.axis, "")
		if fichier != "": return load("res://assets/textures/controles/" + fichier + ".png") as Texture2D
	return null

static func nom(action: StringName, joueur: Node) -> String:
	var manette: bool = is_instance_valid(joueur) and joueur.get("usingController") == true
	for evenement in InputMap.action_get_events(action):
		if (evenement is InputEventJoypadButton or evenement is InputEventJoypadMotion) != manette:
			continue
		if evenement is InputEventJoypadButton:
			match evenement.button_index:
				JOY_BUTTON_A: return "A"
				JOY_BUTTON_B: return "B"
				JOY_BUTTON_X: return "X"
				JOY_BUTTON_Y: return "Y"
				JOY_BUTTON_LEFT_SHOULDER: return "LB"
				JOY_BUTTON_RIGHT_SHOULDER: return "RB"
			return "Bouton %d" % evenement.button_index
		if evenement is InputEventJoypadMotion:
			match evenement.axis:
				JOY_AXIS_TRIGGER_LEFT: return "LT"
				JOY_AXIS_TRIGGER_RIGHT: return "RT"
			return evenement.as_text()
		if evenement is InputEventKey:
			var code: int = evenement.keycode
			if code == 0:
				code = evenement.physical_keycode if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(evenement.physical_keycode)
			return OS.get_keycode_string(code)
		if evenement is InputEventMouseButton:
			match evenement.button_index:
				MOUSE_BUTTON_LEFT: return "Clic gauche"
				MOUSE_BUTTON_RIGHT: return "Clic droit"
			return "Clic %d" % evenement.button_index
	return "Interagir"

static func adapter(texte: String, joueur: Node) -> String:
	return texte.replace("clic gauche", nom(&"primary_attack", joueur)).replace("Clic gauche", nom(&"primary_attack", joueur)).replace("Espace", nom(&"dash", joueur)).replace(" · E", " · " + nom(&"interact", joueur)).replace("sur E pour", "sur " + nom(&"interact", joueur) + " pour")

static func afficher(label: Label, texte: String, action: StringName, joueur: Node) -> void:
	if not label.has_meta("couleur_commande"):
		label.set_meta("couleur_commande", label.get_theme_color("font_color"))
	var image := icone(action, joueur)
	var ancien := label.get_node_or_null("TexteAvecCommande") as RichTextLabel
	if image == null:
		label.add_theme_color_override("font_color", label.get_meta("couleur_commande"))
		label.text = texte
		if ancien: ancien.hide()
		return
	var commande := nom(action, joueur)
	if not (texte.begins_with(commande + " · ") or texte.ends_with(" · " + commande) or texte.contains("sur " + commande + " pour") or texte.contains("le " + commande + " pour") or texte.contains(" + " + commande)):
		label.add_theme_color_override("font_color", label.get_meta("couleur_commande"))
		label.text = texte
		if ancien: ancien.hide()
		return
	var taille := label.get_theme_font_size("font_size")
	var taille_icone := ceili(taille * ECHELLE_ICONE)
	var balise := "[img=%dx%d]%s[/img]" % [taille_icone, taille_icone, image.resource_path]
	var contenu := texte.replace(commande + " · ", balise + " · ").replace(" · " + commande, " · " + balise).replace("sur " + commande + " pour", "sur " + balise + " pour").replace("le " + commande + " pour", "le " + balise + " pour").replace(" + " + commande, " + " + balise)
	if ancien == null:
		ancien = RichTextLabel.new()
		ancien.name = "TexteAvecCommande"
		ancien.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ancien.bbcode_enabled = true
		ancien.scroll_active = false
		label.add_child(ancien)
		ancien.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ancien.add_theme_font_override("normal_font", label.get_theme_font("font"))
	ancien.add_theme_font_size_override("normal_font_size", taille)
	ancien.offset_bottom = float(taille_icone - taille)
	ancien.add_theme_color_override("default_color", label.get_meta("couleur_commande"))
	ancien.text = contenu
	label.text = texte
	label.add_theme_color_override("font_color", Color.TRANSPARENT)
	ancien.show()

static func afficher_consigne(label: Label, texte: String, joueur: Node) -> void:
	if not (texte.contains("clic gauche") or texte.contains("Clic gauche") or texte.contains("Espace") or texte.contains(" · E") or texte.contains("sur E pour")):
		label.text = texte
		label.add_theme_color_override("font_color", label.get_meta("couleur_commande", label.get_theme_color("font_color")))
		var ancien := label.get_node_or_null("TexteAvecCommande")
		if ancien: ancien.hide()
		return
	var action: StringName = &"interact"
	if texte.contains("clic gauche") or texte.contains("Clic gauche"):
		action = &"primary_attack"
	elif texte.contains("Espace"):
		action = &"dash"
	afficher(label, adapter(texte, joueur), action, joueur)

static func afficher_3d(label: Label3D, texte: String, action: StringName, joueur: Node) -> void:
	var image := icone(action, joueur)
	var ancien := label.get_node_or_null("IconeCommande") as Sprite3D
	if image == null:
		label.text = texte
		if ancien: ancien.hide()
		return
	var commande := nom(action, joueur)
	var taille := label.font_size
	var taille_icone := ceili(taille * ECHELLE_ICONE)
	var balise := "[img=%dx%d]%s[/img]" % [taille_icone, taille_icone, image.resource_path]
	var contenu := texte.replace("[" + commande + "]", balise).replace(commande + " · ", balise + " · ")
	var vue := label.get_node_or_null("VueCommande") as SubViewport
	if vue == null:
		vue = SubViewport.new()
		vue.name = "VueCommande"
		vue.transparent_bg = true
		label.add_child(vue)
		var ligne := RichTextLabel.new()
		ligne.name = "Ligne"
		ligne.bbcode_enabled = true
		ligne.scroll_active = false
		ligne.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vue.add_child(ligne)
	var police: Font = label.font if label.font else ThemeDB.fallback_font
	var sans_icone := texte.replace("[" + commande + "]", "").replace(commande + " · ", "")
	var largeur := ceili(police.get_string_size(sans_icone, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x + taille_icone + 24.0)
	vue.size = Vector2i(largeur, ceili(taille_icone * 1.6))
	var ligne: RichTextLabel = vue.get_node("Ligne")
	ligne.size = vue.size
	ligne.add_theme_font_size_override("normal_font_size", taille)
	ligne.add_theme_color_override("default_color", label.modulate)
	if label.font: ligne.add_theme_font_override("normal_font", label.font)
	if ligne.text != contenu:
		ligne.text = contenu
		vue.render_target_update_mode = SubViewport.UPDATE_ONCE
	if ancien == null:
		ancien = Sprite3D.new()
		ancien.name = "IconeCommande"
		ancien.billboard = label.billboard
		ancien.pixel_size = label.pixel_size
		ancien.no_depth_test = label.no_depth_test
		label.add_child(ancien)
	ancien.texture = vue.get_texture()
	label.text = ""
	ancien.show()
