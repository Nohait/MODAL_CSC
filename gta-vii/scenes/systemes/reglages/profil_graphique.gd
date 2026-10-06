extends Resource
class_name ProfilGraphique

@export var titre := "Complet"
@export_range(0.5, 1.0, 0.05) var resolution_3d := 1.0
# 0 conserve tous les détails. La distance est mesurée depuis la caméra.
@export_range(0.0, 150.0, 5.0) var distance_details := 0.0
@export_range(0.0, 15.0, 1.0) var marge_distance := 5.0
