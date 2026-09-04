extends Control

class_name IdleShell

const IdleEconomyConfig = preload("res://scripts/idle/IdleEconomyConfig.gd")

const BG_COLOR := Color("12171B")
const PANEL_COLOR := Color("1E272F")
const PANEL_ALT := Color("243039")
const BORDER_COLOR := Color("33414A")
const TEXT_COLOR := Color("E5DDCC")
const SUBTEXT_COLOR := Color("AAB1B5")
const ACCENT_COLOR := Color("4D8B8F")
const SUCCESS_COLOR := Color("718B52")
const WARNING_COLOR := Color("D49B2E")
const DANGER_COLOR := Color("A24B36")

const TABS := ["overview", "expeditions", "rooms", "crafting", "inventory", "events", "progress"]
const TAB_TITLES := {
	"overview": "Overview",
	"expeditions": "Expeditions",
	"rooms": "Rooms",
	"crafting": "Crafting",
	"inventory": "Inventory",
	"events": "Events",
	"progress": "Progress",
}

signal starter_cache_requested
signal expedition_requested(zone_id: String)
signal room_upgrade_requested(room_id: String)
signal craft_requested(recipe_id: String)
signal daily_reward_requested
signal event_card_action_requested(card_id: String, action_id: String)

var active_tab := "overview"
var current_state: Dictionary = {}
var current_summary: Dictionary = {}

var title_label: Label
var subtitle_label: Label
var resource_grid: GridContainer
var content_root: VBoxContainer
var footer_label: Label
var nav_buttons := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()

func render_state(state: Dictionary, summary: Dictionary = {}) -> void:
	current_state = state
	current_summary = summary
	_rebuild_resource_bar()
	_rebuild_content()
	_refresh_nav_buttons()
	_update_footer()

func _build_layout() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = BG_COLOR
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var header_panel := _make_panel(PANEL_COLOR)
	root.add_child(header_panel)
	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 6)
	header_panel.add_child(header_box)

	title_label = Label.new()
	title_label.text = "Command Bunker"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	header_box.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Bringing bunker systems online..."
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.add_theme_color_override("font_color", SUBTEXT_COLOR)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_box.add_child(subtitle_label)

	var resource_panel := _make_panel(PANEL_ALT)
	root.add_child(resource_panel)
	resource_grid = GridContainer.new()
	resource_grid.columns = 4
	resource_grid.add_theme_constant_override("h_separation", 10)
	resource_grid.add_theme_constant_override("v_separation", 10)
	resource_panel.add_child(resource_grid)

	var content_panel := _make_panel(PANEL_COLOR)
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_panel.add_child(scroll)

	content_root = VBoxContainer.new()
	content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_root.add_theme_constant_override("separation", 12)
	scroll.add_child(content_root)

	var nav_panel := _make_panel(PANEL_ALT)
	root.add_child(nav_panel)
	var nav_grid := GridContainer.new()
	nav_grid.columns = 4
	nav_grid.add_theme_constant_override("h_separation", 10)
	nav_grid.add_theme_constant_override("v_separation", 10)
	nav_panel.add_child(nav_grid)

	for tab_id in TABS:
		var button := Button.new()
		button.text = TAB_TITLES.get(tab_id, tab_id.capitalize())
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(_on_tab_pressed.bind(tab_id))
		nav_grid.add_child(button)
		nav_buttons[tab_id] = button

	footer_label = Label.new()
	footer_label.add_theme_font_size_override("font_size", 13)
	footer_label.add_theme_color_override("font_color", SUBTEXT_COLOR)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer_label)

func _rebuild_resource_bar() -> void:
	_clear_children(resource_grid)
	var resources: Dictionary = current_state.get("resources", {})
	for resource_id in IdleEconomyConfig.RESOURCE_BAR_ORDER:
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", _make_stylebox(PANEL_COLOR, BORDER_COLOR, 8))
		resource_grid.add_child(tile)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		tile.add_child(box)

		var label := Label.new()
		label.text = IdleEconomyConfig.get_resource_title(resource_id)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", SUBTEXT_COLOR)
		box.add_child(label)

		var value_label := Label.new()
		value_label.text = IdleEconomyConfig.format_amount(float(resources.get(resource_id, 0.0)))
		value_label.add_theme_font_size_override("font_size", 18)
		value_label.add_theme_color_override("font_color", TEXT_COLOR)
		box.add_child(value_label)

