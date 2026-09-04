extends Node
class_name WorkstationSystemClass
## Manages all workstation types for crafting, smelting, cooking, and processing
## Handles queued recipes, fuel consumption, and output collection

signal workstation_placed(station_id: String, station_type: int)
signal workstation_removed(station_id: String)
signal crafting_started(station_id: String, recipe_id: String)
signal crafting_progress(station_id: String, progress: float)
signal crafting_completed(station_id: String, recipe_id: String, output: Dictionary)
signal fuel_consumed(station_id: String, remaining: float)
signal fuel_depleted(station_id: String)

# ============================================================================
# WORKSTATION TYPES
# ============================================================================

enum WorkstationType {
	CAMPFIRE,
	WORKBENCH,
	FURNACE,
	CHEMISTRY_STATION,
	MEDICAL_TABLE,
	WEAPONS_BENCH,
	ARMOR_BENCH,
	ELECTRONICS_BENCH,
	STONE_CUTTER,
	TANNING_RACK,
	WATER_COLLECTOR,
	GARDEN_BED,
	GENERATOR,
	RECYCLER,
	REPAIR_STATION,
}

enum FuelType {
	NONE,
	WOOD,
	COAL,
	GASOLINE,
	ELECTRICITY,
}

const WORKSTATION_DEFINITIONS := {
	WorkstationType.CAMPFIRE: {
		"display_name": "Campfire",
		"description": "Basic cooking and light source",
		"unlock_level": 1,
		"build_cost": {"stone": 5, "wood": 3},
		"fuel_type": FuelType.WOOD,
		"fuel_capacity": 100.0,
		"fuel_burn_rate": 1.0,  # Per second when active
		"crafting_speed": 1.0,
		"input_slots": 4,
		"output_slots": 4,
		"fuel_slots": 2,
		"recipes": ["cook_meat", "cook_fish", "boil_water", "cook_stew", "cook_soup", "dry_meat"],
		"provides_light": true,
		"provides_warmth": true,
		"warmth_radius": 150.0,
		"size": Vector2i(1, 1),
		"sprite": "campfire",
	},
	WorkstationType.WORKBENCH: {
		"display_name": "Workbench",
		"description": "Craft tools, weapons, and basic items",
		"unlock_level": 2,
		"build_cost": {"wood": 15, "nails": 10, "rope": 2},
		"fuel_type": FuelType.NONE,
		"fuel_capacity": 0,
		"fuel_burn_rate": 0,
		"crafting_speed": 1.0,
		"input_slots": 6,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["wooden_hatchet", "stone_pickaxe", "wooden_spear", "bow", "arrows", "repair_kit", "nails", "rope", "plank"],
		"provides_light": false,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "workbench",
	},
	WorkstationType.FURNACE: {
		"display_name": "Furnace",
		"description": "Smelt ores into bars and process metals",
		"unlock_level": 5,
		"build_cost": {"stone": 20, "iron_ore": 5, "clay": 10},
		"fuel_type": FuelType.COAL,
		"fuel_capacity": 200.0,
		"fuel_burn_rate": 0.5,
		"crafting_speed": 0.8,
		"input_slots": 6,
		"output_slots": 6,
		"fuel_slots": 4,
		"recipes": ["smelt_iron", "smelt_copper", "smelt_aluminum", "smelt_titanium", "make_steel", "make_glass", "make_brick"],
		"provides_light": true,
		"provides_warmth": true,
		"warmth_radius": 100.0,
		"size": Vector2i(2, 2),
		"sprite": "furnace",
	},
	WorkstationType.CHEMISTRY_STATION: {
		"display_name": "Chemistry Station",
		"description": "Create chemicals, medicines, and explosives",
		"unlock_level": 10,
		"build_cost": {"steel_plate": 10, "glass": 5, "electronics": 3, "rubber": 5},
		"fuel_type": FuelType.ELECTRICITY,
		"fuel_capacity": 500.0,
		"fuel_burn_rate": 2.0,
		"crafting_speed": 1.2,
		"input_slots": 8,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["gunpowder", "acid", "antibiotics", "antidote", "adrenaline", "stimulant", "explosive"],
		"provides_light": true,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "chemistry_station",
	},
	WorkstationType.MEDICAL_TABLE: {
		"display_name": "Medical Table",
		"description": "Create advanced medical supplies",
		"unlock_level": 8,
		"build_cost": {"steel_plate": 8, "cloth": 15, "leather": 5},
		"fuel_type": FuelType.NONE,
		"fuel_capacity": 0,
		"fuel_burn_rate": 0,
		"crafting_speed": 1.0,
		"input_slots": 6,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["first_aid_kit", "medkit", "bandage", "splint", "blood_bag", "surgery_kit"],
		"provides_light": false,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "medical_table",
	},
	WorkstationType.WEAPONS_BENCH: {
		"display_name": "Weapons Bench",
		"description": "Craft and modify weapons",
		"unlock_level": 7,
		"build_cost": {"steel_plate": 15, "wood": 10, "nails": 20},
		"fuel_type": FuelType.NONE,
		"fuel_capacity": 0,
		"fuel_burn_rate": 0,
		"crafting_speed": 0.9,
		"input_slots": 8,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["pistol", "shotgun", "rifle", "smg", "ammo_9mm", "ammo_556", "ammo_762", "ammo_shotgun", "weapon_mod"],
		"provides_light": false,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "weapons_bench",
	},
	WorkstationType.ARMOR_BENCH: {
		"display_name": "Armor Bench",
		"description": "Craft protective gear and clothing",
		"unlock_level": 6,
		"build_cost": {"wood": 15, "leather": 10, "cloth": 10},
		"fuel_type": FuelType.NONE,
		"fuel_capacity": 0,
		"fuel_burn_rate": 0,
		"crafting_speed": 1.0,
		"input_slots": 6,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["leather_armor", "military_vest", "tactical_helmet", "boots", "gloves", "backpack"],
		"provides_light": false,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "armor_bench",
	},
	WorkstationType.ELECTRONICS_BENCH: {
		"display_name": "Electronics Bench",
		"description": "Craft electronic components and devices",
		"unlock_level": 12,
		"build_cost": {"steel_plate": 10, "electronics": 10, "copper_wire": 15},
		"fuel_type": FuelType.ELECTRICITY,
		"fuel_capacity": 300.0,
		"fuel_burn_rate": 1.5,
		"crafting_speed": 1.0,
		"input_slots": 8,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["circuit_board", "battery", "radio", "flashlight", "night_vision", "motion_sensor", "turret_controller"],
		"provides_light": true,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "electronics_bench",
	},
	WorkstationType.STONE_CUTTER: {
		"display_name": "Stone Cutter",
		"description": "Process stone into building materials",
		"unlock_level": 4,
		"build_cost": {"stone": 25, "iron_bar": 5},
		"fuel_type": FuelType.NONE,
		"fuel_capacity": 0,
		"fuel_burn_rate": 0,
		"crafting_speed": 0.7,
		"input_slots": 4,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["stone_block", "stone_brick", "gravel", "limestone_block"],
		"provides_light": false,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "stone_cutter",
	},
	WorkstationType.TANNING_RACK: {
		"display_name": "Tanning Rack",
		"description": "Process hides into leather",
		"unlock_level": 3,
		"build_cost": {"wood": 20, "rope": 5},
		"fuel_type": FuelType.NONE,
		"fuel_capacity": 0,
		"fuel_burn_rate": 0,
		"crafting_speed": 0.5,
		"input_slots": 4,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["leather", "thick_leather", "fur"],
		"provides_light": false,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "tanning_rack",
	},
	WorkstationType.WATER_COLLECTOR: {
		"display_name": "Water Collector",
		"description": "Collect and purify water",
		"unlock_level": 2,
		"build_cost": {"wood": 10, "cloth": 5, "empty_bottle": 3},
		"fuel_type": FuelType.NONE,
		"fuel_capacity": 0,
		"fuel_burn_rate": 0,
		"crafting_speed": 0.2,  # Slow passive collection
		"input_slots": 0,
		"output_slots": 6,
		"fuel_slots": 0,
		"recipes": ["collect_water"],
		"provides_light": false,
		"provides_warmth": false,
		"passive": true,  # Works automatically
		"size": Vector2i(1, 1),
		"sprite": "water_collector",
	},
	WorkstationType.GARDEN_BED: {
		"display_name": "Garden Bed",
		"description": "Grow crops and plants",
		"unlock_level": 3,
		"build_cost": {"wood": 8, "plant_fiber": 10},
		"fuel_type": FuelType.NONE,
		"fuel_capacity": 0,
		"fuel_burn_rate": 0,
		"crafting_speed": 0.1,  # Very slow growth
		"input_slots": 4,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["grow_carrot", "grow_corn", "grow_potato", "grow_hemp", "grow_berries"],
		"provides_light": false,
		"provides_warmth": false,
		"passive": true,
		"needs_water": true,
		"size": Vector2i(2, 2),
		"sprite": "garden_bed",
	},
	WorkstationType.GENERATOR: {
		"display_name": "Generator",
		"description": "Provides electricity to connected stations",
		"unlock_level": 15,
		"build_cost": {"steel_plate": 20, "electronics": 10, "engine_part": 2, "copper_wire": 20},
		"fuel_type": FuelType.GASOLINE,
		"fuel_capacity": 500.0,
		"fuel_burn_rate": 0.3,
		"crafting_speed": 0,
		"input_slots": 0,
		"output_slots": 0,
		"fuel_slots": 4,
		"recipes": [],
		"provides_light": false,
		"provides_warmth": false,
		"provides_power": true,
		"power_output": 100.0,
		"power_radius": 300.0,
		"size": Vector2i(2, 2),
		"sprite": "generator",
	},
	WorkstationType.RECYCLER: {
		"display_name": "Recycler",
		"description": "Break down items into base materials",
		"unlock_level": 8,
		"build_cost": {"steel_plate": 15, "electronics": 5, "gears": 10},
		"fuel_type": FuelType.ELECTRICITY,
		"fuel_capacity": 200.0,
		"fuel_burn_rate": 3.0,
		"crafting_speed": 1.5,
		"input_slots": 8,
		"output_slots": 8,
		"fuel_slots": 0,
		"recipes": ["recycle"],  # Special handling
		"provides_light": false,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "recycler",
	},
	WorkstationType.REPAIR_STATION: {
		"display_name": "Repair Station",
		"description": "Repair and maintain equipment",
		"unlock_level": 5,
		"build_cost": {"wood": 10, "steel_plate": 5, "nails": 15},
		"fuel_type": FuelType.NONE,
		"fuel_capacity": 0,
		"fuel_burn_rate": 0,
		"crafting_speed": 1.0,
		"input_slots": 4,
		"output_slots": 4,
		"fuel_slots": 0,
		"recipes": ["repair"],  # Special handling
		"provides_light": false,
		"provides_warmth": false,
		"size": Vector2i(2, 1),
		"sprite": "repair_station",
	},
}

