extends Area3D
class_name LootDrop
## Simple loot drop - auto-pickup when player enters

signal picked_up(item_id: String, quantity: int)

@export var item_id := "scrap"
@export var quantity := 1

var _mesh: MeshInstance3D
var _label: Label3D
var _bob_time := 0.0
var _start_y := 0.0


func _ready() -> void:
	add_to_group("loot")
	
	# Setup collision
	collision_layer = 16  # Interactables layer
	collision_mask = 1    # Player layer
	
	_start_y = global_position.y
	
	# Create visual
	_create_visual()
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	print("[LootDrop] Spawned: ", item_id, " x", quantity)


func _create_visual() -> void:
	# Loot mesh - simple box
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	_mesh.mesh = box
	
	var material := StandardMaterial3D.new()
	material.albedo_color = _get_item_color()
	material.emission_enabled = true
	material.emission = _get_item_color()
	material.emission_energy_multiplier = 0.3
	_mesh.material_override = material
	
	add_child(_mesh)
	
	# Floating text label
	_label = Label3D.new()
	_label.text = "+%d %s" % [quantity, item_id.capitalize()]
	_label.font_size = 32
	_label.position.y = 0.5
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.modulate = Color(1, 1, 0.5)
	
	add_child(_label)


func _get_item_color() -> Color:
	match item_id:
		"wood": return Color(0.6, 0.4, 0.2)
		"stone": return Color(0.5, 0.5, 0.5)
		"scrap": return Color(0.6, 0.6, 0.6)
		"fiber": return Color(0.4, 0.7, 0.3)
		"food": return Color(0.8, 0.5, 0.3)
		"med_supplies": return Color(0.9, 0.2, 0.2)
		"zombie_flesh": return Color(0.5, 0.25, 0.3)
		_: return Color(0.8, 0.8, 0.2)


func _process(delta: float) -> void:
	# Floating animation
	_bob_time += delta * 3.0
	global_position.y = _start_y + sin(_bob_time) * 0.1
	
	# Rotate
	if _mesh:
		_mesh.rotation.y += delta * 2.0


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_collect(body)


func _collect(_player: Node3D) -> void:
	# Try to add to inventory
	var inventory = _get_inventory()
	if inventory and inventory.has_method("add_item"):
		var success: bool = inventory.add_item(item_id, quantity)
		if not success:
			print("[LootDrop] Inventory full!")
			return
	
	picked_up.emit(item_id, quantity)
	print("[LootDrop] Collected: ", item_id, " x", quantity)
	
	# Pickup effect
	_spawn_pickup_effect()
	
	queue_free()


func _get_inventory():
	# Try Main3D scene
	var main := get_tree().current_scene
	if main and main.has_node("Inventory"):
		return main.get_node("Inventory")
	
	# Try autoload
	if has_node("/root/Inventory"):
		return get_node("/root/Inventory")
	
	return null


func _spawn_pickup_effect() -> void:
	# Quick scale-up effect on the label before removing
	if _label:
		var tween := create_tween()
		tween.tween_property(_label, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
		tween.tween_property(_label, "modulate:a", 0.0, 0.2)


## Static factory method to spawn loot at a position
static func spawn_at(parent: Node, pos: Vector3, loot_item: String = "scrap", amount: int = 1) -> LootDrop:
	var loot_scene := preload("res://scenes/resources/LootDrop.tscn")
	var loot: LootDrop = loot_scene.instantiate()
	loot.item_id = loot_item
	loot.quantity = amount
	parent.add_child(loot)
	loot.global_position = pos + Vector3(0, 0.5, 0)
	return loot
