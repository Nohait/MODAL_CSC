extends Node3D

signal etat_change
@export_range(0, 100, 1) var prix_activation := 5
@export_range(5.0, 120.0, 1.0) var duree := 30.0
@export_range(1.0, 40.0, 0.5) var rayon := 18.0
@export_range(0.0, 1.0, 0.05) var proportion_fumee := 0.2
@export var racine_fumee := NodePath("../../..")
var arme := false
var temps_restant := 0.0
var fumee_initiale: Dictionary = {}
var attente_scan := 0.0

func _ready() -> void:
	add_to_group("ventilation_zombie")
	_connecter_vagues.call_deferred()

func _connecter_vagues() -> void:
	var scene := get_tree().current_scene
	if scene == null: return
	var vagues := scene.get_node_or_null("main/Salles/RoomManager")
	if vagues != null: vagues.salle_commencee.connect(_debut_vague)

func armer() -> void:
	if arme or temps_restant > 0.0: return
	arme = true
	etat_change.emit()

func _debut_vague(_salle: Node3D) -> void:
	if not arme: return
	arme = false
	temps_restant = duree
	_reduire_fumee()
	etat_change.emit()

func _process(delta: float) -> void:
	if temps_restant <= 0.0: return
	temps_restant = maxf(0.0, temps_restant - delta)
	attente_scan -= delta
	# Un foyer peut apparaître en cours de vague ; un scan par seconde suffit.
	if attente_scan <= 0.0:
		attente_scan = 1.0
		_reduire_fumee()
	if temps_restant == 0.0:
		_restaurer_fumee()
		etat_change.emit()

func _reduire_fumee() -> void:
	var decor := get_node_or_null(racine_fumee)
	if decor == null: return
	for particules in decor.find_children("Fumee", "CPUParticles3D", true, false):
		if global_position.distance_to(particules.global_position) > rayon: continue
		if not fumee_initiale.has(particules): fumee_initiale[particules] = particules.amount
		particules.amount = maxi(1, roundi(fumee_initiale[particules] * proportion_fumee))
		particules.emitting = proportion_fumee > 0.0

func _restaurer_fumee() -> void:
	for particules in fumee_initiale:
		if not is_instance_valid(particules): continue
		particules.amount = fumee_initiale[particules]
		particules.emitting = true
	fumee_initiale.clear()

func capturer_sauvegarde() -> Dictionary:
	return {"arme": arme, "temps_restant": temps_restant}

func restaurer_sauvegarde(etat: Dictionary) -> void:
	_restaurer_fumee()
	arme = bool(etat.get("arme", false))
	temps_restant = maxf(0.0, float(etat.get("temps_restant", 0.0)))
	if temps_restant > 0.0: _reduire_fumee()
	etat_change.emit()
