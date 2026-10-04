extends Button

var animation: Tween
var horloge := 0.0
@onready var visuel: Control = $Visuel
@onready var image: TextureRect = $Visuel/Image

func _ready() -> void:
	# Une vraie surface Button conserve les clics ; son image remplace les fonds standards.
	for etat in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	image.material = image.material.duplicate()
	resized.connect(_actualiser_taille)
	_actualiser_taille()
	mouse_entered.connect(_animer.bind(true))
	mouse_exited.connect(_animer.bind(false))
	focus_entered.connect(_animer.bind(true))
	focus_exited.connect(_animer.bind(false))
	focus_mode = Control.FOCUS_NONE

func afficher(definition: Dictionary) -> void:
	image.texture = definition.image
	$Visuel/Titre.text = definition.titre

func _actualiser_taille() -> void:
	# Agrandir seulement le visuel : la place de la carte dans le menu reste stable.
	visuel.pivot_offset = size / 2.0
	image.material.set_shader_parameter("taille", size)

func _animer(survole: bool) -> void:
	survole = survole or has_focus()
	if animation:
		animation.kill()
	animation = create_tween().set_parallel(true)
	# Taille et incandescence progressent ensemble, sans saut au passage de la souris.
	animation.tween_property(visuel, "scale", Vector2.ONE * (1.045 if survole else 1.0), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation.tween_property(image.material, "shader_parameter/survol", 1.0 if survole else 0.0, 0.18)

func _process(delta: float) -> void:
	horloge += delta
	image.material.set_shader_parameter("horloge", horloge)
