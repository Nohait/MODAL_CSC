extends "res://scenes/salles/room_manager.gd"

var difficulte: DifficulteZombie = preload("res://scenes/modes/zombie/equilibrage/difficulte_zombie.tres")
var map: PackedScene
var reprise_en_attente: Dictionary = {}
var vague_actuelle := 0
var vagues_terminees := 0
var temps_vague := 0.0
var pause_restante := 0.0
var vague_en_cours := false
var refuge: Node3D
var phase := "combat"
var calendrier: Array[Dictionary] = []
var composition_actuelle: CompositionVague
# Les annonces gardent leurs positions habituelles ; ce tableau leur associe un type.
var types_planifies: Dictionary = {}
# Les positions réservées restent des identifiants uniques du calendrier.
var entrees_planifiees: Dictionary = {}
var entrees: Array[EntreeEnnemisZombie] = []
var visuels_types: Dictionary = {}
@onready var evenements = get_node("../../EvenementsVague")
@onready var boutique = get_node("../../UpgradeManager")

func demarrer_partie() -> void:
	if initialized:
		return
	initialized = true
	guidage_sortie = GUIDAGE_SORTIE.new()
	add_child(guidage_sortie)
	# Une scène fixe remplace le générateur ; l’entrée et la navigation restent communes.
	if map == null: map = load("res://scenes/modes/zombie/maps/hall.tscn")
	var salle = map.instantiate()
	salle.process_mode = Node.PROCESS_MODE_DISABLED
	salle.hide()
	salles.add_child(salle)
	await get_tree().physics_frame
	refuge = preload("res://scenes/modes/zombie/victimes/refuge_zombie.tscn").instantiate()
	refuge.name = "Refuge"
	# Chaque arène peut placer le camion, sans déplacer les systèmes de jeu.
	if salle.get("position_refuge") is Vector3: refuge.position = salle.position_refuge
	salle.get_node("Navigation/Decor").add_child(refuge)
	refuge.escorte = victim_manager
	refuge.victime_perdue.connect(boutique.retours_bonus.afficher_victime_perdue)
	victim_manager.refuge = refuge
	boutique.boutique_fermee.connect(_apres_boutique)
	var acces: Node = salle.get_node_or_null("Navigation/Decor/EntreesEnnemis")
	if acces != null:
		for entree_mob in acces.get_children():
			if entree_mob is EntreeEnnemisZombie:
				entrees.append(entree_mob)
	await activer_salle(0)
	partie_prete.emit()

func demarrer_sauvetage(_salle: Node3D) -> void:
	# activer_salle appelle cette fonction après la course d'entrée du joueur.
	# Le sauvetage commence après la course d’entrée, comme dans le jeu principal.
	if not reprise_en_attente.is_empty():
		get_node("../../PointRepriseZombie").reprendre()
		var reprise := reprise_en_attente
		reprise_en_attente = {}
		_demarrer_vague(load(reprise.composition), reprise.graine)
	else:
		_demarrer_vague()

