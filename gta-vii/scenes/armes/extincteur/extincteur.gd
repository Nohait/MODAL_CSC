extends Node3D

@onready var particles: GPUParticles3D = $AttaquePrincipale/GPUParticles3D
@onready var damage_area: Area3D = $AttaquePrincipale/DamageArea
@onready var muzzle: Node3D = $AttaquePrincipale
@onready var direction_marker: Marker3D = $AttaquePrincipale/DirectionMarker
@onready var indicateur_attaque = $IndicateurAttaque
@export_group("Jet")
## Distance maximale, en mètres depuis le départ du jet.
# L'ancienne sphère de 2.8 était agrandie par l'échelle 1.5 de l'arme du joueur.
@export_range(0.1, 30.0, 0.1) var portee_jet := 4.2
## Angle de chaque côté de la visée : 15 donne une ouverture totale de 30°.
@export_range(1.0, 85.0, 1.0) var demi_angle_jet := 15.0
## Vitesse commune aux particules et aux limites de la zone de dégâts.
@export_range(0.1, 30.0, 0.1) var vitesse_jet := 5.6
@export_range(0.0, 1.0, 0.01) var opacite_particules := 0.8

# Chaque appui crée une portion : X = distance du début, Y = distance de fin.
# Plusieurs portions permettent de conserver les espaces entre des tirs brefs.
var portions_jet: Array[Vector2] = []

@export_group("Charge")
## Réserve maximale de l'extincteur au début du niveau.
@export_range(1.0, 1000.0, 1.0, "or_greater") var max_charge: float = 100.0
## Quantité de charge consommée par seconde de tir.
@export_range(0.0, 100.0, 0.1, "or_greater") var consumption_rate: float = 25.0
## Quantité récupérée par seconde, réglable indépendamment de la consommation.
@export_range(0.1, 100.0, 0.1, "or_greater") var reload_rate: float = 50.0

@export_group("Attaque")
## Dégâts de base par impact, avant le bonus d'escorte et la variation aléatoire.
@export_range(0,100,1) var degats1: float = 1.0
# Le VictimManager recalcule ce booléen quand l'escorte change.
var bonus_degats_actif := false
# Indépendant de l'escorte : reste actif quand une victime est évacuée.
var multiplicateur_degats_ameliorations := 1.0
const AUGMENTATION_DEGATS_ESCORTE: float = 0.25
@export_range(0,100,1) var attack_cooldown = 0.2
var attack_timer = 0.0

# Attendre que Godot ait chargé les valeurs choisies dans l'Inspecteur.
@onready var charge: float = max_charge #Charge actuelle au démarrage
var is_attacking := false 
var is_overheated := false #Entre en cooldown forcé si l'extincteur tombe à 0

func _ready() -> void:
	# Des ressources propres à cette arme évitent de modifier les autres instances.
	particles.process_material = particles.process_material.duplicate()
	particles.draw_pass_1 = particles.draw_pass_1.duplicate()
	particles.draw_pass_1.material = particles.draw_pass_1.material.duplicate()
	# Travailler en mètres, sans subir l'échelle 0.11 du parent AttaquePrincipale.
	particles.top_level = true
	damage_area.top_level = true
	damage_area.get_node("CollisionShape3D").shape = damage_area.get_node("CollisionShape3D").shape.duplicate()
	configurer_jet()
	actualiser_position_jet()


func configurer_jet() -> void:
	var simulation := particles.process_material as ParticleProcessMaterial
	# Spread représente déjà un DEMI-angle dans Godot : ne pas le multiplier par 2.
	simulation.spread = demi_angle_jet
	simulation.initial_velocity_min = vitesse_jet
	simulation.initial_velocity_max = vitesse_jet
	particles.lifetime = portee_jet / vitesse_jet
	particles.draw_pass_1.material.albedo_color.a = opacite_particules
	particles.visibility_aabb = AABB(Vector3.ONE * -portee_jet, Vector3.ONE * portee_jet * 2.0)
	damage_area.get_node("CollisionShape3D").shape.radius = portee_jet


func direction_jet() -> Vector3:
	var direction := direction_marker.global_position - muzzle.global_position
	direction.y = 0.0
	return direction.normalized()


func actualiser_position_jet() -> void:
	var direction := direction_jet()
	particles.global_transform = Transform3D(Basis.looking_at(direction), muzzle.global_position)
	damage_area.global_transform = Transform3D(Basis.IDENTITY, muzzle.global_position)
	# local_coords reste activé : le jet déjà émis suit la visée, comme auparavant.

