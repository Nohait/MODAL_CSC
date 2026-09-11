extends Node3D

@onready var particles: GPUParticles3D = $Muzzle/GPUParticles3D
@onready var damage_area: Area3D = $Muzzle/DamageArea
@onready var muzzle: Node3D = $Muzzle
@onready var direction_marker: Marker3D = $Muzzle/DirectionMarker

@export_group("Charge")
## Réserve maximale de l'extincteur au début du niveau.
@export_range(1.0, 1000.0, 1.0, "or_greater") var max_charge: float = 100.0
## Quantité de charge consommée par seconde de tir.
@export_range(0.0, 100.0, 0.1, "or_greater") var consumption_rate: float = 25.0
## Quantité récupérée par seconde, réglable indépendamment de la consommation.
@export_range(0.1, 100.0, 0.1, "or_greater") var reload_rate: float = 50.0

@export_group("Attaque")
## Demi-angle en degrés : 30 donne une ouverture totale de 60 degrés.
## La portée se règle dans DamageArea/CollisionShape3D ; le jet visuel reste indépendant.
@export_range(0.0, 180.0, 1.0) var cone_angle: float = 15.0
@export_range(0,100,1) var degats1: float = 1.0
@export_range(0,100,1) var attack_cooldown = 0.2
var attack_timer = 0.0

# Attendre que Godot ait chargé les valeurs choisies dans l'Inspecteur.
@onready var charge: float = max_charge #Charge actuelle au démarrage
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
		charge -= consumption_rate * delta
		if charge <= 0.0:
			charge = 0.0
			is_overheated = true
			is_attacking = false
			particles.emitting = false
	else:
		charge += reload_rate * delta
		if charge >= max_charge:
			charge = max_charge
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
			var minimum_alignment: float = cos(deg_to_rad(cone_angle)) #calcul du cos minimal souhaité

			if alignment >= minimum_alignment:
				#si l'ennemi est dans le cône, on attaque
				
				if Input.is_action_pressed("primary_attack"):
					attaque_1(body)

func attaque_1(cible):
	if cible != null:
		var multiplier = randf_range(0.9,1.1)
		cible.prendre_degats(round(multiplier * degats1 *100.0)/100.0)
	
