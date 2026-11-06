extends Node3D

const PLACEMENT_ZONE_SOL = preload("res://scenes/systemes/ennemis/placement_zone_sol.gd")

var definition: ModificateurElite
var horloge := 0.0
var anneau: MeshInstance3D
var symbole: Label3D
var cible: Node3D
var presentation := false
var teinte: ShaderMaterial
var overlays := {}
var halo_applique := false
var decalage_sol := 0.0
var braises: CPUParticles3D

func _ready() -> void:
	cible = get_parent()
	if presentation:
		cible.scale *= definition.taille
	if not presentation:
		cible.vie_max *= definition.vie
		cible.vie *= definition.vie
		# Agrandir aussi la collision ; la navigation tient compte du nouveau rayon.
		var collision: CollisionShape3D = cible.get_node("CollisionShape3D")
		# Garder le bas de la collision au même endroit quand le Colosse grandit.
		decalage_sol = calculer_decalage_sol(collision, cible.scale.y, definition.taille)
		cible.position.y += decalage_sol
		cible.scale *= definition.taille
		cible.hitbox_radius *= definition.taille
		cible.navigation_agent.radius *= definition.taille
	_habiller()

static func calculer_decalage_sol(collision: CollisionShape3D, echelle_y: float, taille: float) -> float:
	var demi_hauteur := 0.0
	if collision.shape is CapsuleShape3D: demi_hauteur = collision.shape.height / 2.0
	elif collision.shape is SphereShape3D: demi_hauteur = collision.shape.radius
	elif collision.shape is BoxShape3D: demi_hauteur = collision.shape.size.y / 2.0
	return (demi_hauteur - collision.position.y) * echelle_y * (taille - 1.0)

func est_enrage() -> bool:
	return definition.seuil_rage > 0.0 and not presentation and cible.vie <= cible.vie_max * definition.seuil_rage

func vitesse() -> float:
	return definition.vitesse if definition.seuil_rage == 0.0 or est_enrage() else 1.0

func degats() -> float:
	return definition.degats if definition.seuil_rage == 0.0 or est_enrage() else 1.0

func _habiller() -> void:
	teinte = ShaderMaterial.new()
	teinte.shader = preload("res://scenes/systemes/ennemis/habillage_elite.gdshader")
	teinte.set_shader_parameter("teinte", definition.couleur)
	teinte.set_shader_parameter("opacite_corps", definition.opacite_couleur_corps)
	teinte.set_shader_parameter("emission", definition.emission_halo)
	_appliquer_halo()
	anneau = _anneau(0.8, 0.022)
	anneau.position.y = PLACEMENT_ZONE_SOL.hauteur_locale(cible, 0.03, -0.7)
	if definition.aura != "aucune" and not presentation:
		var zone := _anneau(definition.rayon_aura / cible.scale.x, 0.025)
		zone.position.y = PLACEMENT_ZONE_SOL.hauteur_locale(cible, 0.05, anneau.position.y + 0.02)
		zone.material_override.set_shader_parameter("aura", true)
		zone.material_override.set_shader_parameter("puissance", definition.intensite_zone_aura)
	symbole = Label3D.new()
	symbole.text = definition.symbole
	symbole.font_size = 42
	symbole.pixel_size = 0.007
	symbole.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	symbole.modulate = definition.couleur
	symbole.outline_modulate = Color(0.04, 0.02, 0.02)
	symbole.position.y = 2.3
	add_child(symbole)
	_creer_braises()

