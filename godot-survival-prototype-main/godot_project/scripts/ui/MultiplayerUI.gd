extends Control

## MultiplayerUI - LDOE-style multiplayer interface
## Features party management, clan system, trading, raid protection, and global chat

class_name MultiplayerUI

# ============================================================================
# SIGNALS
# ============================================================================

signal multiplayer_ui_opened
signal multiplayer_ui_closed
signal party_invite_sent(player_id: String)
signal trade_request_sent(player_id: String)
signal clan_action(action: String, data: Dictionary)
signal chat_message_sent(message: String, channel: String)

# ============================================================================
# CONSTANTS
# ============================================================================

const TABS := {
	"party": {"name": "Party", "icon": "👥"},
	"clan": {"name": "Clan", "icon": "🏰"},
	"trade": {"name": "Trade", "icon": "🔄"},
	"inbox": {"name": "Inbox", "icon": "📬"},
	"friends": {"name": "Friends", "icon": "❤️"}
}

const CLAN_RANKS := {
	"leader": {"name": "Leader", "icon": "👑", "color": Color(0.9, 0.7, 0.3)},
	"officer": {"name": "Officer", "icon": "⭐", "color": Color(0.6, 0.8, 0.9)},
	"veteran": {"name": "Veteran", "icon": "🎖️", "color": Color(0.7, 0.7, 0.8)},
	"member": {"name": "Member", "icon": "👤", "color": Color(0.6, 0.6, 0.6)}
}

# ============================================================================
# STATE
# ============================================================================

var is_open := false
var current_tab := "party"

# Party data
var party_members: Array = []
var max_party_size := 4
var party_leader_id := ""

# Clan data
var clan_info: Dictionary = {}
var clan_members: Array = []

# Trade data
var trade_partner := ""
var my_trade_offer: Array = []
var their_trade_offer: Array = []
var trade_locked := false

# Inbox
var inbox_messages: Array = []

# Friends
var friends_list: Array = []
var online_players: Array = []

# ============================================================================
# REFERENCES
# ============================================================================

@onready var background: ColorRect = $Background
@onready var main_panel: PanelContainer = $MainPanel
@onready var tab_container: HBoxContainer = $MainPanel/Content/TabContainer
@onready var content_panel: Panel = $MainPanel/Content/ContentPanel
@onready var chat_panel: PanelContainer = $MainPanel/Content/ChatPanel

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("multiplayer_ui")
	_build_ui()
	_connect_signals()
	_load_sample_data()
	hide()

func _build_ui() -> void:
	if not has_node("Background"):
		_create_ui_structure()
	
	_populate_tabs()

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
	main_panel.custom_minimum_size = Vector2(850, 600)
	main_panel.position = -main_panel.custom_minimum_size / 2
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.98)
	panel_style.set_corner_radius_all(12)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.35, 0.3, 0.28)
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
	title.text = "🌐 MULTIPLAYER"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	var online_label := Label.new()
	online_label.name = "OnlineLabel"
	online_label.text = "🟢 Online: 1,234"
	online_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	header.add_child(online_label)
	
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
	
	# Content area with chat
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 15)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)
	
	# Main content panel
	content_panel = Panel.new()
	content_panel.name = "ContentPanel"
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content_style := StyleBoxFlat.new()
	content_style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	content_style.set_corner_radius_all(8)
	content_panel.add_theme_stylebox_override("panel", content_style)
	content_hbox.add_child(content_panel)
	
	# Chat panel (right side)
	chat_panel = PanelContainer.new()
	chat_panel.name = "ChatPanel"
	chat_panel.custom_minimum_size.x = 280
	var chat_style := StyleBoxFlat.new()
	chat_style.bg_color = Color(0.06, 0.06, 0.08, 0.95)
	chat_style.set_corner_radius_all(8)
	chat_panel.add_theme_stylebox_override("panel", chat_style)
	content_hbox.add_child(chat_panel)
	
	_create_chat_panel()

