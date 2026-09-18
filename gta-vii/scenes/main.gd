extends Node3D

# A SUPPRIMER DANS LE JEU REEL 
func _unhandled_key_input(event: InputEvent) -> void:
	# Pour beta_test : R recommence le niveau. On ignore 
	# les répétitions automatiques lorsqu'elle reste enfoncée.
	if event is InputEventKey:
		if event.pressed and (not event.echo) and (event.keycode == KEY_R):
			# On recharge la scène
			get_tree().reload_current_scene()
		elif event.pressed and (not event.echo) and (event.keycode == KEY_I):
			# Le joueur peut avoir été supprimé après sa mort.
			var joueur = get_node_or_null("player")
			if joueur == null:
				return
			# "not" inverse le booléen : un appui active, le suivant désactive.
			joueur.invincible = not joueur.invincible
			if joueur.invincible:
				$InterfaceTest/EtatInvincibilite.text = "TEST : INVINCIBLE — I pour désactiver"
			else:
				$InterfaceTest/EtatInvincibilite.text = "I : activer l'invincibilité"


#Génération aléatoire du nombre d'ennemis
var ennemi_scene = preload("res://scenes/ennemi.tscn")
#On copie la scene type d'un ennemi

@export_group("Génération")
@export var nombre_min_ennemis := 3
@export var nombre_max_ennemis := 8


func _ready() -> void:
	# La mort appartient au joueur ; le choix de l'écran suivant appartient au niveau.
	$player.died.connect(_on_player_died, CONNECT_ONE_SHOT)
	var nombre_ennemis = randi_range(nombre_min_ennemis, nombre_max_ennemis)
	for i in range(nombre_ennemis):
		creer_ennemi(i)
	# Tous les ennemis existent maintenant : le gestionnaire peut les compter.
	# Connecter avant l'initialisation, qui peut déjà valider une salle vide.
	$RoomManager.room_cleared.connect($Porte.ouvrir)
	$RoomManager.initialiser_salle()


func creer_ennemi(i: int) -> void:
	var ennemi = ennemi_scene.instantiate()
	ennemi.name = "Ennemi " + str(i)
	$Ennemis.add_child(ennemi)


func _on_player_died() -> void:
	# Arrêter le combat immédiatement. L'écran suivant rétablira un arbre non pausé.
	get_tree().paused = true
	# Les dégâts arrivent pendant la physique : différer le changement de scène
	# pour ne pas supprimer les corps pendant le traitement de leurs collisions.
	call_deferred("afficher_ecran_mort")


func afficher_ecran_mort() -> void:
	# Changer de scène détruit TOUT le niveau, dont ses CanvasLayer et menus.
	get_tree().change_scene_to_file("res://scenes/ecran_mort.tscn")
