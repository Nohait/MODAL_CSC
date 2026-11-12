extends Node

@export var morceau: AudioStream
@export_range(-40.0, 0.0, 1.0) var volume_db := -12.0
@export_range(0.2, 5.0, 0.1) var duree_entree := 1.5
@export_range(0.2, 8.0, 0.1) var duree_boucle := 2.0

var lecteurs: Array[AudioStreamPlayer] = []
var courant := 0
var fondu: Tween
var arret_en_cours := false

func _ready() -> void:
	if morceau == null: return
	morceau = morceau.duplicate()
	if morceau is AudioStreamMP3 or morceau is AudioStreamOggVorbis:
		morceau.loop = false
	for i in 2:
		var lecteur := AudioStreamPlayer.new()
		lecteur.bus = "Musique"
		lecteur.stream = morceau
		lecteur.volume_db = -80.0
		add_child(lecteur)
		lecteurs.append(lecteur)
	lecteurs[0].play()
	fondu = create_tween()
	fondu.tween_property(lecteurs[0], "volume_db", volume_db, duree_entree)

func _process(_delta: float) -> void:
	if arret_en_cours or lecteurs.is_empty(): return
	var lecteur := lecteurs[courant]
	var duree := morceau.get_length()
	if duree <= 0.0 or not lecteur.playing: return
	if lecteur.get_playback_position() < duree - duree_boucle: return
	var suivant := 1 - courant
	lecteurs[suivant].volume_db = -80.0
	lecteurs[suivant].play()
	if fondu: fondu.kill()
	fondu = create_tween().set_parallel(true)
	fondu.tween_property(lecteur, "volume_db", -80.0, duree_boucle)
	fondu.tween_property(lecteurs[suivant], "volume_db", volume_db, duree_boucle)
	courant = suivant

func arreter_en_fondu(duree: float) -> void:
	arret_en_cours = true
	if fondu: fondu.kill()
	fondu = create_tween().set_parallel(true)
	for lecteur in lecteurs:
		if lecteur.playing: fondu.tween_property(lecteur, "volume_db", -80.0, duree)

func reprendre() -> void:
	if lecteurs.is_empty(): return
	arret_en_cours = false
	if fondu: fondu.kill()
	if not lecteurs[courant].playing: lecteurs[courant].play()
	fondu = create_tween()
	fondu.tween_property(lecteurs[courant], "volume_db", volume_db, duree_entree)
