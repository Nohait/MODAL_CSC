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
	lecteur.add_animation_library("Parvis", banque)
	var melange := arbre.tree_root as AnimationNodeBlendTree
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
	arbre.active = true
	arbre.advance(0)
	return arbre

func actualiser(arbre: AnimationTree, vitesse: float, delta: float) -> void:
	BASE.actualiser(arbre, vitesse, delta)
	if not activer_clips_importes: return
	arbre.set_meta("pivot_restant", maxf(0.0, float(arbre.get_meta("pivot_restant")) - delta))

func pivote(arbre: AnimationTree) -> bool:
	return float(arbre.get_meta("pivot_restant", 0.0)) > 0.0

func orienter(arbre: AnimationTree, modele: Node3D, direction: Vector3, delta: float, face_positive := false) -> void:
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
