extends Node3D

@export_range(0.2, 2.0, 0.05) var duree := 0.55
@onready var anneau: MeshInstance3D = $Anneau
@onready var pictogramme: Sprite3D = $Pictogramme


func _ready() -> void:
	# Chaque libération a son matériau : le fondu ne doit pas affecter les autres anneaux.
	var mat: StandardMaterial3D = anneau.get_active_material(0).duplicate()
	anneau.material_override = mat
	var animation := create_tween().set_parallel(true)
	# Les quatre pistes se jouent ensemble. On conserve Y pour que le cercle reste plat.
	# EASE_IN accélère le resserrement vers les pieds au lieu de ralentir à l'arrivée.
	animation.tween_property(anneau, "scale", Vector3(0.08, 0.1, 0.08), duree).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	animation.tween_property(mat, "albedo_color:a", 0.0, duree)
	# Le pictogramme reste orienté vers la caméra grâce au billboard de Sprite3D.
	animation.tween_property(pictogramme, "position:y", pictogramme.position.y + 0.5, duree).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(pictogramme, "modulate:a", 0.0, duree)
	# chain attend la fin des pistes parallèles avant de supprimer tout l'effet.
	animation.chain().tween_callback(queue_free)
