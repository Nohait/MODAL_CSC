extends Node
class_name TutorialSystemClass
## Comprehensive tutorial and onboarding system for teaching game mechanics
## Manages tutorial steps, hints, tooltips, and player progression tracking

signal tutorial_started(tutorial_id: String)
signal tutorial_step_started(tutorial_id: String, step_index: int)
signal tutorial_step_completed(tutorial_id: String, step_index: int)
signal tutorial_completed(tutorial_id: String)
signal tutorial_skipped(tutorial_id: String)
signal hint_shown(hint_id: String)
signal hint_dismissed(hint_id: String)
signal objective_highlighted(node_path: String)

# ============================================================================
# TUTORIAL CONFIGURATION
# ============================================================================

enum TutorialType {
	MANDATORY,  # Must complete to progress
	OPTIONAL,   # Can skip anytime
	CONTEXTUAL, # Triggered by player actions
}

enum TriggerType {
	MANUAL,         # Triggered by code
	ON_ENTER_AREA,  # When player enters area
	ON_FIRST_TIME,  # First time doing something
	ON_ITEM_PICKUP, # When picking up specific item
	ON_LEVEL,       # When reaching certain level
	ON_EVENT,       # When event occurs
}

enum StepType {
	TEXT,           # Show text popup
	HIGHLIGHT,      # Highlight UI element
	INTERACT,       # Wait for interaction
	MOVE_TO,        # Move to location
	PERFORM_ACTION, # Do specific action
	WAIT,           # Wait for time
	CHOICE,         # Player makes choice
	CINEMATIC,      # Play cutscene
}

enum HighlightStyle {
	GLOW,
	PULSE,
	ARROW,
	CIRCLE,
	RECTANGLE,
}

const MAX_HINTS_ON_SCREEN := 3
const HINT_DISPLAY_TIME := 8.0
const HINT_COOLDOWN := 60.0  # Don't repeat same hint too soon

