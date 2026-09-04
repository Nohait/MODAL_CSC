extends Node
class_name SettingsSystemClass
## Comprehensive settings management for graphics, audio, controls, and gameplay
## Handles persistence, validation, and real-time application of settings

signal settings_changed(category: String)
signal graphics_applied()
signal controls_remapped(action: String, event: InputEvent)
signal language_changed(language: String)

# ============================================================================
# SETTINGS CONFIGURATION
# ============================================================================

enum SettingsCategory {
	GRAPHICS,
	AUDIO,
	CONTROLS,
	GAMEPLAY,
	ACCESSIBILITY,
	NETWORK,
}

enum QualityPreset {
	LOW,
	MEDIUM,
	HIGH,
	ULTRA,
	CUSTOM,
}

enum WindowMode {
	WINDOWED,
	BORDERLESS,
	FULLSCREEN,
	EXCLUSIVE_FULLSCREEN,
}

enum ShadowQuality {
	OFF,
	LOW,
	MEDIUM,
	HIGH,
	ULTRA,
}

enum AntiAliasing {
	DISABLED,
	FXAA,
	MSAA_2X,
	MSAA_4X,
	MSAA_8X,
	TAA,
}

enum VSync {
	DISABLED,
	ENABLED,
	ADAPTIVE,
}

const SETTINGS_FILE := "user://settings.cfg"

const DEFAULT_GRAPHICS := {
	"quality_preset": QualityPreset.HIGH,
	"window_mode": WindowMode.FULLSCREEN,
	"resolution": Vector2i(1920, 1080),
	"vsync": VSync.ENABLED,
	"fps_limit": 0,  # 0 = unlimited
	"brightness": 1.0,
	"gamma": 1.0,
	"contrast": 1.0,
	"fov": 75,
	"shadow_quality": ShadowQuality.HIGH,
	"shadow_distance": 100.0,
	"anti_aliasing": AntiAliasing.TAA,
	"ambient_occlusion": true,
	"bloom": true,
	"motion_blur": false,
	"depth_of_field": true,
	"volumetric_fog": true,
	"ssr": true,  # Screen-space reflections
	"ssao": true,  # Screen-space ambient occlusion
	"texture_quality": 2,  # 0-3
	"mesh_lod_distance": 1.0,
	"grass_density": 1.0,
	"draw_distance": 1.0,
	"particles_quality": 2,  # 0-2
	"render_scale": 1.0,
}

const DEFAULT_AUDIO := {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 1.0,
	"ambient_volume": 0.6,
	"voice_volume": 1.0,
	"ui_volume": 0.8,
	"master_muted": false,
	"music_muted": false,
	"sfx_muted": false,
	"subtitles": true,
	"audio_device": "Default",
	"dynamic_range": 1.0,  # 0=compressed, 1=full
	"dialogue_boost": false,
}

const DEFAULT_GAMEPLAY := {
	"difficulty": 1,  # 0=easy, 1=normal, 2=hard, 3=survival
	"aim_sensitivity_x": 1.0,
	"aim_sensitivity_y": 1.0,
	"invert_y": false,
	"invert_x": false,
	"auto_aim": false,
	"aim_assist": true,
	"toggle_sprint": false,
	"toggle_crouch": true,
	"toggle_aim": false,
	"auto_pickup": true,
	"pickup_filter": [],  # Item types to auto-pickup
	"show_damage_numbers": true,
	"show_health_bars": true,
	"camera_shake": 1.0,
	"hit_markers": true,
	"crosshair_style": 0,
	"crosshair_color": Color.WHITE,
	"hud_scale": 1.0,
	"minimap_zoom": 1.0,
	"minimap_rotate": true,
	"confirm_drops": true,
	"auto_sort_inventory": false,
	"tutorial_hints": true,
	"blood_effects": true,
	"mature_content": true,
}

