extends CanvasLayer

const BOUTON = preload("res://scenes/interfaces/menus/titre/bouton_menu.tscn")
@onready var menu: Control = $Menu
@onready var panneau: Control = $Menu/Panneau
@onready var papier: TextureRect = $Menu/Panneau/Papier
@onready var contenu: VBoxContainer = %ContenuReglages
@onready var controles: Control = %Controles
@onready var onglet_reglages: Button = %OngletReglages
@onready var onglet_controles: Button = %OngletControles
var curseurs: Dictionary = {}
var page_video: VBoxContainer
var onglet_video: Button
var commandes_video: Dictionary = {}
var plein_ecran: Button
var boutons_profils: Array[Button] = []
var pause_avant := false
var souris_avant: int
var focus_avant: Control
var entrees_suspendues: Array[Dictionary] = []
var animation: Tween
var horloge := 0.0
var boutons_graphite: Array[Button] = []

const AIDE_VIDEO = {
	"resolution_3d": "Résolution interne de la 3D. 50 % calcule quatre fois moins de pixels que 100 %. L'interface reste nette.",
	"distance_details": "Distance depuis la caméra au-delà de laquelle les détails décoratifs sont masqués. 0 signifie illimitée ; 5 m est le réglage le plus léger. Les obstacles restent solides.",
	"seuil_lod": "Utilise plus tôt les modèles simplifiés disponibles dans les assets. Une valeur élevée réduit le nombre de triangles ; elle ne simplifie pas les modèles dépourvus de LOD.",
	"ombres": "Active les ombres des lumières qui en possèdent. Les couper réduit le coût du rendu sans supprimer l'éclairage.",
	"lumieres_decor": "Active les sources de lumière décoratives. Les effets lumineux de combat restent actifs. Désactiver cette option peut fortement assombrir le décor.",
	"lueur": "Halo autour des surfaces lumineuses. Désactiver la lueur réduit le post-traitement, mais ne supprime ni les lumières ni leur brillance sur les matériaux.",
	"reflets_ecran": "SSR : reflets des objets visibles à l'écran, si la scène les utilise. Ne contrôle pas les points brillants produits directement par les lumières.",
	"sondes_reflets": "Reflets du décor capturés par les sondes. Les couper supprime ces captures, mais ne supprime pas la brillance directe des lumières.",
	"brillance_lumieres": "Points et plages brillants produits directement par les lumières sur les sols et les objets. Les couper conserve l'éclairage diffus. Pour retirer aussi les images réfléchies du décor, désactivez SSR et Sondes.",
	"textures_decor": "Remplace les textures et le relief du décor opaque par des matériaux unis. Les textures restent chargées en mémoire : ce réglage allège leur rendu, pas leur chargement."
}

func _ready() -> void:
	menu.hide()
	_creer_titre("AMBIANCE SONORE")
	_creer_curseur("general", "Volume général", 0.0, 100.0, 1.0)
	_creer_curseur("ambiance", "Crépitement des incendies", 0.0, 100.0, 1.0)
	_creer_curseur("effets", "Effets sonores", 0.0, 100.0, 1.0)
	_creer_curseur("musique", "Musique", 0.0, 100.0, 1.0)
	_creer_titre("AFFICHAGE ET VISÉE")
	var ligne := HBoxContainer.new()
	contenu.add_child(ligne)
	ligne.add_child(_libelle("Mode d’affichage"))
	plein_ecran = BOUTON.instantiate()
	plein_ecran.taille_minimale = Vector2(260, 48)
	plein_ecran.taille_police = 22
	plein_ecran.toggle_mode = true
	ligne.add_child(plein_ecran)
	plein_ecran.toggled.connect(_changer_affichage)
	_creer_curseur("sensibilite", "Sensibilité de visée · manette", 0.25, 2.5, 0.05)
	_creer_page_video()
	%Fermer.pressed.connect(fermer)
	onglet_reglages.pressed.connect(_choisir_page.bind("reglages"))
	onglet_controles.pressed.connect(_choisir_page.bind("controles"))
	controles.commandes_changees.connect(Reglages.sauvegarder)
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(menu)
	papier.material = papier.material.duplicate()
	_habiller_boutons(menu)
	_choisir_page("reglages")

