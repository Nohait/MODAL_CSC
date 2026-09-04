extends Control

## QuestUI - LDOE-style quest interface with daily/weekly/story missions
## Features quest tracking, rewards preview, and progress visualization

class_name QuestUI

# ============================================================================
# SIGNALS
# ============================================================================

signal quest_ui_opened
signal quest_ui_closed
signal quest_selected(quest_id: String)
signal quest_tracked(quest_id: String)
signal quest_claimed(quest_id: String)

# ============================================================================
# CONSTANTS
# ============================================================================

const QUEST_TYPES := {
	"daily": {"name": "Daily", "icon": "📅", "color": Color(0.4, 0.8, 0.4)},
	"weekly": {"name": "Weekly", "icon": "📆", "color": Color(0.4, 0.6, 0.9)},
	"story": {"name": "Story", "icon": "📖", "color": Color(0.9, 0.7, 0.3)},
	"event": {"name": "Event", "icon": "⭐", "color": Color(0.9, 0.4, 0.8)}
}

const REWARD_ICONS := {
	"xp": "✨",
	"coins": "🪙",
	"item": "📦",
	"blueprint": "📜",
	"reputation": "⭐"
}

# ============================================================================
# STATE
# ============================================================================

var is_open := false
var current_tab := "daily"
var selected_quest_id := ""
var tracked_quest_id := ""

var quest_data: Dictionary = {
	"daily": [],
	"weekly": [],
	"story": [],
	"event": []
}

# ============================================================================
# REFERENCES
# ============================================================================

@onready var background: ColorRect = $Background
@onready var main_panel: PanelContainer = $MainPanel
@onready var tab_container: HBoxContainer = $MainPanel/Content/TabContainer
@onready var quest_scroll: ScrollContainer = $MainPanel/Content/QuestScroll
@onready var quest_list: VBoxContainer = $MainPanel/Content/QuestScroll/QuestList
@onready var details_panel: PanelContainer = $MainPanel/Content/DetailsPanel
@onready var details_content: VBoxContainer = $MainPanel/Content/DetailsPanel/Content
@onready var timer_label: Label = $MainPanel/Content/TimerLabel
@onready var claim_button: Button = $MainPanel/Content/DetailsPanel/ClaimButton
@onready var track_button: Button = $MainPanel/Content/DetailsPanel/TrackButton

# Tracker overlay (always visible when tracking)
@onready var tracker_panel: PanelContainer = $TrackerPanel

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("quest_ui")
	_build_ui()
	_connect_signals()
	_load_quest_data()
	hide()

func _build_ui() -> void:
	if not has_node("Background"):
		_create_ui_structure()
	
	_populate_tabs()
	_create_tracker_panel()

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
	main_panel.custom_minimum_size = Vector2(800, 550)
	main_panel.position = -main_panel.custom_minimum_size / 2
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.15, 0.98)
	panel_style.set_corner_radius_all(10)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.3, 0.28, 0.25)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(main_panel)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.name = "Content"
	main_vbox.add_theme_constant_override("separation", 10)
	main_panel.add_child(main_vbox)
	
	# Header
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 50
	main_vbox.add_child(header)
	
	var title := Label.new()
	title.text = "📋 MISSIONS"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "Resets in: 23:59:59"
	timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	header.add_child(timer_label)
	
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)
	
	# Tab container
	tab_container = HBoxContainer.new()
	tab_container.name = "TabContainer"
	tab_container.add_theme_constant_override("separation", 5)
	main_vbox.add_child(tab_container)
	
	# Content area
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 15)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)
	
	# Quest list (left)
	quest_scroll = ScrollContainer.new()
	quest_scroll.name = "QuestScroll"
	quest_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(quest_scroll)
	
	quest_list = VBoxContainer.new()
	quest_list.name = "QuestList"
	quest_list.add_theme_constant_override("separation", 8)
	quest_scroll.add_child(quest_list)
	
	# Details panel (right)
	details_panel = PanelContainer.new()
	details_panel.name = "DetailsPanel"
	details_panel.custom_minimum_size.x = 280
	var details_style := StyleBoxFlat.new()
	details_style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	details_style.set_corner_radius_all(8)
	details_panel.add_theme_stylebox_override("panel", details_style)
	details_panel.visible = false
	content_hbox.add_child(details_panel)
	
	var details_vbox := VBoxContainer.new()
	details_vbox.add_theme_constant_override("separation", 10)
	details_panel.add_child(details_vbox)
	
	details_content = VBoxContainer.new()
	details_content.name = "Content"
	details_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_vbox.add_child(details_content)
	
	track_button = Button.new()
	track_button.name = "TrackButton"
	track_button.text = "📍 TRACK"
	track_button.custom_minimum_size.y = 36
	track_button.pressed.connect(_on_track_pressed)
	details_vbox.add_child(track_button)
	
	claim_button = Button.new()
	claim_button.name = "ClaimButton"
	claim_button.text = "🎁 CLAIM REWARD"
	claim_button.custom_minimum_size.y = 44
	claim_button.disabled = true
	claim_button.pressed.connect(_on_claim_pressed)
	details_vbox.add_child(claim_button)

