extends Node3D

## Intensité lumineuse de l'œil au repos puis à la fin du chargement.
@export var emission_repos := 0.15
@export var emission_charge := 0.9
## Lumière réelle sur le décor, indépendante de l'émission du matériau.
@export var lumiere_repos := 0.7
@export var lumiere_charge := 2.0

@onready var tourelle = get_parent()
@onready var pivot: Node3D = $OeilPivot
@onready var pupille: MeshInstance3D = $OeilPivot/Pupille
@onready var lumiere: OmniLight3D = $OeilPivot/LumiereOeil
var materiau_oeil: StandardMaterial3D


func _ready() -> void:
	# Un matériau par tourelle : charger un œil ne doit pas éclairer tous les autres.
	# Orange cuivré peu émissif : conserver le relief du modèle sans motif rayé.
	materiau_oeil = StandardMaterial3D.new()
	materiau_oeil.albedo_color = Color(0.5, 0.14, 0.025)
	materiau_oeil.roughness = 0.8
	materiau_oeil.emission_enabled = true
	materiau_oeil.emission = Color(1.0, 0.2, 0.015)
	materiau_oeil.emission_energy_multiplier = emission_repos
	# Le GLB contient son propre arbre ; appliquer le matériau aux maillages importés.
	var modele := $OeilPivot/Oeil
	if modele is MeshInstance3D:
		modele.material_override = materiau_oeil
	for maillage in modele.find_children("*", "MeshInstance3D", true, false):
		maillage.material_override = materiau_oeil


func actualiser() -> void:
	if is_instance_valid(tourelle.cible):
		# Tourner seulement l'œil horizontalement ; la tour et sa collision restent fixes.
		var direction: Vector3 = tourelle.cible.global_position - pivot.global_position
		direction.y = 0.0
		if direction.length_squared() > 0.001:
			pivot.look_at(pivot.global_position + direction, Vector3.UP)
	var progression := clampf(tourelle.chargement_ecoule / tourelle.duree_chargement, 0.0, 1.0)
	# Lire le chargement existant : aucun second minuteur ne peut se désynchroniser.
	materiau_oeil.emission_energy_multiplier = lerpf(emission_repos, emission_charge, progression)
	lumiere.light_energy = lerpf(lumiere_repos, lumiere_charge, progression)
	pupille.scale.x = lerpf(0.075, 0.034, progression)
