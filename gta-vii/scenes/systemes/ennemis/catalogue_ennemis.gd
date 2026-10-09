extends Node

signal rencontre_ajoutee
signal ennemi_enregistre(ennemi: Node3D)
signal elite_importante_apparue(ennemi: Node3D)
const CATALOGUE = preload("res://scenes/systemes/ennemis/definitions_ennemis.gd")
const ELITE = preload("res://scenes/systemes/ennemis/elite_ennemi.gd")
const SAUVEGARDE = "user://glossaire.cfg"
const MODIFICATEURS: Array[ModificateurElite] = [
	preload("res://scenes/systemes/ennemis/modificateurs/geant.tres"),
	preload("res://scenes/systemes/ennemis/modificateurs/rapide.tres"),
	preload("res://scenes/systemes/ennemis/modificateurs/enrage.tres"),
	preload("res://scenes/systemes/ennemis/modificateurs/aura_vitesse.tres"),
	preload("res://scenes/systemes/ennemis/modificateurs/aura_resistance.tres"),
	preload("res://scenes/systemes/ennemis/modificateurs/aura_degats.tres")
]
# Commun aux deux modes. Les modificateurs restent réglables dans leurs .tres.
@export var equilibrage: EquilibrageElites = preload("res://scenes/systemes/ennemis/equilibrage_elites.tres")
var rencontres: Dictionary = {}
var ennemis: Array[Node3D] = []
var delai := 0.0

func _ready() -> void:
	var fichier := ConfigFile.new()
	if fichier.load(SAUVEGARDE) == OK:
		rencontres = fichier.get_value("glossaire", "rencontres", {})
	get_tree().node_added.connect(_noeud_ajoute)

func _noeud_ajoute(noeud: Node) -> void:
	if noeud is Node3D and not noeud.scene_file_path.is_empty():
		_enregistrer_ennemi.call_deferred(noeud.get_instance_id())

func _enregistrer_ennemi(identifiant_instance: int) -> void:
	# L’aperçu peut avoir été détruit avant cet appel différé.
	var noeud = instance_from_id(identifiant_instance)
	if not is_instance_valid(noeud) or not noeud.is_inside_tree() or noeud.has_meta("apercu_glossaire"): return
	# Les figurants d'arrivée n'appartiennent à aucun groupe de combat.
	if not noeud.is_in_group("enemies") and not noeud.is_in_group("flaque"): return
	if not noeud.is_node_ready(): return
	var fiche := fiche_scene(noeud.scene_file_path)
	if fiche.is_empty() or ennemis.has(noeud): return
	noeud.set_meta("fiche_glossaire", fiche.id)
	noeud.set_meta("variante_glossaire", "normal")
	ennemis.append(noeud)
	var monnaie = get_tree().get_first_node_in_group("monnaie_partie")
	if monnaie != null and noeud.has_signal("died"):
		var valeur: int = noeud.get_meta("valeur_pieces", fiche.cout_difficulte)
		noeud.died.connect(monnaie.lacher_pieces.bind(noeud, valeur), CONNECT_ONE_SHOT)
	if fiche.get("elite_possible", false) and randf() * 100.0 < equilibrage.chance(_progression(noeud)):
		var total := 0.0
		for mod in MODIFICATEURS: total += mod.poids
		var tirage := randf() * total
		for mod in MODIFICATEURS:
			tirage -= mod.poids
			if tirage < 0.0:
				appliquer_elite(noeud, mod)
				break
		if noeud.has_node("Elite"):
			elite_importante_apparue.emit(noeud)

	ennemi_enregistre.emit(noeud)

func _progression(ennemi: Node) -> int:
	var courant := ennemi.get_parent()
	while courant != null:
		var gestionnaire := courant.get_node_or_null("RoomManager")
		if gestionnaire != null:
			var vague = gestionnaire.get("vague_actuelle")
			return maxi(1, int(vague)) if vague != null else gestionnaire.indice_salle + 1
		courant = courant.get_parent()
	return 1

func _gestionnaire(ennemi: Node) -> Node:
	var courant := ennemi.get_parent()
	while courant != null:
		var gestionnaire := courant.get_node_or_null("RoomManager")
		if gestionnaire != null: return gestionnaire
		courant = courant.get_parent()
	return null

func fiche_scene(chemin: String) -> Dictionary:
	for fiche in CATALOGUE.ENNEMIS:
		if fiche.scene == chemin: return fiche
	return {}

