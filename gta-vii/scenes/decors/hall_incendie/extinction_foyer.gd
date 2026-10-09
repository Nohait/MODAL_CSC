extends Node3D

signal foyer_eteint

@export var extinguible := true
@export_range(0.2, 10.0, 0.1) var duree_extinction := 2.5
@export_range(0.1, 2.0, 0.05) var rayon_contact := 0.45
@export_range(0.1, 3.0, 0.1) var persistance_vapeur := 1.0
@export_range(4, 30) var particules_vapeur := 14
@export var mobilier: Node3D
var intensite := 1.0
var reste_vapeur := 0.0
var flammes: Dictionary = {}
var volume_initial := 0.0
var vapeur: CPUParticles3D
@onready var foyer: Node3D = get_parent()
const IMPACT = preload("res://scenes/effets/combat/impact_mousse.tscn")

func _ready() -> void:
	add_to_group("foyers_extinguibles")
	set_physics_process(false)

func recevoir_mousse(delta: float) -> void:
	if not extinguible or intensite <= 0.0: return
	if vapeur == null: _preparer()
	# Le refroidissement est indépendant des dégâts et des cartes de puissance du joueur.
	intensite = maxf(0.0, intensite - delta / duree_extinction)
	reste_vapeur = persistance_vapeur
	vapeur.emitting = true
	set_physics_process(true)
	for flamme: CPUParticles3D in flammes:
		flamme.scale = flammes[flamme] * lerpf(0.15, 1.0, intensite)
		flamme.emitting = intensite > 0.0
	var braises := foyer.get_node("Braises") as CPUParticles3D
	braises.emitting = intensite > 0.0
	foyer.get_node("Fumee").emitting = intensite > 0.0
	var son := foyer.get_node("Crepitement") as AudioStreamPlayer3D
	son.volume_db = volume_initial + linear_to_db(maxf(intensite, 0.001))
	if intensite <= 0.0:
		son.stop()
		_refroidir_mobilier()
		foyer_eteint.emit()

func _preparer() -> void:
	# Capturer après le ready du foyer : la génération a déjà appliqué sa taille et son volume.
	for enfant in foyer.get_children():
		if enfant is CPUParticles3D and (enfant.name == "Flammes" or enfant.name.begins_with("LangueSecondaire")):
			flammes[enfant] = enfant.scale
	volume_initial = foyer.get_node("Crepitement").volume_db
	# Réutiliser la vapeur existante avec un seul émetteur continu, plutôt que créer un effet par frame.
	var impact := IMPACT.instantiate()
	vapeur = impact.get_node("Vapeur").duplicate() as CPUParticles3D
	impact.free()
	vapeur.name = "VapeurExtinction"
	vapeur.one_shot = false
	vapeur.explosiveness = 0.0
	vapeur.amount = particules_vapeur
	vapeur.lifetime = 1.3
	vapeur.direction = Vector3.UP
	vapeur.emission_sphere_radius = rayon_contact
	vapeur.position.y = 0.25
	vapeur.scale = Vector3.ONE * foyer.taille
	add_child(vapeur)

func _physics_process(delta: float) -> void:
	reste_vapeur = maxf(0.0, reste_vapeur - delta)
	if reste_vapeur <= 0.0:
		vapeur.emitting = false
		set_physics_process(false)

func _refroidir_mobilier() -> void:
	var meuble := mobilier if is_instance_valid(mobilier) else foyer.get_parent()
	var script: Script = meuble.get_script()
	if script == null or not script.resource_path.ends_with("mobilier_incendie.gd"): return
	for surface in meuble.find_children("*", "MeshInstance3D", true, false):
		for i in range(surface.mesh.get_surface_count()):
			var original: Material = surface.get_active_material(i)
			if original is ShaderMaterial and original.shader.resource_path.ends_with("mobilier_appartement.gdshader"):
				# Garder le meuble carbonisé, mais supprimer sa lueur sans toucher aux autres instances.
				var mat := original.duplicate() as ShaderMaterial
				mat.set_shader_parameter("intensite_braises", 0.0)
				surface.set_surface_override_material(i, mat)
