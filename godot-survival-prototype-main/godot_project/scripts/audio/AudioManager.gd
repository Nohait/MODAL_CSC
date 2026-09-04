extends Node
class_name AudioManagerClass
## Comprehensive audio management system for 3D survival game
## Handles music, SFX, ambient sounds, 3D positional audio, and audio pools

signal music_changed(track_name: String)
signal ambient_changed(ambient_name: String)
signal audio_settings_changed()
signal sound_played(sound_id: String, position: Vector3)

# ============================================================================
# AUDIO CONFIGURATION
# ============================================================================

enum AudioBus {
	MASTER,
	MUSIC,
	SFX,
	AMBIENT,
	UI,
	VOICE,
}

enum MusicState {
	STOPPED,
	PLAYING,
	FADING_IN,
	FADING_OUT,
	CROSSFADING,
}

enum SoundCategory {
	COMBAT,
	FOOTSTEPS,
	ENVIRONMENT,
	UI,
	VOICE,
	VEHICLE,
	BUILDING,
	CRAFTING,
	CREATURE,
	WEATHER,
}

const BUS_NAMES := {
	AudioBus.MASTER: "Master",
	AudioBus.MUSIC: "Music",
	AudioBus.SFX: "SFX",
	AudioBus.AMBIENT: "Ambient",
	AudioBus.UI: "UI",
	AudioBus.VOICE: "Voice",
}

const DEFAULT_VOLUMES := {
	AudioBus.MASTER: 1.0,
	AudioBus.MUSIC: 0.7,
	AudioBus.SFX: 1.0,
	AudioBus.AMBIENT: 0.6,
	AudioBus.UI: 0.8,
	AudioBus.VOICE: 1.0,
}

const MUSIC_FADE_TIME := 2.0
const CROSSFADE_TIME := 3.0
const SFX_POOL_SIZE := 32
const AMBIENT_POOL_SIZE := 8
const MAX_CONCURRENT_SOUNDS := 64

