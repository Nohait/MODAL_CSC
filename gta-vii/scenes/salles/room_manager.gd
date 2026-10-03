extends Node

signal room_cleared

# Les défis suivent une salle depuis son activation jusqu’au passage de sa porte.
signal salle_preparee(salle: Node3D)
signal salle_commencee(salle: Node3D)
signal salle_terminee(salle: Node3D)
signal partie_prete

@onready var transition_etage = $"../../TransitionEtage"

# Fourni avant la génération par l'UpgradeManager, selon le réglage du défi.
var victimes_supplementaires_reserve := 1

# Indique à l'UpgradeManager combien de victimes vivantes sont actuellement dans l'escorte.
signal choix_amelioration_demande(nombre_victimes: int)

const GUIDAGE_SORTIE = preload("res://scenes/effets/guidage_sortie/guidage_sortie.gd")
const SBIRE_SCENE = preload("res://scenes/ennemis/mobiles/sbire.tscn")
const ANNONCE_SCENE = preload("res://scenes/effets/apparition/annonce_apparition.tscn")
const TOUR_ENFLAMMEE_SCENE = preload("res://scenes/ennemis/tourelles/tour_enflammee.tscn")
const FLAQUE_SCENE = preload("res://scenes/ennemis/dangers/flaque_de_feu.tscn")
const VICTIME_SCENE = preload("res://scenes/victimes/victime.tscn")

# Ancien système conservé dans le projet.
# La scène n'est simplement plus instanciée automatiquement.
const EVACUATION_SCENE = preload("res://scenes/victimes/evacuation/point_evacuation.tscn")

# Parcours

@export_group("Parcours")

# Nombre d'étages du parcours.
@export_range(1, 10, 1) var nombre_etages := 3
const SALLES_PAR_ETAGE := 5
var nombre_salles: int:
	get:
		return nombre_etages * SALLES_PAR_ETAGE

# Population

@export_group("Population des salles")
@export_range(0, 20, 1) var nombre_min_ennemis := 3
@export_range(0, 20, 1) var nombre_max_ennemis := 6
@export_range(0, 10, 1) var nombre_min_tour_enflammee := 0
@export_range(0, 10, 1) var nombre_max_tour_enflammee := 2
@export_range(0, 10, 1) var nombre_min_flaques := 0
@export_range(0, 10, 1) var nombre_max_flaques := 3

# Vagues

@export_group("Vagues des ennemis mobiles")
@export_range(1, 5, 1) var taille_min_vague := 1
@export_range(1, 5, 1) var taille_max_vague := 3

# Durée tirée pour chaque salle ; la dernière vague apparaît à la fin.
@export_range(15.0, 30.0, 1.0) var duree_min_vagues := 15.0
@export_range(15.0, 30.0, 1.0) var duree_max_vagues := 30.0

# Durée de l'annonce visuelle avant apparition.
@export_range(0.2, 3.0, 0.1) var duree_annonce := 1.0

# Distance horizontale minimale avec le joueur pour une vague normale.
@export_range(1.5, 10.0, 0.5) var distance_securite_spawn := 3.0

# Victimes

@export_group("Victimes présentes dès le début")
@export_range(1, 5, 1) var nombre_min_victimes := 1
@export_range(0, 5, 1) var nombre_max_victimes := 3

# Ancien système de bonus

@export_group("Ancien système de types de victimes")
@export_range(0, 100, 1) var poids_sans_bonus := 8
@export_range(0, 100, 1) var poids_dash := 1
@export_range(0, 100, 1) var poids_degats := 1

# Références
@onready var generateur = $"../RoomGenerator"
@onready var salles: Node3D = $"../Rooms"
@onready var joueur = $"../../player"
@onready var camera_rig = $"../../CameraRig"
@onready var victim_manager = $"../../VictimManager"
@onready var informations_salle = $InterfaceSalle/HUD/InformationsSalle
@onready var objectifs: Label = $InterfaceSalle/HUD/InformationsSalle/Objectifs
@onready var timer_container: Control = $InterfaceSalle/HUD/InformationsSalle/TimerContainer
@onready var timer_bar: ProgressBar = $InterfaceSalle/HUD/InformationsSalle/TimerContainer/TimerBar
@onready var message_victoire: PanelContainer = $InterfaceSalle/HUD/MessageVictoire

