extends Node

@export var couches: Array[CoucheMusicaleZombie] = []
@export_range(0.1, 5.0, 0.1) var duree_fondu := 1.5
@export_range(0.1, 2.0, 0.1) var intervalle_evaluation := 0.3
@onready var vagues = get_node("../Salles/RoomManager")
var lecteur: AudioStreamPlayer
var mixage: AudioStreamSynchronized
var attente := 0.0
var initialise := false
var volumes_cibles: Array[float] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var utilisables: Array[CoucheMusicaleZombie] = []
	for couche in couches:
		if couche != null and couche.piste != null: utilisables.append(couche)
	couches = utilisables
	mixage = AudioStreamSynchronized.new()
	mixage.stream_count = mini(32, couches.size())
	for i in mixage.stream_count:
		var piste := couches[i].piste
		if piste == null: continue
		# Une copie locale évite de modifier la boucle d'une Resource partagée.
		piste = piste.duplicate()
		if piste is AudioStreamWAV:
			piste.loop_mode = AudioStreamWAV.LOOP_FORWARD
			piste.loop_begin = 0
			piste.loop_end = roundi(piste.get_length() * piste.mix_rate)
		elif piste is AudioStreamOggVorbis or piste is AudioStreamMP3: piste.loop = true
		mixage.set_sync_stream(i, piste)
		mixage.set_sync_stream_volume(i, -60.0)
		volumes_cibles.append(-60.0)
	lecteur = AudioStreamPlayer.new()
	lecteur.stream = mixage
	lecteur.bus = "Musique"
	add_child(lecteur)

func _process(delta: float) -> void:
	if couches.is_empty() or vagues.vague_actuelle == 0: return
	if not initialise:
		initialise = true
		# Tous les stems commencent ensemble et continuent, même inaudibles.
		# Il faut des fichiers de même durée, déjà préparés pour boucler.
		lecteur.play()
	# Lisser à chaque image, même entre deux évaluations du danger.
	for i in mixage.stream_count:
		mixage.set_sync_stream_volume(i, move_toward(mixage.get_sync_stream_volume(i), volumes_cibles[i], 60.0 * delta / duree_fondu))
	attente -= delta
	if attente > 0.0: return
	attente = intervalle_evaluation
	var ennemis := 0
	var elite := false
	var boss := false
	if is_instance_valid(vagues.salle_actuelle):
		for ennemi in vagues.salle_actuelle.get_node("Ennemis").get_children():
			if not ennemi.is_in_group("enemies"): continue
			if ennemi.get("est_mort") == true or ennemi.is_queued_for_deletion(): continue
			ennemis += 1
			elite = elite or ennemi.has_node("Elite")
			boss = boss or ennemi.scene_file_path.contains("mini_boss")
	for i in mixage.stream_count:
		var couche := couches[i]
		var seuil_atteint: bool = ennemis >= couche.ennemis_minimum and vagues.vague_actuelle >= couche.vague_minimum
		seuil_atteint = seuil_atteint or (couche.activer_si_elite and elite) or (couche.activer_si_boss and boss)
		var active: bool = vagues.phase == "combat" and seuil_atteint
		active = active and (not couche.exige_elite or elite) and (not couche.exige_boss or boss)
		if not couche.evenements.is_empty(): active = active and StringName(vagues.composition_actuelle.evenement) in couche.evenements
		volumes_cibles[i] = couche.volume_db if active else -60.0
