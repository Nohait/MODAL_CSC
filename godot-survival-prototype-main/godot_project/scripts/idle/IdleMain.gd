extends Node

const IdleEconomyConfig = preload("res://scripts/idle/IdleEconomyConfig.gd")
const PassiveTickSystem = preload("res://scripts/idle/PassiveTickSystem.gd")
const ExpeditionSystem = preload("res://scripts/idle/ExpeditionSystem.gd")
const IdleShell = preload("res://scripts/ui/IdleShell.gd")
const InventoryScene = preload("res://scripts/inventory/Inventory.gd")
const SaveLoadSystemScene = preload("res://scripts/core/SaveLoadSystem.gd")
const WorkstationSystemScene = preload("res://scripts/base/WorkstationSystem.gd")
const NotificationSystemScene = preload("res://scripts/ui/NotificationSystem.gd")
const WorldEventSystemScene = preload("res://scripts/events/WorldEventSystem.gd")

const IDLE_AUTOSAVE_FILE := "autosave.save"
const IDLE_WORKBENCH_TYPE := 1
const IDLE_WORKBENCH_POSITION := Vector2(12, 8)
const MAX_IDLE_QUEUE := 3
const MAX_EVENT_CARDS := 2

const EVENT_EMERGENCY_CACHE := 2
const EVENT_TRADER_CARAVAN := 4
const EVENT_WANDERING_MERCHANT := 5
const EVENT_SURVIVOR_RESCUE := 6
const EVENT_HELICOPTER_CRASH := 16
const EVENT_HIDDEN_BUNKER := 18
const EVENT_ABANDONED_CONVOY := 19

var state: Dictionary = {}
var passive_tick_system: PassiveTickSystem
var expedition_system: ExpeditionSystem
var shell: Control
var inventory
var save_load_system
var workstation_system
var notification_system
var world_event_system

var tick_timer: Timer
var autosave_timer: Timer
var last_summary: Dictionary = {}
var _pending_craft_completions: Array = []

func _ready() -> void:
	add_to_group("idle_mode_root")
	_install_shared_systems()
	_install_systems()
	_connect_runtime_signals()
	_load_or_initialize_state()
	_install_shell()
	_seed_event_log_if_needed()
	var startup_summary := _apply_progress_since_last_tick()
	if _summary_has_content(startup_summary):
		last_summary = startup_summary
	_refresh_ui()
	_start_timers()
	print("IdleMain ready - open scenes/idle/IdleMain.tscn to run the bunker prototype")

func _install_shared_systems() -> void:
	inventory = get_tree().get_first_node_in_group("inventory")
	if inventory == null:
		inventory = InventoryScene.new()
		inventory.name = "Inventory"
		add_child(inventory)

	save_load_system = get_node_or_null("SaveLoadSystem")
	if save_load_system == null:
		save_load_system = SaveLoadSystemScene.new()
		save_load_system.name = "SaveLoadSystem"
		add_child(save_load_system)

	workstation_system = get_node_or_null("WorkstationSystem")
	if workstation_system == null:
		workstation_system = WorkstationSystemScene.new()
		workstation_system.name = "WorkstationSystem"
		add_child(workstation_system)
	workstation_system.auto_update_enabled = false

	notification_system = get_node_or_null("NotificationSystem")
	if notification_system == null:
		notification_system = NotificationSystemScene.new()
		notification_system.name = "NotificationSystem"
		add_child(notification_system)

	world_event_system = get_node_or_null("WorldEventSystem")
	if world_event_system == null:
		world_event_system = WorldEventSystemScene.new()
		world_event_system.name = "WorldEventSystem"
		add_child(world_event_system)

func _install_systems() -> void:
	passive_tick_system = PassiveTickSystem.new()
	passive_tick_system.name = "PassiveTickSystem"
	add_child(passive_tick_system)

	expedition_system = ExpeditionSystem.new()
	expedition_system.name = "ExpeditionSystem"
	add_child(expedition_system)

func _connect_runtime_signals() -> void:
	if workstation_system != null:
		workstation_system.crafting_completed.connect(_on_workstation_crafting_completed)

func _load_or_initialize_state() -> void:
	state = _make_default_state()
	var loaded := false

	if save_load_system and save_load_system.save_exists(IDLE_AUTOSAVE_FILE):
		loaded = save_load_system.load_autosave()

	if not loaded:
		var legacy_state := _load_legacy_state()
		state = legacy_state if not legacy_state.is_empty() else _make_default_state()
		_sync_inventory_from_state_resources()
		if workstation_system:
			workstation_system.load_data({})
		if notification_system:
			notification_system.load_data({})
		if world_event_system:
			world_event_system.load_data({})

	_ensure_idle_workstations()
	_sync_resources_from_inventory()
	state["craft_queue"] = _snapshot_craft_queue()

