class_name DefinitionSucces
extends Resource

@export var identifiant := ""
@export var titre := ""
@export_multiline var description := ""
@export_enum("vague", "eliminations", "elites", "boss", "vagues_intactes", "synergies") var critere := "vague"
@export_range(1, 10000) var objectif := 10
@export var rarete := "RARE"
@export var couleur := Color("f5f5f0")

func fiche() -> Dictionary:
	return {"id": identifiant, "titre": titre, "description": description, "critere": critere,
		"objectif": objectif, "rarete": rarete, "couleur": couleur}
