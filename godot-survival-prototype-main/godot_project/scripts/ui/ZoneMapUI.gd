extends Control
class_name ZoneMapUI
## Zone selection map UI for traveling to different zones

signal travel_requested(zone_id: String)
signal closed

const ZONES := {
	"green_zone": {
		"name": "Green Zone",
		"level": 1,
		"difficulty": "Easy",
		"resources": "Wood, Stone, Fiber",
		"unlocked": true,
		"color": Color(0.3, 0.6, 0.3),
		"icon": "🌲"
	},
	"yellow_zone": {
		"name": "Yellow Zone",
		"level": 2,
		"difficulty": "Medium",
		"resources": "Iron, Coal, Fiber",
		"unlocked": true,
		"color": Color(0.8, 0.6, 0.2),
		"icon": "🏚️"
	},
	"red_zone": {
		"name": "Red Zone",
		"level": 3,
		"difficulty": "Hard",
		"resources": "Steel, Electronics",
		"unlocked": false,
		"color": Color(0.7, 0.2, 0.2),
		"icon": "💀"
	}
}

var selected_zone := ""

# UI References
var _background: ColorRect
var _panel: PanelContainer
var _title: Label
var _zone_buttons: Dictionary = {}
var _selected_info: Label
var _travel_button: Button
var _close_button: Button

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
	_panel.custom_minimum_size = Vector2(600, 500)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-300, -250)
	
	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.4, 0.4, 0.45)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	
	# Main container
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	_panel.add_child(vbox)
	
	# Add margin
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)
	
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 15)
	margin.add_child(content)
	
	# Title
	_title = Label.new()
	_title.text = "ZONE MAP"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	content.add_child(_title)
	
	# Zone grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	content.add_child(grid)
	
	# Create zone buttons
	for zone_id in ZONES.keys():
		var zone: Dictionary = ZONES[zone_id]
		var btn := _create_zone_button(zone_id, zone)
		_zone_buttons[zone_id] = btn
		grid.add_child(btn)
	
	# Add locked placeholder
	var locked_btn := Button.new()
	locked_btn.text = "???\n\nLOCKED"
	locked_btn.custom_minimum_size = Vector2(150, 100)
	locked_btn.disabled = true
	grid.add_child(locked_btn)
	
	# Selected info
	_selected_info = Label.new()
	_selected_info.text = "Select a zone to travel"
	_selected_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selected_info.add_theme_font_size_override("font_size", 16)
	_selected_info.custom_minimum_size = Vector2(0, 80)
	content.add_child(_selected_info)
	
	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	content.add_child(btn_row)
	
	_travel_button = Button.new()
	_travel_button.text = "TRAVEL"
	_travel_button.custom_minimum_size = Vector2(120, 50)
	_travel_button.disabled = true
	_travel_button.pressed.connect(_on_travel_pressed)
	btn_row.add_child(_travel_button)
	
	_close_button = Button.new()
	_close_button.text = "CLOSE"
	_close_button.custom_minimum_size = Vector2(120, 50)
	_close_button.pressed.connect(_on_close_pressed)
	btn_row.add_child(_close_button)


func _create_zone_button(zone_id: String, zone: Dictionary) -> Button:
	var btn := Button.new()
	btn.text = "%s\n%s\nLv.%d" % [zone.icon, zone.name, zone.level]
	btn.custom_minimum_size = Vector2(150, 100)
	
	if not zone.unlocked:
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5)
	
	# Style the button
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = zone.color * 0.6
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = zone.color * 0.8
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = zone.color
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.pressed.connect(_on_zone_selected.bind(zone_id))
	
	return btn


func _on_zone_selected(zone_id: String) -> void:
	var zone: Variant = ZONES.get(zone_id)
	if zone and zone.unlocked:
		selected_zone = zone_id
		_update_info()
		_travel_button.disabled = false
		
		# Update button visuals
		for id in _zone_buttons.keys():
			var btn: Button = _zone_buttons[id]
			if id == zone_id:
				btn.modulate = Color(1.2, 1.2, 1.2)
			else:
				btn.modulate = Color(1, 1, 1) if ZONES[id].unlocked else Color(0.5, 0.5, 0.5)


func _on_travel_pressed() -> void:
	if selected_zone != "":
		travel_requested.emit(selected_zone)
		hide()


func _on_close_pressed() -> void:
	closed.emit()
	hide()


func _update_info() -> void:
	if selected_zone == "":
		_selected_info.text = "Select a zone to travel"
		_travel_button.disabled = true
	else:
		var zone: Dictionary = ZONES[selected_zone]
		_selected_info.text = "%s\nLevel: %d\nDifficulty: %s\nResources: %s" % [
			zone.name, zone.level, zone.difficulty, zone.resources
		]


func open() -> void:
	selected_zone = ""
	_update_info()
	_travel_button.disabled = true
	
	# Reset button visuals
	for id in _zone_buttons.keys():
		var btn: Button = _zone_buttons[id]
		btn.modulate = Color(1, 1, 1) if ZONES[id].unlocked else Color(0.5, 0.5, 0.5)
	
	show()
	# Capture input
	mouse_filter = Control.MOUSE_FILTER_STOP


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
