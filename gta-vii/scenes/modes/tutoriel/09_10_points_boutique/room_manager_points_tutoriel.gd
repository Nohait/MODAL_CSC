extends "res://scenes/salles/room_manager.gd"

signal boutique_preparee(numero: int, victimes_vivantes: int)
signal parcours_termine

@export_group("Parcours pédagogique")
@export var graines_fixes: Array[int] = [17092026, 23102026]
@export_range(1, 4, 1) var ennemis_premiere_salle := 1
@export_range(1, 4, 1) var ennemis_deuxieme_salle := 2
@export_range(6.0, 18.0, 0.5) var distance_victime_cible := 10.0
@export_range(4.0, 15.0, 0.5) var distance_ennemi_cible := 7.5
@export_range(2.0, 8.0, 0.5) var distance_securite_entree := 3.5
@export_range(2.0, 8.0, 0.5) var distance_securite_victime := 3.0
@export_range(1.5, 4.0, 0.1) var distance_ouverture_porte := 2.5
var fin_emise := false
var sauvetage_retenu: Node3D
var ouverture_sortie_en_cours := false
const PORTE_ARRIVEE = preload("res://scenes/decors/porte_sortie.tscn")
const REPERE_PASSAGE = preload("res://scenes/modes/tutoriel/commun/decors/repere_passage.tscn")

func _preparer_salle(indice: int) -> void:
	if indice >= 0 and indice < graines_fixes.size(): seed(graines_fixes[indice])
	super._preparer_salle(indice)
	var salle := salles.get_child(indice)
	_masquer_plafonniers(salle)
	for sortie in salle.get_node("Portes").get_children():
		_masquer_signalisation_sortie(sortie)
	if salle.entree.has_node("PorteArriveeTutoriel"): return
	var porte = PORTE_ARRIVEE.instantiate()
	porte.name = "PorteArriveeTutoriel"
	porte.deja_ouverte = true
	porte.rotation.y = PI
	porte.position = Vector3(0, 0.1, -0.12)
	salle.entree.add_child(porte)
	_masquer_signalisation_sortie(porte)

func _masquer_signalisation_sortie(porte: Node) -> void:
	var voyant := porte.get_node_or_null("Voyant") as Node3D
	if voyant != null: voyant.hide()
	var boitier := porte.get_node_or_null("BoitierSortie") as Node3D
	if boitier != null: boitier.hide()

func _masquer_plafonniers(salle: Node3D) -> void:
	for support in salle.find_children("Plafonnier", "Node3D", true, false):
		for enfant in support.get_children():
			if enfant is Light3D: continue
			if enfant is Node3D: enfant.hide()

func _process(delta: float) -> void:
	super._process(delta)
	if transition_en_cours or ouverture_sortie_en_cours or not is_instance_valid(salle_actuelle): return
	if not salle_actuelle.liberee or not Input.is_action_just_pressed("interact"): return
	var porte := _porte_sortie_proche()
	if porte != null: _ouvrir_sortie(porte)

func _porte_sortie_proche() -> Node3D:
	var meilleure: Node3D
	var meilleure_distance := distance_ouverture_porte
	for candidate in salle_actuelle.get_node("Portes").get_children():
		var ecart: Vector3 = candidate.global_position - joueur.global_position
		ecart.y = 0.0
		if ecart.length() <= meilleure_distance:
			meilleure = candidate
			meilleure_distance = ecart.length()
	return meilleure

func _ouvrir_sortie(porte: Node3D) -> void:
	ouverture_sortie_en_cours = true
	var repere := porte.get_node_or_null("ReperePassage")
	if repere != null: repere.hide()
	porte.ouvrir()
	if not porte.est_ouverte: await porte.ouverte
	if not is_instance_valid(salle_actuelle) or joueur.est_mort:
		ouverture_sortie_en_cours = false
		return
	_on_sortie_franchie(salle_actuelle)

func liberer_portes(salle: Node3D) -> void:
	for porte in salle.get_node("Portes").get_children():
		porte.autoriser()
		if porte.has_node("ReperePassage"): continue
		var repere := REPERE_PASSAGE.instantiate()
		repere.name = "ReperePassage"
		repere.position = Vector3(0, 0, 1.65)
		porte.add_child(repere)

