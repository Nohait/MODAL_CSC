extends Node3D

const AMBULANCE = preload("res://assets/tutoriel/ambulance/scene.gltf")
const SOIGNANTE = preload("res://assets/tutoriel/personnel/soignante/soignante_idle.glb")
const POLICIERE = preload("res://assets/tutoriel/personnel/policiere/policiere_idle.glb")
const BRANCARD = preload("res://assets/tutoriel/brancard/scene.gltf")
const MONITEUR = preload("res://assets/tutoriel/moniteur/scene.gltf")

func _ready() -> void:
	_placer(AMBULANCE, "Ambulance", Vector3(-11, 0, 11), PI * 0.5, 6.9)
	_placer_personnel(SOIGNANTE, "Secouriste", Vector3(-9.3, 0, 7.2), -PI * 0.5, "soignante_Idle")
	_placer_personnel(POLICIERE, "Policiere1", Vector3(3.6, 0, 7.8), -2.88, "policiere_Idle")
	_placer_personnel(POLICIERE, "Policiere2", Vector3(10.8, 0, 10.2), -2.54, "policiere_Idle", 0.8)
	# Masquer uniquement les anciens figurants de cette instance du tutoriel.
	for nom in ["Policier1", "Policier2"]:
		get_parent().get_node("Secours/" + nom).hide()
	_placer(BRANCARD, "Brancard", Vector3(-13, 0, 8), 0.0, 2.0)
	_placer(MONITEUR, "Moniteur", Vector3(-12.7, 0.9, 8.8), 0.0, 0.5)
	_preparer_rampe()

func _placer_personnel(scene: PackedScene, nom: String, position_sol: Vector3, angle: float, idle: String, decalage := 0.0) -> void:
	var support := Node3D.new()
	support.name = nom
	add_child(support)
	var modele: Node3D = scene.instantiate()
	support.add_child(modele)
	# Les GLB animés sont déjà en mètres et posés au sol : aucun redimensionnement par AABB.
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

func _placer(scene: PackedScene, nom: String, position_sol: Vector3, angle: float, dimension: float, hauteur := false) -> void:
	var support := Node3D.new()
	support.name = nom
	add_child(support)
	var modele: Node3D = scene.instantiate()
	support.add_child(modele)
	# Les exports téléchargés ont des unités et des pivots différents.
	var limites := AABB()
	var premiere := true
	for surface in modele.find_children("*", "MeshInstance3D", true, false):
		var boite: AABB = surface.get_aabb()
		for coin in range(8):
			var point := support.to_local(surface.to_global(boite.get_endpoint(coin)))
			if premiere:
				limites = AABB(point, Vector3.ZERO)
				premiere = false
			else: limites = limites.expand(point)
	var taille := limites.size.y if hauteur else maxf(limites.size.x, maxf(limites.size.y, limites.size.z))
	var facteur := dimension / maxf(taille, 0.001)
	modele.scale *= facteur
	modele.position = -Vector3(limites.get_center().x, limites.position.y, limites.get_center().z) * facteur
	support.position = position_sol
	support.rotation.y = angle
