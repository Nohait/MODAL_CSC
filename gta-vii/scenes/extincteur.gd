extends Node3D

@onready var particles: GPUParticles3D = $Muzzle/GPUParticles3D

const MAX_CHARGE = 100.0 #Gère la charge maximale de l'extincteur
const CONSUMPTION_RATE = 25 #Gère la consommation de l'extincteur
const RECHARGE_RATE = CONSUMPTION_RATE * 2 #taux de rechare

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
