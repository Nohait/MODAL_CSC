@tool
extends Node3D

const Tuyau = preload("res://scenes/decors/ville/tuyau_intervention.gd")
const Fumee = preload("res://assets/shaders/decors/fumee_hall.gdshader")
const Jet = preload("res://assets/shaders/decors/jet_intervention.gdshader")

@export var sortie_lance := Vector3(-1.6, 1.25, -2.0)
@onready var point_vise: Vector3 = to_local($Batiment/CibleLance.global_position)
var temps := 0.0

func _ready() -> void:
	# Ces éléments sont purement décoratifs : aucun dégât, collision ou cible d'ennemi.
	Tuyau.creer(self, [Vector3(1, 0.55, 3), Vector3(0, 0.08, 2), Vector3(-4, 0.08, 1),
		Vector3(-3.4, 0.08, -2.5), Vector3(-3, 1.25, -2.7), sortie_lance], 0.055, Color("c4ae77"))
	Tuyau.creer(self, [Vector3(-4.5, 0.4, 5), Vector3(-3, 0.07, 6),
		Vector3(1.8, 0.07, 5), Vector3(1, 0.45, 3)], 0.06, Color("c4ae77"))
	_creer_jet()
	_creer_fumee(point_vise, true)
	# Les effets suivent le bâtiment quand on le recule derrière le trottoir.
	_creer_fumee(to_local($Batiment/FlammesFenetre.global_position) - Vector3(0, 0.3, 0), false)

func _process(delta: float) -> void:
	temps += delta
	# Les deux gyrophares alternent doucement ; pas de flash plein écran.
	$GyrophareBleu.light_energy = 1.1 + 0.9 * sin(temps * 5.0)
	$GyrophareRouge.light_energy = 1.1 - 0.9 * sin(temps * 5.0)
	$Pompiers.rotation.z = sin(temps * 1.5) * 0.008

func _creer_jet() -> void:
	var trajet := point_vise - sortie_lance
	# Calculer une vitesse de départ qui atteint la fenêtre malgré la gravité.
	var duree := Vector2(trajet.x, trajet.z).length() / 14.0
	var gravite := Vector3(0, -3, 0)
	var vitesse := (trajet - gravite * duree * duree * 0.5) / duree
	var direction := vitesse.normalized()
	var lance := MeshInstance3D.new()
	var embout := CylinderMesh.new()
	embout.top_radius = 0.035
	embout.bottom_radius = 0.065
	embout.height = 0.4
	lance.mesh = embout
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("b0b5b8")
	metal.metallic = 0.7
	metal.roughness = 0.4
	lance.material_override = metal
	add_child(lance)
	lance.position = sortie_lance - direction * 0.2
	lance.quaternion = Quaternion(Vector3.UP, direction)
	var points: Array[Vector3] = []
	for i in 25:
		var instant := duree * i / 24.0
		points.append(sortie_lance + vitesse * instant + gravite * instant * instant * 0.5)
	var jet := Tuyau.creer(self, points, 0.045, Color.WHITE)
	var mat := ShaderMaterial.new()
	mat.shader = Jet
	jet.material_override = mat
	jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Les gouttes utilisent la même vitesse et la même gravité que cette courbe.
	var eau := CPUParticles3D.new()
	eau.name = "GouttesLance"
	eau.amount = 100
	eau.lifetime = duree
	eau.preprocess = eau.lifetime
	eau.direction = direction
	eau.spread = 0.25
	eau.gravity = gravite
	eau.initial_velocity_min = vitesse.length()
	eau.initial_velocity_max = vitesse.length()
	eau.mesh = _goutte()
	add_child(eau)
	eau.position = sortie_lance
	var impact := CPUParticles3D.new()
	impact.name = "EclaboussuresFenetre"
	impact.amount = 40
	impact.lifetime = 0.65
	impact.preprocess = 0.65
	impact.direction = Vector3(-1, 0.2, 0)
	impact.spread = 50.0
	impact.gravity = Vector3(0, -3, 0)
	impact.initial_velocity_min = 1.0
	impact.initial_velocity_max = 2.0
	impact.mesh = _goutte()
	add_child(impact)
	impact.position = point_vise

func _goutte() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 0.02
	mesh.height = 0.04
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.75, 0.87, 0.95, 0.45)
	mesh.material = mat
	return mesh

func _creer_fumee(point: Vector3, vapeur: bool) -> void:
	var nuage := CPUParticles3D.new()
	nuage.name = "VapeurFenetre" if vapeur else "FumeeFenetre"
	nuage.amount = 16
	nuage.lifetime = 4.0
	nuage.preprocess = 3.0
	nuage.direction = Vector3(-0.3, 1, 0.1)
	nuage.spread = 15.0
	nuage.gravity = Vector3(-0.04, 0.12, 0.05)
	nuage.initial_velocity_min = 0.6
	nuage.initial_velocity_max = 1.0
	nuage.scale_amount_min = 0.6
	nuage.scale_amount_max = 1.6
	var mat := ShaderMaterial.new()
	mat.shader = Fumee
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.5, 1.5)
	mesh.material = mat
	nuage.mesh = mesh
	var rampe := Gradient.new()
	rampe.offsets = PackedFloat32Array([0, 0.15, 0.6, 1])
	var couleur := Color("a8afb5") if vapeur else Color("282628")
	rampe.colors = PackedColorArray([Color(couleur, 0), Color(couleur, 0.45), Color(couleur, 0.25), Color(couleur, 0)])
	nuage.color_ramp = rampe
	nuage.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(nuage)
	nuage.position = point
