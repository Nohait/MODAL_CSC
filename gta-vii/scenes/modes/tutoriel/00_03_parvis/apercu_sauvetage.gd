extends Node3D

@export_range(2, 3, 1) var nombre_habitants := 2
@export_range(0.5, 4.0, 0.01) var vitesse := 1.67
@export_range(0.6, 2.5, 0.1) var espacement := 1.3
@export_range(0.4, 1.0, 0.05) var allure_blessee := 1.0
@export var trajet := PackedVector3Array([
	# Sortir au-delà des vantaux ouverts avant de contourner la porte à gauche.
	Vector3(-0.6, 1, -7.1), Vector3(-0.6, 1, -2.3),
	Vector3(-3, 1, -4.3), Vector3(-7, 1, -4.3),
	Vector3(-9, 1, -1),
	Vector3(-10, 1, 2), Vector3(-11, 1, 6.7)])
var lance := false
var termine := false
var distance := 0.0
var figurants: Array[Dictionary] = []
var accueillant: Node3D
var trace := PackedVector3Array()
var segment := 1
var habitant_embarque := 1
var guide_arrive := false
var guide_ecarte := false
var porte: StaticBody3D
const HABITANT = preload("res://scenes/victimes/victime.tscn")
const ANIMATIONS = preload("res://scenes/modes/tutoriel/00_03_parvis/animations_parvis.gd")
@export var locomotion: ANIMATIONS = ANIMATIONS.new()

func _ready() -> void:
	set_process(false)

func jouer(joueur: Node3D) -> void:
	if lance or trajet.size() < 2: return
	lance = true
	porte = get_parent().get_node("PorteEntree")
	porte.ouvrir()
	if not porte.ouverte: await porte.ouverture_terminee
	if not is_instance_valid(joueur): return
	var pompier: Node3D = joueur.get_node("visual/pompier").duplicate()
	_assainir(pompier)
	var porteur := Node3D.new()
	add_child(porteur)
	porteur.add_child(pompier)
	pompier.get_node("visual/Armature/Skeleton3D/Right_Hand_Holder/extincteur0").hide()
	var arbre := locomotion.installer(pompier, true)
	figurants.append({"modele": porteur, "arbre": arbre, "pompier": true})
	accueillant = get_parent().get_node("PointRegroupement/Secouriste")
	for i in range(nombre_habitants):
		# Extraire seulement le modèle animé ; aucun script de victime ne rejoint l’arbre.
		var instance = HABITANT.instantiate()
		var modele: Node3D = instance.get_node("victime")
		instance.remove_child(modele)
		instance.free()
		_assainir(modele)
		var habitant := Node3D.new()
		add_child(habitant)
		habitant.add_child(modele)
		# Conserver l’échelle du modèle partagé, sans mesure AABB du squelette.
		modele.position.y -= 0.25
		var animation := locomotion.installer(modele, false)
		figurants.append({"modele": habitant, "arbre": animation, "pompier": false})
	for figurant in figurants: figurant.modele.hide()
	for figurant in figurants: figurant.modele.position = trajet[0]
	trace.append(trajet[0])
	set_process(true)

func _assainir(noeud: Node) -> void:
	# Les figurants n’interagissent ni avec le joueur, ni avec les compteurs, ni avec le son.
	noeud.set_script(null)
	for groupe in noeud.get_groups(): noeud.remove_from_group(groupe)
	if noeud is CollisionObject3D:
		noeud.collision_layer = 0
		noeud.collision_mask = 0
	if noeud is Area3D:
		noeud.monitoring = false
		noeud.monitorable = false
	for enfant in noeud.get_children():
		if enfant is AudioStreamPlayer or enfant is AudioStreamPlayer3D:
			noeud.remove_child(enfant)
			enfant.free()
		else:
			_assainir(enfant)

func _longueur() -> float:
	var total := 0.0
	for i in range(trajet.size() - 1): total += trajet[i].distance_to(trajet[i + 1])
	return total

