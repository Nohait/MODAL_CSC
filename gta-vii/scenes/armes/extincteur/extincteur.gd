extends Node3D

const RETOUR_COMBAT = preload("res://scenes/effets/combat/retour_combat.gd")

@onready var particles: GPUParticles3D = $AttaquePrincipale/GPUParticles3D
@onready var damage_area: Area3D = $AttaquePrincipale/DamageArea
@onready var muzzle: Node3D = $AttaquePrincipale
@onready var direction_marker: Marker3D = $AttaquePrincipale/DirectionMarker
@onready var indicateur_attaque = $IndicateurAttaque

@onready var steam_damage = $"Sons/steam_damage".get_children()
@onready var steam_damage_sound = $"Sons/steam_damage/steam_damage2"
@onready var souffle: AudioStreamPlayer3D = $Sons/Souffle
@onready var volume_souffle: float = souffle.volume_db
var fondu_souffle: Tween
@export_group("Souffle sonore")
@export_range(0.05, 0.5, 0.01) var seuil_reserve_souffle := 0.25
@export_range(0.0, 12.0, 0.5) var baisse_souffle_db := 4.0


@export_group("Jet")
## Distance maximale, en mètres depuis le départ du jet.
# L'ancienne sphère de 2.8 était agrandie par l'échelle 1.5 de l'arme du joueur.
@export_range(0.1, 30.0, 0.1) var portee_jet := 4.2
## Angle de chaque côté de la visée : 15 donne une ouverture totale de 30°.
@export_range(1.0, 85.0, 1.0) var demi_angle_jet := 15.0
## Vitesse commune aux particules et aux limites de la zone de dégâts.
@export_range(0.1, 30.0, 0.1) var vitesse_jet := 5.6
@export_range(0.0, 1.0, 0.01) var opacite_particules := 0.8
@export_subgroup("Aspect de la pulvérisation")
@export_range(50, 800, 10) var nombre_particules := 340
@export_range(0.02, 0.3, 0.01) var taille_depart := 0.09
@export_range(0.1, 1.0, 0.01) var taille_fin := 0.48
@export_range(1.0, 2.0, 0.05) var luminosite_jet := 1.5
@export var couleur_jet_givre := Color(0.74, 0.94, 1.0)

# Chaque appui crée une portion : X = distance du début, Y = distance de fin.
# Plusieurs portions permettent de conserver les espaces entre des tirs brefs.
var portions_jet: Array[Vector2] = []

@export_group("Retour visuel — impacts")
@export var afficher_impacts_mousse := true
## Délai entre deux éclaboussures sur une même cible ; ne change pas les dégâts.
@export_range(0.05, 0.5, 0.01) var intervalle_impacts := 0.14
var delais_impacts: Dictionary = {}

@export_group("Charge")
## Réserve maximale de l'extincteur au début du niveau.
@export_range(1.0, 1000.0, 1.0, "or_greater") var max_charge: float = 100.0
## Quantité de charge consommée par seconde de tir.
@export_range(0.0, 100.0, 0.1, "or_greater") var consumption_rate: float = 25.0
## Quantité récupérée par seconde, réglable indépendamment de la consommation.
@export_range(0.1, 100.0, 0.1, "or_greater") var reload_rate: float = 20.0

## Une courte attente après le tir empêche de recharger entre deux clics rapides.
@export_range(0.0, 2.0, 0.05) var delai_avant_recharge := 0.25
var attente_recharge := 0.0

@export_group("Attaque")
## Dégâts de base par impact, avant le bonus d'escorte et la variation aléatoire.
@export_range(0,100,1) var degats1: float = 1.0
# Le VictimManager recalcule ce booléen quand l'escorte change.
var bonus_degats_actif := false
# Indépendant de l'escorte : reste actif quand une victime est évacuée.
var multiplicateur_degats_ameliorations := 1.0
# Les événements sont indépendants des cartes et ne changent pas leur équilibrage.
var consommation_evenement := 1.0
var panne_evenement := false
var bonus_dernier_souffle := 0.0
var seuil_dernier_souffle := 25.0
var ralentissement_jet := 0.0
var duree_gel := 1.0
var couleur_jet_initiale: Color
var porteur: Node
# Option de test indépendante des statistiques et des améliorations acquises.
var degats_colossaux_test := false
const AUGMENTATION_DEGATS_ESCORTE: float = 0.25
@export_range(0,100,1) var attack_cooldown = 0.2
var attack_timer = 0.0

