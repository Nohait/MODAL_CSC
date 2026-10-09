@tool
extends Resource
class_name NiveauIncendie

@export var titre := "Incendie actif"
@export_range(0.0, 10.0, 0.1) var poids := 1.0
@export_range(0.3, 1.5, 0.05) var ampleur := 1.0
@export_range(0.3, 1.5, 0.05) var lumiere := 1.0
@export_range(0.0, 1.5, 0.05) var fumee := 1.0
@export_range(0.0, 1.0, 0.05) var chance_couvant := 0.08
@export_range(0, 4) var foyers_supplementaires := 2
@export_range(0, 100) var braises := 56
@export_range(0.0, 2.0, 0.05) var force_vent := 0.8
@export_range(0.0, 1.5, 0.05) var force_rafales := 0.5
@export_range(0, 5) var foyers_annexes := 3
@export var couleur_ambiante := Color(1, 0.65, 0.53)
@export var couleur_soleil := Color(1, 0.85, 0.75)

func adapter(identite: IdentiteSalle) -> IdentiteSalle:
	var copie: IdentiteSalle = identite.duplicate()
	if identite.incendie == null: return copie
	# L'identité choisit le style ; ce niveau en règle l'intensité, sans modifier le profil partagé.
	copie.incendie = identite.incendie.duplicate()
	copie.incendie.ampleur *= ampleur
	copie.incendie.intensite_lumiere *= lumiere
	copie.incendie.fumee = clampf(copie.incendie.fumee * fumee, 0, 1)
	copie.incendie.chance_couvant = chance_couvant
	return copie
