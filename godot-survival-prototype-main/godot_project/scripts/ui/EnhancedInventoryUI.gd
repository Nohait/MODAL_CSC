extends Control

## EnhancedInventoryUI - Full-featured inventory with equipment, stats, and item management
## LDOE-style inventory with drag-drop, context menus, and visual polish

class_name EnhancedInventoryUI

# ============================================================================
# SIGNALS
# ============================================================================

signal inventory_opened
signal inventory_closed
signal item_selected(item: Dictionary, slot_index: int)
signal item_used(item: Dictionary)
signal item_dropped(item: Dictionary, count: int)
signal item_equipped(item: Dictionary, slot: String)
signal item_unequipped(slot: String)

# ============================================================================
# CONSTANTS
# ============================================================================

const SLOT_SIZE := Vector2(64, 64)
const INVENTORY_COLUMNS := 6
const INVENTORY_ROWS := 5
const TOTAL_SLOTS := INVENTORY_COLUMNS * INVENTORY_ROWS

const EQUIPMENT_SLOTS := ["head", "torso", "legs", "feet", "hands", "weapon", "offhand"]

const RARITY_COLORS := {
	0: Color(0.6, 0.6, 0.6),    # Common - Gray
	1: Color(0.2, 0.8, 0.2),    # Uncommon - Green
	2: Color(0.2, 0.4, 1.0),    # Rare - Blue
	3: Color(0.7, 0.3, 0.9),    # Epic - Purple
	4: Color(1.0, 0.6, 0.1),    # Legendary - Orange
	5: Color(1.0, 0.2, 0.2)     # Mythic - Red
}

# ============================================================================
# STATE
# ============================================================================

var is_open := false
var selected_slot := -1
var dragging_item: Dictionary = {}
var dragging_from_slot := -1
var dragging_from_equipment := ""

var inventory_data: Array = []
var equipment_data: Dictionary = {}

# ============================================================================
# REFERENCES
# ============================================================================

@onready var background: ColorRect = $Background
@onready var main_panel: PanelContainer = $MainPanel
@onready var inventory_grid: GridContainer = $MainPanel/HBox/InventorySection/InventoryGrid
@onready var equipment_panel: Control = $MainPanel/HBox/CharacterSection/EquipmentPanel
@onready var stats_panel: VBoxContainer = $MainPanel/HBox/CharacterSection/StatsPanel
@onready var item_info_panel: PanelContainer = $MainPanel/HBox/InventorySection/ItemInfoPanel
@onready var context_menu: PopupMenu = $ContextMenu
@onready var drag_preview: Control = $DragPreview
@onready var weight_bar: ProgressBar = $MainPanel/HBox/InventorySection/WeightBar
@onready var currency_label: Label = $MainPanel/HBox/InventorySection/CurrencyLabel

var slot_scenes: Array[Control] = []
var equipment_slots: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("inventory_ui")
	_build_ui()
	_connect_signals()
	hide()

func _build_ui() -> void:
	# Create main structure if not exists
	if not has_node("Background"):
		_create_ui_structure()
	
	_create_inventory_slots()
	_create_equipment_slots()
	_setup_context_menu()