func _make_default_state() -> Dictionary:
	return IdleEconomyConfig.normalize_state(IdleEconomyConfig.make_default_state())

func _load_legacy_state() -> Dictionary:
	if not FileAccess.file_exists(IdleEconomyConfig.SAVE_PATH):
		return {}

	var file := FileAccess.open(IdleEconomyConfig.SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return {}

	return IdleEconomyConfig.normalize_state(parsed)

func save_idle_data() -> Dictionary:
	return {
		"state": _snapshot_persistent_state(),
		"workstations": workstation_system.save_data() if workstation_system else {},
		"notifications": notification_system.save_data() if notification_system else {},
		"world_events": world_event_system.save_data() if world_event_system else {},
	}

func load_idle_data(data: Dictionary) -> void:
	var idle_state: Dictionary = data.get("state", {})
	if idle_state.is_empty() and data.has("resources"):
		idle_state = data

	state = _make_default_state()
	if not idle_state.is_empty():
		state = IdleEconomyConfig.normalize_state(idle_state)

	if workstation_system:
		workstation_system.load_data(data.get("workstations", {}))
	if notification_system:
		notification_system.load_data(data.get("notifications", {}))
	if world_event_system:
		world_event_system.load_data(data.get("world_events", {}))

	if inventory and inventory.has_method("serialize_items") and inventory.serialize_items().is_empty():
		_sync_inventory_from_state_resources()
	else:
		_sync_resources_from_inventory()

	_ensure_idle_workstations()
	state["craft_queue"] = _snapshot_craft_queue()

func _install_shell() -> void:
	shell = IdleShell.new()
	shell.name = "IdleShell"
	add_child(shell)

	shell.starter_cache_requested.connect(_on_starter_cache_requested)
	shell.expedition_requested.connect(_on_expedition_requested)
	shell.room_upgrade_requested.connect(_on_room_upgrade_requested)
	shell.craft_requested.connect(_on_craft_requested)
	shell.daily_reward_requested.connect(_on_daily_reward_requested)
	shell.event_card_action_requested.connect(_on_event_card_action_requested)

func _start_timers() -> void:
	tick_timer = Timer.new()
	tick_timer.name = "TickTimer"
	tick_timer.wait_time = 1.0
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_tick_timer_timeout)
	add_child(tick_timer)

	autosave_timer = Timer.new()
	autosave_timer.name = "AutosaveTimer"
	autosave_timer.wait_time = 20.0
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(_save_state)
	add_child(autosave_timer)

func _save_state() -> void:
	state["last_tick_unix"] = int(Time.get_unix_time_from_system())
	state["craft_queue"] = _snapshot_craft_queue()
	if save_load_system:
		save_load_system.autosave()

func _seed_event_log_if_needed() -> void:
	var log_entries: Array = state.get("event_log", [])
	if not log_entries.is_empty():
		return
	_append_event("Idle command bunker online. Claim the starter cache to begin.", "system")

func _on_tick_timer_timeout() -> void:
	var summary := _apply_progress_since_last_tick()
	if _summary_has_content(summary):
		last_summary = summary
	_refresh_ui()

func _apply_progress_since_last_tick() -> Dictionary:
	var now_unix := int(Time.get_unix_time_from_system())
	var previous_tick := int(state.get("last_tick_unix", now_unix))
	var elapsed_seconds := max(0, now_unix - previous_tick)
	state["last_tick_unix"] = now_unix

	if elapsed_seconds <= 0:
		state["craft_queue"] = _snapshot_craft_queue()
		return {}

	var passive_before := _sync_state_resources_from_inventory()
	var passive_summary := passive_tick_system.apply_passive_progress(state, float(elapsed_seconds))
	var passive_generated := _commit_state_resource_changes(passive_before)
	var completed_crafts := _advance_workstations(float(elapsed_seconds))

	var expedition_before := _sync_state_resources_from_inventory()
	var expedition_result := expedition_system.resolve_ready(state, now_unix)
	var expedition_rewards := _commit_state_resource_changes(expedition_before)
	if not expedition_result.is_empty():
		expedition_result["rewards"] = expedition_rewards

	for completed in completed_crafts:
		_append_event("Craft complete: %s ready." % completed.get("title", "Recipe"), "craft")

	if not expedition_result.is_empty():
		var outcome_label := str(expedition_result.get("outcome", "full")).capitalize()
		_append_event("%s returned with %s." % [expedition_result.get("title", "Expedition"), outcome_label], "expedition")
		_notify_expedition_result(expedition_result)

	var new_event_cards := _maybe_spawn_follow_up_card(expedition_result)
	var summary := {
		"elapsed_seconds": float(passive_summary.get("elapsed_seconds", 0.0)),
		"generated": passive_generated,
		"completed_crafts": completed_crafts,
		"expedition_result": expedition_result,
		"new_event_cards": new_event_cards,
	}

	state["craft_queue"] = _snapshot_craft_queue()
	IdleEconomyConfig.trim_event_log(state)
	return summary