const DEFAULT_ACCESSIBILITY := {
	"colorblind_mode": 0,  # 0=off, 1=protanopia, 2=deuteranopia, 3=tritanopia
	"colorblind_intensity": 1.0,
	"screen_shake_reduction": 0.0,
	"flash_reduction": false,
	"high_contrast_ui": false,
	"large_text": false,
	"text_scale": 1.0,
	"closed_captions": false,
	"audio_cues": false,
	"hold_to_interact": false,
	"interact_hold_time": 0.5,
	"one_hand_mode": false,
	"dyslexia_friendly_font": false,
	"reduce_motion": false,
	"auto_sprint": false,
}

const DEFAULT_NETWORK := {
	"player_name": "Survivor",
	"show_ping": true,
	"network_quality": 1,  # 0=low bandwidth, 1=normal, 2=high
	"voice_chat": true,
	"voice_chat_volume": 1.0,
	"push_to_talk": true,
	"voice_activation_threshold": 0.1,
	"text_chat": true,
	"show_player_names": true,
	"allow_friend_requests": true,
	"allow_invites": true,
	"privacy_mode": 0,  # 0=public, 1=friends, 2=private
}

const DEFAULT_CONTROLS := {
	# Key bindings stored as action -> [InputEvent]
}

const DEFAULT_INPUT_ACTIONS := {
	"move_forward": [KEY_W],
	"move_back": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"jump": [KEY_SPACE],
	"sprint": [KEY_SHIFT],
	"crouch": [KEY_CTRL],
	"prone": [KEY_Z],
	"interact": [KEY_E],
	"reload": [KEY_R],
	"primary_fire": [MOUSE_BUTTON_LEFT],
	"secondary_fire": [MOUSE_BUTTON_RIGHT],
	"melee": [KEY_V],
	"throw_grenade": [KEY_G],
	"switch_weapon": [KEY_Q],
	"weapon_1": [KEY_1],
	"weapon_2": [KEY_2],
	"weapon_3": [KEY_3],
	"weapon_4": [KEY_4],
	"inventory": [KEY_TAB],
	"map": [KEY_M],
	"crafting": [KEY_C],
	"quest_log": [KEY_J],
	"character": [KEY_P],
	"pause": [KEY_ESCAPE],
	"quick_slot_1": [KEY_F1],
	"quick_slot_2": [KEY_F2],
	"quick_slot_3": [KEY_F3],
	"quick_slot_4": [KEY_F4],
	"flashlight": [KEY_F],
	"ping": [MOUSE_BUTTON_MIDDLE],
	"voice_chat": [KEY_T],
	"text_chat": [KEY_ENTER],
	"zoom_in": [MOUSE_BUTTON_WHEEL_UP],
	"zoom_out": [MOUSE_BUTTON_WHEEL_DOWN],
}


# ============================================================================
# STATE
# ============================================================================

var graphics: Dictionary = {}
var audio: Dictionary = {}
var gameplay: Dictionary = {}
var accessibility: Dictionary = {}
var network: Dictionary = {}
var controls: Dictionary = {}

var _available_resolutions: Array[Vector2i] = []
var _pending_changes: Dictionary = {}
var _is_applying: bool = false


func _ready() -> void:
	_detect_available_resolutions()
	load_settings()
	apply_all_settings()


# ============================================================================
# INITIALIZATION
# ============================================================================

func _detect_available_resolutions() -> void:
	_available_resolutions.clear()
	
	# Common resolutions
	var common := [
		Vector2i(1280, 720),
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3840, 2160),
	]
	
	var screen_size := DisplayServer.screen_get_size()
	
	for res in common:
		if res.x <= screen_size.x and res.y <= screen_size.y:
			_available_resolutions.append(res)
	
	# Add native resolution if not in list
	if screen_size not in _available_resolutions:
		_available_resolutions.append(screen_size)
	
	_available_resolutions.sort_custom(func(a, b): return a.x * a.y < b.x * b.y)


func get_available_resolutions() -> Array[Vector2i]:
	return _available_resolutions.duplicate()


# ============================================================================
# SAVE / LOAD
# ============================================================================

