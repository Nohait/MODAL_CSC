extends RefCounted

class_name IdleEconomyConfig

const SAVE_PATH := "user://idle_mode_save.json"
const OFFLINE_CAP_SECONDS := 4 * 60 * 60
const MAX_EVENT_LOG := 30

const RESOURCE_ORDER := [
	"wood",
	"stone",
	"fibers",
	"water",
	"food",
	"planks",
	"rope",
	"scrap",
	"fuel",
	"metal_parts",
	"med_supplies",
	"defense_kits",
	"electronics",
	"signal_intel",
	"survivor_credits",
]

const RESOURCE_BAR_ORDER := [
	"wood",
	"stone",
	"fibers",
	"water",
	"food",
	"planks",
	"rope",
	"survivor_credits",
]

const RESOURCE_DEFS := {
	"wood": {"title": "Wood", "tier": "basic", "category": "materials"},
	"stone": {"title": "Stone", "tier": "basic", "category": "materials"},
	"fibers": {"title": "Fibers", "tier": "basic", "category": "materials"},
	"water": {"title": "Water", "tier": "sustain", "category": "sustain"},
	"food": {"title": "Food", "tier": "sustain", "category": "sustain"},
	"planks": {"title": "Planks", "tier": "processed", "category": "crafting"},
	"rope": {"title": "Rope", "tier": "processed", "category": "crafting"},
	"scrap": {"title": "Scrap", "tier": "mid", "category": "industrial"},
	"fuel": {"title": "Fuel", "tier": "mid", "category": "industrial"},
	"metal_parts": {"title": "Metal Parts", "tier": "mid", "category": "industrial"},
	"med_supplies": {"title": "Med Supplies", "tier": "utility", "category": "utility"},
	"defense_kits": {"title": "Defense Kits", "tier": "utility", "category": "utility"},
	"electronics": {"title": "Electronics", "tier": "rare", "category": "late"},
	"signal_intel": {"title": "Signal Intel", "tier": "rare", "category": "late"},
	"survivor_credits": {"title": "Credits", "tier": "premium_safe", "category": "meta"},
}

const STARTER_CACHE := {
	"wood": 18.0,
	"stone": 12.0,
	"fibers": 10.0,
	"water": 4.0,
	"food": 4.0,
	"survivor_credits": 5.0,
}

const ROOM_ORDER := [
	"command",
	"storage",
	"workshop",
	"water",
	"food",
	"defense",
	"forge",
	"communications",
	"recycling",
]

const ROOM_DEFS := {
	"command": {
		"title": "Command",
		"description": "Coordinates bunker operations and unlocks new zones.",
		"starting_level": 1,
		"max_level": 4,
		"base_cost": {"wood": 10.0, "stone": 8.0},
	},
	"storage": {
		"title": "Storage",
		"description": "Raises bunker caps so your haul does not overflow.",
		"starting_level": 1,
		"max_level": 4,
		"base_cost": {"wood": 9.0, "stone": 6.0},
	},
	"workshop": {
		"title": "Workshop",
		"description": "Processes raw salvage into useful materials.",
		"starting_level": 1,
		"max_level": 4,
		"base_cost": {"wood": 8.0, "stone": 6.0, "fibers": 4.0},
	},
	"water": {
		"title": "Water",
		"description": "Passively condenses clean water for expeditions.",
		"starting_level": 1,
		"max_level": 4,
		"base_cost": {"stone": 7.0, "fibers": 3.0},
	},
	"food": {
		"title": "Food",
		"description": "Produces steady rations so teams can keep moving.",
		"starting_level": 1,
		"max_level": 4,
		"base_cost": {"wood": 6.0, "fibers": 5.0},
	},
	"defense": {
		"title": "Defense",
		"description": "Hardens the bunker and reduces late-run risk.",
		"starting_level": 0,
		"max_level": 4,
		"base_cost": {"stone": 10.0, "planks": 4.0},
	},
	"forge": {
		"title": "Forge",
		"description": "Converts scrap and fuel into stronger industrial parts.",
		"starting_level": 0,
		"max_level": 4,
		"base_cost": {"planks": 5.0, "scrap": 6.0},
	},
	"communications": {
		"title": "Communications",
		"description": "Expands radio reach and unlocks higher-risk opportunities.",
		"starting_level": 0,
		"max_level": 4,
		"base_cost": {"planks": 4.0, "rope": 3.0, "scrap": 6.0},
	},
	"recycling": {
		"title": "Recycling",
		"description": "Turns waste into steady salvage while you are away.",
		"starting_level": 0,
		"max_level": 4,
		"base_cost": {"scrap": 8.0, "rope": 3.0},
	},
}

