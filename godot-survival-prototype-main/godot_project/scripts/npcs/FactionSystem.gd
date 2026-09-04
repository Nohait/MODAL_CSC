extends Node
class_name FactionSystemClass
## Manages factions, reputation, territories, and faction relationships
## Controls how NPCs and enemies interact based on faction allegiances

signal faction_reputation_changed(faction_id: String, old_value: int, new_value: int)
signal faction_rank_changed(faction_id: String, old_rank: int, new_rank: int)
signal faction_relation_changed(faction_a: String, faction_b: String, relation: int)
signal faction_war_started(faction_a: String, faction_b: String)
signal faction_war_ended(faction_a: String, faction_b: String)
signal player_joined_faction(faction_id: String)
signal player_left_faction(faction_id: String)
signal territory_captured(territory_id: String, faction_id: String)

# ============================================================================
# FACTION CONFIGURATION
# ============================================================================

enum FactionType {
	MILITARY,
	SURVIVOR_GROUP,
	RAIDER_GANG,
	CULT,
	SCIENTIST,
	MERCHANT,
	NEUTRAL,
}

enum FactionRelation {
	WAR = -100,
	HOSTILE = -50,
	UNFRIENDLY = -25,
	NEUTRAL = 0,
	FRIENDLY = 25,
	ALLIED = 50,
	UNIFIED = 100,
}

enum FactionRank {
	UNKNOWN,
	OUTSIDER,
	ASSOCIATE,
	MEMBER,
	TRUSTED,
	VETERAN,
	ELITE,
	LEADER,
}

