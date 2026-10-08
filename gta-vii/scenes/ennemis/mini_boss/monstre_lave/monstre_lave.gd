extends "res://scenes/ennemis/mobiles/demolisseur/demolisseur.gd"

signal impact_sol
signal charge_salve
signal boule_projetee
signal salve_terminee
signal mort_mise_en_scene(effet: Node3D)

# Réutiliser la navigation, le gel, les dégâts reçus et les mouvements du golem.
@export_group("Mini-boss — coup au sol")
@export_range(0.5, 3.0, 0.01) var hauteur_corps_au_sol := 1.35
@export var rayon_impact := 3.4
@export var degats_impact := 30.0
@export_range(0.0, 3.0, 0.1) var avance_saut := 0.9
@export_range(-1.0, 1.0, 0.1) var decalage_impact := 0.0
@export var couleur_annonce := Color(1.0, 0.28, 0.035)
@export_range(0.01, 0.15, 0.005) var hauteur_annonce_sol := 0.035
@export_range(0.0, 1.0, 0.01) var force_secousse_impact := 0.3
@export_range(0.05, 1.0, 0.05) var duree_secousse_impact := 0.25
@export_group("Mini-boss — salve")
@export var portee_salve := 14.0
@export var preparation_salve := 0.5
@export_range(1, 12, 1) var boules_par_salve := 12
@export_range(0.1, 1.0, 0.05) var intervalle_boules := 0.1
@export var vitesse_boules := 10.0
@export var degats_boules := 12.0
@export var repos_salve := 0.9
@export_range(1.0, 12.0, 0.1) var delai_apres_salve := 3.0

@export_group("Présentation du boss")
@export var nom_boss := "Le Cœur du Brasier"
@export var interface_boss: PackedScene = preload("res://scenes/interfaces/hud/barre_boss.tscn")
@export var effet_mort: PackedScene = preload("res://scenes/ennemis/mini_boss/monstre_lave/mort_boss.tscn")

const PROJECTILE = preload("res://scenes/ennemis/mobiles/artilleur/projectile_artilleur.tscn")
var cooldown_salve := 0.0
var frappe_fissure := false
var prochaine_distance_fissure := true
var boules_restantes := 0
var taille_orbe := Vector3.ONE
var depart_saut := Vector3.ZERO
var reception_saut := Vector3.ZERO
var centre_impact := Vector3.ZERO
var annonce_impact: ShaderMaterial
@onready var phase = $PhaseBoss
@onready var invocations = $InvocationBoss
@onready var fissure = $FissureBoss
@onready var orbe: MeshInstance3D = $Orbe
@onready var titre: Label3D = $Titre

func _ready() -> void:
	super._ready()
	hitbox_radius = $CollisionShape3D.shape.radius
	# Le nœud existant garde sa visibilité ; un plan dessine maintenant l'annonce.
	zone.mesh = null
	var surface_annonce := MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = Vector2.ONE * rayon_impact * 2.0
	surface_annonce.mesh = plan
	surface_annonce.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	annonce_impact = ShaderMaterial.new()
	annonce_impact.shader = preload("res://assets/shaders/effets/annonce_impact_boss.gdshader")
	annonce_impact.set_shader_parameter("couleur", couleur_annonce)
	surface_annonce.material_override = annonce_impact
	zone.add_child(surface_annonce)
	taille_orbe = orbe.scale
	orbe.hide()
	_actualiser_vie()
	if interface_boss:
		var interface = interface_boss.instantiate()
		var conteneur: Node = get_tree().current_scene if get_tree().current_scene != null else get_parent()
		conteneur.add_child(interface)
		interface.suivre(self)
	# Reprendre le repère de l’artilleur, uniquement pendant la charge de la salve.
	var annonce = preload("res://scenes/effets/combat/alerte_artilleur.gd").new()
	annonce.etat_preparation = "preparation_salve"
	annonce.propriete_duree = "preparation_salve"
	add_child(annonce)

