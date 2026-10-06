extends Node

const ETAT = preload("res://scenes/systemes/ameliorations/etat_mousse.gd")
const ZONE = preload("res://scenes/systemes/ameliorations/zone_mousse.gd")
const VAPEUR = preload("res://scenes/effets/combat/impact_mousse.tscn")
var gestion: Node
var joueur: CharacterBody3D
var depuis_dash := 100.0
var etait_dash := false
var derniere_position := Vector3.ZERO
var derniere_trace := Vector3.ZERO
var touches_dash: Dictionary = {}
var courage_restant := 0.0
var protection_restant := 0.0
var position_abri := Vector3.ZERO
var attente_zone := 0.0
var attente_equipe := 0.0
var reseau_restant := 0.0
var dernier_sprinkler: Node3D
var victimes_bouclier: Dictionary = {}
var prochaine_protection: Dictionary = {}
var temps_ecoule := 0.0
var attente_trace := 0.0
var maximum_zones := 40
const ONDE_DEBLAYAGE = preload("res://scenes/effets/combat/onde_deblayage.gd")
const TRACE = preload("res://scenes/effets/combat/trace_combat.gd")

func _ready() -> void:
	joueur = get_parent()
	process_physics_priority = 1
	derniere_position = joueur.global_position
	gestion.escorte.escort_changed.connect(_suivre_victimes)
	_suivre_victimes()

func reinitialiser_etape() -> void:
	depuis_dash = 100.0
	etait_dash = false
	derniere_position = joueur.global_position
	attente_zone = 0.0

func valeur(id: StringName) -> float:
	return gestion.effets_actifs.get(id, 0.0)

func visible_depuis(position: Vector3, cible: Node3D) -> bool:
	if not is_instance_valid(cible) or cible.is_queued_for_deletion(): return false
	var requete := PhysicsRayQueryParameters3D.create(position, cible.global_position + Vector3.UP, 1)
	return joueur.get_world_3d().direct_space_state.intersect_ray(requete).is_empty()

func ennemis_proches(position: Vector3, rayon: float) -> Array[Node3D]:
	var resultat: Array[Node3D] = []
	for ennemi in get_tree().get_nodes_in_group("enemies"):
		if not ennemi is Node3D or not ennemi.has_method("prendre_degats") or ennemi.is_queued_for_deletion(): continue
		# Une explosion ne doit jamais affecter une salle préparée à l'avance.
		if not gestion.room_manager.salle_actuelle.is_ancestor_of(ennemi): continue
		if ennemi.get("est_mort") == true: continue
		if ennemi.global_position.distance_to(position) <= rayon and visible_depuis(position + Vector3.UP, ennemi):
			resultat.append(ennemi)
	return resultat

func etat(ennemi: Node3D) -> Node:
	var actuel := ennemi.get_node_or_null("EtatMousse")
	if actuel == null:
		actuel = ETAT.new()
		actuel.name = "EtatMousse"
		actuel.effets = self
		ennemi.add_child(actuel)
	return actuel

func infliger(ennemi: Node3D, degats: float, source: StringName = &"mousse") -> void:
	if not is_instance_valid(ennemi) or ennemi.is_queued_for_deletion(): return
	if ennemi.get("est_mort") == true: return
	etat(ennemi)
	ennemi.prendre_degats(degats, source)

func toucher_jet(ennemi: Node3D, delta: float) -> void:
	etat(ennemi).toucher_jet(delta)
	if is_instance_valid(gestion.branches_zombie): gestion.branches_zombie.toucher(ennemi, delta)

func modifier_degats(ennemi: Node3D, source: StringName) -> float:
	var facteur := 1.0
	if is_instance_valid(gestion.branches_zombie): facteur *= gestion.branches_zombie.multiplicateur_cible(ennemi)
	var statut := ennemi.get_node_or_null("EtatMousse")
	if statut != null: facteur *= statut.multiplier_degats(source)
	if valeur("gyrophare_intervention") > 0 and gestion.mode_jeu == "zombie":
		var refuge = gestion.room_manager.refuge
		if is_instance_valid(refuge) and refuge.attire(ennemi): facteur *= 1.0 + valeur("gyrophare_intervention") / 100.0
	return facteur

