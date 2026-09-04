extends Node
class_name ResourceSpawnerClass
## Handles spawning and management of harvestable resource nodes
## Trees, rocks, bushes, plants, ore deposits, etc.

signal resource_harvested(resource_type: String, amount: int, position: Vector2)
signal resource_depleted(node_id: String)
signal resource_respawned(node_id: String)

# ============================================================================
# RESOURCE DEFINITIONS
# ============================================================================

enum ResourceCategory {
	TREE,
	ROCK,
	ORE,
	BUSH,
	PLANT,
	CRATE,
	SPECIAL,
}

const RESOURCE_DEFINITIONS := {
	# Trees
	"pine_tree": {
		"category": ResourceCategory.TREE,
		"display_name": "Pine Tree",
		"yields": {"wood": [3, 6], "plant_fiber": [0, 2]},
		"tool_required": "hatchet",
		"tool_tier_min": 1,
		"harvest_time": 3.0,
		"hp": 100,
		"respawn_time": 600,
		"scene": "res://scenes/resources/TreeNode.tscn",
		"sprite": "pine_tree",
		"size": Vector2(2, 3),
	},
	"oak_tree": {
		"category": ResourceCategory.TREE,
		"display_name": "Oak Tree",
		"yields": {"wood": [4, 8], "plant_fiber": [1, 3]},
		"tool_required": "hatchet",
		"tool_tier_min": 1,
		"harvest_time": 4.0,
		"hp": 150,
		"respawn_time": 900,
		"scene": "res://scenes/resources/TreeNode.tscn",
		"sprite": "oak_tree",
		"size": Vector2(2, 4),
	},
	"dead_tree": {
		"category": ResourceCategory.TREE,
		"display_name": "Dead Tree",
		"yields": {"wood": [2, 4]},
		"tool_required": "hatchet",
		"tool_tier_min": 1,
		"harvest_time": 2.0,
		"hp": 60,
		"respawn_time": 0,  # Doesn't respawn
		"scene": "res://scenes/resources/TreeNode.tscn",
		"sprite": "dead_tree",
		"size": Vector2(1, 2),
	},
	
	# Rocks
	"stone_boulder": {
		"category": ResourceCategory.ROCK,
		"display_name": "Stone Boulder",
		"yields": {"stone": [2, 5]},
		"tool_required": "pickaxe",
		"tool_tier_min": 1,
		"harvest_time": 3.0,
		"hp": 120,
		"respawn_time": 480,
		"scene": "res://scenes/resources/RockNode.tscn",
		"sprite": "boulder",
		"size": Vector2(2, 2),
	},
	"limestone_rock": {
		"category": ResourceCategory.ROCK,
		"display_name": "Limestone",
		"yields": {"stone": [3, 6], "iron_ore": [0, 1]},
		"tool_required": "pickaxe",
		"tool_tier_min": 1,
		"harvest_time": 4.0,
		"hp": 150,
		"respawn_time": 600,
		"scene": "res://scenes/resources/RockNode.tscn",
		"sprite": "limestone",
		"size": Vector2(2, 2),
	},
	
	# Ore Deposits
	"iron_deposit": {
		"category": ResourceCategory.ORE,
		"display_name": "Iron Deposit",
		"yields": {"iron_ore": [2, 4], "stone": [1, 2]},
		"tool_required": "pickaxe",
		"tool_tier_min": 2,
		"harvest_time": 5.0,
		"hp": 200,
		"respawn_time": 1800,
		"scene": "res://scenes/resources/RockNode.tscn",
		"sprite": "iron_ore",
		"size": Vector2(2, 2),
	},
	"copper_deposit": {
		"category": ResourceCategory.ORE,
		"display_name": "Copper Deposit",
		"yields": {"copper_ore": [2, 4], "stone": [1, 2]},
		"tool_required": "pickaxe",
		"tool_tier_min": 2,
		"harvest_time": 5.0,
		"hp": 180,
		"respawn_time": 1800,
		"scene": "res://scenes/resources/RockNode.tscn",
		"sprite": "copper_ore",
		"size": Vector2(2, 2),
	},
	"coal_deposit": {
		"category": ResourceCategory.ORE,
		"display_name": "Coal Deposit",
		"yields": {"coal": [3, 6]},
		"tool_required": "pickaxe",
		"tool_tier_min": 1,
		"harvest_time": 3.0,
		"hp": 100,
		"respawn_time": 1200,
		"scene": "res://scenes/resources/RockNode.tscn",
		"sprite": "coal",
		"size": Vector2(1, 1),
	},
	"titanium_vein": {
		"category": ResourceCategory.ORE,
		"display_name": "Titanium Vein",
		"yields": {"titanium_bar": [1, 2], "stone": [2, 4]},
		"tool_required": "pickaxe",
		"tool_tier_min": 3,
		"harvest_time": 8.0,
		"hp": 400,
		"respawn_time": 7200,
		"scene": "res://scenes/resources/RockNode.tscn",
		"sprite": "titanium",
		"size": Vector2(2, 2),
		"zone_difficulty_min": 2,
	},
	
	# Bushes
	"berry_bush": {
		"category": ResourceCategory.BUSH,
		"display_name": "Berry Bush",
		"yields": {"berries": [2, 5]},
		"tool_required": null,
		"tool_tier_min": 0,
		"harvest_time": 1.5,
		"hp": 20,
		"respawn_time": 300,
		"scene": "res://scenes/resources/PlantNode.tscn",
		"sprite": "berry_bush",
		"size": Vector2(1, 1),
	},
	"fiber_bush": {
		"category": ResourceCategory.BUSH,
		"display_name": "Fiber Bush",
		"yields": {"plant_fiber": [2, 4]},
		"tool_required": null,
		"tool_tier_min": 0,
		"harvest_time": 1.0,
		"hp": 15,
		"respawn_time": 180,
		"scene": "res://scenes/resources/PlantNode.tscn",
		"sprite": "fiber_bush",
		"size": Vector2(1, 1),
	},
	
	# Plants
	"wild_carrot": {
		"category": ResourceCategory.PLANT,
		"display_name": "Wild Carrot",
		"yields": {"carrot": [1, 2]},
		"tool_required": null,
		"tool_tier_min": 0,
		"harvest_time": 0.5,
		"hp": 5,
		"respawn_time": 240,
		"scene": "res://scenes/resources/PlantNode.tscn",
		"sprite": "wild_carrot",
		"size": Vector2(1, 1),
	},
	"mushroom_cluster": {
		"category": ResourceCategory.PLANT,
		"display_name": "Mushroom Cluster",
		"yields": {"mushroom": [1, 3]},
		"tool_required": null,
		"tool_tier_min": 0,
		"harvest_time": 0.5,
		"hp": 5,
		"respawn_time": 360,
		"scene": "res://scenes/resources/PlantNode.tscn",
		"sprite": "mushroom",
		"size": Vector2(1, 1),
	},
	"corn_stalk": {
		"category": ResourceCategory.PLANT,
		"display_name": "Corn Stalk",
		"yields": {"corn": [1, 2]},
		"tool_required": null,
		"tool_tier_min": 0,
		"harvest_time": 1.0,
		"hp": 10,
		"respawn_time": 480,
		"scene": "res://scenes/resources/PlantNode.tscn",
		"sprite": "corn",
		"size": Vector2(1, 2),
	},
	"hemp_plant": {
		"category": ResourceCategory.PLANT,
		"display_name": "Hemp Plant",
		"yields": {"plant_fiber": [3, 5], "cloth": [0, 1]},
		"tool_required": null,
		"tool_tier_min": 0,
		"harvest_time": 1.5,
		"hp": 15,
		"respawn_time": 420,
		"scene": "res://scenes/resources/PlantNode.tscn",
		"sprite": "hemp",
		"size": Vector2(1, 2),
	},
	
	# Special
	"scrap_pile": {
		"category": ResourceCategory.SPECIAL,
		"display_name": "Scrap Pile",
		"yields": {"scrap_metal": [2, 5], "electronics": [0, 1]},
		"tool_required": null,
		"tool_tier_min": 0,
		"harvest_time": 2.0,
		"hp": 30,
		"respawn_time": 600,
		"scene": "res://scenes/resources/PlantNode.tscn",
		"sprite": "scrap_pile",
		"size": Vector2(1, 1),
	},
	"abandoned_crate": {
		"category": ResourceCategory.CRATE,
		"display_name": "Abandoned Crate",
		"yields": {"random": [1, 3]},
		"tool_required": null,
		"tool_tier_min": 0,
		"harvest_time": 2.0,
		"hp": 40,
		"respawn_time": 900,
		"scene": "res://scenes/resources/LootItem.tscn",
		"sprite": "crate",
		"size": Vector2(1, 1),
		"loot_table": "basic_crate",
	},
	"military_crate": {
		"category": ResourceCategory.CRATE,
		"display_name": "Military Crate",
		"yields": {"random": [2, 4]},
		"tool_required": "crowbar",
		"tool_tier_min": 1,
		"harvest_time": 3.0,
		"hp": 80,
		"respawn_time": 3600,
		"scene": "res://scenes/resources/LootItem.tscn",
		"sprite": "military_crate",
		"size": Vector2(1, 1),
		"loot_table": "military_crate",
		"zone_difficulty_min": 2,
	},
}

