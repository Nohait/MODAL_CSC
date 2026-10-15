extends Node3D

const POMPIER = preload("res://scenes/joueur/player_pompier.tscn")
const SBIRE = preload("res://assets/modeles/ennemis/mobiles/sbire/sbire.tscn")
const SOL = preload("res://assets/materiaux/sol_appartements.tres")
const MUR = preload("res://assets/materiaux/mur_appartements.tres")
const FOYER = preload("res://scenes/decors/hall_incendie/foyer_incendie.tscn")
const FINITIONS = preload("res://scenes/salles/finitions_parcours.tres")
const PORTE = preload("res://scenes/decors/interieurs/porte_entrouverte.tscn")
const APPLIQUE = preload("res://assets/modeles/parking/industrial_wall_lamp_2k.gltf/industrial_wall_lamp_2k.gltf")
const SAC = preload("res://scenes/decors/interieurs/evacuation_sac.tscn")
@export_range(0, 150, 1) var nombre_braises := 45
@export_range(0.0, 0.2, 0.005) var amplitude_camera := 0.045
@export_range(4.0, 30.0, 1.0) var periode_camera := 18.0
@export_range(0, 30, 1) var nombre_volutes := 9
@export_range(0.0, 3.0, 0.05) var intensite_gyrophares := 0.65
@export_group("Composition des personnages")
@export var position_pompier := Vector3(-0.8, 1.1, 1.0)
@export var position_sbire := Vector3(1.5, 0.6291781, -2.8)
@export_range(0.0, 5.0, 0.1) var energie_pompier := 2.1
@export_range(0.0, 5.0, 0.1) var energie_contour_sbire := 2.6
var temps := 0.0
var lumiere_feu: OmniLight3D
var camera: Camera3D
var position_camera: Vector3
var lumiere_bleue: OmniLight3D
var lumiere_rouge: OmniLight3D
var applique: Node3D
var lumiere_applique: OmniLight3D
var prochain_clignotement := 5.0
var depart_en_cours := false

func _ready() -> void:
	camera = get_node("Camera")
	position_camera = camera.position
	# Seulement les modèles visuels : ni IA, ni attaque, ni interface du joueur.
	var pompier = POMPIER.instantiate()
	pompier.scale *= 0.125
	# Comme dans player.tscn, l'origine du modèle est au centre du personnage.
	pompier.position = position_pompier
	pompier.rotation.y += 0.65 + PI
	add_child(pompier)
	pompier.get_node("visual/Armature/AnimationTree").active = false
	pompier.get_node("visual/Armature/AnimationPlayer").play("Idle/Idle")
	var sbire = SBIRE.instantiate()
	# Reprendre l'échelle du sbire en jeu : sa boîte de mesh ne couvre pas la pose du squelette.
	sbire.scale = Vector3.ONE * 0.295
	sbire.position = position_sbire
	var direction_pompier := position_pompier - position_sbire
	sbire.rotation.y = atan2(direction_pompier.x, direction_pompier.z)
	add_child(sbire)
	var animation_sbire: AnimationPlayer = sbire.get_node("Armature/AnimationPlayer")
	# Une copie locale permet de boucler la pose sans modifier les animations en jeu.
	var idle := animation_sbire.get_animation("idle").duplicate() as Animation
	idle.loop_mode = Animation.LOOP_LINEAR
	var bibliotheque := AnimationLibrary.new()
	bibliotheque.add_animation("idle", idle)
	animation_sbire.add_animation_library("titre", bibliotheque)
	animation_sbire.play("titre/idle")
	_eclairer_personnage("EclairagePompier", Vector3(1.8, 3.7, 3.4), position_pompier, Color("b5d9ff"), energie_pompier)
	_eclairer_personnage("ContourSbire", Vector3(1.9, 3.0, -4.7), position_sbire + Vector3.UP * 0.65, Color("ff6e24"), energie_contour_sbire)
	# Atténuer le bain uniforme pour que les éclairages des silhouettes ressortent.
	$Lumiere.light_energy = 0.65
	_bloc(Vector3(0, -0.15, -1.0), Vector3(14, 0.3, 16), SOL)
	_bloc(Vector3(0, 2, -6), Vector3(14, 4, 0.3), MUR)
	_bloc(Vector3(-4.5, 2, -1), Vector3(0.3, 4, 10), MUR)
	_finitions_mur(Vector3(1.345, 0, -5.85), 11.31, 0.0)
	_finitions_mur(Vector3(-4.35, 0, -0.905), 9.81, PI / 2)
	_creer_details()
	_creer_braises()
	_creer_fumee()
	lumiere_bleue = _lumiere_exterieure("GyrophareBleu", Vector3(3.5, 1.5, 3), Color("407dff"))
	lumiere_rouge = _lumiere_exterieure("GyrophareRouge", Vector3(-2.5, 1.5, 3), Color("ff4930"))
	lumiere_feu = OmniLight3D.new()
	lumiere_feu.position = Vector3(2.2, 1.5, -3.4)
	lumiere_feu.light_color = Color("ff852f")
	lumiere_feu.omni_range = 5.0
	add_child(lumiere_feu)

