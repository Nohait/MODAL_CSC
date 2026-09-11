@tool
extends Node3D

@export var generate := false ;
const TILE_SIZE = 5.0

var roomSize = Vector2i(10, 8)
var grid = []

func _process(delta: float) -> void:
	if generate :
		print("GENERATE :")
		clearRoom()
		generateRoom()
		displayRoom()
		generate = false

func _ready():
	clearRoom()
	generateRoom()
	displayRoom()

func clearRoom():
	for child in get_children():
		child.queue_free()

func generateRoom():
	grid.clear()

	for y in range(roomSize.y):
		var row = []

		for x in range(roomSize.x):
			row.append(true)

		grid.append(row)

	var numberOfCuts = randi_range(3, 8)

	for i in range(numberOfCuts):
		removeRandomRectangle()

func removeRandomRectangle():
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

	if not isConnected():
		for cell in removedCells:
			grid[cell.y][cell.x] = true
			
func isConnected():
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
	var debug := false
	if debug :
		for y in range(roomSize.y) :
			var line := ""
			for x in range(roomSize.x) :
				line += "#" if grid[y][x] else " "
			print(line)
	else :
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