# Tutorial definitions
const TUTORIAL_DEFINITIONS := {
	"basic_movement": {
		"name": "Basic Movement",
		"description": "Learn how to move around the world",
		"type": TutorialType.MANDATORY,
		"trigger": TriggerType.MANUAL,
		"steps": [
			{
				"type": StepType.TEXT,
				"title": "Welcome, Survivor",
				"message": "The world has changed. To survive, you must learn the basics.",
				"duration": 0,  # 0 = wait for input
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Movement",
				"message": "Use WASD to move around.",
				"action": "move_any",
				"highlight_keys": ["W", "A", "S", "D"],
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Sprint",
				"message": "Hold SHIFT while moving to sprint.",
				"action": "sprint",
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Jump",
				"message": "Press SPACE to jump over obstacles.",
				"action": "jump",
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Crouch",
				"message": "Press CTRL to crouch and move silently.",
				"action": "crouch",
			},
			{
				"type": StepType.TEXT,
				"title": "Great!",
				"message": "You've mastered basic movement. Stay mobile to survive!",
				"duration": 3.0,
			},
		],
	},
	
	"basic_combat": {
		"name": "Combat Basics",
		"description": "Learn how to fight and survive encounters",
		"type": TutorialType.MANDATORY,
		"trigger": TriggerType.ON_FIRST_TIME,
		"trigger_data": "first_enemy_spotted",
		"steps": [
			{
				"type": StepType.TEXT,
				"title": "Danger!",
				"message": "An enemy is nearby. Be ready to fight!",
				"pause_game": true,
			},
			{
				"type": StepType.HIGHLIGHT,
				"title": "Your Weapon",
				"message": "You're equipped with a weapon. Use it wisely.",
				"highlight_path": "HUD/WeaponSlot",
				"style": HighlightStyle.GLOW,
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Attack",
				"message": "Click LEFT MOUSE BUTTON to attack.",
				"action": "primary_fire",
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Aim",
				"message": "Hold RIGHT MOUSE BUTTON to aim for better accuracy.",
				"action": "secondary_fire",
			},
			{
				"type": StepType.TEXT,
				"title": "Stay Alert",
				"message": "Watch your health. Retreat when injured!",
				"duration": 3.0,
			},
		],
	},
	
	"inventory_basics": {
		"name": "Inventory Management",
		"description": "Learn how to manage your items",
		"type": TutorialType.OPTIONAL,
		"trigger": TriggerType.ON_FIRST_TIME,
		"trigger_data": "first_item_pickup",
		"steps": [
			{
				"type": StepType.TEXT,
				"title": "Item Acquired!",
				"message": "You picked up an item. Let's learn about inventory.",
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Open Inventory",
				"message": "Press TAB to open your inventory.",
				"action": "inventory",
			},
			{
				"type": StepType.HIGHLIGHT,
				"title": "Your Items",
				"message": "Here are all your items. Drag to rearrange.",
				"highlight_path": "InventoryUI/ItemGrid",
				"style": HighlightStyle.RECTANGLE,
			},
			{
				"type": StepType.HIGHLIGHT,
				"title": "Equipment Slots",
				"message": "Drag items here to equip them.",
				"highlight_path": "InventoryUI/EquipmentSlots",
				"style": HighlightStyle.GLOW,
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Close Inventory",
				"message": "Press TAB again to close.",
				"action": "inventory",
			},
		],
	},
	
	"crafting_intro": {
		"name": "Crafting System",
		"description": "Learn to craft items for survival",
		"type": TutorialType.OPTIONAL,
		"trigger": TriggerType.ON_FIRST_TIME,
		"trigger_data": "crafting_opened",
		"steps": [
			{
				"type": StepType.TEXT,
				"title": "Crafting",
				"message": "Crafting lets you create tools, weapons, and supplies.",
			},
			{
				"type": StepType.HIGHLIGHT,
				"title": "Recipe List",
				"message": "Available recipes are shown here. Grayed out means you lack materials.",
				"highlight_path": "CraftingUI/RecipeList",
				"style": HighlightStyle.RECTANGLE,
			},
			{
				"type": StepType.HIGHLIGHT,
				"title": "Required Materials",
				"message": "Check what materials you need for each recipe.",
				"highlight_path": "CraftingUI/MaterialList",
				"style": HighlightStyle.GLOW,
			},
			{
				"type": StepType.HIGHLIGHT,
				"title": "Craft Button",
				"message": "Click here to craft when you have the materials.",
				"highlight_path": "CraftingUI/CraftButton",
				"style": HighlightStyle.PULSE,
			},
		],
	},
	
	"base_building": {
		"name": "Base Building",
		"description": "Learn to build and upgrade your base",
		"type": TutorialType.OPTIONAL,
		"trigger": TriggerType.ON_ENTER_AREA,
		"trigger_data": "base_area",
		"steps": [
			{
				"type": StepType.TEXT,
				"title": "Your Base",
				"message": "This is your home base. Build structures to survive.",
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Build Menu",
				"message": "Press B to open the build menu.",
				"action": "build_menu",
			},
			{
				"type": StepType.TEXT,
				"title": "Structures",
				"message": "Build walls, floors, and defenses. Upgrade them for more protection.",
				"duration": 4.0,
			},
			{
				"type": StepType.TEXT,
				"title": "Workstations",
				"message": "Build workstations to unlock advanced crafting recipes.",
				"duration": 4.0,
			},
		],
	},
	
	"vehicle_intro": {
		"name": "Vehicle Tutorial",
		"description": "Learn to use vehicles for travel",
		"type": TutorialType.CONTEXTUAL,
		"trigger": TriggerType.ON_FIRST_TIME,
		"trigger_data": "vehicle_entered",
		"steps": [
			{
				"type": StepType.TEXT,
				"title": "Vehicle Controls",
				"message": "Use WASD to drive. Hold SHIFT for boost.",
			},
			{
				"type": StepType.HIGHLIGHT,
				"title": "Fuel Gauge",
				"message": "Keep an eye on fuel. You'll need gas cans to refuel.",
				"highlight_path": "HUD/VehicleUI/FuelGauge",
				"style": HighlightStyle.GLOW,
			},
			{
				"type": StepType.TEXT,
				"title": "Exit Vehicle",
				"message": "Press E to exit the vehicle.",
				"duration": 3.0,
			},
		],
	},
	
	"coop_intro": {
		"name": "Co-op Features",
		"description": "Learn multiplayer cooperative features",
		"type": TutorialType.OPTIONAL,
		"trigger": TriggerType.ON_EVENT,
		"trigger_data": "multiplayer_joined",
		"steps": [
			{
				"type": StepType.TEXT,
				"title": "Playing Together",
				"message": "You're now playing with others. Teamwork is key!",
			},
			{
				"type": StepType.PERFORM_ACTION,
				"title": "Ping System",
				"message": "Press MIDDLE MOUSE to ping locations for teammates.",
				"action": "ping",
			},
			{
				"type": StepType.TEXT,
				"title": "Reviving",
				"message": "If a teammate goes down, get close and hold E to revive them.",
				"duration": 4.0,
			},
			{
				"type": StepType.TEXT,
				"title": "Proximity Bonus",
				"message": "Stay near teammates for combat bonuses!",
				"duration": 3.0,
			},
		],
	},
}