func _rebuild_content() -> void:
	_clear_children(content_root)
	subtitle_label.text = IdleEconomyConfig.get_next_objective(current_state)

	match active_tab:
		"overview":
			_render_overview_tab()
		"expeditions":
			_render_expeditions_tab()
		"rooms":
			_render_rooms_tab()
		"crafting":
			_render_crafting_tab()
		"inventory":
			_render_inventory_tab()
		"events":
			_render_events_tab()
		"progress":
			_render_progress_tab()

func _render_overview_tab() -> void:
	var objective_card := _add_card("Current Objective", IdleEconomyConfig.get_next_objective(current_state))
	var ftue: Dictionary = current_state.get("ftue", {})
	if not bool(ftue.get("starter_cache_claimed", false)):
		var claim_button := _make_button("Claim Starter Cache", "primary")
		claim_button.pressed.connect(_on_starter_cache_pressed)
		objective_card.add_child(claim_button)
		_add_info_line(objective_card, "Cache contents: %s" % IdleEconomyConfig.build_amount_text(IdleEconomyConfig.STARTER_CACHE), SUBTEXT_COLOR)

	var daily_available := bool(current_state.get("daily_reward_available", false))
	var daily_streak := int(current_state.get("daily_reward_streak", 0))
	var preview_streak := int(current_state.get("daily_reward_preview_streak", max(1, daily_streak)))
	var daily_reward_card := _add_card("Daily Reward", "Claim a once-per-day bunker stipend to keep the loop alive.")
	_add_info_line(daily_reward_card, "Streak target: Day %d" % preview_streak, ACCENT_COLOR)
	_add_info_line(daily_reward_card, "Reward: %s" % IdleEconomyConfig.build_amount_text(current_state.get("daily_reward_preview", {})), SUBTEXT_COLOR)
	if daily_available:
		var daily_button := _make_button("Claim Daily Reward", "primary")
		daily_button.pressed.connect(_on_daily_reward_pressed)
		daily_reward_card.add_child(daily_button)
	else:
		_add_info_line(daily_reward_card, "Claimed today. Current streak: %d." % daily_streak, SUCCESS_COLOR)

	var expedition_card := _add_card("Active Expedition", _build_active_expedition_text())
	var active_expedition: Dictionary = current_state.get("active_expedition", {})
	if active_expedition.is_empty():
		_add_info_line(expedition_card, "No team in the field.", SUBTEXT_COLOR)
	else:
		_add_info_line(expedition_card, "Risk: %s" % active_expedition.get("risk", "Low"), WARNING_COLOR)

	var summary_text := _build_summary_text(current_summary)
	var summary_card := _add_card("Recent System Summary", summary_text)
	if summary_text == "No recent completions.":
		_add_info_line(summary_card, "Leave the bunker open or reload later to see passive gains, craft completions, and expedition outcomes.", SUBTEXT_COLOR)

	var log_card := _add_card("Latest Events", "Command log from the bunker.")
	var events: Array = current_state.get("event_log", [])
	if events.is_empty():
		_add_info_line(log_card, "No events recorded yet.", SUBTEXT_COLOR)
	else:
		for event_index in range(events.size() - 1, max(events.size() - 4, -1), -1):
			var entry: Dictionary = events[event_index]
			_add_info_line(log_card, str(entry.get("message", "System log entry.")), _category_color(str(entry.get("category", "system"))))

