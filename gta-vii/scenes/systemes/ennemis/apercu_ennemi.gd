extends RefCounted

static func creer(scene: PackedScene, parent: Node) -> Node3D:
	# Ces modèles sont déjà placés dans leur scène : ne pas lancer leur IA ni le HUD du boss.
	var modele = scene.instantiate()
	var modele_autonome: bool = modele.has_node("sbire") or modele.has_node("hound") or modele.has_node("AnimationsBoss")
	modele.set_meta("apercu_glossaire", true)
	modele.process_mode = Node.PROCESS_MODE_DISABLED
	modele.hide()
	for noeud in [modele] + modele.find_children("*", "", true, false):
		for groupe in noeud.get_groups(): noeud.remove_from_group(groupe)
		if noeud is CollisionShape3D: noeud.disabled = true
	if not modele_autonome: parent.add_child(modele)
	var visuel := Node3D.new()
	for nom in ["sbire", "hound", "Sketchfab_Scene", "Visuel", "Flammes", "MeshInstance3D", "vfx_fire"]:
		var partie = modele.get_node_or_null(nom)
		if partie != null: visuel.add_child(partie.duplicate(0))
	if is_instance_valid(modele.get("cible_idle")): modele.cible_idle.free()
	modele.free()
	return visuel

static func preparer_pose(visuel: Node3D) -> void:
	# Une pose de repos fixe permet de mesurer le modèle sans ses scripts de combat.
	for arbre in visuel.find_children("*", "AnimationTree", true, false):
		arbre.active = false
	for lecteur in visuel.find_children("*", "AnimationPlayer", true, false):
		lecteur.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for nom in lecteur.get_animation_list():
			if nom.to_lower() == "attente" or "idle" in nom.to_lower():
				lecteur.play(nom)
				lecteur.seek(0.0, true)
				break
	for squelette in visuel.find_children("*", "Skeleton3D", true, false):
		squelette.force_update_all_bone_transforms()

static func mesurer(visuel: Node3D) -> AABB:
	var boite := AABB()
	var premier := true
	for mesh in visuel.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
		var limites: AABB = mesh.get_aabb()
		if mesh.get_skin_reference() != null:
			# La boîte brute ignore la pose et l'échelle des os de certains imports.
			var pose: ArrayMesh = mesh.bake_mesh_from_current_skeleton_pose()
			if pose != null: limites = pose.get_aabb()
		limites = (visuel.global_transform.affine_inverse() * mesh.global_transform) * limites
		boite = limites if premier else boite.merge(limites)
		premier = false
	return boite