# Zone-specific resource spawn weights
const ZONE_RESOURCE_WEIGHTS := {
	0: {  # FOREST
		"pine_tree": 10, "oak_tree": 8, "dead_tree": 3,
		"stone_boulder": 4, "limestone_rock": 2,
		"iron_deposit": 1, "copper_deposit": 1, "coal_deposit": 2,
		"berry_bush": 6, "fiber_bush": 8,
		"mushroom_cluster": 4,
	},
	1: {  # CITY
		"scrap_pile": 10, "abandoned_crate": 6, "military_crate": 1,
		"fiber_bush": 2,
	},
	2: {  # INDUSTRIAL
		"scrap_pile": 15, "iron_deposit": 5, "copper_deposit": 5, "coal_deposit": 8,
		"abandoned_crate": 8, "military_crate": 2,
		"stone_boulder": 3,
	},
	3: {  # MILITARY
		"military_crate": 8, "abandoned_crate": 4, "scrap_pile": 5,
	},
	4: {  # FARM
		"wild_carrot": 8, "corn_stalk": 10, "hemp_plant": 6,
		"berry_bush": 4, "fiber_bush": 5,
		"pine_tree": 3, "dead_tree": 2,
	},
	5: {  # HIGHWAY
		"scrap_pile": 10, "abandoned_crate": 5,
	},
	6: {  # BUNKER
		"military_crate": 10, "scrap_pile": 5,
	},
	7: {  # SWAMP
		"dead_tree": 6, "mushroom_cluster": 10, "fiber_bush": 8,
		"hemp_plant": 5,
	},
	8: {  # DESERT
		"stone_boulder": 8, "limestone_rock": 5,
		"iron_deposit": 4, "copper_deposit": 4, "coal_deposit": 3,
		"titanium_vein": 1,
	},
	9: {  # WINTER
		"pine_tree": 10, "dead_tree": 5,
		"stone_boulder": 4, "coal_deposit": 3,
		"berry_bush": 2,
	},
}


