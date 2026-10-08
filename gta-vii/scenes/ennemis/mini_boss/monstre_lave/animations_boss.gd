extends Node

signal pas_pose

# Les instants désignent des secondes dans les clips, pas les délais du combat.
@export_group("Synchronisation des gestes")
@export_range(0.0, 3.0, 0.01) var debut_descente := 1.35
@export_range(0.0, 3.0, 0.01) var instant_impact := 1.67
@export_range(0.0, 4.0, 0.01) var instant_projection := 1.4
@export_range(0.0, 1.0, 0.01) var fondu_postures := 0.15
@export_group("Saut du coup au sol")
@export_range(0.0, 3.0, 0.05) var hauteur_saut := 1.2
@export_range(0.0, 2.0, 0.01) var instant_decollage := 0.5
@export_range(0.0, 2.0, 0.01) var instant_sommet := 1.0

@export_group("Contacts des pieds dans le clip de marche")
@export var instants_pas := PackedFloat32Array([0.2, 0.8])

var lecteur: AnimationPlayer
var squelette: Skeleton3D
var main_gauche := -1
var main_droite := -1
var visuel: Node3D
var collision: CollisionShape3D
var hauteur_visuel := 0.0
var hauteur_collision := 0.0
var impact_local := Vector3.ZERO
@onready var boss = get_parent()

func _ready() -> void:
	visuel = boss.get_node("Sketchfab_Scene")
	collision = boss.get_node("CollisionShape3D")
	hauteur_visuel = visuel.position.y
	hauteur_collision = collision.position.y
	lecteur = boss.get_node("Sketchfab_Scene/Modele").find_child("AnimationPlayer", true, false)
	squelette = boss.get_node("Sketchfab_Scene/Modele").find_child("Skeleton3D", true, false)
	# Le combat pilote la lecture : gel et pause suspendent aussi le geste.
	lecteur.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in ["attente", "marche"]:
		lecteur.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	main_gauche = squelette.find_bone("LeftHand_015")
	main_droite = squelette.find_bone("RightHand_019")
	# Mesurer une fois le contact des mains, pour annoncer exactement ce point au sol.
	lecteur.play("coup_sol")
	lecteur.seek(instant_impact, true)
	squelette.force_update_all_bone_transforms()
	var mains := (squelette.get_bone_global_pose(main_gauche).origin + squelette.get_bone_global_pose(main_droite).origin) * 0.5
	impact_local = boss.to_local(squelette.to_global(mains))
	impact_local.y = 0.0
	lecteur.play("attente", 0.0)
	lecteur.seek(0.0, true)
	process_physics_priority = 1

func _physics_process(delta: float) -> void:
	if boss.est_mort or boss.est_gele() or boss.subit_recul():
		return
	var etat: String = boss.etat
	var clip := "attente"
	if etat in ["preparation", "frappe"]:
		clip = "coup_sol"
	elif etat in ["preparation_salve", "salve"]:
		clip = "salve"
	elif etat == "colere":
		clip = "colere"
	elif etat == "invocation":
		clip = "invocation"
	elif etat == "repos" and lecteur.current_animation in ["coup_sol", "salve", "invocation"]:
		clip = lecteur.current_animation
	elif etat == "marche" and boss.velocity.length() > 0.1:
		clip = "marche"
	if lecteur.current_animation != clip:
		lecteur.play(clip, fondu_postures)
	var position_avant := lecteur.current_animation_position
	lecteur.advance(delta)
	# Détecter les contacts dans le clip, y compris lorsque la boucle recommence.
	if clip == "marche":
		var position_apres := lecteur.current_animation_position
		for instant in instants_pas:
			var contact := position_avant < instant and position_apres >= instant
			if position_apres < position_avant:
				contact = instant > position_avant or instant <= position_apres
			if contact: pas_pose.emit()
	if etat == "colere":
		_positionner(0.0, lecteur.get_animation(clip).length, boss.phase.duree_colere)
	elif etat == "invocation":
		_positionner(0.0, lecteur.get_animation(clip).length * 0.75, boss.invocations.preparation)
	elif etat == "repos" and clip == "invocation":
		_positionner(lecteur.get_animation(clip).length * 0.75, lecteur.get_animation(clip).length, boss.invocations.recuperation)
	elif etat == "preparation":
		_positionner(0.0, debut_descente, boss.preparation_frappe)
	elif etat == "frappe":
		_positionner(debut_descente, instant_impact, boss.duree_coup)
	elif etat == "repos" and clip == "coup_sol":
		_positionner(instant_impact, lecteur.get_animation(clip).length, boss.repos_frappe)
	elif etat == "repos" and clip == "salve":
		_positionner(instant_projection, lecteur.get_animation(clip).length, boss.repos_salve)
	elif etat == "preparation_salve":
		_positionner(0.0, instant_projection, boss.preparation_salve)
	elif etat == "salve":
		# Garder les mains en position de projection pendant les tirs rapprochés.
		lecteur.seek(instant_projection, true)
	# Le saut déplace seulement le visuel : la collision reste stable au sol.
	# Les animations importées posent les pieds au sol : cette courbe ajoute le vrai saut.
	var hauteur := 0.0
	if clip == "coup_sol":
		hauteur = _hauteur_du_saut(lecteur.current_animation_position)
	visuel.position.y = hauteur_visuel + hauteur
	collision.position.y = hauteur_collision
	if etat in ["preparation_salve", "salve"] and main_gauche >= 0 and main_droite >= 0:
		var gauche := squelette.get_bone_global_pose(main_gauche).origin
		var droite := squelette.get_bone_global_pose(main_droite).origin
		boss.orbe.global_position = squelette.to_global((gauche + droite) * 0.5) + boss.global_basis.z * 0.2

func _positionner(debut: float, fin: float, duree: float) -> void:
	# Étaler chaque portion du clip sur la durée réglée dans l'Inspector du boss.
	var progression := 1.0 - clampf(boss.temps_etat / maxf(duree, 0.01), 0.0, 1.0)
	lecteur.seek(lerpf(debut, fin, progression), true)

func _hauteur_du_saut(instant: float) -> float:
	if instant <= instant_decollage or instant >= instant_impact:
		return 0.0
	# Une montée et une descente arrondies, avec la réception exactement à l'impact.
	if instant < instant_sommet:
		var progression := (instant - instant_decollage) / maxf(instant_sommet - instant_decollage, 0.01)
		return hauteur_saut * sin(progression * PI * 0.5)
	var progression := (instant - instant_sommet) / maxf(instant_impact - instant_sommet, 0.01)
	return hauteur_saut * cos(progression * PI * 0.5)