# Sound definitions
const SOUND_DEFINITIONS := {
	# Combat
	"gun_pistol": {"path": "res://assets/sfx/combat/gun_pistol.ogg", "category": SoundCategory.COMBAT, "volume": 0.0, "pitch_variance": 0.1},
	"gun_rifle": {"path": "res://assets/sfx/combat/gun_rifle.ogg", "category": SoundCategory.COMBAT, "volume": 0.0, "pitch_variance": 0.1},
	"gun_shotgun": {"path": "res://assets/sfx/combat/gun_shotgun.ogg", "category": SoundCategory.COMBAT, "volume": 0.0, "pitch_variance": 0.1},
	"gun_reload": {"path": "res://assets/sfx/combat/gun_reload.ogg", "category": SoundCategory.COMBAT, "volume": -3.0, "pitch_variance": 0.05},
	"melee_swing": {"path": "res://assets/sfx/combat/melee_swing.ogg", "category": SoundCategory.COMBAT, "volume": -5.0, "pitch_variance": 0.15},
	"melee_hit": {"path": "res://assets/sfx/combat/melee_hit.ogg", "category": SoundCategory.COMBAT, "volume": -3.0, "pitch_variance": 0.1},
	"bullet_impact": {"path": "res://assets/sfx/combat/bullet_impact.ogg", "category": SoundCategory.COMBAT, "volume": -5.0, "pitch_variance": 0.2},
	"explosion": {"path": "res://assets/sfx/combat/explosion.ogg", "category": SoundCategory.COMBAT, "volume": 3.0, "pitch_variance": 0.1},
	
	# Player
	"footstep_dirt": {"path": "res://assets/sfx/player/footstep_dirt.ogg", "category": SoundCategory.FOOTSTEPS, "volume": -10.0, "pitch_variance": 0.2},
	"footstep_grass": {"path": "res://assets/sfx/player/footstep_grass.ogg", "category": SoundCategory.FOOTSTEPS, "volume": -10.0, "pitch_variance": 0.2},
	"footstep_concrete": {"path": "res://assets/sfx/player/footstep_concrete.ogg", "category": SoundCategory.FOOTSTEPS, "volume": -8.0, "pitch_variance": 0.15},
	"footstep_metal": {"path": "res://assets/sfx/player/footstep_metal.ogg", "category": SoundCategory.FOOTSTEPS, "volume": -6.0, "pitch_variance": 0.15},
	"footstep_water": {"path": "res://assets/sfx/player/footstep_water.ogg", "category": SoundCategory.FOOTSTEPS, "volume": -8.0, "pitch_variance": 0.2},
	"player_hurt": {"path": "res://assets/sfx/player/player_hurt.ogg", "category": SoundCategory.VOICE, "volume": 0.0, "pitch_variance": 0.1},
	"player_death": {"path": "res://assets/sfx/player/player_death.ogg", "category": SoundCategory.VOICE, "volume": 0.0, "pitch_variance": 0.05},
	"player_jump": {"path": "res://assets/sfx/player/player_jump.ogg", "category": SoundCategory.FOOTSTEPS, "volume": -5.0, "pitch_variance": 0.1},
	"player_land": {"path": "res://assets/sfx/player/player_land.ogg", "category": SoundCategory.FOOTSTEPS, "volume": -3.0, "pitch_variance": 0.1},
	
	# Environment
	"door_open": {"path": "res://assets/sfx/environment/door_open.ogg", "category": SoundCategory.ENVIRONMENT, "volume": -3.0, "pitch_variance": 0.1},
	"door_close": {"path": "res://assets/sfx/environment/door_close.ogg", "category": SoundCategory.ENVIRONMENT, "volume": -3.0, "pitch_variance": 0.1},
	"container_open": {"path": "res://assets/sfx/environment/container_open.ogg", "category": SoundCategory.ENVIRONMENT, "volume": -5.0, "pitch_variance": 0.1},
	"container_close": {"path": "res://assets/sfx/environment/container_close.ogg", "category": SoundCategory.ENVIRONMENT, "volume": -5.0, "pitch_variance": 0.1},
	"tree_chop": {"path": "res://assets/sfx/environment/tree_chop.ogg", "category": SoundCategory.ENVIRONMENT, "volume": -3.0, "pitch_variance": 0.15},
	"tree_fall": {"path": "res://assets/sfx/environment/tree_fall.ogg", "category": SoundCategory.ENVIRONMENT, "volume": 0.0, "pitch_variance": 0.1},
	"rock_mine": {"path": "res://assets/sfx/environment/rock_mine.ogg", "category": SoundCategory.ENVIRONMENT, "volume": -3.0, "pitch_variance": 0.15},
	"bush_rustle": {"path": "res://assets/sfx/environment/bush_rustle.ogg", "category": SoundCategory.ENVIRONMENT, "volume": -8.0, "pitch_variance": 0.2},
	
	# UI
	"ui_click": {"path": "res://assets/sfx/ui/ui_click.ogg", "category": SoundCategory.UI, "volume": -5.0, "pitch_variance": 0.0},
	"ui_hover": {"path": "res://assets/sfx/ui/ui_hover.ogg", "category": SoundCategory.UI, "volume": -10.0, "pitch_variance": 0.0},
	"ui_confirm": {"path": "res://assets/sfx/ui/ui_confirm.ogg", "category": SoundCategory.UI, "volume": -3.0, "pitch_variance": 0.0},
	"ui_cancel": {"path": "res://assets/sfx/ui/ui_cancel.ogg", "category": SoundCategory.UI, "volume": -3.0, "pitch_variance": 0.0},
	"ui_error": {"path": "res://assets/sfx/ui/ui_error.ogg", "category": SoundCategory.UI, "volume": 0.0, "pitch_variance": 0.0},
	"ui_notification": {"path": "res://assets/sfx/ui/ui_notification.ogg", "category": SoundCategory.UI, "volume": -3.0, "pitch_variance": 0.0},
	"inventory_open": {"path": "res://assets/sfx/ui/inventory_open.ogg", "category": SoundCategory.UI, "volume": -5.0, "pitch_variance": 0.0},
	"inventory_close": {"path": "res://assets/sfx/ui/inventory_close.ogg", "category": SoundCategory.UI, "volume": -5.0, "pitch_variance": 0.0},
	"item_pickup": {"path": "res://assets/sfx/ui/item_pickup.ogg", "category": SoundCategory.UI, "volume": -5.0, "pitch_variance": 0.1},
	"item_drop": {"path": "res://assets/sfx/ui/item_drop.ogg", "category": SoundCategory.UI, "volume": -5.0, "pitch_variance": 0.1},
	"item_equip": {"path": "res://assets/sfx/ui/item_equip.ogg", "category": SoundCategory.UI, "volume": -3.0, "pitch_variance": 0.0},
	
	# Crafting
	"craft_start": {"path": "res://assets/sfx/crafting/craft_start.ogg", "category": SoundCategory.CRAFTING, "volume": -5.0, "pitch_variance": 0.0},
	"craft_complete": {"path": "res://assets/sfx/crafting/craft_complete.ogg", "category": SoundCategory.CRAFTING, "volume": 0.0, "pitch_variance": 0.0},
	"craft_fail": {"path": "res://assets/sfx/crafting/craft_fail.ogg", "category": SoundCategory.CRAFTING, "volume": 0.0, "pitch_variance": 0.0},
	"forge_fire": {"path": "res://assets/sfx/crafting/forge_fire.ogg", "category": SoundCategory.CRAFTING, "volume": -3.0, "pitch_variance": 0.1},
	"hammer_hit": {"path": "res://assets/sfx/crafting/hammer_hit.ogg", "category": SoundCategory.CRAFTING, "volume": -3.0, "pitch_variance": 0.15},
	
	# Building
	"build_place": {"path": "res://assets/sfx/building/build_place.ogg", "category": SoundCategory.BUILDING, "volume": -3.0, "pitch_variance": 0.1},
	"build_destroy": {"path": "res://assets/sfx/building/build_destroy.ogg", "category": SoundCategory.BUILDING, "volume": 0.0, "pitch_variance": 0.1},
	"build_upgrade": {"path": "res://assets/sfx/building/build_upgrade.ogg", "category": SoundCategory.BUILDING, "volume": 0.0, "pitch_variance": 0.0},
	"turret_fire": {"path": "res://assets/sfx/building/turret_fire.ogg", "category": SoundCategory.BUILDING, "volume": 0.0, "pitch_variance": 0.1},
	
	# Vehicles
	"vehicle_engine_start": {"path": "res://assets/sfx/vehicles/engine_start.ogg", "category": SoundCategory.VEHICLE, "volume": 0.0, "pitch_variance": 0.05},
	"vehicle_engine_loop": {"path": "res://assets/sfx/vehicles/engine_loop.ogg", "category": SoundCategory.VEHICLE, "volume": -3.0, "pitch_variance": 0.0},
	"vehicle_engine_stop": {"path": "res://assets/sfx/vehicles/engine_stop.ogg", "category": SoundCategory.VEHICLE, "volume": -3.0, "pitch_variance": 0.05},
	"vehicle_horn": {"path": "res://assets/sfx/vehicles/horn.ogg", "category": SoundCategory.VEHICLE, "volume": 0.0, "pitch_variance": 0.0},
	"vehicle_crash": {"path": "res://assets/sfx/vehicles/crash.ogg", "category": SoundCategory.VEHICLE, "volume": 3.0, "pitch_variance": 0.1},
	
	# Creatures
	"zombie_groan": {"path": "res://assets/sfx/creatures/zombie_groan.ogg", "category": SoundCategory.CREATURE, "volume": -3.0, "pitch_variance": 0.2},
	"zombie_attack": {"path": "res://assets/sfx/creatures/zombie_attack.ogg", "category": SoundCategory.CREATURE, "volume": 0.0, "pitch_variance": 0.15},
	"zombie_death": {"path": "res://assets/sfx/creatures/zombie_death.ogg", "category": SoundCategory.CREATURE, "volume": 0.0, "pitch_variance": 0.1},
	"wolf_growl": {"path": "res://assets/sfx/creatures/wolf_growl.ogg", "category": SoundCategory.CREATURE, "volume": 0.0, "pitch_variance": 0.1},
	"wolf_attack": {"path": "res://assets/sfx/creatures/wolf_attack.ogg", "category": SoundCategory.CREATURE, "volume": 0.0, "pitch_variance": 0.1},
}

