extends Node

@export_range(0, 3, 1) var boosters_rares_offerts := 1
@export_range(-30.0, 0.0, 1.0) var baisse_musique_db := -14.0
@export_range(0.0, 2.0, 0.1) var marge_avant_boutique := 0.3
var temps_restant := 0.0
var boss_vaincu := false
@onready var vagues = get_node("../Salles/RoomManager")
@onready var boutique = get_node("../UpgradeManager")

func _ready() -> void:
	vagues.salle_commencee.connect(func(_salle):
		boss_vaincu = false
		temps_restant = 0.0)
	vagues.salle_terminee.connect(_recompenser)

func suivre(boss: Node3D) -> void:
	# Seuls les boss du calendrier de vague rapportent ce cadeau, pas ceux du debug.
	boss.mort_mise_en_scene.connect(_mort, CONNECT_ONE_SHOT)

func _mort(effet: Node3D) -> void:
	boss_vaincu = true
	temps_restant = effet.duree_chute + effet.attente_au_sol + effet.duree_dissolution
	get_node("../CouchesMusicales").accalmie(temps_restant, baisse_musique_db)

func _process(delta: float) -> void:
	temps_restant = maxf(0.0, temps_restant - delta)

func _recompenser(_salle: Node3D) -> void:
	if not boss_vaincu: return
	boss_vaincu = false
	# Le cadeau attend aussi la fin des renforts ; aucun point d'escorte n'est dépensé.
	boutique.defis.boosters_rares_gratuits += boosters_rares_offerts
	if boosters_rares_offerts > 0:
		boutique.defis.bilan += "Boss vaincu : %d booster(s) rare(s) offert(s). " % boosters_rares_offerts
