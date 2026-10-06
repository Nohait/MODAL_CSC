extends MeshInstance3D

func _ready() -> void:
	var forme := PlaneMesh.new()
	forme.size = Vector2(0.8, 0.8)
	mesh = forme
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/systemes/ennemis/sceau_elite.gdshader")
	mat.set_shader_parameter("puissance", 0.45)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var collision = get_parent().get_node_or_null("CollisionShape3D")
	position.y = collision.position.y - collision.shape.height * 0.5 + 0.04 if collision != null and collision.shape is CapsuleShape3D else -0.66

func actualiser(vitesse: float, degats: float, resistance: float) -> void:
	# Ce sceau indique un bonus reçu, il ne crée pas une nouvelle mutation.
	visible = vitesse > 1.0 or degats > 1.0 or resistance > 0.0
	var couleur := Color("26ffa6") if vitesse > 1.0 else (Color("ffd940") if degats > 1.0 else Color("a659ff"))
	material_override.set_shader_parameter("teinte", couleur)
