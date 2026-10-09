extends Node

@export_range(-40.0, 0.0, 1.0) var volume_clic_db := -5.0
@export_range(-40.0, 0.0, 1.0) var volume_booster_db := -16.0
var clic: AudioStreamPlayer
var booster: AudioStreamPlayer
var derniere_image_clic := -1
var attenuation_musique: AudioEffectAmplify
var fondu_musique: Tween
@export_range(-40.0, 0.0, 1.0) var volume_succes_db := -24.0

func jouer_succes() -> void:
	var son := _creer_lecteur(preload("res://assets/sounds/design/menus/maximize_004.ogg"))
	son.volume_db = volume_succes_db
	son.finished.connect(son.queue_free)
	son.play()

func celebrer_legendaire() -> void:
	# Le lecteur appartient à l'autoload : choisir une carte ne coupe pas sa résonance.
	var son := _creer_lecteur(preload("res://assets/sounds/interfaces/revelation_legendaire.wav"))
	son.volume_db = -14.0
	son.finished.connect(son.queue_free)
	son.play()

func preparer_carte(puissance: int) -> void:
	var souffle := _creer_lecteur(preload("res://assets/sounds/design/mouvements/swish-3.wav"))
	souffle.volume_db = -28.0 + puissance * 2.0
	souffle.pitch_scale = 0.9 + puissance * 0.1
	souffle.finished.connect(souffle.queue_free)
	souffle.play()
	if puissance < 2:
		return
	if attenuation_musique == null:
		# Un effet séparé préserve le volume choisi par le joueur dans les options.
		var bus := AudioServer.get_bus_index("Musique")
		if bus < 0:
			return
		attenuation_musique = AudioEffectAmplify.new()
		AudioServer.add_bus_effect(bus, attenuation_musique)
	if fondu_musique:
		fondu_musique.kill()
	fondu_musique = create_tween()
	fondu_musique.tween_property(attenuation_musique, "volume_db", -4.0 if puissance == 2 else -7.0, 0.15)
	# Cette restauration reste active même si on quitte le menu pendant l'animation.
	fondu_musique.tween_interval(0.6)
	fondu_musique.tween_property(attenuation_musique, "volume_db", 0.0, 0.9)

func _ready() -> void:
	# L'autoload survit aux changements de scène et aux pauses des menus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	clic = _creer_lecteur(preload("res://assets/sounds/interfaces/clic_bouton.ogg"))
	booster = _creer_lecteur(preload("res://assets/sounds/interfaces/ouverture_booster.wav"))
	get_tree().node_added.connect(_brancher_bouton)
	_brancher_arbre(get_tree().root)

func _creer_lecteur(son: AudioStream) -> AudioStreamPlayer:
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = son
	lecteur.bus = "Effets"
	add_child(lecteur)
	return lecteur

func _brancher_arbre(noeud: Node) -> void:
	_brancher_bouton(noeud)
	for enfant in noeud.get_children():
		_brancher_arbre(enfant)

func _brancher_bouton(noeud: Node) -> void:
	if noeud is BaseButton:
		# pressed couvre la souris et la validation manette, sans son au simple survol.
		if not noeud.pressed.is_connected(jouer_clic):
			noeud.pressed.connect(jouer_clic)
	elif noeud is Control:
		# Les cartes et certaines vignettes sont des Control avec leur propre signal.
		for nom in ["selected", "selectionne"]:
			if noeud.has_signal(nom) and not noeud.is_connected(nom, jouer_clic):
				noeud.connect(nom, jouer_clic)

func jouer_clic() -> void:
	# Une activation peut traverser plusieurs boutons/signaux : ne jouer qu'un clic.
	var image := Engine.get_process_frames()
	if image == derniere_image_clic:
		return
	derniere_image_clic = image
	clic.volume_db = volume_clic_db
	clic.play()

func ouvrir_booster() -> void:
	booster.volume_db = volume_booster_db
	booster.play()

func annoncer_vague(evenement: String) -> void:
	# Réutiliser le souffle existant, sans ajouter une nouvelle musique.
	var son := _creer_lecteur(preload("res://assets/sounds/design/mouvements/swish-3.wav"))
	son.volume_db = -24.0
	son.pitch_scale = {"doree": 1.25, "blackout": 0.7, "double_horde": 0.85, "mutation": 0.95}.get(evenement, 1.1)
	son.finished.connect(son.queue_free)
	son.play()
