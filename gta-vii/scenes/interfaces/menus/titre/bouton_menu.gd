extends Button

const PLAQUE = preload("res://assets/textures/interfaces/titre/plaque_bouton.svg")
const REFLET = preload("res://scenes/interfaces/menus/titre/bouton_menu.gdshader")
const POLICE = preload("res://assets/fonts/Oswald-SemiBold.ttf")


@export var taille_police := 28
var fond: TextureRect
var icone: TextureRect

@export var taille_minimale := Vector2(300, 74)

func _ready() -> void:
	custom_minimum_size = taille_minimale
	# Le Button garde ses clics et son texte ; une plaque dessinée remplace son fond.
	for etat in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	add_theme_font_override("font", POLICE)
	add_theme_font_size_override("font_size", taille_police)
	add_theme_color_override("font_color", Color("f0e5cf"))
	add_theme_color_override("font_hover_color", Color("fff2cc"))
	add_theme_color_override("font_pressed_color", Color("e8b37d"))
	add_theme_color_override("font_shadow_color", Color(0.015, 0.02, 0.025, 0.9))
	add_theme_constant_override("shadow_offset_y", 2)
	
	fond = TextureRect.new()
	fond.texture = PLAQUE
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fond.show_behind_parent = true
	
	var mat := ShaderMaterial.new()
	mat.shader = REFLET
	mat.set_shader_parameter("survol", 0.0)
	fond.material = mat
	add_child(fond)
	
	icone = TextureRect.new()
	icone.name = "Icone"
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icone.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icone.custom_minimum_size = Vector2(50, 50)
	icone.size = Vector2(50, 50)

	icone.set_anchors_preset(Control.PRESET_CENTER)
	icone.position = -icone.size / 2.0
	add_child(icone)
	
	# Connexion des événements
	mouse_entered.connect(grab_focus)
	

func _process(delta: float) -> void:
	if fond == null: return
	fond.material.set_shader_parameter("taille", size)
	# Utiliser l'état réel évite un survol bloqué après un changement de menu.
	var cible := 1.0 if not disabled and (is_hovered() or (has_focus() and not Input.get_connected_joypads().is_empty())) else 0.0
	var valeur = fond.material.get_shader_parameter("survol")
	var actuel: float = float(valeur) if valeur != null else 0.0
	fond.material.set_shader_parameter("survol", lerpf(actuel, cible, 1.0 - exp(-12.0 * delta)))
	fond.modulate = Color(0.8, 0.8, 0.8, 0.45) if disabled else Color(0.82, 0.82, 0.82) if is_pressed() else Color.WHITE

func _make_custom_tooltip(texte: String) -> Object:
	if texte.strip_edges().is_empty(): return null
	var bulle = preload("res://scenes/interfaces/menus/infobulle_metal.gd").new()
	bulle.texte = texte
	return bulle
	
