@tool
extends Node3D

# L'algorithme de découpage et son test de connexité viennent du générateur initial.
# Le générateur construit le décor ; le RoomManager décide du contenu et du parcours.
@export var generate := false
@export var apercu_auto := false
@export var roomSize := Vector2i(10, 8)
## Matériau appliqué aux cases de sol.
@export var materiau_sol: StandardMaterial3D
## Matériau des murs et des morceaux de mur autour des portes.
@export var materiau_murs: StandardMaterial3D
@export_group("Trous du plancher")
## Largeur du parquet brûlé qui dépasse vers le vide, sans agrandir le sol praticable.
@export_range(0.2, 1.2, 0.05) var largeur_bord_trou := 0.8
## Intensité des fragments orange sur les bords ; zéro conserve seulement le charbon.
@export_range(0.0, 5.0, 0.1) var intensite_braises := 1.5
const TROUS_PLANCHER = preload("res://scenes/decors/trous_plancher.gd")
const TILE_SIZE = 5.0
const BOX_SCENE = preload("res://scenes/decors/caisse.tscn")
const DOOR_SCENE = preload("res://scenes/decors/porte.tscn")
const ROOM_SCENE = preload("res://scenes/salles/salle.tscn")
const DIRECTIONS = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

var grid = []
var salle_en_creation: Node3D
var cellules_disponibles: Array[Vector2i] = []
var cellules_reservees: Array[Vector2i] = []
var cellules_trous := {}


func _ready() -> void:
	# L'aperçu reste utilisable dans RoomGenerator.tscn, sans lancer le jeu complet.
	if apercu_auto:
		regenerer_apercu()


func _process(_delta: float) -> void:
	if generate:
		generate = false
		regenerer_apercu()


func regenerer_apercu() -> void:
	for enfant in get_children():
		remove_child(enfant)
		enfant.queue_free()
	add_child(generer_salle())


func generer_salle(nombre_arrivants: int = 1) -> Node3D:
	# Toujours repartir d'une nouvelle scène : aucune salle ne partage ses compteurs.
	roomSize = roomSize.clamp(Vector2i(6, 6), Vector2i(20, 20))
	salle_en_creation = ROOM_SCENE.instantiate()
	generateRoom()
	# Une découpe extrême ne doit pas enlever toutes les places réservées aux acteurs.
	var total := 0
	for ligne in grid:
		total += ligne.count(true)
	if total < 20:
		# Repli rare et déterministe : un rectangle plein reste une salle valide.
		for ligne in grid:
			ligne.fill(true)
	cellules_disponibles.clear()
	cellules_reservees.clear()
	for y in range(roomSize.y):
		for x in range(roomSize.x):
			if grid[y][x]:
				cellules_disponibles.append(Vector2i(x, y))
	displayRoom()
	# Seuls les vides enfermés dans la salle deviennent des trous. Les découpes
	# reliées à l'extérieur gardent les murs et ne deviennent pas des précipices.
	cellules_trous = TROUS_PLANCHER.trouver_trous(grid, roomSize)
	displayWalls()
	TROUS_PLANCHER.construire(salle_en_creation, cellules_trous, TILE_SIZE,
		materiau_sol, largeur_bord_trou, intensite_braises)
	# Réserver assez de place pour le joueur et TOUTE son escorte avant les caisses.
	cellules_disponibles.shuffle()
	var places_par_cellule := 9
	var nombre_cellules := ceili(float(nombre_arrivants) / places_par_cellule)
	for i in range(mini(nombre_cellules, cellules_disponibles.size())):
		var cellule: Vector2i = cellules_disponibles.pop_back()
		cellules_reservees.append(cellule)
		for z in [-1.4, 0.0, 1.4]:
			for x in [-1.4, 0.0, 1.4]:
				salle_en_creation.points_arrivee.append(position_cellule(cellule) + Vector3(x, 0, z))
	displayBoxes()
	# Les emplacements restants serviront au RoomManager pour les personnages.
	for cellule in cellules_disponibles:
		salle_en_creation.points_spawn.append(position_cellule(cellule))
	return salle_en_creation


func position_cellule(cellule: Vector2i) -> Vector3:
	return Vector3(cellule.x * TILE_SIZE, 0, cellule.y * TILE_SIZE)


func generateRoom():
	"""
	Génère la salle, commence par un rectange plein,
	   choisis un nombre arbitraire de "cuts", puis fait
	   chacune, vérifie la connexité, la refait si besoin
	   puis continue.
	"""
	grid.clear()
	for y in range(roomSize.y):
		var row = []

		for x in range(roomSize.x):
			row.append(true)

		grid.append(row)

	# à adapter ?
	var numberOfCuts = randi_range(3, 5)
	
	for i in range(numberOfCuts):
		removeRandomRectangle()

func removeRandomRectangle():
	"""Cut un rectangle à la grid"""
	var width = randi_range(1, 4)
	var height = randi_range(1, 4)

	var startX = randi_range(0, roomSize.x - width)
	var startY = randi_range(0, roomSize.y - height)

	var removedCells = []

	for y in range(startY, startY + height):
		for x in range(startX, startX + width):
			if grid[y][x]:
				removedCells.append(Vector2i(x, y))
				grid[y][x] = false
	# Vérifie la connexité
	if not isConnected():
		for cell in removedCells:
			grid[cell.y][cell.x] = true
			