func _demarrer_vague(composition_forcee: CompositionVague = null, graine_reprise: int = -1) -> void:
	phase = "combat"
	vague_actuelle += 1
	temps_vague = 0.0
	vague_en_cours = true
	types_planifies.clear()
	entrees_planifiees.clear()
	for entree_mob in entrees:
		entree_mob.reinitialiser()
	# Le debug peut imposer une composition pour cette vague seulement.
	composition_actuelle = composition_forcee if composition_forcee != null else difficulte.choisir_composition(vague_actuelle)
	var graine := graine_reprise if graine_reprise >= 0 else randi()
	# Écrire AVANT le combat : quitter ne sauvegarde jamais les dégâts de cette vague.
	if not get_node("../../PointRepriseZombie").enregistrer(self, composition_actuelle, graine):
		boutique.retours_bonus._afficher_message("Sauvegarde impossible · reprise non garantie", preload("res://assets/textures/interfaces/ameliorations/pictogrammes/intervention_eclair.svg"))
	# Rejouer le même tirage au lancement d'une vague sauvegardée.
	seed(graine)
	evenements.commencer(composition_actuelle)
	var positions: Array[Vector3] = salle_actuelle.points_spawn.duplicate()
	positions.shuffle()
	# Réserver les places des captives avant celles des ennemis.
	var captives := randi_range(maxi(1, difficulte.victimes_minimum), maxi(difficulte.victimes_minimum, difficulte.victimes_maximum))
	salle_actuelle.remaining_victims = 0
	for i in range(mini(captives, maxi(0, positions.size() - 1))):
		var victime = VICTIME_SCENE.instantiate()
		victime.position = positions.pop_back() + Vector3.UP * 0.75
		salle_actuelle.get_node("Victimes").add_child(victime)
		victime.set_ennemis_container(salle_actuelle.get_node("Ennemis"))
		victim_manager.surveiller_victime(victime)
		victime.freed.connect(_on_victim_freed.bind(salle_actuelle), CONNECT_ONE_SHOT)
		victime.died.connect(_on_victim_died.bind(salle_actuelle), CONNECT_ONE_SHOT)
		salle_actuelle.remaining_victims += 1
	# Les tourelles prennent leurs places avant les sbires : pas de superposition.
	for i in range(difficulte.nombre_tourelles(vague_actuelle) if composition_actuelle.autoriser_tourelles else 0):
		if positions.size() <= 1: break # Garder un emplacement pour le premier sbire.
		var indice := -1
		for j in range(positions.size()):
			if emplacement_suffisamment_eloigne(salle_actuelle, positions[j]):
				indice = j
				break
		if indice == -1:
			break
		var emplacement: Vector3 = positions.pop_at(indice)
		var tour = TOUR_ENFLAMMEE_SCENE.instantiate()
		tour.set_script(preload("res://scenes/modes/zombie/ennemis/tour_zombie.gd"))
		tour.position = emplacement + Vector3.UP * 0.1
		tour.etage = 1
		tour.projectiles_tour = salle_actuelle.get_node("ProjectilesTour")
		salle_actuelle.get_node("Ennemis").add_child(tour)
		tour.died.connect(_on_enemy_died.bind(salle_actuelle), CONNECT_ONE_SHOT)
		salle_actuelle.remaining_enemies += 1
	var types := composition_actuelle.repartir(roundi(difficulte.budget_mobiles(vague_actuelle) * composition_actuelle.multiplicateur_budget), vague_actuelle)
	# Réserver une position par ennemi, sans recouvrir le camion ni un autre corps.
	for type in types:
		var indice := _trouver_position_type(type, positions)
		if indice == -1: continue
		var emplacement: Vector3 = positions.pop_at(indice)
		types_planifies[emplacement] = type
		salle_actuelle.mobiles_a_creer.append(emplacement)
	# Compter aussi les ennemis à venir empêche de finir la vague trop tôt.
	salle_actuelle.remaining_enemies += salle_actuelle.mobiles_a_creer.size()
	# La liste commence par le boss dans sa composition, sinon par un type mélangé.
	# Le boss arrive seul ; une vague ordinaire commence avec le groupe réglé dans la difficulté.
	var nombre_initial := 1 if composition_actuelle.ennemi_initial != null else difficulte.ennemis_au_depart
	for i in range(mini(nombre_initial, salle_actuelle.mobiles_a_creer.size())):
		creer_mobile(salle_actuelle, salle_actuelle.mobiles_a_creer.pop_front())
	# Le dernier groupe apparaît exactement à la fin du timer de sauvetage.
	calendrier.clear()
	var duree := randf_range(difficulte.duree_minimum_vague, maxf(difficulte.duree_minimum_vague, difficulte.duree_maximum_vague))
	salle_actuelle.duree_sauvetage = duree
	salle_actuelle.temps_sauvetage_restant = duree
	salle_actuelle.sauvetage_en_cours = true
	salle_actuelle.sauvetage_termine = false
	var groupes := ceili(float(salle_actuelle.mobiles_a_creer.size()) / difficulte.taille_groupe(vague_actuelle))
	for i in range(groupes):
		var echeance := duree * float(i + 1) / groupes
		calendrier.append({"annonce": maxf(0, echeance - minf(_duree_entrees(), duree / groupes * 0.85)), "apparition": echeance})
	informations_salle.demarrer_timer()
	timer_bar.max_value = duree
	timer_bar.value = duree
	salle_commencee.emit(salle_actuelle)
	actualiser_objectifs()

