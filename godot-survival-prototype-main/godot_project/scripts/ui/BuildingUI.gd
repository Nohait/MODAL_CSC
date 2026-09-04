extends Control

## BuildingUI - LDOE-style base building interface with structure placement and upgrading
## Features grid visualization, structure categories, and placement preview

class_name BuildingUI

# ============================================================================
# SIGNALS
# ============================================================================

signal building_mode_entered
signal building_mode_exited
signal structure_selected(structure_type: String)
signal structure_placed(structure_type: String, grid_pos: Vector2i)
signal structure_rotated(direction: int)
signal structure_upgraded(grid_pos: Vector2i)
signal structure_demolished(grid_pos: Vector2i)

# ============================================================================
# CONSTANTS
# ============================================================================

const GRID_SIZE := 32
const PREVIEW_ALPHA := 0.6

const STRUCTURE_CATEGORIES := {
	"foundations": {
		"name": "Foundations",
		"icon": "🏗️",
		"structures": ["floor_wood", "floor_stone", "floor_metal"]
	},
	"walls": {
		"name": "Walls & Doors",
		"icon": "🧱",
		"structures": ["wall_wood", "wall_stone", "wall_metal", "door_wood", "door_metal", "window_wood"]
	},
	"crafting": {
		"name": "Crafting",
		"icon": "⚒️",
		"structures": ["workbench_basic", "workbench_advanced", "forge", "campfire", "chemistry_station"]
	},
	"storage": {
		"name": "Storage",
		"icon": "📦",
		"structures": ["chest_small", "chest_large", "crate_weapon", "locker"]
	},
	"defense": {
		"name": "Defense",
		"icon": "🛡️",
		"structures": ["spike_trap", "turret_basic", "turret_advanced", "landmine"]
	},
	"utility": {
		"name": "Utility",
		"icon": "💡",
		"structures": ["bed", "lamp", "generator", "water_collector", "garden_bed"]
	}
}

const STRUCTURE_DATA := {
	"floor_wood": {"name": "Wood Floor", "icon": "⬜", "cost": {"wood": 5}, "hp": 100},
	"floor_stone": {"name": "Stone Floor", "icon": "⬜", "cost": {"stone": 8}, "hp": 250},
	"floor_metal": {"name": "Metal Floor", "icon": "⬜", "cost": {"steel_ingot": 3}, "hp": 500},
	"wall_wood": {"name": "Wood Wall", "icon": "🪵", "cost": {"wood": 10}, "hp": 150},
	"wall_stone": {"name": "Stone Wall", "icon": "🧱", "cost": {"stone": 15}, "hp": 400},
	"wall_metal": {"name": "Metal Wall", "icon": "🔩", "cost": {"steel_ingot": 5}, "hp": 800},
	"door_wood": {"name": "Wood Door", "icon": "🚪", "cost": {"wood": 8}, "hp": 100},
	"door_metal": {"name": "Metal Door", "icon": "🚪", "cost": {"steel_ingot": 4}, "hp": 500},
	"window_wood": {"name": "Window", "icon": "🪟", "cost": {"wood": 6, "glass": 2}, "hp": 50},
	"workbench_basic": {"name": "Basic Workbench", "icon": "🔧", "cost": {"wood": 15, "stone": 5}, "hp": 200},
	"workbench_advanced": {"name": "Advanced Workbench", "icon": "⚙️", "cost": {"steel_ingot": 10, "electronics": 5}, "hp": 400},
	"forge": {"name": "Forge", "icon": "🔥", "cost": {"stone": 20, "iron_ore": 5}, "hp": 300},
	"campfire": {"name": "Campfire", "icon": "🔥", "cost": {"wood": 8, "stone": 3}, "hp": 100},
	"chemistry_station": {"name": "Chemistry Station", "icon": "🧪", "cost": {"steel_ingot": 8, "electronics": 3}, "hp": 250},
	"chest_small": {"name": "Small Chest", "icon": "📦", "cost": {"wood": 10}, "hp": 150, "slots": 12},
	"chest_large": {"name": "Large Chest", "icon": "📦", "cost": {"wood": 20, "iron_ore": 5}, "hp": 200, "slots": 24},
	"crate_weapon": {"name": "Weapon Crate", "icon": "🗃️", "cost": {"steel_ingot": 8}, "hp": 300, "slots": 16},
	"locker": {"name": "Locker", "icon": "🗄️", "cost": {"steel_ingot": 6}, "hp": 250, "slots": 20},
	"spike_trap": {"name": "Spike Trap", "icon": "📍", "cost": {"wood": 5, "iron_ore": 3}, "hp": 50, "damage": 15},
	"turret_basic": {"name": "Basic Turret", "icon": "🔫", "cost": {"steel_ingot": 15, "electronics": 10}, "hp": 200, "damage": 25},
	"turret_advanced": {"name": "Advanced Turret", "icon": "🔫", "cost": {"titanium": 10, "electronics": 20}, "hp": 400, "damage": 50},
	"landmine": {"name": "Landmine", "icon": "💣", "cost": {"iron_ore": 5, "gunpowder": 10}, "hp": 25, "damage": 100},
	"bed": {"name": "Bed", "icon": "🛏️", "cost": {"wood": 12, "cloth": 8}, "hp": 100},
	"lamp": {"name": "Lamp", "icon": "💡", "cost": {"wood": 3, "electronics": 2}, "hp": 25},
	"generator": {"name": "Generator", "icon": "⚡", "cost": {"steel_ingot": 20, "electronics": 15}, "hp": 300},
	"water_collector": {"name": "Water Collector", "icon": "💧", "cost": {"wood": 10, "cloth": 5}, "hp": 100},
	"garden_bed": {"name": "Garden Bed", "icon": "🌱", "cost": {"wood": 8}, "hp": 75}
}