func _create_chat_panel() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	chat_panel.add_child(vbox)
	
	# Chat header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var chat_title := Label.new()
	chat_title.text = "💬 Chat"
	chat_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(chat_title)
	
	var channel_btn := Button.new()
	channel_btn.text = "🌍 Global"
	channel_btn.name = "ChannelButton"
	header.add_child(channel_btn)
	
	# Chat messages
	var scroll := ScrollContainer.new()
	scroll.name = "ChatScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var messages := VBoxContainer.new()
	messages.name = "ChatMessages"
	scroll.add_child(messages)
	
	# Sample messages
	_add_chat_message("System", "Welcome to the chat!", Color(0.9, 0.8, 0.3))
	_add_chat_message("Player123", "Anyone want to team up?", Color(0.7, 0.7, 0.8))
	_add_chat_message("SurvivorX", "Trading iron for wood", Color(0.7, 0.7, 0.8))
	
	# Chat input
	var input_hbox := HBoxContainer.new()
	vbox.add_child(input_hbox)
	
	var chat_input := LineEdit.new()
	chat_input.name = "ChatInput"
	chat_input.placeholder_text = "Type a message..."
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect(_on_chat_submitted)
	input_hbox.add_child(chat_input)
	
	var send_btn := Button.new()
	send_btn.text = "→"
	send_btn.custom_minimum_size.x = 40
	send_btn.pressed.connect(func(): _on_chat_submitted(chat_input.text))
	input_hbox.add_child(send_btn)

func _add_chat_message(sender: String, text: String, color: Color = Color(0.7, 0.7, 0.8)) -> void:
	var messages := chat_panel.get_node_or_null("VBoxContainer/ChatScroll/ChatMessages")
	if not messages:
		return
	
	var msg := RichTextLabel.new()
	msg.bbcode_enabled = true
	msg.fit_content = true
	msg.text = "[color=#%s]%s[/color]: %s" % [color.to_html(false), sender, text]
	messages.add_child(msg)

func _populate_tabs() -> void:
	for child in tab_container.get_children():
		child.queue_free()
	
	for tab_id in TABS:
		var tab_data: Dictionary = TABS[tab_id]
		
		var btn := Button.new()
		btn.text = "%s %s" % [tab_data.icon, tab_data.name]
		btn.custom_minimum_size = Vector2(100, 42)
		btn.toggle_mode = true
		btn.button_pressed = tab_id == current_tab
		btn.pressed.connect(_on_tab_selected.bind(tab_id))
		
		# Add badge for inbox
		if tab_id == "inbox" and _count_unread_messages() > 0:
			var badge := Label.new()
			badge.text = str(_count_unread_messages())
			badge.add_theme_font_size_override("font_size", 9)
			badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			badge.position = Vector2(-10, 0)
			btn.add_child(badge)
		
		tab_container.add_child(btn)

func _connect_signals() -> void:
	background.gui_input.connect(_on_background_input)

func _load_sample_data() -> void:
	# Sample party data
	party_members = [
		{"id": "player_self", "name": "You", "level": 15, "class": "Survivor", "hp": 85, "max_hp": 100, "is_leader": true},
		{"id": "player_2", "name": "AlphaHunter", "level": 12, "class": "Hunter", "hp": 70, "max_hp": 100, "is_leader": false}
	]
	party_leader_id = "player_self"
	
	# Sample clan data
	clan_info = {
		"name": "Survivors United",
		"tag": "[SU]",
		"level": 5,
		"xp": 2500,
		"xp_required": 5000,
		"member_count": 24,
		"max_members": 30,
		"base_defense": 850,
		"raid_protection_ends": Time.get_unix_time_from_system() + 3600 * 8
	}
	
	clan_members = [
		{"id": "leader1", "name": "ChiefSurvivor", "rank": "leader", "level": 45, "contribution": 15000, "online": true},
		{"id": "officer1", "name": "VeteranFighter", "rank": "officer", "level": 38, "contribution": 8500, "online": true},
		{"id": "member1", "name": "ScoutRanger", "rank": "veteran", "level": 28, "contribution": 3200, "online": false},
		{"id": "member2", "name": "NewRecruit", "rank": "member", "level": 8, "contribution": 450, "online": false}
	]
	
	# Sample inbox
	inbox_messages = [
		{"id": "msg1", "from": "System", "subject": "Daily Reward", "body": "Claim your daily reward!", "time": Time.get_unix_time_from_system() - 3600, "read": false},
		{"id": "msg2", "from": "ChiefSurvivor", "subject": "Welcome to the clan!", "body": "Glad to have you aboard. Don't forget to contribute!", "time": Time.get_unix_time_from_system() - 86400, "read": true}
	]
	
	# Sample friends
	friends_list = [
		{"id": "friend1", "name": "BestBuddy", "level": 22, "online": true, "status": "In Green Zone"},
		{"id": "friend2", "name": "TradePartner", "level": 18, "online": false, "last_seen": Time.get_unix_time_from_system() - 3600 * 5}
	]

