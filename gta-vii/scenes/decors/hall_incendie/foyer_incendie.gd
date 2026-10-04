@tool
extends Node3D

@export_range(0.2, 2.0, 0.05) var taille := 1.0:
	set(valeur):
		taille = valeur
		if is_node_ready():
			_actualiser()
@export_range(0.0, 5.0, 0.1) var energie := 1.8:
	set(valeur):
		energie = valeur
		if is_node_ready():
			_actualiser()
@export_range(1.0, 10.0, 0.1) var portee_lumiere := 5.0:
	set(valeur):
		portee_lumiere = valeur
		if is_node_ready():
			_actualiser()

@export_range(0.0, 1.0, 0.1) var densite_fumee := 1.0:
	set(valeur):
		densite_fumee = valeur
		if is_node_ready():
			_actualiser()

var temps := 0.0
@onready var lumiere: OmniLight3D = $Lumiere

func _ready() -> void:
	# Décaler les oscillations pour que les foyers ne battent pas tous ensemble.
	temps = global_position.x * 0.7 + global_position.z * 0.3
	_actualiser()

func _process(delta: float) -> void:
	temps += delta
	# Deux oscillations superposées donnent un vacillement doux, sans flash.
	lumiere.light_energy = energie * (0.88 + 0.08 * sin(temps * 5.0) + 0.04 * sin(temps * 11.3))

func _actualiser() -> void:
	# Agrandir les particules indépendamment de la portée de leur éclairage.
	$Flammes.scale = Vector3.ONE * taille
	$Fumee.scale = Vector3.ONE * taille
	# Les petits foyers peuvent produire moins de fumée sans changer les autres.
	$Fumee.amount = maxi(1, roundi(10 * densite_fumee))
	$Fumee.emitting = densite_fumee > 0.0
	$Braises.scale = Vector3.ONE * taille
	lumiere.position.y = 0.45 * taille
	lumiere.omni_range = portee_lumiere
	lumiere.light_energy = energie
