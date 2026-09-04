extends Node
class_name StorageSystemClass
## Comprehensive storage management with sorting, filtering, stacking, and organization
## Handles containers, inventory management, and item transfer

signal storage_created(container_id: String)
signal storage_destroyed(container_id: String)
signal item_stored(container_id: String, item: Dictionary)
signal item_removed(container_id: String, item: Dictionary)
signal storage_full(container_id: String)
signal storage_sorted(container_id: String)
signal quick_stack_completed(count: int)
signal auto_deposit_completed(count: int)

# ============================================================================
# CONTAINER TYPES
# ============================================================================

enum ContainerType {
	# Basic Storage
	SMALL_CHEST,
	MEDIUM_CHEST,
	LARGE_CHEST,
	TRUNK,
	
	# Specialized Storage
	WEAPON_RACK,
	ARMOR_STAND,
	MEDICINE_CABINET,
	FOOD_STORAGE,
	AMMO_CRATE,
	FUEL_TANK,
	
	# Advanced Storage
	SAFE,
	VAULT,
	REFRIGERATOR,
	FREEZER,
	
	# Utility
	MAILBOX,
	DEAD_DROP,
	VEHICLE_STORAGE,
}

enum SortMode {
	NONE,
	NAME_ASC,
	NAME_DESC,
	TYPE,
	RARITY,
	QUANTITY,
	WEIGHT,
	RECENT,
	CUSTOM,
}

enum FilterMode {
	ALL,
	WEAPONS,
	ARMOR,
	TOOLS,
	CONSUMABLES,
	MATERIALS,
	AMMO,
	BLUEPRINTS,
	QUEST_ITEMS,
	JUNK,
	FAVORITES,
}

