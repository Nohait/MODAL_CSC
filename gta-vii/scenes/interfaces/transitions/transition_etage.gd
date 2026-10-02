extends CanvasLayer

@export_range(0.1, 1.0, 0.05) var duree_noir := 0.3
@export_range(0.2, 2.0, 0.05) var duree_titre := 0.75
@export_range(0.1, 1.0, 0.05) var duree_retour := 0.4
@onready var menu: Control = $Menu
@onready var voile: ColorRect = $Menu/Voile
@onready var panneau: Control = $Menu/Centre/Panneau
@onready var papier: TextureRect = $Menu/Centre/Panneau/Papier
var horloge := 0.0


func _ready() -> void:
	papier.material = papier.material.duplicate()
	menu.hide()


func _process(delta: float) -> void:
	if not menu.visible:
		return
	horloge += delta
	papier.material.set_shader_parameter("horloge", horloge)
	papier.material.set_shader_parameter("taille", papier.size)


func masquer() -> void:
	# Le RoomManager a déjà gelé le combat ; ce menu ne met pas l'arbre en pause.
	# La physique doit continuer pour préparer la navigation sous le voile noir.
	menu.show()
	panneau.modulate.a = 0.0
	voile.color.a = 0.0
	var fondu := create_tween()
	fondu.tween_property(voile, "color:a", 1.0, duree_noir)
	await fondu.finished # Le RoomManager peut maintenant masquer l'ancienne salle.


func reveler(numero: int) -> void:
	%Titre.text = "Étage %d" % numero
	panneau.pivot_offset = panneau.size / 2.0
	panneau.scale = Vector2.ONE * 0.96
	var entree := create_tween().set_parallel(true)
	# Fondu et petit agrandissement se jouent ensemble, sur le noir complet.
	entree.tween_property(panneau, "modulate:a", 1.0, 0.2)
	entree.tween_property(panneau, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await entree.finished
	var attente := create_tween()
	attente.tween_interval(duree_titre)
	await attente.finished
	var sortie := create_tween().set_parallel(true)
	# Le titre s'efface pendant que le voile laisse réapparaître la nouvelle salle.
	sortie.tween_property(panneau, "modulate:a", 0.0, duree_retour)
	sortie.tween_property(voile, "color:a", 0.0, duree_retour)
	await sortie.finished
	menu.hide()
	# À cet instant seulement, le RoomManager rend le contrôle et lance le timer.
