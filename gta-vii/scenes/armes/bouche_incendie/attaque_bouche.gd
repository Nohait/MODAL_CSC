extends Node3D

@export_node_path("CharacterBody3D") var chemin_joueur := NodePath("../..")
@export_group("Attaque")
@export_range(1.0, 30.0, 0.5) var portee := 9.0
@export_range(0.5, 10.0, 0.1) var rayon := 2.5
@export_range(1.0, 1000.0, 1.0) var degats := 35.0
@export_range(0.0, 40.0, 0.5) var force_recul := 14.0
@export_range(0.1, 2.0, 0.05) var duree_recul := 0.5
@export_group("Présentation")
@export_range(1.0, 2.0, 0.1) var duree_chute := 1.4
@export_range(2.0, 15.0, 0.5) var duree_presence := 5.0
@export_range(0.1, 2.0, 0.1) var duree_onde := 0.55
@export_range(0.5, 3.0, 0.1) var hauteur_modele := 1.2
@export_range(0.2, 1.0, 0.05) var rayon_collision := 0.4
@export_range(3.0, 20.0, 0.5) var hauteur_chute := 8.0
@export_range(0, 150, 1) var gouttes_impact := 48
@export_range(0.4, 3.0, 0.1) var duree_cycle_visee := 1.2
@export_range(0.002, 0.05, 0.002) var epaisseur_contour := 0.008
@export_range(12.0, 48.0, 1.0) var taille_pictogramme := 28.0
@export_range(-10.0, 10.0, 0.5) var decalage_vertical_pictogramme := -1.0
@export_flags_3d_physics var masque_decor := 1

const MODELE = preload("res://assets/modeles/armes/bouche_incendie/scene.gltf")
const SHADER = preload("res://scenes/armes/bouche_incendie/disque_eau.gdshader")
# L'attaque est rangée dans le conteneur SecondaryAttack du joueur.
@onready var joueur = get_node(chemin_joueur)
var vise := false
var cycle_visee := 0.0
var hauteur_sol_visee := 0.0
var emplacement_valide := false
var cible := Vector3.ZERO
var corps: StaticBody3D
var dessin: Node3D
var disque: MeshInstance3D
var materiau: ShaderMaterial
var icone: TextureRect
var recharge_icone: ShaderMaterial
var temps := 0.0
var phase := "disponible"
var touches: Dictionary = {}
var salle_depart: Node

func _ready() -> void:
	# Une action dédiée permet de changer la touche sans dépendre de l'extincteur.
	if not InputMap.has_action("attaque_bouche"):
		InputMap.add_action("attaque_bouche")
		var clic := InputEventMouseButton.new()
		clic.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("attaque_bouche", clic)
	disque = MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = Vector2.ONE * rayon * 2.0
	disque.mesh = plan
	disque.top_level = true
	disque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	materiau = ShaderMaterial.new()
	materiau.shader = SHADER
	materiau.set_shader_parameter("epaisseur_contour", epaisseur_contour)
	disque.material_override = materiau
	add_child(disque)
	disque.hide()
	icone = TextureRect.new()
	icone.texture = preload("res://scenes/armes/bouche_incendie/icone_bouche.svg")
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Désactiver la taille minimale de la texture AVANT de fixer celle du HUD.
	icone.size = Vector2.ONE * taille_pictogramme
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recharge_icone = ShaderMaterial.new()
	recharge_icone.shader = preload("res://scenes/armes/bouche_incendie/recharge_icone.gdshader")
	recharge_icone.set_shader_parameter("silhouette", preload("res://scenes/armes/bouche_incendie/silhouette_bouche.svg"))
	icone.material = recharge_icone
	var jauge: Control = joueur.get_node("Interface/Reserve/Jauge")
	jauge.add_child(icone)
	# Suivre le remplissage de la barre, et non le centre de son cadre avec titre.
	jauge.resized.connect(_aligner_icone)
	jauge.get_node("Remplissage").resized.connect(_aligner_icone)
	_aligner_icone.call_deferred()

func _aligner_icone() -> void:
	var jauge: Control = icone.get_parent()
	var barre: Control = jauge.get_node("Remplissage")
	icone.size = Vector2.ONE * taille_pictogramme
	# Corriger légèrement le centre visuel de la silhouette et du socle.
	icone.position = Vector2(jauge.size.x - 39.0 - icone.size.x / 2.0, barre.position.y + barre.size.y / 2.0 - icone.size.y / 2.0 + decalage_vertical_pictogramme)

