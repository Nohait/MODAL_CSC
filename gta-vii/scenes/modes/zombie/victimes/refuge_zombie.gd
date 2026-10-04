extends StaticBody3D

const ICONE = preload("res://assets/textures/interfaces/ameliorations/icone_victimes.svg")
# Seules les données restent dans le refuge ; les personnages déposés sont retirés.
var victimes: Array[Dictionary] = []
var is_freed: bool:
	get: return not victimes.is_empty()
var escorte: Node
var depot_demande := false
var survole := false
var surbrillance: ShaderMaterial
var meshes: Array[Node] = []
var compteur: Label3D
var barre: Sprite3D
var viewport: SubViewport
var vie_barre: ProgressBar
var indication: Label3D
var reduction_degats := 0.0
var boucliers: Array[Dictionary] = []
var barre_bouclier: ProgressBar
var sprite_bouclier: Sprite3D
var sirene_restante := 0.0
var rayon_sirene := 0.0

func _ready() -> void:
	add_to_group("refuge_zombie")
	add_to_group("victime")
	add_to_group("fleche")
	collision_layer = 9
	collision_mask = 0
	# Le modèle et sa collision restent éditables dans refuge_zombie.tscn.
	meshes = $Modele.find_children("*", "MeshInstance3D", true, false)
	surbrillance = ShaderMaterial.new()
	surbrillance.shader = preload("res://scenes/modes/zombie/victimes/surbrillance_refuge.gdshader")
	compteur = _texte(2.65, 26)
	var icone := Sprite3D.new()
	icone.texture = ICONE
	icone.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icone.pixel_size = 0.008
	icone.position = Vector3(-0.4, 2.65, 0)
	add_child(icone)
	viewport = SubViewport.new()
	viewport.size = Vector2i(160, 18)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	vie_barre = ProgressBar.new()
	vie_barre.size = Vector2(160, 18)
	vie_barre.show_percentage = false
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color("30231d")
	var plein := StyleBoxFlat.new()
	plein.bg_color = Color("92b86e")
	vie_barre.add_theme_stylebox_override("background", fond)
	vie_barre.add_theme_stylebox_override("fill", plein)
	viewport.add_child(vie_barre)
	barre = Sprite3D.new()
	barre.texture = viewport.get_texture()
	barre.pixel_size = 0.01
	barre.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	barre.position.y = 2.3
	add_child(barre)
	# Une seconde barre bleue représente la protection, au-dessus des PV verts.
	var vue_bouclier := SubViewport.new()
	vue_bouclier.size = Vector2i(160, 12)
	vue_bouclier.transparent_bg = true
	vue_bouclier.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vue_bouclier)
	barre_bouclier = ProgressBar.new()
	barre_bouclier.size = Vector2(160, 12)
	barre_bouclier.show_percentage = false
	var bleu := StyleBoxFlat.new()
	bleu.bg_color = Color("55b5eb")
	barre_bouclier.add_theme_stylebox_override("fill", bleu)
	barre_bouclier.add_theme_stylebox_override("background", fond)
	vue_bouclier.add_child(barre_bouclier)
	sprite_bouclier = Sprite3D.new()
	sprite_bouclier.texture = vue_bouclier.get_texture()
	sprite_bouclier.pixel_size = 0.01
	sprite_bouclier.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite_bouclier.position.y = 2.48
	add_child(sprite_bouclier)
	indication = _texte(3.15, 20)
	indication.text = "Clic milieu : mettre l’escorte à l’abri"
	actualiser()

func _texte(hauteur: float, taille: int) -> Label3D:
	var texte := Label3D.new()
	texte.position.y = hauteur
	texte.font_size = taille
	texte.pixel_size = 0.01
	texte.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texte.no_depth_test = true
	add_child(texte)
	return texte

