extends "res://scenes/interfaces/menus/bilan/rapport_intervention.gd"

const STATISTIQUES = preload("res://scenes/jeu/statistiques_classiques.gd")
@export var victoire := false

func preparer_bilan() -> void:
	bilan = get_tree().get_meta(STATISTIQUES.CLE_BILAN, {}).duplicate(true)
	var disponible := not bilan.is_empty() and bool(bilan.get("victoire", false)) == victoire
	if not disponible: bilan = STATISTIQUES.bilan_vide()
	lignes = [
		{"id": "salles_liberees", "titre": "Salles libérées", "icone": ICONE_COMBAT},
		{"id": "etage_atteint", "titre": "Étage atteint", "icone": ICONE_COMBAT},
		{"id": "ennemis_elimines", "titre": "Ennemis éliminés", "icone": ICONE_COMBAT},
		{"id": "temps", "titre": "Temps actif", "icone": ICONE_TEMPS},
		{"id": "victimes_liberees", "titre": "Victimes libérées", "icone": ICONE_VICTIMES},
		{"id": "victimes_perdues", "titre": "Victimes perdues", "icone": ICONE_VICTIMES, "note": "Captives et escorte"},
		{"id": "victimes_escorte", "titre": "Dans l’escorte", "icone": ICONE_VICTIMES},
		{"id": "degats_infliges", "titre": "Dégâts infligés", "icone": ICONE_COMBAT},
		{"id": "degats_recus", "titre": "PV perdus", "icone": ICONE_VIE},
		{"id": "points_depenses", "titre": "Points dépensés", "icone": ICONE_VICTIMES},
		{"id": "ameliorations_choisies", "titre": "Cartes choisies", "icone": "res://assets/textures/interfaces/hud/icone_bonus.svg"}
	]
	$Panneau/Marge/Contenu/Surtitre.text = "MODE CLASSIQUE · INTERVENTION TERMINÉE" if victoire else "MODE CLASSIQUE · VOUS ÊTES MORT"
	$Panneau/Marge/Contenu/Titre.text = "Immeuble libéré" if victoire else "Rapport d’intervention"
	%Progression.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if disponible:
		%Progression.text = "Salle %d sur %d · Pauses et transitions exclues du temps actif" % [bilan.salle_atteinte, bilan.nombre_salles]
	else:
		%Progression.text = "Aucun bilan de partie disponible dans cet aperçu."
	var information: Label = $Panneau/Marge/Contenu/Pied/Information
	information.text = "Statistiques de cette intervention."
	information.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if bilan.get("partiel", false):
		information.text = "Ancienne sauvegarde : statistiques de combat depuis la reprise."