# Music tracks
const MUSIC_DEFINITIONS := {
	"menu_theme": {"path": "res://assets/music/menu_theme.ogg", "loop": true, "volume": 0.0},
	"exploration": {"path": "res://assets/music/exploration.ogg", "loop": true, "volume": -3.0},
	"exploration_night": {"path": "res://assets/music/exploration_night.ogg", "loop": true, "volume": -3.0},
	"combat": {"path": "res://assets/music/combat.ogg", "loop": true, "volume": 0.0},
	"combat_intense": {"path": "res://assets/music/combat_intense.ogg", "loop": true, "volume": 0.0},
	"base": {"path": "res://assets/music/base.ogg", "loop": true, "volume": -5.0},
	"horde": {"path": "res://assets/music/horde.ogg", "loop": true, "volume": 0.0},
	"boss": {"path": "res://assets/music/boss.ogg", "loop": true, "volume": 0.0},
	"dungeon": {"path": "res://assets/music/dungeon.ogg", "loop": true, "volume": -3.0},
	"victory": {"path": "res://assets/music/victory.ogg", "loop": false, "volume": 0.0},
	"defeat": {"path": "res://assets/music/defeat.ogg", "loop": false, "volume": 0.0},
	"tension": {"path": "res://assets/music/tension.ogg", "loop": true, "volume": -5.0},
}

