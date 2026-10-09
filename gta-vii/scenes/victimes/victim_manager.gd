extends Node

# Référence au joueur du niveau. @onready attend que les nœuds soient disponibles.
@onready var player: CharacterBody3D = $"../player"

# Tableau ordonné : indice 0 = première victime, indice -1 = dernière victime.
var freed_victims: Array[CharacterBody3D] = []
var evacuated_count: int = 0
var ordre_liberation := 0
# null signifie suivre le joueur ; sinon conserver la destination donnée.
var cible_deplacement: Node3D = null

# Les menus peuvent écouter ce signal pour actualiser leur liste.
signal escort_changed

func _ready() -> void:
	# Les victimes annoncent leur libération ; le gestionnaire centralise la file.
	var victims := get_tree().get_nodes_in_group("victims")
	
	for victim in victims:
		# On connecte le signal freed et waiting termine à la fonction qui enregistre une victime libérée
		surveiller_victime(victim)

func surveiller_victime(victim: CharacterBody3D) -> void:
	# Fonction également appelée pour les victimes créées pendant la génération.
	if not victim.freed.is_connected(register_victim):
		victim.freed.connect(register_victim)
	if not victim.waiting_termine.is_connected(_on_waiting_termine):
		victim.waiting_termine.connect(_on_waiting_termine)

func diriger_victime(fleche) -> void:
	cible_deplacement = fleche
	reorganiser_file()

func retour_nav_auto() -> void:
	cible_deplacement = null
	reorganiser_file()

func register_victim(victim: CharacterBody3D) -> void:

	# has évite d'ajouter deux fois le même personnage si le signal se répète.
	if freed_victims.has(victim):
		return

	# Sortir la victime de sa salle AVANT de surveiller sa disparition.
	# Elle continuera à suivre le joueur quand l'ancienne salle sera désactivée.
	if not victim.has_meta("ordre_liberation"):
		ordre_liberation += 1
		victim.set_meta("ordre_liberation", ordre_liberation)
	victim.reparent(get_node("../Escorte"), true)
	if freed_victims.is_empty():
		cible_deplacement = null
		victim.follow_target = player
	else:
		victim.follow_target = freed_victims[-1]
	freed_victims.append(victim)

	# bind permet de savoir quelle victime quitte l’arbre pour la retirer de la file.
	victim.tree_exiting.connect(_on_victim_exiting.bind(victim))
	actualiser_bonus()
	escort_changed.emit()

func _on_waiting_termine() -> void:
	print("signal capturé")
	retour_nav_auto()

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
	# Un décès ou une évacuation ne doit pas annuler l'ordre du joueur.
	var cible: Node3D = cible_deplacement if is_instance_valid(cible_deplacement) else player
	for suivante in freed_victims:
		if is_instance_valid(suivante):
			suivante.waiting_timer = suivante.waiting_cooldown
			suivante.follow_target = cible

			# Au tour suivant, cette victime devient la cible de celle qui la suit.
			cible = suivante

func actualiser_bonus() -> void:
	if not is_instance_valid(player):
		return

	# Recalculer à partir de l'escorte actuelle : chaque type est actif ou inactif.
	# Deux victimes du même type ne cumulent pas leur bonus.
	player.bonus_dash_actif = false
	player.extincteur.bonus_degats_actif = false
	for victime in freed_victims:
		if not is_instance_valid(victime) or victime.is_queued_for_deletion():
			continue
		if victime.bonus_dash:
			player.bonus_dash_actif = true
		if victime.bonus_degats:
			player.extincteur.bonus_degats_actif = true

		# Ne pas sortir après la sportive : une spécialiste peut se trouver après elle.

func _on_victim_exiting(victim: CharacterBody3D) -> void:

	# Une évacuation l'a déjà retirée : ce cas ne doit pas compter deux fois.
	if not freed_victims.has(victim):
		return
	freed_victims.erase(victim)
	reorganiser_file()
	actualiser_bonus()
	escort_changed.emit()

func capturer_sauvegarde() -> Dictionary:
	var victimes: Array[Dictionary] = []
	var effets = player.ameliorations.effets_cartes
	for victime in freed_victims:
		if not is_instance_valid(victime) or victime.est_morte: continue
		var protection: Dictionary = effets.victimes_bouclier.get(victime.get_instance_id(), {}).duplicate()
		protection.erase("victime")
		victimes.append({"position": victime.global_position, "rotation": victime.rotation,
			"vie": victime.vie, "vie_max": victime.vie_max,
			"fragile": victime.defi_fragile, "points": victime.points_boutique,
			"ordre": victime.get_meta("ordre_liberation", 0), "depot": _est_en_depot(victime),
			"extraction_utilisee": victime.has_meta("extraction_utilisee"), "protection": protection,
			"prochaine_protection": effets.prochaine_protection.get(victime.get_instance_id(), 0.0)})
	return {"victimes": victimes, "ordre_liberation": ordre_liberation,
		"destination": cible_deplacement.global_position if is_instance_valid(cible_deplacement) else null}

func restaurer_sauvegarde(etat: Dictionary, salle: Node3D) -> void:
	ordre_liberation = etat.ordre_liberation
	var effets = player.ameliorations.effets_cartes
	for donnees in etat.victimes:
		var victime = preload("res://scenes/victimes/victime.tscn").instantiate()
		victime.is_freed = true
		victime.waiting = false
		victime.vie_max = donnees.vie_max
		victime.defi_fragile = donnees.get("fragile", false)
		victime.points_boutique = donnees.get("points", 1)
		get_node("../Escorte").add_child(victime)
		# vie est @onready : la restaurer après l'ajout empêche un remplissage involontaire.
		victime.vie = donnees.vie
		victime.global_position = donnees.position
		victime.rotation = donnees.rotation
		victime.set_meta("ordre_liberation", donnees.ordre)
		if donnees.extraction_utilisee: victime.set_meta("extraction_utilisee", true)
		victime.set_ennemis_container(salle.get_node("Ennemis"))
		victime.playback.travel("Locomotion")
		victime.actualiser_barre_vie()
		victime.update_interaction_label()
		freed_victims.append(victime)
		victime.tree_exiting.connect(_on_victim_exiting.bind(victime))
		if donnees.depot: _restaurer_depot(victime)
		var id: int = victime.get_instance_id()
		if not donnees.protection.is_empty():
			effets.proteger_victime(victime)
			var protection: Dictionary = donnees.protection.duplicate()
			protection.victime = victime
			effets.victimes_bouclier[id] = protection
		effets.prochaine_protection[id] = donnees.prochaine_protection
	# Conserver un ordre de déplacement en cours sans émettre une nouvelle libération.
	if etat.destination is Vector3:
		var destination := Marker3D.new()
		get_node("../Escorte").add_child(destination)
		destination.global_position = etat.destination
		cible_deplacement = destination
	reorganiser_file()
	escort_changed.emit()

func _est_en_depot(_victime: CharacterBody3D) -> bool:
	return false

func _restaurer_depot(_victime: CharacterBody3D) -> void:
	pass
