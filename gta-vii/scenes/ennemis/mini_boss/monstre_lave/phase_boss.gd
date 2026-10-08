extends Node3D

signal colere_commencee

@export_range(0.1, 0.9, 0.05) var seuil_vie := 0.5
@export_range(0.5, 3.0, 0.1) var duree_colere := 2.2
@export_range(0.5, 1.0, 0.05) var multiplicateur_delais := 0.85
@export_range(0.0, 5.0, 0.1) var energie_lueur := 2.0
@export var grondement: AudioStream = preload("res://assets/sounds/ennemis/monstre_lave/cri_colere.wav")
@export_range(-30.0, 6.0, 1.0) var volume_grondement := 3.0
@export_range(1.0, 30.0, 0.5) var distance_reference_cri := 16.0
# Zéro désactive la coupure de distance : le cri porte dans toute la salle.
@export_range(0.0, 200.0, 1.0) var portee_cri := 0.0
@export var cri_audible_dans_toute_la_salle := true
@export_range(0.0, 0.5, 0.01) var force_secousse := 0.12

var active := false
var lueur: OmniLight3D
@onready var boss = get_parent()

func commencer() -> bool:
	if active or boss.vie <= 0.0 or boss.vie > boss.vie_max * seuil_vie: return false
	# Le combat appelle cette méthode seulement entre deux attaques : aucun saut interrompu.
	active = true
	boss.invocations.passer_en_phase_deux()
	boss.invocations.commencer(true, duree_colere)
	lueur = OmniLight3D.new()
	lueur.position.y = 1.5
	lueur.light_color = Color(1.0, 0.25, 0.035)
	lueur.light_energy = 0.0
	lueur.omni_range = 6.0
	lueur.shadow_enabled = false
	add_child(lueur)
	var son := AudioStreamPlayer3D.new()
	son.stream = grondement
	son.bus = &"Effets"
	son.volume_db = volume_grondement
	# Ce rugissement est déjà grave : conserver sa tonalité et sa durée originales.
	son.pitch_scale = 1.0
	son.unit_size = distance_reference_cri
	son.max_distance = portee_cri
	# Le cri garde sa direction 3D, mais pas une baisse de volume avec la distance.
	son.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED if cri_audible_dans_toute_la_salle else AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	# Garder le cri clair même lorsque le boss est éloigné du joueur.
	son.attenuation_filter_db = 0.0
	add_child(son)
	son.finished.connect(son.queue_free)
	if grondement: son.play()
	colere_commencee.emit()
	if is_instance_valid(boss.player) and boss.player.has_method("secouer_camera"):
		boss.player.secouer_camera(force_secousse, 0.2)
	return true

func avancer_colere() -> void:
	# La progression dépend du temps du combat, donc respecte aussi le gel.
	var progression := 1.0 - clampf(boss.temps_etat / duree_colere, 0.0, 1.0)
	lueur.light_energy = energie_lueur * progression

func delai(base: float) -> float:
	return base * multiplicateur_delais if active else base