# Ambient sounds
const AMBIENT_DEFINITIONS := {
	"forest_day": {"path": "res://assets/sfx/ambient/forest_day.ogg", "loop": true, "volume": -10.0},
	"forest_night": {"path": "res://assets/sfx/ambient/forest_night.ogg", "loop": true, "volume": -10.0},
	"wind": {"path": "res://assets/sfx/ambient/wind.ogg", "loop": true, "volume": -8.0},
	"rain_light": {"path": "res://assets/sfx/ambient/rain_light.ogg", "loop": true, "volume": -5.0},
	"rain_heavy": {"path": "res://assets/sfx/ambient/rain_heavy.ogg", "loop": true, "volume": 0.0},
	"thunder": {"path": "res://assets/sfx/ambient/thunder.ogg", "loop": false, "volume": 3.0},
	"indoor": {"path": "res://assets/sfx/ambient/indoor.ogg", "loop": true, "volume": -15.0},
	"city_ruins": {"path": "res://assets/sfx/ambient/city_ruins.ogg", "loop": true, "volume": -10.0},
	"cave": {"path": "res://assets/sfx/ambient/cave.ogg", "loop": true, "volume": -10.0},
	"fire_crackling": {"path": "res://assets/sfx/ambient/fire_crackling.ogg", "loop": true, "volume": -5.0},
}


# ============================================================================
# STATE
# ============================================================================

var _bus_volumes: Dictionary = {}
var _bus_muted: Dictionary = {}
var _music_state: int = MusicState.STOPPED
var _current_music: String = ""
var _current_ambient: String = ""
var _music_player: AudioStreamPlayer = null
var _music_player_secondary: AudioStreamPlayer = null  # For crossfading
var _ambient_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer3D] = []
var _sfx_pool_2d: Array[AudioStreamPlayer] = []
var _active_sounds: Dictionary = {}  # sound_id -> AudioStreamPlayer
var _sound_cache: Dictionary = {}  # path -> AudioStream
var _listener_position: Vector3 = Vector3.ZERO
var _fade_tween: Tween = null
var _crossfade_tween: Tween = null
var _sound_cooldowns: Dictionary = {}  # sound_id -> cooldown timer


func _ready() -> void:
	_setup_audio_buses()
	_initialize_volumes()
	_create_music_players()
	_create_sfx_pool()
	_create_ambient_player()


func _process(delta: float) -> void:
	_update_sound_cooldowns(delta)


# ============================================================================
# INITIALIZATION
# ============================================================================

func _setup_audio_buses() -> void:
	# Ensure audio buses exist (normally done in project settings)
	# This creates them programmatically if needed
	pass


func _initialize_volumes() -> void:
	for bus in AudioBus.values():
		_bus_volumes[bus] = DEFAULT_VOLUMES.get(bus, 1.0)
		_bus_muted[bus] = false