# ============================================================================
# INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
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
	
	# Update button states
	for btn in tab_container.get_children():
		if btn is Button:
			btn.button_pressed = btn.text.contains(TABS[tab_id].name)
	
	_populate_content()

func _on_chat_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	
	var chat_input: LineEdit = chat_panel.get_node_or_null("VBoxContainer/ChatInput")
	if chat_input:
		chat_input.text = ""
	
	_add_chat_message("You", text, Color(0.5, 0.9, 0.5))
	chat_message_sent.emit(text, "global")

# ============================================================================
# CONTENT POPULATION
# ============================================================================

func _populate_content() -> void:
	# Clear existing content
	for child in content_panel.get_children():
		child.queue_free()
	
	match current_tab:
		"party":
			_create_party_content()
		"clan":
			_create_clan_content()
		"trade":
			_create_trade_content()
		"inbox":
			_create_inbox_content()
		"friends":
			_create_friends_content()

# ============================================================================
# PARTY TAB
# ============================================================================

func _create_party_content() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	content_panel.add_child(vbox)
	
	# Party header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var party_title := Label.new()
	party_title.text = "👥 Your Party (%d/%d)" % [party_members.size(), max_party_size]
	party_title.add_theme_font_size_override("font_size", 18)
	party_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(party_title)
	
	var invite_btn := Button.new()
	invite_btn.text = "+ Invite"
	invite_btn.pressed.connect(_on_invite_party_pressed)
	header.add_child(invite_btn)
	
	var leave_btn := Button.new()
	leave_btn.text = "Leave Party"
	leave_btn.pressed.connect(_on_leave_party_pressed)
	header.add_child(leave_btn)
	
	# Party members
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var member_list := VBoxContainer.new()
	member_list.add_theme_constant_override("separation", 8)
	scroll.add_child(member_list)
	
	for member in party_members:
		var entry := _create_party_member_entry(member)
		member_list.add_child(entry)
	
	# Empty slots
	for i in range(max_party_size - party_members.size()):
		var empty := _create_empty_party_slot()
		member_list.add_child(empty)
	
	# Party bonuses
	var bonus_panel := PanelContainer.new()
	var bonus_style := StyleBoxFlat.new()
	bonus_style.bg_color = Color(0.15, 0.2, 0.15, 0.9)
	bonus_style.set_corner_radius_all(6)
	bonus_panel.add_theme_stylebox_override("panel", bonus_style)
	vbox.add_child(bonus_panel)
	
	var bonus_hbox := HBoxContainer.new()
	bonus_panel.add_child(bonus_hbox)
	
	var bonus_label := Label.new()
	bonus_label.text = "🎁 Party Bonuses: "
	bonus_hbox.add_child(bonus_label)
	
	var xp_bonus := Label.new()
	xp_bonus.text = "+%d%% XP" % (party_members.size() * 5)
	xp_bonus.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	bonus_hbox.add_child(xp_bonus)
	
	var loot_bonus := Label.new()
	loot_bonus.text = " | +%d%% Loot" % (party_members.size() * 3)
	loot_bonus.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	bonus_hbox.add_child(loot_bonus)

