extends Node3D

## Indicateur de debug : le masquer ne change jamais les dégâts.
@export var affiche := true
## Hauteur mondiale, à adapter au sol plat de la salle.
@export var hauteur_sol := 0.03
@export var couleur_normale := Color.WHITE
@export var couleur_impact := Color(1.0, 0.12, 0.06)
@export_range(0.0, 1.0, 0.01) var opacite_fond := 0.035
@export_range(0.0, 1.0, 0.01) var opacite_contour := 0.3
## Maintient brièvement le rouge entre deux impacts.
@export_range(0.0, 1.0, 0.01) var duree_impact := 0.15

@onready var extincteur = get_parent()
var temps_impact := 0.0
var surfaces: Array[MeshInstance3D] = []
var plan := PlaneMesh.new()


func _ready() -> void:
	hide()
	# Rester à plat, sans hériter de l'échelle ou de la rotation de l'arme.
	top_level = true
	global_transform = Transform3D.IDENTITY


func signaler_impact() -> void:
	temps_impact = duree_impact


func _process(delta: float) -> void:
	temps_impact = maxf(temps_impact - delta, 0.0)
	# Lire les portions réelles plutôt que le bouton : après relâchement,
	# les dernières particules sont encore actives et doivent rester indiquées.
	visible = affiche and not extincteur.portions_jet.is_empty()
	if not visible:
		temps_impact = 0.0
		return
	adapter_surfaces(extincteur.portions_jet.size())
	var origine: Vector3 = extincteur.muzzle.global_position
	global_position = Vector3(origine.x, hauteur_sol, origine.z)
	var taille: Vector2 = Vector2.ONE * extincteur.portee_jet * 2.0
	if plan.size != taille:
		plan.size = taille
	var direction: Vector3 = extincteur.direction_jet()
	for i in surfaces.size():
		var materiau := surfaces[i].material_override as ShaderMaterial
		var portion: Vector2 = extincteur.portions_jet[i]
		materiau.set_shader_parameter("origine_jet", Vector2(origine.x, origine.z))
		materiau.set_shader_parameter("direction_jet", Vector2(direction.x, direction.z))
		materiau.set_shader_parameter("rayon_min", portion.x)
		materiau.set_shader_parameter("rayon_max", portion.y)
		materiau.set_shader_parameter("demi_angle", deg_to_rad(extincteur.demi_angle_jet))
		materiau.set_shader_parameter("angle_interieur", deg_to_rad(extincteur.demi_angle_jet * 0.3) if extincteur.double_lance else 0.0)
		materiau.set_shader_parameter("opacite_fond", opacite_fond)
		materiau.set_shader_parameter("opacite_contour", opacite_contour)
		materiau.set_shader_parameter("couleur", couleur_impact if temps_impact > 0.0 else couleur_normale)


func adapter_surfaces(nombre: int) -> void:
	# Un plan par portion : des clics rapprochés peuvent produire deux jets
	# séparés par du vide. Un seul grand cône masquerait cet espace.
	while surfaces.size() < nombre:
		var surface := MeshInstance3D.new()
		surface.mesh = plan
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var materiau := ShaderMaterial.new()
		materiau.shader = preload("res://scenes/armes/extincteur/indicateur_attaque.gdshader")
		surface.material_override = materiau
		add_child(surface)
		surfaces.append(surface)
	while surfaces.size() > nombre:
		var surface: MeshInstance3D = surfaces.pop_back()
		surface.hide()
		surface.queue_free()
