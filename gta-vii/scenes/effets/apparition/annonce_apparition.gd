extends Node3D

# L'effet annonce sa fin ; le RoomManager reste responsable de créer l'ennemi.
signal terminee
## Durée totale des deux mouvements ; le RoomManager la renseigne avant add_child().
@export_range(0.2, 3.0, 0.1) var duree := 1.0


func _ready() -> void:
	var anneau: MeshInstance3D = $Anneau
	# scale est un multiplicateur de taille sur X, Y et Z.
	# X et Z réduisent le diamètre initial ; Y = 0.04 aplatit l'anneau au sol.
	anneau.scale = Vector3(0.35, 0.04, 0.35)

	var animation := create_tween()
	# tween_property(objet, propriété, valeur finale, durée) programme un mouvement.
	animation.tween_property(anneau, "scale", Vector3(1.1, 0.04, 1.1), duree * 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(anneau, "scale", Vector3(0.85, 0.04, 0.85), duree * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# finished est un signal du Tween émis à la fin de TOUTE la séquence.
	# await suspend seulement cette fonction jusqu'au signal : le jeu continue.
	await animation.finished
	# Prévenir le RoomManager : il peut maintenant créer l'ennemi annoncé,
	# même si le joueur s'est approché pendant l'animation.
	terminee.emit()
	# L'effet a fini son travail. Supprimer le nœud et son anneau en fin d'image.
	queue_free()
