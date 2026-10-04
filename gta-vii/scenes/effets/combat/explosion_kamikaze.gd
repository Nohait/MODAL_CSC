extends Node3D

var rayon := 2.1
const TEXTURES = [
	preload("res://assets/textures/feu/kenney/explosion/explosion00.png"),
	preload("res://assets/textures/feu/kenney/explosion/explosion04.png"),
	preload("res://assets/textures/feu/kenney/explosion/explosion08.png")
]

func _ready() -> void:
	# Un bref éclair illumine le décor ; le nuage conserve une silhouette irrégulière.
	var eclair := create_tween()
	eclair.tween_property($Flash, "light_energy", 0.0, 0.25)
	# La texture garde un aspect volumineux tout en restant orientée vers la caméra.
	var nuage: Sprite3D = $Nuage
	nuage.texture = TEXTURES.pick_random()
	var taille := rayon * 2.0 / (nuage.texture.get_width() * nuage.pixel_size)
	nuage.scale = Vector3.ONE * taille * 0.2
	var expansion := create_tween()
	expansion.tween_property(nuage, "scale", Vector3.ONE * taille, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var fondu := create_tween()
	fondu.tween_property(nuage, "modulate", Color(1, 0.85, 0.65, 1), 0.1)
	fondu.tween_property(nuage, "modulate", Color(0.3, 0.22, 0.2, 0), 0.55)
	$Etincelles.restart()
	get_tree().create_timer(0.8).timeout.connect(queue_free)
