extends "res://scenes/ennemis/mobiles/sbire.gd"

# Garder les dégâts reçus, le gel et les cendres du sbire.
@export_group("Artilleur — déplacement")
@export var vitesse_marche := 3.5
@export var hauteur_modele := 2.4
@export var portee_tir := 12.0
@export_range(0.1, 1.0, 0.05) var intervalle_navigation := 0.3
@export_range(0.1, 3.0, 0.1) var deplacement_avant_recalcul := 0.6
@export_range(256, 8192, 256) var limite_polygones_navigation := 2048
@export_group("Artilleur — tir")
@export var preparation_tir := 0.8
@export var delai_tir := 2.0
@export var vitesse_projectile := 18.0
@export var degats_projectile := 15.0

const PROJECTILE = preload("res://scenes/ennemis/mobiles/artilleur/projectile_artilleur.tscn")
var etat := "marche"
var temps_etat := 0.0
var cooldown_tir := 0.0
var direction_tir := Vector3.FORWARD
var depart_tir: Marker3D
var origine_visuel := Vector3.ZERO
var taille_visuel := Vector3.ONE
var attente_navigation := 0.0
var cible_navigation: Node3D
@onready var visuel: Node3D = $Sketchfab_Scene
@onready var orbe: MeshInstance3D = $Orbe

