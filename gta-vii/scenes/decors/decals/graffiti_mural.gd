@tool
extends MeshInstance3D

@export var texture: Texture2D:
	set(valeur):
		texture = valeur
		_actualiser.call_deferred()
@export var taille := Vector2(3, 3):
	set(valeur):
		taille = valeur
		_actualiser.call_deferred()
@export var teinte := Color(1, 1, 1, 0.85):
	set(valeur):
		teinte = valeur
		_actualiser.call_deferred()
@export_range(0, 10) var ordre := 0:
	set(valeur):
		ordre = valeur
		_actualiser.call_deferred()

func _ready() -> void:
	_actualiser()

func _actualiser() -> void:
	if not is_inside_tree(): return
	# Le plan reste dans le même repère qu'un decal : X/Z pour le dessin, Y pour sa normale.
	var surface := PlaneMesh.new()
	surface.size = taille
	mesh = surface
	var peinture := StandardMaterial3D.new()
	peinture.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	peinture.albedo_texture = texture
	peinture.albedo_color = teinte
	peinture.roughness = 1.0
	peinture.metallic_specular = 0.0
	peinture.render_priority = ordre
	material_override = peinture
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
