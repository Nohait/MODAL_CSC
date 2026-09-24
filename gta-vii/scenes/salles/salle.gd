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


func _on_passage(corps: Node3D) -> void:
	# Les victimes qui suivent le joueur ne doivent pas déclencher une transition.
	if corps.is_in_group("player"):
		sortie_franchie.emit(self)


func cuire_navigation() -> void:
	# Le décor n'existe qu'après génération : son maillage se calcule au lancement.
	var region: NavigationRegion3D = $Navigation
	var maillage := NavigationMesh.new()
	maillage.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	maillage.agent_radius = 0.5
	# Multiples de la hauteur de voxel par défaut (0,25) pour éviter les arrondis.
	maillage.agent_height = 2.0
	maillage.agent_max_climb = 0.25
	# Construire la ressource avant de la publier dans la région : le serveur ne
	# doit pas recevoir d'abord un maillage vide puis devoir détecter sa mutation.
	var geometrie := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(maillage, geometrie, region)
	NavigationServer3D.bake_from_source_geometry_data(maillage, geometrie)
	region.navigation_mesh = maillage