# Contextual hints that appear based on game state
const HINT_DEFINITIONS := {
	"low_health": {
		"message": "Your health is low! Use a bandage or medkit.",
		"condition": "health_below_25",
		"priority": 10,
	},
	"low_stamina": {
		"message": "Out of stamina. Stop sprinting to recover.",
		"condition": "stamina_below_10",
		"priority": 5,
	},
	"inventory_full": {
		"message": "Inventory full! Drop or store items to make room.",
		"condition": "inventory_full",
		"priority": 8,
	},
	"weapon_empty": {
		"message": "Weapon empty! Press R to reload.",
		"condition": "ammo_zero",
		"priority": 9,
	},
	"night_approaching": {
		"message": "Night is coming. Find shelter or prepare for danger.",
		"condition": "time_near_night",
		"priority": 6,
	},
	"horde_warning": {
		"message": "Horde activity detected nearby!",
		"condition": "horde_spawning",
		"priority": 10,
	},
	"first_death": {
		"message": "You died but respawned. Your items dropped at death location.",
		"condition": "first_death",
		"priority": 10,
		"once": true,
	},
	"durability_low": {
		"message": "Your weapon is about to break! Repair it at a workbench.",
		"condition": "weapon_durability_low",
		"priority": 7,
	},
	"encumbered": {
		"message": "You're carrying too much weight. Move speed reduced.",
		"condition": "encumbered",
		"priority": 6,
	},
	"thirst_warning": {
		"message": "You're getting thirsty. Find clean water.",
		"condition": "thirst_high",
		"priority": 7,
	},
	"hunger_warning": {
		"message": "You're getting hungry. Find food.",
		"condition": "hunger_high",
		"priority": 7,
	},
}


# ============================================================================
# STATE
# ============================================================================

var _completed_tutorials: Array[String] = []
var _active_tutorial: String = ""
var _current_step_index: int = -1
var _step_timer: float = 0.0
var _is_waiting_for_action: bool = false
var _expected_action: String = ""
var _active_hints: Array[Dictionary] = []
var _hint_cooldowns: Dictionary = {}  # hint_id -> time remaining
var _triggered_once_hints: Array[String] = []
var _tutorial_paused: bool = false
var _skip_all: bool = false
var _highlight_nodes: Array[Node] = []


func _ready() -> void:
	# Connect to input for action detection
	set_process_input(true)


func _process(delta: float) -> void:
	_update_step_timer(delta)
	_update_hint_cooldowns(delta)
	_update_active_hints(delta)


func _input(event: InputEvent) -> void:
	if _is_waiting_for_action and event.is_action_pressed(_expected_action):
		_complete_current_step()


# ============================================================================
# TUTORIAL MANAGEMENT
# ============================================================================

func start_tutorial(tutorial_id: String) -> Dictionary:
	if tutorial_id not in TUTORIAL_DEFINITIONS:
		return {"success": false, "error": "Unknown tutorial: " + tutorial_id}
	
	if tutorial_id in _completed_tutorials:
		return {"success": false, "error": "Tutorial already completed"}
	
	if _active_tutorial != "":
		return {"success": false, "error": "Another tutorial is active"}
	
	if _skip_all:
		return {"success": false, "error": "Tutorials disabled"}
	
	var tutorial: Dictionary = TUTORIAL_DEFINITIONS[tutorial_id]
	
	_active_tutorial = tutorial_id
	_current_step_index = -1
	
	emit_signal("tutorial_started", tutorial_id)
	
	_advance_step()
	
	return {"success": true}


