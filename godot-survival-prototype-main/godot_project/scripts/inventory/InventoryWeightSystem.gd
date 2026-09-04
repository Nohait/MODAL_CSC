extends Node

## InventoryWeightSystem - Weight and encumbrance affecting player movement
## LDOE-style weight limits with smooth movement speed penalties

class_name InventoryWeightSystem

# ============================================================================
# SIGNALS
# ============================================================================

signal weight_changed(current: float, maximum: float)
signal encumbrance_changed(level: int, speed_multiplier: float)
signal over_encumbered(is_over: bool)

# ============================================================================
# CONSTANTS
# ============================================================================

enum EncumbranceLevel {
	NONE,       # 0-50% - No penalty
	LIGHT,      # 50-75% - Minor penalty
	MODERATE,   # 75-90% - Moderate penalty
	HEAVY,      # 90-100% - Heavy penalty
	OVERLOADED  # 100%+ - Severe penalty, no running
}

const ENCUMBRANCE_THRESHOLDS := {
	EncumbranceLevel.NONE: 0.0,
	EncumbranceLevel.LIGHT: 0.5,
	EncumbranceLevel.MODERATE: 0.75,
	EncumbranceLevel.HEAVY: 0.9,
	EncumbranceLevel.OVERLOADED: 1.0
}

const SPEED_MULTIPLIERS := {
	EncumbranceLevel.NONE: 1.0,
	EncumbranceLevel.LIGHT: 0.9,
	EncumbranceLevel.MODERATE: 0.75,
	EncumbranceLevel.HEAVY: 0.5,
	EncumbranceLevel.OVERLOADED: 0.25
}

const STAMINA_DRAIN_MULTIPLIERS := {
	EncumbranceLevel.NONE: 1.0,
	EncumbranceLevel.LIGHT: 1.2,
	EncumbranceLevel.MODERATE: 1.5,
	EncumbranceLevel.HEAVY: 2.0,
	EncumbranceLevel.OVERLOADED: 3.0
}

# Base weight capacity without any bonuses
const BASE_CAPACITY := 50.0

# Item weight categories (in kg)
const WEIGHT_CLASSES := {
	"negligible": 0.01,   # Seeds, bullets, small items
	"very_light": 0.1,    # Bandages, herbs
	"light": 0.25,        # Food items, small tools
	"medium": 0.5,        # Weapons, gear
	"heavy": 1.0,         # Armor, large tools
	"very_heavy": 2.0,    # Heavy weapons, equipment
	"massive": 5.0        # Vehicle parts, building materials
}

# ============================================================================
# ITEM WEIGHT DATABASE
# ============================================================================

