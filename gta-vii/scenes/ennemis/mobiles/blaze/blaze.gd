extends "res://scenes/ennemis/mobiles/prototype_elementaire.gd"

const PROJECTILE = preload("res://scenes/ennemis/mobiles/artilleur/projectile_artilleur.tscn")
@export_group("Blaze — salve")
@export_range(2.0, 30.0, 0.5) var portee_tir := 14.0
@export_range(0.1, 3.0, 0.1) var preparation_salve := 0.9
@export_range(1, 10, 1) var nombre_boules := 3
@export_range(0.05, 1.0, 0.05) var intervalle_boules := 0.25
@export_range(0.0, 20.0, 0.5) var dispersion_degres := 4.0
@export_range(1.0, 40.0, 0.5) var vitesse_boules := 12.0
@export_range(0.0, 100.0, 1.0) var degats_boule := 10.0
@export_group("Blaze — distance au joueur")
@export_range(2.0, 20.0, 0.5) var distance_ideale := 8.0
@export_range(0.2, 3.0, 0.1) var marge_distance := 1.0
@export_range(0.1, 1.0, 0.05) var vitesse_laterale := 0.6
@export_range(0.5, 6.0, 0.5) var pas_lateral := 3.0
@export_group("Blaze — flammes")
@export_range(0.5, 10.0, 0.1) var duree_extinction := 3.5
@export_range(0.0, 5.0, 0.1) var intensite_lumiere := 1.5
var sens_contournement := 1.0
var etat := "enflamme"
var temps_etat := 0.0
var boules_restantes := 0
var materiaux: Array[BaseMaterial3D] = []
var couleurs: Array[Color] = []
@onready var flammes: Node3D = $Flammes
@onready var lumiere: OmniLight3D = $Lumiere
@onready var depart_tir: Marker3D = $DepartTir

func _ready() -> void:
	super._ready()
	# Des matériaux propres au Blaze permettent d'assombrir celui-ci sans toucher ses copies.
	for mesh in visuel.find_children("*", "MeshInstance3D", true, false):
		for index in range(mesh.mesh.get_surface_count()):
			var original = mesh.get_active_material(index)
			if original is BaseMaterial3D:
				var copie: BaseMaterial3D = original.duplicate()
				mesh.set_surface_override_material(index, copie)
				materiaux.append(copie)
				couleurs.append(copie.albedo_color)
	_actualiser_flammes(true)
	sens_contournement = -1.0 if randf() < 0.5 else 1.0
	# Reprendre le même repère directionnel que l'artilleur, pendant la charge et la salve.
	var alerte = preload("res://scenes/effets/combat/alerte_artilleur.gd").new()
	alerte.name = "AlerteTir"
	alerte.propriete_duree = "preparation_salve"
	alerte.etats_supplementaires.append("salve")
	add_child(alerte)

func _physics_process(delta: float) -> void:
	if est_mort: return
	velocity = Vector3.ZERO
	if est_gele() or subit_recul(): return
	temps_etat -= delta
	attente_navigation -= delta
	# Seul le pompier déclenche sa salve ; une victime ne devient pas sa cible de tir.
	cible = get_tree().get_first_node_in_group("player")
	var joueur_visible := _voit_joueur()
	if is_instance_valid(cible):
		var direction: Vector3 = cible.global_position - global_position
		direction.y = 0.0
		if direction.length() > 0.01: rotation.y = atan2(direction.x, direction.z)
	match etat:
		"enflamme":
			if joueur_visible:
				cible_attaque = cible
				etat = "preparation"
				temps_etat = preparation_salve
				lumiere.light_energy = intensite_lumiere * 1.5
		"preparation":
			if not joueur_visible:
				etat = "enflamme"
				_actualiser_flammes(true)
			elif temps_etat <= 0.0:
				etat = "salve"
				boules_restantes = nombre_boules
				temps_etat = 0.0
		"salve":
			if not joueur_visible: _eteindre()
			elif temps_etat <= 0.0:
				_tirer()
				boules_restantes -= 1
				temps_etat = intervalle_boules
				if boules_restantes <= 0: _eteindre()
		"eteint":
			if temps_etat <= 0.0:
				etat = "enflamme"
				_actualiser_flammes(true)
	# Le déplacement reste indépendant du cycle de tir : il peut reculer en tirant.
	_maintenir_distance(joueur_visible)
	move_and_slide()