func appliquer_elite(ennemi: Node3D, mod: ModificateurElite) -> void:
	if ennemi.has_node("Elite"): return
	var effet := ELITE.new()
	effet.name = "Elite"
	effet.definition = mod
	ennemi.add_child(effet)
	ennemi.set_meta("variante_glossaire", mod.identifiant)

func a_rencontre(id: String, variante := "") -> bool:
	return rencontres.has(id) if variante.is_empty() else variante in rencontres.get(id, [])

func noter_rencontre(id: String, variante: String) -> void:
	if a_rencontre(id, variante): return
	if not rencontres.has(id): rencontres[id] = []
	rencontres[id].append(variante)
	var fichier := ConfigFile.new()
	fichier.set_value("glossaire", "rencontres", rencontres)
	fichier.save(SAUVEGARDE)
	rencontre_ajoutee.emit()

func debloquer_tout() -> void:
	# Le debug remplit la même sauvegarde que les découvertes pendant une partie.
	for fiche in CATALOGUE.ENNEMIS:
		rencontres[fiche.id] = ["normal", "doree"]
		if fiche.get("elite_possible", false):
			for mod in MODIFICATEURS: rencontres[fiche.id].append(mod.identifiant)
	var fichier := ConfigFile.new()
	fichier.set_value("glossaire", "rencontres", rencontres)
	fichier.save(SAUVEGARDE)
	rencontre_ajoutee.emit()

func _physics_process(delta: float) -> void:
	delai -= delta
	if delai > 0.0: return
	delai = 0.2
	ennemis = ennemis.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())
	var camera := get_viewport().get_camera_3d()
	var joueur = get_tree().get_first_node_in_group("player")
	var sources_aura: Array[Node3D] = []
	for source in ennemis:
		var elite = source.get_node_or_null("Elite")
		if elite == null or source.get("est_mort") == true or not source.is_visible_in_tree(): continue
		for mod in [elite.definition]:
			if mod.aura != "aucune":
				sources_aura.append(source)
				break
	for ennemi in ennemis:
		if not ennemi.is_visible_in_tree() or ennemi.get("est_mort") == true: continue
		if ennemi.has_method("multiplicateur_degats"):
			ennemi.vitesse_aura = 1.0
			ennemi.degats_aura = 1.0
			ennemi.resistance_aura = 0.0
			# Les auras identiques ne s'empilent pas ; les différentes peuvent coexister.
			for source in sources_aura:
				var elite = source.get_node_or_null("Elite")
				if elite == null or not source.is_visible_in_tree() or source.get("est_mort") == true: continue
				for mod in [elite.definition]:
					if mod.aura == "aucune" or source.global_position.distance_to(ennemi.global_position) > mod.rayon_aura: continue
					match mod.aura:
						"vitesse": ennemi.vitesse_aura = maxf(ennemi.vitesse_aura, 1.0 + mod.bonus_aura)
						"degats": ennemi.degats_aura = maxf(ennemi.degats_aura, 1.0 + mod.bonus_aura)
						"resistance": ennemi.resistance_aura = maxf(ennemi.resistance_aura, mod.bonus_aura)
		if ennemi.has_method("multiplicateur_degats"):
			var retour = ennemi.get_node_or_null("InfluenceAura")
			var influence: bool = ennemi.vitesse_aura > 1.0 or ennemi.degats_aura > 1.0 or ennemi.resistance_aura > 0.0
			if influence and retour == null:
				retour = preload("res://scenes/systemes/ennemis/influence_aura.gd").new()
				retour.name = "InfluenceAura"
				ennemi.add_child(retour)
			if retour != null:
				retour.actualiser(ennemi.vitesse_aura, ennemi.degats_aura, ennemi.resistance_aura)
		if camera == null or not is_instance_valid(joueur): continue
		if not camera.is_position_in_frustum(ennemi.global_position) or joueur.global_position.distance_to(ennemi.global_position) > 24.0: continue
		var rayon := PhysicsRayQueryParameters3D.create(joueur.global_position, ennemi.global_position + Vector3.UP * 0.5, 1)
		rayon.exclude = [joueur.get_rid(), ennemi.get_rid()] if ennemi is CollisionObject3D else [joueur.get_rid()]
		if ennemi.get_world_3d().direct_space_state.intersect_ray(rayon).is_empty():
			noter_rencontre(ennemi.get_meta("fiche_glossaire"), "doree" if ennemi.has_node("Dore") else ennemi.get_meta("variante_glossaire"))
