extends Node3D

signal invocation_demandee(invocations: Array[Dictionary])

@export_range(1, 8, 1) var nombre_sbires := 3
@export_range(1, 20, 1) var maximum_vivants := 6
@export_range(1.0, 30.0, 0.5) var premiere_invocation := 6.0
@export_range(3.0, 60.0, 0.5) var delai_invocations := 12.0
@export_range(0.5, 5.0, 0.1) var preparation := 2.2
@export_range(0.1, 2.0, 0.1) var recuperation := 0.8
@export_range(2.0, 8.0, 0.1) var distance_invocation := 3.8
@export var couleur := Color(1.0, 0.55, 0.08)

@export_group("Deuxième phase")
@export_range(1, 20, 1) var maximum_vivants_phase_deux := 12
@export_range(0, 12, 1) var sbires_ralliement := 6
@export_range(0, 12, 1) var kamikazes_ralliement := 4
@export_range(0, 8, 1) var sbires_phase_deux := 3
@export_range(0, 8, 1) var kamikazes_phase_deux := 2
@export_range(3.0, 60.0, 0.5) var delai_phase_deux := 9.0
@export_range(0.0, 10.0, 0.1) var attente_apres_colere := 1.5
@export_range(0.5, 3.0, 0.1) var hauteur_kamikaze := 1.2

const KAMIKAZE = preload("res://scenes/ennemis/mobiles/kamikaze/kamikaze.tscn")
const SBIRE = preload("res://scenes/ennemis/mobiles/sbire.tscn")
var attente := 0.0
var positions: Array[Vector3] = []
var annonces: Array[MeshInstance3D] = []
var phase_deux := false
var duree_charge := 2.2
var types_planifies: Array[StringName] = []
var formes: Dictionary = {}
@onready var boss = get_parent()

func _ready() -> void:
	attente = premiere_invocation
	for type in [&"sbire", &"kamikaze"]:
		var scene: PackedScene = SBIRE if type == &"sbire" else KAMIKAZE
		var modele = scene.instantiate()
		formes[type] = {"scene": scene, "shape": modele.get_node("CollisionShape3D").shape, "transform": modele.get_node("CollisionShape3D").transform}
		modele.free()

func passer_en_phase_deux() -> void:
	phase_deux = true
	attente = minf(attente, attente_apres_colere)

func avancer(delta: float) -> void:
	# Le boss appelle cette méthode : gel et pause suspendent le compte à rebours.
	attente = maxf(0.0, attente - delta)
	if boss.etat in ["invocation", "colere"]:
		for annonce in annonces:
			annonce.charger(1.0 - clampf(boss.temps_etat / maxf(duree_charge, 0.01), 0.0, 1.0))

func _nombre_vivants() -> int:
	var nombre := 0
	for ennemi in boss.get_parent().get_children():
		if ennemi.get_meta("boss_invocateur", 0) == boss.get_instance_id() and not ennemi.is_queued_for_deletion() and not ennemi.est_mort:
			nombre += 1
	return nombre

func eliminer_invocations() -> void:
	# L'identifiant distingue ses renforts des ennemis naturels et de ceux d'un autre boss.
	for ennemi in boss.get_parent().get_children():
		if ennemi.get_meta("boss_invocateur", 0) != boss.get_instance_id(): continue
		if ennemi.is_queued_for_deletion() or ennemi.est_mort: continue
		ennemi.set_meta("fin_invocation", true)
		# Une vraie mort garde les cendres, les signaux et le compteur de vague cohérents.
		ennemi.mourir()

func commencer(ralliement := false, duree_ralliement := 0.0) -> bool:
	if (attente > 0.0 and not ralliement) or invocation_demandee.get_connections().is_empty(): return false
	var limite := maximum_vivants_phase_deux if phase_deux else maximum_vivants
	var souhaites: Array[StringName] = []
	# Alterner les types pour garder des kamikazes même s'il reste peu de places.
	var sbires := sbires_ralliement if ralliement else (sbires_phase_deux if phase_deux else nombre_sbires)
	var kamikazes := kamikazes_ralliement if ralliement else (kamikazes_phase_deux if phase_deux else 0)
	for i in range(maxi(sbires, kamikazes)):
		if i < sbires: souhaites.append(&"sbire")
		if i < kamikazes: souhaites.append(&"kamikaze")
	var places := mini(souhaites.size(), limite - _nombre_vivants())
	if places <= 0: return false
	positions.clear()
	types_planifies.clear()
	duree_charge = duree_ralliement if ralliement and duree_ralliement > 0.0 else preparation
	# Un nombre borné de tentatives évite une boucle infinie dans un coin encombré.
	for i in range(24):
		var angle: float = boss.rotation.y + float(i) * TAU / 12.0
		var point: Vector3 = boss.global_position + Vector3(sin(angle), 0, cos(angle)) * (distance_invocation + floori(float(i) / 12.0) * 1.5)
		var sol := _chercher_sol(point)
		if sol.is_empty(): continue
		point = sol.position
		if not _point_libre(point, souhaites[positions.size()]): continue
		var trop_proche := false
		for autre in positions:
			if autre.distance_to(point) < 1.5: trop_proche = true
		if trop_proche: continue
		types_planifies.append(souhaites[positions.size()])
		positions.append(point)
		if positions.size() >= places: break
	if positions.is_empty():
		attente = 1.0
		return false
	for point in positions:
		var annonce = preload("res://scenes/effets/apparition/cercle_apparition.tscn").instantiate()
		annonce.couleur = couleur
		add_child(annonce)
		annonce.top_level = true
		annonce.global_position = point + Vector3.UP * 0.035
		annonces.append(annonce)
	return true

func terminer() -> void:
	var libres: Array[Dictionary] = []
	var limite := maximum_vivants_phase_deux if phase_deux else maximum_vivants
	var places := maxi(0, limite - _nombre_vivants())
	# Recontrôler les collisions et le plafond au moment de la création.
	for i in range(positions.size()):
		var type := types_planifies[i]
		if libres.size() >= places: break
		if _point_libre(positions[i], type):
			libres.append({"position": positions[i], "scene": formes[type].scene, "hauteur": hauteur_kamikaze if type == &"kamikaze" else 0.75})
	invocation_demandee.emit(libres)
	for annonce in annonces: annonce.queue_free()
	annonces.clear()
	positions.clear()
	types_planifies.clear()
	attente = delai_phase_deux if phase_deux else delai_invocations

func _chercher_sol(point: Vector3) -> Dictionary:
	var rayon := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0, point - Vector3.UP * 6.0, 1)
	return boss.get_world_3d().direct_space_state.intersect_ray(rayon)

func _point_libre(point: Vector3, type: StringName = &"sbire") -> bool:
	var carte: RID = boss.get_node("NavigationAgent").get_navigation_map()
	if not carte.is_valid() or NavigationServer3D.map_get_iteration_id(carte) == 0: return false
	if NavigationServer3D.map_get_closest_point(carte, point).distance_to(point) > 0.5: return false
	var requete := PhysicsShapeQueryParameters3D.new()
	requete.shape = formes[type].shape
	requete.collision_mask = 15
	requete.transform = Transform3D(Basis.IDENTITY, point + Vector3.UP * (hauteur_kamikaze if type == &"kamikaze" else 0.75)) * formes[type].transform
	return boss.get_world_3d().direct_space_state.intersect_shape(requete, 1).is_empty()