func _on_starter_cache_requested() -> void:
	var ftue: Dictionary = state.get("ftue", {})
	if bool(ftue.get("starter_cache_claimed", false)):
		return

	var granted := _grant_bundle(IdleEconomyConfig.STARTER_CACHE)
	ftue["starter_cache_claimed"] = true
	state["ftue"] = ftue
	last_summary = {
		"elapsed_seconds": 0.0,
		"generated": granted,
		"completed_crafts": [],
		"expedition_result": {},
		"new_event_cards": [],
	}
	_append_event("Starter cache claimed. Bunker stores are finally stocked.", "success")
	if notification_system:
		notification_system.show_success("Starter Cache", IdleEconomyConfig.build_amount_text(granted))
	_save_state()
	_refresh_ui()

func _on_expedition_requested(zone_id: String) -> void:
	var before_resources := _sync_state_resources_from_inventory()
	var result := expedition_system.start_expedition(state, zone_id, int(Time.get_unix_time_from_system()))
	var spent_resources := _commit_state_resource_changes(before_resources)
	if bool(result.get("ok", false)):
		var expedition: Dictionary = result.get("expedition", {})
		_append_event("Dispatched team to %s." % expedition.get("title", zone_id.capitalize()), "expedition")
		if notification_system:
			notification_system.show_system_message("Dispatched %s with %s." % [expedition.get("title", zone_id.capitalize()), IdleEconomyConfig.build_amount_text(spent_resources)], true)
	else:
		_append_event(str(result.get("reason", "Expedition launch failed.")), "warning")
		if notification_system:
			notification_system.show_warning("Expedition Blocked", str(result.get("reason", "Expedition launch failed.")))

	_save_state()
	_refresh_ui()

func _on_room_upgrade_requested(room_id: String) -> void:
	var current_level := IdleEconomyConfig.get_room_level(state, room_id)
	var cost := IdleEconomyConfig.get_room_upgrade_cost(room_id, current_level)
	if cost.is_empty():
		_append_event("%s is already maxed for this prototype." % IdleEconomyConfig.get_room_def(room_id).get("title", room_id.capitalize()), "warning")
		_refresh_ui()
		return

	var before_resources := _sync_state_resources_from_inventory()
	if not IdleEconomyConfig.spend_resources(state, cost):
		_append_event("Not enough supplies to upgrade %s." % IdleEconomyConfig.get_room_def(room_id).get("title", room_id.capitalize()), "warning")
		if notification_system:
			notification_system.show_warning("Upgrade Blocked", "Not enough supplies.")
		_refresh_ui()
		return
	_commit_state_resource_changes(before_resources)

	state["rooms"][room_id]["level"] = current_level + 1
	var action := "Unlocked" if current_level <= 0 else "Upgraded"
	_append_event("%s %s to L%d." % [action, IdleEconomyConfig.get_room_def(room_id).get("title", room_id.capitalize()), current_level + 1], "success")
	if notification_system:
		notification_system.show_success("Room Upgrade", "%s %s to L%d." % [action, IdleEconomyConfig.get_room_def(room_id).get("title", room_id.capitalize()), current_level + 1])
	_save_state()
	_refresh_ui()

func _on_craft_requested(recipe_id: String) -> void:
	_ensure_idle_workstations()
	var queue_snapshot := _snapshot_craft_queue()
	if queue_snapshot.size() >= MAX_IDLE_QUEUE:
		_append_event("Crafting queue full.", "warning")
		if notification_system:
			notification_system.show_warning("Craft Queue Full", "Collect outputs before queuing more jobs.")
		_refresh_ui()
		return

	var result := workstation_system.start_crafting(_get_idle_workbench_id(), recipe_id, inventory)
	_sync_resources_from_inventory()
	state["craft_queue"] = _snapshot_craft_queue()
	if bool(result.get("success", false)):
		var queue_after := _snapshot_craft_queue()
		var title := _get_recipe_title(recipe_id)
		var finish_unix := int(Time.get_unix_time_from_system())
		for entry in queue_after:
			if str(entry.get("recipe_id", "")) == recipe_id:
				finish_unix = int(entry.get("finish_unix", finish_unix))
				break
		_append_event("Queued %s. Ready in %s." % [title, _format_duration(max(0, finish_unix - int(Time.get_unix_time_from_system())))], "craft")
		if notification_system:
			notification_system.show_system_message("Queued %s." % title)
	else:
		_append_event(str(result.get("error", "Crafting failed.")), "warning")
		if notification_system:
			notification_system.show_warning("Craft Blocked", str(result.get("error", "Crafting failed.")))

	_save_state()
	_refresh_ui()

