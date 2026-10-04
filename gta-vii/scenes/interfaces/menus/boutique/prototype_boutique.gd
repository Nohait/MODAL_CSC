extends Control

# Interface réutilisée en jeu. F6 conserve un mode de démonstration indépendant.
signal achat_demande(rarete: StringName)
signal defi_demande(identifiant: StringName)
signal catalogue_debug_demande
signal continuer_demande
signal bonus_demandes

const BOUTON = preload("res://scenes/interfaces/menus/titre/bouton_menu.tscn")
const OUVERTURE = preload("res://scenes/interfaces/menus/ouverture_booster.tscn")
const BOOSTER = preload("res://scenes/interfaces/menus/boutique/booster_apercu.tscn")
const DEFI = preload("res://scenes/interfaces/menus/boutique/ligne_defi_apercu.gd")
const ICONE = preload("res://assets/textures/interfaces/ameliorations/icone_victimes.svg")
const POLICE = preload("res://assets/fonts/Almendra-Bold.ttf")
const POLICE_ITALIQUE = preload("res://assets/fonts/Almendra-BoldItalic.ttf")

@export_group("Aperçu — raretés")
# Pourcentage du bonus de base, et non un ajout direct de 50 % aux dégâts.
@export_range(0, 300, 10) var puissance_commune := 50.0
@export_range(0, 300, 10) var puissance_rare := 100.0
@export_range(0, 300, 10) var puissance_epique := 200.0
@export var points_demo := 3
@export var mode_demonstration := true
# Fourni par l’UpgradeManager avant l’ajout à l’arbre, dans la vraie boutique.
var catalogue: Array[Dictionary] = []
var bouton_gratuit: Button

