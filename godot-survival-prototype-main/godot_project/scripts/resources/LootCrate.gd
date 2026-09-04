extends StaticBody3D
class_name LootCrate
## Interactable loot container - open with E key for random items

signal opened()
signal item_dropped(item_id: String, quantity: int)

@export var possible_drops: Array[Dictionary] = [
	{"item_id": "zombie_flesh", "weight": 3},
	{"item_id": "wood", "weight": 2},
	{"item_id": "stone", "weight": 2}
]
@export var min_items := 1
@export var max_items := 3

const LOOT_SCENE := preload("res://scenes/resources/LootDrop.tscn")

var is_looted := false
var _mesh_instance: MeshInstance3D
var _original_color: Color


func _ready() -> void:
	add_to_group("interactable")
	
	# Cache mesh for color change
	if has_node("MeshPivot/MeshInstance3D"):
		_mesh_instance = $MeshPivot/MeshInstance3D
		if _mesh_instance.material_override:
			_original_color = _mesh_instance.material_override.albedo_color
	
	print("[LootCrate] Ready - possible drops: ", possible_drops.size())


func interact(player: Node) -> void:
	"""Called when player presses E while in range."""
	if is_looted:
		_show_floating_text("Already looted!")
		return
	
	is_looted = true
	opened.emit()
	
	# Spawn random items based on weighted selection
	var item_count := randi_range(min_items, max_items)
	var total_weight := 0
	for drop in possible_drops:
		total_weight += drop.get("weight", 1)
	
	for i in item_count:
		var item_id := _pick_weighted_item(total_weight)
		if not item_id.is_empty():
			_spawn_loot(item_id, 1)
			item_dropped.emit(item_id, 1)
	
	# Visual change - darken
	_set_looted_visual()
	
	# Floating text
	_show_floating_text("Opened!")
	
	print("[LootCrate] Opened! Dropped ", item_count, " items")


func _pick_weighted_item(total_weight: int) -> String:
	var roll := randi() % total_weight
	var cumulative := 0
	
	for drop in possible_drops:
		cumulative += drop.get("weight", 1)
		if roll < cumulative:
			return drop.get("item_id", "")
	
	return ""


func _spawn_loot(item_id: String, quantity: int) -> void:
	var loot: Area3D = LOOT_SCENE.instantiate()
	loot.item_id = item_id
	loot.quantity = quantity
	
	get_tree().current_scene.add_child(loot)
	
	# Position above crate with random offset
	var offset := Vector3(randf_range(-0.3, 0.3), 0.5, randf_range(-0.3, 0.3))
	loot.global_position = global_position + offset


func _set_looted_visual() -> void:
	if not _mesh_instance:
		return
	
	var mat := _mesh_instance.material_override
	if mat and mat is StandardMaterial3D:
		mat.albedo_color = _original_color.darkened(0.5)


func _show_floating_text(text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1, 1, 0.5)
	
	add_child(label)
	label.position = Vector3(0, 1.2, 0)
	
	# Animate up and fade
	var tween := create_tween()
	tween.parallel().tween_property(label, "position:y", 2.0, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)
