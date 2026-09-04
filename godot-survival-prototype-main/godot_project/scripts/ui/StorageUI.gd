extends Control
class_name StorageUI
## Storage UI for transferring items between player inventory and home storage

signal closed

const SLOT_SIZE := 64
const GRID_COLUMNS := 5

# UI References
var _background: ColorRect
var _panel: PanelContainer
var _inventory_grid: GridContainer
var _storage_grid: GridContainer
var _close_button: Button

var _inventory_slots: Array = []
var _storage_slots: Array = []

func _ready() -> void:
	_setup_ui()
	hide()


func _setup_ui() -> void:
	# Full screen background
	_background = ColorRect.new()
	_background.color = Color(0, 0, 0, 0.7)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)
	
	# Center panel
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(750, 450)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-375, -225)
	
	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.35, 0.35, 0.4)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	
	# Main margin
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Title
	var title := Label.new()
	title.text = "STORAGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	vbox.add_child(title)
	
	# Two-column layout
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)
	
	# Inventory panel
	var inv_result := _create_item_panel("YOUR INVENTORY")
	hbox.add_child(inv_result[0])
	_inventory_grid = inv_result[1]
	
	# Separator
	var sep := VSeparator.new()
	hbox.add_child(sep)
	
	# Storage panel
	var storage_result := _create_item_panel("HOME STORAGE")
	hbox.add_child(storage_result[0])
	_storage_grid = storage_result[1]
	
	# Close button
	_close_button = Button.new()
	_close_button.text = "CLOSE"
	_close_button.custom_minimum_size = Vector2(100, 40)
	_close_button.pressed.connect(_on_close_pressed)
	
	var btn_container := CenterContainer.new()
	btn_container.add_child(_close_button)
	vbox.add_child(btn_container)


func _create_item_panel(title_text: String) -> Array:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label := Label.new()
	label.text = title_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	panel.add_child(label)
	
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 280)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	
	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	
	return [panel, grid]


func _create_item_slot(item: Dictionary, is_inventory: bool, index: int) -> Button:
	var slot := Button.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	
	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25) if item.is_empty() else Color(0.25, 0.25, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(0.4, 0.4, 0.45)
	slot.add_theme_stylebox_override("normal", style)
	
	var hover := style.duplicate()
	hover.border_color = Color(0.7, 0.6, 0.3)
	slot.add_theme_stylebox_override("hover", hover)
	
	if not item.is_empty():
		# Item content
		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_child(vbox)
		
		# Icon (text placeholder for now)
		var icon := Label.new()
		var icon_text := _get_icon_for_item(item.get("id", ""))
		icon.text = icon_text
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 20)
		vbox.add_child(icon)
		
		# Count
		if item.get("count", 1) > 1:
			var count := Label.new()
			count.text = str(item.get("count", 1))
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			count.add_theme_font_size_override("font_size", 12)
			count.add_theme_color_override("font_color", Color(0.9, 0.9, 0.8))
			vbox.add_child(count)
		
		# Connect signal
		if is_inventory:
			slot.pressed.connect(_on_inventory_item_clicked.bind(index))
		else:
			slot.pressed.connect(_on_storage_item_clicked.bind(index))
		
		slot.tooltip_text = "%s x%d" % [item.get("name", "Item"), item.get("count", 1)]
	else:
		slot.disabled = true
	
	return slot


func _get_icon_for_item(item_id: String) -> String:
	match item_id:
		"wood": return "🪵"
		"stone": return "🪨"
		"fiber": return "🌿"
		"iron": return "⚙️"
		"coal": return "◼️"
		"food": return "🍖"
		"water": return "💧"
		"rope": return "🪢"
		"plank": return "📦"
		_: return "📦"


func _refresh_grids() -> void:
	# Clear grids
	for child in _inventory_grid.get_children():
		child.queue_free()
	for child in _storage_grid.get_children():
		child.queue_free()
	
	_inventory_slots.clear()
	_storage_slots.clear()
	
	# Populate inventory
	var inventory: Array = GameManager.player_inventory if GameManager else []
	for i in range(max(inventory.size(), 15)):  # At least 15 slots
		var item: Dictionary = inventory[i] if i < inventory.size() else {}
		var slot := _create_item_slot(item, true, i)
		_inventory_grid.add_child(slot)
		_inventory_slots.append(slot)
	
	# Populate storage
	var storage: Array = GameManager.storage_contents if GameManager else []
	for i in range(max(storage.size(), 20)):  # At least 20 slots
		var item: Dictionary = storage[i] if i < storage.size() else {}
		var slot := _create_item_slot(item, false, i)
		_storage_grid.add_child(slot)
		_storage_slots.append(slot)


func _on_inventory_item_clicked(index: int) -> void:
	if GameManager:
		GameManager.transfer_to_storage(index)
		_refresh_grids()


func _on_storage_item_clicked(index: int) -> void:
	if GameManager:
		GameManager.transfer_from_storage(index)
		_refresh_grids()


func _on_close_pressed() -> void:
	if GameManager:
		GameManager.save_game()
	closed.emit()
	hide()


func open() -> void:
	_refresh_grids()
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
