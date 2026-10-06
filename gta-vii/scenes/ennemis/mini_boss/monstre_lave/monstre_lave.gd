extends "res://scenes/ennemis/mobiles/demolisseur/demolisseur.gd"

# Réutiliser la navigation, le gel, les dégâts reçus et les mouvements du golem.
@export_group("Mini-boss — coup au sol")
@export var rayon_impact := 3.4
@export var degats_impact := 30.0
@export_group("Mini-boss — salve")
@export var portee_salve := 14.0
@export var preparation_salve := 0.5
@export_range(1, 12, 1) var boules_par_salve := 12
@export_range(0.1, 1.0, 0.05) var intervalle_boules := 0.1
@export var vitesse_boules := 10.0
@export var degats_boules := 12.0
@export var repos_salve := 0.9

const PROJECTILE = preload("res://scenes/ennemis/mobiles/artilleur/projectile_artilleur.tscn")
var boules_restantes := 0
var taille_orbe := Vector3.ONE
@onready var orbe: MeshInstance3D = $Orbe
@onready var titre: Label3D = $Titre

func _ready() -> void:
	super._ready()
	hitbox_radius = $CollisionShape3D.shape.radius
	# Adapter le disque à la vraie zone de dégâts, plutôt qu'à une taille arbitraire.
	var disque: CylinderMesh = zone.mesh.duplicate()
	disque.top_radius = rayon_impact
	disque.bottom_radius = rayon_impact
	zone.mesh = disque
	taille_orbe = orbe.scale
	orbe.hide()
	_actualiser_vie()
	# Reprendre le repère de l’artilleur, uniquement pendant la charge de la salve.
	var annonce = preload("res://scenes/effets/combat/alerte_artilleur.gd").new()
	annonce.etat_preparation = "preparation_salve"
	annonce.propriete_duree = "preparation_salve"
	add_child(annonce)

func choisir_cible() -> void:
	# Le mini-boss poursuit le joueur ; les victimes peuvent subir ses attaques de zone.
	cible = player if is_instance_valid(player) and not player.est_mort else null

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
	var direction: Vector3 = cible.global_position - global_position
	rotation.y = atan2(direction.x, direction.z)
	if _distance_au_bord(cible) <= rayon_impact and _voie_libre(cible):
		velocity = Vector3.ZERO
		if cooldown_frappe <= 0.0: _preparer_coup(direction.normalized())
	elif _distance_au_bord(cible) <= portee_salve and _voie_libre(cible) and cooldown_frappe <= 0.0:
		_preparer_salve()
	else:
		_suivre_cible()

func _preparer_coup(direction: Vector3) -> void:
	super._preparer_coup(direction)
	velocity = Vector3.ZERO
	# L'attaque touche autour du boss : garder le disque centré sur lui, au sol.
	zone.global_position = global_position - Vector3.UP * 1.325

func _frapper() -> void:
	# Les dégâts arrivent une seule fois à l'impact. Sortir du disque permet d'esquiver.
	for corps in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("victime"):
		if not is_instance_valid(corps) or corps.is_queued_for_deletion(): continue
		if not corps.has_method("prendre_degats"): continue
		if _distance_au_bord(corps) <= rayon_impact and _voie_libre(corps):
			corps.prendre_degats(degats_impact * (1.0 + maxi(etage - 1, 0) * degats_par_etage_pourcent / 100.0))
	cooldown_frappe = delai_frappe
	etat = "repos"
	temps_etat = repos_frappe
	if animation_frappe: animation_frappe.kill()
	animation_frappe = create_tween().set_parallel(true)
	# Redresser le corps et retrouver sa taille ensemble, après l'écrasement de l'impact.
	animation_frappe.tween_property(visuel, "rotation:x", 0.0, repos_frappe).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation_frappe.tween_property(visuel, "scale", taille_visuel, repos_frappe)
	if animation_zone: animation_zone.kill()
	animation_zone = create_tween()
	animation_zone.tween_property(materiau_zone, "albedo_color:a", 0.0, 0.25)
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
	# Faire grossir le feu et relever le corps annonce la salve avant le premier tir.
	animation_frappe.tween_property(orbe, "scale", taille_orbe, preparation_salve)
	animation_frappe.tween_property(visuel, "rotation:x", -0.12, preparation_salve)

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
	# Chaque boule vise la position actuelle, puis garde une trajectoire rectiligne.
	boules_restantes -= 1
	temps_etat = intervalle_boules
	if boules_restantes <= 0: _terminer_salve()

func _terminer_salve() -> void:
	orbe.hide()
	etat = "repos"
	temps_etat = repos_salve
	cooldown_frappe = delai_frappe
	if animation_frappe: animation_frappe.kill()
	animation_frappe = create_tween()
	animation_frappe.tween_property(visuel, "rotation:x", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func prendre_degats(degats: float, source: StringName = &"feu") -> void:
	super.prendre_degats(degats, source)
	if not est_mort: _actualiser_vie()

func _actualiser_vie() -> void:
	titre.text = "MONSTRE DE LAVE
%d / %d PV" % [ceili(vie), ceili(vie_max)]

func mourir() -> void:
	orbe.hide()
	super.mourir()
