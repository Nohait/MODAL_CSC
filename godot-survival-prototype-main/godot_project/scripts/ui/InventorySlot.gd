extends Button

@onready var _icon: TextureRect = $Icon
@onready var quantity_label: Label = $Quantity
@onready var highlight: ColorRect = $Highlight

func _ready() -> void:
    highlight.visible = false
    flat = true
    focus_mode = Control.FOCUS_NONE
    mouse_filter = Control.MOUSE_FILTER_STOP
    text = ""

func set_item(item_id: String, quantity: int) -> void:
    if item_id == "" or quantity <= 0:
        _icon.texture = null
        quantity_label.text = ""
        highlight.visible = false
        return
    var info: Dictionary = ItemDatabase.get_item(item_id) if ItemDatabase else {}
    _icon.texture = info.get("icon", null)
    quantity_label.text = str(quantity)
    highlight.visible = true
