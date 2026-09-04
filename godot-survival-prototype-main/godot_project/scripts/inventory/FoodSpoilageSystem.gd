extends Node

## FoodSpoilageSystem - Perishable items with freshness timers
## More advanced than LDOE with quality grades, preservation methods, and effects

class_name FoodSpoilageSystem

# ============================================================================
# SIGNALS
# ============================================================================

signal item_freshness_changed(item_id: String, slot: int, freshness: float)
signal item_spoiled(item_id: String, slot: int)
signal item_quality_changed(item_id: String, slot: int, old_quality: int, new_quality: int)
signal food_effect_applied(effect_name: String, duration: float)

# ============================================================================
# ENUMS
# ============================================================================

enum FoodQuality {
	PERFECT,      # 100-80% - Full nutrition, possible bonus
	FRESH,        # 80-60% - Normal nutrition
	AGING,        # 60-40% - Slightly reduced nutrition
	STALE,        # 40-20% - Reduced nutrition, small sickness chance
	SPOILED,      # 20-0% - Very low nutrition, high sickness chance
	ROTTEN        # 0% - No nutrition, guaranteed sickness
}

enum PreservationType {
	NONE,
	DRIED,        # Jerky, dried fruits - much slower decay
	CANNED,       # Canned goods - very slow decay until opened
	FROZEN,       # Frozen items - almost no decay while frozen
	SALTED,       # Salted meats - slower decay
	SMOKED,       # Smoked meats - moderate decay reduction
	PICKLED,      # Pickled vegetables - very slow decay
	VACUUM_SEALED # Modern preservation - minimal decay
}

# ============================================================================
# CONSTANTS
# ============================================================================

# Base spoilage time in seconds (real-time)
const SPOILAGE_TIMES := {
	# Raw meats - spoil quickly
	"meat_raw": 300.0,         # 5 minutes
	"fish_raw": 240.0,         # 4 minutes
	"chicken_raw": 300.0,      # 5 minutes
	
	# Cooked foods - moderate spoilage
	"meat_cooked": 900.0,      # 15 minutes
	"fish_cooked": 720.0,      # 12 minutes
	"chicken_cooked": 900.0,   # 15 minutes
	"stew": 600.0,             # 10 minutes
	"soup": 480.0,             # 8 minutes
	"bread": 1800.0,           # 30 minutes
	"cooked_vegetables": 720.0,# 12 minutes
	
	# Fresh produce - varies
	"berry": 600.0,            # 10 minutes
	"apple": 1200.0,           # 20 minutes
	"carrot": 1800.0,          # 30 minutes
	"potato": 2400.0,          # 40 minutes
	"corn": 1200.0,            # 20 minutes
	"mushroom": 480.0,         # 8 minutes
	"tomato": 720.0,           # 12 minutes
	"lettuce": 360.0,          # 6 minutes
	"onion": 3600.0,           # 60 minutes
	"garlic": 3600.0,          # 60 minutes
	
	# Preserved foods - very slow or no spoilage
	"jerky": 7200.0,           # 2 hours
	"dried_fruit": 5400.0,     # 90 minutes
	"canned_food": 36000.0,    # 10 hours
	"mre": 72000.0,            # 20 hours
	"canned_beans": 36000.0,   # 10 hours
	"canned_meat": 36000.0,    # 10 hours
	"pickles": 14400.0,        # 4 hours
	"salted_meat": 3600.0,     # 60 minutes
	"smoked_meat": 2400.0,     # 40 minutes
	
	# Drinks
	"water_bottle": -1.0,      # Never spoils (clean water)
	"water_dirty": -1.0,       # Already bad, doesn't get worse
	"energy_drink": -1.0,      # Preserved
	"coffee": 600.0,           # 10 minutes (if brewed)
	"milk": 480.0,             # 8 minutes
	"juice": 720.0,            # 12 minutes
	
	# Eggs and dairy
	"egg": 1800.0,             # 30 minutes
	"cheese": 2400.0,          # 40 minutes
	"butter": 1800.0           # 30 minutes
}

