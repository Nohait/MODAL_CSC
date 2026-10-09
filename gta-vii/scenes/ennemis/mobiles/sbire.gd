extends CharacterBody3D

const RETOUR_COMBAT = preload("res://scenes/effets/combat/retour_combat.gd")
@export_group("Retour visuel — mort")
@export var afficher_cendres := true
@export_range(0.2, 2.0, 0.05) var duree_cendres := 0.7

@export_group("Apparition")
# Seuil dans le parcours : une salle plus tardive reste autorisée aux étages suivants.
@export_range(1, 10, 1) var premier_etage := 1
@export_range(1, 5, 1) var premiere_salle := 1

@export_group("Progression par étage")
## Pourcentage ajouté à la valeur de base par étage après le premier.
@export_range(0.0, 200.0, 1.0) var degats_par_etage_pourcent := 10.0
# Fourni par le créateur AVANT add_child, donc avant _ready.
var etage := 1


# Annonce une vraie mort au RoomManager, avant la suppression du nœud.
signal died
signal degats_subis(quantite: float)
var est_mort := false

# L'agent calcule le chemin ; ce CharacterBody3D réalise le déplacement.
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent
@onready var detection_shape: CollisionShape3D = $SurfaceDetection/CollisionShape3D
@onready var SurfaceDetection: Area3D = $"SurfaceDetection"
@onready var exclamationRouge: Node3D = $"PointExclamationRouge"
@onready var player = get_tree().get_first_node_in_group("player")
var cible = null



@export_group("Statistiques de base")
@export var vie_max := 100.0
var vie := vie_max

@export var vitesse_sbire = 7

# Bonus temporaires recalculés par les auras des élites.
var vitesse_aura := 1.0
var degats_aura := 1.0
var resistance_aura := 0.0

var hitbox_radius = 0.9 #Définit comment l'extincteur va implémenter la largueur de le sbire dans son cône d'attaque

@export_group('Portée')
@export var distance_attaque = 1.3
@export var distance_detection = 10.0
@export var distance_lacher = 20.0
var distance_min = 1000.0 #Pour définir qui est la cible

@export_group("Attaque")
## Temps pour sortir de portée avant que le coup soit lancé.
@export_range(0.1, 1.5, 0.05) var duree_preparation := 0.25
var preparation_restante := 0.0
var cible_attaque: Node3D
var feux_mains: Array[Node3D] = []
var tailles_feux: Array[Vector3] = []
var animation_feux: Tween
var animation_frappe: Tween
@export var attaque_cooldown = 1.0
var attaque_timer = 0.0 #temps initialisé à 0
@export var degats_sbire = 10.0
@export var repos_apres_attaque := 0.0
var timer_apres_attaque := 0.0

@export_group("Idle")
@export var rayon_idle := 10.0
@export var temps_idle_min := 1.0
@export var temps_idle_max := 5
var idle_timer := 0.0
var en_idle := true
@onready var cible_idle = Marker3D.new()


@export_group("Cible_manager")
@export var chgt_cible_cooldown = 1.3 #On reste 3s sur la meme cible avant de se demander si on change
@export var aggro_cooldown = chgt_cible_cooldown*3
var chgt_cible_timer = 0.0 #temps initialisé à 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_preparer_feux_mains()
	cible_idle.name = "Cible " + self.name
	get_parent().add_child(cible_idle)

	# Les PV restent ceux de l’Inspecteur ; seuls les dégâts progressent par étage.
	var paliers := maxi(etage - 1, 0)
	vie = vie_max
	degats_sbire *= 1.0 + paliers * degats_par_etage_pourcent / 100.0
	detection_shape.shape.radius = distance_detection  #On met à jour la distance de detection en fonction de la valeur choisie en variable

	# Le RoomManager choisit un emplacement libre : ne pas remplacer sa position ici.

	pass # Replace with function body.


