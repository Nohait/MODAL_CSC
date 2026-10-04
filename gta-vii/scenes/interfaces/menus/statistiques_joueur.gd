extends PanelContainer

const POLICE = preload("res://assets/fonts/Oswald-SemiBold.ttf")
const ICONE_VIE = preload("res://assets/textures/interfaces/hud/icone_vie.svg")
const ICONE_MOUSSE = preload("res://assets/textures/interfaces/hud/icone_mousse.svg")
const PICTOS = "res://assets/textures/interfaces/ameliorations/pictogrammes/"
var valeurs := {}
var vitesse_base := 0.0
var materiau_icones: ShaderMaterial

var lignes: Array[HBoxContainer] = []
var infobulle: PanelContainer
var texte_infobulle: Label

func _ready() -> void:
	# Les pictos des cartes sont bruns : conserver leur alpha et les teinter en crème.
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment() { COLOR.rgb = vec3(0.93, 0.80, 0.61); }"
	materiau_icones = ShaderMaterial.new()
	materiau_icones.shader = shader
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.055, 0.055, 0.65)
	style.border_color = Color("886044")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	add_theme_stylebox_override("panel", style)
	var contenu := VBoxContainer.new()
	contenu.add_theme_constant_override("separation", 12)
	add_child(contenu)
	var titre := Label.new()
	titre.text = "LE POMPIER"
	titre.add_theme_font_override("font", POLICE)
	titre.add_theme_font_size_override("font_size", 23)
	titre.add_theme_color_override("font_color", Color("f0d0a0"))
	contenu.add_child(titre)
	_ajouter(contenu, "vie", ICONE_VIE, "Vie actuelle / vie maximale.")
	_ajouter(contenu, "mousse", ICONE_MOUSSE, "Mousse disponible / réserve maximale.")
	contenu.add_child(HSeparator.new())
	_ajouter(contenu, "degats", load(PICTOS + "pression.svg"), "Dégâts : multiplicateur actuel, effets conditionnels inclus.")
	_ajouter(contenu, "recharge", load(PICTOS + "recharge.svg"), "Vitesse de recharge : multiplicateur par rapport au début de partie.")
	_ajouter(contenu, "reserve", load(PICTOS + "reserve.svg"), "Capacité de mousse : multiplicateur de la réserve maximale.")
	_ajouter(contenu, "vitesse", load(PICTOS + "escorte_agile.svg"), "Vitesse de déplacement du pompier : multiplicateur de base.")
	_ajouter(contenu, "dash", load(PICTOS + "dash.svg"), "Récupération du dash : ×2 signifie un délai deux fois plus court.")
	_ajouter(contenu, "bouclier", load(PICTOS + "mousse_protectrice.svg"), "Bouclier du pompier : points absorbés avant de toucher sa vie.")
	var note := Label.new()
	note.text = "Survolez un pictogramme
pour connaître sa signification."
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color("bfa58c"))
	contenu.add_child(note)
	_creer_infobulle()

func _ajouter(contenu: VBoxContainer, id: String, texture: Texture2D, explication: String) -> void:
	var ligne := HBoxContainer.new()
	ligne.mouse_filter = Control.MOUSE_FILTER_PASS
	ligne.set_meta("explication", explication)
	lignes.append(ligne)
	ligne.add_theme_constant_override("separation", 12)
	contenu.add_child(ligne)
	var icone := TextureRect.new()
	icone.texture = texture
	icone.custom_minimum_size = Vector2(34, 34)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.material = materiau_icones
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ligne.add_child(icone)
	var valeur := Label.new()
	valeur.add_theme_font_override("font", POLICE)
	valeur.add_theme_font_size_override("font_size", 22)
	valeur.add_theme_color_override("font_color", Color("f0ddbd"))
	valeur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ligne.add_child(valeur)
	valeurs[id] = valeur

func actualiser(joueur: Node, upgrades: Node) -> void:
	if valeurs.is_empty(): return
	var arme = joueur.extincteur
	if vitesse_base == 0.0: vitesse_base = joueur.speed
	valeurs.vie.text = "%d / %d PV" % [ceili(joueur.BarreDeVie.value), ceili(joueur.BarreDeVie.max_value)]
	valeurs.mousse.text = "%d / %d" % [ceili(arme.charge), ceili(arme.max_charge)]
	valeurs.degats.text = "×%.2f" % (arme.get_degats() / maxf(arme.degats1, 0.001))
	valeurs.recharge.text = "×%.2f" % (arme.reload_rate / maxf(upgrades.recharge_de_base, 0.001))
	valeurs.reserve.text = "×%.2f" % (arme.max_charge / maxf(upgrades.charge_de_base, 0.001))
	valeurs.vitesse.text = "×%.2f" % (joueur.speed / maxf(vitesse_base, 0.001))
	valeurs.dash.text = "×%.2f" % (joueur.dash_cooldown / maxf(joueur.get_dash_cooldown(), 0.001))
	var bouclier := 0.0
	for protection in upgrades.boucliers_joueur: bouclier += protection.bouclier_restant
	valeurs.bouclier.text = "%d PV" % ceili(bouclier)
	valeurs.bouclier.get_parent().visible = bouclier > 0.0

func _creer_infobulle() -> void:
	# Dessiner dans le menu évite de dépendre de la fenêtre d'infobulle de Godot.
	infobulle = PanelContainer.new()
	infobulle.top_level = true
	infobulle.z_index = 100
	infobulle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("32201e")
	style.border_color = Color("b18c60")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	infobulle.add_theme_stylebox_override("panel", style)
	texte_infobulle = Label.new()
	texte_infobulle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texte_infobulle.add_theme_color_override("font_color", Color("f0ddbd"))
	texte_infobulle.add_theme_font_override("font", POLICE)
	texte_infobulle.add_theme_font_size_override("font_size", 17)
	infobulle.add_child(texte_infobulle)
	add_child(infobulle)
	infobulle.hide()

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		infobulle.hide()
		return
	var souris := get_global_mouse_position()
	for ligne in lignes:
		if ligne.is_visible_in_tree() and ligne.get_global_rect().has_point(souris):
			texte_infobulle.text = ligne.get_meta("explication")
			infobulle.size = infobulle.get_combined_minimum_size()
			var position_souhaitee := souris + Vector2(18, 20)
			var limites := get_viewport_rect()
			# Garder le texte à l'écran, notamment pour les pictogrammes à droite.
			position_souhaitee.x = clampf(position_souhaitee.x, 8, limites.size.x - infobulle.size.x - 8)
			position_souhaitee.y = clampf(position_souhaitee.y, 8, limites.size.y - infobulle.size.y - 8)
			infobulle.global_position = position_souhaitee
			infobulle.show()
			return
	infobulle.hide()
