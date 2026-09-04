extends CanvasLayer

const SLOT_SCENE := preload("res://scenes/ui/InventorySlot.tscn")
const SLOT_COUNT := 32

@onready var grid := $InventoryPanel/MarginContainer/VBoxContainer/GridContainer
var inventory_node: Node = null

func _ready() -> void:
    visible = false
    set_process_input(true)
    for i in range(SLOT_COUNT):
        var slot = SLOT_SCENE.instantiate()
        grid.add_child(slot)
    _ensure_inventory()
    _refresh_slots()

func _input(event):
    if event is InputEventKey and event.pressed and event.keycode == KEY_I:
        visible = not visible

func _ensure_inventory() -> void:
    if inventory_node and inventory_node.is_inside_tree():
        return
    inventory_node = get_tree().get_root().get_node_or_null("Inventory")
    if not inventory_node:
        var current = get_tree().current_scene
        if current:
            inventory_node = current.get_node_or_null("Inventory")
    if inventory_node and not inventory_node.is_connected("inventory_changed", Callable(self, "_refresh_slots")):
        inventory_node.inventory_changed.connect(_refresh_slots)

func _refresh_slots() -> void:
    _ensure_inventory()
    if not inventory_node:
        return
    for i in range(grid.get_child_count()):
        var slot = grid.get_child(i)
        var data = inventory_node.get_slot(i)
        slot.set_item(data.item_id, data.quantity)