# ============================================================================
# WORKSTATION RECIPES
# ============================================================================

const WORKSTATION_RECIPES := {
	"plank": {
		"display_name": "Planks",
		"inputs": {"wood": 4},
		"outputs": {"planks": 1},
		"craft_time": 20.0,
		"fuel_cost": 0.0,
		"xp_reward": 4,
	},
	"rope": {
		"display_name": "Rope",
		"inputs": {"fibers": 3},
		"outputs": {"rope": 1},
		"craft_time": 25.0,
		"fuel_cost": 0.0,
		"xp_reward": 4,
	},
	# Campfire recipes
	"cook_meat": {
		"display_name": "Cooked Meat",
		"inputs": {"raw_meat": 1},
		"outputs": {"cooked_meat": 1},
		"craft_time": 30.0,
		"fuel_cost": 5.0,
		"xp_reward": 5,
	},
	"cook_fish": {
		"display_name": "Cooked Fish",
		"inputs": {"raw_fish": 1},
		"outputs": {"cooked_fish": 1},
		"craft_time": 25.0,
		"fuel_cost": 4.0,
		"xp_reward": 5,
	},
	"boil_water": {
		"display_name": "Purified Water",
		"inputs": {"dirty_water": 1, "empty_bottle": 1},
		"outputs": {"water_bottle": 1},
		"craft_time": 20.0,
		"fuel_cost": 3.0,
		"xp_reward": 3,
	},
	"cook_stew": {
		"display_name": "Hearty Stew",
		"inputs": {"raw_meat": 2, "carrot": 1, "potato": 1, "water_bottle": 1},
		"outputs": {"stew": 1},
		"craft_time": 60.0,
		"fuel_cost": 10.0,
		"xp_reward": 15,
	},
	"dry_meat": {
		"display_name": "Dried Meat",
		"inputs": {"raw_meat": 2},
		"outputs": {"dried_meat": 1},
		"craft_time": 120.0,
		"fuel_cost": 15.0,
		"xp_reward": 10,
	},
	
	# Furnace recipes
	"smelt_iron": {
		"display_name": "Iron Bar",
		"inputs": {"iron_ore": 2},
		"outputs": {"iron_bar": 1},
		"craft_time": 45.0,
		"fuel_cost": 10.0,
		"xp_reward": 10,
	},
	"smelt_copper": {
		"display_name": "Copper Bar",
		"inputs": {"copper_ore": 2},
		"outputs": {"copper_bar": 1},
		"craft_time": 40.0,
		"fuel_cost": 8.0,
		"xp_reward": 10,
	},
	"smelt_aluminum": {
		"display_name": "Aluminum Bar",
		"inputs": {"aluminum_ore": 3},
		"outputs": {"aluminum_bar": 1},
		"craft_time": 60.0,
		"fuel_cost": 15.0,
		"xp_reward": 15,
	},
	"smelt_titanium": {
		"display_name": "Titanium Bar",
		"inputs": {"titanium_ore": 4},
		"outputs": {"titanium_bar": 1},
		"craft_time": 90.0,
		"fuel_cost": 25.0,
		"xp_reward": 25,
	},
	"make_steel": {
		"display_name": "Steel Plate",
		"inputs": {"iron_bar": 2, "coal": 1},
		"outputs": {"steel_plate": 1},
		"craft_time": 60.0,
		"fuel_cost": 15.0,
		"xp_reward": 20,
	},
	"make_glass": {
		"display_name": "Glass",
		"inputs": {"sand": 3},
		"outputs": {"glass": 1},
		"craft_time": 40.0,
		"fuel_cost": 12.0,
		"xp_reward": 8,
	},
	"make_brick": {
		"display_name": "Brick",
		"inputs": {"clay": 2},
		"outputs": {"brick": 1},
		"craft_time": 35.0,
		"fuel_cost": 8.0,
		"xp_reward": 6,
	},
	
	# Chemistry recipes
	"gunpowder": {
		"display_name": "Gunpowder",
		"inputs": {"charcoal": 2, "sulfur": 1, "saltpeter": 1},
		"outputs": {"gunpowder": 2},
		"craft_time": 30.0,
		"fuel_cost": 10.0,
		"xp_reward": 15,
	},
	"antibiotics": {
		"display_name": "Antibiotics",
		"inputs": {"herb": 3, "alcohol": 1, "empty_bottle": 1},
		"outputs": {"antibiotics": 1},
		"craft_time": 60.0,
		"fuel_cost": 20.0,
		"xp_reward": 25,
	},
	"antidote": {
		"display_name": "Antidote",
		"inputs": {"herb": 2, "venom_gland": 1, "water_bottle": 1},
		"outputs": {"antidote": 1},
		"craft_time": 45.0,
		"fuel_cost": 15.0,
		"xp_reward": 20,
	},
	"explosive": {
		"display_name": "C4 Explosive",
		"inputs": {"gunpowder": 5, "electronics": 1, "duct_tape": 2},
		"outputs": {"c4_explosive": 1},
		"craft_time": 90.0,
		"fuel_cost": 30.0,
		"xp_reward": 50,
	},
	
	# Garden recipes
	"grow_carrot": {
		"display_name": "Grow Carrots",
		"inputs": {"carrot_seed": 1},
		"outputs": {"carrot": 3, "carrot_seed": 1},
		"craft_time": 1800.0,  # 30 minutes
		"fuel_cost": 0,
		"xp_reward": 10,
		"needs_water": true,
	},
	"grow_corn": {
		"display_name": "Grow Corn",
		"inputs": {"corn_seed": 1},
		"outputs": {"corn": 2, "corn_seed": 1},
		"craft_time": 2400.0,  # 40 minutes
		"fuel_cost": 0,
		"xp_reward": 12,
		"needs_water": true,
	},
	
	# Water collector
	"collect_water": {
		"display_name": "Collect Water",
		"inputs": {},
		"outputs": {"dirty_water": 1},
		"craft_time": 600.0,  # 10 minutes
		"fuel_cost": 0,
		"xp_reward": 2,
		"weather_bonus": {"rain": 3.0, "thunderstorm": 4.0},
	},
}


