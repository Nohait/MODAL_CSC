extends Node3D

signal collegues_passes
signal porte_ouverte
signal premier_passe
signal loup_repere

const CHIEN = preload("res://scenes/ennemis/mobiles/chien_magma/chien_magma.tscn")
const RETOUR_COMBAT = preload("res://scenes/effets/combat/retour_combat.gd")

@export_range(2.0, 8.0, 0.1) var vitesse_collegues := 5.0
@export_range(0.2, 1.2, 0.05) var duree_bond := 0.65
@export_range(0.2, 1.5, 0.05) var hauteur_bond := 0.7
@export_range(0.2, 1.0, 0.05) var duree_jet := 0.6
@export_range(0.0, 1.0, 0.05) var decalage_collegues := 0.25
@export_range(0.2, 2.0, 0.1) var duree_disparition := 0.8
@export_range(0.0, 4.0, 0.1) var avance_dans_hall := 2.0
@export_range(0.5, 1.5, 0.05) var ecartement_collegues := 0.85
@export_range(0.5, 3.0, 0.1) var intervalle_collegues := 1.5
@export_range(0.2, 1.5, 0.05) var duree_ouverture := 0.65
@export_range(0.2, 1.5, 0.05) var duree_fermeture := 0.65
@export_range(6.0, 24.0, 0.5) var distance_surprise := 14.0
@export_range(3.0, 7.0, 0.1) var vitesse_arrivee := 5.0
@export_range(0.3, 1.5, 0.05) var duree_fermeture_grille := 0.75
@export_range(3.0, 10.0, 0.1) var vitesse_loup := 6.0
@export_range(2.5, 6.0, 0.1) var distance_bond := 4.5
@export_range(5.0, 10.0, 0.1) var distance_alerte := 7.0
@export_range(0.5, 3.0, 0.1) var distance_interposition := 2.0

var preparee := false
var joueur: CharacterBody3D
var collegues: Array[Node3D] = []
var passes := 0
var loup: Node3D
var modele_loup: Node3D
var porte: Node3D
var ouverture_terminee := false
var alerte_donnee := false
var positions_precedentes: Dictionary = {}
var animer_joueur := false

func preparer(personnage: CharacterBody3D) -> void:
	joueur = personnage
	preparee = true
	# Ce repère place le groupe dans la rue avant le fondu de chargement.
	var hauteur := _hauteur_joueur_au_sol()
	joueur.global_position = $DepartRue.global_position
	joueur.global_position.y = hauteur
	var grille = get_parent().get_node("Navigation/Decor/FondCouloir/Grille")
	# La grille est enroulée derrière le linteau, plutôt que suspendue dans le vide.
	grille.position.y = 1.45
	grille.scale.y = 0.03
	porte = get_parent().get_node("Navigation/Decor/EntreesEnnemis/PorteAppartements")
	for indice in 2:
		var collegue := Node3D.new()
		collegue.name = "Collegue%d" % (indice + 1)
		add_child(collegue)
		# Copier seulement le modèle, pas le joueur, son HUD ou son arme fonctionnelle.
		var modele = joueur.get_node("visual/pompier").duplicate()
		collegue.add_child(modele)
		modele.collision_layer = 0
		modele.collision_mask = 0
		# Garder l'extincteur visible, mais sans attaque ni traitement autonome.
		var arme = modele.get_node("visual/Armature/Skeleton3D/Right_Hand_Holder/extincteur0")
		arme.show()
		arme.process_mode = Node.PROCESS_MODE_DISABLED
		modele.get_node("visual/Armature/AnimationPlayer").stop()
		modele.get_node("visual/Armature/AnimationTree").active = true
		collegue.global_position = joueur.global_position + _position_collegue(indice)
		collegues.append(collegue)
		positions_precedentes[collegue] = collegue.global_position
	# Ce loup est un figurant : aucune IA, collision, monnaie ou inscription au glossaire.
	var original := CHIEN.instantiate()
	loup = Node3D.new()
	loup.name = "LoupIntroduction"
	add_child(loup)
	modele_loup = original.get_node("Sketchfab_Scene").duplicate()
	loup.add_child(modele_loup)
	original.free()
	loup.hide()