# État global
var guidage_sortie: Node3D
var salle_actuelle: Node3D
var indice_salle := -1
var transition_en_cours := false
var initialized := false
var animation_message: Tween
var remaining_victims := 0
var remaining_enemies := 0
var is_room_cleared := false

# Étages

func etage_pour_salle(indice: int) -> int:
	return floori(float(indice) / SALLES_PAR_ETAGE) + 1

# Démarrage

func demarrer_partie() -> void:
	if initialized:
		return
	initialized = true
	guidage_sortie = GUIDAGE_SORTIE.new()
	add_child(guidage_sortie)
	transition_en_cours = true
	joueur.set_physics_process(false)
	objectifs.text = "Génération des salles…"
	for i in range(nombre_salles):
		var fin_etage := (i + 1) % SALLES_PAR_ETAGE == 0

		# On réserve suffisamment de points d'arrivée pour toute l'escorte potentielle.
		var salle = generateur.generer_salle(
			2 # Le joueur et une éventuelle victime fragile.
			+ nombre_salles
			* (victimes_supplementaires_reserve + maxi(nombre_min_victimes, nombre_max_victimes)),
			fin_etage,
			etage_pour_salle(i),
			i > 0 and i % SALLES_PAR_ETAGE == 0
		)
		salle.etage = etage_pour_salle(i)
		salle.name = "Salle%d" % (i + 1)
		salle.position.x = i * 150.0
		salle.process_mode = Node.PROCESS_MODE_DISABLED
		salle.hide()
		salles.add_child(salle)
		peupler_salle(salle)
		salle.sortie_franchie.connect(_on_sortie_franchie)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await activer_salle(0)
	partie_prete.emit()

# Population

func peupler_salle(salle: Node3D) -> void:
	var emplacements: Array[Vector3] = salle.points_spawn.duplicate()
	emplacements.shuffle()

	# Victimes
	var nombre_victimes := randi_range(maxi(1, nombre_min_victimes), maxi(1, maxi(nombre_min_victimes, nombre_max_victimes)))
	for i in range(mini(nombre_victimes, emplacements.size())):
		var victime = VICTIME_SCENE.instantiate()
		victime.name = "Victime%d" % (i + 1)
		victime.position = emplacements.pop_back() + Vector3.UP * 0.75

		# Toutes les victimes générées sont désormais normales.
		victime.bonus_dash = false
		victime.bonus_degats = false
		salle.get_node("Victimes").add_child(victime)

		# La victime connaît les ennemis de sa salle.
		victime.set_ennemis_container(salle.get_node("Ennemis"))
		victim_manager.surveiller_victime(victime)
		victime.freed.connect(_on_victim_freed.bind(salle), CONNECT_ONE_SHOT)
		victime.died.connect(_on_victim_died.bind(salle), CONNECT_ONE_SHOT)
		salle.remaining_victims += 1

	# Tourelles
	var nombre_tours := mini(
		randi_range(nombre_min_tour_enflammee, maxi(nombre_min_tour_enflammee, nombre_max_tour_enflammee)),
		emplacements.size()
	)
	for i in range(nombre_tours):
		var tour = TOUR_ENFLAMMEE_SCENE.instantiate()
		tour.position = emplacements.pop_back() + Vector3.UP * 0.1
		tour.projectiles_tour = salle.get_node("ProjectilesTour")
		tour.etage = salle.etage
		salle.get_node("Ennemis").add_child(tour)
		tour.died.connect(_on_enemy_died.bind(salle), CONNECT_ONE_SHOT)
		salle.remaining_enemies += 1

	# Flaques initiales
	var nombre_flaques := mini(
		randi_range(nombre_min_flaques, maxi(nombre_min_flaques, nombre_max_flaques)),
		emplacements.size()
	)
	for i in range(nombre_flaques):
		var flaque = FLAQUE_SCENE.instantiate()
		flaque.etage = salle.etage
		salle.get_node("Ennemis").add_child(flaque)
		flaque.choisir_taille_aleatoire()
		flaque.position = emplacements.pop_back() + Vector3.UP * 0.2
		flaque.died.connect(_on_enemy_died.bind(salle), CONNECT_ONE_SHOT)
		salle.remaining_enemies += 1

	# Mobiles à venir
	var nombre := mini(
		randi_range(nombre_min_ennemis, maxi(nombre_min_ennemis, nombre_max_ennemis)),
		emplacements.size()
	)
	for i in range(nombre):
		salle.mobiles_a_creer.append(emplacements.pop_back())

	# Ils comptent immédiatement comme ennemis de la salle.
	# La porte ne peut donc pas s'ouvrir entre deux vagues.
	salle.remaining_enemies += nombre

