extends "res://scenes/ennemis/mobiles/sbire.gd"

# Base provisoire : réutiliser les dégâts, le gel et la mort du sbire.
# Les attaques propres à chaque élémentaire seront conçues ensuite.
@export_group("Prototype — modèle")
@export_range(0.5, 4.0, 0.1) var hauteur_modele := 1.8
# Désactiver lorsque la scène contient déjà le placement définitif du modèle.
@export var ajuster_modele_au_demarrage := true
@export var animation_repos := ""
@export var animation_marche := ""
@export var animation_attaque := ""
@export_range(-180.0, 180.0, 5.0) var orientation_modele := 0.0
@export_group("Prototype — déplacement")
@export_range(0.1, 1.0, 0.05) var intervalle_navigation := 0.25
var attente_navigation := 0.0
var lecteur: AnimationPlayer
var coup_restant := 0.0
@onready var visuel: Node3D = $Sketchfab_Scene

func _ready() -> void:
	vie = vie_max
	degats_sbire *= 1.0 + maxi(etage - 1, 0) * degats_par_etage_pourcent / 100.0
	cible_idle.free()
	cible_idle = null
	hitbox_radius = $CollisionShape3D.shape.radius
	navigation_agent.path_search_max_polygons = 2048
	# Ajuster uniformément la taille et poser le modèle au sol sans l’étirer.
	var limites := AABB()
	var premier := true
	for mesh in visuel.find_children("*", "MeshInstance3D", true, false):
		var boite: AABB = (visuel.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		limites = boite if premier else limites.merge(boite)
		premier = false
	if ajuster_modele_au_demarrage and not premier and limites.size.y > 0.001:
		var facteur := hauteur_modele / limites.size.y
		var modele: Node3D = visuel.get_child(0)
		modele.scale = Vector3.ONE * facteur
		modele.position = Vector3(-limites.get_center().x, -limites.position.y, -limites.get_center().z) * facteur
		visuel.position.y = -$CollisionShape3D.shape.height / 2.0
		visuel.rotation.y = deg_to_rad(orientation_modele)
	var lecteurs := visuel.find_children("*", "AnimationPlayer", true, false)
	if not lecteurs.is_empty():
		lecteur = lecteurs[0]
		for nom in lecteur.get_animation_library_list():
			var copie := lecteur.get_animation_library(nom).duplicate(true)
			lecteur.remove_animation_library(nom)
			lecteur.add_animation_library(nom, copie)
	_jouer_animation(animation_repos)

func _physics_process(delta: float) -> void:
	if est_mort: return
	if est_gele() or subit_recul():
		velocity = Vector3.ZERO
		_jouer_animation(animation_repos)
		return
	attaque_timer -= delta
	attente_navigation -= delta
	if coup_restant > 0.0:
		coup_restant = maxf(0.0, coup_restant - delta)
		if coup_restant == 0.0:
			# Vérifier à l’impact : une cible qui esquive ne reçoit pas le coup.
			if is_instance_valid(cible_attaque) and global_position.distance_to(cible_attaque.global_position) <= distance_attaque:
				cible_attaque.prendre_degats(degats_sbire * multiplicateur_degats())
		return
	if attente_navigation <= 0.0:
		attente_navigation = intervalle_navigation
		cible = null
		var distance_proche: float = distance_detection
		for corps in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("victime"):
			if corps.is_queued_for_deletion() or corps.get("est_mort") == true: continue
			if corps.is_in_group("victime") and not corps.is_freed: continue
			var distance := global_position.distance_to(corps.global_position)
			if distance < distance_proche:
				distance_proche = distance
				cible = corps
		if is_instance_valid(cible): navigation_agent.target_position = cible.global_position
	velocity = Vector3.ZERO
	if not is_instance_valid(cible):
		_jouer_animation(animation_repos)
		return
	var direction: Vector3 = cible.global_position - global_position
	direction.y = 0.0
	if direction.length() > 0.01: rotation.y = atan2(direction.x, direction.z)
	if global_position.distance_to(cible.global_position) <= distance_attaque:
		if attaque_timer <= 0.0:
			cible_attaque = cible
			coup_restant = duree_preparation
			attaque_timer = attaque_cooldown
			_jouer_animation(animation_attaque, false)
		else: _jouer_animation(animation_repos)
	elif NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) > 0:
		direction = navigation_agent.get_next_path_position() - global_position
		direction.y = 0.0
		if direction.length() > 0.05:
			velocity = direction.normalized() * vitesse_sbire * multiplicateur_vitesse()
		_jouer_animation(animation_marche)
	move_and_slide()

func _jouer_animation(nom: String, boucle := true) -> void:
	if lecteur == null or nom.is_empty() or not lecteur.has_animation(nom): return
	if lecteur.current_animation == nom and lecteur.is_playing(): return
	# Dupliquer évite de modifier la ressource d’animation partagée entre les copies.
	var animation := lecteur.get_animation(nom)
	animation.loop_mode = Animation.LOOP_LINEAR if boucle else Animation.LOOP_NONE
	lecteur.play(nom, 0.12)
