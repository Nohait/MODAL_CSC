extends SceneTree

class SalleTest:
	extends "res://scenes/salles/salle.gd"
	func _ready() -> void:
		pass

class EnnemiCompteTest:
	extends Node3D
	signal died
	var est_mort := false
	func mourir() -> void:
		if est_mort: return
		est_mort = true
		died.emit()

class GestionTest:
	extends "res://scenes/salles/room_manager.gd"
	var apparus: Array[Dictionary] = []
	func actualiser_objectifs() -> void:
		pass
	func creer_mobile(salle: Node3D, emplacement: Vector3) -> void:
		var scene: PackedScene = types_mobiles_annonces.get(emplacement)
		types_mobiles_annonces.erase(emplacement)
		var corps := StaticBody3D.new()
		corps.collision_layer = 4
		var collision := CollisionShape3D.new()
		var volume := CylinderShape3D.new()
		volume.radius = 0.95
		volume.height = 2.6
		collision.shape = volume
		corps.add_child(collision)
		corps.position = emplacement + Vector3.UP * 1.4
		salle.get_node("Ennemis").add_child(corps)
		apparus.append({"position": emplacement, "type": scene, "corps": corps})

var salle: SalleTest
var gestion: GestionTest
var joueur: Node3D

func _initialize() -> void:
	verifier.call_deferred()