# Preservation multipliers (applied to base time)
const PRESERVATION_MULTIPLIERS := {
	PreservationType.NONE: 1.0,
	PreservationType.DRIED: 4.0,
	PreservationType.CANNED: 10.0,
	PreservationType.FROZEN: 50.0,
	PreservationType.SALTED: 2.5,
	PreservationType.SMOKED: 2.0,
	PreservationType.PICKLED: 6.0,
	PreservationType.VACUUM_SEALED: 8.0
}

# Temperature effects (zone/container based)
const TEMPERATURE_MULTIPLIERS := {
	"hot": 0.5,        # Spoils 2x faster
	"warm": 0.75,      # Spoils 1.33x faster
	"normal": 1.0,     # Normal rate
	"cool": 1.5,       # Spoils 0.67x slower
	"cold": 3.0,       # Spoils 0.33x slower
	"frozen": 20.0     # Almost no spoilage
}

# Quality thresholds
const QUALITY_THRESHOLDS := {
	FoodQuality.PERFECT: 0.8,
	FoodQuality.FRESH: 0.6,
	FoodQuality.AGING: 0.4,
	FoodQuality.STALE: 0.2,
	FoodQuality.SPOILED: 0.0,
	FoodQuality.ROTTEN: -1.0  # Used when freshness hits 0
}

# Nutrition multipliers by quality
const NUTRITION_MULTIPLIERS := {
	FoodQuality.PERFECT: 1.1,   # Bonus nutrition
	FoodQuality.FRESH: 1.0,
	FoodQuality.AGING: 0.8,
	FoodQuality.STALE: 0.5,
	FoodQuality.SPOILED: 0.2,
	FoodQuality.ROTTEN: 0.0
}

# Sickness chance by quality
const SICKNESS_CHANCE := {
	FoodQuality.PERFECT: 0.0,
	FoodQuality.FRESH: 0.0,
	FoodQuality.AGING: 0.0,
	FoodQuality.STALE: 0.1,     # 10% chance
	FoodQuality.SPOILED: 0.4,   # 40% chance
	FoodQuality.ROTTEN: 1.0     # Guaranteed
}

# Sickness effects
const SICKNESS_EFFECTS := {
	"food_poisoning": {
		"duration": 120.0,  # 2 minutes
		"health_drain": 1,  # HP per second
		"stamina_penalty": 0.5,
		"description": "Food Poisoning - Draining health and stamina"
	},
	"mild_nausea": {
		"duration": 60.0,   # 1 minute
		"health_drain": 0,
		"stamina_penalty": 0.3,
		"description": "Mild Nausea - Reduced stamina"
	},
	"dysentery": {
		"duration": 300.0,  # 5 minutes
		"health_drain": 2,
		"thirst_drain": 2,
		"stamina_penalty": 0.7,
		"description": "Dysentery - Severe dehydration and weakness"
	}
}

# ============================================================================
# TRACKED ITEMS
# ============================================================================

# Dictionary: slot_id -> { item_id, freshness, max_freshness, preservation, quality, spawn_time }
var tracked_items: Dictionary = {}
var slot_counter := 0

# Current environment
var current_temperature := "normal"

# Reference to player for applying effects
var player_ref: Node = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("spoilage_system")

func _process(delta: float) -> void:
	_update_all_items(delta)

func set_player(player: Node) -> void:
	player_ref = player

# ============================================================================
# ITEM TRACKING
# ============================================================================

func add_perishable_item(item_id: String, preservation: PreservationType = PreservationType.NONE, initial_freshness: float = 1.0) -> int:
	if not is_perishable(item_id):
		return -1
	
	slot_counter += 1
	var slot := slot_counter
	
	var max_fresh := get_max_freshness(item_id, preservation)
	
	tracked_items[slot] = {
		"item_id": item_id,
		"freshness": initial_freshness * max_fresh,
		"max_freshness": max_fresh,
		"preservation": preservation,
		"quality": _get_quality_for_freshness(initial_freshness),
		"spawn_time": Time.get_unix_time_from_system()
	}
	
	return slot

func remove_tracked_item(slot: int) -> void:
	if tracked_items.has(slot):
		tracked_items.erase(slot)

func get_item_freshness(slot: int) -> float:
	if not tracked_items.has(slot):
		return 1.0
	
	var data: Dictionary = tracked_items[slot]
	return data.freshness / data.max_freshness if data.max_freshness > 0 else 0.0

