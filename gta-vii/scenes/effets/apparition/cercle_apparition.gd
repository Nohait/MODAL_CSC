extends MeshInstance3D

@export var couleur := Color(1.0, 0.55, 0.08)
var mat: ShaderMaterial

func _ready() -> void:
	# Chaque apparition anime son propre matériau, sans modifier les autres cercles.
	mat = material_override.duplicate()
	material_override = mat
	mat.set_shader_parameter("couleur", couleur)

func charger(progression: float) -> void:
	mat.set_shader_parameter("charge", progression)

func attenuer(opacite: float) -> void:
	mat.set_shader_parameter("opacite", opacite)