func _process(delta: float) -> void:
	temps += delta
	if temps >= prochain_clignotement:
		prochain_clignotement = temps + randf_range(4.0, 7.0)
		_clignoter_applique()
	# Deux fréquences donnent une lumière de feu moins mécanique qu'un seul sinus.
	lumiere_feu.light_energy = 1.0 + sin(temps * 5.0) * 0.1 + sin(temps * 8.7) * 0.06
	var cycle := temps * TAU / periode_camera
	# Le déplacement reste centré sur le cadrage initial, sans dérive au fil du temps.
	if not depart_en_cours:
		camera.position = position_camera + Vector3(sin(cycle), sin(cycle * 0.7) * 0.45, 0) * amplitude_camera
	# Des passages lumineux doux évoquent les véhicules stationnés hors champ.
	lumiere_bleue.light_energy = pow(maxf(0.0, sin(temps * 2.4)), 6.0) * intensite_gyrophares
	lumiere_rouge.light_energy = pow(maxf(0.0, sin(temps * 2.4 + PI)), 6.0) * intensite_gyrophares

func _eclairer_personnage(nom: String, origine: Vector3, cible: Vector3, couleur: Color, energie: float) -> void:
	var lumiere := SpotLight3D.new()
	lumiere.name = nom
	lumiere.position = origine
	lumiere.light_color = couleur
	lumiere.light_energy = energie
	lumiere.spot_range = 7.0
	lumiere.spot_angle = 32.0
	lumiere.spot_angle_attenuation = 1.5
	lumiere.shadow_enabled = false
	add_child(lumiere)
	lumiere.look_at(to_global(cible), Vector3.UP)

func _creer_details() -> void:
	var porte = PORTE.instantiate()
	porte.position = Vector3(3.6, 0, -5.82)
	porte.energie_lueur = 0.9
	porte.portee_lueur = 4.0
	add_child(porte)
	# La porte décorative a son fond opaque ; elle masque les finitions situées derrière.
	applique = APPLIQUE.instantiate()
	add_child(applique)
	# Une véritable applique murale remplace le plafonnier détourné.
	var boite_applique := _limites_visuelles(applique)
	var largeur := maxf(boite_applique.size.x, boite_applique.size.y)
	if largeur > 0:
		applique.scale *= 0.45 / largeur
	_plaquer_au_mur(applique, Vector2(-2.6, 2.6))
	lumiere_applique = OmniLight3D.new()
	lumiere_applique.position = Vector3(-2.6, 2.6, -5.35)
	lumiere_applique.light_color = Color("ffcf8f")
	lumiere_applique.light_energy = 0.8
	lumiere_applique.omni_range = 4.0
	add_child(lumiere_applique)
	var sac = SAC.instantiate()
	sac.position = Vector3(-3.6, 0, -3.8)
	sac.rotation.y = -0.4
	add_child(sac)

func _limites_visuelles(modele: Node3D) -> AABB:
	var limites := AABB()
	var premier := true
	var surfaces := modele.find_children("*", "MeshInstance3D", true, false)
	# Certains imports glTF ont leur mesh à la racine, sans enfant visuel.
	if modele is MeshInstance3D:
		surfaces.append(modele)
	for surface: MeshInstance3D in surfaces:
		var boite: AABB = global_transform.affine_inverse() * surface.global_transform * surface.get_aabb()
		limites = boite if premier else limites.merge(boite)
		premier = false
	return limites