# Ancien système de types

func attribuer_bonus(victime: Node) -> void:
	victime.bonus_dash = false
	victime.bonus_degats = false
	var total := poids_sans_bonus + poids_dash + poids_degats
	if total == 0:
		return
	var ticket := randi_range(0, total - 1)
	if ticket < poids_sans_bonus:
		return
	elif (ticket < poids_sans_bonus + poids_dash):
		victime.bonus_dash = true
	else:
		victime.bonus_degats = true

# Boucle de jeu de la salle

func _process(delta: float) -> void:
	if (transition_en_cours or not is_instance_valid(salle_actuelle)):
		return

	if not salle_actuelle.sauvetage_en_cours:
		return
	actualiser_sauvetage(delta)
	if not salle_actuelle.sauvetage_en_cours:
		return
	var restant: float = salle_actuelle.temps_sauvetage_restant
	# Les annonces commencent avant leur échéance, mais le calendrier décide du spawn.
	while not salle_actuelle.vagues_planifiees.is_empty():
		var vague: Dictionary = salle_actuelle.vagues_planifiees[0]
		if restant > vague.restant + duree_annonce:
			break
		salle_actuelle.vagues_planifiees.pop_front()
		creer_vague(vague.nombre, vague.restant)
	for apparition in salle_actuelle.apparitions_planifiees.duplicate():
		if restant <= apparition.restant:
			salle_actuelle.apparitions_planifiees.erase(apparition)
			_terminer_apparition(salle_actuelle, apparition.position)

# Timer

func demarrer_sauvetage(salle: Node3D) -> void:
	if salle.sauvetage_demarre:
		return
	salle.sauvetage_demarre = true
	salle.sauvetage_en_cours = true
	salle.sauvetage_termine = false
	salle.duree_sauvetage = randf_range(clampf(duree_min_vagues, 15.0, 30.0), clampf(maxf(duree_min_vagues, duree_max_vagues), 15.0, 30.0))
	salle.temps_sauvetage_restant = salle.duree_sauvetage
	var tailles: Array[int] = []
	var a_planifier: int = salle.mobiles_a_creer.size()
	while a_planifier > 0:
		var taille := mini(a_planifier, randi_range(taille_min_vague, maxi(taille_min_vague, taille_max_vague)))
		tailles.append(taille)
		a_planifier -= taille
	for i in range(tailles.size()):
		# Échéances espacées régulièrement ; la dernière vaut exactement zéro seconde restante.
		var restant: float = salle.duree_sauvetage * (1.0 - float(i + 1) / tailles.size())
		salle.vagues_planifiees.append({"nombre": tailles[i], "restant": restant})
	informations_salle.demarrer_timer()

	# La ProgressBar représente directement des secondes.
	timer_bar.min_value = 0.0
	timer_bar.max_value = salle.duree_sauvetage
	timer_bar.value = salle.duree_sauvetage
	timer_container.show()

func actualiser_sauvetage(delta: float) -> void:
	var salle := salle_actuelle
	var temps_precedent: float = salle.temps_sauvetage_restant
	salle.temps_sauvetage_restant = maxf(salle.temps_sauvetage_restant - delta, 0.0)
	timer_bar.value = salle.temps_sauvetage_restant

	# Proportion écoulée : 0 au début, 0.5 à mi-parcours, 1 à la fin.
	var proportion_ecoulee: float = 1.0 - salle.temps_sauvetage_restant / salle.duree_sauvetage
	for victime in (salle.get_node("Victimes").get_children()):
		if not is_instance_valid(victime) or victime.is_queued_for_deletion() or victime.est_morte or victime.is_freed:
			continue
		# Un seul cri au passage de la moitié du timer, quelle que soit la durée de la salle.
		var mi_parcours: float = salle.duree_sauvetage / 2.0
		if temps_precedent > mi_parcours and salle.temps_sauvetage_restant <= mi_parcours and not victime.cris.is_empty():
			victime.cris.pick_random().play()
		victime.actualiser_degats_sauvetage(proportion_ecoulee)
		
	if salle.temps_sauvetage_restant <= 0.0:
		terminer_sauvetage(salle)
	else:
		actualiser_objectifs()