func _habiller_boutons(parent: Node) -> void:
	for enfant in parent.get_children():
		_habiller_boutons(enfant)
	if not parent is Button:
		return
	var bouton := parent as Button
	var fond: TextureRect
	# Réutiliser la plaque des boutons existants préserve leurs dimensions et leurs actions.
	for enfant in bouton.get_children():
		if enfant is TextureRect and enfant.show_behind_parent:
			fond = enfant
			break
	if fond == null:
		fond = TextureRect.new()
		fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fond.show_behind_parent = true
		bouton.add_child(fond)
		fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.texture = preload("res://assets/textures/interfaces/ameliorations/texture_carte_300x450_r16.png")
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/interfaces/menus/onglet_carnet.gdshader")
	mat.set_shader_parameter("selection", 0.0)
	mat.set_shader_parameter("largeur_bord", 4.0)
	mat.set_shader_parameter("rayon_coin", 6.0)
	mat.set_shader_parameter("intensite_braises", 0.3)
	fond.material = mat
	bouton.set_meta("fond_graphite", fond)
	for etat in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxEmpty.new()
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		bouton.add_theme_stylebox_override(etat, style)
	boutons_graphite.append(bouton)

func _creer_titre(texte: String) -> void:
	var titre := Label.new()
	titre.text = texte
	titre.add_theme_color_override("font_color", Color("d5a76d"))
	titre.add_theme_font_size_override("font_size", 20)
	contenu.add_child(titre)

func _libelle(texte: String) -> Label:
	var libelle := Label.new()
	libelle.text = texte
	libelle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	libelle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return libelle

func _creer_curseur(id: String, texte: String, minimum: float, maximum: float, pas: float) -> void:
	var ligne := HBoxContainer.new()
	ligne.custom_minimum_size.y = 48
	ligne.add_theme_constant_override("separation", 24)
	contenu.add_child(ligne)
	ligne.add_child(_libelle(texte))
	var curseur := HSlider.new()
	curseur.custom_minimum_size = Vector2(300, 36)
	curseur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	curseur.min_value = minimum
	curseur.max_value = maximum
	curseur.step = pas
	ligne.add_child(curseur)
	var valeur := Label.new()
	valeur.custom_minimum_size.x = 90
	valeur.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	valeur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ligne.add_child(valeur)
	curseurs[id] = {"curseur": curseur, "valeur": valeur}
	curseur.value_changed.connect(_changer_curseur.bind(id))

func _changer_curseur(valeur: float, id: String) -> void:
	_afficher_valeur(id, valeur)
	if id == "sensibilite": Reglages.regler_sensibilite(valeur)
	else: Reglages.regler_volume(id, valeur / 100.0)

func _afficher_valeur(id: String, valeur: float) -> void:
	curseurs[id].valeur.text = "× %.2f" % valeur if id == "sensibilite" else "%d %%" % roundi(valeur)

func _changer_affichage(actif: bool) -> void:
	Reglages.regler_plein_ecran(actif)
	plein_ecran.text = "Plein écran" if actif else "Fenêtré"

func _choisir_profil(indice: int) -> void:
	Reglages.graphismes.appliquer(indice)
	Reglages.sauvegarder()
	_actualiser_profils()
	_actualiser_video()

func _actualiser_profils() -> void:
	for i in range(boutons_profils.size()):
		boutons_profils[i].set_pressed_no_signal(boutons_profils[i].get_meta("profil") == Reglages.graphismes.indice and not Reglages.graphismes.personnalise)

func ouvrir() -> void:
	if Reglages.chargement.en_cours: return
	_actualiser_profils()
	if menu.visible or get_tree().current_scene == null: return
	var joueur := get_tree().get_first_node_in_group("player")
	if is_instance_valid(joueur):
		var salles := joueur.get_parent().get_node_or_null("Salles/RoomManager")
		if salles != null and salles.transition_en_cours: return
		joueur.extincteur.stop_primary_attack()
	pause_avant = get_tree().paused
	souris_avant = Input.mouse_mode
	focus_avant = get_viewport().gui_get_focus_owner()
	# Les menus derrière restent affichés, mais ne reçoivent plus Échap ou B.
	_suspendre_entrees(get_tree().current_scene)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for id in curseurs:
		var valeur: float = Reglages.sensibilite if id == "sensibilite" else Reglages.volumes[id] * 100.0
		curseurs[id].curseur.set_value_no_signal(valeur)
		_afficher_valeur(id, valeur)
	var actif := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	plein_ecran.set_pressed_no_signal(actif)
	plein_ecran.text = "Plein écran" if actif else "Fenêtré"
	controles.mettre_a_jour_affichage_clavier()
	controles.mettre_a_jour_affichage_manette()
	_choisir_page("reglages")
	menu.show()
	if animation: animation.kill()
	animation = preload("res://scenes/interfaces/menus/transition_panneau.gd").ouvrir(self, menu, panneau)
	if not Input.get_connected_joypads().is_empty(): onglet_reglages.grab_focus()

