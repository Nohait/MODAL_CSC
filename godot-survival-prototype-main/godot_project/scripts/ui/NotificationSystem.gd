extends Node
class_name NotificationSystemClass
## Handles in-game notifications, toasts, alerts, and message queuing
## Manages display priority, stacking, and notification history

signal notification_shown(notification_id: String, data: Dictionary)
signal notification_dismissed(notification_id: String)
signal notification_clicked(notification_id: String)
signal notification_action(notification_id: String, action: String)
signal queue_updated(pending_count: int)

# ============================================================================
# NOTIFICATION CONFIGURATION
# ============================================================================

enum NotificationType {
	INFO,        # General information
	SUCCESS,     # Positive feedback
	WARNING,     # Caution/warning
	ERROR,       # Error/failure
	ACHIEVEMENT, # Achievement unlocked
	LOOT,        # Item acquired
	QUEST,       # Quest update
	COMBAT,      # Combat feedback
	SYSTEM,      # System messages
	SOCIAL,      # Multiplayer/social
	TUTORIAL,    # Tutorial hints
}

enum NotificationPosition {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT,
	CENTER,
}

enum NotificationPriority {
	LOW,     # Can be skipped if queue is full
	NORMAL,  # Standard priority
	HIGH,    # Shows above normal
	URGENT,  # Interrupts other notifications
}

const TYPE_SETTINGS := {
	NotificationType.INFO: {
		"icon": "notification_info",
		"color": Color(0.3, 0.6, 0.9),
		"sound": "ui_notification",
		"duration": 4.0,
		"position": NotificationPosition.TOP_RIGHT,
	},
	NotificationType.SUCCESS: {
		"icon": "notification_success",
		"color": Color(0.3, 0.8, 0.3),
		"sound": "ui_confirm",
		"duration": 3.0,
		"position": NotificationPosition.TOP_RIGHT,
	},
	NotificationType.WARNING: {
		"icon": "notification_warning",
		"color": Color(0.9, 0.7, 0.2),
		"sound": "ui_notification",
		"duration": 5.0,
		"position": NotificationPosition.TOP_CENTER,
	},
	NotificationType.ERROR: {
		"icon": "notification_error",
		"color": Color(0.9, 0.3, 0.3),
		"sound": "ui_error",
		"duration": 5.0,
		"position": NotificationPosition.TOP_CENTER,
	},
	NotificationType.ACHIEVEMENT: {
		"icon": "notification_achievement",
		"color": Color(1.0, 0.84, 0.0),
		"sound": "achievement_unlocked",
		"duration": 6.0,
		"position": NotificationPosition.TOP_CENTER,
	},
	NotificationType.LOOT: {
		"icon": "notification_loot",
		"color": Color(0.8, 0.6, 0.2),
		"sound": "item_pickup",
		"duration": 2.5,
		"position": NotificationPosition.BOTTOM_RIGHT,
	},
	NotificationType.QUEST: {
		"icon": "notification_quest",
		"color": Color(0.6, 0.4, 0.9),
		"sound": "quest_update",
		"duration": 5.0,
		"position": NotificationPosition.TOP_RIGHT,
	},
	NotificationType.COMBAT: {
		"icon": "notification_combat",
		"color": Color(0.9, 0.2, 0.2),
		"sound": "",  # Combat has its own sounds
		"duration": 2.0,
		"position": NotificationPosition.CENTER,
	},
	NotificationType.SYSTEM: {
		"icon": "notification_system",
		"color": Color(0.7, 0.7, 0.7),
		"sound": "ui_notification",
		"duration": 5.0,
		"position": NotificationPosition.TOP_CENTER,
	},
	NotificationType.SOCIAL: {
		"icon": "notification_social",
		"color": Color(0.3, 0.7, 0.9),
		"sound": "social_notification",
		"duration": 4.0,
		"position": NotificationPosition.TOP_RIGHT,
	},
	NotificationType.TUTORIAL: {
		"icon": "notification_tutorial",
		"color": Color(0.4, 0.8, 0.9),
		"sound": "tutorial_ping",
		"duration": 8.0,
		"position": NotificationPosition.BOTTOM_CENTER,
	},
}