func skip_tutorial() -> void:
	if _active_tutorial == "":
		return
	
	var tutorial: Dictionary = TUTORIAL_DEFINITIONS[_active_tutorial]
	
	# Only allow skipping optional tutorials
	if tutorial["type"] == TutorialType.MANDATORY:
		return
	
	_clear_highlights()
	emit_signal("tutorial_skipped", _active_tutorial)
	
	_active_tutorial = ""
	_current_step_index = -1
	_is_waiting_for_action = false


func skip_all_tutorials() -> void:
	_skip_all = true
	skip_tutorial()


func enable_tutorials() -> void:
	_skip_all = false


func _advance_step() -> void:
	_current_step_index += 1
	
	var tutorial: Dictionary = TUTORIAL_DEFINITIONS[_active_tutorial]
	var steps: Array = tutorial["steps"]
	
	if _current_step_index >= steps.size():
		_complete_tutorial()
		return
	
	var step: Dictionary = steps[_current_step_index]
	
	emit_signal("tutorial_step_started", _active_tutorial, _current_step_index)
	
	_process_step(step)


func _process_step(step: Dictionary) -> void:
	_clear_highlights()
	_is_waiting_for_action = false
	_step_timer = 0.0
	
	match step["type"]:
		StepType.TEXT:
			var duration: float = step.get("duration", 0.0)
			if duration > 0:
				_step_timer = duration
			else:
				_is_waiting_for_action = true
				_expected_action = "ui_accept"  # Any confirm input
			
			if step.get("pause_game", false):
				get_tree().paused = true
				_tutorial_paused = true
		
		StepType.HIGHLIGHT:
			var path: String = step.get("highlight_path", "")
			if path != "":
				_highlight_node(path, step.get("style", HighlightStyle.GLOW))
			
			_is_waiting_for_action = true
			_expected_action = "ui_accept"
		
		StepType.INTERACT:
			_is_waiting_for_action = true
			_expected_action = "interact"
		
		StepType.MOVE_TO:
			# Would check player position against target
			_is_waiting_for_action = true
			_expected_action = "move_any"
		
		StepType.PERFORM_ACTION:
			_is_waiting_for_action = true
			_expected_action = step.get("action", "ui_accept")
		
		StepType.WAIT:
			_step_timer = step.get("duration", 2.0)
		
		StepType.CHOICE:
			# Would show choice UI
			pass
		
		StepType.CINEMATIC:
			# Would play cutscene
			_step_timer = step.get("duration", 5.0)


func _update_step_timer(delta: float) -> void:
	if _active_tutorial == "" or _is_waiting_for_action:
		return
	
	if _step_timer > 0:
		_step_timer -= delta
		if _step_timer <= 0:
			_complete_current_step()


func _complete_current_step() -> void:
	if _tutorial_paused:
		get_tree().paused = false
		_tutorial_paused = false
	
	emit_signal("tutorial_step_completed", _active_tutorial, _current_step_index)
	
	_advance_step()


func _complete_tutorial() -> void:
	if _active_tutorial not in _completed_tutorials:
		_completed_tutorials.append(_active_tutorial)
	
	_clear_highlights()
	emit_signal("tutorial_completed", _active_tutorial)
	
	_active_tutorial = ""
	_current_step_index = -1
	_is_waiting_for_action = false


# ============================================================================
# HIGHLIGHTING
# ============================================================================

func _highlight_node(path: String, style: int) -> void:
	var node := get_node_or_null(path)
	if node == null:
		# Try finding in scene tree
		node = get_tree().current_scene.get_node_or_null(path)
	
	if node == null:
		push_warning("TutorialSystem: Cannot find node to highlight: " + path)
		return
	
	_highlight_nodes.append(node)
	emit_signal("objective_highlighted", path)
	
	# The actual highlighting would be done by the UI/shader system
	# Store the node reference for the highlight manager to use


