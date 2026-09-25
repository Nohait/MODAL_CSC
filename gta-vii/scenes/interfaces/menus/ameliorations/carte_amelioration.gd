extends Control

signal selected

@export_group("Animation")

## Agrandissement de la carte lorsque la souris la survole.
@export_range(1.0, 1.3, 0.01)
var hover_scale: float = 1.06

## Durée de l'animation de survol, en secondes.
@export_range(0.05, 1.0, 0.01)
var hover_duration: float = 0.15

var hover_tween: Tween


func _ready() -> void:
	pivot_offset = size / 2.0

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	gui_input.connect(_on_gui_input)
	
	selected.connect(_test_selection)


func _on_mouse_entered() -> void:
	animate_scale(Vector2(hover_scale, hover_scale))


func _on_mouse_exited() -> void:
	animate_scale(Vector2.ONE)


func animate_scale(target_scale: Vector2) -> void:
	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween()
	hover_tween.tween_property(
		self,
		"scale",
		target_scale,
		hover_duration
	)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selected.emit()

func _test_selection() -> void:
	print("CARTE SÉLECTIONNÉE")
