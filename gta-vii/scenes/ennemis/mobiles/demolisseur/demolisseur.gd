extends "res://scenes/ennemis/mobiles/sbire.gd"

# Reprendre les dégâts reçus, le gel et les cendres ; remplacer la poursuite et le coup.
@export_group("Démolisseur — déplacement")
@export var vitesse_marche := 3.0
@export var hauteur_modele := 3.0

@export_group("Démolisseur — frappe")
@export var portee_frappe := 1.7
@export var degats_frappe := 28.0
@export_range(0.1, 2.0, 0.05) var preparation_frappe := 0.85
@export_range(0.05, 0.5, 0.01) var duree_coup := 0.14
@export var repos_frappe := 0.55
@export var delai_frappe := 2.0

var etat := "marche"
var temps_etat := 0.0
var cooldown_frappe := 0.0
var direction_frappe := Vector3.FORWARD
var origine_visuel := Vector3.ZERO
var taille_visuel := Vector3.ONE
var animation_zone: Tween
var materiau_zone: StandardMaterial3D
@onready var visuel: Node3D = $Sketchfab_Scene
@onready var zone: MeshInstance3D = $ZoneImpact

func _ready() -> void:
	vie = vie_max
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
	# Un matériau propre à chaque ennemi : son annonce ne colore pas les autres.
	materiau_zone = zone.material_override.duplicate()
	zone.material_override = materiau_zone
	zone.top_level = true
	zone.hide()

func choisir_cible() -> void:
	var refuge = get_tree().get_first_node_in_group("refuge_zombie")
	# Le camion occupé est prioritaire, même si le joueur attaque le golem.
	# Une sirène peut aussi l'attirer vers un camion momentanément vide.
	if is_instance_valid(refuge) and (refuge.is_freed or refuge.attire(self)):
		cible = refuge
		return
	# Sans camion occupé, le joueur et les victimes libérées sont des cibles normales.
	cible = null
	var distance_proche: float = distance_lacher
	var candidats := get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("victime")
	for corps in candidats:
		if not is_instance_valid(corps) or corps.is_queued_for_deletion(): continue
		if corps.is_in_group("refuge_zombie"): continue
		if corps.is_in_group("player") and corps.est_mort: continue
		if corps.is_in_group("victime") and not corps.is_freed: continue
		var ecart: Vector3 = corps.global_position - global_position
		ecart.y = 0.0
		if ecart.length() <= distance_proche:
			distance_proche = ecart.length()
			cible = corps

func _physics_process(delta: float) -> void:
	# Le gel profond suspend aussi la préparation des attaques, pas seulement la marche.
	if est_gele():
		velocity = Vector3.ZERO
		return
	if est_mort: return
	cooldown_frappe = maxf(0.0, cooldown_frappe - delta)
	temps_etat -= delta
	if etat == "preparation":
		if temps_etat <= 0.0: _lancer_coup()
		return
	if etat == "frappe":
		if temps_etat <= 0.0: _frapper()
		return
	if etat == "repos":
		if temps_etat <= 0.0: etat = "marche"
		return
	choisir_cible()
	if not is_instance_valid(cible) or cible.is_queued_for_deletion(): return
	var direction: Vector3 = cible.global_position - global_position
	direction.y = 0.0
	if direction.length() > 0.01: rotation.y = atan2(direction.x, direction.z)
	if _distance_au_bord(cible) <= portee_frappe and _voie_libre(cible):
		velocity = Vector3.ZERO
		if cooldown_frappe <= 0.0: _preparer_coup(direction.normalized())
		return
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
	navigation_agent.target_position = cible.global_position
	var direction := navigation_agent.get_next_path_position() - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		velocity = direction.normalized() * vitesse_marche * multiplicateur_vitesse()
		rotation.y = atan2(direction.x, direction.z)
	move_and_slide()

func _preparer_coup(direction: Vector3) -> void:
	etat = "preparation"
	temps_etat = preparation_frappe
	cible_attaque = cible
	direction_frappe = direction
	zone.global_position = global_position + direction * 1.2 - Vector3.UP * 1.325
	zone.scale = Vector3.ONE
	materiau_zone.albedo_color = Color(1.0, 0.28, 0.04, 0.12)
	zone.show()
	if animation_zone: animation_zone.kill()
	animation_zone = create_tween()
	animation_zone.tween_property(materiau_zone, "albedo_color:a", 0.4, preparation_frappe)
	if animation_frappe: animation_frappe.kill()
	animation_frappe = create_tween().set_parallel(true)
	# Le recul et l'étirement se jouent ensemble : un mouvement ample annonce le coup.
	animation_frappe.tween_property(visuel, "rotation:x", -0.18, preparation_frappe).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	animation_frappe.tween_property(visuel, "scale", taille_visuel * Vector3(0.97, 1.08, 0.97), preparation_frappe)

func _lancer_coup() -> void:
	etat = "frappe"
	temps_etat = duree_coup
	if animation_frappe: animation_frappe.kill()
	animation_frappe = create_tween().set_parallel(true)
	# La frappe est bien plus rapide que la préparation. Les dégâts arrivent à sa fin.
	animation_frappe.tween_property(visuel, "rotation:x", 0.23, duree_coup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	animation_frappe.tween_property(visuel, "scale", taille_visuel * Vector3(1.05, 0.86, 1.05), duree_coup)

func _frapper() -> void:
	# Garder la cible et la direction choisies : le golem peut frapper dans le vide.
	if is_instance_valid(cible_attaque) and not cible_attaque.is_queued_for_deletion():
		var direction: Vector3 = cible_attaque.global_position - global_position
		direction.y = 0.0
		if _distance_au_bord(cible_attaque) <= portee_frappe and direction.normalized().dot(direction_frappe) >= 0.5 and _voie_libre(cible_attaque):
			cible_attaque.prendre_degats(degats_frappe)
	cooldown_frappe = delai_frappe
	etat = "repos"
	temps_etat = repos_frappe
	if animation_frappe: animation_frappe.kill()
	animation_frappe = create_tween().set_parallel(true)
	# Retour lent à la posture d'origine pour donner du poids à la récupération.
	animation_frappe.tween_property(visuel, "rotation:x", 0.0, repos_frappe).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation_frappe.tween_property(visuel, "scale", taille_visuel, repos_frappe)
	if animation_zone: animation_zone.kill()
	animation_zone = create_tween().set_parallel(true)
	# Un bref élargissement puis un fondu signalent l'impact, sans créer de dégâts supplémentaires.
	animation_zone.tween_property(zone, "scale", Vector3(1.35, 1.0, 1.35), 0.25)
	animation_zone.tween_property(materiau_zone, "albedo_color:a", 0.0, 0.25)
	animation_zone.chain().tween_callback(zone.hide)

func mourir() -> void:
	if animation_zone: animation_zone.kill()
	zone.hide()
	super.mourir()

func _on_surface_detection_body_entered(_body: Node3D) -> void:
	pass # La priorité du camion est gérée par choisir_cible.