const RECIPE_ORDER := ["plank", "rope"]

const RECIPE_DEFS := {
	"plank": {
		"title": "Plank",
		"duration_seconds": 20,
		"inputs": {"wood": 4.0},
		"outputs": {"planks": 1.0},
	},
	"rope": {
		"title": "Rope",
		"duration_seconds": 25,
		"inputs": {"fibers": 3.0},
		"outputs": {"rope": 1.0},
	},
}

const ZONE_ORDER := ["green", "yellow", "red"]

const ZONE_DEFS := {
	"green": {
		"title": "Green Zone",
		"risk": "Low",
		"duration_seconds": 90,
		"requirements": {},
		"supply_cost": {"water": 1.0, "food": 1.0},
		"reward_ranges": {
			"wood": Vector2(6, 10),
			"stone": Vector2(4, 8),
			"fibers": Vector2(3, 6),
			"survivor_credits": Vector2(0, 1),
		},
		"outcomes": {"full": 70, "partial": 25, "injury": 5},
	},
	"yellow": {
		"title": "Yellow Zone",
		"risk": "Medium",
		"duration_seconds": 5 * 60,
		"requirements": {"command": 2, "workshop": 2},
		"supply_cost": {"water": 2.0, "food": 2.0},
		"reward_ranges": {
			"scrap": Vector2(4, 7),
			"fuel": Vector2(2, 4),
			"planks": Vector2(1, 2),
			"metal_parts": Vector2(1, 2),
		},
		"outcomes": {"full": 50, "partial": 35, "injury": 12, "failure": 3},
	},
	"red": {
		"title": "Red Zone",
		"risk": "High",
		"duration_seconds": 15 * 60,
		"requirements": {"command": 3, "defense": 1, "communications": 1},
		"supply_cost": {"water": 3.0, "food": 3.0, "med_supplies": 1.0},
		"reward_ranges": {
			"electronics": Vector2(1, 2),
			"signal_intel": Vector2(1, 2),
			"defense_kits": Vector2(1, 2),
			"scrap": Vector2(8, 12),
		},
		"outcomes": {"full": 30, "partial": 35, "injury": 20, "failure": 10, "jackpot": 5},
	},
}

static func make_default_state() -> Dictionary:
	var state := {
		"version": 1,
		"resources": {},
		"rooms": {},
		"craft_queue": [],
		"active_expedition": {},
		"event_cards": [],
		"event_log": [],
		"daily_rewards": {
			"last_claim_day": -1,
			"streak": 0,
		},
		"ftue": {
			"starter_cache_claimed": false,
			"first_expedition_complete": false,
			"first_craft_complete": false,
		},
		"last_tick_unix": int(Time.get_unix_time_from_system()),
	}

	for resource_id in RESOURCE_ORDER:
		state["resources"][resource_id] = 0.0

	for room_id in ROOM_ORDER:
		var room_def: Dictionary = ROOM_DEFS.get(room_id, {})
		state["rooms"][room_id] = {
			"level": int(room_def.get("starting_level", 0)),
		}

	return state

