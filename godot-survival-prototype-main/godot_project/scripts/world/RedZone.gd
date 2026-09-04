extends ZoneScene

const TREE := preload("res://scenes/resources/TreeNode.tscn")
const ROCK := preload("res://scenes/resources/RockNode.tscn")
const PLANT := preload("res://scenes/resources/PlantNode.tscn")

func _ready() -> void:
    zone_name = "Red Zone"
    enemy_count = 4
    map_size = Vector2i(18, 18)
    tile_size = Vector2(32, 32)
    ground_texture = preload("res://assets/tiles/red_tile.png")
    tile_tint = Color(1, 0.85, 0.9, 1)
    tile_variation = 3
    resource_layout = [
        {"scene": ROCK, "offset": Vector2(-120, 50)},
        {"scene": ROCK, "offset": Vector2(0, 30)},
        {"scene": ROCK, "offset": Vector2(110, 80)},
        {"scene": TREE, "offset": Vector2(-160, 30)},
        {"scene": PLANT, "offset": Vector2(90, -60)},
        {"scene": PLANT, "offset": Vector2(20, -120)}
    ]