func _create_ui_structure() -> void:
	# Background overlay
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)
	
	# Main panel
	main_panel = PanelContainer.new()
	main_panel.name = "MainPanel"
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(900, 600)
	main_panel.position = -main_panel.custom_minimum_size / 2
	add_child(main_panel)
	
	var main_hbox := HBoxContainer.new()
	main_hbox.name = "HBox"
	main_hbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(main_hbox)
	
	# Character section (left side)
	var char_section := VBoxContainer.new()
	char_section.name = "CharacterSection"
	char_section.custom_minimum_size.x = 280
	main_hbox.add_child(char_section)
	
	var char_label := Label.new()
	char_label.text = "CHARACTER"
	char_label.add_theme_font_size_override("font_size", 18)
	char_section.add_child(char_label)
	
	equipment_panel = Control.new()
	equipment_panel.name = "EquipmentPanel"
	equipment_panel.custom_minimum_size = Vector2(260, 300)
	char_section.add_child(equipment_panel)
	
	stats_panel = VBoxContainer.new()
	stats_panel.name = "StatsPanel"
	char_section.add_child(stats_panel)
	
	# Inventory section (right side)
	var inv_section := VBoxContainer.new()
	inv_section.name = "InventorySection"
	inv_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(inv_section)
	
	var inv_header := HBoxContainer.new()
	inv_section.add_child(inv_header)
	
	var inv_label := Label.new()
	inv_label.text = "INVENTORY"
	inv_label.add_theme_font_size_override("font_size", 18)
	inv_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_header.add_child(inv_label)
	
	currency_label = Label.new()
	currency_label.name = "CurrencyLabel"
	currency_label.text = "0 🪙"
	inv_header.add_child(currency_label)
	
	weight_bar = ProgressBar.new()
	weight_bar.name = "WeightBar"
	weight_bar.custom_minimum_size.y = 20
	weight_bar.max_value = 100
	weight_bar.value = 0
	weight_bar.show_percentage = false
	inv_section.add_child(weight_bar)
	
	var weight_label := Label.new()
	weight_label.text = "Weight: 0/100"
	weight_label.name = "WeightLabel"
	inv_section.add_child(weight_label)
	
	inventory_grid = GridContainer.new()
	inventory_grid.name = "InventoryGrid"
	inventory_grid.columns = INVENTORY_COLUMNS
	inventory_grid.add_theme_constant_override("h_separation", 4)
	inventory_grid.add_theme_constant_override("v_separation", 4)
	inv_section.add_child(inventory_grid)
	
	item_info_panel = PanelContainer.new()
	item_info_panel.name = "ItemInfoPanel"
	item_info_panel.custom_minimum_size = Vector2(0, 120)
	inv_section.add_child(item_info_panel)
	
	# Context menu
	context_menu = PopupMenu.new()
	context_menu.name = "ContextMenu"
	add_child(context_menu)
	
	# Drag preview
	drag_preview = Control.new()
	drag_preview.name = "DragPreview"
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.visible = false
	drag_preview.z_index = 100
	add_child(drag_preview)

func _create_inventory_slots() -> void:
	slot_scenes.clear()
	
	for child in inventory_grid.get_children():
		child.queue_free()
	
	for i in range(TOTAL_SLOTS):
		var slot := _create_slot(i)
		inventory_grid.add_child(slot)
		slot_scenes.append(slot)

func _create_slot(index: int) -> Control:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.name = "Slot_%d" % index
	
	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 0.9)
	style.border_color = Color(0.3, 0.3, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	slot.add_theme_stylebox_override("panel", style)
	
	# Icon
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	
	# Count label
	var count := Label.new()
	count.name = "Count"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.set_anchors_preset(Control.PRESET_FULL_RECT)
	count.add_theme_font_size_override("font_size", 12)
	count.add_theme_color_override("font_color", Color.WHITE)
	count.add_theme_color_override("font_shadow_color", Color.BLACK)
	count.add_theme_constant_override("shadow_offset_x", 1)
	count.add_theme_constant_override("shadow_offset_y", 1)
	slot.add_child(count)
	
	# Durability bar
	var durability := ProgressBar.new()
	durability.name = "Durability"
	durability.custom_minimum_size = Vector2(SLOT_SIZE.x - 8, 4)
	durability.position = Vector2(4, SLOT_SIZE.y - 8)
	durability.max_value = 100
	durability.value = 100
	durability.show_percentage = false
	durability.visible = false
	slot.add_child(durability)
	
	# Rarity border (overlay)
	var rarity_border := Panel.new()
	rarity_border.name = "RarityBorder"
	rarity_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	rarity_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rarity_style := StyleBoxFlat.new()
	rarity_style.bg_color = Color.TRANSPARENT
	rarity_style.border_color = Color.TRANSPARENT
	rarity_style.set_border_width_all(2)
	rarity_style.set_corner_radius_all(4)
	rarity_border.add_theme_stylebox_override("panel", rarity_style)
	slot.add_child(rarity_border)
	
	# Input handling
	slot.gui_input.connect(_on_slot_input.bind(index))
	slot.mouse_entered.connect(_on_slot_hover.bind(index))
	slot.mouse_exited.connect(_on_slot_unhover.bind(index))
	
	return slot

func _create_equipment_slots() -> void:
	equipment_slots.clear()
	
	var slot_positions := {
		"head": Vector2(100, 10),
		"torso": Vector2(100, 90),
		"legs": Vector2(100, 170),
		"feet": Vector2(100, 250),
		"hands": Vector2(20, 130),
		"weapon": Vector2(20, 50),
		"offhand": Vector2(180, 50)
	}
	
	var slot_labels := {
		"head": "🎩",
		"torso": "👕",
		"legs": "👖",
		"feet": "👟",
		"hands": "🧤",
		"weapon": "⚔️",
		"offhand": "🛡️"
	}
	
	for slot_name in EQUIPMENT_SLOTS:
		var slot := Panel.new()
		slot.name = "Equip_" + slot_name
		slot.custom_minimum_size = Vector2(56, 56)
		slot.position = slot_positions.get(slot_name, Vector2.ZERO)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.12, 0.15, 0.95)
		style.border_color = Color(0.4, 0.35, 0.3)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		slot.add_theme_stylebox_override("panel", style)
		
		# Placeholder icon
		var placeholder := Label.new()
		placeholder.name = "Placeholder"
		placeholder.text = slot_labels.get(slot_name, "?")
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		placeholder.add_theme_font_size_override("font_size", 24)
		placeholder.modulate.a = 0.3
		slot.add_child(placeholder)
		
		# Item icon
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		
		slot.gui_input.connect(_on_equipment_slot_input.bind(slot_name))
		slot.mouse_entered.connect(_on_equipment_slot_hover.bind(slot_name))
		
		equipment_panel.add_child(slot)
		equipment_slots[slot_name] = slot

