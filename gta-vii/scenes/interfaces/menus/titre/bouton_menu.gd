extends Button

const PLAQUE = preload("res://assets/textures/interfaces/titre/plaque_bouton.svg")
const REFLET = preload("res://scenes/interfaces/menus/titre/bouton_menu.gdshader")
const POLICE = preload("res://assets/fonts/Oswald-SemiBold.ttf")
@export var taille_police := 28
var fond: TextureRect
var animation: Tween

func _ready() -> void:
	# Le Button garde ses clics et son texte ; une plaque dessinée remplace son fond.
	for etat in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	add_theme_font_override("font", POLICE)
	add_theme_font_size_override("font_size", taille_police)
	add_theme_color_override("font_color", Color("e9d8b4"))
	add_theme_color_override("font_hover_color", Color("fff2cc"))
	add_theme_color_override("font_pressed_color", Color("e8b37d"))
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
	mouse_entered.connect(_animer.bind(true))
	mouse_exited.connect(_animer.bind(false))
	focus_entered.connect(_animer.bind(true))
	focus_exited.connect(_animer.bind(false))

func _animer(survole: bool) -> void:
	if animation:
		animation.kill()
	animation = create_tween()
	# Le reflet glisse progressivement au lieu de sauter à l'entrée de la souris.
	animation.tween_property(fond.material, "shader_parameter/survol", 1.0 if survole else 0.0, 0.18)
