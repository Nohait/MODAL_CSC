@tool #permet l'utilisation du script dans l'apercu du générateur dans l'éditeur
extends Node3D

# Une salle conserve ses données ; le RoomManager prend les décisions de jeu.
signal sortie_franchie(salle: Node3D)
var points_arrivee: Array[Vector3] = []
var points_spawn: Array[Vector3] = []
var remaining_victims := 0
var remaining_enemies := 0
var liberee := false
# Positions réservées aux mobiles encore à venir ; chaque salle garde son attente.
var mobiles_a_creer: Array[Vector3] = []
var temps_avant_vague := 0.0
# Un mobile annoncé reste « à venir » jusqu'à la fin de son cercle animé.
var apparitions_en_cours := 0

# Le décor reste identique pendant le combat : conserver sa géométrie évite
# de relire toutes ses collisions à chaque apparition d'une flaque.
var geometrie_decor: NavigationMeshSourceGeometryData3D
var navigation_a_actualiser := false
# Deux cartes distinctes permettent de superposer deux sols navigables sans
# que Godot relie par erreur le chemin des victimes à celui des ennemis.
var carte_ennemis: RID


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	carte_ennemis = NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(carte_ennemis, 0.25)
	NavigationServer3D.map_set_cell_height(carte_ennemis, 0.25)
	$NavigationEnnemis.set_navigation_map(carte_ennemis)
	# Les obstacles initiaux sont dans Ennemis ; ceux des tirs dans FlaquesDeFeu.
	# Ces signaux signalent un ajout/retrait, sans surveiller la liste à chaque image.
	for conteneur in [$Ennemis, $FlaquesDeFeu]:
		conteneur.child_entered_tree.connect(_sur_obstacle_modifie)
		conteneur.child_exiting_tree.connect(_sur_obstacle_modifie)


func _exit_tree() -> void:
	# Une carte créée par le serveur doit être libérée, notamment lors d'un reload.
	if carte_ennemis.is_valid():
		NavigationServer3D.free_rid(carte_ennemis)
		carte_ennemis = RID()


func activer_navigation(active: bool) -> void:
	# Le RoomManager active ou désactive toujours les deux parcours ensemble.
	$Navigation.enabled = active
	$NavigationEnnemis.enabled = active
	NavigationServer3D.map_set_active(carte_ennemis, active)


func _sur_obstacle_modifie(noeud: Node) -> void:
	if not noeud.is_in_group("obstacles_navigation") or geometrie_decor == null:
		return
	if navigation_a_actualiser or not $Navigation.enabled:
		return
	navigation_a_actualiser = true
	# Reporter le calcul laisse le projectile terminer le placement et la taille
	# de sa flaque, ou l'obstacle disparaître. Plusieurs changements sont regroupés.
	_actualiser_navigation.call_deferred()


func _actualiser_navigation() -> void:
	navigation_a_actualiser = false
	if is_inside_tree() and $Navigation.enabled:
		cuire_navigation()


func _on_passage(corps: Node3D) -> void:
	# Les victimes qui suivent le joueur ne doivent pas déclencher une transition.
	if corps.is_in_group("player"):
		sortie_franchie.emit(self)


func cuire_navigation() -> void:
	_cuire_region($Navigation, true)
	_cuire_region($NavigationEnnemis, false)


func _cuire_region(region: NavigationRegion3D, eviter_flaques: bool) -> void:
	# Le décor n'existe qu'après génération : son maillage se calcule au lancement.
	var maillage := NavigationMesh.new()
	maillage.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	maillage.agent_radius = 0.5
	# Multiples de la hauteur de voxel par défaut (0,25) pour éviter les arrondis.
	maillage.agent_height = 2.0
	maillage.agent_max_climb = 0.25
	# Construire la ressource avant de la publier dans la région : le serveur ne
	# doit pas recevoir d'abord un maillage vide puis devoir détecter sa mutation.
	var geometrie := NavigationMeshSourceGeometryData3D.new()
	if geometrie_decor == null:
		geometrie_decor = NavigationMeshSourceGeometryData3D.new()
		# Le décor est sous Navigation. Les deux régions ont le même repère local :
		# sa géométrie mémorisée peut donc servir aux deux calculs sans duplication de nœuds.
		NavigationServer3D.parse_source_geometry_data(maillage, geometrie_decor, $Navigation)
	geometrie.merge(geometrie_decor)
	_ajouter_obstacles_navigation(geometrie, region, eviter_flaques)
	NavigationServer3D.bake_from_source_geometry_data(maillage, geometrie)
	region.navigation_mesh = maillage


func _ajouter_obstacles_navigation(geometrie: NavigationMeshSourceGeometryData3D, region: NavigationRegion3D, eviter_flaques: bool) -> void:
	for obstacle in get_tree().get_nodes_in_group("obstacles_navigation"):
		# Seul le parcours des victimes exclut le feu. Les tourelles restent
		# des obstacles pour tout le monde, quel que soit ce paramètre.
		if obstacle.is_in_group("flaque") and not eviter_flaques:
			continue
		# Chaque salle ne prend que ses propres obstacles encore présents.
		if not is_ancestor_of(obstacle) or obstacle.is_queued_for_deletion():
			continue
		var collision := obstacle.get_node("CollisionShape3D") as CollisionShape3D
		var cylindre := collision.shape as CylinderShape3D
		if cylindre == null or collision.disabled:
			continue
		# Tourelles et flaques ont une collision cylindrique. Un contour de 16 points
		# représente leur empreinte au sol. Le petit surplus couvre les bords du cercle.
		var contour := PackedVector3Array()
		var rayon := cylindre.radius / cos(PI / 16.0)
		for i in range(16):
			var angle := TAU * i / 16.0
			var point := Vector3(cos(angle) * rayon, 0, sin(angle) * rayon)
			# Passer par le monde prend en compte la taille aléatoire des flaques ;
			# revenir dans la région fonctionne aussi pour les salles éloignées de l'origine.
			contour.append(region.to_local(collision.to_global(point)))
		var centre := region.to_local(collision.global_position)
		var hauteur := cylindre.height * collision.global_basis.y.length()
		# false conserve la marge agent_radius autour de l'obstacle : on contourne
		# avec tout son corps, pas seulement avec son centre. Ceci retire du sol
		# navigable sans ajouter de collision physique : le joueur traverse les flaques.
		geometrie.add_projected_obstruction(contour, centre.y - hauteur / 2.0 - 0.5, hauteur + 1.0, false)