const FACTION_DEFINITIONS := {
	"survivors_alliance": {
		"name": "Survivors Alliance",
		"description": "A coalition of survivors working together to rebuild civilization.",
		"type": FactionType.SURVIVOR_GROUP,
		"color": Color(0.2, 0.6, 0.2),
		"base_relation": FactionRelation.FRIENDLY,
		"joinable": true,
		"hostile_to_player": false,
		"trade_discount": 0.1,  # 10% discount when allied
		"rank_requirements": {
			FactionRank.ASSOCIATE: 10,
			FactionRank.MEMBER: 50,
			FactionRank.TRUSTED: 150,
			FactionRank.VETERAN: 300,
			FactionRank.ELITE: 500,
		},
		"rank_benefits": {
			FactionRank.ASSOCIATE: ["safe_zone_access"],
			FactionRank.MEMBER: ["trade_discount_5"],
			FactionRank.TRUSTED: ["safe_house_use", "trade_discount_10"],
			FactionRank.VETERAN: ["faction_gear_access", "trade_discount_15"],
			FactionRank.ELITE: ["faction_base_access", "trade_discount_20", "special_missions"],
		},
	},
	"iron_wolves": {
		"name": "Iron Wolves",
		"description": "A militaristic faction of ex-soldiers maintaining order through strength.",
		"type": FactionType.MILITARY,
		"color": Color(0.4, 0.4, 0.5),
		"base_relation": FactionRelation.NEUTRAL,
		"joinable": true,
		"hostile_to_player": false,
		"trade_discount": 0.15,
		"rank_requirements": {
			FactionRank.ASSOCIATE: 25,
			FactionRank.MEMBER: 75,
			FactionRank.TRUSTED: 200,
			FactionRank.VETERAN: 400,
			FactionRank.ELITE: 700,
		},
		"rank_benefits": {
			FactionRank.ASSOCIATE: ["military_training"],
			FactionRank.MEMBER: ["weapon_access"],
			FactionRank.TRUSTED: ["armor_access", "military_base_entry"],
			FactionRank.VETERAN: ["tactical_support", "rare_weapons"],
			FactionRank.ELITE: ["elite_gear", "command_soldiers"],
		},
	},
	"merchant_guild": {
		"name": "Merchant Guild",
		"description": "A network of traders and merchants controlling commerce.",
		"type": FactionType.MERCHANT,
		"color": Color(0.8, 0.6, 0.2),
		"base_relation": FactionRelation.FRIENDLY,
		"joinable": true,
		"hostile_to_player": false,
		"trade_discount": 0.25,
		"rank_requirements": {
			FactionRank.ASSOCIATE: 15,
			FactionRank.MEMBER: 60,
			FactionRank.TRUSTED: 180,
			FactionRank.VETERAN: 350,
			FactionRank.ELITE: 600,
		},
		"rank_benefits": {
			FactionRank.ASSOCIATE: ["trade_discount_10"],
			FactionRank.MEMBER: ["rare_item_access", "trade_discount_15"],
			FactionRank.TRUSTED: ["caravan_protection", "trade_discount_20"],
			FactionRank.VETERAN: ["exclusive_goods", "trade_discount_25"],
			FactionRank.ELITE: ["trade_routes", "market_manipulation"],
		},
	},
	"cult_of_the_new_dawn": {
		"name": "Cult of the New Dawn",
		"description": "A mysterious cult that believes the apocalypse was destined.",
		"type": FactionType.CULT,
		"color": Color(0.6, 0.2, 0.6),
		"base_relation": FactionRelation.UNFRIENDLY,
		"joinable": true,
		"hostile_to_player": false,
		"trade_discount": 0.0,
		"rank_requirements": {
			FactionRank.ASSOCIATE: 20,
			FactionRank.MEMBER: 80,
			FactionRank.TRUSTED: 200,
			FactionRank.VETERAN: 400,
			FactionRank.ELITE: 666,
		},
		"rank_benefits": {
			FactionRank.ASSOCIATE: ["cult_protection"],
			FactionRank.MEMBER: ["ritual_knowledge"],
			FactionRank.TRUSTED: ["inner_sanctum_access"],
			FactionRank.VETERAN: ["mystic_abilities"],
			FactionRank.ELITE: ["prophet_status"],
		},
	},
	"bio_research_institute": {
		"name": "Bio Research Institute",
		"description": "Scientists searching for a cure to the infection.",
		"type": FactionType.SCIENTIST,
		"color": Color(0.2, 0.5, 0.8),
		"base_relation": FactionRelation.NEUTRAL,
		"joinable": true,
		"hostile_to_player": false,
		"trade_discount": 0.1,
		"rank_requirements": {
			FactionRank.ASSOCIATE: 20,
			FactionRank.MEMBER: 70,
			FactionRank.TRUSTED: 180,
			FactionRank.VETERAN: 350,
			FactionRank.ELITE: 550,
		},
		"rank_benefits": {
			FactionRank.ASSOCIATE: ["medical_support"],
			FactionRank.MEMBER: ["research_access"],
			FactionRank.TRUSTED: ["serum_access", "lab_entry"],
			FactionRank.VETERAN: ["experimental_treatments"],
			FactionRank.ELITE: ["cure_research_participation"],
		},
	},
	"blood_raiders": {
		"name": "Blood Raiders",
		"description": "A vicious raider gang that terrorizes survivors.",
		"type": FactionType.RAIDER_GANG,
		"color": Color(0.8, 0.2, 0.2),
		"base_relation": FactionRelation.HOSTILE,
		"joinable": false,
		"hostile_to_player": true,
		"trade_discount": 0.0,
		"rank_requirements": {},
		"rank_benefits": {},
	},
	"rust_horde": {
		"name": "Rust Horde",
		"description": "Vehicle-obsessed raiders who roam the wasteland.",
		"type": FactionType.RAIDER_GANG,
		"color": Color(0.6, 0.3, 0.1),
		"base_relation": FactionRelation.HOSTILE,
		"joinable": false,
		"hostile_to_player": true,
		"trade_discount": 0.0,
		"rank_requirements": {},
		"rank_benefits": {},
	},
	"scavenger_union": {
		"name": "Scavenger Union",
		"description": "Independent scavengers loosely organized for mutual benefit.",
		"type": FactionType.SURVIVOR_GROUP,
		"color": Color(0.5, 0.5, 0.3),
		"base_relation": FactionRelation.NEUTRAL,
		"joinable": true,
		"hostile_to_player": false,
		"trade_discount": 0.05,
		"rank_requirements": {
			FactionRank.ASSOCIATE: 10,
			FactionRank.MEMBER: 40,
			FactionRank.TRUSTED: 100,
			FactionRank.VETERAN: 200,
			FactionRank.ELITE: 350,
		},
		"rank_benefits": {
			FactionRank.ASSOCIATE: ["scav_tips"],
			FactionRank.MEMBER: ["shared_locations"],
			FactionRank.TRUSTED: ["loot_sharing"],
			FactionRank.VETERAN: ["scav_network"],
			FactionRank.ELITE: ["exclusive_finds"],
		},
	},
}

