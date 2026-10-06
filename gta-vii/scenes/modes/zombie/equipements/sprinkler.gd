extends Node3D

signal etat_change
var voyant: MeshInstance3D
var temps_voyant := 0.0
var attente_eclaboussure := 0.0
var detail_etat: Label3D
const VAPEUR = preload("res://scenes/effets/combat/impact_mousse.tscn")
@export var emplacement := "Entrée"
@export_range(1.0, 3.5, 0.1) var hauteur := 2.7
@export var sur_pied := false
@export_range(1, 100, 1) var prix_activation := 5
@export_range(1.0, 8.0, 0.5) var rayon := 4.0
@export_range(0.5, 10.0, 0.5) var duree := 3.0
@export_range(1.0, 100.0, 1.0) var degats_par_seconde := 20.0
var arme := false
var temps_restant := 0.0
var temps_degats := 0.0
var utilisations := 0
var attente_rearmement := 0.0
var utilise := false
@onready var zone: Area3D = $Zone
@onready var eau: CPUParticles3D = $Eau

func _ready() -> void:
	detail_etat = preload("res://scenes/interfaces/indications/indication_equipement.gd").habiller($Etat, emplacement)
	voyant = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.07
	sphere.height = 0.14
	voyant.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	voyant.material_override = mat
	add_child(voyant)
	voyant.position = Vector3(0, hauteur, 0.18)

	add_to_group("sprinkler")
	# Le pied permet de garder une tête haute même près d'une cloison basse.
	$Support.visible = sur_pied
	$Support/Mat.mesh = $Support/Mat.mesh.duplicate()
	# Le bas de la tête est 25 cm sous son centre : le poteau s'arrête à ce raccord.
	$Support/Mat.mesh.height = hauteur - 0.25
	$Support/Mat.position.y = (hauteur - 0.25) / 2.0
	for noeud in [$Tete, $Eau, $Etat]:
		noeud.position.y += hauteur - 2.7
	# Sur pied, centrer la tête sur le poteau ; au mur, conserver un petit déport.
	var avance := 0.0 if sur_pied else 0.2
	$Tete.position.z = avance
	$Eau.position.z = avance + 0.3
	# Le texte tourne vers la caméra : le garder devant le mur, même sur pied.
	$Etat.position.z = avance + 0.65
	# Le modèle téléchargé n'a pas de texture : lui donner une finition métallique sobre.
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("a38a62")
	metal.metallic = 0.75
	metal.roughness = 0.45
	for morceau in $Tete.find_children("*", "MeshInstance3D", true, false):
		morceau.material_override = metal
	$Zone/Collision.shape = $Zone/Collision.shape.duplicate()
	$Zone/Collision.shape.radius = rayon
	$Zone/Anneau.mesh = $Zone/Anneau.mesh.duplicate()
	$Zone/Anneau.mesh.inner_radius = rayon - 0.04
	$Zone/Anneau.mesh.outer_radius = rayon
	_actualiser()

func armer() -> void:
	arme = true
	utilise = false
	attente_rearmement = 0.0
	var effets = _effets_cartes()
	utilisations = 2 if effets != null and effets.valeur("circuit_secours") > 0 else 1
	_actualiser()
	etat_change.emit()

func recharger() -> void:
	# Le debug peut aussi interrompre un jet en cours avant de réarmer l'équipement.
	temps_restant = 0.0
	temps_degats = 0.0
	eau.emitting = false
	armer()

