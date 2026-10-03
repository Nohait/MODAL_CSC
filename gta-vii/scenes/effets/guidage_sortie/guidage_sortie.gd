extends Node3D

const FLECHE = preload("res://scenes/effets/fleche_victime/fleche.tscn")
@export var delai_affichage := 20.0
@export var rayon := 1.7
# Le centre du CharacterBody correspond approximativement à la taille du joueur.
@export var hauteur := 0.0
@export var vitesse_rotation := 4.0
var joueur: Node3D
var salle: Node3D
var temps := 0.0
var angle := 0.0

func _ready() -> void:
	# Réutiliser le mesh sans les transformations du marqueur d’ordre aux victimes.
	var modele := FLECHE.instantiate()
	var original: MeshInstance3D = modele.find_children("*", "MeshInstance3D", true, false)[0]
	var support := Node3D.new()
	add_child(support)
	var visuel := MeshInstance3D.new()
	visuel.mesh = original.mesh
	visuel.position = -visuel.mesh.get_aabb().get_center()
	visuel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.07, 0.035)
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.02, 0.01)
	mat.emission_energy_multiplier = 0.8
	visuel.material_override = mat
	support.add_child(visuel)
	# Le modèle pointe vers -Y ; le coucher lui fait indiquer -Z, à une petite taille.
	support.rotation.x = PI / 2.0
	support.scale = Vector3.ONE * 0.16
	modele.free()
	hide()

func demarrer(cible: Node3D, piece: Node3D) -> void:
	arreter()
	joueur = cible
	salle = piece
	var sortie := _sortie_la_plus_proche()
	if is_instance_valid(sortie):
		var direction := sortie.global_position - joueur.global_position
		angle = atan2(direction.x, direction.z)

func arreter() -> void:
	salle = null
	joueur = null
	temps = 0.0
	hide()

func _sortie_la_plus_proche() -> Node3D:
	var proche: Node3D
	var distance := INF
	for porte in salle.get_node("Portes").get_children():
		var ecart: Vector3 = porte.global_position - joueur.global_position
		ecart.y = 0.0
		if ecart.length_squared() < distance:
			distance = ecart.length_squared()
			proche = porte
	return proche

func _process(delta: float) -> void:
	if not is_instance_valid(salle) or not is_instance_valid(joueur):
		hide()
		return
	if joueur.est_mort:
		arreter()
		return
	temps += delta
	var sortie := _sortie_la_plus_proche()
	if not is_instance_valid(sortie):
		hide()
		return
	var direction := sortie.global_position - joueur.global_position
	var cible := atan2(direction.x, direction.z)
	# wrapf prend le chemin angulaire le plus court, même entre -PI et PI.
	# Limiter le pas évite aussi un brusque demi-tour si la porte la plus proche change.
	var ecart := wrapf(cible - angle, -PI, PI)
	var pas := ecart * (1.0 - exp(-vitesse_rotation * delta))
	angle += clampf(pas, -PI * delta, PI * delta)
	var orbite := Vector3(sin(angle), 0.0, cos(angle))
	global_position = joueur.global_position + orbite * rayon + Vector3.UP * (hauteur + sin(temps * 2.5) * 0.08)
	global_rotation = Vector3(0.0, angle + PI, 0.0)
	visible = temps >= delai_affichage
