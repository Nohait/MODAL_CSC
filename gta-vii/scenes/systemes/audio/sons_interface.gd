extends Node

@export_range(-40.0, 0.0, 1.0) var volume_clic_db := -18.0
@export_range(-40.0, 0.0, 1.0) var volume_booster_db := -16.0
var clic: AudioStreamPlayer
var booster: AudioStreamPlayer
var derniere_image_clic := -1

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