func _create_party_member_entry(member: Dictionary) -> Control:
	var entry := PanelContainer.new()
	entry.custom_minimum_size.y = 70
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.5, 0.3) if member.get("is_leader", false) else Color(0.25, 0.25, 0.3)
	style.set_corner_radius_all(6)
	entry.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	entry.add_child(hbox)
	
	# Avatar placeholder
	var avatar := ColorRect.new()
	avatar.custom_minimum_size = Vector2(50, 50)
	avatar.color = Color(0.3, 0.3, 0.4)
	hbox.add_child(avatar)
	
	var avatar_label := Label.new()
	avatar_label.text = "👤"
	avatar_label.add_theme_font_size_override("font_size", 24)
	avatar_label.set_anchors_preset(Control.PRESET_CENTER)
	avatar.add_child(avatar_label)
	
	# Info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_hbox := HBoxContainer.new()
	info_vbox.add_child(name_hbox)
	
	if member.get("is_leader", false):
		var crown := Label.new()
		crown.text = "👑 "
		name_hbox.add_child(crown)
	
	var name_label := Label.new()
	name_label.text = member.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_hbox.add_child(name_label)
	
	var level_class := Label.new()
	level_class.text = "Lv.%d %s" % [member.get("level", 1), member.get("class", "")]
	level_class.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info_vbox.add_child(level_class)
	
	# HP bar
	var hp_hbox := HBoxContainer.new()
	hbox.add_child(hp_hbox)
	
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(80, 16)
	hp_bar.max_value = member.get("max_hp", 100)
	hp_bar.value = member.get("hp", 100)
	hp_bar.show_percentage = false
	hp_hbox.add_child(hp_bar)
	
	var hp_label := Label.new()
	hp_label.text = " %d/%d" % [member.get("hp", 100), member.get("max_hp", 100)]
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_hbox.add_child(hp_label)
	
	# Actions
	if member.get("id", "") != "player_self":
		var actions := HBoxContainer.new()
		hbox.add_child(actions)
		
		if party_leader_id == "player_self":
			var kick_btn := Button.new()
			kick_btn.text = "✕"
			kick_btn.tooltip_text = "Kick"
			kick_btn.pressed.connect(_on_kick_member.bind(member.get("id", "")))
			actions.add_child(kick_btn)
		
		var trade_btn := Button.new()
		trade_btn.text = "🔄"
		trade_btn.tooltip_text = "Trade"
		trade_btn.pressed.connect(_on_trade_member.bind(member.get("id", "")))
		actions.add_child(trade_btn)
	
	return entry

func _create_empty_party_slot() -> Control:
	var entry := PanelContainer.new()
	entry.custom_minimum_size.y = 70
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.6)
	style.set_border_width_all(1)
	style.border_color = Color(0.2, 0.2, 0.25)
	style.set_corner_radius_all(6)
	entry.add_theme_stylebox_override("panel", style)
	
	var label := Label.new()
	label.text = "+ Empty Slot"
	label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entry.add_child(label)
	
	return entry

# ============================================================================
# CLAN TAB
# ============================================================================

func _create_clan_content() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	content_panel.add_child(vbox)
	
	if clan_info.is_empty():
		_create_no_clan_content(vbox)
		return
	
	# Clan header
	var header_panel := PanelContainer.new()
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.15, 0.12, 0.1, 0.95)
	header_style.set_corner_radius_all(8)
	header_style.set_border_width_all(2)
	header_style.border_color = Color(0.5, 0.4, 0.3)
	header_panel.add_theme_stylebox_override("panel", header_style)
	vbox.add_child(header_panel)
	
	var header_vbox := VBoxContainer.new()
	header_panel.add_child(header_vbox)
	
	var clan_name := Label.new()
	clan_name.text = "🏰 %s %s" % [clan_info.get("tag", ""), clan_info.get("name", "")]
	clan_name.add_theme_font_size_override("font_size", 20)
	clan_name.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	header_vbox.add_child(clan_name)
	
	var clan_stats := HBoxContainer.new()
	header_vbox.add_child(clan_stats)
	
	var level_label := Label.new()
	level_label.text = "Level %d" % clan_info.get("level", 1)
	clan_stats.add_child(level_label)
	
	var members_label := Label.new()
	members_label.text = " | 👥 %d/%d" % [clan_info.get("member_count", 0), clan_info.get("max_members", 30)]
	clan_stats.add_child(members_label)
	
	var defense_label := Label.new()
	defense_label.text = " | 🛡️ Defense: %d" % clan_info.get("base_defense", 0)
	clan_stats.add_child(defense_label)
	
	# Raid protection
	var protection_time: int = clan_info.get("raid_protection_ends", 0) - int(Time.get_unix_time_from_system())
	if protection_time > 0:
		var protection_panel := PanelContainer.new()
		var prot_style := StyleBoxFlat.new()
		prot_style.bg_color = Color(0.2, 0.25, 0.2, 0.9)
		prot_style.set_corner_radius_all(6)
		protection_panel.add_theme_stylebox_override("panel", prot_style)
		vbox.add_child(protection_panel)
		
		var prot_label := Label.new()
		prot_label.text = "🛡️ Raid Protection Active: %02d:%02d:%02d" % [protection_time / 3600, (protection_time % 3600) / 60, protection_time % 60]
		prot_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		protection_panel.add_child(prot_label)
	
	# Member list
	var member_header := HBoxContainer.new()
	vbox.add_child(member_header)
	
	var member_title := Label.new()
	member_title.text = "Members"
	member_title.add_theme_font_size_override("font_size", 16)
	member_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	member_header.add_child(member_title)
	
	var invite_btn := Button.new()
	invite_btn.text = "+ Invite"
	member_header.add_child(invite_btn)
	
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var member_list := VBoxContainer.new()
	member_list.add_theme_constant_override("separation", 5)
	scroll.add_child(member_list)
	
	for member in clan_members:
		var entry := _create_clan_member_entry(member)
		member_list.add_child(entry)
	
	# Action buttons
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	vbox.add_child(actions)
	
	var donate_btn := Button.new()
	donate_btn.text = "💰 Donate"
	donate_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(donate_btn)
	
	var base_btn := Button.new()
	base_btn.text = "🏠 Clan Base"
	base_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(base_btn)
	
	var leave_btn := Button.new()
	leave_btn.text = "🚪 Leave Clan"
	leave_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(leave_btn)