const CONTAINER_DEFINITIONS := {
	ContainerType.SMALL_CHEST: {
		"display_name": "Small Chest",
		"slots": 12,
		"max_weight": 100.0,
		"build_cost": {"wood": 10, "nails": 5},
		"durability": 100,
		"lockable": false,
		"filter_types": [],  # Accepts all
		"decay_rate": 0.0,
		"description": "Basic wooden storage chest.",
	},
	ContainerType.MEDIUM_CHEST: {
		"display_name": "Medium Chest",
		"slots": 24,
		"max_weight": 250.0,
		"build_cost": {"wood": 25, "nails": 12, "iron_bar": 2},
		"durability": 150,
		"lockable": true,
		"filter_types": [],
		"decay_rate": 0.0,
		"description": "Reinforced storage chest.",
	},
	ContainerType.LARGE_CHEST: {
		"display_name": "Large Chest",
		"slots": 48,
		"max_weight": 500.0,
		"build_cost": {"wood": 40, "nails": 20, "steel_plate": 5},
		"durability": 250,
		"lockable": true,
		"filter_types": [],
		"decay_rate": 0.0,
		"description": "Large reinforced storage chest.",
	},
	ContainerType.TRUNK: {
		"display_name": "Trunk",
		"slots": 36,
		"max_weight": 400.0,
		"build_cost": {"wood": 30, "leather": 10, "nails": 15},
		"durability": 200,
		"lockable": true,
		"filter_types": [],
		"decay_rate": 0.0,
		"description": "Leather-bound travel trunk.",
	},
	ContainerType.WEAPON_RACK: {
		"display_name": "Weapon Rack",
		"slots": 8,
		"max_weight": 150.0,
		"build_cost": {"wood": 20, "nails": 10, "iron_bar": 3},
		"durability": 175,
		"lockable": false,
		"filter_types": ["weapon", "melee", "ranged"],
		"decay_rate": 0.0,
		"display_type": "rack",
		"description": "Displays and stores weapons.",
	},
	ContainerType.ARMOR_STAND: {
		"display_name": "Armor Stand",
		"slots": 6,
		"max_weight": 200.0,
		"build_cost": {"wood": 15, "nails": 8, "cloth": 5},
		"durability": 150,
		"lockable": false,
		"filter_types": ["armor", "helmet", "vest", "boots", "gloves"],
		"decay_rate": 0.0,
		"display_type": "mannequin",
		"description": "Displays armor sets.",
	},
	ContainerType.MEDICINE_CABINET: {
		"display_name": "Medicine Cabinet",
		"slots": 16,
		"max_weight": 50.0,
		"build_cost": {"wood": 10, "glass": 3, "nails": 6},
		"durability": 80,
		"lockable": true,
		"filter_types": ["medical", "medicine", "bandage", "antidote"],
		"decay_rate": 0.0,
		"description": "Stores medical supplies.",
	},
	ContainerType.FOOD_STORAGE: {
		"display_name": "Food Storage",
		"slots": 20,
		"max_weight": 150.0,
		"build_cost": {"wood": 15, "nails": 8, "cloth": 3},
		"durability": 100,
		"lockable": false,
		"filter_types": ["food", "drink", "consumable"],
		"decay_rate": 0.5,  # Items decay slower here
		"description": "Stores food with reduced spoilage.",
	},
	ContainerType.AMMO_CRATE: {
		"display_name": "Ammo Crate",
		"slots": 12,
		"max_weight": 200.0,
		"build_cost": {"wood": 15, "steel_plate": 3},
		"durability": 200,
		"lockable": true,
		"filter_types": ["ammo", "ammunition", "bullet", "shell", "arrow"],
		"decay_rate": 0.0,
		"description": "Reinforced ammunition storage.",
	},
	ContainerType.FUEL_TANK: {
		"display_name": "Fuel Tank",
		"slots": 4,
		"max_weight": 500.0,
		"build_cost": {"steel_plate": 20, "pipe": 5, "rubber": 3},
		"durability": 300,
		"lockable": false,
		"filter_types": ["fuel", "gasoline", "diesel", "oil"],
		"flammable": true,
		"decay_rate": 0.0,
		"description": "Stores fuel safely.",
	},
	ContainerType.SAFE: {
		"display_name": "Safe",
		"slots": 16,
		"max_weight": 100.0,
		"build_cost": {"steel_plate": 30, "gears": 5, "electronics": 3},
		"durability": 500,
		"lockable": true,
		"lock_strength": 3,  # Requires level 3 lockpicking
		"filter_types": [],
		"decay_rate": 0.0,
		"description": "High-security storage.",
	},
	ContainerType.VAULT: {
		"display_name": "Vault",
		"slots": 64,
		"max_weight": 1000.0,
		"build_cost": {"steel_plate": 80, "concrete": 50, "electronics": 20},
		"durability": 2000,
		"lockable": true,
		"lock_strength": 5,
		"filter_types": [],
		"decay_rate": 0.0,
		"indestructible": true,
		"description": "Maximum security vault.",
	},
	ContainerType.REFRIGERATOR: {
		"display_name": "Refrigerator",
		"slots": 24,
		"max_weight": 200.0,
		"build_cost": {"steel_plate": 15, "electronics": 8, "copper_wire": 10},
		"durability": 150,
		"lockable": false,
		"filter_types": ["food", "drink", "organic"],
		"decay_rate": 0.1,  # 10% normal decay
		"requires_power": true,
		"power_consumption": 5,
		"description": "Keeps food fresh longer.",
	},
	ContainerType.FREEZER: {
		"display_name": "Freezer",
		"slots": 20,
		"max_weight": 250.0,
		"build_cost": {"steel_plate": 20, "electronics": 12, "copper_wire": 15},
		"durability": 175,
		"lockable": false,
		"filter_types": ["food", "organic", "meat"],
		"decay_rate": 0.0,  # No decay when powered
		"requires_power": true,
		"power_consumption": 10,
		"description": "Prevents food spoilage completely.",
	},
	ContainerType.MAILBOX: {
		"display_name": "Mailbox",
		"slots": 6,
		"max_weight": 20.0,
		"build_cost": {"wood": 5, "nails": 3},
		"durability": 50,
		"lockable": true,
		"filter_types": [],
		"public_deposit": true,  # Others can add items
		"decay_rate": 0.0,
		"description": "Receives deliveries and messages.",
	},
	ContainerType.DEAD_DROP: {
		"display_name": "Dead Drop",
		"slots": 4,
		"max_weight": 30.0,
		"build_cost": {"wood": 3, "cloth": 2},
		"durability": 30,
		"lockable": false,
		"hidden": true,
		"filter_types": [],
		"decay_rate": 0.0,
		"description": "Hidden cache for secret exchanges.",
	},
	ContainerType.VEHICLE_STORAGE: {
		"display_name": "Vehicle Storage",
		"slots": 30,
		"max_weight": 400.0,
		"build_cost": {},  # Part of vehicle
		"durability": 0,  # Tied to vehicle
		"lockable": true,
		"filter_types": [],
		"decay_rate": 0.0,
		"mobile": true,
		"description": "Storage compartment in vehicle.",
	},
}