# Default faction relations (can be modified during gameplay)
const DEFAULT_FACTION_RELATIONS := {
	"survivors_alliance": {
		"iron_wolves": FactionRelation.FRIENDLY,
		"merchant_guild": FactionRelation.ALLIED,
		"bio_research_institute": FactionRelation.FRIENDLY,
		"blood_raiders": FactionRelation.WAR,
		"rust_horde": FactionRelation.WAR,
		"cult_of_the_new_dawn": FactionRelation.UNFRIENDLY,
		"scavenger_union": FactionRelation.FRIENDLY,
	},
	"iron_wolves": {
		"survivors_alliance": FactionRelation.FRIENDLY,
		"merchant_guild": FactionRelation.NEUTRAL,
		"bio_research_institute": FactionRelation.NEUTRAL,
		"blood_raiders": FactionRelation.WAR,
		"rust_horde": FactionRelation.WAR,
		"cult_of_the_new_dawn": FactionRelation.HOSTILE,
		"scavenger_union": FactionRelation.NEUTRAL,
	},
	"merchant_guild": {
		"survivors_alliance": FactionRelation.ALLIED,
		"iron_wolves": FactionRelation.NEUTRAL,
		"bio_research_institute": FactionRelation.FRIENDLY,
		"blood_raiders": FactionRelation.HOSTILE,
		"rust_horde": FactionRelation.HOSTILE,
		"cult_of_the_new_dawn": FactionRelation.NEUTRAL,
		"scavenger_union": FactionRelation.FRIENDLY,
	},
	"blood_raiders": {
		"survivors_alliance": FactionRelation.WAR,
		"iron_wolves": FactionRelation.WAR,
		"merchant_guild": FactionRelation.HOSTILE,
		"bio_research_institute": FactionRelation.HOSTILE,
		"rust_horde": FactionRelation.NEUTRAL,
		"cult_of_the_new_dawn": FactionRelation.NEUTRAL,
		"scavenger_union": FactionRelation.HOSTILE,
	},
}


# ============================================================================
# TERRITORY DEFINITIONS
# ============================================================================

const TERRITORY_DEFINITIONS := {
	"safe_zone_central": {
		"name": "Central Safe Zone",
		"controlling_faction": "survivors_alliance",
		"zone_type": "green",
		"capturable": false,
		"resources": ["food", "water", "shelter"],
	},
	"military_outpost_alpha": {
		"name": "Military Outpost Alpha",
		"controlling_faction": "iron_wolves",
		"zone_type": "yellow",
		"capturable": true,
		"resources": ["weapons", "ammo", "military_gear"],
	},
	"trade_hub_market": {
		"name": "Market Trade Hub",
		"controlling_faction": "merchant_guild",
		"zone_type": "green",
		"capturable": false,
		"resources": ["trade_goods", "rare_items"],
	},
	"research_facility_beta": {
		"name": "Research Facility Beta",
		"controlling_faction": "bio_research_institute",
		"zone_type": "yellow",
		"capturable": true,
		"resources": ["medical", "research_data"],
	},
	"raider_stronghold": {
		"name": "Raider Stronghold",
		"controlling_faction": "blood_raiders",
		"zone_type": "red",
		"capturable": true,
		"resources": ["loot", "vehicles"],
	},
}


# ============================================================================
# STATE
# ============================================================================

var _player_reputation: Dictionary = {}  # faction_id -> reputation value (-1000 to 1000)
var _player_rank: Dictionary = {}  # faction_id -> FactionRank
var _player_faction: String = ""  # Player's primary faction
var _faction_relations: Dictionary = {}  # faction_a -> {faction_b -> relation}
var _territories: Dictionary = {}  # territory_id -> territory data
var _faction_wars: Array = []  # Active wars [{a, b, started_at}]


func _ready() -> void:
	_initialize_factions()


func _initialize_factions() -> void:
	# Initialize player reputation to 0 for all factions
	for faction_id in FACTION_DEFINITIONS:
		_player_reputation[faction_id] = 0
		_player_rank[faction_id] = FactionRank.UNKNOWN
	
	# Initialize faction relations
	_faction_relations = DEFAULT_FACTION_RELATIONS.duplicate(true)
	
	# Initialize territories
	for territory_id in TERRITORY_DEFINITIONS:
		_territories[territory_id] = TERRITORY_DEFINITIONS[territory_id].duplicate(true)


# ============================================================================
# REPUTATION MANAGEMENT
# ============================================================================