func fermer() -> void:
	if not menu.visible: return
	controles.annuler_rebind()
	Reglages.sauvegarder()
	if animation: animation.kill()
	menu.hide()
	get_viewport().gui_release_focus()
	# Une boutique ou le Carnet déjà ouvert doit rester en pause au retour.
	get_tree().paused = pause_avant
	Input.mouse_mode = souris_avant
	for entree in entrees_suspendues:
		if is_instance_valid(entree.noeud):
			entree.noeud.set_process_input(entree.input)
			entree.noeud.set_process_unhandled_input(entree.unhandled)
			entree.noeud.set_process_unhandled_key_input(entree.key)
			if entree.navigation: entree.noeud.set_process(entree.process)
	entrees_suspendues.clear()
	if is_instance_valid(focus_avant) and focus_avant.is_visible_in_tree(): focus_avant.grab_focus()

func _suspendre_entrees(noeud: Node) -> void:
	entrees_suspendues.append({"noeud": noeud, "input": noeud.is_processing_input(), "unhandled": noeud.is_processing_unhandled_input(), "key": noeud.is_processing_unhandled_key_input(), "navigation": noeud is NavigationManette, "process": noeud.is_processing()})
	noeud.set_process_input(false)
	noeud.set_process_unhandled_input(false)
	noeud.set_process_unhandled_key_input(false)
	# Un menu derrière ne doit pas reprendre le focus de la manette.
	if noeud is NavigationManette: noeud.set_process(false)
	for enfant in noeud.get_children(): _suspendre_entrees(enfant)

func _choisir_page(page: String) -> void:
	controles.annuler_rebind()
	contenu.visible = page == "reglages"
	page_video.visible = page == "video"
	%PageControles.visible = page == "controles"
	controles.visible = page == "controles"
	for entree in [[onglet_reglages, "reglages"], [onglet_video, "video"], [onglet_controles, "controles"]]:
		entree[0].set_pressed_no_signal(page == entree[1])
	%Defilement.scroll_vertical = 0
	_actualiser_video()

func _input(event: InputEvent) -> void:
	if not menu.visible or event.is_echo() or controles.rebind_en_cours(): return
	var raccourci: bool = event is InputEventKey and event.pressed and event.physical_keycode == KEY_F2
	var start: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
	if event.is_action_pressed("ui_cancel") or raccourci or start:
		get_viewport().set_input_as_handled()
		fermer()

func _process(delta: float) -> void:
	if not menu.visible: return
	horloge += delta
	papier.material.set_shader_parameter("horloge", horloge)
	papier.material.set_shader_parameter("taille", papier.size)
	for bouton in boutons_graphite:
		var fond: TextureRect = bouton.get_meta("fond_graphite")
		var cible := 1.0 if bouton.button_pressed else (0.45 if bouton.is_hovered() or bouton.has_focus() else 0.0)
		var actuel: float = fond.material.get_shader_parameter("selection")
		fond.material.set_shader_parameter("selection", lerpf(actuel, cible, 1.0 - exp(-12.0 * delta)))
		fond.material.set_shader_parameter("horloge", horloge)
		fond.material.set_shader_parameter("taille", bouton.size)