const MAX_VISIBLE_NOTIFICATIONS := 5
const MAX_QUEUE_SIZE := 20
const MAX_HISTORY_SIZE := 100
const STACK_OFFSET := 60  # pixels between stacked notifications
const ANIMATION_DURATION := 0.3


# ============================================================================
# STATE
# ============================================================================

var _active_notifications: Array[Dictionary] = []
var _notification_queue: Array[Dictionary] = []
var _notification_history: Array[Dictionary] = []
var _notification_id_counter: int = 0
var _muted_types: Dictionary = {}  # NotificationType -> bool
var _do_not_disturb: bool = false
var _paused: bool = false


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_update_notifications(delta)
	_process_queue()


# ============================================================================
# NOTIFICATION CREATION
# ============================================================================

func show_notification(type: int, title: String, message: String = "", extra: Dictionary = {}) -> String:
	var notification := _create_notification(type, title, message, extra)
	return _queue_notification(notification)


func show_info(title: String, message: String = "") -> String:
	return show_notification(NotificationType.INFO, title, message)


func show_success(title: String, message: String = "") -> String:
	return show_notification(NotificationType.SUCCESS, title, message)


func show_warning(title: String, message: String = "") -> String:
	return show_notification(NotificationType.WARNING, title, message)


func show_error(title: String, message: String = "") -> String:
	return show_notification(NotificationType.ERROR, title, message)


func show_achievement(achievement_name: String, achievement_desc: String, icon: String = "") -> String:
	return show_notification(NotificationType.ACHIEVEMENT, achievement_name, achievement_desc, {
		"custom_icon": icon,
		"priority": NotificationPriority.HIGH,
	})


func show_loot(item_name: String, quantity: int = 1, rarity: String = "common") -> String:
	var message := ""
	if quantity > 1:
		message = "x%d" % quantity
	
	return show_notification(NotificationType.LOOT, item_name, message, {
		"rarity": rarity,
		"quantity": quantity,
	})


func show_quest_update(quest_name: String, update_text: String, is_complete: bool = false) -> String:
	var title := "Quest Complete!" if is_complete else "Quest Update"
	return show_notification(NotificationType.QUEST, title, "%s: %s" % [quest_name, update_text], {
		"is_complete": is_complete,
		"priority": NotificationPriority.HIGH if is_complete else NotificationPriority.NORMAL,
	})


func show_combat_text(text: String, is_critical: bool = false) -> String:
	return show_notification(NotificationType.COMBAT, text, "", {
		"is_critical": is_critical,
		"priority": NotificationPriority.LOW,
	})


func show_system_message(message: String, is_important: bool = false) -> String:
	var priority := NotificationPriority.HIGH if is_important else NotificationPriority.NORMAL
	return show_notification(NotificationType.SYSTEM, "System", message, {
		"priority": priority,
	})


func show_social(title: String, message: String, player_name: String = "") -> String:
	return show_notification(NotificationType.SOCIAL, title, message, {
		"player_name": player_name,
	})


func show_tutorial_hint(hint_text: String) -> String:
	return show_notification(NotificationType.TUTORIAL, "Hint", hint_text, {
		"priority": NotificationPriority.LOW,
	})


func _create_notification(type: int, title: String, message: String, extra: Dictionary) -> Dictionary:
	_notification_id_counter += 1
	var notification_id := "notif_%d_%d" % [Time.get_ticks_msec(), _notification_id_counter]
	
	var type_settings: Dictionary = TYPE_SETTINGS.get(type, TYPE_SETTINGS[NotificationType.INFO])
	
	var notification := {
		"id": notification_id,
		"type": type,
		"title": title,
		"message": message,
		"icon": extra.get("custom_icon", type_settings["icon"]),
		"color": extra.get("custom_color", type_settings["color"]),
		"sound": extra.get("custom_sound", type_settings["sound"]),
		"duration": extra.get("duration", type_settings["duration"]),
		"position": extra.get("position", type_settings["position"]),
		"priority": extra.get("priority", NotificationPriority.NORMAL),
		"actions": extra.get("actions", []),  # [{label, action_id}]
		"progress": extra.get("progress", -1.0),  # -1 = no progress bar
		"extra": extra,
		"timer": 0.0,
		"created_at": Time.get_unix_time_from_system(),
		"shown": false,
	}
	
	return notification