const ITEM_WEIGHTS := {
	# Resources - Building
	"wood": 0.3,
	"stone": 0.4,
	"iron_ore": 0.5,
	"iron_bar": 0.4,
	"steel_bar": 0.5,
	"copper": 0.35,
	"aluminum": 0.25,
	"rope": 0.2,
	"leather": 0.15,
	"cloth": 0.1,
	"rubber": 0.2,
	"plastic": 0.1,
	"glass": 0.25,
	"electronics": 0.15,
	"fuel": 0.3,
	"oil": 0.25,
	"charcoal": 0.2,
	"gunpowder": 0.1,
	
	# Resources - Natural
	"plant_fiber": 0.05,
	"pine_log": 1.5,
	"oak_log": 2.0,
	"limestone": 0.6,
	"sulfur": 0.3,
	"saltpeter": 0.3,
	"berry": 0.02,
	"carrot": 0.05,
	"potato": 0.1,
	"corn": 0.08,
	"meat_raw": 0.3,
	"meat_cooked": 0.25,
	"fish_raw": 0.2,
	"fish_cooked": 0.18,
	
	# Food & Water
	"water_bottle": 0.5,
	"water_dirty": 0.5,
	"canned_food": 0.4,
	"mre": 0.3,
	"jerky": 0.1,
	"dried_fruit": 0.08,
	"stew": 0.4,
	"bread": 0.15,
	"energy_drink": 0.3,
	"coffee": 0.25,
	
	# Medical
	"bandage": 0.05,
	"first_aid_kit": 0.3,
	"med_kit": 0.5,
	"painkillers": 0.02,
	"antibiotics": 0.02,
	"adrenaline": 0.03,
	"splint": 0.1,
	"alcohol": 0.2,
	"herbal_medicine": 0.1,
	
	# Melee Weapons
	"fists": 0.0,
	"wood_club": 0.8,
	"baseball_bat": 1.0,
	"machete": 0.7,
	"fire_axe": 1.5,
	"crowbar": 1.2,
	"knife": 0.3,
	"sledgehammer": 3.0,
	"pipe_wrench": 1.0,
	"katana": 1.1,
	"spiked_bat": 1.2,
	"hatchet": 0.8,
	"pickaxe": 1.8,
	"shovel": 1.5,
	
	# Ranged Weapons
	"pistol": 0.9,
	"revolver": 1.0,
	"shotgun": 3.5,
	"rifle": 3.0,
	"sniper_rifle": 4.5,
	"smg": 2.5,
	"assault_rifle": 3.5,
	"bow": 0.8,
	"crossbow": 2.0,
	"makeshift_pistol": 0.6,
	
	# Ammunition
	"bullet_9mm": 0.01,
	"bullet_45": 0.015,
	"shell_12ga": 0.03,
	"bullet_556": 0.012,
	"bullet_762": 0.02,
	"arrow": 0.05,
	"bolt": 0.06,
	
	# Armor - Head
	"cloth_cap": 0.1,
	"baseball_cap": 0.1,
	"military_helmet": 1.0,
	"riot_helmet": 1.2,
	"tactical_helmet": 0.8,
	
	# Armor - Body
	"cloth_shirt": 0.2,
	"leather_jacket": 1.5,
	"kevlar_vest": 2.5,
	"tactical_vest": 3.0,
	"military_armor": 5.0,
	"swat_armor": 6.0,
	
	# Armor - Hands
	"cloth_gloves": 0.05,
	"leather_gloves": 0.15,
	"tactical_gloves": 0.2,
	"reinforced_gloves": 0.3,
	
	# Armor - Feet
	"sneakers": 0.4,
	"boots": 0.8,
	"military_boots": 1.0,
	"reinforced_boots": 1.2,
	
	# Backpacks (increase capacity)
	"small_backpack": 0.5,
	"medium_backpack": 0.8,
	"large_backpack": 1.2,
	"military_backpack": 1.5,
	"hiking_backpack": 2.0,
	
	# Tools
	"flashlight": 0.2,
	"lockpick": 0.02,
	"wrench": 0.5,
	"hammer": 0.6,
	"screwdriver": 0.1,
	"wire_cutters": 0.15,
	"multitool": 0.25,
	"radio": 0.3,
	"compass": 0.05,
	"binoculars": 0.4,
	"rope_ladder": 1.0,
	"grappling_hook": 0.8,
	
	# Crafting Components
	"duct_tape": 0.1,
	"nails": 0.05,
	"screws": 0.03,
	"springs": 0.04,
	"gears": 0.1,
	"wire": 0.05,
	"circuit_board": 0.08,
	"battery": 0.15,
	"motor": 0.5,
	
	# Vehicle Parts
	"engine_part": 5.0,
	"wheel": 8.0,
	"gas_tank": 3.0,
	"car_battery": 15.0,
	"spark_plugs": 0.2,
	
	# Special Items
	"blueprint": 0.01,
	"keycard": 0.01,
	"dog_tag": 0.01,
	"photo": 0.01,
	"journal": 0.1,
	"map": 0.02
}

# Backpack capacity bonuses
const BACKPACK_BONUSES := {
	"small_backpack": 15.0,
	"medium_backpack": 25.0,
	"large_backpack": 40.0,
	"military_backpack": 55.0,
	"hiking_backpack": 70.0
}

# ============================================================================
# STATE
# ============================================================================

var current_weight := 0.0
var max_capacity := BASE_CAPACITY
var current_encumbrance: EncumbranceLevel = EncumbranceLevel.NONE
var equipped_backpack: String = ""

# Skill/perk bonuses
var strength_bonus := 0.0  # From strength stat
var perk_bonus := 0.0      # From perks like "Pack Mule"

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("weight_system")

# ============================================================================
# WEIGHT CALCULATION
# ============================================================================

func calculate_inventory_weight(inventory: Dictionary) -> float:
	var total := 0.0
	
	for item_id in inventory.keys():
		var quantity: int = inventory[item_id]
		var item_weight := get_item_weight(item_id)
		total += item_weight * quantity
	
	return total

func get_item_weight(item_id: String) -> float:
	if ITEM_WEIGHTS.has(item_id):
		return ITEM_WEIGHTS[item_id]
	
	# Check ItemDatabase for custom items
	if has_node("/root/ItemDatabase"):
		var db = get_node("/root/ItemDatabase")
		if db.has_method("get_item"):
			var item = db.get_item(item_id)
			if item and item.has("weight"):
				return item.weight
	
	# Default weight for unknown items
	return 0.1

func get_stack_weight(item_id: String, quantity: int) -> float:
	return get_item_weight(item_id) * quantity

# ============================================================================
# CAPACITY MANAGEMENT
# ============================================================================

func recalculate_capacity() -> void:
	max_capacity = BASE_CAPACITY
	
	# Add backpack bonus
	if BACKPACK_BONUSES.has(equipped_backpack):
		max_capacity += BACKPACK_BONUSES[equipped_backpack]
	
	# Add strength bonus (e.g., 2kg per strength point)
	max_capacity += strength_bonus
	
	# Add perk bonus
	max_capacity += perk_bonus
	
	# Recalculate encumbrance with new capacity
	_update_encumbrance()

func set_equipped_backpack(backpack_id: String) -> void:
	equipped_backpack = backpack_id
	recalculate_capacity()

func add_strength_bonus(bonus: float) -> void:
	strength_bonus += bonus
	recalculate_capacity()