func _physics_process(delta: float) -> void:
	if attente_rearmement > 0:
		attente_rearmement = maxf(0, attente_rearmement - delta)
		if attente_rearmement == 0: _actualiser()
		return
	if arme:
		for ennemi in zone.get_overlapping_bodies():
			if _peut_toucher(ennemi):
				# Circuit de secours ajoute une seconde utilisation, sans nouvel achat.
				preload("res://scenes/effets/retours/impulsion_visuelle.gd").jouer(get_parent(), zone.global_position + Vector3.UP * 0.08, Color("80dfff"), rayon)
				utilisations -= 1
				utilise = true
				var effets = _effets_cartes()
				if effets != null: effets.sprinkler_declenche(self)
				arme = false
				temps_restant = duree
				temps_degats = 0.0
				eau.restart()
				eau.emitting = true
				_actualiser()
				etat_change.emit()
				break
	if temps_restant <= 0.0: return
	var pas := minf(delta, temps_restant)
	temps_restant -= pas
	temps_degats += pas
	# Réunir les dégâts par quarts de seconde limite aussi le nombre de bouffées de vapeur.
	if temps_degats >= 0.25 or temps_restant <= 0.0:
		for ennemi in zone.get_overlapping_bodies():
			if not _peut_toucher(ennemi): continue
			var position_vapeur: Vector3 = ennemi.global_position + Vector3.UP
			var effets = _effets_cartes()
			if effets != null:
				effets.infliger(ennemi, degats_par_seconde * temps_degats * effets.puissance_sprinkler(self), &"eau")
				if effets.valeur("eau_glacee") > 0 and not ennemi.est_mort and ennemi.has_method("appliquer_gel"):
					ennemi.appliquer_gel(effets.valeur("eau_glacee"), 1.0)
			else: ennemi.prendre_degats(degats_par_seconde * temps_degats, &"eau")
			var vapeur = VAPEUR.instantiate()
			get_parent().add_child(vapeur)
			vapeur.global_position = position_vapeur
			vapeur.lancer(Vector3.UP)
		temps_degats = 0.0
	if temps_restant <= 0.0:
		eau.emitting = false
		if utilisations > 0:
			arme = true
			attente_rearmement = 5.0
		_actualiser()
		etat_change.emit()

func _effets_cartes() -> Node:
	var pompier = get_tree().get_first_node_in_group("player")
	return pompier.ameliorations.effets_cartes if is_instance_valid(pompier) and is_instance_valid(pompier.ameliorations) else null

func _peut_toucher(corps: Node3D) -> bool:
	if not is_instance_valid(corps) or corps.is_queued_for_deletion(): return false
	if not corps.is_in_group("enemies") or not corps.has_method("prendre_degats"): return false
	# Les murs protègent un ennemi situé dans la pièce voisine.
	var rayon_vue := PhysicsRayQueryParameters3D.create(
		zone.global_position, corps.global_position + Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(rayon_vue).is_empty()

func _actualiser() -> void:
	$Zone/Anneau.visible = arme or temps_restant > 0.0
	detail_etat.text = "ARROSAGE EN COURS" if temps_restant > 0.0 else ("RÉARMEMENT…" if attente_rearmement > 0 else ("PRÊT" if arme else "À RECHARGER EN BOUTIQUE"))
	detail_etat.modulate = Color("8ad8ee") if temps_restant > 0.0 else (Color("9cd5b3") if arme else Color("b6aaa0"))

func _process(delta: float) -> void:
	temps_voyant += delta
	attente_eclaboussure = maxf(0.0, attente_eclaboussure - delta)
	if temps_restant > 0.0 and attente_eclaboussure == 0:
		attente_eclaboussure = 0.45
		var point := zone.global_position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
		preload("res://scenes/effets/combat/eclaboussure_eau.gd").jouer(get_parent(), point)
		preload("res://scenes/effets/combat/trace_combat.gd").sur_sol(get_parent(), point, Color(0.4, 0.68, 0.8, 0.22), 0.8, 2.5)

	var actif := temps_restant > 0.0
	var mat: StandardMaterial3D = voyant.material_override
	mat.albedo_color = Color("80dfff") if actif else (Color("81dba7") if arme else Color("b76c50"))
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 2.5 if actif else (0.5 + 0.4 * sin(temps_voyant * 3.0) if arme else 0.15)