func terminer_sauvetage(salle: Node3D) -> void:
	if not salle.sauvetage_en_cours:
		return
	salle.sauvetage_en_cours = false
	salle.sauvetage_termine = true
	salle.temps_sauvetage_restant = 0.0
	timer_bar.value = 0.0
	timer_container.hide()

	# Sécurité mathématique : imposer exactement 100 % des dégâts du timer aux victimes encore captives.
	for victime in (salle.get_node("Victimes").get_children() .duplicate()):
		if victime.is_in_group("victime"):
			if (
				not is_instance_valid(victime)
				or victime.is_queued_for_deletion()
				or victime.is_freed
				or victime.est_morte
			):
				continue
			victime.actualiser_degats_sauvetage(1.0)

	# À zéro seconde, aucun mobile planifié ne doit rester en attente.
	forcer_spawn_mobiles_restants(salle)
	if salle == salle_actuelle:
		actualiser_objectifs()

# Vagues

func creer_vague(nombre_prevu: int, restant: float) -> void:
	var nombre := mini(nombre_prevu, salle_actuelle.mobiles_a_creer.size())
	for i in range(nombre):
		var indice := trouver_emplacement_eloigne(salle_actuelle)
		if indice == -1:
			indice = 0 # L’annonce prévient le joueur ; ne pas retarder la vague.
		var emplacement: Vector3 = salle_actuelle.mobiles_a_creer[indice]
		salle_actuelle.mobiles_a_creer.remove_at(indice)
		salle_actuelle.mobiles_annonces.append(emplacement)
		salle_actuelle.apparitions_en_cours += 1
		var annonce = ANNONCE_SCENE.instantiate()
		annonce.position = emplacement + Vector3.UP * 0.13
		annonce.duree = duree_annonce
		salle_actuelle.annonces_en_cours.append(annonce)
		salle_actuelle.apparitions_planifiees.append({"position": emplacement, "restant": restant})
		annonce.terminee.connect(salle_actuelle.annonces_en_cours.erase.bind(annonce), CONNECT_ONE_SHOT)
		salle_actuelle.add_child(annonce)
	actualiser_objectifs()

func emplacement_suffisamment_eloigne(salle: Node3D, emplacement: Vector3) -> bool:
	if not is_instance_valid(joueur):
		return false
	var ecart: Vector3 = salle.to_global(emplacement) - joueur.global_position
	ecart.y = 0.0
	return ecart.length() >= distance_securite_spawn

func trouver_emplacement_eloigne(salle: Node3D) -> int:
	for i in range(salle.mobiles_a_creer.size()):
		if emplacement_suffisamment_eloigne(salle, salle.mobiles_a_creer[i]):
			return i
	return -1

func _terminer_apparition(salle: Node3D, emplacement: Vector3) -> void:
	# Une position consommée ne doit jamais créer deux ennemis.
	if not salle.mobiles_annonces.has(emplacement):
		return
	salle.mobiles_annonces.erase(emplacement)
	salle.apparitions_en_cours = maxi(salle.apparitions_en_cours - 1, 0)
	if (salle != salle_actuelle or transition_en_cours):
		salle.mobiles_a_creer.append(emplacement)
	else:
		creer_sbire(salle, emplacement)
	if salle == salle_actuelle:
		actualiser_objectifs()

