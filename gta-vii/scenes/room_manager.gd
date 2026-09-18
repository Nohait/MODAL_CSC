extends Node

# D'autres systèmes pourront écouter ce signal pour ouvrir une porte, par exemple.
signal room_cleared

var remaining_victims: int = 0
var remaining_enemies: int = 0
var is_room_cleared := false
var initialized := false

@onready var objectifs: Label = $InterfaceSalle/Objectifs
@onready var message_victoire: PanelContainer = $InterfaceSalle/MessageVictoire


func initialiser_salle() -> void:
	# main appelle cette fonction APRÈS avoir créé les ennemis aléatoires.
	# Un second appel ne doit pas doubler les connexions ni réinitialiser les compteurs.
	if initialized:
		return
	initialized = true
	var salle := get_parent()
	for victime in get_tree().get_nodes_in_group("victims"):
		# Les groupes sont communs à tout l'arbre : ne compter que cette salle.
		if salle.is_ancestor_of(victime) and not victime.is_freed:
			remaining_victims += 1
			# ONE_SHOT déconnecte après la première libération : jamais de double comptage.
			victime.freed.connect(_on_victim_freed, CONNECT_ONE_SHOT)
	for ennemi in get_tree().get_nodes_in_group("enemies"):
		# Le conteneur Ennemis est aussi dans ce groupe, mais n'a pas de signal died.
		if salle.is_ancestor_of(ennemi) and ennemi.has_signal("died"):
			remaining_enemies += 1
			ennemi.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
	actualiser_objectifs()


func _on_victim_freed(_victim: CharacterBody3D) -> void:
	# On compte la libération, pas l'évacuation : rejoindre l'escorte suffit.
	remaining_victims -= 1
	actualiser_objectifs()


func _on_enemy_died() -> void:
	# Seule une mort compte ; quitter l'arbre lors d'un rechargement ne compte pas.
	remaining_enemies -= 1
	actualiser_objectifs()


func actualiser_objectifs() -> void:
	objectifs.text = "Victimes à libérer : %d   |   Ennemis restants : %d" % [remaining_victims, remaining_enemies]
	# and exige que LES DEUX objectifs soient accomplis, quel que soit leur ordre.
	# Le booléen empêche de rejouer la victoire si cette fonction est rappelée.
	if remaining_victims == 0 and remaining_enemies == 0 and not is_room_cleared:
		is_room_cleared = true
		afficher_victoire()
		room_cleared.emit()


func afficher_victoire() -> void:
	objectifs.text = "Salle libérée — toutes les victimes ont été secourues !"
	# Le panneau existe dans main.tscn : son aspect est modifiable dans l'éditeur.
	message_victoire.modulate.a = 0.0
	message_victoire.show()
	var animation := create_tween()
	# Le Tween fait varier l'opacité sans écrire de boucle dans _process.
	animation.tween_property(message_victoire, "modulate:a", 1.0, 0.4)
	animation.tween_interval(4.0)
	animation.tween_property(message_victoire, "modulate:a", 0.0, 0.6)
	animation.tween_callback(message_victoire.hide)
	# Le petit texte d'objectif reste affiché une fois le bandeau disparu.
