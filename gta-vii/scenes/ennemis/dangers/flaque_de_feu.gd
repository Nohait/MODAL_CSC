extends Area3D

@export_group("Apparition")
# Seuil dans le parcours : une salle plus tardive reste autorisée aux étages suivants.
@export_range(1, 10, 1) var premier_etage := 1
@export_range(1, 5, 1) var premiere_salle := 1

@export_group("Progression par étage")
## Pourcentage ajouté à la valeur de base par étage après le premier.
@export_range(0.0, 200.0, 1.0) var degats_par_etage_pourcent := 10.0
# Fourni par le créateur AVANT add_child, donc avant _ready.
var etage := 1


# Les flaques initiales annoncent leur destruction au RoomManager.
signal died
signal degats_subis(quantite: float)
var est_mort := false

@export_group("Statistiques de base")
@export var degats_flaque := 5.0
@export var vie_max := 30.0
var vie = vie_max
@export var attaque_cooldown = 1.0
var attaque_timer = 0.0 #temps initialisé à 0
var cible = null
var hitbox_radius = 0.5


func choisir_taille_aleatoire() -> void:
	# Appelée une seule fois à la création, pour les flaques initiales comme celles
	# des projectiles. Agrandir la racine agrandit le visuel ET la zone de dégâts.
	var facteur := randf_range(1.0, 2.0)
	scale *= facteur
	# Compenser l'agrandissement du parent pour garder un texte de taille lisible.
	$PopUpDegats.scale /= facteur
	# L'extincteur utilise ce rayon pour savoir si son jet atteint le bord du feu.
	hitbox_radius *= facteur
	
func _ready() -> void:
	# Chaque flaque reçoit un contour différent, sans dupliquer le matériau partagé.
	$MeshInstance3D.set_instance_shader_parameter("variation", randf_range(0.0, TAU))
	# Répartir de petites flammes sur la flaque, plutôt qu'étirer un feu central.
	var flammes: CPUParticles3D = $vfx_fire/Flames
	# Les réglages CPU appartiennent à l'émetteur : plus de matériau de simulation à dupliquer.
	flammes.emission_sphere_radius = 0.55
	flammes.gravity = Vector3(0, 2, 0)
	flammes.scale_amount_min = 0.4
	flammes.scale_amount_max = 0.75
	flammes.color = Color(2.5, 1.15, 0.4, 1.0)
	# L'enfant a démarré avant le _ready de la flaque : recalculer immédiatement
	# ses particules avec les réglages définitifs, avant le premier affichage.
	flammes.restart()
	# Les PV restent ceux de l’Inspecteur ; seuls les dégâts progressent par étage.
	var paliers := maxi(etage - 1, 0)
	vie = vie_max
	degats_flaque *= 1.0 + paliers * degats_par_etage_pourcent / 100.0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if is_instance_valid(cible):
		attaque_timer -= delta
		if attaque_timer <0:
			attaque()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("victime"):
		cible = body
		
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("victime"):
		cible = null
		
		

func prendre_degats(degats: float, source: StringName = &"feu") -> void:
	if est_mort:
		return
	# Le bilan écoute cette perte effective ; un coup fatal ne compte pas de PV négatifs.
	# La source distingue le jet et l’eau des coups de feu pour les combos.
	var pompier = get_tree().get_first_node_in_group("player")
	if is_instance_valid(pompier) and is_instance_valid(pompier.ameliorations):
		degats *= pompier.ameliorations.effets_cartes.modifier_degats(self, source)
	var vie_avant: float = vie
	vie -= degats
	vie = max(vie, 0)
	if vie < vie_avant: degats_subis.emit(vie_avant - vie)
	afficher_degats(degats)
	
	if vie <= 0:
		mourir()
		
func mourir():
	if est_mort:
		return
	est_mort = true
	
	# Une copie du visuel termine l’animation ; le vrai sbire meurt immédiatement.
	var steam_death=  AudioStreamPlayer3D.new()
	steam_death.bus = &"Effets"
	get_parent().add_child(steam_death)
	steam_death.stream = preload("res://assets/sounds/ennemis/steam_death.wav")
	steam_death.global_position = global_position
	steam_death.play()
	died.emit()
	queue_free()

func attaque() -> void:
	print("ATTAQUE DE ", name)
	if is_instance_valid(cible):
		var multiplier = randf_range(0.9,1.1)
		cible.prendre_degats(round(multiplier * degats_flaque *100.0)/100.0)
		print(degats_flaque)
		
	attaque_timer = attaque_cooldown


func couleur_degats(degats: float) -> Color:
	
	var t = clamp((degats - 0.9*degats_flaque) / 1.0, 0.0, 1.0)
	
	var blanc = Color(0.998, 1.0, 0.29, 1.0)
	var orange = Color(1.0, 0.388, 0.0, 1.0)
	
	return blanc.lerp(orange, t)
	
#On affiche les dégats
var popup_tween: Tween
func afficher_degats(degats: float) -> void:
	var rd1 = randf_range(-0.1,0.1)
	var rd2 = randf_range(-0.1,0.1)
	var rd3 = randf_range(-0.1,0.1)
	
	# Afficher deux décimales sans modifier les dégâts réellement infligés.
	$PopUpDegats.text = "-%.2f" % degats
	$PopUpDegats.modulate = couleur_degats(degats)
	$PopUpDegats.position = Vector3(rd1,0.7+rd2 ,0+rd3)
	$PopUpDegats.font_size = roundi(46 * (1 + rd2))
	$PopUpDegats.outline_size = 4
	$PopUpDegats.visible = true
	
	if popup_tween:
		popup_tween.kill()
	
	var position_depart = Vector3(rd1,0.7+rd2 ,0+rd3)
	var position_fin = position_depart + Vector3(rd2, 1+ rd3, 0+ rd1)
	var taille_fin = roundi(48 * (1 + rd1))
	popup_tween = create_tween() #Fonction qui permet de faire un gradient

	popup_tween.parallel().tween_property($PopUpDegats,"position",position_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"font_size",taille_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"modulate:a",0.0,0.4)

	await popup_tween.finished

	$PopUpDegats.visible = false
