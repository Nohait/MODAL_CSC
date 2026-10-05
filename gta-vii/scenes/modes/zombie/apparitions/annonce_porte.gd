extends Node3D

@export_range(0.0, 0.15, 0.005) var force_secousse := 0.045
@export_range(1, 6) var nombre_coups := 3

@onready var portes: Node3D = get_parent().get_node("Portes")
@onready var poussiere: CPUParticles3D = $Poussiere
var dernier_coup := -1

func actualiser(progression: float) -> void:
	# Les portes s'ouvrent à 65 % de l'arrivée : terminer les coups avant.
	if progression >= 0.6:
		portes.position = Vector3.ZERO
		portes.rotation = Vector3.ZERO
		return
	var avance := progression / 0.6 * nombre_coups
	var coup := floori(avance)
	var phase := fmod(avance, 1.0)
	if coup != dernier_coup:
		dernier_coup = coup
		poussiere.restart()
		poussiere.emitting = true
	# Chaque coup pousse les battants vers la salle, puis s'amortit.
	# Le cadre reste fixe ; seul le parent des battants est secoué.
	var amortissement := pow(1.0 - phase, 3.0)
	portes.position.z = sin(phase * TAU * 2.0) * force_secousse * amortissement
	portes.rotation.x = sin(phase * TAU) * force_secousse * 0.35 * amortissement

func reinitialiser() -> void:
	dernier_coup = -1
	portes.position = Vector3.ZERO
	portes.rotation = Vector3.ZERO
	poussiere.emitting = false