func _physics_process(delta):
	# Le gel profond suspend aussi la préparation des attaques, pas seulement la marche.
	if est_gele() or subit_recul():
		velocity = Vector3.ZERO
		return
	attaque_timer -= delta 	#A chaque frame, le cooldown réduit
	timer_apres_attaque -= delta

	# La préparation garde sa cible, mais n'empêche plus de la poursuivre.
	if preparation_restante > 0.0:
		if not is_instance_valid(cible_attaque) or cible_attaque.is_queued_for_deletion():
			preparation_restante = 0.0
			_animer_feux(false, 0.1)
			velocity = Vector3.ZERO
			return
		cible = cible_attaque
		var direction := global_position.direction_to(cible_attaque.global_position)
		if Vector2(direction.x, direction.z).length() > 0.001:
			rotation.y = atan2(direction.x, direction.z)
		if global_position.distance_to(cible_attaque.global_position) > distance_attaque:
			suivre_cible_navigation()
		else:
			velocity = Vector3.ZERO
			move_and_slide()
		preparation_restante = maxf(preparation_restante - delta, 0.0)
		if preparation_restante == 0.0:
			attaque()
		return

	#On définit la cible.
	#Il y a un timer pour eviter que le sbire soit indécis
	if cible == null:
		chgt_cible_timer = 0.0
	chgt_cible_timer -= delta
	if chgt_cible_timer < 0:
		choisir_cible()

	if cible == null or en_idle:
		idle_timer -= delta
		if idle_timer <0 :
			cible_idle.position =  choisir_destination_idle()
			cible = cible_idle
			idle_timer = randf_range(temps_idle_min,temps_idle_max)

	if timer_apres_attaque > 0.0:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	# Le joueur peut avoir été supprimé après sa mort : ne plus lire sa position.
	if not is_instance_valid(cible):
		cible = null
		velocity = Vector3.ZERO
		return

	if cible != null :	#Une fois que le joueur est pris pour cible
		var distance = global_position.distance_to(cible.global_position)

		#On tourne le sbire et sa hitbox vers la cible
		var direction = global_position.direction_to(cible.global_position)
		var theta = atan2(direction.x, direction.z) - rotation.y
		self.rotate(Vector3(0,1,0),theta)
		detection_shape.rotate(Vector3(0,1,0),theta)


		if distance > distance_lacher: #calcul de sortie de range
			cible = null
			en_idle = true
			velocity = Vector3.ZERO
			move_and_slide()

		elif distance > distance_attaque: # comportement dans la range
			# Suivre les étapes d'un chemin au lieu de foncer directement vers le joueur.
			suivre_cible_navigation()

		else: #comportement dans la portée d'attaque
			velocity = Vector3.ZERO

			if attaque_timer < 0.0:
				if cible.is_in_group("player") or cible.is_in_group("victime"):
					commencer_preparation()

#On detecte pour bypass le cooldown de changer de cible dans choisir_cible() pour sortir instantanément de l'idle
func _on_surface_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		cible = body
		en_idle = false
		$SbireRepere.play("PopUp")
		$SonRepere.play()

	elif body.is_in_group("victime") and body.is_freed:
		cible = body
		en_idle = false
		$SbireRepere.play("PopUp")
		$SonRepere.play()

func choisir_destination_idle():
	var destination = Vector3.ZERO
	var map_rid := navigation_agent.get_navigation_map()
	for i in range(10):
		var rand_x = randf_range(-rayon_idle, rayon_idle)
		var rand_z = randf_range(-rayon_idle, rayon_idle)
		destination = Vector3(rand_x,0.0,rand_z) + global_position
		var position_nav := NavigationServer3D.map_get_closest_point(map_rid,destination)
		position_nav.y = 0.0
		destination.y = 0.0
		if destination.distance_to(position_nav) < 0.1:
			return destination
	return global_position

func suivre_cible_navigation() -> void:
	# Arrêt par défaut si la carte n'est pas prête ou si aucun chemin n'est trouvé.
	velocity = Vector3.ZERO
	# Au démarrage, Godot synchronise la carte de navigation avec le monde physique.
	# Une itération à 0 indique qu'il faut attendre le prochain delta.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return

	# La destination est actualisée car le joueur peut bouger pendant la poursuite.
	navigation_agent.target_position = cible.global_position
	if en_idle:
		navigation_agent.target_position = cible_idle.position

	var prochaine_position := navigation_agent.get_next_path_position()

	# Ce point peut être intermédiaire.
	var direction := prochaine_position - global_position
	direction.y = 0.0 # Déplacement horizontal
	if direction.length() > 0.01:
		# Normaliser conserve uniquement la direction.
		velocity = direction.normalized() * vitesse_sbire * multiplicateur_vitesse()

	# L'agent ne déplace rien lui-même : appliquer la vitesse avec les collisions.

	move_and_slide()

