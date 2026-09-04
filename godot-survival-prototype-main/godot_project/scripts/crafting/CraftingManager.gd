extends Node

const CraftingRecipe := preload("res://scripts/crafting/CraftingRecipe.gd")
const CRAFT_SFX := preload("res://assets/sfx/craft.wav")

signal crafted(recipe_id)

var recipes: Array = []
var inventory: Node = null

func _ready() -> void:
    _build_recipes()
    inventory = get_tree().get_root().get_node_or_null("Inventory")
    if not inventory:
        var current = get_tree().current_scene
        if current:
            inventory = current.get_node_or_null("Inventory")

func _build_recipes() -> void:
    var wood_icon: Texture2D = _get_item_icon("plank")
    var pickaxe_icon: Texture2D = _get_item_icon("pickaxe")
    var hatchet_icon: Texture2D = _get_item_icon("hatchet")
    var rope_icon: Texture2D = _get_item_icon("rope")
    recipes = [
        CraftingRecipe.new("plank", "Plank", wood_icon, {"wood": 3}, {"item_id": "plank", "quantity": 1}),
        CraftingRecipe.new("pickaxe", "Pickaxe", pickaxe_icon, {"wood": 3, "stone": 2}, {"item_id": "pickaxe", "quantity": 1}),
        CraftingRecipe.new("hatchet", "Hatchet", hatchet_icon, {"wood": 2, "stone": 3}, {"item_id": "hatchet", "quantity": 1}),
        CraftingRecipe.new("rope", "Rope", rope_icon, {"fibers": 3}, {"item_id": "rope", "quantity": 1})
    ]

func _get_item_icon(item_id: String) -> Texture2D:
    if ItemDatabase:
        var info: Dictionary = ItemDatabase.get_item(item_id)
        if info and info.has("icon"):
            return info.icon
    return null

func get_recipes() -> Array:
    return recipes.duplicate()

func can_craft(recipe_id: String) -> bool:
    var recipe = _find(recipe_id)
    if not recipe or not inventory:
        return false
    return inventory.has_items(recipe.ingredients)

func craft(recipe_id: String) -> bool:
    var recipe = _find(recipe_id)
    if not recipe or not inventory:
        return false
    if not inventory.has_items(recipe.ingredients):
        return false
    inventory.remove_items(recipe.ingredients)
    inventory.add_item(recipe.result.item_id, recipe.result.quantity)
    emit_signal("crafted", recipe_id)
    _play_sound()
    return true

func _find(recipe_id: String) -> CraftingRecipe:
    for recipe in recipes:
        if recipe.id == recipe_id:
            return recipe
    return null

func _play_sound() -> void:
    var player = $CraftSFX if has_node("CraftSFX") else null
    if player and CRAFT_SFX:
        player.stream = CRAFT_SFX
        player.play()
