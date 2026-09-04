extends Control

## EnhancedCraftingUI - LDOE-style crafting interface with categories, queue, and animations
## Features recipe learning, resource requirements, and crafting progress

class_name EnhancedCraftingUI

# ============================================================================
# SIGNALS
# ============================================================================

signal crafting_opened
signal crafting_closed
signal recipe_selected(recipe_id: String)
signal craft_started(recipe_id: String)
signal craft_completed(recipe_id: String)
signal craft_cancelled(recipe_id: String)

# ============================================================================
# CONSTANTS
# ============================================================================

const CATEGORIES := {
	"all": {"name": "All", "icon": "📦"},
	"weapons": {"name": "Weapons", "icon": "⚔️"},
	"armor": {"name": "Armor", "icon": "🛡️"},
	"tools": {"name": "Tools", "icon": "🔧"},
	"building": {"name": "Building", "icon": "🏠"},
	"consumables": {"name": "Food & Meds", "icon": "🍖"},
	"ammo": {"name": "Ammunition", "icon": "🔫"},
	"materials": {"name": "Materials", "icon": "🧱"}
}

const CRAFT_STATIONS := {
	"hand": "Hand Crafting",
	"workbench_basic": "Basic Workbench",
	"workbench_advanced": "Advanced Workbench",
	"forge": "Forge",
	"chemistry_station": "Chemistry Station",
	"campfire": "Campfire",
	"tanning_rack": "Tanning Rack"
}

# ============================================================================
# STATE
# ============================================================================

var is_open := false
var current_category := "all"
var selected_recipe_id := ""
var craft_queue: Array[Dictionary] = []
var current_craft: Dictionary = {}
var craft_progress := 0.0
var available_station := "hand"

var all_recipes: Dictionary = {}
var learned_recipes: Array[String] = []
var favorite_recipes: Array[String] = []

# ============================================================================
# REFERENCES
# ============================================================================

@onready var background: ColorRect = $Background
@onready var main_panel: PanelContainer = $MainPanel
@onready var category_list: VBoxContainer = $MainPanel/Content/LeftPanel/Categories
@onready var recipe_scroll: ScrollContainer = $MainPanel/Content/CenterPanel/RecipeScroll
@onready var recipe_grid: GridContainer = $MainPanel/Content/CenterPanel/RecipeScroll/RecipeGrid
@onready var details_panel: VBoxContainer = $MainPanel/Content/RightPanel/Details
@onready var requirements_list: VBoxContainer = $MainPanel/Content/RightPanel/Requirements
@onready var craft_button: Button = $MainPanel/Content/RightPanel/CraftButton
@onready var queue_panel: VBoxContainer = $MainPanel/Content/QueuePanel
@onready var search_box: LineEdit = $MainPanel/Content/CenterPanel/SearchBox
@onready var progress_bar: ProgressBar = $MainPanel/Content/RightPanel/ProgressBar

var recipe_buttons: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("crafting_ui")
	_build_ui()
	_load_recipes()
	_connect_signals()
	hide()

func _build_ui() -> void:
	if not has_node("Background"):
		_create_ui_structure()
	
	_populate_categories()