func jouer(arrivee: Vector3) -> void:
	# Avancer assez pour que le mur de l'entrée ne masque pas la réaction du joueur.
	arrivee -= global_basis.z.normalized() * avance_dans_hall
	# Conserver la hauteur réelle de la capsule, plutôt que les 1,1 m du point d'arrivée.
	arrivee.y = joueur.global_position.y
	joueur.set_physics_process(false)
	joueur.entree_automatique = false
	joueur.velocity = Vector3.ZERO
	# Réutiliser les animations du jeu : le regard peut différer du déplacement.
	joueur.get_node("visual/pompier/visual/Armature/AnimationPlayer").stop()
	joueur.anim_tree.active = true
	animer_joueur = true
	positions_precedentes[joueur] = joueur.global_position
	joueur.visual.rotation.y = deg_to_rad(-45.0)
	var marches: Array[Tween] = []
	_fermer_grille()
	# La course continue au-delà de l’embuscade : personne ne s’arrête pour attendre le loup.
	var fin_course := arrivee + Vector3.FORWARD * 3.0
	for indice in collegues.size():
		collegues[indice].rotation.y = deg_to_rad(45.0) if indice == 0 else 0.0
		var marche := create_tween()
		var destination := fin_course + _position_collegue(indice)
		marche.tween_property(collegues[indice], "global_position", destination, collegues[indice].global_position.distance_to(destination) / vitesse_arrivee)
		marches.append(marche)
	var entree := create_tween()
	entree.tween_property(joueur, "global_position", fin_course, joueur.global_position.distance_to(fin_course) / vitesse_arrivee)
	# Lancer le loup pendant la course pour qu’il surprenne le joueur dans le Hall.
	var temps_approche := (distance_surprise - distance_alerte) / vitesse_loup
	var temps_arrivee := joueur.global_position.distance_to(arrivee) / vitesse_arrivee
	await get_tree().create_timer(maxf(0.05, temps_arrivee - temps_approche)).timeout
	# Partir de la droite du Hall garde le trajet à l'intérieur, hors du cadre initial.
	var droite := global_basis.x.normalized()
	var cible := arrivee - Vector3.UP * 0.3
	loup.global_position = cible + droite * distance_surprise
	# Le modèle du chien regarde vers +Z, contrairement au visuel du pompier.
	loup.look_at(cible, Vector3.UP, true)
	loup.show()
	_animer_loup(true)
	var depart_course := loup.global_position
	var portee_impulsion := maxf(distance_bond, distance_interposition + 1.5)
	var impulsion := cible + droite * portee_impulsion
	var seuil_reperage := maxf(distance_alerte, portee_impulsion + 0.5)
	var course := create_tween()
	# L'approche est au sol. Seuls les derniers mètres seront parcourus en sautant.
	course.tween_method(func(p: float):
		loup.global_position = depart_course.lerp(impulsion, p)
		if not alerte_donnee and loup.global_position.distance_to(cible) <= seuil_reperage:
			alerte_donnee = true
			loup_repere.emit()
	, 0.0, 1.0, depart_course.distance_to(impulsion) / vitesse_loup)
	if not alerte_donnee: await loup_repere
	# La fuite et l’interception remplacent immédiatement les trajets d’arrivée.
	entree.kill()
	for marche in marches: marche.kill()
	_signaler_surprise(joueur)
	for indice in collegues.size():
		_depart_collegue(collegues[indice], indice)
	var interception := cible + Vector3.UP * 0.3 + droite * distance_interposition
	# Le joueur court réellement entre son collègue et le loup pendant l'approche.
	var intervention := _intercepter(interception)
	if course.is_running(): await course.finished
	_animer_loup(false)
	$Grognement.global_position = loup.global_position
	$Grognement.play()
	var depart := loup.global_position
	var fin := interception + droite * 0.9 - Vector3.UP * 0.3
	var bond := create_tween()
	# La parabole donne un véritable saut : le loup revient à sa hauteur de départ.
	bond.tween_method(func(p: float):
		loup.global_position = depart.lerp(fin, p) + Vector3.UP * sin(p * PI) * hauteur_bond
		modele_loup.rotation.x = -sin(p * TAU) * 0.2
	, 0.0, 1.0, duree_bond)
	if intervention.is_running(): await intervention.finished
	joueur.visual.look_at(Vector3(fin.x, joueur.visual.global_position.y, fin.z))
	joueur.extincteur.start_primary_attack()
	var debut_jet := Time.get_ticks_msec()
	# Sur une image très lente, le bond peut déjà être terminé lorsque le timer reprend.
	if bond.is_running(): await bond.finished
	RETOUR_COMBAT.creer_cendres(loup, [modele_loup], 0.65)
	loup.hide()
	loup.queue_free()
	var temps_jet := (Time.get_ticks_msec() - debut_jet) / 1000.0
	await get_tree().create_timer(maxf(0.05, duree_jet - temps_jet)).timeout
	joueur.extincteur.stop_primary_attack()
	animer_joueur = false
	joueur.velocity = Vector3.ZERO
	joueur.set_physics_process(true)
	# Les collègues poursuivent leur trajet en arrière-plan pendant que l'on joue.
	if passes < 2:
		await collegues_passes
	porte.set_process(true)
	get_parent().get_node("AnnexesHall/LimiteCouloir").show()