func _process(delta: float) -> void:
	if transition_en_cours or not is_instance_valid(salle_actuelle):
		return
	if not vague_en_cours:
		if phase == "boutique": return
		pause_restante = maxf(0, pause_restante - delta)
		if pause_restante == 0:
			if phase == "avant_boutique":
				phase = "boutique"
				boutique.ouvrir_choix(0)
			else:
				_demarrer_vague()
		actualiser_objectifs()
		return
	temps_vague += delta
	for groupe in calendrier.duplicate():
		if temps_vague >= groupe.annonce:
			calendrier.erase(groupe)
			creer_vague(difficulte.taille_groupe(vague_actuelle), groupe.apparition)
	for apparition in salle_actuelle.apparitions_planifiees.duplicate():
		if temps_vague >= apparition.restant:
			salle_actuelle.apparitions_planifiees.erase(apparition)
			_terminer_apparition(salle_actuelle, apparition.position)
	if salle_actuelle.sauvetage_en_cours:
		actualiser_sauvetage(delta)
	actualiser_objectifs()

func _apres_boutique() -> void:
	phase = "apres_boutique"
	pause_restante = difficulte.delai_apres_boutique
	actualiser_objectifs()

func actualiser_objectifs() -> void:
	if not is_instance_valid(salle_actuelle):
		return
	remaining_enemies = salle_actuelle.remaining_enemies
	if vague_en_cours and remaining_enemies == 0 and not salle_actuelle.sauvetage_en_cours:
		vague_en_cours = false
		evenements.fin_vague()
		vagues_terminees += 1
		phase = "avant_boutique"
		pause_restante = difficulte.delai_avant_boutique
		var victoire = get_node("../../VictoireBoss")
		if victoire.temps_restant > 0.0:
			pause_restante = maxf(pause_restante, victoire.temps_restant + victoire.marge_avant_boutique)
		# Compter au moment de la victoire, avant la pause et les dépôts suivants.
		salle_terminee.emit(salle_actuelle)
		boutique.points = refuge.victimes.size()
		_nettoyer_dangers()
	# Reprendre le HUD existant ; les portes restent fermées pendant la survie.
	informations_salle.objectifs.text = "VAGUE %d · %s" % [vague_actuelle, composition_actuelle.titre.to_upper()]
	informations_salle.ennemis.text = "%d ENNEMIS RESTANTS · %d À VENIR" % [remaining_enemies, salle_actuelle.mobiles_a_creer.size() + salle_actuelle.mobiles_annonces.size()] if vague_en_cours else ("BOUTIQUE DANS %d s" if phase == "avant_boutique" else "PROCHAINE VAGUE DANS %d s") % ceili(pause_restante)
	informations_salle.victimes_a_liberer = salle_actuelle.remaining_victims
	informations_salle._actualiser_timer(timer_bar.value)
	timer_container.visible = salle_actuelle.sauvetage_en_cours

func _nettoyer_dangers() -> void:
	# Les tirs et flaques des tourelles ne doivent pas s'accumuler entre les vagues.
	for nom in ["ProjectilesTour", "FlaquesDeFeu"]:
		for danger in salle_actuelle.get_node(nom).get_children():
			danger.queue_free()

func aller_vague_debug(numero: int, composition_forcee: CompositionVague = null) -> void:
	if transition_en_cours or not is_instance_valid(salle_actuelle):
		return
	evenements.terminer()
	# La fonction héritée annule aussi les annonces et les mobiles encore à venir.
	liberer_salle_debug()
	for captive in salle_actuelle.get_node("Victimes").get_children():
		if captive.is_in_group("victime"): captive.queue_free()
	calendrier.clear()
	vague_actuelle = maxi(1, numero) - 1
	_demarrer_vague(composition_forcee)

