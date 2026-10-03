extends Node3D

var attente: Array[Dictionary] = []
var escorte: Array[CharacterBody3D] = []
var active := false
const ESPACEMENT := 2.1 # Respecter les deux mètres de distance habituels entre les victimes.
const POINT_EMERGENCE := 3.8

func preparer(victimes: Array[CharacterBody3D]) -> void:
	arreter()
	escorte = victimes.duplicate()
	for i in range(escorte.size()):
		var victime := escorte[i]
		if not is_instance_valid(victime) or victime.is_queued_for_deletion():
			continue
		var distance := 1.6 + (i + 1) * ESPACEMENT
		victime.global_position = to_global(Vector3(0, 0.75, minf(distance, POINT_EMERGENCE)))
		victime.velocity = Vector3.ZERO
		victime.player_nearby = false
		victime.navigation_agent.target_position = victime.global_position
		if distance > POINT_EMERGENCE:
			# L’excédent attend sans collision et sans dégâts ; ses PV sont conservés.
			attente.append({"victime": victime, "couche": victime.collision_layer, "masque": victime.collision_mask})
			victime.collision_layer = 0
			victime.collision_mask = 0
			victime.set_physics_process(false)
			victime.hide()

func commencer() -> void:
	active = true

func _physics_process(_delta: float) -> void:
	if not active:
		return
	if not attente.is_empty():
		var suivante: CharacterBody3D = attente[0].victime
		if not is_instance_valid(suivante) or suivante.is_queued_for_deletion():
			attente.pop_front()
		else:
			var cible: Node3D = suivante.follow_target
			# Faire sortir une victime seulement quand la précédente a laissé assez de place.
			if is_instance_valid(cible) and to_local(cible.global_position).z < POINT_EMERGENCE - ESPACEMENT:
				_reveler(attente.pop_front())
	for victime in escorte:
		if not is_instance_valid(victime) or victime.is_queued_for_deletion():
			continue
		# Le corps et sa barre de vie émergent ensemble de l’obscurité du couloir.
		var disparition := smoothstep(2.8, 4.0, to_local(victime.global_position).z)
		victime.visuel.transparency = disparition
		victime.health_bar_sprite.transparency = disparition

func _reveler(donnees: Dictionary) -> void:
	var victime: CharacterBody3D = donnees.victime
	if not is_instance_valid(victime):
		return
	victime.collision_layer = donnees.couche
	victime.collision_mask = donnees.masque
	victime.set_physics_process(true)
	victime.show()

func arreter() -> void:
	active = false
	for donnees in attente:
		_reveler(donnees)
	attente.clear()
	for victime in escorte:
		if is_instance_valid(victime):
			victime.visuel.transparency = 0.0
			victime.health_bar_sprite.transparency = 0.0
	escorte.clear()