func _render_expeditions_tab() -> void:
	var active_expedition: Dictionary = current_state.get("active_expedition", {})
	if not active_expedition.is_empty():
		var active_card := _add_card("Team In Field", _build_active_expedition_text())
		_add_info_line(active_card, "Only one team is supported in the first scaffold.", SUBTEXT_COLOR)

	for zone_id in IdleEconomyConfig.ZONE_ORDER:
		var zone_def: Dictionary = IdleEconomyConfig.get_zone_def(zone_id)
		var card := _add_card(str(zone_def.get("title", zone_id.capitalize())), "%s risk • %s" % [zone_def.get("risk", "Low"), _format_duration(int(zone_def.get("duration_seconds", 0)))])
		_add_info_line(card, "Loot preview: %s" % IdleEconomyConfig.build_zone_loot_preview(zone_id), SUBTEXT_COLOR)
		_add_info_line(card, "Supply cost: %s" % IdleEconomyConfig.build_cost_text(zone_def.get("supply_cost", {})), SUBTEXT_COLOR)

		var unlock_reason := IdleEconomyConfig.get_zone_unlock_reason(current_state, zone_id)
		var start_button := _make_button("Dispatch Team", "primary")
		start_button.pressed.connect(_on_expedition_pressed.bind(zone_id))

		if not unlock_reason.is_empty():
			start_button.disabled = true
			_add_info_line(card, "Locked: %s" % unlock_reason, WARNING_COLOR)
		elif not active_expedition.is_empty():
			start_button.disabled = true
			_add_info_line(card, "Team busy until the current run ends.", SUBTEXT_COLOR)

		card.add_child(start_button)

func _render_rooms_tab() -> void:
	for room_id in IdleEconomyConfig.ROOM_ORDER:
		var room_def: Dictionary = IdleEconomyConfig.get_room_def(room_id)
		var level := IdleEconomyConfig.get_room_level(current_state, room_id)
		var title := "%s • L%d" % [room_def.get("title", room_id.capitalize()), level]
		var card := _add_card(title, str(room_def.get("description", "")))
		_add_info_line(card, IdleEconomyConfig.get_room_effect_summary(room_id, level), SUBTEXT_COLOR)

		var cost := IdleEconomyConfig.get_room_upgrade_cost(room_id, level)
		if cost.is_empty():
			_add_info_line(card, "Maxed for the first scaffold.", SUCCESS_COLOR)
			continue

		_add_info_line(card, "Upgrade cost: %s" % IdleEconomyConfig.build_cost_text(cost), SUBTEXT_COLOR)
		var button_text := "Unlock" if level <= 0 else "Upgrade"
		var upgrade_button := _make_button("%s %s" % [button_text, room_def.get("title", room_id.capitalize())], "secondary")
		upgrade_button.pressed.connect(_on_room_upgrade_pressed.bind(room_id))
		upgrade_button.disabled = not IdleEconomyConfig.can_afford(current_state.get("resources", {}), cost)
		card.add_child(upgrade_button)

func _render_crafting_tab() -> void:
	var queue_card := _add_card("Craft Queue", _build_craft_queue_text())
	_add_info_line(queue_card, "Workshop jobs resolve automatically when their timers finish.", SUBTEXT_COLOR)

	for recipe_id in IdleEconomyConfig.RECIPE_ORDER:
		var recipe: Dictionary = IdleEconomyConfig.get_recipe_def(recipe_id)
		var card := _add_card(str(recipe.get("title", recipe_id.capitalize())), "Ready in %s" % _format_duration(int(recipe.get("duration_seconds", 0))))
		_add_info_line(card, "Cost: %s" % IdleEconomyConfig.build_cost_text(recipe.get("inputs", {})), SUBTEXT_COLOR)
		_add_info_line(card, "Output: %s" % IdleEconomyConfig.build_amount_text(recipe.get("outputs", {})), SUBTEXT_COLOR)

		var craft_button := _make_button("Queue %s" % recipe.get("title", recipe_id.capitalize()), "primary")
		craft_button.pressed.connect(_on_craft_pressed.bind(recipe_id))
		var queue_check := _craft_button_reason(recipe_id)
		craft_button.disabled = not queue_check.is_empty()
		if not queue_check.is_empty():
			_add_info_line(card, queue_check, WARNING_COLOR)
		card.add_child(craft_button)