func _create_music_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_NAMES[AudioBus.MUSIC]
	add_child(_music_player)
	
	_music_player_secondary = AudioStreamPlayer.new()
	_music_player_secondary.bus = BUS_NAMES[AudioBus.MUSIC]
	add_child(_music_player_secondary)


func _create_ambient_player() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = BUS_NAMES[AudioBus.AMBIENT]
	add_child(_ambient_player)


func _create_sfx_pool() -> void:
	# 3D sound pool
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer3D.new()
		player.bus = BUS_NAMES[AudioBus.SFX]
		player.max_distance = 50.0
		player.unit_size = 5.0
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(player)
		_sfx_pool.append(player)
	
	# 2D sound pool (for UI, non-positional)
	for i in range(16):
		var player := AudioStreamPlayer.new()
		player.bus = BUS_NAMES[AudioBus.SFX]
		add_child(player)
		_sfx_pool_2d.append(player)


# ============================================================================
# VOLUME CONTROL
# ============================================================================

func set_bus_volume(bus: int, volume: float) -> void:
	volume = clampf(volume, 0.0, 1.0)
	_bus_volumes[bus] = volume
	
	var bus_name: String = BUS_NAMES.get(bus, "Master")
	var bus_idx := AudioServer.get_bus_index(bus_name)
	
	if bus_idx >= 0:
		var db := linear_to_db(volume)
		AudioServer.set_bus_volume_db(bus_idx, db)
	
	emit_signal("audio_settings_changed")


func get_bus_volume(bus: int) -> float:
	return _bus_volumes.get(bus, 1.0)


func set_bus_muted(bus: int, muted: bool) -> void:
	_bus_muted[bus] = muted
	
	var bus_name: String = BUS_NAMES.get(bus, "Master")
	var bus_idx := AudioServer.get_bus_index(bus_name)
	
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, muted)
	
	emit_signal("audio_settings_changed")


func is_bus_muted(bus: int) -> bool:
	return _bus_muted.get(bus, false)


func set_master_volume(volume: float) -> void:
	set_bus_volume(AudioBus.MASTER, volume)


func get_master_volume() -> float:
	return get_bus_volume(AudioBus.MASTER)


# ============================================================================
# MUSIC
# ============================================================================

func play_music(track_name: String, fade_in: bool = true) -> void:
	if track_name == _current_music and _music_state == MusicState.PLAYING:
		return
	
	var track: Dictionary = MUSIC_DEFINITIONS.get(track_name, {})
	if track.is_empty():
		push_warning("AudioManager: Unknown music track: " + track_name)
		return
	
	var stream: AudioStream = _load_audio(track["path"])
	if stream == null:
		return
	
	if _music_state == MusicState.PLAYING and fade_in:
		_crossfade_music(stream, track)
	else:
		_start_music(stream, track, fade_in)
	
	_current_music = track_name
	emit_signal("music_changed", track_name)


func _start_music(stream: AudioStream, track: Dictionary, fade_in: bool) -> void:
	_music_player.stream = stream
	_music_player.volume_db = track.get("volume", 0.0)
	
	if fade_in:
		_music_player.volume_db = -80.0
		_music_player.play()
		_music_state = MusicState.FADING_IN
		
		if _fade_tween:
			_fade_tween.kill()
		
		_fade_tween = create_tween()
		_fade_tween.tween_property(_music_player, "volume_db", track.get("volume", 0.0), MUSIC_FADE_TIME)
		_fade_tween.tween_callback(func(): _music_state = MusicState.PLAYING)
	else:
		_music_player.play()
		_music_state = MusicState.PLAYING


func _crossfade_music(new_stream: AudioStream, track: Dictionary) -> void:
	# Swap players
	var temp := _music_player
	_music_player = _music_player_secondary
	_music_player_secondary = temp
	
	_music_player.stream = new_stream
	_music_player.volume_db = -80.0
	_music_player.play()
	
	_music_state = MusicState.CROSSFADING
	
	if _crossfade_tween:
		_crossfade_tween.kill()
	
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(_music_player, "volume_db", track.get("volume", 0.0), CROSSFADE_TIME)
	_crossfade_tween.tween_property(_music_player_secondary, "volume_db", -80.0, CROSSFADE_TIME)
	_crossfade_tween.set_parallel(false)
	_crossfade_tween.tween_callback(func():
		_music_player_secondary.stop()
		_music_state = MusicState.PLAYING
	)