func _clear_highlights() -> void:
	for node in _highlight_nodes:
		if is_instance_valid(node):
			# Clear highlight effect
			pass
	_highlight_nodes.clear()


# ============================================================================
# CONTEXTUAL HINTS
# ============================================================================

func show_hint(hint_id: String) -> void:
	if hint_id not in HINT_DEFINITIONS:
		return
	
	# Check cooldown
	if _hint_cooldowns.get(hint_id, 0.0) > 0:
		return
	
	var hint: Dictionary = HINT_DEFINITIONS[hint_id]
	
	# Check if already triggered (for once-only hints)
	if hint.get("once", false) and hint_id in _triggered_once_hints:
		return
	
	# Check if already showing
	for active in _active_hints:
		if active["id"] == hint_id:
			return
	
	# Check max hints
	if _active_hints.size() >= MAX_HINTS_ON_SCREEN:
		# Remove lowest priority hint
		var lowest_priority := 999
		var lowest_index := 0
		for i in range(_active_hints.size()):
			if _active_hints[i]["priority"] < lowest_priority:
				lowest_priority = _active_hints[i]["priority"]
				lowest_index = i
		
		if hint.get("priority", 0) <= lowest_priority:
			return  # New hint is lower priority
		
		dismiss_hint(_active_hints[lowest_index]["id"])
	
	var hint_data := {
		"id": hint_id,
		"message": hint["message"],
		"priority": hint.get("priority", 0),
		"timer": HINT_DISPLAY_TIME,
	}
	
	_active_hints.append(hint_data)
	
	if hint.get("once", false):
		_triggered_once_hints.append(hint_id)
	
	_hint_cooldowns[hint_id] = HINT_COOLDOWN
	
	emit_signal("hint_shown", hint_id)


func dismiss_hint(hint_id: String) -> void:
	for i in range(_active_hints.size() - 1, -1, -1):
		if _active_hints[i]["id"] == hint_id:
			_active_hints.remove_at(i)
			emit_signal("hint_dismissed", hint_id)
			return


func _update_active_hints(delta: float) -> void:
	for i in range(_active_hints.size() - 1, -1, -1):
		_active_hints[i]["timer"] -= delta
		if _active_hints[i]["timer"] <= 0:
			var hint_id: String = _active_hints[i]["id"]
			_active_hints.remove_at(i)
			emit_signal("hint_dismissed", hint_id)


func _update_hint_cooldowns(delta: float) -> void:
	var to_remove: Array = []
	for hint_id in _hint_cooldowns:
		_hint_cooldowns[hint_id] -= delta
		if _hint_cooldowns[hint_id] <= 0:
			to_remove.append(hint_id)
	
	for hint_id in to_remove:
		_hint_cooldowns.erase(hint_id)


# ============================================================================
# TRIGGERS
# ============================================================================

func trigger_event(event_name: String) -> void:
	# Check if any tutorial should trigger
	for tutorial_id in TUTORIAL_DEFINITIONS:
		if tutorial_id in _completed_tutorials:
			continue
		
		var tutorial: Dictionary = TUTORIAL_DEFINITIONS[tutorial_id]
		
		if tutorial["trigger"] == TriggerType.ON_FIRST_TIME:
			if tutorial.get("trigger_data", "") == event_name:
				start_tutorial(tutorial_id)
				return
		
		elif tutorial["trigger"] == TriggerType.ON_EVENT:
			if tutorial.get("trigger_data", "") == event_name:
				start_tutorial(tutorial_id)
				return


func trigger_area_entered(area_name: String) -> void:
	for tutorial_id in TUTORIAL_DEFINITIONS:
		if tutorial_id in _completed_tutorials:
			continue
		
		var tutorial: Dictionary = TUTORIAL_DEFINITIONS[tutorial_id]
		
		if tutorial["trigger"] == TriggerType.ON_ENTER_AREA:
			if tutorial.get("trigger_data", "") == area_name:
				start_tutorial(tutorial_id)
				return