# Attendre que Godot ait chargé les valeurs choisies dans l'Inspecteur.
@onready var charge: float = max_charge #Charge actuelle au démarrage
var jet_pulse := false
var double_lance := false
var temps_tir := 0.0
# Le bouton peut rester maintenu pendant le creux d’une pulsation.
var emission_effective := false
var particles_secondaires: GPUParticles3D
var is_attacking := false 
var is_overheated := false #Entre en cooldown forcé si l'extincteur tombe à 0

func _ready() -> void:
	# Des ressources propres à cette arme évitent de modifier les autres instances.
	particles.process_material = particles.process_material.duplicate()
	particles.draw_pass_1 = particles.draw_pass_1.duplicate()
	particles.draw_pass_1.material = particles.draw_pass_1.material.duplicate()
	# La couleur des particules doit être lue par le matériau de leur mesh.
	particles.draw_pass_1.material.vertex_color_use_as_albedo = true
	# Travailler en mètres, sans subir l'échelle 0.11 du parent AttaquePrincipale.
	particles.top_level = true
	damage_area.top_level = true
	damage_area.get_node("CollisionShape3D").shape = damage_area.get_node("CollisionShape3D").shape.duplicate()
	couleur_jet_initiale = particles.process_material.color
	porteur = get_tree().get_first_node_in_group("player")
	configurer_jet()
	actualiser_position_jet()
	# Le composant visuel reste indépendant du calcul des dégâts.
	add_child(preload("res://scenes/effets/combat/contact_jet_murs.tscn").instantiate())


func configurer_jet() -> void:
	var simulation := particles.process_material as ParticleProcessMaterial
	# Spread représente déjà un DEMI-angle dans Godot : ne pas le multiplier par 2.
	simulation.spread = demi_angle_jet * (0.35 if double_lance else 1.0)
	simulation.initial_velocity_min = vitesse_jet
	simulation.initial_velocity_max = vitesse_jet
	# Le diamètre augmente au cours du trajet : fin à la buse, plus diffus au loin.
	# La courbe agit sur l'image de chaque particule, sans changer sa trajectoire.
	var expansion := Curve.new()
	expansion.add_point(Vector2(0.0, taille_depart))
	expansion.add_point(Vector2(0.25, lerpf(taille_depart, taille_fin, 0.35)))
	expansion.add_point(Vector2(1.0, taille_fin))
	var texture_expansion := CurveTexture.new()
	texture_expansion.curve = expansion
	simulation.scale_curve = texture_expansion
	particles.amount = nombre_particules
	particles.lifetime = portee_jet / vitesse_jet
	particles.draw_pass_1.material.albedo_color = Color(luminosite_jet, luminosite_jet, luminosite_jet, opacite_particules)
	particles.visibility_aabb = AABB(Vector3.ONE * -portee_jet, Vector3.ONE * portee_jet * 2.0)
	damage_area.get_node("CollisionShape3D").shape.radius = portee_jet
	if is_instance_valid(particles_secondaires):
		particles_secondaires.amount = nombre_particules
		particles_secondaires.process_material.scale_curve = texture_expansion
		particles_secondaires.process_material.spread = simulation.spread
		particles_secondaires.process_material.initial_velocity_min = vitesse_jet
		particles_secondaires.process_material.initial_velocity_max = vitesse_jet
		particles_secondaires.process_material.color = simulation.color
		particles_secondaires.lifetime = particles.lifetime
		particles_secondaires.visibility_aabb = particles.visibility_aabb


func direction_jet() -> Vector3:
	var direction := direction_marker.global_position - muzzle.global_position
	direction.y = 0.0
	return direction.normalized()


func actualiser_position_jet() -> void:
	var direction := direction_jet()
	var ecart := deg_to_rad(demi_angle_jet * 0.65) if double_lance else 0.0
	particles.global_transform = Transform3D(Basis.looking_at(direction.rotated(Vector3.UP, ecart)), muzzle.global_position)
	if is_instance_valid(particles_secondaires):
		particles_secondaires.global_transform = Transform3D(Basis.looking_at(direction.rotated(Vector3.UP, -ecart)), muzzle.global_position)
	damage_area.global_transform = Transform3D(Basis.IDENTITY, muzzle.global_position)
	# local_coords reste activé : le jet déjà émis suit la visée, comme auparavant.