func stop_music(fade_out: bool = true) -> void:
	if _music_state == MusicState.STOPPED:
		return
	
	if fade_out:
		_music_state = MusicState.FADING_OUT
		
		if _fade_tween:
			_fade_tween.kill()
		
		_fade_tween = create_tween()
		_fade_tween.tween_property(_music_player, "volume_db", -80.0, MUSIC_FADE_TIME)
		_fade_tween.tween_callback(func():
			_music_player.stop()
			_music_state = MusicState.STOPPED
			_current_music = ""
		)
	else:
		_music_player.stop()
		_music_state = MusicState.STOPPED
		_current_music = ""


func pause_music() -> void:
	_music_player.stream_paused = true


func resume_music() -> void:
	_music_player.stream_paused = false


func get_current_music() -> String:
	return _current_music


# ============================================================================
# AMBIENT
# ============================================================================

func play_ambient(ambient_name: String, fade_in: bool = true) -> void:
	if ambient_name == _current_ambient:
		return
	
	var ambient: Dictionary = AMBIENT_DEFINITIONS.get(ambient_name, {})
	if ambient.is_empty():
		push_warning("AudioManager: Unknown ambient: " + ambient_name)
		return
	
	var stream: AudioStream = _load_audio(ambient["path"])
	if stream == null:
		return
	
	if fade_in and _ambient_player.playing:
		var tween := create_tween()
		tween.tween_property(_ambient_player, "volume_db", -80.0, 1.0)
		tween.tween_callback(func():
			_ambient_player.stream = stream
			_ambient_player.volume_db = -80.0
			_ambient_player.play()
			var fade_tween := create_tween()
			fade_tween.tween_property(_ambient_player, "volume_db", ambient.get("volume", -10.0), 1.0)
		)
	else:
		_ambient_player.stream = stream
		if fade_in:
			_ambient_player.volume_db = -80.0
			_ambient_player.play()
			var tween := create_tween()
			tween.tween_property(_ambient_player, "volume_db", ambient.get("volume", -10.0), 1.0)
		else:
			_ambient_player.volume_db = ambient.get("volume", -10.0)
			_ambient_player.play()
	
	_current_ambient = ambient_name
	emit_signal("ambient_changed", ambient_name)


func stop_ambient(fade_out: bool = true) -> void:
	if fade_out:
		var tween := create_tween()
		tween.tween_property(_ambient_player, "volume_db", -80.0, 1.0)
		tween.tween_callback(func():
			_ambient_player.stop()
			_current_ambient = ""
		)
	else:
		_ambient_player.stop()
		_current_ambient = ""


func get_current_ambient() -> String:
	return _current_ambient


# ============================================================================
# SOUND EFFECTS - 3D
# ============================================================================

func play_sound_3d(sound_id: String, position: Vector3, override_volume: float = -100.0) -> AudioStreamPlayer3D:
	var sound_def: Dictionary = SOUND_DEFINITIONS.get(sound_id, {})
	if sound_def.is_empty():
		push_warning("AudioManager: Unknown sound: " + sound_id)
		return null
	
	# Check cooldown
	if _sound_cooldowns.get(sound_id, 0.0) > 0:
		return null
	
	var player := _get_available_3d_player()
	if player == null:
		return null
	
	var stream: AudioStream = _load_audio(sound_def["path"])
	if stream == null:
		return null
	
	player.stream = stream
	player.global_position = position
	
	var volume: float = override_volume if override_volume > -100.0 else sound_def.get("volume", 0.0)
	player.volume_db = volume
	
	# Apply pitch variance
	var pitch_variance: float = sound_def.get("pitch_variance", 0.0)
	player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	
	# Set appropriate bus based on category
	var category: int = sound_def.get("category", SoundCategory.ENVIRONMENT)
	player.bus = _get_bus_for_category(category)
	
	player.play()
	
	# Set small cooldown to prevent spam
	_sound_cooldowns[sound_id] = 0.05
	
	emit_signal("sound_played", sound_id, position)
	
	return player


