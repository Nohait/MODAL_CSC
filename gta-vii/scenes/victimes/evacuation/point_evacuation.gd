extends Node3D

## Gestionnaire de la file, à sélectionner dans l'Inspecteur de l'instance.
@export var victim_manager: Node
# $chemin récupère un nœud de la scène. Ces références évitent de réécrire les chemins.
@onready var menu: Control = $Interface/Menu
@onready var liste: VBoxContainer = $Interface/Menu/Centre/Panneau/Marge/Contenu/Defilement/Liste
@onready var bilan: Label = $Interface/Menu/Centre/Panneau/Marge/Contenu/Bilan
@onready var fermer: Button = $Interface/Menu/Centre/Panneau/Marge/Contenu/Fermer
@onready var indication: Label3D = $Indication
var joueur_proche: Node3D = null
# Mémoriser l'état du curseur pour le restaurer exactement à la fermeture.
var souris_avant: int


func _ready() -> void:
	# connect relie chaque événement à la fonction qui doit y répondre.
	$Detection.body_entered.connect(_entree)
	$Detection.body_exited.connect(_sortie)
	fermer.pressed.connect(fermer_menu)
	victim_manager.escort_changed.connect(actualiser_liste)
	# Utiliser le libellé de la touche réellement associée à l'action.
	var touches := InputMap.action_get_events("interact")
	if not touches.is_empty():
		indication.text = "[%s] Évacuer" % touches[0].as_text()


func _entree(body: Node3D) -> void:
	# La zone peut détecter d'autres corps ; seul le groupe player nous intéresse.
	if body.is_in_group("player"):
		joueur_proche = body
		indication.show()


func _sortie(body: Node3D) -> void:
	# null signifie qu'aucun joueur n'est actuellement à portée d'interaction.
	if body == joueur_proche:
		joueur_proche = null
		indication.hide()


func _unhandled_input(event: InputEvent) -> void:
	# Menu ouvert : Échap ferme. Menu fermé : l'action interact ouvre à proximité.
	# is_echo élimine les répétitions de touche ; handled arrête cet événement.
	if menu.visible:
		if event.is_action_pressed("ui_cancel"):
			fermer_menu()
			get_viewport().set_input_as_handled()
	elif not get_tree().paused and is_instance_valid(joueur_proche):
		if event.is_action_pressed("interact") and not event.is_echo():
			ouvrir_menu()
			get_viewport().set_input_as_handled()


func ouvrir_menu() -> void:
	# Le menu continue de fonctionner pendant la pause grâce à Process Mode = Always.
	souris_avant = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.show()
	actualiser_liste()
	get_tree().paused = true
	fermer.grab_focus()
	# Le focus permet aussi d'utiliser le menu au clavier (Tab, Entrée, Échap).


func fermer_menu() -> void:
	# Masquer l'interface ne suffit pas : il faut aussi reprendre la simulation.
	menu.hide()
	Input.mouse_mode = souris_avant
	get_tree().paused = false


func actualiser_liste() -> void:
	# Supprimer les anciens boutons avant de reconstruire la liste actuelle.
	for enfant in liste.get_children():
		# Retirer tout de suite du conteneur, puis détruire en fin d'image.
		liste.remove_child(enfant)
		enfant.queue_free()
	bilan.text = "Victimes évacuées : %d" % victim_manager.evacuated_count
	# %d insère un entier. nombre sert à numéroter uniquement les victimes valides.
	var nombre := 0
	for victime in victim_manager.freed_victims:
		if not is_instance_valid(victime) or victime.is_queued_for_deletion():
			# on saute cette victime et passe au tour suivant, sans quitter la fonction.
			continue
		nombre += 1
		var bouton := Button.new()
		# new crée un nœud comme dans l'éditeur. %s insère le nom et le type de victime.
		bouton.text = "Évacuer %s — position %d" % [victime.get_nom_affiche(), nombre]
		bouton.custom_minimum_size.y = 44
		# bind mémorise la victime de CE bouton, indépendamment de sa place dans la file.
		bouton.pressed.connect(_evacuer.bind(victime))
		liste.add_child(bouton)
		# Le VBoxContainer place automatiquement ses enfants les uns sous les autres.
	if nombre == 0:
		var vide := Label.new()
		vide.text = "Aucune victime dans votre escorte.\nLibérez une victime, puis revenez ici."
		liste.add_child(vide)


func _evacuer(victime: CharacterBody3D) -> void:
	# Le menu délègue la logique au gestionnaire ; il ne modifie pas lui-même la file.
	victim_manager.evacuate_victim(victime)
	fermer.grab_focus()
