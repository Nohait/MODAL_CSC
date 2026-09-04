extends Node

## StatusEffectSystem - Complete status effect management
## Handles buffs, debuffs, DoTs, and visual indicators

class_name StatusEffectSystem

# ============================================================================
# SIGNALS
# ============================================================================

signal effect_applied(target: Node, effect_name: String, effect_data: Dictionary)
signal effect_removed(target: Node, effect_name: String)
signal effect_stacked(target: Node, effect_name: String, new_stacks: int)
signal effect_tick(target: Node, effect_name: String, tick_damage: int)

# ============================================================================
# ENUMS
# ============================================================================

enum EffectType {
	DAMAGE_OVER_TIME,
	HEAL_OVER_TIME,
	STAT_MODIFIER,
	MOVEMENT_MODIFIER,
	CROWD_CONTROL,
	BUFF,
	DEBUFF
}

enum StackBehavior {
	NONE,           # Cannot stack
	DURATION,       # Refreshes duration
	INTENSITY,      # Increases effect strength
	COUNT           # Multiple separate instances
}

# ============================================================================
# EFFECT DEFINITIONS
# ============================================================================

const EFFECT_DEFINITIONS := {
	# ========== DAMAGE OVER TIME ==========
	"bleeding": {
		"name": "Bleeding",
		"description": "Losing blood rapidly",
		"type": EffectType.DAMAGE_OVER_TIME,
		"duration": 10.0,
		"tick_rate": 1.0,
		"damage_per_tick": 3,
		"stack_behavior": StackBehavior.INTENSITY,
		"max_stacks": 5,
		"icon": "bleeding",
		"color": Color(0.8, 0.1, 0.1),
		"can_kill": true,
		"cured_by": ["bandage", "first_aid", "med_kit"]
	},
	"burning": {
		"name": "Burning",
		"description": "On fire! Taking damage over time",
		"type": EffectType.DAMAGE_OVER_TIME,
		"duration": 5.0,
		"tick_rate": 0.5,
		"damage_per_tick": 4,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "burning",
		"color": Color(1.0, 0.5, 0.1),
		"can_kill": true,
		"spread_chance": 0.1,  # Can spread to nearby enemies
		"cured_by": ["water", "roll"]
	},
	"poison": {
		"name": "Poisoned",
		"description": "Toxins coursing through your veins",
		"type": EffectType.DAMAGE_OVER_TIME,
		"duration": 15.0,
		"tick_rate": 2.0,
		"damage_per_tick": 2,
		"stack_behavior": StackBehavior.INTENSITY,
		"max_stacks": 3,
		"icon": "poison",
		"color": Color(0.2, 0.8, 0.2),
		"can_kill": false,  # Leaves at 1 HP
		"cured_by": ["antidote", "med_kit"]
	},
	"acid_burn": {
		"name": "Acid Burn",
		"description": "Corrosive acid eating at flesh",
		"type": EffectType.DAMAGE_OVER_TIME,
		"duration": 4.0,
		"tick_rate": 0.5,
		"damage_per_tick": 5,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "acid",
		"color": Color(0.6, 0.9, 0.2),
		"can_kill": true,
		"armor_reduction": 0.2  # Also reduces armor
	},
	"radiation": {
		"name": "Radiation Sickness",
		"description": "Irradiated - health slowly draining",
		"type": EffectType.DAMAGE_OVER_TIME,
		"duration": 60.0,
		"tick_rate": 5.0,
		"damage_per_tick": 1,
		"stack_behavior": StackBehavior.INTENSITY,
		"max_stacks": 10,
		"icon": "radiation",
		"color": Color(0.9, 0.9, 0.2),
		"can_kill": true,
		"max_health_reduction": 0.05,  # Per stack
		"cured_by": ["anti_rad", "med_kit"]
	},
	"infection": {
		"name": "Infected",
		"description": "Wound is infected and spreading",
		"type": EffectType.DAMAGE_OVER_TIME,
		"duration": 120.0,
		"tick_rate": 10.0,
		"damage_per_tick": 1,
		"stack_behavior": StackBehavior.NONE,
		"max_stacks": 1,
		"icon": "infection",
		"color": Color(0.4, 0.5, 0.2),
		"can_kill": true,
		"spreads_over_time": true,  # Gets worse if untreated
		"cured_by": ["antibiotics", "med_kit"]
	},
	
	# ========== HEAL OVER TIME ==========
	"regeneration": {
		"name": "Regenerating",
		"description": "Health slowly restoring",
		"type": EffectType.HEAL_OVER_TIME,
		"duration": 30.0,
		"tick_rate": 1.0,
		"heal_per_tick": 2,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "regen",
		"color": Color(0.2, 1.0, 0.4)
	},
	"well_fed": {
		"name": "Well Fed",
		"description": "Satisfying meal boosting recovery",
		"type": EffectType.HEAL_OVER_TIME,
		"duration": 120.0,
		"tick_rate": 5.0,
		"heal_per_tick": 1,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "food",
		"color": Color(0.9, 0.7, 0.3),
		"stamina_regen_bonus": 0.25
	},
	"adrenaline_surge": {
		"name": "Adrenaline",
		"description": "Heart racing, pain numbed",
		"type": EffectType.HEAL_OVER_TIME,
		"duration": 10.0,
		"tick_rate": 1.0,
		"heal_per_tick": 5,
		"stack_behavior": StackBehavior.NONE,
		"max_stacks": 1,
		"icon": "adrenaline",
		"color": Color(1.0, 0.3, 0.3),
		"damage_resistance": 0.3,
		"speed_bonus": 0.2
	},
	
	# ========== CROWD CONTROL ==========
	"stunned": {
		"name": "Stunned",
		"description": "Cannot move or act",
		"type": EffectType.CROWD_CONTROL,
		"duration": 2.0,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "stun",
		"color": Color(1.0, 1.0, 0.3),
		"disables_movement": true,
		"disables_actions": true
	},
	"frozen": {
		"name": "Frozen",
		"description": "Encased in ice",
		"type": EffectType.CROWD_CONTROL,
		"duration": 3.0,
		"stack_behavior": StackBehavior.NONE,
		"max_stacks": 1,
		"icon": "frozen",
		"color": Color(0.5, 0.8, 1.0),
		"disables_movement": true,
		"disables_actions": true,
		"damage_resistance": 0.5  # Harder to damage when frozen
	},
	"fear": {
		"name": "Terrified",
		"description": "Paralyzed with fear",
		"type": EffectType.CROWD_CONTROL,
		"duration": 3.0,
		"stack_behavior": StackBehavior.NONE,
		"max_stacks": 1,
		"icon": "fear",
		"color": Color(0.5, 0.1, 0.5),
		"disables_actions": true,
		"force_flee": true
	},
	"grabbed": {
		"name": "Grabbed",
		"description": "Something has you!",
		"type": EffectType.CROWD_CONTROL,
		"duration": 1.5,
		"stack_behavior": StackBehavior.NONE,
		"max_stacks": 1,
		"icon": "grabbed",
		"color": Color(0.6, 0.3, 0.3),
		"disables_movement": true,
		"mash_to_escape": true
	},
	"slowed": {
		"name": "Slowed",
		"description": "Movement impaired",
		"type": EffectType.MOVEMENT_MODIFIER,
		"duration": 5.0,
		"stack_behavior": StackBehavior.INTENSITY,
		"max_stacks": 3,
		"icon": "slow",
		"color": Color(0.4, 0.4, 0.8),
		"speed_reduction": 0.2  # Per stack
	},
	"crippled": {
		"name": "Crippled",
		"description": "Leg injury - severely slowed",
		"type": EffectType.MOVEMENT_MODIFIER,
		"duration": 30.0,
		"stack_behavior": StackBehavior.NONE,
		"max_stacks": 1,
		"icon": "crippled",
		"color": Color(0.5, 0.3, 0.3),
		"speed_reduction": 0.5,
		"disables_sprint": true,
		"disables_dodge": true,
		"cured_by": ["splint", "med_kit"]
	},
	
	# ========== STAT BUFFS ==========
	"strengthened": {
		"name": "Strengthened",
		"description": "Increased damage output",
		"type": EffectType.BUFF,
		"duration": 60.0,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "strength",
		"color": Color(1.0, 0.5, 0.3),
		"damage_bonus": 0.25
	},
	"fortified": {
		"name": "Fortified",
		"description": "Increased damage resistance",
		"type": EffectType.BUFF,
		"duration": 60.0,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "defense",
		"color": Color(0.5, 0.5, 0.8),
		"damage_resistance": 0.25
	},
	"caffeinated": {
		"name": "Caffeinated",
		"description": "Energy drink boost",
		"type": EffectType.BUFF,
		"duration": 180.0,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "coffee",
		"color": Color(0.6, 0.4, 0.2),
		"stamina_regen_bonus": 0.5,
		"speed_bonus": 0.1
	},
	"stealthy": {
		"name": "Stealthy",
		"description": "Harder to detect",
		"type": EffectType.BUFF,
		"duration": 60.0,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "stealth",
		"color": Color(0.3, 0.3, 0.3),
		"detection_reduction": 0.5
	},
	
	# ========== STAT DEBUFFS ==========
	"weakened": {
		"name": "Weakened",
		"description": "Reduced damage output",
		"type": EffectType.DEBUFF,
		"duration": 15.0,
		"stack_behavior": StackBehavior.INTENSITY,
		"max_stacks": 3,
		"icon": "weak",
		"color": Color(0.5, 0.5, 0.5),
		"damage_reduction": 0.15  # Per stack
	},
	"vulnerable": {
		"name": "Vulnerable",
		"description": "Taking increased damage",
		"type": EffectType.DEBUFF,
		"duration": 10.0,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "vulnerable",
		"color": Color(0.8, 0.3, 0.3),
		"damage_taken_increase": 0.25
	},
	"exhausted": {
		"name": "Exhausted",
		"description": "Stamina regeneration halted",
		"type": EffectType.DEBUFF,
		"duration": 30.0,
		"stack_behavior": StackBehavior.DURATION,
		"max_stacks": 1,
		"icon": "exhausted",
		"color": Color(0.4, 0.4, 0.5),
		"stamina_regen_reduction": 1.0,  # No stamina regen
		"speed_reduction": 0.2
	},
	"food_poisoning": {
		"name": "Food Poisoning",
		"description": "Bad food making you sick",
		"type": EffectType.DEBUFF,
		"duration": 120.0,
		"tick_rate": 2.0,
		"damage_per_tick": 1,
		"stack_behavior": StackBehavior.NONE,
		"max_stacks": 1,
		"icon": "sick",
		"color": Color(0.5, 0.7, 0.3),
		"stamina_regen_reduction": 0.5,
		"hunger_drain_increase": 2.0,
		"cured_by": ["antibiotics", "charcoal"]
	},
	"dehydrated": {
		"name": "Dehydrated",
		"description": "Critically low on water",
		"type": EffectType.DEBUFF,
		"duration": -1,  # Until cured
		"stack_behavior": StackBehavior.NONE,
		"max_stacks": 1,
		"icon": "thirst",
		"color": Color(0.3, 0.5, 0.8),
		"stamina_max_reduction": 0.3,
		"health_regen_reduction": 1.0,
		"auto_remove_when": "thirst_above_25"
	},
	"starving": {
		"name": "Starving",
		"description": "Critically low on food",
		"type": EffectType.DEBUFF,
		"duration": -1,  # Until cured
		"stack_behavior": StackBehavior.NONE,
		"max_stacks": 1,
		"icon": "hunger",
		"color": Color(0.6, 0.4, 0.2),
		"stamina_max_reduction": 0.3,
		"damage_reduction": 0.2,
		"auto_remove_when": "hunger_above_25"
	}
}

