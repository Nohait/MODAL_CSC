extends Node3D

signal ramassee
@export var duree_chute := 0.4
@export var duree_flottement := 0.3
@export var duree_collecte := 0.65
@export var hauteur_arc := 2.0
var joueur: Node3D
var origine := Vector3.ZERO
var point_sol := Vector3.ZERO
var depart_arc := Vector3.ZERO
var temps := 0.0
var phase := 0.0
var decalage := 0.0
var trajectoire := ImmediateMesh.new()
@onready var visuel: Node3D = $Visuel
@onready var rayon: MeshInstance3D = $Rayon

func _ready() -> void:
	origine = global_position
	depart_arc = point_sol + Vector3.UP * 0.16
	phase = randf() * TAU
	rayon.top_level = true
	rayon.global_transform = Transform3D.IDENTITY
	rayon.mesh = trajectoire

func _process(delta: float) -> void:
	if not is_instance_valid(joueur) or joueur.get("est_mort") == true:
		queue_free()
		return
	temps += delta
	visuel.rotation.y += delta * 4.0
	var chute := clampf(temps / duree_chute, 0.0, 1.0)
	if temps < duree_chute:
		# Une petite impulsion écarte les pièces ; elles retombent sans corps physique.
		global_position = origine.lerp(point_sol, chute) + Vector3.UP * sin(chute * PI) * 0.65
		return
	var attente := duree_chute + duree_flottement + decalage
	if temps < attente:
		global_position = point_sol + Vector3.UP * (0.16 + sin(temps * 6.0 + phase) * 0.05)
		depart_arc = global_position
		return
	var progression := clampf((temps - attente) / duree_collecte, 0.0, 1.0)
	var destination: Vector3 = joueur.global_position + Vector3.UP * 0.35
	# Le point de contrôle est au-dessus du milieu : l'arc reste dans un plan vertical.
	var controle := (depart_arc + destination) / 2.0 + Vector3.UP * hauteur_arc
	global_position = _point_arc(progression, controle, destination)
	visuel.scale = Vector3.ONE * (1.0 - progression * 0.75)
	_dessiner_rayon(progression, controle, destination)
	if progression >= 1.0:
		ramassee.emit()
		queue_free()

func _point_arc(progression: float, controle: Vector3, destination: Vector3) -> Vector3:
	# Bézier quadratique : départ → point haut → joueur, qui peut continuer à bouger.
	var inverse := 1.0 - progression
	return inverse * inverse * depart_arc + 2.0 * inverse * progression * controle + progression * progression * destination

func _dessiner_rayon(progression: float, controle: Vector3, destination: Vector3) -> void:
	trajectoire.clear_surfaces()
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	trajectoire.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var debut := maxf(0.0, progression - 0.4)
	for i in range(13):
		var fraction := i / 12.0
		var t := lerpf(debut, progression, fraction)
		var point := _point_arc(t, controle, destination)
		var direction := (controle - depart_arc).lerp(destination - controle, t).normalized()
		var cote := direction.cross(camera.global_position - point).normalized() * 0.025
		# Une traînée tournée vers la caméra, plus fine et transparente à sa base.
		trajectoire.surface_set_color(Color(1, 0.78, 0.22, fraction * 0.8))
		trajectoire.surface_add_vertex(point - cote)
		trajectoire.surface_add_vertex(point + cote)
	trajectoire.surface_end()
