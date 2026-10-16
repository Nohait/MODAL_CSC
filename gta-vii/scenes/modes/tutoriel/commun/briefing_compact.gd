extends PanelContainer

@export_range(400.0, 800.0, 10.0) var largeur := 600.0

func _ready() -> void:
	add_to_group("briefings_tutoriel")
	get_viewport().size_changed.connect(_ajuster)
	for etiquette in find_children("*", "Label"):
		etiquette.minimum_size_changed.connect(_ajuster.call_deferred)
	_ajuster.call_deferred()

func _ajuster() -> void:
	var limites := get_viewport_rect().size
	size = Vector2(minf(largeur, limites.x - 40.0), 0.0)
	position = Vector2((limites.x - size.x) * 0.5, 24.0)
