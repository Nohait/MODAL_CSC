extends Node

# Les cartes sont des données ; ce composant orchestre leurs interactions.
@export_range(0.1, 5.0, 0.1) var intervalle_ondes := 1.6
@export_range(0.1, 1.0, 0.05) var puissance_ondes := 0.35
@export_range(0.1, 1.0, 0.05) var puissance_double := 0.65
@export_range(0.1, 1.0, 0.05) var delai_retour := 0.8
@export_range(0.1, 1.0, 0.05) var paralysie := 0.35
@export_range(0.1, 1.0, 0.05) var paralysie_boss := 0.15
@export_range(0.1, 1.0, 0.05) var charge_par_seconde := 0.4
@export_range(0.1, 5.0, 0.1) var prolongation_maximale := 2.0
@export_range(0.1, 2.0, 0.1) var decalage_double := 0.6
@export_range(1.0, 5.0, 0.1) var distance_point_appui := 3.0
@export var son_electricite: AudioStream = preload("res://assets/sounds/bouche_incendie/electricite.wav")
@export var son_impact: AudioStream = preload("res://assets/sounds/bouche_incendie/impact.wav")
@export_range(-40.0, -10.0, 1.0) var volume_electricite_db := -29.0
@export_group("Présentation")
@export var scene_presentation: PackedScene = preload("res://scenes/armes/bouche_incendie/presentation_bouche.tscn")
var presentations: Array[Node3D] = []
var attaque: Node3D #
var prochaine_onde := 0.0
var retours: Array[Dictionary] = []
var final_lance := false
var dash_precedent := false
var appui_utilise := false
var charge := 0.0
var prolongation := 0.0
var double_corps: StaticBody3D
var double_cible := Vector3.ZERO
var double_pose := false
var arcs: Node3D
var lecteur: AudioStreamPlayer3D
var zone: Node3D

func _ready() -> void:
	attaque = get_parent()

func valeur(id: StringName) -> float:
	if not is_instance_valid(attaque.joueur.ameliorations): return 0.0
	return attaque.joueur.ameliorations.effets_cartes.valeur(id)

func definition(id: StringName) -> Amelioration:
	return attaque.joueur.ameliorations.catalogue_ameliorations.trouver(id)

func rayon() -> float:
	return attaque.rayon * (1.0 + valeur(&"hydrant_zone") / 100.0)

func portee() -> float:
	var resultat: float = attaque.portee * (1.0 + valeur(&"hydrant_distance") / 100.0)
	if valeur(&"hydrant_fonte") > 0: resultat *= 1.0 - definition(&"hydrant_fonte").contrepartie / 100.0
	return resultat

func chute() -> float:
	return attaque.duree_chute * (1.0 - valeur(&"hydrant_express") / 100.0)

func presence() -> float:
	return maxf(1.0, attaque.duree_presence + valeur(&"hydrant_robinet") - valeur(&"hydrant_demontage")) + prolongation

func puissance() -> float:
	var resultat := 1.0 + valeur(&"hydrant_fonte") / 100.0
	if valeur(&"hydrant_distance") > 0: resultat *= 1.0 - definition(&"hydrant_distance").contrepartie / 100.0
	if valeur(&"hydrant_electrique") > 0: resultat *= 1.0 + valeur(&"hydrant_electrique") / 100.0
	if is_instance_valid(double_corps): resultat *= puissance_double
	return resultat

func lancer() -> void:
	retours.clear()
	final_lance = false
	appui_utilise = false
	charge = 0.0
	prolongation = 0.0
	dash_precedent = attaque.joueur.is_dashing
	if valeur(&"hydrant_double") > 0: _creer_double()