func _on_daily_reward_requested() -> void:
	if not _is_daily_reward_available():
		_append_event("Daily reward already claimed today.", "warning")
		if notification_system:
			notification_system.show_warning("Daily Reward", "Come back after the next daily reset.")
		_refresh_ui()
		return

	var daily_rewards: Dictionary = state.get("daily_rewards", {})
	var today_index := _today_day_index()
	var previous_claim := int(daily_rewards.get("last_claim_day", -1))
	var next_streak := 1 if previous_claim != today_index - 1 else int(daily_rewards.get("streak", 0)) + 1
	daily_rewards["last_claim_day"] = today_index
	daily_rewards["streak"] = min(next_streak, 7)
	state["daily_rewards"] = daily_rewards

	var granted := _grant_bundle(_build_daily_reward_bundle(int(daily_rewards.get("streak", 1))))
	last_summary = {
		"elapsed_seconds": 0.0,
		"generated": granted,
		"completed_crafts": [],
		"expedition_result": {},
		"new_event_cards": [],
	}
	_append_event("Daily reward claimed. Streak %d secured." % int(daily_rewards.get("streak", 1)), "success")
	if notification_system:
		notification_system.show_success("Daily Reward", IdleEconomyConfig.build_amount_text(granted))
	_save_state()
	_refresh_ui()

func _on_event_card_action_requested(card_id: String, action_id: String) -> void:
	var card_index := _find_event_card_index(card_id)
	if card_index < 0:
		return

	var cards: Array = state.get("event_cards", [])
	var card: Dictionary = cards[card_index]
	if action_id == "dismiss":
		cards.remove_at(card_index)
		state["event_cards"] = cards
		if world_event_system:
			world_event_system.cancel_event(str(card.get("event_id", "")))
		_append_event("Ignored %s." % card.get("title", "field intel"), "warning")
		if notification_system:
			notification_system.show_system_message("Ignored %s." % card.get("title", "field intel"))
		_save_state()
		_refresh_ui()
		return

	var resolution := _resolve_event_card(card)
	if not bool(resolution.get("ok", false)):
		_append_event(str(resolution.get("message", "Event card resolution failed.")), "warning")
		if notification_system:
			notification_system.show_warning("Event Card", str(resolution.get("message", "Event card resolution failed.")))
		_refresh_ui()
		return

	cards.remove_at(card_index)
	state["event_cards"] = cards
	var granted: Dictionary = resolution.get("rewards", {})
	if granted.is_empty():
		_append_event("%s resolved with no usable haul." % card.get("title", "Event card"), "system")
	else:
		_append_event("%s resolved: %s." % [card.get("title", "Event card"), IdleEconomyConfig.build_amount_text(granted)], "success")
		if notification_system:
			notification_system.show_success(str(card.get("title", "Event Card")), IdleEconomyConfig.build_amount_text(granted))
	_save_state()
	_refresh_ui()

func _find_event_card_index(card_id: String) -> int:
	var cards: Array = state.get("event_cards", [])
	for index in range(cards.size()):
		var card: Dictionary = cards[index]
		if str(card.get("card_id", "")) == card_id:
			return index
	return -1

func _advance_workstations(elapsed_seconds: float) -> Array:
	if workstation_system == null or elapsed_seconds <= 0.0:
		return []

	_ensure_idle_workstations()
	_pending_craft_completions.clear()
	workstation_system.advance_time(elapsed_seconds)

	var output_bundle := {}
	for output in workstation_system.collect_output(_get_idle_workbench_id()):
		var item_data: Dictionary = output
		var item_id := str(item_data.get("id", ""))
		var count := float(item_data.get("count", 0))
		if item_id.is_empty() or count <= 0.0:
			continue
		output_bundle[item_id] = float(output_bundle.get(item_id, 0.0)) + count

	var granted_bundle := _grant_bundle(output_bundle)
	if not granted_bundle.is_empty():
		var ftue: Dictionary = state.get("ftue", {})
		ftue["first_craft_complete"] = true
		state["ftue"] = ftue

	if _pending_craft_completions.is_empty():
		var fallback: Array = []
		for resource_id in granted_bundle.keys():
			fallback.append({
				"recipe_id": resource_id,
				"title": IdleEconomyConfig.get_resource_title(str(resource_id)),
				"outputs": {resource_id: granted_bundle.get(resource_id, 0.0)},
			})
		return fallback

	return _pending_craft_completions.duplicate(true)