func start_primary_attack() -> void:
	if not panne_evenement and not is_overheated and not is_attacking:
		portions_jet.append(Vector2.ZERO)
		is_attacking = true
		temps_tir = 0.0
		emission_effective = true
		attente_recharge = delai_avant_recharge
		particles.emitting = true
		if is_instance_valid(particles_secondaires): particles_secondaires.emitting = double_lance
		regler_souffle(true)


func stop_primary_attack() -> void:
	# Arrêter l'émission ; les portions déjà parties continuent leur trajet.
	if is_attacking:
		regler_souffle(false)
	is_attacking = false
	emission_effective = false
	particles.emitting = false
	if is_instance_valid(particles_secondaires): particles_secondaires.emitting = false

func regler_souffle(en_marche: bool) -> void:
	# Interrompre le fondu précédent permet aussi de reprendre un tir très rapidement.
	if fondu_souffle: fondu_souffle.kill()
	fondu_souffle = create_tween()
	if en_marche:
		if not souffle.playing:
			souffle.volume_db = -60.0
			souffle.play()
		# Le Tween monte le volume en 80 ms, sans changer la vitesse du son.
		fondu_souffle.tween_property(souffle, "volume_db", volume_cible_souffle(), 0.08)
	else:
		# Baisser le volume avant stop() évite une coupure sèche du souffle.
		fondu_souffle.tween_property(souffle, "volume_db", -60.0, 0.12)
		fondu_souffle.tween_callback(souffle.stop)

func volume_cible_souffle() -> float:
	var reserve := clampf(charge / maxf(max_charge, 0.01), 0.0, 1.0)
	return volume_souffle - baisse_souffle_db * (1.0 - smoothstep(0.0, seuil_reserve_souffle, reserve))


func vider_jet() -> void:
	# Une téléportation vers une autre salle ne doit pas emporter un ancien tir.
	stop_primary_attack()
	portions_jet.clear()
	particles.restart()
	particles.emitting = false
	if is_instance_valid(particles_secondaires):
		particles_secondaires.restart()
		particles_secondaires.emitting = false

func _physics_process(delta: float) -> void:
	# Les délais sont indépendants par cible et disparaissent une fois expirés.
	for id in delais_impacts.keys():
		delais_impacts[id] -= delta
		if delais_impacts[id] <= 0.0:
			delais_impacts.erase(id)

	if Input.is_key_label_pressed(KEY_J):
		modifier(15,10)
	if Input.is_key_label_pressed(KEY_K):
		modifier(30,2)
	if Input.is_key_label_pressed(KEY_M):
		modifier(15,2.8)
	if is_attacking:
		temps_tir += delta
		var emettre := not jet_pulse or fmod(temps_tir, 0.6) < 0.22
		# Chaque impulsion possède sa portion ; les trous continuent d’avancer.
		if emettre and not emission_effective: portions_jet.append(Vector2.ZERO)
		emission_effective = emettre
		particles.emitting = emettre
		if is_instance_valid(particles_secondaires): particles_secondaires.emitting = emettre and double_lance
	if is_attacking:
		attente_recharge = delai_avant_recharge
		if emission_effective: charge -= consumption_rate * consommation_evenement * delta
		if charge <= 0.0:
			charge = 0.0
			is_overheated = true
			stop_primary_attack()
	else:
		# Recharger uniquement la portion de cette frame située après l'attente.
		var temps_recharge := maxf(0.0, delta - attente_recharge)
		attente_recharge = maxf(0.0, attente_recharge - delta)
		var soutien: float = porteur.ameliorations.effets_cartes.multiplicateur_recharge() if is_instance_valid(porteur) and is_instance_valid(porteur.ameliorations) else 1.0
		charge += reload_rate * soutien * temps_recharge
		if charge >= max_charge:
			charge = max_charge
			is_overheated = false
	
	actualiser_position_jet()
	avancer_jet(delta)
	if is_attacking and souffle.playing and (fondu_souffle == null or not fondu_souffle.is_running()):
		souffle.volume_db = move_toward(souffle.volume_db, volume_cible_souffle(), delta * 12.0)
	if portions_jet.is_empty():
		return
	# Même test pour les personnages (bodies) et les flaques (areas).
	var candidats := damage_area.get_overlapping_bodies() + damage_area.get_overlapping_areas()
	for cible in candidats:
		if cible.is_in_group("enemies") and not cible.is_queued_for_deletion():
			if cible_dans_jet(cible.global_position, cible.hitbox_radius):
				attaque_1(cible, delta)