# ============================================================================
# STATE
# ============================================================================

# target -> { effect_name: { stacks, timer, tick_timer, data } }
var active_effects: Dictionary = {}

# Cached stat modifiers per target
var stat_cache: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("status_effects")

func _process(delta: float) -> void:
	_update_all_effects(delta)

# ============================================================================
# EFFECT APPLICATION
# ============================================================================

func apply_effect(target: Node, effect_name: String, override_data: Dictionary = {}) -> bool:
	if not EFFECT_DEFINITIONS.has(effect_name):
		push_warning("Unknown effect: " + effect_name)
		return false
	
	var definition: Dictionary = EFFECT_DEFINITIONS[effect_name]
	var effect_data: Dictionary = definition.duplicate(true)
	
	# Apply overrides
	for key in override_data.keys():
		effect_data[key] = override_data[key]
	
	# Initialize target tracking
	if not active_effects.has(target):
		active_effects[target] = {}
	
	var target_effects: Dictionary = active_effects[target]
	
	# Check if already has effect
	if target_effects.has(effect_name):
		return _handle_stack(target, effect_name, effect_data)
	
	# Apply new effect
	target_effects[effect_name] = {
		"stacks": 1,
		"timer": effect_data.get("duration", 10.0),
		"tick_timer": 0.0,
		"data": effect_data
	}
	
	_invalidate_stat_cache(target)
	effect_applied.emit(target, effect_name, effect_data)
	
	# Notify target
	if target.has_method("on_status_effect_applied"):
		target.on_status_effect_applied(effect_name, effect_data)
	
	return true