func _on_workstation_crafting_completed(_station_id: String, recipe_id: String, output: Dictionary) -> void:
	_pending_craft_completions.append({
		"recipe_id": recipe_id,
		"title": _get_recipe_title(recipe_id),
		"outputs": output.duplicate(true),
	})

func _get_idle_workbench_id() -> String:
	return "%d_%d_%d" % [IDLE_WORKBENCH_TYPE, int(IDLE_WORKBENCH_POSITION.x), int(IDLE_WORKBENCH_POSITION.y)]

func _ensure_idle_workstations() -> void:
	if workstation_system == null:
		return
	if workstation_system.get_workstation(_get_idle_workbench_id()).is_empty():
		workstation_system.place_workstation(IDLE_WORKBENCH_TYPE, IDLE_WORKBENCH_POSITION, 99)

func _snapshot_craft_queue() -> Array:
	if workstation_system == null:
		return []

	var workstation: Dictionary = workstation_system.get_workstation(_get_idle_workbench_id())
	if workstation.is_empty():
		return []

	var queue_snapshot: Array = []
	var cursor_unix := int(Time.get_unix_time_from_system())
	var current_recipe := str(workstation.get("current_recipe", ""))
	if not current_recipe.is_empty():
		cursor_unix += int(ceil(_estimate_remaining_craft_seconds(workstation, current_recipe)))
		queue_snapshot.append({
			"recipe_id": current_recipe,
			"title": _get_recipe_title(current_recipe),
			"finish_unix": cursor_unix,
		})

	for entry in workstation_system.get_queue(_get_idle_workbench_id()):
		var recipe_id := _queue_entry_recipe_id(entry)
		if recipe_id.is_empty():
			continue
		cursor_unix += int(ceil(_estimate_recipe_seconds(workstation, recipe_id)))
		queue_snapshot.append({
			"recipe_id": recipe_id,
			"title": _get_recipe_title(recipe_id),
			"finish_unix": cursor_unix,
		})

	if queue_snapshot.size() > MAX_IDLE_QUEUE:
		return queue_snapshot.slice(0, MAX_IDLE_QUEUE)
	return queue_snapshot

func _queue_entry_recipe_id(entry) -> String:
	if entry is Dictionary:
		return str(entry.get("recipe_id", ""))
	return str(entry)

func _estimate_recipe_seconds(workstation: Dictionary, recipe_id: String) -> float:
	var recipe: Dictionary = IdleEconomyConfig.get_recipe_def(recipe_id)
	var craft_time := float(recipe.get("duration_seconds", 10.0))
	var craft_speed := maxf(float(workstation.get("crafting_speed", 1.0)), 0.001)
	return craft_time / craft_speed

func _estimate_remaining_craft_seconds(workstation: Dictionary, recipe_id: String) -> float:
	var recipe_seconds := _estimate_recipe_seconds(workstation, recipe_id)
	var remaining_progress := maxf(0.0, 1.0 - float(workstation.get("craft_progress", 0.0)))
	return recipe_seconds * remaining_progress

func _get_recipe_title(recipe_id: String) -> String:
	var recipe: Dictionary = IdleEconomyConfig.get_recipe_def(recipe_id)
	return str(recipe.get("title", recipe_id.capitalize()))

func _sync_state_resources_from_inventory() -> Dictionary:
	var resources: Dictionary = state.get("resources", {}).duplicate(true)
	if inventory == null:
		state["resources"] = resources
		return resources

	for resource_id in IdleEconomyConfig.RESOURCE_ORDER:
		resources[resource_id] = float(inventory.get_item_count(resource_id))
	state["resources"] = resources
	return resources.duplicate(true)

func _sync_resources_from_inventory() -> void:
	_sync_state_resources_from_inventory()

func _sync_inventory_from_state_resources() -> void:
	if inventory == null:
		return

	inventory.clear()
	var resources: Dictionary = state.get("resources", {})
	for resource_id in IdleEconomyConfig.RESOURCE_ORDER:
		var amount := int(round(float(resources.get(resource_id, 0.0))))
		if amount > 0:
			inventory.add_item(resource_id, amount)
	_sync_resources_from_inventory()