func choisir_cible() -> void:
	# Le mini-boss poursuit le joueur ; les victimes peuvent subir ses attaques de zone.
	cible = player if is_instance_valid(player) and not player.est_mort else null

func _physics_process(delta: float) -> void:
	if not est_mort:
		_recaler_au_sol()
	# Le gel profond suspend aussi la préparation des attaques, pas seulement la marche.
	if est_gele() or subit_recul():
		velocity = Vector3.ZERO
		return
	if est_mort: return
	invocations.avancer(delta)
	cooldown_frappe = maxf(0.0, cooldown_frappe - delta)
	cooldown_salve = maxf(0.0, cooldown_salve - delta)
	temps_etat -= delta
	if etat in ["preparation", "frappe"]:
		_avancer_saut()
	if etat == "colere":
		phase.avancer_colere()
		if temps_etat <= 0.0:
			if not invocations.positions.is_empty(): invocations.terminer()
			etat = "repos"
			temps_etat = invocations.recuperation
		return
	if etat == "invocation":
		if temps_etat <= 0.0:
			invocations.terminer()
			etat = "repos"
			temps_etat = invocations.recuperation
		return
	if etat == "preparation":
		if temps_etat <= 0.0: _lancer_coup()
		return
	if etat == "frappe":
		if temps_etat <= 0.0: _frapper()
		return
	if etat == "repos":
		if temps_etat <= 0.0: etat = "marche"
		return
	if etat == "preparation_salve" or etat == "salve":
		if not is_instance_valid(cible_attaque) or cible_attaque.is_queued_for_deletion() or cible_attaque.est_mort:
			_terminer_salve()
			return
		var direction: Vector3 = cible_attaque.global_position - global_position
		rotation.y = atan2(direction.x, direction.z)
		if temps_etat <= 0.0:
			if etat == "preparation_salve":
				etat = "salve"
				boules_restantes = maxi(1, boules_par_salve)
			_tirer_boule()
		return
	choisir_cible()
	if not is_instance_valid(cible): return
	if phase.commencer():
		etat = "colere"
		temps_etat = phase.duree_colere
		velocity = Vector3.ZERO
		return
	if invocations.commencer():
		etat = "invocation"
		temps_etat = invocations.preparation
		velocity = Vector3.ZERO
		return
	var direction: Vector3 = cible.global_position - global_position
	rotation.y = atan2(direction.x, direction.z)
	if _distance_au_bord(cible) <= rayon_impact and _voie_libre(cible):
		velocity = Vector3.ZERO
		if cooldown_frappe <= 0.0:
			frappe_fissure = false
			_preparer_coup(direction.normalized())
	elif _distance_au_bord(cible) <= fissure.portee and _voie_libre(cible) and cooldown_frappe <= 0.0 and fissure.disponible() and (prochaine_distance_fissure or cooldown_salve > 0.0):
		# Alterner les attaques à distance, en réutilisant le geste de frappe existant.
		frappe_fissure = true
		prochaine_distance_fissure = false
		_preparer_coup(direction.normalized())
		fissure.preparer(zone.global_position, direction_frappe)
		zone.hide()
	elif _distance_au_bord(cible) <= portee_salve and _voie_libre(cible) and cooldown_frappe <= 0.0 and cooldown_salve <= 0.0:
		prochaine_distance_fissure = true
		_preparer_salve()
	else:
		_suivre_cible()

func _recaler_au_sol() -> void:
	# Le boss ne saute pas physiquement : ne pas conserver une hauteur issue d'un chevauchement.
	var rayon := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, global_position - Vector3.UP * 6.0, 1)
	rayon.exclude = [get_rid()]
	var sol := get_world_3d().direct_space_state.intersect_ray(rayon)
	if not sol.is_empty() and sol.normal.y > 0.7:
		global_position.y = sol.position.y + hauteur_corps_au_sol

