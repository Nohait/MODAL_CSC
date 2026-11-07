extends Node

@export var morceaux: Array[MorceauMusicalZombie] = []
@export_range(0.1, 5.0, 0.1) var duree_fondu := 1.5
@export_range(0.1, 2.0, 0.1) var intervalle_evaluation := 0.3
@export_range(0.1, 2.0, 0.1) var fondu_introduction := 0.4
var ordre: Array[MorceauMusicalZombie] = []
var courant: Dictionary = {}
var sortant: Dictionary = {}
var indice_morceau := 0
var introduction := false
var attente := 0.0
var generateur := RandomNumberGenerator.new()
var accalmie_restante := 0.0
var volume_accalmie := 0.0

func accalmie(duree: float, volume: float) -> void:
	accalmie_restante = maxf(accalmie_restante, duree)
	volume_accalmie = minf(0.0, volume)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	generateur.randomize()
	# Cette playlist ne consomme pas le hasard utilisé pour générer les vagues.
	morceaux = morceaux.filter(_morceau_valide)
	_melanger_playlist()

func _process(delta: float) -> void:
	if not get_tree().paused:
		accalmie_restante = maxf(0.0, accalmie_restante - delta)
	if morceaux.is_empty(): return
	var contexte := _contexte_musical()
	var combat: bool = introduction or contexte.get("combat", false)
	if combat and courant.is_empty(): _suivant()
	if courant.is_empty(): return
	var lecteur: AudioStreamPlayer = courant.lecteur
	var duree := fondu_introduction if introduction else duree_fondu
	var cible_volume := volume_accalmie if accalmie_restante > 0.0 else 0.0
	lecteur.volume_db = move_toward(lecteur.volume_db, cible_volume if combat else -60.0, 60.0 * delta / duree)
	if combat and lecteur.stream_paused:
		# Reprendre tous les instruments ensemble, à leur position conservée.
		lecteur.stream_paused = false
	elif not combat and lecteur.volume_db <= -60.0:
		lecteur.stream_paused = true
	if not sortant.is_empty():
		var ancien: AudioStreamPlayer = sortant.lecteur
		ancien.volume_db = move_toward(ancien.volume_db, -60.0, 60.0 * delta / duree_fondu)
		if ancien.volume_db <= -60.0:
			ancien.queue_free()
			sortant = {}
	if not combat: return
	if contexte.get("combat", false): introduction = false
	attente -= delta
	if attente <= 0.0:
		attente = intervalle_evaluation
		_evaluer_couches()
	var mixage: AudioStreamSynchronized = courant.mixage
	for i in courant.couches.size():
		mixage.set_sync_stream_volume(i, move_toward(mixage.get_sync_stream_volume(i), courant.cibles[i], 60.0 * delta / duree_fondu))
	# Anticiper la fin pour laisser le fondu se produire avant le silence.
	if lecteur.get_playback_position() >= courant.duree - duree_fondu:
		_suivant()

func commencer_introduction() -> void:
	introduction = true
	if courant.is_empty() and not morceaux.is_empty(): _suivant()
	if not courant.is_empty(): _evaluer_couches()

func _melanger_playlist() -> void:
	ordre.assign(morceaux)
	indice_morceau = 0
	# Un seul mélange par partie ; les cycles suivants conservent cet ordre.
	for i in range(ordre.size() - 1, 0, -1):
		var j := generateur.randi_range(0, i)
		var temporaire := ordre[i]
		ordre[i] = ordre[j]
		ordre[j] = temporaire

func _tirer_morceau() -> MorceauMusicalZombie:
	var morceau := ordre[indice_morceau]
	indice_morceau = (indice_morceau + 1) % ordre.size()
	return morceau

func _suivant() -> void:
	if not sortant.is_empty(): sortant.lecteur.queue_free()
	sortant = courant
	var morceau := _tirer_morceau()
	var mixage := AudioStreamSynchronized.new()
	var couches: Array[CoucheMusicaleZombie] = []
	for couche in morceau.couches:
		if couche != null and couche.piste != null: couches.append(couche)
	# AudioStreamSynchronized accepte au maximum 32 pistes simultanées.
	if couches.size() > 32: couches.resize(32)
	mixage.stream_count = mini(32, couches.size())
	var longueur := 0.0
	var cibles: Array[float] = []
	for i in mixage.stream_count:
		var piste := couches[i].piste.duplicate()
		# Les fichiers ne bouclent pas : leur fin déclenche le morceau suivant.
		if piste is AudioStreamWAV: piste.loop_mode = AudioStreamWAV.LOOP_DISABLED
		elif piste is AudioStreamMP3 or piste is AudioStreamOggVorbis: piste.loop = false
		mixage.set_sync_stream(i, piste)
		mixage.set_sync_stream_volume(i, -60.0)
		longueur = maxf(longueur, piste.get_length())
		cibles.append(-60.0)
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = mixage
	lecteur.bus = "Musique"
	lecteur.volume_db = -60.0
	add_child(lecteur)
	courant = {"lecteur": lecteur, "mixage": mixage, "couches": couches, "cibles": cibles, "duree": morceau.duree if morceau.duree > 0.0 else longueur, "morceau": morceau}
	_evaluer_couches()
	# Les couches de base sont prêtes dès le début du fondu principal.
	for i in mixage.stream_count: mixage.set_sync_stream_volume(i, cibles[i])
	# Le même décalage est appliqué au mixage entier, jamais à une piste seule.
	lecteur.play(clampf(morceau.debut_lecture, 0.0, maxf(0.0, longueur - duree_fondu)))

func _evaluer_couches() -> void:
	var contexte := _contexte_musical()
	var salle: Node = contexte.get("salle")
	var ennemis := 0
	var elite := false
	var boss := false
	if is_instance_valid(salle):
		for ennemi in salle.get_node("Ennemis").get_children():
			if ennemi.is_in_group("flaque") or not ennemi.is_in_group("enemies") or ennemi.get("est_mort") == true or ennemi.is_queued_for_deletion(): continue
			ennemis += 1
			elite = elite or ennemi.has_node("Elite")
			boss = boss or ennemi.scene_file_path.contains("mini_boss")
	ennemis = maxi(ennemis, int(contexte.get("intensite_minimale", 0)))
	for i in courant.couches.size():
		var couche: CoucheMusicaleZombie = courant.couches[i]
		var active: bool = ennemis >= couche.ennemis_minimum and int(contexte.get("palier", 1)) >= couche.vague_minimum
		if introduction: active = couche.ennemis_minimum == 0 and couche.vague_minimum <= 1
		active = active or (couche.activer_si_elite and elite) or (couche.activer_si_boss and boss)
		active = active and (not couche.exige_elite or elite) and (not couche.exige_boss or boss)
		if not couche.evenements.is_empty():
			active = active and StringName(contexte.get("evenement", "")) in couche.evenements
		courant.cibles[i] = couche.volume_db if active else -60.0

func _contexte_musical() -> Dictionary:
	return {}

func _morceau_valide(morceau: MorceauMusicalZombie) -> bool:
	if morceau == null: return false
	for couche in morceau.couches:
		if couche != null and couche.piste != null: return true
	return false
