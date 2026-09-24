extends Node

signal room_cleared
signal partie_prete

const ENNEMI_SCENE = preload("res://scenes/ennemis/mobiles/ennemi.tscn")
const ANNONCE_SCENE = preload("res://scenes/effets/apparition/annonce_apparition.tscn")
const TOUR_ENFLAMMEE_SCENE = preload("res://scenes/ennemis/tourelles/tour_enflammee.tscn")
const FLAQUE_SCENE = preload("res://scenes/ennemis/dangers/flaque_de_feu.tscn")
const VICTIME_SCENE = preload("res://scenes/victimes/victime.tscn")
const EVACUATION_SCENE = preload("res://scenes/victimes/evacuation/point_evacuation.tscn")

@export_group("Parcours")
## Chaque nouvelle partie génère de nouvelles salles, sans graine fixe.
@export_range(1, 6, 1) var nombre_salles := 3
@export_group("Population des salles")
@export_range(0, 20, 1) var nombre_min_ennemis := 3
@export_range(0, 20, 1) var nombre_max_ennemis := 6
@export_range(0,10,1) var nombre_min_tour_enflammee := 0
@export_range(0,10,1) var nombre_max_tour_enflammee := 2
@export_range(0, 10, 1) var nombre_min_flaques := 0
@export_range(0, 10, 1) var nombre_max_flaques := 3
@export_group("Vagues des ennemis mobiles")
## La première vague arrive après ce même délai ; les suivantes peuvent se chevaucher.
@export_range(1, 5, 1) var taille_min_vague := 1
@export_range(1, 5, 1) var taille_max_vague := 3
@export_range(0.2, 30.0, 0.1) var delai_vagues := 4.0
## Temps pendant lequel le cercle prévient le joueur avant l'apparition.
@export_range(0.2, 3.0, 0.1) var duree_annonce := 1.0
## Distance horizontale minimale entre le joueur et un nouvel ennemi.
@export_range(1.5, 10.0, 0.5) var distance_securite_spawn := 3.0
@export_group("Victimes présentes dès le début")
@export_range(0, 5, 1) var nombre_min_victimes := 0
@export_range(0, 5, 1) var nombre_max_victimes := 3
## Poids relatifs : 8/1/1 donne 80 % sans bonus, 10 % dash et 10 % dégâts.
@export_range(0, 100, 1) var poids_sans_bonus := 8
@export_range(0, 100, 1) var poids_dash := 1
@export_range(0, 100, 1) var poids_degats := 1

@onready var generateur = $"../RoomGenerator"
@onready var salles: Node3D = $"../Rooms"
@onready var joueur = $"../../player"
@onready var camera_rig = $"../../CameraRig"
@onready var victim_manager = $"../../VictimManager"
@onready var objectifs: Label = $InterfaceSalle/Objectifs
@onready var message_victoire: PanelContainer = $InterfaceSalle/MessageVictoire

var salle_actuelle: Node3D
var indice_salle := -1
var transition_en_cours := false
var initialized := false
var animation_message: Tween

# Ces valeurs reflètent seulement la salle active, pour l'interface et les tests.
var remaining_victims := 0
var remaining_enemies := 0
var is_room_cleared := false


func demarrer_partie() -> void:
	if initialized:
		return
	initialized = true
	transition_en_cours = true
	joueur.set_physics_process(false)
	objectifs.text = "Génération des salles…"
	# Le même joueur et son escorte restent hors de Rooms toute la partie.
	for i in range(nombre_salles):
		var salle = generateur.generer_salle(1 + nombre_salles * maxi(nombre_min_victimes, nombre_max_victimes))
		salle.name = "Salle%d" % (i + 1)
		# Salles éloignées pour que leurs collisions ne se superposent jamais.
		salle.position.x = i * 150.0
		salle.process_mode = Node.PROCESS_MODE_DISABLED
		salle.hide()
		salles.add_child(salle)
		peupler_salle(salle)
		salle.sortie_franchie.connect(_on_sortie_franchie)
	# Les serveurs de physique et navigation doivent synchroniser les nouveaux nœuds.
	await get_tree().physics_frame
	await get_tree().physics_frame
	await activer_salle(0)
	partie_prete.emit()