func _create_tracker_panel() -> void:
	# Mini quest tracker (always visible when tracking)
	tracker_panel = PanelContainer.new()
	tracker_panel.name = "TrackerPanel"
	tracker_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tracker_panel.custom_minimum_size = Vector2(250, 80)
	tracker_panel.position = Vector2(-260, 10)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	style.set_corner_radius_all(8)
	style.border_color = Color(0.4, 0.35, 0.3)
	style.set_border_width_all(1)
	tracker_panel.add_theme_stylebox_override("panel", style)
	
	var tracker_content := VBoxContainer.new()
	tracker_content.name = "TrackerContent"
	tracker_panel.add_child(tracker_content)
	
	var tracker_title := Label.new()
	tracker_title.name = "TrackerTitle"
	tracker_title.text = "📍 Tracked Quest"
	tracker_title.add_theme_font_size_override("font_size", 12)
	tracker_content.add_child(tracker_title)
	
	var tracker_desc := Label.new()
	tracker_desc.name = "TrackerDesc"
	tracker_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	tracker_content.add_child(tracker_desc)
	
	var tracker_progress := ProgressBar.new()
	tracker_progress.name = "TrackerProgress"
	tracker_progress.custom_minimum_size.y = 16
	tracker_progress.max_value = 100
	tracker_content.add_child(tracker_progress)
	
	tracker_panel.visible = false
	
	# Add to UI layer (not main panel, so it's always visible)
	add_child(tracker_panel)

func _populate_tabs() -> void:
	for child in tab_container.get_children():
		child.queue_free()
	
	for tab_id in QUEST_TYPES:
		var tab_data: Dictionary = QUEST_TYPES[tab_id]
		
		var btn := Button.new()
		btn.text = "%s %s" % [tab_data.icon, tab_data.name]
		btn.custom_minimum_size = Vector2(100, 40)
		btn.toggle_mode = true
		btn.button_pressed = tab_id == current_tab
		btn.pressed.connect(_on_tab_selected.bind(tab_id))
		
		# Add notification badge
		var quest_count: int = quest_data.get(tab_id, []).size()
		var claimable := _count_claimable_quests(tab_id)
		if claimable > 0:
			var badge := Label.new()
			badge.text = str(claimable)
			badge.add_theme_font_size_override("font_size", 10)
			badge.add_theme_color_override("font_color", Color.WHITE)
			badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			badge.position = Vector2(-15, 2)
			
			var badge_bg := ColorRect.new()
			badge_bg.color = Color(0.9, 0.3, 0.3)
			badge_bg.size = Vector2(16, 16)
			badge_bg.position = Vector2(-8, -2)
			badge.add_child(badge_bg)
			badge_bg.z_index = -1
			
			btn.add_child(badge)
		
		tab_container.add_child(btn)

func _connect_signals() -> void:
	background.gui_input.connect(_on_background_input)