# ============================================================================
# STATE
# ============================================================================

var is_building_mode := false
var current_category := ""
var selected_structure := ""
var placement_rotation := 0
var is_valid_placement := false
var preview_grid_pos := Vector2i.ZERO

# ============================================================================
# REFERENCES
# ============================================================================

@onready var category_bar: HBoxContainer = $CategoryBar
@onready var structure_panel: PanelContainer = $StructurePanel
@onready var structure_grid: GridContainer = $StructurePanel/Scroll/Grid
@onready var info_panel: PanelContainer = $InfoPanel
@onready var cost_list: VBoxContainer = $InfoPanel/Content/CostList
@onready var preview_node: Node2D = $PreviewNode
@onready var grid_overlay: Node2D = $GridOverlay
@onready var controls_hint: Label = $ControlsHint

var base_building_system: Node = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("building_ui")
	_build_ui()
	_connect_signals()
	hide()

func _build_ui() -> void:
	if not has_node("CategoryBar"):
		_create_ui_structure()
	
	_populate_categories()

func _create_ui_structure() -> void:
	# Category bar at top
	category_bar = HBoxContainer.new()
	category_bar.name = "CategoryBar"
	category_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	category_bar.custom_minimum_size.y = 60
	category_bar.add_theme_constant_override("separation", 5)
	add_child(category_bar)
	
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.1, 0.1, 0.12, 0.95)
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.z_index = -1
	category_bar.add_child(bar_bg)
	
	# Structure selection panel
	structure_panel = PanelContainer.new()
	structure_panel.name = "StructurePanel"
	structure_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	structure_panel.custom_minimum_size = Vector2(400, 200)
	structure_panel.position = Vector2(10, -210)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	panel_style.set_corner_radius_all(8)
	structure_panel.add_theme_stylebox_override("panel", panel_style)
	structure_panel.visible = false
	add_child(structure_panel)
	
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	structure_panel.add_child(scroll)
	
	structure_grid = GridContainer.new()
	structure_grid.name = "Grid"
	structure_grid.columns = 5
	structure_grid.add_theme_constant_override("h_separation", 8)
	structure_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(structure_grid)
	
	# Info panel on right
	info_panel = PanelContainer.new()
	info_panel.name = "InfoPanel"
	info_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	info_panel.custom_minimum_size = Vector2(220, 180)
	info_panel.position = Vector2(-230, -90)
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	info_style.set_corner_radius_all(8)
	info_panel.add_theme_stylebox_override("panel", info_style)
	info_panel.visible = false
	add_child(info_panel)
	
	var info_content := VBoxContainer.new()
	info_content.name = "Content"
	info_panel.add_child(info_content)
	
	var info_title := Label.new()
	info_title.name = "Title"
	info_title.add_theme_font_size_override("font_size", 16)
	info_content.add_child(info_title)
	
	cost_list = VBoxContainer.new()
	cost_list.name = "CostList"
	info_content.add_child(cost_list)
	
	var place_btn := Button.new()
	place_btn.name = "PlaceButton"
	place_btn.text = "PLACE [LMB]"
	place_btn.custom_minimum_size.y = 36
	info_content.add_child(place_btn)
	
	# Controls hint
	controls_hint = Label.new()
	controls_hint.name = "ControlsHint"
	controls_hint.text = "[R] Rotate  |  [LMB] Place  |  [RMB] Cancel  |  [B] Exit"
	controls_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_hint.add_theme_font_size_override("font_size", 14)
	controls_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	controls_hint.position.y = -30
	add_child(controls_hint)
	
	# Preview node (added to world, not UI)
	preview_node = Node2D.new()
	preview_node.name = "PreviewNode"
	preview_node.z_index = 100
	
	# Grid overlay
	grid_overlay = Node2D.new()
	grid_overlay.name = "GridOverlay"
	grid_overlay.z_index = 99