func choisir_cible():
	var cible_avant = cible #on sauvegardde la cible
	var bodies = SurfaceDetection.get_overlapping_bodies()
	if cible != null and !en_idle:
		distance_min = global_position.distance_to(cible.global_position)
	else:
		distance_min = 1000.0

	for body in bodies:
		#les cibles ne peuvent etre que des gentils libérés
		if body.is_in_group("player") or (body.is_in_group("victime") and body.is_freed):
			var distance_body = global_position.distance_to(body.global_position)

			#La cible choisie est la plus proche
			if distance_body <= distance_min:
				distance_min = distance_body
				cible = body

	chgt_cible_timer = chgt_cible_cooldown
	if cible != cible_avant:
		en_idle = false
		$SbireRepere.reset_section()
		$SbireRepere.play("PopUp")
		$SonRepere.play()

func animation_enerve():
	var tween_enerve = create_tween()
	var scale_origine = Vector3(0.16,0.16,0.16)
	#var couleur_origine = exclamation.modulate
	exclamationRouge.scale = Vector3(0.0,0.0,0.0)
	exclamationRouge.visible = true
	#exclamation.modulate= Color(0.546, 0.0, 0.016, 1.0)
	tween_enerve.tween_property(exclamationRouge, "scale", scale_origine, 0.2)
	tween_enerve.tween_property(exclamationRouge, "scale",  Vector3(0.0,0.0,0.0), aggro_cooldown-0.2)
	#await tween_enerve.finished
	#exclamation.visible = false
	#exclamation.modulate =couleur_origine



func prendre_degats(degats: float, source: StringName = &"feu") -> void:
	# queue_free attend la fin de l'image : ignorer les impacts reçus entre-temps.
	if est_mort:
		return
	degats *= 1.0 - resistance_aura
	# Annoncer les PV réellement retirés, sans compter les dégâts au-delà de zéro.
	# La source distingue le jet et l’eau des coups de feu pour les combos.
	var pompier = get_tree().get_first_node_in_group("player")
	if is_instance_valid(pompier) and is_instance_valid(pompier.ameliorations):
		degats *= pompier.ameliorations.effets_cartes.modifier_degats(self, source)
	var vie_avant: float = vie
	vie -= degats
	vie = max(vie, 0)
	if vie < vie_avant: degats_subis.emit(vie_avant - vie)

	#Le joueur prends l'aggro
	if cible != player:
		if $SbireRepere.current_animation == "PopUp":
			$SbireRepere.stop()
			$SbireRepere.reset_section()
		$SonRepere.play()
		$SonRepere.play()
		animation_enerve()

		cible = player
		chgt_cible_timer = aggro_cooldown #On veut que la cible ait le temps de "s'echapper"

	afficher_degats(degats)

	if vie <= 0:
		mourir()

func mourir():
	# Une mort ne doit émettre le signal qu'une seule fois.
	if est_mort:
		return
	est_mort = true
	var apparition := get_node_or_null("ApparitionSbire")
	if apparition != null: apparition.annuler()
	if animation_feux:
		animation_feux.kill()
	if animation_frappe:
		animation_frappe.kill()

	#On joue le son de mort dans un parent de l'ennemi pour qu'il reste après la mort
	var steam_death=  AudioStreamPlayer3D.new()
	steam_death.bus = &"Effets"
	get_parent().add_child(steam_death)
	steam_death.stream = preload("res://assets/sounds/ennemis/steam_death.wav")
	steam_death.global_position = global_position
	steam_death.volume_db = -10
	steam_death.play()

	# Une copie du visuel termine l’animation ; le vrai sbire meurt immédiatement.
	if afficher_cendres:
		RETOUR_COMBAT.creer_cendres(self, [$Sketchfab_Scene, $droplet], duree_cendres)
	died.emit()
	print("Bravo, vous avez tué le sbire")
	queue_free()

