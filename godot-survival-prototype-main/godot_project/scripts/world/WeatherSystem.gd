extends Node
class_name WeatherSystemClass
## Dynamic weather and environmental effects system
## Controls weather patterns, visual effects, and gameplay modifiers

signal weather_changed(old_weather: WeatherType, new_weather: WeatherType)
signal weather_intensity_changed(intensity: float)
signal temperature_changed(old_temp: float, new_temp: float)
signal environmental_hazard_started(hazard_type: String, position: Vector2)
signal environmental_hazard_ended(hazard_type: String)

# ============================================================================
# WEATHER TYPES
# ============================================================================

enum WeatherType {
	CLEAR,
	CLOUDY,
	OVERCAST,
	FOG,
	LIGHT_RAIN,
	HEAVY_RAIN,
	THUNDERSTORM,
	SNOW,
	BLIZZARD,
	SANDSTORM,
	ACID_RAIN,
	RADIATION_STORM,
}

enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER,
}

const WEATHER_CONFIGS := {
	WeatherType.CLEAR: {
		"name": "Clear",
		"ambient_light": Color(1.0, 1.0, 0.95),
		"ambient_light_energy": 1.0,
		"fog_density": 0.0,
		"visibility_range": 1000,
		"movement_modifier": 1.0,
		"stamina_modifier": 1.0,
		"sound_ambient": "ambient_day",
		"particle_effect": null,
		"temperature_modifier": 0,
	},
	WeatherType.CLOUDY: {
		"name": "Cloudy",
		"ambient_light": Color(0.85, 0.85, 0.9),
		"ambient_light_energy": 0.8,
		"fog_density": 0.05,
		"visibility_range": 800,
		"movement_modifier": 1.0,
		"stamina_modifier": 1.0,
		"sound_ambient": "ambient_cloudy",
		"particle_effect": null,
		"temperature_modifier": -2,
	},
	WeatherType.OVERCAST: {
		"name": "Overcast",
		"ambient_light": Color(0.7, 0.7, 0.75),
		"ambient_light_energy": 0.6,
		"fog_density": 0.1,
		"visibility_range": 600,
		"movement_modifier": 1.0,
		"stamina_modifier": 1.0,
		"sound_ambient": "ambient_overcast",
		"particle_effect": null,
		"temperature_modifier": -5,
	},
	WeatherType.FOG: {
		"name": "Fog",
		"ambient_light": Color(0.8, 0.8, 0.85),
		"ambient_light_energy": 0.5,
		"fog_density": 0.4,
		"visibility_range": 200,
		"movement_modifier": 0.95,
		"stamina_modifier": 1.0,
		"sound_ambient": "ambient_fog",
		"particle_effect": "fog",
		"temperature_modifier": -3,
		"enemy_detection_modifier": 0.5,  # Enemies spot player at half distance
	},
	WeatherType.LIGHT_RAIN: {
		"name": "Light Rain",
		"ambient_light": Color(0.75, 0.75, 0.8),
		"ambient_light_energy": 0.65,
		"fog_density": 0.1,
		"visibility_range": 500,
		"movement_modifier": 0.95,
		"stamina_modifier": 1.05,
		"sound_ambient": "rain_light",
		"particle_effect": "rain_light",
		"temperature_modifier": -8,
		"wetness_rate": 0.1,
	},
	WeatherType.HEAVY_RAIN: {
		"name": "Heavy Rain",
		"ambient_light": Color(0.5, 0.5, 0.6),
		"ambient_light_energy": 0.4,
		"fog_density": 0.2,
		"visibility_range": 300,
		"movement_modifier": 0.85,
		"stamina_modifier": 1.15,
		"sound_ambient": "rain_heavy",
		"particle_effect": "rain_heavy",
		"temperature_modifier": -12,
		"wetness_rate": 0.25,
		"fire_extinguish_chance": 0.3,
	},
	WeatherType.THUNDERSTORM: {
		"name": "Thunderstorm",
		"ambient_light": Color(0.4, 0.4, 0.5),
		"ambient_light_energy": 0.3,
		"fog_density": 0.25,
		"visibility_range": 250,
		"movement_modifier": 0.8,
		"stamina_modifier": 1.2,
		"sound_ambient": "thunderstorm",
		"particle_effect": "rain_heavy",
		"temperature_modifier": -15,
		"wetness_rate": 0.4,
		"lightning_chance": 0.1,
		"fire_extinguish_chance": 0.5,
	},
	WeatherType.SNOW: {
		"name": "Snow",
		"ambient_light": Color(0.9, 0.92, 1.0),
		"ambient_light_energy": 0.7,
		"fog_density": 0.15,
		"visibility_range": 400,
		"movement_modifier": 0.9,
		"stamina_modifier": 1.1,
		"sound_ambient": "snow_ambient",
		"particle_effect": "snow",
		"temperature_modifier": -20,
		"cold_damage_rate": 0.5,
	},
	WeatherType.BLIZZARD: {
		"name": "Blizzard",
		"ambient_light": Color(0.85, 0.87, 0.95),
		"ambient_light_energy": 0.4,
		"fog_density": 0.5,
		"visibility_range": 100,
		"movement_modifier": 0.6,
		"stamina_modifier": 1.4,
		"sound_ambient": "blizzard",
		"particle_effect": "blizzard",
		"temperature_modifier": -35,
		"cold_damage_rate": 2.0,
		"enemy_detection_modifier": 0.3,
	},
	WeatherType.SANDSTORM: {
		"name": "Sandstorm",
		"ambient_light": Color(0.85, 0.7, 0.5),
		"ambient_light_energy": 0.5,
		"fog_density": 0.6,
		"visibility_range": 80,
		"movement_modifier": 0.7,
		"stamina_modifier": 1.3,
		"sound_ambient": "sandstorm",
		"particle_effect": "sandstorm",
		"temperature_modifier": 10,
		"damage_rate": 0.5,
		"enemy_detection_modifier": 0.25,
	},
	WeatherType.ACID_RAIN: {
		"name": "Acid Rain",
		"ambient_light": Color(0.6, 0.7, 0.5),
		"ambient_light_energy": 0.5,
		"fog_density": 0.15,
		"visibility_range": 350,
		"movement_modifier": 0.9,
		"stamina_modifier": 1.1,
		"sound_ambient": "rain_acid",
		"particle_effect": "acid_rain",
		"temperature_modifier": -5,
		"damage_rate": 1.0,
		"armor_degrade_rate": 0.1,
		"requires_shelter": true,
	},
	WeatherType.RADIATION_STORM: {
		"name": "Radiation Storm",
		"ambient_light": Color(0.5, 0.6, 0.4),
		"ambient_light_energy": 0.4,
		"fog_density": 0.3,
		"visibility_range": 200,
		"movement_modifier": 0.85,
		"stamina_modifier": 1.2,
		"sound_ambient": "radiation_storm",
		"particle_effect": "radiation",
		"temperature_modifier": 5,
		"radiation_rate": 2.0,
		"requires_shelter": true,
		"hazmat_protection": true,
	},
}