# ============================================================================
# STATE
# ============================================================================

var _spawned_nodes: Dictionary = {}  # node_id -> node data
var _depleted_nodes: Dictionary = {}  # node_id -> depletion timestamp
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func _process(delta: float) -> void:
	_check_respawns()


# ============================================================================
# SPAWNING
# ============================================================================

func spawn_resources_for_zone(zone_data: Dictionary) -> Array[Dictionary]:
	## Generate resource nodes for a zone
	var zone_type: int = zone_data.get("type", 0)
	var zone_seed: int = zone_data.get("seed", randi())
	var zone_size: Vector2i = zone_data.get("size", Vector2i(64, 64))
	var difficulty: int = zone_data.get("difficulty", 0)
	
	_rng.seed = zone_seed
	
	var resources: Array[Dictionary] = []
	var weights: Dictionary = ZONE_RESOURCE_WEIGHTS.get(zone_type, {})
	
	if weights.is_empty():
		return resources
	
	# Calculate total weight
	var total_weight := 0
	for w in weights.values():
		total_weight += w
	
	# Determine resource density
	var base_count := int((zone_size.x * zone_size.y) / 50)
	var resource_count := base_count + _rng.randi_range(-10, 10)
	resource_count = clampi(resource_count, 20, 200)
	
	# Track placed positions
	var placed: Dictionary = {}
	var tiles: Array = zone_data.get("tiles", [])
	
	for i in range(resource_count):
		# Select resource type
		var resource_type := _select_weighted_resource(weights, total_weight)
		var resource_def: Dictionary = RESOURCE_DEFINITIONS.get(resource_type, {})
		
		if resource_def.is_empty():
			continue
		
		# Check difficulty requirement
		var min_difficulty: int = resource_def.get("zone_difficulty_min", 0)
		if difficulty < min_difficulty:
			continue
		
		# Find valid position
		var position := _find_resource_position(zone_data, placed, resource_def)
		if position == Vector2i(-1, -1):
			continue
		
		# Mark position as occupied
		var size: Vector2 = resource_def.get("size", Vector2(1, 1))
		for y in range(int(size.y)):
			for x in range(int(size.x)):
				placed[Vector2i(position.x + x, position.y + y)] = true
		
		# Generate unique ID
		var node_id := "%s_%d_%d_%d" % [resource_type, zone_seed, position.x, position.y]
		
		# Check if depleted
		var is_depleted := node_id in _depleted_nodes
		var respawn_remaining := 0.0
		
		if is_depleted:
			var depleted_time: int = _depleted_nodes[node_id]
			var respawn_time: int = resource_def.get("respawn_time", 600)
			var current_time := int(Time.get_unix_time_from_system())
			
			if respawn_time > 0 and current_time - depleted_time >= respawn_time:
				# Respawned
				_depleted_nodes.erase(node_id)
				is_depleted = false
			else:
				respawn_remaining = respawn_time - (current_time - depleted_time)
		
		var node_data := {
			"id": node_id,
			"type": resource_type,
			"display_name": resource_def.get("display_name", resource_type),
			"category": resource_def.get("category", ResourceCategory.PLANT),
			"position": position,
			"world_position": Vector2(position.x * 32, position.y * 32),
			"size": size,
			"hp": resource_def.get("hp", 100),
			"current_hp": resource_def.get("hp", 100),
			"yields": resource_def.get("yields", {}),
			"tool_required": resource_def.get("tool_required", null),
			"tool_tier_min": resource_def.get("tool_tier_min", 0),
			"harvest_time": resource_def.get("harvest_time", 1.0),
			"respawn_time": resource_def.get("respawn_time", 600),
			"scene": resource_def.get("scene", ""),
			"sprite": resource_def.get("sprite", ""),
			"loot_table": resource_def.get("loot_table", ""),
			"is_depleted": is_depleted,
			"respawn_remaining": respawn_remaining,
		}
		
		resources.append(node_data)
		_spawned_nodes[node_id] = node_data
	
	return resources


