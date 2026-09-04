extends Node2D

## BaseBuildingSystem - Intuitive grid-based base construction
## Allows placing walls, floors, crafting stations, storage, defenses

signal structure_placed(structure: Node2D, grid_pos: Vector2i)
signal structure_removed(grid_pos: Vector2i)
signal base_expanded(new_size: Vector2i)
signal building_mode_changed(enabled: bool)
signal resource_insufficient(required: Dictionary)

const GameConfig = preload("res://scripts/core/GameConfig.gd")

# ============================================================================
# STRUCTURE DEFINITIONS
# ============================================================================

const STRUCTURE_TYPES := {
	# Floors
	"wood_floor": {
		"name": "Wood Floor",
		"category": "floor",
		"size": Vector2i(1, 1),
		"cost": {"wood": 5},
		"health": 100,
		"material": "wood",
		"layer": 0,
		"walkable": true
	},
	"stone_floor": {
		"name": "Stone Floor",
		"category": "floor",
		"size": Vector2i(1, 1),
		"cost": {"stone": 8},
		"health": 200,
		"material": "stone",
		"layer": 0,
		"walkable": true
	},
	"metal_floor": {
		"name": "Metal Floor",
		"category": "floor",
		"size": Vector2i(1, 1),
		"cost": {"steel_ingot": 4},
		"health": 400,
		"material": "metal",
		"layer": 0,
		"walkable": true
	},
	
	# Walls
	"wood_wall": {
		"name": "Wood Wall",
		"category": "wall",
		"size": Vector2i(1, 1),
		"cost": {"wood": 10},
		"health": 150,
		"material": "wood",
		"layer": 1,
		"walkable": false,
		"blocks_sight": true
	},
	"stone_wall": {
		"name": "Stone Wall",
		"category": "wall",
		"size": Vector2i(1, 1),
		"cost": {"stone": 15},
		"health": 350,
		"material": "stone",
		"layer": 1,
		"walkable": false,
		"blocks_sight": true
	},
	"metal_wall": {
		"name": "Metal Wall",
		"category": "wall",
		"size": Vector2i(1, 1),
		"cost": {"steel_ingot": 8, "iron_ore": 4},
		"health": 600,
		"material": "metal",
		"layer": 1,
		"walkable": false,
		"blocks_sight": true
	},
	"reinforced_wall": {
		"name": "Reinforced Wall",
		"category": "wall",
		"size": Vector2i(1, 1),
		"cost": {"steel_ingot": 12, "titanium": 2},
		"health": 1000,
		"material": "reinforced",
		"layer": 1,
		"walkable": false,
		"blocks_sight": true
	},
	
	# Doors
	"wood_door": {
		"name": "Wood Door",
		"category": "door",
		"size": Vector2i(1, 1),
		"cost": {"wood": 8, "iron_ore": 2},
		"health": 100,
		"material": "wood",
		"layer": 1,
		"walkable": true,
		"interactable": true
	},
	"metal_door": {
		"name": "Metal Door",
		"category": "door",
		"size": Vector2i(1, 1),
		"cost": {"steel_ingot": 6, "iron_ore": 4},
		"health": 400,
		"material": "metal",
		"layer": 1,
		"walkable": true,
		"interactable": true
	},
	"vault_door": {
		"name": "Vault Door",
		"category": "door",
		"size": Vector2i(2, 1),
		"cost": {"titanium": 10, "electronics": 5},
		"health": 2000,
		"material": "titanium",
		"layer": 1,
		"walkable": true,
		"interactable": true
	},
	
	# Crafting Stations
	"workbench_basic": {
		"name": "Basic Workbench",
		"category": "crafting",
		"size": Vector2i(2, 1),
		"cost": {"wood": 20, "stone": 10},
		"health": 200,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"crafting_tier": 1
	},
	"workbench_advanced": {
		"name": "Advanced Workbench",
		"category": "crafting",
		"size": Vector2i(2, 2),
		"cost": {"wood": 30, "steel_ingot": 15, "electronics": 5},
		"health": 400,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"crafting_tier": 2
	},
	"forge": {
		"name": "Forge",
		"category": "crafting",
		"size": Vector2i(2, 2),
		"cost": {"stone": 40, "iron_ore": 20, "wood": 15},
		"health": 500,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"crafting_tier": 2,
		"smelting": true
	},
	"chemistry_station": {
		"name": "Chemistry Station",
		"category": "crafting",
		"size": Vector2i(2, 2),
		"cost": {"steel_ingot": 20, "glass": 10, "electronics": 8},
		"health": 350,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"crafting_tier": 3
	},
	"electronics_lab": {
		"name": "Electronics Lab",
		"category": "crafting",
		"size": Vector2i(3, 2),
		"cost": {"steel_ingot": 30, "electronics": 20, "polymer": 10},
		"health": 400,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"crafting_tier": 4
	},
	
	# Storage
	"small_chest": {
		"name": "Small Chest",
		"category": "storage",
		"size": Vector2i(1, 1),
		"cost": {"wood": 10},
		"health": 100,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"storage_slots": 12
	},
	"large_chest": {
		"name": "Large Chest",
		"category": "storage",
		"size": Vector2i(2, 1),
		"cost": {"wood": 25, "iron_ore": 5},
		"health": 200,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"storage_slots": 24
	},
	"metal_locker": {
		"name": "Metal Locker",
		"category": "storage",
		"size": Vector2i(1, 1),
		"cost": {"steel_ingot": 10},
		"health": 400,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"storage_slots": 18
	},
	"vault": {
		"name": "Vault",
		"category": "storage",
		"size": Vector2i(3, 3),
		"cost": {"titanium": 20, "electronics": 10, "steel_ingot": 30},
		"health": 2000,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"storage_slots": 100,
		"raid_protected": true
	},
	
	# Defenses
	"spike_trap": {
		"name": "Spike Trap",
		"category": "defense",
		"size": Vector2i(1, 1),
		"cost": {"wood": 5, "iron_ore": 3},
		"health": 50,
		"layer": 0,
		"walkable": true,
		"trap": true,
		"damage": 25
	},
	"turret_basic": {
		"name": "Basic Turret",
		"category": "defense",
		"size": Vector2i(1, 1),
		"cost": {"steel_ingot": 15, "electronics": 5, "gunpowder": 10},
		"health": 300,
		"layer": 2,
		"walkable": false,
		"turret": true,
		"damage": 15,
		"fire_rate": 2.0,
		"range": 200
	},
	"turret_advanced": {
		"name": "Advanced Turret",
		"category": "defense",
		"size": Vector2i(2, 2),
		"cost": {"titanium": 10, "advanced_circuits": 5, "polymer": 8},
		"health": 600,
		"layer": 2,
		"walkable": false,
		"turret": true,
		"damage": 35,
		"fire_rate": 3.5,
		"range": 300
	},
	"electric_fence": {
		"name": "Electric Fence",
		"category": "defense",
		"size": Vector2i(1, 1),
		"cost": {"steel_ingot": 5, "wire": 8, "electronics": 2},
		"health": 150,
		"layer": 1,
		"walkable": false,
		"electric": true,
		"damage": 10,
		"stun_duration": 1.5
	},
	
	# Utility
	"campfire": {
		"name": "Campfire",
		"category": "utility",
		"size": Vector2i(1, 1),
		"cost": {"wood": 5, "stone": 3},
		"health": 50,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"cooking": true,
		"light_radius": 150
	},
	"generator": {
		"name": "Generator",
		"category": "utility",
		"size": Vector2i(2, 2),
		"cost": {"steel_ingot": 20, "electronics": 15, "polymer": 10},
		"health": 400,
		"layer": 2,
		"walkable": false,
		"power_output": 100
	},
	"rain_collector": {
		"name": "Rain Collector",
		"category": "utility",
		"size": Vector2i(1, 1),
		"cost": {"wood": 10, "glass": 5},
		"health": 75,
		"layer": 2,
		"walkable": false,
		"water_production": 5
	},
	"garden_plot": {
		"name": "Garden Plot",
		"category": "utility",
		"size": Vector2i(2, 2),
		"cost": {"wood": 8},
		"health": 50,
		"layer": 0,
		"walkable": true,
		"farming": true,
		"growth_slots": 4
	},
	"bed": {
		"name": "Bed",
		"category": "utility",
		"size": Vector2i(1, 2),
		"cost": {"wood": 15, "cloth": 10},
		"health": 100,
		"layer": 2,
		"walkable": false,
		"interactable": true,
		"spawn_point": true
	}
}