# ============================================================================
# ITEM CATEGORIES FOR FILTERING
# ============================================================================

const ITEM_CATEGORIES := {
	FilterMode.WEAPONS: ["weapon", "melee", "ranged", "gun", "sword", "axe", "bow"],
	FilterMode.ARMOR: ["armor", "helmet", "vest", "boots", "gloves", "pants", "jacket"],
	FilterMode.TOOLS: ["tool", "pickaxe", "hatchet", "hammer", "wrench", "crowbar"],
	FilterMode.CONSUMABLES: ["consumable", "food", "drink", "medicine", "bandage"],
	FilterMode.MATERIALS: ["material", "wood", "stone", "metal", "cloth", "leather"],
	FilterMode.AMMO: ["ammo", "ammunition", "bullet", "shell", "arrow", "bolt"],
	FilterMode.BLUEPRINTS: ["blueprint", "recipe", "schematic"],
	FilterMode.QUEST_ITEMS: ["quest", "key", "special"],
	FilterMode.JUNK: ["junk", "scrap", "trash"],
}


# ============================================================================
# STATE
# ============================================================================

var _containers: Dictionary = {}  # container_id -> container data
var _global_search_cache: Array = []  # Cached search results
var _favorite_items: Array = []  # Item IDs marked as favorite
var _custom_categories: Dictionary = {}  # Custom sorting categories

# Quick access settings
var auto_stack_enabled: bool = true
var auto_deposit_enabled: bool = false
var auto_deposit_rules: Array = []  # {filter: FilterMode, container_id: String}


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_update_decay(delta)
	_update_powered_containers(delta)


# ============================================================================
# CONTAINER MANAGEMENT
# ============================================================================

func create_container(container_type: int, position: Vector2 = Vector2.ZERO, custom_data: Dictionary = {}) -> String:
	var definition: Dictionary = CONTAINER_DEFINITIONS.get(container_type, {})
	if definition.is_empty():
		return ""
	
	var container_id := "container_%d_%d" % [
		Time.get_ticks_msec(),
		randi() % 10000
	]
	
	var container := {
		"id": container_id,
		"type": container_type,
		"type_name": ContainerType.keys()[container_type],
		"display_name": custom_data.get("name", definition.get("display_name", "Container")),
		"position": position,
		"slots": definition.get("slots", 12),
		"max_weight": definition.get("max_weight", 100.0),
		"current_weight": 0.0,
		"items": [],  # Array of item dictionaries
		"durability": definition.get("durability", 100),
		"max_durability": definition.get("durability", 100),
		"locked": false,
		"lock_code": "",
		"filter_types": definition.get("filter_types", []),
		"decay_rate": definition.get("decay_rate", 1.0),
		"requires_power": definition.get("requires_power", false),
		"powered": not definition.get("requires_power", false),
		"sort_mode": SortMode.NONE,
		"custom_label": custom_data.get("label", ""),
		"created_at": Time.get_unix_time_from_system(),
		"owner_id": custom_data.get("owner_id", ""),
	}
	
	_containers[container_id] = container
	emit_signal("storage_created", container_id)
	
	return container_id


func destroy_container(container_id: String) -> Dictionary:
	if container_id not in _containers:
		return {"success": false, "error": "Container not found"}
	
	var container: Dictionary = _containers[container_id]
	var dropped_items: Array = container.get("items", []).duplicate()
	
	_containers.erase(container_id)
	emit_signal("storage_destroyed", container_id)
	
	return {"success": true, "dropped_items": dropped_items}


func get_container(container_id: String) -> Dictionary:
	return _containers.get(container_id, {})


func get_all_containers() -> Array:
	return _containers.values()


func get_containers_at_position(position: Vector2, radius: float = 64.0) -> Array:
	var nearby: Array = []
	for container in _containers.values():
		if container.get("position", Vector2.ZERO).distance_to(position) <= radius:
			nearby.append(container)
	return nearby


# ============================================================================
# ITEM STORAGE
# ============================================================================

