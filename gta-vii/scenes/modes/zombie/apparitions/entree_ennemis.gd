class_name EntreeEnnemisZombie
extends Node3D

@export_enum("porte", "breche", "fenetre", "ascenseur") var type_entree := "porte"
@export_range(1, 5) var capacite := 3
@export_range(0.5, 5.0, 0.1) var duree_arrivee := 2.8
@export var hauteur_depart_cabine := 8.0
@export_range(2.0, 6.0, 0.1) var distance_sortie := 3.3

var occupee := false
var temps := 0.0
var duree := 0.0
var fermeture_restante := 0.0
var remontee_restante := 0.0
var hauteur_descente := 8.0
var ouverture_depart := 0.0
var passages: Array[Dictionary] = []
@onready var cabine: Node3D = get_node_or_null("Cabine")
@onready var lumiere: OmniLight3D = $Annonce/Lumiere
@onready var braises: CPUParticles3D = $Annonce/Braises

func _ready() -> void:
	reinitialiser()

func accepte(type: TypeEnnemiVague) -> bool:
	return type.volant if type_entree == "fenetre" else not type.volant

func preparer(duree_totale: float) -> void:
	var hauteur_actuelle := cabine.position.y if cabine != null else 0.0
	var portes := _portes()
	var ouverture_actuelle := clampf((-portes.get_node("Gauche").position.x - 0.9) / 1.9, 0.0, 1.0) if portes != null else 0.0
	reinitialiser()
	hauteur_descente = hauteur_actuelle
	ouverture_depart = ouverture_actuelle
	if cabine != null: cabine.position.y = hauteur_descente
	occupee = true
	temps = 0.0
	duree = maxf(0.01, duree_totale)
	fermeture_restante = 0.0
	braises.emitting = true

func ajouter_visuel(visuel: Node3D, hauteur: float, indice: int) -> Vector3:
	# Répartir le groupe dans la largeur, puis légèrement en profondeur.
	var lateral: float = [-1.4, 0.0, 1.4][indice % 3] if capacite > 1 else 0.0
	var destination := Vector3(lateral, hauteur, distance_sortie + (1.5 if indice % 3 == 1 else 0.0) + floori(indice / 3.0) * 1.5)
	# Resserrer le groupe dans l'ouverture, puis l'écarter une fois à l'intérieur.
	var depart := Vector3(lateral * (0.2 if type_entree == "fenetre" else 0.65), hauteur, -1.0)
	var conteneur: Node3D = cabine if cabine != null else self
	conteneur.add_child(visuel)
	visuel.position = depart
	passages.append({"visuel": visuel, "depart": depart, "destination": destination})
	return to_global(destination)

func _process(delta: float) -> void:
	if occupee:
		temps += delta
		var progression := clampf(temps / duree, 0.0, 1.0)
		lumiere.light_energy = (0.4 + progression * 1.2) * (0.9 + sin(temps * 13.0) * 0.1)
		if cabine != null:
			# Accélérer puis freiner doucement : la descente reste visible sur tout le trajet.
			var descente := clampf(progression / 0.65, 0.0, 1.0)
			cabine.position.y = hauteur_descente * (1.0 - smoothstep(0.0, 1.0, descente))
		var ouverture := clampf((progression - 0.65) / 0.15, 0.0, 1.0)
		if progression < 0.65:
			ouverture = ouverture_depart * (1.0 - clampf(progression / 0.15, 0.0, 1.0))
		_regler_portes(ouverture)
		for passage in passages:
			if is_instance_valid(passage.visuel):
				# Les figurants sortent seulement une fois la cabine arrivée et ouverte.
				passage.visuel.position = passage.depart.lerp(passage.destination, clampf((progression - 0.8) / 0.2, 0.0, 1.0))
	elif fermeture_restante > 0.0:
		fermeture_restante = maxf(0.0, fermeture_restante - delta)
		_regler_portes(clampf(fermeture_restante / 0.4, 0.0, 1.0))
		if fermeture_restante == 0.0:
			remontee_restante = 1.2 if cabine != null else 0.0
	elif remontee_restante > 0.0:
		# La cabine vide remonte aussi progressivement, sans se téléporter en hauteur.
		remontee_restante = maxf(0.0, remontee_restante - delta)
		cabine.position.y = hauteur_depart_cabine * smoothstep(0.0, 1.0, 1.0 - remontee_restante / 1.2)

func terminer() -> void:
	# Le calendrier appelle ceci à l'échéance exacte, sans attendre un signal de Tween.
	for passage in passages:
		if is_instance_valid(passage.visuel):
			passage.visuel.queue_free()
	passages.clear()
	occupee = false
	braises.emitting = false
	lumiere.light_energy = 0.0
	if cabine != null:
		cabine.position.y = 0.0
	_regler_portes(1.0)
	fermeture_restante = 1.0

func reinitialiser() -> void:
	for passage in passages:
		if is_instance_valid(passage.visuel):
			passage.visuel.queue_free()
	passages.clear()
	occupee = false
	fermeture_restante = 0.0
	remontee_restante = 0.0
	braises.emitting = false
	lumiere.light_energy = 0.0
	_regler_portes(0.0)
	if cabine != null:
		cabine.position.y = hauteur_depart_cabine

func _regler_portes(ouverture: float) -> void:
	var portes := _portes()
	if portes == null:
		return
	portes.get_node("Gauche").position.x = -0.9 - ouverture * 1.9
	portes.get_node("Droite").position.x = 0.9 + ouverture * 1.9

func _portes() -> Node3D:
	return get_node_or_null("Cabine/Portes") if cabine != null else get_node_or_null("Portes")