func _create_ui_structure() -> void:
	# Background
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.75)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)
	
	# Main panel
	main_panel = PanelContainer.new()
	main_panel.name = "MainPanel"
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(1000, 650)
	main_panel.position = -main_panel.custom_minimum_size / 2
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.15, 0.98)
	panel_style.set_corner_radius_all(8)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.3, 0.25, 0.2)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(main_panel)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.name = "Content"
	main_panel.add_child(main_vbox)
	
	# Header
	var header := _create_header()
	main_vbox.add_child(header)
	
	# Content area
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 15)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)
	
	# Left panel - Categories
	var left_panel := PanelContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.custom_minimum_size.x = 160
	content_hbox.add_child(left_panel)
	
	var left_vbox := VBoxContainer.new()
	left_panel.add_child(left_vbox)
	
	var cat_label := Label.new()
	cat_label.text = "CATEGORIES"
	cat_label.add_theme_font_size_override("font_size", 14)
	left_vbox.add_child(cat_label)
	
	category_list = VBoxContainer.new()
	category_list.name = "Categories"
	left_vbox.add_child(category_list)
	
	# Center panel - Recipe grid
	var center_panel := VBoxContainer.new()
	center_panel.name = "CenterPanel"
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(center_panel)
	
	search_box = LineEdit.new()
	search_box.name = "SearchBox"
	search_box.placeholder_text = "🔍 Search recipes..."
	search_box.custom_minimum_size.y = 32
	center_panel.add_child(search_box)
	
	recipe_scroll = ScrollContainer.new()
	recipe_scroll.name = "RecipeScroll"
	recipe_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_panel.add_child(recipe_scroll)
	
	recipe_grid = GridContainer.new()
	recipe_grid.name = "RecipeGrid"
	recipe_grid.columns = 5
	recipe_grid.add_theme_constant_override("h_separation", 8)
	recipe_grid.add_theme_constant_override("v_separation", 8)
	recipe_scroll.add_child(recipe_grid)
	
	# Right panel - Details
	var right_panel := PanelContainer.new()
	right_panel.name = "RightPanel"
	right_panel.custom_minimum_size.x = 280
	var right_style := StyleBoxFlat.new()
	right_style.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	right_style.set_corner_radius_all(6)
	right_panel.add_theme_stylebox_override("panel", right_style)
	content_hbox.add_child(right_panel)
	
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 10)
	right_panel.add_child(right_vbox)
	
	details_panel = VBoxContainer.new()
	details_panel.name = "Details"
	right_vbox.add_child(details_panel)
	
	var req_label := Label.new()
	req_label.text = "REQUIREMENTS"
	req_label.add_theme_font_size_override("font_size", 12)
	right_vbox.add_child(req_label)
	
	requirements_list = VBoxContainer.new()
	requirements_list.name = "Requirements"
	requirements_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(requirements_list)
	
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size.y = 24
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.visible = false
	right_vbox.add_child(progress_bar)
	
	craft_button = Button.new()
	craft_button.name = "CraftButton"
	craft_button.text = "CRAFT"
	craft_button.custom_minimum_size.y = 48
	craft_button.disabled = true
	right_vbox.add_child(craft_button)
	
	# Queue panel at bottom
	var queue_container := PanelContainer.new()
	queue_container.name = "QueuePanel"
	queue_container.custom_minimum_size.y = 80
	main_vbox.add_child(queue_container)
	
	var queue_hbox := HBoxContainer.new()
	queue_container.add_child(queue_hbox)
	
	var queue_label := Label.new()
	queue_label.text = "QUEUE: "
	queue_hbox.add_child(queue_label)
	
	queue_panel = VBoxContainer.new()
	queue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	queue_hbox.add_child(queue_panel)

func _create_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 50
	
	var title := Label.new()
	title.text = "⚒️ CRAFTING"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	var station_label := Label.new()
	station_label.name = "StationLabel"
	station_label.text = CRAFT_STATIONS.get(available_station, "Hand Crafting")
	station_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	header.add_child(station_label)
	
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)
	
	return header

func _populate_categories() -> void:
	for child in category_list.get_children():
		child.queue_free()
	
	for cat_id in CATEGORIES:
		var cat_data: Dictionary = CATEGORIES[cat_id]
		
		var btn := Button.new()
		btn.text = "%s %s" % [cat_data.icon, cat_data.name]
		btn.custom_minimum_size.y = 36
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.toggle_mode = true
		btn.button_pressed = cat_id == current_category
		btn.pressed.connect(_on_category_selected.bind(cat_id))
		
		category_list.add_child(btn)

func _load_recipes() -> void:
	# Load from ExtendedItemDatabase
	if ClassDB.class_exists("ExtendedItemDatabase"):
		var item_db = load("res://scripts/inventory/ExtendedItemDatabase.gd")
		if item_db:
			var items: Dictionary = item_db.ITEMS
			for item_id in items:
				var item: Dictionary = items[item_id]
				if item.get("craftable", false):
					all_recipes[item_id] = item
	
	# Fallback recipes if database not loaded
	if all_recipes.is_empty():
		all_recipes = _get_fallback_recipes()

