extends MeshInstance3D

## Autorise l'indicateur ; il reste masqué si le bouton d'attaque est relâché.
@export var affiche := true
## Hauteur mondiale : les salles actuelles ont leur sol à Y = 0.
@export var hauteur_sol := 0.03
@export var couleur_normale := Color.WHITE
@export var couleur_impact := Color(1.0, 0.12, 0.06)
## Maintient brièvement le rouge entre deux impacts pour éviter le clignotement.
@export_range(0.0, 1.0, 0.01) var duree_impact := 0.15

@onready var extincteur = get_parent()
var materiau: ShaderMaterial
var temps_impact := 0.0


func _ready() -> void:
	hide()
	# Ne pas hériter de la rotation ni de l'échelle de l'arme : rester à plat.
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	materiau = ShaderMaterial.new()
	materiau.shader = preload("res://scenes/armes/extincteur/indicateur_attaque.gdshader")
	material_override = materiau
	mesh = PlaneMesh.new()


func signaler_impact() -> void:
	# Appelé par le code qui inflige réellement les dégâts.
	temps_impact = duree_impact


func _process(delta: float) -> void:
	temps_impact = maxf(temps_impact - delta, 0.0)
	# Lire l'action plutôt qu'un bouton précis : fonctionne aussi si on change
	# les contrôles. Chaque future attaque pourra utiliser sa propre action.
	visible = affiche and Input.is_action_pressed("primary_attack")
	if not visible:
		# Un nouvel appui commence en blanc, sans conserver un ancien impact.
		temps_impact = 0.0
		return
	var collision: CollisionShape3D = extincteur.damage_area.get_node("CollisionShape3D")
	var sphere := collision.shape as SphereShape3D
	var centre := collision.global_position
	# Inclure l'échelle réelle de la collision, même si celle de l'arme change.
	var rayon := sphere.radius * collision.global_basis.get_scale().abs().x
	global_position = Vector3(centre.x, hauteur_sol, centre.z)
	var taille := Vector2.ONE * rayon * 2.0
	# Ne reconstruire le plan que si la portée change.
	if (mesh as PlaneMesh).size != taille:
		(mesh as PlaneMesh).size = taille
	var origine: Vector3 = extincteur.muzzle.global_position
	var direction: Vector3 = extincteur.direction_marker.global_position - origine
	var direction_sol := Vector2(direction.x, direction.z).normalized()
	materiau.set_shader_parameter("centre_zone", Vector2(centre.x, centre.z))
	materiau.set_shader_parameter("origine_jet", Vector2(origine.x, origine.z))
	materiau.set_shader_parameter("direction_jet", direction_sol)
	materiau.set_shader_parameter("rayon", rayon)
	materiau.set_shader_parameter("demi_angle", deg_to_rad(extincteur.particles.process_material.spread / 2.0))
	materiau.set_shader_parameter("couleur", couleur_impact if temps_impact > 0.0 else couleur_normale)
