extends CharacterBody3D

const RETOUR_COMBAT = preload("res://scenes/effets/combat/retour_combat.gd")
@export_group("Retour visuel — mort")
@export var afficher_cendres := true
@export_range(0.2, 2.0, 0.05) var duree_cendres := 0.7

@export_group("Apparition")
# Seuil dans le parcours : une salle plus tardive reste autorisée aux étages suivants.
@export_range(1, 10, 1) var premier_etage := 1
@export_range(1, 5, 1) var premiere_salle := 3

@export_group("Progression par étage")
## Pourcentage ajouté à la valeur de base par étage après le premier.
@export_range(0.0, 200.0, 1.0) var degats_par_etage_pourcent := 10.0
# Fourni par le créateur AVANT add_child, donc avant _ready.
var etage := 1


# Annonce une vraie mort au RoomManager, avant la suppression du nœud.
signal died
signal degats_subis(quantite: float)
var est_mort := false

var cible = null

@onready var player = get_tree().get_first_node_in_group("player")
@onready var detection_shape: CollisionShape3D = $"SurfaceDetection/CollisionShape3D"
@onready var SurfaceDetection: Area3D = $"SurfaceDetection"
# Le laser et le projectile partent désormais de la face de l’œil.
@onready var muzzle: Marker3D = $Visuel/OeilPivot/Muzzle

@export_group("Statistiques de base")
@export var vie_max := 200.0
var vie := vie_max
var hitbox_radius = 1.5

@export_group("Portée")
## Rayon d'acquisition d'une cible.
@export_range(1.0, 30.0, 0.5) var distance_detection := 10.0
## Portée indiquée par le cercle blanc : en sortir interrompt la visée.
@export_range(1.0, 40.0, 0.5) var distance_attaque := 14.0
var distance_min = 1000.0

@export_group("Attaque")
## Temps sans laser après chaque tir.
@export_range(0.1, 10.0, 0.1) var cooldown_post_tir := 1.5
## Temps pendant lequel le laser annonce le prochain tir.
@export_range(0.1, 10.0, 0.1) var duree_chargement := 1.5
# Un temps de repos à zéro signifie que la tourelle peut commencer à viser.
var repos_restant := 0.0
var chargement_ecoule := 0.0
# Ancien dégât effectif du projectile : 25. La tourelle le pilote maintenant.
@export var degats_ennemi = 25.0


@onready var laser: MeshInstance3D = $Laser
@onready var disque: Node3D = $IndicateurDetection
var materiau_laser: StandardMaterial3D

var projectile_scene = preload("res://scenes/ennemis/tourelles/projectile_tour.tscn")
# Fourni avant add_child : les projectiles appartiennent à la salle de cette tour.
@export var projectiles_tour: Node3D


func _ready() -> void:
	# Les PV restent ceux de l’Inspecteur ; seuls les dégâts progressent par étage.
	var paliers := maxi(etage - 1, 0)
	vie = vie_max
	degats_ennemi *= 1.0 + paliers * degats_par_etage_pourcent / 100.0
	# Dupliquer la forme et le matériau évite qu'une tourelle modifie ses voisines.
	detection_shape.shape = detection_shape.shape.duplicate()
	detection_shape.shape.radius = distance_detection
	disque.scale = Vector3(distance_attaque, 1.0, distance_attaque)
	materiau_laser = laser.get_active_material(0).duplicate()
	laser.material_override = materiau_laser
	laser.hide()
	disque.hide()


func _physics_process(delta: float) -> void:
	if est_mort:
		return
	repos_restant = maxf(0.0, repos_restant - delta)
	# La détection déclenche la visée ; le disque indique ensuite la zone à quitter.
	# Une victime seule n'affiche pas l'indicateur et n'est jamais prise pour cible.
	choisir_cible()
	print("j'ai choisi ma cible:", cible)
	# La détection acquiert la cible ; la portée d'attaque permet de la conserver
	# un peu plus loin. Une sortie de portée annule entièrement le chargement.
	if is_instance_valid(cible):
		var ecart: Vector3 = cible.global_position - global_position
		ecart.y = 0.0
		if ecart.length() > distance_attaque:
			cible = null
	else:
		cible = null
	# Orienter l'œil AVANT de calculer le laser depuis son point de départ.
	$Visuel.actualiser()
	# Rester visible entre 10 et 14 m, ainsi que pendant le repos après un tir :
	# sortir de la détection ne suffit pas à échapper à une tourelle déjà alertée.
	disque.visible = is_instance_valid(cible)
	if not is_instance_valid(cible):
		chargement_ecoule = 0.0
		laser.hide()
		return
	# Vérifier également la portée si l'inspecteur définit une attaque plus courte
	# que la détection : détecter quelqu'un n'autorise pas un tir hors de portée.
	var distance := Vector2(cible.global_position.x - global_position.x,
		cible.global_position.z - global_position.z).length()
	disque.visible = distance <= distance_attaque
	if repos_restant > 0.0 or distance > distance_attaque:
		chargement_ecoule = 0.0
		laser.hide()
		return

	chargement_ecoule += delta
	var progression := clampf(chargement_ecoule / duree_chargement, 0.0, 1.0)
	$Visuel.actualiser()
	actualiser_laser(progression)
	if progression >= 1.0:
		tirer_projectile()
		chargement_ecoule = 0.0
		repos_restant = cooldown_post_tir
		laser.hide()


