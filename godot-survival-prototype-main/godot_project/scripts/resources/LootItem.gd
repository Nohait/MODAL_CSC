extends Area2D

signal picked_up(item_type, quantity)

@export var item_type := "resource"
@export var quantity := 1
@export var float_amplitude := 4.0
@export var float_speed := 3.0

var _base_position := Vector2.ZERO
var _bob_timer := 0.0

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
    monitoring = true
    set_process(true)
    _base_position = global_position
    area_entered.connect(_on_area_entered)
    if ItemDatabase:
        var info: Dictionary = ItemDatabase.get_item(item_type)
        if info and info.has("icon") and info.icon:
            sprite.texture = info.icon

func _process(delta: float) -> void:
    _bob_timer += delta
    var offset_y = sin(_bob_timer * float_speed) * float_amplitude
    global_position = _base_position + Vector2(0, offset_y)

func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("player_interact"):
        var inventory = get_tree().get_root().get_node_or_null("Inventory")
        if not inventory:
            var current = get_tree().current_scene
            if current:
                inventory = current.get_node_or_null("Inventory")
        var collected := true
        if inventory:
            collected = inventory.add_item(item_type, quantity)
        if collected:
            emit_signal("picked_up", item_type, quantity)
            print("Collected %s x%d" % [item_type, quantity])
            queue_free()
