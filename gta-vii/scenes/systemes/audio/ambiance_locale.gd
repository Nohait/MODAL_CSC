extends Node3D

signal passage_demarre
signal passage_termine

@export var profil: ProfilAmbiance
@export_enum("Local", "Global") var diffusion := 0
# Facultatif : par exemple le camion, créé après la map. Sinon, utiliser ce nœud.
@export_node_path("Node3D") var cible: NodePath
var coordonne := false
var lecteur: Node
var actif := true
var attente := 0.0
var dernier_son := -1
var passage_en_cours := false
var animation: Tween
var aleatoire := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("ambiances_locales")
	if profil == null:
		push_warning("Attribuer un profil à l'ambiance : " + str(get_path()))
		set_process(false)
		return
	# Le hasard sonore ne modifie pas les graines des combats ni les sauvegardes.
	aleatoire.randomize()
	lecteur = AudioStreamPlayer3D.new() if diffusion == 0 else AudioStreamPlayer.new()
	lecteur.bus = &"ResonanceParking" if profil.resonance else &"Ambiance"
	if diffusion == 0:
		lecteur.unit_size = profil.distance_reference
		lecteur.max_distance = profil.portee
	add_child(lecteur)
	lecteur.finished.connect(_terminer)
	_programmer()

func _process(delta: float) -> void:
	if not actif or lecteur == null or lecteur.playing or profil.sons.is_empty(): return
	# Le gestionnaire partage une horloge entre les sources d'un même profil ponctuel.
	if coordonne and not profil.boucle: return
	attente -= delta
	if attente > 0.0: return
	_jouer()

func _choisir(nombre: int, precedent: int) -> int:
	if nombre <= 1: return 0
	if precedent < 0: return aleatoire.randi_range(0, nombre - 1)
	# Écarter le dernier choix évite deux alarmes identiques sur la même voiture.
	var choix := aleatoire.randi_range(0, nombre - 2)
	return choix + 1 if choix >= precedent and precedent >= 0 else choix

func _jouer() -> void:
	if not actif or lecteur == null or profil.sons.is_empty(): return
	var source := self if cible.is_empty() else get_node_or_null(cible) as Node3D
	if diffusion == 0 and source == null: return
	dernier_son = _choisir(profil.sons.size(), dernier_son)
	if diffusion == 0:
		lecteur.global_position = source.global_position + Vector3.UP * profil.hauteur
	var son := profil.sons[dernier_son].duplicate() as AudioStream
	# Chaque lecteur possède sa boucle ; la ressource d'origine reste inchangée.
	if son is AudioStreamWAV:
		son.loop_mode = AudioStreamWAV.LOOP_FORWARD if profil.boucle else AudioStreamWAV.LOOP_DISABLED
		if profil.boucle:
			son.loop_begin = 0
			son.loop_end = roundi(son.get_length() * son.mix_rate)
	elif son is AudioStreamMP3 or son is AudioStreamOggVorbis:
		son.loop = profil.boucle
	lecteur.stream = son
	lecteur.pitch_scale = aleatoire.randf_range(profil.vitesse_min, profil.vitesse_max)
	lecteur.volume_db = -60.0
	passage_en_cours = true
	lecteur.play(aleatoire.randf_range(0.0, son.get_length() * 0.5) if profil.boucle else 0.0)
	if animation: animation.kill()
	animation = create_tween()
	var duree: float = son.get_length() / lecteur.pitch_scale
	var fondu := profil.fondu if profil.boucle else minf(profil.fondu, duree * 0.4)
	animation.tween_property(lecteur, "volume_db", profil.volume_db, fondu)
	if not profil.boucle:
		# La durée suit aussi le léger changement de vitesse du grincement.
		animation.tween_interval(maxf(0.0, duree - fondu * 2.0))
		animation.tween_property(lecteur, "volume_db", -60.0, fondu)
		animation.tween_callback(_terminer)
	passage_demarre.emit()

func suspendre(duree: float) -> void:
	actif = false
	if lecteur == null or not lecteur.playing: return
	if animation: animation.kill()
	# Seul le fondu continue brièvement pendant la pause de la boutique.
	lecteur.process_mode = Node.PROCESS_MODE_ALWAYS
	animation = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	animation.tween_property(lecteur, "volume_db", -60.0, duree)
	animation.tween_callback(_terminer)

func reprendre() -> void:
	actif = true

func _terminer() -> void:
	if animation: animation.kill()
	lecteur.stop()
	lecteur.process_mode = Node.PROCESS_MODE_INHERIT
	_programmer()
	if passage_en_cours:
		passage_en_cours = false
		passage_termine.emit()

func _programmer() -> void:
	# Un délai par catégorie, calculé après le passage, quel que soit le nombre de sources.
	attente = aleatoire.randf_range(minf(profil.attente_min, profil.attente_max), maxf(profil.attente_min, profil.attente_max))