func get_item_quality(slot: int) -> FoodQuality:
	if not tracked_items.has(slot):
		return FoodQuality.FRESH
	return tracked_items[slot].quality

func is_perishable(item_id: String) -> bool:
	if not SPOILAGE_TIMES.has(item_id):
		return false
	return SPOILAGE_TIMES[item_id] > 0

func get_max_freshness(item_id: String, preservation: PreservationType) -> float:
	var base_time: float = SPOILAGE_TIMES.get(item_id, 600.0)
	if base_time < 0:
		return -1.0  # Never spoils
	
	var preservation_mult: float = PRESERVATION_MULTIPLIERS.get(preservation, 1.0)
	return base_time * preservation_mult

# ============================================================================
# FRESHNESS UPDATE
# ============================================================================

func _update_all_items(delta: float) -> void:
	var to_remove: Array = []
	
	for slot in tracked_items.keys():
		var data: Dictionary = tracked_items[slot]
		
		if data.max_freshness < 0:
			continue  # Never spoils
		
		# Calculate decay rate
		var temp_mult: float = TEMPERATURE_MULTIPLIERS.get(current_temperature, 1.0)
		var decay_rate := delta / temp_mult
		
		# Reduce freshness
		var old_freshness := data.freshness
		data.freshness = max(0, data.freshness - decay_rate)
		
		# Check quality change
		var freshness_percent := data.freshness / data.max_freshness
		var new_quality := _get_quality_for_freshness(freshness_percent)
		
		if new_quality != data.quality:
			var old_quality: FoodQuality = data.quality
			data.quality = new_quality
			item_quality_changed.emit(data.item_id, slot, old_quality, new_quality)
		
		# Emit freshness change signal periodically
		if int(old_freshness / 60) != int(data.freshness / 60):  # Every minute
			item_freshness_changed.emit(data.item_id, slot, freshness_percent)
		
		# Check if fully spoiled
		if data.freshness <= 0:
			data.quality = FoodQuality.ROTTEN
			item_spoiled.emit(data.item_id, slot)

func _get_quality_for_freshness(freshness_percent: float) -> FoodQuality:
	if freshness_percent >= QUALITY_THRESHOLDS[FoodQuality.PERFECT]:
		return FoodQuality.PERFECT
	elif freshness_percent >= QUALITY_THRESHOLDS[FoodQuality.FRESH]:
		return FoodQuality.FRESH
	elif freshness_percent >= QUALITY_THRESHOLDS[FoodQuality.AGING]:
		return FoodQuality.AGING
	elif freshness_percent >= QUALITY_THRESHOLDS[FoodQuality.STALE]:
		return FoodQuality.STALE
	elif freshness_percent > QUALITY_THRESHOLDS[FoodQuality.SPOILED]:
		return FoodQuality.SPOILED
	else:
		return FoodQuality.ROTTEN

# ============================================================================
# TEMPERATURE MANAGEMENT
# ============================================================================

func set_temperature(temp: String) -> void:
	if TEMPERATURE_MULTIPLIERS.has(temp):
		current_temperature = temp

func get_temperature_for_zone(zone_name: String) -> String:
	# Zone-based temperature
	match zone_name:
		"desert", "volcano", "fire_zone":
			return "hot"
		"jungle", "swamp":
			return "warm"
		"forest", "plains":
			return "normal"
		"mountain", "cave":
			return "cool"
		"tundra", "ice_cave", "freezer":
			return "frozen"
		_:
			return "normal"

func get_temperature_for_container(container_type: String) -> String:
	match container_type:
		"refrigerator", "cooler":
			return "cold"
		"freezer", "cryogenic":
			return "frozen"
		"heated_storage":
			return "warm"
		_:
			return current_temperature

# ============================================================================
# CONSUMPTION
# ============================================================================

func consume_item(slot: int) -> Dictionary:
	if not tracked_items.has(slot):
		return {"success": false, "reason": "Item not found"}
	
	var data: Dictionary = tracked_items[slot]
	var quality: FoodQuality = data.quality
	
	# Calculate nutrition
	var nutrition_mult: float = NUTRITION_MULTIPLIERS.get(quality, 1.0)
	
	# Check for sickness
	var sickness_chance: float = SICKNESS_CHANCE.get(quality, 0.0)
	var got_sick := false
	var sickness_effect := ""
	
	if randf() <= sickness_chance:
		got_sick = true
		sickness_effect = _determine_sickness(quality)
		_apply_sickness(sickness_effect)
	
	# Remove from tracking
	remove_tracked_item(slot)
	
	return {
		"success": true,
		"item_id": data.item_id,
		"quality": quality,
		"nutrition_multiplier": nutrition_mult,
		"got_sick": got_sick,
		"sickness_effect": sickness_effect
	}