func creer_mobile(salle: Node3D, emplacement: Vector3) -> void:
	# Le système commun appelle ce point d'entrée pour chaque apparition annoncée.
	if types_planifies.has(emplacement):
		var type: TypeEnnemiVague = types_planifies[emplacement]
		types_planifies.erase(emplacement)
		if entrees_planifiees.has(emplacement):
			var arrivee: Dictionary = entrees_planifiees[emplacement]
			entrees_planifiees.erase(emplacement)
			# Le vrai ennemi prend la place du figurant seulement une fois dans la salle.
			emplacement = salle.to_local(arrivee.destination) - Vector3.UP * type.hauteur
			var ennemi := _creer_type(salle, emplacement, type)
			ennemi.rotation.y = arrivee.entree.global_rotation.y
			var entree_mob: EntreeEnnemisZombie = arrivee.entree
			var encore_utilisee := false
			for autre in entrees_planifiees.values():
				if autre.entree == entree_mob: encore_utilisee = true
			if not encore_utilisee: entree_mob.terminer()
		elif not salle.sauvetage_en_cours:
			# Premier adversaire présent dès le départ, avec une porte qui s'ouvre progressivement.
			var entree_mob := _choisir_entree(type, entrees.filter(func(entree_mob): return entree_mob.type_entree == "ascenseur"))
			if entree_mob != null:
				entree_mob.ouvrir_pour_arrivee_immediate()
				var destination := entree_mob.to_global(Vector3(0, type.hauteur, entree_mob.distance_sortie))
				destination = _destination_libre(type, entree_mob, destination)
				emplacement = salle.to_local(destination) - Vector3.UP * type.hauteur
			var ennemi := _creer_type(salle, emplacement, type)
			if entree_mob != null: ennemi.rotation.y = entree_mob.global_rotation.y
		else:
			_creer_type(salle, emplacement, type)
		return
	super.creer_mobile(salle, emplacement)

func creer_sbire(salle: Node3D, emplacement: Vector3) -> Node3D:
	# Un sbire ajouté par le debug n'appartient pas au calendrier de la vague.
	var sbire = SBIRE_SCENE.instantiate()
	sbire.set_script(preload("res://scenes/modes/zombie/ennemis/sbire_zombie.gd"))
	sbire.etage = 1
	sbire.position = emplacement + Vector3.UP * 0.75
	salle.get_node("Ennemis").add_child(sbire)
	sbire.get_node("NavigationAgent").set_navigation_map(salle.carte_ennemis)
	sbire.died.connect(_on_enemy_died.bind(salle), CONNECT_ONE_SHOT)
	sbire.add_child(preload("res://scenes/effets/apparition/apparition_sbire.tscn").instantiate())
	return sbire

func peut_creer_ennemi_debug() -> bool:
	return is_instance_valid(salle_actuelle) and not transition_en_cours and vague_en_cours

func _trouver_position_type(type: TypeEnnemiVague, positions: Array[Vector3], orientation := 0.0) -> int:
	var modele = type.scene.instantiate()
	var collision: CollisionShape3D = modele.get_node("CollisionShape3D")
	var requete := PhysicsShapeQueryParameters3D.new()
	requete.shape = collision.shape
	requete.collision_mask = 15
	var resultat := -1
	modele.rotation.y = orientation
	for i in range(positions.size()):
		if not emplacement_suffisamment_eloigne(salle_actuelle, positions[i]): continue
		modele.position = positions[i] + Vector3.UP * type.hauteur
		requete.transform = salle_actuelle.global_transform * modele.transform * collision.transform
		if salle_actuelle.get_world_3d().direct_space_state.intersect_shape(requete, 1).is_empty():
			resultat = i
			break
	modele.free()
	return resultat