# ============================================================================
# QUEUE MANAGEMENT
# ============================================================================

func _queue_notification(notification: Dictionary) -> String:
	var type: int = notification["type"]
	
	# Check if muted
	if _muted_types.get(type, false):
		return notification["id"]
	
	# Check DND mode (allow urgent)
	if _do_not_disturb and notification["priority"] != NotificationPriority.URGENT:
		return notification["id"]
	
	# Check paused (allow urgent)
	if _paused and notification["priority"] != NotificationPriority.URGENT:
		_notification_queue.append(notification)
		emit_signal("queue_updated", _notification_queue.size())
		return notification["id"]
	
	# Check if can show immediately
	if _can_show_notification(notification):
		_show_notification_now(notification)
	else:
		# Queue it
		if _notification_queue.size() >= MAX_QUEUE_SIZE:
			# Remove lowest priority from queue
			_remove_lowest_priority_from_queue()
		
		_notification_queue.append(notification)
		_sort_queue()
		emit_signal("queue_updated", _notification_queue.size())
	
	return notification["id"]


func _can_show_notification(notification: Dictionary) -> bool:
	var position: int = notification["position"]
	var count_at_position: int = 0
	
	for active in _active_notifications:
		if active["position"] == position:
			count_at_position += 1
	
	return count_at_position < MAX_VISIBLE_NOTIFICATIONS


func _show_notification_now(notification: Dictionary) -> void:
	notification["shown"] = true
	notification["timer"] = notification["duration"]
	
	_active_notifications.append(notification)
	_add_to_history(notification)
	
	# Play sound
	if notification["sound"] != "" and has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager.play_sound(notification["sound"])
	
	emit_signal("notification_shown", notification["id"], notification)


func _sort_queue() -> void:
	_notification_queue.sort_custom(func(a, b):
		return a["priority"] > b["priority"]
	)


func _remove_lowest_priority_from_queue() -> void:
	if _notification_queue.is_empty():
		return
	
	var lowest_idx: int = 0
	var lowest_priority: int = _notification_queue[0]["priority"]
	
	for i in range(_notification_queue.size()):
		if _notification_queue[i]["priority"] < lowest_priority:
			lowest_priority = _notification_queue[i]["priority"]
			lowest_idx = i
	
	_notification_queue.remove_at(lowest_idx)


func _process_queue() -> void:
	if _paused:
		return
	
	while not _notification_queue.is_empty():
		var notification: Dictionary = _notification_queue[0]
		
		if _can_show_notification(notification):
			_notification_queue.remove_at(0)
			_show_notification_now(notification)
			emit_signal("queue_updated", _notification_queue.size())
		else:
			break


# ============================================================================
# NOTIFICATION UPDATE
# ============================================================================

func _update_notifications(delta: float) -> void:
	var to_remove: Array = []
	
	for i in range(_active_notifications.size()):
		var notification: Dictionary = _active_notifications[i]
		
		notification["timer"] -= delta
		
		if notification["timer"] <= 0:
			to_remove.append(i)
	
	# Remove expired (in reverse order to maintain indices)
	for i in range(to_remove.size() - 1, -1, -1):
		var idx: int = to_remove[i]
		var notification: Dictionary = _active_notifications[idx]
		_active_notifications.remove_at(idx)
		emit_signal("notification_dismissed", notification["id"])


# ============================================================================
# NOTIFICATION ACTIONS
# ============================================================================

