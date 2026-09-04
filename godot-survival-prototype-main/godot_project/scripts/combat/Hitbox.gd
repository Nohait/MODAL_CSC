extends Area2D

signal damage_dealt(target, amount)

@export var lifetime := 0.2
@export var damage := 25.0
@export var target_groups := []

var _owner: Node
var _time_left := 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    monitoring = false
    set_physics_process(false)
    area_entered.connect(_on_area_entered)

func activate(range: float, direction: Vector2) -> void:
    _configure_shape(range)
    rotation = direction.angle()
    _time_left = lifetime
    monitoring = true
    set_physics_process(true)

func _physics_process(delta: float) -> void:
    _time_left -= delta
    if _time_left <= 0.0:
        queue_free()

func _configure_shape(range: float) -> void:
    var shape = _shape.shape
    if shape is CircleShape2D:
        shape.radius = range
    elif shape is RectangleShape2D:
        shape.extents = Vector2.ONE * range

func _on_area_entered(area: Area2D) -> void:
    if _owner and area.get_owner() == _owner:
        return
    if target_groups.size() > 0:
        var matches := false
        for group in target_groups:
            if area.is_in_group(group):
                matches = true
                break
        if not matches:
            return
    if area.has_method("take_damage"):
        var applied: bool = area.take_damage(damage, _owner)
        if applied:
            emit_signal("damage_dealt", area, damage)
