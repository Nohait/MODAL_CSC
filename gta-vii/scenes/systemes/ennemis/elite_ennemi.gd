extends Node3D

var definition: ModificateurElite
var horloge := 0.0
var teinte: ShaderMaterial
var anneau: MeshInstance3D
var symbole: Label3D
var cible: Node3D
var presentation := false
var overlays := {}
var decalage_sol := 0.0

func _ready() -> void:
	cible = get_parent()
	if presentation:
		cible.scale *= definition.taille
	if not presentation:
		cible.vie_max *= definition.vie
		cible.vie *= definition.vie
		# Agrandir aussi la collision ; la navigation tient compte du nouveau rayon.
		var collision: CollisionShape3D = cible.get_node("CollisionShape3D")
		var demi_hauteur := 0.0
		if collision.shape is CapsuleShape3D: demi_hauteur = collision.shape.height / 2.0
		elif collision.shape is SphereShape3D: demi_hauteur = collision.shape.radius
		elif collision.shape is BoxShape3D: demi_hauteur = collision.shape.size.y / 2.0
		# Garder le bas de la collision au même endroit quand le Colosse grandit.
		decalage_sol = (demi_hauteur - collision.position.y) * cible.scale.y * (definition.taille - 1.0)
		cible.position.y += decalage_sol
		cible.scale *= definition.taille
		cible.hitbox_radius *= definition.taille
		cible.navigation_agent.radius *= definition.taille
	_habiller()

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
	for mesh in cible.find_children("*", "MeshInstance3D", true, false):
		if mesh.name in ["Laser", "Disque", "Cercle"] or str(mesh.name).begins_with("Zone"): continue
		overlays[mesh] = mesh.material_overlay
		mesh.material_overlay = teinte
	anneau = _anneau(0.8, 0.022)
	# La racine des mobiles se trouve au-dessus du sol.
	anneau.position.y = -cible.get_node("CollisionShape3D").shape.height / 2.0 if cible.has_node("CollisionShape3D") and cible.get_node("CollisionShape3D").shape is CapsuleShape3D else -0.7
	if definition.aura != "aucune" and not presentation:
		var zone := _anneau(definition.rayon_aura / cible.scale.x, 0.025)
		zone.position.y = anneau.position.y
		zone.material_override.albedo_color.a = 0.23
	symbole = Label3D.new()
	symbole.text = definition.symbole
	symbole.font_size = 60
	symbole.pixel_size = 0.009
	symbole.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	symbole.modulate = definition.couleur
	symbole.outline_modulate = Color(0.04, 0.02, 0.02)
	symbole.position.y = 2.3
	add_child(symbole)

func _anneau(rayon: float, epaisseur: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var tore := TorusMesh.new()
	tore.inner_radius = rayon - epaisseur
	tore.outer_radius = rayon + epaisseur
	tore.rings = 48
	tore.ring_segments = 8
	mesh.mesh = tore
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = definition.couleur
	mat.albedo_color.a = 0.5
	mat.emission_enabled = true
	mat.emission = definition.couleur
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh

func _process(delta: float) -> void:
	horloge += delta
	teinte.set_shader_parameter("horloge", horloge)
	# L'enragé se met à pulser plus fort dès qu'il passe sous son seuil.
	var rage := est_enrage()
	teinte.set_shader_parameter("intensite", 2.0 if rage else 1.0)
	anneau.scale = Vector3.ONE * (1.0 + sin(horloge * (8.0 if rage else 3.0)) * 0.04)
	symbole.modulate = definition.couleur * (1.4 if rage else 1.0)

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
