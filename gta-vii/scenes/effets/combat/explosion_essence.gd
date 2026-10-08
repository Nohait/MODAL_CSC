extends Node3D

signal remplacement_demande

@export_range(6.0, 20.0, 0.5) var taille := 18.0
@export_range(1.0, 4.0, 0.1) var duree := 2.2
@export_range(-20.0, 6.0, 1.0) var volume_db := 0.0
@export_range(10.0, 100.0, 1.0) var portee_son := 80.0
@export var haute_definition := true
@export_range(24, 128, 8) var qualite_volume := 80
@export_range(10.0, 100.0, 5.0) var densite_fumee := 65.0
@export_range(0.5, 8.0, 0.1) var luminosite_feu := 3.6
@export_range(0.0, 4.0, 0.1) var ombres_fumee := 1.8
@export_range(0.05, 1.0, 0.01) var instant_remplacement := 0.24
var temps := 0.0
var volume: MeshInstance3D
var materiau: ShaderMaterial
static var images_volume: Array[Texture3D] = []
static var images_legeres: Array[Texture3D] = []
var simulation: Array[Texture3D] = []
var lumiere: OmniLight3D
var remplacement_fait := false

# Les volumes sont chargés avec le Hall pour éviter une pause au moment de l'explosion.
static func preparer_volumes(detaille: bool = true) -> Array[Texture3D]:
	var images := images_volume if detaille else images_legeres
	if images.is_empty():
		var dossier := "volumes_hd" if detaille else "volumes"
		for i in range(48 if detaille else 32):
			images.append(load("res://assets/textures/effets/explosion_essence/%s/%02d.res" % [dossier, i]))
	return images

func _ready() -> void:
	# Le profil économique conserve une version moins coûteuse du même effet.
	var reglages := get_node_or_null("/root/Reglages")
	if reglages != null and reglages.graphismes.indice == 0:
		haute_definition = false
		qualite_volume = mini(qualite_volume, 40)
	simulation = preparer_volumes(haute_definition)
	volume = MeshInstance3D.new()
	var boite := BoxMesh.new()
	boite.size = Vector3.ONE
	volume.mesh = boite
	volume.scale = Vector3(taille * 2.0 / 3.0, taille, taille * 2.0 / 3.0)
	volume.position.y = taille / 2.0
	volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	materiau = ShaderMaterial.new()
	materiau.shader = preload("res://assets/shaders/effets/explosion_volume.gdshader")
	materiau.set_shader_parameter("nombre_pas", qualite_volume)
	materiau.set_shader_parameter("opacite", densite_fumee)
	materiau.set_shader_parameter("luminosite", luminosite_feu)
	materiau.set_shader_parameter("ombres_fumee", ombres_fumee)
	materiau.set_shader_parameter("encodage_racine", haute_definition)
	volume.material_override = materiau
	add_child(volume)
	_actualiser_volume()
	
	var debris := CPUParticles3D.new()
	debris.one_shot = true
	debris.explosiveness = 1.0
	debris.amount = 12
	debris.lifetime = 1.4
	debris.local_coords = false
	debris.position.y = 1
	debris.direction = Vector3.UP
	debris.spread = 80
	debris.initial_velocity_min = 4
	debris.initial_velocity_max = 7
	debris.gravity = Vector3(0, -9.8, 0)
	debris.angular_velocity_min = 90
	debris.angular_velocity_max = 240
	var eclat := BoxMesh.new()
	eclat.size = Vector3(0.08, 0.035, 0.15)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.12, 0.1, 0.08)
	metal.roughness = 0.6
	eclat.material = metal
	debris.mesh = eclat
	debris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(debris)
	debris.restart()
	lumiere = OmniLight3D.new()
	lumiere.position.y = 2
	lumiere.light_color = Color(1, 0.3, 0.06)
	lumiere.omni_range = 18
	lumiere.light_energy = 9
	add_child(lumiere)
	var son := AudioStreamPlayer3D.new()
	son.stream = preload("res://assets/sounds/evenements/explosion_voiture.wav")
	son.bus = "Effets"
	son.volume_db = volume_db
	son.unit_size = 25
	son.max_distance = portee_son
	add_child(son)
	son.play()

func _actualiser_volume() -> void:
	# Interpoler deux instants évite de voir les étapes de la simulation.
	var derniere := simulation.size() - 1
	var image := clampf(temps / duree * derniere, 0.0, float(derniere))
	var indice := int(image)
	materiau.set_shader_parameter("volume_actuel", simulation[indice])
	materiau.set_shader_parameter("volume_suivant", simulation[mini(indice + 1, derniere)])
	materiau.set_shader_parameter("interpolation", image - indice)
	# Le cœur opaque couvre le modèle pendant son remplacement, puis se dissipe.
	materiau.set_shader_parameter("coeur", smoothstep(0.02, 0.12, temps) * (1.0 - smoothstep(0.3, 0.65, temps)))
	materiau.set_shader_parameter("disparition", clampf((duree - temps) / 0.4, 0.0, 1.0))

func _process(delta: float) -> void:
	temps += delta
	_actualiser_volume()
	# Utiliser la même horloge pour le volume et la voiture évite un décalage.
	if not remplacement_fait and temps >= instant_remplacement:
		remplacement_fait = true
		remplacement_demande.emit()
	volume.visible = temps < duree
	lumiere.light_energy = 9.0 * exp(-temps * 6.0)
	# Conserver le nœud jusqu'à la fin de la retombée sonore.
	if temps >= maxf(duree, 3.6): queue_free()