func isConnected():
	"""Controle la connexité de la salle par parcours de graphe"""
	var start = Vector2i(-1, -1)
	var totalCells = 0

	for y in range(roomSize.y):
		for x in range(roomSize.x):
			if grid[y][x]:
				totalCells += 1
				if start.x == -1:
					start = Vector2i(x, y)
	if totalCells == 0:
		return false
	var visited = []
	var queue = [start]
	for y in range(roomSize.y):
		var row = []
		for x in range(roomSize.x):
			row.append(false)
		visited.append(row)

	visited[start.y][start.x] = true
	while queue.size() > 0:
		var current = queue.pop_front()
		var directions = [
			Vector2i(1, 0), 
			Vector2i(-1, 0),
			Vector2i(0, 1),
			Vector2i(0, -1)
		]
		for direction in directions:
			var next = current + direction
			if next.x < 0 or next.x >= roomSize.x:
				continue
			if next.y < 0 or next.y >= roomSize.y:
				continue
			if not grid[next.y][next.x]:
				continue
			if visited[next.y][next.x]:
				continue
			visited[next.y][next.x] = true
			queue.append(next)
	var connectedCells = 0

	for y in range(roomSize.y):
		for x in range(roomSize.x):
			if visited[y][x]:
				connectedCells += 1

	return connectedCells == totalCells

func displayRoom() -> void:
	# Chaque case est désormais un corps fixe : le sol est visible ET solide.
	for cellule in cellules_disponibles:
				creer_bloc(
			position_cellule(cellule),
			Vector3(TILE_SIZE, 0.2, TILE_SIZE),
			Color(0.3, 0.32, 0.34),
			materiau_sol
		)


func displayBoxes() -> void:
	# Mélanger une liste finie évite la boucle infinie si la salle manque de place.
	# Garder au moins 12 cases libres pour les personnages et la borne.
	var nombre := mini(randi_range(5, 10), maxi(0, cellules_disponibles.size() - 12))
	for i in range(nombre):
		var cellule: Vector2i = cellules_disponibles.pop_back()
		var caisse = BOX_SCENE.instantiate()
		caisse.position = position_cellule(cellule) + Vector3(0, 0.85, 0)
		salle_en_creation.get_node("Navigation/Decor").add_child(caisse)


func displayWalls() -> void:
	# Tous les bords du sol sont admissibles, y compris après les découpes.
	# Cela garantit au moins une sortie même si le rectangle d'origine a été rogné.
	var bords: Array = []
	for cellule in cellules_disponibles:
		for direction in DIRECTIONS:
			var voisine: Vector2i = cellule + direction
			if voisine.x < 0 or voisine.y < 0 or voisine.x >= roomSize.x or voisine.y >= roomSize.y or not grid[voisine.y][voisine.x]:
				bords.append([cellule, direction])
	bords.shuffle()
	# Choisir des sorties vers l'extérieur de l'emprise de la salle : un palier ne
	# doit pas traverser un autre morceau du décor dans une découpe concave.
	var minimum := Vector2i(roomSize.x, roomSize.y)
	var maximum := Vector2i.ZERO
	for cellule in cellules_disponibles:
		minimum = minimum.min(cellule)
		maximum = maximum.max(cellule)
	var sorties_possibles: Array = []
	for bord in bords:
		var cellule: Vector2i = bord[0]
		var direction: Vector2i = bord[1]
		if (direction.x == -1 and cellule.x == minimum.x) or (direction.x == 1 and cellule.x == maximum.x) or (direction.y == -1 and cellule.y == minimum.y) or (direction.y == 1 and cellule.y == maximum.y):
			sorties_possibles.append(bord)
	var portes: Array = sorties_possibles.slice(0, mini(randi_range(1, 2), sorties_possibles.size()))
	for bord in bords:
		if cellules_trous.has(bord[0] + bord[1]):
			# La barrière garde les dimensions du mur, mais n'a aucun visuel.
			# Sous Navigation/Decor, elle est prise en compte par les deux maillages.
			createWall(bord[0], bord[1], true)
		elif bord in portes:
			createDoor(bord[0], bord[1])
		else:
			createWall(bord[0], bord[1])
	# Aucune caisse ni apparition au milieu du passage d'une porte.
	for bord in portes:
		cellules_disponibles.erase(bord[0])


## Crée un mur sur le côté de [param cellule] indiqué par [param direction].
## Les coordonnées de cellule sont dans la grille, pas en mètres.
## Avec [param invisible] à true, conserve uniquement la collision : utilisé au bord des trous.
## Le corps est ajouté sous Navigation/Decor, donc lu lors du calcul des chemins.
func createWall(cellule: Vector2i, direction: Vector2i, invisible: bool = false) -> void:
	var taille := Vector3(TILE_SIZE, 3.0, 0.2)
	if direction.x != 0:
		taille = Vector3(0.2, 3.0, TILE_SIZE)
	var normale := Vector3(direction.x, 0, direction.y)
	creer_bloc(
	position_cellule(cellule) + normale * TILE_SIZE / 2.0 + Vector3.UP * 1.6,
	taille,
	Color(0.22, 0.24, 0.27),
	materiau_murs,
	invisible
	)