func _load_quest_data() -> void:
	# Get quests from QuestSystem if available
	var quest_system := get_tree().get_first_node_in_group("quest_system")
	if quest_system and "active_quests" in quest_system:
		for quest in quest_system.active_quests:
			var quest_type: String = quest.get("type", "daily")
			if quest_data.has(quest_type):
				quest_data[quest_type].append(quest)
	
	# Fallback sample data
	if _all_quests_empty():
		quest_data = _get_sample_quests()

func _get_sample_quests() -> Dictionary:
	return {
		"daily": [
			{
				"id": "daily_kill_10",
				"name": "Zombie Hunter",
				"description": "Kill 10 zombies in any zone",
				"type": "daily",
				"objectives": [{"type": "kill", "target": "zombie", "current": 7, "required": 10}],
				"rewards": [{"type": "xp", "amount": 100}, {"type": "coins", "amount": 50}],
				"completed": false,
				"claimed": false
			},
			{
				"id": "daily_gather_wood",
				"name": "Lumber Jack",
				"description": "Gather 20 wood from trees",
				"type": "daily",
				"objectives": [{"type": "gather", "target": "wood", "current": 20, "required": 20}],
				"rewards": [{"type": "xp", "amount": 75}, {"type": "item", "item_id": "bandage", "amount": 3}],
				"completed": true,
				"claimed": false
			},
			{
				"id": "daily_craft",
				"name": "Craftsman",
				"description": "Craft any 3 items",
				"type": "daily",
				"objectives": [{"type": "craft", "current": 1, "required": 3}],
				"rewards": [{"type": "xp", "amount": 50}],
				"completed": false,
				"claimed": false
			}
		],
		"weekly": [
			{
				"id": "weekly_boss",
				"name": "Boss Slayer",
				"description": "Defeat any boss enemy",
				"type": "weekly",
				"objectives": [{"type": "kill", "target": "boss", "current": 0, "required": 1}],
				"rewards": [{"type": "xp", "amount": 500}, {"type": "coins", "amount": 200}, {"type": "item", "item_id": "medkit", "amount": 2}],
				"completed": false,
				"claimed": false
			},
			{
				"id": "weekly_explore",
				"name": "Explorer",
				"description": "Visit all 3 zones",
				"type": "weekly",
				"objectives": [{"type": "visit", "zones": ["green", "yellow", "red"], "visited": ["green"], "required": 3}],
				"rewards": [{"type": "xp", "amount": 300}, {"type": "blueprint", "item_id": "iron_hatchet"}],
				"completed": false,
				"claimed": false
			}
		],
		"story": [
			{
				"id": "story_intro",
				"name": "First Steps",
				"description": "Learn the basics of survival",
				"type": "story",
				"chapter": 1,
				"objectives": [
					{"type": "craft", "target": "bandage", "current": 1, "required": 1, "label": "Craft a bandage"},
					{"type": "build", "target": "any", "current": 0, "required": 1, "label": "Build something"}
				],
				"rewards": [{"type": "xp", "amount": 200}, {"type": "item", "item_id": "wood_club", "amount": 1}],
				"completed": false,
				"claimed": false
			}
		],
		"event": []
	}

func _all_quests_empty() -> bool:
	for tab in quest_data:
		if not quest_data[tab].is_empty():
			return false
	return true

# ============================================================================
# INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_J or event.keycode == KEY_L:
			toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and is_open:
			close()
			get_viewport().set_input_as_handled()

func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _on_tab_selected(tab_id: String) -> void:
	current_tab = tab_id
	selected_quest_id = ""
	details_panel.visible = false
	
	# Update button states
	for btn in tab_container.get_children():
		if btn is Button:
			btn.button_pressed = btn.text.contains(QUEST_TYPES[tab_id].name)
	
	_populate_quest_list()
	_update_timer_label()

func _on_quest_selected(quest_id: String) -> void:
	selected_quest_id = quest_id
	_update_details_panel()
	details_panel.visible = true
	quest_selected.emit(quest_id)

func _on_track_pressed() -> void:
	if selected_quest_id.is_empty():
		return
	
	if tracked_quest_id == selected_quest_id:
		tracked_quest_id = ""
		tracker_panel.visible = false
	else:
		tracked_quest_id = selected_quest_id
		_update_tracker()
		tracker_panel.visible = true
	
	_update_details_panel()
	quest_tracked.emit(tracked_quest_id)

