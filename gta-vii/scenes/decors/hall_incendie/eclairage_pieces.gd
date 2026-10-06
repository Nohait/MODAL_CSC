extends Node3D

var temps := 0.0

func _process(delta: float) -> void:
	temps += delta
	# Le local technique oscille doucement : éviter les flashs brusques pendant le combat.
	$AppliqueTechnique.light_energy = 1.1 * (0.85 + 0.1 * sin(temps * 3.0) + 0.05 * sin(temps * 11.0))
