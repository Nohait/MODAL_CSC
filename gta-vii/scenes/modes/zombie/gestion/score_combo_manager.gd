extends Node

signal combo_important(multiplieur: int)
@export_range(1.0, 20.0, 0.5) var duree_combo := 5.0
@export_range(1, 20) var eliminations_par_palier := 5
@export_range(1, 10) var multiplicateur_maximum := 5
@export_range(1, 10) var seuil_sonore := 3
@export_range(1, 1000) var points_elimination := 100
@export_range(-40.0, 0.0, 1.0) var volume_db := -24.0
@onready var vagues = get_node("../Salles/RoomManager")
var score := 0
var serie := 0
var restant := 0.0
var dernier_palier := 1

func _ready() -> void:
	CatalogueEnnemis.ennemi_enregistre.connect(_suivre)
	vagues.salle_terminee.connect(func(_salle): _rompre())
	get_parent().get_node("player").degats_recus.connect(func(_quantite): _rompre())

func _suivre(ennemi: Node3D) -> void:
	if not get_parent().is_ancestor_of(ennemi) or ennemi.is_in_group("flaque"): return
	if ennemi.has_signal("died"): ennemi.died.connect(_eliminer.bind(ennemi), CONNECT_ONE_SHOT)

func multiplicateur() -> int:
	return mini(multiplicateur_maximum, 1 + serie / eliminations_par_palier)

func _eliminer(ennemi: Node3D) -> void:
	serie += 1
	restant = duree_combo
	var palier := multiplicateur()
	score += points_elimination * int(ennemi.get_meta("valeur_pieces", 1)) * palier
	if palier > dernier_palier and palier >= seuil_sonore:
		combo_important.emit(palier)
		var son := AudioStreamPlayer.new()
		son.stream = preload("res://assets/sounds/design/menus/maximize_004.ogg")
		son.bus = "Effets"
		son.volume_db = volume_db
		son.pitch_scale = 1.0 + palier * 0.06
		add_child(son)
		son.finished.connect(son.queue_free)
		son.play()
	dernier_palier = palier

func _physics_process(delta: float) -> void:
	if restant <= 0.0: return
	restant = maxf(0.0, restant - delta)
	if restant == 0.0: _rompre()

func _rompre() -> void:
	serie = 0
	restant = 0.0
	dernier_palier = 1