func _select_weighted_resource(weights: Dictionary, total: int) -> String:
	var roll := _rng.randi() % total
	var cumulative := 0
	
	for resource_type in weights:
		cumulative += weights[resource_type]
		if roll < cumulative:
			return resource_type
	
	return weights.keys()[0]


func _find_resource_position(zone_data: Dictionary, placed: Dictionary, resource_def: Dictionary) -> Vector2i:
	var zone_size: Vector2i = zone_data.get("size", Vector2i(64, 64))
	var tiles: Array = zone_data.get("tiles", [])
	var size: Vector2 = resource_def.get("size", Vector2(1, 1))
	var category: int = resource_def.get("category", ResourceCategory.PLANT)
	
	for _attempt in range(30):
		var x := _rng.randi_range(2, zone_size.x - int(size.x) - 2)
		var y := _rng.randi_range(2, zone_size.y - int(size.y) - 2)
		var pos := Vector2i(x, y)
		
		# Check if already occupied
		var blocked := false
		for dy in range(int(size.y)):
			for dx in range(int(size.x)):
				if Vector2i(x + dx, y + dy) in placed:
					blocked = true
					break
			if blocked:
				break
		
		if blocked:
			continue
		
		# Check tile compatibility
		if tiles.size() > y and tiles[y].size() > x:
			var tile: int = tiles[y][x]
			
			# Water and walls are always invalid
			if tile == 4 or tile == 7:  # WATER or WALL
				continue
			
			# Category-specific checks
			match category:
				ResourceCategory.TREE:
					# Trees can grow on grass or dirt
					if tile not in [1, 2, 9]:  # GRASS, DIRT, SNOW
						continue
				ResourceCategory.ORE, ResourceCategory.ROCK:
					# Ore/rocks on any ground
					if tile == 5:  # ROAD
						continue
				ResourceCategory.PLANT, ResourceCategory.BUSH:
					# Plants on grass or dirt
					if tile not in [1, 2, 10]:  # GRASS, DIRT, MUD
						continue
		
		return pos
	
	return Vector2i(-1, -1)


