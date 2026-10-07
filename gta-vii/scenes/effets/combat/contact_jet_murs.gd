extends Node3D

@export var actif := true
@export_flags_3d_physics var masque_contacts := 1048575
@export_range(3, 9, 2) var nombre_rayons := 5
@export_range(0.2, 2.0, 0.05) var taille_contact := 0.65
@export_range(0.04, 0.3, 0.01) var intervalle_detection := 0.08
@export_range(0.1, 0.6, 0.01) var intervalle_dispersion := 0.2
@export_range(2, 16, 1) var nombre_particules := 6
@export_range(0.1, 1.0, 0.05) var duree_dispersion := 0.35
@export_range(0.2, 3.0, 0.1) var vitesse_dispersion := 1.2
const COUCHE_JET := 131072 # Couche visuelle 18, réservée aux collisions de cette pulvérisation.
const TEXTURE = preload("res://assets/textures/extincteur/pulverisation.png")
var attente := 0.0
var attente_dispersion := 0.0
var obstacles: Dictionary = {}
@onready var arme = get_parent()
var exclusions: Array[RID] = []

func _ready() -> void:
	# Ignorer le porteur, sinon le jet peut toucher sa propre capsule en sortant de l'arme.
	var parent := get_parent()
	while parent != null:
		if parent is CollisionObject3D: exclusions.append(parent.get_rid())
		parent = parent.get_parent()

func _physics_process(delta: float) -> void:
	attente -= delta
	attente_dispersion -= delta
	# Garder les collisions jusqu'à la disparition des dernières particules émises.
	for id in obstacles.keys():
		obstacles[id].reste -= delta
		var corps = obstacles[id].corps.get_ref()
		if obstacles[id].reste <= 0.0 or corps == null or corps.is_queued_for_deletion():
			obstacles[id].noeud.queue_free()
			obstacles.erase(id)
		else:
			# Un objet mobile emporte son contact ; aucune ancienne collision ne reste en l'air.
			obstacles[id].noeud.global_transform = corps.global_transform * obstacles[id].local
	if not actif or attente > 0.0 or arme.portions_jet.is_empty(): return
	attente = intervalle_detection
	_preparer_particules(arme.particles)
	if is_instance_valid(arme.particles_secondaires): _preparer_particules(arme.particles_secondaires)
	var depart: Vector3 = arme.muzzle.global_position
	var direction: Vector3 = arme.direction_jet()
	# Échantillonner aussi l'intérieur du cône, pour repérer les petits obstacles.
	for index in range(nombre_rayons):
		var angle: float = lerpf(-arme.demi_angle_jet, arme.demi_angle_jet, float(index) / (nombre_rayons - 1))
		var fin: Vector3 = depart + direction.rotated(Vector3.UP, deg_to_rad(angle)) * arme.portee_jet
		var requete := PhysicsRayQueryParameters3D.create(depart, fin, masque_contacts, exclusions)
		# Les zones de détection et d'attaque ne sont pas des surfaces solides.
		requete.collide_with_areas = false
		var contact := get_world_3d().direct_space_state.intersect_ray(requete)
		if contact.is_empty(): continue
		_ajouter_obstacle(contact)
		var distance: float = depart.distance_to(contact.position)
		for portion: Vector2 in arme.portions_jet:
			if distance >= portion.x and distance <= portion.y and attente_dispersion <= 0.0:
				_disperser(contact.position, contact.normal)
				attente_dispersion = intervalle_dispersion
				break

func _preparer_particules(jet: GPUParticles3D) -> void:
	jet.layers |= COUCHE_JET
	jet.process_material.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT

func _ajouter_obstacle(contact: Dictionary) -> void:
	var corps: CollisionObject3D = contact.collider
	var proprietaire := corps.shape_find_owner(contact.shape)
	var collision := corps.shape_owner_get_owner(proprietaire) as CollisionShape3D
	var boite_exacte := collision != null and collision.shape is BoxShape3D
	var id := "%s:%s" % [corps.get_instance_id(), contact.shape]
	if not obstacles.has(id):
		# Une boîte exacte pour les murs ; une petite surface au contact pour les autres formes.
		var boite := GPUParticlesCollisionBox3D.new()
		boite.top_level = true
		boite.cull_mask = COUCHE_JET
		add_child(boite)
		obstacles[id] = {"noeud": boite, "reste": 0.0, "corps": weakref(corps), "local": Transform3D.IDENTITY}
	if boite_exacte:
		obstacles[id].noeud.size = collision.shape.size
		obstacles[id].noeud.global_transform = collision.global_transform
	else:
		# La normale indique l'extérieur de la surface, même sur un objet rond ou un mesh.
		var normale: Vector3 = contact.normal
		var haut := Vector3.RIGHT if absf(normale.dot(Vector3.UP)) > 0.95 else Vector3.UP
		obstacles[id].noeud.size = Vector3(taille_contact, taille_contact, 0.08)
		obstacles[id].noeud.global_transform = Transform3D(Basis.looking_at(normale, haut), contact.position - normale * 0.02)
	obstacles[id].local = corps.global_transform.affine_inverse() * obstacles[id].noeud.global_transform
	obstacles[id].reste = arme.portee_jet / arme.vitesse_jet + 0.2

func _disperser(position_contact: Vector3, normale: Vector3) -> void:
	var cote := normale.cross(Vector3.UP).normalized()
	if cote.length_squared() < 0.01: cote = normale.cross(Vector3.RIGHT).normalized()
	for sens in [-1.0, 1.0]:
		var nuage := CPUParticles3D.new()
		nuage.top_level = true
		nuage.emitting = false
		nuage.one_shot = true
		nuage.amount = nombre_particules
		nuage.lifetime = duree_dispersion
		nuage.explosiveness = 1.0
		nuage.local_coords = false
		nuage.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nuage.direction = (cote * sens + normale * 0.25 + Vector3.UP * 0.15).normalized()
		nuage.spread = 20.0
		nuage.gravity = Vector3.ZERO
		nuage.initial_velocity_min = vitesse_dispersion * 0.7
		nuage.initial_velocity_max = vitesse_dispersion
		var materiau := StandardMaterial3D.new()
		materiau.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		materiau.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		materiau.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		materiau.vertex_color_use_as_albedo = true
		materiau.albedo_texture = TEXTURE
		var image := QuadMesh.new()
		image.size = Vector2(0.25, 0.25)
		image.material = materiau
		nuage.mesh = image
		var couleur: Color = arme.particles.process_material.color
		var fondu := Gradient.new()
		fondu.set_color(0, Color(couleur, 0.4))
		fondu.set_color(1, Color(couleur, 0.0))
		nuage.color_ramp = fondu
		add_child(nuage)
		nuage.global_position = position_contact + normale * 0.05
		nuage.finished.connect(nuage.queue_free)
		nuage.restart()
