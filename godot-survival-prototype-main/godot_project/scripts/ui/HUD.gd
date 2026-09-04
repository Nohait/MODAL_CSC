extends CanvasLayer

## HUD - LDOE-style heads-up display
## Features health/stamina bars, minimap, hotbar, status effects, and notifications

class_name HUD

# ============================================================================
# SIGNALS
# ============================================================================

signal hotbar_slot_selected(index: int)
signal quick_action_triggered(action: String)
signal minimap_expanded

# ============================================================================
# CONSTANTS
# ============================================================================

const HOTBAR_SLOTS := 6
const NOTIFICATION_DURATION := 3.0
const MAX_NOTIFICATIONS := 5

const STATUS_ICONS := {
	"bleeding": "🩸",
	"poisoned": "☠️",
	"infected": "🦠",
	"starving": "🍖",
	"dehydrated": "💧",
	"cold": "❄️",
	"hot": "🔥",
	"tired": "😴",
	"broken_bone": "🦴",
	"radiation": "☢️"
}

const STAT_COLORS := {
	"health": Color(0.8, 0.2, 0.2),
	"stamina": Color(0.9, 0.7, 0.2),
	"hunger": Color(0.6, 0.4, 0.2),
	"thirst": Color(0.3, 0.5, 0.8),
	"xp": Color(0.5, 0.8, 0.3)
}

# ============================================================================
# STATE
# ============================================================================

var current_health := 100.0
var max_health := 100.0
var current_stamina := 100.0
var max_stamina := 100.0
var current_hunger := 100.0
var current_thirst := 100.0
var current_xp := 0
var xp_to_next_level := 100
var player_level := 1

var hotbar_items: Array = []
var selected_hotbar_index := 0
var status_effects: Array = []
var notifications: Array = []

# ============================================================================
# REFERENCES
# ============================================================================

@onready var top_left: Control = $TopLeft
@onready var top_right: Control = $TopRight
@onready var bottom_center: Control = $BottomCenter
@onready var notification_container: VBoxContainer = $NotificationContainer

# Bars
@onready var health_bar: ProgressBar = $TopLeft/StatBars/HealthBar
@onready var stamina_bar: ProgressBar = $TopLeft/StatBars/StaminaBar
@onready var hunger_bar: ProgressBar = $TopLeft/StatBars/HungerBar
@onready var thirst_bar: ProgressBar = $TopLeft/StatBars/ThirstBar
@onready var xp_bar: ProgressBar = $TopLeft/XPBar

# Minimap
@onready var minimap: Control = $TopRight/Minimap

# Hotbar
@onready var hotbar: HBoxContainer = $BottomCenter/Hotbar

# Quick actions
@onready var quick_actions: HBoxContainer = $BottomRight/QuickActions

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("hud")
	layer = 100  # Always on top
	_build_ui()
	_connect_player_signals()

func _build_ui() -> void:
	# Create all HUD elements
	_create_stat_bars()
	_create_minimap()
	_create_hotbar()
	_create_quick_actions()
	_create_status_effects_panel()
	_create_notification_container()
	_create_compass()
	_create_day_night_indicator()

