extends Node

@onready var vagues = get_node("../Salles/RoomManager")
var eliminations := 0
var elites := 0
var boss := 0
var vagues_intactes := 0
var touche := false

func _ready() -> void:
	CatalogueEnnemis.ennemi_enregistre.connect(_suivre)
	vagues.salle_commencee.connect(func(_salle): touche = false)
	vagues.salle_terminee.connect(_fin)
	get_parent().get_node("player").degats_recus.connect(func(_quantite): touche = true)
	get_parent().get_node("UpgradeManager").synergy_manager.synergie_decouverte.connect(_synergie)

func _suivre(ennemi: Node3D) -> void:
	if not get_parent().is_ancestor_of(ennemi) or ennemi.is_in_group("flaque"): return
	if ennemi.has_signal("died"): ennemi.died.connect(_mort.bind(ennemi), CONNECT_ONE_SHOT)

func _mort(ennemi: Node3D) -> void:
	eliminations += 1
	if ennemi.has_node("Elite"): elites += 1
	if ennemi.scene_file_path.contains("mini_boss"): boss += 1
	SuccesManager.progresser("eliminations", eliminations)
	SuccesManager.progresser("elites", elites)
	SuccesManager.progresser("boss", boss)

func _fin(_salle: Node) -> void:
	vagues_intactes = 0 if touche else vagues_intactes + 1
	SuccesManager.progresser("vague", vagues.vague_actuelle)
	SuccesManager.progresser("vagues_intactes", vagues_intactes)

func _synergie(_definition: Synergie) -> void:
	var gestionnaire = get_parent().get_node("UpgradeManager").synergy_manager
	SuccesManager.progresser("synergies", gestionnaire.decouvertes.size())
