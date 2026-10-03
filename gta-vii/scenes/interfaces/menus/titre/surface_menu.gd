extends TextureRect

var horloge := 0.0

func _ready() -> void:
	# Chaque panneau conserve sa taille et sa couleur sans modifier les autres.
	material = material.duplicate()
	resized.connect(_actualiser_taille)
	_actualiser_taille()

func _actualiser_taille() -> void:
	material.set_shader_parameter("taille", size)

func _process(delta: float) -> void:
	horloge += delta
	material.set_shader_parameter("horloge", horloge)