func trigger_item_picked_up(item_id: String) -> void:
	for tutorial_id in TUTORIAL_DEFINITIONS:
		if tutorial_id in _completed_tutorials:
			continue
		
		var tutorial: Dictionary = TUTORIAL_DEFINITIONS[tutorial_id]
		
		if tutorial["trigger"] == TriggerType.ON_ITEM_PICKUP:
			var trigger_items: Array = tutorial.get("trigger_data", [])
			if item_id in trigger_items or trigger_items.is_empty():
				start_tutorial(tutorial_id)
				return


func trigger_level_reached(level: int) -> void:
	for tutorial_id in TUTORIAL_DEFINITIONS:
		if tutorial_id in _completed_tutorials:
			continue
		
		var tutorial: Dictionary = TUTORIAL_DEFINITIONS[tutorial_id]
		
		if tutorial["trigger"] == TriggerType.ON_LEVEL:
			if tutorial.get("trigger_data", 0) <= level:
				start_tutorial(tutorial_id)
				return


# ============================================================================
# CONDITION CHECKING (for hints)
# ============================================================================

func check_conditions(player_data: Dictionary) -> void:
	# Check all hint conditions based on player state
	
	if player_data.get("health_percent", 1.0) < 0.25:
		show_hint("low_health")
	
	if player_data.get("stamina_percent", 1.0) < 0.1:
		show_hint("low_stamina")
	
	if player_data.get("inventory_full", false):
		show_hint("inventory_full")
	
	if player_data.get("current_ammo", 1) == 0:
		show_hint("weapon_empty")
	
	if player_data.get("encumbered", false):
		show_hint("encumbered")
	
	if player_data.get("weapon_durability", 1.0) < 0.15:
		show_hint("durability_low")
	
	if player_data.get("thirst", 0.0) > 0.75:
		show_hint("thirst_warning")
	
	if player_data.get("hunger", 0.0) > 0.75:
		show_hint("hunger_warning")


# ============================================================================
# QUERIES
# ============================================================================

func is_tutorial_active() -> bool:
	return _active_tutorial != ""


func get_active_tutorial() -> String:
	return _active_tutorial


func get_current_step() -> Dictionary:
	if _active_tutorial == "" or _current_step_index < 0:
		return {}
	
	var tutorial: Dictionary = TUTORIAL_DEFINITIONS[_active_tutorial]
	var steps: Array = tutorial["steps"]
	
	if _current_step_index >= steps.size():
		return {}
	
	return steps[_current_step_index]


func get_current_step_index() -> int:
	return _current_step_index


func get_total_steps() -> int:
	if _active_tutorial == "":
		return 0
	return TUTORIAL_DEFINITIONS[_active_tutorial]["steps"].size()


func is_tutorial_completed(tutorial_id: String) -> bool:
	return tutorial_id in _completed_tutorials


func get_completed_tutorials() -> Array[String]:
	return _completed_tutorials.duplicate()


func get_active_hints() -> Array[Dictionary]:
	return _active_hints.duplicate()


func get_tutorial_progress() -> float:
	var total := TUTORIAL_DEFINITIONS.size()
	var completed := _completed_tutorials.size()
	return float(completed) / float(total) if total > 0 else 1.0


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"completed_tutorials": _completed_tutorials.duplicate(),
		"triggered_once_hints": _triggered_once_hints.duplicate(),
		"skip_all": _skip_all,
	}


func load_data(data: Dictionary) -> void:
	_completed_tutorials.clear()
	for tutorial_id in data.get("completed_tutorials", []):
		_completed_tutorials.append(tutorial_id)
	
	_triggered_once_hints.clear()
	for hint_id in data.get("triggered_once_hints", []):
		_triggered_once_hints.append(hint_id)
	
	_skip_all = data.get("skip_all", false)


# ============================================================================
# DEBUG
# ============================================================================

func reset_tutorials() -> void:
	_completed_tutorials.clear()
	_triggered_once_hints.clear()
	_skip_all = false


func complete_all_tutorials() -> void:
	for tutorial_id in TUTORIAL_DEFINITIONS:
		if tutorial_id not in _completed_tutorials:
			_completed_tutorials.append(tutorial_id)
