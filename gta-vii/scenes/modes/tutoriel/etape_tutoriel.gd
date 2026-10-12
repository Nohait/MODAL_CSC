extends Resource

enum Objectif { CONVERSATION, FOYERS, RESERVE, DASH, ENTREE }

@export var titre := ""
@export_multiline var consigne := ""
@export var repliques: PackedStringArray = []
@export var objectif: Objectif = Objectif.CONVERSATION