func peupler_salle(salle: Node3D) -> void:
	# Les cases de départ, de porte et de caisse ont déjà été retirées de cette liste.
	var emplacements: Array[Vector3] = salle.points_spawn.duplicate()
	emplacements.shuffle()
	# Une borne par salle. Sa référence est attribuée AVANT add_child et son _ready.
	if not emplacements.is_empty():
		var borne = EVACUATION_SCENE.instantiate()
		borne.name = "PointEvacuation"
		borne.victim_manager = victim_manager
		borne.position = emplacements.pop_back() + Vector3.UP * 0.1
		salle.get_node("Navigation/Decor").add_child(borne)
		# Always serait prioritaire sur le mode Disabled de la salle inactive.
		borne.process_mode = Node.PROCESS_MODE_DISABLED
	var nombre_victimes := randi_range(nombre_min_victimes, maxi(nombre_min_victimes, nombre_max_victimes))
	for i in range(mini(nombre_victimes, emplacements.size())):
		var victime = VICTIME_SCENE.instantiate()
		victime.name = "Victime%d" % (i + 1)
		victime.position = emplacements.pop_back() + Vector3.UP * 0.75
		attribuer_bonus(victime)
		salle.get_node("Victimes").add_child(victime)
		# Les victimes sont créées après _ready du gestionnaire : les inscrire explicitement.
		victim_manager.surveiller_victime(victime)
		victime.freed.connect(_on_victim_freed.bind(salle), CONNECT_ONE_SHOT)
		salle.remaining_victims += 1
	# Fixes : présents dès l'entrée, chacun sur une case libre distincte.
	var nombre_tours := mini(randi_range(nombre_min_tour_enflammee, maxi(nombre_min_tour_enflammee, nombre_max_tour_enflammee)), emplacements.size())
	for i in range(nombre_tours):
		var tour = TOUR_ENFLAMMEE_SCENE.instantiate()
		tour.position = emplacements.pop_back() + Vector3.UP * 0.1
		tour.projectiles_tour = salle.get_node("ProjectilesTour")
		salle.get_node("Ennemis").add_child(tour)
		tour.died.connect(_on_enemy_died.bind(salle), CONNECT_ONE_SHOT)
		salle.remaining_enemies += 1
	var nombre_flaques := mini(randi_range(nombre_min_flaques, maxi(nombre_min_flaques, nombre_max_flaques)), emplacements.size())
	for i in range(nombre_flaques):
		var flaque = FLAQUE_SCENE.instantiate()
		flaque.position = emplacements.pop_back() + Vector3.UP * 0.2
		salle.get_node("Ennemis").add_child(flaque)
		# Seules les flaques initiales comptent, pas celles produites par les tirs.
		flaque.died.connect(_on_enemy_died.bind(salle), CONNECT_ONE_SHOT)
		salle.remaining_enemies += 1
	# Compter les mobiles prévus dès maintenant : aucune victoire entre deux vagues.
	var nombre := mini(randi_range(nombre_min_ennemis, maxi(nombre_min_ennemis, nombre_max_ennemis)), emplacements.size())
	for i in range(nombre):
		salle.mobiles_a_creer.append(emplacements.pop_back())
	salle.remaining_enemies += nombre


func attribuer_bonus(victime: Node) -> void:
	victime.bonus_dash = false
	victime.bonus_degats = false
	var total := poids_sans_bonus + poids_dash + poids_degats
	if total == 0:
		return # Tous les poids nuls : aucun bonus.
	# Avec 8/1/1 : tickets 0..7 = aucun, 8 = dash, 9 = dégâts.
	var ticket := randi_range(0, total - 1)
	if ticket < poids_sans_bonus:
		return
	elif ticket < poids_sans_bonus + poids_dash:
		victime.bonus_dash = true
	else:
		victime.bonus_degats = true


func _process(delta: float) -> void:
	# Hérite de la pause : le compte à rebours s'arrête dans les menus.
	if transition_en_cours or not is_instance_valid(salle_actuelle):
		return
	if salle_actuelle.mobiles_a_creer.is_empty():
		return
	salle_actuelle.temps_avant_vague -= delta
	if salle_actuelle.temps_avant_vague <= 0.0:
		creer_vague()
		salle_actuelle.temps_avant_vague = delai_vagues