# ============================================================================
# HARVESTING
# ============================================================================

func can_harvest(node_id: String, tool_id: String, tool_tier: int) -> Dictionary:
	## Check if player can harvest this resource
	if node_id not in _spawned_nodes:
		return {"can_harvest": false, "reason": "Resource not found"}
	
	var node_data: Dictionary = _spawned_nodes[node_id]
	
	if node_data["is_depleted"]:
		return {"can_harvest": false, "reason": "Resource depleted"}
	
	var required_tool: String = node_data.get("tool_required", "")
	var required_tier: int = node_data.get("tool_tier_min", 0)
	
	if required_tool and tool_id != required_tool:
		return {"can_harvest": false, "reason": "Requires " + required_tool}
	
	if tool_tier < required_tier:
		return {"can_harvest": false, "reason": "Tool tier too low"}
	
	return {"can_harvest": true, "harvest_time": node_data.get("harvest_time", 1.0)}


func damage_resource(node_id: String, damage: float, tool_tier: int = 1) -> Dictionary:
	## Apply damage to resource node, returns harvest result if depleted
	if node_id not in _spawned_nodes:
		return {}
	
	var node_data: Dictionary = _spawned_nodes[node_id]
	
	if node_data["is_depleted"]:
		return {}
	
	# Apply damage with tool tier bonus
	var effective_damage := damage * (1.0 + (tool_tier - 1) * 0.25)
	node_data["current_hp"] -= effective_damage
	
	# Check if depleted
	if node_data["current_hp"] <= 0:
		return _harvest_resource(node_id)
	
	return {"damaged": true, "remaining_hp": node_data["current_hp"]}


func _harvest_resource(node_id: String) -> Dictionary:
	## Fully harvest a resource and generate yields
	if node_id not in _spawned_nodes:
		return {}
	
	var node_data: Dictionary = _spawned_nodes[node_id]
	var yields: Dictionary = node_data.get("yields", {})
	var result := {
		"harvested": true,
		"items": {},
		"node_id": node_id,
		"position": node_data.get("world_position", Vector2.ZERO),
	}
	
	# Generate yield amounts
	for item_type in yields:
		if item_type == "random":
			# Handle random loot table
			var loot_table: String = node_data.get("loot_table", "basic_crate")
			result["loot_table"] = loot_table
			continue
		
		var range_arr: Array = yields[item_type]
		var amount := _rng.randi_range(range_arr[0], range_arr[1])
		if amount > 0:
			result["items"][item_type] = amount
	
	# Mark as depleted
	node_data["is_depleted"] = true
	node_data["current_hp"] = 0
	_depleted_nodes[node_id] = int(Time.get_unix_time_from_system())
	
	emit_signal("resource_harvested", node_data["type"], result["items"].size(), node_data.get("world_position", Vector2.ZERO))
	emit_signal("resource_depleted", node_id)
	
	return result


func instant_harvest(node_id: String) -> Dictionary:
	## Instantly harvest without damage (for debugging or special cases)
	return _harvest_resource(node_id)


# ============================================================================
# RESPAWNING
# ============================================================================