func _input(event: InputEvent) -> void:
	# Le HUD peut absorber les événements souris avant _unhandled_input.
	# Lire cette action ici, uniquement pendant le jeu, comme le jet principal.
	if get_tree().paused or joueur.est_mort or joueur.entree_automatique or phase != "disponible": return
	if event is InputEventMouseButton:
		CursorManager.position_curseur = event.position
	if event.is_action_pressed("attaque_bouche"):
		vise = true
		cycle_visee = 0.0
	elif event.is_action_released("attaque_bouche") and vise:
		_actualiser_cible()
		vise = false
		if emplacement_valide: _lancer()
		else: disque.hide()
	else: return
	get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# Une salle peut changer sans recréer le joueur : ne pas emporter l'attaque.
	if phase != "disponible" and (not is_instance_valid(salle_depart) or salle_depart != _salle_actuelle()):
		_terminer()
	if joueur.est_mort or joueur.entree_automatique:
		vise = false
		if phase == "disponible": disque.hide()
	if vise:
		# Un relâchement absorbé par un menu ne doit pas lancer une attaque au retour.
		if not Input.is_action_pressed("attaque_bouche"):
			vise = false
			disque.hide()
		else:
			# Une onde de prévisualisation ; aucun dégât n'est appliqué ici.
			cycle_visee = fmod(cycle_visee + delta / duree_cycle_visee, 1.0)
			materiau.set_shader_parameter("cycle_visee", cycle_visee)
			_actualiser_cible()
	if phase == "disponible": return
	temps += delta
	if phase == "chute":
		var p := clampf(temps / duree_chute, 0.0, 1.0)
		corps.global_position = cible + Vector3.UP * hauteur_chute * (1.0 - p * p)
		recharge_icone.set_shader_parameter("recharge", clampf(temps / (duree_chute + duree_presence), 0.0, 1.0))
		if p >= 1.0:
			phase = "presence"
			temps = 0.0
			corps.collision_layer = 1
			# Tout le disque frappe à l'atterrissage ; l'onde suivante est visuelle.
			_frapper(rayon)
			_eclabousser()
			joueur.secouer_camera(0.12, 0.18)
	elif phase == "presence":
		var p := clampf(temps / duree_onde, 0.0, 1.0)
		materiau.set_shader_parameter("progression", p)
		disque.visible = p < 1.0
		recharge_icone.set_shader_parameter("recharge", clampf((duree_chute + temps) / (duree_chute + duree_presence), 0.0, 1.0))
		# La dernière seconde annonce la disparition, sans ajouter de cooldown.
		dessin.visible = temps < duree_presence - 1.0 or sin(temps * 20.0) > 0.0
		if temps >= duree_presence: _terminer()

func _actualiser_cible() -> void:
	var camera: Camera3D = joueur.camera
	if not is_instance_valid(camera): return
	var espace := get_world_3d().direct_space_state
	# L'origine du CharacterBody est au-dessus du plancher. Retrouver le sol
	# sous le joueur donne la même hauteur au disque, même au-dessus d'un trou.
	var support := espace.intersect_ray(PhysicsRayQueryParameters3D.create(joueur.global_position + Vector3.UP * 0.2, joueur.global_position - Vector3.UP * 4.0, masque_decor))
	if not support.is_empty(): hauteur_sol_visee = support.position.y
	var hauteur_sol := hauteur_sol_visee
	var souris: Vector2 = CursorManager.position_curseur
	var point = Plane(Vector3.UP, hauteur_sol).intersects_ray(camera.project_ray_origin(souris), camera.project_ray_normal(souris))
	if point == null: return
	var direction: Vector3 = point - joueur.global_position
	direction.y = 0.0
	cible = joueur.global_position + direction.limit_length(portee)
	cible.y = hauteur_sol
	# Chercher la vraie surface du sol, et non supposer que son dessus est à zéro.
	var sol := espace.intersect_ray(PhysicsRayQueryParameters3D.create(cible + Vector3.UP * 3.0, cible - Vector3.UP * 4.0, masque_decor))
	emplacement_valide = not sol.is_empty() and sol.normal.y > 0.8
	if emplacement_valide:
		cible = sol.position
		var trajet := PhysicsRayQueryParameters3D.create(joueur.global_position + Vector3.UP * 0.6, cible + Vector3.UP * 0.6, masque_decor)
		emplacement_valide = espace.intersect_ray(trajet).is_empty()
		var volume := CylinderShape3D.new()
		volume.radius = rayon_collision
		volume.height = hauteur_modele
		var test := PhysicsShapeQueryParameters3D.new()
		test.shape = volume
		test.transform.origin = cible + Vector3.UP * (hauteur_modele / 2.0 + 0.05)
		test.collision_mask = masque_decor | 2
		emplacement_valide = emplacement_valide and espace.intersect_shape(test, 1).is_empty()
	disque.global_position = cible + Vector3.UP * 0.04
	disque.show()
	materiau.set_shader_parameter("progression", -1.0)
	materiau.set_shader_parameter("couleur", Color(0.4, 0.85, 1.0, 0.65) if emplacement_valide else Color(1.0, 0.25, 0.15, 0.65))

