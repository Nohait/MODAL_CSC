class_name CoucheMusicaleZombie
extends Resource

@export var titre := "Percussions"
@export var piste: AudioStream
@export_range(-40.0, 0.0, 1.0) var volume_db := -22.0
@export_range(0, 100) var ennemis_minimum := 0
@export_range(1, 100) var vague_minimum := 1
@export var exige_elite := false
@export var exige_boss := false
@export var evenements: Array[StringName] = []

# Une élite ou un boss peut activer la couche avant les seuils habituels.
@export var activer_si_elite := false
@export var activer_si_boss := false