func _exiger(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func _synchroniser() -> void:
	await physics_frame
	await physics_frame

func _obstacle(taille: Vector3, position: Vector3, couche: int) -> StaticBody3D:
	var corps := StaticBody3D.new()
	corps.collision_layer = couche
	var collision := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = taille
	collision.shape = boite
	corps.add_child(collision)
	corps.position = position
	salle.add_child(corps)
	return corps

func _retirer_mobiles() -> void:
	for apparition in gestion.apparus:
		if is_instance_valid(apparition.corps):
			apparition.corps.queue_free()
			apparition.corps = null
			salle.remaining_enemies -= 1

func _verifier_compteur() -> bool:
	var piece := SalleTest.new()
	for nom in ["Ennemis", "Victimes", "ProjectilesTour", "FlaquesDeFeu"]:
		var conteneur := Node3D.new()
		conteneur.name = nom
		piece.add_child(conteneur)
	var controle := GestionTest.new()
	controle.salle_actuelle = piece
	controle.timer_bar = ProgressBar.new()
	controle.add_child(controle.timer_bar)
	controle.timer_container = Control.new()
	controle.add_child(controle.timer_container)
	for i in range(5):
		var participant := EnnemiCompteTest.new()
		piece.get_node("Ennemis").add_child(participant)
		if i < 2:
			participant.died.connect(controle._on_enemy_died.bind(piece), CONNECT_ONE_SHOT)
		else:
			participant.add_to_group("flaque")
	var point = preload("res://scenes/jeu/sauvegarde/point_reprise_classique.gd").new()
	point._restaurer_population(controle, {"mobiles": [Vector3.ZERO], "victimes": []})
	var reprise_correcte: bool = piece.remaining_enemies == 3
	# Simuler précisément un ancien compteur fantôme, puis utiliser la vraie commande debug.
	piece.remaining_enemies += 3
	controle.liberer_salle_debug()
	var debug_correct: bool = piece.remaining_enemies == 0 and piece.mobiles_a_creer.is_empty() and controle.conditions_sortie_remplies(piece)
	point.free()
	controle.free()
	piece.free()
	if not _exiger(reprise_correcte, "La reprise compte les flaques parmi les ennemis."): return false
	if not _exiger(debug_correct, "La libération debug laisse un compteur fantôme bloquer la sortie."): return false
	print("VAGUES_COMPTEUR_SANS_FLAQUES_DEBUG_OK")
	return true

func verifier() -> void:
	if not _verifier_compteur(): return
	create_timer(25.0).timeout.connect(func():
		push_error("Délai dépassé pour les vagues classiques.")
		quit(1))
	salle = SalleTest.new()
	salle.etage = 3
	salle.numero_dans_etage = 5
	salle.points_spawn = [Vector3.ZERO]
	var ennemis := Node3D.new()
	ennemis.name = "Ennemis"
	salle.add_child(ennemis)
	root.add_child(salle)
	_obstacle(Vector3(5, 0.2, 5), Vector3.ZERO, 1)
	var region := NavigationRegion3D.new()
	var maillage := NavigationMesh.new()
	# Même cuisson que les salles réelles, y compris l'arrondi vertical du sol.
	maillage.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	maillage.agent_radius = 0.5
	maillage.agent_height = 2.0
	maillage.agent_max_climb = 0.25
	var geometrie := NavigationMeshSourceGeometryData3D.new()
	await _synchroniser()
	NavigationServer3D.parse_source_geometry_data(maillage, geometrie, salle)
	NavigationServer3D.bake_from_source_geometry_data(maillage, geometrie)
	region.navigation_mesh = maillage
	salle.carte_ennemis = NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(salle.carte_ennemis, 0.25)
	NavigationServer3D.map_set_cell_height(salle.carte_ennemis, 0.25)
	NavigationServer3D.map_set_active(salle.carte_ennemis, true)
	salle.add_child(region)
	region.set_navigation_map(salle.carte_ennemis)
	joueur = Node3D.new()
	joueur.position = Vector3(20, 1, 20)
	root.add_child(joueur)
	# Le gestionnaire reste hors de l'arbre : seuls ses appels de vagues sont exercés.
	gestion = GestionTest.new()
	gestion.salle_actuelle = salle
	gestion.joueur = joueur
	gestion.duree_annonce = 0.2
	await _synchroniser()
	if not _exiger(NavigationServer3D.map_get_iteration_id(salle.carte_ennemis) > 0, "Navigation du scénario non synchronisée."): return
	var surface := Vector3(0, 0.1, 0)
	var navigable := NavigationServer3D.map_get_closest_point(salle.carte_ennemis, surface)
	print("VAGUES_HAUTEUR_NAVIGATION : sol=%s, navigation=%s" % [surface, navigable])
	var nombre := gestion._planifier_mobiles(salle, salle.points_spawn, 13)
	salle.remaining_enemies = nombre
	if not _exiger(nombre == 13 and salle.mobiles_a_creer.size() == 13, "Le nombre de mobiles a été plafonné au nombre de cases."): return
	var positions_reprises: Array = bytes_to_var(var_to_bytes(salle.mobiles_a_creer))
	if not _exiger(positions_reprises == salle.mobiles_a_creer, "Les points répétés ne survivent pas à la sérialisation."): return
	gestion.planifier_types_mobiles(salle, 71243)
	var types_attendus: Array[PackedScene] = gestion.mobiles_classiques_planifies.duplicate()
	var placement: Resource = gestion.placement_mobiles
	var points: Array[Vector3] = placement.points_mobiles(salle.points_spawn)
	var uniques: Dictionary = {}
	for point in points:
		uniques[point] = true
		if not _exiger(absf(point.x) < 2.5 and absf(point.z) < 2.5, "Un candidat sort de sa case."): return
	if not _exiger(points.size() == 9 and uniques.size() == 9, "Une case doit fournir neuf candidats distincts."): return
	print("VAGUES_NEUF_POINTS_OK")
	var derniers: Array[Vector3] = placement.placer(salle.points_spawn, salle.mobiles_annonces, salle, salle.carte_ennemis, joueur.global_position, gestion.distance_securite_spawn, 1, true)
	if not _exiger(derniers.size() == 1, "Le dernier mobile d'une horde ne trouve pas de place."): return

	gestion.creer_vague(1, 0.0)
	gestion._process(0.21)
	if not _exiger(gestion.apparus.size() == 1, "La première vague n'est pas apparue."): return
	var premiere_position: Vector3 = gestion.apparus[0].position
	gestion.apparus[0].corps.position.x += 10.0
	await _synchroniser()
	gestion.creer_vague(1, 0.0)
	gestion._process(0.21)
	if not _exiger(gestion.apparus.size() == 2 and gestion.apparus[1].position == premiere_position, "Le point n'est pas réutilisé alors que le premier mobile est encore vivant ailleurs."): return
	print("VAGUES_REUTILISATION_OK")

	var obstacle := _obstacle(Vector3(5, 2, 5), Vector3(0, 1.1, 0), 4)
	await _synchroniser()
	gestion.creer_vague(3, 0.0)
	if not _exiger(salle.mobiles_annonces.is_empty() and gestion.mobiles_a_annoncer == 3, "Une vague apparaît dans une case entièrement occupée."): return
	salle.sauvetage_termine = true
	gestion.forcer_spawn_mobiles_restants(salle)
	gestion._process(0.6)
	if not _exiger(salle.mobiles_a_creer.size() == 11 and salle.remaining_enemies == 13 and gestion.apparus.size() == 2, "La fin du timer perd des ennemis ou force leur apparition dans l'obstacle."): return
	obstacle.queue_free()
	_retirer_mobiles()
	await _synchroniser()

	gestion.hordes_salle_actives = true
	gestion.creer_vague(0, 0.0)
	if not _exiger(not salle.mobiles_annonces.is_empty(), "La horde ne trouve aucune des neuf positions libérées."): return
	for point in salle.mobiles_annonces:
		if not _exiger(points.has(point), "La horde utilise une position hors de la grille à neuf points."): return
	var intrusion: Vector3 = salle.mobiles_annonces[0]
	var annonces_avant: int = salle.mobiles_annonces.size()
	var attente_avant: int = salle.mobiles_a_creer.size()
	var bloqueur := _obstacle(Vector3(0.2, 1, 0.2), intrusion + Vector3.UP * 0.6, 4)
	await _synchroniser()
	gestion._process(0.21)
	if not _exiger(salle.mobiles_a_creer.size() == attente_avant + 1 and gestion.apparus.size() == 2 + annonces_avant - 1, "L'intrusion pendant l'annonce n'a pas reporté exactement un mobile."): return
	bloqueur.queue_free()
	_retirer_mobiles()
	await _synchroniser()
	for essai in range(60):
		gestion._process(0.51)
		await _synchroniser()
		_retirer_mobiles()
		await _synchroniser()
		if salle.mobiles_a_creer.is_empty() and salle.mobiles_annonces.is_empty(): break
	if not _exiger(gestion.apparus.size() == 13 and salle.remaining_enemies == 0 and gestion.mobiles_a_annoncer == 0, "Une vague reste bloquée, perd ou duplique des mobiles."): return
	for apparition in gestion.apparus:
		if not _exiger(types_attendus.has(apparition.type), "Le type d'un mobile a été perdu ou remplacé."): return
		types_attendus.erase(apparition.type)
	if not _exiger(types_attendus.is_empty() and gestion.types_mobiles_annonces.is_empty() and gestion.mobiles_classiques_planifies.is_empty(), "Le planning conserve des ennemis fantômes."): return
	print("VAGUES_ATTENTE_COLLISIONS_FIN_TIMER_OK")
	gestion.free()
	gestion = null
	salle.queue_free()
	joueur.queue_free()
	await process_frame
	await process_frame
	print("VAGUES_CLASSIQUES_OK")
	quit()
