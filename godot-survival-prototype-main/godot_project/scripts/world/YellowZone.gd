extends ZoneScene

const TREE := preload("res://scenes/resources/TreeNode.tscn")
const ROCK := preload("res://scenes/resources/RockNode.tscn")
const PLANT := preload("res://scenes/resources/PlantNode.tscn")

func _ready() -> void:
    zone_name = "Yellow Zone"
    enemy_count = 3
    map_size = Vector2i(16, 16)
    tile_size = Vector2(32, 32)
    ground_texture = preload("res://assets/tiles/yellow_tile.png")
    tile_tint = Color(1, 0.95, 0.8, 1)
    tile_variation = 2
    resource_layout = [
        {"scene": TREE, "offset": Vector2(-180, 100)},
        {"scene": TREE, "offset": Vector2(-90, 150)},
        {"scene": ROCK, "offset": Vector2(60, 60)},
        {"scene": ROCK, "offset": Vector2(130, 10)},
        {"scene": PLANT, "offset": Vector2(160, -40)},
        {"scene": PLANT, "offset": Vector2(80, -100)}
    ]
