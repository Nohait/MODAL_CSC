extends Node

## DayNightSystem - Complete day/night cycle with weather, lighting, and gameplay effects
## Creates atmospheric world with meaningful survival impact

# ============================================================================
# SIGNALS
# ============================================================================

signal time_changed(hour: int, minute: int)
signal day_changed(day: int)
signal period_changed(period: String)  # dawn, day, dusk, night
signal weather_changed(weather: String)
signal temperature_changed(temp: float)

# ============================================================================
# CONSTANTS
# ============================================================================

enum TimePeriod { DAWN, DAY, DUSK, NIGHT }
enum Weather { CLEAR, CLOUDY, RAIN, STORM, FOG, SNOW }

const MINUTES_PER_GAME_DAY := 24.0 * 60.0  # Full day in game minutes
const REAL_SECONDS_PER_GAME_MINUTE := 1.0  # 1 real second = 1 game minute (24 min real = 1 day)

# Time period boundaries (hours)
const DAWN_START := 5
const DAY_START := 7
const DUSK_START := 18
const NIGHT_START := 20

# Temperature ranges by period (Celsius)
const TEMP_BASE := {
	TimePeriod.DAWN: 12.0,
	TimePeriod.DAY: 22.0,
	TimePeriod.DUSK: 18.0,
	TimePeriod.NIGHT: 8.0
}

# Lighting colors
const AMBIENT_COLORS := {
	TimePeriod.DAWN: Color(0.9, 0.7, 0.6, 1.0),
	TimePeriod.DAY: Color(1.0, 1.0, 1.0, 1.0),
	TimePeriod.DUSK: Color(0.9, 0.5, 0.3, 1.0),
	TimePeriod.NIGHT: Color(0.2, 0.2, 0.4, 1.0)
}

const AMBIENT_ENERGY := {
	TimePeriod.DAWN: 0.6,
	TimePeriod.DAY: 1.0,
	TimePeriod.DUSK: 0.5,
	TimePeriod.NIGHT: 0.15
}

# Weather effects
const WEATHER_DATA := {
	Weather.CLEAR: {
		"name": "Clear",
		"visibility": 1.0,
		"sound_dampen": 1.0,
		"temp_modifier": 0.0,
		"zombie_activity": 1.0
	},
	Weather.CLOUDY: {
		"name": "Cloudy",
		"visibility": 0.9,
		"sound_dampen": 1.0,
		"temp_modifier": -2.0,
		"zombie_activity": 1.1
	},
	Weather.RAIN: {
		"name": "Rain",
		"visibility": 0.6,
		"sound_dampen": 0.7,
		"temp_modifier": -5.0,
		"zombie_activity": 0.8,
		"wetness_rate": 0.5
	},
	Weather.STORM: {
		"name": "Storm",
		"visibility": 0.3,
		"sound_dampen": 0.4,
		"temp_modifier": -8.0,
		"zombie_activity": 0.5,
		"wetness_rate": 1.0,
		"lightning": true
	},
	Weather.FOG: {
		"name": "Fog",
		"visibility": 0.3,
		"sound_dampen": 0.8,
		"temp_modifier": -3.0,
		"zombie_activity": 1.3
	},
	Weather.SNOW: {
		"name": "Snow",
		"visibility": 0.5,
		"sound_dampen": 0.6,
		"temp_modifier": -15.0,
		"zombie_activity": 0.7,
		"cold_rate": 0.8
	}
}

# ============================================================================
# STATE
# ============================================================================

var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0
var total_game_minutes: float = 8 * 60  # Start at 8:00 AM

var current_period: TimePeriod = TimePeriod.DAY
var current_weather: Weather = Weather.CLEAR
var weather_duration: float = 0.0
var next_weather_check: float = 300.0  # Check every 5 minutes

var current_temperature: float = 20.0
var target_temperature: float = 20.0

var time_scale: float = 1.0
var is_paused: bool = false

# Visual references
var canvas_modulate: CanvasModulate = null
var world_environment: WorldEnvironment = null
var rain_particles: GPUParticles2D = null
var snow_particles: GPUParticles2D = null
var fog_overlay: ColorRect = null
var lightning_timer: float = 0.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("day_night_system")
	_find_visual_nodes()
	_update_period()
	_update_lighting()

func _find_visual_nodes() -> void:
	# Try to find existing visual nodes
	canvas_modulate = get_tree().get_first_node_in_group("canvas_modulate") as CanvasModulate
	world_environment = get_tree().get_first_node_in_group("world_environment") as WorldEnvironment
	rain_particles = get_tree().get_first_node_in_group("rain_particles") as GPUParticles2D
	snow_particles = get_tree().get_first_node_in_group("snow_particles") as GPUParticles2D
	fog_overlay = get_tree().get_first_node_in_group("fog_overlay") as ColorRect

# ============================================================================
# MAIN LOOP
# ============================================================================

