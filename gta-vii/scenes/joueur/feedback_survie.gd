extends Node

@export_group("Sons des impacts")
@export var sons_vie: Array[AudioStream] = [
	preload("res://assets/sounds/joueur/douleur/douleur_01.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_02.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_03.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_04.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_05.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_06.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_07.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_08.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_09.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_10.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_11.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_12.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_13.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_14.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_15.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_16.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_17.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_18.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_19.wav"),
	preload("res://assets/sounds/joueur/douleur/douleur_20.wav")
]
@export var son_bouclier: AudioStream = preload("res://assets/sounds/design/impact/impactPlate_light_002.ogg")
@export_range(-40.0, 0.0, 1.0) var volume_vie := -16.0
@export_range(-40.0, 0.0, 1.0) var volume_bouclier := -19.0
@export_range(0.0, 1.0, 0.01) var intervalle_impacts := 0.12
@export_group("Faible vie")
@export var alerte_active := true
@export_range(1.0, 50.0, 1.0) var seuil_vie := 25.0
@export_range(0.0, 0.4, 0.01) var intensite_alerte := 0.12
@export_range(0.3, 3.0, 0.1) var cycle_alerte := 1.2
@export_group("Mort")
@export_range(0.1, 1.0, 0.05) var duree_reaction := 0.25
@export_range(0.1, 1.0, 0.05) var duree_fondu := 0.35
@export_range(0.0, 45.0, 1.0) var inclinaison_mort := 18.0

@onready var joueur = get_parent()
var lecteur_vie: AudioStreamPlayer
var lecteur_bouclier: AudioStreamPlayer
var alerte: ColorRect
var noir: ColorRect
var temps := 0.0
var attente_vie := 0.0
var derniere_reaction := -1
var attente_bouclier := 0.0

func _ready() -> void:
	# La transition reste active quand main met le combat en pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	lecteur_vie = AudioStreamPlayer.new()
	lecteur_bouclier = AudioStreamPlayer.new()
	for lecteur in [lecteur_vie, lecteur_bouclier]:
		lecteur.bus = "Effets"
		add_child(lecteur)
	joueur.degats_recus.connect(_impact_vie)
	var couche := CanvasLayer.new()
	couche.layer = 12
	add_child(couche)
	alerte = _creer_rect(couche)
	var materiau := ShaderMaterial.new()
	materiau.shader = preload("res://scenes/interfaces/hud/contour_degats.gdshader")
	alerte.material = materiau
	alerte.color = Color(0.7, 0.04, 0.015, 0.0)
	var transition := CanvasLayer.new()
	transition.layer = 100
	add_child(transition)
	noir = _creer_rect(transition)
	noir.color = Color(0, 0, 0, 0)

func _creer_rect(couche: CanvasLayer) -> ColorRect:
	var rectangle := ColorRect.new()
	couche.add_child(rectangle)
	rectangle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rectangle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rectangle

func _process(delta: float) -> void:
	attente_vie = maxf(0.0, attente_vie - delta)
	attente_bouclier = maxf(0.0, attente_bouclier - delta)
	if get_tree().paused: return
	temps += delta
	var faible: bool = joueur.BarreDeVie.value <= joueur.BarreDeVie.max_value * seuil_vie / 100.0
	alerte.visible = alerte_active and faible and not joueur.est_mort
	if alerte.visible:
		# Une respiration douce sur les bords, indépendante de Dernier souffle.
		alerte.color.a = intensite_alerte * (0.65 + 0.35 * sin(temps * TAU / cycle_alerte))

func _impact_vie(_quantite: float) -> void:
	# Les dégâts continus ne doivent pas couper une réaction déjà en cours.
	if attente_vie > 0.0 or lecteur_vie.playing or sons_vie.is_empty(): return
	var indice := randi_range(0, sons_vie.size() - 1)
	# Décaler le tirage évite une répétition immédiate, sans boucle de recherche.
	if sons_vie.size() > 1 and indice == derniere_reaction:
		indice = (indice + randi_range(1, sons_vie.size() - 1)) % sons_vie.size()
	derniere_reaction = indice
	attente_vie = intervalle_impacts
	_jouer(lecteur_vie, sons_vie[indice], volume_vie)

func impact_bouclier() -> void:
	if attente_bouclier > 0.0: return
	attente_bouclier = intervalle_impacts
	_jouer(lecteur_bouclier, son_bouclier, volume_bouclier)

func _jouer(lecteur: AudioStreamPlayer, son: AudioStream, volume: float) -> void:
	if son == null: return
	lecteur.stream = son
	lecteur.volume_db = volume
	lecteur.pitch_scale = randf_range(0.97, 1.03)
	lecteur.play()

func jouer_mort() -> void:
	alerte.hide()
	# Suspendre les effets déjà lancés pour garder la pose finale stable.
	if joueur.flash_tween: joueur.flash_tween.kill()
	joueur.damage_flash.hide()
	joueur.anim_tree.active = false
	var dash = joueur.get_node_or_null("FeedbackDash")
	if dash != null:
		dash.set_process(false)
		if is_instance_valid(dash.camera): dash.camera.size = dash.taille_camera
		if dash.trainee != null: dash.trainee.hide()
	var animation := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Seul le visuel s'affaisse : le corps et la caméra restent en place.
	animation.tween_property(joueur.visual, "rotation:z", deg_to_rad(inclinaison_mort), duree_reaction).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(noir, "color:a", 1.0, duree_fondu)
	await animation.finished