func _create_no_clan_content(parent: VBoxContainer) -> void:
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(center)
	
	var icon := Label.new()
	icon.text = "🏰"
	icon.add_theme_font_size_override("font_size", 64)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(icon)
	
	var text := Label.new()
	text.text = "You are not in a clan"
	text.add_theme_font_size_override("font_size", 18)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(text)
	
	var desc := Label.new()
	desc.text = "Join or create a clan to unlock special bonuses!"
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(desc)
	
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 20)
	center.add_child(btn_hbox)
	
	var create_btn := Button.new()
	create_btn.text = "🏗️ Create Clan"
	create_btn.custom_minimum_size = Vector2(150, 44)
	btn_hbox.add_child(create_btn)
	
	var browse_btn := Button.new()
	browse_btn.text = "🔍 Browse Clans"
	browse_btn.custom_minimum_size = Vector2(150, 44)
	btn_hbox.add_child(browse_btn)

func _create_clan_member_entry(member: Dictionary) -> Control:
	var entry := HBoxContainer.new()
	entry.custom_minimum_size.y = 36
	
	var rank_data: Dictionary = CLAN_RANKS.get(member.get("rank", "member"), CLAN_RANKS.member)
	
	# Online indicator
	var online := Label.new()
	online.text = "🟢" if member.get("online", false) else "⚫"
	online.custom_minimum_size.x = 24
	entry.add_child(online)
	
	# Rank icon
	var rank := Label.new()
	rank.text = rank_data.icon
	rank.custom_minimum_size.x = 24
	entry.add_child(rank)
	
	# Name
	var name_label := Label.new()
	name_label.text = member.get("name", "Unknown")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", rank_data.color)
	entry.add_child(name_label)
	
	# Level
	var level := Label.new()
	level.text = "Lv.%d" % member.get("level", 1)
	level.custom_minimum_size.x = 50
	entry.add_child(level)
	
	# Contribution
	var contrib := Label.new()
	contrib.text = "⭐ %d" % member.get("contribution", 0)
	contrib.custom_minimum_size.x = 80
	contrib.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	entry.add_child(contrib)
	
	return entry

# ============================================================================
# TRADE TAB
# ============================================================================