# ============================================================================
# STATE
# ============================================================================

var base_size := GameConfig.BASE_STARTING_SIZE
var grid_offset := Vector2.ZERO  # World position of grid origin
var structures := {}  # Vector2i -> Array of structure data
var building_mode := false
var selected_structure_type := ""
var preview_node: Node2D = null
var can_place := false
var inventory: Node = null  # Reference to player inventory

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	_create_preview_node()
	set_process_input(false)  # Only process when building mode is on

func set_inventory(inv: Node) -> void:
	inventory = inv

func _create_preview_node() -> void:
	preview_node = Node2D.new()
	preview_node.visible = false
	add_child(preview_node)

# ============================================================================
# BUILDING MODE
# ============================================================================

func toggle_building_mode() -> void:
	building_mode = not building_mode
	set_process_input(building_mode)
	preview_node.visible = building_mode
	emit_signal("building_mode_changed", building_mode)

func enable_building_mode() -> void:
	if not building_mode:
		toggle_building_mode()

func disable_building_mode() -> void:
	if building_mode:
		toggle_building_mode()

func select_structure(structure_type: String) -> void:
	if not STRUCTURE_TYPES.has(structure_type):
		push_warning("Unknown structure type: " + structure_type)
		return
	
	selected_structure_type = structure_type
	_update_preview()

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input(event: InputEvent) -> void:
	if not building_mode:
		return
	
	if event is InputEventMouseMotion:
		_update_preview_position()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_attempt_place()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_attempt_remove()