func _check_respawns() -> void:
	## Check for resources ready to respawn
	var current_time := int(Time.get_unix_time_from_system())
	var to_respawn: Array[String] = []
	
	for node_id in _depleted_nodes:
		var depleted_time: int = _depleted_nodes[node_id]
		
		if node_id in _spawned_nodes:
			var node_data: Dictionary = _spawned_nodes[node_id]
			var respawn_time: int = node_data.get("respawn_time", 600)
			
			if respawn_time > 0 and current_time - depleted_time >= respawn_time:
				to_respawn.append(node_id)
	
	for node_id in to_respawn:
		_respawn_resource(node_id)


func _respawn_resource(node_id: String) -> void:
	if node_id not in _spawned_nodes:
		return
	
	var node_data: Dictionary = _spawned_nodes[node_id]
	node_data["is_depleted"] = false
	node_data["current_hp"] = node_data.get("hp", 100)
	
	_depleted_nodes.erase(node_id)
	
	emit_signal("resource_respawned", node_id)


# ============================================================================
# QUERIES
# ============================================================================

func get_resource(node_id: String) -> Dictionary:
	return _spawned_nodes.get(node_id, {})


func get_resources_in_radius(position: Vector2, radius: float) -> Array[Dictionary]:
	var nearby: Array[Dictionary] = []
	
	for node_data in _spawned_nodes.values():
		var node_pos: Vector2 = node_data.get("world_position", Vector2.ZERO)
		if position.distance_to(node_pos) <= radius:
			nearby.append(node_data)
	
	return nearby


func get_resources_by_type(resource_type: String) -> Array[Dictionary]:
	var matching: Array[Dictionary] = []
	
	for node_data in _spawned_nodes.values():
		if node_data.get("type", "") == resource_type:
			matching.append(node_data)
	
	return matching


func get_harvestable_resources() -> Array[Dictionary]:
	var harvestable: Array[Dictionary] = []
	
	for node_data in _spawned_nodes.values():
		if not node_data.get("is_depleted", false):
			harvestable.append(node_data)
	
	return harvestable


func get_resource_count() -> int:
	return _spawned_nodes.size()


func get_depleted_count() -> int:
	return _depleted_nodes.size()


# ============================================================================
# ZONE MANAGEMENT
# ============================================================================

func clear_zone_resources() -> void:
	## Clear resources when leaving zone
	_spawned_nodes.clear()
	# Note: _depleted_nodes persists for respawn tracking


func get_zone_resource_summary() -> Dictionary:
	var summary := {
		"total": 0,
		"harvestable": 0,
		"depleted": 0,
		"by_category": {},
		"by_type": {},
	}
	
	for node_data in _spawned_nodes.values():
		summary["total"] += 1
		
		if node_data.get("is_depleted", false):
			summary["depleted"] += 1
		else:
			summary["harvestable"] += 1
		
		var category: int = node_data.get("category", 0)
		var cat_name := ResourceCategory.keys()[category]
		summary["by_category"][cat_name] = summary["by_category"].get(cat_name, 0) + 1
		
		var res_type: String = node_data.get("type", "unknown")
		summary["by_type"][res_type] = summary["by_type"].get(res_type, 0) + 1
	
	return summary


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var node_states := {}
	for node_id in _spawned_nodes:
		var node_data: Dictionary = _spawned_nodes[node_id]
		node_states[node_id] = {
			"current_hp": node_data.get("current_hp", 0),
			"is_depleted": node_data.get("is_depleted", false),
		}
	
	return {
		"depleted_nodes": _depleted_nodes.duplicate(),
		"node_states": node_states,
	}


func load_data(data: Dictionary) -> void:
	_depleted_nodes = data.get("depleted_nodes", {})
	
	# Apply saved states to spawned nodes
	var node_states: Dictionary = data.get("node_states", {})
	for node_id in node_states:
		if node_id in _spawned_nodes:
			_spawned_nodes[node_id]["current_hp"] = node_states[node_id].get("current_hp", 100)
			_spawned_nodes[node_id]["is_depleted"] = node_states[node_id].get("is_depleted", false)
