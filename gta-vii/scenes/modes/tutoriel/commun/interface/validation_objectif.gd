extends RefCounted

const SON = preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.tscn")

static func jouer(arbre: SceneTree) -> void:
	var lecteur := arbre.root.get_node_or_null("ValidationObjectifTutoriel") as AudioStreamPlayer
	if lecteur == null:
		lecteur = SON.instantiate() as AudioStreamPlayer
		arbre.root.add_child(lecteur)
	# Deux objectifs terminés ensemble ne superposent pas deux confirmations.
	if not lecteur.playing: lecteur.play()
