extends PanelContainer

var texte := ""
var libelle: Label
var fond: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.4)
	add_theme_stylebox_override("panel", style)
	fond = TextureRect.new()
	fond.texture = preload("res://assets/textures/interfaces/titre/plaque_bouton.svg")
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fond.show_behind_parent = true
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/interfaces/menus/titre/bouton_menu.gdshader")
	mat.set_shader_parameter("survol", 0.0)
	mat.set_shader_parameter("eclaircissement", 0.12)
	fond.material = mat
	libelle = Label.new()
	libelle.text = texte
	# Les explications longues restent dans une plaque lisible à l'écran.
	if texte.length() > 65:
		libelle.custom_minimum_size.x = 380
		libelle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	libelle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	libelle.add_theme_font_override("font", preload("res://assets/fonts/Oswald-SemiBold.ttf"))
	libelle.add_theme_font_size_override("font_size", 17)
	libelle.add_theme_color_override("font_color", Color("f2e4ce"))
	libelle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	libelle.add_theme_constant_override("shadow_offset_y", 1)
	add_child(libelle)

func _process(_delta: float) -> void:
	if not is_visible_in_tree(): return
	# Le Container réserve les marges au texte, mais la plaque couvre toute l'infobulle.
	fond.position = Vector2.ZERO
	fond.size = size
	fond.material.set_shader_parameter("taille", fond.size)