func _get_fallback_recipes() -> Dictionary:
	return {
		"wood_club": {
			"id": "wood_club",
			"name": "Wooden Club",
			"category": "weapons",
			"icon": "⚔️",
			"craft_time": 5.0,
			"craft_station": "hand",
			"recipe": {"wood": 5}
		},
		"stone_knife": {
			"id": "stone_knife",
			"name": "Stone Knife",
			"category": "weapons",
			"icon": "🔪",
			"craft_time": 8.0,
			"craft_station": "hand",
			"recipe": {"stone": 3, "wood": 2}
		},
		"bandage": {
			"id": "bandage",
			"name": "Bandage",
			"category": "consumables",
			"icon": "🩹",
			"craft_time": 5.0,
			"craft_station": "hand",
			"recipe": {"cloth": 2}
		},
		"cloth": {
			"id": "cloth",
			"name": "Cloth",
			"category": "materials",
			"icon": "🧵",
			"craft_time": 10.0,
			"craft_station": "hand",
			"recipe": {"fibers": 5}
		}
	}

func _connect_signals() -> void:
	background.gui_input.connect(_on_background_input)
	search_box.text_changed.connect(_on_search_changed)
	craft_button.pressed.connect(_on_craft_pressed)

# ============================================================================
# PROCESS
# ============================================================================

func _process(delta: float) -> void:
	if not is_open:
		return
	
	# Update crafting progress
	if not current_craft.is_empty():
		var craft_time: float = current_craft.get("craft_time", 5.0)
		craft_progress += delta
		
		progress_bar.value = (craft_progress / craft_time) * 100
		
		if craft_progress >= craft_time:
			_complete_craft()

# ============================================================================
# INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C and not is_open:
			toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and is_open:
			close()
			get_viewport().set_input_as_handled()

func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _on_category_selected(cat_id: String) -> void:
	current_category = cat_id
	
	# Update button states
	for btn in category_list.get_children():
		if btn is Button:
			btn.button_pressed = btn.text.contains(CATEGORIES[cat_id].name)
	
	_populate_recipes()

func _on_search_changed(text: String) -> void:
	_populate_recipes(text)

func _on_recipe_selected(recipe_id: String) -> void:
	selected_recipe_id = recipe_id
	
	# Update button highlights
	for rid in recipe_buttons:
		var btn: Control = recipe_buttons[rid]
		var style: StyleBoxFlat = btn.get_theme_stylebox("panel")
		if rid == recipe_id:
			style.border_color = Color(0.9, 0.7, 0.3)
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
		else:
			style.border_color = Color(0.3, 0.3, 0.35)
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
	
	_update_details()
	recipe_selected.emit(recipe_id)

func _on_craft_pressed() -> void:
	if selected_recipe_id.is_empty():
		return
	
	var recipe: Dictionary = all_recipes.get(selected_recipe_id, {})
	if recipe.is_empty():
		return
	
	if not _can_craft(recipe):
		return
	
	_start_craft(recipe)

# ============================================================================
# RECIPE DISPLAY
# ============================================================================

func _populate_recipes(search_filter: String = "") -> void:
	# Clear existing
	for child in recipe_grid.get_children():
		child.queue_free()
	recipe_buttons.clear()
	
	var filter := search_filter.to_lower()
	
	for recipe_id in all_recipes:
		var recipe: Dictionary = all_recipes[recipe_id]
		
		# Category filter
		if current_category != "all":
			var recipe_cat: String = _get_recipe_category(recipe)
			if recipe_cat != current_category:
				continue
		
		# Search filter
		if not filter.is_empty():
			var recipe_name: String = recipe.get("name", recipe_id).to_lower()
			if not recipe_name.contains(filter):
				continue
		
		var btn := _create_recipe_button(recipe_id, recipe)
		recipe_grid.add_child(btn)
		recipe_buttons[recipe_id] = btn

