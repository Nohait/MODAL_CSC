extends Node3D

const SHADER = preload("res://scenes/effets/combat/onde_deblayage.gdshader")
var effets: Node
var definition: Amelioration
var temps := 0.0
var touches: Dictionary[int, bool] = {}
var materiau: ShaderMaterial

func _ready() -> void:
	var support := MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = Vector2.ONE * (definition.rayon * 2.0 + 1.0)
	support.mesh = plan
	support.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	materiau = ShaderMaterial.new()
	materiau.shader = SHADER
	materiau.set_shader_parameter("rayon", 0.0)
	support.material_override = materiau
	add_child(support)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(effets):
		queue_free()
		return
	temps += delta
	var progression := clampf(temps / maxf(definition.duree_effet, 0.05), 0.0, 1.0)
	var rayon := progression * definition.rayon
	materiau.set_shader_parameter("rayon", rayon)
	materiau.set_shader_parameter("progression", progression)
	# Le front visuel et le front de dégâts avancent ensemble, une touche par ennemi.
	for ennemi in effets.ennemis_proches(global_position, definition.rayon + 3.0):
		var identifiant: int = ennemi.get_instance_id()
		if touches.has(identifiant): continue
		var direction: Vector3 = ennemi.global_position - global_position
		direction.y = 0.0
		if direction.length() > rayon + ennemi.hitbox_radius: continue
		touches[identifiant] = true
		effets.infliger(ennemi, effets.valeur("synergie_belier"), &"dash")
		if ennemi is CharacterBody3D and not ennemi.est_mort:
			if direction.length_squared() < 0.001: direction = effets.joueur.last_direction
			effets.etat(ennemi).repousser(direction, definition.contrepartie, definition.duree_recul, true)
	if progression >= 1.0:
		# Laisser le dernier front être dessiné avant le court fondu final.
		set_physics_process(false)
		var fondu := create_tween()
		fondu.tween_method(func(alpha: float): materiau.set_shader_parameter("opacite", alpha), 1.0, 0.0, 0.15)
		fondu.tween_callback(queue_free)