func _depart_collegue(collegue: Node3D, indice: int) -> void:
	if indice > 0:
		await get_tree().create_timer(decalage_collegues * indice).timeout
	var hauteur := joueur.global_position.y - global_position.y
	# Ces points évitent les piliers du Hall, puis suivent le couloir existant.
	var chemin := $ApprochePorte.get_children()
	# Le deuxième s'arrête à côté du passage, sans marcher sur celui qui ouvre.
	for point in chemin.slice(0, chemin.size() - 1):
		await _deplacer(collegue, point.global_position + Vector3.UP * hauteur)
	if indice == 0:
		await _deplacer(collegue, chemin.back().global_position + Vector3.UP * hauteur)
		porte.set_process(false)
		get_parent().get_node("AnnexesHall/LimiteCouloir").hide()
		await _animer_porte(true)
		ouverture_terminee = true
		porte_ouverte.emit()
	else:
		await _deplacer(collegue, $AttentePorte.global_position + Vector3.UP * hauteur)
		if not ouverture_terminee: await porte_ouverte
		if passes == 0: await premier_passe
		await get_tree().create_timer(0.2).timeout
	await _deplacer(collegue, $ApresPorte.global_position + Vector3.UP * hauteur)
	passes += 1
	if indice == 0:
		premier_passe.emit()
	else:
		# Refermer visiblement avant de rendre la porte au calendrier des ennemis.
		await _animer_porte(false)
		collegues_passes.emit()
	for point in $VersEscalier.get_children():
		await _deplacer(collegue, point.global_position + Vector3.UP * hauteur)
	# La transparence des géométries sert à disparaître discrètement dans l'escalier.
	var fondu := create_tween().set_parallel(true)
	for mesh in collegue.find_children("*", "GeometryInstance3D", true, false):
		fondu.tween_property(mesh, "transparency", 1.0, duree_disparition)
	var sortie: Vector3 = $Disparition.global_position + Vector3.UP * hauteur
	collegue.look_at(Vector3(sortie.x, collegue.global_position.y, sortie.z))
	fondu.tween_property(collegue, "global_position", sortie, duree_disparition)
	await fondu.finished
	collegue.queue_free()

func _position_collegue(indice: int) -> Vector3:
	return Vector3(-ecartement_collegues, 0, -intervalle_collegues if indice == 0 else intervalle_collegues)

func _animer_porte(ouvrir: bool) -> void:
	var battants := porte.get_node("Portes")
	var animation := create_tween().set_parallel(true)
	# Un seul Tween pilote les battants : les collègues ne se disputent plus leur rotation.
	animation.tween_property(battants.get_node("Gauche"), "rotation:y", -1.4 if ouvrir else 0.0, duree_ouverture if ouvrir else duree_fermeture).set_trans(Tween.TRANS_SINE)
	animation.tween_property(battants.get_node("Droite"), "rotation:y", 1.4 if ouvrir else 0.0, duree_ouverture if ouvrir else duree_fermeture).set_trans(Tween.TRANS_SINE)
	await animation.finished

func _deplacer(acteur: Node3D, cible: Vector3, vitesse: float = -1.0, orienter: bool = true) -> void:
	if vitesse < 0.0: vitesse = vitesse_collegues
	var direction := cible - acteur.global_position
	if direction.length_squared() < 0.001: return
	var regard := Vector3(cible.x, acteur.global_position.y, cible.z)
	var ancienne_rotation := acteur.quaternion
	if orienter: acteur.look_at(regard)
	var rotation_cible := acteur.quaternion
	acteur.quaternion = ancienne_rotation
	var marche := create_tween()
	# Interpolation linéaire : conserver la vitesse de course sur chaque segment.
	marche.tween_property(acteur, "global_position", cible, direction.length() / vitesse)
	marche.parallel().tween_property(acteur, "quaternion", rotation_cible, 0.15)
	await marche.finished

