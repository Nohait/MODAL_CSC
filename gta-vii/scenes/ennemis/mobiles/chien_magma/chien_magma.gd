extends "res://scenes/ennemis/mobiles/sbire.gd"

# Le chien reprend les dégâts reçus, le gel et les cendres du sbire.
# Son déplacement et ses attaques sont propres à cette scène.
@export_group("Course et bond")
@export var vitesse_course := 7.0
@export_range(0.5, 2.0, 0.05) var taille_modele := 1.25
# Déclencher assez tôt : la course continue pendant les 0,3 s de préparation.
@export var distance_declenchement_bond := 8.0
@export var distance_minimum_bond := 2.0
@export_range(0.05, 10.0, 0.05) var duree_preparation_bond := 0.3
@export_range(0.05, 10.0, 0.05) var duree_bond := 0.45
@export var portee_bond := 6.0
@export var hauteur_bond := 1.2
@export_range(0.0, 30.0, 1.0) var inclinaison_bond_degres := 12.0
@export var repos_bond := 0.55
@export_range(0.1, 0.5, 0.01) var duree_reception := 0.26
@export_range(0.05, 0.4, 0.01) var tassement_reception := 0.22
@export_range(0.05, 10.0, 0.05) var delai_entre_bonds := 2.0
@export var degats_bond := 12.0

@export_group("Morsure")
@export var portee_morsure := 1.4
@export_range(0.05, 10.0, 0.05) var preparation_morsure := 0.18
@export_range(0.05, 10.0, 0.05) var delai_morsure := 0.8
@export var degats_morsure := 7.0

var etat := "course"
var temps_etat := 0.0
var cooldown_bond := 0.0
var cooldown_morsure := 0.0
var direction_bond := Vector3.ZERO
var origine_visuel := Vector3.ZERO
var animations: AnimationPlayer
var animation_marche := ""
var animation_repos := ""
@onready var visuel: Node3D = $Sketchfab_Scene
@onready var crocs: Node3D = $Crocs

func _ready() -> void:
	vie = vie_max
	# Le chien ne patrouille pas : libérer le marqueur hérité qui ne lui sert pas.
	cible_idle.free()
	cible_idle = null
	hitbox_radius = 0.55
	_preparer_modele()
	origine_visuel = visuel.position
	crocs.hide()
	for rangee in [$Crocs/Haut, $Crocs/Bas]:
		for i in range(5):
			var dent := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.11
			cone.height = 0.35
			cone.radial_segments = 6
			dent.mesh = cone
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(1.0, 0.9, 0.6)
			# Les crocs doivent rester lisibles même devant le corps du joueur.
			mat.no_depth_test = true
			dent.material_override = mat
			dent.position = Vector3((i - 2) * 0.26, 0, -abs(i - 2) * 0.08)
			if rangee == $Crocs/Haut: dent.rotation.z = PI
			rangee.add_child(dent)