func _determine_sickness(quality: FoodQuality) -> String:
	match quality:
		FoodQuality.STALE:
			return "mild_nausea"
		FoodQuality.SPOILED:
			if randf() < 0.3:
				return "dysentery"
			return "food_poisoning"
		FoodQuality.ROTTEN:
			if randf() < 0.5:
				return "dysentery"
			return "food_poisoning"
		_:
			return "mild_nausea"

func _apply_sickness(effect_name: String) -> void:
	if not SICKNESS_EFFECTS.has(effect_name):
		return
	
	var effect: Dictionary = SICKNESS_EFFECTS[effect_name]
	
	food_effect_applied.emit(effect_name, effect.duration)
	
	# Apply to player if available
	if is_instance_valid(player_ref):
		if player_ref.has_method("apply_status_effect"):
			player_ref.apply_status_effect(effect_name, effect)

# ============================================================================
# PRESERVATION
# ============================================================================

func preserve_item(slot: int, method: PreservationType) -> bool:
	if not tracked_items.has(slot):
		return false
	
	var data: Dictionary = tracked_items[slot]
	var old_preservation: PreservationType = data.preservation
	
	if old_preservation != PreservationType.NONE:
		return false  # Already preserved
	
	# Recalculate max freshness with new preservation
	var old_max := data.max_freshness
	var new_max := get_max_freshness(data.item_id, method)
	
	if new_max < 0:
		# Item doesn't spoil with this preservation
		data.max_freshness = -1.0
		data.preservation = method
		return true
	
	# Scale current freshness to new max
	var freshness_percent := data.freshness / old_max if old_max > 0 else 1.0
	data.freshness = freshness_percent * new_max
	data.max_freshness = new_max
	data.preservation = method
	
	return true

func get_preservation_name(method: PreservationType) -> String:
	match method:
		PreservationType.NONE: return "Fresh"
		PreservationType.DRIED: return "Dried"
		PreservationType.CANNED: return "Canned"
		PreservationType.FROZEN: return "Frozen"
		PreservationType.SALTED: return "Salted"
		PreservationType.SMOKED: return "Smoked"
		PreservationType.PICKLED: return "Pickled"
		PreservationType.VACUUM_SEALED: return "Vacuum Sealed"
		_: return "Unknown"

# ============================================================================
# RECIPES - COOKING AFFECTS SPOILAGE
# ============================================================================

const COOKING_CONVERSIONS := {
	"meat_raw": "meat_cooked",
	"fish_raw": "fish_cooked",
	"chicken_raw": "chicken_cooked",
	"potato": "cooked_vegetables",
	"carrot": "cooked_vegetables",
	"corn": "cooked_vegetables"
}

func cook_item(slot: int) -> Dictionary:
	if not tracked_items.has(slot):
		return {"success": false, "reason": "Item not found"}
	
	var data: Dictionary = tracked_items[slot]
	var item_id: String = data.item_id
	
	if not COOKING_CONVERSIONS.has(item_id):
		return {"success": false, "reason": "Item cannot be cooked"}
	
	var cooked_id: String = COOKING_CONVERSIONS[item_id]
	
	# Cooking resets freshness but inherits some quality loss
	var quality_penalty := 0.0
	match data.quality:
		FoodQuality.STALE:
			quality_penalty = 0.1
		FoodQuality.SPOILED:
			quality_penalty = 0.3
		FoodQuality.ROTTEN:
			return {"success": false, "reason": "Item is too rotten to cook"}
	
	# Remove old item
	remove_tracked_item(slot)
	
	# Add cooked item with adjusted freshness
	var new_slot := add_perishable_item(cooked_id, PreservationType.NONE, 1.0 - quality_penalty)
	
	return {
		"success": true,
		"new_item_id": cooked_id,
		"new_slot": new_slot,
		"freshness": 1.0 - quality_penalty
	}