func _preparer_coup(direction: Vector3) -> void:
	# La différence de hauteur avec la cible ne doit pas faire monter le corps.
	direction.y = 0.0
	direction = direction.normalized()
	etat = "preparation"
	temps_etat = preparation_frappe
	cible_attaque = cible
	direction_frappe = direction
	velocity = Vector3.ZERO
	depart_saut = global_position
	var trajet := direction * (0.0 if frappe_fissure else avance_saut)
	# Tester avec la collision au sol avant le décollage, pour ne pas traverser le décor.
	var obstacle := KinematicCollision3D.new()
	if test_move(global_transform, trajet, obstacle):
		trajet = obstacle.get_travel()
	reception_saut = depart_saut + trajet
	centre_impact = reception_saut + global_basis * $AnimationsBoss.impact_local + direction * decalage_impact
	# L'annonce reste à la réception prévue, pas sous les pieds pendant le saut.
	# Chercher la surface réelle : la hauteur du corps peut varier après une collision.
	var rayon_sol := PhysicsRayQueryParameters3D.create(centre_impact + Vector3.UP, centre_impact - Vector3.UP * 5.0, 1)
	rayon_sol.exclude = [get_rid()]
	var sol := get_world_3d().direct_space_state.intersect_ray(rayon_sol)
	var hauteur_sol: float = sol.position.y if not sol.is_empty() else centre_impact.y - 1.35
	zone.global_position = Vector3(centre_impact.x, hauteur_sol + hauteur_annonce_sol, centre_impact.z)
	zone.scale = Vector3.ONE
	# Annuler l'ancien fondu avant de réafficher, y compris son callback hide().
	if animation_zone: animation_zone.kill()
	annonce_impact.set_shader_parameter("charge", 0.0)
	annonce_impact.set_shader_parameter("opacite", 1.0)
	zone.show()

func _avancer_saut() -> void:
	var gestes = $AnimationsBoss
	# La charge suit le combat, et s'arrête aussi si le boss est gelé.
	var temps_restant := temps_etat + duree_coup if etat == "preparation" else temps_etat
	annonce_impact.set_shader_parameter("charge", clampf(1.0 - temps_restant / maxf(preparation_frappe + duree_coup, 0.01), 0.0, 1.0))
	var instant: float
	if etat == "preparation":
		instant = lerpf(0.0, gestes.debut_descente, 1.0 - clampf(temps_etat / preparation_frappe, 0.0, 1.0))
	else:
		instant = lerpf(gestes.debut_descente, gestes.instant_impact, 1.0 - clampf(temps_etat / duree_coup, 0.0, 1.0))
	var progression := clampf((instant - gestes.instant_decollage) / maxf(gestes.instant_impact - gestes.instant_decollage, 0.01), 0.0, 1.0)
	# L'avancée ralentit vers la réception et respecte les collisions pendant le vol.
	var destination := depart_saut.lerp(reception_saut, smoothstep(0.0, 1.0, progression))
	var mouvement := destination - global_position
	mouvement.y = 0.0
	move_and_collide(mouvement)
	_recaler_au_sol()

func _lancer_coup() -> void:
	# Le squelette joue la descente ; les dégâts restent appliqués une fois à son impact.
	etat = "frappe"
	temps_etat = duree_coup

func _frapper() -> void:
	impact_sol.emit()
	# La réception secoue la caméra, même si le joueur esquive la zone de dégâts.
	if is_instance_valid(player) and player.has_method("secouer_camera"):
		player.secouer_camera(force_secousse_impact, duree_secousse_impact)
	# Les dégâts arrivent une seule fois à l'impact. Sortir du disque permet d'esquiver.
	if frappe_fissure:
		fissure.lancer()
	# La fissure remplace les dégâts circulaires : pas de double attaque à l'impact.
	var cibles: Array = [] if frappe_fissure else get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("victime")
	for corps in cibles:
		if not is_instance_valid(corps) or corps.is_queued_for_deletion(): continue
		if not corps.has_method("prendre_degats"): continue
		var ecart: Vector3 = corps.global_position - centre_impact
		ecart.y = 0.0
		if ecart.length() <= rayon_impact and _voie_libre(corps):
			corps.prendre_degats(degats_impact * (1.0 + maxi(etage - 1, 0) * degats_par_etage_pourcent / 100.0))
	cooldown_frappe = phase.delai(delai_frappe)
	etat = "repos"
	temps_etat = repos_frappe
	# AnimationsBoss joue le redressement du squelette pendant ce repos.
	if animation_zone: animation_zone.kill()
	animation_zone = create_tween()
	animation_zone.tween_method(func(valeur: float): annonce_impact.set_shader_parameter("opacite", valeur), 1.0, 0.0, 0.25)
	animation_zone.tween_callback(zone.hide)

