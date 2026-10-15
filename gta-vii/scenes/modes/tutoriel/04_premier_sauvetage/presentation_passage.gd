extends Node3D

const FEU = preload("res://assets/tutoriel/feu_volumetrique/brasier_volume.gdshader")
const BRUIT = preload("res://assets/tutoriel/feu_volumetrique/bruit_feu.tres")
var volume: MeshInstance3D
var materiau: ShaderMaterial
var eteint := false
var horloge := 0.0
var largeur_brasier := 3.2
@export_range(0.6, 2.0, 0.05) var profondeur_max := 1.1

func preparer(largeur: float) -> void:
	largeur_brasier = largeur
	volume = MeshInstance3D.new()
	volume.name = "BrasierVolumetrique"
	var mesh := BoxMesh.new()
	materiau = ShaderMaterial.new()
	materiau.shader = FEU
	materiau.set_shader_parameter("sample_noise", BRUIT)
	materiau.set_shader_parameter("raymarch_steps", 6)
	materiau.set_shader_parameter("sample_jitter", true)
	materiau.set_shader_parameter("jitter_multiplier", 0.3)
	materiau.set_shader_parameter("fire_width", largeur)
	materiau.set_shader_parameter("fire_depth", profondeur_max)
	materiau.set_shader_parameter("taper_factor", 0.12)
	materiau.set_shader_parameter("base_density", 0.08)
	mesh.material = materiau
	volume.mesh = mesh
	volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(volume)
	actualiser(1.0, 0.0)

func actualiser(intensite: float, delta: float) -> void:
	if eteint: return
	# Temps intégré : ralentir sans saut ni retour arrière dans l'animation.
	horloge += delta * lerpf(0.008, 0.027, intensite)
	var hauteur := lerpf(1.1, 3.8, intensite)
	var profondeur := lerpf(0.6, profondeur_max, intensite)
	(volume.mesh as BoxMesh).size = Vector3(largeur_brasier, hauteur, profondeur)
	volume.position.y = hauteur / 2
	materiau.set_shader_parameter("box_center", Vector3(0, -hauteur / 2, 0))
	materiau.set_shader_parameter("fire_height", hauteur)
	materiau.set_shader_parameter("fire_depth", profondeur)
	materiau.set_shader_parameter("animation_time", horloge)
	materiau.set_shader_parameter("wobble_strength", lerpf(0.4, 2.0, intensite))
	materiau.set_shader_parameter("emission_strength", lerpf(1.8, 4.0, intensite))
	materiau.set_shader_parameter("core_glow_multiplier", lerpf(1.0, 5.0, intensite))
	# La base et la densité restent présentes : l'action réduit la puissance, pas l'opacité.

func ouvrir(foyer: Node3D, largeur: float) -> void:
	if eteint: return
	eteint = true
	volume.hide()
	# Résidus visuels uniquement : aucun corps, zone de dégâts ou obstacle.
	var braises := foyer.get_node("Braises").duplicate() as CPUParticles3D
	braises.position = Vector3(0, 0.1, 0)
	braises.scale = Vector3.ONE
	braises.emission_box_extents = Vector3(largeur / 2, 0.03, 0.12)
	braises.initial_velocity_min = 0.05
	braises.initial_velocity_max = 0.15
	braises.preprocess = 0
	braises.one_shot = true
	braises.emitting = false
	add_child(braises)
	braises.restart()
	braises.emitting = true
	var impact = preload("res://scenes/effets/combat/impact_mousse.tscn").instantiate()
	var vapeur := impact.get_node("Vapeur").duplicate() as CPUParticles3D
	impact.free()
	vapeur.position = Vector3(0, 0.25, 0)
	vapeur.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	vapeur.emission_box_extents = Vector3(largeur / 2, 0.05, 0.15)
	vapeur.amount = 20
	vapeur.preprocess = 0
	vapeur.one_shot = true
	vapeur.emitting = false
	add_child(vapeur)
	vapeur.restart()
	vapeur.emitting = true
