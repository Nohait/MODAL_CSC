extends "res://scenes/interfaces/menus/bilan/rapport_intervention.gd"

const LIGNES = [
	{"id": "vagues_terminees", "titre": "Vagues terminées", "icone": ICONE_COMBAT},
	{"id": "ennemis_elimines", "titre": "Ennemis éliminés", "icone": ICONE_COMBAT},
	{"id": "pieces_collectees", "titre": "Pièces ramassées", "icone": ICONE_PIECE},
	{"id": "temps", "titre": "Temps actif", "icone": ICONE_TEMPS},
	{"id": "victimes_liberees", "titre": "Victimes libérées", "icone": ICONE_VICTIMES},
	{"id": "victimes_perdues", "titre": "Victimes perdues", "icone": ICONE_VICTIMES},
	{"id": "victimes_abritees", "titre": "Dans le camion", "icone": ICONE_VICTIMES},
	{"id": "victimes_escorte", "titre": "Dans l’escorte", "icone": ICONE_VICTIMES},
	{"id": "degats_infliges", "titre": "Dégâts infligés", "icone": ICONE_COMBAT},
	{"id": "degats_recus", "titre": "PV perdus", "icone": ICONE_VIE},
	{"id": "points_depenses", "titre": "Points dépensés", "icone": ICONE_VICTIMES},
	{"id": "ameliorations_choisies", "titre": "Améliorations choisies", "icone": "res://assets/textures/interfaces/hud/icone_bonus.svg"}
]

func preparer_bilan() -> void:
	bilan = StatistiquesZombie.dernier_bilan.duplicate(true)
	if bilan.is_empty(): bilan = StatistiquesZombie.bilan_vide()
	lignes = LIGNES
	records = StatistiquesZombie.records
	ids_records = StatistiquesZombie.RECORDS
	%Progression.text = "Vague %d atteinte · Les pauses sont exclues du temps actif" % bilan.vague_atteinte

func nouvelle_partie() -> void:
	changer_scene("res://scenes/modes/zombie/mode_zombie.tscn")