func _update_preview_position() -> void:
	var mouse_pos := get_global_mouse_position()
	var grid_pos := world_to_grid(mouse_pos)
	preview_node.position = grid_to_world(grid_pos)
	can_place = _can_place_at(grid_pos, selected_structure_type)
	_update_preview_color()

func _update_preview() -> void:
	# Clear existing preview children
	for child in preview_node.get_children():
		child.queue_free()
	
	if selected_structure_type == "":
		return
	
	var structure_def: Dictionary = STRUCTURE_TYPES[selected_structure_type]
	var size: Vector2i = structure_def.get("size", Vector2i(1, 1))
	
	# Create preview sprite/shape
	var preview_rect := ColorRect.new()
	preview_rect.size = Vector2(size) * GameConfig.BASE_GRID_SIZE
	preview_rect.color = Color(0.3, 0.8, 0.3, 0.5)
	preview_node.add_child(preview_rect)

func _update_preview_color() -> void:
	for child in preview_node.get_children():
		if child is ColorRect:
			if can_place:
				child.color = Color(0.3, 0.8, 0.3, 0.5)
			else:
				child.color = Color(0.8, 0.3, 0.3, 0.5)

# ============================================================================
# GRID UTILITIES
# ============================================================================

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local := world_pos - grid_offset
	return Vector2i(
		int(floor(local.x / GameConfig.BASE_GRID_SIZE)),
		int(floor(local.y / GameConfig.BASE_GRID_SIZE))
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos) * GameConfig.BASE_GRID_SIZE + grid_offset