func _handle_stack(target: Node, effect_name: String, effect_data: Dictionary) -> bool:
	var effect: Dictionary = active_effects[target][effect_name]
	var behavior: StackBehavior = effect_data.get("stack_behavior", StackBehavior.NONE)
	var max_stacks: int = effect_data.get("max_stacks", 1)
	
	match behavior:
		StackBehavior.NONE:
			return false  # Already has effect
		
		StackBehavior.DURATION:
			# Refresh duration
			effect.timer = effect_data.get("duration", 10.0)
			return true
		
		StackBehavior.INTENSITY:
			# Add stack
			if effect.stacks < max_stacks:
				effect.stacks += 1
				effect.timer = effect_data.get("duration", 10.0)
				_invalidate_stat_cache(target)
				effect_stacked.emit(target, effect_name, effect.stacks)
			else:
				# Max stacks, just refresh duration
				effect.timer = effect_data.get("duration", 10.0)
			return true
		
		StackBehavior.COUNT:
			# Multiple separate instances (handled differently)
			return true
	
	return false

func remove_effect(target: Node, effect_name: String) -> void:
	if not active_effects.has(target):
		return
	
	if not active_effects[target].has(effect_name):
		return
	
	active_effects[target].erase(effect_name)
	
	if active_effects[target].is_empty():
		active_effects.erase(target)
	
	_invalidate_stat_cache(target)
	effect_removed.emit(target, effect_name)
	
	if target.has_method("on_status_effect_removed"):
		target.on_status_effect_removed(effect_name)