func actualiser_laser(progression: float) -> void:
	var depart := muzzle.global_position
	var arrivee: Vector3 = cible.global_position
	var direction := arrivee - depart
	if direction.length_squared() < 0.001:
		laser.hide()
		return
	laser.show()
	# Le BoxMesh mesure une unité : son axe Z devient la longueur du rayon.
	# Son centre est placé à mi-chemin, puis son axe -Z est orienté vers le joueur.
	laser.global_position = (depart + arrivee) / 2.0
	var axe_haut := Vector3.UP
	if absf(direction.normalized().dot(axe_haut)) > 0.99:
		axe_haut = Vector3.RIGHT
	laser.look_at(arrivee, axe_haut)
	# Un rayon fin qui se concentre pendant la charge ; la couleur et l'opacité
	# assurent la montée en intensité sans avoir besoin d'un faisceau large.
	var largeur := lerpf(0.07, 0.035, progression)
	laser.scale = Vector3(largeur, largeur, direction.length())
	# Rouge transparent au départ, puis orange et presque blanc opaque avant le tir.
	# La progression au carré accentue la montée finale. Le matériau non éclairé
	# conserve cette lisibilité même dans une salle sombre, sans dépendre du glow.
	var intensite := progression * progression
	materiau_laser.albedo_color = Color(1.0, 0.04, 0.01).lerp(
		Color(1.0, 0.95, 0.8), intensite)
	materiau_laser.albedo_color.a = lerpf(0.12, 1.0, progression)


func prendre_degats(degats: float) -> void:
	# queue_free attend la fin de l'image : ignorer les impacts reçus entre-temps.
	if est_mort:
		return
	# Le bilan écoute cette perte effective ; un coup fatal ne compte pas de PV négatifs.
	var vie_avant: float = vie
	vie -= degats
	vie = max(vie, 0)
	if vie < vie_avant: degats_subis.emit(vie_avant - vie)
	cible = player #On change l'aggro si le joueur attaque la tour
	
	afficher_degats(degats)
	
	if vie <= 0:
		mourir()
		
func mourir():
	# Une mort ne doit émettre le signal qu'une seule fois.
	if est_mort:
		return
	est_mort = true
	#On joue le son de mort dans un parent de l'ennemi pour qu'il reste après la mort
	var steam_death=  AudioStreamPlayer3D.new()
	steam_death.bus = &"Effets"
	get_parent().add_child(steam_death)
	steam_death.stream = preload("res://assets/sounds/ennemis/steam_death.wav")
	steam_death.global_position = global_position
	steam_death.play()
	# Une copie du visuel termine l’animation ; le vrai ennemi meurt immédiatement.
	if afficher_cendres:
		RETOUR_COMBAT.creer_cendres(self, [$Visuel/Tour, $Visuel/OeilPivot/Oeil, $Visuel/OeilPivot/Pupille], duree_cendres)
	died.emit()
	print("Bravo, vous avez tué l'ennemi")
	queue_free()

func tirer_projectile() -> void:
	if not is_instance_valid(cible) or not is_instance_valid(projectiles_tour):
		return
	var projectile = projectile_scene.instantiate()
	# Transmettre les dégâts déjà ajustés ; ne pas multiplier une deuxième fois.
	projectile.degats = degats_ennemi
	projectile.etage = etage
	projectiles_tour.add_child(projectile)
	projectile.global_position = muzzle.global_position
	# Le tir suit exactement le laser au moment du départ. L'ancienne anticipation
	# de la vitesse du joueur annoncerait une direction différente du projectile.
	projectile.direction = (cible.global_position - muzzle.global_position).normalized()

func choisir_cible():
	var cible_avant = cible #on sauvegardde la cible
	var bodies = SurfaceDetection.get_overlapping_bodies()
	if cible != null:
		distance_min = global_position.distance_to(cible.global_position)
	else:
		distance_min = 1000.0
		
	for body in bodies:
		#les cibles ne peuvent etre que des gentils libérés
		if body.is_in_group("player") or (body.is_in_group("victime") and body.is_freed):
			var distance_body = global_position.distance_to(body.global_position)
			print(body, " dbody: ",distance_body," dmin: ", distance_min)
			
			#La cible choisie est la plus proche
			if distance_body <= distance_min:
				distance_min = distance_body
				cible = body
				print(cible)
	if cible_avant !=null and cible != cible_avant:
		repos_restant = 0.0
		chargement_ecoule = duree_chargement/1.2


func couleur_degats(degats: float) -> Color:
	var t = clamp((degats - 0.9*degats_ennemi) / 1.0, 0.0, 1.0)
	
	var blanc = Color(0.998, 1.0, 0.29, 1.0)
	var orange = Color(1.0, 0.388, 0.0, 1.0)
	
	return blanc.lerp(orange, t)
	
#On affiche les dégats
var popup_tween: Tween
func afficher_degats(degats: float) -> void:
	var rd1 = randf_range(-0.1,0.1)
	var rd2 = randf_range(-0.1,0.1)
	var rd3 = randf_range(-0.1,0.1)
	
	$PopUpDegats.text = "-" + str(degats)
	$PopUpDegats.modulate = couleur_degats(degats)
	$PopUpDegats.position = Vector3(rd1,4.5+rd2 ,0+rd3)
	$PopUpDegats.font_size = 100*(1+rd2)
	$PopUpDegats.visible = true
	
	if popup_tween:
		popup_tween.kill()
	
	var position_depart = Vector3(rd1,4.5+rd2 ,0+rd3)
	var position_fin = position_depart + Vector3(rd2, 1+ rd3, 0+ rd1)
	var taille_fin = 120*(1+rd1)
	popup_tween = create_tween() #Fonction qui permet de faire un gradient

	popup_tween.parallel().tween_property($PopUpDegats,"position",position_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"font_size",taille_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"modulate:a",0.0,0.4)

	await popup_tween.finished

	$PopUpDegats.visible = false
