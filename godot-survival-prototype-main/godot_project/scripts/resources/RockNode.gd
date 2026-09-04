extends ResourceNode

func _ready() -> void:
    max_hp = 4
    loot_type = "stone"
    loot_amount = 2
    hit_flash_color = Color(0.7, 0.7, 1, 1)
    super._ready()
