extends Area3D

@export_group("Progression par étage")
## Pourcentage ajouté à la valeur de base par étage après le premier.
@export_range(0.0, 200.0, 1.0) var pv_par_etage_pourcent := 20.0
@export_range(0.0, 200.0, 1.0) var degats_par_etage_pourcent := 10.0
# Fourni par le créateur AVANT add_child, donc avant _ready.
var etage := 1


# Les flaques initiales annoncent leur destruction au RoomManager.
signal died
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
	# Appliquer une seule fois à l'apparition, à partir des valeurs de l'Inspecteur.
	# Étage 1 = base ; étage 3 avec +20 % = base × 1.4 (progression linéaire).
	var paliers := maxi(etage - 1, 0)
	vie_max *= 1.0 + paliers * pv_par_etage_pourcent / 100.0
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
		
		

func prendre_degats(degats: float) -> void:
	if est_mort:
		return
	vie -= degats
	vie = max(vie, 0)
	afficher_degats(degats)
	
	if vie <= 0:
		mourir()
		
func mourir():
	if est_mort:
		return
	est_mort = true
	
	# Une copie du visuel termine l’animation ; le vrai sbire meurt immédiatement.
	var steam_death=  AudioStreamPlayer3D.new()
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
	
	$PopUpDegats.text = "-" + str(degats)
	$PopUpDegats.modulate = couleur_degats(degats)
	$PopUpDegats.position = Vector3(rd1,0.7+rd2 ,0+rd3)
	$PopUpDegats.font_size = 100*(1+rd2)
	$PopUpDegats.visible = true
	
	if popup_tween:
		popup_tween.kill()
	
	var position_depart = Vector3(rd1,0.7+rd2 ,0+rd3)
	var position_fin = position_depart + Vector3(rd2, 1+ rd3, 0+ rd1)
	var taille_fin = 120*(1+rd1)
	popup_tween = create_tween() #Fonction qui permet de faire un gradient

	popup_tween.parallel().tween_property($PopUpDegats,"position",position_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"font_size",taille_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"modulate:a",0.0,0.4)

	await popup_tween.finished

	$PopUpDegats.visible = false
