extends RefCounted

const REGLAGES = preload("res://scenes/interfaces/indications/reglages_nombres_degats.tres")

static func afficher(modele: Label3D, degats: float, hauteur: float) -> void:
	# Le texte de la scène sert de modèle ; chaque coup a sa propre copie.
	var nombre := modele.duplicate() as Label3D
	modele.get_tree().current_scene.add_child(nombre)
	nombre.global_transform = modele.global_transform
	nombre.global_position = modele.get_parent().to_global(Vector3(0, hauteur, 0))
	var decalage := Vector3(randf_range(-0.22, 0.22), randf_range(-0.08, 0.08), randf_range(-0.22, 0.22))
	nombre.global_position += decalage
	nombre.text = "-%.2f" % degats
	var couleur: Color = REGLAGES.couleur_pour(degats)
	nombre.modulate = couleur.lerp(Color.WHITE, REGLAGES.eclaircissement_initial)
	nombre.font_size = 46
	nombre.outline_size = 4
	nombre.show()
	# Le tween appartient au texte : la mort du mob ne coupe pas son animation.
	var animation := nombre.create_tween().set_parallel(true)
	animation.tween_property(nombre, "position", nombre.position + Vector3(decalage.x, 0.9, decalage.z), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Le bref éclat revient à la couleur du montant avant que le fondu commence.
	animation.tween_property(nombre, "modulate", couleur, 0.16)
	animation.tween_property(nombre, "scale", nombre.scale * 1.12, 0.18)
	animation.tween_property(nombre, "modulate:a", 0.0, 0.35).set_delay(0.2)
	# On libère chaque copie une fois son mouvement et son fondu terminés.
	animation.chain().tween_callback(nombre.queue_free)