func _position_sur_trajet(avance: float) -> Vector3:
	for i in range(trajet.size() - 1):
		var longueur := trajet[i].distance_to(trajet[i + 1])
		if avance <= longueur: return trajet[i].lerp(trajet[i + 1], avance / maxf(longueur, 0.001))
		avance -= longueur
	return trajet[-1]

func _position_dans_trace(recul: float) -> Vector3:
	for i in range(trace.size() - 1, 0, -1):
		var longueur := trace[i].distance_to(trace[i - 1])
		if recul <= longueur: return trace[i].lerp(trace[i - 1], recul / maxf(longueur, 0.001))
		recul -= longueur
	return trace[0]

func _animer(figurant: Dictionary, cible: Vector3, delta: float, allure_max := 1.0) -> void:
	var modele: Node3D = figurant.modele
	var ancienne := modele.position
	locomotion.orienter(figurant.arbre, modele, cible - ancienne, delta, not figurant.pompier)
	# Le guide adopte l'allure du groupe ; les victimes ne courent pas pour le rattraper.
	var vitesse_cible := minf(vitesse * allure_blessee * allure_max, modele.position.distance_to(cible) * 4.0)
	if locomotion.pivote(figurant.arbre): vitesse_cible = 0.0
	var vitesse_actuelle := move_toward(float(figurant.get("vitesse", 0.0)), vitesse_cible, delta * 3.0)
	figurant.vitesse = vitesse_actuelle
	modele.position = modele.position.move_toward(cible, vitesse_actuelle * delta)
	if modele.position.distance_to(cible) < 0.005:
		modele.position = cible
		figurant.vitesse = 0.0
	var mouvement := modele.position - ancienne
	locomotion.actualiser(figurant.arbre, mouvement.length() / maxf(delta, 0.001), delta)

func _process(delta: float) -> void:
	var guide: Dictionary = figurants[0]
	guide.modele.show()
	if not guide_arrive:
		var precedent: Vector3 = guide.modele.position
		_animer(guide, trajet[segment], delta)
		var nouveau: Vector3 = guide.modele.position
		distance += precedent.distance_to(nouveau)
		if trace[-1].distance_to(nouveau) > 0.02: trace.append(nouveau)
		if nouveau.distance_to(trajet[segment]) < 0.05:
			if segment < trajet.size() - 1: segment += 1
			else:
				guide_arrive = true
				_animer(guide, nouveau, delta)
	elif not guide_ecarte:
		# Libérer le pied de la rampe avant de laisser monter les habitants.
		var attente := Vector3(-9.9, 1, 6.5)
		_animer(guide, attente, delta, 0.5)
		if guide.modele.position.is_equal_approx(attente):
			guide_ecarte = true
			_animer(guide, attente, delta)
	else:
		_animer(guide, guide.modele.position, delta)
		locomotion.orienter(guide.arbre, guide.modele, guide.modele.get_parent().to_local(accueillant.global_position) - guide.modele.position, delta)
	for i in range(1, figurants.size()):
		var figurant: Dictionary = figurants[i]
		if distance < i * espacement: continue
		if i < habitant_embarque: continue
		figurant.modele.show()
		if guide_arrive and guide_ecarte and i == habitant_embarque:
			# Monter sur la rampe, puis masquer seulement après le franchissement de l’ouverture.
			var points := [
				Vector3(-11, 1, 6.7), Vector3(-11, 1.65, 8.15),
				Vector3(-11, 1.65, 8.8)]
			var etape: int = figurant.get("embarquement", 0)
			_animer(figurant, points[etape], delta, 0.6)
			if figurant.modele.position.distance_to(points[etape]) < 0.04:
				if etape < points.size() - 1: figurant.embarquement = etape + 1
				else:
					_animer(figurant, points[etape], delta)
					figurant.modele.hide()
					figurant.arbre.active = false
					habitant_embarque += 1
		else:
			# La file suit les positions du guide, pas une animation directionnelle indépendante.
			_animer(figurant, _position_dans_trace(i * espacement), delta)
	if guide_arrive and habitant_embarque >= figurants.size():
		if float(guide.arbre["parameters/Transition/blend_amount"]) <= 0.001 and not locomotion.pivote(guide.arbre):
			termine = true
			set_process(false)
			porte.fermer()

