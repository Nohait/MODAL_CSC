class_name EntreeEnnemisZombie
extends Node3D

@export_enum("porte", "breche", "fenetre", "ascenseur") var type_entree := "porte"
@export_range(1, 5) var capacite := 3
@export_range(1, 100) var premiere_vague := 1
@export_range(0.5, 5.0, 0.1) var duree_arrivee := 2.8
@export var hauteur_depart_cabine := 8.0
@export var afficher_fond := true
@export var battants_sur_gonds := false
@export_range(2.0, 6.0, 0.1) var distance_sortie := 3.3

var occupee := false
var temps := 0.0
var duree := 0.0
var fermeture_restante := 0.0
var ouverture_restante := 0.0
var remontee_restante := 0.0
var hauteur_descente := 8.0
var ouverture_depart := 0.0
var passages: Array[Dictionary] = []
@onready var cabine: Node3D = get_node_or_null("Cabine")
@onready var lumiere: OmniLight3D = $Annonce/Lumiere
@onready var braises: CPUParticles3D = $Annonce/Braises
@onready var son_mecanisme: AudioStreamPlayer3D = get_node_or_null("Mecanisme")
@onready var volume_mecanisme: float = son_mecanisme.volume_db if son_mecanisme != null else -10.0
var mecanisme_en_marche := false
var fondu_son: Tween
@onready var son_portes: AudioStreamPlayer3D = get_node_or_null("OuverturePortes")
var portes_en_ouverture := false
@onready var annonce_porte: Node3D = get_node_or_null("AnnoncePorte")

func _ready() -> void:
	# Certaines entrées donnent sur un décor extérieur, tout en gardant leur limite physique.
	var fond := get_node_or_null("FondSombre/Visuel")
	if fond != null: fond.visible = afficher_fond
	reinitialiser()

func accepte(type: TypeEnnemiVague) -> bool:
	return type.volant if type_entree == "fenetre" else not type.volant

func preparer(duree_totale: float) -> void:
	var hauteur_actuelle := cabine.position.y if cabine != null else 0.0
	var portes := _portes()
	var ouverture_actuelle := 0.0
	if portes != null:
		ouverture_actuelle = absf(portes.get_node("Gauche").rotation.y) / 1.4 if battants_sur_gonds else clampf((-portes.get_node("Gauche").position.x - 0.9) / 1.9, 0.0, 1.0)
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
		if annonce_porte != null: annonce_porte.actualiser(progression)
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
				passage.visuel.position = passage.depart.lerp(passage.destination, _progression_sortie(progression))
	elif ouverture_restante > 0.0:
		# Le premier ennemi est déjà présent : ouvrir malgré tout les battants progressivement.
		ouverture_restante = maxf(0.0, ouverture_restante - delta)
		_regler_portes(smoothstep(0.0, 1.0, 1.0 - ouverture_restante / 0.4))
	elif fermeture_restante > 0.0:
		fermeture_restante = maxf(0.0, fermeture_restante - delta)
		_regler_portes(clampf(fermeture_restante / 0.4, 0.0, 1.0))
		if fermeture_restante == 0.0:
			remontee_restante = 1.2 if cabine != null else 0.0
	elif remontee_restante > 0.0:
		# La cabine vide remonte aussi progressivement, sans se téléporter en hauteur.
		remontee_restante = maxf(0.0, remontee_restante - delta)
		cabine.position.y = hauteur_depart_cabine * smoothstep(0.0, 1.0, 1.0 - remontee_restante / 1.2)
	# Le moteur ne joue que pendant les déplacements de la cabine, pas ceux des portes.
	var descente_en_cours := occupee and temps < duree * 0.65 and hauteur_descente > 0.01
	_regler_son_mecanisme(descente_en_cours or remontee_restante > 0.0)
	# Le glissement occupe la phase entre l'arrivée de la cabine et la sortie des mobs.
	_regler_son_portes(occupee and temps >= duree * 0.65 and temps < duree * 0.8)

func _progression_sortie(progression: float) -> float:
	return clampf((progression - 0.8) / 0.2, 0.0, 1.0)

func ouvrir_pour_arrivee_immediate() -> void:
	# Conserver la fermeture habituelle, sans sauter directement à l'état ouvert.
	terminer()
	_regler_portes(0.0)
	ouverture_restante = 0.4

func terminer() -> void:
	if annonce_porte != null: annonce_porte.reinitialiser()
	_regler_son_mecanisme(false)
	_regler_son_portes(false)
	# Le calendrier appelle ceci à l'échéance exacte, sans attendre un signal de Tween.
	for passage in passages:
		if is_instance_valid(passage.visuel):
			passage.visuel.queue_free()
	passages.clear()
	occupee = false
	ouverture_restante = 0.0
	braises.emitting = false
	lumiere.light_energy = 0.0
	if cabine != null:
		cabine.position.y = 0.0
	_regler_portes(1.0)
	fermeture_restante = 1.0

func reinitialiser() -> void:
	if annonce_porte != null: annonce_porte.reinitialiser()
	_regler_son_portes(false)
	if fondu_son: fondu_son.kill()
	if son_mecanisme != null: son_mecanisme.stop()
	mecanisme_en_marche = false
	for passage in passages:
		if is_instance_valid(passage.visuel):
			passage.visuel.queue_free()
	passages.clear()
	occupee = false
	ouverture_restante = 0.0
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
	if battants_sur_gonds:
		# Les pivots sont sur les gonds : faire tourner les battants, sans les faire coulisser.
		portes.get_node("Gauche").rotation.y = -smoothstep(0.0, 1.0, ouverture) * 1.4
		portes.get_node("Droite").rotation.y = smoothstep(0.0, 1.0, ouverture) * 1.4
		return
	portes.get_node("Gauche").position.x = -0.9 - ouverture * 1.9
	portes.get_node("Droite").position.x = 0.9 + ouverture * 1.9

func _portes() -> Node3D:
	return get_node_or_null("Cabine/Portes") if cabine != null else get_node_or_null("Portes")

func _regler_son_portes(en_ouverture: bool) -> void:
	# Seul l'ascenseur possède ce lecteur. Ne pas relancer le son à chaque image.
	if son_portes == null or portes_en_ouverture == en_ouverture: return
	portes_en_ouverture = en_ouverture
	if en_ouverture:
		son_portes.play()
	else:
		son_portes.stop()

func _regler_son_mecanisme(en_marche: bool) -> void:
	# Les portes, fenêtres et brèches partagent ce script, sans lecteur de mécanisme.
	if son_mecanisme == null or mecanisme_en_marche == en_marche: return
	mecanisme_en_marche = en_marche
	if fondu_son: fondu_son.kill()
	fondu_son = create_tween()
	if en_marche:
		if not son_mecanisme.playing:
			son_mecanisme.volume_db = -60.0
			son_mecanisme.play()
		# Monter le volume progressivement évite un démarrage sec du moteur.
		fondu_son.tween_property(son_mecanisme, "volume_db", volume_mecanisme, 0.12)
	else:
		# Le Tween baisse le volume, puis arrête la boucle une fois le fondu terminé.
		fondu_son.tween_property(son_mecanisme, "volume_db", -60.0, 0.15)
		fondu_son.tween_callback(son_mecanisme.stop)
