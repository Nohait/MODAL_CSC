extends RefCounted

static func ouvrir(proprietaire: Node, voile: Control, panneau: Control, duree: float = 0.2) -> Tween:
	# Mémoriser la position de repos évite une dérive si on rouvre pendant l'animation.
	var destination: Vector2 = panneau.get_meta("position_repos", panneau.position)
	panneau.set_meta("position_repos", destination)
	voile.modulate.a = 0.0
	panneau.position = destination + Vector2(0, 12)
	panneau.pivot_offset = panneau.size / 2.0
	panneau.scale = Vector2.ONE * 0.985
	var animation := proprietaire.create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	animation.tween_property(voile, "modulate:a", 1.0, duree)
	animation.tween_property(panneau, "position", destination, duree).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation.tween_property(panneau, "scale", Vector2.ONE, duree).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation.finished.connect(func(): panneau.remove_meta("position_repos"))
	return animation
