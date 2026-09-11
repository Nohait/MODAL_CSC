extends Node

# Référence au joueur du niveau. @onready attend que les nœuds soient disponibles.
@onready var player: CharacterBody3D = $"../player"

# Tableau ordonné : indice 0 = première victime, indice -1 = dernière victime.
var freed_victims: Array[CharacterBody3D] = []
var evacuated_count: int = 0

# Les menus peuvent écouter ce signal pour actualiser leur liste.
signal escort_changed

func _ready() -> void:
	# Les victimes annoncent leur libération ; le gestionnaire centralise la file.
	var victims := get_tree().get_nodes_in_group("victims")

	for victim in victims:
		##On connecte le signal freed à la fonction qui enregistre une victime libérée
		victim.freed.connect(register_victim)


func register_victim(victim: CharacterBody3D) -> void:
	# has évite d'ajouter deux fois le même personnage si le signal se répète.
	if freed_victims.has(victim):
		return
	if freed_victims.is_empty():
		victim.follow_target = player
	else:
		victim.follow_target = freed_victims[-1]

	freed_victims.append(victim)
	# Si un autre système supprime la victime, retirer aussi sa contribution.
	# bind transmet cette victime au signal tree_exiting, qui n'a pas d'argument.
	victim.tree_exiting.connect(_on_victim_exiting.bind(victim))
	actualiser_bonus()
	escort_changed.emit()


func evacuate_victim(victim: CharacterBody3D) -> void:
	# Seules les victimes présentes dans notre escorte peuvent être évacuées.
	if not is_instance_valid(victim) or not freed_victims.has(victim):
		return

	freed_victims.erase(victim)
	evacuated_count += 1

	reorganiser_file()
	actualiser_bonus()

	# queue_free programme la destruction en fin d'image.
	victim.queue_free()

	# Le menu reconstruit sa liste et son compteur.
	escort_changed.emit()


func reorganiser_file() -> void:
	# Le joueur peut déjà avoir disparu, notamment lors d'un redémarrage du niveau.
	if not is_instance_valid(player):
		return
	# Reconnecter la file AVANT de supprimer la cible que d'autres suivaient.
	var cible: Node3D = player
	for suivante in freed_victims:
		if is_instance_valid(suivante):
			suivante.follow_target = cible
			# Au tour suivant, cette victime devient la cible de celle qui la suit.
			cible = suivante


func actualiser_bonus() -> void:
	if not is_instance_valid(player):
		return
	# Repartir de false puis chercher AU MOINS une sportive dans la liste actuelle.
	# Cela retire le bonus après la dernière sportive, mais le conserve s'il en reste une.
	player.bonus_dash_actif = false
	for victime in freed_victims:
		if is_instance_valid(victime) and not victime.is_queued_for_deletion() and victime.bonus_dash:
			player.bonus_dash_actif = true
			break # Inutile de continuer : le bonus ne se cumule pas.


func _on_victim_exiting(victim: CharacterBody3D) -> void:
	# Une évacuation l'a déjà retirée : ce cas ne doit pas compter deux fois.
	if not freed_victims.has(victim):
		return
	freed_victims.erase(victim)
	reorganiser_file()
	actualiser_bonus()
	escort_changed.emit()