func modify_reputation(faction_id: String, amount: int) -> void:
	if faction_id not in FACTION_DEFINITIONS:
		return
	
	var old_value: int = _player_reputation.get(faction_id, 0)
	var new_value: int = clampi(old_value + amount, -1000, 1000)
	
	_player_reputation[faction_id] = new_value
	
	emit_signal("faction_reputation_changed", faction_id, old_value, new_value)
	
	# Check for rank changes
	_update_faction_rank(faction_id)
	
	# Reputation actions affect allied/enemy factions
	_propagate_reputation(faction_id, amount)


func _propagate_reputation(faction_id: String, base_amount: int) -> void:
	var relations: Dictionary = _faction_relations.get(faction_id, {})
	
	for other_faction in relations:
		var relation: int = relations[other_faction]
		var propagated_amount: int = 0
		
		if relation >= FactionRelation.ALLIED:
			# Allied factions share reputation (50%)
			propagated_amount = int(base_amount * 0.5)
		elif relation >= FactionRelation.FRIENDLY:
			# Friendly factions share reputation (25%)
			propagated_amount = int(base_amount * 0.25)
		elif relation <= FactionRelation.WAR:
			# Enemy factions lose reputation (50%)
			propagated_amount = -int(base_amount * 0.5)
		elif relation <= FactionRelation.HOSTILE:
			# Hostile factions lose reputation (25%)
			propagated_amount = -int(base_amount * 0.25)
		
		if propagated_amount != 0:
			var old_rep: int = _player_reputation.get(other_faction, 0)
			_player_reputation[other_faction] = clampi(old_rep + propagated_amount, -1000, 1000)


func _update_faction_rank(faction_id: String) -> void:
	var definition: Dictionary = FACTION_DEFINITIONS.get(faction_id, {})
	var requirements: Dictionary = definition.get("rank_requirements", {})
	var reputation: int = _player_reputation.get(faction_id, 0)
	var current_rank: int = _player_rank.get(faction_id, FactionRank.UNKNOWN)
	var new_rank: int = FactionRank.UNKNOWN
	
	if reputation < 0:
		new_rank = FactionRank.UNKNOWN
	elif reputation >= 0:
		new_rank = FactionRank.OUTSIDER
	
	# Check each rank threshold
	for rank in requirements:
		if reputation >= requirements[rank]:
			new_rank = maxi(new_rank, rank)
	
	if new_rank != current_rank:
		_player_rank[faction_id] = new_rank
		emit_signal("faction_rank_changed", faction_id, current_rank, new_rank)


func get_reputation(faction_id: String) -> int:
	return _player_reputation.get(faction_id, 0)


func get_rank(faction_id: String) -> int:
	return _player_rank.get(faction_id, FactionRank.UNKNOWN)


func get_rank_name(rank: int) -> String:
	return FactionRank.keys()[rank]


# ============================================================================
# FACTION MEMBERSHIP
# ============================================================================

func join_faction(faction_id: String) -> Dictionary:
	var definition: Dictionary = FACTION_DEFINITIONS.get(faction_id, {})
	
	if definition.is_empty():
		return {"success": false, "error": "Unknown faction"}
	
	if not definition.get("joinable", false):
		return {"success": false, "error": "This faction does not accept new members"}
	
	var rank: int = _player_rank.get(faction_id, FactionRank.UNKNOWN)
	if rank < FactionRank.ASSOCIATE:
		return {"success": false, "error": "Insufficient reputation to join"}
	
	# Leave current faction if in one
	if _player_faction != "" and _player_faction != faction_id:
		leave_faction()
	
	_player_faction = faction_id
	emit_signal("player_joined_faction", faction_id)
	
	return {"success": true, "faction": faction_id}


func leave_faction() -> void:
	if _player_faction == "":
		return
	
	var old_faction: String = _player_faction
	_player_faction = ""
	
	# Reputation penalty for leaving
	modify_reputation(old_faction, -50)
	
	emit_signal("player_left_faction", old_faction)


func get_player_faction() -> String:
	return _player_faction


# ============================================================================
# FACTION BENEFITS
# ============================================================================

func get_faction_benefits(faction_id: String) -> Array:
	var definition: Dictionary = FACTION_DEFINITIONS.get(faction_id, {})
	var rank: int = _player_rank.get(faction_id, FactionRank.UNKNOWN)
	var benefits: Array = []
	
	var rank_benefits: Dictionary = definition.get("rank_benefits", {})
	for r in rank_benefits:
		if rank >= r:
			benefits.append_array(rank_benefits[r])
	
	return benefits


