extends Node

@export var son_debut: AudioStream = preload("res://assets/sounds/design/menus/maximize_004.ogg")
@export var son_fin: AudioStream = preload("res://assets/sounds/design/impact/impactBell_heavy_000.ogg")
@export var son_elite: AudioStream = preload("res://assets/sounds/design/magie/spell_fire_03.ogg")
@export var son_boss: AudioStream = preload("res://assets/sounds/design/explosion3.ogg")
@export_range(-40.0, 0.0, 1.0) var volume_db := -22.0
@export_range(0.0, 10.0, 0.1) var intervalle_elites := 3.0
@onready var vagues = get_node("../Salles/RoomManager")
var derniere_elite := -100.0

func _ready() -> void:
	vagues.salle_commencee.connect(_debut)
	vagues.salle_terminee.connect(_fin)
	CatalogueEnnemis.elite_importante_apparue.connect(_elite)

func _debut(_salle: Node) -> void:
	jouer(son_boss if vagues.composition_actuelle == vagues.difficulte.composition_boss else son_debut)

func _fin(_salle: Node) -> void:
	jouer(son_fin)

func _elite(ennemi: Node3D) -> void:
	if not get_parent().is_ancestor_of(ennemi): return
	var temps := Time.get_ticks_msec() / 1000.0
	if temps - derniere_elite < intervalle_elites: return
	derniere_elite = temps
	jouer(son_elite)

func jouer(son: AudioStream) -> void:
	if son == null: return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = son
	lecteur.bus = "Effets"
	lecteur.volume_db = volume_db
	add_child(lecteur)
	lecteur.finished.connect(lecteur.queue_free)
	lecteur.play()