func _create_stat_bars() -> void:
	# Top-left container for stats
	top_left = Control.new()
	top_left.name = "TopLeft"
	top_left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_left.position = Vector2(20, 20)
	add_child(top_left)
	
	var vbox := VBoxContainer.new()
	vbox.name = "StatBars"
	vbox.add_theme_constant_override("separation", 6)
	top_left.add_child(vbox)
	
	# Player level/portrait
	var portrait_hbox := HBoxContainer.new()
	portrait_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(portrait_hbox)
	
	var portrait := Panel.new()
	portrait.custom_minimum_size = Vector2(50, 50)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.15, 0.15, 0.18)
	portrait_style.set_corner_radius_all(6)
	portrait_style.set_border_width_all(2)
	portrait_style.border_color = Color(0.4, 0.35, 0.3)
	portrait.add_theme_stylebox_override("panel", portrait_style)
	portrait_hbox.add_child(portrait)
	
	var portrait_icon := Label.new()
	portrait_icon.text = "👤"
	portrait_icon.add_theme_font_size_override("font_size", 28)
	portrait_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(portrait_icon)
	
	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv.%d" % player_level
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	level_label.position = Vector2(-20, -12)
	portrait.add_child(level_label)
	
	# Bars container
	var bars_vbox := VBoxContainer.new()
	bars_vbox.add_theme_constant_override("separation", 4)
	portrait_hbox.add_child(bars_vbox)
	
	# Health bar
	health_bar = _create_stat_bar("health", "❤️", 180)
	bars_vbox.add_child(health_bar)
	
	# Stamina bar
	stamina_bar = _create_stat_bar("stamina", "⚡", 160)
	bars_vbox.add_child(stamina_bar)
	
	# XP bar (under portrait area)
	xp_bar = ProgressBar.new()
	xp_bar.name = "XPBar"
	xp_bar.custom_minimum_size = Vector2(240, 10)
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp
	xp_bar.show_percentage = false
	vbox.add_child(xp_bar)
	
	var xp_style := StyleBoxFlat.new()
	xp_style.bg_color = Color(0.15, 0.25, 0.1)
	xp_style.set_corner_radius_all(3)
	xp_bar.add_theme_stylebox_override("background", xp_style)
	
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = STAT_COLORS.xp
	xp_fill.set_corner_radius_all(3)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	
	# Hunger/Thirst (smaller, below)
	var needs_hbox := HBoxContainer.new()
	needs_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(needs_hbox)
	
	var hunger_vbox := VBoxContainer.new()
	needs_hbox.add_child(hunger_vbox)
	
	var hunger_label := Label.new()
	hunger_label.text = "🍖"
	hunger_vbox.add_child(hunger_label)
	
	hunger_bar = _create_mini_stat_bar("hunger")
	hunger_vbox.add_child(hunger_bar)
	
	var thirst_vbox := VBoxContainer.new()
	needs_hbox.add_child(thirst_vbox)
	
	var thirst_label := Label.new()
	thirst_label.text = "💧"
	thirst_vbox.add_child(thirst_label)
	
	thirst_bar = _create_mini_stat_bar("thirst")
	thirst_vbox.add_child(thirst_bar)

func _create_stat_bar(stat_type: String, icon: String, width: float) -> ProgressBar:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 5)
	
	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(icon_label)
	
	var bar := ProgressBar.new()
	bar.name = stat_type.capitalize() + "Bar"
	bar.custom_minimum_size = Vector2(width, 18)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	bg_style.set_corner_radius_all(4)
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color(0.2, 0.2, 0.25)
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = STAT_COLORS.get(stat_type, Color.WHITE)
	fill_style.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill_style)
	
	hbox.add_child(bar)
	
	var value_label := Label.new()
	value_label.name = "Value"
	value_label.text = "100"
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.custom_minimum_size.x = 30
	hbox.add_child(value_label)
	
	# Return the container but store bar reference
	return bar

func _create_mini_stat_bar(stat_type: String) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(60, 8)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	bg_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = STAT_COLORS.get(stat_type, Color.WHITE)
	fill_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill_style)
	
	return bar

func _create_minimap() -> void:
	top_right = Control.new()
	top_right.name = "TopRight"
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-170, 20)
	add_child(top_right)
	
	# Minimap container
	minimap = Panel.new()
	minimap.name = "Minimap"
	minimap.custom_minimum_size = Vector2(150, 150)
	
	var map_style := StyleBoxFlat.new()
	map_style.bg_color = Color(0.08, 0.1, 0.08, 0.9)
	map_style.set_corner_radius_all(75)  # Circular
	map_style.set_border_width_all(3)
	map_style.border_color = Color(0.3, 0.28, 0.25)
	minimap.add_theme_stylebox_override("panel", map_style)
	top_right.add_child(minimap)
	
	# Map content (would be a SubViewport in real implementation)
	var map_content := ColorRect.new()
	map_content.name = "MapContent"
	map_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_content.anchor_left = 0.05
	map_content.anchor_right = 0.95
	map_content.anchor_top = 0.05
	map_content.anchor_bottom = 0.95
	map_content.color = Color(0.12, 0.15, 0.1, 0.9)
	minimap.add_child(map_content)
	
	# Player marker
	var player_marker := Label.new()
	player_marker.name = "PlayerMarker"
	player_marker.text = "▲"
	player_marker.add_theme_font_size_override("font_size", 14)
	player_marker.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	player_marker.set_anchors_preset(Control.PRESET_CENTER)
	player_marker.position = Vector2(-5, -7)
	minimap.add_child(player_marker)
	
	# Zone label
	var zone_label := Label.new()
	zone_label.name = "ZoneLabel"
	zone_label.text = "Green Zone"
	zone_label.add_theme_font_size_override("font_size", 10)
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_label.position = Vector2(0, 155)
	zone_label.custom_minimum_size.x = 150
	top_right.add_child(zone_label)
	
	# Coordinates
	var coords := Label.new()
	coords.name = "Coordinates"
	coords.text = "X: 0  Y: 0"
	coords.add_theme_font_size_override("font_size", 9)
	coords.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	coords.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coords.position = Vector2(0, 168)
	coords.custom_minimum_size.x = 150
	top_right.add_child(coords)