func store_item(container_id: String, item: Dictionary) -> Dictionary:
	if container_id not in _containers:
		return {"success": false, "error": "Container not found"}
	
	var container: Dictionary = _containers[container_id]
	
	# Check filter
	if not _item_matches_filter(item, container.get("filter_types", [])):
		return {"success": false, "error": "Item type not allowed"}
	
	# Check weight
	var item_weight: float = item.get("weight", 1.0) * item.get("quantity", 1)
	if container["current_weight"] + item_weight > container["max_weight"]:
		return {"success": false, "error": "Not enough weight capacity"}
	
	# Try to stack with existing items
	if auto_stack_enabled and item.get("stackable", true):
		for existing in container["items"]:
			if _can_stack(existing, item):
				var stack_amount := mini(
					item.get("quantity", 1),
					existing.get("max_stack", 99) - existing.get("quantity", 1)
				)
				if stack_amount > 0:
					existing["quantity"] = existing.get("quantity", 1) + stack_amount
					item["quantity"] = item.get("quantity", 1) - stack_amount
					container["current_weight"] += item.get("weight", 1.0) * stack_amount
					
					if item.get("quantity", 0) <= 0:
						emit_signal("item_stored", container_id, item)
						return {"success": true, "stacked": true}
	
	# Check slots
	if container["items"].size() >= container["slots"]:
		emit_signal("storage_full", container_id)
		return {"success": false, "error": "Container full"}
	
	# Add as new item
	container["items"].append(item.duplicate())
	container["current_weight"] += item_weight
	
	emit_signal("item_stored", container_id, item)
	return {"success": true, "stacked": false}


func remove_item(container_id: String, item_index: int, quantity: int = -1) -> Dictionary:
	if container_id not in _containers:
		return {"success": false, "error": "Container not found"}
	
	var container: Dictionary = _containers[container_id]
	
	if item_index < 0 or item_index >= container["items"].size():
		return {"success": false, "error": "Invalid item index"}
	
	var item: Dictionary = container["items"][item_index]
	var remove_qty: int = quantity if quantity > 0 else item.get("quantity", 1)
	remove_qty = mini(remove_qty, item.get("quantity", 1))
	
	var removed_item: Dictionary = item.duplicate()
	removed_item["quantity"] = remove_qty
	
	item["quantity"] = item.get("quantity", 1) - remove_qty
	container["current_weight"] -= item.get("weight", 1.0) * remove_qty
	
	if item.get("quantity", 0) <= 0:
		container["items"].remove_at(item_index)
	
	emit_signal("item_removed", container_id, removed_item)
	return {"success": true, "item": removed_item}


func remove_item_by_id(container_id: String, item_id: String, quantity: int = -1) -> Dictionary:
	if container_id not in _containers:
		return {"success": false, "error": "Container not found"}
	
	var container: Dictionary = _containers[container_id]
	
	for i in range(container["items"].size()):
		if container["items"][i].get("id", "") == item_id:
			return remove_item(container_id, i, quantity)
	
	return {"success": false, "error": "Item not found"}


func move_item(from_container: String, to_container: String, item_index: int, quantity: int = -1) -> Dictionary:
	# Remove from source
	var remove_result := remove_item(from_container, item_index, quantity)
	if not remove_result.get("success", false):
		return remove_result
	
	# Add to destination
	var store_result := store_item(to_container, remove_result["item"])
	if not store_result.get("success", false):
		# Put back in source
		store_item(from_container, remove_result["item"])
		return store_result
	
	return {"success": true}


func swap_items(container_id: String, index_a: int, index_b: int) -> bool:
	if container_id not in _containers:
		return false
	
	var container: Dictionary = _containers[container_id]
	var items: Array = container["items"]
	
	if index_a < 0 or index_a >= items.size():
		return false
	if index_b < 0 or index_b >= items.size():
		return false
	
	var temp: Dictionary = items[index_a]
	items[index_a] = items[index_b]
	items[index_b] = temp
	
	return true


func _can_stack(item_a: Dictionary, item_b: Dictionary) -> bool:
	if item_a.get("id", "") != item_b.get("id", ""):
		return false
	if not item_a.get("stackable", true) or not item_b.get("stackable", true):
		return false
	if item_a.get("quantity", 1) >= item_a.get("max_stack", 99):
		return false
	return true


func _item_matches_filter(item: Dictionary, filter_types: Array) -> bool:
	if filter_types.is_empty():
		return true
	
	var item_type: String = item.get("type", "")
	var item_tags: Array = item.get("tags", [])
	
	for filter_type in filter_types:
		if item_type == filter_type:
			return true
		if filter_type in item_tags:
			return true
	
	return false


# ============================================================================
# SORTING
# ============================================================================