# Weather transition probabilities by current weather
const WEATHER_TRANSITIONS := {
	WeatherType.CLEAR: {
		WeatherType.CLEAR: 0.6,
		WeatherType.CLOUDY: 0.3,
		WeatherType.FOG: 0.1,
	},
	WeatherType.CLOUDY: {
		WeatherType.CLEAR: 0.3,
		WeatherType.CLOUDY: 0.3,
		WeatherType.OVERCAST: 0.25,
		WeatherType.LIGHT_RAIN: 0.15,
	},
	WeatherType.OVERCAST: {
		WeatherType.CLOUDY: 0.2,
		WeatherType.OVERCAST: 0.3,
		WeatherType.LIGHT_RAIN: 0.3,
		WeatherType.HEAVY_RAIN: 0.15,
		WeatherType.FOG: 0.05,
	},
	WeatherType.FOG: {
		WeatherType.CLEAR: 0.3,
		WeatherType.CLOUDY: 0.3,
		WeatherType.FOG: 0.3,
		WeatherType.LIGHT_RAIN: 0.1,
	},
	WeatherType.LIGHT_RAIN: {
		WeatherType.CLOUDY: 0.2,
		WeatherType.OVERCAST: 0.2,
		WeatherType.LIGHT_RAIN: 0.3,
		WeatherType.HEAVY_RAIN: 0.25,
		WeatherType.CLEAR: 0.05,
	},
	WeatherType.HEAVY_RAIN: {
		WeatherType.LIGHT_RAIN: 0.3,
		WeatherType.HEAVY_RAIN: 0.3,
		WeatherType.THUNDERSTORM: 0.3,
		WeatherType.OVERCAST: 0.1,
	},
	WeatherType.THUNDERSTORM: {
		WeatherType.HEAVY_RAIN: 0.4,
		WeatherType.THUNDERSTORM: 0.3,
		WeatherType.OVERCAST: 0.2,
		WeatherType.LIGHT_RAIN: 0.1,
	},
	WeatherType.SNOW: {
		WeatherType.SNOW: 0.5,
		WeatherType.BLIZZARD: 0.2,
		WeatherType.CLOUDY: 0.2,
		WeatherType.CLEAR: 0.1,
	},
	WeatherType.BLIZZARD: {
		WeatherType.SNOW: 0.5,
		WeatherType.BLIZZARD: 0.3,
		WeatherType.OVERCAST: 0.2,
	},
	WeatherType.SANDSTORM: {
		WeatherType.SANDSTORM: 0.4,
		WeatherType.CLEAR: 0.4,
		WeatherType.CLOUDY: 0.2,
	},
	WeatherType.ACID_RAIN: {
		WeatherType.ACID_RAIN: 0.3,
		WeatherType.HEAVY_RAIN: 0.3,
		WeatherType.OVERCAST: 0.3,
		WeatherType.CLEAR: 0.1,
	},
	WeatherType.RADIATION_STORM: {
		WeatherType.RADIATION_STORM: 0.4,
		WeatherType.OVERCAST: 0.3,
		WeatherType.CLEAR: 0.2,
		WeatherType.FOG: 0.1,
	},
}


