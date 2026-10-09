extends Node3D

@export_node_path("Node") var gestionnaire := NodePath("../Salles/RoomManager")
@export_node_path("WorldEnvironment") var ambiance := NodePath("Ambiance")
@export_node_path("DirectionalLight3D") var soleil := NodePath("Soleil")

var environnement: Environment
var lumiere: DirectionalLight3D
var couleur_ambiante_initiale: Color
var couleur_soleil_initiale: Color

func _ready() -> void:
	var monde := get_node_or_null(ambiance) as WorldEnvironment
	lumiere = get_node_or_null(soleil) as DirectionalLight3D
	if monde == null or lumiere == null: return
	# Copier l'environnement protège les autres scènes qui utiliseraient la même ressource.
	monde.environment = monde.environment.duplicate()
	environnement = monde.environment
	couleur_ambiante_initiale = environnement.ambient_light_color
	couleur_soleil_initiale = lumiere.light_color
	var salles := get_node_or_null(gestionnaire)
	if salles != null: salles.salle_preparee.connect(actualiser)

func actualiser(salle: Node3D) -> void:
	if environnement == null: return
	var niveau: NiveauIncendie = salle.get_meta("ambiance_incendie", null)
	# Le signal arrive avant l'entrée du joueur : la nouvelle teinte est prête pendant le fondu.
	environnement.ambient_light_color = niveau.couleur_ambiante if niveau != null else couleur_ambiante_initiale
	lumiere.light_color = niveau.couleur_soleil if niveau != null else couleur_soleil_initiale
