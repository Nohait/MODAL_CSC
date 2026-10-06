extends Node3D

@export_range(0.3, 2.0, 0.05) var periode := 0.8
@export_range(0.1, 0.9, 0.05) var proportion_allumee := 0.45
@export_range(0.0, 3.0, 0.1) var energie := 0.6
@export_range(0.5, 6.0, 0.1) var portee := 2.8
@export_range(0.0, 8.0, 0.1) var emission_phares := 3.0
var temps := 0.0
var allumes := false
var materiaux: Array[StandardMaterial3D] = []
var lumieres: Array[OmniLight3D] = []

func _ready() -> void:
	# Le parent instancie la voiture dans son _ready, après celui de ses enfants.
	_preparer_feux.call_deferred()

func _preparer_feux() -> void:
	var positions: Dictionary = {}
	var nombres: Dictionary = {}
	for morceau: MeshInstance3D in get_parent().find_children("*", "MeshInstance3D", true, false):
		for surface in morceau.mesh.get_surface_count():
			var original := morceau.mesh.surface_get_material(surface) as StandardMaterial3D
			if original == null: continue
			# Utiliser les réflecteurs des phares avant et les verres des feux arrière.
			if original.resource_name not in ["Headlight_Metal", "Glass_-_Red", "Glass_-_Red_-_Rough"]: continue
			var mat := original.duplicate() as StandardMaterial3D
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.28, 0.025)
			mat.emission_energy_multiplier = 0.0
			morceau.set_surface_override_material(surface, mat)
			materiaux.append(mat)
			var centre := to_local(morceau.to_global(morceau.get_aabb().get_center()))
			var cle := Vector2(signf(centre.x), signf(centre.z))
			positions[cle] = positions.get(cle, Vector3.ZERO) + centre
			nombres[cle] = nombres.get(cle, 0) + 1
	# Une lumière par groupe de phares, placée dans la géométrie existante.
	for cle in positions:
		var lumiere := OmniLight3D.new()
		lumiere.position = positions[cle] / nombres[cle]
		lumiere.light_color = Color(1.0, 0.32, 0.035)
		lumiere.omni_range = portee
		add_child(lumiere)
		lumieres.append(lumiere)
	_regler(allumes)

func _process(delta: float) -> void:
	temps = fmod(temps + delta, periode)
	var nouvel_etat := temps < periode * proportion_allumee
	if nouvel_etat != allumes: _regler(nouvel_etat)

func _regler(valeur: bool) -> void:
	allumes = valeur
	for mat in materiaux: mat.emission_energy_multiplier = emission_phares if valeur else 0.0
	for lumiere in lumieres: lumiere.light_energy = energie if valeur else 0.0
