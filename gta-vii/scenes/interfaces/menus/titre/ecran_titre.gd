extends "res://scenes/interfaces/menus/navigation_menus.gd"

func _ready() -> void:
	super._ready()
	%Succes.pressed.connect($MenuSucces.ouvrir)
	%Controles.pressed.connect($MenuControles.ouvrir)
	%Quitter.pressed.connect(get_tree().quit)
	# Faire apparaître le menu doucement, pendant que le décor 3D vit déjà.
	$Menu.modulate.a = 0.0
	var animation := create_tween()
	animation.tween_property($Menu, "modulate:a", 1.0, 0.45)