func _populate_categories() -> void:
	for child in category_bar.get_children():
		if child is Button:
			child.queue_free()
	
	# Exit button
	var exit_btn := Button.new()
	exit_btn.text = "✕ EXIT"
	exit_btn.custom_minimum_size = Vector2(80, 50)
	exit_btn.pressed.connect(exit_building_mode)
	category_bar.add_child(exit_btn)
	
	# Separator
	var sep := VSeparator.new()
	category_bar.add_child(sep)
	
	# Category buttons
	for cat_id in STRUCTURE_CATEGORIES:
		var cat_data: Dictionary = STRUCTURE_CATEGORIES[cat_id]
		
		var btn := Button.new()
		btn.text = "%s\n%s" % [cat_data.icon, cat_data.name]
		btn.custom_minimum_size = Vector2(90, 50)
		btn.toggle_mode = true
		btn.pressed.connect(_on_category_selected.bind(cat_id))
		
		category_bar.add_child(btn)

func _connect_signals() -> void:
	base_building_system = get_tree().get_first_node_in_group("base_building")

# ============================================================================
# INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_B:
			if is_building_mode:
				exit_building_mode()
			else:
				enter_building_mode()
			get_viewport().set_input_as_handled()
		
		elif is_building_mode:
			if event.keycode == KEY_R:
				_rotate_structure()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_ESCAPE:
				if selected_structure:
					_deselect_structure()
				else:
					exit_building_mode()
				get_viewport().set_input_as_handled()
	
	if is_building_mode and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_structure()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect_structure()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not is_building_mode or selected_structure.is_empty():
		return
	
	_update_preview_position()
	_update_placement_validity()

# ============================================================================
# BUILDING MODE
# ============================================================================

func enter_building_mode() -> void:
	if is_building_mode:
		return
	
	is_building_mode = true
	visible = true
	
	# Add preview and grid to world
	var world := get_tree().current_scene
	if world:
		if not preview_node.get_parent():
			world.add_child(preview_node)
		if not grid_overlay.get_parent():
			world.add_child(grid_overlay)
	
	building_mode_entered.emit()
	
	# Animate in
	modulate.a = 0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func exit_building_mode() -> void:
	if not is_building_mode:
		return
	
	is_building_mode = false
	_deselect_structure()
	
	# Remove preview and grid from world
	if preview_node.get_parent():
		preview_node.get_parent().remove_child(preview_node)
	if grid_overlay.get_parent():
		grid_overlay.get_parent().remove_child(grid_overlay)
	
	building_mode_exited.emit()
	
	# Animate out
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): visible = false)

