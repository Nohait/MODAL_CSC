extends "res://scenes/salles/room_manager.gd"

var difficulte: DifficulteZombie = preload("res://scenes/modes/zombie/equilibrage/difficulte_zombie.tres")
var map: PackedScene = preload("res://scenes/modes/zombie/maps/map_test.tscn")
var vague_actuelle := 0
var vagues_terminees := 0
var temps_vague := 0.0
var pause_restante := 0.0
var vague_en_cours := false
var refuge: Node3D
var phase := "combat"
var calendrier: Array[Dictionary] = []
@onready var boutique = get_node("../../UpgradeManager")

func demarrer_partie() -> void:
	if initialized:
		return
	initialized = true
	guidage_sortie = GUIDAGE_SORTIE.new()
	add_child(guidage_sortie)
	# Une scène fixe remplace le générateur ; l’entrée et la navigation restent communes.
	var salle = map.instantiate()
	salle.process_mode = Node.PROCESS_MODE_DISABLED
	salle.hide()
	salles.add_child(salle)
	await get_tree().physics_frame
	refuge = preload("res://scenes/modes/zombie/victimes/refuge_zombie.tscn").instantiate()
	refuge.name = "Refuge"
	salle.get_node("Navigation/Decor").add_child(refuge)
	refuge.escorte = victim_manager
	victim_manager.refuge = refuge
	boutique.boutique_fermee.connect(_apres_boutique)
	await activer_salle(0)
	partie_prete.emit()

func demarrer_sauvetage(_salle: Node3D) -> void:
	# activer_salle appelle cette fonction après la course d'entrée du joueur.
	# Le sauvetage commence après la course d’entrée, comme dans le jeu principal.
	_demarrer_vague()

func _demarrer_vague() -> void:
	phase = "combat"
	vague_actuelle += 1
	temps_vague = 0.0
	vague_en_cours = true
	var positions: Array[Vector3] = salle_actuelle.points_spawn.duplicate()
	positions.shuffle()
	# Réserver les places des captives avant celles des ennemis.
	var captives := randi_range(maxi(1, difficulte.victimes_minimum), maxi(difficulte.victimes_minimum, difficulte.victimes_maximum))
	salle_actuelle.remaining_victims = 0
	for i in range(mini(captives, positions.size())):
		var victime = VICTIME_SCENE.instantiate()
		victime.position = positions.pop_back() + Vector3.UP * 0.75
		salle_actuelle.get_node("Victimes").add_child(victime)
		victime.set_ennemis_container(salle_actuelle.get_node("Ennemis"))
		victim_manager.surveiller_victime(victime)
		victime.freed.connect(_on_victim_freed.bind(salle_actuelle), CONNECT_ONE_SHOT)
		victime.died.connect(_on_victim_died.bind(salle_actuelle), CONNECT_ONE_SHOT)
		salle_actuelle.remaining_victims += 1
	# Les tourelles prennent leurs places avant les sbires : pas de superposition.
	for i in range(difficulte.nombre_tourelles(vague_actuelle)):
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
	var nombre := mini(difficulte.nombre_sbires(vague_actuelle), positions.size())
	for i in range(nombre):
		salle_actuelle.mobiles_a_creer.append(positions[i])
	# Compter aussi les ennemis à venir empêche de finir la vague trop tôt.
	salle_actuelle.remaining_enemies += nombre
	# Le dernier groupe apparaît exactement à la fin du timer de sauvetage.
	calendrier.clear()
	var duree := randf_range(difficulte.duree_minimum_vague, maxf(difficulte.duree_minimum_vague, difficulte.duree_maximum_vague))
	salle_actuelle.duree_sauvetage = duree
	salle_actuelle.temps_sauvetage_restant = duree
	salle_actuelle.sauvetage_en_cours = true
	salle_actuelle.sauvetage_termine = false
	var groupes := ceili(float(nombre) / difficulte.taille_groupe(vague_actuelle))
	for i in range(groupes):
		var echeance := duree * float(i + 1) / groupes
		calendrier.append({"annonce": maxf(0, echeance - duree_annonce), "apparition": echeance})
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
		vagues_terminees += 1
		phase = "avant_boutique"
		pause_restante = difficulte.delai_avant_boutique
		# Compter au moment de la victoire, avant la pause et les dépôts suivants.
		salle_terminee.emit(salle_actuelle)
		boutique.points += refuge.victimes.size()
		_nettoyer_dangers()
	# Reprendre le HUD existant ; les portes restent fermées pendant la survie.
	informations_salle.objectifs.text = "MODE ZOMBIE · VAGUE %d" % vague_actuelle
	informations_salle.ennemis.text = "%d ENNEMIS RESTANTS · %d À VENIR" % [remaining_enemies, salle_actuelle.mobiles_a_creer.size() + salle_actuelle.mobiles_annonces.size()] if vague_en_cours else ("BOUTIQUE DANS %d s" if phase == "avant_boutique" else "PROCHAINE VAGUE DANS %d s") % ceili(pause_restante)
	informations_salle.victimes_a_liberer = salle_actuelle.remaining_victims
	informations_salle._actualiser_timer(timer_bar.value)
	timer_container.visible = salle_actuelle.sauvetage_en_cours

func _nettoyer_dangers() -> void:
	# Les tirs et flaques des tourelles ne doivent pas s'accumuler entre les vagues.
	for nom in ["ProjectilesTour", "FlaquesDeFeu"]:
		for danger in salle_actuelle.get_node(nom).get_children():
			danger.queue_free()

func aller_vague_debug(numero: int) -> void:
	if transition_en_cours or not is_instance_valid(salle_actuelle):
		return
	# La fonction héritée annule aussi les annonces et les sbires encore à venir.
	liberer_salle_debug()
	for captive in salle_actuelle.get_node("Victimes").get_children():
		if captive.is_in_group("victime"): captive.queue_free()
	calendrier.clear()
	vague_actuelle = maxi(1, numero) - 1
	_demarrer_vague()

func creer_sbire(salle: Node3D, emplacement: Vector3) -> void:
	var sbire = SBIRE_SCENE.instantiate()
	sbire.set_script(preload("res://scenes/modes/zombie/ennemis/sbire_zombie.gd"))
	sbire.etage = 1
	sbire.position = emplacement + Vector3.UP * 0.75
	salle.get_node("Ennemis").add_child(sbire)
	sbire.get_node("NavigationAgent").set_navigation_map(salle.carte_ennemis)
	sbire.died.connect(_on_enemy_died.bind(salle), CONNECT_ONE_SHOT)
