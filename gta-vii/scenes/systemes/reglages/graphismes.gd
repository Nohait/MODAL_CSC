extends Node

@export var profils: Array[ProfilGraphique] = [
	preload("res://scenes/systemes/reglages/profils/economique.tres"),
	preload("res://scenes/systemes/reglages/profils/equilibre.tres"),
	preload("res://scenes/systemes/reglages/profils/complet.tres")
]
var indice := 2
var details: Array[GeometryInstance3D] = []

func _ready() -> void:
	# Ne visiter que les branches de décoration explicitement marquées.
	get_tree().node_added.connect(_noeud_ajoute)
	appliquer(indice)

func _noeud_ajoute(noeud: Node) -> void:
	if noeud.is_in_group("details_decor"):
		_enregistrer.call_deferred(noeud)

func _enregistrer(noeud: Node) -> void:
	if not is_instance_valid(noeud): return
	if noeud is GeometryInstance3D and not noeud is GPUParticles3D:
		if not noeud.has_meta("portee_graphique_originale"):
			noeud.set_meta("portee_graphique_originale", noeud.visibility_range_end)
			noeud.set_meta("marge_graphique_originale", noeud.visibility_range_end_margin)
			noeud.set_meta("fondu_graphique_original", noeud.visibility_range_fade_mode)
			details.append(noeud)
		_regler_detail(noeud)
	for enfant in noeud.get_children():
		_enregistrer(enfant)

func appliquer(nouvel_indice: int) -> void:
	indice = clampi(nouvel_indice, 0, profils.size() - 1)
	# Seule la 3D baisse en résolution : les textes de l'interface restent nets.
	get_viewport().scaling_3d_scale = profils[indice].resolution_3d
	details = details.filter(func(detail): return is_instance_valid(detail))
	for detail in details: _regler_detail(detail)

func _regler_detail(detail: GeometryInstance3D) -> void:
	var profil := profils[indice]
	var origine: float = detail.get_meta("portee_graphique_originale")
	detail.visibility_range_end = origine if profil.distance_details == 0.0 else (minf(origine, profil.distance_details) if origine > 0.0 else profil.distance_details)
	detail.visibility_range_end_margin = detail.get_meta("marge_graphique_originale") if profil.distance_details == 0.0 else profil.marge_distance
	# La marge crée une hystérésis : pas de clignotement à la limite de distance.
	detail.visibility_range_fade_mode = detail.get_meta("fondu_graphique_original") if profil.distance_details == 0.0 else GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
