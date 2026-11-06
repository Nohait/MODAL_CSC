extends Node

var effets: Node

func _ready() -> void:
	effets.joueur.dash_commence.connect(_dash)

func soigner_liberation(victime: Node3D) -> void:
	if effets.valeur("point_suture") <= 0 or victime.est_morte or victime.vie <= 0: return
	victime.vie += maxf(0.0, victime.vie_max - victime.vie) * clampf(effets.valeur("point_suture") / 100.0, 0.0, 1.0)
	victime.actualiser_barre_vie()

func _dash(_direction: Vector3) -> void:
	if effets.valeur("issue_secours") <= 0.0: return
	var escorte = effets.gestion.escorte
	if is_instance_valid(escorte.cible_deplacement): return
	var carte: Amelioration = effets.gestion.catalogue_ameliorations.trouver(&"issue_secours")
	# Le signal précède le déplacement : toutes les distances sont mesurées au départ.
	for victime in escorte.freed_victims:
		if not is_instance_valid(victime) or victime.est_morte or not victime.is_freed: continue
		if victime.global_position.distance_to(effets.joueur.global_position) > carte.rayon: continue
		victime.accelerer_escorte(1.0 + carte.valeur / 100.0, carte.duree_effet)