func _on_claim_pressed() -> void:
	if selected_quest_id.is_empty():
		return
	
	var quest := _get_quest_by_id(selected_quest_id)
	if not quest or not quest.get("completed", false) or quest.get("claimed", false):
		return
	
	# Grant rewards
	_grant_rewards(quest.get("rewards", []))
	
	# Mark as claimed
	quest["claimed"] = true
	
	quest_claimed.emit(selected_quest_id)
	
	_update_details_panel()
	_populate_quest_list()
	_populate_tabs()

# ============================================================================
# QUEST LIST
# ============================================================================

func _populate_quest_list() -> void:
	for child in quest_list.get_children():
		child.queue_free()
	
	var quests: Array = quest_data.get(current_tab, [])
	
	if quests.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No quests available"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		quest_list.add_child(empty_label)
		return
	
	for quest in quests:
		var quest_entry := _create_quest_entry(quest)
		quest_list.add_child(quest_entry)

func _create_quest_entry(quest: Dictionary) -> Control:
	var entry := Panel.new()
	entry.name = "Quest_" + quest.get("id", "")
	entry.custom_minimum_size = Vector2(0, 70)
	
	var is_completed: bool = quest.get("completed", false)
	var is_claimed: bool = quest.get("claimed", false)
	var is_tracked: bool = quest.get("id", "") == tracked_quest_id
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 0.95)
	style.set_border_width_all(2)
	
	if is_claimed:
		style.border_color = Color(0.3, 0.3, 0.3)
		style.bg_color = Color(0.12, 0.12, 0.14, 0.8)
	elif is_completed:
		style.border_color = Color(0.3, 0.9, 0.3)
	elif is_tracked:
		style.border_color = Color(0.9, 0.7, 0.3)
	else:
		style.border_color = Color(0.3, 0.3, 0.35)
	
	style.set_corner_radius_all(6)
	entry.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	entry.add_child(hbox)
	
	# Status icon
	var status_icon := Label.new()
	status_icon.custom_minimum_size.x = 30
	if is_claimed:
		status_icon.text = "✓"
		status_icon.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	elif is_completed:
		status_icon.text = "🎁"
	elif is_tracked:
		status_icon.text = "📍"
	else:
		status_icon.text = "○"
	status_icon.add_theme_font_size_override("font_size", 20)
	status_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(status_icon)
	
	# Quest info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label := Label.new()
	name_label.text = quest.get("name", "Unknown Quest")
	name_label.add_theme_font_size_override("font_size", 14)
	if is_claimed:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	info_vbox.add_child(name_label)
	
	# Progress
	var objectives: Array = quest.get("objectives", [])
	if not objectives.is_empty():
		var obj: Dictionary = objectives[0]
		var current: int = obj.get("current", 0)
		var required: int = obj.get("required", 1)
		
		var progress_hbox := HBoxContainer.new()
		info_vbox.add_child(progress_hbox)
		
		var progress_bar := ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(150, 12)
		progress_bar.max_value = required
		progress_bar.value = current
		progress_bar.show_percentage = false
		progress_hbox.add_child(progress_bar)
		
		var progress_label := Label.new()
		progress_label.text = " %d/%d" % [current, required]
		progress_label.add_theme_font_size_override("font_size", 11)
		if is_claimed:
			progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		progress_hbox.add_child(progress_label)
	
	# Reward preview
	var rewards: Array = quest.get("rewards", [])
	if not rewards.is_empty():
		var rewards_hbox := HBoxContainer.new()
		hbox.add_child(rewards_hbox)
		
		for reward in rewards:
			var reward_icon := Label.new()
			reward_icon.text = REWARD_ICONS.get(reward.get("type", ""), "?")
			reward_icon.add_theme_font_size_override("font_size", 16)
			rewards_hbox.add_child(reward_icon)
	
	# Input
	entry.gui_input.connect(_on_quest_entry_input.bind(quest.get("id", "")))
	
	return entry

