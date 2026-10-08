extends Node3D

@export var son_grondement: AudioStream = preload("res://assets/sounds/ennemis/monstre_lave/grondement_faille.wav")
@export var son_projection: AudioStream = preload("res://assets/sounds/ennemis/monstre_lave/projection_lave.wav")
@export_range(-40.0, 6.0, 1.0) var volume_grondement := -7.0
@export_range(-40.0, 6.0, 1.0) var volume_projection := -8.0
@export_range(0.1, 1.0, 0.05) var fondu := 0.35
@export_range(0.1, 1.0, 0.05) var intervalle_projections := 0.3
@export_range(1.0, 30.0, 0.5) var distance_reference := 12.0
@export_range(5.0, 80.0, 1.0) var portee := 40.0

var grondement: AudioStreamPlayer3D
var projections: Array[AudioStreamPlayer3D] = []
var termine := true
var attente := 0.0
@onready var fissure = get_parent()
@onready var boss = fissure.get_parent()

func _ready() -> void:
	grondement = _lecteur(son_grondement)
	for i in 2: projections.append(_lecteur(son_projection))
	fissure.preparation_commencee.connect(_commencer)
	fissure.portion_ouverte.connect(_projeter)
	fissure.fissure_terminee.connect(func(): termine = true)

func _lecteur(son: AudioStream) -> AudioStreamPlayer3D:
	var lecteur := AudioStreamPlayer3D.new()
	lecteur.stream = son
	lecteur.bus = &"Effets"
	lecteur.unit_size = distance_reference
	lecteur.max_distance = portee
	lecteur.attenuation_filter_db = 0.0
	add_child(lecteur)
	lecteur.top_level = true
	return lecteur

func _commencer(point: Vector3) -> void:
	termine = false
	attente = 0.0
	grondement.global_position = point
	grondement.volume_db = -60.0
	grondement.play()

func _projeter(point: Vector3) -> void:
	if attente > 0.0: return
	# Deux voix au maximum : chaque son peut finir sans accumuler les projections.
	for lecteur in projections:
		if lecteur.playing: continue
		lecteur.global_position = point
		lecteur.volume_db = volume_projection
		lecteur.play()
		attente = intervalle_projections
		break

func _physics_process(delta: float) -> void:
	var suspendu: bool = boss.est_gele() or boss.subit_recul()
	grondement.stream_paused = suspendu
	for lecteur in projections: lecteur.stream_paused = suspendu
	if boss.est_mort:
		termine = true
		for lecteur in projections: lecteur.stop()
	if suspendu: return
	attente = maxf(0.0, attente - delta)
	# La fin de la faille baisse progressivement le grondement au lieu de le couper.
	grondement.volume_db = move_toward(grondement.volume_db, -60.0 if termine else volume_grondement, 60.0 * delta / fondu)
	if termine and grondement.volume_db <= -60.0: grondement.stop()
