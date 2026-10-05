class_name EquilibrageElites
extends Resource

@export_range(0.0, 100.0) var chance_initiale := 5.0
@export_range(0.0, 10.0, 0.1) var augmentation_par_vague_ou_salle := 1.5
@export_range(0.0, 49.0) var chance_maximale := 30.0

func chance(progression: int) -> float:
	return clampf(chance_initiale + maxi(progression - 1, 0) * augmentation_par_vague_ou_salle, 0.0, minf(chance_maximale, 49.0))
