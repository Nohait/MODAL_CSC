extends Area2D
class_name ResourceNode

signal depleted(node)
signal harvested(item_type, amount)

@export var max_hp := 3
@export var loot_type := "resource"
@export var loot_amount := 1
@export var loot_scene := preload("res://scenes/resources/LootItem.tscn")
@export var hit_flash_color := Color(1, 0.7, 0.5, 1)
@export var drop_spread := 12.0

var current_hp := 0
var _flash_timer := 0.0
var _original_color := Color(1, 1, 1, 1)

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
    current_hp = max_hp
    monitoring = true
    set_process(true)
    add_to_group("resource")

func _process(delta: float) -> void:
    if _flash_timer > 0.0:
        _flash_timer -= delta
        if _flash_timer <= 0.0 and sprite:
            sprite.modulate = _original_color

func interact(player: Node) -> void:
    take_damage(1, player, true)

func take_damage(amount: float, source: Node = null, harvested := false) -> bool:
    if current_hp <= 0:
        return false
    current_hp = max(current_hp - amount, 0)
    if sprite:
        sprite.modulate = hit_flash_color
    _flash_timer = 0.2
    if current_hp <= 0:
        _deplete(source)
    else:
        emit_signal("harvested", loot_type, amount)
    return true

func _deplete(source: Node) -> void:
    emit_signal("depleted", source)
    _drop_loot()
    queue_free()

func _drop_loot() -> void:
    var parent_node = get_parent()
    for i in range(loot_amount):
        var loot = loot_scene.instantiate()
        loot.item_type = loot_type
        loot.quantity = 1
        var offset = Vector2(randf_range(-drop_spread, drop_spread), randf_range(-drop_spread, drop_spread))
        loot.global_position = global_position + offset
        if parent_node:
            parent_node.add_child(loot)
        else:
            get_tree().current_scene.add_child(loot)

func reset() -> void:
    current_hp = max_hp
    _flash_timer = 0.0
    if sprite:
        sprite.modulate = _original_color
