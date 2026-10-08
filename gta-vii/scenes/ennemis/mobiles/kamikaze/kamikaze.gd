extends "res://scenes/ennemis/mobiles/sbire.gd"

# Réutiliser les dégâts reçus et le gel ; le crâne vole sans suivre le navmesh.
@export_group("Kamikaze — poursuite")
@export var portee_detection := 12.0
@export var vitesse_vol := 12.0
@export var acceleration_vol := 20.0
@export_range(20.0, 360.0, 5.0) var rotation_par_seconde_degres := 160.0
@export var duree_activation := 0.3
@export_group("Kamikaze — explosion")
@export var rayon_explosion := 2.1
@export var degats_explosion := 20.0

const EXPLOSION = preload("res://scenes/effets/combat/explosion_kamikaze.tscn")
var etat := "veille"
var explosion_declenchee := false
var temps_activation := 0.0
var temps_vol := 0.0
var vitesse_actuelle := 0.0
var angle_vol := 0.0
var origine_visuel := Vector3.ZERO
var taille_visuel := Vector3.ONE
@onready var visuel: Node3D = $Sketchfab_Scene
@onready var flammes: Node3D = $Flammes

func _ready() -> void:
	vie = vie_max
	hitbox_radius = $CollisionShape3D.shape.radius
	cible_idle.free()
	cible_idle = null
	# Le placement du modèle est enregistré dans la scène, visible aussi dans l’éditeur.
	origine_visuel = visuel.position
	taille_visuel = visuel.scale
	var particules: CPUParticles3D = flammes.get_node("Flames")
	particules.emission_sphere_radius = 0.8
	particules.gravity = Vector3(0, 3, 0)
	particules.color = Color(3.5, 1.1, 0.25, 1)
	particules.preprocess = 0.6
	flammes.scale = Vector3.ONE * 0.36

func _physics_process(delta: float) -> void:
	# Le gel profond suspend aussi la préparation des attaques, pas seulement la marche.
	if est_gele() or subit_recul():
		velocity = Vector3.ZERO
		return
	if est_mort: return
	temps_vol += delta
	# La lévitation est uniquement visuelle : la collision garde une hauteur constante.
	visuel.position.y = origine_visuel.y + sin(temps_vol * 3.0) * 0.06
	if not is_instance_valid(player) or player.est_mort:
		velocity = Vector3.ZERO
		return
	if etat == "veille":
		var ecart: Vector3 = player.global_position - global_position
		ecart.y = 0.0
		if ecart.length() <= portee_detection and _joueur_visible(): _activer(ecart)
		return
	if etat == "activation":
		temps_activation -= delta
		if temps_activation <= 0.0: etat = "poursuite"
		return
	var direction: Vector3 = player.global_position - global_position
	direction.y = 0.0
	var angle_cible := atan2(direction.x, direction.z)
	# Limiter la rotation empêche la tête chercheuse de suivre instantanément un dash.
	var ecart_angle := wrapf(angle_cible - angle_vol, -PI, PI)
	var rotation_max := deg_to_rad(rotation_par_seconde_degres) * delta
	angle_vol += clampf(ecart_angle, -rotation_max, rotation_max)
	rotation.y = angle_vol
	vitesse_actuelle = move_toward(vitesse_actuelle, vitesse_vol, acceleration_vol * delta)
	velocity = Vector3(sin(angle_vol), 0, cos(angle_vol)) * vitesse_actuelle * multiplicateur_vitesse()
	# Contrairement aux autres mobiles, le crâne ne contourne pas les murs : il explose.
	var contact := move_and_collide(velocity * delta)
	if contact: _exploser()

func _joueur_visible() -> bool:
	var destination: Vector3 = player.global_position
	destination.y = global_position.y
	var rayon := PhysicsRayQueryParameters3D.create(global_position, destination, 1)
	rayon.exclude = [get_rid(), player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(rayon).is_empty()

func _activer(direction: Vector3) -> void:
	cible = player
	etat = "activation"
	temps_activation = duree_activation
	angle_vol = atan2(direction.x, direction.z)
	rotation.y = angle_vol
	flammes.show()
	flammes.scale = Vector3.ONE * 0.36
	animation_frappe = create_tween().set_parallel(true)
	# Gonfler légèrement le crâne et ses flammes annonce la poursuite.
	animation_frappe.tween_property(visuel, "scale", taille_visuel * 1.08, duree_activation)
	animation_frappe.tween_property(flammes, "scale", Vector3.ONE * 0.72, duree_activation)

func _exploser() -> void:
	if est_mort or explosion_declenchee: return
	explosion_declenchee = true
	var effet = EXPLOSION.instantiate()
	effet.rayon = rayon_explosion
	effet.position = position
	get_parent().add_child(effet)
	# La cible poursuivie reste le joueur ; l'explosion peut toucher les alliés proches.
	for corps in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("victime"):
		if not is_instance_valid(corps) or corps.is_queued_for_deletion(): continue
		if not corps.has_method("prendre_degats"): continue
		var distance: float = global_position.distance_to(corps.global_position)
		if corps.is_in_group("refuge_zombie"): distance -= corps.distance_au_bord(global_position)
		if distance > rayon_explosion: continue
		# Un mur protège les entités situées derrière lui.
		var destination: Vector3 = corps.global_position
		destination.y = global_position.y
		var rayon := PhysicsRayQueryParameters3D.create(global_position, destination, 1)
		rayon.exclude = [get_rid(), corps.get_rid()]
		if get_world_3d().direct_space_state.intersect_ray(rayon).is_empty():
			corps.prendre_degats(degats_explosion * multiplicateur_degats() * (1.0 + maxi(etage - 1, 0) * degats_par_etage_pourcent / 100.0))
	# Une explosion compte comme une mort normale pour la fin de la vague.
	# mourir() ne redéclenche pas cette explosion grâce au booléen ci-dessus.
	mourir()

func mourir() -> void:
	if est_mort: return
	var statut := get_node_or_null("EtatMousse")
	# Choc thermique déclenche aussi son explosion dangereuse habituelle, une seule fois.
	if not get_meta("fin_invocation", false) and not explosion_declenchee and statut != null and statut.refroidi() and statut.effets.valeur("choc_thermique") > 0:
		_exploser()
		return
	flammes.hide()
	super.mourir()

func _on_surface_detection_body_entered(_body: Node3D) -> void:
	pass # Seul le joueur peut déclencher la poursuite du crâne.