func _physics_process(delta: float) -> void:
	sirene_restante = maxf(0.0, sirene_restante - delta)
	# Le survol utilise le vrai volume 3D, même quand la caméra est inclinée.
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	var souris := get_viewport().get_mouse_position()
	var origine := camera.project_ray_origin(souris)
	var requete := PhysicsRayQueryParameters3D.create(origine, origine + camera.project_ray_normal(souris) * 200, 8)
	var resultat := get_world_3d().direct_space_state.intersect_ray(requete)
	var nouveau_survol: bool = resultat.get("collider") == self
	if nouveau_survol != survole:
		survole = nouveau_survol
		# L’overlay ne s’ajoute qu’au survol ; les matériaux importés restent intacts.
		for mesh in meshes:
			mesh.material_overlay = surbrillance if survole else null
	indication.visible = survole
	if not depot_demande or not is_instance_valid(escorte): return
	# On attend leur arrivée : cliquer ne téléporte aucune victime.
	for victime in escorte.freed_victims.duplicate():
		if not is_instance_valid(victime) or victime.est_morte: continue
		var ecart: Vector3 = victime.global_position - global_position
		ecart.y = 0
		# La distance suit le bord du camion, y compris près de ses extrémités.
		if ecart.length() <= distance_au_bord(victime.global_position) + 0.9:
			victimes.append({"vie": victime.vie, "vie_max": victime.vie_max, "ordre": victime.get_meta("ordre_liberation", 0)})
			# L’ordre de libération prime sur l’ordre d’arrivée au refuge.
			victimes.sort_custom(func(a, b): return a.ordre < b.ordre)
			escorte.freed_victims.erase(victime)
			victime.queue_free()
			actualiser()
	if escorte.freed_victims.is_empty():
		depot_demande = false
		escorte.escort_changed.emit()

func prendre_degats(degats: float) -> void:
	if victimes.is_empty(): return
	var restant := maxf(0, degats)
	# Les protections les plus anciennes absorbent le coup avant les victimes.
	for bouclier in boucliers:
		var absorbe := minf(restant, bouclier.bouclier_restant)
		bouclier.bouclier_restant -= absorbe
		restant -= absorbe
		if restant == 0: break
	# Le blindage réduit seulement la partie qui atteint les occupants.
	restant *= 1.0 - clampf(reduction_degats, 0.0, 0.8)
	victimes[-1].vie = maxf(0, victimes[-1].vie - restant)
	if victimes[-1].vie == 0:
		victimes.pop_back()
	actualiser()

func actualiser() -> void:
	compteur.text = str(victimes.size())
	var total := 0.0
	var maximum := 0.0
	for bouclier in boucliers:
		total += bouclier.bouclier_restant
		maximum += bouclier.gain
	sprite_bouclier.visible = total > 0
	barre_bouclier.max_value = maxf(1, maximum)
	barre_bouclier.value = total
	barre.visible = not victimes.is_empty()
	if not victimes.is_empty():
		vie_barre.max_value = victimes[-1].vie_max
		vie_barre.value = victimes[-1].vie

func distance_au_bord(position_monde: Vector3) -> float:
	# Rayon du camion dans la direction de l’attaquant : il est plus long que large.
	var direction := to_local(position_monde)
	direction.y = 0
	if direction.length_squared() < 0.001: return 0
	direction = direction.normalized()
	var demi_taille: Vector3 = $CollisionShape3D.shape.size / 2.0
	var bord_x := demi_taille.x / maxf(absf(direction.x), 0.001)
	var bord_z := demi_taille.z / maxf(absf(direction.z), 0.001)
	return minf(bord_x, bord_z)

func soigner_victimes(gain: float) -> void:
	# On conserve l’ordre et on ne ressuscite pas les victimes retirées de la liste.
	for victime in victimes:
		victime.vie = minf(victime.vie_max, victime.vie + gain)
	actualiser()

func attire(ennemi: Node3D) -> bool:
	return sirene_restante > 0.0 and global_position.distance_to(ennemi.global_position) <= rayon_sirene

func declencher_sirene(rayon: float, duree: float) -> void:
	rayon_sirene = rayon
	sirene_restante = duree
	var anneau := MeshInstance3D.new()
	var forme := TorusMesh.new()
	forme.inner_radius = 0.95
	forme.outer_radius = 1.0
	anneau.mesh = forme
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.3, 0.7, 1.0, 0.7)
	anneau.material_override = mat
	add_child(anneau)
	anneau.position.y = 0.12
	# L'onde s'élargit en même temps qu'elle s'efface, puis son nœud est supprimé.
	var onde := create_tween().set_parallel(true)
	onde.tween_property(anneau, "scale", Vector3(rayon, 1, rayon), 0.7)
	onde.tween_property(mat, "albedo_color:a", 0.0, 0.7)
	onde.chain().tween_callback(anneau.queue_free)