func add_perk_bonus(bonus: float) -> void:
	perk_bonus += bonus
	recalculate_capacity()

# ============================================================================
# WEIGHT UPDATES
# ============================================================================

func update_weight(new_weight: float) -> void:
	current_weight = new_weight
	_update_encumbrance()
	weight_changed.emit(current_weight, max_capacity)

func add_weight(amount: float) -> void:
	update_weight(current_weight + amount)

func remove_weight(amount: float) -> void:
	update_weight(max(0, current_weight - amount))

func can_add_item(item_id: String, quantity: int = 1) -> bool:
	var item_weight := get_stack_weight(item_id, quantity)
	# Allow going slightly over (105%) but not too much
	return (current_weight + item_weight) <= (max_capacity * 1.05)

func get_available_capacity() -> float:
	return max(0, max_capacity - current_weight)

# ============================================================================
# ENCUMBRANCE
# ============================================================================

func _update_encumbrance() -> void:
	var weight_ratio := current_weight / max_capacity if max_capacity > 0 else 1.0
	var new_level := _get_encumbrance_level(weight_ratio)
	
	if new_level != current_encumbrance:
		var old_level := current_encumbrance
		current_encumbrance = new_level
		
		var speed_mult := get_speed_multiplier()
		encumbrance_changed.emit(current_encumbrance, speed_mult)
		
		# Over-encumbered notification
		var was_over := old_level == EncumbranceLevel.OVERLOADED
		var is_over := current_encumbrance == EncumbranceLevel.OVERLOADED
		if was_over != is_over:
			over_encumbered.emit(is_over)

func _get_encumbrance_level(weight_ratio: float) -> EncumbranceLevel:
	if weight_ratio >= ENCUMBRANCE_THRESHOLDS[EncumbranceLevel.OVERLOADED]:
		return EncumbranceLevel.OVERLOADED
	elif weight_ratio >= ENCUMBRANCE_THRESHOLDS[EncumbranceLevel.HEAVY]:
		return EncumbranceLevel.HEAVY
	elif weight_ratio >= ENCUMBRANCE_THRESHOLDS[EncumbranceLevel.MODERATE]:
		return EncumbranceLevel.MODERATE
	elif weight_ratio >= ENCUMBRANCE_THRESHOLDS[EncumbranceLevel.LIGHT]:
		return EncumbranceLevel.LIGHT
	else:
		return EncumbranceLevel.NONE

func get_speed_multiplier() -> float:
	return SPEED_MULTIPLIERS.get(current_encumbrance, 1.0)

func get_stamina_drain_multiplier() -> float:
	return STAMINA_DRAIN_MULTIPLIERS.get(current_encumbrance, 1.0)

func is_over_encumbered() -> bool:
	return current_encumbrance == EncumbranceLevel.OVERLOADED

func can_sprint() -> bool:
	return current_encumbrance != EncumbranceLevel.OVERLOADED

func can_jump() -> bool:
	return current_encumbrance in [EncumbranceLevel.NONE, EncumbranceLevel.LIGHT, EncumbranceLevel.MODERATE]

func can_dodge() -> bool:
	return current_encumbrance in [EncumbranceLevel.NONE, EncumbranceLevel.LIGHT]

# ============================================================================
# UI HELPERS
# ============================================================================

func get_weight_percent() -> float:
	if max_capacity <= 0:
		return 100.0
	return (current_weight / max_capacity) * 100.0

func get_weight_string() -> String:
	return "%.1f / %.1f kg" % [current_weight, max_capacity]

func get_encumbrance_name() -> String:
	match current_encumbrance:
		EncumbranceLevel.NONE: return "Normal"
		EncumbranceLevel.LIGHT: return "Light Load"
		EncumbranceLevel.MODERATE: return "Moderate Load"
		EncumbranceLevel.HEAVY: return "Heavy Load"
		EncumbranceLevel.OVERLOADED: return "Overloaded!"
		_: return "Unknown"

func get_encumbrance_color() -> Color:
	match current_encumbrance:
		EncumbranceLevel.NONE: return Color.WHITE
		EncumbranceLevel.LIGHT: return Color.YELLOW
		EncumbranceLevel.MODERATE: return Color.ORANGE
		EncumbranceLevel.HEAVY: return Color.ORANGE_RED
		EncumbranceLevel.OVERLOADED: return Color.RED
		_: return Color.WHITE

# ============================================================================
# SERIALIZATION
# ============================================================================

func get_save_data() -> Dictionary:
	return {
		"current_weight": current_weight,
		"equipped_backpack": equipped_backpack,
		"strength_bonus": strength_bonus,
		"perk_bonus": perk_bonus
	}

func load_save_data(data: Dictionary) -> void:
	equipped_backpack = data.get("equipped_backpack", "")
	strength_bonus = data.get("strength_bonus", 0.0)
	perk_bonus = data.get("perk_bonus", 0.0)
	
	recalculate_capacity()
	update_weight(data.get("current_weight", 0.0))
