extends Node
## GameState autoload - manages global game state

# Static singleton instance (set by autoload)
static var instance: Node = null

signal stats_changed(health, stamina)
signal zone_changed(zone_name)

const STARTING_HEALTH := 100.0
const STARTING_STAMINA := 100.0
const DEFAULT_ZONE := "Green Zone"
const GLOBAL_CONFIG := {
    "max_world_radius": 1500,
    "zone_names": ["Green Zone", "Yellow Zone", "Red Zone"],
    "fog_density": 0.35,
    "camera_smooth_speed": 10.0
}

var player_health := STARTING_HEALTH
var player_stamina := STARTING_STAMINA
var current_zone_name := DEFAULT_ZONE

func _ready() -> void:
    instance = self
    current_zone_name = DEFAULT_ZONE
    emit_signal("zone_changed", current_zone_name)

# Static methods for global access
static func update_player_stats(health: float, stamina: float) -> void:
    if instance:
        instance._update_player_stats(health, stamina)

static func update_zone(zone_name: String) -> void:
    if instance:
        instance._update_zone(zone_name)

static func player_died() -> void:
    if instance:
        instance._player_died()

static func reset_stats() -> void:
    if instance:
        instance._reset_stats()

# Instance methods
func _update_player_stats(health: float, stamina: float) -> void:
    var new_health: float = clamp(health, 0.0, STARTING_HEALTH)
    var new_stamina: float = clamp(stamina, 0.0, STARTING_STAMINA)
    var has_changed: bool = player_health != new_health or player_stamina != new_stamina
    player_health = new_health
    player_stamina = new_stamina
    if has_changed:
        emit_signal("stats_changed", player_health, player_stamina)

func _update_zone(zone_name: String) -> void:
    if current_zone_name == zone_name:
        return
    current_zone_name = zone_name
    emit_signal("zone_changed", current_zone_name)

func _reset_stats() -> void:
    player_health = STARTING_HEALTH
    player_stamina = STARTING_STAMINA
    emit_signal("stats_changed", player_health, player_stamina)

func _player_died() -> void:
    player_health = 0.0
    emit_signal("stats_changed", player_health, player_stamina)