func _plaquer_au_mur(modele: Node3D, centre: Vector2) -> void:
	var limites := _limites_visuelles(modele)
	# Aligner le dos réel du mesh, plutôt que son origine importée souvent décalée.
	modele.position += Vector3(centre.x - limites.get_center().x, centre.y - limites.get_center().y, -5.845 - limites.position.z)

func _clignoter_applique() -> void:
	var animation := create_tween()
	for i in range(randi_range(1, 2)):
		animation.tween_callback(func(): lumiere_applique.light_energy = 0.0)
		animation.tween_interval(0.14)
		animation.tween_callback(func(): lumiere_applique.light_energy = 0.8)
		animation.tween_interval(0.1)
	animation.tween_callback(func(): lumiere_applique.light_energy = 0.0)
	animation.tween_interval(0.8)
	animation.tween_callback(func(): lumiere_applique.light_energy = 0.8)

func animer_depart(duree: float) -> void:
	depart_en_cours = true
	var animation := create_tween()
	animation.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	animation.tween_property(camera, "position", camera.position - camera.global_basis.z * 0.45, duree)

func _lumiere_exterieure(nom: String, position_lumiere: Vector3, couleur: Color) -> OmniLight3D:
	var lumiere := OmniLight3D.new()
	lumiere.name = nom
	lumiere.position = position_lumiere
	lumiere.light_color = couleur
	lumiere.light_energy = 0.0
	lumiere.omni_range = 8.0
	lumiere.shadow_enabled = false
	add_child(lumiere)
	return lumiere

func _creer_fumee() -> void:
	if nombre_volutes == 0:
		return
	var modele_foyer := FOYER.instantiate()
	var fumee: CPUParticles3D = modele_foyer.get_node("Fumee")
	modele_foyer.remove_child(fumee)
	modele_foyer.free()
	fumee.name = "FumeeAuSol"
	fumee.amount = nombre_volutes
	fumee.position = Vector3(0, 0.25, -3.5)
	fumee.emission_box_extents = Vector3(3.2, 0.05, 1.0)
	fumee.direction = Vector3(1, 0.08, 0.2)
	fumee.initial_velocity_min = 0.15
	fumee.initial_velocity_max = 0.3
	fumee.gravity = Vector3(0.02, 0.015, 0)
	add_child(fumee)

func _finitions_mur(origine: Vector3, longueur: float, angle: float) -> void:
	var parent := Node3D.new()
	parent.position = origine
	parent.rotation.y = angle
	add_child(parent)
	var peinture := StandardMaterial3D.new()
	peinture.albedo_color = FINITIONS.teintes[0]
	peinture.roughness = 0.75
	var hauteur: float = FINITIONS.hauteur_soubassement
	var plinthe: float = FINITIONS.hauteur_plinthe
	var moulure: float = FINITIONS.hauteur_moulure
	# Les faces dépassent légèrement du mur ; les baguettes ne recouvrent pas la peinture.
	for element in [
		["Soubassement", Vector3(0, (plinthe + hauteur - moulure) / 2, 0.025), Vector3(longueur, hauteur - plinthe - moulure - 0.004, 0.02), peinture],
		["Plinthe", Vector3(0, plinthe / 2, 0.035), Vector3(longueur, plinthe, 0.035), FINITIONS.bois],
		["Moulure", Vector3(0, hauteur - moulure / 2, 0.035), Vector3(longueur, moulure, 0.035), FINITIONS.bois]
	]:
		var surface := MeshInstance3D.new()
		surface.name = element[0]
		var cube := BoxMesh.new()
		cube.size = element[2]
		cube.material = element[3]
		surface.mesh = cube
		surface.position = element[1]
		parent.add_child(surface)

func _creer_braises() -> void:
	if nombre_braises == 0:
		return
	# Extraire l'émetteur du foyer conserve son grain, son fondu et les rafales de vent.
	var modele_foyer := FOYER.instantiate()
	var braises: CPUParticles3D = modele_foyer.get_node("Braises")
	modele_foyer.remove_child(braises)
	modele_foyer.free()
	braises.amount = nombre_braises
	braises.position = Vector3(0, 0.4, -2)
	braises.emission_box_extents = Vector3(3.5, 0.1, 2.5)
	add_child(braises)

func _bloc(position_bloc: Vector3, taille: Vector3, mat: Material) -> void:
	var visuel := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = taille
	mesh.material = mat
	visuel.mesh = mesh
	visuel.position = position_bloc
	add_child(visuel)