func _process(delta: float) -> void:
	if is_paused:
		return
	
	var scaled_delta := delta * time_scale
	
	# Advance time
	_advance_time(scaled_delta)
	
	# Update weather
	_update_weather(scaled_delta)
	
	# Update temperature
	_update_temperature(scaled_delta)
	
	# Update visuals
	_update_lighting()
	_update_weather_effects(scaled_delta)

func _advance_time(delta: float) -> void:
	var prev_hour := current_hour
	var prev_day := current_day
	
	# Convert real delta to game minutes
	total_game_minutes += delta / REAL_SECONDS_PER_GAME_MINUTE
	
	# Wrap around days
	while total_game_minutes >= MINUTES_PER_GAME_DAY:
		total_game_minutes -= MINUTES_PER_GAME_DAY
		current_day += 1
		day_changed.emit(current_day)
	
	# Calculate hour and minute
	current_hour = int(total_game_minutes / 60.0)
	current_minute = int(fmod(total_game_minutes, 60.0))
	
	if current_hour != prev_hour:
		time_changed.emit(current_hour, current_minute)
		_update_period()

func _update_period() -> void:
	var prev_period := current_period
	
	if current_hour >= NIGHT_START or current_hour < DAWN_START:
		current_period = TimePeriod.NIGHT
	elif current_hour >= DUSK_START:
		current_period = TimePeriod.DUSK
	elif current_hour >= DAY_START:
		current_period = TimePeriod.DAY
	else:
		current_period = TimePeriod.DAWN
	
	if current_period != prev_period:
		period_changed.emit(get_period_name())
		target_temperature = _calculate_target_temperature()

# ============================================================================
# WEATHER
# ============================================================================

func _update_weather(delta: float) -> void:
	weather_duration -= delta
	next_weather_check -= delta
	
	if next_weather_check <= 0.0:
		next_weather_check = 300.0  # 5 minutes
		_check_weather_change()
	
	if weather_duration <= 0.0 and current_weather != Weather.CLEAR:
		set_weather(Weather.CLEAR)

func _check_weather_change() -> void:
	if current_weather != Weather.CLEAR:
		return
	
	# Random weather chance
	var roll := randf()
	var threshold := 0.15  # 15% chance per check
	
	# Higher chance at night
	if current_period == TimePeriod.NIGHT:
		threshold *= 1.5
	
	if roll < threshold:
		_trigger_random_weather()

func _trigger_random_weather() -> void:
	var weather_options := [Weather.CLOUDY, Weather.RAIN, Weather.FOG]
	
	# Seasonal weather (could tie to game day)
	if current_day > 30:  # "Winter" after day 30
		weather_options.append(Weather.SNOW)
	
	# Rare storm
	if randf() < 0.1:
		weather_options.append(Weather.STORM)
	
	var new_weather: Weather = weather_options.pick_random()
	var duration := randf_range(180.0, 600.0)  # 3-10 minutes
	
	set_weather(new_weather, duration)

func set_weather(weather: Weather, duration: float = -1.0) -> void:
	var prev_weather := current_weather
	current_weather = weather
	
	if duration > 0:
		weather_duration = duration
	elif weather == Weather.CLEAR:
		weather_duration = INF
	else:
		weather_duration = randf_range(180.0, 600.0)
	
	if prev_weather != weather:
		weather_changed.emit(get_weather_name())
		target_temperature = _calculate_target_temperature()
		_update_weather_particles()

func _update_weather_particles() -> void:
	# Toggle rain particles
	if rain_particles:
		rain_particles.emitting = current_weather == Weather.RAIN or current_weather == Weather.STORM
	
	# Toggle snow particles
	if snow_particles:
		snow_particles.emitting = current_weather == Weather.SNOW
	
	# Toggle fog overlay
	if fog_overlay:
		var fog_alpha := 0.0
		if current_weather == Weather.FOG:
			fog_alpha = 0.4
		elif current_weather == Weather.STORM:
			fog_alpha = 0.2
		
		var tween := create_tween()
		tween.tween_property(fog_overlay, "modulate:a", fog_alpha, 2.0)

func _update_weather_effects(delta: float) -> void:
	# Lightning during storms
	if current_weather == Weather.STORM:
		lightning_timer -= delta
		if lightning_timer <= 0.0:
			_trigger_lightning()
			lightning_timer = randf_range(3.0, 15.0)

func _trigger_lightning() -> void:
	# Flash screen
	if canvas_modulate:
		var original_color := canvas_modulate.color
		canvas_modulate.color = Color.WHITE
		
		await get_tree().create_timer(0.1).timeout
		canvas_modulate.color = original_color
	
	# Could play thunder sound here

# ============================================================================
# TEMPERATURE
# ============================================================================

func _calculate_target_temperature() -> float:
	var base_temp: float = TEMP_BASE.get(current_period, 20.0)
	var weather_mod: float = WEATHER_DATA[current_weather].get("temp_modifier", 0.0)
	
	return base_temp + weather_mod

