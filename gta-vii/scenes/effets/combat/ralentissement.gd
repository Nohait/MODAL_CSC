extends Node

var restant := 0.0
var multiplicateur := 1.0
var overlays: Dictionary = {}
var teinte: ShaderMaterial

func _ready() -> void:
	teinte = ShaderMaterial.new()
	teinte.shader = preload("res://scenes/effets/combat/teinte_givree.gdshader")
	for mesh in get_parent().get_node("Sketchfab_Scene").find_children("*", "MeshInstance3D", true, false):
		overlays[mesh] = mesh.material_overlay
		mesh.material_overlay = teinte

func appliquer(pourcentage: float, duree: float) -> void:
	multiplicateur = 1.0 - clampf(pourcentage, 0.0, 80.0) / 100.0
	restant = maxf(restant, duree)

func _physics_process(delta: float) -> void:
	restant -= delta
	if restant > 0.0: return
	# Rendre les matériaux initiaux ; les autres sbires gardent leurs propres matériaux.
	multiplicateur = 1.0
	for mesh in overlays:
		if is_instance_valid(mesh): mesh.material_overlay = overlays[mesh]
	queue_free()
