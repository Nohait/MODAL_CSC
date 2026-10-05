extends Node3D

signal etat_change
const VAPEUR = preload("res://scenes/effets/combat/impact_mousse.tscn")
@export_range(1, 100, 1) var prix_activation := 15
@export_range(1.0, 8.0, 0.5) var rayon := 4.0
@export_range(0.5, 10.0, 0.5) var duree := 3.0
@export_range(1.0, 100.0, 1.0) var degats_par_seconde := 20.0
var arme := false
var temps_restant := 0.0
var temps_degats := 0.0
@onready var zone: Area3D = $Zone
@onready var eau: CPUParticles3D = $Eau

func _ready() -> void:
	add_to_group("sprinkler")
	$Zone/Collision.shape = $Zone/Collision.shape.duplicate()
	$Zone/Collision.shape.radius = rayon
	$Zone/Anneau.mesh = $Zone/Anneau.mesh.duplicate()
	$Zone/Anneau.mesh.inner_radius = rayon - 0.04
	$Zone/Anneau.mesh.outer_radius = rayon
	_actualiser()

func armer() -> void:
	arme = true
	_actualiser()
	etat_change.emit()

func _physics_process(delta: float) -> void:
	if arme:
		for ennemi in zone.get_overlapping_bodies():
			if _peut_toucher(ennemi):
				# Un achat donne un seul déclenchement, même si plusieurs ennemis arrivent.
				arme = false
				temps_restant = duree
				temps_degats = 0.0
				eau.restart()
				eau.emitting = true
				_actualiser()
				etat_change.emit()
				break
	if temps_restant <= 0.0: return
	var pas := minf(delta, temps_restant)
	temps_restant -= pas
	temps_degats += pas
	# Réunir les dégâts par quarts de seconde limite aussi le nombre de bouffées de vapeur.
	if temps_degats >= 0.25 or temps_restant <= 0.0:
		for ennemi in zone.get_overlapping_bodies():
			if not _peut_toucher(ennemi): continue
			var position_vapeur: Vector3 = ennemi.global_position + Vector3.UP
			ennemi.prendre_degats(degats_par_seconde * temps_degats)
			var vapeur = VAPEUR.instantiate()
			get_parent().add_child(vapeur)
			vapeur.global_position = position_vapeur
			vapeur.lancer(Vector3.UP)
		temps_degats = 0.0
	if temps_restant <= 0.0:
		eau.emitting = false
		_actualiser()
		etat_change.emit()

func _peut_toucher(corps: Node3D) -> bool:
	if not is_instance_valid(corps) or corps.is_queued_for_deletion(): return false
	if not corps.is_in_group("enemies") or not corps.has_method("prendre_degats"): return false
	# Les murs protègent un ennemi situé dans la pièce voisine.
	var rayon_vue := PhysicsRayQueryParameters3D.create(
		zone.global_position, corps.global_position + Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(rayon_vue).is_empty()

func _actualiser() -> void:
	$Zone/Anneau.visible = arme or temps_restant > 0.0
	$Etat.text = "Sprinkler actif" if temps_restant > 0.0 else ("Sprinkler armé" if arme else "Sprinkler · Activation en boutique")