func _maintenir_distance(joueur_visible: bool) -> void:
	if not is_instance_valid(cible) or cible.get("est_mort") == true: return
	var carte := navigation_agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(carte) == 0: return
	var ecart: Vector3 = global_position - cible.global_position
	ecart.y = 0.0
	var distance := ecart.length()
	var eloignement := ecart.normalized() if distance > 0.01 else global_basis.z
	var sur_le_cote := eloignement.cross(Vector3.UP) * sens_contournement
	var lateral: bool = joueur_visible and absf(distance - distance_ideale) <= marge_distance
	if attente_navigation <= 0.0:
		attente_navigation = intervalle_navigation
		var destination: Vector3 = cible.global_position
		if joueur_visible:
			# Trop proche : reculer ; trop loin : revenir sur le cercle idéal.
			# Dans la bonne plage : se déplacer latéralement au lieu de rester planté.
			destination = global_position + sur_le_cote * pas_lateral if lateral else cible.global_position + eloignement * distance_ideale
			destination.y = global_position.y
			# Près d'un mur, essayer aussi deux directions obliques pour ne pas reculer dedans.
			var meilleur := NavigationServer3D.map_get_closest_point(carte, destination)
			var meilleure_erreur := meilleur.distance_squared_to(destination)
			for angle in [-45.0, 45.0]:
				var alternative := global_position + (destination - global_position).rotated(Vector3.UP, deg_to_rad(angle))
				var point := NavigationServer3D.map_get_closest_point(carte, alternative)
				var erreur := point.distance_squared_to(alternative)
				if erreur + 0.1 < meilleure_erreur:
					meilleur = point
					meilleure_erreur = erreur
			destination = meilleur
		navigation_agent.target_position = destination
	if navigation_agent.is_navigation_finished(): return
	var direction := navigation_agent.get_next_path_position() - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		velocity = direction.normalized() * vitesse_sbire * multiplicateur_vitesse() * (vitesse_laterale if lateral else 1.0)

func _voit_joueur() -> bool:
	if not is_instance_valid(cible) or cible.is_queued_for_deletion() or cible.get("est_mort") == true: return false
	if global_position.distance_to(cible.global_position) > portee_tir: return false
	# Les murs empêchent de préparer ou de lancer un tir vers un joueur caché.
	var rayon := PhysicsRayQueryParameters3D.create(depart_tir.global_position, cible.global_position, 1)
	rayon.exclude = [get_rid(), cible.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(rayon).is_empty()

func _tirer() -> void:
	var boule = PROJECTILE.instantiate()
	boule.tireur = self
	boule.vitesse = vitesse_boules
	boule.degats = degats_boule * multiplicateur_degats() * (1.0 + maxi(etage - 1, 0) * degats_par_etage_pourcent / 100.0)
	# Chaque boule vise la position actuelle, avec une petite imprécision horizontale.
	boule.direction = depart_tir.global_position.direction_to(cible.global_position).rotated(Vector3.UP, deg_to_rad(randf_range(-dispersion_degres, dispersion_degres)))
	boule.position = get_parent().to_local(depart_tir.global_position)
	get_parent().add_child(boule)

func _eteindre() -> void:
	etat = "eteint"
	boules_restantes = 0
	temps_etat = duree_extinction
	_actualiser_flammes(false)

func _actualiser_flammes(actives: bool) -> void:
	flammes.visible = actives
	for particules in flammes.find_children("*", "CPUParticles3D", true, false):
		particules.emitting = actives
	lumiere.light_energy = intensite_lumiere if actives else 0.0
	for i in range(materiaux.size()):
		materiaux[i].albedo_color = couleurs[i] if actives else Color(0.15, 0.12, 0.1, couleurs[i].a)

func prendre_degats(degats: float, source: StringName = &"feu") -> void:
	if est_mort: return
	# La mousse ou l’eau annule aussi une salve déjà commencée ; les boules parties restent.
	if degats > 0.0 and source in [&"mousse", &"eau"]: _eteindre()
	super.prendre_degats(degats, source)
