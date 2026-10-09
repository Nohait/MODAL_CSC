extends Node
const SECURITE_MATERIAU = preload("res://scenes/systemes/reglages/securite_materiau.gd")

@export var profils: Array[ProfilGraphique] = [
	preload("res://scenes/systemes/reglages/profils/economique.tres"),
	preload("res://scenes/systemes/reglages/profils/equilibre.tres"),
	preload("res://scenes/systemes/reglages/profils/complet.tres"),
	# Ajouter à la fin conserve les indices des profils déjà sauvegardés.
	preload("res://scenes/systemes/reglages/profils/grille_pain.tres")
]
var indice := 2
var details: Array[GeometryInstance3D] = []
var personnalise := false
var parametres: Dictionary = {}
var elements: Array[Node] = []
var materiaux_conserves: Array = []
var materiaux_simples: Dictionary = {}

func _ready() -> void:
	# Ne visiter que les branches de décoration explicitement marquées.
	get_tree().node_added.connect(_noeud_ajoute)
	appliquer(indice)

func _noeud_ajoute(noeud: Node) -> void:
	# Installer immédiatement : un aperçu de modèle peut être supprimé dans la même frame.
	if noeud is MeshInstance3D and noeud.get_script() == null:
		noeud.set_script(SECURITE_MATERIAU)
	if noeud is Light3D or noeud is WorldEnvironment or noeud is ReflectionProbe or noeud is MeshInstance3D:
		_enregistrer_identifiant.call_deferred(noeud.get_instance_id(), false)
	if noeud.is_in_group("details_decor"):
		_enregistrer_identifiant.call_deferred(noeud.get_instance_id(), true)

func _enregistrer_identifiant(identifiant: int, detail: bool) -> void:
	# Certains modèles de test sont supprimés avant le prochain tour de boucle.
	var noeud = instance_from_id(identifiant)
	if not is_instance_valid(noeud) or not noeud.is_inside_tree(): return
	if detail: _enregistrer(noeud)
	else: _enregistrer_element(noeud)

func _enregistrer(noeud: Node) -> void:
	if not is_instance_valid(noeud): return
	if noeud is GeometryInstance3D and not noeud is GPUParticles3D:
		if not noeud.has_meta("portee_graphique_originale"):
			noeud.set_meta("portee_graphique_originale", noeud.visibility_range_end)
			noeud.set_meta("marge_graphique_originale", noeud.visibility_range_end_margin)
			noeud.set_meta("fondu_graphique_original", noeud.visibility_range_fade_mode)
			details.append(noeud)
		_regler_detail(noeud)
	for enfant in noeud.get_children():
		_enregistrer(enfant)

func appliquer(nouvel_indice: int) -> void:
	indice = clampi(nouvel_indice, 0, profils.size() - 1)
	personnalise = false
	for nom in ["resolution_3d", "distance_details", "ombres", "reflets_ecran", "sondes_reflets", "brillance_lumieres", "textures_decor", "lueur", "lumieres_decor", "seuil_lod"]:
		parametres[nom] = profils[indice].get(nom)
	_actualiser()

func regler(nom: String, valeur: Variant) -> void:
	parametres[nom] = valeur
	personnalise = true
	_actualiser()

func _actualiser() -> void:
	# Seule la 3D baisse en résolution : les textes de l'interface restent nets.
	get_viewport().scaling_3d_scale = parametres.resolution_3d
	# Utiliser plus tôt les versions simplifiées déjà présentes dans les modèles importés.
	get_viewport().mesh_lod_threshold = parametres.seuil_lod
	details = details.filter(func(detail): return is_instance_valid(detail))
	for detail in details: _regler_detail(detail)
	elements = elements.filter(func(n): return is_instance_valid(n))
	for element in elements: _regler_element(element)

func _regler_detail(detail: GeometryInstance3D) -> void:
	var profil := parametres
	var origine: float = detail.get_meta("portee_graphique_originale")
	detail.visibility_range_end = origine if profil.distance_details == 0.0 else (minf(origine, profil.distance_details) if origine > 0.0 else profil.distance_details)
	detail.visibility_range_end_margin = detail.get_meta("marge_graphique_originale") if profil.distance_details == 0.0 else profils[indice].marge_distance
	# La marge crée une hystérésis : pas de clignotement à la limite de distance.
	detail.visibility_range_fade_mode = detail.get_meta("fondu_graphique_original") if profil.distance_details == 0.0 else GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

func _enregistrer_element(noeud: Node) -> void:
	if not is_instance_valid(noeud) or elements.has(noeud): return
	elements.append(noeud)
	if noeud is Light3D:
		noeud.set_meta("ombres_originales", noeud.shadow_enabled)
		noeud.set_meta("energie_originale", noeud.light_energy)
		noeud.set_meta("brillance_originale", noeud.light_specular)
	elif noeud is WorldEnvironment and noeud.environment != null:
		# Le niveau a déjà sa copie ; garder celle utilisée par son éclairage dynamique.
		noeud.set_meta("reflets_originaux", noeud.environment.ssr_enabled)
		noeud.set_meta("lueur_originale", noeud.environment.glow_enabled)
	elif noeud is ReflectionProbe:
		noeud.set_meta("sonde_visible", noeud.visible)
	elif noeud is MeshInstance3D:
		noeud.tree_exiting.connect(_liberer_remplacements.bind(noeud))
	_regler_element(noeud)

