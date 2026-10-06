extends Button

var accent := Color("b18c60")
var papier: TextureRect
var temps := 0.0
var survol := 0.0

func _ready() -> void:
	# Conserver un vrai Button pour la manette, mais remplacer son habillage standard.
	for etat in ["normal", "hover", "pressed", "focus", "disabled"]:
		var marge := StyleBoxEmpty.new()
		marge.content_margin_left = 18
		marge.content_margin_right = 18
		marge.content_margin_top = 10
		marge.content_margin_bottom = 10
		add_theme_stylebox_override(etat, marge)
	add_theme_font_size_override("font_size", 17)
	add_theme_color_override("font_hover_color", Color("fff0d4"))
	add_theme_color_override("font_pressed_color", Color("fff0d4"))
	papier = TextureRect.new()
	papier.texture = preload("res://assets/textures/interfaces/ameliorations/texture_carte_300x450_r16.png")
	papier.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	papier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	papier.show_behind_parent = true
	add_child(papier)
	papier.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/interfaces/menus/onglet_carnet.gdshader")
	mat.set_shader_parameter("largeur_bord", 4.0)
	mat.set_shader_parameter("rayon_coin", 6.0)
	mat.set_shader_parameter("intensite_braises", 0.35)
	mat.set_shader_parameter("braises_personnalisees", true)
	mat.set_shader_parameter("teinte_braises", accent)
	papier.material = mat

func _process(delta: float) -> void:
	temps += delta
	var cible := 1.0 if not disabled and (is_hovered() or has_focus() or button_pressed) else 0.0
	survol = lerpf(survol, cible, 1.0 - exp(-12.0 * delta))
	papier.material.set_shader_parameter("selection", survol)
	papier.material.set_shader_parameter("horloge", temps)
	papier.material.set_shader_parameter("taille", size)
	papier.modulate.a = 0.45 if disabled else 1.0