func _create_trade_content() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	content_panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "🔄 Trading"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	if trade_partner.is_empty():
		# No active trade
		var center := VBoxContainer.new()
		center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(center)
		
		var placeholder := Label.new()
		placeholder.text = "No active trade\nInvite a party member or friend to trade!"
		placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.set_anchors_preset(Control.PRESET_CENTER)
		center.add_child(placeholder)
		return
	
	# Trade interface
	var trade_hbox := HBoxContainer.new()
	trade_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trade_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(trade_hbox)
	
	# My offer (left)
	var my_panel := _create_trade_panel("Your Offer", my_trade_offer, true)
	my_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trade_hbox.add_child(my_panel)
	
	# Arrow
	var arrow := Label.new()
	arrow.text = "⇄"
	arrow.add_theme_font_size_override("font_size", 32)
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trade_hbox.add_child(arrow)
	
	# Their offer (right)
	var their_panel := _create_trade_panel(trade_partner + "'s Offer", their_trade_offer, false)
	their_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trade_hbox.add_child(their_panel)
	
	# Trade buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_hbox)
	
	var lock_btn := Button.new()
	lock_btn.text = "🔒 Lock Trade" if not trade_locked else "🔓 Unlock"
	lock_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock_btn.custom_minimum_size.y = 44
	btn_hbox.add_child(lock_btn)
	
	var confirm_btn := Button.new()
	confirm_btn.text = "✓ Confirm Trade"
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.custom_minimum_size.y = 44
	confirm_btn.disabled = not trade_locked
	btn_hbox.add_child(confirm_btn)
	
	var cancel_btn := Button.new()
	cancel_btn.text = "✕ Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size.y = 44
	btn_hbox.add_child(cancel_btn)

func _create_trade_panel(title: String, items: Array, editable: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = Color(0.3, 0.3, 0.35)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	
	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 14)
	vbox.add_child(header)
	
	# Item grid (3x3)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)
	
	for i in range(9):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(56, 56)
		
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.15, 0.15, 0.18)
		slot_style.set_corner_radius_all(4)
		slot_style.set_border_width_all(1)
		slot_style.border_color = Color(0.25, 0.25, 0.3)
		slot.add_theme_stylebox_override("panel", slot_style)
		
		if i < items.size():
			var item_label := Label.new()
			item_label.text = items[i].get("icon", "?")
			item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(item_label)
		elif editable:
			var plus := Label.new()
			plus.text = "+"
			plus.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
			plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(plus)
		
		grid.add_child(slot)
	
	return panel

# ============================================================================
# INBOX TAB
# ============================================================================

func _create_inbox_content() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	content_panel.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var title := Label.new()
	title.text = "📬 Inbox (%d)" % inbox_messages.size()
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	var delete_all := Button.new()
	delete_all.text = "🗑️ Delete All Read"
	header.add_child(delete_all)
	
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var message_list := VBoxContainer.new()
	message_list.add_theme_constant_override("separation", 5)
	scroll.add_child(message_list)
	
	if inbox_messages.is_empty():
		var empty := Label.new()
		empty.text = "No messages"
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		message_list.add_child(empty)
	else:
		for msg in inbox_messages:
			var entry := _create_inbox_entry(msg)
			message_list.add_child(entry)

func _create_inbox_entry(msg: Dictionary) -> Control:
	var entry := PanelContainer.new()
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95) if msg.get("read", true) else Color(0.15, 0.15, 0.2, 0.95)
	style.set_corner_radius_all(6)
	style.set_border_width_all(1)
	style.border_color = Color(0.3, 0.3, 0.4) if not msg.get("read", true) else Color(0.25, 0.25, 0.3)
	entry.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	entry.add_child(hbox)
	
	# Unread indicator
	if not msg.get("read", true):
		var unread := Label.new()
		unread.text = "●"
		unread.add_theme_color_override("font_color", Color(0.3, 0.6, 0.9))
		hbox.add_child(unread)
	
	# Message info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	
	var from_label := Label.new()
	from_label.text = "From: %s" % msg.get("from", "Unknown")
	from_label.add_theme_font_size_override("font_size", 14)
	info.add_child(from_label)
	
	var subject := Label.new()
	subject.text = msg.get("subject", "")
	subject.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	info.add_child(subject)
	
	# Time
	var time_ago := _format_time_ago(msg.get("time", 0))
	var time_label := Label.new()
	time_label.text = time_ago
	time_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hbox.add_child(time_label)
	
	# Actions
	var delete_btn := Button.new()
	delete_btn.text = "🗑️"
	delete_btn.custom_minimum_size = Vector2(32, 32)
	hbox.add_child(delete_btn)
	
	return entry

# ============================================================================
# FRIENDS TAB
# ============================================================================

