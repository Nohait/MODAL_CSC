extends Node

@export var vagues: AudioStream
@export var danger: AudioStream
@export var obscurite: AudioStream
@export var boutique: AudioStream
@export_range(-40.0, 0.0, 1.0) var volume_db := -18.0
@export_range(0.1, 5.0, 0.1) var duree_fondu := 1.5

@onready var gestionnaire = get_parent().get_node("Salles/RoomManager")
@onready var lecteurs: Array[AudioStreamPlayer] = [$PisteA, $PisteB]
var piste_actuelle: AudioStream
var lecteur_actuel := 0
var fondu: Tween
var phase_precedente := ""
# Une position en secondes par morceau, conservée pendant cette partie.
var positions_lecture: Dictionary = {}

func _ready() -> void:
	# La lecture doit continuer dans la boutique, qui met le jeu en pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for piste in [vagues, danger, obscurite, boutique]:
		if piste is AudioStreamMP3:
			piste.loop = true

func _process(_delta: float) -> void:
	# Attendre la fin de la course d'entrée avant de lancer la première musique.
	if gestionnaire.vague_actuelle == 0:
		return
	var phase: String = gestionnaire.phase
	var changement_phase := phase != phase_precedente
	phase_precedente = phase
	if phase in ["avant_boutique", "boutique"]:
		# La pause de victoire sert au fondu : la boutique est déjà calme à son ouverture.
		_changer_piste(boutique, maxf(duree_fondu, gestionnaire.pause_restante))
		return
	if phase == "apres_boutique":
		if changement_phase:
			# Retirer progressivement la boutique pendant le compte à rebours suivant.
			if fondu: fondu.kill()
			for lecteur in lecteurs:
				if lecteur != lecteurs[lecteur_actuel]: _memoriser_et_arreter(lecteur)
			fondu = create_tween()
			fondu.tween_property(lecteurs[lecteur_actuel], "volume_db", -45.0, maxf(0.1, gestionnaire.pause_restante))
		return
	var composition: CompositionVague = gestionnaire.composition_actuelle
	if composition == null:
		return
	if not get_parent().get_node("CouchesMusicales").couches.is_empty():
		if fondu: fondu.kill()
		for lecteur in lecteurs:
			lecteur.volume_db = move_toward(lecteur.volume_db, -60.0, _delta * 30.0)
			if lecteur.volume_db <= -60.0: _memoriser_et_arreter(lecteur)
		piste_actuelle = null
		return
	if composition == gestionnaire.difficulte.composition_boss or composition.evenement == "double_horde":
		_changer_piste(danger)
	elif composition.evenement in ["blackout", "brouillard"]:
		_changer_piste(obscurite)
	else:
		_changer_piste(vagues)

func _changer_piste(piste: AudioStream, duree: float = -1.0) -> void:
	# Ne pas redémarrer le morceau à chaque frame ni entre deux vagues similaires.
	if piste == null or piste == piste_actuelle:
		return
	if fondu:
		fondu.kill()
	piste_actuelle = piste
	var ancien := lecteurs[lecteur_actuel]
	lecteur_actuel = 1 - lecteur_actuel
	var nouveau := lecteurs[lecteur_actuel]
	# Si on revient pendant un fondu, le morceau joue encore : le laisser continuer.
	if nouveau.stream != piste or not nouveau.playing:
		_memoriser_et_arreter(nouveau)
		nouveau.stream = piste
		nouveau.volume_db = -60.0
		var position: float = positions_lecture.get(piste, 0.0)
		# Une position en fin de morceau revient au début de la boucle.
		var longueur := piste.get_length()
		if longueur > 0.0: position = fposmod(position, longueur)
		nouveau.play(position)
	var temps := duree_fondu if duree < 0.0 else duree
	fondu = create_tween().set_parallel(true)
	# Les deux volumes évoluent ensemble : l'ancien baisse pendant que le nouveau monte.
	fondu.tween_property(ancien, "volume_db", -60.0, temps)
	fondu.tween_property(nouveau, "volume_db", volume_db, temps)
	# chain attend la fin des deux fondus avant d'arrêter l'ancien lecteur.
	fondu.chain().tween_callback(_memoriser_et_arreter.bind(ancien))


func _memoriser_et_arreter(lecteur: AudioStreamPlayer) -> void:
	if not lecteur.playing or lecteur.stream == null:
		return
	# Lire la position AVANT stop(), qui remet la tête de lecture à zéro.
	positions_lecture[lecteur.stream] = lecteur.get_playback_position()
	lecteur.stop()