# ============================================================================
# STATE
# ============================================================================

var current_weather: WeatherType = WeatherType.CLEAR
var weather_intensity: float = 1.0  # 0.0 - 1.0
var current_temperature: float = 20.0  # Celsius
var current_season: Season = Season.SUMMER

# Timers
var weather_duration: float = 0.0
var weather_timer: float = 0.0
var next_weather_check: float = 0.0
const WEATHER_CHECK_INTERVAL := 300.0  # 5 minutes

# Zone-specific modifiers
var zone_base_temperature: float = 20.0
var zone_weather_bias: Dictionary = {}

# Hazard tracking
var active_hazards: Array[Dictionary] = []

# Visual effect references
var _rain_particles: GPUParticles2D
var _snow_particles: GPUParticles2D
var _fog_overlay: ColorRect
var _lightning_timer: float = 0.0

# RNG
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	
	# Set initial weather duration
	weather_duration = _rng.randf_range(180.0, 600.0)
	
	_setup_visual_effects()


func _process(delta: float) -> void:
	weather_timer += delta
	
	# Check for weather change
	if weather_timer >= weather_duration:
		_transition_weather()
		weather_timer = 0.0
	
	# Update weather effects
	_update_weather_effects(delta)
	
	# Lightning during thunderstorms
	if current_weather == WeatherType.THUNDERSTORM:
		_update_lightning(delta)
	
	# Apply environmental damage
	_apply_environmental_damage(delta)


# ============================================================================
# WEATHER TRANSITIONS
# ============================================================================

func _transition_weather() -> void:
	var old_weather := current_weather
	var new_weather := _select_next_weather()
	
	if new_weather != old_weather:
		current_weather = new_weather
		weather_intensity = _rng.randf_range(0.5, 1.0)
		weather_duration = _rng.randf_range(180.0, 600.0)
		
		_apply_weather_visuals()
		emit_signal("weather_changed", old_weather, new_weather)
		
		# Update temperature
		var old_temp := current_temperature
		_update_temperature()
		if abs(current_temperature - old_temp) > 1.0:
			emit_signal("temperature_changed", old_temp, current_temperature)


func _select_next_weather() -> WeatherType:
	var transitions: Dictionary = WEATHER_TRANSITIONS.get(current_weather, {})
	
	# Apply zone bias
	for weather_type in zone_weather_bias:
		if weather_type in transitions:
			transitions[weather_type] *= zone_weather_bias[weather_type]
	
	# Apply season modifiers
	transitions = _apply_season_modifiers(transitions)
	
	# Normalize probabilities
	var total := 0.0
	for prob in transitions.values():
		total += prob
	
	if total == 0:
		return WeatherType.CLEAR
	
	# Random selection
	var roll := _rng.randf() * total
	var cumulative := 0.0
	
	for weather_type in transitions:
		cumulative += transitions[weather_type]
		if roll <= cumulative:
			return weather_type
	
	return current_weather