func _creer_page_video() -> void:
	onglet_video = BOUTON.instantiate()
	onglet_video.text = "Vidéo"
	onglet_video.toggle_mode = true
	onglet_video.taille_minimale = Vector2(220, 50)
	onglet_video.taille_police = 24
	onglet_reglages.get_parent().add_child(onglet_video)
	onglet_reglages.get_parent().move_child(onglet_video, 1)
	onglet_video.pressed.connect(_choisir_page.bind("video"))
	page_video = VBoxContainer.new()
	page_video.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_video.add_theme_constant_override("separation", 12)
	contenu.get_parent().add_child(page_video)
	var ancien_contenu := contenu
	contenu = page_video
	_creer_titre("PROFILS GRAPHIQUES")
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	page_video.add_child(ligne)
	# L'ordre visuel ne change pas les indices enregistrés dans les options.
	for i in [3, 0, 1, 2]:
		var bouton: Button = BOUTON.instantiate()
		bouton.taille_minimale = Vector2(170, 48)
		bouton.taille_police = 22
		bouton.text = Reglages.graphismes.profils[i].titre
		bouton.toggle_mode = true
		bouton.set_meta("profil", i)
		bouton.tooltip_text = ["Économique : résolution réduite, ombres et reflets du décor désactivés.", "Équilibré : résolution légèrement réduite, modèles simplifiés plus tôt, sans SSR.", "Complet : conserve la qualité et les effets prévus par les scènes.", "Grille-pain : rendu 3D à 50 %, décor détaillé limité à 5 m, simplification maximale, sans ombres, reflets, lueur, lumières décoratives ni textures détaillées."][i]
		ligne.add_child(bouton)
		boutons_profils.append(bouton)
		bouton.pressed.connect(_choisir_profil.bind(i))
	_creer_titre("RÉGLAGES INDIVIDUELS")
	_ajouter_curseur_video("resolution_3d", "Résolution 3D", 0.5, 1.0, 0.05)
	_ajouter_curseur_video("distance_details", "Distance du décor", 0.0, 150.0, 5.0)
	_ajouter_curseur_video("seuil_lod", "Détails des modèles", 1.0, 6.0, 0.5)
	for entree in [["ombres", "Ombres"], ["lumieres_decor", "Éclairage décoratif"], ["lueur", "Lueur"], ["reflets_ecran", "Reflets SSR"], ["sondes_reflets", "Sondes"], ["brillance_lumieres", "Brillance"], ["textures_decor", "Textures"]]:
		var rangee := HBoxContainer.new()
		page_video.add_child(rangee)
		var nom := _libelle(entree[1])
		nom.set_script(preload("res://scenes/interfaces/menus/options/libelle_video.gd"))
		nom.mouse_filter = Control.MOUSE_FILTER_STOP
		nom.tooltip_text = AIDE_VIDEO[entree[0]]
		rangee.add_child(nom)
		var bouton: Button = BOUTON.instantiate()
		bouton.taille_minimale = Vector2(180, 42)
		bouton.taille_police = 20
		bouton.toggle_mode = true
		bouton.tooltip_text = AIDE_VIDEO[entree[0]]
		rangee.add_child(bouton)
		commandes_video[entree[0]] = bouton
		bouton.toggled.connect(_modifier_video.bind(entree[0]))
	var aide := Label.new()
	aide.text = "Changer un réglage crée un profil personnalisé. Les textures désactivées restent chargées en mémoire."
	aide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aide.add_theme_font_size_override("font_size", 16)
	page_video.add_child(aide)
	contenu = ancien_contenu

func _ajouter_curseur_video(nom: String, texte: String, minimum: float, maximum: float, pas: float) -> void:
	var ligne := HBoxContainer.new()
	page_video.add_child(ligne)
	var libelle := _libelle(texte)
	libelle.set_script(preload("res://scenes/interfaces/menus/options/libelle_video.gd"))
	libelle.mouse_filter = Control.MOUSE_FILTER_STOP
	libelle.tooltip_text = AIDE_VIDEO[nom]
	ligne.add_child(libelle)
	var curseur := HSlider.new()
	curseur.custom_minimum_size = Vector2(300, 36)
	curseur.min_value = minimum
	curseur.max_value = maximum
	curseur.step = pas
	ligne.add_child(curseur)
	var valeur := Label.new()
	valeur.custom_minimum_size.x = 100
	ligne.add_child(valeur)
	commandes_video[nom] = {"curseur": curseur, "valeur": valeur}
	curseur.value_changed.connect(_modifier_video.bind(nom))

func _modifier_video(valeur: Variant, nom: String) -> void:
	Reglages.graphismes.regler(nom, valeur)
	Reglages.sauvegarder()
	_actualiser_video()

func _actualiser_video() -> void:
	_actualiser_profils()
	for nom in commandes_video:
		var valeur: Variant = Reglages.graphismes.parametres[nom]
		var commande: Variant = commandes_video[nom]
		if commande is Button:
			commande.set_pressed_no_signal(valeur)
			commande.text = "Activé" if valeur else "Désactivé"
		else:
			commande.curseur.set_value_no_signal(valeur)
			if nom == "resolution_3d": commande.valeur.text = "%d %%" % roundi(valeur * 100)
			elif nom == "seuil_lod": commande.valeur.text = "× %.1f" % valeur
			else: commande.valeur.text = "Illimitée" if valeur == 0 else "%d m" % valeur
