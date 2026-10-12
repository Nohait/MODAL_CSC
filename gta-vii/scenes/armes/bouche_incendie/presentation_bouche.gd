extends Node3D

# La présentation ne modifie jamais la collision, les dégâts ni les échéances des ondes.
@export_range(0.1, 0.6, 0.05) var duree_preparation := 0.3
@export_range(0.0, 0.03, 0.001) var vibration := 0.008
@export_range(0, 40, 1) var gouttes_par_raccord := 18
@export_range(0.1, 0.6, 0.05) var duree_projection := 0.3
@export var son_preparation: AudioStream = preload("res://assets/sounds/design/mouvements/swish-3.wav")
@export_range(-40.0, -15.0, 1.0) var volume_preparation_db := -32.0
var dessin: Node3D
var materiaux: Array[ShaderMaterial] = []
var materiau_fondu: ShaderMaterial
var hauteur := 1.2
var fuite := false
var froid := false
var raccord := false
var pression := 0.0
var charge := 0.0
var impulsion := 0.0
var temps := 0.0
var preparation_jouee := false
var rotation_repos := Vector3.ZERO
var jets: Array[CPUParticles3D] = []
var souffle: AudioStreamPlayer3D

func _ready() -> void:
	for sens in [-1.0, 1.0]:
		var jet := CPUParticles3D.new()
		jet.emitting = false
		jet.one_shot = true
		jet.amount = maxi(1, gouttes_par_raccord)
		jet.lifetime = duree_projection
		jet.explosiveness = 0.9
		jet.direction = Vector3(sens, 0.1, 0.0)
		jet.spread = 16.0
		jet.initial_velocity_min = 1.8
		jet.initial_velocity_max = 3.2
		jet.gravity = Vector3(0, -7, 0)
		jet.scale_amount_min = 0.65
		jet.scale_amount_max = 1.2
		var goutte := SphereMesh.new()
		goutte.radius = 0.015
		goutte.height = 0.045
		goutte.radial_segments = 6
		goutte.rings = 3
		var eau := StandardMaterial3D.new()
		eau.albedo_color = Color(0.72, 0.9, 0.98, 0.65)
		eau.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		eau.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		goutte.material = eau
		jet.mesh = goutte
		jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		jet.position = Vector3(sens * hauteur * 0.35, hauteur * 0.56, 0)
		add_child(jet)
		jets.append(jet)
	souffle = AudioStreamPlayer3D.new()
	souffle.stream = son_preparation
	souffle.bus = &"Effets"
	souffle.volume_db = volume_preparation_db
	souffle.unit_size = 3.0
	souffle.max_distance = 12.0
	add_child(souffle)
	souffle.position.y = hauteur * 0.6

func configurer(modele: Node3D, taille: float, fuite_active: bool, givre: bool, raccord_actif: bool) -> void:
	dessin = modele
	hauteur = taille
	fuite = fuite_active
	froid = givre
	raccord = raccord_actif
	rotation_repos = dessin.rotation
	var surfaces := dessin.find_children("*", "MeshInstance3D", true, false)
	if dessin is MeshInstance3D: surfaces.append(dessin)
	for surface: MeshInstance3D in surfaces:
		for i in range(surface.mesh.get_surface_count()):
			var mat = surface.get_active_material(i)
			if mat is ShaderMaterial:
				materiaux.append(mat)
				mat.set_shader_parameter("givre", froid)
				mat.set_shader_parameter("raccord_actif", raccord)

func actualiser(anticipation: float, reserve_pression: float) -> void:
	pression = clampf(anticipation, 0.0, 1.0)
	charge = clampf(reserve_pression, 0.0, 1.0)
	if pression <= 0.01: preparation_jouee = false
	if pression > 0.1 and not preparation_jouee:
		preparation_jouee = true
		souffle.pitch_scale = 0.8 + charge * 0.2
		if son_preparation != null: souffle.play()

func relacher(intensite: float, retour: bool) -> void:
	impulsion = clampf(intensite, 0.0, 2.0)
	pression = 0.0
	preparation_jouee = false
	if retour or not fuite or gouttes_par_raccord == 0: return
	for jet in jets:
		jet.initial_velocity_max = 3.2 * (1.0 + minf(intensite, 1.0) * 0.25)
		jet.restart()

func _process(delta: float) -> void:
	temps += delta
	impulsion = move_toward(impulsion, 0.0, delta * 6.0)
	for mat in materiaux:
		mat.set_shader_parameter("pression", pression)
		mat.set_shader_parameter("charge_raccord", charge)
		mat.set_shader_parameter("impulsion", impulsion)
		if materiau_fondu != null and mat != materiau_fondu:
			mat.set_shader_parameter("opacite", materiau_fondu.get_shader_parameter("opacite"))
	if is_instance_valid(dessin):
		# Une vibration infime du modèle annonce le relâchement, sans déplacer son socle.
		dessin.rotation = rotation_repos + Vector3(0, 0, sin(temps * 95.0) * vibration * pression)
