@tool
extends Resource
class_name IncendieSalle

@export_range(1.0, 3.0, 0.1) var ampleur := 2.0
@export_range(0.0, 1.0, 0.05) var chance_couvant := 0.08
@export_range(1.0, 2.0, 0.05) var intensite_lumiere := 1.25
@export_range(1.0, 8.0, 0.5) var portee_lumiere := 4.5
@export_range(0.0, 1.0, 0.05) var fumee := 0.6
@export_range(1.0, 5.0, 0.25) var duree_braises := 3.0
@export_range(0, 2) var langues_secondaires := 2
@export_range(0.2, 0.8, 0.05) var etalement := 0.4
@export_range(6, 20) var particules_par_langue := 10

func appliquer(foyer: Node3D, couvant: bool = false) -> void:
	if foyer.has_meta("incendie_renforce"): return
	foyer.set_meta("incendie_renforce", true)
	foyer.taille = clampf(foyer.taille * ampleur, 0.2, 2.0)
	foyer.energie *= intensite_lumiere
	foyer.portee_lumiere = portee_lumiere
	foyer.densite_fumee = fumee
	var flammes: CPUParticles3D = foyer.get_node("Flammes")
	flammes.scale_amount_min = 0.85
	flammes.scale_amount_max = 1.5
	var braises: CPUParticles3D = foyer.get_node("Braises")
	braises.lifetime = duree_braises
	braises.initial_velocity_max = 1.3
	braises.spread = 35.0
	var panache: CPUParticles3D = foyer.get_node("Fumee")
	panache.initial_velocity_min = 0.45
	panache.initial_velocity_max = 0.75
	if couvant: return
	# Réutiliser les flammes donne plusieurs points de combustion sans ajouter de lumière ni de son.
	for i in range(langues_secondaires):
		var langue: CPUParticles3D = flammes.duplicate()
		langue.name = "LangueSecondaire%d" % i
		langue.amount = particules_par_langue
		langue.scale = Vector3.ONE * foyer.taille * 0.8
		langue.position = Vector3((-1.0 if i == 0 else 1.0) * etalement * foyer.taille, 0.05, 0.1)
		langue.initial_velocity_min = 0.3
		langue.initial_velocity_max = 0.65
		# Des durées différentes évitent que les langues donnent l'impression d'être copiées.
		langue.lifetime = 1.1 + i * 0.2
		foyer.add_child(langue)
