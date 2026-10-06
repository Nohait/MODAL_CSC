extends Control

# Interface réutilisée en jeu. F6 conserve un mode de démonstration indépendant.
signal achat_demande(rarete: StringName)
signal defi_demande(identifiant: StringName)
signal catalogue_debug_demande
signal continuer_demande
signal recharge_murale_demandee
signal sprinkler_demande(sprinkler: Node3D)
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
var colonne_offres: VBoxContainer
var compteur_pieces: Label
var recharge_murale: Button
var description_recharge: Label
var prix_recharge: Label
var entete_monnaies: HBoxContainer
var tuiles_sprinklers: Array[Dictionary] = []
var choix_sprinklers: Window
var categorie_sprinklers: Button


func _ready() -> void:
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Garder une bordure brûlée de la même épaisseur lorsque la fenêtre change.
	$Fond.resized.connect(_ajuster_parchemin)
	_ajuster_parchemin()
	var bloc_points := VBoxContainer.new()
	bloc_points.add_theme_constant_override("separation", 4)
	contenu.add_child(bloc_points)
	var entete := HBoxContainer.new()
	entete_monnaies = entete
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
	colonne_offres = gauche
	gauche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gauche.size_flags_stretch_ratio = 1.6
	gauche.add_theme_constant_override("separation", 18)
	colonnes.add_child(gauche)
	var renforts := _panneau(gauche, "BONUS PERMANENTS")
	var pochettes := HBoxContainer.new()
	pochettes.alignment = BoxContainer.ALIGNMENT_CENTER
	pochettes.add_theme_constant_override("separation", 12)
	renforts.add_child(pochettes)
	var propositions: Array[Dictionary] = [
		{"id": &"commun", "titre": "Commun", "couleur": Color("c6ac86"), "prix": 1, "puissance": puissance_commune, "symbole": "I"},
		{"id": &"rare", "titre": "Rare", "couleur": Color("569ccb"), "prix": 2, "puissance": puissance_rare, "symbole": "II"},
		{"id": &"epique", "titre": "Épique", "couleur": Color("af77c8"), "prix": 3, "puissance": puissance_epique, "symbole": "III"},
		{"id": &"legendaire", "titre": "Légendaire", "couleur": Color("efc35b"), "prix": 5, "puissance": 200.0, "symbole": "IV", "contenu": "3 choix · surtout légendaires"}
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
	emplacement.custom_minimum_size = Vector2(125, 195)
	parent.add_child(emplacement)
	var booster = BOOSTER.instantiate()
	booster.titre = proposition.titre
	booster.couleur = proposition.couleur
	booster.prix = proposition.prix
	booster.contenu = proposition.get("contenu", "3 choix · puissance %d %%" % proposition.puissance)
	booster.symbole = proposition.symbole
	booster.niveau_eclat = [&"commun", &"rare", &"epique", &"legendaire"].find(proposition.id)
	booster.niveau_eclat = maxi(booster.niveau_eclat, 0)
	booster.scale = Vector2.ONE * (125.0 / 270.0)
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
		var verrouille: bool = booster.get_meta("verrouille", false)
		booster.modulate.a = 0.55 if booster.prix > points_demo or verrouille else 1.0
		booster.tooltip_text = "Aucune légendaire disponible : obtenez ses prérequis ou relancez une partie." if verrouille else ("Points insuffisants" if booster.prix > points_demo else "")

func actualiser_legendaire(disponible: bool) -> void:
	for booster in boosters:
		if booster.get_meta("rarete") == &"legendaire": booster.set_meta("verrouille", not disponible)
	_actualiser_budget()


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
		booster.hide()
		await ouverture.ouvrir(booster)
		booster.show()
		return


func ajouter_ravitaillement() -> void:
	# Réunir les boosters en haut laisse la place aux achats en pièces.
	for bouton in contenu.get_children():
		if bouton is Button:
			bouton.custom_minimum_size.y = 44
	var ligne: Container = boosters[0].get_parent().get_parent()
	var temporaires: Container = boosters.back().get_parent().get_parent()
	var panneau_temporaire := temporaires.get_parent().get_parent()
	for booster in boosters:
		var emplacement := booster.get_parent()
		if emplacement.get_parent() != ligne: emplacement.reparent(ligne)
	if temporaires != ligne:
		colonne_offres.remove_child(panneau_temporaire)
		panneau_temporaire.queue_free()
	ligne.get_parent().get_child(0).text = "AMÉLIORATIONS · POINTS"
	var equipement := _panneau(colonne_offres, "ÉQUIPEMENT & RAVITAILLEMENT")
	var budget := HBoxContainer.new()
	budget.add_theme_constant_override("separation", 10)
	var separation := Control.new()
	separation.custom_minimum_size.x = 20
	entete_monnaies.add_child(separation)
	entete_monnaies.add_child(budget)
	var piece := TextureRect.new()
	piece.texture = preload("res://assets/textures/interfaces/hud/icone_piece.svg")
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	piece.custom_minimum_size = Vector2(28, 28)
	budget.add_child(piece)
	compteur_pieces = _texte("0 PIÈCE", 23)
	budget.add_child(compteur_pieces)
	var offres := HBoxContainer.new()
	equipement.add_child(offres)
	recharge_murale = Button.new()
	recharge_murale.custom_minimum_size = Vector2(180, 250)
	recharge_murale.pressed.connect(func(): recharge_murale_demandee.emit())
	offres.add_child(recharge_murale)
	# La tuile reste un seul bouton : ses enfants ne capturent pas les clics.
	for etat in ["normal", "hover", "pressed", "focus", "disabled"]:
		var cadre := StyleBoxFlat.new()
		cadre.bg_color = Color("bea17c") if etat == "normal" or etat == "disabled" else Color("d6bc93")
		cadre.border_color = Color("614635")
		cadre.set_border_width_all(2)
		cadre.set_corner_radius_all(6)
		recharge_murale.add_theme_stylebox_override(etat, cadre)
	var details := VBoxContainer.new()
	details.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	details.offset_left = 12
	details.offset_right = -12
	details.offset_top = 8
	details.offset_bottom = -8
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recharge_murale.add_child(details)
	var image := TextureRect.new()
	image.texture = preload("res://assets/textures/interfaces/boutique/extincteur_mural.svg")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(image)
	description_recharge = _texte("Recharger\nl’extincteur mural", 17)
	description_recharge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_recharge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(description_recharge)
	prix_recharge = _texte("", 16)
	prix_recharge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prix_recharge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prix_recharge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(prix_recharge)

func actualiser_ravitaillement(solde: int, disponible: bool, prix: int, present: bool) -> void:
	compteur_pieces.text = "%d PIÈCE%s" % [solde, "S" if solde != 1 else ""]
	# Une salle classique peut ne pas proposer d'extincteur mural.
	recharge_murale.visible = present
	recharge_murale.disabled = not present or disponible or solde < prix
	recharge_murale.modulate.a = 0.55 if recharge_murale.disabled else 1.0
	prix_recharge.text = "%d pièces" % prix
	if not present: prix_recharge.text = "Indisponible"
	elif disponible: prix_recharge.text = "Déjà prêt"
	elif solde < prix: prix_recharge.text += " · Fonds insuffisants"
	recharge_murale.tooltip_text = "Recharger l’extincteur mural pour pouvoir y refaire un plein de mousse."

func ajouter_sprinklers(sprinklers: Array[Node3D]) -> void:
	categorie_sprinklers = recharge_murale.duplicate(0)
	categorie_sprinklers.name = "CategorieSprinklers"
	categorie_sprinklers.disabled = false
	categorie_sprinklers.modulate.a = 1.0
	recharge_murale.get_parent().add_child(categorie_sprinklers)
	var illustration := categorie_sprinklers.get_child(0)
	illustration.get_child(0).texture = preload("res://assets/textures/interfaces/boutique/sprinkler.svg")
	illustration.get_child(1).text = "Sprinklers"
	illustration.get_child(2).text = "Choisir un\nemplacement"
	categorie_sprinklers.pressed.connect(_ouvrir_sprinklers)
	# Une fenêtre exclusive garde les clics et le retour manette dans ce sous-menu.
	choix_sprinklers = Window.new()
	choix_sprinklers.title = "Sprinklers"
	choix_sprinklers.size = Vector2i(900, 400)
	choix_sprinklers.transient = true
	choix_sprinklers.exclusive = true
	choix_sprinklers.borderless = true
	add_child(choix_sprinklers)
	choix_sprinklers.hide()
	choix_sprinklers.close_requested.connect(_fermer_sprinklers)
	choix_sprinklers.window_input.connect(_input_sprinklers)
	var racine := Control.new()
	racine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choix_sprinklers.add_child(racine)
	var contenu := _panneau(racine, "CHOISIR UN SPRINKLER")
	contenu.get_parent().set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var offres := HBoxContainer.new()
	offres.add_theme_constant_override("separation", 14)
	contenu.add_child(offres)
	# Chaque tuile conserve sa propre référence ; acheter l'une n'arme pas les autres.
	for sprinkler in sprinklers:
		var bouton: Button = recharge_murale.duplicate(0)
		bouton.name = "Activer" + sprinkler.name
		offres.add_child(bouton)
		var details := bouton.get_child(0)
		details.get_child(0).texture = preload("res://assets/textures/interfaces/boutique/sprinkler.svg")
		details.get_child(1).text = "Armer le sprinkler\n" + sprinkler.emplacement
		details.get_child(1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bouton.pressed.connect(func(): sprinkler_demande.emit(sprinkler))
		bouton.tooltip_text = "Le prochain ennemi dans sa zone déclenche un jet d’eau qui inflige des dégâts."
		tuiles_sprinklers.append({"objet": sprinkler, "bouton": bouton, "prix": details.get_child(2)})
	var bloc := VBoxContainer.new()
	bloc.custom_minimum_size = Vector2(220, 250)
	offres.add_child(bloc)
	var legende := _texte("Emplacement", 18)
	legende.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bloc.add_child(legende)
	var plan := preload("res://scenes/modes/zombie/interfaces/boutique/apercu_sprinklers.gd").new()
	plan.size_flags_vertical = Control.SIZE_EXPAND_FILL
	plan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloc.add_child(plan)
	for tuile in tuiles_sprinklers:
		tuile.bouton.mouse_entered.connect(plan.montrer.bind(tuile.objet))
		tuile.bouton.mouse_exited.connect(plan.montrer.bind(null))
		tuile.bouton.focus_entered.connect(plan.montrer.bind(tuile.objet))
		tuile.bouton.focus_exited.connect(plan.montrer.bind(null))
	var fermer = BOUTON.instantiate()
	fermer.taille_minimale = Vector2(300, 44)
	fermer.taille_police = 18
	fermer.text = "Retour à la boutique"
	fermer.pressed.connect(_fermer_sprinklers)
	contenu.add_child(fermer)
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(racine)

func _ouvrir_sprinklers() -> void:
	choix_sprinklers.popup_centered()

func _fermer_sprinklers() -> void:
	choix_sprinklers.hide()
	if not Input.get_connected_joypads().is_empty(): categorie_sprinklers.grab_focus()

func _input_sprinklers(event: InputEvent) -> void:
	if not event.is_echo() and event.is_action_pressed("ui_cancel"):
		choix_sprinklers.set_input_as_handled()
		_fermer_sprinklers()

func _notification(what: int) -> void:
	# Le sous-menu doit aussi disparaître si la boutique se ferme par une autre commande.
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		if is_instance_valid(choix_sprinklers): choix_sprinklers.hide()

func actualiser_sprinklers(solde: int) -> void:
	for tuile in tuiles_sprinklers:
		var objet = tuile.objet
		if not is_instance_valid(objet):
			tuile.bouton.hide()
			continue
		var actif: bool = objet.temps_restant > 0.0
		tuile.bouton.disabled = objet.arme or actif or solde < objet.prix_activation
		tuile.bouton.modulate.a = 0.55 if tuile.bouton.disabled else 1.0
		tuile.prix.text = "%d pièces" % objet.prix_activation
		if actif: tuile.prix.text = "En cours"
		elif objet.arme: tuile.prix.text = "Déjà armé"
		elif solde < objet.prix_activation: tuile.prix.text += " · Fonds insuffisants"
