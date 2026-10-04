@tool
extends Node3D

@export var allumee := true:
	set(valeur):
		allumee = valeur
		if is_node_ready():
			_actualiser()
@export var couleur := Color(1.0, 0.77, 0.48):
	set(valeur):
		couleur = valeur
		if is_node_ready():
			_actualiser()
@export_range(0.0, 5.0, 0.1) var energie := 1.6:
	set(valeur):
		energie = valeur
		if is_node_ready():
			_actualiser()
@export var vacillante := false:
	set(valeur):
		vacillante = valeur
		if is_node_ready():
			_actualiser()

var temps := 0.0
@onready var lumiere: OmniLight3D = $FixationDeformee/Lumiere
@onready var tube: MeshInstance3D = $FixationDeformee/Modele/Diffuseur

func _ready() -> void:
	# Chaque applique peut s'éteindre sans modifier le matériau de ses voisines.
	tube.material_override = tube.material_override.duplicate()
	_actualiser()

func _process(delta: float) -> void:
	if not vacillante or not allumee:
		return
	temps += delta
	# Une oscillation légère donne une lampe fatiguée, sans flash brutal.
	lumiere.light_energy = energie * (0.82 + 0.13 * sin(temps * 2.6) + 0.05 * sin(temps * 13.0))

func _actualiser() -> void:
	lumiere.visible = allumee
	lumiere.light_color = couleur
	lumiere.light_energy = energie
	tube.material_override.emission = couleur
	tube.material_override.emission_energy_multiplier = 2.5 if allumee else 0.0