@onready var contenu: VBoxContainer = $Marge/Contenu
var compteur: Label
var retour: Label
var actifs: VBoxContainer
var proposes: VBoxContainer
var vide: Label
var boosters: Array[Control] = []
var ouverture: Control
var panneau_defis: Control


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Garder une bordure brûlée de la même épaisseur lorsque la fenêtre change.
	$Fond.resized.connect(_ajuster_parchemin)
	_ajuster_parchemin()
	var bloc_points := VBoxContainer.new()
	bloc_points.add_theme_constant_override("separation", 4)
	contenu.add_child(bloc_points)
	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 12)
	bloc_points.add_child(entete)
	var icone := TextureRect.new()
	icone.texture = ICONE
	icone.modulate = Color("483525")
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.custom_minimum_size = Vector2(30, 30)
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	entete.add_child(icone)
	compteur = _texte("", 24)
	entete.add_child(compteur)
	var note := _texte("Chaque victime vivante dans votre escorte vous rapporte un point.", 16)
	note.add_theme_font_override("font", POLICE_ITALIQUE)
	bloc_points.add_child(note)
	var titre := _texte("La relève", 42)
	titre.add_theme_font_override("font", POLICE)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenu.add_child(titre)

	# Le défilement garde tous les boutons accessibles dans une fenêtre plus petite.
	var defilement := ScrollContainer.new()
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	contenu.add_child(defilement)
	var colonnes := HBoxContainer.new()
	colonnes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colonnes.add_theme_constant_override("separation", 24)
	defilement.add_child(colonnes)
	var gauche := VBoxContainer.new()
	gauche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gauche.size_flags_stretch_ratio = 1.6
	gauche.add_theme_constant_override("separation", 18)
	colonnes.add_child(gauche)
	var renforts := _panneau(gauche, "BONUS PERMANENTS")
	var pochettes := HBoxContainer.new()
	pochettes.alignment = BoxContainer.ALIGNMENT_CENTER
	pochettes.add_theme_constant_override("separation", 22)
	renforts.add_child(pochettes)
	var propositions: Array[Dictionary] = [
		{"id": &"commun", "titre": "Commun", "couleur": Color("c6ac86"), "prix": 1, "puissance": puissance_commune, "symbole": "I"},
		{"id": &"rare", "titre": "Rare", "couleur": Color("569ccb"), "prix": 2, "puissance": puissance_rare, "symbole": "II"},
		{"id": &"epique", "titre": "Épique", "couleur": Color("af77c8"), "prix": 3, "puissance": puissance_epique, "symbole": "III"}
	]
	if not catalogue.is_empty():
		propositions = catalogue
	for proposition in propositions:
		if proposition.get("categorie", "permanent") == "permanent":
			_ajouter_booster(pochettes, proposition)
	bouton_gratuit = Button.new()
	bouton_gratuit.text = "Ouvrir le booster rare offert"
	bouton_gratuit.focus_mode = Control.FOCUS_NONE
	bouton_gratuit.hide()
	bouton_gratuit.pressed.connect(func(): achat_demande.emit(&"rare_gratuit"))
	renforts.add_child(bouton_gratuit)
	var temporaires := _panneau(gauche, "SOINS ET BONUS TEMPORAIRES")
	var interventions := HBoxContainer.new()
	interventions.alignment = BoxContainer.ALIGNMENT_CENTER
	temporaires.add_child(interventions)
	for proposition in propositions:
		if proposition.get("categorie", "permanent") == "temporaire":
			_ajouter_booster(interventions, proposition)
	if interventions.get_child_count() == 0:
		_ajouter_booster(interventions, {"id": &"temporaire", "titre": "Intervention", "couleur": Color("55b5a5"), "prix": 1, "puissance": 100, "symbole": "+", "contenu": "Soins et protection"})

	var droite := VBoxContainer.new()
	droite.custom_minimum_size.x = 380
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colonnes.add_child(droite)
	panneau_defis = droite
	var paris := _panneau(droite, "Défis et paris", true)
	paris.add_child(_texte("EN COURS", 14))
	actifs = VBoxContainer.new()
	paris.add_child(actifs)
	vide = _texte("Aucun défi en cours.", 15)
	actifs.add_child(vide)
	paris.add_child(HSeparator.new())
	paris.add_child(_texte("PROPOSÉS", 14))
	proposes = VBoxContainer.new()
	proposes.add_theme_constant_override("separation", 12)
	paris.add_child(proposes)
	if mode_demonstration:
		_ajouter_defi("Une vie précieuse", 3, "Une petite victime fragile rejoint votre escorte. Elle rapporte 2 points par salle complétée tant qu'elle reste en vie.")
		_ajouter_defi("Sans une égratignure", 1, "Terminez la prochaine salle sans perdre de vie pour recevoir un booster rare gratuit.")
		_ajouter_defi("Sauvetage sous pression", 0, "La prochaine salle contient davantage d'ennemis mobiles et de victimes à sauver.")
	retour = _texte("APERÇU INTERACTIF — les achats et défis ne modifient pas encore la partie.", 14)
	if not mode_demonstration:
		retour.text = "Les points non dépensés sont perdus en quittant la boutique."
	retour.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenu.add_child(retour)
	if not mode_demonstration:
		var bonus = BOUTON.instantiate()
		bonus.name = "ConsulterBonus"
		bonus.taille_police = 18
		bonus.custom_minimum_size = Vector2(300, 40)
		bonus.text = "Mes bonus et statistiques [B]"
		bonus.focus_mode = Control.FOCUS_NONE
		bonus.pressed.connect(func(): bonus_demandes.emit())
		contenu.add_child(bonus)
		var continuer = BOUTON.instantiate()
		continuer.taille_police = 18
		continuer.custom_minimum_size = Vector2(300, 40)
		continuer.text = "Continuer vers la prochaine salle"
		continuer.focus_mode = Control.FOCUS_NONE
		continuer.custom_minimum_size.y = 40
		continuer.pressed.connect(func(): continuer_demande.emit())
		contenu.add_child(continuer)
	if not mode_demonstration and OS.is_debug_build():
		var debug = BOUTON.instantiate()
		debug.taille_police = 16
		debug.custom_minimum_size = Vector2(300, 40)
		debug.name = "DebugCartes"
		debug.text = "Debug : toutes les cartes du mode"
		debug.focus_mode = Control.FOCUS_NONE
		debug.pressed.connect(func(): catalogue_debug_demande.emit())
		contenu.add_child(debug)
	_actualiser_budget()


func _ajouter_booster(parent: Control, proposition: Dictionary) -> void:
	# Un conteneur réserve la petite taille ; le dessin conserve ses proportions.
	var emplacement := Control.new()
	emplacement.custom_minimum_size = Vector2(135, 210)
	parent.add_child(emplacement)
	var booster = BOOSTER.instantiate()
	booster.titre = proposition.titre
	booster.couleur = proposition.couleur
	booster.prix = proposition.prix
	booster.contenu = proposition.get("contenu", "3 choix · puissance %d %%" % proposition.puissance)
	booster.symbole = proposition.symbole
	booster.scale = Vector2.ONE * 0.5
	booster.selectionne.connect(_selectionner.bind(proposition))
	emplacement.add_child(booster)
	booster.set_meta("rarete", proposition.id)
	boosters.append(booster)