func _create_friends_content() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	content_panel.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var title := Label.new()
	title.text = "❤️ Friends (%d)" % friends_list.size()
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	var add_btn := Button.new()
	add_btn.text = "+ Add Friend"
	header.add_child(add_btn)
	
	# Online/offline sections
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var friend_list := VBoxContainer.new()
	friend_list.add_theme_constant_override("separation", 5)
	scroll.add_child(friend_list)
	
	# Online friends
	var online_header := Label.new()
	online_header.text = "🟢 Online"
	online_header.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	friend_list.add_child(online_header)
	
	var has_online := false
	for friend in friends_list:
		if friend.get("online", false):
			has_online = true
			var entry := _create_friend_entry(friend)
			friend_list.add_child(entry)
	
	if not has_online:
		var none := Label.new()
		none.text = "  No friends online"
		none.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		friend_list.add_child(none)
	
	# Offline friends
	var offline_header := Label.new()
	offline_header.text = "⚫ Offline"
	offline_header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	friend_list.add_child(offline_header)
	
	for friend in friends_list:
		if not friend.get("online", false):
			var entry := _create_friend_entry(friend)
			friend_list.add_child(entry)

func _create_friend_entry(friend: Dictionary) -> Control:
	var entry := HBoxContainer.new()
	entry.custom_minimum_size.y = 40
	
	# Status
	var status := Label.new()
	status.text = "🟢" if friend.get("online", false) else "⚫"
	status.custom_minimum_size.x = 24
	entry.add_child(status)
	
	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(info)
	
	var name_label := Label.new()
	name_label.text = friend.get("name", "Unknown")
	info.add_child(name_label)
	
	var detail := Label.new()
	if friend.get("online", false):
		detail.text = friend.get("status", "Online")
		detail.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	else:
		detail.text = "Last seen: " + _format_time_ago(friend.get("last_seen", 0))
		detail.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	detail.add_theme_font_size_override("font_size", 11)
	info.add_child(detail)
	
	# Actions
	if friend.get("online", false):
		var invite_btn := Button.new()
		invite_btn.text = "👥"
		invite_btn.tooltip_text = "Invite to Party"
		entry.add_child(invite_btn)
		
		var trade_btn := Button.new()
		trade_btn.text = "🔄"
		trade_btn.tooltip_text = "Trade"
		entry.add_child(trade_btn)
	
	var msg_btn := Button.new()
	msg_btn.text = "💬"
	msg_btn.tooltip_text = "Message"
	entry.add_child(msg_btn)
	
	var remove_btn := Button.new()
	remove_btn.text = "✕"
	remove_btn.tooltip_text = "Remove"
	entry.add_child(remove_btn)
	
	return entry

# ============================================================================
# HELPERS
# ============================================================================

func _count_unread_messages() -> int:
	var count := 0
	for msg in inbox_messages:
		if not msg.get("read", true):
			count += 1
	return count

func _format_time_ago(timestamp: int) -> String:
	var now := int(Time.get_unix_time_from_system())
	var diff := now - timestamp
	
	if diff < 60:
		return "Just now"
	elif diff < 3600:
		return "%d min ago" % (diff / 60)
	elif diff < 86400:
		return "%d hr ago" % (diff / 3600)
	else:
		return "%d days ago" % (diff / 86400)

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_invite_party_pressed() -> void:
	# Show player search dialog
	pass

func _on_leave_party_pressed() -> void:
	party_members.clear()
	_populate_content()

func _on_kick_member(member_id: String) -> void:
	party_members = party_members.filter(func(m): return m.get("id", "") != member_id)
	_populate_content()

func _on_trade_member(member_id: String) -> void:
	trade_partner = "Player"
	current_tab = "trade"
	_populate_tabs()
	_populate_content()

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
	_populate_content()
	
	multiplayer_ui_opened.emit()
	
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
	
	multiplayer_ui_closed.emit()

func start_trade(partner_id: String, partner_name: String) -> void:
	trade_partner = partner_name
	my_trade_offer.clear()
	their_trade_offer.clear()
	trade_locked = false
	
	current_tab = "trade"
	open()

func update_party(members: Array) -> void:
	party_members = members
	if is_open and current_tab == "party":
		_populate_content()

func add_inbox_message(from: String, subject: String, body: String) -> void:
	inbox_messages.push_front({
		"id": "msg_" + str(Time.get_unix_time_from_system()),
		"from": from,
		"subject": subject,
		"body": body,
		"time": int(Time.get_unix_time_from_system()),
		"read": false
	})
	_populate_tabs()
