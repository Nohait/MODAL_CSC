extends Node3D

var direction := Vector3.ZERO
var vitesse := 18.0
var degats := 15.0
var tireur: CollisionObject3D
var duree_restante := 5.0
var distance_parcourue := 0.0

func _ready() -> void:
	$Trainee.scale.y = 0.001
	$Trainee.position.z = 0.0
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
		var corps = impact.collider
		if (corps.is_in_group("player") or corps.is_in_group("victime")) and corps.has_method("prendre_degats"):
			corps.prendre_degats(degats)
		if corps.is_in_group("collider"):
			preload("res://scenes/effets/combat/trace_combat.gd").creer(get_parent(), impact.position, impact.normal, Color(0.045, 0.025, 0.015, 0.7), 1.0, 8.0)
		# Une seule collision : aucune flaque et aucun dégât répété.
		queue_free()
		return
	distance_parcourue += global_position.distance_to(destination)
	global_position = destination
	# Ne pas faire apparaître toute la queue d'un coup au départ du sceptre.
	var longueur := minf(2.4, distance_parcourue)
	$Trainee.scale.y = longueur / 2.4
	$Trainee.position.z = longueur / 2.0
