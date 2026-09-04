extends CanvasLayer

## UIManager - Central controller for all game UI systems
## Handles UI state, transitions, and communication between UI panels

class_name UIManager

# ============================================================================
# SIGNALS
# ============================================================================

signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)
signal all_ui_closed

# ============================================================================
# CONSTANTS
# ============================================================================

const UI_SCENES := {
	"inventory": "res://scenes/ui/EnhancedInventoryUI.tscn",
	"crafting": "res://scenes/ui/EnhancedCraftingUI.tscn",
	"building": "res://scenes/ui/BuildingUI.tscn",
	"quest": "res://scenes/ui/QuestUI.tscn",
	"multiplayer": "res://scenes/ui/MultiplayerUI.tscn",
	"hud": "res://scenes/ui/HUD.tscn"
}

const UI_KEYBINDS := {
	"inventory": [KEY_TAB, KEY_I],
	"crafting": [KEY_C],
	"building": [KEY_B],
	"quest": [KEY_J, KEY_L],
	"multiplayer": [KEY_M],
	"map": [KEY_N]
}

# ============================================================================
# STATE
# ============================================================================

var loaded_uis: Dictionary = {}
var open_uis: Array[String] = []
var ui_stack: Array[String] = []  # For back navigation

var game_paused := false
var ui_input_locked := false

# ============================================================================
# REFERENCES
# ============================================================================

@onready var hud: HUD = null
@onready var inventory_ui: Control = null
@onready var crafting_ui: Control = null
@onready var building_ui: Control = null
@onready var quest_ui: Control = null
@onready var multiplayer_ui: Control = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("ui_manager")
	layer = 50  # Above game, below HUD
	
	# Preload critical UIs
	_preload_ui("hud")
	_preload_ui("inventory")
	_preload_ui("crafting")

func _preload_ui(ui_name: String) -> void:
	if loaded_uis.has(ui_name):
		return
	
	var path: String = UI_SCENES.get(ui_name, "")
	if path.is_empty():
		push_error("Unknown UI: " + ui_name)
		return
	
	if not ResourceLoader.exists(path):
		push_warning("UI scene not found: " + path)
		return
	
	var scene := load(path)
	if not scene:
		push_error("Failed to load UI: " + path)
		return
	
	var instance := scene.instantiate()
	instance.visible = false
	add_child(instance)
	
	loaded_uis[ui_name] = instance
	
	# Store specific references
	match ui_name:
		"hud":
			hud = instance
			hud.visible = true  # HUD always visible
		"inventory":
			inventory_ui = instance
			_connect_inventory_signals()
		"crafting":
			crafting_ui = instance
			_connect_crafting_signals()
		"building":
			building_ui = instance
		"quest":
			quest_ui = instance
		"multiplayer":
			multiplayer_ui = instance

func _connect_inventory_signals() -> void:
	if inventory_ui and inventory_ui.has_signal("inventory_closed"):
		inventory_ui.inventory_closed.connect(_on_ui_closed.bind("inventory"))
	if inventory_ui and inventory_ui.has_signal("inventory_opened"):
		inventory_ui.inventory_opened.connect(_on_ui_opened.bind("inventory"))

func _connect_crafting_signals() -> void:
	if crafting_ui and crafting_ui.has_signal("crafting_closed"):
		crafting_ui.crafting_closed.connect(_on_ui_closed.bind("crafting"))
	if crafting_ui and crafting_ui.has_signal("crafting_opened"):
		crafting_ui.crafting_opened.connect(_on_ui_opened.bind("crafting"))

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input(event: InputEvent) -> void:
	if ui_input_locked:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		# ESC to close current UI
		if event.keycode == KEY_ESCAPE:
			if not open_uis.is_empty():
				close_top_ui()
				get_viewport().set_input_as_handled()
				return
		
		# Check keybinds (only if not typing in a text field)
		if not _is_text_input_focused():
			for ui_name in UI_KEYBINDS:
				var keys: Array = UI_KEYBINDS[ui_name]
				if event.keycode in keys:
					toggle_ui(ui_name)
					get_viewport().set_input_as_handled()
					return

func _is_text_input_focused() -> bool:
	var focused := get_viewport().gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit

# ============================================================================
# UI MANAGEMENT
# ============================================================================

func toggle_ui(ui_name: String) -> void:
	if ui_name in open_uis:
		close_ui(ui_name)
	else:
		open_ui(ui_name)

func open_ui(ui_name: String) -> void:
	# Load if not loaded
	if not loaded_uis.has(ui_name):
		_preload_ui(ui_name)
	
	var ui: Control = loaded_uis.get(ui_name)
	if not ui:
		push_error("Failed to get UI: " + ui_name)
		return
	
	# Don't reopen if already open
	if ui_name in open_uis:
		return
	
	# Close conflicting UIs (e.g., can't have inventory and building open together)
	_handle_ui_conflicts(ui_name)
	
	# Open the UI
	if ui.has_method("open"):
		ui.open()
	else:
		ui.visible = true
	
	open_uis.append(ui_name)
	ui_stack.append(ui_name)
	
	ui_opened.emit(ui_name)
	_update_game_pause()