func _on_quest_entry_input(event: InputEvent, quest_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_quest_selected(quest_id)

# ============================================================================
# DETAILS PANEL
# ============================================================================

func _update_details_panel() -> void:
	for child in details_content.get_children():
		child.queue_free()
	
	var quest := _get_quest_by_id(selected_quest_id)
	if not quest:
		return
	
	var is_completed: bool = quest.get("completed", false)
	var is_claimed: bool = quest.get("claimed", false)
	
	# Title
	var title := Label.new()
	title.text = quest.get("name", "Unknown")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", QUEST_TYPES[current_tab].color)
	details_content.add_child(title)
	
	# Description
	var desc := Label.new()
	desc.text = quest.get("description", "")
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	details_content.add_child(desc)
	
	# Separator
	details_content.add_child(HSeparator.new())
	
	# Objectives
	var obj_label := Label.new()
	obj_label.text = "OBJECTIVES"
	obj_label.add_theme_font_size_override("font_size", 12)
	details_content.add_child(obj_label)
	
	var objectives: Array = quest.get("objectives", [])
	for obj in objectives:
		var obj_row := HBoxContainer.new()
		
		var check := Label.new()
		var current: int = obj.get("current", 0)
		var required: int = obj.get("required", 1)
		check.text = "✓ " if current >= required else "○ "
		check.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4) if current >= required else Color(0.6, 0.6, 0.6))
		obj_row.add_child(check)
		
		var obj_text := Label.new()
		obj_text.text = obj.get("label", "%s %s: %d/%d" % [obj.get("type", ""), obj.get("target", ""), current, required])
		obj_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		obj_row.add_child(obj_text)
		
		details_content.add_child(obj_row)
	
	# Rewards
	details_content.add_child(HSeparator.new())
	
	var rewards_label := Label.new()
	rewards_label.text = "REWARDS"
	rewards_label.add_theme_font_size_override("font_size", 12)
	details_content.add_child(rewards_label)
	
	var rewards: Array = quest.get("rewards", [])
	for reward in rewards:
		var reward_row := HBoxContainer.new()
		
		var reward_icon := Label.new()
		reward_icon.text = REWARD_ICONS.get(reward.get("type", ""), "?") + " "
		reward_row.add_child(reward_icon)
		
		var reward_text := Label.new()
		match reward.get("type", ""):
			"xp":
				reward_text.text = "%d XP" % reward.get("amount", 0)
				reward_text.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
			"coins":
				reward_text.text = "%d Coins" % reward.get("amount", 0)
				reward_text.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
			"item":
				reward_text.text = "%s x%d" % [reward.get("item_id", "").capitalize(), reward.get("amount", 1)]
			"blueprint":
				reward_text.text = "Blueprint: %s" % reward.get("item_id", "").capitalize()
				reward_text.add_theme_color_override("font_color", Color(0.4, 0.7, 0.9))
			_:
				reward_text.text = str(reward)
		reward_row.add_child(reward_text)
		
		details_content.add_child(reward_row)
	
	# Update buttons
	track_button.text = "📍 UNTRACK" if tracked_quest_id == selected_quest_id else "📍 TRACK"
	track_button.disabled = is_claimed
	
	claim_button.disabled = not is_completed or is_claimed
	claim_button.text = "✓ CLAIMED" if is_claimed else ("🎁 CLAIM REWARD" if is_completed else "IN PROGRESS")

func _update_tracker() -> void:
	if tracked_quest_id.is_empty():
		tracker_panel.visible = false
		return
	
	var quest := _get_quest_by_id(tracked_quest_id)
	if not quest:
		tracker_panel.visible = false
		return
	
	var tracker_content := tracker_panel.get_node_or_null("TrackerContent")
	if not tracker_content:
		return
	
	var tracker_title: Label = tracker_content.get_node_or_null("TrackerTitle")
	var tracker_desc: Label = tracker_content.get_node_or_null("TrackerDesc")
	var tracker_progress: ProgressBar = tracker_content.get_node_or_null("TrackerProgress")
	
	if tracker_title:
		tracker_title.text = "📍 " + quest.get("name", "Unknown")
	
	var objectives: Array = quest.get("objectives", [])
	if not objectives.is_empty() and tracker_desc and tracker_progress:
		var obj: Dictionary = objectives[0]
		var current: int = obj.get("current", 0)
		var required: int = obj.get("required", 1)
		
		tracker_desc.text = obj.get("label", quest.get("description", ""))
		tracker_progress.max_value = required
		tracker_progress.value = current
	
	tracker_panel.visible = true

