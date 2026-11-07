extends SceneTree

const CLASSIQUE = preload("res://scenes/systemes/audio/musique_classique.tscn")
const ZOMBIE = preload("res://scenes/modes/zombie/audio/couches_dynamiques.gd")
const TUTORIEL = preload("res://scenes/modes/tutoriel/commun/musique_tutoriel.gd")
const ASSAULT = preload("res://scenes/modes/zombie/audio/morceaux/assault.tres")

class NiveauTest extends Node3D:
	var session_tutoriel := false

class GestionTest extends Node:
	var initialized := true
	var transition_en_cours := false
	var salle_actuelle: Node3D
	var vague_actuelle := 1
	var phase := "combat"
	var composition_actuelle: Resource

class SalleTest extends Node3D:
	var etage := 1
	var liberee := false

class JoueurTest extends Node3D:
	var est_mort := false

class AmeliorationsTest extends Node:
	var mode_jeu := "classique"

class EnnemiTest extends Node3D:
	var est_mort := false

func _initialize() -> void:
	verifier.call_deferred()

func _niveau() -> Node3D:
	var niveau := NiveauTest.new()
	var salles := Node3D.new()
	salles.name = "Salles"
	niveau.add_child(salles)
	var gestion := GestionTest.new()
	gestion.name = "RoomManager"
	salles.add_child(gestion)
	var salle := SalleTest.new()
	salles.add_child(salle)
	gestion.salle_actuelle = salle
	var ennemis := Node3D.new()
	ennemis.name = "Ennemis"
	salle.add_child(ennemis)
	var joueur := JoueurTest.new()
	joueur.name = "player"
	niveau.add_child(joueur)
	var ameliorations := AmeliorationsTest.new()
	ameliorations.name = "UpgradeManager"
	niveau.add_child(ameliorations)
	return niveau

func verifier() -> void:
	create_timer(25.0).timeout.connect(func():
		push_error("Délai dépassé pour la musique adaptative.")
		quit(1))
	var niveau := _niveau()
	var musique = CLASSIQUE.instantiate()
	niveau.add_child(musique)
	root.add_child(niveau)
	current_scene = niveau
	musique.set_process(false)
	assert(musique.ordre.size() == 4)
	var ordre_initial: Array = musique.ordre.duplicate()
	for cycle in 3:
		for morceau in ordre_initial:
			assert(musique._tirer_morceau() == morceau)
	assert(musique.ordre == ordre_initial)
	for morceau in ordre_initial:
		assert(morceau.couches[0].ennemis_minimum == 0)
		assert(morceau.couches[0].vague_minimum == 1)
	print("MUSIQUE_ORDRE_CYCLIQUE_OK")
	musique.ordre.assign([ASSAULT])
	musique.indice_morceau = 0
	musique._process(2.0)
	var gestion = niveau.get_node("Salles/RoomManager")
	var salle = gestion.salle_actuelle
	assert(musique.courant.cibles == [-10.0, -60.0, -60.0, -60.0])
	salle.etage = 2
	musique._evaluer_couches()
	assert(musique.courant.cibles == [-10.0, -10.0, -60.0, -60.0])
	salle.etage = 3
	musique._evaluer_couches()
	assert(musique.courant.cibles == [-10.0, -10.0, -10.0, -10.0])
	salle.etage = 1
	var ennemis: Node = salle.get_node("Ennemis")
	for i in 7:
		var ennemi := EnnemiTest.new()
		ennemi.add_to_group("enemies")
		ennemis.add_child(ennemi)
	musique._evaluer_couches()
	assert(musique.courant.cibles[2] == -10.0)
	for ennemi in ennemis.get_children(): ennemi.add_to_group("flaque")
	musique._evaluer_couches()
	assert(musique.courant.cibles[2] == -60.0)
	var elite := ennemis.get_child(0)
	elite.remove_from_group("flaque")
	var mutation := Node.new()
	mutation.name = "Elite"
	elite.add_child(mutation)
	musique._evaluer_couches()
	assert(musique.courant.cibles[3] == -10.0)
	print("MUSIQUE_ETAGES_DANGER_OK")
	var lecteur: AudioStreamPlayer = musique.courant.lecteur
	assert(lecteur.bus == &"Musique")
	await create_timer(0.1).timeout
	salle.liberee = true
	paused = true
	musique._process(0.1)
	assert(lecteur.volume_db < 0.0 and lecteur.volume_db > -60.0)
	musique._process(2.0)
	assert(lecteur.stream_paused and musique.boutique.playing)
	var position := lecteur.get_playback_position()
	await create_timer(0.1).timeout
	assert(is_equal_approx(position, lecteur.get_playback_position()))
	salle.liberee = false
	paused = false
	musique._process(2.0)
	assert(musique.courant.lecteur == lecteur and not lecteur.stream_paused)
	assert(musique.boutique.stream_paused)
	# Une fin de morceau crée un second lecteur, sans couper le précédent.
	musique.courant.duree = 0.01
	musique._process(0.01)
	assert(musique.sortant.lecteur == lecteur)
	musique._process(2.0)
	assert(musique.sortant.is_empty())
	print("MUSIQUE_FONDUS_REPRISE_OK")
	_arreter_audio(niveau)
	niveau.queue_free()
	await process_frame
	niveau = _niveau()
	niveau.get_node("UpgradeManager").mode_jeu = "zombie"
	var classique_inactif = CLASSIQUE.instantiate()
	niveau.add_child(classique_inactif)
	var zombie = ZOMBIE.new()
	zombie.morceaux.assign([ASSAULT])
	niveau.add_child(zombie)
	root.add_child(niveau)
	current_scene = niveau
	zombie.set_process(false)
	assert(not classique_inactif.is_processing())
	zombie._process(2.0)
	assert(zombie.courant.cibles[0] == -10.0)
	niveau.get_node("Salles/RoomManager").phase = "boutique"
	zombie._process(2.0)
	assert(zombie.courant.lecteur.stream_paused)
	print("MUSIQUE_ZOMBIE_PARTAGE_OK")
	_arreter_audio(niveau)
	niveau.queue_free()
	await process_frame
	niveau = _niveau()
	niveau.session_tutoriel = true
	niveau.add_child(CLASSIQUE.instantiate())
	root.add_child(niveau)
	current_scene = niveau
	await process_frame
	await process_frame
	var percussions: AudioStreamPlayer = root.get_node("MusiqueTutoriel")
	assert(percussions.playing and percussions.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	assert(percussions.stream.loop_end > 0 and percussions.bus == &"Musique")
	var suite := _niveau()
	suite.session_tutoriel = true
	suite.add_child(CLASSIQUE.instantiate())
	root.add_child(suite)
	current_scene = suite
	niveau.queue_free()
	paused = true
	await process_frame
	assert(root.get_node("MusiqueTutoriel") == percussions and percussions.playing)
	paused = false
	var titre := Node.new()
	root.add_child(titre)
	current_scene = titre
	suite.queue_free()
	await process_frame
	await process_frame
	assert(not root.has_node("MusiqueTutoriel"))
	titre.queue_free()
	print("MUSIQUE_TUTORIEL_CONTINU_OK")
	await create_timer(0.1).timeout
	print("MUSIQUE_ADAPTATIVE_OK")
	quit(0)

func _arreter_audio(noeud: Node) -> void:
	if noeud is AudioStreamPlayer:
		noeud.stop()
		noeud.stream = null
	for enfant in noeud.get_children(): _arreter_audio(enfant)
