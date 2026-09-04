extends Node

## Enhanced Loot System - Rewarding drops with pity timer and quality scaling
## Addresses the "lackluster loot" problem from LDOE

signal loot_generated(loot_data: Dictionary)
signal pity_timer_triggered(quality: String)
signal legendary_dropped(item_id: String)

const GameConfig = preload("res://scripts/core/GameConfig.gd")
const ItemDatabase = preload("res://scripts/inventory/ItemDatabase.gd")

# Loot pools organized by category and quality
var loot_pools := {
	"weapons": {},
	"armor": {},
	"resources": {},
	"consumables": {},
	"blueprints": {},
	"special": {}
}

# Pity timer tracking per player
var pity_counters := {}  # player_id -> int

# Loot modifiers from skills, events, etc.
var global_loot_modifier := 0.0
var player_loot_modifiers := {}  # player_id -> float

func _ready() -> void:
	_build_loot_pools()

func _build_loot_pools() -> void:
	# Weapons by quality
	loot_pools["weapons"] = {
		"common": [
			{"id": "wood_club", "weight": 30},
			{"id": "stone_knife", "weight": 25},
			{"id": "makeshift_spear", "weight": 20},
			{"id": "wood_bow", "weight": 15},
			{"id": "slingshot", "weight": 10}
		],
		"uncommon": [
			{"id": "iron_hatchet", "weight": 25},
			{"id": "hunting_knife", "weight": 25},
			{"id": "compound_bow", "weight": 20},
			{"id": "iron_sword", "weight": 15},
			{"id": "crossbow", "weight": 15}
		],
		"rare": [
			{"id": "steel_machete", "weight": 25},
			{"id": "military_knife", "weight": 20},
			{"id": "rifle_bolt", "weight": 20},
			{"id": "shotgun_pump", "weight": 18},
			{"id": "katana", "weight": 17}
		],
		"epic": [
			{"id": "assault_rifle", "weight": 25},
			{"id": "sniper_rifle", "weight": 20},
			{"id": "chainsaw", "weight": 18},
			{"id": "flamethrower", "weight": 17},
			{"id": "grenade_launcher", "weight": 20}
		],
		"legendary": [
			{"id": "plasma_cutter", "weight": 25},
			{"id": "railgun", "weight": 20},
			{"id": "energy_sword", "weight": 25},
			{"id": "smart_rifle", "weight": 20},
			{"id": "minigun", "weight": 10}
		],
		"mythic": [
			{"id": "void_blade", "weight": 30},
			{"id": "thunderstrike", "weight": 25},
			{"id": "infinity_bow", "weight": 25},
			{"id": "omega_cannon", "weight": 20}
		]
	}
	
	# Armor by quality
	loot_pools["armor"] = {
		"common": [
			{"id": "cloth_shirt", "weight": 30},
			{"id": "cloth_pants", "weight": 30},
			{"id": "bandana", "weight": 20},
			{"id": "leather_gloves", "weight": 20}
		],
		"uncommon": [
			{"id": "leather_jacket", "weight": 25},
			{"id": "leather_pants", "weight": 25},
			{"id": "combat_boots", "weight": 25},
			{"id": "biker_helmet", "weight": 25}
		],
		"rare": [
			{"id": "kevlar_vest", "weight": 30},
			{"id": "tactical_pants", "weight": 25},
			{"id": "military_boots", "weight": 25},
			{"id": "combat_helmet", "weight": 20}
		],
		"epic": [
			{"id": "swat_armor", "weight": 30},
			{"id": "reinforced_vest", "weight": 25},
			{"id": "exo_legs", "weight": 25},
			{"id": "night_vision_helmet", "weight": 20}
		],
		"legendary": [
			{"id": "power_armor_chest", "weight": 30},
			{"id": "power_armor_legs", "weight": 25},
			{"id": "tactical_exosuit", "weight": 25},
			{"id": "stealth_suit", "weight": 20}
		],
		"mythic": [
			{"id": "quantum_armor", "weight": 35},
			{"id": "void_cloak", "weight": 35},
			{"id": "immortal_plate", "weight": 30}
		]
	}
	
	# Resources by quality (higher quality = rarer resources)
	loot_pools["resources"] = {
		"common": [
			{"id": "wood", "weight": 25, "quantity_range": [5, 15]},
			{"id": "stone", "weight": 25, "quantity_range": [5, 15]},
			{"id": "fibers", "weight": 25, "quantity_range": [3, 10]},
			{"id": "cloth", "weight": 15, "quantity_range": [2, 8]},
			{"id": "leather", "weight": 10, "quantity_range": [1, 5]}
		],
		"uncommon": [
			{"id": "iron_ore", "weight": 30, "quantity_range": [3, 8]},
			{"id": "copper_ore", "weight": 25, "quantity_range": [2, 6]},
			{"id": "rubber", "weight": 20, "quantity_range": [2, 5]},
			{"id": "glass", "weight": 15, "quantity_range": [1, 4]},
			{"id": "wire", "weight": 10, "quantity_range": [1, 3]}
		],
		"rare": [
			{"id": "steel_ingot", "weight": 30, "quantity_range": [2, 5]},
			{"id": "electronics", "weight": 25, "quantity_range": [1, 3]},
			{"id": "gunpowder", "weight": 25, "quantity_range": [2, 6]},
			{"id": "polymer", "weight": 20, "quantity_range": [1, 3]}
		],
		"epic": [
			{"id": "titanium", "weight": 30, "quantity_range": [1, 3]},
			{"id": "advanced_circuits", "weight": 25, "quantity_range": [1, 2]},
			{"id": "carbon_fiber", "weight": 25, "quantity_range": [1, 2]},
			{"id": "fusion_core", "weight": 20, "quantity_range": [1, 1]}
		],
		"legendary": [
			{"id": "quantum_crystal", "weight": 35, "quantity_range": [1, 2]},
			{"id": "dark_matter", "weight": 35, "quantity_range": [1, 1]},
			{"id": "plasma_cell", "weight": 30, "quantity_range": [1, 2]}
		],
		"mythic": [
			{"id": "void_essence", "weight": 50, "quantity_range": [1, 1]},
			{"id": "eternal_fragment", "weight": 50, "quantity_range": [1, 1]}
		]
	}
	
	# Consumables
	loot_pools["consumables"] = {
		"common": [
			{"id": "bandage", "weight": 30, "quantity_range": [1, 3]},
			{"id": "water_bottle", "weight": 25, "quantity_range": [1, 2]},
			{"id": "canned_food", "weight": 25, "quantity_range": [1, 2]},
			{"id": "berries", "weight": 20, "quantity_range": [3, 8]}
		],
		"uncommon": [
			{"id": "first_aid_kit", "weight": 30, "quantity_range": [1, 2]},
			{"id": "energy_drink", "weight": 25, "quantity_range": [1, 2]},
			{"id": "cooked_meat", "weight": 25, "quantity_range": [1, 3]},
			{"id": "painkillers", "weight": 20, "quantity_range": [1, 2]}
		],
		"rare": [
			{"id": "medkit", "weight": 35, "quantity_range": [1, 1]},
			{"id": "adrenaline_shot", "weight": 25, "quantity_range": [1, 1]},
			{"id": "mre_pack", "weight": 25, "quantity_range": [1, 2]},
			{"id": "antidote", "weight": 15, "quantity_range": [1, 1]}
		],
		"epic": [
			{"id": "combat_stim", "weight": 35, "quantity_range": [1, 1]},
			{"id": "regeneration_serum", "weight": 35, "quantity_range": [1, 1]},
			{"id": "immunity_booster", "weight": 30, "quantity_range": [1, 1]}
		],
		"legendary": [
			{"id": "nano_heal", "weight": 50, "quantity_range": [1, 1]},
			{"id": "resurrection_kit", "weight": 50, "quantity_range": [1, 1]}
		],
		"mythic": [
			{"id": "phoenix_elixir", "weight": 100, "quantity_range": [1, 1]}
		]
	}
	
	# Blueprints (recipes for crafting)
	loot_pools["blueprints"] = {
		"uncommon": [
			{"id": "bp_iron_hatchet", "weight": 25},
			{"id": "bp_compound_bow", "weight": 25},
			{"id": "bp_leather_armor", "weight": 25},
			{"id": "bp_workbench_2", "weight": 25}
		],
		"rare": [
			{"id": "bp_steel_weapons", "weight": 30},
			{"id": "bp_firearms_basic", "weight": 25},
			{"id": "bp_kevlar_armor", "weight": 25},
			{"id": "bp_vehicle_parts", "weight": 20}
		],
		"epic": [
			{"id": "bp_advanced_firearms", "weight": 30},
			{"id": "bp_power_armor", "weight": 25},
			{"id": "bp_explosives", "weight": 25},
			{"id": "bp_atv_complete", "weight": 20}
		],
		"legendary": [
			{"id": "bp_plasma_weapons", "weight": 35},
			{"id": "bp_exosuit", "weight": 35},
			{"id": "bp_helicopter", "weight": 30}
		],
		"mythic": [
			{"id": "bp_quantum_tech", "weight": 50},
			{"id": "bp_void_forge", "weight": 50}
		]
	}