# ============================================================================
# UI HELPERS
# ============================================================================

func get_quality_name(quality: FoodQuality) -> String:
	match quality:
		FoodQuality.PERFECT: return "Perfect"
		FoodQuality.FRESH: return "Fresh"
		FoodQuality.AGING: return "Aging"
		FoodQuality.STALE: return "Stale"
		FoodQuality.SPOILED: return "Spoiled"
		FoodQuality.ROTTEN: return "Rotten"
		_: return "Unknown"

func get_quality_color(quality: FoodQuality) -> Color:
	match quality:
		FoodQuality.PERFECT: return Color(0.2, 1.0, 0.2)  # Bright green
		FoodQuality.FRESH: return Color(0.5, 1.0, 0.5)    # Light green
		FoodQuality.AGING: return Color(1.0, 1.0, 0.3)    # Yellow
		FoodQuality.STALE: return Color(1.0, 0.7, 0.2)    # Orange
		FoodQuality.SPOILED: return Color(1.0, 0.3, 0.2)  # Red
		FoodQuality.ROTTEN: return Color(0.4, 0.2, 0.4)   # Dark purple
		_: return Color.WHITE

func get_freshness_bar_data(slot: int) -> Dictionary:
	if not tracked_items.has(slot):
		return {"visible": false}
	
	var data: Dictionary = tracked_items[slot]
	if data.max_freshness < 0:
		return {"visible": false}  # Never spoils
	
	var percent := data.freshness / data.max_freshness
	var quality: FoodQuality = data.quality
	
	return {
		"visible": true,
		"percent": percent,
		"color": get_quality_color(quality),
		"quality_name": get_quality_name(quality),
		"time_remaining": data.freshness
	}

func get_time_remaining_string(slot: int) -> String:
	if not tracked_items.has(slot):
		return ""
	
	var data: Dictionary = tracked_items[slot]
	if data.max_freshness < 0:
		return "Never spoils"
	
	var seconds := data.freshness
	if seconds <= 0:
		return "Rotten"
	
	if seconds < 60:
		return "%ds" % int(seconds)
	elif seconds < 3600:
		return "%dm" % int(seconds / 60)
	else:
		return "%dh %dm" % [int(seconds / 3600), int(fmod(seconds, 3600) / 60)]

# ============================================================================
# SERIALIZATION
# ============================================================================

func get_save_data() -> Dictionary:
	var save_items := {}
	var current_time := Time.get_unix_time_from_system()
	
	for slot in tracked_items.keys():
		var data: Dictionary = tracked_items[slot]
		# Store time elapsed, not absolute time
		save_items[slot] = {
			"item_id": data.item_id,
			"freshness": data.freshness,
			"max_freshness": data.max_freshness,
			"preservation": data.preservation,
			"quality": data.quality,
			"time_since_spawn": current_time - data.spawn_time
		}
	
	return {
		"tracked_items": save_items,
		"slot_counter": slot_counter,
		"current_temperature": current_temperature
	}

func load_save_data(data: Dictionary) -> void:
	tracked_items.clear()
	slot_counter = data.get("slot_counter", 0)
	current_temperature = data.get("current_temperature", "normal")
	
	var saved_items: Dictionary = data.get("tracked_items", {})
	var current_time := Time.get_unix_time_from_system()
	
	for slot_str in saved_items.keys():
		var slot := int(slot_str)
		var item_data: Dictionary = saved_items[slot_str]
		
		# Account for time passed while game was closed
		var time_offline: float = item_data.get("time_since_spawn", 0.0)
		var freshness: float = item_data.get("freshness", 0.0)
		var max_fresh: float = item_data.get("max_freshness", 600.0)
		
		# Decay for offline time (at normal temperature rate)
		if max_fresh > 0:
			freshness = max(0, freshness - time_offline)
		
		tracked_items[slot] = {
			"item_id": item_data.get("item_id", ""),
			"freshness": freshness,
			"max_freshness": max_fresh,
			"preservation": item_data.get("preservation", PreservationType.NONE),
			"quality": _get_quality_for_freshness(freshness / max_fresh if max_fresh > 0 else 0),
			"spawn_time": current_time
		}
