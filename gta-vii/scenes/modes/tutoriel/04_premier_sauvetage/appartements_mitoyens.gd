extends Node3D

const STYLE = preload("res://scenes/modes/tutoriel/commun/decors/construction_interieur.gd")
const SBIRE = preload("res://scenes/ennemis/mobiles/sbire.tscn")
const MOBILIER = preload("res://scenes/decors/ville/mobilier_annexe.gd")
const FOYER = preload("res://scenes/decors/hall_incendie/foyer_incendie.tscn")

func _ready() -> void:
	var salle := get_parent() as Node3D
	# La pièce mitoyenne est visible depuis la libération, mais demeure inaccessible.
	var ancien_mur = salle.get_node("MurEst")
	ancien_mur.hide()
	ancien_mur.get_node("Collision").set_deferred("disabled", true)
	for cote in [-1, 1]:
		STYLE.bloc(self, "Cloison" + str(cote), Vector3(4.15, 0.6, cote * 2.65), Vector3(0.3, 1.2, 3), STYLE.MUR)
	STYLE.bloc(self, "Allege", Vector3(4.15, 0.35, 0), Vector3(0.3, 0.7, 2.3), STYLE.MUR)
	STYLE.bloc(self, "SolMitoyen", Vector3(7.3, -0.15, 0), Vector3(6.3, 0.3, 8.3), STYLE.SOL)
	STYLE.bloc(self, "FondMitoyen", Vector3(10.45, 0.6, 0), Vector3(0.3, 1.2, 8.3), STYLE.MUR)
	STYLE.bloc(self, "RetourMitoyen", Vector3(7.3, 0.6, 4.15), Vector3(6.3, 1.2, 0.3), STYLE.MUR)
	# Une large embrasure relie le salon à la cuisine : le sbire parcourt les deux.
	for x in [4.875, 9.725]:
		STYLE.bloc(self, "Embrasure" + str(x), Vector3(x, 0.6, -4.15), Vector3(1.45, 1.2, 0.3), STYLE.MUR)
	STYLE.bloc(self, "SolCuisine", Vector3(7.3, -0.15, -7.15), Vector3(6.3, 0.3, 6), STYLE.SOL)
	STYLE.bloc(self, "FondCuisine", Vector3(7.3, 0.6, -10.15), Vector3(6.3, 1.2, 0.3), STYLE.MUR)
	for x in [4.15, 10.45]:
		STYLE.bloc(self, "MurCuisine" + str(x), Vector3(x, 0.6, -7.15), Vector3(0.3, 1.2, 6), STYLE.MUR)
	var vitre := StandardMaterial3D.new()
	vitre.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vitre.albedo_color = Color(0.62, 0.76, 0.8, 0.18)
	STYLE.bloc(self, "Vitre", Vector3(4.15, 1.35, 0), Vector3(0.06, 1.3, 2.3), vitre)
	var cadre := StandardMaterial3D.new()
	cadre.albedo_color = Color(0.18, 0.16, 0.13)
	for cote in [-1, 1]:
		STYLE.bloc(self, "Montant" + str(cote), Vector3(4.15, 1.35, cote * 1.15), Vector3(0.1, 1.5, 0.08), cadre)
	STYLE.bloc(self, "Traverse", Vector3(4.15, 2.05, 0), Vector3(0.1, 0.08, 2.4), cadre)
	_meuble(preload("res://assets/modeles/decors/appartements/loungeSofa.glb"), Vector3(7.3, 0, 3.1), 0.9, PI)
	_meuble(preload("res://assets/modeles/decors/appartements/tableCoffee.glb"), Vector3(7.3, 0, 2), 0.45)
	_meuble(preload("res://assets/modeles/decors/appartements/cardboardBoxClosed.glb"), Vector3(9.5, 0, -2.8), 0.65)
	_meuble(preload("res://assets/modeles/decors/appartements/kitchenStove.glb"), Vector3(9.65, 0, -7.6), 0.85, -PI * 0.5)
	_meuble(preload("res://assets/modeles/decors/appartements/kitchenSink.glb"), Vector3(9.65, 0, -5.8), 0.9, -PI * 0.5)
	_meuble(preload("res://assets/modeles/decors/appartements/kitchenFridge.glb"), Vector3(5.1, 0, -9.2), 1.8)
	_entourer_piece()
	STYLE.porte_fictive(self, Vector3(4.34, 0, -6.3), PI / 2)
	_incendie(Vector3(9.45, 0.25, 2.9), 0.85, 0.45)
	_incendie(Vector3(9.55, 0.25, -9.35), 1.0, 0.5)
	STYLE.meuble(salle, preload("res://assets/modeles/decors/appartements/cabinetBed.glb"), Vector3(-3.2, 0, -2.8))
	var nav := NavigationRegion3D.new()
	var mesh := NavigationMesh.new()
	# Polygones joints du salon, de l'embrasure et de la cuisine, hors des meubles.
	mesh.vertices = PackedVector3Array([
		Vector3(5.1, 0, 1), Vector3(9.3, 0, 1), Vector3(9.3, 0, -3.3),
		Vector3(8.9, 0, -3.3), Vector3(5.7, 0, -3.3), Vector3(5.1, 0, -3.3),
		Vector3(8.9, 0, -5), Vector3(5.7, 0, -5),
		Vector3(9.3, 0, -5), Vector3(9.3, 0, -9.2),
		Vector3(5.7, 0, -9.2)])
	mesh.add_polygon(PackedInt32Array([0, 1, 2, 3, 4, 5]))
	mesh.add_polygon(PackedInt32Array([4, 3, 6, 7]))
	mesh.add_polygon(PackedInt32Array([7, 6, 8, 9, 10]))
	nav.navigation_mesh = mesh
	add_child(nav)
	var creature = SBIRE.instantiate()
	creature.set_script(preload("res://scenes/modes/tutoriel/04_premier_sauvetage/sbire_ambiance.gd"))
	creature.position = Vector3(6.8, 0, -1)
	creature.vitesse_sbire = 1.4
	creature.temps_idle_min = 1.5
	creature.temps_idle_max = 2.5
	creature.degats_sbire = 0
	creature.distance_detection = 0.1
	creature.collision_layer = 0
	creature.remove_from_group("enemies")
	var detection: Area3D = creature.get_node("SurfaceDetection")
	# Le script commun lit les chevauchements ; garder le suivi actif avec un masque vide.
	detection.monitoring = true
	detection.collision_mask = 0
	var forme: CollisionShape3D = detection.get_node("CollisionShape3D")
	forme.shape = forme.shape.duplicate()
	add_child(creature)

