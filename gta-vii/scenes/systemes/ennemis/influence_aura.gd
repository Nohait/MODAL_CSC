extends MeshInstance3D

const PLACEMENT_ZONE_SOL = preload("res://scenes/systemes/ennemis/placement_zone_sol.gd")

func _ready() -> void:
	var forme := PlaneMesh.new()
	forme.size = Vector2(0.8, 0.8)
	mesh = forme
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/systemes/ennemis/sceau_elite.gdshader")
	mat.set_shader_parameter("puissance", 0.45)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position.y = PLACEMENT_ZONE_SOL.hauteur_locale(get_parent(), 0.04, -0.66)

func actualiser(vitesse: float, degats: float, resistance: float) -> void:
	# Ce sceau indique un bonus reçu, il ne crée pas une nouvelle mutation.
	visible = vitesse > 1.0 or degats > 1.0 or resistance > 0.0
	var couleur := Color("26ffa6") if vitesse > 1.0 else (Color("ffd940") if degats > 1.0 else Color("a659ff"))
	material_override.set_shader_parameter("teinte", couleur)