func _create_compass() -> void:
	var compass := HBoxContainer.new()
	compass.name = "Compass"
	compass.set_anchors_preset(Control.PRESET_CENTER_TOP)
	compass.position = Vector2(-100, 15)
	
	var compass_bg := Panel.new()
	compass_bg.custom_minimum_size = Vector2(200, 30)
	var compass_style := StyleBoxFlat.new()
	compass_style.bg_color = Color(0.08, 0.08, 0.1, 0.8)
	compass_style.set_corner_radius_all(4)
	compass_bg.add_theme_stylebox_override("panel", compass_style)
	compass.add_child(compass_bg)
	
	var directions := Label.new()
	directions.name = "Directions"
	directions.text = "W ━━━━━ N ━━━━━ E"
	directions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	directions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	directions.set_anchors_preset(Control.PRESET_FULL_RECT)
	compass_bg.add_child(directions)
	
	add_child(compass)

func _create_hotbar() -> void:
	bottom_center = Control.new()
	bottom_center.name = "BottomCenter"
	bottom_center.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom_center.position = Vector2(-((HOTBAR_SLOTS * 64 + (HOTBAR_SLOTS - 1) * 6) / 2), -90)
	add_child(bottom_center)
	
	var hotbar_bg := Panel.new()
	hotbar_bg.name = "HotbarBG"
	hotbar_bg.custom_minimum_size = Vector2(HOTBAR_SLOTS * 64 + (HOTBAR_SLOTS - 1) * 6 + 16, 72)
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	bg_style.set_corner_radius_all(8)
	bg_style.set_border_width_all(2)
	bg_style.border_color = Color(0.25, 0.25, 0.3)
	hotbar_bg.add_theme_stylebox_override("panel", bg_style)
	bottom_center.add_child(hotbar_bg)
	
	hotbar = HBoxContainer.new()
	hotbar.name = "Hotbar"
	hotbar.add_theme_constant_override("separation", 6)
	hotbar.position = Vector2(8, 4)
	bottom_center.add_child(hotbar)
	
	for i in range(HOTBAR_SLOTS):
		var slot := _create_hotbar_slot(i)
		hotbar.add_child(slot)

func _create_hotbar_slot(index: int) -> Control:
	var slot := Panel.new()
	slot.name = "Slot_" + str(index)
	slot.custom_minimum_size = Vector2(64, 64)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.35, 0.35, 0.4) if index == selected_hotbar_index else Color(0.25, 0.25, 0.3)
	style.set_corner_radius_all(6)
	slot.add_theme_stylebox_override("panel", style)
	
	# Keybind label
	var key_label := Label.new()
	key_label.name = "KeyLabel"
	key_label.text = str(index + 1)
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	key_label.position = Vector2(4, 2)
	slot.add_child(key_label)
	
	# Item icon placeholder
	var item_icon := Label.new()
	item_icon.name = "ItemIcon"
	item_icon.text = ""
	item_icon.add_theme_font_size_override("font_size", 28)
	item_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(item_icon)
	
	# Stack count
	var stack_label := Label.new()
	stack_label.name = "StackLabel"
	stack_label.text = ""
	stack_label.add_theme_font_size_override("font_size", 11)
	stack_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	stack_label.position = Vector2(-20, -15)
	slot.add_child(stack_label)
	
	# Durability bar
	var durability := ProgressBar.new()
	durability.name = "DurabilityBar"
	durability.custom_minimum_size = Vector2(54, 4)
	durability.max_value = 100
	durability.value = 100
	durability.show_percentage = false
	durability.position = Vector2(5, 55)
	durability.visible = false
	slot.add_child(durability)
	
	# Cooldown overlay
	var cooldown := ColorRect.new()
	cooldown.name = "Cooldown"
	cooldown.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown.color = Color(0, 0, 0, 0.6)
	cooldown.visible = false
	slot.add_child(cooldown)
	
	# Input
	slot.gui_input.connect(_on_hotbar_slot_input.bind(index))
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	
	return slot

