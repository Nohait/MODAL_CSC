extends Node3D

@export_range(0.3, 2.0, 0.1) var duree := 0.9
@export_range(0.1, 1.0, 0.05) var hauteur_montee := 0.35
@export_range(-30.0, 0.0, 1.0) var volume_son := -12.0
@export_range(0.2, 3.0, 0.1) var intervalle_son := 0.8

var refuge
var symbole: Sprite3D
var nombre: Label3D
var son: AudioStreamPlayer3D
var animation: Tween
var pertes := 0
var dernier_son := -10000

func _ready() -> void:
	refuge = get_parent()
	# Le parent crée ses indicateurs dans _ready ; on attend qu'ils existent.
	refuge.ready.connect(_preparer, CONNECT_ONE_SHOT)

func _preparer() -> void:
	symbole = Sprite3D.new()
	symbole.texture = refuge.ICONE
	symbole.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	symbole.pixel_size = refuge.icone_victimes.pixel_size
	symbole.no_depth_test = true
	symbole.modulate = Color("ff8b75")
	add_child(symbole)
	nombre = Label3D.new()
	nombre.text = "−1"
	nombre.font_size = 23
	nombre.pixel_size = 0.01
	nombre.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nombre.no_depth_test = true
	nombre.modulate = Color("ff8b75")
	add_child(nombre)
	son = AudioStreamPlayer3D.new()
	son.stream = preload("res://assets/sounds/victimes/victim_death2.wav")
	son.bus = &"Effets"
	son.volume_db = volume_son
	son.max_distance = 25.0
	add_child(son)
	hide()
	refuge.victime_perdue.connect(_signaler_perte)

func _signaler_perte() -> void:
	# Les pertes rapprochées partagent un seul indicateur, sans empiler les sons.
	pertes = pertes + 1 if visible else 1
	if animation: animation.kill()
	symbole.position = refuge.icone_victimes.position + Vector3(0, 0.2, 0)
	nombre.position = refuge.compteur.position + Vector3(0, 0.2, 0)
	nombre.text = "−%d" % pertes
	symbole.modulate.a = 1.0
	nombre.modulate.a = 1.0
	show()
	var maintenant := Time.get_ticks_msec()
	if maintenant - dernier_son >= intervalle_son * 1000.0:
		son.play()
		dernier_son = maintenant
	animation = create_tween().set_parallel(true)
	# Le pictogramme et le nombre montent ensemble ; le fondu commence après un court temps de lecture.
	animation.tween_property(symbole, "position:y", symbole.position.y + hauteur_montee, duree).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	animation.tween_property(nombre, "position:y", nombre.position.y + hauteur_montee, duree).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	animation.tween_property(symbole, "modulate:a", 0.0, duree * 0.65).set_delay(duree * 0.35)
	animation.tween_property(nombre, "modulate:a", 0.0, duree * 0.65).set_delay(duree * 0.35)
	animation.chain().tween_callback(hide)