func has_benefit(benefit: String) -> bool:
	if _player_faction == "":
		return false
	
	var benefits: Array = get_faction_benefits(_player_faction)
	return benefit in benefits


func get_trade_discount(faction_id: String) -> float:
	var definition: Dictionary = FACTION_DEFINITIONS.get(faction_id, {})
	var rank: int = _player_rank.get(faction_id, FactionRank.UNKNOWN)
	
	if rank < FactionRank.MEMBER:
		return 0.0
	
	var base_discount: float = definition.get("trade_discount", 0.0)
	
	# Scale discount with rank
	var rank_bonus: float = 0.0
	match rank:
		FactionRank.MEMBER:
			rank_bonus = 0.0
		FactionRank.TRUSTED:
			rank_bonus = 0.05
		FactionRank.VETERAN:
			rank_bonus = 0.10
		FactionRank.ELITE:
			rank_bonus = 0.15
	
	return base_discount + rank_bonus


# ============================================================================
# FACTION RELATIONS (BETWEEN FACTIONS)
# ============================================================================

func get_faction_relation(faction_a: String, faction_b: String) -> int:
	if faction_a == faction_b:
		return FactionRelation.UNIFIED
	
	var relations: Dictionary = _faction_relations.get(faction_a, {})
	return relations.get(faction_b, FactionRelation.NEUTRAL)


func set_faction_relation(faction_a: String, faction_b: String, relation: int) -> void:
	if faction_a not in _faction_relations:
		_faction_relations[faction_a] = {}
	if faction_b not in _faction_relations:
		_faction_relations[faction_b] = {}
	
	_faction_relations[faction_a][faction_b] = relation
	_faction_relations[faction_b][faction_a] = relation  # Mirror
	
	emit_signal("faction_relation_changed", faction_a, faction_b, relation)


func are_factions_hostile(faction_a: String, faction_b: String) -> bool:
	var relation: int = get_faction_relation(faction_a, faction_b)
	return relation <= FactionRelation.HOSTILE


func are_factions_at_war(faction_a: String, faction_b: String) -> bool:
	for war in _faction_wars:
		if (war["a"] == faction_a and war["b"] == faction_b) or \
		   (war["a"] == faction_b and war["b"] == faction_a):
			return true
	return false


func start_war(faction_a: String, faction_b: String) -> void:
	if are_factions_at_war(faction_a, faction_b):
		return
	
	_faction_wars.append({
		"a": faction_a,
		"b": faction_b,
		"started_at": Time.get_unix_time_from_system(),
	})
	
	set_faction_relation(faction_a, faction_b, FactionRelation.WAR)
	emit_signal("faction_war_started", faction_a, faction_b)


func end_war(faction_a: String, faction_b: String) -> void:
	for i in range(_faction_wars.size() - 1, -1, -1):
		var war: Dictionary = _faction_wars[i]
		if (war["a"] == faction_a and war["b"] == faction_b) or \
		   (war["a"] == faction_b and war["b"] == faction_a):
			_faction_wars.remove_at(i)
	
	set_faction_relation(faction_a, faction_b, FactionRelation.HOSTILE)
	emit_signal("faction_war_ended", faction_a, faction_b)


# ============================================================================
# PLAYER HOSTILITY CHECK
# ============================================================================

func is_faction_hostile_to_player(faction_id: String) -> bool:
	var definition: Dictionary = FACTION_DEFINITIONS.get(faction_id, {})
	
	# Always hostile factions
	if definition.get("hostile_to_player", false):
		return true
	
	# Check reputation
	var reputation: int = _player_reputation.get(faction_id, 0)
	if reputation <= -500:
		return true
	
	# Check if player's faction is at war with this faction
	if _player_faction != "" and are_factions_at_war(_player_faction, faction_id):
		return true
	
	return false


func is_npc_hostile_to_player(npc_faction: String) -> bool:
	if npc_faction == "":
		return false  # No faction, neutral
	
	return is_faction_hostile_to_player(npc_faction)


# ============================================================================
# TERRITORIES
# ============================================================================

func get_territory(territory_id: String) -> Dictionary:
	return _territories.get(territory_id, {})


func get_territory_controller(territory_id: String) -> String:
	var territory: Dictionary = _territories.get(territory_id, {})
	return territory.get("controlling_faction", "")