func _create_quick_actions() -> void:
	var bottom_right := Control.new()
	bottom_right.name = "BottomRight"
	bottom_right.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom_right.position = Vector2(-200, -90)
	add_child(bottom_right)
	
	quick_actions = HBoxContainer.new()
	quick_actions.name = "QuickActions"
	quick_actions.add_theme_constant_override("separation", 10)
	bottom_right.add_child(quick_actions)
	
	var actions := [
		{"icon": "🎒", "action": "inventory", "key": "I"},
		{"icon": "🔧", "action": "crafting", "key": "C"},
		{"icon": "🏗️", "action": "building", "key": "B"},
		{"icon": "📋", "action": "quests", "key": "J"}
	]
	
	for action_data in actions:
		var btn := _create_quick_action_button(action_data)
		quick_actions.add_child(btn)

func _create_quick_action_button(data: Dictionary) -> Button:
	var btn := Button.new()
	btn.text = data.icon
	btn.custom_minimum_size = Vector2(44, 44)
	btn.tooltip_text = "%s (%s)" % [data.action.capitalize(), data.key]
	btn.pressed.connect(func(): quick_action_triggered.emit(data.action))
	
	return btn

func _create_status_effects_panel() -> void:
	var effects_container := HBoxContainer.new()
	effects_container.name = "StatusEffects"
	effects_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	effects_container.position = Vector2(20, 180)
	effects_container.add_theme_constant_override("separation", 8)
	add_child(effects_container)

func _create_notification_container() -> void:
	notification_container = VBoxContainer.new()
	notification_container.name = "NotificationContainer"
	notification_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_container.position = Vector2(-150, 60)
	notification_container.custom_minimum_size.x = 300
	notification_container.add_theme_constant_override("separation", 5)
	add_child(notification_container)

func _create_day_night_indicator() -> void:
	var indicator := HBoxContainer.new()
	indicator.name = "DayNightIndicator"
	indicator.position = Vector2(0, 185)
	top_right.add_child(indicator)
	
	var icon := Label.new()
	icon.name = "TimeIcon"
	icon.text = "☀️"
	icon.add_theme_font_size_override("font_size", 18)
	indicator.add_child(icon)
	
	var time_label := Label.new()
	time_label.name = "TimeLabel"
	time_label.text = " Day 1 - 12:00"
	time_label.add_theme_font_size_override("font_size", 12)
	indicator.add_child(time_label)

func _connect_player_signals() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(_on_stamina_changed)
		if player.has_signal("hunger_changed"):
			player.hunger_changed.connect(_on_hunger_changed)
		if player.has_signal("thirst_changed"):
			player.thirst_changed.connect(_on_thirst_changed)
		if player.has_signal("xp_changed"):
			player.xp_changed.connect(_on_xp_changed)

# ============================================================================
# INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Hotbar keys 1-6
		if event.keycode >= Key.KEY_1 and event.keycode <= Key.KEY_6:
			var index := event.keycode - Key.KEY_1
			select_hotbar_slot(index)
			get_viewport().set_input_as_handled()

