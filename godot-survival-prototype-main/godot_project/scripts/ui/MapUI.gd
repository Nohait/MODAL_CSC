extends CanvasLayer

@onready var zone_manager: Node = null
@onready var green_btn: Button = $MapPanel/GreenButton
@onready var yellow_btn: Button = $MapPanel/YellowButton
@onready var red_btn: Button = $MapPanel/RedButton

func _ready() -> void:
    var root = get_tree().current_scene
    if root:
        zone_manager = root.get_node_or_null("ZoneManager")
    green_btn.pressed.connect(func(): _on_zone_selected("Green"))
    yellow_btn.pressed.connect(func(): _on_zone_selected("Yellow"))
    red_btn.pressed.connect(func(): _on_zone_selected("Red"))

func _on_zone_selected(zone_key: String) -> void:
    if zone_manager:
        zone_manager.load_zone(zone_key)