func _apply_season_modifiers(transitions: Dictionary) -> Dictionary:
	var modified := transitions.duplicate()
	
	match current_season:
		Season.WINTER:
			if WeatherType.SNOW in modified:
				modified[WeatherType.SNOW] *= 3.0
			if WeatherType.BLIZZARD in modified:
				modified[WeatherType.BLIZZARD] *= 2.0
			if WeatherType.CLEAR in modified:
				modified[WeatherType.CLEAR] *= 0.5
		Season.SUMMER:
			if WeatherType.CLEAR in modified:
				modified[WeatherType.CLEAR] *= 2.0
			if WeatherType.SANDSTORM in modified:
				modified[WeatherType.SANDSTORM] *= 1.5
			if WeatherType.SNOW in modified:
				modified[WeatherType.SNOW] *= 0.0
		Season.SPRING:
			if WeatherType.LIGHT_RAIN in modified:
				modified[WeatherType.LIGHT_RAIN] *= 1.5
			if WeatherType.FOG in modified:
				modified[WeatherType.FOG] *= 1.3
		Season.AUTUMN:
			if WeatherType.OVERCAST in modified:
				modified[WeatherType.OVERCAST] *= 1.5
			if WeatherType.FOG in modified:
				modified[WeatherType.FOG] *= 1.5
	
	return modified


# ============================================================================
# TEMPERATURE
# ============================================================================

func _update_temperature() -> void:
	var base_temp := zone_base_temperature
	
	# Season modifier
	match current_season:
		Season.WINTER:
			base_temp -= 20
		Season.SUMMER:
			base_temp += 10
		Season.SPRING:
			base_temp += 0
		Season.AUTUMN:
			base_temp -= 5
	
	# Time of day modifier (assuming DayNightSystem exists)
	var time_modifier := 0.0
	var day_night_system := get_tree().get_first_node_in_group("day_night_system")
	if day_night_system and day_night_system.has_method("get_current_hour"):
		var hour: int = day_night_system.get_current_hour()
		if hour >= 12 and hour <= 16:
			time_modifier = 5.0  # Afternoon warmth
		elif hour >= 0 and hour <= 6:
			time_modifier = -8.0  # Night cold
	
	# Weather modifier
	var weather_config: Dictionary = WEATHER_CONFIGS.get(current_weather, {})
	var weather_temp_mod: float = weather_config.get("temperature_modifier", 0)
	
	current_temperature = base_temp + time_modifier + (weather_temp_mod * weather_intensity)


func get_temperature_feeling() -> String:
	if current_temperature < -20:
		return "Freezing"
	elif current_temperature < 0:
		return "Very Cold"
	elif current_temperature < 10:
		return "Cold"
	elif current_temperature < 20:
		return "Cool"
	elif current_temperature < 25:
		return "Comfortable"
	elif current_temperature < 30:
		return "Warm"
	elif current_temperature < 35:
		return "Hot"
	else:
		return "Scorching"


func get_temperature_status_effect() -> String:
	if current_temperature < -15:
		return "freezing"
	elif current_temperature < 0:
		return "cold"
	elif current_temperature > 40:
		return "overheating"
	elif current_temperature > 35:
		return "hot"
	return ""


# ============================================================================
# VISUAL EFFECTS
# ============================================================================

func _setup_visual_effects() -> void:
	# These would be set up in the scene or created dynamically
	pass


func _apply_weather_visuals() -> void:
	var config := WEATHER_CONFIGS.get(current_weather, {})
	
	# Update ambient lighting
	var ambient_color: Color = config.get("ambient_light", Color.WHITE)
	var ambient_energy: float = config.get("ambient_light_energy", 1.0)
	
	# Apply to world environment (if exists)
	# get_tree().call_group("environment", "set_ambient", ambient_color, ambient_energy)
	
	# Update fog
	var fog_density: float = config.get("fog_density", 0.0)
	if _fog_overlay:
		_fog_overlay.color.a = fog_density * weather_intensity
		_fog_overlay.visible = fog_density > 0.01
	
	# Update particles
	var particle_effect: String = config.get("particle_effect", "")
	_update_particle_effects(particle_effect)