func is_within_base(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < base_size.x and \
		   grid_pos.y >= 0 and grid_pos.y < base_size.y

# ============================================================================
# PLACEMENT VALIDATION
# ============================================================================

func _can_place_at(grid_pos: Vector2i, structure_type: String) -> bool:
	if structure_type == "":
		return false
	
	if not STRUCTURE_TYPES.has(structure_type):
		return false
	
	var structure_def: Dictionary = STRUCTURE_TYPES[structure_type]
	var size: Vector2i = structure_def.get("size", Vector2i(1, 1))
	var layer: int = structure_def.get("layer", 0)
	var category: String = structure_def.get("category", "")
	
	# Check all cells the structure would occupy
	for dx in range(size.x):
		for dy in range(size.y):
			var check_pos := grid_pos + Vector2i(dx, dy)
			
			# Must be within base bounds
			if not is_within_base(check_pos):
				return false
			
			# Check for conflicts at same layer
			if _has_structure_at_layer(check_pos, layer):
				return false
			
			# Floors can only be placed on empty ground
			if category == "floor":
				pass  # Always placeable if no conflict
			
			# Walls require floor underneath
			elif category == "wall" or category == "door":
				if not _has_floor_at(check_pos):
					return false
			
			# Crafting/storage/utility requires floor
			elif category in ["crafting", "storage", "utility", "defense"]:
				if not _has_floor_at(check_pos):
					return false
	
	# Check if player has resources
	var cost: Dictionary = structure_def.get("cost", {})
	if inventory and not inventory.has_items(cost):
		return false
	
	return true

func _has_structure_at_layer(grid_pos: Vector2i, layer: int) -> bool:
	if not structures.has(grid_pos):
		return false
	
	for structure in structures[grid_pos]:
		if structure.get("layer", 0) == layer:
			return true
	
	return false

func _has_floor_at(grid_pos: Vector2i) -> bool:
	if not structures.has(grid_pos):
		return false
	
	for structure in structures[grid_pos]:
		if structure.get("category", "") == "floor":
			return true
	
	return false

func get_structure_at(grid_pos: Vector2i, layer: int = -1) -> Dictionary:
	if not structures.has(grid_pos):
		return {}
	
	for structure in structures[grid_pos]:
		if layer == -1 or structure.get("layer", 0) == layer:
			return structure
	
	return {}

# ============================================================================
# PLACEMENT AND REMOVAL
# ============================================================================

func _attempt_place() -> void:
	if not can_place or selected_structure_type == "":
		return
	
	var mouse_pos := get_global_mouse_position()
	var grid_pos := world_to_grid(mouse_pos)
	
	place_structure(grid_pos, selected_structure_type)

func place_structure(grid_pos: Vector2i, structure_type: String) -> bool:
	if not _can_place_at(grid_pos, structure_type):
		return false
	
	var structure_def: Dictionary = STRUCTURE_TYPES[structure_type]
	var cost: Dictionary = structure_def.get("cost", {})
	
	# Consume resources
	if inventory:
		if not inventory.remove_items(cost):
			emit_signal("resource_insufficient", cost)
			return false
	
	# Create structure data
	var structure_data := {
		"type": structure_type,
		"grid_pos": grid_pos,
		"health": structure_def.get("health", 100),
		"max_health": structure_def.get("health", 100),
		"layer": structure_def.get("layer", 0),
		"category": structure_def.get("category", ""),
		"node": null
	}
	
	# Store in grid
	var size: Vector2i = structure_def.get("size", Vector2i(1, 1))
	for dx in range(size.x):
		for dy in range(size.y):
			var cell := grid_pos + Vector2i(dx, dy)
			if not structures.has(cell):
				structures[cell] = []
			structures[cell].append(structure_data)
	
	# Create visual node
	var structure_node := _create_structure_node(structure_data)
	structure_data["node"] = structure_node
	
	emit_signal("structure_placed", structure_node, grid_pos)
	return true

func _create_structure_node(structure_data: Dictionary) -> Node2D:
	var structure_type: String = structure_data["type"]
	var structure_def: Dictionary = STRUCTURE_TYPES[structure_type]
	var grid_pos: Vector2i = structure_data["grid_pos"]
	var size: Vector2i = structure_def.get("size", Vector2i(1, 1))
	
	var node := Node2D.new()
	node.position = grid_to_world(grid_pos)
	node.name = structure_type + "_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	
	# Visual representation
	var visual := ColorRect.new()
	visual.size = Vector2(size) * GameConfig.BASE_GRID_SIZE
	
	# Color by category
	match structure_def.get("category", ""):
		"floor":
			visual.color = Color(0.4, 0.35, 0.25, 1.0)
		"wall":
			visual.color = Color(0.5, 0.45, 0.4, 1.0)
		"door":
			visual.color = Color(0.45, 0.35, 0.25, 1.0)
		"crafting":
			visual.color = Color(0.3, 0.4, 0.5, 1.0)
		"storage":
			visual.color = Color(0.5, 0.4, 0.3, 1.0)
		"defense":
			visual.color = Color(0.6, 0.3, 0.3, 1.0)
		"utility":
			visual.color = Color(0.3, 0.5, 0.4, 1.0)
		_:
			visual.color = Color(0.5, 0.5, 0.5, 1.0)
	
	node.add_child(visual)
	
	# Add collision if not walkable
	if not structure_def.get("walkable", true):
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(size) * GameConfig.BASE_GRID_SIZE
		collision.shape = shape
		collision.position = visual.size / 2
		body.add_child(collision)
		node.add_child(body)
	
	add_child(node)
	return node

func _attempt_remove() -> void:
	var mouse_pos := get_global_mouse_position()
	var grid_pos := world_to_grid(mouse_pos)
	remove_structure(grid_pos)

func remove_structure(grid_pos: Vector2i, layer: int = -1) -> bool:
	if not structures.has(grid_pos):
		return false
	
	var to_remove: Dictionary = {}
	
	# Find structure to remove (highest layer if not specified)
	for structure in structures[grid_pos]:
		if layer == -1 or structure.get("layer", 0) == layer:
			if to_remove.is_empty() or structure.get("layer", 0) > to_remove.get("layer", 0):
				to_remove = structure
	
	if to_remove.is_empty():
		return false
	
	# Remove from all cells it occupies
	var structure_def: Dictionary = STRUCTURE_TYPES.get(to_remove["type"], {})
	var size: Vector2i = structure_def.get("size", Vector2i(1, 1))
	var origin: Vector2i = to_remove["grid_pos"]
	
	for dx in range(size.x):
		for dy in range(size.y):
			var cell := origin + Vector2i(dx, dy)
			if structures.has(cell):
				structures[cell].erase(to_remove)
				if structures[cell].is_empty():
					structures.erase(cell)
	
	# Remove visual node
	if to_remove.has("node") and to_remove["node"] != null:
		to_remove["node"].queue_free()
	
	# Refund some resources
	var cost: Dictionary = structure_def.get("cost", {})
	if inventory:
		for resource in cost:
			var refund := int(cost[resource] * 0.5)  # 50% refund
			if refund > 0:
				inventory.add_item(resource, refund)
	
	emit_signal("structure_removed", grid_pos)
	return true

# ============================================================================
# BASE EXPANSION
# ============================================================================

func expand_base(direction: Vector2i) -> bool:
	# Check max size
	var new_size := base_size + Vector2i(abs(direction.x) * 5, abs(direction.y) * 5)
	if new_size.x > GameConfig.BASE_MAX_SIZE.x or new_size.y > GameConfig.BASE_MAX_SIZE.y:
		push_warning("Base at maximum size")
		return false
	
	# Check resources
	if inventory and not inventory.has_items(GameConfig.BASE_EXPANSION_COST):
		emit_signal("resource_insufficient", GameConfig.BASE_EXPANSION_COST)
		return false
	
	# Consume resources
	if inventory:
		inventory.remove_items(GameConfig.BASE_EXPANSION_COST)
	
	# Expand
	base_size = new_size
	
	# Adjust offset if expanding in negative direction
	if direction.x < 0:
		grid_offset.x -= 5 * GameConfig.BASE_GRID_SIZE
	if direction.y < 0:
		grid_offset.y -= 5 * GameConfig.BASE_GRID_SIZE
	
	emit_signal("base_expanded", base_size)
	return true

# ============================================================================
# DAMAGE AND REPAIR
# ============================================================================

func damage_structure(grid_pos: Vector2i, damage: float, layer: int = -1) -> void:
	var structure := get_structure_at(grid_pos, layer)
	if structure.is_empty():
		return
	
	structure["health"] -= damage
	
	if structure["health"] <= 0:
		remove_structure(grid_pos, structure.get("layer", 0))

func repair_structure(grid_pos: Vector2i, layer: int = -1) -> bool:
	var structure := get_structure_at(grid_pos, layer)
	if structure.is_empty():
		return false
	
	if structure["health"] >= structure["max_health"]:
		return false
	
	var structure_def: Dictionary = STRUCTURE_TYPES.get(structure["type"], {})
	var cost: Dictionary = structure_def.get("cost", {})
	
	# Calculate repair cost (30% of build cost)
	var repair_cost := {}
	for resource in cost:
		repair_cost[resource] = max(1, int(cost[resource] * GameConfig.WEAPON_REPAIR_COST_MULTIPLIER))
	
	if inventory and not inventory.has_items(repair_cost):
		emit_signal("resource_insufficient", repair_cost)
		return false
	
	if inventory:
		inventory.remove_items(repair_cost)
	
	structure["health"] = structure["max_health"]
	return true

# ============================================================================
# QUERIES
# ============================================================================

func get_crafting_stations() -> Array:
	var stations := []
	for pos in structures:
		for structure in structures[pos]:
			if structure.get("category", "") == "crafting":
				stations.append(structure)
	return stations

func get_highest_crafting_tier() -> int:
	var highest := 0
	for station in get_crafting_stations():
		var structure_def: Dictionary = STRUCTURE_TYPES.get(station["type"], {})
		var tier: int = structure_def.get("crafting_tier", 0)
		highest = max(highest, tier)
	return highest

func get_storage_containers() -> Array:
	var containers := []
	for pos in structures:
		for structure in structures[pos]:
			if structure.get("category", "") == "storage":
				containers.append(structure)
	return containers

func get_total_storage_slots() -> int:
	var total := 0
	for container in get_storage_containers():
		var structure_def: Dictionary = STRUCTURE_TYPES.get(container["type"], {})
		total += structure_def.get("storage_slots", 0)
	return total

func get_defenses() -> Array:
	var defenses := []
	for pos in structures:
		for structure in structures[pos]:
			if structure.get("category", "") == "defense":
				defenses.append(structure)
	return defenses

func get_power_output() -> int:
	var power := 0
	for pos in structures:
		for structure in structures[pos]:
			var structure_def: Dictionary = STRUCTURE_TYPES.get(structure["type"], {})
			power += structure_def.get("power_output", 0)
	return power

# ============================================================================
# SAVE/LOAD
# ============================================================================

func get_save_data() -> Dictionary:
	var save_structures := []
	var processed := {}
	
	for pos in structures:
		for structure in structures[pos]:
			var origin: Vector2i = structure["grid_pos"]
			var key := str(origin.x) + "_" + str(origin.y) + "_" + str(structure.get("layer", 0))
			if not processed.has(key):
				processed[key] = true
				save_structures.append({
					"type": structure["type"],
					"grid_pos": [origin.x, origin.y],
					"health": structure["health"]
				})
	
	return {
		"base_size": [base_size.x, base_size.y],
		"grid_offset": [grid_offset.x, grid_offset.y],
		"structures": save_structures
	}

func load_save_data(data: Dictionary) -> void:
	# Clear existing
	for pos in structures.keys():
		for structure in structures[pos]:
			if structure.has("node") and structure["node"] != null:
				structure["node"].queue_free()
	structures.clear()
	
	# Load base size
	if data.has("base_size"):
		base_size = Vector2i(data["base_size"][0], data["base_size"][1])
	
	if data.has("grid_offset"):
		grid_offset = Vector2(data["grid_offset"][0], data["grid_offset"][1])
	
	# Rebuild structures
	if data.has("structures"):
		for struct_data in data["structures"]:
			var grid_pos := Vector2i(struct_data["grid_pos"][0], struct_data["grid_pos"][1])
			var structure_type: String = struct_data["type"]
			
			# Temporarily disable inventory check
			var temp_inv := inventory
			inventory = null
			
			if place_structure(grid_pos, structure_type):
				# Apply saved health
				var structure := get_structure_at(grid_pos)
				if not structure.is_empty():
					structure["health"] = struct_data.get("health", structure["max_health"])
			
			inventory = temp_inv
