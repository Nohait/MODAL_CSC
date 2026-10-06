extends OmniLight3D

@export_range(0.1, 10.0, 0.1) var intervalle_min := 0.8
@export_range(0.1, 15.0, 0.1) var intervalle_max := 2.5
@export_range(0.0, 1.0, 0.05) var intensite_faible := 0.12
@export_range(0.05, 0.5, 0.01) var duree_coupure := 0.16
var energie_normale: float
var attente: float
var coupure := false
var aleatoire := RandomNumberGenerator.new()

func _ready() -> void:
	energie_normale = light_energy
	aleatoire.randomize()
	attente = aleatoire.randf_range(intervalle_min, maxf(intervalle_min, intervalle_max))

func _process(delta: float) -> void:
	attente -= delta
	if attente > 0.0: return
	coupure = not coupure
	# Une brève baisse locale, sans clignotement de l'écran ni création de lumière.
	light_energy = energie_normale * intensite_faible if coupure else energie_normale
	attente = duree_coupure if coupure else aleatoire.randf_range(intervalle_min, maxf(intervalle_min, intervalle_max))