func creer_vague() -> void:
	var nombre := mini(randi_range(taille_min_vague, maxi(taille_min_vague, taille_max_vague)), salle_actuelle.mobiles_a_creer.size())
	for i in range(nombre):
		var indice := trouver_emplacement_eloigne(salle_actuelle)
		if indice == -1:
			break # Toutes les places sont trop proches : réessayer à la prochaine vague.
		var emplacement: Vector3 = salle_actuelle.mobiles_a_creer[indice]
		# Retirer la place empêche une autre vague de l'annoncer en même temps.
		# L'ennemi reste néanmoins « à venir » grâce au compteur des animations.
		salle_actuelle.mobiles_a_creer.remove_at(indice)
		salle_actuelle.apparitions_en_cours += 1
		var annonce = ANNONCE_SCENE.instantiate()
		annonce.position = emplacement + Vector3.UP * 0.13 # Juste au-dessus du sol.
		annonce.duree = duree_annonce
		# bind ajoute ces deux arguments au signal terminee, qui n'en fournit aucun.
		# Chaque cercle conserve ainsi SA salle et SA position, même après la boucle.
		# CONNECT_ONE_SHOT déconnecte cet appel après la première émission du signal.
		annonce.terminee.connect(_terminer_apparition.bind(salle_actuelle, emplacement), CONNECT_ONE_SHOT)
		# L'ajout à l'arbre déclenche _ready(), donc démarre le Tween du cercle.
		# C'est pourquoi la durée et la connexion ont été préparées AVANT cette ligne.
		salle_actuelle.add_child(annonce)
	actualiser_objectifs()


func emplacement_suffisamment_eloigne(salle: Node3D, emplacement: Vector3) -> bool:
	if not is_instance_valid(joueur):
		return false
	var ecart: Vector3 = salle.to_global(emplacement) - joueur.global_position
	ecart.y = 0.0 # Le saut du joueur ne doit pas autoriser une apparition sous lui.
	return ecart.length() >= distance_securite_spawn


func trouver_emplacement_eloigne(salle: Node3D) -> int:
	# Parcourir les cases déjà réservées garantit de rester sur le sol, hors des caisses.
	for i in range(salle.mobiles_a_creer.size()):
		if emplacement_suffisamment_eloigne(salle, salle.mobiles_a_creer[i]):
			return i
	return -1


func _terminer_apparition(salle: Node3D, emplacement: Vector3) -> void:
	salle.apparitions_en_cours -= 1
	# Une fois le cercle lancé, l'apparition est confirmée même si le joueur approche.
	# Seul un changement de salle reporte encore la création de l'ennemi.
	if salle != salle_actuelle or transition_en_cours:
		salle.mobiles_a_creer.append(emplacement)
	else:
		var ennemi = ENNEMI_SCENE.instantiate()
		ennemi.position = emplacement + Vector3.UP * 0.75
		salle.get_node("Ennemis").add_child(ennemi)
		ennemi.died.connect(_on_enemy_died.bind(salle), CONNECT_ONE_SHOT)
		# Déjà compté à la préparation de la salle : ne pas ajouter au total.
	if salle == salle_actuelle:
		actualiser_objectifs()


