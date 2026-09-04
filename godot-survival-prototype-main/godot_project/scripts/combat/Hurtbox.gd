extends Area2D

signal damaged(amount, remaining_health, source)
signal died(source)

@export var max_health := 120.0
@export var group_name := "hurtbox_enemy"
@export var invulnerable_time := 0.1

var current_health := max_health
var _invulnerable_timer := 0.0

func _ready() -> void:
    current_health = max_health
    add_to_group(group_name)
    set_physics_process(true)

func _physics_process(delta: float) -> void:
    if _invulnerable_timer > 0.0:
        _invulnerable_timer = max(_invulnerable_timer - delta, 0.0)

func take_damage(amount: float, source: Node) -> bool:
    if current_health <= 0.0:
        return false
    if _invulnerable_timer > 0.0:
        return false
    current_health = clamp(current_health - amount, 0.0, max_health)
    _invulnerable_timer = invulnerable_time
    emit_signal("damaged", amount, current_health, source)
    if current_health <= 0.0:
        emit_signal("died", source)
    return true

func reset_health() -> void:
    current_health = max_health
    _invulnerable_timer = 0.0