func _on_hotbar_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			select_hotbar_slot(index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_use_hotbar_item(index)

# ============================================================================
# UPDATE METHODS
# ============================================================================

func _on_health_changed(value: float, max_value: float) -> void:
	current_health = value
	max_health = max_value
	_animate_bar(health_bar, value, max_value)
	
	# Flash on low health
	if value / max_value < 0.25:
		_flash_bar(health_bar, Color(1, 0, 0, 0.5))

func _on_stamina_changed(value: float, max_value: float) -> void:
	current_stamina = value
	max_stamina = max_value
	_animate_bar(stamina_bar, value, max_value)

func _on_hunger_changed(value: float) -> void:
	current_hunger = value
	if hunger_bar:
		hunger_bar.value = value
	
	if value < 25:
		add_status_effect("starving")
	else:
		remove_status_effect("starving")

func _on_thirst_changed(value: float) -> void:
	current_thirst = value
	if thirst_bar:
		thirst_bar.value = value
	
	if value < 25:
		add_status_effect("dehydrated")
	else:
		remove_status_effect("dehydrated")

func _on_xp_changed(value: int, required: int, level: int) -> void:
	current_xp = value
	xp_to_next_level = required
	player_level = level
	
	if xp_bar:
		xp_bar.max_value = required
		xp_bar.value = value
	
	var level_label: Label = top_left.get_node_or_null("StatBars/HBoxContainer/Panel/LevelLabel")
	if level_label:
		level_label.text = "Lv.%d" % level

func _animate_bar(bar: ProgressBar, value: float, max_value: float) -> void:
	if not bar:
		return
	
	bar.max_value = max_value
	
	var tween := create_tween()
	tween.tween_property(bar, "value", value, 0.2).set_ease(Tween.EASE_OUT)

func _flash_bar(bar: ProgressBar, color: Color) -> void:
	if not bar:
		return
	
	var tween := create_tween()
	tween.tween_property(bar, "modulate", color, 0.1)
	tween.tween_property(bar, "modulate", Color.WHITE, 0.1)
	tween.set_loops(3)

# ============================================================================
# HOTBAR
# ============================================================================

func select_hotbar_slot(index: int) -> void:
	if index < 0 or index >= HOTBAR_SLOTS:
		return
	
	# Deselect previous
	var prev_slot: Panel = hotbar.get_node_or_null("Slot_" + str(selected_hotbar_index))
	if prev_slot:
		var style: StyleBoxFlat = prev_slot.get_theme_stylebox("panel").duplicate()
		style.border_color = Color(0.25, 0.25, 0.3)
		prev_slot.add_theme_stylebox_override("panel", style)
	
	selected_hotbar_index = index
	
	# Select new
	var new_slot: Panel = hotbar.get_node_or_null("Slot_" + str(index))
	if new_slot:
		var style: StyleBoxFlat = new_slot.get_theme_stylebox("panel").duplicate()
		style.border_color = Color(0.9, 0.7, 0.3)
		new_slot.add_theme_stylebox_override("panel", style)
	
	hotbar_slot_selected.emit(index)

func set_hotbar_item(index: int, item_data: Dictionary) -> void:
	if index < 0 or index >= HOTBAR_SLOTS:
		return
	
	var slot: Panel = hotbar.get_node_or_null("Slot_" + str(index))
	if not slot:
		return
	
	var icon_label: Label = slot.get_node_or_null("ItemIcon")
	var stack_label: Label = slot.get_node_or_null("StackLabel")
	var durability_bar: ProgressBar = slot.get_node_or_null("DurabilityBar")
	
	if item_data.is_empty():
		if icon_label:
			icon_label.text = ""
		if stack_label:
			stack_label.text = ""
		if durability_bar:
			durability_bar.visible = false
	else:
		if icon_label:
			icon_label.text = item_data.get("icon", "?")
		if stack_label:
			var count: int = item_data.get("count", 1)
			stack_label.text = str(count) if count > 1 else ""
		if durability_bar and item_data.has("durability"):
			durability_bar.max_value = item_data.get("max_durability", 100)
			durability_bar.value = item_data.get("durability", 100)
			durability_bar.visible = true

func _use_hotbar_item(index: int) -> void:
	# Emit signal for player/inventory to handle
	pass

# ============================================================================
# STATUS EFFECTS
# ============================================================================

func add_status_effect(effect_id: String) -> void:
	if effect_id in status_effects:
		return
	
	status_effects.append(effect_id)
	_update_status_effects_display()

func remove_status_effect(effect_id: String) -> void:
	status_effects.erase(effect_id)
	_update_status_effects_display()

func _update_status_effects_display() -> void:
	var container: HBoxContainer = get_node_or_null("StatusEffects")
	if not container:
		return
	
	for child in container.get_children():
		child.queue_free()
	
	for effect_id in status_effects:
		var effect_panel := Panel.new()
		effect_panel.custom_minimum_size = Vector2(36, 36)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.1, 0.1, 0.9)
		style.set_corner_radius_all(6)
		style.set_border_width_all(1)
		style.border_color = Color(0.8, 0.3, 0.3)
		effect_panel.add_theme_stylebox_override("panel", style)
		
		var icon := Label.new()
		icon.text = STATUS_ICONS.get(effect_id, "?")
		icon.add_theme_font_size_override("font_size", 20)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		effect_panel.add_child(icon)
		
		container.add_child(effect_panel)