func _update_temperature(delta: float) -> void:
	# Smoothly interpolate temperature
	var temp_change := (target_temperature - current_temperature) * delta * 0.1
	current_temperature += temp_change
	
	# Emit signal if significant change
	if abs(temp_change) > 0.01:
		temperature_changed.emit(current_temperature)

func get_temperature() -> float:
	return current_temperature

func is_cold() -> bool:
	return current_temperature < 5.0

func is_hot() -> bool:
	return current_temperature > 35.0

# ============================================================================
# LIGHTING
# ============================================================================

func _update_lighting() -> void:
	if not canvas_modulate:
		return
	
	# Calculate transition between periods
	var target_color: Color = AMBIENT_COLORS[current_period]
	var target_energy: float = AMBIENT_ENERGY[current_period]
	
	# Smooth transition (handle blending between periods)
	var hour_progress := float(current_minute) / 60.0
	
	# During transition hours, blend between colors
	if current_hour == DAWN_START - 1:  # Transitioning to dawn
		target_color = AMBIENT_COLORS[TimePeriod.NIGHT].lerp(AMBIENT_COLORS[TimePeriod.DAWN], hour_progress)
	elif current_hour == DAY_START - 1:  # Transitioning to day
		target_color = AMBIENT_COLORS[TimePeriod.DAWN].lerp(AMBIENT_COLORS[TimePeriod.DAY], hour_progress)
	elif current_hour == DUSK_START - 1:  # Transitioning to dusk
		target_color = AMBIENT_COLORS[TimePeriod.DAY].lerp(AMBIENT_COLORS[TimePeriod.DUSK], hour_progress)
	elif current_hour == NIGHT_START - 1:  # Transitioning to night
		target_color = AMBIENT_COLORS[TimePeriod.DUSK].lerp(AMBIENT_COLORS[TimePeriod.NIGHT], hour_progress)
	
	# Apply weather darkening
	var weather_visibility: float = WEATHER_DATA[current_weather].get("visibility", 1.0)
	target_color = target_color * weather_visibility
	target_color.a = 1.0
	
	# Smooth lerp to target
	canvas_modulate.color = canvas_modulate.color.lerp(target_color, 0.02)

# ============================================================================
# GAMEPLAY EFFECTS
# ============================================================================

func get_visibility_multiplier() -> float:
	var base: float = AMBIENT_ENERGY[current_period]
	var weather_mod: float = WEATHER_DATA[current_weather].get("visibility", 1.0)
	return base * weather_mod

func get_zombie_activity_multiplier() -> float:
	var base := 1.0
	
	# Night = more zombies
	if current_period == TimePeriod.NIGHT:
		base = 2.0
	elif current_period == TimePeriod.DAWN or current_period == TimePeriod.DUSK:
		base = 1.5
	
	var weather_mod: float = WEATHER_DATA[current_weather].get("zombie_activity", 1.0)
	return base * weather_mod

func get_sound_range_multiplier() -> float:
	return WEATHER_DATA[current_weather].get("sound_dampen", 1.0)

func is_night() -> bool:
	return current_period == TimePeriod.NIGHT

func is_day() -> bool:
	return current_period == TimePeriod.DAY

func should_apply_cold_damage() -> bool:
	return is_cold() and current_weather in [Weather.SNOW, Weather.STORM]

func should_apply_wetness() -> bool:
	return current_weather in [Weather.RAIN, Weather.STORM]

# ============================================================================
# API
# ============================================================================

func set_time(hour: int, minute: int = 0) -> void:
	current_hour = clampi(hour, 0, 23)
	current_minute = clampi(minute, 0, 59)
	total_game_minutes = current_hour * 60.0 + current_minute
	_update_period()
	time_changed.emit(current_hour, current_minute)

func set_day(day: int) -> void:
	current_day = maxi(day, 1)
	day_changed.emit(current_day)

func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

func get_period_name() -> String:
	match current_period:
		TimePeriod.DAWN:
			return "Dawn"
		TimePeriod.DAY:
			return "Day"
		TimePeriod.DUSK:
			return "Dusk"
		TimePeriod.NIGHT:
			return "Night"
	return "Unknown"

func get_weather_name() -> String:
	return WEATHER_DATA[current_weather].get("name", "Unknown")

func get_day() -> int:
	return current_day

func pause() -> void:
	is_paused = true

func resume() -> void:
	is_paused = false

func set_time_scale(scale: float) -> void:
	time_scale = max(scale, 0.1)

# ============================================================================
# SAVE/LOAD
# ============================================================================

func get_save_data() -> Dictionary:
	return {
		"day": current_day,
		"total_minutes": total_game_minutes,
		"weather": current_weather,
		"weather_duration": weather_duration
	}

func load_save_data(data: Dictionary) -> void:
	current_day = data.get("day", 1)
	total_game_minutes = data.get("total_minutes", 8 * 60)
	current_hour = int(total_game_minutes / 60.0)
	current_minute = int(fmod(total_game_minutes, 60.0))
	
	set_weather(data.get("weather", Weather.CLEAR), data.get("weather_duration", -1))
	_update_period()
	_update_lighting()
