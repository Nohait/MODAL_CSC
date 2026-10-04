extends Node3D

const NIVEAU = preload("res://scenes/jeu/main.tscn")
const GESTIONNAIRE = preload("res://scenes/modes/zombie/gestion/vagues_zombie.gd")
const DEBUG = preload("res://scenes/modes/zombie/interfaces/debug/debug_zombie.gd")
@export var difficulte: DifficulteZombie = preload("res://scenes/modes/zombie/equilibrage/difficulte_zombie.tres")
@export var map: PackedScene = preload("res://scenes/modes/zombie/maps/map_test.tscn")
const PARTIE = preload("res://scenes/modes/zombie/gestion/partie_zombie.gd")

@export_group("Éclairage")
@export var ambiance: Environment = preload("res://assets/materiaux/hall_incendie/ambiance_hall.tres")
@export_range(0.0, 1.0, 0.05) var energie_soleil := 0.3

func _ready() -> void:
	# Reprendre main sans copier le joueur, le décor, les lumières ni leurs scripts.
	var niveau = NIVEAU.instantiate()
	# Le mode zombie garde ses réglages lumineux sans modifier ceux du jeu classique.
	niveau.get_node("Eclairage/Ambiance").environment = ambiance
	niveau.get_node("Eclairage/Soleil").light_energy = energie_soleil
	# Spécialiser les systèmes communs avant leur initialisation.
	niveau.get_node("VictimManager").set_script(preload("res://scenes/modes/zombie/victimes/escorte_zombie.gd"))
	niveau.get_node("UpgradeManager").set_script(preload("res://scenes/modes/zombie/interfaces/boutique/boutique_zombie.gd"))
	niveau.get_node("UpgradeManager").mode_jeu = "zombie"
	niveau.get_node("UpgradeManager/DefiManager").set_script(preload("res://scenes/modes/zombie/interfaces/boutique/defis_zombie.gd"))
	niveau.set_script(PARTIE)
	var vagues = niveau.get_node("Salles/RoomManager")
	vagues.set_script(GESTIONNAIRE)
	vagues.difficulte = difficulte
	vagues.map = get_tree().get_meta("map_zombie", map)
	niveau.get_node("MenuDebug").set_script(DEBUG)
	add_child(niveau)