func _commit_state_resource_changes(previous_resources: Dictionary) -> Dictionary:
	if inventory == null:
		return state.get("resources", {}).duplicate(true)

	var target_resources: Dictionary = state.get("resources", {})
	for resource_id in IdleEconomyConfig.RESOURCE_ORDER:
		var before_amount := int(round(float(previous_resources.get(resource_id, 0.0))))
		var target_amount := int(round(float(target_resources.get(resource_id, before_amount))))
		var delta := target_amount - before_amount
		if delta > 0:
			inventory.add_item(resource_id, delta)
		elif delta < 0:
			inventory.remove_items({resource_id: -delta})

	_sync_resources_from_inventory()
	var actual_resources: Dictionary = state.get("resources", {})
	var resolved := {}
	for resource_id in IdleEconomyConfig.RESOURCE_ORDER:
		var actual_delta := int(round(float(actual_resources.get(resource_id, 0.0)))) - int(round(float(previous_resources.get(resource_id, 0.0))))
		if actual_delta != 0:
			resolved[resource_id] = float(actual_delta)
	return resolved

func _grant_bundle(bundle: Dictionary) -> Dictionary:
	var previous_resources := _sync_state_resources_from_inventory()
	for resource_id in bundle.keys():
		IdleEconomyConfig.add_resource(state, str(resource_id), float(bundle.get(resource_id, 0.0)))
	return _commit_state_resource_changes(previous_resources)

func _snapshot_persistent_state() -> Dictionary:
	_sync_resources_from_inventory()
	state["craft_queue"] = _snapshot_craft_queue()
	IdleEconomyConfig.trim_event_log(state)
	return state.duplicate(true)

func _build_ui_state() -> Dictionary:
	var ui_state := _snapshot_persistent_state()
	var daily_rewards: Dictionary = state.get("daily_rewards", {})
	var preview_streak := _next_daily_streak()
	ui_state["daily_reward_available"] = _is_daily_reward_available()
	ui_state["daily_reward_streak"] = int(daily_rewards.get("streak", 0))
	ui_state["daily_reward_preview_streak"] = preview_streak
	ui_state["daily_reward_preview"] = _build_daily_reward_bundle(preview_streak)
	ui_state["notification_history"] = notification_system.get_history(6) if notification_system else []
	return ui_state

func _is_daily_reward_available() -> bool:
	return int(state.get("daily_rewards", {}).get("last_claim_day", -1)) != _today_day_index()

func _next_daily_streak() -> int:
	var daily_rewards: Dictionary = state.get("daily_rewards", {})
	var last_claim_day := int(daily_rewards.get("last_claim_day", -1))
	var current_streak := int(daily_rewards.get("streak", 0))
	if last_claim_day == _today_day_index():
		return current_streak
	if last_claim_day == _today_day_index() - 1:
		return min(current_streak + 1, 7)
	return 1

func _today_day_index() -> int:
	return int(floor(Time.get_unix_time_from_system() / 86400.0))

func _build_daily_reward_bundle(streak: int) -> Dictionary:
	var day_streak := clampi(streak, 1, 7)
	var reward := {
		"water": float(2 + day_streak),
		"food": float(2 + day_streak),
		"survivor_credits": float(1 + int(floor(float(day_streak) / 2.0))),
	}
	if day_streak >= 3:
		reward["planks"] = 1.0
	if day_streak >= 5:
		reward["med_supplies"] = 1.0
	if day_streak >= 7:
		reward["signal_intel"] = 1.0
	return reward

func _maybe_spawn_follow_up_card(expedition_result: Dictionary) -> Array:
	if world_event_system == null or expedition_result.is_empty():
		return []

	var zone_id := str(expedition_result.get("zone_id", ""))
	if zone_id != "yellow" and zone_id != "red":
		return []

	var cards: Array = state.get("event_cards", [])
	if cards.size() >= MAX_EVENT_CARDS:
		return []

	var event_type := _pick_follow_up_event_type(zone_id, str(expedition_result.get("outcome", "full")))
	var spawned := world_event_system.spawn_event(event_type, Vector2.ZERO, zone_id)
	if not bool(spawned.get("success", false)):
		return []

	var event_data: Dictionary = spawned.get("event", {})
	var card := _build_event_card(event_data, zone_id, str(expedition_result.get("outcome", "full")))
	cards.append(card)
	state["event_cards"] = cards
	_append_event("%s intel opened a follow-up card: %s." % [zone_id.capitalize(), card.get("title", "Opportunity")], "expedition")
	if notification_system:
		notification_system.show_system_message("New event card: %s." % card.get("title", "Opportunity"), true)
	return [card]

