extends Area3D

var effets: Node
var type_zone := "mousse"
var duree := 4.0
@export_range(0.1, 3.0, 0.1) var duree_fonte := 0.9
var rayon := 0.9
var degats := 8.0
var gel := 0.0
var ralentissement_eau := 0.0
var gele_progressivement := false
@export_range(0.1, 3.0, 0.1) var delai_gel_eau := 1.2
var contacts_eau: Dictionary = {}
var obstacles_exclus: Array[RID] = []
var couleur_gel := Color(0.74, 0.94, 1.0, 0.4)
var expansive := false
var empreinte := PackedVector2Array()
var coordonnees_empreinte := PackedVector2Array()
var temps := 0.0
var temps_croissance := 0.0
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
	dessin.mesh = disque if empreinte.is_empty() else _dessiner_empreinte()
	dessin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Chaque trace a sa propre fonte ; seule la glace reçoit le matériau PBR.
	if gel > 0.0:
		materiau = preload("res://assets/materiaux/verglas.tres").duplicate()
	else:
		materiau = ShaderMaterial.new()
		materiau.shader = preload("res://scenes/armes/bouche_incendie/nappe_eau.gdshader") if type_zone == "eau" else preload("res://scenes/systemes/ameliorations/zone_mousse.gdshader")
	var couleur := couleur_gel if gel > 0 else Color(0.85, 0.9, 0.8, 0.4)
	if type_zone == "eau" and gel <= 0: couleur = Color(0.22, 0.38, 0.45, 0.28)
	if type_zone == "abri": couleur = Color(0.2, 0.7, 1.0, 0.2)
	materiau.set_shader_parameter("couleur", couleur)
	materiau.set_shader_parameter("forme_libre", not empreinte.is_empty())
	dessin.material_override = materiau
	dessin.position.y = 0.025
	add_child(dessin)
	dessin.scale = Vector3(rayon, 1, rayon)

func _dessiner_empreinte() -> ArrayMesh:
	# Les mêmes points définissent le dessin et le test de présence dans la zone.
	var sommets := PackedVector3Array()
	var normales := PackedVector3Array()
	var tangentes := PackedFloat32Array()
	for point in empreinte:
		sommets.append(Vector3(point.x, 0, point.y))
		# La normale pointe vers le haut ; la texture de relief suit les axes X/Z.
		normales.append(Vector3.UP)
		tangentes.append_array(PackedFloat32Array([1.0, 0.0, 0.0, -1.0]))
	var tableaux: Array = []
	tableaux.resize(Mesh.ARRAY_MAX)
	tableaux[Mesh.ARRAY_VERTEX] = sommets
	tableaux[Mesh.ARRAY_NORMAL] = normales
	tableaux[Mesh.ARRAY_TANGENT] = tangentes
	tableaux[Mesh.ARRAY_TEX_UV] = coordonnees_empreinte
	tableaux[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(empreinte)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tableaux)
	return mesh

func _dans_empreinte(corps: Node3D) -> bool:
	if empreinte.is_empty(): return true
	var position_locale := dessin.to_local(corps.global_position)
	var point := Vector2(position_locale.x, position_locale.z)
	if Geometry2D.is_point_in_polygon(point, empreinte): return true
	# Une grande cible peut toucher le bord sans avoir son centre dans le cône.
	var largeur := float(corps.get("hitbox_radius")) if corps.get("hitbox_radius") != null else 0.0
	for i in range(empreinte.size()):
		var proche := Geometry2D.get_closest_point_to_segment(point, empreinte[i], empreinte[(i + 1) % empreinte.size()])
		if point.distance_to(proche) <= largeur / dessin.scale.x: return true
	return false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(effets):
		queue_free()
		return
	temps += delta
	temps_croissance += delta
	if temps >= duree:
		queue_free()
		return
	var croissance: float = effets.valeur("mousse_expansive") / 100.0 * minf(temps_croissance / 2.0, 1.0) if expansive else 0.0
	var taille := rayon * (1.0 + croissance)
	forme.radius = taille
	dessin.scale = Vector3(taille, 1, taille)
	if gel > 0.0:
		# La fonte reste visuelle : la durée et le rayon du ralentissement sont inchangés.
		materiau.set_shader_parameter("fonte", 1.0 - clampf((duree - temps) / minf(duree_fonte, duree), 0.0, 1.0))
	else:
		materiau.set_shader_parameter("opacite", minf(1.0, (duree - temps) / 0.6))
	attente += delta
	if attente < 0.25: return
	var pas := attente
	attente = 0.0
	if type_zone == "abri": return
	for corps in get_overlapping_bodies():
		if not _dans_empreinte(corps): continue
		if type_zone == "eau":
			var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.6, corps.global_position + Vector3.UP * 0.6, 1)
			ray.exclude = obstacles_exclus
			if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		elif not effets.visible_depuis(global_position + Vector3.UP, corps): continue
		if corps.is_in_group("enemies"):
			if corps.get("est_mort") == true: continue
			if degats > 0: effets.infliger(corps, degats * pas)
			if gel > 0 and corps.has_method("appliquer_gel"): corps.appliquer_gel(gel, 0.7)
			if ralentissement_eau > 0 and corps.has_method("appliquer_gel"):
				corps.appliquer_gel(ralentissement_eau, 0.3)
				if gele_progressivement:
					var id := corps.get_instance_id()
					var contact: Dictionary = contacts_eau.get(id, {"temps": 0.0, "dernier": temps})
					if temps - contact.dernier > 0.4: contact.temps = 0.0
					contact.temps += pas
					contact.dernier = temps
					contacts_eau[id] = contact
					if contact.temps >= delai_gel_eau: effets.etat(corps).gel_restant = maxf(effets.etat(corps).gel_restant, 0.4)
		elif type_zone != "eau" and corps.is_in_group("victime") and corps is CharacterBody3D:
			effets.proteger_victime(corps)