func save_settings() -> void:
	var config := ConfigFile.new()
	
	# Graphics
	for key in graphics:
		var value = graphics[key]
		if value is Vector2i:
			config.set_value("graphics", key, {"x": value.x, "y": value.y})
		elif value is Color:
			config.set_value("graphics", key, {"r": value.r, "g": value.g, "b": value.b, "a": value.a})
		else:
			config.set_value("graphics", key, value)
	
	# Audio
	for key in audio:
		config.set_value("audio", key, audio[key])
	
	# Gameplay
	for key in gameplay:
		var value = gameplay[key]
		if value is Color:
			config.set_value("gameplay", key, {"r": value.r, "g": value.g, "b": value.b, "a": value.a})
		else:
			config.set_value("gameplay", key, value)
	
	# Accessibility
	for key in accessibility:
		config.set_value("accessibility", key, accessibility[key])
	
	# Network
	for key in network:
		config.set_value("network", key, network[key])
	
	# Controls
	for action in controls:
		var events: Array = []
		for event in controls[action]:
			events.append(_serialize_input_event(event))
		config.set_value("controls", action, events)
	
	var error := config.save(SETTINGS_FILE)
	if error != OK:
		push_error("SettingsSystem: Failed to save settings: " + str(error))


func load_settings() -> void:
	# Start with defaults
	graphics = DEFAULT_GRAPHICS.duplicate(true)
	audio = DEFAULT_AUDIO.duplicate(true)
	gameplay = DEFAULT_GAMEPLAY.duplicate(true)
	accessibility = DEFAULT_ACCESSIBILITY.duplicate(true)
	network = DEFAULT_NETWORK.duplicate(true)
	controls = {}
	
	_setup_default_controls()
	
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_FILE)
	
	if error != OK:
		# No settings file, use defaults
		save_settings()
		return
	
	# Graphics
	for key in config.get_section_keys("graphics"):
		if key in graphics:
			var value = config.get_value("graphics", key)
			if value is Dictionary and "x" in value and "y" in value:
				graphics[key] = Vector2i(value["x"], value["y"])
			elif value is Dictionary and "r" in value:
				graphics[key] = Color(value["r"], value["g"], value["b"], value.get("a", 1.0))
			else:
				graphics[key] = value
	
	# Audio
	for key in config.get_section_keys("audio"):
		if key in audio:
			audio[key] = config.get_value("audio", key)
	
	# Gameplay
	for key in config.get_section_keys("gameplay"):
		if key in gameplay:
			var value = config.get_value("gameplay", key)
			if value is Dictionary and "r" in value:
				gameplay[key] = Color(value["r"], value["g"], value["b"], value.get("a", 1.0))
			else:
				gameplay[key] = value
	
	# Accessibility
	for key in config.get_section_keys("accessibility"):
		if key in accessibility:
			accessibility[key] = config.get_value("accessibility", key)
	
	# Network
	for key in config.get_section_keys("network"):
		if key in network:
			network[key] = config.get_value("network", key)
	
	# Controls
	if config.has_section("controls"):
		for action in config.get_section_keys("controls"):
			var events_data: Array = config.get_value("controls", action, [])
			controls[action] = []
			for event_data in events_data:
				var event := _deserialize_input_event(event_data)
				if event:
					controls[action].append(event)


func _setup_default_controls() -> void:
	for action in DEFAULT_INPUT_ACTIONS:
		controls[action] = []
		for key_or_button in DEFAULT_INPUT_ACTIONS[action]:
			var event: InputEvent
			if key_or_button is int:
				if key_or_button >= MOUSE_BUTTON_LEFT and key_or_button <= MOUSE_BUTTON_WHEEL_DOWN:
					event = InputEventMouseButton.new()
					event.button_index = key_or_button
				else:
					event = InputEventKey.new()
					event.physical_keycode = key_or_button
			controls[action].append(event)


func _serialize_input_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"keycode": event.physical_keycode,
			"shift": event.shift_pressed,
			"ctrl": event.ctrl_pressed,
			"alt": event.alt_pressed,
		}
	elif event is InputEventMouseButton:
		return {
			"type": "mouse",
			"button": event.button_index,
		}
	elif event is InputEventJoypadButton:
		return {
			"type": "joypad_button",
			"button": event.button_index,
		}
	elif event is InputEventJoypadMotion:
		return {
			"type": "joypad_axis",
			"axis": event.axis,
			"value": event.axis_value,
		}
	return {}