# ============================================================================
# NOTIFICATIONS
# ============================================================================

func show_notification(text: String, type: String = "info") -> void:
	# Limit notifications
	while notification_container.get_child_count() >= MAX_NOTIFICATIONS:
		notification_container.get_child(0).queue_free()
	
	var notif := Panel.new()
	notif.custom_minimum_size.y = 36
	
	var style := StyleBoxFlat.new()
	match type:
		"success":
			style.bg_color = Color(0.15, 0.25, 0.15, 0.95)
			style.border_color = Color(0.4, 0.7, 0.4)
		"warning":
			style.bg_color = Color(0.25, 0.2, 0.1, 0.95)
			style.border_color = Color(0.8, 0.6, 0.3)
		"error":
			style.bg_color = Color(0.25, 0.1, 0.1, 0.95)
			style.border_color = Color(0.8, 0.3, 0.3)
		_:
			style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
			style.border_color = Color(0.4, 0.4, 0.5)
	
	style.set_corner_radius_all(6)
	style.set_border_width_all(1)
	notif.add_theme_stylebox_override("panel", style)
	
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	notif.add_child(label)
	
	# Animate in
	notif.modulate.a = 0
	notification_container.add_child(notif)
	
	var tween := create_tween()
	tween.tween_property(notif, "modulate:a", 1.0, 0.2)
	tween.tween_interval(NOTIFICATION_DURATION)
	tween.tween_property(notif, "modulate:a", 0.0, 0.3)
	tween.tween_callback(notif.queue_free)

func show_item_pickup(item_name: String, count: int = 1) -> void:
	var text := "+ %s" % item_name
	if count > 1:
		text += " x%d" % count
	show_notification(text, "success")

func show_damage_number(amount: int, position: Vector2) -> void:
	# Create floating damage text
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	label.position = position
	add_child(label)
	
	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", position.y - 50, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

# ============================================================================
# MINIMAP
# ============================================================================

func update_minimap_position(player_pos: Vector2) -> void:
	var coords: Label = top_right.get_node_or_null("Coordinates")
	if coords:
		coords.text = "X: %d  Y: %d" % [int(player_pos.x), int(player_pos.y)]

func update_minimap_zone(zone_name: String) -> void:
	var zone_label: Label = top_right.get_node_or_null("ZoneLabel")
	if zone_label:
		zone_label.text = zone_name

func update_minimap_rotation(angle: float) -> void:
	var player_marker: Label = minimap.get_node_or_null("PlayerMarker")
	if player_marker:
		player_marker.rotation = angle

# ============================================================================
# TIME
# ============================================================================

func update_time_display(day: int, hour: int, minute: int, is_night: bool) -> void:
	var indicator: HBoxContainer = top_right.get_node_or_null("DayNightIndicator")
	if not indicator:
		return
	
	var icon: Label = indicator.get_node_or_null("TimeIcon")
	var time_label: Label = indicator.get_node_or_null("TimeLabel")
	
	if icon:
		icon.text = "🌙" if is_night else "☀️"
	
	if time_label:
		time_label.text = " Day %d - %02d:%02d" % [day, hour, minute]

# ============================================================================
# PUBLIC API
# ============================================================================

func refresh() -> void:
	# Refresh all displays from current state
	_connect_player_signals()
