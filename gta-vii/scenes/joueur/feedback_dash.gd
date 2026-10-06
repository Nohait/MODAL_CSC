extends Node3D

@export var actif := true
@export var couleur := Color("a7e8ef")
@export_range(0.05, 0.8, 0.01) var duree_trace := 0.22
@export_range(0.05, 0.8, 0.01) var largeur_trace := 0.3
@export_range(0.1, 1.5, 0.05) var hauteur_trace := 0.65
@export_range(1, 40) var nombre_particules := 10
@export_range(0.05, 0.6, 0.01) var duree_particules := 0.25
@export_range(0.0, 0.1, 0.005) var impulsion_camera := 0.025
@export_range(0.05, 0.6, 0.01) var retour_camera := 0.2
@export_range(-40.0, 0.0, 1.0) var volume_db := -23.0
@export var son: AudioStream = preload("res://assets/sounds/design/mouvements/swish-3.wav")

@onready var joueur: CharacterBody3D = get_parent()
var lecteur: AudioStreamPlayer
var trainee: GPUParticles3D
var temps_trace := 0.0
var camera: Camera3D
var taille_camera := 0.0
var recul := 0.0

func _ready() -> void:
	joueur.dash_commence.connect(_commencer)
	lecteur = AudioStreamPlayer.new()
	lecteur.bus = "Effets"
	add_child(lecteur)
	# Le ruban GPU mémorise le trajet : aucun mesh créé à chaque image.
	trainee = preload("res://addons/GPUTrail/GPUTrail3D.gd").new()
	add_child(trainee)
	trainee.fixed_fps = 60
	trainee.length_seconds = duree_trace
	trainee.position.y = hauteur_trace
	trainee.scale = Vector3.ONE * largeur_trace * 0.5
	trainee.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trainee.visibility_aabb = AABB(Vector3(-10, -3, -10), Vector3(20, 6, 20))
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(couleur, 0.0), Color(couleur, 0.7)])
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	trainee.color_ramp = texture
	trainee.hide()
	trainee.emitting = false

func _commencer(_direction: Vector3) -> void:
	if not actif: return
	temps_trace = duree_trace
	trainee.show()
	trainee.emitting = true
	trainee.restart()
	lecteur.stream = son
	lecteur.volume_db = volume_db
	lecteur.pitch_scale = randf_range(0.97, 1.03)
	if son != null: lecteur.play()
	# La caméra est orthographique : sa taille joue le rôle d'un léger dézoom.
	if is_instance_valid(joueur.camera):
		camera = joueur.camera
		if recul <= 0.0: taille_camera = camera.size
		recul = retour_camera
	_gerbe()

func _process(delta: float) -> void:
	if is_instance_valid(camera) and recul > 0.0:
		recul = maxf(0.0, recul - delta)
		camera.size = taille_camera * (1.0 + impulsion_camera * recul / retour_camera)
	if joueur.is_dashing and actif:
		temps_trace = duree_trace
	else:
		# Laisser la queue du ruban se résorber avant de désactiver les particules.
		temps_trace = maxf(0.0, temps_trace - delta)
		if temps_trace == 0.0:
			trainee.hide()
			trainee.emitting = false

func _gerbe() -> void:
	var particules := CPUParticles3D.new()
	particules.amount = nombre_particules
	particules.one_shot = true
	particules.explosiveness = 1.0
	particules.lifetime = duree_particules
	particules.direction = -joueur.last_direction
	particules.spread = 35.0
	particules.gravity = Vector3(0, -2, 0)
	particules.initial_velocity_min = 1.0
	particules.initial_velocity_max = 2.0
	var forme := SphereMesh.new()
	forme.radius = 0.035
	forme.height = 0.07
	forme.radial_segments = 6
	forme.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = couleur
	forme.material = mat
	particules.mesh = forme
	particules.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particules)
	particules.top_level = true
	particules.global_position = joueur.global_position + Vector3.UP * 0.15
	particules.finished.connect(particules.queue_free)
	particules.restart()

func _exit_tree() -> void:
	if is_instance_valid(camera) and taille_camera > 0.0:
		camera.size = taille_camera