func _lancer() -> void:
	phase = "chute"
	temps = 0.0
	recharge_icone.set_shader_parameter("recharge", 0.0)
	touches.clear()
	salle_depart = _salle_actuelle()
	corps = StaticBody3D.new()
	corps.top_level = true
	corps.collision_layer = 0
	add_child(corps)
	dessin = MODELE.instantiate()
	corps.add_child(dessin)
	# Normaliser le modèle importé en conservant ses proportions.
	var boite := _bornes(dessin, Transform3D.IDENTITY)
	var facteur := hauteur_modele / maxf(boite.size.y, 0.01)
	dessin.scale *= facteur
	dessin.position = -Vector3(boite.get_center().x, boite.position.y, boite.get_center().z) * facteur
	var forme := CollisionShape3D.new()
	var cylindre := CylinderShape3D.new()
	cylindre.radius = rayon_collision
	cylindre.height = hauteur_modele
	forme.shape = cylindre
	forme.position.y = hauteur_modele / 2.0
	corps.add_child(forme)
	corps.global_position = cible + Vector3.UP * hauteur_chute

func _bornes(noeud: Node3D, parent_transform: Transform3D) -> AABB:
	var transformation := parent_transform * noeud.transform
	var resultat := AABB()
	if noeud is MeshInstance3D and noeud.mesh != null:
		resultat = transformation * noeud.get_aabb()
	for enfant in noeud.get_children():
		if enfant is Node3D:
			var boite := _bornes(enfant, transformation)
			if boite.size != Vector3.ZERO:
				resultat = boite if resultat.size == Vector3.ZERO else resultat.merge(boite)
	return resultat

func _frapper(distance: float) -> void:
	if not is_instance_valid(joueur.ameliorations): return
	for ennemi in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(ennemi) or not ennemi is Node3D or ennemi.get("est_mort") == true: continue
		if not salle_depart.is_ancestor_of(ennemi) or not ennemi.has_method("prendre_degats"): continue
		var id := ennemi.get_instance_id()
		if touches.has(id): continue
		var direction: Vector3 = ennemi.global_position - cible
		direction.y = 0.0
		if direction.length() > distance: continue
		# L'eau ne frappe pas à travers les murs. Exclure la bouche elle-même du rayon.
		var requete := PhysicsRayQueryParameters3D.create(cible + Vector3.UP * 0.6, ennemi.global_position + Vector3.UP * 0.6, masque_decor)
		requete.exclude = [corps.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(requete).is_empty(): continue
		touches[id] = true
		var effets = joueur.ameliorations.effets_cartes
		effets.infliger(ennemi, degats, &"eau")
		if is_instance_valid(ennemi) and ennemi is CharacterBody3D and ennemi.get("est_mort") != true:
			if direction.length_squared() < 0.001: direction = joueur.last_direction
			effets.etat(ennemi).repousser(direction, force_recul, duree_recul, true)

func _terminer() -> void:
	if is_instance_valid(corps): corps.queue_free()
	phase = "disponible"
	disque.hide()
	icone.modulate = Color.WHITE
	recharge_icone.set_shader_parameter("recharge", 1.0)

func _eclabousser() -> void:
	if gouttes_impact == 0: return
	var gouttes := CPUParticles3D.new()
	gouttes.amount = gouttes_impact
	gouttes.lifetime = 0.7
	gouttes.one_shot = true
	gouttes.explosiveness = 1.0
	gouttes.direction = Vector3.UP
	gouttes.spread = 80.0
	gouttes.initial_velocity_min = 2.0
	gouttes.initial_velocity_max = 5.0
	gouttes.gravity = Vector3(0, -9.8, 0)
	gouttes.scale_amount_min = 0.7
	gouttes.scale_amount_max = 1.3
	var bille := SphereMesh.new()
	bille.radius = 0.025
	bille.height = 0.05
	bille.radial_segments = 6
	bille.rings = 3
	var eau := StandardMaterial3D.new()
	eau.albedo_color = Color(0.6, 0.9, 1.0, 0.7)
	eau.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	eau.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bille.material = eau
	gouttes.mesh = bille
	corps.add_child(gouttes)
	gouttes.position.y = 0.1
	gouttes.restart()

func _salle_actuelle() -> Node:
	if is_instance_valid(joueur.ameliorations):
		return joueur.ameliorations.room_manager.salle_actuelle
	return joueur.get_parent()