func _update_particle_effects(effect_type: String) -> void:
	# Disable all first
	if _rain_particles:
		_rain_particles.emitting = false
	if _snow_particles:
		_snow_particles.emitting = false
	
	match effect_type:
		"rain_light", "rain_heavy", "acid_rain":
			if _rain_particles:
				_rain_particles.emitting = true
				_rain_particles.amount = 500 if "heavy" in effect_type else 200
		"snow", "blizzard":
			if _snow_particles:
				_snow_particles.emitting = true
				_snow_particles.amount = 300 if effect_type == "blizzard" else 150


func _update_weather_effects(delta: float) -> void:
	# Intensity fluctuation
	var target_intensity := _rng.randf_range(0.7, 1.0)
	weather_intensity = lerp(weather_intensity, target_intensity, delta * 0.1)
	
	# Update fog overlay alpha based on intensity
	if _fog_overlay and _fog_overlay.visible:
		var config: Dictionary = WEATHER_CONFIGS.get(current_weather, {})
		var base_fog: float = config.get("fog_density", 0.0)
		_fog_overlay.color.a = base_fog * weather_intensity


func _update_lightning(delta: float) -> void:
	_lightning_timer -= delta
	
	if _lightning_timer <= 0:
		var config: Dictionary = WEATHER_CONFIGS.get(current_weather, {})
		var lightning_chance: float = config.get("lightning_chance", 0.0)
		
		if _rng.randf() < lightning_chance:
			_trigger_lightning()
		
		_lightning_timer = _rng.randf_range(3.0, 15.0)


func _trigger_lightning() -> void:
	# Flash effect
	# get_tree().call_group("lighting", "lightning_flash")
	
	# Sound effect
	# AudioManager.play_sfx("thunder")
	
	# Possible lightning strike damage in open areas
	if _rng.randf() < 0.05:
		var strike_pos := Vector2(_rng.randf_range(0, 1000), _rng.randf_range(0, 1000))
		emit_signal("environmental_hazard_started", "lightning_strike", strike_pos)


# ============================================================================
# ENVIRONMENTAL DAMAGE
# ============================================================================

func _apply_environmental_damage(delta: float) -> void:
	var config: Dictionary = WEATHER_CONFIGS.get(current_weather, {})
	
	# Direct damage (sandstorm, acid rain)
	var damage_rate: float = config.get("damage_rate", 0.0)
	if damage_rate > 0:
		_apply_damage_to_player(damage_rate * weather_intensity * delta, "environmental")
	
	# Cold damage
	var cold_damage_rate: float = config.get("cold_damage_rate", 0.0)
	if cold_damage_rate > 0 and not _player_is_sheltered():
		_apply_damage_to_player(cold_damage_rate * weather_intensity * delta, "cold")
	
	# Radiation damage
	var radiation_rate: float = config.get("radiation_rate", 0.0)
	if radiation_rate > 0 and not _player_has_hazmat():
		_apply_radiation_to_player(radiation_rate * weather_intensity * delta)
	
	# Wetness accumulation
	var wetness_rate: float = config.get("wetness_rate", 0.0)
	if wetness_rate > 0 and not _player_is_sheltered():
		_apply_wetness_to_player(wetness_rate * weather_intensity * delta)


func _apply_damage_to_player(amount: float, damage_type: String) -> void:
	# Connect to player health system
	# var player = get_tree().get_first_node_in_group("player")
	# if player and player.has_method("take_environmental_damage"):
	#     player.take_environmental_damage(amount, damage_type)
	pass


func _apply_radiation_to_player(amount: float) -> void:
	# if StatusEffects:
	#     StatusEffects.add_effect(player, "radiation", amount)
	pass


func _apply_wetness_to_player(amount: float) -> void:
	# Wetness leads to cold effects
	# player.wetness = min(1.0, player.wetness + amount)
	pass


func _player_is_sheltered() -> bool:
	# Check if player is indoors or under cover
	# var player = get_tree().get_first_node_in_group("player")
	# return player and player.is_sheltered
	return false


func _player_has_hazmat() -> bool:
	# Check if player has hazmat gear equipped
	return false