func _on_category_selected(cat_id: String) -> void:
	current_category = cat_id
	
	# Update button states
	for child in category_bar.get_children():
		if child is Button and child.toggle_mode:
			child.button_pressed = child.text.contains(STRUCTURE_CATEGORIES[cat_id].name)
	
	_populate_structures(cat_id)
	structure_panel.visible = true

func _populate_structures(cat_id: String) -> void:
	for child in structure_grid.get_children():
		child.queue_free()
	
	var cat_data: Dictionary = STRUCTURE_CATEGORIES.get(cat_id, {})
	var structures: Array = cat_data.get("structures", [])
	
	for struct_id in structures:
		var struct_data: Dictionary = STRUCTURE_DATA.get(struct_id, {})
		
		var btn := Panel.new()
		btn.name = "Struct_" + struct_id
		btn.custom_minimum_size = Vector2(70, 70)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.18, 0.95)
		style.set_border_width_all(2)
		style.border_color = Color(0.3, 0.3, 0.35)
		style.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("panel", style)
		
		# Icon
		var icon := Label.new()
		icon.text = struct_data.get("icon", "?")
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 24)
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_child(icon)
		
		# Name
		var name_label := Label.new()
		name_label.text = struct_data.get("name", struct_id)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		name_label.position.y = -18
		btn.add_child(name_label)
		
		# Check if can afford
		if not _can_afford(struct_data):
			btn.modulate.a = 0.5
		
		btn.gui_input.connect(_on_structure_button_input.bind(struct_id))
		
		structure_grid.add_child(btn)