static func normalize_state(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return make_default_state()

	var normalized := make_default_state()
	var resources: Dictionary = state.get("resources", {})
	for resource_id in RESOURCE_ORDER:
		normalized["resources"][resource_id] = float(resources.get(resource_id, normalized["resources"][resource_id]))

	var rooms: Dictionary = state.get("rooms", {})
	for room_id in ROOM_ORDER:
		var room_state: Dictionary = rooms.get(room_id, {})
		normalized["rooms"][room_id]["level"] = int(room_state.get("level", normalized["rooms"][room_id]["level"]))

	var ftue_state: Dictionary = state.get("ftue", {})
	for ftue_key in normalized["ftue"].keys():
		normalized["ftue"][ftue_key] = bool(ftue_state.get(ftue_key, normalized["ftue"][ftue_key]))

	normalized["craft_queue"] = []
	for job in state.get("craft_queue", []):
		if job is Dictionary:
			normalized["craft_queue"].append(job)

	var active_expedition: Dictionary = state.get("active_expedition", {})
	if active_expedition is Dictionary:
		normalized["active_expedition"] = active_expedition

	normalized["event_cards"] = []
	for card in state.get("event_cards", []):
		if card is Dictionary:
			normalized["event_cards"].append(card.duplicate(true))

	normalized["event_log"] = []
	for entry in state.get("event_log", []):
		if entry is Dictionary:
			normalized["event_log"].append(entry)

	var daily_rewards: Dictionary = state.get("daily_rewards", {})
	normalized["daily_rewards"] = {
		"last_claim_day": int(daily_rewards.get("last_claim_day", -1)),
		"streak": int(daily_rewards.get("streak", 0)),
	}

	normalized["last_tick_unix"] = int(state.get("last_tick_unix", normalized["last_tick_unix"]))
	return normalized

static func get_resource_def(resource_id: String) -> Dictionary:
	return RESOURCE_DEFS.get(resource_id, {"title": resource_id.capitalize(), "tier": "basic", "category": "misc"})

static func get_resource_title(resource_id: String) -> String:
	var resource_def: Dictionary = get_resource_def(resource_id)
	return str(resource_def.get("title", resource_id.capitalize()))

static func get_room_def(room_id: String) -> Dictionary:
	return ROOM_DEFS.get(room_id, {})

static func get_recipe_def(recipe_id: String) -> Dictionary:
	return RECIPE_DEFS.get(recipe_id, {})

static func get_zone_def(zone_id: String) -> Dictionary:
	return ZONE_DEFS.get(zone_id, {})

static func get_room_level(state: Dictionary, room_id: String) -> int:
	var rooms: Dictionary = state.get("rooms", {})
	var room_state: Dictionary = rooms.get(room_id, {})
	return int(room_state.get("level", 0))

static func get_base_level(state: Dictionary) -> int:
	return get_room_level(state, "command")

static func get_resource_cap(state: Dictionary, resource_id: String) -> float:
	var storage_level := get_room_level(state, "storage")
	var resource_def: Dictionary = get_resource_def(resource_id)
	var tier := str(resource_def.get("tier", "basic"))

	match tier:
		"basic":
			return 30.0 + float(storage_level) * 24.0
		"sustain":
			return 16.0 + float(storage_level) * 10.0
		"processed":
			return 10.0 + float(storage_level) * 10.0
		"mid":
			return 6.0 + float(storage_level) * 8.0
		"utility":
			return 4.0 + float(storage_level) * 5.0
		"rare":
			return 2.0 + float(storage_level) * 3.0
		"premium_safe":
			return 999.0
		_:
			return 30.0

static func add_resource(state: Dictionary, resource_id: String, amount: float) -> float:
	if amount <= 0.0:
		return 0.0

	var resources: Dictionary = state.get("resources", {})
	var current := float(resources.get(resource_id, 0.0))
	var cap := get_resource_cap(state, resource_id)
	var next_value := min(cap, current + amount)
	resources[resource_id] = snapped(next_value, 0.1)
	state["resources"] = resources
	return next_value - current

static func remove_resource(state: Dictionary, resource_id: String, amount: float) -> float:
	if amount <= 0.0:
		return 0.0

	var resources: Dictionary = state.get("resources", {})
	var current := float(resources.get(resource_id, 0.0))
	var next_value := max(0.0, current - amount)
	resources[resource_id] = snapped(next_value, 0.1)
	state["resources"] = resources
	return current - next_value

static func can_afford(resources: Dictionary, cost: Dictionary) -> bool:
	for resource_id in cost.keys():
		if float(resources.get(resource_id, 0.0)) + 0.001 < float(cost.get(resource_id, 0.0)):
			return false
	return true

static func spend_resources(state: Dictionary, cost: Dictionary) -> bool:
	var resources: Dictionary = state.get("resources", {})
	if not can_afford(resources, cost):
		return false

	for resource_id in cost.keys():
		remove_resource(state, resource_id, float(cost.get(resource_id, 0.0)))
	return true

static func get_room_upgrade_cost(room_id: String, current_level: int) -> Dictionary:
	var room_def: Dictionary = get_room_def(room_id)
	if room_def.is_empty():
		return {}

	var max_level := int(room_def.get("max_level", 4))
	if current_level >= max_level:
		return {}

	var base_cost: Dictionary = room_def.get("base_cost", {})
	var factor := 0.85 if current_level <= 0 else pow(1.35, current_level - 1)
	var result := {}
	for resource_id in base_cost.keys():
		result[resource_id] = float(int(ceil(float(base_cost.get(resource_id, 0.0)) * factor)))
	return result

static func get_room_effect_summary(room_id: String, level: int) -> String:
	if level <= 0:
		return "Offline until unlocked."

	match room_id:
		"command":
			return "Base level %d. Unlocks tougher zones and stronger bunker ops." % level
		"storage":
			return "Basic caps at %s, processed caps at %s." % [format_amount(get_resource_cap({"rooms": {"storage": {"level": level}}}, "wood")), format_amount(get_resource_cap({"rooms": {"storage": {"level": level}}}, "planks"))]
		"workshop":
			return "Runs crafting queues for planks and rope. Higher levels reduce future friction."
		"water":
			return "%s water per minute." % format_amount(float(level) * 0.75)
		"food":
			return "%s food per minute." % format_amount(float(level) * 0.55)
		"defense":
			return "Raid mitigation online. Current defense tier %d." % level
		"forge":
			return "Industrial conversion ready. Unlocks stronger late-loop outputs at tier %d." % level
		"communications":
			return "Radio reach tier %d. Supports late-zone access and event quality." % level
		"recycling":
			return "%s scrap per minute from bunker waste." % format_amount(float(level) * 0.2)
		_:
			return "Functional room."

static func get_room_production_rates(room_id: String, level: int) -> Dictionary:
	if level <= 0:
		return {}

	match room_id:
		"water":
			return {"water": 0.75 * float(level)}
		"food":
			return {"food": 0.55 * float(level)}
		"recycling":
			return {"scrap": 0.2 * float(level)}
		_:
			return {}

static func is_zone_unlocked(state: Dictionary, zone_id: String) -> bool:
	return get_zone_unlock_reason(state, zone_id).is_empty()

static func get_zone_unlock_reason(state: Dictionary, zone_id: String) -> String:
	var zone_def: Dictionary = get_zone_def(zone_id)
	var requirements: Dictionary = zone_def.get("requirements", {})
	for room_id in requirements.keys():
		var required_level := int(requirements.get(room_id, 0))
		if get_room_level(state, room_id) < required_level:
			var room_title := str(get_room_def(room_id).get("title", room_id.capitalize()))
			return "%s L%d required." % [room_title, required_level]
	return ""

static func build_zone_loot_preview(zone_id: String) -> String:
	var zone_def: Dictionary = get_zone_def(zone_id)
	var reward_ranges: Dictionary = zone_def.get("reward_ranges", {})
	var parts: Array[String] = []
	for resource_id in reward_ranges.keys():
		parts.append(get_resource_title(str(resource_id)))
	return ", ".join(parts)

static func build_cost_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "No cost"

	var parts: Array[String] = []
	for resource_id in cost.keys():
		parts.append("%s %s" % [format_amount(float(cost.get(resource_id, 0.0))), get_resource_title(str(resource_id))])
	return ", ".join(parts)

static func build_amount_text(amounts: Dictionary) -> String:
	if amounts.is_empty():
		return "No change"

	var parts: Array[String] = []
	for resource_id in amounts.keys():
		parts.append("%s %s" % [format_amount(float(amounts.get(resource_id, 0.0))), get_resource_title(str(resource_id))])
	return ", ".join(parts)

static func format_amount(value: float) -> String:
	var rounded_int := int(round(value))
	if absf(value - float(rounded_int)) < 0.05:
		return str(rounded_int)
	return "%.1f" % value

static func trim_event_log(state: Dictionary) -> void:
	var entries: Array = state.get("event_log", [])
	while entries.size() > MAX_EVENT_LOG:
		entries.pop_front()
	state["event_log"] = entries

static func get_next_objective(state: Dictionary) -> String:
	var ftue: Dictionary = state.get("ftue", {})
	if not bool(ftue.get("starter_cache_claimed", false)):
		return "Claim the starter cache to stock the bunker."

	if not bool(ftue.get("first_expedition_complete", false)):
		if state.get("active_expedition", {}).is_empty():
			return "Launch a Green Zone expedition."
		return "Wait for the first expedition team to report back."

	if not bool(ftue.get("first_craft_complete", false)):
		return "Queue your first Plank or Rope at the Workshop."

	if get_room_level(state, "storage") < 2:
		return "Upgrade Storage so future hauls do not overflow."

	if get_room_level(state, "workshop") < 2:
		return "Upgrade the Workshop to push toward Yellow Zone readiness."

	if not is_zone_unlocked(state, "yellow"):
		return "Raise Command and Workshop to unlock Yellow Zone expeditions."

	return "Keep the bunker supplied and push toward higher-risk zones."
