extends Node3D

const NIVEAU = preload("res://scenes/jeu/main.tscn")
const GESTIONNAIRE = preload("res://scenes/modes/zombie/gestion/vagues_zombie.gd")
const DEBUG = preload("res://scenes/modes/zombie/interfaces/debug/debug_zombie.gd")
@export var difficulte: DifficulteZombie = preload("res://scenes/modes/zombie/equilibrage/difficulte_zombie.tres")
@export var map: PackedScene
@export_group("Musique adaptative")
@export var playlist_musicale: Array[MorceauMusicalZombie] = [
	preload("res://scenes/modes/zombie/audio/morceaux/assault.tres"),
	preload("res://scenes/modes/zombie/audio/morceaux/unfed.tres"),
	preload("res://scenes/modes/zombie/audio/morceaux/sin_town.tres"),
	preload("res://scenes/modes/zombie/audio/morceaux/rescue_mission.tres")
]
@export_group("Progression et builds")
@export var synergies_zombie: Array[Synergie] = [preload("res://scenes/systemes/ameliorations/synergies/belier.tres"), preload("res://scenes/systemes/ameliorations/synergies/samu.tres")]
@export var paliers_arene: Array[PalierArene] = [preload("res://scenes/modes/zombie/evenements/paliers/fenetre.tres"), preload("res://scenes/modes/zombie/evenements/paliers/ascenseur.tres"), preload("res://scenes/modes/zombie/evenements/paliers/lumiere.tres"), preload("res://scenes/modes/zombie/evenements/paliers/hall_explosion_voiture.tres")]
const PARTIE = preload("res://scenes/modes/zombie/gestion/partie_zombie.gd")

@export_group("Ã‰clairage")
@export var ambiance: Environment = preload("res://assets/materiaux/hall_incendie/ambiance_hall.tres")
# Une faible lumière générale garde les ombres lisibles sans effacer les lampes locales.
@export_range(0.0, 1.0, 0.01) var energie_soleil := 0.16

func _ready() -> void:
	# Reprendre main sans copier le joueur, le dÃ©cor, les lumiÃ¨res ni leurs scripts.
	var niveau = NIVEAU.instantiate()
	# Le mode zombie garde ses rÃ©glages lumineux sans modifier ceux du jeu classique.
	niveau.get_node("Eclairage/Ambiance").environment = ambiance
	niveau.get_node("Eclairage/Soleil").light_energy = energie_soleil
	# SpÃ©cialiser les systÃ¨mes communs avant leur initialisation.
	niveau.get_node("VictimManager").set_script(preload("res://scenes/modes/zombie/victimes/escorte_zombie.gd"))
	niveau.get_node("UpgradeManager").set_script(preload("res://scenes/modes/zombie/interfaces/boutique/boutique_zombie.gd"))
	niveau.get_node("UpgradeManager").mode_jeu = "zombie"
	niveau.get_node("UpgradeManager").synergies = synergies_zombie
	niveau.get_node("UpgradeManager/DefiManager").set_script(preload("res://scenes/modes/zombie/interfaces/boutique/defis_zombie.gd"))
	niveau.set_script(PARTIE)
	var vagues = niveau.get_node("Salles/RoomManager")
	vagues.set_script(GESTIONNAIRE)
	vagues.difficulte = difficulte
	# Le catalogue conserve un chemin ; le chargement a déjà mis le Hall en cache.
	var choix = get_tree().get_meta("map_zombie", map if map != null else "res://scenes/modes/zombie/maps/hall.tscn")
	vagues.map = get_tree().get_meta("map_zombie_chargee") if get_tree().has_meta("map_zombie_chargee") else null
	if vagues.map == null or (choix is String and vagues.map.resource_path != choix):
		vagues.map = load(choix) if choix is String else choix
	if get_tree().has_meta("map_zombie_chargee"): get_tree().remove_meta("map_zombie_chargee")
	niveau.get_node("MenuDebug").set_script(DEBUG)
	niveau.add_child(preload("res://scenes/modes/zombie/evenements/evenements_vague.tscn").instantiate())
	# La musique appartient Ã  cette partie : quitter le mode arrÃªte aussi les morceaux.
	niveau.add_child(preload("res://scenes/modes/zombie/audio/musique_zombie.tscn").instantiate())
	var ambiance_arene := Node.new()
	ambiance_arene.name = "AmbianceArene"
	ambiance_arene.set_script(preload("res://scenes/modes/zombie/audio/environnement/ambiance_arene.gd"))
	niveau.add_child(ambiance_arene)
	var sons_vagues := preload("res://scenes/modes/zombie/audio/feedback_vagues.tscn").instantiate()
	niveau.add_child(sons_vagues)
	var musique_adaptative := Node.new()
	musique_adaptative.set_script(preload("res://scenes/modes/zombie/audio/couches_dynamiques.gd"))
	musique_adaptative.name = "CouchesMusicales"
	musique_adaptative.morceaux = playlist_musicale
	niveau.add_child(musique_adaptative)
	niveau.add_child(preload("res://scenes/modes/zombie/evenements/victoire_boss.tscn").instantiate())
	var arene := Node.new()
	arene.name = "ArenaEventManager"
	arene.set_script(preload("res://scenes/modes/zombie/evenements/arena_event_manager.gd"))
	arene.paliers = paliers_arene
	arene.palier_declenche.connect(func(palier): niveau.get_node("UpgradeManager").retours_bonus._afficher_message(palier.titre, preload("res://assets/textures/interfaces/ameliorations/pictogrammes/intervention_eclair.svg")))
	niveau.add_child(arene)
	var score := preload("res://scenes/modes/zombie/gestion/score_combo_manager.tscn").instantiate()
	niveau.add_child(score)
	var succes := Node.new()
	succes.name = "SuccesZombie"
	succes.set_script(preload("res://scenes/modes/zombie/gestion/succes_zombie.gd"))
	niveau.add_child(succes)
	var point_reprise := preload("res://scenes/modes/zombie/sauvegarde/point_reprise_zombie.gd").new()
	point_reprise.name = "PointRepriseZombie"
	niveau.add_child(point_reprise)
	add_child(niveau)