func start_primary_attack() -> void:
	if not is_overheated and not is_attacking:
		portions_jet.append(Vector2.ZERO)
		is_attacking = true
		particles.emitting = true


func stop_primary_attack() -> void:
	# Arrêter l'émission ; les portions déjà parties continuent leur trajet.
	is_attacking = false
	particles.emitting = false


func vider_jet() -> void:
	# Une téléportation vers une autre salle ne doit pas emporter un ancien tir.
	stop_primary_attack()
	portions_jet.clear()
	particles.restart()
	particles.emitting = false

func _physics_process(delta: float) -> void:
	if Input.is_key_label_pressed(KEY_J):
		modifier(15,10)
	if Input.is_key_label_pressed(KEY_K):
		modifier(30,2)
	if Input.is_key_label_pressed(KEY_M):
		modifier(15,2.8)
	if is_attacking:
		charge -= consumption_rate * delta
		if charge <= 0.0:
			charge = 0.0
			is_overheated = true
			stop_primary_attack()
	else:
		charge += reload_rate * delta
		if charge >= max_charge:
			charge = max_charge
			is_overheated = false
	
	actualiser_position_jet()
	avancer_jet(delta)
	if portions_jet.is_empty():
		return
	# Même test pour les personnages (bodies) et les flaques (areas).
	var candidats := damage_area.get_overlapping_bodies() + damage_area.get_overlapping_areas()
	for cible in candidats:
		if cible.is_in_group("enemies") and not cible.is_queued_for_deletion():
			if cible_dans_jet(cible.global_position, cible.hitbox_radius):
				attaque_1(cible)


func avancer_jet(delta: float) -> void:
	var avance := vitesse_jet * delta
	# Parcourir à l'envers permet de retirer les portions terminées sans décaler
	# les indices de celles qu'il reste à examiner.
	for i in range(portions_jet.size() - 1, -1, -1):
		var portion := portions_jet[i]
		portion.y = minf(portion.y + avance, portee_jet)
		if is_attacking and i == portions_jet.size() - 1:
			portion.x = 0.0 # Le tir maintenu continue de remplir le départ du jet.
		else:
			portion.x += avance # Après relâchement, le vide avance depuis l'arme.
		if portion.x >= portee_jet:
			portions_jet.remove_at(i)
		else:
			portions_jet[i] = portion


func cible_dans_jet(position_cible: Vector3, rayon_cible: float) -> bool:
	# Le combat se lit au sol : projeter la position de l'ennemi sur X/Z.
	var decalage := position_cible - muzzle.global_position
	var point := Vector2(decalage.x, decalage.z)
	var direction := direction_jet()
	var avant := Vector2(direction.x, direction.z)
	var angle := avant.angle_to(point)
	var angle_limite := deg_to_rad(demi_angle_jet)
	var direction_proche := avant.rotated(clampf(angle, -angle_limite, angle_limite))
	for portion in portions_jet:
		if portion.y <= portion.x:
			continue
		# Chercher le point du secteur le plus proche du centre de l'ennemi.
		# Sa largeur compte, mais ne doit pas combler arbitrairement les trous du jet.
		var distance_proche := clampf(point.dot(direction_proche), portion.x, portion.y)
		var point_proche := direction_proche * distance_proche
		if point.distance_to(point_proche) <= rayon_cible:
			return true
	return false


func get_degats() -> float:
	# Ne jamais modifier degats1 : le bonus doit pouvoir disparaître sans dérive.
	if bonus_degats_actif:
		return degats1 * multiplicateur_degats_ameliorations * (1.0 + AUGMENTATION_DEGATS_ESCORTE)
	return degats1 * multiplicateur_degats_ameliorations


func attaque_1(cible):
	if cible != null:
		var multiplier = randf_range(0.9,1.1)
		cible.prendre_degats(round(multiplier * get_degats() *100.0)/100.0)
		# Colorer la zone uniquement après un impact, y compris sur les flaques.
		indicateur_attaque.signaler_impact()

func modifier(angle, rayon):
	if is_equal_approx(demi_angle_jet, float(angle)) and is_equal_approx(portee_jet, float(rayon)):
		return
	demi_angle_jet = clampf(angle, 1.0, 85.0)
	portee_jet = maxf(rayon, 0.1)
	# Un changement de réglage repart proprement, pour ne pas mélanger
	# des particules anciennes avec une nouvelle portée ou un nouvel angle.
	portions_jet.clear()
	if is_attacking:
		portions_jet.append(Vector2.ZERO)
	configurer_jet()
	particles.restart()
	particles.emitting = is_attacking
