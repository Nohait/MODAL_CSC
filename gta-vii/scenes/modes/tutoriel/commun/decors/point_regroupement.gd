extends Node3D

const AMBULANCE = preload("res://assets/tutoriel/ambulance/scene.gltf")
const SOIGNANTE = preload("res://assets/tutoriel/personnel/soignante/soignante_idle.glb")
const POLICIERE = preload("res://assets/tutoriel/personnel/policiere/policiere_idle.glb")
const BRANCARD = preload("res://assets/tutoriel/brancard/scene.gltf")
const MONITEUR = preload("res://assets/tutoriel/moniteur/scene.gltf")

@export_range(1.0, 2.0, 0.01) var echelle_policiere := 1.61
@export var correction_pieds_policiere := -1.023
@export_range(0.15, 0.5, 0.01) var rayon_personnel := 0.3
@export var position_camion := Vector3(-3, -0.03, 14.8)
@export var position_second_camion := Vector3(-12, -0.03, 18)
const SOL_RUE := -0.03

func _ready() -> void:
	_preparer_vehicules()
	_placer(AMBULANCE, "Ambulance", Vector3(-11, SOL_RUE, 11), PI * 0.5, 6.9)
	_placer_personnel(SOIGNANTE, "Secouriste", Vector3(-9.3, SOL_RUE, 7.2), -PI * 0.5, "soignante_Idle")
	_placer_personnel(POLICIERE, "Policiere1", Vector3(3.6, SOL_RUE, 7.8), -2.88, "policiere_Idle")
	_placer_personnel(POLICIERE, "Policiere2", Vector3(10.8, SOL_RUE, 10.2), -2.54, "policiere_Idle", 0.8)
	# Masquer uniquement les anciens figurants de cette instance du tutoriel.
	for nom in ["Policier1", "Policier2"]:
		get_parent().get_node("Secours/" + nom).hide()
	_placer(BRANCARD, "Brancard", Vector3(-13, SOL_RUE, 8), 0.0, 2.0)
	_placer(MONITEUR, "Moniteur", Vector3(-12.7, 0.9, 8.8), 0.0, 0.5)
	_preparer_rampe()

func _placer_personnel(scene: PackedScene, nom: String, position_sol: Vector3, angle: float, idle: String, decalage := 0.0) -> void:
	var support := Node3D.new()
	support.name = nom
	add_child(support)
	var modele: Node3D = scene.instantiate()
	support.add_child(modele)
	# Mesures de la pose animée : l'AABB d'import ne décrit pas ces maillages skinnés.
	var hauteur := 1.72
	if scene == POLICIERE:
		modele.scale *= echelle_policiere
		modele.position.y = correction_pieds_policiere
		hauteur = 1.0873 * echelle_policiere
	else:
		modele.position.y = -0.006
	var capsule := CapsuleShape3D.new()
	capsule.radius = rayon_personnel
	capsule.height = hauteur
	_ajouter_collision(support, capsule, Vector3(0, hauteur * 0.5, 0))
	support.position = position_sol
	support.rotation.y = angle
	var lecteur: AnimationPlayer = modele.find_child("AnimationPlayer", true, false)
	var banque := lecteur.get_animation_library("").duplicate(true) as AnimationLibrary
	banque.get_animation(idle).loop_mode = Animation.LOOP_LINEAR
	lecteur.remove_animation_library("")
	lecteur.add_animation_library("", banque)
	lecteur.play(idle)
	lecteur.seek(decalage, true)
	lecteur.advance(0)

func _preparer_vehicules() -> void:
	var secours: Node3D = get_parent().get_node("Secours")
	# Adapter cette instance du parvis uniquement, sans modifier le décor partagé du Hall.
	for nom in ["Camion", "SecondCamion", "Police1", "Police2"]:
		var vehicule: Node3D = secours.get_node(nom)
		if nom == "Camion":
			vehicule.position = position_camion - secours.position
		elif nom == "SecondCamion":
			vehicule.position = position_second_camion - secours.position
		else:
			vehicule.position.y = SOL_RUE - secours.position.y
		_collision_boite(vehicule, _limites(vehicule.get_node("Modele"), vehicule))

func _ajouter_collision(support: Node3D, forme: Shape3D, centre: Vector3) -> void:
	var corps := StaticBody3D.new()
	corps.name = "Obstacle"
	corps.collision_layer = 1
	corps.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = forme
	collision.position = centre
	corps.add_child(collision)
	support.add_child(corps)

func _collision_boite(support: Node3D, limites: AABB) -> void:
	var forme := BoxShape3D.new()
	forme.size = limites.size
	_ajouter_collision(support, forme, limites.get_center())

func _limites(modele: Node3D, support: Node3D) -> AABB:
	var limites := AABB()
	var premiere := true
	for surface in modele.find_children("*", "MeshInstance3D", true, false):
		var boite: AABB = surface.get_aabb()
		for coin in range(8):
			var point := support.to_local(surface.to_global(boite.get_endpoint(coin)))
			if premiere:
				limites = AABB(point, Vector3.ZERO)
				premiere = false
			else:
				limites = limites.expand(point)
	return limites

func _preparer_rampe() -> void:
	var rampe := MeshInstance3D.new()
	rampe.name = "Rampe"
	var surface := BoxMesh.new()
	# Même pente que le trajet des figurants : sol à z=6.7, accès à z=8.15.
	surface.size = Vector3(1.5, 0.06, Vector2(1.45, 0.65).length())
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.28, 0.3, 0.32)
	metal.metallic = 0.65
	metal.roughness = 0.7
	surface.material = metal
	rampe.mesh = surface
	rampe.position = Vector3(-11, 0.325, 7.425)
	rampe.rotation.x = -atan2(0.65, 1.45)
	add_child(rampe)
	_collision_boite(rampe, surface.get_aabb())

func _placer(scene: PackedScene, nom: String, position_sol: Vector3, angle: float, dimension: float, hauteur := false) -> void:
	var support := Node3D.new()
	support.name = nom
	add_child(support)
	var modele: Node3D = scene.instantiate()
	support.add_child(modele)
	# Les exports téléchargés ont des unités et des pivots différents.
	var limites := _limites(modele, support)
	var taille := limites.size.y if hauteur else maxf(limites.size.x, maxf(limites.size.y, limites.size.z))
	var facteur := dimension / maxf(taille, 0.001)
	modele.scale *= facteur
	modele.position = -Vector3(limites.get_center().x, limites.position.y, limites.get_center().z) * facteur
	support.position = position_sol
	support.rotation.y = angle
	_collision_boite(support, _limites(modele, support))
