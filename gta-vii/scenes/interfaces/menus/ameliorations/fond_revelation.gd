extends ColorRect

const PALETTE = preload("res://scenes/interfaces/menus/boutique/catalogue_boutique.gd")
const RARETES = preload("res://scenes/systemes/ameliorations/tirage_ameliorations.gd").RARETES
var horloge := 0.0
var arrivee := 0.0
var eclat := 0.0
var teinte := Color("b8a897")
var rarete_revelee := -1
var animation_arrivee: Tween
var animation_eclat: Tween
var animation_teinte: Tween

func preparer() -> void:
	horloge = 0.0
	arrivee = 0.0
	eclat = 0.0
	# Commencer neutre : ni le booster ni une carte encore cachée ne dévoilent la couleur.
	teinte = Color("b8a897")
	rarete_revelee = -1
	material.set_shader_parameter("teinte", teinte)
	material.set_shader_parameter("teinte_eclat", teinte)
	material.set_shader_parameter("puissance", 0.0)
	material.set_shader_parameter("eclat", 0.0)
	material.set_shader_parameter("arrivee", 0.0)
	if animation_arrivee:
		animation_arrivee.kill()
	if animation_eclat:
		animation_eclat.kill()
	if animation_teinte:
		animation_teinte.kill()
	show()
	# Le fond se déploie doucement pendant que les dos attendent leur révélation.
	animation_arrivee = create_tween()
	animation_arrivee.tween_property(self, "arrivee", 1.0, 0.6).set_ease(Tween.EASE_OUT)

func accentuer(rarete: StringName) -> void:
	var puissance := maxi(0, RARETES.find(rarete))
	if puissance > rarete_revelee:
		rarete_revelee = puissance
		var nouvelle_teinte: Color = PALETTE.COULEURS.get(rarete, Color("e4b56d"))
		material.set_shader_parameter("teinte_eclat", nouvelle_teinte)
		if animation_teinte:
			animation_teinte.kill()
		# Le signal arrive quand la face est dévoilée ; la couleur monte seulement alors.
		animation_teinte = create_tween()
		animation_teinte.tween_property(self, "teinte", nouvelle_teinte, 0.3)
	if animation_eclat:
		animation_eclat.kill()
	# Renforcer le halo derrière les cartes, puis le laisser retomber sans flash blanc.
	animation_eclat = create_tween()
	animation_eclat.tween_property(self, "eclat", 0.2 + puissance * 0.2, 0.12)
	animation_eclat.tween_property(self, "eclat", 0.0, 0.65 + puissance * 0.1)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	horloge += delta
	material.set_shader_parameter("horloge", horloge)
	material.set_shader_parameter("arrivee", arrivee)
	material.set_shader_parameter("eclat", eclat)
	material.set_shader_parameter("taille", size)
	material.set_shader_parameter("teinte", teinte)
	material.set_shader_parameter("puissance", maxf(0.0, rarete_revelee))
