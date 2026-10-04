@tool
extends ProgressBar

@export var titre := "VIE"
@export var couleur := Color(0.65, 0.16, 0.14):
	set(nouvelle_couleur):
		couleur = nouvelle_couleur
		if is_node_ready():
			remplissage.material.set_shader_parameter("teinte", couleur)
@export var pictogramme: Texture2D

@onready var cadre: TextureRect = $Cadre
@onready var remplissage: TextureRect = $Remplissage
@onready var texte_valeur: Label = $Valeur
var animation_degats: Tween
var bouclier := 0.0
var couche_bouclier: TextureRect

func _ready() -> void:
	# Chaque jauge a son matériau : rougir la vie ne doit pas rougir la mousse.
	remplissage.material = remplissage.material.duplicate()
	$Titre.text = titre
	$Icone.texture = pictogramme
	value_changed.connect(actualiser_valeur)
	changed.connect(actualiser_valeur)
	actualiser_valeur()

func actualiser_valeur(_nouvelle_valeur: float = 0.0) -> void:
	var proportion := clampf((value - min_value) / maxf(max_value - min_value, 0.001), 0.0, 1.0)
	remplissage.material.set_shader_parameter("proportion", proportion)
	remplissage.material.set_shader_parameter("teinte", couleur)
	texte_valeur.text = "%d / %d" % [ceili(value), ceili(max_value)]
	if bouclier > 0.0:
		texte_valeur.text += " (+%d)" % ceili(bouclier)
	if is_instance_valid(couche_bouclier):
		# 40 PV de bouclier couvrent 40 % d'une barre de 100 PV, même à vie réduite.
		couche_bouclier.material.set_shader_parameter("proportion", clampf(bouclier / maxf(max_value, 1.0), 0.0, 1.0))
		couche_bouclier.visible = bouclier > 0.0

func afficher_recharge(active: bool) -> void:
	remplissage.material.set_shader_parameter("recharge", active)

func reagir_aux_degats(_degats: float) -> void:
	if animation_degats:
		animation_degats.kill()
	cadre.self_modulate = Color(1.4, 0.75, 0.65)
	animation_degats = create_tween().set_parallel(true)
	# Le cadre retrouve sa couleur pendant que le reflet rouge s'atténue.
	animation_degats.tween_property(cadre, "self_modulate", Color.WHITE, 0.4)
	animation_degats.tween_method(_regler_impact, 1.0, 0.0, 0.4)

func _regler_impact(intensite: float) -> void:
	remplissage.material.set_shader_parameter("impact", intensite)

func afficher_bouclier(reserve: float) -> void:
	bouclier = maxf(0.0, reserve)
	if couche_bouclier == null and bouclier > 0.0:
		# Dupliquer seulement le remplissage garde exactement sa position et son relief.
		couche_bouclier = remplissage.duplicate()
		couche_bouclier.name = "CoucheBouclier"
		couche_bouclier.material = remplissage.material.duplicate()
		couche_bouclier.material.set_shader_parameter("teinte", Color("59bde8"))
		couche_bouclier.material.set_shader_parameter("impact", 0.0)
		couche_bouclier.material.set_shader_parameter("recharge", false)
		add_child(couche_bouclier)
		move_child(couche_bouclier, remplissage.get_index() + 1)
		# L'espace réservé au nombre accueille aussi les PV de protection.
		texte_valeur.offset_left = -190.0
	actualiser_valeur()