func forcer_spawn_mobiles_restants(salle: Node3D) -> void:

	# Positions encore jamais annoncées.
	var positions: Array[Vector3] = salle.mobiles_a_creer.duplicate()

	# Positions dont l'annonce était encore en cours.
	positions.append_array(salle.mobiles_annonces)

	# Retirer les annonces visuelles restantes.
	for annonce in (salle.annonces_en_cours.duplicate()):
		if is_instance_valid(annonce):
			annonce.queue_free()
	salle.annonces_en_cours.clear()
	salle.mobiles_a_creer.clear()
	salle.mobiles_annonces.clear()
	salle.apparitions_en_cours = 0
	salle.vagues_planifiees.clear()
	salle.apparitions_planifiees.clear()
	for emplacement in positions:
		creer_sbire(salle, emplacement)

func creer_sbire(salle: Node3D, emplacement: Vector3) -> void:
	var sbire = SBIRE_SCENE.instantiate()
	sbire.etage = salle.etage
	sbire.position = emplacement + Vector3.UP * 0.75
	salle.get_node("Ennemis").add_child(sbire)
	sbire.get_node("NavigationAgent").set_navigation_map(salle.carte_ennemis)
	sbire.died.connect(_on_enemy_died.bind(salle), CONNECT_ONE_SHOT)

# Activation d'une salle

