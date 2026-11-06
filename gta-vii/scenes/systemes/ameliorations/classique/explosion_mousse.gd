extends Node3D

@export_range(0.1, 20.0, 0.1) var rayon := 3.0
@export_range(0.2, 1.2, 0.05) var duree := 0.65
@export_range(16, 192, 8) var densite := 144
@export_range(0.1, 2.0, 0.05) var taille_nuages := 1.0
@export var couleur := Color(0.65, 0.95, 0.86, 0.85)
var temps := 0.0
var mat: ShaderMaterial

func _ready() -> void:
	# Le disque reste au-dessus de la surface réelle, y compris sur les sols épais.
	var sol := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.5, global_position + Vector3.DOWN * 2.0, 1)
	var contact: Dictionary = get_world_3d().direct_space_state.intersect_ray(sol)
	var disque := MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = Vector2.ONE * rayon * 2.0
	disque.mesh = plan
	disque.position.y = to_local(contact.position).y + 0.035 if not contact.is_empty() else 0.035
	disque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mat = ShaderMaterial.new()
	mat.shader = preload("res://scenes/systemes/ameliorations/classique/disque_mousse.gdshader")
	mat.set_shader_parameter("couleur", couleur)
	disque.material_override = mat
	add_child(disque)
	var nuage = preload("res://scenes/systemes/ameliorations/classique/bouffee_directionnelle.tscn").instantiate()
	nuage.position.y = 0.65
	nuage.distance = rayon * 0.75
	nuage.demi_angle = 180.0
	nuage.duree = duree
	nuage.densite = densite
	nuage.taille = taille_nuages
	nuage.couleur = couleur
	add_child(nuage)

func _process(delta: float) -> void:
	temps += delta
	mat.set_shader_parameter("progression", clampf(temps / duree, 0.0, 1.0))
	if temps >= duree + 0.15: queue_free()