func atterrir() -> void:
	var son_impact_player = AudioStreamPlayer3D.new()
	son_impact_player.stream = son_impact
	attaque.add_child(son_impact_player)
	son_impact_player.play()
	
	prochaine_onde = intervalle_ondes
	_installer_presentation(attaque.corps, attaque.dessin)
	onde(attaque.cible, 1.0, false, false)
	if valeur(&"hydrant_perimetre") > 0:
		var effets = attaque.joueur.ameliorations.effets_cartes
		var glace := valeur(&"hydrant_patinoire") > 0
		zone = effets.creer_zone(attaque.cible, "eau", 0.0, rayon(), presence(), 40.0 if glace else 0.0)
		zone.ralentissement_eau = valeur(&"hydrant_perimetre")
		zone.gele_progressivement = glace
		zone.obstacles_exclus.append(attaque.corps.get_rid())
		if is_instance_valid(double_corps): zone.obstacles_exclus.append(double_corps.get_rid())
	if valeur(&"hydrant_electrique") > 0:
		arcs = preload("res://scenes/armes/bouche_incendie/arcs_electriques.gd").new()
		arcs.rayon = 0.5
		arcs.hauteur = attaque.hauteur_modele
		attaque.corps.add_child(arcs)
		lecteur = AudioStreamPlayer3D.new()
		lecteur.stream = son_electricite
		lecteur.bus = &"Effets"
		lecteur.volume_db = volume_electricite_db
		lecteur.unit_size = 3.0
		lecteur.max_distance = 14.0
		attaque.corps.add_child(lecteur)
		lecteur.position.y = 0.6
		lecteur.finished.connect(lecteur.play)
		lecteur.play()

func avancer(delta: float) -> void:
	_actualiser_double()
	if attaque.phase == "chute":
		if valeur(&"hydrant_patiente") > 0:
			for ennemi in _ennemis(attaque.cible):
				if ennemi.has_method("appliquer_gel"): ennemi.appliquer_gel(valeur(&"hydrant_patiente"), 0.2)
		return
	if attaque.phase != "presence": return
	if valeur(&"hydrant_fuite") > 0 and attaque.temps >= prochaine_onde:
		prochaine_onde += intervalle_ondes
		onde(attaque.cible, puissance_ondes * (1.0 + charge), false, true)
		if double_pose: onde(double_cible, puissance_ondes * (1.0 + charge), false, true)
		charge = 0.0
	for i in range(retours.size() - 1, -1, -1):
		retours[i].attente -= delta
		if retours[i].attente <= 0.0:
			onde(retours[i].position, 1.0 if retours[i].final else puissance_ondes, not retours[i].final, true)
			retours.remove_at(i)
	var extinction: float = presence() - maxf(attaque.duree_avertissement, delai_retour + 0.1)
	if valeur(&"hydrant_final") > 0 and not final_lance and attaque.temps >= extinction:
		final_lance = true
		if valeur(&"hydrant_essorage") > 0:
			onde(attaque.cible, puissance_ondes, true, true)
			retours.append({"attente": delai_retour, "position": attaque.cible, "final": true})
		else:
			onde(attaque.cible, 1.0, false, true)
	var dash: bool = attaque.joueur.is_dashing
	if dash and not dash_precedent and not appui_utilise and valeur(&"hydrant_appui") > 0:
		if attaque.joueur.global_position.distance_to(attaque.cible) <= distance_point_appui:
			var extincteur = attaque.joueur.extincteur
			extincteur.charge = minf(extincteur.max_charge, extincteur.charge + extincteur.max_charge * valeur(&"hydrant_appui") / 100.0)
			appui_utilise = true
	dash_precedent = dash
	if valeur(&"hydrant_raccord") > 0:
		var extincteur = attaque.joueur.extincteur
		if extincteur.emission_effective and extincteur.cible_dans_jet(attaque.cible, attaque.rayon_collision):
			var ray := PhysicsRayQueryParameters3D.create(extincteur.muzzle.global_position, attaque.cible + Vector3.UP * 0.5, attaque.masque_decor)
			ray.exclude = [attaque.corps.get_rid()]
			if attaque.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
				charge = minf(1.0, charge + delta * charge_par_seconde)
				if valeur(&"hydrant_circuit") > 0 and not final_lance:
					prolongation = minf(prolongation_maximale, prolongation + delta * charge_par_seconde)
	if is_instance_valid(zone): zone.duree = presence()
	if is_instance_valid(arcs): arcs.actualiser(0.5, attaque.hauteur_modele)
	for presentation in presentations:
		if not is_instance_valid(presentation): continue
		var anticipation := 0.0
		if valeur(&"hydrant_fuite") > 0:
			anticipation = clampf(1.0 - (prochaine_onde - attaque.temps) / presentation.duree_preparation, 0.0, 1.0)
		if valeur(&"hydrant_final") > 0 and not final_lance:
			anticipation = maxf(anticipation, clampf(1.0 - (extinction - attaque.temps) / presentation.duree_preparation, 0.0, 1.0))
		for retour in retours:
			if retour.final: anticipation = maxf(anticipation, clampf(1.0 - retour.attente / presentation.duree_preparation, 0.0, 1.0))
		presentation.actualiser(anticipation, charge)
	if is_instance_valid(lecteur):
		var fondu := clampf((presence() - attaque.temps) / attaque.duree_fondu_final, 0.001, 1.0)
		lecteur.volume_db = volume_electricite_db + linear_to_db(fondu)