func _preparer_modele() -> void:
	# Le GLB garde ses proportions. Ramener sa hauteur à celle d'un petit chien.
	var limites := AABB()
	var premier := true
	for mesh in visuel.find_children("*", "MeshInstance3D", true, false):
		var boite: AABB = (visuel.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		limites = boite if premier else limites.merge(boite)
		premier = false
	if not premier and limites.size.y > 0.001:
		var facteur := 1.2 * taille_modele / limites.size.y
		visuel.scale = Vector3.ONE * facteur
		visuel.position = Vector3(-limites.get_center().x * facteur, -0.75, -limites.get_center().z * facteur)
		# Le GLB animé a déjà ses pattes à son origine. Son AABB n'est pas fiable
		# pour les poser au sol : compenser seulement les 0,75 m du corps physique.
	for noeud in visuel.find_children("*", "AnimationPlayer", true, false):
		animations = noeud
		for nom in animations.get_animation_list():
			if "walk" in nom.to_lower(): animation_marche = nom
			if "idle" in nom.to_lower(): animation_repos = nom
			if nom != "RESET": animations.get_animation(nom).loop_mode = Animation.LOOP_LINEAR
		break

func _physics_process(delta: float) -> void:
	# Le gel profond suspend aussi la préparation des attaques, pas seulement la marche.
	if est_gele() or subit_recul():
		velocity = Vector3.ZERO
		return
	if est_mort: return
	cooldown_bond = maxf(0.0, cooldown_bond - delta)
	cooldown_morsure = maxf(0.0, cooldown_morsure - delta)
	temps_etat -= delta
	if etat == "reception":
		# Le tween finit la descente et l'amortissement avant de rendre le déplacement.
		return
	if etat == "bond":
		_avancer_bond(delta)
		return
	if etat == "preparation_bond":
		if not is_instance_valid(player) or player.is_queued_for_deletion() or player.est_mort:
			_annuler_preparation()
			return
		# Garder l'élan pendant le tassement, sans réorienter la charge vers un dash.
		velocity = direction_bond * vitesse_course * multiplicateur_vitesse()
		move_and_slide()
		_jouer_animation(true)
		if global_position.distance_to(player.global_position) <= portee_morsure:
			_annuler_preparation()
			etat = "morsure"
			temps_etat = preparation_morsure
			_jouer_animation(false)
			return
		if temps_etat <= 0.0:
			# La direction mémorisée ne change plus : un dash peut faire rater le bond.
			# Ce passage ne se produit qu’au départ du bond, jamais à chaque image.
			$GrognementBond.play()
			etat = "bond"
			temps_etat = duree_bond
			cooldown_bond = delai_entre_bonds
			_jouer_animation(false)
			# Une brève extension du corps souligne l'impulsion plus rapide que la course.
			if animation_frappe: animation_frappe.kill()
			visuel.scale.y = visuel.scale.x * 1.12
			animation_frappe = create_tween()
			animation_frappe.tween_property(visuel, "scale:y", visuel.scale.x, 0.12)
		return
	if etat == "morsure":
		if temps_etat <= 0.0:
			_mordre()
			etat = "repos"
			temps_etat = 0.25
		return
	if etat == "repos":
		_jouer_animation(false)
		if temps_etat <= 0.0: etat = "course"
		return
	# Ce premier prototype chasse le joueur ; il ne bondit pas sur les captives.
	if not is_instance_valid(player) or player.is_queued_for_deletion() or player.est_mort:
		_jouer_animation(false)
		return
	cible = player
	var direction: Vector3 = player.global_position - global_position
	direction.y = 0.0
	var distance := direction.length()
	if distance > distance_lacher:
		_jouer_animation(false)
		return
	if distance > 0.01: rotation.y = atan2(direction.x, direction.z)
	if distance <= portee_morsure:
		_jouer_animation(false)
		if cooldown_morsure <= 0.0:
			etat = "morsure"
			temps_etat = preparation_morsure
		return
	if distance >= distance_minimum_bond and distance <= distance_declenchement_bond and cooldown_bond <= 0.0 and _voie_libre():
		direction_bond = direction.normalized()
		etat = "preparation_bond"
		temps_etat = duree_preparation_bond
		_suivre_joueur()
		# Le tassement annonce le saut. Le tween revient à la taille normale au départ.
		animation_frappe = create_tween()
		animation_frappe.tween_property(visuel, "scale:y", visuel.scale.x * 0.8, duree_preparation_bond * 0.65)
		animation_frappe.tween_property(visuel, "scale:y", visuel.scale.x, duree_preparation_bond * 0.35)
		return
	_suivre_joueur()

func _annuler_preparation() -> void:
	if animation_frappe: animation_frappe.kill()
	visuel.scale.y = visuel.scale.x
	etat = "course"

func _voie_libre() -> bool:
	# Ne pas préparer un bond à travers un mur ou le camion.
	var requete := PhysicsRayQueryParameters3D.create(global_position, player.global_position, 1)
	requete.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(requete).is_empty()

func _suivre_joueur() -> void:
	velocity = Vector3.ZERO
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0: return
	# L'agent doit pouvoir dépasser le premier point situé sous le centre du corps.
	navigation_agent.target_position = player.global_position
	var direction := navigation_agent.get_next_path_position() - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		velocity = direction.normalized() * vitesse_course * multiplicateur_vitesse()
		rotation.y = atan2(direction.x, direction.z)
	move_and_slide()
	_jouer_animation(velocity.length() > 0.1)

func _avancer_bond(delta: float) -> void:
	# Le corps reste sur le sol pour conserver les collisions ; seul le modèle s'élève.
	var progression := clampf(1.0 - temps_etat / duree_bond, 0.0, 1.0)
	visuel.position.y = origine_visuel.y + sin(progression * PI) * hauteur_bond
	# Une sinusoïde relève le museau à la montée puis l'abaisse à la descente.
	# L'angle vaut zéro aux deux extrémités : pas de cassure avec la réception.
	visuel.rotation.x = -sin(progression * TAU) * deg_to_rad(inclinaison_bond_degres)
	var mouvement := direction_bond * portee_bond / duree_bond * delta * multiplicateur_vitesse()
	var collision := move_and_collide(mouvement)
	if collision:
		var corps = collision.get_collider()
		if is_instance_valid(corps) and corps.is_in_group("player"):
			corps.prendre_degats(degats_bond * multiplicateur_degats())
		# Un seul impact termine le bond : aucun dégât répété par image.
		_terminer_bond()
	elif temps_etat <= 0.0:
		_terminer_bond()

func _terminer_bond() -> void:
	velocity = Vector3.ZERO
	_jouer_animation(false)
	etat = "reception"
	if animation_frappe: animation_frappe.kill()
	var taille := Vector3.ONE * visuel.scale.x
	var descente := 0.1 if visuel.position.y > origine_visuel.y + 0.03 else 0.02
	animation_frappe = create_tween()
	# Un impact peut interrompre le saut en l'air : rejoindre le sol sans téléportation.
	animation_frappe.tween_property(visuel, "position", origine_visuel, descente).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Si un obstacle coupe le bond, redresser aussi le corps pendant sa descente.
	animation_frappe.parallel().tween_property(visuel, "rotation:x", 0.0, descente)
	# Au contact du sol, le corps s'écrase et le museau penche légèrement.
	# parallel() joue l'inclinaison en même temps que le tassement.
	animation_frappe.tween_property(visuel, "scale", taille * Vector3(1.06, 1.0 - tassement_reception, 1.06), duree_reception * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation_frappe.parallel().tween_property(visuel, "rotation:x", 0.12, duree_reception * 0.3)
	# Le retour est plus lent que l'impact pour donner une impression de poids.
	animation_frappe.tween_property(visuel, "scale", taille, duree_reception * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation_frappe.parallel().tween_property(visuel, "rotation:x", 0.0, duree_reception * 0.7)
	animation_frappe.tween_callback(func():
		etat = "repos"
		# La réception fait partie du repos existant, elle ne rajoute pas une longue pause.
		temps_etat = maxf(0.0, repos_bond - descente - duree_reception))

func _mordre() -> void:
	cooldown_morsure = delai_morsure
	_jouer_animation(false)
	# Deux mâchoires larges se referment devant le museau, même en cas d'esquive.
	crocs.show()
	crocs.scale = Vector3.ONE
	$Crocs/Haut.position.y = 0.32
	$Crocs/Bas.position.y = -0.32
	if animation_frappe: animation_frappe.kill()
	animation_frappe = create_tween().set_parallel(true)
	animation_frappe.tween_property($Crocs/Haut, "position:y", 0.04, 0.16)
	animation_frappe.tween_property($Crocs/Bas, "position:y", -0.04, 0.16)
	# Le modèle donne un petit coup vers l'avant pendant que les crocs se ferment.
	animation_frappe.tween_property(visuel, "position", origine_visuel + Vector3(0, 0, 0.25), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation_frappe.chain().tween_property(visuel, "position", origine_visuel, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	animation_frappe.chain().tween_callback(crocs.hide)
	if is_instance_valid(player) and not player.is_queued_for_deletion():
		if global_position.distance_to(player.global_position) <= portee_morsure and _voie_libre():
			player.prendre_degats(degats_morsure * multiplicateur_degats())

func _jouer_animation(marche: bool) -> void:
	if animations == null: return
	var nom := animation_marche if marche else animation_repos
	if nom.is_empty(): return
	if animations.current_animation != nom: animations.play(nom, 0.12)
	animations.speed_scale = 1.5 * multiplicateur_vitesse() if marche else 1.0

func _on_surface_detection_body_entered(_body: Node3D) -> void:
	pass # Le chien utilise directement la distance au joueur.
