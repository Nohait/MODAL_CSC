@tool
extends Node3D

# Permet de relancer la génération
@export var generate := false ;
const TILE_SIZE = 5.0
const BOX_SCENE = preload("res://scenes/caisse.tscn")
const DOOR_SCENE = preload("res://scenes/porte.tscn")

var roomSize = Vector2i(10, 8)
var grid = []

func _process(delta: float) -> void:
	if generate :
		# For debug purposes
		print("GENERATE :")
		clearRoom()
		generateRoom()
		displayRoom()
		displayWalls()
		displayBoxes()
		generate = false

func _ready():
	clearRoom()
	generateRoom()
	displayRoom()
	displayWalls()
	displayBoxes()

func clearRoom():
	# On free tous les sous-noeuds
	for child in get_children():
		child.queue_free()

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

func displayRoom():
	"""
	En cas de nouvelle feature à haut potentiel de raté, mettre en mode debug
	   pour éviter de faire planter Godot avec une scène bancale.
	"""
	var debug := false
	if debug :
		# Affichage uniquement en ligne de commande
		for y in range(roomSize.y) :
			var line := ""
			for x in range(roomSize.x) :
				line += "#" if grid[y][x] else " "
			print(line)
	else :
		# Modification de la scène
		for y in range(roomSize.y):
			for x in range(roomSize.x):
				if grid[y][x]:
					var mesh = MeshInstance3D.new()
					var box = BoxMesh.new()

					box.size = Vector3(TILE_SIZE, 0.2, TILE_SIZE)
					mesh.mesh = box

					mesh.position = Vector3(
						x * TILE_SIZE,
						0,
						y * TILE_SIZE
					)
					add_child(mesh)
				

					
func displayBoxes():
	"""Place aléatoirement quelques caisses dans la salle"""
	var numberOfBoxes = randi_range(5, 10)
	var boxesPositions = []

	while boxesPositions.size() < numberOfBoxes:
		var position = Vector2i(
			randi_range(0, roomSize.x - 1),
			randi_range(0, roomSize.y - 1)
		)

		# On vérifie que la tile est du sol
		if not grid[position.y][position.x]:
			continue

		# On vérifie qu'il n'y a pas déjà une caisse
		if position in boxesPositions:
			continue

		boxesPositions.append(position)

		var box = BOX_SCENE.instantiate()

		box.position = Vector3(
			position.x * TILE_SIZE,
			1,
			position.y * TILE_SIZE
		)

		add_child(box)
		
func displayWalls():
	"""Place des murs autour de la salle et une ou deux portes sur le bord"""
	var debug := true
	var numberOfDoors = randi_range(1, 2)
	var doorsPositions = []

	# Récupère tous les emplacements possibles pour les portes
	var possibleDoors = []

	for y in range(roomSize.y):
		for x in range(roomSize.x):
			if not grid[y][x]:
				continue

			if x == 0:
				possibleDoors.append([Vector2i(x, y), Vector2i(-1, 0)])

			if x == roomSize.x - 1:
				possibleDoors.append([Vector2i(x, y), Vector2i(1, 0)])

			if y == 0:
				possibleDoors.append([Vector2i(x, y), Vector2i(0, -1)])

			if y == roomSize.y - 1:
				possibleDoors.append([Vector2i(x, y), Vector2i(0, 1)])

	# Choisis aléatoirement les emplacements des portes
	possibleDoors.shuffle()

	for i in range(min(numberOfDoors, possibleDoors.size())):
		doorsPositions.append(possibleDoors[i])

	# Crée les murs
	for y in range(roomSize.y):
		for x in range(roomSize.x):
			if not grid[y][x]:
				continue

			var directions = [
				Vector2i(1, 0),
				Vector2i(-1, 0),
				Vector2i(0, 1),
				Vector2i(0, -1)
			]

			for direction in directions:
				var neighbour = Vector2i(x, y) + direction
				var position = Vector2i(x, y)

				var exterior := false

				if neighbour.x < 0 or neighbour.x >= roomSize.x:
					exterior = true
				elif neighbour.y < 0 or neighbour.y >= roomSize.y:
					exterior = true
				elif not grid[neighbour.y][neighbour.x]:
					createWall(position, direction, debug, false)
					continue

				if exterior:
					if [position, direction] in doorsPositions:
						createDoor(position, direction)
					else:
						createWall(position, direction, debug, true)
					
func createWall(pos: Vector2i, direction: Vector2i, debug: bool, exterior: bool):
	"""Crée un mur sur un côté d'une tile"""
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()

	box.size = Vector3(TILE_SIZE, 3.0, 0.2)
	mesh.mesh = box

	mesh.position = Vector3(
		pos.x * TILE_SIZE,
		1.5,
		pos.y * TILE_SIZE
	)

	if direction.x != 0:
		box.size = Vector3(0.2, 3.0, TILE_SIZE)
		mesh.position.x += direction.x * TILE_SIZE / 2.0

	else:
		box.size = Vector3(TILE_SIZE, 3.0, 0.2)
		mesh.position.z += direction.y * TILE_SIZE / 2.0
	
	if exterior :
		mesh.visible = true
	
	elif debug:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.GREEN
		mesh.material_override = material
		mesh.visible = true

	else:
		mesh.visible = false

	add_child(mesh)

func createDoor(position: Vector2i, direction: Vector2i):
	"""Crée une porte à la place d'un mur"""
	var door = DOOR_SCENE.instantiate()

	door.position = Vector3(
		position.x * TILE_SIZE,
		0,
		position.y * TILE_SIZE
	)

	if direction.x != 0:
		door.position.x += direction.x * TILE_SIZE / 2.0
		door.rotation.y = PI / 2.0

	else:
		door.position.z += direction.y * TILE_SIZE / 2.0

	add_child(door)
