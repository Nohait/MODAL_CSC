extends ResourceNode

func _ready() -> void:
    max_hp = 2
    loot_type = "fibers"
    loot_amount = 4
    hit_flash_color = Color(1, 0.6, 0.9, 1)
    super._ready()