func sort_container(container_id: String, sort_mode: int = SortMode.NAME_ASC) -> void:
	if container_id not in _containers:
		return
	
	var container: Dictionary = _containers[container_id]
	var items: Array = container["items"]
	
	match sort_mode:
		SortMode.NAME_ASC:
			items.sort_custom(func(a, b): return a.get("display_name", "") < b.get("display_name", ""))
		SortMode.NAME_DESC:
			items.sort_custom(func(a, b): return a.get("display_name", "") > b.get("display_name", ""))
		SortMode.TYPE:
			items.sort_custom(func(a, b): return a.get("type", "") < b.get("type", ""))
		SortMode.RARITY:
			items.sort_custom(func(a, b): return a.get("rarity", 0) > b.get("rarity", 0))
		SortMode.QUANTITY:
			items.sort_custom(func(a, b): return a.get("quantity", 1) > b.get("quantity", 1))
		SortMode.WEIGHT:
			items.sort_custom(func(a, b): 
				return a.get("weight", 1.0) * a.get("quantity", 1) > b.get("weight", 1.0) * b.get("quantity", 1)
			)
		SortMode.RECENT:
			items.sort_custom(func(a, b): return a.get("obtained_at", 0) > b.get("obtained_at", 0))
	
	container["sort_mode"] = sort_mode
	emit_signal("storage_sorted", container_id)


func consolidate_stacks(container_id: String) -> int:
	## Merge partial stacks into full stacks
	if container_id not in _containers:
		return 0
	
	var container: Dictionary = _containers[container_id]
	var items: Array = container["items"]
	var merged_count := 0
	
	var i := 0
	while i < items.size():
		var item: Dictionary = items[i]
		if not item.get("stackable", true):
			i += 1
			continue
		
		var j := i + 1
		while j < items.size():
			if _can_stack(item, items[j]):
				var stack_space: int = item.get("max_stack", 99) - item.get("quantity", 1)
				var transfer: int = mini(stack_space, items[j].get("quantity", 1))
				
				item["quantity"] = item.get("quantity", 1) + transfer
				items[j]["quantity"] = items[j].get("quantity", 1) - transfer
				merged_count += 1
				
				if items[j].get("quantity", 0) <= 0:
					items.remove_at(j)
					continue
			j += 1
		i += 1
	
	return merged_count


# ============================================================================
# FILTERING & SEARCHING
# ============================================================================

func filter_container(container_id: String, filter_mode: int) -> Array:
	if container_id not in _containers:
		return []
	
	var container: Dictionary = _containers[container_id]
	var items: Array = container["items"]
	
	if filter_mode == FilterMode.ALL:
		return items.duplicate()
	
	if filter_mode == FilterMode.FAVORITES:
		return items.filter(func(item): return item.get("id", "") in _favorite_items)
	
	var filter_tags: Array = ITEM_CATEGORIES.get(filter_mode, [])
	
	return items.filter(func(item): 
		var item_type: String = item.get("type", "")
		var item_tags: Array = item.get("tags", [])
		for tag in filter_tags:
			if tag in item_type or tag in item_tags:
				return true
		return false
	)


func search_container(container_id: String, query: String) -> Array:
	if container_id not in _containers:
		return []
	
	var container: Dictionary = _containers[container_id]
	var items: Array = container["items"]
	var query_lower := query.to_lower()
	
	return items.filter(func(item):
		var name: String = item.get("display_name", "").to_lower()
		var desc: String = item.get("description", "").to_lower()
		return name.contains(query_lower) or desc.contains(query_lower)
	)


