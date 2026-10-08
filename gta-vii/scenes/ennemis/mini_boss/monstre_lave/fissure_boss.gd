extends Node3D

signal preparation_commencee(position: Vector3)
signal portion_ouverte(position: Vector3)
signal fissure_terminee

# Une seule attaque planifiée ; ses segments restent fixes même si le joueur bouge.
@export var active := true
@export_range(4.0, 24.0, 0.5) var portee := 14.0
@export_range(0.5, 4.0, 0.1) var largeur := 2.2
@export_range(0.0, 10.0, 0.1) var intensite_lave := 4.0
@export_range(0.02, 0.3, 0.01) var luminosite_roche := 0.08
@export_range(0.3, 0.85, 0.05) var proportion_fond_visible := 0.6
@export_range(0.0, 2.0, 0.05) var relief := 0.7
@export_range(1.0, 8.0, 0.1) var profondeur_visuelle := 3.5
@export_range(0.0, 1.0, 0.05) var irregularite_bords := 1.0
@export_range(0, 40, 1) var braises_par_segment := 12
@export_range(0, 24, 1) var projections_par_segment := 9
@export_range(0.2, 3.0, 0.1) var hauteur_jaillissement := 1.4
@export_range(0.0, 4.0, 0.1) var eclat_ouverture := 2.0
@export_range(2.0, 20.0, 0.5) var vitesse := 7.0
@export_range(0.2, 1.5, 0.05) var avertissement := 0.55
@export_range(0.2, 2.0, 0.05) var duree_feu := 0.65
@export_range(1.0, 100.0, 1.0) var degats := 24.0
@export_range(2.0, 30.0, 0.5) var delai := 8.0
@export_range(0.5, 2.0, 0.1) var longueur_segment := 1.0

var segments: Array[Dictionary] = []
var touches: Array[int] = []
var temps := 0.0
var lancee := false
var attente := 0.0
@onready var boss = get_parent()

func disponible() -> bool:
	return active and attente <= 0.0 and segments.is_empty()

func preparer(origine: Vector3, direction: Vector3) -> void:
	touches.clear()
	temps = 0.0
	lancee = false
	# Tester le trajet devant le boss : la fissure s'arrête contre le décor.
	var precedent := origine + Vector3.UP * 0.25
	for i in range(ceili(portee / longueur_segment)):
		var point := origine + direction * (float(i) + 0.5) * longueur_segment
		var obstacle := PhysicsRayQueryParameters3D.create(precedent, point + Vector3.UP * 0.25, 1)
		obstacle.exclude = [boss.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(obstacle).is_empty(): break
		var rayon := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0, point - Vector3.UP * 4.0, 1)
		rayon.exclude = [boss.get_rid()]
		var sol := get_world_3d().direct_space_state.intersect_ray(rayon)
		if sol.is_empty() or sol.normal.y < 0.7: break
		point = sol.position + Vector3.UP * 0.04
		var surface := MeshInstance3D.new()
		var plan := PlaneMesh.new()
		plan.size = Vector2(largeur, longueur_segment)
		surface.mesh = plan
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/effets/fissure_boss.gdshader")
		mat.set_shader_parameter("intensite_lave", intensite_lave)
		mat.set_shader_parameter("luminosite_roche", luminosite_roche)
		mat.set_shader_parameter("proportion_fond", proportion_fond_visible)
		mat.set_shader_parameter("relief", relief)
		mat.set_shader_parameter("profondeur", profondeur_visuelle)
		mat.set_shader_parameter("largeur", largeur)
		mat.set_shader_parameter("irregularite", irregularite_bords)
		mat.set_shader_parameter("roche", preload("res://assets/textures/effets/fissure_lave/Lava003_2K-PNG_Color.png"))
		mat.set_shader_parameter("lave", preload("res://assets/textures/effets/fissure_lave/Lava003_2K-PNG_Emission.png"))
		mat.set_shader_parameter("normales", preload("res://assets/textures/effets/fissure_lave/Lava003_2K-PNG_NormalGL.png"))
		mat.set_shader_parameter("rugosite", preload("res://assets/textures/effets/fissure_lave/Lava003_2K-PNG_Roughness.png"))
		# Des UV continus évitent de répéter la même image à chaque segment.
		mat.set_shader_parameter("portion", Vector2(float(i) * longueur_segment / largeur, longueur_segment / largeur))
		surface.material_override = mat
		add_child(surface)
		surface.top_level = true
		surface.global_position = point
		surface.global_rotation.y = atan2(direction.x, direction.z)
		segments.append({"surface": surface, "materiau": mat, "position": point, "instant": float(i) * longueur_segment / vitesse, "feu": false})
		precedent = point + Vector3.UP * 0.21
	# La pointe doit se placer au bout réel, même si un mur a raccourci le trajet.
	for segment in segments:
		segment.materiau.set_shader_parameter("longueur_totale", float(segments.size()) * longueur_segment / largeur)
	if not segments.is_empty(): preparation_commencee.emit(origine)

func lancer() -> void:
	lancee = true
	temps = 0.0
	attente = boss.phase.delai(delai)