func createDoor(cellule: Vector2i, direction: Vector2i) -> void:
	var normale := Vector3(direction.x, 0, direction.y)
	var tangente := Vector3(normale.z, 0, -normale.x)
	var centre := position_cellule(cellule) + normale * TILE_SIZE / 2.0
	var porte = DOOR_SCENE.instantiate()
	# Le voyant et la poignée sont du côté +Z local : ce côté doit regarder
	# vers l'intérieur, donc dans le sens OPPOSÉ à la normale extérieure du mur.
	porte.rotation.y = atan2(-normale.x, -normale.z)
	# Le cadre est légèrement reculé dans porte.tscn (Z = -0.12).
	# Compenser ce recul après rotation place le cadre dans l'axe des murs,
	# au lieu de décaler arbitrairement toute la porte de 0.25 unité.
	var decalage_cadre: float = porte.get_node("Encadrement/MontantGauche").position.z
	porte.position = centre + normale * decalage_cadre + Vector3.UP * 0.1
	# La porte a été retournée : inverser aussi l'angle pour ouvrir vers la salle.
	porte.angle_ouverture = -175.0
	salle_en_creation.get_node("Portes").add_child(porte)
	# La porte fait 2,5 unités avec son cadre ; fermer le reste du bord de 5 unités.
	var largeur_cote := (TILE_SIZE - 2.5) / 2.0
	var taille := Vector3(largeur_cote, 3, 0.2)
	if direction.x != 0:
		taille = Vector3(0.2, 3, largeur_cote)
	for signe in [-1, 1]:
		creer_bloc(
			centre + tangente * signe * (1.25 + largeur_cote / 2.0) + Vector3.UP * 1.6,
			taille,
			Color(0.22, 0.24, 0.27),
			materiau_murs
			)
	# Petit palier au-delà du seuil : même un dash ne tombe pas immédiatement dans le vide.
	var palier := Vector3(2.5, 0.2, 6)
	if direction.x != 0:
		palier = Vector3(6, 0.2, 2.5)
	creer_bloc(centre + normale * 3.0, palier, Color(0.24, 0.28, 0.3))
	var zone := Area3D.new()
	zone.name = "Passage"
	zone.monitoring = false
	zone.collision_layer = 0
	zone.collision_mask = 1
	# L'extérieur se trouve maintenant du côté -Z local de la porte.
	zone.position = Vector3(0, 1.5, -3.5)
	var collision := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = Vector3(2.2, 3, 5.0)
	collision.shape = forme
	zone.add_child(collision)
	porte.add_child(zone)
	# La sortie devient utilisable seulement une fois l'animation de porte terminée.
	porte.ouverte.connect(func(): zone.set_deferred("monitoring", true))
	zone.body_entered.connect(salle_en_creation._on_passage)


## Ajoute un bloc fixe à la salle en cours de génération.
## [param position_bloc] et [param taille] sont exprimées en mètres, dans le repère de la salle.
## [param materiau_personnalise] remplace la couleur simple lorsqu'il est fourni.
## [param invisible] supprime uniquement la partie visuelle : la collision et le groupe
## collider restent présents pour bloquer les personnages et être lus par la navigation.
## Cette fonction ne renvoie pas le bloc ; elle l'ajoute directement à Navigation/Decor.
func creer_bloc(position_bloc: Vector3, taille: Vector3, couleur: Color, materiau_personnalise: Material = null, invisible: bool = false) -> void:
	#le materiau_personnalise est facultatif, vaut null s'il n'est pas renseigné
	var corps := StaticBody3D.new()
	corps.position = position_bloc
	if invisible:
		# Aucun mesh, même caché : pas d'ombre de mur autour du vide.
		corps.name = "BarriereTrou"
		var collision_trou := CollisionShape3D.new()
		var forme_trou := BoxShape3D.new()
		forme_trou.size = taille
		collision_trou.shape = forme_trou
		corps.add_child(collision_trou)
		corps.add_to_group("collider")
		salle_en_creation.get_node("Navigation/Decor").add_child(corps)
		return
	var visuel := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = taille
	if materiau_personnalise != null:
		# Utiliser le matériau fourni, avec tous ses réglages.
		mesh.material = materiau_personnalise
	else:
		# Sans matériau fourni, conserver la couleur simple utilisée jusque-là.
		var materiau := StandardMaterial3D.new()
		materiau.albedo_color = couleur
		mesh.material = materiau
	
	visuel.mesh = mesh
	corps.add_child(visuel)
	var collision := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = taille
	collision.shape = forme
	corps.add_child(collision)
	corps.add_to_group("collider")
	salle_en_creation.get_node("Navigation/Decor").add_child(corps)