func _ennemis(position: Vector3) -> Array[Node3D]:
	var resultat: Array[Node3D] = []
	for ennemi in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(ennemi) or not ennemi is Node3D or ennemi.is_queued_for_deletion(): continue
		if ennemi.get("est_mort") == true or not ennemi.has_method("prendre_degats"): continue
		if not attaque.salle_depart.is_ancestor_of(ennemi): continue
		var direction: Vector3 = ennemi.global_position - position
		direction.y = 0.0
		if direction.length() > rayon(): continue
		var ray := PhysicsRayQueryParameters3D.create(position + Vector3.UP * 0.6, ennemi.global_position + Vector3.UP * 0.6, attaque.masque_decor)
		ray.exclude = [attaque.corps.get_rid()]
		if is_instance_valid(double_corps): ray.exclude = [attaque.corps.get_rid(), double_corps.get_rid()]
		if attaque.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): resultat.append(ennemi)
	return resultat

func onde(position: Vector3, facteur: float, retour: bool, visuel: bool) -> void:
	var electrique := valeur(&"hydrant_electrique") > 0
	for presentation in presentations:
		if is_instance_valid(presentation) and presentation.global_position.distance_squared_to(position) < 0.1:
			presentation.relacher(1.0 + charge, retour)
	var effets = attaque.joueur.ameliorations.effets_cartes
	for ennemi in _ennemis(position):
		effets.infliger(ennemi, attaque.degats * puissance() * facteur, &"eau")
		if not is_instance_valid(ennemi) or ennemi.get("est_mort") == true: continue
		var statut = effets.etat(ennemi)
		if electrique:
			statut.recul_restant = 0.0
			statut.degats_collision = 0.0
			statut.paralysie_restant = maxf(statut.paralysie_restant, paralysie_boss if ennemi.has_node("AnimationsBoss") else paralysie)
		else:
			var direction: Vector3 = ennemi.global_position - position
			direction.y = 0.0
			if direction.length_squared() < 0.001: direction = attaque.joueur.last_direction
			if retour: direction = -direction
			statut.repousser(direction, attaque.force_recul, attaque.duree_recul, true)
			if valeur(&"hydrant_belier") > 0: statut.degats_collision = valeur(&"hydrant_belier")
	if visuel: _dessiner_onde(position, retour, electrique)
	if not retour and valeur(&"hydrant_retour") > 0 and not final_lance:
		retours.append({"attente": delai_retour, "position": position, "final": false})