# ============================================================================
# STATE
# ============================================================================

var _workstations: Dictionary = {}  # station_id -> workstation data
var _crafting_queue: Dictionary = {}  # station_id -> Array of queued recipes
var _power_grid: Dictionary = {}  # generator_id -> connected stations
var auto_update_enabled := true


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if not auto_update_enabled:
		return
	_update_workstations(delta)
	_update_power_grid(delta)


# ============================================================================
# WORKSTATION MANAGEMENT
# ============================================================================

func place_workstation(station_type: int, position: Vector2, player_level: int = 1) -> Dictionary:
	## Place a new workstation at the given position
	var definition: Dictionary = WORKSTATION_DEFINITIONS.get(station_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown workstation type"}
	
	# Check level requirement
	var required_level: int = definition.get("unlock_level", 1)
	if player_level < required_level:
		return {"success": false, "error": "Requires level %d" % required_level}
	
	var station_id := "%d_%d_%d" % [station_type, int(position.x), int(position.y)]
	
	var workstation := {
		"id": station_id,
		"type": station_type,
		"type_name": WorkstationType.keys()[station_type],
		"display_name": definition.get("display_name", "Workstation"),
		"position": position,
		"fuel": 0.0,
		"fuel_capacity": definition.get("fuel_capacity", 0),
		"fuel_type": definition.get("fuel_type", FuelType.NONE),
		"fuel_burn_rate": definition.get("fuel_burn_rate", 0),
		"crafting_speed": definition.get("crafting_speed", 1.0),
		"input_slots": [],
		"output_slots": [],
		"fuel_slots": [],
		"max_input": definition.get("input_slots", 4),
		"max_output": definition.get("output_slots", 4),
		"max_fuel": definition.get("fuel_slots", 0),
		"recipes": definition.get("recipes", []),
		"is_active": false,
		"current_recipe": null,
		"craft_progress": 0.0,
		"provides_light": definition.get("provides_light", false),
		"provides_warmth": definition.get("provides_warmth", false),
		"warmth_radius": definition.get("warmth_radius", 0),
		"provides_power": definition.get("provides_power", false),
		"power_output": definition.get("power_output", 0),
		"power_radius": definition.get("power_radius", 0),
		"passive": definition.get("passive", false),
		"needs_water": definition.get("needs_water", false),
		"water_level": 0.0 if definition.get("needs_water", false) else -1,
		"size": definition.get("size", Vector2i(1, 1)),
		"level": 1,
		"placed_time": Time.get_unix_time_from_system(),
	}
	
	# Initialize slot arrays
	for i in range(workstation["max_input"]):
		workstation["input_slots"].append(null)
	for i in range(workstation["max_output"]):
		workstation["output_slots"].append(null)
	for i in range(workstation["max_fuel"]):
		workstation["fuel_slots"].append(null)
	
	_workstations[station_id] = workstation
	_crafting_queue[station_id] = []
	
	emit_signal("workstation_placed", station_id, station_type)
	
	return {"success": true, "station_id": station_id, "workstation": workstation}


func remove_workstation(station_id: String) -> Dictionary:
	## Remove a workstation and return remaining items
	if station_id not in _workstations:
		return {"success": false, "error": "Workstation not found"}
	
	var workstation: Dictionary = _workstations[station_id]
	var remaining_items: Array = []
	
	# Collect items from all slots
	for item in workstation["input_slots"]:
		if item != null:
			remaining_items.append(item)
	
	for item in workstation["output_slots"]:
		if item != null:
			remaining_items.append(item)
	
	for item in workstation["fuel_slots"]:
		if item != null:
			remaining_items.append(item)
	
	_workstations.erase(station_id)
	_crafting_queue.erase(station_id)
	
	emit_signal("workstation_removed", station_id)
	
	return {"success": true, "items": remaining_items}


func get_workstation(station_id: String) -> Dictionary:
	return _workstations.get(station_id, {})


func get_all_workstations() -> Array:
	return _workstations.values()


func get_workstations_by_type(station_type: int) -> Array:
	var matching: Array = []
	for ws in _workstations.values():
		if ws["type"] == station_type:
			matching.append(ws)
	return matching


# ============================================================================
# SLOT MANAGEMENT
# ============================================================================

func add_item_to_input(station_id: String, item: Dictionary, slot_index: int = -1) -> bool:
	if station_id not in _workstations:
		return false
	
	var workstation: Dictionary = _workstations[station_id]
	
	if slot_index >= 0:
		if slot_index < workstation["input_slots"].size() and workstation["input_slots"][slot_index] == null:
			workstation["input_slots"][slot_index] = item
			return true
	else:
		# Find first empty slot
		for i in range(workstation["input_slots"].size()):
			if workstation["input_slots"][i] == null:
				workstation["input_slots"][i] = item
				return true
	
	return false


func remove_item_from_input(station_id: String, slot_index: int) -> Dictionary:
	if station_id not in _workstations:
		return {}
	
	var workstation: Dictionary = _workstations[station_id]
	
	if slot_index < workstation["input_slots"].size():
		var item = workstation["input_slots"][slot_index]
		workstation["input_slots"][slot_index] = null
		return item if item else {}
	
	return {}


func add_fuel(station_id: String, fuel_item: Dictionary) -> bool:
	if station_id not in _workstations:
		return false
	
	var workstation: Dictionary = _workstations[station_id]
	
	# Check fuel type compatibility
	var fuel_type: int = workstation.get("fuel_type", FuelType.NONE)
	if fuel_type == FuelType.NONE:
		return false
	
	# Calculate fuel value
	var fuel_value := _get_fuel_value(fuel_item, fuel_type)
	if fuel_value <= 0:
		return false
	
	# Add fuel
	var new_fuel := workstation["fuel"] + fuel_value
	workstation["fuel"] = minf(new_fuel, workstation["fuel_capacity"])
	
	return true


func _get_fuel_value(item: Dictionary, fuel_type: int) -> float:
	var item_id: String = item.get("id", "")
	var count: int = item.get("count", 1)
	
	match fuel_type:
		FuelType.WOOD:
			if item_id == "wood":
				return 10.0 * count
			elif item_id == "plant_fiber":
				return 2.0 * count
		FuelType.COAL:
			if item_id == "coal":
				return 30.0 * count
			elif item_id == "charcoal":
				return 20.0 * count
		FuelType.GASOLINE:
			if item_id == "gasoline":
				return 50.0 * count
	
	return 0.0


func collect_output(station_id: String, slot_index: int = -1) -> Array[Dictionary]:
	if station_id not in _workstations:
		return []
	
	var workstation: Dictionary = _workstations[station_id]
	var collected: Array[Dictionary] = []
	
	if slot_index >= 0:
		if slot_index < workstation["output_slots"].size() and workstation["output_slots"][slot_index] != null:
			collected.append(workstation["output_slots"][slot_index])
			workstation["output_slots"][slot_index] = null
	else:
		# Collect all outputs
		for i in range(workstation["output_slots"].size()):
			if workstation["output_slots"][i] != null:
				collected.append(workstation["output_slots"][i])
				workstation["output_slots"][i] = null
	
	return collected


# ============================================================================
# CRAFTING
# ============================================================================

func start_crafting(station_id: String, recipe_id: String, inventory_provider: Node = null) -> Dictionary:
	if station_id not in _workstations:
		return {"success": false, "error": "Workstation not found"}
	
	var workstation: Dictionary = _workstations[station_id]
	
	# Check if recipe is available for this workstation
	if recipe_id not in workstation["recipes"] and recipe_id != "recycle" and recipe_id != "repair":
		return {"success": false, "error": "Recipe not available"}
	
	var recipe: Dictionary = WORKSTATION_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return {"success": false, "error": "Unknown recipe"}

	var inputs: Dictionary = recipe.get("inputs", {})
	var use_inventory_inputs := _can_use_inventory_inputs(inventory_provider)
	
	# Check if already crafting
	if workstation["current_recipe"] != null:
		if use_inventory_inputs:
			if not inventory_provider.has_items(inputs):
				return {"success": false, "error": "Missing ingredients"}
			if not inventory_provider.remove_items(inputs):
				return {"success": false, "error": "Missing ingredients"}
			_crafting_queue[station_id].append({
				"recipe_id": recipe_id,
				"reserved_inputs": true,
			})
		else:
			_crafting_queue[station_id].append(recipe_id)
		return {"success": true, "queued": true}
	
	if use_inventory_inputs:
		if not inventory_provider.has_items(inputs):
			return {"success": false, "error": "Missing ingredients"}
	else:
		if not _has_required_inputs(workstation, inputs):
			return {"success": false, "error": "Missing ingredients"}
	
	# Check fuel
	var fuel_cost: float = recipe.get("fuel_cost", 0)
	if fuel_cost > 0 and workstation["fuel"] < fuel_cost:
		return {"success": false, "error": "Not enough fuel"}
	
	# Check output space
	if not _has_output_space(workstation, recipe.get("outputs", {})):
		return {"success": false, "error": "Output slots full"}
	
	if use_inventory_inputs:
		if not inventory_provider.remove_items(inputs):
			return {"success": false, "error": "Missing ingredients"}
	else:
		_consume_inputs(workstation, inputs)

	return _begin_crafting(station_id, workstation, recipe_id)


func _can_use_inventory_inputs(inventory_provider: Node) -> bool:
	return inventory_provider != null \
		and inventory_provider.has_method("has_items") \
		and inventory_provider.has_method("remove_items")


func _begin_crafting(station_id: String, workstation: Dictionary, recipe_id: String) -> Dictionary:
	var recipe: Dictionary = WORKSTATION_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return {"success": false, "error": "Unknown recipe"}
	if not _has_output_space(workstation, recipe.get("outputs", {})):
		return {"success": false, "error": "Output slots full"}

	workstation["current_recipe"] = recipe_id
	workstation["craft_progress"] = 0.0
	workstation["is_active"] = true

	emit_signal("crafting_started", station_id, recipe_id)
	return {"success": true, "craft_time": recipe.get("craft_time", 10.0)}


func cancel_crafting(station_id: String) -> Dictionary:
	if station_id not in _workstations:
		return {"success": false}
	
	var workstation: Dictionary = _workstations[station_id]
	
	if workstation["current_recipe"] == null:
		return {"success": false, "error": "Not crafting"}
	
	var recipe_id: String = workstation["current_recipe"]
	var recipe: Dictionary = WORKSTATION_RECIPES.get(recipe_id, {})
	
	# Return partial inputs (based on progress)
	var progress: float = workstation["craft_progress"]
	var inputs: Dictionary = recipe.get("inputs", {})
	var returned_items: Array = []
	
	for item_id in inputs:
		var count: int = inputs[item_id]
		var return_count := int(count * (1.0 - progress))
		if return_count > 0:
			returned_items.append({"id": item_id, "count": return_count})
	
	workstation["current_recipe"] = null
	workstation["craft_progress"] = 0.0
	workstation["is_active"] = false
	
	return {"success": true, "returned_items": returned_items}


func get_queue(station_id: String) -> Array:
	return _crafting_queue.get(station_id, [])


func clear_queue(station_id: String) -> void:
	if station_id in _crafting_queue:
		_crafting_queue[station_id].clear()


func _has_required_inputs(workstation: Dictionary, inputs: Dictionary) -> bool:
	var available := {}
	
	for item in workstation["input_slots"]:
		if item != null:
			var id: String = item.get("id", "")
			available[id] = available.get(id, 0) + item.get("count", 1)
	
	for item_id in inputs:
		if available.get(item_id, 0) < inputs[item_id]:
			return false
	
	return true


func _consume_inputs(workstation: Dictionary, inputs: Dictionary) -> void:
	var to_consume := inputs.duplicate()
	
	for i in range(workstation["input_slots"].size()):
		var item = workstation["input_slots"][i]
		if item == null:
			continue
		
		var id: String = item.get("id", "")
		if id in to_consume and to_consume[id] > 0:
			var count: int = item.get("count", 1)
			var consume := mini(count, to_consume[id])
			to_consume[id] -= consume
			
			if consume >= count:
				workstation["input_slots"][i] = null
			else:
				item["count"] = count - consume


func _has_output_space(workstation: Dictionary, outputs: Dictionary) -> bool:
	var empty_slots := 0
	for item in workstation["output_slots"]:
		if item == null:
			empty_slots += 1
	
	return empty_slots >= outputs.size()


func _add_outputs(workstation: Dictionary, outputs: Dictionary) -> void:
	for item_id in outputs:
		var count: int = outputs[item_id]
		var item := {"id": item_id, "count": count}
		
		# Try to stack with existing
		var stacked := false
		for i in range(workstation["output_slots"].size()):
			var existing = workstation["output_slots"][i]
			if existing != null and existing.get("id", "") == item_id:
				existing["count"] = existing.get("count", 1) + count
				stacked = true
				break
		
		if not stacked:
			# Find empty slot
			for i in range(workstation["output_slots"].size()):
				if workstation["output_slots"][i] == null:
					workstation["output_slots"][i] = item
					break


func advance_time(delta: float) -> void:
	if delta <= 0.0:
		return

	for station_id in _workstations.keys():
		_advance_station(station_id, delta)

	_update_power_grid(delta)


func _advance_station(station_id: String, delta: float) -> void:
	var remaining := delta
	while remaining > 0.0:
		if station_id not in _workstations:
			return

		var workstation: Dictionary = _workstations[station_id]
		if workstation.get("passive", false):
			var passive_step := _time_to_next_passive_resolution(workstation, remaining)
			if passive_step <= 0.0:
				return
			_update_passive_station(station_id, workstation, passive_step)
			remaining -= passive_step
		elif workstation.get("is_active", false):
			var active_step := _time_to_next_active_resolution(workstation, remaining)
			if active_step <= 0.0:
				return
			_update_active_station(station_id, workstation, active_step)
			remaining -= active_step
		else:
			return


func _time_to_next_active_resolution(workstation: Dictionary, max_step: float) -> float:
	var recipe_id: String = workstation.get("current_recipe", "")
	if recipe_id.is_empty():
		return 0.0

	var recipe: Dictionary = WORKSTATION_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return 0.0

	var craft_speed := maxf(float(workstation.get("crafting_speed", 1.0)), 0.001)
	var craft_time := maxf(float(recipe.get("craft_time", 10.0)), 0.001)
	var remaining_progress := maxf(0.0, 1.0 - float(workstation.get("craft_progress", 0.0)))
	var time_to_complete := (remaining_progress * craft_time) / craft_speed
	if time_to_complete <= 0.0:
		time_to_complete = minf(max_step, 0.01)

	var fuel_limit := INF
	var fuel_type: int = workstation.get("fuel_type", FuelType.NONE)
	var fuel_rate := float(workstation.get("fuel_burn_rate", 0.0))
	if fuel_type != FuelType.NONE and fuel_rate > 0.0:
		var current_fuel := float(workstation.get("fuel", 0.0))
		if current_fuel <= 0.0:
			return 0.0
		fuel_limit = current_fuel / fuel_rate

	return minf(max_step, time_to_complete, fuel_limit)


func _time_to_next_passive_resolution(workstation: Dictionary, max_step: float) -> float:
	var recipes: Array = workstation.get("recipes", [])
	if recipes.is_empty():
		return 0.0

	var recipe_id := str(recipes[0])
	var recipe: Dictionary = WORKSTATION_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return 0.0
	if workstation.get("needs_water", false) and workstation.get("water_level", 0.0) <= 0.0:
		return 0.0
	if not _has_output_space(workstation, recipe.get("outputs", {})):
		return 0.0

	var craft_speed := maxf(float(workstation.get("crafting_speed", 1.0)), 0.001)
	var craft_time := maxf(float(recipe.get("craft_time", 600.0)), 0.001)
	var remaining_progress := maxf(0.0, 1.0 - float(workstation.get("craft_progress", 0.0)))
	var time_to_complete := (remaining_progress * craft_time) / craft_speed
	if time_to_complete <= 0.0:
		time_to_complete = minf(max_step, 0.01)

	return minf(max_step, time_to_complete)


# ============================================================================
# UPDATE LOOP
# ============================================================================

func _update_workstations(delta: float) -> void:
	for station_id in _workstations:
		var workstation: Dictionary = _workstations[station_id]
		
		if workstation["passive"]:
			_update_passive_station(station_id, workstation, delta)
		elif workstation["is_active"]:
			_update_active_station(station_id, workstation, delta)


func _update_active_station(station_id: String, workstation: Dictionary, delta: float) -> void:
	var recipe_id: String = workstation.get("current_recipe", "")
	if recipe_id.is_empty():
		workstation["is_active"] = false
		return
	
	var recipe: Dictionary = WORKSTATION_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		workstation["is_active"] = false
		return
	
	# Check and consume fuel
	var fuel_type: int = workstation.get("fuel_type", FuelType.NONE)
	if fuel_type != FuelType.NONE:
		var fuel_rate: float = workstation.get("fuel_burn_rate", 1.0)
		workstation["fuel"] -= fuel_rate * delta
		
		if workstation["fuel"] <= 0:
			workstation["fuel"] = 0
			workstation["is_active"] = false
			emit_signal("fuel_depleted", station_id)
			return
		
		emit_signal("fuel_consumed", station_id, workstation["fuel"])
	
	# Update progress
	var craft_time: float = recipe.get("craft_time", 10.0)
	var craft_speed: float = workstation.get("crafting_speed", 1.0)
	
	workstation["craft_progress"] += (delta / craft_time) * craft_speed
	
	emit_signal("crafting_progress", station_id, workstation["craft_progress"])
	
	# Check completion
	if workstation["craft_progress"] >= 1.0:
		_complete_crafting(station_id, workstation, recipe)


func _update_passive_station(station_id: String, workstation: Dictionary, delta: float) -> void:
	# Passive stations like water collectors and gardens
	var recipes: Array = workstation.get("recipes", [])
	if recipes.is_empty():
		return
	
	var recipe_id: String = recipes[0]
	var recipe: Dictionary = WORKSTATION_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return
	
	# Check water requirement
	if workstation.get("needs_water", false) and workstation.get("water_level", 0) <= 0:
		return
	
	# Check output space
	if not _has_output_space(workstation, recipe.get("outputs", {})):
		return
	
	# Update progress
	var craft_time: float = recipe.get("craft_time", 600.0)
	var craft_speed: float = workstation.get("crafting_speed", 1.0)
	
	# Apply weather bonus
	var weather_bonus: Dictionary = recipe.get("weather_bonus", {})
	# TODO: Integrate with WeatherSystem
	
	workstation["craft_progress"] += (delta / craft_time) * craft_speed
	
	if workstation["craft_progress"] >= 1.0:
		_complete_crafting(station_id, workstation, recipe)
		workstation["craft_progress"] = 0.0  # Restart passive crafting


func _complete_crafting(station_id: String, workstation: Dictionary, recipe: Dictionary) -> void:
	var outputs: Dictionary = recipe.get("outputs", {})
	
	_add_outputs(workstation, outputs)
	
	var recipe_id: String = workstation.get("current_recipe", "")
	
	workstation["current_recipe"] = null
	workstation["craft_progress"] = 0.0
	workstation["is_active"] = false
	
	emit_signal("crafting_completed", station_id, recipe_id, outputs)
	
	# Start next queued recipe
	var queue: Array = _crafting_queue.get(station_id, [])
	if queue.size() > 0:
		var next_entry = queue.pop_front()
		if next_entry is Dictionary:
			var queued_recipe := str(next_entry.get("recipe_id", ""))
			if queued_recipe.is_empty():
				return
			var start_result := _begin_crafting(station_id, workstation, queued_recipe)
			if not bool(start_result.get("success", false)):
				queue.push_front(next_entry)
		else:
			start_crafting(station_id, str(next_entry))


# ============================================================================
# POWER GRID
# ============================================================================

func _update_power_grid(_delta: float) -> void:
	# Find all generators
	var generators: Array = get_workstations_by_type(WorkstationType.GENERATOR)
	
	_power_grid.clear()
	
	for generator in generators:
		if generator["fuel"] <= 0:
			continue
		
		var gen_id: String = generator["id"]
		var gen_pos: Vector2 = generator["position"]
		var power_radius: float = generator.get("power_radius", 300.0)
		
		_power_grid[gen_id] = []
		
		# Find stations in range that need power
		for ws in _workstations.values():
			if ws["id"] == gen_id:
				continue
			
			var ws_fuel_type: int = ws.get("fuel_type", FuelType.NONE)
			if ws_fuel_type != FuelType.ELECTRICITY:
				continue
			
			var ws_pos: Vector2 = ws["position"]
			if gen_pos.distance_to(ws_pos) <= power_radius:
				_power_grid[gen_id].append(ws["id"])
				
				# Supply power to station
				var power_output: float = generator.get("power_output", 100.0)
				var connected_count: int = _power_grid[gen_id].size()
				var power_per_station := power_output / connected_count
				
				ws["fuel"] = minf(ws["fuel"] + power_per_station * 0.1, ws["fuel_capacity"])


func get_powered_stations() -> Array:
	var powered: Array = []
	for gen_id in _power_grid:
		powered.append_array(_power_grid[gen_id])
	return powered


func is_station_powered(station_id: String) -> bool:
	for gen_id in _power_grid:
		if station_id in _power_grid[gen_id]:
			return true
	return false


# ============================================================================
# QUERIES
# ============================================================================

func get_available_recipes(station_id: String, inventory_provider: Node = null) -> Array[Dictionary]:
	if station_id not in _workstations:
		return []
	
	var workstation: Dictionary = _workstations[station_id]
	var recipes: Array[Dictionary] = []
	var use_inventory_inputs := _can_use_inventory_inputs(inventory_provider)
	
	for recipe_id in workstation["recipes"]:
		var recipe: Dictionary = WORKSTATION_RECIPES.get(recipe_id, {})
		if not recipe.is_empty():
			var recipe_data := recipe.duplicate()
			recipe_data["id"] = recipe_id
			recipe_data["can_craft"] = inventory_provider.has_items(recipe.get("inputs", {})) if use_inventory_inputs else _has_required_inputs(workstation, recipe.get("inputs", {}))
			recipes.append(recipe_data)
	
	return recipes


func get_crafting_progress(station_id: String) -> float:
	if station_id not in _workstations:
		return 0.0
	return _workstations[station_id].get("craft_progress", 0.0)


func get_warmth_sources() -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	
	for ws in _workstations.values():
		if ws.get("provides_warmth", false) and ws.get("is_active", false):
			sources.append({
				"position": ws["position"],
				"radius": ws.get("warmth_radius", 100.0),
			})
	
	return sources


func get_light_sources() -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	
	for ws in _workstations.values():
		if ws.get("provides_light", false) and (ws.get("is_active", false) or ws.get("fuel", 0) > 0):
			sources.append({
				"position": ws["position"],
				"active": ws.get("is_active", false),
			})
	
	return sources


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var serialized_workstations := {}
	for station_id in _workstations.keys():
		var workstation: Dictionary = _workstations[station_id].duplicate(true)
		var position = workstation.get("position", Vector2.ZERO)
		if position is Vector2:
			workstation["position"] = {"x": position.x, "y": position.y}
		var size = workstation.get("size", Vector2i.ONE)
		if size is Vector2i:
			workstation["size"] = {"x": size.x, "y": size.y}
		serialized_workstations[station_id] = workstation

	return {
		"workstations": serialized_workstations,
		"crafting_queue": _crafting_queue.duplicate(true),
	}


func load_data(data: Dictionary) -> void:
	_workstations = data.get("workstations", {}).duplicate(true)
	for station_id in _workstations.keys():
		var workstation: Dictionary = _workstations[station_id]
		if workstation.has("position") and workstation["position"] is Dictionary:
			var pos: Dictionary = workstation["position"]
			workstation["position"] = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
		if workstation.has("size") and workstation["size"] is Dictionary:
			var size: Dictionary = workstation["size"]
			workstation["size"] = Vector2i(int(size.get("x", 1)), int(size.get("y", 1)))
		_workstations[station_id] = workstation
	_crafting_queue = data.get("crafting_queue", {}).duplicate(true)
