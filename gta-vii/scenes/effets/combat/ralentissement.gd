extends Node

var restant := 0.0
var multiplicateur := 1.0
var overlays: Dictionary = {}
var teinte: ShaderMaterial



func _ready() -> void:
	teinte = ShaderMaterial.new()
	teinte.shader = preload("res://scenes/effets/combat/teinte_givree.gdshader")
	# Les mobiles partagent le ralentissement, mais pas la hiérarchie de leur modèle.
	# Limiter la teinte au corps pour préserver les indicateurs et effets de combat.
	for chemin in ["sbire", "hound", "Sketchfab_Scene"]:
		var modele := get_parent().get_node_or_null(chemin)
		if modele == null: continue
		var meshes := modele.find_children("*", "MeshInstance3D", true, false)
		if modele is MeshInstance3D: meshes.append(modele)
		for mesh in meshes:
			if mesh.mesh == null: continue
			overlays[mesh] = mesh.material_overlay
			mesh.material_overlay = teinte

func appliquer(pourcentage: float, duree: float) -> void:
	multiplicateur = 1.0 - clampf(pourcentage, 0.0, 80.0) / 100.0
	restant = maxf(restant, duree)

func _physics_process(delta: float) -> void:
	restant -= delta
	if restant > 0.0: return
	# Rendre les matériaux initiaux ; les autres ennemis gardent leurs propres matériaux.
	multiplicateur = 1.0
	for mesh in overlays:
		if not is_instance_valid(mesh): continue
		if mesh.material_overlay != teinte: continue
		# Une mutation peut avoir été ajoutée ou retirée pendant le gel.
		var elite = get_parent().get_node_or_null("Elite")
		var precedent: Material = overlays[mesh]
		if elite != null and elite.overlays.has(mesh):
			mesh.material_overlay = elite.teinte
		elif precedent is ShaderMaterial and precedent.shader != null and precedent.shader.resource_path.ends_with("habillage_elite.gdshader"):
			mesh.material_overlay = null
		else:
			mesh.material_overlay = precedent
	queue_free()