func _get_available_3d_player() -> AudioStreamPlayer3D:
	for player in _sfx_pool:
		if not player.playing:
			return player
	
	# All players busy - find oldest/furthest
	var best_player: AudioStreamPlayer3D = _sfx_pool[0]
	var best_distance: float = 0.0
	
	for player in _sfx_pool:
		var dist := player.global_position.distance_to(_listener_position)
		if dist > best_distance:
			best_distance = dist
			best_player = player
	
	best_player.stop()
	return best_player


func _get_bus_for_category(category: int) -> String:
	match category:
		SoundCategory.UI:
			return BUS_NAMES[AudioBus.UI]
		SoundCategory.VOICE:
			return BUS_NAMES[AudioBus.VOICE]
		_:
			return BUS_NAMES[AudioBus.SFX]


# ============================================================================
# SOUND EFFECTS - 2D (Non-positional)
# ============================================================================

func play_sound(sound_id: String, override_volume: float = -100.0) -> AudioStreamPlayer:
	var sound_def: Dictionary = SOUND_DEFINITIONS.get(sound_id, {})
	if sound_def.is_empty():
		push_warning("AudioManager: Unknown sound: " + sound_id)
		return null
	
	var player := _get_available_2d_player()
	if player == null:
		return null
	
	var stream: AudioStream = _load_audio(sound_def["path"])
	if stream == null:
		return null
	
	player.stream = stream
	
	var volume: float = override_volume if override_volume > -100.0 else sound_def.get("volume", 0.0)
	player.volume_db = volume
	
	var pitch_variance: float = sound_def.get("pitch_variance", 0.0)
	player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	
	var category: int = sound_def.get("category", SoundCategory.UI)
	player.bus = _get_bus_for_category(category)
	
	player.play()
	
	return player


func _get_available_2d_player() -> AudioStreamPlayer:
	for player in _sfx_pool_2d:
		if not player.playing:
			return player
	
	# Force stop oldest
	_sfx_pool_2d[0].stop()
	return _sfx_pool_2d[0]


# ============================================================================
# UI SOUNDS (convenience)
# ============================================================================

func play_ui_click() -> void:
	play_sound("ui_click")


func play_ui_hover() -> void:
	play_sound("ui_hover")


func play_ui_confirm() -> void:
	play_sound("ui_confirm")


func play_ui_cancel() -> void:
	play_sound("ui_cancel")


func play_ui_error() -> void:
	play_sound("ui_error")


func play_notification() -> void:
	play_sound("ui_notification")


# ============================================================================
# HELPERS
# ============================================================================

func _load_audio(path: String) -> AudioStream:
	if path in _sound_cache:
		return _sound_cache[path]
	
	if not ResourceLoader.exists(path):
		# Create placeholder for missing audio
		return null
	
	var stream: AudioStream = load(path)
	if stream:
		_sound_cache[path] = stream
	
	return stream


func _update_sound_cooldowns(delta: float) -> void:
	var to_remove: Array = []
	for sound_id in _sound_cooldowns:
		_sound_cooldowns[sound_id] -= delta
		if _sound_cooldowns[sound_id] <= 0:
			to_remove.append(sound_id)
	
	for sound_id in to_remove:
		_sound_cooldowns.erase(sound_id)


func set_listener_position(position: Vector3) -> void:
	_listener_position = position


func preload_sounds(sound_ids: Array) -> void:
	for sound_id in sound_ids:
		var sound_def: Dictionary = SOUND_DEFINITIONS.get(sound_id, {})
		if not sound_def.is_empty():
			_load_audio(sound_def["path"])


func clear_cache() -> void:
	_sound_cache.clear()


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"bus_volumes": _bus_volumes.duplicate(),
		"bus_muted": _bus_muted.duplicate(),
	}


func load_data(data: Dictionary) -> void:
	var volumes: Dictionary = data.get("bus_volumes", {})
	for bus in volumes:
		set_bus_volume(int(bus), volumes[bus])
	
	var muted: Dictionary = data.get("bus_muted", {})
	for bus in muted:
		set_bus_muted(int(bus), muted[bus])