func _deserialize_input_event(data: Dictionary) -> InputEvent:
	match data.get("type", ""):
		"key":
			var event := InputEventKey.new()
			event.physical_keycode = data.get("keycode", 0)
			event.shift_pressed = data.get("shift", false)
			event.ctrl_pressed = data.get("ctrl", false)
			event.alt_pressed = data.get("alt", false)
			return event
		"mouse":
			var event := InputEventMouseButton.new()
			event.button_index = data.get("button", 0)
			return event
		"joypad_button":
			var event := InputEventJoypadButton.new()
			event.button_index = data.get("button", 0)
			return event
		"joypad_axis":
			var event := InputEventJoypadMotion.new()
			event.axis = data.get("axis", 0)
			event.axis_value = data.get("value", 0.0)
			return event
	return null


# ============================================================================
# RESET
# ============================================================================

func reset_to_defaults(category: int = -1) -> void:
	match category:
		SettingsCategory.GRAPHICS:
			graphics = DEFAULT_GRAPHICS.duplicate(true)
		SettingsCategory.AUDIO:
			audio = DEFAULT_AUDIO.duplicate(true)
		SettingsCategory.CONTROLS:
			controls.clear()
			_setup_default_controls()
		SettingsCategory.GAMEPLAY:
			gameplay = DEFAULT_GAMEPLAY.duplicate(true)
		SettingsCategory.ACCESSIBILITY:
			accessibility = DEFAULT_ACCESSIBILITY.duplicate(true)
		SettingsCategory.NETWORK:
			network = DEFAULT_NETWORK.duplicate(true)
		_:
			# Reset all
			graphics = DEFAULT_GRAPHICS.duplicate(true)
			audio = DEFAULT_AUDIO.duplicate(true)
			gameplay = DEFAULT_GAMEPLAY.duplicate(true)
			accessibility = DEFAULT_ACCESSIBILITY.duplicate(true)
			network = DEFAULT_NETWORK.duplicate(true)
			controls.clear()
			_setup_default_controls()
	
	save_settings()
	apply_all_settings()


# ============================================================================
# APPLY SETTINGS
# ============================================================================

func apply_all_settings() -> void:
	apply_graphics_settings()
	apply_audio_settings()
	apply_control_settings()
	apply_accessibility_settings()


func apply_graphics_settings() -> void:
	_is_applying = true
	
	# Window mode
	match graphics["window_mode"]:
		WindowMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen_size := DisplayServer.screen_get_size()
			DisplayServer.window_set_size(screen_size)
			DisplayServer.window_set_position(Vector2i.ZERO)
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	# Resolution (only for windowed)
	if graphics["window_mode"] == WindowMode.WINDOWED:
		var res: Vector2i = graphics["resolution"]
		DisplayServer.window_set_size(res)
		# Center window
		var screen_size := DisplayServer.screen_get_size()
		var pos := (screen_size - res) / 2
		DisplayServer.window_set_position(pos)
	
	# VSync
	match graphics["vsync"]:
		VSync.DISABLED:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		VSync.ENABLED:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		VSync.ADAPTIVE:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	
	# FPS limit
	if graphics["fps_limit"] > 0:
		Engine.max_fps = graphics["fps_limit"]
	else:
		Engine.max_fps = 0
	
	# These would need RenderingServer or Environment adjustments
	# For now, store values to be read by other systems
	
	_is_applying = false
	emit_signal("graphics_applied")
	emit_signal("settings_changed", "graphics")


