extends Node3D

# A SUPPRIMER DANS LE JEU REEL 
func _unhandled_key_input(event: InputEvent) -> void:
	# Pour beta_test : R recommence le niveau. On ignore 
	# les répétitions automatiques lorsqu'elle reste enfoncée.
	if event is InputEventKey:
		if event.pressed and (not event.echo) and (event.keycode == KEY_R):
			# On recharge la scène
			get_tree().reload_current_scene()


func _ready() -> void:
	# Garder la lance aussi sur les boutons qui demandent un curseur en forme de main.
	var curseur = preload("res://assets/textures/interfaces/curseurs/curseur_lance.svg")
	Input.set_custom_mouse_cursor(curseur, Input.CURSOR_POINTING_HAND, Vector2(3, 3))
	# main ne gère plus les apparitions : il relie seulement les systèmes du jeu.
	$player.died.connect(_on_player_died, CONNECT_ONE_SHOT)
	# Tous les enfants doivent avoir terminé leur _ready avant de générer les salles.
	if $UpgradeManager.mode_jeu == "classique":
		var point = preload("res://scenes/jeu/sauvegarde/point_reprise_classique.gd").new()
		point.name = "PointRepriseClassique"
		add_child(point)
	$Salles/RoomManager.call_deferred("demarrer_partie")


func _on_player_died() -> void:
	if $UpgradeManager.mode_jeu == "classique": SauvegardeClassique.supprimer()
	# Arrêter le combat immédiatement. L'écran suivant rétablira un arbre non pausé.
	get_tree().paused = true
	# Les dégâts arrivent pendant la physique : différer le changement de scène
	# pour ne pas supprimer les corps pendant le traitement de leurs collisions.
	call_deferred("_transition_mort")


func _transition_mort() -> void:
	await $player/FeedbackSurvie.jouer_mort()
	# La méthode spécialisée du zombie conserve son bilan de fin de partie.
	afficher_ecran_mort()

func afficher_ecran_mort() -> void:
	# Changer de scène détruit TOUT le niveau, dont ses CanvasLayer et menus.
	get_tree().change_scene_to_file("res://scenes/interfaces/menus/ecran_mort.tscn")
