extends Node3D

signal impact
const FLAQUE = preload("res://scenes/ennemis/dangers/flaque_de_feu.tscn")

@onready var vfx: Node3D = $vfx_fire
var vfx_actif := false

@export_group("Zone")
@export_range(0.5, 10.0, 0.1) var rayon := 2.5
## Temps entre l'apparition de la zone et l'impact.
@export_range(0.5, 10.0, 0.1) var delai_avertissement := 3.0

@export_group("Chute")
@export_range(0.2, 1.5, 0.05) var duree_chute := 0.5
@export var hauteur_chute := 18.0

@export_group("Dégâts")
@export var degats_impact := 25.0
@export var touche_joueur := true
@export var touche_victimes := true
@export var touche_ennemis := false

var etat := "avertissement"
var temps := 0.0
var temps_degats := 0.0
var anneau: MeshInstance3D
var remplissage: MeshInstance3D
var lumiere: OmniLight3D
var mat_remplissage: StandardMaterial3D





func _sol_sous(joueur: Node3D) -> Vector3:
	# La position du joueur est celle du centre de sa capsule : on cherche le sol dessous.
	var requete := PhysicsRayQueryParameters3D.create(
		joueur.global_position + Vector3.UP * 0.5,
		joueur.global_position - Vector3.UP * 5.0,
		1)  # couche 1 : décor, comme dans ton _voie_libre
	var contact := joueur.get_world_3d().direct_space_state.intersect_ray(requete)
	if not contact.is_empty():
		return contact.position
	# Repli : sol approximatif sous les pieds.
	return Vector3(joueur.global_position.x, joueur.global_position.y - 1.0, joueur.global_position.z)



func _ready() -> void:
	_regler_vfx(false)
	vfx.position.y = hauteur_chute
	
	anneau = _creer_disque(Color(1.0, 0.15, 0.05, 0.25), 0.03)
	remplissage = _creer_disque(Color(1.0, 0.45, 0.05, 0.5), 0.05)
	mat_remplissage = remplissage.material_override
	remplissage.scale = Vector3(0.001, 1.0, 0.001)

func _regler_vfx(actif: bool) -> void:
	vfx_actif = actif
	vfx.visible = actif
	var particules: Array = vfx.find_children("*", "GPUParticles3D", true, false)
	for p in particules:
		p.emitting = actif

func _creer_disque(couleur: Color, hauteur_y: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cylindre := CylinderMesh.new()
	cylindre.top_radius = rayon
	cylindre.bottom_radius = rayon
	cylindre.height = 0.02
	cylindre.radial_segments = 48
	mesh.mesh = cylindre
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = couleur
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = mat
	# Léger décalage vertical pour éviter le scintillement avec le sol.
	mesh.position.y = hauteur_y
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh

func _process(delta: float) -> void:
	temps += delta
	if etat == "avertissement":
		_maj_avertissement()

func _creer_flaque() -> void:
	var flaque := FLAQUE.instantiate()
	# Enfant du parent, pas de la zone : la zone se supprime juste après.
	get_parent().add_child(flaque)
	#var flaques = get_parent().get_parent().get_node("FlaquesDeFeu")
	#flaques.add_child(flaque)
	
	flaque.global_position = global_position
	flaque.scale *= rayon*3.0/2.0

func _maj_avertissement() -> void:
	var p := clampf(temps / delai_avertissement, 0.0, 1.0)
	# Le disque intérieur grandit jusqu'à remplir la zone.
	remplissage.scale = Vector3(maxf(p, 0.001), 1.0, maxf(p, 0.001))
	# Le clignotement accélère à l'approche de l'impact.
	var alpha := 0.4 + 0.25 * sin(temps * (4.0 + p * 16.0))
	mat_remplissage.albedo_color.a = alpha

	var debut_chute := delai_avertissement - duree_chute
	if temps >= debut_chute:
		if not vfx_actif: _regler_vfx(true)
		var q := clampf((temps - debut_chute) / duree_chute, 0.0, 1.0)
		# Accélération en chute libre jusqu'au sol.
		vfx.position.y = lerpf(hauteur_chute, 0.0, q * q)
	if temps >= delai_avertissement:
		_declencher_impact()

func _declencher_impact() -> void:
	etat = "impact"
	_regler_vfx(false)
	_toucher(degats_impact)
	impact.emit()
	_creer_flaque()
	_terminer()

func _terminer() -> void:
	set_process(false)
	var fondu := create_tween().set_parallel(true)
	fondu.tween_property(mat_remplissage, "albedo_color:a", 0.0, 0.4)
	fondu.tween_property(anneau.material_override, "albedo_color:a", 0.0, 0.4)
	
	fondu.chain().tween_callback(queue_free)

func _toucher(montant: float) -> void:
	var groupes: Array[String] = []
	if touche_joueur: groupes.append("player")
	if touche_victimes: groupes.append("victims")
	if touche_ennemis: groupes.append("mobiles")
	for groupe in groupes:
		for cible in get_tree().get_nodes_in_group(groupe):
			if not cible is Node3D or not cible.has_method("prendre_degats"): continue
			# Distance à plat : la hauteur du modèle ne doit pas sortir la cible de la zone.
			var ecart: Vector3 = cible.global_position - global_position
			ecart.y = 0.0
			if ecart.length() <= rayon:
				cible.prendre_degats(montant)