func _entourer_piece() -> void:
	# Chambres et salle d'eau fixes : aucune pièce n'est tirée au hasard.
	STYLE.bloc(self, "SolChambre", Vector3(-7.3, -0.15, 0), Vector3(6.3, 0.3, 8.3), STYLE.SOL)
	STYLE.bloc(self, "SolSalleEau", Vector3(-7.3, -0.15, -7.15), Vector3(6.3, 0.3, 6), STYLE.SOL)
	STYLE.bloc(self, "FacadeOuest", Vector3(-10.45, 0.6, -3), Vector3(0.3, 1.2, 14.3), STYLE.MUR)
	STYLE.bloc(self, "FondOuest", Vector3(-7.3, 0.6, -10.15), Vector3(6.3, 1.2, 0.3), STYLE.MUR)
	STYLE.bloc(self, "RetourOuest", Vector3(-7.3, 0.6, 4.15), Vector3(6.3, 1.2, 0.3), STYLE.MUR)
	STYLE.bloc(self, "SeparationSalleEau", Vector3(-7.3, 0.6, -4.15), Vector3(6.3, 1.2, 0.3), STYLE.MUR)
	STYLE.bloc(self, "CloisonSalleEau", Vector3(-4.15, 0.6, -7.15), Vector3(0.3, 1.2, 6), STYLE.MUR)
	STYLE.porte_fictive(self, Vector3(-7.3, 0, -3.96), 0.0)
	STYLE.porte_fictive(self, Vector3(-3.96, 0, -6.3), PI / 2)
	_meuble(preload("res://assets/modeles/decors/appartements/bedSingle.glb"), Vector3(-8.7, 0, 1), 0.8)
	_meuble(preload("res://assets/modeles/decors/appartements/cabinetBed.glb"), Vector3(-9.2, 0, -2.8), 0.6)
	_meuble(preload("res://assets/modeles/decors/appartements/shower.glb"), Vector3(-9.5, 0, -8.7), 1.85)
	_meuble(preload("res://assets/modeles/decors/appartements/toilet.glb"), Vector3(-5.2, 0, -8.9), 0.75)
	_meuble(preload("res://assets/modeles/decors/appartements/bathroomSink.glb"), Vector3(-5.1, 0, -5.5), 0.6, -PI * 0.5)
	_incendie(Vector3(-8.7, 0.4, 1.1), 0.9, 0.4)
	_incendie(Vector3(-9.1, 0.25, -3), 0.7, 0.35)
	_incendie(Vector3(-9.1, 0.25, -8.1), 0.75, 0.4)

func _meuble(scene: PackedScene, emplacement: Vector3, hauteur: float, angle := 0.0) -> void:
	# Réutiliser l'habillage classique, y compris les dimensions et la suie.
	var objet = MOBILIER.new()
	objet.modele_scene = scene
	objet.hauteur = hauteur
	objet.suie = 0.4
	objet.position = emplacement
	objet.rotation.y = angle
	add_child(objet)

func _incendie(emplacement: Vector3, taille: float, fumee: float) -> void:
	var foyer = FOYER.instantiate()
	foyer.position = emplacement
	foyer.taille = taille
	foyer.energie = 1.1
	foyer.portee_lumiere = 3.5
	foyer.densite_fumee = fumee
	foyer.get_node("Crepitement").volume_db = -24
	add_child(foyer)
