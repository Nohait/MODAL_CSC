extends "res://scenes/modes/tutoriel/commun/figurants/figurant_pompier.gd"

signal prise_en_charge_terminee

var habitant: CharacterBody3D
var animation: AnimationTree
var en_cours := false
var terminee := false

func preparer(joueur: Node3D, arrivee: Node3D) -> void:
	global_position = arrivee.global_position + Vector3(1.2, 1, -0.5)
	installer_modele(joueur)

func prendre_en_charge(victime: CharacterBody3D, escorte: Node) -> void:
	if en_cours or terminee: return
	habitant = victime
	# Une relève visible, sans queue_free ni compteur d'évacuation classique.
	escorte.freed_victims.erase(habitant)
	escorte.reorganiser_file()
	escorte.actualiser_bonus()
	escorte.escort_changed.emit()
	habitant.reparent(get_parent().salle, true)
	habitant.follow_target = null
	habitant.velocity = Vector3.ZERO
	habitant.set_physics_process(false)
	habitant.collision_layer = 0
	habitant.collision_mask = 0
	animation = ANIMATIONS.installer(habitant.get_node("victime"), false)
	en_cours = true

func _process(delta: float) -> void:
	super._process(delta)
	if not en_cours or not is_instance_valid(habitant): return
	var cible := global_position + Vector3(-0.8, -0.25, 0)
	var ancienne := habitant.global_position
	habitant.global_position = ancienne.move_toward(cible, 1.0 * delta)
	var mouvement := habitant.global_position - ancienne
	ANIMATIONS.orienter(habitant, mouvement, delta, true, true)
	ANIMATIONS.actualiser(animation, mouvement.length() / maxf(delta, 0.001), delta)
	if habitant.global_position.distance_to(cible) < 0.01:
		ANIMATIONS.actualiser(animation, 0, delta)
		if float(animation["parameters/Transition/blend_amount"]) <= 0.001:
			en_cours = false
			terminee = true
			prise_en_charge_terminee.emit()