func _setup_context_menu() -> void:
	context_menu.clear()
	context_menu.add_item("Use", 0)
	context_menu.add_item("Equip", 1)
	context_menu.add_item("Drop", 2)
	context_menu.add_item("Drop All", 3)
	context_menu.add_separator()
	context_menu.add_item("Split Stack", 4)
	context_menu.add_separator()
	context_menu.add_item("Examine", 5)
	
	context_menu.id_pressed.connect(_on_context_menu_selected)

func _connect_signals() -> void:
	background.gui_input.connect(_on_background_input)

# ============================================================================
# INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB or event.keycode == KEY_I:
			toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and is_open:
			close()
			get_viewport().set_input_as_handled()
	
	# Update drag preview position
	if dragging_item and drag_preview.visible:
		drag_preview.global_position = get_global_mouse_position() - SLOT_SIZE / 2

func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _on_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var item := _get_item_at_slot(index)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click and item:
				_use_item(item, index)
			elif item:
				_start_drag(item, index)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if item:
				_show_context_menu(item, index)
	
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and dragging_item:
			_end_drag(index)

func _on_equipment_slot_input(event: InputEvent, slot_name: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		var item := equipment_data.get(slot_name, {})
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if item and not item.is_empty():
				_unequip_item(slot_name)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if item and not item.is_empty():
				_show_equipment_context_menu(item, slot_name)
	
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and dragging_item:
			_try_equip_dragged_item(slot_name)

func _on_slot_hover(index: int) -> void:
	var item := _get_item_at_slot(index)
	if item:
		_show_item_info(item)
	
	# Highlight slot
	var slot := slot_scenes[index]
	var style: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate()
	style.border_color = Color(0.8, 0.7, 0.5)
	slot.add_theme_stylebox_override("panel", style)

func _on_slot_unhover(index: int) -> void:
	_hide_item_info()
	
	# Remove highlight
	var slot := slot_scenes[index]
	var style: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate()
	style.border_color = Color(0.3, 0.3, 0.35)
	slot.add_theme_stylebox_override("panel", style)

func _on_equipment_slot_hover(slot_name: String) -> void:
	var item := equipment_data.get(slot_name, {})
	if item and not item.is_empty():
		_show_item_info(item)

func _on_context_menu_selected(id: int) -> void:
	if selected_slot < 0:
		return
	
	var item := _get_item_at_slot(selected_slot)
	if not item:
		return
	
	match id:
		0:  # Use
			_use_item(item, selected_slot)
		1:  # Equip
			_equip_item(item, selected_slot)
		2:  # Drop
			_drop_item(item, selected_slot, 1)
		3:  # Drop All
			_drop_item(item, selected_slot, item.get("count", 1))
		4:  # Split Stack
			_split_stack(item, selected_slot)
		5:  # Examine
			_examine_item(item)

# ============================================================================
# DRAG & DROP
# ============================================================================

func _start_drag(item: Dictionary, from_slot: int) -> void:
	dragging_item = item.duplicate()
	dragging_from_slot = from_slot
	dragging_from_equipment = ""
	
	# Create preview
	_update_drag_preview(item)
	drag_preview.visible = true
	
	# Dim source slot
	slot_scenes[from_slot].modulate.a = 0.5

func _end_drag(to_slot: int) -> void:
	if not dragging_item:
		return
	
	if dragging_from_slot >= 0 and to_slot != dragging_from_slot:
		_swap_items(dragging_from_slot, to_slot)
	
	_clear_drag()

func _try_equip_dragged_item(slot_name: String) -> void:
	if not dragging_item:
		return
	
	var item_slot: String = dragging_item.get("slot", "")
	if item_slot == slot_name:
		_equip_item(dragging_item, dragging_from_slot)
	
	_clear_drag()

func _clear_drag() -> void:
	if dragging_from_slot >= 0:
		slot_scenes[dragging_from_slot].modulate.a = 1.0
	
	dragging_item = {}
	dragging_from_slot = -1
	dragging_from_equipment = ""
	drag_preview.visible = false

func _update_drag_preview(item: Dictionary) -> void:
	# Clear existing
	for child in drag_preview.get_children():
		child.queue_free()
	
	var icon := TextureRect.new()
	icon.custom_minimum_size = SLOT_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate.a = 0.8
	
	var icon_path: String = item.get("icon", "")
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	
	drag_preview.add_child(icon)

# ============================================================================
# ITEM OPERATIONS
# ============================================================================

func _use_item(item: Dictionary, slot_index: int) -> void:
	var item_type: int = item.get("type", -1)
	
	# Check if consumable
	if item_type == 3:  # CONSUMABLE
		# Apply effects through player
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("use_consumable"):
			player.use_consumable(item)
		
		# Remove one from stack
		_remove_item_from_slot(slot_index, 1)
		item_used.emit(item)
	
	# Check if equipment
	elif item_type in [0, 1, 2]:  # WEAPON_MELEE, WEAPON_RANGED, ARMOR
		_equip_item(item, slot_index)

func _equip_item(item: Dictionary, from_slot: int) -> void:
	var slot_name: String = item.get("slot", "")
	if slot_name.is_empty():
		return
	
	# Swap with currently equipped
	var current := equipment_data.get(slot_name, {})
	
	equipment_data[slot_name] = item.duplicate()
	_remove_item_from_slot(from_slot, item.get("count", 1))
	
	if current and not current.is_empty():
		_add_item_to_inventory(current)
	
	_update_equipment_display()
	_update_stats_display()
	
	item_equipped.emit(item, slot_name)

func _unequip_item(slot_name: String) -> void:
	var item := equipment_data.get(slot_name, {})
	if item.is_empty():
		return
	
	if _add_item_to_inventory(item):
		equipment_data[slot_name] = {}
		_update_equipment_display()
		_update_stats_display()
		item_unequipped.emit(slot_name)

func _drop_item(item: Dictionary, slot_index: int, count: int) -> void:
	_remove_item_from_slot(slot_index, count)
	item_dropped.emit(item, count)

func _split_stack(item: Dictionary, slot_index: int) -> void:
	var count: int = item.get("count", 1)
	if count <= 1:
		return
	
	var half := count / 2
	
	# Find empty slot
	for i in range(TOTAL_SLOTS):
		if _get_item_at_slot(i).is_empty():
			var split_item := item.duplicate()
			split_item["count"] = half
			inventory_data[i] = split_item
			
			inventory_data[slot_index]["count"] = count - half
			
			_refresh_slot(slot_index)
			_refresh_slot(i)
			break

func _examine_item(item: Dictionary) -> void:
	# Show detailed item info
	_show_item_info(item, true)

func _swap_items(from: int, to: int) -> void:
	var temp := inventory_data[to] if to < inventory_data.size() else {}
	
	if from < inventory_data.size():
		inventory_data[to] = inventory_data[from]
	if temp:
		inventory_data[from] = temp
	else:
		inventory_data[from] = {}
	
	_refresh_slot(from)
	_refresh_slot(to)

func _get_item_at_slot(index: int) -> Dictionary:
	if index >= 0 and index < inventory_data.size():
		return inventory_data[index]
	return {}

func _remove_item_from_slot(index: int, count: int) -> void:
	if index < 0 or index >= inventory_data.size():
		return
	
	var item: Dictionary = inventory_data[index]
	if item.is_empty():
		return
	
	var current_count: int = item.get("count", 1)
	if count >= current_count:
		inventory_data[index] = {}
	else:
		inventory_data[index]["count"] = current_count - count
	
	_refresh_slot(index)
	_update_weight()

func _add_item_to_inventory(item: Dictionary) -> bool:
	# First try to stack
	var item_id: String = item.get("id", "")
	var stack_size: int = item.get("stack_size", 1)
	var count: int = item.get("count", 1)
	
	if stack_size > 1:
		for i in range(inventory_data.size()):
			var existing: Dictionary = inventory_data[i]
			if existing.get("id", "") == item_id:
				var existing_count: int = existing.get("count", 1)
				if existing_count < stack_size:
					var can_add := min(count, stack_size - existing_count)
					existing["count"] = existing_count + can_add
					count -= can_add
					_refresh_slot(i)
					
					if count <= 0:
						_update_weight()
						return true
	
	# Find empty slot for remainder
	for i in range(inventory_data.size()):
		if inventory_data[i].is_empty():
			var new_item := item.duplicate()
			new_item["count"] = count
			inventory_data[i] = new_item
			_refresh_slot(i)
			_update_weight()
			return true
	
	return false  # Inventory full

# ============================================================================
# DISPLAY UPDATES
# ============================================================================

func _refresh_slot(index: int) -> void:
	if index < 0 or index >= slot_scenes.size():
		return
	
	var slot := slot_scenes[index]
	var item := _get_item_at_slot(index)
	
	var icon: TextureRect = slot.get_node("Icon")
	var count_label: Label = slot.get_node("Count")
	var durability: ProgressBar = slot.get_node("Durability")
	var rarity_border: Panel = slot.get_node("RarityBorder")
	
	if item.is_empty():
		icon.texture = null
		count_label.text = ""
		durability.visible = false
		rarity_border.get_theme_stylebox("panel").border_color = Color.TRANSPARENT
	else:
		# Load icon
		var icon_path: String = item.get("icon", "")
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		else:
			icon.texture = null
		
		# Count
		var item_count: int = item.get("count", 1)
		count_label.text = str(item_count) if item_count > 1 else ""
		
		# Durability
		var item_durability: int = item.get("durability", -1)
		if item_durability >= 0:
			durability.visible = true
			durability.value = item_durability
			durability.modulate = Color.GREEN.lerp(Color.RED, 1.0 - item_durability / 100.0)
		else:
			durability.visible = false
		
		# Rarity border
		var rarity: int = item.get("rarity", 0)
		var style: StyleBoxFlat = rarity_border.get_theme_stylebox("panel")
		style.border_color = RARITY_COLORS.get(rarity, Color.GRAY)

func _update_equipment_display() -> void:
	for slot_name in equipment_slots:
		var slot: Panel = equipment_slots[slot_name]
		var icon: TextureRect = slot.get_node("Icon")
		var placeholder: Label = slot.get_node("Placeholder")
		
		var item: Dictionary = equipment_data.get(slot_name, {})
		
		if item.is_empty():
			icon.texture = null
			placeholder.visible = true
		else:
			var icon_path: String = item.get("icon", "")
			if ResourceLoader.exists(icon_path):
				icon.texture = load(icon_path)
			placeholder.visible = false

func _update_stats_display() -> void:
	# Clear existing
	for child in stats_panel.get_children():
		child.queue_free()
	
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var stats := [
		["Health", player.get("max_health") if "max_health" in player else 100],
		["Armor", _calculate_total_armor()],
		["Damage", _calculate_total_damage()],
		["Speed", player.get("current_speed") if "current_speed" in player else 220]
	]
	
	for stat in stats:
		var row := HBoxContainer.new()
		
		var name_label := Label.new()
		name_label.text = stat[0] + ":"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		
		var value_label := Label.new()
		value_label.text = str(int(stat[1]))
		value_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		row.add_child(value_label)
		
		stats_panel.add_child(row)

func _update_weight() -> void:
	var total_weight := 0.0
	
	for item in inventory_data:
		if item and not item.is_empty():
			total_weight += item.get("weight", 1.0) * item.get("count", 1)
	
	weight_bar.value = total_weight
	
	var weight_label := main_panel.get_node_or_null("HBox/InventorySection/WeightLabel")
	if weight_label:
		weight_label.text = "Weight: %.1f/%.1f" % [total_weight, weight_bar.max_value]

func _calculate_total_armor() -> int:
	var total := 0
	for slot_name in ["head", "torso", "legs", "feet", "hands"]:
		var item: Dictionary = equipment_data.get(slot_name, {})
		total += item.get("armor", 0)
	return total

func _calculate_total_damage() -> int:
	var weapon: Dictionary = equipment_data.get("weapon", {})
	return weapon.get("damage", 5)

func _show_item_info(item: Dictionary, detailed: bool = false) -> void:
	# Clear existing
	for child in item_info_panel.get_children():
		child.queue_free()
	
	var vbox := VBoxContainer.new()
	item_info_panel.add_child(vbox)
	
	# Name with rarity color
	var name_label := Label.new()
	name_label.text = item.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", RARITY_COLORS.get(item.get("rarity", 0), Color.WHITE))
	vbox.add_child(name_label)
	
	# Description
	var desc_label := Label.new()
	desc_label.text = item.get("description", "")
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	# Stats
	var stats := []
	if item.get("damage", 0) > 0:
		stats.append("⚔️ Damage: %d" % item.damage)
	if item.get("armor", 0) > 0:
		stats.append("🛡️ Armor: %d" % item.armor)
	if item.get("health_restore", 0) > 0:
		stats.append("❤️ Heals: %d" % item.health_restore)
	
	for stat in stats:
		var stat_label := Label.new()
		stat_label.text = stat
		stat_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		vbox.add_child(stat_label)

func _hide_item_info() -> void:
	for child in item_info_panel.get_children():
		child.queue_free()

func _show_context_menu(item: Dictionary, slot_index: int) -> void:
	selected_slot = slot_index
	
	# Enable/disable options based on item type
	var item_type: int = item.get("type", -1)
	context_menu.set_item_disabled(0, item_type != 3)  # Use - only consumables
	context_menu.set_item_disabled(1, item_type not in [0, 1, 2])  # Equip - only equipment
	context_menu.set_item_disabled(4, item.get("count", 1) <= 1)  # Split - only if count > 1
	
	context_menu.position = get_global_mouse_position()
	context_menu.popup()

func _show_equipment_context_menu(item: Dictionary, slot_name: String) -> void:
	# Simple menu for equipped items
	context_menu.clear()
	context_menu.add_item("Unequip", 10)
	context_menu.add_item("Examine", 5)
	
	context_menu.position = get_global_mouse_position()
	context_menu.popup()

# ============================================================================
# PUBLIC API
# ============================================================================

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	if is_open:
		return
	
	is_open = true
	visible = true
	
	_refresh_all()
	
	inventory_opened.emit()
	
	# Animate
	main_panel.modulate.a = 0
	main_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_parallel()
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(main_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	if not is_open:
		return
	
	is_open = false
	_clear_drag()
	
	var tween := create_tween().set_parallel()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.1)
	tween.tween_property(main_panel, "scale", Vector2(0.9, 0.9), 0.1)
	tween.chain().tween_callback(func(): visible = false)
	
	inventory_closed.emit()

func set_inventory_data(data: Array) -> void:
	inventory_data = data.duplicate(true)
	
	# Ensure proper size
	while inventory_data.size() < TOTAL_SLOTS:
		inventory_data.append({})
	
	_refresh_all()

func set_equipment_data(data: Dictionary) -> void:
	equipment_data = data.duplicate(true)
	_update_equipment_display()
	_update_stats_display()

func _refresh_all() -> void:
	for i in range(TOTAL_SLOTS):
		_refresh_slot(i)
	
	_update_equipment_display()
	_update_stats_display()
	_update_weight()
