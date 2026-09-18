extends Area3D

@export var degats_flaque := 5.0
@export var vie_max := 30.0
var vie = vie_max
@export var attaque_cooldown = 1.0
var attaque_timer = 0.0 #temps initialisé à 0
var cible = null
var hitbox_radius = 0.5

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if cible != null:
		attaque_timer -= delta
		if attaque_timer <0:
			attaque()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		cible = body
		
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		cible = null
		
		

func prendre_degats(degats: float) -> void:
	vie -= degats
	vie = max(vie, 0)
	print( self.name, " Touché : -", degats)	
	afficher_degats(degats)
	
	if vie <= 0:
		mourir()
		
func mourir():
	queue_free()

func attaque() -> void:
	print("ATTAQUE DE ", name)
	if cible != null:
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
