extends HBoxContainer

var recipe
var manager

@onready var icon_texture: TextureRect = $Icon
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var requirement_label: Label = $VBoxContainer/RequirementLabel
@onready var craft_button: Button = $CraftButton

func setup(_recipe, _manager):
    recipe = _recipe
    manager = _manager
    icon_texture.texture = recipe.icon
    name_label.text = recipe.name
    requirement_label.text = _format_requirements(recipe.ingredients)
    craft_button.pressed.connect(_on_craft_pressed)
    refresh()

func refresh() -> void:
    if manager and recipe:
        craft_button.disabled = not manager.can_craft(recipe.id)

func _format_requirements(ingredients: Dictionary) -> String:
    var parts := []
    for key in ingredients.keys():
        parts.append("%s x%d" % [key.capitalize(), int(ingredients[key])])
    return ", ".join(parts)

func _on_craft_pressed() -> void:
    if manager and recipe:
        manager.craft(recipe.id)
        refresh()