func dismiss_notification(notification_id: String) -> void:
	for i in range(_active_notifications.size()):
		if _active_notifications[i]["id"] == notification_id:
			var notification: Dictionary = _active_notifications[i]
			_active_notifications.remove_at(i)
			emit_signal("notification_dismissed", notification_id)
			return
	
	# Also check queue
	for i in range(_notification_queue.size()):
		if _notification_queue[i]["id"] == notification_id:
			_notification_queue.remove_at(i)
			emit_signal("queue_updated", _notification_queue.size())
			return


func dismiss_all() -> void:
	for notification in _active_notifications:
		emit_signal("notification_dismissed", notification["id"])
	
	_active_notifications.clear()
	_notification_queue.clear()
	emit_signal("queue_updated", 0)


func dismiss_by_type(type: int) -> void:
	var to_remove: Array = []
	
	for i in range(_active_notifications.size()):
		if _active_notifications[i]["type"] == type:
			to_remove.append(i)
	
	for i in range(to_remove.size() - 1, -1, -1):
		var idx: int = to_remove[i]
		var notification: Dictionary = _active_notifications[idx]
		_active_notifications.remove_at(idx)
		emit_signal("notification_dismissed", notification["id"])
	
	# Also from queue
	to_remove.clear()
	for i in range(_notification_queue.size()):
		if _notification_queue[i]["type"] == type:
			to_remove.append(i)
	
	for i in range(to_remove.size() - 1, -1, -1):
		_notification_queue.remove_at(to_remove[i])
	
	emit_signal("queue_updated", _notification_queue.size())


func click_notification(notification_id: String) -> void:
	emit_signal("notification_clicked", notification_id)


func trigger_action(notification_id: String, action_id: String) -> void:
	emit_signal("notification_action", notification_id, action_id)
	dismiss_notification(notification_id)


# ============================================================================
# PROGRESS NOTIFICATIONS
# ============================================================================

func update_progress(notification_id: String, progress: float) -> void:
	for notification in _active_notifications:
		if notification["id"] == notification_id:
			notification["progress"] = clampf(progress, 0.0, 1.0)
			return


func complete_progress(notification_id: String, success: bool = true) -> void:
	for notification in _active_notifications:
		if notification["id"] == notification_id:
			notification["progress"] = 1.0
			notification["color"] = Color.GREEN if success else Color.RED
			notification["timer"] = 2.0  # Show for 2 more seconds
			return


# ============================================================================
# MUTING / DND
# ============================================================================

func mute_type(type: int, muted: bool = true) -> void:
	_muted_types[type] = muted


func is_type_muted(type: int) -> bool:
	return _muted_types.get(type, false)


func set_do_not_disturb(enabled: bool) -> void:
	_do_not_disturb = enabled
	
	if not enabled:
		_process_queue()


func is_do_not_disturb() -> bool:
	return _do_not_disturb


func pause_notifications() -> void:
	_paused = true


func resume_notifications() -> void:
	_paused = false
	_process_queue()


func is_paused() -> bool:
	return _paused


# ============================================================================
# HISTORY
# ============================================================================

func _add_to_history(notification: Dictionary) -> void:
	var history_entry := notification.duplicate()
	history_entry["dismissed_at"] = 0.0
	
	_notification_history.push_front(history_entry)
	
	while _notification_history.size() > MAX_HISTORY_SIZE:
		_notification_history.pop_back()


func get_history(count: int = 20) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(min(count, _notification_history.size())):
		result.append(_notification_history[i])
	return result


func get_history_by_type(type: int, count: int = 20) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for notification in _notification_history:
		if notification["type"] == type:
			result.append(notification)
			if result.size() >= count:
				break
	
	return result


func clear_history() -> void:
	_notification_history.clear()


# ============================================================================
# QUERIES
# ============================================================================

func get_active_notifications() -> Array[Dictionary]:
	return _active_notifications.duplicate()


func get_queued_notifications() -> Array[Dictionary]:
	return _notification_queue.duplicate()


func get_notification(notification_id: String) -> Dictionary:
	for notification in _active_notifications:
		if notification["id"] == notification_id:
			return notification
	return {}


func get_pending_count() -> int:
	return _notification_queue.size()


