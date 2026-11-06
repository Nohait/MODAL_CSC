extends Node3D
## Décor autonome : aucune physique, navigation ou logique du joueur.

const POMPIER = preload("res://scenes/joueur/player_pompier.tscn")
const BETON_COULEUR = preload("res://assets/textures/decors/hall_incendie/sol_beton_couleur.jpg")
const ENDUIT = preload("res://assets/materiaux/appartements/white_plaster_02.tres")
const MARCHES := 8
const GIRON := 0.56
const HAUTEUR := 0.16
const DEPART := -2.52

var acteur: Node3D
var modele: Node3D
var lecteur: AnimationPlayer
var squelette: Skeleton3D
var pieds: Array[int] = []
var temps := 0.0
var duree := 3.4
var actif := false

func _ready() -> void:
	_construire_decor()
	acteur = Node3D.new()
	add_child(acteur)
	modele = POMPIER.instantiate()
	modele.set_script(null)
	modele.collision_layer = 0
	modele.collision_mask = 0
	# Conserver les corrections d'axes importées ; le parent porte le cap.
	modele.scale *= 0.125
	acteur.add_child(modele)
	acteur.rotation.y = -PI / 2.0
	modele.get_node("visual/Armature/AnimationTree").active = false
	lecteur = modele.get_node("visual/Armature/AnimationPlayer")
	lecteur.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	squelette = modele.get_node("visual/Armature/Skeleton3D")
	for nom in ["mixamorig_LeftFoot", "mixamorig_RightFoot", "mixamorig_LeftToeBase", "mixamorig_RightToeBase"]:
		pieds.append(squelette.find_bone(nom))
	set_process(false)

func commencer(duree_course: float) -> void:
	duree = duree_course
	temps = 0.0
	actif = true
	lecteur.play("Run/Run")
	lecteur.advance(0.0)
	_positionner()
	set_process(true)

func arreter() -> void:
	actif = false
	lecteur.stop()
	set_process(false)

func _process(delta: float) -> void:
	if not actif:
		lecteur.advance(delta)
		_positionner()
		return
	temps = minf(temps + delta, duree)
	# Quatre foulées pour huit marches ; l'animation reste propre à cette instance.
	var cadence := lecteur.get_animation("Run/Run").length * 4.0 / duree
	lecteur.advance(delta * cadence)
	_positionner()
	if temps >= duree:
		actif = false
		lecteur.play("Idle/Idle", 0.18)
		lecteur.advance(0.18)
		_positionner()

func _positionner() -> void:
	acteur.position = Vector3(DEPART + temps / duree * MARCHES * GIRON, 0.0, 0.0)
	# Recaler les appuis sur les marches, sans pencher le squelette avec la pente.
	squelette.force_update_all_bone_transforms()
	var hauteur_appui := -INF
	for indice in pieds:
		if indice < 0: continue
		var pied := squelette.to_global(squelette.get_bone_global_pose(indice).origin)
		var marche := clampi(ceili((pied.x - DEPART) / GIRON), 0, MARCHES)
		hauteur_appui = maxf(hauteur_appui, marche * HAUTEUR - pied.y + 0.035)
	acteur.position.y = hauteur_appui if is_finite(hauteur_appui) else 0.0

func _construire_decor() -> void:
	var beton := StandardMaterial3D.new()
	beton.albedo_texture = BETON_COULEUR
	beton.albedo_color = Color("b4b6b5")
	beton.roughness = 0.9
	beton.uv1_triplanar = true
	beton.uv1_world_triplanar = true
	beton.uv1_scale = Vector3.ONE * 0.5
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("39434b")
	metal.metallic = 0.65
	metal.roughness = 0.48
	var balisage := StandardMaterial3D.new()
	balisage.albedo_color = Color("b5a279")
	for i in range(MARCHES):
		var hauteur := (i + 1) * HAUTEUR
		var x := DEPART + (i + 0.5) * GIRON
		_bloc(Vector3(x, hauteur / 2.0 - 0.12, 0), Vector3(GIRON, hauteur + 0.24, 2.35), beton)
		_bloc(Vector3(x - GIRON / 2.0 + 0.035, hauteur + 0.004, 0), Vector3(0.045, 0.008, 2.3), balisage)
	_bloc(Vector3(DEPART - 0.65, -0.12, 0), Vector3(1.3, 0.24, 2.35), beton)
	_bloc(Vector3(DEPART + MARCHES * GIRON + 0.8, MARCHES * HAUTEUR - 0.12, 0), Vector3(1.6, 0.24, 2.35), beton)
	_bloc(Vector3(0, 2.0, -1.3), Vector3(18.0, 10.0, 0.18), ENDUIT)
	# Rampe au fond pour conserver la silhouette et les appuis visibles.
	for i in range(0, MARCHES + 1, 2):
		_bloc(Vector3(DEPART + i * GIRON, i * HAUTEUR + 0.5, -1.02), Vector3(0.045, 1.0, 0.045), metal)
	var rampe := _bloc(Vector3(DEPART + MARCHES * GIRON / 2.0, MARCHES * HAUTEUR / 2.0 + 1.0, -1.02), Vector3(Vector2(MARCHES * GIRON, MARCHES * HAUTEUR).length(), 0.06, 0.06), metal)
	rampe.rotation.z = atan2(HAUTEUR, GIRON)
	var environnement := WorldEnvironment.new()
	environnement.environment = Environment.new()
	environnement.environment.background_mode = Environment.BG_COLOR
	environnement.environment.background_color = Color("11171b")
	environnement.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environnement.environment.ambient_light_color = Color("a5b7c8")
	environnement.environment.ambient_light_energy = 0.65
	add_child(environnement)
	var lumiere := DirectionalLight3D.new()
	lumiere.rotation_degrees = Vector3(-48, -35, 0)
	lumiere.light_color = Color("ffdfb4")
	lumiere.light_energy = 0.9
	lumiere.shadow_enabled = true
	add_child(lumiere)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(-3.8, 3.4, 9.0)
	camera.look_at(Vector3(-0.1, 1.45, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.1
	camera.current = true

func _bloc(position_bloc: Vector3, taille: Vector3, materiau: Material) -> MeshInstance3D:
	var bloc := MeshInstance3D.new()
	bloc.mesh = BoxMesh.new()
	bloc.mesh.size = taille
	bloc.material_override = materiau
	bloc.position = position_bloc
	add_child(bloc)
	return bloc