func _on_structure_button_input(event: InputEvent, struct_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_structure(struct_id)

func _select_structure(struct_id: String) -> void:
	selected_structure = struct_id
	placement_rotation = 0
	
	_update_info_panel()
	_update_preview()
	
	info_panel.visible = true
	
	structure_selected.emit(struct_id)

func _deselect_structure() -> void:
	selected_structure = ""
	info_panel.visible = false
	
	# Clear preview
	for child in preview_node.get_children():
		child.queue_free()

func _rotate_structure() -> void:
	placement_rotation = (placement_rotation + 1) % 4
	_update_preview()
	structure_rotated.emit(placement_rotation)

# ============================================================================
# PREVIEW & PLACEMENT
# ============================================================================

func _update_preview_position() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var camera := get_viewport().get_camera_2d()
	
	if camera:
		var world_pos := camera.get_global_mouse_position()
		preview_grid_pos = Vector2i(
			int(world_pos.x / GRID_SIZE),
			int(world_pos.y / GRID_SIZE)
		)
		preview_node.global_position = Vector2(preview_grid_pos) * GRID_SIZE

func _update_preview() -> void:
	# Clear existing preview
	for child in preview_node.get_children():
		child.queue_free()
	
	if selected_structure.is_empty():
		return
	
	var struct_data: Dictionary = STRUCTURE_DATA.get(selected_structure, {})
	
	# Create simple colored rectangle preview
	var preview := ColorRect.new()
	preview.size = Vector2(GRID_SIZE, GRID_SIZE)
	preview.color = Color(0.3, 0.8, 0.3, PREVIEW_ALPHA)
	preview.rotation_degrees = placement_rotation * 90
	
	# Add icon
	var icon := Label.new()
	icon.text = struct_data.get("icon", "?")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.add_child(icon)
	
	preview_node.add_child(preview)

func _update_placement_validity() -> void:
	is_valid_placement = _can_place_at(preview_grid_pos)
	
	# Update preview color
	for child in preview_node.get_children():
		if child is ColorRect:
			if is_valid_placement:
				child.color = Color(0.3, 0.8, 0.3, PREVIEW_ALPHA)
			else:
				child.color = Color(0.9, 0.3, 0.3, PREVIEW_ALPHA)

func _can_place_at(grid_pos: Vector2i) -> bool:
	if selected_structure.is_empty():
		return false
	
	var struct_data: Dictionary = STRUCTURE_DATA.get(selected_structure, {})
	
	# Check resources
	if not _can_afford(struct_data):
		return false
	
	# Check with building system
	if base_building_system and base_building_system.has_method("can_place_structure"):
		return base_building_system.can_place_structure(selected_structure, grid_pos)
	
	return true

func _try_place_structure() -> void:
	if selected_structure.is_empty() or not is_valid_placement:
		return
	
	var struct_data: Dictionary = STRUCTURE_DATA.get(selected_structure, {})
	
	# Consume resources
	var cost: Dictionary = struct_data.get("cost", {})
	for resource_id in cost:
		_consume_resource(resource_id, cost[resource_id])
	
	# Place via building system
	if base_building_system and base_building_system.has_method("place_structure"):
		base_building_system.place_structure(selected_structure, preview_grid_pos, placement_rotation)
	
	structure_placed.emit(selected_structure, preview_grid_pos)
	
	# Update UI
	_update_info_panel()
	_populate_structures(current_category)

# ============================================================================
# INFO PANEL
# ============================================================================

func _update_info_panel() -> void:
	if selected_structure.is_empty():
		return
	
	var struct_data: Dictionary = STRUCTURE_DATA.get(selected_structure, {})
	
	# Title
	var title: Label = info_panel.get_node_or_null("Content/Title")
	if title:
		title.text = struct_data.get("name", selected_structure)
	
	# Cost list
	for child in cost_list.get_children():
		child.queue_free()
	
	var cost: Dictionary = struct_data.get("cost", {})
	var can_afford := true
	
	for resource_id in cost:
		var needed: int = cost[resource_id]
		var have: int = _get_resource_count(resource_id)
		var has_enough := have >= needed
		
		if not has_enough:
			can_afford = false
		
		var row := HBoxContainer.new()
		
		var res_name := Label.new()
		res_name.text = resource_id.capitalize()
		res_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(res_name)
		
		var count_label := Label.new()
		count_label.text = "%d/%d" % [have, needed]
		count_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4) if has_enough else Color(0.9, 0.4, 0.4))
		row.add_child(count_label)
		
		cost_list.add_child(row)
	
	# Stats
	if struct_data.get("hp", 0) > 0:
		var hp_row := HBoxContainer.new()
		var hp_label := Label.new()
		hp_label.text = "Health:"
		hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hp_row.add_child(hp_label)
		var hp_value := Label.new()
		hp_value.text = str(struct_data.hp)
		hp_value.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		hp_row.add_child(hp_value)
		cost_list.add_child(hp_row)
	
	# Place button
	var place_btn: Button = info_panel.get_node_or_null("Content/PlaceButton")
	if place_btn:
		place_btn.disabled = not can_afford
		place_btn.text = "PLACE [LMB]" if can_afford else "MISSING RESOURCES"

# ============================================================================
# RESOURCE HELPERS
# ============================================================================

func _can_afford(struct_data: Dictionary) -> bool:
	var cost: Dictionary = struct_data.get("cost", {})
	for resource_id in cost:
		if _get_resource_count(resource_id) < cost[resource_id]:
			return false
	return true

func _get_resource_count(resource_id: String) -> int:
	var inventory := get_tree().get_first_node_in_group("inventory")
	if inventory and inventory.has_method("get_item_count"):
		return inventory.get_item_count(resource_id)
	return 99  # Debug fallback

func _consume_resource(resource_id: String, amount: int) -> void:
	var inventory := get_tree().get_first_node_in_group("inventory")
	if inventory and inventory.has_method("remove_item"):
		inventory.remove_item(resource_id, amount)

# ============================================================================
# PUBLIC API
# ============================================================================

func toggle() -> void:
	if is_building_mode:
		exit_building_mode()
	else:
		enter_building_mode()

func set_base_building_system(system: Node) -> void:
	base_building_system = system
