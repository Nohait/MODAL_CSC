extends CanvasLayer

const ENTRY_SCENE := preload("res://scenes/ui/CraftingRecipeEntry.tscn")
var manager: Node = null
var inventory: Node = null

@onready var grid := $CraftPanel/VBoxContainer/ScrollContainer/RecipeList

func _ready() -> void:
    visible = true
    _ensure_manager()
    _ensure_inventory()
    _populate_recipes()
    if inventory and not inventory.is_connected("inventory_changed", Callable(self, "_refresh_entries")):
        inventory.inventory_changed.connect(_refresh_entries)

func _ensure_manager() -> void:
    if manager and manager.is_inside_tree():
        return
    var current := get_tree().current_scene
    if current:
        manager = current.get_node_or_null("CraftingManager")

func _ensure_inventory() -> void:
    if inventory and inventory.is_inside_tree():
        return
    inventory = get_tree().get_root().get_node_or_null("Inventory")
    if not inventory:
        var current := get_tree().current_scene
        if current:
            inventory = current.get_node_or_null("Inventory")

func _populate_recipes() -> void:
    if not manager:
        return
    for child in grid.get_children():
        child.queue_free()
    for recipe in manager.get_recipes():
        var entry = ENTRY_SCENE.instantiate()
        grid.add_child(entry)
        entry.setup(recipe, manager)

func _refresh_entries() -> void:
    for entry in grid.get_children():
        entry.refresh()