func _anneau(rayon: float, _epaisseur: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var forme := PlaneMesh.new()
	forme.size = Vector2.ONE * rayon * 2.0 / 0.975
	mesh.mesh = forme
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/systemes/ennemis/sceau_elite.gdshader")
	mat.set_shader_parameter("teinte", definition.couleur)
	mat.set_shader_parameter("puissance", definition.intensite_visuelle)
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh

func _process(delta: float) -> void:
	horloge += delta
	# L'enragé se met à pulser plus fort dès qu'il passe sous son seuil.
	var rage := est_enrage()
	if not halo_applique: _appliquer_halo()
	teinte.set_shader_parameter("horloge", horloge)
	teinte.set_shader_parameter("intensite", definition.intensite_halo * (definition.halo_rage if rage else 1.0))
	anneau.scale = Vector3.ONE * (1.0 + sin(horloge * (8.0 if rage else 3.0)) * 0.04)
	symbole.modulate = definition.couleur * (1.4 if rage else 1.0)
	if braises != null:
		braises.emitting = cible.get("est_mort") != true and (definition.seuil_rage == 0.0 or rage)
		if definition.identifiant == "rapide" and cible is CharacterBody3D:
			var mouvement: Vector3 = cible.velocity
			mouvement.y = 0.0
			braises.emitting = braises.emitting and mouvement.length() > 0.2
			braises.direction = (-mouvement.normalized() + Vector3.UP * 0.3).normalized()

func _appliquer_halo() -> void:
	# Attendre la fin du dissolve pour ne pas révéler la silhouette trop tôt.
	var apparition := cible.get_node_or_null("ApparitionSbire")
	if apparition != null and not apparition.termine: return
	halo_applique = true
	if definition.intensite_halo <= 0.0: return
	teinte.set_shader_parameter("intensite", definition.intensite_halo)
	# Limiter le halo au modèle : le plan transparent d'apparition reste intact.
	for chemin in ["sbire", "hound", "Sketchfab_Scene"]:
		var modele := cible.get_node_or_null(chemin)
		if modele == null: continue
		for mesh in modele.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null: continue
			var materiau_corps := false
			for surface in range(mesh.mesh.get_surface_count()):
				if mesh.get_active_material(surface) is BaseMaterial3D:
					materiau_corps = true
			if not materiau_corps: continue
			overlays[mesh] = mesh.material_overlay
			# Un gel en cours garde la priorité ; il rendra le halo à sa disparition.
			var precedent: Material = mesh.material_overlay
			if precedent is ShaderMaterial and precedent.shader != null and precedent.shader.resource_path.ends_with("teinte_givree.gdshader"):
				overlays[mesh] = null
			else:
				mesh.material_overlay = teinte

func retirer() -> void:
	# Conserver la proportion de PV : revenir à la normale ne soigne personne.
	if not presentation:
		cible.vie_max /= definition.vie
		cible.vie /= definition.vie
		cible.scale /= definition.taille
		cible.position.y -= decalage_sol
		cible.hitbox_radius /= definition.taille
		cible.navigation_agent.radius /= definition.taille
	for mesh in overlays:
		if is_instance_valid(mesh) and mesh.material_overlay == teinte:
			mesh.material_overlay = overlays[mesh]
	get_parent().remove_child(self)
	queue_free()

func _creer_braises() -> void:
	if definition.particules_visuelles == 0: return
	braises = CPUParticles3D.new()
	braises.amount = definition.particules_visuelles
	braises.lifetime = 0.6
	braises.position.y = 0.1
	braises.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	braises.emission_sphere_radius = 0.45
	braises.direction = Vector3.UP
	braises.spread = 25.0
	braises.gravity = Vector3.ZERO
	braises.initial_velocity_min = 0.4
	braises.initial_velocity_max = 0.9
	braises.scale_amount_min = 0.5
	braises.scale_amount_max = 1.0
	var forme := SphereMesh.new()
	forme.radius = 0.025
	forme.height = 0.05
	forme.radial_segments = 4
	forme.rings = 2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.WHITE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	gradient.colors = PackedColorArray([Color(definition.couleur, 0.0), definition.couleur, Color(definition.couleur, 0.0)])
	braises.color_ramp = gradient
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	forme.material = mat
	braises.mesh = forme
	braises.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Quelques braises suffisent ; l'enragé ne les émet qu'une fois son seuil atteint.
	add_child(braises)