func _preparer_feux_mains() -> void:
	var second_feu: Node3D = $vfx_fire/vfx_fire
	# Deux frères : grossir une main ne doit pas grossir aussi l'autre.
	second_feu.reparent(self, true)
	feux_mains.append($vfx_fire)
	feux_mains.append(second_feu)
	for feu in feux_mains:
		tailles_feux.append(feu.scale)
		feu.scale *= 0.55
		var particules: CPUParticles3D = feu.get_node("Flames")
		particules.color = Color(3.0, 1.3, 0.5, 1.0)

func _animer_feux(charger: bool, duree: float) -> void:
	if animation_feux:
		animation_feux.kill()
	animation_feux = create_tween().set_parallel(true)
	for i in range(feux_mains.size()):
		var feu := feux_mains[i]
		var particules: CPUParticles3D = feu.get_node("Flames")
		# Taille et couleur changent ensemble, progressivement pendant la préparation.
		animation_feux.tween_property(feu, "scale", tailles_feux[i] * (1.15 if charger else 0.55), duree)
		animation_feux.tween_property(particules, "color", Color(7.0, 0.7, 0.12, 1.0) if charger else Color(3.0, 1.3, 0.5, 1.0), duree)

func commencer_preparation() -> void:
	cible_attaque = cible
	preparation_restante = duree_preparation
	_animer_feux(true, duree_preparation)

func attaque() -> void:
	_animer_feux(false, 0.15)
	attaque_timer = attaque_cooldown
	timer_apres_attaque = repos_apres_attaque
	if not is_instance_valid(cible_attaque) or cible_attaque.is_queued_for_deletion():
		return
	# L'impulsion se joue aussi si la cible esquive : le sbire frappe dans le vide.
	_jouer_frappe()
	if global_position.distance_to(cible_attaque.global_position) > distance_attaque:
		return
	# Un seul appel direct : aucune création de projectile, aucun dégât différé.
	var degats: float = round(randf_range(0.9, 1.1) * degats_sbire * multiplicateur_degats() * 100.0) / 100.0
	cible_attaque.prendre_degats(degats)

func _jouer_frappe() -> void:
	var modele: Node3D = $Sketchfab_Scene
	var origine := modele.position
	# Le modèle n'a pas d'animation de frappe : une brève impulsion donne le mouvement.
	var direction := global_position.direction_to(cible_attaque.global_position)
	var impulsion := global_basis.inverse() * direction * 0.18
	animation_frappe = create_tween()
	animation_frappe.tween_property(modele, "position", origine + impulsion, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation_frappe.tween_property(modele, "position", origine, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func afficher_degats(degats: float) -> void:
	preload("res://scenes/interfaces/indications/nombre_degats.gd").afficher($PopUpDegats, degats, 2.5)

func appliquer_gel(pourcentage: float, duree: float) -> void:
	if est_mort: return
	var gel = get_node_or_null("Ralentissement")
	if gel == null:
		gel = preload("res://scenes/effets/combat/ralentissement.gd").new()
		gel.name = "Ralentissement"
		add_child(gel)
	gel.appliquer(pourcentage, duree)

func est_gele() -> bool:
	var statut := get_node_or_null("EtatMousse")
	return statut != null and statut.gel_restant > 0

func subit_recul() -> bool:
	var statut := get_node_or_null("EtatMousse")
	return statut != null and statut.recul_prioritaire and statut.recul_restant > 0.0

func multiplicateur_vitesse() -> float:
	var gel = get_node_or_null("Ralentissement")
	var elite = get_node_or_null("Elite")
	return (gel.multiplicateur if gel != null else 1.0) * vitesse_aura * (elite.vitesse() if elite != null else 1.0)

func multiplicateur_degats() -> float:
	var elite = get_node_or_null("Elite")
	return degats_aura * (elite.degats() if elite != null else 1.0)