func apply_audio_settings() -> void:
	# Apply volumes via AudioManager if available
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager.set_bus_volume(0, audio["master_volume"])
		audio_manager.set_bus_volume(1, audio["music_volume"])
		audio_manager.set_bus_volume(2, audio["sfx_volume"])
		audio_manager.set_bus_volume(3, audio["ambient_volume"])
		audio_manager.set_bus_volume(5, audio["voice_volume"])
		audio_manager.set_bus_volume(4, audio["ui_volume"])
		
		audio_manager.set_bus_muted(0, audio["master_muted"])
		audio_manager.set_bus_muted(1, audio["music_muted"])
		audio_manager.set_bus_muted(2, audio["sfx_muted"])
	else:
		# Direct audio bus control
		for i in range(AudioServer.bus_count):
			var bus_name := AudioServer.get_bus_name(i)
			var volume: float = 1.0
			var muted: bool = false
			
			match bus_name.to_lower():
				"master":
					volume = audio["master_volume"]
					muted = audio["master_muted"]
				"music":
					volume = audio["music_volume"]
					muted = audio["music_muted"]
				"sfx":
					volume = audio["sfx_volume"]
					muted = audio["sfx_muted"]
				"ambient":
					volume = audio["ambient_volume"]
				"voice":
					volume = audio["voice_volume"]
				"ui":
					volume = audio["ui_volume"]
			
			AudioServer.set_bus_volume_db(i, linear_to_db(volume))
			AudioServer.set_bus_mute(i, muted)
	
	emit_signal("settings_changed", "audio")


func apply_control_settings() -> void:
	# Clear existing input map actions and remap
	for action in controls:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
		
		for event in controls[action]:
			InputMap.action_add_event(action, event)
	
	emit_signal("settings_changed", "controls")


func apply_accessibility_settings() -> void:
	# Apply accessibility features
	# These would interface with shader uniforms, UI scaling, etc.
	
	emit_signal("settings_changed", "accessibility")


# ============================================================================
# CONTROL REMAPPING
# ============================================================================

func remap_action(action: String, event: InputEvent, slot: int = 0) -> Dictionary:
	if action not in controls:
		return {"success": false, "error": "Unknown action"}
	
	# Check for conflicts
	var conflict := get_action_conflict(event)
	if conflict != "" and conflict != action:
		return {"success": false, "error": "Conflicts with: " + conflict, "conflict": conflict}
	
	# Ensure array is large enough
	while controls[action].size() <= slot:
		controls[action].append(null)
	
	controls[action][slot] = event
	
	# Apply immediately
	apply_control_settings()
	save_settings()
	
	emit_signal("controls_remapped", action, event)
	
	return {"success": true}


func get_action_conflict(event: InputEvent) -> String:
	for action in controls:
		for existing_event in controls[action]:
			if existing_event and _events_match(event, existing_event):
				return action
	return ""


