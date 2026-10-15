extends RefCounted

const POMPIER = preload("res://assets/tutoriel/animations/pompier_marche.tres")
const VICTIME = preload("res://assets/tutoriel/animations/victime_marche.tres")

static func installer(modele: Node3D, pompier: bool) -> AnimationTree:
	var chemin := "visual/Armature/" if pompier else "Armature/"
	var arbre: AnimationTree = modele.get_node(chemin + "AnimationTree")
	var lecteur: AnimationPlayer = modele.get_node(chemin + "AnimationPlayer")
	arbre.active = false
	lecteur.stop()
	lecteur.add_animation_library("Tutoriel", POMPIER if pompier else VICTIME)
	# Remplacer seulement l'arbre de cette copie décorative, jamais la ressource partagée.
	var melange := AnimationNodeBlendTree.new()
	for nom in ["Idle", "Walk"]:
		var clip := AnimationNodeAnimation.new()
		clip.animation = "Tutoriel/" + nom
		melange.add_node(nom, clip)
	melange.add_node("Cadence", AnimationNodeTimeScale.new())
	melange.add_node("Transition", AnimationNodeBlend2.new())
	melange.connect_node("Cadence", 0, "Walk")
	melange.connect_node("Transition", 0, "Idle")
	melange.connect_node("Transition", 1, "Cadence")
	melange.connect_node("output", 0, "Transition")
	arbre.tree_root = melange
	arbre["parameters/Transition/blend_amount"] = 0.0
	arbre["parameters/Cadence/scale"] = 0.0
	# Vitesse de recul du pied en appui, mesurée sur les clips adaptés à ces modèles.
	arbre.set_meta("vitesse_marche_reference", 0.87 if pompier else 0.94)
	arbre.active = true
	arbre.advance(0)
	return arbre

static func actualiser(arbre: AnimationTree, vitesse: float, delta: float) -> void:
	var precedent: float = arbre["parameters/Transition/blend_amount"]
	var poids := move_toward(precedent, 1.0 if vitesse > 0.03 else 0.0, delta * 5.0)
	arbre["parameters/Transition/blend_amount"] = poids
	var reference: float = arbre.get_meta("vitesse_marche_reference")
	# Au ralentissement, diminuer la cadence plutôt que remplacer la marche par un demi-idle.
	arbre["parameters/Cadence/scale"] = minf(vitesse / maxf(reference * poids, 0.01), 2.0) if poids > 0.01 else 0.0

static func orienter(modele: Node3D, direction: Vector3, delta: float, face_positive := false, immediat := false) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.0000000001: return
	var angle := atan2(direction.x, direction.z) + (0.0 if face_positive else PI)
	modele.rotation.y = angle if immediat else lerp_angle(modele.rotation.y, angle, 1.0 - exp(-8.0 * delta))