func multiplicateur_jet() -> float:
	var facteur: float = 1.0 + valeur("surpression") / 100.0 * gestion.extincteur.charge / gestion.extincteur.max_charge
	if depuis_dash <= 1.5: facteur *= 1.0 + valeur("depart_pression") / 100.0
	if valeur("jet_pulse") > 0: facteur *= 1.0 + valeur("jet_pulse") / 100.0
	if is_instance_valid(gestion.branches_zombie): facteur *= gestion.branches_zombie.multiplicateur_jet()
	return facteur

func multiplicateur_recharge() -> float:
	var nombre: int = gestion.escorte.freed_victims.size()
	if gestion.mode_jeu == "zombie" and is_instance_valid(gestion.room_manager.refuge):
		nombre += gestion.room_manager.refuge.victimes.size()
	var facteur := 1.0 + minf(30.0, nombre * valeur("equipe_soutien")) / 100.0
	if is_instance_valid(gestion.branches_zombie): facteur *= gestion.branches_zombie.multiplicateur_recharge()
	return facteur

func _physics_process(delta: float) -> void:
	if joueur.est_mort or joueur.entree_automatique:
		derniere_position = joueur.global_position
		return
	temps_ecoule += delta
	attente_trace = maxf(0.0, attente_trace - delta)
	if gestion.extincteur.emission_effective and attente_trace == 0:
		attente_trace = 0.35
		var arme = gestion.extincteur
		if not arme.portions_jet.is_empty():
			var depart: Vector3 = arme.muzzle.global_position
			var fin: Vector3 = depart + arme.direction_jet() * minf(arme.portions_jet[-1].y, 3.5)
			var rayon := PhysicsRayQueryParameters3D.create(depart, fin, 1)
			var impact := joueur.get_world_3d().direct_space_state.intersect_ray(rayon)
			if not impact.is_empty(): fin = impact.position - arme.direction_jet() * 0.15
			var teinte := Color(0.65, 0.85, 1.0, 0.4) if arme.ralentissement_jet > 0 else Color(0.87, 0.94, 0.94, 0.35)
			TRACE.sur_sol(gestion.room_manager.salle_actuelle, fin, teinte, 1.1)

	depuis_dash += delta
	courage_restant = maxf(0, courage_restant - delta)
	protection_restant = maxf(0, protection_restant - delta)
	reseau_restant = maxf(0, reseau_restant - delta)
	if joueur.is_dashing and not etait_dash:
		depuis_dash = 0.0
		touches_dash.clear()
		derniere_trace = joueur.global_position
	var traversait: bool = joueur.is_dashing or etait_dash
	if traversait:
		_traverser_dash()
		if valeur("sillage_secours") > 0 and derniere_trace.distance_to(joueur.global_position) >= 0.65:
			creer_zone(joueur.global_position, "mousse", valeur("sillage_secours"), 0.65, 3.0, gestion.extincteur.ralentissement_jet)
			derniere_trace = joueur.global_position
	if etait_dash and not joueur.is_dashing and valeur("freinage_urgence") > 0 and valeur("synergie_belier") <= 0:
		repousser(joueur.global_position, 2.8, valeur("freinage_urgence"))
	if etait_dash and not joueur.is_dashing and valeur("synergie_belier") > 0:
		var definition: Amelioration = gestion.catalogue_ameliorations.trouver(&"synergie_belier")
		var vague = ONDE_DEBLAYAGE.new()
		vague.effets = self
		vague.definition = definition
		gestion.room_manager.salle_actuelle.add_child(vague)
		vague.global_position = Vector3(joueur.global_position.x, 0.08, joueur.global_position.z)
	etait_dash = joueur.is_dashing
	derniere_position = joueur.global_position
	attente_zone -= delta
	if gestion.extincteur.emission_effective and not gestion.extincteur.portions_jet.is_empty() and attente_zone <= 0 and (valeur("mousse_persistante") > 0 or valeur("verglas") > 0):
		attente_zone = 0.4
		var arme = gestion.extincteur
		# La plaque suit le front du jet : elle n'apparaît pas avant son arrivée.
		var distance: float = minf(arme.portions_jet[-1].y, 2.8)
		var position: Vector3 = arme.muzzle.global_position + arme.direction_jet() * distance
		var origine: Vector3 = arme.muzzle.global_position
		var rayon := PhysicsRayQueryParameters3D.create(origine, position, 1)
		var contact := joueur.get_world_3d().direct_space_state.intersect_ray(rayon)
		if not contact.is_empty(): position = contact.position - arme.direction_jet() * 0.3
		creer_zone(position, "mousse", valeur("mousse_persistante"), 0.9, 4.0, valeur("verglas"))
	attente_equipe -= delta
	if attente_equipe <= 0:
		attente_equipe = 0.2
		gestion._actualiser_vitesse_escorte()
		_actualiser_boucliers_victimes(0.2)