func _ready() -> void:
	vie = vie_max
	# Borner les recherches lorsque la cible se trouve dans une zone inaccessible.
	navigation_agent.path_search_max_polygons = limite_polygones_navigation
	hitbox_radius = 0.8
	cible_idle.free()
	cible_idle = null
	# Ce modèle n'est pas animé : sa boîte permet de le centrer et de poser ses pieds.
	var limites := AABB()
	var premier := true
	for mesh in visuel.find_children("*", "MeshInstance3D", true, false):
		var boite: AABB = (visuel.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		limites = boite if premier else limites.merge(boite)
		premier = false
	if not premier and limites.size.y > 0.001:
		var facteur := hauteur_modele / limites.size.y
		visuel.scale = Vector3.ONE * facteur
		visuel.position = Vector3(-limites.get_center().x, -limites.position.y, -limites.get_center().z) * facteur
		visuel.position.y -= 1.35
	origine_visuel = visuel.position
	taille_visuel = visuel.scale
	_colorier_modele()
	orbe.material_override = orbe.material_override.duplicate()
	orbe.hide()

func choisir_cible() -> void:
	cible = null
	var distance_proche: float = distance_lacher
	var candidats := get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("victime")
	for corps in candidats:
		if not is_instance_valid(corps) or corps.is_queued_for_deletion(): continue
		if corps.is_in_group("refuge_zombie") and not corps.is_freed: continue
		if corps.is_in_group("player") and corps.est_mort: continue
		if corps.is_in_group("victime") and not corps.is_freed: continue
		var ecart: Vector3 = corps.global_position - global_position
		ecart.y = 0.0
		if ecart.length() <= distance_proche:
			distance_proche = ecart.length()
			cible = corps


func _physics_process(delta: float) -> void:
	attente_navigation = maxf(0.0, attente_navigation - delta)
	# Le gel profond suspend aussi la préparation des attaques, pas seulement la marche.
	if est_gele() or subit_recul():
		velocity = Vector3.ZERO
		return
	if est_mort: return
	cooldown_tir = maxf(0.0, cooldown_tir - delta)
	if etat == "preparation":
		if not is_instance_valid(cible_attaque) or cible_attaque.is_queued_for_deletion():
			_annuler_tir()
			return
		# Suivre la cible pendant toute la charge, sans déplacer le corps.
		var direction: Vector3 = cible_attaque.global_position - global_position
		rotation.y = atan2(direction.x, direction.z)
		orbe.global_position = depart_tir.global_position
		temps_etat -= delta
		if temps_etat <= 0.0: _tirer()
		return
	choisir_cible()
	if not is_instance_valid(cible) or cible.is_queued_for_deletion(): return
	var direction: Vector3 = cible.global_position - global_position
	direction.y = 0.0
	if direction.length() > 0.01: rotation.y = atan2(direction.x, direction.z)
	if _distance_au_bord(cible) <= portee_tir and _voie_libre(cible):
		velocity = Vector3.ZERO
		if cooldown_tir <= 0.0: _preparer_tir(direction.normalized())
	else:
		_suivre_cible()

func _distance_au_bord(corps: Node3D) -> float:
	var ecart := corps.global_position - global_position
	ecart.y = 0.0
	var distance := ecart.length()
	# La portée est mesurée depuis la carrosserie, pas depuis le centre du camion.
	if corps.is_in_group("refuge_zombie"):
		distance -= corps.distance_au_bord(global_position)
	return distance

func _voie_libre(corps: Node3D) -> bool:
	# La cible est exclue du rayon ; seuls les murs et le décor peuvent bloquer le coup.
	var destination := corps.global_position
	# L'origine du camion est au sol : viser à hauteur du golem évite de toucher le sol.
	destination.y = global_position.y
	var requete := PhysicsRayQueryParameters3D.create(global_position, destination, 1)
	requete.exclude = [get_rid(), corps.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(requete).is_empty()

func _suivre_cible() -> void:
	velocity = Vector3.ZERO
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0: return
	# Affecter target_position relance la recherche : ne pas le faire à chaque image.
	var cible_changee: bool = cible_navigation != cible
	var cible_deplacee := navigation_agent.target_position.distance_squared_to(cible.global_position) >= deplacement_avant_recalcul * deplacement_avant_recalcul
	if cible_changee or (attente_navigation <= 0.0 and (cible_deplacee or navigation_agent.is_navigation_finished())):
		navigation_agent.target_position = cible.global_position
		cible_navigation = cible
		attente_navigation = intervalle_navigation
	# Un chemin terminé attend le prochain recalcul ; le suivre encore provoquerait des requêtes inutiles.
	if navigation_agent.is_navigation_finished(): return
	var direction := navigation_agent.get_next_path_position() - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		velocity = direction.normalized() * vitesse_marche * multiplicateur_vitesse()
		rotation.y = atan2(direction.x, direction.z)
	move_and_slide()


func _preparer_tir(direction: Vector3) -> void:
	etat = "preparation"
	temps_etat = preparation_tir
	velocity = Vector3.ZERO
	# Garder la cible, mais actualiser la visée jusqu’au départ du tir.
	direction_tir = direction
	cible_attaque = cible
	orbe.global_position = depart_tir.global_position
	orbe.scale = Vector3.ONE * 0.25
	orbe.show()
	if animation_frappe: animation_frappe.kill()
	animation_frappe = create_tween().set_parallel(true)
	# L'orbe grossit pendant que le magicien se penche en arrière.
	animation_frappe.tween_property(orbe, "scale", Vector3.ONE, preparation_tir)
	animation_frappe.tween_property(visuel, "rotation:x", -0.12, preparation_tir)

func _tirer() -> void:
	if not is_instance_valid(cible_attaque) or cible_attaque.is_queued_for_deletion():
		_annuler_tir()
		return
	# Viser en 3D depuis le cristal : une boule lancée en hauteur doit redescendre.
	var destination: Vector3 = cible_attaque.global_position
	if cible_attaque.is_in_group("refuge_zombie"):
		destination = cible_attaque.get_node("CollisionShape3D").global_position
	direction_tir = depart_tir.global_position.direction_to(destination)
	var projectile = PROJECTILE.instantiate()
	projectile.direction = direction_tir
	projectile.vitesse = vitesse_projectile
	projectile.degats = degats_projectile * (1.0 + maxi(etage - 1, 0) * degats_par_etage_pourcent / 100.0)
	projectile.tireur = self
	# Le tir appartient à la salle et disparaîtra avec elle.
	var salle := get_parent().get_parent()
	var conteneur := salle.get_node_or_null("ProjectilesTour")
	if conteneur == null: conteneur = salle
	projectile.position = conteneur.to_local(depart_tir.global_position)
	conteneur.add_child(projectile)
	orbe.hide()
	etat = "marche"
	cooldown_tir = delai_tir
	if animation_frappe: animation_frappe.kill()
	animation_frappe = create_tween()
	# Un retour rapide accompagne le départ du projectile.
	animation_frappe.tween_property(visuel, "rotation:x", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func mourir() -> void:
	orbe.hide()
	super.mourir()

func _on_surface_detection_body_entered(_body: Node3D) -> void:
	pass # Les cibles sont choisies directement dans choisir_cible.

func _colorier_modele() -> void:
	# Dupliquer les matériaux pour conserver le modèle téléchargé intact.
	for mesh in visuel.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original = mesh.get_active_material(surface)
			if not original is StandardMaterial3D: continue
			var materiau: StandardMaterial3D = original.duplicate()
			if original.resource_name == "08_-_Default":
				materiau.albedo_color = Color(0.3, 0.09, 0.07)
			elif original.resource_name == "07_-_Default":
				# Le cristal est une surface du modèle : placer le départ au centre de ses sommets.
				var sommets: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				var centre := Vector3.ZERO
				for sommet in sommets: centre += sommet
				centre /= max(sommets.size(), 1)
				depart_tir = Marker3D.new()
				depart_tir.name = "DepartTir"
				mesh.add_child(depart_tir)
				depart_tir.position = centre
				materiau.albedo_texture = null
				materiau.albedo_color = Color(1, 0.25, 0.03)
				materiau.emission_enabled = true
				materiau.emission = Color(1, 0.12, 0.01)
				materiau.emission_energy_multiplier = 2.0
			mesh.set_surface_override_material(surface, materiau)

func _annuler_tir() -> void:
	if animation_frappe: animation_frappe.kill()
	orbe.hide()
	visuel.rotation.x = 0.0
	etat = "marche"
	cooldown_tir = delai_tir