func avancer_jet(delta: float) -> void:
	var avance := vitesse_jet * delta
	# Parcourir à l'envers permet de retirer les portions terminées sans décaler
	# les indices de celles qu'il reste à examiner.
	for i in range(portions_jet.size() - 1, -1, -1):
		var portion := portions_jet[i]
		portion.y = minf(portion.y + avance, portee_jet)
		if emission_effective and i == portions_jet.size() - 1:
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
	var directions: Array[Vector2] = [avant]
	var angle_limite := deg_to_rad(demi_angle_jet)
	if double_lance:
		directions = [avant.rotated(angle_limite * 0.65), avant.rotated(-angle_limite * 0.65)]
		angle_limite *= 0.35
	# Les deux jets ont un espace central ; une cible large peut toucher leur bord.
	for axe in directions:
		var angle := axe.angle_to(point)
		var direction_proche := axe.rotated(clampf(angle, -angle_limite, angle_limite))
		for portion in portions_jet:
			if portion.y <= portion.x: continue
			var distance_proche := clampf(point.dot(direction_proche), portion.x, portion.y)
			if point.distance_to(direction_proche * distance_proche) <= rayon_cible: return true
	return false


func get_degats() -> float:
	if degats_colossaux_test:
		return 100000.0
	var puissance := multiplicateur_degats_ameliorations
	if is_instance_valid(porteur) and is_instance_valid(porteur.ameliorations):
		puissance *= porteur.ameliorations.effets_cartes.multiplicateur_jet()
	# Lire les PV au moment du coup prend aussi en compte les soins et la vie maximale.
	if is_instance_valid(porteur) and porteur.BarreDeVie.value <= porteur.BarreDeVie.max_value * seuil_dernier_souffle / 100.0:
		puissance *= 1.0 + bonus_dernier_souffle / 100.0
	# Ne jamais modifier degats1 : le bonus doit pouvoir disparaître sans dérive.
	if bonus_degats_actif:
		return degats1 * puissance * (1.0 + AUGMENTATION_DEGATS_ESCORTE)
	return degats1 * puissance


func attaque_1(cible, delta: float):
	if cible != null:
		# Créer l'éclaboussure avant les dégâts, car cet impact peut tuer la cible.
		# Les flaques conservent leur rendu actuel ; seuls les corps reçoivent la mousse.
		if afficher_impacts_mousse and cible is CharacterBody3D and not cible.est_mort:
			var id: int = cible.get_instance_id()
			if not delais_impacts.has(id):
				RETOUR_COMBAT.creer_impact(cible, muzzle.global_position)
				delais_impacts[id] = intervalle_impacts
		var multiplier = randf_range(0.9,1.1)
		if ralentissement_jet > 0.0 and cible.has_method("appliquer_gel"):
			cible.appliquer_gel(ralentissement_jet, duree_gel)
		if is_instance_valid(porteur) and is_instance_valid(porteur.ameliorations):
			porteur.ameliorations.effets_cartes.toucher_jet(cible, delta)
		cible.prendre_degats(round(multiplier * get_degats() *100.0)/100.0, &"mousse")
		# Colorer la zone uniquement après un impact, y compris sur les flaques.
		indicateur_attaque.signaler_impact()
		if not steam_damage_sound.playing:
			print('son')
			steam_damage_sound = steam_damage.pick_random()
			steam_damage_sound.play()

func regler_variantes(pulse: bool, double: bool) -> void:
	if double and not is_instance_valid(particles_secondaires):
		# Dupliquer uniquement le système de particules, jamais toute l’arme.
		particles_secondaires = particles.duplicate()
		particles_secondaires.name = "SecondJet"
		particles_secondaires.process_material = particles.process_material.duplicate()
		particles_secondaires.emitting = false
		particles.get_parent().add_child(particles_secondaires)
	var change := jet_pulse != pulse or double_lance != double
	jet_pulse = pulse
	double_lance = double
	if change: vider_jet()
	configurer_jet()
	actualiser_position_jet()

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