# ============================================================================
# PUBLIC API
# ============================================================================

func set_weather(weather_type: WeatherType, duration: float = -1.0) -> void:
	## Force weather change
	var old_weather := current_weather
	current_weather = weather_type
	weather_timer = 0.0
	weather_duration = duration if duration > 0 else _rng.randf_range(180.0, 600.0)
	weather_intensity = 1.0
	
	_apply_weather_visuals()
	emit_signal("weather_changed", old_weather, current_weather)


func set_zone_weather_bias(bias: Dictionary) -> void:
	## Set weather probabilities for current zone
	## e.g., {"SANDSTORM": 2.0} doubles sandstorm chance
	zone_weather_bias = bias


func set_zone_temperature(base_temp: float) -> void:
	zone_base_temperature = base_temp
	_update_temperature()


func set_season(season: Season) -> void:
	current_season = season
	_update_temperature()


func get_weather_name() -> String:
	return WEATHER_CONFIGS.get(current_weather, {}).get("name", "Unknown")


func get_weather_config() -> Dictionary:
	return WEATHER_CONFIGS.get(current_weather, {})


func get_visibility_range() -> float:
	var config: Dictionary = WEATHER_CONFIGS.get(current_weather, {})
	return config.get("visibility_range", 1000) * (2.0 - weather_intensity)


func get_movement_modifier() -> float:
	var config: Dictionary = WEATHER_CONFIGS.get(current_weather, {})
	var base_mod: float = config.get("movement_modifier", 1.0)
	return lerp(1.0, base_mod, weather_intensity)


func get_stamina_modifier() -> float:
	var config: Dictionary = WEATHER_CONFIGS.get(current_weather, {})
	var base_mod: float = config.get("stamina_modifier", 1.0)
	return lerp(1.0, base_mod, weather_intensity)


func get_enemy_detection_modifier() -> float:
	var config: Dictionary = WEATHER_CONFIGS.get(current_weather, {})
	return config.get("enemy_detection_modifier", 1.0)


func is_dangerous_weather() -> bool:
	return current_weather in [
		WeatherType.THUNDERSTORM,
		WeatherType.BLIZZARD,
		WeatherType.SANDSTORM,
		WeatherType.ACID_RAIN,
		WeatherType.RADIATION_STORM,
	]


func requires_shelter() -> bool:
	var config: Dictionary = WEATHER_CONFIGS.get(current_weather, {})
	return config.get("requires_shelter", false)


# ============================================================================
# ENVIRONMENTAL HAZARDS
# ============================================================================

func spawn_hazard(hazard_type: String, position: Vector2, duration: float = 30.0) -> void:
	var hazard := {
		"type": hazard_type,
		"position": position,
		"duration": duration,
		"elapsed": 0.0,
	}
	active_hazards.append(hazard)
	emit_signal("environmental_hazard_started", hazard_type, position)


func update_hazards(delta: float) -> void:
	var to_remove: Array[int] = []
	
	for i in range(active_hazards.size()):
		active_hazards[i]["elapsed"] += delta
		if active_hazards[i]["elapsed"] >= active_hazards[i]["duration"]:
			to_remove.append(i)
			emit_signal("environmental_hazard_ended", active_hazards[i]["type"])
	
	# Remove expired hazards (in reverse order)
	to_remove.reverse()
	for i in to_remove:
		active_hazards.remove_at(i)


func get_hazards_at_position(position: Vector2, radius: float = 50.0) -> Array[Dictionary]:
	var nearby: Array[Dictionary] = []
	for hazard in active_hazards:
		if position.distance_to(hazard["position"]) <= radius:
			nearby.append(hazard)
	return nearby


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"current_weather": current_weather,
		"weather_intensity": weather_intensity,
		"weather_timer": weather_timer,
		"weather_duration": weather_duration,
		"current_temperature": current_temperature,
		"current_season": current_season,
	}


func load_data(data: Dictionary) -> void:
	current_weather = data.get("current_weather", WeatherType.CLEAR)
	weather_intensity = data.get("weather_intensity", 1.0)
	weather_timer = data.get("weather_timer", 0.0)
	weather_duration = data.get("weather_duration", 300.0)
	current_temperature = data.get("current_temperature", 20.0)
	current_season = data.get("current_season", Season.SUMMER)
	
	_apply_weather_visuals()