func search_all_containers(query: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var query_lower := query.to_lower()
	
	for container in _containers.values():
		for i in range(container["items"].size()):
			var item: Dictionary = container["items"][i]
			var name: String = item.get("display_name", "").to_lower()
			var desc: String = item.get("description", "").to_lower()
			
			if name.contains(query_lower) or desc.contains(query_lower):
				results.append({
					"container_id": container["id"],
					"container_name": container.get("display_name", ""),
					"item_index": i,
					"item": item.duplicate(),
				})
	
	_global_search_cache = results.duplicate()
	return results


func find_item_in_containers(item_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for container in _containers.values():
		for i in range(container["items"].size()):
			if container["items"][i].get("id", "") == item_id:
				results.append({
					"container_id": container["id"],
					"container_name": container.get("display_name", ""),
					"item_index": i,
					"quantity": container["items"][i].get("quantity", 1),
				})
	
	return results


# ============================================================================
# QUICK ACTIONS
# ============================================================================

func quick_stack(player_inventory: Array, nearby_containers: Array) -> int:
	## Stack matching items from player inventory into nearby containers
	var stacked_count := 0
	
	for container_id in nearby_containers:
		if container_id not in _containers:
			continue
		
		var container: Dictionary = _containers[container_id]
		
		var i := 0
		while i < player_inventory.size():
			var item: Dictionary = player_inventory[i]
			
			# Check if container has matching item
			for existing in container["items"]:
				if _can_stack(existing, item):
					var result := store_item(container_id, item)
					if result.get("success", false):
						if item.get("quantity", 0) <= 0:
							player_inventory.remove_at(i)
							i -= 1
						stacked_count += 1
					break
			i += 1
	
	emit_signal("quick_stack_completed", stacked_count)
	return stacked_count


func quick_deposit_all(player_inventory: Array, container_id: String, filter_mode: int = FilterMode.ALL) -> int:
	## Deposit all matching items into a container
	if container_id not in _containers:
		return 0
	
	var deposited_count := 0
	var filter_tags: Array = ITEM_CATEGORIES.get(filter_mode, [])
	
	var i := player_inventory.size() - 1
	while i >= 0:
		var item: Dictionary = player_inventory[i]
		var should_deposit := filter_mode == FilterMode.ALL
		
		if not should_deposit:
			var item_type: String = item.get("type", "")
			var item_tags: Array = item.get("tags", [])
			for tag in filter_tags:
				if tag in item_type or tag in item_tags:
					should_deposit = true
					break
		
		if should_deposit:
			var result := store_item(container_id, item)
			if result.get("success", false):
				if item.get("quantity", 0) <= 0:
					player_inventory.remove_at(i)
				deposited_count += 1
		i -= 1
	
	return deposited_count


func quick_loot_all(container_id: String, player_inventory: Array, max_weight: float) -> Dictionary:
	## Take all items from container to player inventory
	if container_id not in _containers:
		return {"success": false, "error": "Container not found"}
	
	var container: Dictionary = _containers[container_id]
	var looted_count := 0
	var current_weight: float = 0.0
	
	for item in player_inventory:
		current_weight += item.get("weight", 1.0) * item.get("quantity", 1)
	
	var i := container["items"].size() - 1
	while i >= 0:
		var item: Dictionary = container["items"][i]
		var item_weight: float = item.get("weight", 1.0) * item.get("quantity", 1)
		
		if current_weight + item_weight <= max_weight:
			player_inventory.append(item.duplicate())
			container["items"].remove_at(i)
			container["current_weight"] -= item_weight
			current_weight += item_weight
			looted_count += 1
		i -= 1
	
	return {"success": true, "looted_count": looted_count}


# ============================================================================
# AUTO-DEPOSIT SYSTEM
# ============================================================================

func add_auto_deposit_rule(filter_mode: int, container_id: String) -> void:
	auto_deposit_rules.append({
		"filter": filter_mode,
		"container_id": container_id,
	})


func remove_auto_deposit_rule(index: int) -> void:
	if index >= 0 and index < auto_deposit_rules.size():
		auto_deposit_rules.remove_at(index)


func process_auto_deposit(player_inventory: Array) -> int:
	if not auto_deposit_enabled:
		return 0
	
	var deposited_count := 0
	
	for rule in auto_deposit_rules:
		var filter_mode: int = rule.get("filter", FilterMode.ALL)
		var container_id: String = rule.get("container_id", "")
		
		deposited_count += quick_deposit_all(player_inventory, container_id, filter_mode)
	
	emit_signal("auto_deposit_completed", deposited_count)
	return deposited_count


# ============================================================================
# FAVORITES
# ============================================================================

func toggle_favorite(item_id: String) -> bool:
	if item_id in _favorite_items:
		_favorite_items.erase(item_id)
		return false
	else:
		_favorite_items.append(item_id)
		return true


func is_favorite(item_id: String) -> bool:
	return item_id in _favorite_items


func get_favorites() -> Array:
	return _favorite_items.duplicate()


# ============================================================================
# LOCKING
# ============================================================================

func lock_container(container_id: String, code: String = "") -> bool:
	if container_id not in _containers:
		return false
	
	var container: Dictionary = _containers[container_id]
	var definition: Dictionary = CONTAINER_DEFINITIONS.get(container["type"], {})
	
	if not definition.get("lockable", false):
		return false
	
	container["locked"] = true
	container["lock_code"] = code
	return true


func unlock_container(container_id: String, code: String = "") -> bool:
	if container_id not in _containers:
		return false
	
	var container: Dictionary = _containers[container_id]
	
	if not container.get("locked", false):
		return true
	
	if container.get("lock_code", "") == "" or container["lock_code"] == code:
		container["locked"] = false
		return true
	
	return false


func is_locked(container_id: String) -> bool:
	if container_id not in _containers:
		return false
	return _containers[container_id].get("locked", false)


# ============================================================================
# DECAY & POWER
# ============================================================================

var _decay_timer: float = 0.0
var _power_timer: float = 0.0

func _update_decay(delta: float) -> void:
	_decay_timer += delta
	if _decay_timer < 60.0:  # Check every minute
		return
	_decay_timer = 0.0
	
	for container in _containers.values():
		var decay_rate: float = container.get("decay_rate", 1.0)
		
		if decay_rate <= 0.0:
			continue
		
		if container.get("requires_power", false) and not container.get("powered", false):
			decay_rate = 1.0  # Full decay when unpowered
		
		for item in container["items"]:
			if item.get("decays", false):
				var freshness: float = item.get("freshness", 1.0)
				freshness -= 0.01 * decay_rate  # 1% per minute base
				item["freshness"] = maxf(freshness, 0.0)
				
				if freshness <= 0.0:
					item["spoiled"] = true


func _update_powered_containers(delta: float) -> void:
	_power_timer += delta
	if _power_timer < 1.0:
		return
	_power_timer = 0.0
	
	# This would integrate with BaseUpgradeSystem power grid


func set_container_power(container_id: String, powered: bool) -> void:
	if container_id in _containers:
		_containers[container_id]["powered"] = powered


# ============================================================================
# STATISTICS
# ============================================================================

func get_container_stats(container_id: String) -> Dictionary:
	if container_id not in _containers:
		return {}
	
	var container: Dictionary = _containers[container_id]
	
	return {
		"slots_used": container["items"].size(),
		"slots_total": container["slots"],
		"weight_used": container["current_weight"],
		"weight_total": container["max_weight"],
		"item_count": container["items"].reduce(func(acc, item): return acc + item.get("quantity", 1), 0),
		"is_full": container["items"].size() >= container["slots"],
	}


func get_total_storage_stats() -> Dictionary:
	var total_slots := 0
	var used_slots := 0
	var total_items := 0
	var total_weight := 0.0
	
	for container in _containers.values():
		total_slots += container["slots"]
		used_slots += container["items"].size()
		total_weight += container["current_weight"]
		for item in container["items"]:
			total_items += item.get("quantity", 1)
	
	return {
		"container_count": _containers.size(),
		"total_slots": total_slots,
		"used_slots": used_slots,
		"total_items": total_items,
		"total_weight": total_weight,
	}


func get_item_count(item_id: String) -> int:
	var total := 0
	for container in _containers.values():
		for item in container["items"]:
			if item.get("id", "") == item_id:
				total += item.get("quantity", 1)
	return total


# ============================================================================
# LABELS & ORGANIZATION
# ============================================================================

func set_container_label(container_id: String, label: String) -> void:
	if container_id in _containers:
		_containers[container_id]["custom_label"] = label


func set_container_name(container_id: String, name: String) -> void:
	if container_id in _containers:
		_containers[container_id]["display_name"] = name


func add_custom_category(category_name: String, item_tags: Array) -> void:
	_custom_categories[category_name] = item_tags


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"containers": _containers.duplicate(true),
		"favorite_items": _favorite_items.duplicate(),
		"custom_categories": _custom_categories.duplicate(),
		"auto_stack_enabled": auto_stack_enabled,
		"auto_deposit_enabled": auto_deposit_enabled,
		"auto_deposit_rules": auto_deposit_rules.duplicate(true),
	}


func load_data(data: Dictionary) -> void:
	_containers = data.get("containers", {})
	_favorite_items = data.get("favorite_items", [])
	_custom_categories = data.get("custom_categories", {})
	auto_stack_enabled = data.get("auto_stack_enabled", true)
	auto_deposit_enabled = data.get("auto_deposit_enabled", false)
	auto_deposit_rules = data.get("auto_deposit_rules", [])
