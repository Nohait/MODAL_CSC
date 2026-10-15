extends Node3D

const ANIMATIONS = preload("res://scenes/modes/tutoriel/commun/figurants/animations_figurant.gd")
const BULLE = preload("res://scenes/modes/tutoriel/commun/dialogues/bulle_pompier.tscn")
var pompier: Node3D
var animation_pompier: AnimationTree
var interlocuteur: Node3D
var bulle: PanelContainer

func installer_modele(joueur: Node3D) -> void:
	pompier = joueur.get_node("visual/pompier").duplicate()
	_assainir(pompier)
	add_child(pompier)
	pompier.get_node("visual/Armature/Skeleton3D/Right_Hand_Holder/extincteur0").hide()
	animation_pompier = ANIMATIONS.installer(pompier, true)
	ANIMATIONS.orienter(pompier, Vector3(0, 0, 1), 1, false, true)

func parler(phrase: String, joueur: Node3D, camera: Camera3D) -> void:
	interlocuteur = joueur
	if not is_instance_valid(bulle):
		var interface := CanvasLayer.new()
		interface.layer = 3
		add_child(interface)
		bulle = BULLE.instantiate()
		interface.add_child(bulle)
		bulle.acteur = self
		bulle.camera = camera
	bulle.afficher(phrase)

func _process(delta: float) -> void:
	if not is_instance_valid(bulle) or not is_instance_valid(interlocuteur): return
	var ecart := interlocuteur.global_position - global_position
	ecart.y = 0
	bulle.visible = ecart.length() < 3.5 and not bulle.camera.is_position_behind(global_position)
	if bulle.visible: ANIMATIONS.orienter(pompier, global_basis.inverse() * ecart, delta)

func terminer_dialogue() -> void:
	interlocuteur = null
	if is_instance_valid(bulle): bulle.hide()

func _assainir(noeud: Node) -> void:
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
		else: _assainir(enfant)
