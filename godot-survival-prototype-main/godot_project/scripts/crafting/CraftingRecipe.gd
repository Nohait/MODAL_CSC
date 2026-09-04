extends RefCounted
class_name CraftingRecipe

var id: String
var name: String
var icon: Texture2D
var ingredients: Dictionary
var result: Dictionary

func _init(_id: String = "", _name: String = "", _icon: Texture2D = null, _ingredients: Dictionary = {}, _result: Dictionary = {}) -> void:
    id = _id
    name = _name
    icon = _icon
    ingredients = _ingredients.duplicate()
    result = _result.duplicate()
