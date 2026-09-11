extends Node3D

# A SUPPRIMER DANS LE JEU REEL 
func _unhandled_key_input(event: InputEvent) -> void:
	# Pour beta_test : R recommence le niveau. On ignore 
	# les répétitions automatiques lorsqu'elle reste enfoncée.
	if event is InputEventKey:
		if event.pressed and (not event.echo) and (event.keycode == KEY_R):
			# On recharge la scène
			get_tree().reload_current_scene()

var ennemi_scene = preload("res://scenes/ennemi.tscn")

@export var nombre_min_ennemis := 3
@export var nombre_max_ennemis := 8


func _ready() -> void:
	var nombre_ennemis = randi_range(nombre_min_ennemis, nombre_max_ennemis)

	for i in range(nombre_ennemis):
		creer_ennemi()


func creer_ennemi() -> void:
	var ennemi = ennemi_scene.instantiate()
	$Ennemis.add_child(ennemi)