## Generate loot for a container/enemy with proper quality distribution
func generate_loot(
	zone: String,
	category: String,
	player_id: String = "default",
	luck_bonus: float = 0.0,
	guaranteed_quality: String = ""
) -> Dictionary:
	
	# Get or initialize pity counter
	if not pity_counters.has(player_id):
		pity_counters[player_id] = 0
	
	# Apply player-specific loot modifier
	var player_bonus: float = player_loot_modifiers.get(player_id, 0.0)
	var total_luck := luck_bonus + player_bonus + global_loot_modifier
	
	# Determine quality
	var quality := guaranteed_quality
	if quality == "":
		# Check pity timer first
		if pity_counters[player_id] >= GameConfig.LOOT_PITY_TIMER_THRESHOLD:
			quality = _get_pity_quality()
			pity_counters[player_id] = 0
			emit_signal("pity_timer_triggered", quality)
		else:
			quality = GameConfig.get_loot_quality(zone, total_luck)
			# Only increment pity for common/uncommon
			if quality in ["common", "uncommon"]:
				pity_counters[player_id] += 1
			else:
				pity_counters[player_id] = 0
	
	# Get pool for category and quality
	var pool: Array = []
	if loot_pools.has(category) and loot_pools[category].has(quality):
		pool = loot_pools[category][quality]
	
	if pool.is_empty():
		# Fallback to common if quality not found
		if loot_pools.has(category) and loot_pools[category].has("common"):
			pool = loot_pools[category]["common"]
			quality = "common"
	
	if pool.is_empty():
		return {"error": "No loot pool found"}
	
	# Roll for item from pool
	var item := _roll_from_pool(pool)
	
	# Calculate quantity
	var quantity := 1
	if item.has("quantity_range"):
		var range_arr: Array = item["quantity_range"]
		quantity = randi_range(range_arr[0], range_arr[1])
		# Apply quality multiplier to quantity
		var mult: float = GameConfig.LOOT_QUALITY_MULTIPLIERS.get(quality, 1.0)
		quantity = int(ceil(quantity * mult))
	
	var result := {
		"item_id": item["id"],
		"quality": quality,
		"quantity": quantity,
		"category": category,
		"zone": zone
	}
	
	# Special handling for legendary+
	if quality in ["legendary", "mythic"]:
		emit_signal("legendary_dropped", item["id"])
	
	emit_signal("loot_generated", result)
	return result

