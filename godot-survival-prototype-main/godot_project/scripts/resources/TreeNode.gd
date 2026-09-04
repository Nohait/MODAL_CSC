extends ResourceNode

func _ready() -> void:
    max_hp = 3
    loot_type = "wood"
    loot_amount = 3
    hit_flash_color = Color(0.5, 0.9, 0.5, 1)
    super._ready()