func _intercepter(cible: Vector3) -> Tween:
	joueur.visual.look_at(Vector3(cible.x, joueur.visual.global_position.y, cible.z))
	var course := create_tween()
	course.tween_property(joueur, "global_position", cible, joueur.global_position.distance_to(cible) / joueur.speed)
	return course

func _animer_loup(courir: bool) -> void:
	for animateur in modele_loup.find_children("*", "AnimationPlayer", true, false):
		for nom in animateur.get_animation_list():
			if ("walk" if courir else "idle") in nom.to_lower():
				animateur.play(nom, 0.1, 1.4 if courir else 1.0)
				return

func _signaler_surprise(personnage: Node3D) -> void:
	# Copier le modèle ET l'animation PopUp du sbire, sans créer une IA dans la scène.
	var sbire := preload("res://scenes/ennemis/mobiles/sbire.tscn").instantiate()
	var support := Node3D.new()
	personnage.add_child(support)
	var alerte := sbire.get_node("PointExclamation").duplicate()
	var animation := sbire.get_node("SbireRepere").duplicate() as AnimationPlayer
	support.add_child(alerte)
	support.add_child(animation)
	sbire.free()
	alerte.position = Vector3(0, 1.6, 0)
	animation.play("PopUp")
	animation.animation_finished.connect(func(_nom): support.queue_free(), CONNECT_ONE_SHOT)
	$Cri.global_position = personnage.global_position + Vector3.UP
	$Cri.play()

func _process(delta: float) -> void:
	if not preparee or delta <= 0.0: return
	# Mesurer le déplacement des Tweens pour alimenter l'arbre d'animation existant.
	for collegue in collegues:
		if not is_instance_valid(collegue): continue
		var vitesse: Vector3 = (collegue.global_position - positions_precedentes[collegue]) / delta
		positions_precedentes[collegue] = collegue.global_position
		var local := collegue.global_basis.orthonormalized().inverse() * vitesse
		var arbre: AnimationTree = collegue.get_child(0).get_node("visual/Armature/AnimationTree")
		var cible := (Vector2(local.x, -local.z) / vitesse_collegues).limit_length(1.0)
		var actuel: Vector2 = arbre["parameters/blend_position"]
		arbre["parameters/blend_position"] = actuel.lerp(cible, 1.0 - exp(-12.0 * delta))
	if animer_joueur:
		joueur.velocity = (joueur.global_position - positions_precedentes[joueur]) / delta
		positions_precedentes[joueur] = joueur.global_position
		# Le même calcul que pendant le jeu gère déjà les déplacements dans toutes les directions.
		joueur.animate(delta)

func _fermer_grille() -> void:
	var grille: Node3D = get_parent().get_node("Navigation/Decor/FondCouloir/Grille")
	# Attendre que le dernier collègue ait entièrement franchi l'entrée extérieure.
	while is_instance_valid(collegues[1]) and collegues[1].global_position.z > grille.global_position.z - 0.8:
		await get_tree().process_frame
	var fermeture := create_tween().set_parallel(true)
	# Le haut reste au niveau du linteau pendant que le bas descend vers le sol.
	fermeture.tween_property(grille, "position:y", 0.0, duree_fermeture_grille).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fermeture.tween_property(grille, "scale:y", 1.0, duree_fermeture_grille).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fermeture.finished
	retablir_grille()

func retablir_grille() -> void:
	var grille = get_parent().get_node("Navigation/Decor/FondCouloir/Grille")
	grille.position.y = 0.0
	grille.scale.y = 1.0
	grille.get_node("Corps/Collision").disabled = false
	# Mettre la navigation à jour une seule fois, après la fermeture ou la reprise.
	get_parent().geometrie_decor = null
	get_parent().cuire_navigation()

func _hauteur_joueur_au_sol() -> float:
	var collision: CollisionShape3D = joueur.get_node("CollisionShape3D")
	var capsule := collision.shape as CapsuleShape3D
	var hauteur := capsule.height * collision.global_basis.get_scale().y / 2.0
	hauteur -= collision.global_position.y - joueur.global_position.y
	# Mesurer le sol du couloir avant de déplacer le joueur dans la rue.
	var rayon := PhysicsRayQueryParameters3D.create(joueur.global_position + Vector3.UP, joueur.global_position - Vector3.UP * 5.0, 1, [joueur.get_rid()])
	var contact := get_world_3d().direct_space_state.intersect_ray(rayon)
	var sol: float = contact.position.y if not contact.is_empty() else get_parent().global_position.y
	return sol + hauteur + joueur.safe_margin
