extends Node3D

@export_group("Sons")
@export var sons_pas: Array[AudioStream] = [preload("res://assets/sounds/design/impact/impactPunch_heavy_000.ogg"), preload("res://assets/sounds/design/impact/impactPunch_heavy_001.ogg")]
@export var son_impact: AudioStream = preload("res://assets/sounds/ennemis/monstre_lave/impact_sol.wav")
@export var son_charge: AudioStream = preload("res://assets/sounds/design/magie/spell_fire_04.ogg")
@export var son_tir: AudioStream = preload("res://assets/sounds/ennemis/monstre_lave/boule_feu.wav")
@export_group("Volumes et portée")
@export_range(-40.0, 6.0, 1.0) var volume_pas := -10.0
@export_range(-40.0, 6.0, 1.0) var volume_impact := -2.0
@export_range(-40.0, 6.0, 1.0) var volume_charge := -9.0
@export_range(-40.0, 6.0, 1.0) var volume_tir := -10.0
@export_range(1.0, 40.0, 1.0) var portee := 24.0
@export_range(1.0, 15.0, 0.5) var distance_reference := 7.0
@export_group("Audibilité des attaques")
@export_range(1.0, 20.0, 0.5) var distance_reference_tirs := 12.0
@export_range(1.0, 60.0, 1.0) var portee_tirs := 36.0
@export_range(-24.0, 0.0, 1.0) var filtre_aigus_impact_db := 0.0
@export_group("Tonalités")
@export_range(0.5, 1.5, 0.05) var tonalite_pas := 0.7
@export_range(0.5, 1.5, 0.05) var tonalite_impact := 1.1
@export_range(0.0, 0.2, 0.01) var variation := 0.05

var pas: AudioStreamPlayer3D
var impact: AudioStreamPlayer3D
var charge: AudioStreamPlayer3D
var tir: AudioStreamPlayer3D
var dernier_pas := -1
var hasard := RandomNumberGenerator.new()
@onready var boss = get_parent()

func _ready() -> void:
	hasard.randomize()
	pas = _creer_lecteur(volume_pas, 2)
	impact = _creer_lecteur(volume_impact, 2)
	charge = _creer_lecteur(volume_charge, 1)
	tir = _creer_lecteur(volume_tir, 4)
	# Les tirs portent davantage, sans modifier les pas ni la charge.
	tir.unit_size = distance_reference_tirs
	tir.max_distance = portee_tirs
	# Le filtre 3D de Godot étouffe les aigus avec la distance ; garder l'impact clair.
	impact.attenuation_filter_db = filtre_aigus_impact_db
	boss.get_node("AnimationsBoss").pas_pose.connect(_jouer_pas)
	boss.impact_sol.connect(_jouer_impact)
	boss.charge_salve.connect(_jouer_charge)
	boss.boule_projetee.connect(_jouer_tir)
	boss.salve_terminee.connect(charge.stop)

func _creer_lecteur(volume: float, voix: int) -> AudioStreamPlayer3D:
	var lecteur := AudioStreamPlayer3D.new()
	lecteur.bus = &"Effets"
	lecteur.volume_db = volume
	lecteur.max_distance = portee
	lecteur.unit_size = distance_reference
	# Plusieurs voix permettent aux tirs rapprochés de terminer leur son.
	lecteur.max_polyphony = voix
	add_child(lecteur)
	return lecteur

func _jouer_pas() -> void:
	if sons_pas.is_empty(): return
	var indice := hasard.randi_range(0, sons_pas.size() - 1)
	if sons_pas.size() > 1 and indice == dernier_pas:
		indice = (indice + 1) % sons_pas.size()
	dernier_pas = indice
	_jouer(pas, sons_pas[indice], tonalite_pas)

func _jouer_impact() -> void:
	# Le choc vient de la réception annoncée, pas de l'ancien emplacement du boss.
	impact.global_position = Vector3(boss.centre_impact.x, boss.zone.global_position.y, boss.centre_impact.z)
	_jouer(impact, son_impact, tonalite_impact)

func _jouer_charge() -> void:
	charge.global_position = boss.orbe.global_position
	_jouer(charge, son_charge)

func _jouer_tir() -> void:
	tir.global_position = boss.orbe.global_position
	_jouer(tir, son_tir)

func _jouer(lecteur: AudioStreamPlayer3D, son: AudioStream, tonalite: float = 1.0) -> void:
	if son == null: return
	if lecteur.stream != son:
		lecteur.stream = son
	lecteur.pitch_scale = tonalite * hasard.randf_range(1.0 - variation, 1.0 + variation)
	lecteur.play()

func _physics_process(_delta: float) -> void:
	if boss.etat == "preparation_salve":
		charge.global_position = boss.orbe.global_position
	if boss.est_mort or boss.est_gele():
		pas.stop()
		charge.stop()
		if boss.est_mort:
			tir.stop()
