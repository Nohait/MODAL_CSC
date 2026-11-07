extends AudioStreamPlayer

@export var percussion: AudioStreamWAV = preload("res://assets/sounds/musique/zombie/assault/MUS_Combat_Incoming_Loop_Percussion_100BPM.wav")
@export_range(-40.0, 0.0, 1.0) var volume_percussions_db := -10.0

static func installer(arbre: SceneTree) -> void:
	if arbre.root.has_node("MusiqueTutoriel"): return
	var musique = load("res://scenes/modes/tutoriel/commun/musique_tutoriel.gd").new()
	musique.name = "MusiqueTutoriel"
	# Le lecteur survit aux salles de formation pour ne pas recommencer à chaque porte.
	arbre.root.add_child.call_deferred(musique)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus = "Musique"
	volume_db = volume_percussions_db
	var boucle := percussion.duplicate() as AudioStreamWAV
	boucle.loop_begin = 0
	boucle.loop_end = int(round(boucle.get_length() * boucle.mix_rate))
	boucle.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream = boucle
	play()

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or Reglages.chargement.en_cours: return
	if scene.get("session_tutoriel") == true: return
	stop()
	queue_free()