func clear_effects(target: Node) -> void:
	if not active_effects.has(target):
		return
	
	var effect_names: Array = active_effects[target].keys()
	for effect_name in effect_names:
		remove_effect(target, effect_name)

func clear_debuffs(target: Node) -> void:
	if not active_effects.has(target):
		return
	
	var to_remove: Array = []
	for effect_name in active_effects[target].keys():
		var data: Dictionary = active_effects[target][effect_name].data
		var effect_type: EffectType = data.get("type", EffectType.DEBUFF)
		if effect_type in [EffectType.DAMAGE_OVER_TIME, EffectType.DEBUFF, EffectType.CROWD_CONTROL]:
			to_remove.append(effect_name)
	
	for effect_name in to_remove:
		remove_effect(target, effect_name)

# ============================================================================
# EFFECT UPDATES
# ============================================================================

func _update_all_effects(delta: float) -> void:
	var targets_to_clean: Array = []
	
	for target in active_effects.keys():
		if not is_instance_valid(target):
			targets_to_clean.append(target)
			continue
		
		_update_target_effects(target, delta)
	
	for target in targets_to_clean:
		active_effects.erase(target)
		stat_cache.erase(target)

func _update_target_effects(target: Node, delta: float) -> void:
	var to_remove: Array = []
	
	for effect_name in active_effects[target].keys():
		var effect: Dictionary = active_effects[target][effect_name]
		var data: Dictionary = effect.data
		
		# Update duration
		var duration: float = data.get("duration", -1)
		if duration > 0:
			effect.timer -= delta
			if effect.timer <= 0:
				to_remove.append(effect_name)
				continue
		
		# Process tick effects
		var tick_rate: float = data.get("tick_rate", 0)
		if tick_rate > 0:
			effect.tick_timer -= delta
			if effect.tick_timer <= 0:
				effect.tick_timer = tick_rate
				_process_tick(target, effect_name, effect)
		
		# Check auto-remove conditions
		var auto_remove: String = data.get("auto_remove_when", "")
		if not auto_remove.is_empty() and _check_auto_remove(target, auto_remove):
			to_remove.append(effect_name)
	
	for effect_name in to_remove:
		remove_effect(target, effect_name)