func _update_timer_label() -> void:
	var type_data: Dictionary = QUEST_TYPES.get(current_tab, {})
	
	match current_tab:
		"daily":
			# Time until midnight
			var datetime := Time.get_datetime_dict_from_system()
			var hours_left := 23 - datetime.hour
			var mins_left := 59 - datetime.minute
			timer_label.text = "Resets in: %02d:%02d:00" % [hours_left, mins_left]
		"weekly":
			# Days until Sunday
			var datetime := Time.get_datetime_dict_from_system()
			var days_left := 7 - datetime.weekday
			timer_label.text = "Resets in: %d days" % days_left
		"story":
			timer_label.text = "Chapter %d" % _get_current_chapter()
		"event":
			timer_label.text = "Limited Time!"

# ============================================================================
# HELPERS
# ============================================================================

func _get_quest_by_id(quest_id: String) -> Dictionary:
	for tab in quest_data:
		for quest in quest_data[tab]:
			if quest.get("id", "") == quest_id:
				return quest
	return {}

func _count_claimable_quests(tab_id: String) -> int:
	var count := 0
	for quest in quest_data.get(tab_id, []):
		if quest.get("completed", false) and not quest.get("claimed", false):
			count += 1
	return count

func _get_current_chapter() -> int:
	var highest := 0
	for quest in quest_data.get("story", []):
		if quest.get("claimed", false):
			highest = max(highest, quest.get("chapter", 0))
	return highest + 1

func _grant_rewards(rewards: Array) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var inventory := get_tree().get_first_node_in_group("inventory")
	
	for reward in rewards:
		match reward.get("type", ""):
			"xp":
				if player and player.has_method("add_xp"):
					player.add_xp(reward.get("amount", 0))
			"coins":
				# Add to currency
				pass
			"item":
				if inventory and inventory.has_method("add_item"):
					inventory.add_item(reward.get("item_id", ""), reward.get("amount", 1))
			"blueprint":
				var crafting_ui := get_tree().get_first_node_in_group("crafting_ui")
				if crafting_ui and crafting_ui.has_method("learn_recipe"):
					crafting_ui.learn_recipe(reward.get("item_id", ""))

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
	
	_populate_tabs()
	_populate_quest_list()
	_update_timer_label()
	
	quest_ui_opened.emit()
	
	# Animate
	main_panel.modulate.a = 0
	main_panel.scale = Vector2(0.95, 0.95)
	var tween := create_tween().set_parallel()
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(main_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	if not is_open:
		return
	
	is_open = false
	
	var tween := create_tween().set_parallel()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.1)
	tween.tween_property(main_panel, "scale", Vector2(0.95, 0.95), 0.1)
	tween.chain().tween_callback(func(): visible = false)
	
	quest_ui_closed.emit()

func update_quest_progress(quest_id: String, objective_index: int, new_value: int) -> void:
	var quest := _get_quest_by_id(quest_id)
	if quest.is_empty():
		return
	
	var objectives: Array = quest.get("objectives", [])
	if objective_index >= objectives.size():
		return
	
	objectives[objective_index]["current"] = new_value
	
	# Check if all objectives complete
	var all_complete := true
	for obj in objectives:
		if obj.get("current", 0) < obj.get("required", 1):
			all_complete = false
			break
	
	quest["completed"] = all_complete
	
	if is_open:
		_populate_quest_list()
		if selected_quest_id == quest_id:
			_update_details_panel()
	
	if tracked_quest_id == quest_id:
		_update_tracker()

func show_tracker() -> void:
	if not tracked_quest_id.is_empty():
		tracker_panel.visible = true

func hide_tracker() -> void:
	tracker_panel.visible = false