func _ajouter_defi(titre: String, prix: int, description: String) -> void:
	var ligne = DEFI.new()
	ligne.titre = titre
	ligne.prix = prix
	ligne.description = description
	ligne.accepte.connect(_accepter_defi.bind(ligne))
	proposes.add_child(ligne)


func _accepter_defi(ligne: VBoxContainer) -> void:
	if ligne.prix > points_demo or ligne.en_cours:
		return
	points_demo -= ligne.prix
	ligne.reparent(actifs)
	ligne.afficher_progression()
	vide.hide()
	retour.text = "Défi accepté dans l'aperçu : %s. Son effet en jeu reste à intégrer." % ligne.titre
	_actualiser_budget()


func _actualiser_budget() -> void:
	compteur.text = "%d POINT%s" % [points_demo, "S" if points_demo != 1 else ""]
	for ligne in proposes.get_children():
		ligne.actualiser_budget(points_demo)
	for booster in boosters:
		booster.modulate.a = 0.55 if booster.prix > points_demo else 1.0
		booster.tooltip_text = "Points insuffisants" if booster.prix > points_demo else ""


func _selectionner(proposition: Dictionary) -> void:
	if not mode_demonstration:
		achat_demande.emit(proposition.id)
		return
	if points_demo < proposition.prix:
		retour.text = "Il manque %d point(s) pour ce booster." % (proposition.prix - points_demo)
		return
	# Illustration des valeurs actuelles : les mêmes trois améliorations, à puissance différente.
	retour.text = "%s : dégâts +%s %%, réserve +%s %%, recharge +%s %% (aperçu)." % [proposition.titre, str(20 * proposition.puissance / 100.0), str(25 * proposition.puissance / 100.0), str(20 * proposition.puissance / 100.0)]


func _panneau(parent: Control, titre: String, defi: bool = false) -> VBoxContainer:
	var panneau := PanelContainer.new()
	parent.add_child(panneau)
	var style := StyleBoxFlat.new()
	# Les défis sont légèrement plus foncés que les encadrés des boosters.
	style.bg_color = Color("c4ac85") if defi else Color("e0cba4")
	style.border_color = Color("90734f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 16
	panneau.add_theme_stylebox_override("panel", style)
	var boite := VBoxContainer.new()
	boite.add_theme_constant_override("separation", 14)
	panneau.add_child(boite)
	var etiquette := _texte(titre, 26)
	etiquette.add_theme_font_override("font", POLICE)
	boite.add_child(etiquette)
	return boite


func _texte(texte: String, taille: int) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	etiquette.add_theme_font_size_override("font_size", taille)
	etiquette.add_theme_color_override("font_color", Color("3e2d20"))
	return etiquette


func _ajuster_parchemin() -> void:
	$Fond.material.set_shader_parameter("taille", $Fond.size)


func actualiser_boutique(points: int, defis_actifs: Array[Dictionary], offres: Array[Dictionary], cadeaux: int, message: String = "") -> void:
	points_demo = points
	for liste in [actifs, proposes]:
		for ligne in liste.get_children():
			liste.remove_child(ligne)
			ligne.queue_free()
	for defi in defis_actifs:
		_creer_ligne_defi(defi, true)
	for defi in offres:
		_creer_ligne_defi(defi, false)
	if actifs.get_child_count() == 0:
		actifs.add_child(_texte("Aucun défi en cours.", 15))
	bouton_gratuit.visible = cadeaux > 0
	bouton_gratuit.text = "Ouvrir un booster rare offert (%d)" % cadeaux
	_actualiser_budget()
	if not message.is_empty():
		retour.text = message


func _creer_ligne_defi(defi: Dictionary, actif: bool) -> void:
	var ligne = DEFI.new()
	ligne.titre = defi.titre
	ligne.prix = defi.prix
	ligne.description = defi.description
	ligne.objectif = defi.objectif
	ligne.progression = defi.get("progression", 0)
	ligne.accepte.connect(func(): defi_demande.emit(defi.id))
	(actifs if actif else proposes).add_child(ligne)
	if actif:
		ligne.afficher_progression()
		if defi.get("echec", false):
			ligne.entete.text += " · échoué"

func animer_ouverture(rarete: StringName) -> void:
	for booster in boosters:
		if booster.get_meta("rarete") != rarete:
			continue
		if not is_instance_valid(ouverture):
			ouverture = OUVERTURE.instantiate()
			add_child(ouverture)
		# Les copies prennent la place du booster pendant sa déchirure.
		var tween: Tween = ouverture.lancer(booster)
		booster.hide()
		await tween.finished
		booster.show()
		return
