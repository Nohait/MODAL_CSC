extends Node

var effets: Node
var restant := 0.0
var leurre: CharacterBody3D
var salle: Node3D

func _ready() -> void:
	effets.joueur.dash_commence.connect(_dash)

func _physics_process(delta: float) -> void:
	restant = maxf(0.0, restant - delta)
	if not is_instance_valid(leurre): return
	if effets.joueur.est_mort or effets.gestion.room_manager.transition_en_cours or salle != effets.gestion.room_manager.salle_actuelle:
		leurre.annuler()
		return
	var arme = effets.gestion.extincteur
	if effets.valeur("prise_piege") > 0.0 and not leurre.charge and not arme.portions_jet.is_empty():
		if arme.cible_dans_jet(leurre.global_position, leurre.hitbox_radius) and effets.visible_depuis(arme.muzzle.global_position, leurre):
			leurre.charger()

func _dash(_direction: Vector3) -> void:
	if effets.valeur("par_ici") <= 0.0 or restant > 0.0: return
	if is_instance_valid(leurre) and not leurre.is_queued_for_deletion(): return
	salle = effets.gestion.room_manager.salle_actuelle
	if not is_instance_valid(salle) or effets.gestion.room_manager.transition_en_cours: return
	var carte: Amelioration = effets.gestion.catalogue_ameliorations.trouver(&"par_ici")
	var origine: Vector3 = effets.joueur.global_position
	var rayon := PhysicsRayQueryParameters3D.create(origine + Vector3.UP, origine + Vector3.DOWN * 3.0, 1)
	var contact: Dictionary = effets.joueur.get_world_3d().direct_space_state.intersect_ray(rayon)
	if contact.is_empty(): return
	leurre = preload("res://scenes/systemes/ameliorations/classique/leurre_mousse.gd").new()
	leurre.effets = effets
	leurre.duree = minf(2.0, carte.duree_effet)
	leurre.rayon_attraction = carte.rayon
	leurre.position = salle.to_local(contact.position)
	salle.add_child(leurre)
	restant = carte.intervalle