func close_ui(ui_name: String) -> void:
	var ui: Control = loaded_uis.get(ui_name)
	if not ui:
		return
	
	if ui.has_method("close"):
		ui.close()
	else:
		ui.visible = false
	
	open_uis.erase(ui_name)
	ui_stack.erase(ui_name)
	
	ui_closed.emit(ui_name)
	_update_game_pause()
	
	if open_uis.is_empty():
		all_ui_closed.emit()

func close_top_ui() -> void:
	if ui_stack.is_empty():
		return
	
	var top_ui: String = ui_stack.back()
	close_ui(top_ui)

func close_all_uis() -> void:
	var uis_to_close := open_uis.duplicate()
	for ui_name in uis_to_close:
		close_ui(ui_name)

func _handle_ui_conflicts(opening_ui: String) -> void:
	# Define mutually exclusive UIs
	var exclusive_groups := [
		["inventory", "crafting", "building", "quest", "multiplayer"]
	]
	
	for group in exclusive_groups:
		if opening_ui in group:
			for ui_name in group:
				if ui_name != opening_ui and ui_name in open_uis:
					close_ui(ui_name)

func _update_game_pause() -> void:
	# Pause game when certain UIs are open
	var pause_uis := ["inventory", "crafting", "quest", "multiplayer"]
	
	var should_pause := false
	for ui_name in pause_uis:
		if ui_name in open_uis:
			should_pause = true
			break
	
	if should_pause != game_paused:
		game_paused = should_pause
		get_tree().paused = should_pause

func _on_ui_opened(ui_name: String) -> void:
	if ui_name not in open_uis:
		open_uis.append(ui_name)
		ui_stack.append(ui_name)
	ui_opened.emit(ui_name)
	_update_game_pause()

func _on_ui_closed(ui_name: String) -> void:
	open_uis.erase(ui_name)
	ui_stack.erase(ui_name)
	ui_closed.emit(ui_name)
	_update_game_pause()

# ============================================================================
# HUD METHODS
# ============================================================================

func show_notification(text: String, type: String = "info") -> void:
	if hud and hud.has_method("show_notification"):
		hud.show_notification(text, type)

func show_item_pickup(item_name: String, count: int = 1) -> void:
	if hud and hud.has_method("show_item_pickup"):
		hud.show_item_pickup(item_name, count)

func show_damage_number(amount: int, position: Vector2) -> void:
	if hud and hud.has_method("show_damage_number"):
		hud.show_damage_number(amount, position)

func update_health(current: float, maximum: float) -> void:
	if hud and hud.has_method("_on_health_changed"):
		hud._on_health_changed(current, maximum)

func update_stamina(current: float, maximum: float) -> void:
	if hud and hud.has_method("_on_stamina_changed"):
		hud._on_stamina_changed(current, maximum)

func update_hunger(value: float) -> void:
	if hud and hud.has_method("_on_hunger_changed"):
		hud._on_hunger_changed(value)

func update_thirst(value: float) -> void:
	if hud and hud.has_method("_on_thirst_changed"):
		hud._on_thirst_changed(value)

func set_hotbar_item(index: int, item_data: Dictionary) -> void:
	if hud and hud.has_method("set_hotbar_item"):
		hud.set_hotbar_item(index, item_data)

func update_minimap_position(pos: Vector2) -> void:
	if hud and hud.has_method("update_minimap_position"):
		hud.update_minimap_position(pos)

func update_minimap_zone(zone_name: String) -> void:
	if hud and hud.has_method("update_minimap_zone"):
		hud.update_minimap_zone(zone_name)

func update_time_display(day: int, hour: int, minute: int, is_night: bool) -> void:
	if hud and hud.has_method("update_time_display"):
		hud.update_time_display(day, hour, minute, is_night)

# ============================================================================
# QUEST UI METHODS
# ============================================================================

func update_quest_progress(quest_id: String, objective_index: int, new_value: int) -> void:
	if not loaded_uis.has("quest"):
		return
	
	var quest := loaded_uis["quest"]
	if quest and quest.has_method("update_quest_progress"):
		quest.update_quest_progress(quest_id, objective_index, new_value)

func show_quest_complete(quest_name: String) -> void:
	show_notification("✅ Quest Complete: " + quest_name, "success")

# ============================================================================
# INVENTORY METHODS
# ============================================================================

func refresh_inventory() -> void:
	if inventory_ui and inventory_ui.has_method("refresh"):
		inventory_ui.refresh()

# ============================================================================
# CRAFTING METHODS
# ============================================================================

func set_craft_station(station_id: String) -> void:
	if not loaded_uis.has("crafting"):
		_preload_ui("crafting")
	
	var crafting: Control = loaded_uis.get("crafting")
	if crafting and crafting.has_method("set_current_station"):
		crafting.set_current_station(station_id)

# ============================================================================
# BUILDING METHODS
# ============================================================================

func enter_build_mode() -> void:
	open_ui("building")

func exit_build_mode() -> void:
	close_ui("building")

# ============================================================================
# STATE QUERIES
# ============================================================================

func is_any_ui_open() -> bool:
	return not open_uis.is_empty()

func is_ui_open(ui_name: String) -> bool:
	return ui_name in open_uis

func get_open_uis() -> Array[String]:
	return open_uis.duplicate()

func is_game_paused() -> bool:
	return game_paused

# ============================================================================
# UTILITY
# ============================================================================

func lock_input() -> void:
	ui_input_locked = true

func unlock_input() -> void:
	ui_input_locked = false