func _create_recipe_button(recipe_id: String, recipe: Dictionary) -> Control:
	var btn := Panel.new()
	btn.name = "Recipe_" + recipe_id
	btn.custom_minimum_size = Vector2(80, 80)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 0.95)
	style.set_border_width_all(1)
	style.border_color = Color(0.3, 0.3, 0.35)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("panel", style)
	
	# Icon/placeholder
	var icon := Label.new()
	icon.text = recipe.get("icon", "?")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 28)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(icon)
	
	# Name
	var name_label := Label.new()
	name_label.text = recipe.get("name", recipe_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_label.position.y = -20
	btn.add_child(name_label)
	
	# Craftable indicator
	var can_craft := _can_craft(recipe)
	if not can_craft:
		btn.modulate.a = 0.5
	
	# Locked indicator
	var is_learned := recipe_id in learned_recipes or learned_recipes.is_empty()
	if not is_learned:
		var lock := Label.new()
		lock.text = "🔒"
		lock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		lock.position = Vector2(-20, 2)
		btn.add_child(lock)
	
	# Input
	btn.gui_input.connect(_on_recipe_button_input.bind(recipe_id))
	
	return btn

func _on_recipe_button_input(event: InputEvent, recipe_id: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_recipe_selected(recipe_id)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Toggle favorite
			if recipe_id in favorite_recipes:
				favorite_recipes.erase(recipe_id)
			else:
				favorite_recipes.append(recipe_id)

func _get_recipe_category(recipe: Dictionary) -> String:
	var category: String = recipe.get("category", "")
	if not category.is_empty():
		return category
	
	# Determine from item type
	var item_type: int = recipe.get("type", -1)
	match item_type:
		0, 1:  # WEAPON_MELEE, WEAPON_RANGED
			return "weapons"
		2:  # ARMOR
			return "armor"
		3:  # CONSUMABLE
			return "consumables"
		4:  # RESOURCE
			return "materials"
		6:  # TOOL
			return "tools"
		7:  # AMMO
			return "ammo"
	
	return "materials"

# ============================================================================
# DETAILS PANEL
# ============================================================================

func _update_details() -> void:
	# Clear existing
	for child in details_panel.get_children():
		child.queue_free()
	for child in requirements_list.get_children():
		child.queue_free()
	
	if selected_recipe_id.is_empty():
		craft_button.disabled = true
		return
	
	var recipe: Dictionary = all_recipes.get(selected_recipe_id, {})
	if recipe.is_empty():
		return
	
	# Item name
	var name_label := Label.new()
	name_label.text = recipe.get("name", selected_recipe_id)
	name_label.add_theme_font_size_override("font_size", 18)
	details_panel.add_child(name_label)
	
	# Description
	var desc_label := Label.new()
	desc_label.text = recipe.get("description", "")
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	details_panel.add_child(desc_label)
	
	# Stats preview
	var stats_vbox := VBoxContainer.new()
	details_panel.add_child(stats_vbox)
	
	if recipe.get("damage", 0) > 0:
		_add_stat_row(stats_vbox, "Damage", str(recipe.damage), Color(0.9, 0.4, 0.4))
	if recipe.get("armor", 0) > 0:
		_add_stat_row(stats_vbox, "Armor", str(recipe.armor), Color(0.4, 0.6, 0.9))
	if recipe.get("health_restore", 0) > 0:
		_add_stat_row(stats_vbox, "Heals", str(recipe.health_restore), Color(0.4, 0.9, 0.4))
	
	# Craft time
	var time_label := Label.new()
	var craft_time: float = recipe.get("craft_time", 5.0)
	time_label.text = "⏱️ %.1f seconds" % craft_time
	time_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	details_panel.add_child(time_label)
	
	# Station requirement
	var station: String = recipe.get("craft_station", "hand")
	var station_name: String = CRAFT_STATIONS.get(station, "Hand Crafting")
	var station_label := Label.new()
	station_label.text = "🔨 %s" % station_name
	
	var has_station := station == "hand" or station == available_station
	station_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4) if has_station else Color(0.9, 0.4, 0.4))
	details_panel.add_child(station_label)
	
	# Requirements
	var requirements: Dictionary = recipe.get("recipe", {})
	var can_craft_all := true
	
	for resource_id in requirements:
		var needed: int = requirements[resource_id]
		var have: int = _get_resource_count(resource_id)
		var has_enough := have >= needed
		
		if not has_enough:
			can_craft_all = false
		
		var row := HBoxContainer.new()
		
		var res_icon := Label.new()
		res_icon.text = "📦"
		res_icon.custom_minimum_size.x = 24
		row.add_child(res_icon)
		
		var res_name := Label.new()
		res_name.text = resource_id.capitalize()
		res_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(res_name)
		
		var count_label := Label.new()
		count_label.text = "%d/%d" % [have, needed]
		count_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4) if has_enough else Color(0.9, 0.4, 0.4))
		row.add_child(count_label)
		
		requirements_list.add_child(row)
	
	# Update craft button
	craft_button.disabled = not can_craft_all
	craft_button.text = "CRAFT" if can_craft_all else "MISSING RESOURCES"

func _add_stat_row(parent: Control, stat_name: String, value: String, color: Color) -> void:
	var row := HBoxContainer.new()
	
	var name_label := Label.new()
	name_label.text = stat_name + ":"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	
	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_color_override("font_color", color)
	row.add_child(value_label)
	
	parent.add_child(row)

