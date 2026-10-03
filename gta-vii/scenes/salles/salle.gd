@tool
extends Node3D


signal sortie_franchie(salle: Node3D)


# Attribué avant le peuplement.
var etage := 1


var points_arrivee: Array[Vector3] = []
var points_spawn: Array[Vector3] = []


var remaining_victims := 0
var remaining_enemies := 0

var liberee := false


# ------------------------------------------------------------------
# ENNEMIS MOBILES
# ------------------------------------------------------------------

# Positions de mobiles qui n'ont pas encore commencé leur animation
# d'apparition.
var mobiles_a_creer: Array[Vector3] = []

# Positions dont le cercle d'apparition est actuellement visible.
var mobiles_annonces: Array[Vector3] = []

# Références aux annonces elles-mêmes.
# Elles permettront de les supprimer proprement si le timer arrive à zéro.
var annonces_en_cours: Array[Node] = []

# Le calendrier utilise les secondes restantes du même timer que les captives.
var duree_sauvetage := 30.0
var vagues_planifiees: Array[Dictionary] = []
var apparitions_planifiees: Array[Dictionary] = []

var apparitions_en_cours := 0


# ------------------------------------------------------------------
# SAUVETAGE
# ------------------------------------------------------------------

# Permet de ne jamais redémarrer le timer d'une salle déjà visitée.
var sauvetage_demarre := false

var sauvetage_en_cours := false

var sauvetage_termine := false

var temps_sauvetage_restant := 0.0


# ------------------------------------------------------------------
# NAVIGATION
# ------------------------------------------------------------------

var geometrie_decor: NavigationMeshSourceGeometryData3D

var navigation_a_actualiser := false

var navigation_active := false

var carte_ennemis: RID


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	carte_ennemis = NavigationServer3D.map_create()

	NavigationServer3D.map_set_cell_size(
		carte_ennemis,
		0.25
	)

	NavigationServer3D.map_set_cell_height(
		carte_ennemis,
		0.25
	)

	NavigationServer3D.map_set_active(
		carte_ennemis,
		true
	)

	$NavigationEnnemis.set_navigation_map(
		carte_ennemis
	)

	for conteneur in [
		$Ennemis,
		$FlaquesDeFeu
	]:
		conteneur.child_entered_tree.connect(
			_sur_obstacle_modifie
		)

		conteneur.child_exiting_tree.connect(
			_sur_obstacle_modifie
		)


func _exit_tree() -> void:
	if carte_ennemis.is_valid():
		NavigationServer3D.free_rid(
			carte_ennemis
		)

		carte_ennemis = RID()


func activer_navigation(active: bool) -> void:
	navigation_active = active

	if not active:
		$Navigation.navigation_mesh = null
		$NavigationEnnemis.navigation_mesh = null


func _sur_obstacle_modifie(noeud: Node) -> void:
	if (
		not noeud.is_in_group("obstacles_navigation")
		or geometrie_decor == null
	):
		return

	if (
		navigation_a_actualiser
		or not navigation_active
	):
		return

	navigation_a_actualiser = true

	_actualiser_navigation.call_deferred()


func _actualiser_navigation() -> void:
	navigation_a_actualiser = false

	if (
		is_inside_tree()
		and navigation_active
	):
		cuire_navigation()


func _on_passage(corps: Node3D) -> void:
	if corps.is_in_group("player"):
		sortie_franchie.emit(self)


func cuire_navigation() -> void:
	_cuire_region(
		$Navigation,
		true
	)

	_cuire_region(
		$NavigationEnnemis,
		false
	)


func _cuire_region(
	region: NavigationRegion3D,
	eviter_flaques: bool
) -> void:

	var maillage := NavigationMesh.new()

	maillage.geometry_parsed_geometry_type = (
		NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	)

	maillage.agent_radius = 0.5
	maillage.agent_height = 2.0
	maillage.agent_max_climb = 0.25

	var geometrie := (
		NavigationMeshSourceGeometryData3D.new()
	)

	if geometrie_decor == null:
		geometrie_decor = (
			NavigationMeshSourceGeometryData3D.new()
		)

		NavigationServer3D.parse_source_geometry_data(
			maillage,
			geometrie_decor,
			$Navigation
		)

	geometrie.merge(
		geometrie_decor
	)

	_ajouter_obstacles_navigation(
		geometrie,
		region,
		eviter_flaques
	)

	NavigationServer3D.bake_from_source_geometry_data(
		maillage,
		geometrie
	)

	region.navigation_mesh = maillage


func _ajouter_obstacles_navigation(
	geometrie: NavigationMeshSourceGeometryData3D,
	region: NavigationRegion3D,
	eviter_flaques: bool
) -> void:

	for obstacle in get_tree().get_nodes_in_group(
		"obstacles_navigation"
	):
		if (
			obstacle.is_in_group("flaque")
			and not eviter_flaques
		):
			continue

		if (
			not is_ancestor_of(obstacle)
			or obstacle.is_queued_for_deletion()
		):
			continue

		var collision := (
			obstacle.get_node("CollisionShape3D")
			as CollisionShape3D
		)

		var cylindre := (
			collision.shape
			as CylinderShape3D
		)

		if (
			cylindre == null
			or collision.disabled
		):
			continue

		var contour := PackedVector3Array()

		var rayon := (
			cylindre.radius
			/ cos(PI / 16.0)
		)

		for i in range(16):
			var angle := (
				TAU
				* i
				/ 16.0
			)

			var point := Vector3(
				cos(angle) * rayon,
				0,
				sin(angle) * rayon
			)

			contour.append(
				region.to_local(
					collision.to_global(point)
				)
			)

		var centre := region.to_local(
			collision.global_position
		)

		var hauteur := (
			cylindre.height
			* collision.global_basis.y.length()
		)

		geometrie.add_projected_obstruction(
			contour,
			centre.y - hauteur / 2.0 - 0.5,
			hauteur + 1.0,
			false
		)
