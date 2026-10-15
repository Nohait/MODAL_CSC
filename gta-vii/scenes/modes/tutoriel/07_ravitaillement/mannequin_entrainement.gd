extends CharacterBody3D

const RETOUR = preload("res://scenes/effets/combat/retour_combat.gd")
@export_range(1.0, 2.5, 0.05) var hauteur := 1.85
var hitbox_radius := 0.6
var est_mort := false
var modele: Node3D
var texte: Label3D
var reaction: Tween
var prochain_impact := 0

func _ready() -> void:
	add_to_group("cibles_entrainement")
	collision_layer = 4
	collision_mask = 0
	set_physics_process(false)
	modele = preload("res://scenes/decors/ville/mobilier_annexe.gd").new()
	modele.modele_scene = preload("res://assets/tutoriel/mannequin/crash_dummy.glb")
	modele.hauteur = hauteur
	modele.suie = 0.15
	add_child(modele)
	var collision := CollisionShape3D.new()
	var forme := CapsuleShape3D.new()
	forme.radius = 0.45
	forme.height = hauteur
	collision.shape = forme
	collision.position.y = hauteur * 0.5
	add_child(collision)
	texte = Label3D.new()
	texte.hide()
	texte.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(texte)
	var feu = preload("res://scenes/effets/feu/flames.tscn").instantiate()
	feu.position.y = 0.45
	feu.scale = Vector3.ONE * 0.55
	modele.add_child(feu)

func prendre_degats(degats: float, _source: StringName = &"mousse") -> void:
	if degats <= 0: return
	# Montant fourni par le jet réel ; aucune jauge, mort ou récompense.
	preload("res://scenes/interfaces/indications/nombre_degats.gd").afficher(texte, degats, hauteur + 0.2)
	if Time.get_ticks_msec() < prochain_impact: return
	prochain_impact = Time.get_ticks_msec() + 250
	if reaction:
		reaction.kill()
		modele.scale = Vector3.ONE
	reaction = RETOUR.reagir_impact(modele, 0.045)
