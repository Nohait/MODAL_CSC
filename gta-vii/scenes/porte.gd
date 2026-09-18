extends Node3D

# Le passage attend la fin du mouvement, pas seulement le début de l'ouverture.
signal ouverte

@export_group("Ouverture")
## Angle autour de Y : le signe choisit le côté d'ouverture.
@export_range(-180.0, 180.0, 1.0) var angle_ouverture: float = -175.0
## Une durée courte donne l'impression que le battant est poussé violemment.
@export_range(0.1, 2.0, 0.05) var duree_ouverture: float = 0.25
## Petit retour après le choc, en degrés.
@export_range(0.0, 15.0, 0.5) var angle_rebond: float = 5.0

@onready var charniere: Node3D = $Charniere
@onready var voyant: MeshInstance3D = $Voyant
var ouverture_declenchee := false
var materiau_voyant: StandardMaterial3D


func _ready() -> void:
	# Chaque porte a son matériau : ouvrir l'une ne doit pas verdir les autres.
	materiau_voyant = voyant.get_active_material(0).duplicate() as StandardMaterial3D
	voyant.material_override = materiau_voyant


func ouvrir() -> void:
	# Cette fonction reçoit le signal room_cleared. Un second appel est sans effet.
	if ouverture_declenchee:
		return
	ouverture_declenchee = true
	materiau_voyant.albedo_color = Color(0.15, 1.0, 0.35)
	materiau_voyant.emission = Color(0.15, 1.0, 0.35)


	# La charnière est au bord du battant : ses enfants tournent autour de ce bord.
	# rotation_degrees permet de travailler directement en degrés, autour de Y.
	var angle_depart := charniere.rotation_degrees.y
	var angle_final := angle_depart + angle_ouverture
	# Revenir vers la fermeture quel que soit le signe de l'ouverture.
	var angle_retour := angle_final - signf(angle_ouverture) * angle_rebond
	var animation := create_tween()
	# Faire avancer l'animation au rythme de la physique pour la collision mobile.
	animation.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	# Mouvement rapide jusqu'au mur : le choc est simulé par ces angles, pas calculé.
	animation.tween_property(charniere, "rotation_degrees:y", angle_final, duree_ouverture)
	# Petit rebond qui ralentit, puis retour plus doux contre le mur.
	animation.tween_property(charniere, "rotation_degrees:y", angle_retour, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(charniere, "rotation_degrees:y", angle_final, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	animation.tween_callback(func(): ouverte.emit())
