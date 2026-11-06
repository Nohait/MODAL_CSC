extends CanvasLayer

@export_range(0.1, 1.0, 0.05) var duree_noir := 0.3
@export_range(2.0, 6.0, 0.1) var duree_titre := 3.4
@export_range(0.1, 1.0, 0.05) var duree_retour := 0.4
@onready var menu: Control = $Menu
@onready var voile: ColorRect = $Menu/Voile
@onready var panneau: Control = $Menu/Centre/Panneau
@onready var vue: SubViewport = %Vue
@onready var escalier: Node3D = %Escalier
@onready var radio: AudioStreamPlayer = $Radio
func _ready() -> void:
	menu.hide()

func masquer(rapide: bool = false) -> void:
	# Le RoomManager a déjà gelé le combat ; ce menu ne met pas l'arbre en pause.
	# La physique doit continuer pour préparer la navigation sous le voile noir.
	menu.show()
	panneau.modulate.a = 0.0
	voile.color.a = 0.0
	var fondu := create_tween()
	fondu.tween_property(voile, "color:a", 1.0, 0.12 if rapide else duree_noir)
	await fondu.finished # Le RoomManager peut maintenant masquer l'ancienne salle.


func reveler(etage_securise: int) -> void:
	%Titre.text = "%s étage sécurisé" % ("1er" if etage_securise == 1 else "%de" % etage_securise)
	%Note.text = "Progression vers le %de étage" % (etage_securise + 1)
	vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	escalier.commencer(duree_titre)
	radio.volume_db = -40.0
	radio.play()
	var entree := create_tween().set_parallel(true)
	entree.tween_property(panneau, "modulate:a", 1.0, 0.2)
	entree.tween_property(radio, "volume_db", -15.0, 0.2)
	await entree.finished
	var attente := create_tween()
	attente.tween_interval(duree_titre - 0.2)
	await attente.finished
	var sortie := create_tween().set_parallel(true)
	# Le titre s'efface pendant que le voile laisse réapparaître la nouvelle salle.
	sortie.tween_property(panneau, "modulate:a", 0.0, duree_retour)
	sortie.tween_property(voile, "color:a", 0.0, duree_retour)
	sortie.tween_property(radio, "volume_db", -40.0, duree_retour)
	await sortie.finished
	radio.stop()
	escalier.arreter()
	vue.render_target_update_mode = SubViewport.UPDATE_DISABLED
	menu.hide()
	# À cet instant seulement, le RoomManager rend le contrôle et lance le timer.

func reveler_salle() -> void:
	# Transition courte entre deux salles ; seul le changement d’étage affiche un titre.
	panneau.modulate.a = 0.0
	var fondu := create_tween()
	fondu.tween_property(voile, "color:a", 0.0, 0.16)
	await fondu.finished
	menu.hide()