func peupler_salle(salle: Node3D) -> void:
	var emplacements: Array[Vector3] = salle.points_spawn.duplicate()
	if emplacements.is_empty(): return
	var entree: Vector3 = salle.entree.position
	var nombre: int = ennemis_premiere_salle if salle.numero_dans_etage == 1 else ennemis_deuxieme_salle
	var candidats_victime: Array[Vector3] = emplacements.duplicate()
	# Un point proche de l'axe d'entrée reste visible et évite de transformer l'exercice en exploration.
	candidats_victime.sort_custom(func(a: Vector3, b: Vector3):
		return _score_position_victime(salle, a) < _score_position_victime(salle, b))
	var position_victime: Vector3 = candidats_victime[0]
	for candidate in candidats_victime:
		var positions_sures := 0
		for position in emplacements:
			if position == candidate: continue
			if position.distance_to(entree) >= distance_securite_entree \
				and position.distance_to(candidate) >= distance_securite_victime:
				positions_sures += 1
		if positions_sures >= nombre:
			position_victime = candidate
			break
	emplacements.erase(position_victime)
	var victime = VICTIME_SCENE.instantiate()
	victime.name = "VictimeTutoriel"
	victime.position = position_victime + Vector3.UP * 0.75
	victime.bonus_dash = false
	victime.bonus_degats = false
	salle.get_node("Victimes").add_child(victime)
	victime.set_ennemis_container(salle.get_node("Ennemis"))
	victim_manager.surveiller_victime(victime)
	victime.freed.connect(_on_victim_freed.bind(salle), CONNECT_ONE_SHOT)
	victime.died.connect(_on_victim_died.bind(salle), CONNECT_ONE_SHOT)
	salle.remaining_victims = 1

	# Les créatures sont présentes dès l'entrée : aucune vague ne surprend le joueur pendant l'explication.
	# Les positions sûres passent avant les replis, eux-mêmes classés par distance.
	# Les graines fixes rendent ce choix reproductible pendant les playtests.
	emplacements.sort_custom(func(a: Vector3, b: Vector3):
		var sure_a := a.distance_to(entree) >= distance_securite_entree and a.distance_to(position_victime) >= distance_securite_victime
		var sure_b := b.distance_to(entree) >= distance_securite_entree and b.distance_to(position_victime) >= distance_securite_victime
		if sure_a != sure_b: return sure_a
		var ecart_a := absf(a.distance_to(position_victime) - distance_ennemi_cible)
		var ecart_b := absf(b.distance_to(position_victime) - distance_ennemi_cible)
		return ecart_a < ecart_b)
	for i in range(mini(nombre, emplacements.size())):
		creer_sbire(salle, emplacements[i])
		salle.remaining_enemies += 1

func _score_position_victime(salle: Node3D, position: Vector3) -> float:
	var relatif: Vector3 = salle.entree.to_local(salle.to_global(position))
	var distance := Vector2(relatif.x, relatif.z).length()
	return absf(distance - distance_victime_cible) + absf(relatif.x) * 0.35

func demarrer_sauvetage(salle: Node3D) -> void:
	# Dans la première salle normale, l'explication doit précéder le compte à rebours.
	var debug_actif: bool = Engine.get_meta("tutoriel_debug_actif", false) \
		or Engine.has_meta("tutoriel_debug_depart")
	if indice_salle == 0 and not debug_actif:
		sauvetage_retenu = salle
		return
	super.demarrer_sauvetage(salle)

func confirmer_introduction() -> void:
	if not is_instance_valid(sauvetage_retenu): return
	var salle := sauvetage_retenu
	sauvetage_retenu = null
	super.demarrer_sauvetage(salle)
	actualiser_objectifs()

func conditions_sortie_remplies(salle: Node3D) -> bool:
	# La sortie attend que la victime ait été libérée ou perdue, sans transformer sa mort en échec forcé.
	return salle.remaining_enemies == 0 and salle.remaining_victims == 0

func preparer_sortie() -> void:
	salle_terminee.emit(salle_actuelle)
	var nombre_victimes: int = compter_victimes_escorte_vivantes()
	boutique_preparee.emit(indice_salle + 1, nombre_victimes)
	choix_amelioration_demande.emit(nombre_victimes)

func passer_salle_suivante() -> void:
	if indice_salle + 1 < salles.get_child_count():
		ouverture_sortie_en_cours = false
		await activer_salle(indice_salle + 1)
	elif not fin_emise:
		fin_emise = true
		parcours_termine.emit()