func _render_inventory_tab() -> void:
	var card := _add_card("Resource Inventory", "Current bunker stock and caps.")
	var resources: Dictionary = current_state.get("resources", {})
	for resource_id in IdleEconomyConfig.RESOURCE_ORDER:
		var amount := float(resources.get(resource_id, 0.0))
		var cap := IdleEconomyConfig.get_resource_cap(current_state, resource_id)
		_add_stat_row(card, IdleEconomyConfig.get_resource_title(resource_id), "%s / %s" % [IdleEconomyConfig.format_amount(amount), IdleEconomyConfig.format_amount(cap)], TEXT_COLOR)

func _render_events_tab() -> void:
	var event_cards: Array = current_state.get("event_cards", [])
	if event_cards.is_empty():
		var empty_card := _add_card("Live Event Cards", "Yellow and Red zone follow-ups surface here.")
		_add_info_line(empty_card, "No live cards right now. Push deeper into Yellow and Red runs to create new decisions.", SUBTEXT_COLOR)
	else:
		for card_data in event_cards:
			var event_card: Dictionary = card_data
			var card := _add_card(str(event_card.get("title", "Opportunity")), str(event_card.get("description", "Field intel needs a decision.")))
			_add_info_line(card, "%s • %s" % [event_card.get("source_label", "Field Intel"), event_card.get("rarity_label", "Common")], ACCENT_COLOR)
			_add_info_line(card, "Potential: %s" % event_card.get("reward_preview", "Unknown"), SUBTEXT_COLOR)

			var action_row := HBoxContainer.new()
			action_row.add_theme_constant_override("separation", 10)
			card.add_child(action_row)

			var resolve_button := _make_button(str(event_card.get("action_label", "Resolve")), "primary")
			resolve_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			resolve_button.pressed.connect(_on_event_card_action_pressed.bind(str(event_card.get("card_id", "")), "resolve"))
			action_row.add_child(resolve_button)

			var dismiss_button := _make_button(str(event_card.get("dismiss_label", "Ignore")), "secondary")
			dismiss_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dismiss_button.pressed.connect(_on_event_card_action_pressed.bind(str(event_card.get("card_id", "")), "dismiss"))
			action_row.add_child(dismiss_button)

	var notifications_card := _add_card("Recent Notifications", "Latest bunker alerts and reward toasts.")
	var notification_history: Array = current_state.get("notification_history", [])
	if notification_history.is_empty():
		_add_info_line(notifications_card, "No notifications captured yet.", SUBTEXT_COLOR)
	else:
		for entry in notification_history:
			var notification: Dictionary = entry
			var line := str(notification.get("title", "Alert"))
			var message := str(notification.get("message", ""))
			if not message.is_empty():
				line += " • %s" % message
			_add_info_line(notifications_card, line, _notification_color(int(notification.get("type", 0))))

	var card := _add_card("Event Log", "Newest bunker updates first.")
	var events: Array = current_state.get("event_log", [])
	if events.is_empty():
		_add_info_line(card, "No events recorded yet.", SUBTEXT_COLOR)
		return

	for event_index in range(events.size() - 1, -1, -1):
		var entry: Dictionary = events[event_index]
		var timestamp_text := _format_timestamp(int(entry.get("timestamp", 0)))
		_add_info_line(card, "[%s] %s" % [timestamp_text, entry.get("message", "System entry")], _category_color(str(entry.get("category", "system"))))

func _render_progress_tab() -> void:
	var card := _add_card("Bunker Progress", "Progress gates for the first playable milestone.")
	_add_stat_row(card, "Base Level", str(IdleEconomyConfig.get_base_level(current_state)), TEXT_COLOR)
	_add_stat_row(card, "Green Zone", "Unlocked", SUCCESS_COLOR)
	_add_stat_row(card, "Yellow Zone", _unlock_text("yellow"), _unlock_color("yellow"))
	_add_stat_row(card, "Red Zone", _unlock_text("red"), _unlock_color("red"))

	var ftue: Dictionary = current_state.get("ftue", {})
	var ftue_card := _add_card("First-Playable Checks", "The bunker should support the first ten-minute loop.")
	_add_stat_row(ftue_card, "Starter Cache", _pass_fail(bool(ftue.get("starter_cache_claimed", false))), _bool_color(bool(ftue.get("starter_cache_claimed", false))))
	_add_stat_row(ftue_card, "First Expedition", _pass_fail(bool(ftue.get("first_expedition_complete", false))), _bool_color(bool(ftue.get("first_expedition_complete", false))))
	_add_stat_row(ftue_card, "First Craft", _pass_fail(bool(ftue.get("first_craft_complete", false))), _bool_color(bool(ftue.get("first_craft_complete", false))))

