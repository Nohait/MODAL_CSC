extends Node3D

@export_range(0.2, 2.0, 0.05) var periode := 0.8
@export_range(0.0, 1.0, 0.05) var decalage := 0.0
@export_range(0.0, 8.0, 0.1) var intensite := 3.0
@export_range(2.0, 20.0, 0.5) var portee := 9.0
@export var couleur_gauche := Color(0.04, 0.2, 1.0)
@export var couleur_droite := Color(1.0, 0.025, 0.015)

var temps := 0.0
var ampoules: Array[MeshInstance3D] = []
var lumieres: Array[OmniLight3D] = []
var rampe: BaseMaterial3D

func _ready() -> void:
	# La voiture possède déjà une vraie rampe : éclairer aussi ses verres colorés.
	for mesh in get_parent().find_children("*fs_vector*", "MeshInstance3D", true, false):
		var mat = mesh.get_active_material(0)
		if mat is BaseMaterial3D:
			rampe = mat.duplicate()
			rampe.emission_enabled = true
			rampe.emission = Color.WHITE
			rampe.emission_texture = rampe.albedo_texture
			mesh.set_surface_override_material(0, rampe)
			break
	for indice in 2:
		var couleur := couleur_gauche if indice == 0 else couleur_droite
		var ampoule := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.09
		sphere.height = 0.12
		ampoule.mesh = sphere
		ampoule.position.x = -0.43 if indice == 0 else 0.43
		ampoule.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := StandardMaterial3D.new()
		mat.albedo_color = couleur
		mat.emission_enabled = true
		mat.emission = couleur
		ampoule.material_override = mat
		add_child(ampoule)
		ampoules.append(ampoule)
		var lumiere := OmniLight3D.new()
		lumiere.position = ampoule.position
		lumiere.light_color = couleur
		lumiere.omni_range = portee
		# Pas d'ombres supplémentaires pour ces petits éclats de lumière.
		add_child(lumiere)
		lumieres.append(lumiere)

func _process(delta: float) -> void:
	temps += delta
	var eclat := false
	for indice in 2:
		var phase := fposmod(temps / periode + decalage + indice * 0.5, 1.0)
		# Deux éclats par côté, suivis d'une pause avant l'autre côté.
		var allume := phase < 0.12 or (phase > 0.2 and phase < 0.32)
		eclat = eclat or allume
		lumieres[indice].light_energy = intensite if allume else 0.0
		ampoules[indice].material_override.emission_energy_multiplier = 5.0 if allume else 0.15
	if rampe != null:
		rampe.emission_energy_multiplier = 2.0 if eclat else 0.0