func capture_territory(territory_id: String, new_faction: String) -> Dictionary:
	if territory_id not in _territories:
		return {"success": false, "error": "Unknown territory"}
	
	var territory: Dictionary = _territories[territory_id]
	
	if not territory.get("capturable", false):
		return {"success": false, "error": "Territory cannot be captured"}
	
	var old_faction: String = territory.get("controlling_faction", "")
	territory["controlling_faction"] = new_faction
	
	emit_signal("territory_captured", territory_id, new_faction)
	
	# Reputation effects
	if new_faction == _player_faction or new_faction == "player":
		if old_faction != "":
			modify_reputation(old_faction, -100)
		# Other factions may like or dislike this
		for faction_id in FACTION_DEFINITIONS:
			if are_factions_hostile(faction_id, old_faction):
				modify_reputation(faction_id, 25)
	
	return {"success": true, "old_faction": old_faction, "new_faction": new_faction}


func get_faction_territories(faction_id: String) -> Array:
	var territories: Array = []
	for territory_id in _territories:
		if _territories[territory_id].get("controlling_faction") == faction_id:
			territories.append(territory_id)
	return territories


# ============================================================================
# QUERIES
# ============================================================================

func get_faction(faction_id: String) -> Dictionary:
	return FACTION_DEFINITIONS.get(faction_id, {})


func get_all_factions() -> Array:
	return FACTION_DEFINITIONS.keys()


func get_joinable_factions() -> Array:
	var factions: Array = []
	for faction_id in FACTION_DEFINITIONS:
		if FACTION_DEFINITIONS[faction_id].get("joinable", false):
			factions.append(faction_id)
	return factions


func get_hostile_factions() -> Array:
	var factions: Array = []
	for faction_id in FACTION_DEFINITIONS:
		if is_faction_hostile_to_player(faction_id):
			factions.append(faction_id)
	return factions


func get_allied_factions() -> Array:
	var factions: Array = []
	for faction_id in FACTION_DEFINITIONS:
		var reputation: int = _player_reputation.get(faction_id, 0)
		if reputation >= 200:  # Allied threshold
			factions.append(faction_id)
	return factions


func get_faction_color(faction_id: String) -> Color:
	var definition: Dictionary = FACTION_DEFINITIONS.get(faction_id, {})
	return definition.get("color", Color.WHITE)


func get_faction_type(faction_id: String) -> int:
	var definition: Dictionary = FACTION_DEFINITIONS.get(faction_id, {})
	return definition.get("type", FactionType.NEUTRAL)


# ============================================================================
# REPUTATION ACTIONS
# ============================================================================

func on_npc_killed(npc_faction: String) -> void:
	if npc_faction == "":
		return
	
	# Major reputation loss
	modify_reputation(npc_faction, -50)


func on_npc_helped(npc_faction: String) -> void:
	if npc_faction == "":
		return
	
	modify_reputation(npc_faction, 10)


func on_quest_completed(faction_id: String, reward_rep: int = 25) -> void:
	modify_reputation(faction_id, reward_rep)


func on_trade_completed(faction_id: String, trade_value: int) -> void:
	# Small reputation gain for trading
	var rep_gain: int = clampi(trade_value / 100, 1, 10)
	modify_reputation(faction_id, rep_gain)


func on_enemy_killed(enemy_faction: String) -> void:
	if enemy_faction == "":
		return
	
	# Killing enemies of a faction improves relations with their enemies
	for faction_id in FACTION_DEFINITIONS:
		if are_factions_at_war(faction_id, enemy_faction):
			modify_reputation(faction_id, 5)


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"player_reputation": _player_reputation.duplicate(),
		"player_rank": _player_rank.duplicate(),
		"player_faction": _player_faction,
		"faction_relations": _faction_relations.duplicate(true),
		"territories": _territories.duplicate(true),
		"faction_wars": _faction_wars.duplicate(true),
	}


func load_data(data: Dictionary) -> void:
	_player_reputation = data.get("player_reputation", {})
	_player_rank = data.get("player_rank", {})
	_player_faction = data.get("player_faction", "")
	_faction_relations = data.get("faction_relations", {})
	_territories = data.get("territories", {})
	_faction_wars = data.get("faction_wars", [])
	
	# Ensure all factions have entries
	for faction_id in FACTION_DEFINITIONS:
		if faction_id not in _player_reputation:
			_player_reputation[faction_id] = 0
		if faction_id not in _player_rank:
			_player_rank[faction_id] = FactionRank.UNKNOWN