func _preparer_salve() -> void:
	etat = "preparation_salve"
	temps_etat = preparation_salve
	cible_attaque = cible
	velocity = Vector3.ZERO
	orbe.scale = taille_orbe * 0.3
	orbe.show()
	if animation_frappe: animation_frappe.kill()
	animation_frappe = create_tween().set_parallel(true)
	# Le feu grandit entre les mains ; AnimationsBoss joue l'incantation.
	animation_frappe.tween_property(orbe, "scale", taille_orbe, preparation_salve)
	charge_salve.emit()

func _tirer_boule() -> void:
	var projectile = PROJECTILE.instantiate()
	projectile.direction = orbe.global_position.direction_to(cible_attaque.global_position)
	projectile.vitesse = vitesse_boules
	projectile.degats = degats_boules * (1.0 + maxi(etage - 1, 0) * degats_par_etage_pourcent / 100.0)
	projectile.tireur = self
	projectile.scale = Vector3.ONE * 1.4
	var salle := get_parent().get_parent()
	var conteneur := salle.get_node_or_null("ProjectilesTour")
	if conteneur == null: conteneur = salle
	projectile.position = conteneur.to_local(orbe.global_position)
	conteneur.add_child(projectile)
	boule_projetee.emit()
	# Chaque boule vise la position actuelle, puis garde une trajectoire rectiligne.
	boules_restantes -= 1
	temps_etat = intervalle_boules
	if boules_restantes <= 0: _terminer_salve()

func _terminer_salve() -> void:
	# Bloquer uniquement la prochaine salve : la marche et le coup au sol restent possibles.
	cooldown_salve = phase.delai(delai_apres_salve)
	salve_terminee.emit()
	orbe.hide()
	etat = "repos"
	temps_etat = repos_salve
	cooldown_frappe = phase.delai(delai_frappe)
	if animation_frappe: animation_frappe.kill()

func prendre_degats(degats: float, source: StringName = &"feu") -> void:
	super.prendre_degats(degats, source)
	if not est_mort: _actualiser_vie()

func _actualiser_vie() -> void:
	# Les PV sont désormais présentés dans le HUD, sans texte flottant sur le modèle.
	titre.hide()

func mourir() -> void:
	if est_mort: return
	orbe.hide()
	if effet_mort:
		var effet = effet_mort.instantiate()
		get_parent().add_child(effet)
		effet.global_transform = global_transform
		# Une mort en plein saut repart au sol, sans garder le décalage du vol.
		$Sketchfab_Scene.position.y = $AnimationsBoss.hauteur_visuel
		$AnimationsBoss.set_physics_process(false)
		effet.commencer($Sketchfab_Scene)
		set_meta("delai_butin", effet.duree_chute * effet.moment_choc)
		set_meta("rayon_butin", effet.rayon_butin)
		mort_mise_en_scene.emit(effet)
		# Le parent peut encore accéder à ce nœud pendant mourir(), donc garder un repère vide.
		var repere := Node3D.new()
		repere.name = "Sketchfab_Scene"
		add_child(repere)
		afficher_cendres = false
	# Le signal died et les récompenses restent immédiats ; seule la mise en scène dure.
	invocations.eliminer_invocations()
	super.mourir()