func _process_tick(target: Node, effect_name: String, effect: Dictionary) -> void:
	var data: Dictionary = effect.data
	var stacks: int = effect.stacks
	
	# Damage over time
	var damage_per_tick: int = data.get("damage_per_tick", 0)
	if damage_per_tick > 0:
		var total_damage := damage_per_tick * stacks
		var can_kill: bool = data.get("can_kill", true)
		
		if target.has_method("take_damage"):
			if can_kill:
				target.take_damage(total_damage, null)
			else:
				# Leave at 1 HP
				var current_health: float = target.get("current_health") if target.get("current_health") else 100
				var new_health := max(1, current_health - total_damage)
				if target.has_method("set_health"):
					target.set_health(new_health)
		
		effect_tick.emit(target, effect_name, total_damage)
	
	# Heal over time
	var heal_per_tick: int = data.get("heal_per_tick", 0)
	if heal_per_tick > 0:
		if target.has_method("heal"):
			target.heal(heal_per_tick * stacks)

func _check_auto_remove(target: Node, condition: String) -> bool:
	match condition:
		"thirst_above_25":
			var thirst: float = target.get("current_thirst") if target.get("current_thirst") else 100
			return thirst > 25
		"hunger_above_25":
			var hunger: float = target.get("current_hunger") if target.get("current_hunger") else 100
			return hunger > 25
	return false

# ============================================================================
# STAT MODIFIERS
# ============================================================================

func _invalidate_stat_cache(target: Node) -> void:
	stat_cache.erase(target)