func _pick_follow_up_event_type(zone_id: String, outcome: String) -> int:
	var candidates := [EVENT_EMERGENCY_CACHE, EVENT_TRADER_CARAVAN, EVENT_SURVIVOR_RESCUE]
	if zone_id == "red":
		candidates = [EVENT_HELICOPTER_CRASH, EVENT_HIDDEN_BUNKER, EVENT_WANDERING_MERCHANT, EVENT_ABANDONED_CONVOY]
		if outcome == "jackpot":
			candidates = [EVENT_HIDDEN_BUNKER, EVENT_HELICOPTER_CRASH, EVENT_ABANDONED_CONVOY]
		elif outcome == "injury" or outcome == "failure":
			candidates = [EVENT_WANDERING_MERCHANT, EVENT_ABANDONED_CONVOY, EVENT_HELICOPTER_CRASH]
	elif outcome == "injury" or outcome == "failure":
		candidates = [EVENT_SURVIVOR_RESCUE, EVENT_EMERGENCY_CACHE, EVENT_TRADER_CARAVAN]

	if candidates.is_empty():
		return EVENT_EMERGENCY_CACHE
	return candidates[int(Time.get_unix_time_from_system()) % candidates.size()]

func _build_event_card(event_data: Dictionary, zone_id: String, outcome: String) -> Dictionary:
	var event_type := int(event_data.get("type", -1))
	var interaction := _event_interaction_for_type(event_type)
	return {
		"card_id": str(event_data.get("id", "")),
		"event_id": str(event_data.get("id", "")),
		"title": str(event_data.get("display_name", "Opportunity")),
		"description": str(event_data.get("description", "New field intel needs a call.")),
		"zone_id": zone_id,
		"outcome": outcome,
		"rarity_label": _event_rarity_label(int(event_data.get("rarity", 0))),
		"source_label": "%s Zone %s result" % [zone_id.capitalize(), outcome.capitalize()],
		"interaction": interaction,
		"action_label": _event_action_label(interaction),
		"dismiss_label": "Ignore",
		"reward_preview": _event_reward_preview(event_type, zone_id),
	}

func _event_interaction_for_type(event_type: int) -> String:
	match event_type:
		EVENT_TRADER_CARAVAN, EVENT_WANDERING_MERCHANT:
			return "trade"
		EVENT_SURVIVOR_RESCUE:
			return "rescue"
		EVENT_HIDDEN_BUNKER:
			return "explore"
		_:
			return "loot"

func _event_action_label(interaction: String) -> String:
	match interaction:
		"trade":
			return "Close a Deal"
		"rescue":
			return "Send Rescue Team"
		"explore":
			return "Investigate"
		_:
			return "Claim Cache"

func _event_reward_preview(event_type: int, zone_id: String) -> String:
	match event_type:
		EVENT_TRADER_CARAVAN, EVENT_WANDERING_MERCHANT:
			return "Targeted bunker supplies and credits."
		EVENT_SURVIVOR_RESCUE:
			return "Credits, medical stock, and survivor goodwill."
		EVENT_HIDDEN_BUNKER:
			return "Signal intel, electronics, and rare salvage."
		EVENT_HELICOPTER_CRASH, EVENT_ABANDONED_CONVOY:
			return "Heavy salvage, parts, and rare field loot."
		_:
			return "Materials suited for %s runs." % zone_id.capitalize()

func _event_rarity_label(rarity: int) -> String:
	match rarity:
		1:
			return "Uncommon"
		2:
			return "Rare"
		3:
			return "Epic"
		4:
			return "Legendary"
		_:
			return "Common"

func _resolve_event_card(card: Dictionary) -> Dictionary:
	if world_event_system == null:
		return {"ok": false, "message": "World event system unavailable.", "rewards": {}}

	var result := world_event_system.interact_with_event(str(card.get("event_id", "")), str(card.get("interaction", "loot")))
	if not bool(result.get("success", false)):
		return {"ok": false, "message": str(result.get("error", "Unable to resolve event card.")), "rewards": {}}

	var reward_bundle := {}
	var loot: Array = result.get("loot", [])
	if not loot.is_empty():
		reward_bundle = _convert_event_loot_to_resources(loot)
	elif result.has("rewards"):
		reward_bundle = _convert_event_rewards(result.get("rewards", {}))
	else:
		var action := str(result.get("action", ""))
		if action == "open_trade":
			reward_bundle = _build_trade_reward_bundle(card, result)
		elif action == "enter_dungeon":
			reward_bundle = _build_explore_reward_bundle(card)
		else:
			reward_bundle = {"survivor_credits": 1.0}

	var granted := _grant_bundle(reward_bundle)
	world_event_system.cancel_event(str(card.get("event_id", "")))
	return {"ok": true, "message": "Resolved", "rewards": granted}