func _traverser_dash() -> void:
	if valeur("dash_assaut") > 0:
		for ennemi in ennemis_proches(joueur.global_position, joueur.dash_speed * joueur.dash_duration + 2):
			var point := Geometry3D.get_closest_point_to_segment(ennemi.global_position, derniere_position, joueur.global_position)
			if point.distance_to(ennemi.global_position) > 1.5 or touches_dash.has(ennemi.get_instance_id()): continue
			touches_dash[ennemi.get_instance_id()] = true
			var gain := valeur("dash_assaut") + (valeur("brise_glace") if etat(ennemi).refroidi() else 0.0)
			infliger(ennemi, gain, &"dash")
	if valeur("brise_glace") > 0:
		for ennemi in ennemis_proches(joueur.global_position, joueur.dash_speed * joueur.dash_duration + 2):
			var point := Geometry3D.get_closest_point_to_segment(ennemi.global_position, derniere_position, joueur.global_position)
			if point.distance_to(ennemi.global_position) > 1.5 or touches_dash.has(ennemi.get_instance_id()): continue
			var statut := etat(ennemi)
			if not statut.refroidi(): continue
			touches_dash[ennemi.get_instance_id()] = true
			infliger(ennemi, valeur("brise_glace"))
			statut.gel_restant = 0.0
			var gel := ennemi.get_node_or_null("Ralentissement")
			if gel != null: gel.appliquer(0, 0.01)
			bouffee(ennemi.global_position + Vector3.UP)
	if valeur("intervention_eclair") > 0:
		for victime in get_tree().get_nodes_in_group("victime"):
			if not victime is CharacterBody3D or victime.is_freed or victime.est_morte: continue
			if not gestion.room_manager.salle_actuelle.is_ancestor_of(victime): continue
			var point := Geometry3D.get_closest_point_to_segment(victime.global_position, derniere_position, joueur.global_position)
			if point.distance_to(victime.global_position) <= 1.6 and visible_depuis(joueur.global_position + Vector3.UP, victime):
				victime.free_victim()

func creer_zone(position: Vector3, type: String, degats: float, rayon: float, duree: float, gel: float = 0.0) -> void:
	if not is_instance_valid(gestion.room_manager.salle_actuelle): return
	var zones: Array[Node] = []
	for actuelle in get_tree().get_nodes_in_group("zones_mousse"):
		if not actuelle.is_queued_for_deletion() and gestion.room_manager.salle_actuelle.is_ancestor_of(actuelle): zones.append(actuelle)
	# Les chaînes d'explosions remplacent les plaques les plus anciennes au plafond.
	while zones.size() >= maximum_zones:
		var ancienne: Node = zones.pop_front()
		ancienne.queue_free()
	var zone = ZONE.new()
	zone.name = "ZoneMousse"
	zone.effets = self
	zone.type_zone = type
	zone.degats = degats
	zone.rayon = rayon
	zone.duree = duree
	zone.gel = gel
	zone.expansive = valeur("mousse_expansive") > 0 and type != "abri"
	# La salle possède ces effets : un changement de salle ne les emporte pas.
	gestion.room_manager.salle_actuelle.add_child(zone)
	zone.global_position = Vector3(position.x, 0.04, position.z)