func activer_salle(indice: int) -> void:
	transition_en_cours = true
	joueur.set_physics_process(false)
	$"../../Escorte".process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(salle_actuelle):
		salle_actuelle.process_mode = Node.PROCESS_MODE_DISABLED
		salle_actuelle.hide()
		salle_actuelle.get_node("Navigation").enabled = false
		var ancienne_borne = salle_actuelle.get_node_or_null("Navigation/Decor/PointEvacuation")
		if ancienne_borne:
			ancienne_borne.process_mode = Node.PROCESS_MODE_DISABLED
	indice_salle = indice
	salle_actuelle = salles.get_child(indice)
	# Le décor doit être actif pour préparer la navigation, mais le combat attend.
	salle_actuelle.get_node("Ennemis").process_mode = Node.PROCESS_MODE_DISABLED
	salle_actuelle.get_node("Victimes").process_mode = Node.PROCESS_MODE_DISABLED
	if animation_message:
		animation_message.kill()
	message_victoire.hide()
	salle_actuelle.show()
	# Réactiver la salle avant la synchronisation : une région sous un parent
	# Disabled n'est pas utilisable par le serveur de navigation.
	salle_actuelle.process_mode = Node.PROCESS_MODE_INHERIT
	salle_actuelle.get_node("Navigation").enabled = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Le décor des trois salles existe déjà. Cuire le chemin de la salle active
	# après sa réactivation pour que ses collisions soient prises en compte.
	salle_actuelle.cuire_navigation()
	# Téléporter les mêmes personnages conserve leur état et leurs bonus.
	joueur.global_position = salle_actuelle.to_global(salle_actuelle.points_arrivee[0]) + Vector3.UP * 1.1
	joueur.velocity = Vector3.ZERO
	joueur.is_dashing = false
	joueur.dash_time_left = 0.0
	for i in range(victim_manager.freed_victims.size()):
		var victime = victim_manager.freed_victims[i]
		victime.global_position = salle_actuelle.to_global(salle_actuelle.points_arrivee[i + 1]) + Vector3.UP * 0.75
		victime.velocity = Vector3.ZERO
		victime.player_nearby = false
		victime.navigation_agent.target_position = victime.global_position
	# Une transition doit recadrer immédiatement, sans traverser le vide entre les salles.
	camera_rig.recentrer()
	# Le serveur prépare les chemins en arrière-plan. Deux images ne suffisent
	# pas toujours : attendre qu'un trajet entre deux places de départ existe.
	var carte: RID = salle_actuelle.get_world_3d().navigation_map
	var arrivee: Vector3 = salle_actuelle.to_global(salle_actuelle.points_arrivee[1])
	for tentative in range(300):
		await get_tree().physics_frame
		if not NavigationServer3D.map_get_path(carte, joueur.global_position, arrivee, true).is_empty():
			break
		if tentative == 299:
			push_error("La navigation de la salle n'a pas pu être initialisée.")
			objectifs.text = "Navigation indisponible — R pour relancer."
			return
	var borne = salle_actuelle.get_node_or_null("Navigation/Decor/PointEvacuation")
	if borne:
		borne.process_mode = Node.PROCESS_MODE_ALWAYS
	joueur.set_physics_process(true)
	$"../../Escorte".process_mode = Node.PROCESS_MODE_INHERIT
	salle_actuelle.get_node("Ennemis").process_mode = Node.PROCESS_MODE_INHERIT
	salle_actuelle.get_node("Victimes").process_mode = Node.PROCESS_MODE_INHERIT
	salle_actuelle.temps_avant_vague = delai_vagues
	transition_en_cours = false
	actualiser_objectifs()


func _on_victim_freed(_victime: CharacterBody3D, salle: Node3D) -> void:
	# bind mémorise la salle d'origine même après le déplacement de la victime dans Escorte.
	salle.remaining_victims -= 1
	if salle == salle_actuelle:
		actualiser_objectifs()


func _on_enemy_died(salle: Node3D) -> void:
	salle.remaining_enemies -= 1
	if salle == salle_actuelle:
		actualiser_objectifs()


func actualiser_objectifs() -> void:
	remaining_victims = salle_actuelle.remaining_victims
	remaining_enemies = salle_actuelle.remaining_enemies
	is_room_cleared = salle_actuelle.liberee
	objectifs.text = "Salle %d/%d · Victimes : %d · Ennemis : %d" % [indice_salle + 1, nombre_salles, remaining_victims, remaining_enemies]
	var a_venir: int = salle_actuelle.mobiles_a_creer.size() + salle_actuelle.apparitions_en_cours
	if a_venir > 0:
		objectifs.text += " · À venir : %d" % a_venir
	if remaining_victims == 0 and remaining_enemies == 0 and not is_room_cleared:
		salle_actuelle.liberee = true
		is_room_cleared = true
		for porte in salle_actuelle.get_node("Portes").get_children():
			porte.ouvrir()
		afficher_victoire()
		room_cleared.emit()


func afficher_victoire() -> void:
	objectifs.text = "Salle %d/%d libérée — franchissez une porte pour continuer." % [indice_salle + 1, nombre_salles]
	message_victoire.modulate.a = 0.0
	message_victoire.show()
	animation_message = create_tween()
	animation_message.tween_property(message_victoire, "modulate:a", 1.0, 0.4)
	animation_message.tween_interval(4.0)
	animation_message.tween_property(message_victoire, "modulate:a", 0.0, 0.6)
	animation_message.tween_callback(message_victoire.hide)


func _on_sortie_franchie(salle: Node3D) -> void:
	# Seule la sortie de la salle active et libérée autorise la progression.
	if transition_en_cours or salle != salle_actuelle or not salle.liberee:
		return
	transition_en_cours = true
	# body_entered arrive pendant la physique : déplacer les corps au tour suivant.
	call_deferred("passer_salle_suivante")


func passer_salle_suivante() -> void:
	if indice_salle + 1 < salles.get_child_count():
		await activer_salle(indice_salle + 1)
	else:
		# Fin explicite du parcours ; aucune quatrième salle ni accès hors du niveau.
		get_tree().change_scene_to_file("res://scenes/interfaces/menus/ecran_victoire.tscn")
