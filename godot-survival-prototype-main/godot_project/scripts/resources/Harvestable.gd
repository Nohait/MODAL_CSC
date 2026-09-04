extends StaticBody3D
class_name Harvestable
## Base class for harvestable resources (trees, rocks, etc.)
## Blocks movement, takes damage, drops loot on destruction

signal damaged(current_hp: float, max_hp: float)
signal destroyed()

@export var hp := 50.0
@export var drops: Array[Dictionary] = []  # [{item_id: String, min_count: int, max_count: int}]

const LOOT_SCENE := preload("res://scenes/resources/LootDrop.tscn")

var _current_hp: float
@onready var mesh_pivot: Node3D = $MeshPivot


func _ready() -> void:
	_current_hp = hp
	add_to_group("harvestable")
	print("[Harvestable] Ready - HP: ", _current_hp)


func take_damage(amount: float, _source: Node = null) -> void:
	if _current_hp <= 0.0:
		return
	
	_current_hp = max(_current_hp - amount, 0.0)
	damaged.emit(_current_hp, hp)
	
	# Hit effect - scale pulse
	_play_hit_effect()
	
	print("[Harvestable] Took ", amount, " damage. HP: ", _current_hp, "/", hp)
	
	if _current_hp <= 0.0:
		_destroy()


func _play_hit_effect() -> void:
	if not mesh_pivot:
		return
	
	var tween := create_tween()
	tween.tween_property(mesh_pivot, "scale", Vector3(1.1, 0.9, 1.1), 0.1)
	tween.tween_property(mesh_pivot, "scale", Vector3.ONE, 0.15)


func _destroy() -> void:
	destroyed.emit()
	
	# Spawn loot drops
	for drop in drops:
		var item_id: String = drop.get("item_id", "")
		var min_count: int = drop.get("min_count", 1)
		var max_count: int = drop.get("max_count", 1)
		
		if item_id.is_empty():
			continue
		
		var count := randi_range(min_count, max_count)
		_spawn_loot(item_id, count)
	
	print("[Harvestable] Destroyed!")
	queue_free()


func _spawn_loot(item_id: String, quantity: int) -> void:
	var loot: Area3D = LOOT_SCENE.instantiate()
	loot.item_id = item_id
	loot.quantity = quantity
	
	# Add to scene tree
	get_tree().current_scene.add_child(loot)
	
	# Position with slight random offset
	var offset := Vector3(randf_range(-0.5, 0.5), 0.3, randf_range(-0.5, 0.5))
	loot.global_position = global_position + offset