func bouffee(position: Vector3) -> void:
	if not is_instance_valid(gestion.room_manager.salle_actuelle): return
	var vapeur = VAPEUR.instantiate()
	gestion.room_manager.salle_actuelle.add_child(vapeur)
	vapeur.global_position = position
	vapeur.lancer(Vector3.UP)

func explosion(position: Vector3, rayon: float, degats: float, glace: bool = false) -> void:
	if joueur.est_mort: return
	onde(position, rayon, glace)
	bouffee(position + Vector3.UP)
	if glace and valeur("blizzard_proximite") > 0:
		var definition: Amelioration = gestion.catalogue_ameliorations.trouver(&"blizzard_proximite")
		creer_zone(position, "mousse", definition.valeur, definition.rayon, definition.duree_effet, definition.valeur)
	for ennemi in ennemis_proches(position, rayon):
		infliger(ennemi, degats)
		if glace and ennemi.has_method("appliquer_gel"): ennemi.appliquer_gel(20, 1)

func onde(position: Vector3, rayon: float, glace: bool = false) -> void:
	if not is_instance_valid(gestion.room_manager.salle_actuelle): return
	var anneau := MeshInstance3D.new()
	var cercle := TorusMesh.new()
	cercle.inner_radius = 0.9
	cercle.outer_radius = 1.0
	anneau.mesh = cercle
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.7, 1, 0.7) if glace else Color(0.9, 0.9, 0.75, 0.7)
	anneau.material_override = mat
	gestion.room_manager.salle_actuelle.add_child(anneau)
	anneau.global_position = position + Vector3.UP * 0.1
	# L'onde s'élargit et disparaît en même temps ; le dessin ne porte pas les dégâts.
	var animation := anneau.create_tween().set_parallel(true)
	animation.tween_property(anneau, "scale", Vector3(rayon, 0.15, rayon), 0.4)
	animation.tween_property(mat, "albedo_color:a", 0.0, 0.4)
	animation.chain().tween_callback(anneau.queue_free)

func repousser(position: Vector3, rayon: float, force: float) -> void:
	onde(position, rayon)
	for ennemi in ennemis_proches(position, rayon):
		if ennemi is CharacterBody3D: etat(ennemi).repousser(ennemi.global_position - position, force)

func ennemi_tue() -> void:
	if depuis_dash <= 1.5 and valeur("deuxieme_souffle") > 0:
		joueur.dash_cooldown_left = maxf(0, joueur.dash_cooldown_left - joueur.get_dash_cooldown() * valeur("deuxieme_souffle") / 100.0)

func _suivre_victimes() -> void:
	for victime in get_tree().get_nodes_in_group("victime"):
		if victime is CharacterBody3D and not victime.freed.is_connected(_victime_liberee):
			victime.freed.connect(_victime_liberee)

func _victime_liberee(_victime: Node3D) -> void:
	# Une victime de défi achetée en boutique n'est pas un sauvetage.
	if _victime.defi_fragile or not _victime.afficher_effet_liberation: return
	if valeur("courage_contagieux") > 0:
		courage_restant = 3.0
		bouffee(joueur.global_position + Vector3.UP)

func multiplicateur_courage() -> float:
	return 1.0 + (valeur("courage_contagieux") / 100.0 if courage_restant > 0 else 0.0)

