extends ZoneScene

const TREE := preload("res://scenes/resources/TreeNode.tscn")
const ROCK := preload("res://scenes/resources/RockNode.tscn")
const PLANT := preload("res://scenes/resources/PlantNode.tscn")

func _ready() -> void:
    zone_name = "Green Zone"
    enemy_count = 2
    map_size = Vector2i(14, 14)
    tile_size = Vector2(32, 32)
    ground_texture = preload("res://assets/tiles/green_tile.png")
    tile_tint = Color(0.9, 1, 0.9, 1)
    tile_variation = 1
    resource_layout = [
        {"scene": TREE, "offset": Vector2(-140, 80)},
        {"scene": ROCK, "offset": Vector2(110, 40)},
        {"scene": PLANT, "offset": Vector2(140, -30)},
        {"scene": TREE, "offset": Vector2(60, -110)}
    ]
