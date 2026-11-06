extends CanvasLayer

@onready var menu: Control = $Menu
@onready var voile: ColorRect = $Menu/Voile

func _ready() -> void:
	menu.hide()

func masquer(rapide: bool = false) -> void:
	# Masquer le remplacement de salle sans suspendre sa préparation physique.
	menu.show()
	voile.color.a = 0.0
	var fondu := create_tween()
	fondu.tween_property(voile, "color:a", 1.0, 0.12 if rapide else 0.3)
	await fondu.finished

func reveler_salle() -> void:
	var fondu := create_tween()
	fondu.tween_property(voile, "color:a", 0.0, 0.16)
	await fondu.finished
	menu.hide()