## Generate multiple loot items (for chests, boss kills, etc.)
func generate_loot_batch(
	zone: String,
	categories: Array,
	count: int,
	player_id: String = "default",
	luck_bonus: float = 0.0
) -> Array:
	var results := []
	for i in range(count):
		var cat: String = categories[randi() % categories.size()]
		var loot := generate_loot(zone, cat, player_id, luck_bonus)
		results.append(loot)
	return results

## Special loot for boss kills - guaranteed high quality
func generate_boss_loot(zone: String, boss_tier: int, player_id: String = "default") -> Array:
	var results := []
	
	# Boss tier affects minimum quality
	var min_quality := "rare"
	if boss_tier >= 2:
		min_quality = "epic"
	if boss_tier >= 3:
		min_quality = "legendary"
	
	# Always drop resources
	results.append(generate_loot(zone, "resources", player_id, 0.5, min_quality))
	
	# Chance for weapon or armor
	if randf() < 0.6:
		results.append(generate_loot(zone, "weapons", player_id, 0.3, min_quality))
	if randf() < 0.4:
		results.append(generate_loot(zone, "armor", player_id, 0.3, min_quality))
	
	# Chance for blueprint
	if randf() < 0.25:
		results.append(generate_loot(zone, "blueprints", player_id, 0.4))
	
	# Always drop consumables
	results.append(generate_loot(zone, "consumables", player_id, 0.2))
	
	return results

## Guaranteed quality for pity timer
func _get_pity_quality() -> String:
	var roll := randf()
	if roll < 0.5:
		return "rare"
	elif roll < 0.85:
		return "epic"
	elif roll < 0.98:
		return "legendary"
	else:
		return "mythic"

## Roll weighted random from pool
func _roll_from_pool(pool: Array) -> Dictionary:
	var total_weight := 0.0
	for entry in pool:
		total_weight += entry.get("weight", 1.0)
	
	var roll := randf() * total_weight
	var cumulative := 0.0
	for entry in pool:
		cumulative += entry.get("weight", 1.0)
		if roll <= cumulative:
			return entry
	
	return pool[0]  # Fallback

## Set global loot modifier (for events, etc.)
func set_global_modifier(modifier: float) -> void:
	global_loot_modifier = modifier

## Set player-specific loot modifier (from skills, gear, etc.)
func set_player_modifier(player_id: String, modifier: float) -> void:
	player_loot_modifiers[player_id] = modifier

## Reset pity timer (for testing)
func reset_pity(player_id: String) -> void:
	pity_counters[player_id] = 0