func activer_salle(indice: int) -> void:
	var ancien_etage := etage_pour_salle(indice_salle)

	# Seul un nouvel étage ajoute son titre au fondu rapide de chaque salle.
	var changer_etage := is_instance_valid(salle_actuelle) and etage_pour_salle(indice) != ancien_etage
	transition_en_cours = true
	joueur.set_physics_process(false)
	$"../../Escorte".process_mode = Node.PROCESS_MODE_DISABLED
	guidage_sortie.arreter()
	joueur.annuler_ordre_victimes()
	joueur.entree_automatique = false
	timer_container.hide()
	await transition_etage.masquer(true)
	if is_instance_valid(salle_actuelle):
		salle_actuelle.entree.arreter()
		salle_actuelle.process_mode = Node.PROCESS_MODE_DISABLED
		salle_actuelle.hide()
		salle_actuelle.activer_navigation(false)
	indice_salle = indice
	salle_actuelle = salles.get_child(indice)

	# Les défis peuvent compléter la population avant le démarrage du timer.
	salle_preparee.emit(salle_actuelle)

	# Le décor est actif pour préparer la navigation, mais le combat reste momentanément gelé.
	salle_actuelle.get_node("Ennemis").process_mode = Node.PROCESS_MODE_DISABLED
	salle_actuelle.get_node("Victimes").process_mode = Node.PROCESS_MODE_DISABLED
	if animation_message:
		animation_message.kill()
	message_victoire.hide()
	salle_actuelle.show()
	salle_actuelle.process_mode = Node.PROCESS_MODE_INHERIT
	salle_actuelle.activer_navigation(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	salle_actuelle.cuire_navigation()

	# Joueur
	joueur.extincteur.vider_jet()
	joueur.global_position = salle_actuelle.entree.to_global(Vector3(0, 1.1, 1.6))
	joueur.velocity = Vector3.ZERO
	joueur.is_dashing = false
	joueur.dash_time_left = 0.0

	# La file attend dans le couloir ; son excédent émergera du noir progressivement.
	salle_actuelle.entree.preparer(victim_manager.freed_victims)
	for victime in victim_manager.freed_victims:
		if is_instance_valid(victime) and not victime.is_queued_for_deletion():
			victime.set_ennemis_container(salle_actuelle.get_node("Ennemis"))
	camera_rig.recentrer()

	# Attendre la navigation
	var carte: RID = salle_actuelle .get_world_3d() .navigation_map
	var arrivee: Vector3 = salle_actuelle.entree.to_global(Vector3(0, 1.1, -1.4))
	for tentative in range(300):
		await get_tree().physics_frame
		var point_proche := NavigationServer3D.map_get_closest_point(carte, joueur.global_position)
		var victimes_pretes := (
			point_proche.distance_to(joueur.global_position)
			< 3.0
			and not NavigationServer3D.map_get_path(carte, joueur.global_position, arrivee, true).is_empty()
		)
		var ennemis_prets := (
			not NavigationServer3D.map_get_path(
				salle_actuelle.carte_ennemis,
				joueur.global_position,
				arrivee,
				true
			).is_empty()
		)
		if (victimes_pretes and ennemis_prets):
			break
		if tentative == 299:
			push_error("La navigation de la salle n'a pas pu être initialisée.")
			objectifs.text = "Navigation indisponible — R pour relancer."
			return

	# Révéler la nouvelle pièce avant la course ; le combat et son timer restent gelés.
	if changer_etage:
		await transition_etage.reveler(salle_actuelle.etage)
	else:
		await transition_etage.reveler_salle()
	$"../../Escorte".process_mode = Node.PROCESS_MODE_INHERIT
	salle_actuelle.entree.commencer()
	joueur.commencer_entree(arrivee)
	joueur.set_physics_process(true)
	await joueur.entree_terminee
	salle_actuelle.get_node("Ennemis").process_mode = Node.PROCESS_MODE_INHERIT
	salle_actuelle.get_node("Victimes").process_mode = Node.PROCESS_MODE_INHERIT
	transition_en_cours = false

	# Le timer commence seulement une fois que le joueur a réellement le contrôle.
	demarrer_sauvetage(salle_actuelle)
	salle_commencee.emit(salle_actuelle)
	actualiser_objectifs()

# Mort / libération

func _on_victim_freed(_victime: CharacterBody3D, salle: Node3D) -> void:
	salle.remaining_victims = maxi(salle.remaining_victims - 1, 0)
	if salle == salle_actuelle:
		actualiser_objectifs()

func _on_victim_died(victime: CharacterBody3D, salle: Node3D) -> void:

	# Une victime déjà libérée avait déjà été retirée du compteur des captives lors de sa libération.
	if not victime.is_freed:
		salle.remaining_victims = maxi(salle.remaining_victims - 1, 0)
	if salle == salle_actuelle:
		actualiser_objectifs()

func _on_enemy_died(salle: Node3D) -> void:
	salle.remaining_enemies = maxi(salle.remaining_enemies - 1, 0)
	if salle == salle_actuelle:
		actualiser_objectifs()

# Objectifs

func actualiser_objectifs() -> void:
	if not is_instance_valid(salle_actuelle):
		return
	remaining_victims = salle_actuelle.remaining_victims
	remaining_enemies = salle_actuelle.remaining_enemies
	is_room_cleared = salle_actuelle.liberee
	var a_venir: int = salle_actuelle .mobiles_a_creer .size() + salle_actuelle .mobiles_annonces .size()

	# Le HUD affiche les données ; le RoomManager conserve les règles de la salle.
	informations_salle.mettre_a_jour(salle_actuelle.etage,
		indice_salle % SALLES_PAR_ETAGE + 1, SALLES_PAR_ETAGE, remaining_enemies, a_venir, remaining_victims)

	# Seuls les ennemis conditionnent l'ouverture de la porte.
	if (remaining_enemies == 0 and not is_room_cleared):
		salle_actuelle.liberee = true
		is_room_cleared = true
		for porte in (salle_actuelle .get_node("Portes") .get_children()):
			porte.ouvrir()
		afficher_victoire()
		room_cleared.emit()

func afficher_victoire() -> void:
	informations_salle.mettre_a_jour(salle_actuelle.etage,
		indice_salle % SALLES_PAR_ETAGE + 1, SALLES_PAR_ETAGE, 0, 0, salle_actuelle.remaining_victims)
	informations_salle.afficher_salle_liberee()
	guidage_sortie.demarrer(joueur, salle_actuelle)

func afficher_message(texte: String) -> void:
	if animation_message:
		animation_message.kill()
	message_victoire.get_node("Texte").text = texte
	message_victoire.modulate.a = 0.0
	message_victoire.show()
	animation_message = create_tween()
	animation_message.tween_property(message_victoire, "modulate:a", 1.0, 0.4)
	animation_message.tween_interval(4.0)
	animation_message.tween_property(message_victoire, "modulate:a", 0.0, 0.6)
	animation_message.tween_callback(message_victoire.hide)

# Sortie

func _on_sortie_franchie(salle: Node3D) -> void:
	if (transition_en_cours or salle != salle_actuelle or not salle.liberee):
		return
	transition_en_cours = true
	call_deferred("preparer_sortie")

func compter_victimes_escorte_vivantes() -> int:
	var total := 0
	for victime in victim_manager.freed_victims:
		if (not is_instance_valid(victime) or victime.is_queued_for_deletion() or victime.est_morte):
			continue
		total += 1
	return total

func preparer_sortie() -> void:

	# Valider les défis avant de calculer les points et récompenses de la boutique.
	salle_terminee.emit(salle_actuelle)

	# Dernière salle : aucune amélioration intermédiaire.
	if (indice_salle + 1 >= salles.get_child_count()):
		passer_salle_suivante()
		return
	var nombre_victimes := compter_victimes_escorte_vivantes()
	choix_amelioration_demande.emit(nombre_victimes)

func passer_salle_suivante() -> void:
	if (indice_salle + 1 < salles.get_child_count()):
		await activer_salle(indice_salle + 1)
	else:
		# Compter les victimes encore vivantes avant que la scène du niveau soit détruite.
		SuccesManager.valider_victoire(compter_victimes_escorte_vivantes())
		get_tree().change_scene_to_file("res://scenes/interfaces/menus/ecran_victoire.tscn")

# Ajouter les participants du défi dans une salle déjà générée, sur des points libres.

func ajouter_population_defi(salle: Node3D, mobiles: int, victimes: int) -> Vector2i:
	var libres: Array[Vector3] = []
	for point in salle.points_spawn:
		if salle.mobiles_a_creer.has(point):
			continue
		var occupe := false
		for conteneur in [salle.get_node("Ennemis"), salle.get_node("Victimes")]:
			for entite in conteneur.get_children():
				if entite is Node3D:
					var ecart: Vector3 = entite.position - point
					ecart.y = 0.0
					if ecart.length() < 1.5:
						occupe = true
		if not occupe:
			libres.append(point)
	libres.shuffle()
	var ajoutes := Vector2i.ZERO

	# Réserver les victimes en premier pour ne pas perdre le bénéfice du défi.
	for i in range(mini(victimes, libres.size())):
		var victime = VICTIME_SCENE.instantiate()
		victime.position = libres.pop_back() + Vector3.UP * 0.75
		victime.bonus_dash = false
		victime.bonus_degats = false
		salle.get_node("Victimes").add_child(victime)
		victime.set_ennemis_container(salle.get_node("Ennemis"))
		victim_manager.surveiller_victime(victime)
		victime.freed.connect(_on_victim_freed.bind(salle), CONNECT_ONE_SHOT)
		victime.died.connect(_on_victim_died.bind(salle), CONNECT_ONE_SHOT)
		salle.remaining_victims += 1
		ajoutes.y += 1
	for i in range(mini(mobiles, libres.size())):
		salle.mobiles_a_creer.append(libres.pop_back())
		salle.remaining_enemies += 1
		ajoutes.x += 1
	return ajoutes

func liberer_salle_debug() -> void:
	if transition_en_cours or not is_instance_valid(salle_actuelle) or salle_actuelle.liberee:
		return
	var salle := salle_actuelle
	# Annuler les vagues sans créer des ennemis juste pour les supprimer ensuite.
	var en_attente: int = salle.mobiles_a_creer.size() + salle.mobiles_annonces.size()
	salle.remaining_enemies = maxi(salle.remaining_enemies - en_attente, 0)
	for annonce in salle.annonces_en_cours:
		if is_instance_valid(annonce):
			annonce.queue_free()
	salle.annonces_en_cours.clear()
	salle.mobiles_a_creer.clear()
	salle.mobiles_annonces.clear()
	salle.vagues_planifiees.clear()
	salle.apparitions_planifiees.clear()
	salle.apparitions_en_cours = 0
	# Arrêter le sauvetage sans appliquer ses dégâts de fin aux victimes.
	salle.sauvetage_en_cours = false
	salle.sauvetage_termine = true
	salle.temps_sauvetage_restant = 0.0
	timer_bar.value = 0.0
	timer_container.hide()
	for ennemi in salle.get_node("Ennemis").get_children():
		if not ennemi.is_queued_for_deletion() and ennemi.has_method("mourir"):
			ennemi.mourir()
	for conteneur in ["ProjectilesTour", "FlaquesDeFeu"]:
		for danger in salle.get_node(conteneur).get_children():
			danger.queue_free()
	# Utiliser la fin normale ouvre les portes, actualise le HUD et démarre le guidage.
	actualiser_objectifs()