func _events_match(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	elif a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	elif a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	return false


func get_action_events(action: String) -> Array:
	return controls.get(action, [])


func get_action_display_name(action: String) -> String:
	var events: Array = controls.get(action, [])
	if events.is_empty():
		return "Unbound"
	
	var event: InputEvent = events[0]
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
			_: return "Mouse " + str(event.button_index)
	elif event is InputEventJoypadButton:
		return "Pad " + str(event.button_index)
	
	return "Unknown"


# ============================================================================
# QUALITY PRESETS
# ============================================================================

func apply_quality_preset(preset: int) -> void:
	graphics["quality_preset"] = preset
	
	match preset:
		QualityPreset.LOW:
			graphics["shadow_quality"] = ShadowQuality.LOW
			graphics["shadow_distance"] = 30.0
			graphics["anti_aliasing"] = AntiAliasing.FXAA
			graphics["ambient_occlusion"] = false
			graphics["bloom"] = false
			graphics["motion_blur"] = false
			graphics["depth_of_field"] = false
			graphics["volumetric_fog"] = false
			graphics["ssr"] = false
			graphics["ssao"] = false
			graphics["texture_quality"] = 0
			graphics["mesh_lod_distance"] = 0.5
			graphics["grass_density"] = 0.25
			graphics["draw_distance"] = 0.5
			graphics["particles_quality"] = 0
			graphics["render_scale"] = 0.75
		
		QualityPreset.MEDIUM:
			graphics["shadow_quality"] = ShadowQuality.MEDIUM
			graphics["shadow_distance"] = 60.0
			graphics["anti_aliasing"] = AntiAliasing.FXAA
			graphics["ambient_occlusion"] = true
			graphics["bloom"] = true
			graphics["motion_blur"] = false
			graphics["depth_of_field"] = false
			graphics["volumetric_fog"] = false
			graphics["ssr"] = false
			graphics["ssao"] = true
			graphics["texture_quality"] = 1
			graphics["mesh_lod_distance"] = 0.75
			graphics["grass_density"] = 0.5
			graphics["draw_distance"] = 0.75
			graphics["particles_quality"] = 1
			graphics["render_scale"] = 1.0
		
		QualityPreset.HIGH:
			graphics["shadow_quality"] = ShadowQuality.HIGH
			graphics["shadow_distance"] = 100.0
			graphics["anti_aliasing"] = AntiAliasing.TAA
			graphics["ambient_occlusion"] = true
			graphics["bloom"] = true
			graphics["motion_blur"] = false
			graphics["depth_of_field"] = true
			graphics["volumetric_fog"] = true
			graphics["ssr"] = true
			graphics["ssao"] = true
			graphics["texture_quality"] = 2
			graphics["mesh_lod_distance"] = 1.0
			graphics["grass_density"] = 0.75
			graphics["draw_distance"] = 1.0
			graphics["particles_quality"] = 2
			graphics["render_scale"] = 1.0
		
		QualityPreset.ULTRA:
			graphics["shadow_quality"] = ShadowQuality.ULTRA
			graphics["shadow_distance"] = 150.0
			graphics["anti_aliasing"] = AntiAliasing.MSAA_4X
			graphics["ambient_occlusion"] = true
			graphics["bloom"] = true
			graphics["motion_blur"] = true
			graphics["depth_of_field"] = true
			graphics["volumetric_fog"] = true
			graphics["ssr"] = true
			graphics["ssao"] = true
			graphics["texture_quality"] = 3
			graphics["mesh_lod_distance"] = 1.5
			graphics["grass_density"] = 1.0
			graphics["draw_distance"] = 1.5
			graphics["particles_quality"] = 2
			graphics["render_scale"] = 1.0
	
	apply_graphics_settings()
	save_settings()


# ============================================================================
# GETTERS / SETTERS
# ============================================================================

func set_setting(category: int, key: String, value) -> void:
	match category:
		SettingsCategory.GRAPHICS:
			if key in graphics:
				graphics[key] = value
				graphics["quality_preset"] = QualityPreset.CUSTOM
		SettingsCategory.AUDIO:
			if key in audio:
				audio[key] = value
		SettingsCategory.GAMEPLAY:
			if key in gameplay:
				gameplay[key] = value
		SettingsCategory.ACCESSIBILITY:
			if key in accessibility:
				accessibility[key] = value
		SettingsCategory.NETWORK:
			if key in network:
				network[key] = value
	
	save_settings()


func get_setting(category: int, key: String):
	match category:
		SettingsCategory.GRAPHICS:
			return graphics.get(key)
		SettingsCategory.AUDIO:
			return audio.get(key)
		SettingsCategory.GAMEPLAY:
			return gameplay.get(key)
		SettingsCategory.ACCESSIBILITY:
			return accessibility.get(key)
		SettingsCategory.NETWORK:
			return network.get(key)
	return null


# ============================================================================
# CONVENIENCE GETTERS
# ============================================================================

func get_difficulty() -> int:
	return gameplay["difficulty"]


func get_sensitivity() -> Vector2:
	return Vector2(gameplay["aim_sensitivity_x"], gameplay["aim_sensitivity_y"])


func is_invert_y() -> bool:
	return gameplay["invert_y"]


func is_subtitles_enabled() -> bool:
	return audio["subtitles"]


func get_hud_scale() -> float:
	return gameplay["hud_scale"]


func get_text_scale() -> float:
	return accessibility["text_scale"]


func is_tutorial_enabled() -> bool:
	return gameplay["tutorial_hints"]


func get_player_name() -> String:
	return network["player_name"]


func set_player_name(name: String) -> void:
	network["player_name"] = name
	save_settings()
