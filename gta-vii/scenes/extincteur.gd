extends Node3D

@onready var particles: GPUParticles3D = $Muzzle/GPUParticles3D
@onready var damage_area: Area3D = $Muzzle/DamageArea
@onready var muzzle: Node3D = $Muzzle
@onready var direction_marker: Marker3D = $Muzzle/DirectionMarker

const MAX_CHARGE = 100.0 #Gère la charge maximale de l'extincteur
const CONSUMPTION_RATE = 25.0 #Gère la consommation de l'extincteur
const RECHARGE_RATE = CONSUMPTION_RATE * 2.0 #taux de rechare
const RANGE = 4.0
const CONE_ANGLE = 30.0 #Demi-angle du cône d'attaque, en degrés

var charge := MAX_CHARGE #Charge actuelle
var is_attacking := false 
var is_overheated := false #Entre en cooldown forcé si l'extincteur tombe à 0


func start_primary_attack() -> void:
	if not is_overheated:
		is_attacking = true
		particles.emitting = true


func stop_primary_attack() -> void:
	#arrête l'attaque principale
	is_attacking = false
	particles.emitting = false

func _physics_process(delta: float) -> void:
	if is_attacking:
		charge -= CONSUMPTION_RATE * delta
		if charge <= 0.0:
			charge = 0.0
			is_overheated = true
			is_attacking = false
			particles.emitting = false
			print("SURCHAUFFE")
	else:
		charge += RECHARGE_RATE * delta
		if charge >= MAX_CHARGE:
			charge = MAX_CHARGE
			is_overheated = false
	
	var bodies := damage_area.get_overlapping_bodies()

	for body in bodies:
		if body.is_in_group("enemies"):
			var target_body := body as PhysicsBody3D
			var origin: Vector3 = muzzle.global_position 
			var to_target: Vector3 = target_body.global_position - origin
			var target_direction: Vector3 = to_target.normalized() #direction à l'ennemi

			var forward: Vector3 = (direction_marker.global_position - muzzle.global_position).normalized() #direction de visée du joueur

			var alignment: float = forward.dot(target_direction) #produit scalaire entre les deux directions
			var minimum_alignment: float = cos(deg_to_rad(CONE_ANGLE)) #calcul du cos minimal souhaité

			if alignment >= minimum_alignment:
				#si l'ennemi est dans le cône, on attaque
				print("Ennemi dans le cône :", target_body)