func _creer_type(salle: Node3D, emplacement: Vector3, type: TypeEnnemiVague) -> Node3D:
	var ennemi = type.scene.instantiate()
	if type.script_zombie != null: ennemi.set_script(type.script_zombie)
	# Le butin utilise exactement le coût retenu par cette composition.
	ennemi.set_meta("valeur_pieces", type.cout_difficulte)
	# La difficulté augmente le nombre d'ennemis, pas leurs PV ni leurs dégâts.
	ennemi.etage = 1
	ennemi.position = emplacement + Vector3.UP * type.hauteur
	ennemi.died.connect(_on_enemy_died.bind(salle), CONNECT_ONE_SHOT)
	salle.get_node("Ennemis").add_child(ennemi)
	if ennemi.has_signal("mort_mise_en_scene"):
		get_node("../../VictoireBoss").suivre(ennemi)
	relier_invocation(ennemi, salle)
	var agent = ennemi.get_node_or_null("NavigationAgent")
	if agent != null: agent.set_navigation_map(salle.carte_ennemis)
	return ennemi

func _duree_entrees() -> float:
	var duree := duree_annonce
	for entree_mob in entrees:
		duree = maxf(duree, entree_mob.duree_arrivee)
	return duree

func _choisir_entree(type: TypeEnnemiVague, exclues: Array) -> EntreeEnnemisZombie:
	var possibles: Array[EntreeEnnemisZombie] = []
	for entree_mob in entrees:
		if vague_actuelle < entree_mob.premiere_vague: continue
		if entree_mob.type_entree == "ascenseur" and (entree_mob.fermeture_restante > 0.0 or entree_mob.remontee_restante > 0.0):
			continue # Laisser la cabine vide repartir avant d'y charger le groupe suivant.
		if entree_mob.accepte(type) and not entree_mob.occupee and not exclues.has(entree_mob):
			possibles.append(entree_mob)
	if possibles.is_empty(): return null
	# Préférer une entrée éloignée du joueur, sans rendre la vague dépendante de lui.
	var eloignees := possibles.filter(func(entree_mob): return entree_mob.global_position.distance_to(joueur.global_position) >= distance_securite_spawn)
	return possibles.pick_random() if eloignees.is_empty() else eloignees.pick_random()

func creer_vague(nombre_prevu: int, echeance: float) -> void:
	if entrees.is_empty():
		super.creer_vague(nombre_prevu, echeance)
		return
	var groupes: Dictionary = {}
	for i in range(mini(nombre_prevu, salle_actuelle.mobiles_a_creer.size())):
		var emplacement: Vector3 = salle_actuelle.mobiles_a_creer.pop_front()
		var type: TypeEnnemiVague = types_planifies[emplacement]
		var entree_mob: EntreeEnnemisZombie
		# Compléter une cabine ou une porte déjà choisie pour ce même groupe.
		for candidate in groupes:
			if candidate.accepte(type) and groupes[candidate] < candidate.capacite:
				entree_mob = candidate
				break
		if entree_mob == null:
			entree_mob = _choisir_entree(type, groupes.keys())
			if entree_mob != null:
				groupes[entree_mob] = 0
				entree_mob.preparer(echeance - temps_vague)
		if entree_mob != null:
			var visuel := _visuel_type(type)
			var destination := entree_mob.ajouter_visuel(visuel, type.hauteur, groupes[entree_mob])
			destination = _destination_libre(type, entree_mob, destination)
			entree_mob.passages.back().destination = entree_mob.to_local(destination)
			groupes[entree_mob] += 1
			entrees_planifiees[emplacement] = {"entree": entree_mob, "destination": destination}
		else:
			# Une map sans entrée compatible conserve l'annonce classique, jamais un ennemi perdu.
			var annonce = ANNONCE_SCENE.instantiate()
			annonce.position = emplacement + Vector3.UP * 0.13
			annonce.duree = maxf(0.01, echeance - temps_vague)
			salle_actuelle.annonces_en_cours.append(annonce)
			annonce.terminee.connect(salle_actuelle.annonces_en_cours.erase.bind(annonce), CONNECT_ONE_SHOT)
			salle_actuelle.add_child(annonce)
		salle_actuelle.mobiles_annonces.append(emplacement)
		salle_actuelle.apparitions_en_cours += 1
		salle_actuelle.apparitions_planifiees.append({"position": emplacement, "restant": echeance})
	actualiser_objectifs()