func get_stat_modifiers(target: Node) -> Dictionary:
	if stat_cache.has(target):
		return stat_cache[target]
	
	var modifiers := {
		"damage_bonus": 0.0,
		"damage_reduction": 0.0,
		"damage_resistance": 0.0,
		"damage_taken_increase": 0.0,
		"speed_bonus": 0.0,
		"speed_reduction": 0.0,
		"stamina_regen_bonus": 0.0,
		"stamina_regen_reduction": 0.0,
		"stamina_max_reduction": 0.0,
		"health_regen_bonus": 0.0,
		"health_regen_reduction": 0.0,
		"detection_reduction": 0.0,
		"armor_reduction": 0.0,
		"max_health_reduction": 0.0,
		"disables_movement": false,
		"disables_actions": false,
		"disables_sprint": false,
		"disables_dodge": false,
		"force_flee": false
	}
	
	if not active_effects.has(target):
		stat_cache[target] = modifiers
		return modifiers
	
	for effect_name in active_effects[target].keys():
		var effect: Dictionary = active_effects[target][effect_name]
		var data: Dictionary = effect.data
		var stacks: int = effect.stacks
		
		# Additive modifiers (scaled by stacks)
		for key in ["damage_bonus", "damage_reduction", "damage_resistance",
					"damage_taken_increase", "speed_bonus", "speed_reduction",
					"stamina_regen_bonus", "stamina_regen_reduction", "stamina_max_reduction",
					"health_regen_bonus", "health_regen_reduction", "detection_reduction",
					"armor_reduction", "max_health_reduction"]:
			if data.has(key):
				modifiers[key] += data[key] * stacks
		
		# Boolean modifiers (OR)
		for key in ["disables_movement", "disables_actions", "disables_sprint",
					"disables_dodge", "force_flee"]:
			if data.get(key, false):
				modifiers[key] = true
	
	stat_cache[target] = modifiers
	return modifiers

# ============================================================================
# QUERIES
# ============================================================================

func has_effect(target: Node, effect_name: String) -> bool:
	if not active_effects.has(target):
		return false
	return active_effects[target].has(effect_name)

func get_effect_stacks(target: Node, effect_name: String) -> int:
	if not has_effect(target, effect_name):
		return 0
	return active_effects[target][effect_name].stacks

func get_effect_remaining_time(target: Node, effect_name: String) -> float:
	if not has_effect(target, effect_name):
		return 0.0
	return active_effects[target][effect_name].timer

func get_all_effects(target: Node) -> Array:
	if not active_effects.has(target):
		return []
	return active_effects[target].keys()

func get_effects_of_type(target: Node, effect_type: EffectType) -> Array:
	var result: Array = []
	if not active_effects.has(target):
		return result
	
	for effect_name in active_effects[target].keys():
		var data: Dictionary = active_effects[target][effect_name].data
		if data.get("type") == effect_type:
			result.append(effect_name)
	
	return result

func can_target_move(target: Node) -> bool:
	var mods := get_stat_modifiers(target)
	return not mods.disables_movement

func can_target_act(target: Node) -> bool:
	var mods := get_stat_modifiers(target)
	return not mods.disables_actions

# ============================================================================
# CURING
# ============================================================================

func cure_with_item(target: Node, item_id: String) -> Array:
	var cured: Array = []
	
	if not active_effects.has(target):
		return cured
	
	for effect_name in active_effects[target].keys():
		var data: Dictionary = active_effects[target][effect_name].data
		var cured_by: Array = data.get("cured_by", [])
		
		if item_id in cured_by:
			cured.append(effect_name)
	
	for effect_name in cured:
		remove_effect(target, effect_name)
	
	return cured

# ============================================================================
# UI HELPERS
# ============================================================================

func get_effect_display_data(target: Node) -> Array:
	var display_data: Array = []
	
	if not active_effects.has(target):
		return display_data
	
	for effect_name in active_effects[target].keys():
		var effect: Dictionary = active_effects[target][effect_name]
		var data: Dictionary = effect.data
		
		display_data.append({
			"name": data.get("name", effect_name),
			"description": data.get("description", ""),
			"icon": data.get("icon", "default"),
			"color": data.get("color", Color.WHITE),
			"stacks": effect.stacks,
			"time_remaining": effect.timer,
			"is_debuff": data.get("type") in [EffectType.DAMAGE_OVER_TIME, EffectType.DEBUFF, EffectType.CROWD_CONTROL]
		})
	
	return display_data
