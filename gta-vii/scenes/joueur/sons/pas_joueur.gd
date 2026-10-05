extends AudioStreamPlayer3D

@export var sons: Array[AudioStream]
## Distance parcourue entre deux pas, en mètres. Plus petite = pas plus fréquents.
@export_range(0.2, 4.0, 0.05) var distance_entre_pas := 1.8
@export_range(0.0, 0.15, 0.01) var variation_tonalite := 0.04

@onready var joueur: CharacterBody3D = get_parent()
var distance_restante := 0.0
var dernier_son := -1

func _physics_process(delta: float) -> void:
	# Ce nœud passe après le joueur : sa vitesse réelle tient compte des collisions.
	var vitesse := joueur.get_real_velocity()
	vitesse.y = 0.0
	var marche: bool = joueur.is_on_floor() and not joueur.est_mort and not joueur.is_dashing
	# Le dernier instant du dash peut encore avoir une grande vitesse, même après sa fin.
	marche = marche and vitesse.length() > 0.1 and vitesse.length() <= joueur.speed * 1.5
	if not marche:
		distance_restante = 0.0
		if joueur.is_dashing or joueur.est_mort or not joueur.is_on_floor():
			stop()
		return
	# Un pas au départ, puis un autre chaque fois que cette distance est parcourue.
	distance_restante -= vitesse.length() * delta
	if distance_restante <= 0.0:
		_jouer_pas()
		distance_restante = distance_entre_pas

func _jouer_pas() -> void:
	if sons.is_empty():
		return
	var indice := randi_range(0, sons.size() - 1)
	# Décaler le choix évite deux pas identiques de suite, sans boucle de tirage.
	if sons.size() > 1 and indice == dernier_son:
		indice = (indice + randi_range(1, sons.size() - 1)) % sons.size()
	dernier_son = indice
	stream = sons[indice]
	pitch_scale = randf_range(1.0 - variation_tonalite, 1.0 + variation_tonalite)
	play()

func _notification(notification: int) -> void:
	if notification == NOTIFICATION_PAUSED:
		# Ne pas reprendre un ancien bruit de pas après la fermeture d’un menu.
		stop()
		distance_restante = 0.0
