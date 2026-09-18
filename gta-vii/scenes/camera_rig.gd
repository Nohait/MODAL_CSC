extends Node3D

## Objet que la caméra doit suivre.
@export var target: Node3D

## Réactivité du suivi de la caméra.
## Plus la valeur est élevée, plus la caméra rattrape rapidement sa cible.
@export_range(0.1, 30.0, 0.1, "or_greater")
var follow_speed: float = 8.0

func _ready() -> void:
	if is_instance_valid(target):
		global_position = target.global_position


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	#Lissage exponentiel du mouvement de la caméra en fonction du temps
	var follow_weight: float = 1.0 - exp(-follow_speed * delta)

	global_position = global_position.lerp(
		target.global_position,
		follow_weight
	)
