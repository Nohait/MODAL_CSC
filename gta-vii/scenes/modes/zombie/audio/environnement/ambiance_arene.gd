extends Node

@export_range(5.0, 60.0, 1.0) var silence_entre_passages := 15.0
@export_range(0.1, 2.0, 0.1) var fondu_boutique := 0.6
@export_range(0.0, 0.5, 0.01) var resonance := 0.14
var sources: Array[Node3D] = []
var categories: Dictionary = {}
var silence_restant := 0.0
var aleatoire := RandomNumberGenerator.new()
@onready var gestionnaire = get_parent().get_node("Salles/RoomManager")
@onready var boutique = get_parent().get_node("UpgradeManager")

func _ready() -> void:
	aleatoire.randomize()
	_preparer_resonance()
	gestionnaire.partie_prete.connect(_installer)
	boutique.boutique_affichee.connect(_suspendre)
	boutique.boutique_fermee.connect(_reprendre)

func _installer() -> void:
	sources.clear()
	categories.clear()
	var salle: Node3D = gestionnaire.salle_actuelle
	# La map définit les sources. Aucune liste de maps ni de chemins dans le gestionnaire.
	for source in get_tree().get_nodes_in_group("ambiances_locales"):
		if not salle.is_ancestor_of(source) or source.profil == null: continue
		sources.append(source)
		source.coordonne = true
		if source.profil.boucle: continue
		var profil: ProfilAmbiance = source.profil
		if not categories.has(profil):
			categories[profil] = {"sources": [], "dernier": null, "attente": _delai(profil)}
		categories[profil].sources.append(source)
		source.passage_termine.connect(_terminer_passage.bind(profil))

func _process(delta: float) -> void:
	if boutique.boutique_ouverte or categories.is_empty(): return
	silence_restant = maxf(0.0, silence_restant - delta)
	var disponibles: Array[ProfilAmbiance] = []
	for profil in categories:
		categories[profil].attente -= delta
		if categories[profil].attente <= 0.0: disponibles.append(profil)
	if silence_restant > 0.0 or disponibles.is_empty(): return
	for source in sources:
		if not source.profil.boucle and source.lecteur.playing: return
	var profil: ProfilAmbiance = disponibles[aleatoire.randi_range(0, disponibles.size() - 1)]
	var categorie: Dictionary = categories[profil]
	var candidats: Array = categorie.sources.duplicate()
	# Trois voitures partagent le même délai : en ajouter ne multiplie pas les alarmes.
	if candidats.size() > 1: candidats.erase(categorie.dernier)
	var source = candidats[aleatoire.randi_range(0, candidats.size() - 1)]
	categorie.dernier = source
	source._jouer()
	if not source.lecteur.playing: categorie.attente = 5.0

func _delai(profil: ProfilAmbiance) -> float:
	return aleatoire.randf_range(minf(profil.attente_min, profil.attente_max), maxf(profil.attente_min, profil.attente_max))

func _terminer_passage(profil: ProfilAmbiance) -> void:
	categories[profil].attente = _delai(profil)
	silence_restant = silence_entre_passages

func _suspendre() -> void:
	for source in sources: source.suspendre(fondu_boutique)

func _reprendre() -> void:
	for source in sources: source.reprendre()

func _preparer_resonance() -> void:
	# Une réverbération légère pour le métal, sans modifier le bus général d'ambiance.
	var indice := AudioServer.get_bus_index(&"ResonanceParking")
	if indice < 0:
		AudioServer.add_bus()
		indice = AudioServer.bus_count - 1
		AudioServer.set_bus_name(indice, &"ResonanceParking")
		AudioServer.set_bus_send(indice, &"Ambiance")
		var echo := AudioEffectReverb.new()
		echo.room_size = 0.8
		echo.damping = 0.6
		AudioServer.add_bus_effect(indice, echo)
	AudioServer.get_bus_effect(indice, 0).wet = resonance
