extends RefCounted

static func creer(scene: PackedScene, parent: Node) -> Node3D:
	# Les _ready des ennemis mettent les GLB à la bonne échelle.
	# Préparer une instance inerte puis ne conserver que ses éléments visuels.
	var modele = scene.instantiate()
	modele.set_meta("apercu_glossaire", true)
	modele.process_mode = Node.PROCESS_MODE_DISABLED
	modele.hide()
	for noeud in [modele] + modele.find_children("*", "", true, false):
		for groupe in noeud.get_groups(): noeud.remove_from_group(groupe)
		if noeud is CollisionShape3D: noeud.disabled = true
	parent.add_child(modele)
	var visuel := Node3D.new()
	for nom in ["Sketchfab_Scene", "Visuel", "Flammes", "MeshInstance3D", "vfx_fire"]:
		var partie = modele.get_node_or_null(nom)
		if partie != null: visuel.add_child(partie.duplicate(0))
	if is_instance_valid(modele.get("cible_idle")): modele.cible_idle.free()
	modele.free()
	return visuel