func has_notifications() -> bool:
	return not _active_notifications.is_empty()


func has_queued() -> bool:
	return not _notification_queue.is_empty()


# ============================================================================
# BATCH NOTIFICATIONS
# ============================================================================

func show_loot_batch(items: Array) -> void:
	# Group similar items
	var grouped: Dictionary = {}
	
	for item in items:
		var item_id: String = item.get("id", "unknown")
		if item_id in grouped:
			grouped[item_id]["quantity"] += item.get("quantity", 1)
		else:
			grouped[item_id] = {
				"name": item.get("name", "Unknown Item"),
				"quantity": item.get("quantity", 1),
				"rarity": item.get("rarity", "common"),
			}
	
	# Show notifications for each unique item
	for item_id in grouped:
		var item: Dictionary = grouped[item_id]
		show_loot(item["name"], item["quantity"], item["rarity"])


func show_damage_numbers(damages: Array) -> void:
	# Aggregate damage numbers that are close together
	var total_damage: int = 0
	var is_any_critical: bool = false
	
	for damage in damages:
		total_damage += damage.get("amount", 0)
		if damage.get("critical", false):
			is_any_critical = true
	
	show_combat_text(str(total_damage), is_any_critical)


func _serialize_notification_entry(notification: Dictionary) -> Dictionary:
	var color_value = notification.get("color", Color.WHITE)
	var color_text := ""
	if color_value is Color:
		color_text = color_value.to_html()

	return {
		"id": notification.get("id", ""),
		"type": notification.get("type", NotificationType.INFO),
		"title": notification.get("title", ""),
		"message": notification.get("message", ""),
		"icon": notification.get("icon", ""),
		"color": color_text,
		"duration": notification.get("duration", 0.0),
		"position": notification.get("position", NotificationPosition.TOP_RIGHT),
		"priority": notification.get("priority", NotificationPriority.NORMAL),
		"actions": notification.get("actions", []),
		"progress": notification.get("progress", -1.0),
		"created_at": notification.get("created_at", 0.0),
		"dismissed_at": notification.get("dismissed_at", 0.0),
	}


func _deserialize_notification_entry(entry: Dictionary) -> Dictionary:
	var notification_type := int(entry.get("type", NotificationType.INFO))
	var type_settings: Dictionary = TYPE_SETTINGS.get(notification_type, TYPE_SETTINGS[NotificationType.INFO])
	var color_text := str(entry.get("color", ""))
	var restored_color: Color = type_settings.get("color", Color.WHITE)
	if not color_text.is_empty():
		restored_color = Color.from_string(color_text, restored_color)

	return {
		"id": str(entry.get("id", "")),
		"type": notification_type,
		"title": str(entry.get("title", "")),
		"message": str(entry.get("message", "")),
		"icon": str(entry.get("icon", type_settings.get("icon", "notification_info"))),
		"color": restored_color,
		"sound": type_settings.get("sound", ""),
		"duration": float(entry.get("duration", type_settings.get("duration", 4.0))),
		"position": int(entry.get("position", type_settings.get("position", NotificationPosition.TOP_RIGHT))),
		"priority": int(entry.get("priority", NotificationPriority.NORMAL)),
		"actions": entry.get("actions", []),
		"progress": float(entry.get("progress", -1.0)),
		"extra": {},
		"timer": 0.0,
		"created_at": float(entry.get("created_at", 0.0)),
		"shown": true,
		"dismissed_at": float(entry.get("dismissed_at", 0.0)),
	}


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var serialized_history: Array = []
	for entry in _notification_history.slice(0, 50):
		serialized_history.append(_serialize_notification_entry(entry))

	return {
		"muted_types": _muted_types.duplicate(),
		"do_not_disturb": _do_not_disturb,
		"history": serialized_history,
	}


func load_data(data: Dictionary) -> void:
	_muted_types = data.get("muted_types", {})
	_do_not_disturb = data.get("do_not_disturb", false)
	
	_notification_history.clear()
	for entry in data.get("history", []):
		_notification_history.append(_deserialize_notification_entry(entry))