func _dessiner_onde(position: Vector3, retour: bool, electrique: bool) -> void:
	var couronne = preload("res://scenes/armes/bouche_incendie/couronne_eau.tscn").instantiate()
	couronne.rayon = rayon()
	couronne.hauteur = attaque.hauteur_couronne_eau * (1.0 + charge * 0.35)
	couronne.duree = attaque.duree_onde
	couronne.retour = retour
	couronne.position = attaque.salle_depart.to_local(position)
	attaque.salle_depart.add_child(couronne)
	if electrique:
		var effet = preload("res://scenes/armes/bouche_incendie/arcs_electriques.gd").new()
		effet.onde = true
		effet.rayon = rayon()
		effet.duree = attaque.duree_onde
		couronne.add_child(effet)
	attaque._jouer_son_impact(attaque.son_eau, attaque.volume_eau_db - 5.0)

func _creer_double() -> void:
	# La seconde bouche ne doit jamais tomber dans un trou ou dans un obstacle.
	var espace := attaque.get_world_3d().direct_space_state
	for axe in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var point: Vector3 = attaque.cible + axe * (attaque.rayon_collision * 2.0 + 0.4)
		var sol := espace.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0, point - Vector3.UP * 2.0, attaque.masque_decor))
		if sol.is_empty() or sol.normal.y < 0.8: continue
		var forme := CylinderShape3D.new()
		forme.radius = attaque.rayon_collision
		forme.height = attaque.hauteur_modele
		var test := PhysicsShapeQueryParameters3D.new()
		test.shape = forme
		test.transform.origin = sol.position + Vector3.UP * (forme.height / 2.0 + 0.05)
		test.collision_mask = attaque.masque_decor | 2
		if not espace.intersect_shape(test, 1).is_empty(): continue
		double_cible = sol.position
		double_corps = StaticBody3D.new()
		double_corps.top_level = true
		double_corps.collision_layer = 0
		attaque.corps.add_child(double_corps)
		var modele: Node3D = attaque.dessin.duplicate()
		double_corps.add_child(modele)
		# La pression de chaque bouche anime ses matériaux propres.
		for surface in modele.find_children("*", "MeshInstance3D", true, false):
			for i in range(surface.mesh.get_surface_count()):
				var mat = surface.get_active_material(i)
				if mat != null: surface.set_surface_override_material(i, mat.duplicate())
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		collision.shape = forme
		collision.position.y = forme.height / 2.0
		double_corps.add_child(collision)
		double_pose = false
		double_corps.global_position = double_cible + Vector3.UP * attaque.hauteur_chute
		return

func _actualiser_double() -> void:
	if not is_instance_valid(double_corps) or double_pose: return
	var temps_total: float = attaque.temps if attaque.phase == "chute" else chute() + attaque.temps
	var p := clampf((temps_total - decalage_double) / chute(), 0.0, 1.0)
	double_corps.global_position = double_cible + Vector3.UP * attaque.hauteur_chute * (1.0 - p * p)
	if p < 1.0: return
	double_pose = true
	double_corps.collision_layer = 1
	double_corps.add_to_group("obstacles_navigation")
	double_corps.set_meta("salle_navigation", attaque.salle_depart)
	attaque.salle_depart.demander_navigation()
	_installer_presentation(double_corps, double_corps.get_child(0))
	onde(double_cible, 1.0, false, true)
	attaque._jouer_son_impact(attaque.son_impact, attaque.volume_impact_db - 3.0)

func _installer_presentation(corps: Node3D, modele: Node3D) -> void:
	var presentation: Node3D = scene_presentation.instantiate()
	presentation.configurer(modele, attaque.hauteur_modele, valeur(&"hydrant_fuite") > 0, valeur(&"hydrant_patinoire") > 0, valeur(&"hydrant_raccord") > 0)
	if not attaque.materiaux_modele.is_empty(): presentation.materiau_fondu = attaque.materiaux_modele[0]
	corps.add_child(presentation)
	presentations.append(presentation)

func terminer() -> void:
	presentations.clear()
	retours.clear()
	if is_instance_valid(zone): zone.queue_free()
	if is_instance_valid(double_corps): double_corps.remove_from_group("obstacles_navigation")
	double_corps = null
	double_pose = false
	prolongation = 0.0
