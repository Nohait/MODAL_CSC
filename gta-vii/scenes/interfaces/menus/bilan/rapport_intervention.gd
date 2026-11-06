extends "res://scenes/interfaces/menus/navigation_menus.gd"

const ICONE_VICTIMES = "res://assets/textures/interfaces/ameliorations/icone_victimes.svg"
const ICONE_VIE = "res://assets/textures/interfaces/hud/icone_vie.svg"
const ICONE_PIECE = "res://assets/textures/interfaces/hud/icone_piece.svg"
const ICONE_COMBAT = "res://assets/textures/interfaces/ameliorations/pictogrammes/pression.svg"
const ICONE_TEMPS = "res://assets/textures/interfaces/ameliorations/pictogrammes/recharge.svg"
const POLICE_CHIFFRES = preload("res://assets/fonts/rubik/accent.tres")
const ICONE_CLAIRE = preload("res://scenes/modes/zombie/interfaces/fin/icone_bilan.gdshader")
var lignes: Array = []
var records: Dictionary = {}
var ids_records: Array = []
var bilan: Dictionary
var animation: Tween
var horloge := 0.0
var fonds_records: Array[TextureRect] = []
@onready var papier: TextureRect = $Panneau/Papier

func _ready() -> void:
	super._ready()
	preparer_bilan()
	papier.material = papier.material.duplicate()
	animation = create_tween().set_parallel(true)
	for i in range(lignes.size()): _creer_statistique(lignes[i], i)
	preload("res://scenes/interfaces/menus/transition_panneau.gd").ouvrir(self, self, $Panneau)

func _creer_statistique(ligne: Dictionary, indice: int) -> void:
	var bloc := PanelContainer.new()
	bloc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0.062745, 0.062745, 0.062745, 0.82)
	fond.set_border_width_all(1)
	fond.set_corner_radius_all(5)
	fond.shadow_size = 3
	fond.shadow_color = Color(0, 0, 0, 0.25)
	fond.border_color = Color(0.337255, 0.337255, 0.337255, 0.6)
	fond.content_margin_left = 16
	fond.content_margin_right = 16
	fond.content_margin_top = 12
	fond.content_margin_bottom = 12
	bloc.add_theme_stylebox_override("panel", fond)
	%Grille.add_child(bloc)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 2)
	bloc.add_child(colonne)
	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 8)
	colonne.add_child(entete)
	var icone := TextureRect.new()
	icone.texture = load(ligne.icone)
	icone.custom_minimum_size = Vector2(24, 24)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ligne.icone in [ICONE_COMBAT, ICONE_TEMPS]:
		var materiau := ShaderMaterial.new()
		materiau.shader = ICONE_CLAIRE
		icone.material = materiau
	entete.add_child(icone)
	var titre := Label.new()
	titre.text = ligne.titre
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titre.add_theme_font_size_override("font_size", 20)
	entete.add_child(titre)
	var valeur := Label.new()
	valeur.add_theme_font_override("font", POLICE_CHIFFRES)
	valeur.add_theme_font_size_override("font_size", 38)
	colonne.add_child(valeur)
	var record := Label.new()
	record.add_theme_font_size_override("font_size", 15)
	record.add_theme_color_override("font_color", Color("bdbdbd"))
	colonne.add_child(record)
	var id: String = ligne.id
	if id in ids_records:
		var nouveau: bool = id in bilan.get("nouveaux_records", [])
		record.text = "NOUVEAU RECORD" if nouveau else "Meilleur : %s" % _formater_valeur(records.get(id, 0.0), id)
		if nouveau:
			fond.bg_color = Color.TRANSPARENT
			record.add_theme_color_override("font_color", Color("008e5e"))
			var plaque := TextureRect.new()
			plaque.texture = preload("res://assets/textures/interfaces/titre/plaque_bouton.svg")
			plaque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
			plaque.show_behind_parent = true
			bloc.add_child(plaque)
			plaque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scenes/interfaces/menus/titre/bouton_menu.gdshader")
			mat.set_shader_parameter("survol", 0.5)
			mat.set_shader_parameter("plastique", preload("res://assets/textures/interfaces/matieres/plastic_001/plastic_001_color.jpg"))
			plaque.material = mat
			fonds_records.append(plaque)
	elif ligne.has("note"): record.text = ligne.note
	elif id == "victimes_perdues": record.text = "Captives, escorte et camion"
	elif id in ["victimes_abritees", "victimes_escorte"]: record.text = "Encore en vie à la fin"
	elif id == "degats_recus": record.text = "Après les boucliers"
	# Les blocs apparaissent en décalage, les nombres montent sans bloquer les boutons.
	bloc.modulate.a = 0.0
	animation.tween_property(bloc, "modulate:a", 1.0, 0.25).set_delay(indice * 0.04)
	animation.tween_method(_animer_valeur.bind(valeur, id), 0.0, float(bilan.get(id, 0)), 0.65).set_delay(indice * 0.04)

func _animer_valeur(nombre: float, libelle: Label, id: String) -> void:
	libelle.text = _formater_valeur(nombre, id)

func _formater_valeur(nombre: float, id: String) -> String:
	return _formater_duree(nombre) if id == "temps" else str(roundi(nombre))

func _process(delta: float) -> void:
	%Grille.columns = 4 if %Grille.size.x >= 1150.0 else 3 if %Grille.size.x >= 800.0 else 2
	horloge += delta
	for plaque in fonds_records:
		# Le fond couvre le bloc entier, sans reprendre les marges du texte.
		plaque.position = Vector2.ZERO
		plaque.size = plaque.get_parent().size
		plaque.material.set_shader_parameter("taille", plaque.size)
	papier.material.set_shader_parameter("horloge", horloge)
	papier.material.set_shader_parameter("taille", papier.size)

func preparer_bilan() -> void:
	pass

func _formater_duree(secondes: float) -> String:
	var total := maxi(0, int(secondes))
	if total >= 3600: return "%d h %02d min %02d s" % [total / 3600, (total / 60) % 60, total % 60]
	return "%d min %02d s" % [total / 60, total % 60]