func _physics_process(delta: float) -> void:
	if boss.est_mort:
		_nettoyer()
		return
	if boss.est_gele() or boss.subit_recul(): return
	attente = maxf(0.0, attente - delta)
	if not lancee: return
	temps += delta
	var terminee := true
	for segment in segments:
		var age: float = temps - segment.instant
		var intensite := clampf(age / avertissement, 0.0, 1.0)
		segment.materiau.set_shader_parameter("charge", intensite)
		if age >= avertissement and age < avertissement + duree_feu:
			if not segment.feu:
				segment.feu = true
				# Les braises s'échappent de la lave sans masquer la cavité par des flammes.
				segment.materiau.set_shader_parameter("eruption", 1.0)
				_creer_braises(segment.surface)
				_creer_projections(segment.surface)
				portion_ouverte.emit(segment.position)
			# Un pic lumineux très bref souligne la libération de pression.
			var eclat := exp(-maxf(0.0, age - avertissement) * 18.0)
			segment.materiau.set_shader_parameter("eruption", 1.0 + eclat * eclat_ouverture)
			_blesser(segment.position)
		if age >= avertissement + duree_feu:
			segment.surface.hide()
		else:
			terminee = false
	if terminee: _nettoyer()

func _blesser(point: Vector3) -> void:
	# Un personnage ne reçoit qu'un coup par fissure, même entre deux segments.
	for corps in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("victime"):
		if not is_instance_valid(corps) or corps.is_queued_for_deletion() or not corps.has_method("prendre_degats"): continue
		if corps.get_instance_id() in touches: continue
		# Les surfaces portent la rotation du trajet, indépendante du mouvement ultérieur du boss.
		var local: Vector3 = segments[0].surface.global_basis.inverse() * (corps.global_position - point)
		if absf(local.x) > largeur * 0.5 or absf(local.z) > longueur_segment * 0.6 or absf(local.y) > 2.5: continue
		touches.append(corps.get_instance_id())
		corps.prendre_degats(degats * (1.0 + maxi(boss.etage - 1, 0) * boss.degats_par_etage_pourcent / 100.0))

func _nettoyer() -> void:
	if not segments.is_empty(): fissure_terminee.emit()
	for segment in segments: segment.surface.queue_free()
	segments.clear()
	touches.clear()
	lancee = false

func _creer_braises(surface: Node3D) -> void:
	if braises_par_segment <= 0: return
	var braises := CPUParticles3D.new()
	braises.amount = braises_par_segment
	braises.one_shot = true
	braises.explosiveness = 0.85
	braises.lifetime = duree_feu
	braises.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	braises.emission_box_extents = Vector3(largeur * 0.4, 0.02, longueur_segment * 0.4)
	braises.direction = Vector3.UP
	braises.spread = 35.0
	braises.initial_velocity_min = 1.2
	braises.initial_velocity_max = 2.8
	braises.gravity = Vector3(0, -1.2, 0)
	braises.scale_amount_min = 0.5
	braises.scale_amount_max = 1.0
	var taille := Curve.new()
	taille.add_point(Vector2(0, 1))
	taille.add_point(Vector2(1, 0))
	braises.scale_amount_curve = taille
	var grain := SphereMesh.new()
	grain.radius = 0.025
	grain.height = 0.05
	grain.radial_segments = 6
	grain.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.45, 0.05)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.2, 0.01)
	mat.emission_energy_multiplier = 3.0
	grain.material = mat
	braises.mesh = grain
	braises.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Chaque petite gerbe commence seulement quand le front du feu arrive ici.
	surface.add_child(braises)
	braises.emitting = true

func _creer_projections(surface: Node3D) -> void:
	if projections_par_segment <= 0: return
	var jets := CPUParticles3D.new()
	jets.amount = projections_par_segment
	jets.one_shot = true
	jets.explosiveness = 0.95
	jets.lifetime = minf(duree_feu, 0.8)
	jets.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	jets.emission_box_extents = Vector3(largeur * 0.18, 0.01, longueur_segment * 0.4)
	jets.direction = Vector3.UP
	jets.spread = 18.0
	# Adapter la gravité au temps disponible : montée vive, puis retombée au sol.
	var gravite := 8.0 * hauteur_jaillissement / (jets.lifetime * jets.lifetime)
	jets.gravity = Vector3.DOWN * gravite
	jets.initial_velocity_max = gravite * jets.lifetime * 0.5
	jets.initial_velocity_min = jets.initial_velocity_max * 0.75
	jets.scale_amount_min = 0.6
	jets.scale_amount_max = 1.0
	var taille := Curve.new()
	taille.add_point(Vector2(0, 0.45))
	taille.add_point(Vector2(0.15, 1))
	taille.add_point(Vector2(1, 0))
	jets.scale_amount_curve = taille
	var goutte := SphereMesh.new()
	goutte.radius = 0.065
	goutte.height = 0.35
	goutte.radial_segments = 8
	goutte.rings = 4
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.18, 0.005)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.25, 0.005)
	mat.emission_energy_multiplier = intensite_lave
	goutte.material = mat
	jets.mesh = goutte
	jets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface.add_child(jets)
	jets.emitting = true
