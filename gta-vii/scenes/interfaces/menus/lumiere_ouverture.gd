extends CanvasLayer

var pression := 0.0
var horloge := 0.0
var voile: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 21
	voile = ColorRect.new()
	voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/interfaces/menus/lumiere_ouverture.gdshader")
	voile.material = mat
	add_child(voile)

func charger(valeur: float) -> void:
	pression = valeur * 0.65

func eclater() -> void:
	# Atteindre le pic rapidement, puis laisser la lumière accompagner la sortie des cartes.
	var eclat := create_tween()
	eclat.tween_property(self, "pression", 1.0, 0.08)
	eclat.tween_property(self, "pression", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	eclat.finished.connect(queue_free)

func _process(delta: float) -> void:
	horloge += delta
	voile.size = get_viewport().get_visible_rect().size
	voile.material.set_shader_parameter("pression", pression)
	voile.material.set_shader_parameter("horloge", horloge)
	voile.material.set_shader_parameter("aspect", voile.size.x / maxf(voile.size.y, 1.0))
