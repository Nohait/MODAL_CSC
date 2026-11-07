extends "res://scenes/systemes/audio/playlist_adaptative.gd"

@export_group("Progression classique")
## Nombre d'ennemis équivalent garanti par étage pour enrichir l'arrangement.
@export var intensite_par_etage: Array[int] = [0, 4, 8]
@export_range(1, 10, 1) var paliers_par_etage := 5
@export_group("Boutique")
@export_range(-40.0, 0.0, 1.0) var volume_boutique_db := -18.0
@onready var gestion = get_node("../Salles/RoomManager")
@onready var joueur = get_node("../player")
@onready var boutique: AudioStreamPlayer = $Boutique

func _ready() -> void:
	if get_parent().get_node("UpgradeManager").mode_jeu != "classique":
		set_process(false)
		return
	if get_parent().get("session_tutoriel") == true:
		preload("res://scenes/modes/tutoriel/commun/musique_tutoriel.gd").installer(get_tree())
		set_process(false)
		return
	super._ready()
	var piste_boutique := boutique.stream.duplicate() as AudioStreamMP3
	piste_boutique.loop = true
	boutique.stream = piste_boutique

func _contexte_musical() -> Dictionary:
	var salle: Node = gestion.salle_actuelle
	if not is_instance_valid(salle): return {}
	var etage: int = maxi(1, salle.etage)
	var intensite := 0
	if not intensite_par_etage.is_empty():
		intensite = intensite_par_etage[mini(etage - 1, intensite_par_etage.size() - 1)]
	return {
		"combat": gestion.initialized and not gestion.transition_en_cours and not salle.liberee and not joueur.est_mort and not get_tree().paused,
		"salle": salle,
		"palier": 1 + (etage - 1) * paliers_par_etage,
		"intensite_minimale": intensite
	}

func _process(delta: float) -> void:
	super._process(delta)
	var calme: bool = gestion.initialized and is_instance_valid(gestion.salle_actuelle) \
		and gestion.salle_actuelle.liberee and not gestion.transition_en_cours and not joueur.est_mort
	if calme and not boutique.playing:
		boutique.play()
	if calme: boutique.stream_paused = false
	boutique.volume_db = move_toward(boutique.volume_db, volume_boutique_db if calme else -60.0, 60.0 * delta / duree_fondu)
	if not calme and boutique.volume_db <= -60.0:
		boutique.stream_paused = true