func _visuel_type(type: TypeEnnemiVague) -> Node3D:
	if not visuels_types.has(type.scene):
		# _ready ajuste les modèles importés : le laisser préparer une instance inerte.
		var modele = type.scene.instantiate()
		modele.process_mode = Node.PROCESS_MODE_DISABLED
		modele.hide()
		for noeud in [modele] + modele.find_children("*", "", true, false):
			for groupe in noeud.get_groups(): noeud.remove_from_group(groupe)
			if noeud is CollisionShape3D: noeud.disabled = true
		add_child(modele)
		var visuel := Node3D.new()
		for nom in ["Sketchfab_Scene", "Flammes"]:
			var partie = modele.get_node_or_null(nom)
			if partie != null:
				# Sans scripts ni groupes, la copie n'est qu'une présentation du modèle.
				visuel.add_child(partie.duplicate(0))
		if is_instance_valid(modele.get("cible_idle")): modele.cible_idle.queue_free()
		modele.queue_free()
		visuels_types[type.scene] = visuel
	var copie: Node3D = visuels_types[type.scene].duplicate(0)
	# Les figurants qui sortent des portes annoncent aussi leur version dorée.
	if composition_actuelle.evenement == "doree":
		var effet = preload("res://scenes/systemes/ennemis/ennemi_dore.gd").new()
		effet.name = "Dore"
		copie.add_child(effet)
	return copie

func liberer_salle_debug() -> void:
	if transition_en_cours or not is_instance_valid(salle_actuelle) or salle_actuelle.liberee:
		return
	for entree_mob in entrees:
		entree_mob.reinitialiser()
	entrees_planifiees.clear()
	types_planifies.clear()
	calendrier.clear()
	super.liberer_salle_debug()

func _destination_libre(type: TypeEnnemiVague, entree_mob: EntreeEnnemisZombie, destination: Vector3) -> Vector3:
	var candidats: Array[Vector3] = []
	# Chercher près du seuil, en tenant compte des captives, tourelles et autres arrivées.
	for avance in [0.0, 1.8, 3.6]:
		for cote in [0.0, -1.8, 1.8]:
			var position_monde := destination + entree_mob.global_basis * Vector3(cote, 0, avance)
			var trop_proche := false
			for arrivee in entrees_planifiees.values():
				if position_monde.distance_to(arrivee.destination) < 2.3:
					trop_proche = true
			if not trop_proche:
				candidats.append(salle_actuelle.to_local(position_monde) - Vector3.UP * type.hauteur)
	var indice := _trouver_position_type(type, candidats, entree_mob.global_rotation.y)
	return destination if indice == -1 else salle_actuelle.to_global(candidats[indice] + Vector3.UP * type.hauteur)

func _exit_tree() -> void:
	# Les modèles de présentation conservés hors de l'arbre doivent aussi être libérés.
	for visuel in visuels_types.values():
		visuel.free()


func preparer_entree_salle() -> bool:
	reprise_en_attente = SauvegardeZombie.consommer_reprise()
	if reprise_en_attente.is_empty():
		var introduction := salle_actuelle.get_node_or_null("IntroductionHall")
		if introduction != null:
			introduction.preparer(joueur)
			camera_rig.recentrer()
		return true
	var point_reprise = get_node("../../PointRepriseZombie")
	point_reprise.restaurer(self, reprise_en_attente)
	point_reprise.figer_pendant_fondu(self)
	var introduction := salle_actuelle.get_node_or_null("IntroductionHall")
	if introduction != null: introduction.retablir_grille()
	return false

func jouer_entree_salle(arrivee: Vector3) -> void:
	var introduction := salle_actuelle.get_node_or_null("IntroductionHall")
	if introduction != null and introduction.preparee:
		get_node("../../MusiqueZombie").commencer_introduction()
		await introduction.jouer(arrivee)
	else:
		await super.jouer_entree_salle(arrivee)