func _add_card(title_text: String, subtitle_text: String) -> VBoxContainer:
	var panel := _make_panel(PANEL_ALT)
	content_root.add_child(panel)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	body.add_child(title)

	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", SUBTEXT_COLOR)
	body.add_child(subtitle)

	return body

func _add_info_line(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _add_stat_row(parent: VBoxContainer, label_text: String, value_text: String, value_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", SUBTEXT_COLOR)
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", value_color)
	row.add_child(value)

func _make_panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_stylebox(color, BORDER_COLOR, 12))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel

func _make_button(text_value: String, kind: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _button_style(kind, false))
	button.add_theme_stylebox_override("hover", _button_style(kind, true))
	button.add_theme_stylebox_override("pressed", _button_style(kind, true))
	button.add_theme_stylebox_override("disabled", _button_style("ghost", false))
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", SUBTEXT_COLOR)
	return button

func _button_style(kind: String, hovered: bool) -> StyleBoxFlat:
	var fill := PANEL_ALT
	match kind:
		"primary":
			fill = ACCENT_COLOR if hovered else Color("2E6164")
		"secondary":
			fill = Color("39454E") if hovered else Color("2A353D")
		"ghost":
			fill = Color("202A31") if hovered else Color("182127")
		"danger":
			fill = Color("8B4230") if hovered else DANGER_COLOR
	return _make_stylebox(fill, BORDER_COLOR, 10)

func _make_stylebox(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _refresh_nav_buttons() -> void:
	for tab_id in nav_buttons.keys():
		var button: Button = nav_buttons.get(tab_id)
		if button == null:
			continue
		var kind := "primary" if tab_id == active_tab else "ghost"
		button.add_theme_stylebox_override("normal", _button_style(kind, false))
		button.add_theme_stylebox_override("hover", _button_style(kind, true))
		button.add_theme_stylebox_override("pressed", _button_style(kind, true))

func _update_footer() -> void:
	var active_expedition: Dictionary = current_state.get("active_expedition", {})
	if active_expedition.is_empty():
		footer_label.text = "Idle bunker scaffold active • open the Expeditions tab to dispatch the first team"
	else:
		var remaining := max(0, int(active_expedition.get("finish_unix", 0)) - int(Time.get_unix_time_from_system()))
		footer_label.text = "%s returning in %s" % [active_expedition.get("title", "Expedition"), _format_duration(remaining)]

func _build_active_expedition_text() -> String:
	var active_expedition: Dictionary = current_state.get("active_expedition", {})
	if active_expedition.is_empty():
		return "No active expedition. Dispatch a Green Zone run to start the loop."

	var remaining := max(0, int(active_expedition.get("finish_unix", 0)) - int(Time.get_unix_time_from_system()))
	return "%s • %s remaining" % [active_expedition.get("title", "Expedition"), _format_duration(remaining)]

func _build_summary_text(summary: Dictionary) -> String:
	if summary.is_empty():
		return "No recent completions."

	var parts: Array[String] = []
	var generated: Dictionary = summary.get("generated", {})
	if not generated.is_empty():
		parts.append("Passive income: %s" % IdleEconomyConfig.build_amount_text(generated))

	var completed_crafts: Array = summary.get("completed_crafts", [])
	if not completed_crafts.is_empty():
		var craft_names: Array[String] = []
		for entry in completed_crafts:
			craft_names.append(str(entry.get("title", "Recipe")))
		parts.append("Crafting complete: %s" % ", ".join(craft_names))

	var expedition_result: Dictionary = summary.get("expedition_result", {})
	if not expedition_result.is_empty():
		parts.append("Expedition result: %s (%s)" % [expedition_result.get("title", "Run"), str(expedition_result.get("outcome", "full")).capitalize()])

	var new_event_cards: Array = summary.get("new_event_cards", [])
	if not new_event_cards.is_empty():
		parts.append("New event card: %s" % new_event_cards[0].get("title", "Field Intel"))

	if parts.is_empty():
		return "No recent completions."
	return "\n".join(parts)

func _build_craft_queue_text() -> String:
	var queue: Array = current_state.get("craft_queue", [])
	if queue.is_empty():
		return "No jobs queued. Queue Planks or Rope to complete the first craft objective."

	var parts: Array[String] = []
	for entry in queue:
		var finish_unix := int(entry.get("finish_unix", 0))
		var remaining := max(0, finish_unix - int(Time.get_unix_time_from_system()))
		parts.append("%s • %s" % [entry.get("title", "Recipe"), _format_duration(remaining)])
	return "\n".join(parts)

func _craft_button_reason(recipe_id: String) -> String:
	var recipe: Dictionary = IdleEconomyConfig.get_recipe_def(recipe_id)
	if IdleEconomyConfig.get_room_level(current_state, "workshop") <= 0:
		return "Workshop offline."

	var queue: Array = current_state.get("craft_queue", [])
	if queue.size() >= 3:
		return "Crafting queue full."

	if not IdleEconomyConfig.can_afford(current_state.get("resources", {}), recipe.get("inputs", {})):
		return "Not enough materials."

	return ""

func _unlock_text(zone_id: String) -> String:
	if IdleEconomyConfig.is_zone_unlocked(current_state, zone_id):
		return "Unlocked"
	return IdleEconomyConfig.get_zone_unlock_reason(current_state, zone_id)

func _unlock_color(zone_id: String) -> Color:
	return SUCCESS_COLOR if IdleEconomyConfig.is_zone_unlocked(current_state, zone_id) else WARNING_COLOR

func _pass_fail(value: bool) -> String:
	return "Ready" if value else "Pending"

func _bool_color(value: bool) -> Color:
	return SUCCESS_COLOR if value else WARNING_COLOR

func _category_color(category: String) -> Color:
	match category:
		"success":
			return SUCCESS_COLOR
		"warning":
			return WARNING_COLOR
		"expedition":
			return ACCENT_COLOR
		"craft":
			return TEXT_COLOR
		_:
			return SUBTEXT_COLOR

func _notification_color(notification_type: int) -> Color:
	match notification_type:
		1:
			return SUCCESS_COLOR
		2, 3:
			return WARNING_COLOR
		4, 5:
			return ACCENT_COLOR
		_:
			return SUBTEXT_COLOR

func _format_duration(total_seconds: int) -> String:
	var seconds := max(0, total_seconds)
	var minutes := seconds / 60
	var remaining_seconds := seconds % 60
	if minutes <= 0:
		return "%ss" % remaining_seconds
	if minutes < 60:
		return "%dm %02ds" % [minutes, remaining_seconds]
	var hours := minutes / 60
	return "%dh %02dm" % [hours, minutes % 60]

func _format_timestamp(unix_time: int) -> String:
	if unix_time <= 0:
		return "--:--"
	var stamp: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d:%02d" % [int(stamp.get("hour", 0)), int(stamp.get("minute", 0))]

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _on_tab_pressed(tab_id: String) -> void:
	active_tab = tab_id
	_rebuild_content()
	_refresh_nav_buttons()
	_update_footer()

func _on_starter_cache_pressed() -> void:
	starter_cache_requested.emit()

func _on_expedition_pressed(zone_id: String) -> void:
	expedition_requested.emit(zone_id)

func _on_room_upgrade_pressed(room_id: String) -> void:
	room_upgrade_requested.emit(room_id)

func _on_craft_pressed(recipe_id: String) -> void:
	craft_requested.emit(recipe_id)

func _on_daily_reward_pressed() -> void:
	daily_reward_requested.emit()

func _on_event_card_action_pressed(card_id: String, action_id: String) -> void:
	event_card_action_requested.emit(card_id, action_id)