func _convert_event_rewards(rewards: Dictionary) -> Dictionary:
	var bundle := {}
	var reputation := int(rewards.get("reputation", 0))
	if reputation > 0:
		bundle["survivor_credits"] = max(1.0, float(int(round(float(reputation) / 10.0))))
	if bool(rewards.get("potential_recruit", false)):
		bundle["med_supplies"] = 1.0
		bundle["food"] = 2.0
		bundle["water"] = 2.0
	return bundle

func _build_trade_reward_bundle(card: Dictionary, result: Dictionary) -> Dictionary:
	var bundle := {
		"food": 2.0,
		"fuel": 1.0,
		"survivor_credits": 2.0,
	}
	if bool(result.get("special_deals", false)):
		bundle["metal_parts"] = 1.0
	if bool(result.get("accepts_special", false)) or str(card.get("zone_id", "")) == "red":
		bundle["electronics"] = 1.0
	return bundle

func _build_explore_reward_bundle(card: Dictionary) -> Dictionary:
	var bundle := {
		"signal_intel": 1.0,
		"scrap": 4.0,
		"survivor_credits": 2.0,
	}
	if str(card.get("zone_id", "")) == "red":
		bundle["electronics"] = 1.0
	return bundle

func _convert_event_loot_to_resources(loot: Array) -> Dictionary:
	var bundle := {}
	for loot_entry in loot:
		var item_data: Dictionary = loot_entry
		var item_id := str(item_data.get("id", ""))
		var count := float(item_data.get("count", 1))
		var mapped_resource := _map_event_loot_to_resource(item_id)
		if mapped_resource.is_empty():
			continue

		var converted_amount := count
		if item_id.begins_with("weapon_") or item_id.begins_with("armor_"):
			converted_amount = maxf(2.0, count)
		elif item_id.begins_with("ammo_"):
			converted_amount = maxf(1.0, round(count / 15.0))
		elif mapped_resource == "electronics":
			converted_amount = maxf(1.0, count)

		bundle[mapped_resource] = float(bundle.get(mapped_resource, 0.0)) + converted_amount
	return bundle

func _map_event_loot_to_resource(item_id: String) -> String:
	if item_id == "water_bottle":
		return "water"
	if item_id.begins_with("food"):
		return "food"
	if item_id in ["bandage", "medkit", "medkit_military", "first_aid_kit", "antibiotics"]:
		return "med_supplies"
	if item_id == "rope":
		return "rope"
	if item_id in ["flashlight", "radio", "battery", "circuit_board", "night_vision", "motion_sensor", "blueprint_weapon"]:
		return "electronics"
	if item_id == "grenade" or item_id == "explosive" or item_id.begins_with("weapon_") or item_id.begins_with("armor_") or item_id.begins_with("ammo_"):
		return "defense_kits"
	if item_id in ["tools_basic", "nails", "gears", "steel_plate", "engine_part", "weapon_mod"]:
		return "metal_parts"
	return "scrap"

func _notify_expedition_result(expedition_result: Dictionary) -> void:
	if notification_system == null or expedition_result.is_empty():
		return

	var title := "%s Result" % str(expedition_result.get("title", "Expedition"))
	var outcome := str(expedition_result.get("outcome", "full"))
	match outcome:
		"jackpot":
			notification_system.show_achievement(title, "Jackpot haul secured.")
		"failure":
			notification_system.show_error(title, "The team returned empty-handed.")
		"injury":
			notification_system.show_warning(title, "The team returned hurt, but alive.")
		"partial":
			notification_system.show_warning(title, "Only part of the haul made it home.")
		_:
			notification_system.show_success(title, "The full haul made it back to base.")

func _append_event(message: String, category: String) -> void:
	var entries: Array = state.get("event_log", [])
	entries.append({
		"message": message,
		"category": category,
		"timestamp": int(Time.get_unix_time_from_system()),
	})
	state["event_log"] = entries
	IdleEconomyConfig.trim_event_log(state)

func _refresh_ui() -> void:
	if shell and shell.has_method("render_state"):
		shell.render_state(_build_ui_state(), last_summary.duplicate(true))

func _summary_has_content(summary: Dictionary) -> bool:
	if summary.is_empty():
		return false
	if not summary.get("generated", {}).is_empty():
		return true
	if not summary.get("completed_crafts", []).is_empty():
		return true
	if not summary.get("expedition_result", {}).is_empty():
		return true
	if not summary.get("new_event_cards", []).is_empty():
		return true
	return false

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_state()
