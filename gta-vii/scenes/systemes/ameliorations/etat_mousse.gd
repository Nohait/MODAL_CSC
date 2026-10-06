extends Node

var effets: Node
var temps_jet := 0.0
var enrobage_restant := 0.0
var gel_restant := 0.0
var delai_gel := 0.0
var dernier_contact := 0.0
var recul := Vector3.ZERO
var recul_restant := 0.0
var recul_initial := 0.2
var recul_prioritaire := false
var halo: MeshInstance3D
var halo_materiau: StandardMaterial3D

func _ready() -> void:
	process_physics_priority = 2
	get_parent().died.connect(_mort)
	halo = MeshInstance3D.new()
	var cercle := TorusMesh.new()
	cercle.inner_radius = 0.88
	cercle.outer_radius = 1.0
	halo.mesh = cercle
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo_materiau = StandardMaterial3D.new()
	halo_materiau.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_materiau.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.material_override = halo_materiau
	get_parent().add_child(halo)
	halo.position.y = 0.7
	halo.scale = Vector3(0.65, 0.2, 0.65)
	halo.hide()

func toucher_jet(delta: float) -> void:
	# Additionner le contact réel, et non le temps pendant lequel le bouton reste tenu.
	dernier_contact = 0.0
	temps_jet += delta
	if effets.valeur("enrobage") > 0 and temps_jet >= 0.8:
		enrobage_restant = 3.0
	if effets.valeur("gel_profond") > 0 and temps_jet >= 1.2 and delai_gel <= 0:
		gel_restant = effets.valeur("gel_profond")
		delai_gel = 5.0
		temps_jet = 0.0
		# Le bleu et l'anneau restent visibles pendant l'immobilisation.
		if get_parent().has_method("appliquer_gel"): get_parent().appliquer_gel(80, gel_restant)

func refroidi() -> bool:
	var gel := get_parent().get_node_or_null("Ralentissement")
	return gel_restant > 0 or (gel != null and gel.restant > 0)

func multiplier_degats(_source: StringName) -> float:
	return 1.0 + (effets.valeur("enrobage") / 100.0 if enrobage_restant > 0 else 0.0)

func repousser(direction: Vector3, force: float, duree: float = 0.2, prioritaire: bool = false) -> void:
	# Un petit recul continu du jet ne doit pas écraser l'impulsion de l'onde.
	if recul_prioritaire and recul_restant > 0.0 and not prioritaire: return
	direction.y = 0.0
	recul = direction.normalized() * force
	recul_restant = duree
	recul_initial = maxf(duree, 0.01)
	recul_prioritaire = prioritaire

func _physics_process(delta: float) -> void:
	dernier_contact += delta
	if dernier_contact > 0.3: temps_jet = 0.0
	enrobage_restant = maxf(0, enrobage_restant - delta)
	gel_restant = maxf(0, gel_restant - delta)
	delai_gel = maxf(0, delai_gel - delta)
	halo.visible = enrobage_restant > 0 or gel_restant > 0
	halo_materiau.albedo_color = Color(0.15, 0.65, 1, 0.8) if gel_restant > 0 else Color(0.9, 0.95, 0.85, 0.7)
	if recul_restant > 0 and get_parent() is CharacterBody3D:
		var pas := minf(delta, recul_restant)
		var frein := recul_restant / recul_initial if recul_prioritaire else 1.0
		recul_restant = maxf(0.0, recul_restant - delta)
		# L'impulsion ralentit progressivement et les collisions arrêtent le recul aux murs.
		get_parent().move_and_collide(recul * pas * frein)

func _mort() -> void:
	if not is_instance_valid(effets): return
	var position: Vector3 = get_parent().global_position
	effets.ennemi_tue()
	var degats_explosion: float = effets.valeur("choc_thermique") if refroidi() else 0.0
	if gel_restant > 0: degats_explosion += effets.valeur("eclats_glace")
	if degats_explosion > 0:
		# Une seule explosion réunit les cartes ; elle ne cible que les ennemis.
		# Différer l'appel évite une autre mort au milieu du signal died actuel.
		effets.call_deferred("explosion", position, 2.5, degats_explosion, true)
	if enrobage_restant > 0 and effets.valeur("reaction_chaine") > 0:
		for ennemi in effets.ennemis_proches(position, effets.valeur("reaction_chaine")):
			if ennemi == get_parent(): continue
			effets.etat(ennemi).enrobage_restant = 3.0