# ============================================================================
# CRAFTING
# ============================================================================

func _can_craft(recipe: Dictionary) -> bool:
	# Check station
	var station: String = recipe.get("craft_station", "hand")
	if station != "hand" and station != available_station:
		return false
	
	# Check resources
	var requirements: Dictionary = recipe.get("recipe", {})
	for resource_id in requirements:
		var needed: int = requirements[resource_id]
		var have: int = _get_resource_count(resource_id)
		if have < needed:
			return false
	
	return true

func _start_craft(recipe: Dictionary) -> void:
	# Consume resources
	var requirements: Dictionary = recipe.get("recipe", {})
	for resource_id in requirements:
		_consume_resource(resource_id, requirements[resource_id])
	
	current_craft = recipe.duplicate()
	craft_progress = 0.0
	
	progress_bar.visible = true
	progress_bar.value = 0
	craft_button.disabled = true
	craft_button.text = "CRAFTING..."
	
	craft_started.emit(recipe.get("id", ""))
	
	_update_details()

func _complete_craft() -> void:
	var recipe_id: String = current_craft.get("id", "")
	
	# Add item to inventory
	_add_crafted_item(current_craft)
	
	current_craft = {}
	craft_progress = 0.0
	
	progress_bar.visible = false
	craft_button.text = "CRAFT"
	
	craft_completed.emit(recipe_id)
	
	_update_details()
	_populate_recipes(search_box.text)

func _cancel_craft() -> void:
	if current_craft.is_empty():
		return
	
	var recipe_id: String = current_craft.get("id", "")
	
	# Refund resources
	var requirements: Dictionary = current_craft.get("recipe", {})
	for resource_id in requirements:
		_add_resource(resource_id, requirements[resource_id])
	
	current_craft = {}
	craft_progress = 0.0
	
	progress_bar.visible = false
	craft_button.text = "CRAFT"
	
	craft_cancelled.emit(recipe_id)
	
	_update_details()

# ============================================================================
# RESOURCE MANAGEMENT
# ============================================================================

func _get_resource_count(resource_id: String) -> int:
	var inventory := get_tree().get_first_node_in_group("inventory")
	if inventory and inventory.has_method("get_item_count"):
		return inventory.get_item_count(resource_id)
	
	# Fallback - check player inventory data
	var player := get_tree().get_first_node_in_group("player")
	if player and "inventory" in player:
		var count := 0
		for item in player.inventory:
			if item is Dictionary and item.get("id", "") == resource_id:
				count += item.get("count", 1)
		return count
	
	return 99  # Debug fallback

func _consume_resource(resource_id: String, amount: int) -> void:
	var inventory := get_tree().get_first_node_in_group("inventory")
	if inventory and inventory.has_method("remove_item"):
		inventory.remove_item(resource_id, amount)

func _add_resource(resource_id: String, amount: int) -> void:
	var inventory := get_tree().get_first_node_in_group("inventory")
	if inventory and inventory.has_method("add_item"):
		inventory.add_item(resource_id, amount)

func _add_crafted_item(recipe: Dictionary) -> void:
	var inventory := get_tree().get_first_node_in_group("inventory")
	var item_id: String = recipe.get("id", "")
	
	if inventory and inventory.has_method("add_item"):
		inventory.add_item(item_id, 1)

# ============================================================================
# PUBLIC API
# ============================================================================

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open(station: String = "hand") -> void:
	if is_open:
		return
	
	available_station = station
	is_open = true
	visible = true
	
	_populate_recipes()
	
	crafting_opened.emit()
	
	# Animate
	main_panel.modulate.a = 0
	main_panel.scale = Vector2(0.95, 0.95)
	var tween := create_tween().set_parallel()
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(main_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	if not is_open:
		return
	
	# Cancel any active craft
	if not current_craft.is_empty():
		_cancel_craft()
	
	is_open = false
	
	var tween := create_tween().set_parallel()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.1)
	tween.tween_property(main_panel, "scale", Vector2(0.95, 0.95), 0.1)
	tween.chain().tween_callback(func(): visible = false)
	
	crafting_closed.emit()

func set_available_station(station: String) -> void:
	available_station = station
	if is_open:
		_update_details()
		_populate_recipes(search_box.text)

func learn_recipe(recipe_id: String) -> void:
	if recipe_id not in learned_recipes:
		learned_recipes.append(recipe_id)
