extends Resource

const BASE = preload("res://scenes/modes/tutoriel/commun/figurants/animations_figurant.gd")
const POMPIER = preload("res://assets/tutoriel/animations/parvis/pompier.tres")
const VICTIME = preload("res://assets/tutoriel/animations/parvis/victime_blessee.tres")

@export var activer_clips_importes := true
@export_range(20.0, 90.0, 1.0) var seuil_pivot_degres := 45.0
@export_range(0.05, 0.3, 0.01) var fondu_pivot := 0.12
@export_range(30.0, 360.0, 10.0) var rotation_douce_degres := 120.0
@export_range(0.5, 3.0, 0.05) var cadence_pompier := 1.67
@export_range(0.5, 3.0, 0.05) var cadence_victime := 1.28

func installer(modele: Node3D, pompier: bool) -> AnimationTree:
	var arbre := BASE.installer(modele, pompier)
	if not activer_clips_importes: return arbre
	arbre.active = false
	var lecteur: AnimationPlayer = modele.get_node(("visual/Armature/" if pompier else "Armature/") + "AnimationPlayer")
	var banque: AnimationLibrary = POMPIER if pompier else VICTIME
	var repos_reference: Animation
	if not pompier:
		banque = VICTIME.duplicate() as AnimationLibrary
		if lecteur.has_animation("idle"):
			var repos := lecteur.get_animation("idle").duplicate() as Animation
			repos_reference = repos
			repos.loop_mode = Animation.LOOP_LINEAR
			banque.remove_animation("Idle")
			banque.add_animation("Idle", repos)
	if not pompier and lecteur.has_animation_library("injured_walk"):
		var marche_blessee := lecteur.get_animation_library("injured_walk")
		if marche_blessee.has_animation("injured_walk"):
			var marche := marche_blessee.get_animation("injured_walk").duplicate() as Animation
			if repos_reference != null:
				_adapter_bassin(marche, repos_reference)
			marche.loop_mode = Animation.LOOP_LINEAR
			banque.remove_animation("Walk")
			banque.add_animation("Walk", marche)
	lecteur.add_animation_library("Parvis", banque)
	var melange := arbre.tree_root as AnimationNodeBlendTree
	melange.add_node("DecalageMarche", AnimationNodeTimeSeek.new())
	melange.disconnect_node("Cadence", 0)
	melange.connect_node("DecalageMarche", 0, "Walk")
	melange.connect_node("Cadence", 0, "DecalageMarche")
	for nom in ["Idle", "Walk"]:
		(melange.get_node(nom) as AnimationNodeAnimation).animation = "Parvis/" + nom
	for nom in ["TurnLeft", "TurnRight"]:
		var clip := AnimationNodeAnimation.new()
		clip.animation = "Parvis/" + nom
		melange.add_node(nom, clip)
	melange.add_node("SensPivot", AnimationNodeBlend2.new())
	melange.connect_node("SensPivot", 0, "TurnLeft")
	melange.connect_node("SensPivot", 1, "TurnRight")
	var pivot := AnimationNodeOneShot.new()
	pivot.fadein_time = fondu_pivot
	pivot.fadeout_time = fondu_pivot
	melange.add_node("Pivot", pivot)
	melange.disconnect_node("output", 0)
	melange.connect_node("Pivot", 0, "Transition")
	melange.connect_node("Pivot", 1, "SensPivot")
	melange.connect_node("output", 0, "Pivot")
	arbre.set_meta("duree_gauche", banque.get_animation("TurnLeft").length)
	arbre.set_meta("duree_droite", banque.get_animation("TurnRight").length)
	arbre.set_meta("vitesse_marche_reference", cadence_pompier if pompier else cadence_victime)
	arbre.set_meta("pivot_restant", 0.0)
	arbre.set_meta("figurant_pompier", pompier)
	arbre.active = true
	arbre.advance(0)
	return arbre

func decaler_marche(arbre: AnimationTree, temps: float) -> void:
	if not activer_clips_importes: return
	# Activer momentanément la branche permet de positionner sa lecture sans bouger le figurant.
	arbre["parameters/Transition/blend_amount"] = 1.0
	arbre["parameters/Cadence/scale"] = 1.0
	arbre["parameters/DecalageMarche/seek_request"] = temps
	arbre.advance(0.001)
	arbre["parameters/Transition/blend_amount"] = 0.0
	arbre["parameters/Cadence/scale"] = 0.0
	arbre.advance(0.001)

func _adapter_bassin(marche: Animation, repos: Animation) -> void:
	# Les deux clips utilisent des axes et des unités différents pour le bassin.
	var chemin := NodePath("Armature/Skeleton3D:mixamorig2_Hips")
	var piste_marche := marche.find_track(chemin, Animation.TYPE_POSITION_3D)
	var piste_repos := repos.find_track(chemin, Animation.TYPE_POSITION_3D)
	if piste_marche < 0 or piste_repos < 0: return
	if marche.track_get_key_count(piste_marche) == 0 or repos.track_get_key_count(piste_repos) == 0: return
	var origine: Vector3 = marche.track_get_key_value(piste_marche, 0)
	var hauteur_repos: Vector3 = repos.track_get_key_value(piste_repos, 0)
	for i in marche.track_get_key_count(piste_marche):
		var ecart: Vector3 = marche.track_get_key_value(piste_marche, i) - origine
		marche.track_set_key_value(piste_marche, i, hauteur_repos + Vector3(ecart.x, ecart.z, -ecart.y) * 100.0)

func actualiser(arbre: AnimationTree, vitesse: float, delta: float) -> void:
	BASE.actualiser(arbre, vitesse, delta)
	if not activer_clips_importes: return
	arbre.set_meta("pivot_restant", maxf(0.0, float(arbre.get_meta("pivot_restant")) - delta))

func pivote(arbre: AnimationTree) -> bool:
	return float(arbre.get_meta("pivot_restant", 0.0)) > 0.0

func orienter(arbre: AnimationTree, modele: Node3D, direction: Vector3, delta: float, face_positive := false, pivot_sur_place := true) -> void:
	if not activer_clips_importes:
		BASE.orienter(modele, direction, delta, face_positive)
		return
	direction.y = 0.0
	if direction.length_squared() < 0.000001: return
	var cible := atan2(direction.x, direction.z) + (0.0 if face_positive else PI)
	if not arbre.has_meta("orientation_initialisee"):
		modele.rotation.y = cible
		arbre.set_meta("orientation_initialisee", true)
		return
	var ecart := angle_difference(modele.rotation.y, cible)
	if not pivot_sur_place or not bool(arbre.get_meta("figurant_pompier", true)):
		modele.rotation.y = rotate_toward(modele.rotation.y, cible, deg_to_rad(rotation_douce_degres) * delta)
		return
	if not pivote(arbre) and absf(ecart) >= deg_to_rad(seuil_pivot_degres):
		var gauche := ecart > 0.0
		var duree: float = arbre.get_meta("duree_gauche" if gauche else "duree_droite")
		arbre["parameters/SensPivot/blend_amount"] = 0.0 if gauche else 1.0
		arbre["parameters/Pivot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		arbre.set_meta("pivot_restant", duree)
		arbre.set_meta("vitesse_pivot", minf(absf(ecart), PI * 0.5) / duree)
	# Le porteur tourne avec les appuis du clip, sans rotation supplémentaire du squelette.
	var vitesse: float = arbre.get_meta("vitesse_pivot", 0.0) if pivote(arbre) else deg_to_rad(rotation_douce_degres)
	modele.rotation.y = rotate_toward(modele.rotation.y, cible, vitesse * delta)
