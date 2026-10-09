extends Node3D

# Les sources enfants utilisent AmbianceLocale. Ce nœud espace leurs passages.
@export_range(0.0, 60.0, 1.0) var silence_entre_passages := 12.0
@export_range(0.1, 2.0, 0.1) var fondu_pause := 0.6
var sources: Array[Node3D] = []
var silence_restant := 0.0
var suspendu := false

func _ready() -> void:
	# Continuer uniquement la surveillance et les fondus lorsque la partie est en pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for source in get_children():
		if source.get_script() != preload("res://scenes/systemes/audio/ambiance_locale.gd"): continue
		source.coordonne = true
		sources.append(source)
		source.passage_termine.connect(_passage_termine)

func _process(delta: float) -> void:
	var doit_suspendre := not is_visible_in_tree() or get_tree().paused
	if doit_suspendre != suspendu:
		suspendu = doit_suspendre
		for source in sources:
			if suspendu: source.suspendre(fondu_pause)
			else: source.reprendre()
	if suspendu: return
	silence_restant = maxf(0.0, silence_restant - delta)
	for source in sources:
		if source.lecteur != null and source.lecteur.playing: return
	# L'horloge sonore se fige pendant la boutique et dans les salles inactives.
	for source in sources:
		source.avancer_attente(delta)
		if silence_restant <= 0.0 and source.attente <= 0.0:
			source._jouer()
			return

func _passage_termine() -> void:
	silence_restant = silence_entre_passages
