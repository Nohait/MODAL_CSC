@tool
extends CPUParticles3D

@export_range(0.0, 2.0, 0.05) var force_vent := 0.15
@export_range(0.0, 1.5, 0.05) var force_rafales := 0.1
@export_range(3.0, 12.0, 0.5) var periode_rafales := 6.0
@export_range(0.0, 45.0, 1.0) var variation_direction := 18.0
var temps := 0.0
var phase := 0.0

func _ready() -> void:
	# Chaque foyer décale ses rafales sans consommer le hasard de la génération.
	phase = global_position.x * 0.73 + global_position.z * 0.41

func _process(delta: float) -> void:
	temps += delta
	var cycle := temps * TAU / maxf(periode_rafales, 0.1) + phase
	var rafale := pow((sin(cycle) + 1.0) * 0.5, 3.0)
	var angle := deg_to_rad(variation_direction) * sin(cycle * 0.61)
	var vent := Vector3(0.8, 0, 0.35).normalized().rotated(Vector3.UP, angle)
	# Une mise à jour de l'émetteur suffit à courber toutes ses particules.
	gravity = vent * (force_vent + force_rafales * rafale) + Vector3.UP * 0.025