func proteger_victime(victime: Node3D) -> void:
	if valeur("passage_securise") <= 0 or not victime.is_freed or victime.est_morte: return
	var id: int = victime.get_instance_id()
	if not victimes_bouclier.has(id):
		# Une même plaque ne redonne pas un bouclier neuf à chaque quart de seconde.
		if temps_ecoule < prochaine_protection.get(id, 0.0): return
		prochaine_protection[id] = temps_ecoule + 5.0
		victimes_bouclier[id] = {"victime": victime, "restant": valeur("passage_securise"), "temps": 3.0}
		var bulle := MeshInstance3D.new()
		bulle.name = "ProtectionMousse"
		var forme := SphereMesh.new()
		forme.radius = 0.65
		forme.height = 1.8
		bulle.mesh = forme
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.2, 0.7, 1, 0.18)
		bulle.material_override = mat
		victime.add_child(bulle)
		bulle.position.y = 0.5
	else:
		victimes_bouclier[id].temps = 3.0

func _actualiser_boucliers_victimes(delta: float) -> void:
	for id in victimes_bouclier.keys():
		var protection: Dictionary = victimes_bouclier[id]
		protection.temps -= delta
		if protection.temps <= 0 or protection.restant <= 0 or not is_instance_valid(protection.victime):
			if is_instance_valid(protection.victime):
				var bulle = protection.victime.get_node_or_null("ProtectionMousse")
				if bulle != null: bulle.queue_free()
			victimes_bouclier.erase(id)

func degats_victime(victime: Node3D, degats: float) -> float:
	if valeur("formation_serree") > 0 and victime.is_freed:
		for autre in gestion.escorte.freed_victims:
			if is_instance_valid(autre) and autre != victime and autre.global_position.distance_to(victime.global_position) < 3:
				degats *= 1.0 - valeur("formation_serree") / 100.0
				break
	var protection: Dictionary = victimes_bouclier.get(victime.get_instance_id(), {})
	if not protection.is_empty():
		var absorption := minf(degats, protection.restant)
		protection.restant -= absorption
		degats -= absorption
	if degats >= victime.vie and valeur("extraction_urgence") > 0 and victime.is_freed and not victime.has_meta("extraction_utilisee"):
		victime.set_meta("extraction_utilisee", true)
		# La position du joueur est accessible ; un décalage pourrait tomber dans un mur.
		victime.global_position = joueur.global_position
		bouffee(victime.global_position + Vector3.UP)
		degats = maxf(0, victime.vie - 1.0)
	return degats

func protection_joueur() -> float:
	if protection_restant > 0 and joueur.global_position.distance_to(position_abri) < 5:
		return 1.0 - valeur("zone_repli") / 100.0
	return 1.0

func camion_bouclier_brise() -> void:
	if valeur("zone_repli") <= 0: return
	position_abri = gestion.room_manager.refuge.global_position
	protection_restant = 3.0
	creer_zone(position_abri, "abri", 0, 5, 3)

func sprinkler_declenche(sprinkler: Node3D) -> void:
	dernier_sprinkler = sprinkler
	reseau_restant = 5.0

func puissance_sprinkler(sprinkler: Node3D) -> float:
	return 1.0 + (valeur("reseau_interconnecte") / 100.0 if reseau_restant > 0 and sprinkler != dernier_sprinkler else 0.0)

func plein_mural() -> void:
	if valeur("reserve_collective") > 0: gestion._appliquer_soin("soin_victimes", valeur("reserve_collective"))

func entretien() -> void:
	if valeur("maintenance_preventive") <= 0: return
	var usages: Array[Node3D] = []
	for groupe in ["extincteur_mural", "sprinkler"]:
		for objet in get_tree().get_nodes_in_group(groupe):
			if not gestion.room_manager.salle_actuelle.is_ancestor_of(objet): continue
			if groupe == "extincteur_mural" and not objet.disponible: usages.append(objet)
			elif groupe == "sprinkler" and objet.utilise and not objet.arme and objet.temps_restant <= 0: usages.append(objet)
	if not usages.is_empty(): usages.pick_random().recharger()
