extends Area3D

var effets: Node
var type_zone := "mousse"
var duree := 4.0
var rayon := 0.9
var degats := 8.0
var gel := 0.0
var expansive := false
var temps := 0.0
var attente := 0.0
var forme: CylinderShape3D
var dessin: MeshInstance3D
var materiau: ShaderMaterial

func _ready() -> void:
	add_to_group("zones_mousse")
	collision_layer = 0
	collision_mask = 12
	forme = CylinderShape3D.new()
	forme.radius = rayon
	forme.height = 2.5
	var collision := CollisionShape3D.new()
	collision.shape = forme
	collision.position.y = 1.0
	add_child(collision)
	dessin = MeshInstance3D.new()
	var disque := PlaneMesh.new()
	disque.size = Vector2(2, 2)
	dessin.mesh = disque
	dessin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	materiau = ShaderMaterial.new()
	materiau.shader = preload("res://scenes/systemes/ameliorations/zone_mousse.gdshader")
	var couleur := Color(0.25, 0.65, 1.0, 0.4) if gel > 0 else Color(0.85, 0.9, 0.8, 0.4)
	if type_zone == "abri": couleur = Color(0.2, 0.7, 1.0, 0.2)
	materiau.set_shader_parameter("couleur", couleur)
	dessin.material_override = materiau
	dessin.position.y = 0.025
	add_child(dessin)
	dessin.scale = Vector3(rayon, 1, rayon)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(effets):
		queue_free()
		return
	temps += delta
	if temps >= duree:
		queue_free()
		return
	var croissance: float = effets.valeur("mousse_expansive") / 100.0 * minf(temps / 2.0, 1.0) if expansive else 0.0
	var taille := rayon * (1.0 + croissance)
	forme.radius = taille
	dessin.scale = Vector3(taille, 1, taille)
	materiau.set_shader_parameter("opacite", minf(1.0, (duree - temps) / 0.6))
	attente += delta
	if attente < 0.25: return
	var pas := attente
	attente = 0.0
	if type_zone == "abri": return
	for corps in get_overlapping_bodies():
		if not effets.visible_depuis(global_position + Vector3.UP, corps): continue
		if corps.is_in_group("enemies"):
			if corps.get("est_mort") == true: continue
			if degats > 0: effets.infliger(corps, degats * pas)
			if gel > 0 and corps.has_method("appliquer_gel"): corps.appliquer_gel(gel, 0.7)
		elif corps.is_in_group("victime") and corps is CharacterBody3D:
			effets.proteger_victime(corps)
