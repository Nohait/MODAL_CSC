extends Node3D

var direction := Vector3.ZERO
var vitesse := 18.0
var degats := 15.0
var tireur: CollisionObject3D
var duree_restante := 5.0
@export_group("Traînée de feu")
@export_range(0.1, 2.0, 0.05) var duree_trainee := 0.65
@export_range(0.02, 0.5, 0.01) var largeur_trainee := 0.18
@export var effet_impact: PackedScene = preload("res://scenes/effets/combat/impact_boule_feu.tscn")
var trainee: MeshInstance3D

func _ready() -> void:
	trainee = preload("res://scenes/effets/feu/trainee_projectile.gd").new()
	trainee.duree = duree_trainee
	trainee.largeur = largeur_trainee * global_basis.get_scale().x
	get_parent().add_child(trainee)
	trainee.ajouter_point(global_position)
	if direction.length_squared() > 0.001:
		# -Z est l'avant de la boule ; la queue est placée derrière, vers +Z.
		var haut := Vector3.UP if absf(direction.normalized().dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		look_at(global_position + direction, haut)

func _physics_process(delta: float) -> void:
	duree_restante -= delta
	if duree_restante <= 0.0:
		queue_free()
		return
	var destination := global_position + direction * vitesse * delta
	# Balayer tout le trajet de cette frame évite de traverser un mur ou une cible.
	var requete := PhysicsRayQueryParameters3D.create(global_position, destination, 11)
	if is_instance_valid(tireur): requete.exclude = [tireur.get_rid()]
	var impact := get_world_3d().direct_space_state.intersect_ray(requete)
	if not impact.is_empty():
		trainee.ajouter_point(impact.position)
		var corps = impact.collider
		if (corps.is_in_group("player") or corps.is_in_group("victime")) and corps.has_method("prendre_degats"):
			corps.prendre_degats(degats)
		if effet_impact:
			var effet = effet_impact.instantiate()
			get_parent().add_child(effet)
			effet.lancer(impact.position, impact.normal)
		# Une seule collision : aucune flaque et aucun dégât répété.
		queue_free()
		return
	global_position = destination
	trainee.ajouter_point(global_position)

func _exit_tree() -> void:
	if is_instance_valid(trainee):
		trainee.terminer()