func _est_decor(noeud: Node) -> bool:
	var parent := noeud
	while parent != null:
		if parent.is_in_group("enemies") or parent.is_in_group("player") or parent.is_in_group("victime"): return false
		if parent.is_in_group("details_decor") or parent.name in ["Decor", "Ville", "EnveloppeBatiment"]: return true
		parent = parent.get_parent()
	return false

func _regler_element(noeud: Node) -> void:
	if parametres.is_empty(): return
	if noeud is Light3D:
		noeud.light_specular = noeud.get_meta("brillance_originale", 1.0) if parametres.brillance_lumieres else 0.0
		noeud.shadow_enabled = noeud.get_meta("ombres_originales", false) and parametres.ombres
		# Les lumières de combat restent actives : laser, glace, flammes et boss.
		if _est_decor(noeud):
			noeud.light_energy = noeud.get_meta("energie_originale", 1.0) if parametres.lumieres_decor else 0.0
	elif noeud is WorldEnvironment and noeud.environment != null:
		noeud.environment.ssr_enabled = noeud.get_meta("reflets_originaux", false) and parametres.reflets_ecran
		noeud.environment.glow_enabled = noeud.get_meta("lueur_originale", false) and parametres.lueur
	elif noeud is ReflectionProbe:
		noeud.visible = noeud.get_meta("sonde_visible", true) and parametres.sondes_reflets
	elif noeud is MeshInstance3D and noeud.mesh != null and _est_decor(noeud):
		if not noeud.has_meta("materiau_decor_original"):
			noeud.set_meta("materiau_decor_original", {"override": noeud.material_override, "surfaces": []})
			var origine: Dictionary = noeud.get_meta("materiau_decor_original")
			for i in range(noeud.mesh.get_surface_count()):
				origine.surfaces.append(noeud.get_surface_override_material(i))
		var origine: Dictionary = noeud.get_meta("materiau_decor_original")
		if parametres.textures_decor:
			noeud.set_meta("decor_simplifie", false)
			noeud.material_override = origine.override
			for i in range(origine.surfaces.size()): noeud.set_surface_override_material(i, origine.surfaces[i])
		else:
			if noeud.get_meta("decor_simplifie", false): return
			# Garder les matières transparentes évite de rendre les fenêtres opaques.
			var actif: Material = noeud.get_active_material(0)
			# Les shaders d'effets restent visibles : feu, trous et indications de jeu.
			if actif is ShaderMaterial:
				var nom: String = actif.shader.resource_path.get_file() if actif.shader != null else ""
				if not nom.begins_with("sol_") and not nom.begins_with("mur_"): return
			if actif is BaseMaterial3D and actif.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: return
			var cle: int = actif.get_instance_id() if actif != null else 0
			if not materiaux_simples.has(cle):
				var mat := StandardMaterial3D.new()
				mat.albedo_color = actif.albedo_color if actif is BaseMaterial3D else Color(0.45, 0.44, 0.42)
				mat.roughness = 0.9
				materiaux_simples[cle] = mat
			noeud.material_override = materiaux_simples[cle]
			noeud.set_meta("decor_simplifie", true)

func _liberer_remplacements(mesh: MeshInstance3D) -> void:
	# Éviter les références de rendu périmées lors de la destruction d'un effet.
	# Un simple changement de parent ne doit pas effacer ses matériaux.
	var parent: Node = mesh
	var suppression := false
	while parent != null:
		suppression = suppression or parent.is_queued_for_deletion()
		parent = parent.get_parent()
	if not suppression: return
	var retenus: Array[Material] = []
	for i in range(mesh.get_surface_override_material_count()):
		var mat := mesh.get_surface_override_material(i)
		if mat != null: retenus.append(mat)
		mesh.set_surface_override_material(i, null)
	if mesh.material_override != null: retenus.append(mesh.material_override)
	if mesh.material_overlay != null: retenus.append(mesh.material_overlay)
	mesh.material_override = null
	mesh.material_overlay = null
	# Garder les ressources jusqu'au traitement des commandes du moteur de rendu.
	materiaux_conserves.append(retenus)
	_relacher_materials(retenus)

func _relacher_materials(retenus: Array[Material]) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	materiaux_conserves.erase(retenus)

func _process(_delta: float) -> void:
	if parametres.is_empty() or parametres.lumieres_decor: return
	# Les scripts de scintillement peuvent écrire l'énergie après les options.
	for element in elements:
		if is_instance_valid(element) and element is Light3D and _est_decor(element):
			element.light_energy = 0.0
