extends CanvasLayer

signal ameliorations_changees

@export_enum("classique", "zombie") var mode_jeu := "classique"
@export var catalogue_ameliorations: CatalogueAmeliorations = preload("res://scenes/systemes/ameliorations/catalogue_ameliorations.tres")
@export_group("Boutique — prix")
@export_range(1, 20) var prix_commun := 1
@export_range(1, 20) var prix_rare := 2
@export_range(1, 20) var prix_epique := 3
@export_range(1, 20) var prix_temporaire := 1
@export_group("Boutique — puissance des raretés")
# 50 % donne la moitié du bonus de base ; une carte dégâts à +20 % donne +10 %.
@export_range(0.0, 300.0, 10.0) var puissance_commune := 50.0
@export_range(0.0, 300.0, 10.0) var puissance_rare := 100.0
@export_range(0.0, 300.0, 10.0) var puissance_epique := 200.0
@export_group("Tirage — poids commun / rare / épique")
# X = commun, Y = rare, Z = épique. Les proportions sont recalculées sur les cartes disponibles.
@export var poids_booster_commun := Vector3(88, 11, 1)
@export var poids_booster_rare := Vector3(25, 65, 10)
@export var poids_booster_epique := Vector3(5, 25, 70)
@export var poids_booster_temporaire := Vector3(65, 30, 5)

const TIRAGE = preload("res://scenes/systemes/ameliorations/tirage_ameliorations.gd")
const CARTE = preload("res://scenes/interfaces/menus/ameliorations/carte_amelioration.tscn")
const BOUTIQUE = preload("res://scenes/interfaces/menus/boutique/prototype_boutique.tscn")
const CATALOGUE = preload("res://scenes/interfaces/menus/boutique/catalogue_boutique.gd")
@onready var room_manager = $"../Salles/RoomManager"
@onready var joueur = $"../player"
@onready var extincteur = $"../player".extincteur
@onready var escorte = $"../VictimManager"
@onready var defis = $DefiManager
@onready var menu: Control = $Menu
@onready var cartes: GridContainer = $Menu/Defilement/Centre/Marge/Contenu/Cartes
var extincteur_mural: Node3D
@onready var monnaie = get_node("../Monnaie")
var boutique: Control
var niveaux: Dictionary = {}
# Historique de la partie : une carte unique consommée ne redevient pas achetable.
var cartes_obtenues: Dictionary = {}
var bonus_cumules_pourcent: Dictionary = {}
# Le récapitulatif garde la rareté et le gain réel de chaque acquisition.
var acquisitions: Array[Dictionary] = []
var points := 0
# Le menu de debug active ce mode pour la partie en cours, sans modifier l'escorte.
var points_abondants_test := false
const POINTS_BOUTIQUE_TEST := 999
var boutique_ouverte := false
var choix_ouverts := false
var souris_avant: int
var animation: Tween
var charge_de_base: float
var recharge_de_base: float
var vie_de_base: float
var catalogue_debug := false
var retour_debug: Button
var multiplicateur_choix_courant := 1.0
var rarete_courante: StringName = &"commun"
var boucliers_joueur: Array[Dictionary] = []
var bonus_vitesse_escorte := 1.0
var etape_en_cours := false
var sirene_timer := 0.0
var sirene_definition: Amelioration
var rayon_sirene := 0.0
var retours_bonus: CanvasLayer


func _ready() -> void:
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(menu)
	menu.hide()
	joueur.ameliorations = self
	escorte.escort_changed.connect(_actualiser_vitesse_escorte)
	retours_bonus = preload("res://scenes/interfaces/hud/retours_bonus.tscn").instantiate()
	retours_bonus.joueur = joueur
	retours_bonus.upgrades = self
	joueur.add_child(retours_bonus)
	charge_de_base = extincteur.max_charge
	recharge_de_base = extincteur.reload_rate
	vie_de_base = joueur.BarreDeVie.max_value
	room_manager.salle_commencee.connect(_commencer_etape)
	room_manager.salle_terminee.connect(_terminer_etape)
	retour_debug = preload("res://scenes/interfaces/menus/titre/bouton_menu.tscn").instantiate()
	retour_debug.set("taille_police", 20)
	retour_debug.custom_minimum_size = Vector2(300, 40)
	retour_debug.text = "Retour à la boutique"
	retour_debug.focus_mode = Control.FOCUS_NONE
	retour_debug.pressed.connect(_retour_boutique)
	cartes.get_parent().add_child(retour_debug)
	cartes.get_parent().move_child(retour_debug, 1)
	retour_debug.hide()
	# Le défi doit toujours coûter moins cher que le booster rare.
	defis.prix_sans_degats = mini(defis.prix_sans_degats, prix_rare - 1)
	room_manager.victimes_supplementaires_reserve = defis.victimes_supplementaires
	boutique = BOUTIQUE.instantiate()
	boutique.mode_demonstration = false
	boutique.catalogue = offres_boosters()
	add_child(boutique)
	boutique.hide()
	boutique.ajouter_ravitaillement()
	boutique.recharge_murale_demandee.connect(_acheter_recharge_murale)
	monnaie.solde_change.connect(_actualiser_pieces)
	boutique.achat_demande.connect(_acheter_booster)
	boutique.catalogue_debug_demande.connect(ouvrir_catalogue_debug)
	boutique.defi_demande.connect(_acheter_defi)
	boutique.continuer_demande.connect(_continuer)
	boutique.bonus_demandes.connect(func(): get_node("../MenuBonus").ouvrir_menu())
	room_manager.choix_amelioration_demande.connect(ouvrir_choix)


func offres_boosters() -> Array[Dictionary]:
	return [
		{"id": &"commun", "titre": "Commun", "couleur": CATALOGUE.COULEURS[&"commun"], "prix": prix_commun, "puissance": puissance_commune, "symbole": "I", "categorie": "permanent", "contenu": "3 choix · surtout communes"},
		{"id": &"rare", "titre": "Rare", "couleur": CATALOGUE.COULEURS[&"rare"], "prix": prix_rare, "puissance": puissance_rare, "symbole": "II", "categorie": "permanent", "contenu": "3 choix · surtout rares"},
		{"id": &"epique", "titre": "Épique", "couleur": CATALOGUE.COULEURS[&"epique"], "prix": prix_epique, "puissance": puissance_epique, "symbole": "III", "categorie": "permanent", "contenu": "3 choix · surtout épiques"},
		{"id": &"temporaire", "titre": "Intervention", "couleur": CATALOGUE.COULEURS[&"temporaire"], "prix": prix_temporaire, "puissance": 100.0, "symbole": "+", "categorie": "temporaire", "contenu": "%d choix · soins et protection" % mini(3, catalogue_ameliorations.disponibles(mode_jeu, "temporaire").size())}
	]


# Nom conservé pour le signal existant du RoomManager ; il ouvre désormais la boutique.
func ouvrir_choix(_nombre_victimes: int) -> void:
	if boutique_ouverte or choix_ouverts:
		return
	points = 0
	for victime in escorte.freed_victims:
		if is_instance_valid(victime) and not victime.est_morte and not victime.is_queued_for_deletion():
			points += 1
	if points_abondants_test:
		points = POINTS_BOUTIQUE_TEST
	boutique_ouverte = true
	extincteur.stop_primary_attack()
	souris_avant = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_actualiser_boutique()
	boutique.show()
	boutique.modulate.a = 0.0
	# Un fondu court accompagne l'ouverture. Always permet au Tween de vivre en pause.
	animation = create_tween()
	animation.tween_property(boutique, "modulate:a", 1.0, 0.2)


func _actualiser_boutique(message: String = "") -> void:
	if message.is_empty():
		message = defis.bilan + "Les points non dépensés seront perdus en quittant la boutique."
	boutique.actualiser_boutique(points, defis.actifs, defis.propositions(), defis.boosters_rares_gratuits, message)
	_actualiser_pieces()


func _acheter_defi(id: StringName) -> void:
	if not boutique_ouverte or choix_ouverts:
		return
	for offre in defis.propositions():
		if offre.id == id and points >= offre.prix:
			if defis.accepter(id):
				points -= offre.prix
				_actualiser_boutique("Défi accepté : %s. Il commence dans la prochaine salle." % offre.titre)
			return


func _acheter_booster(rarete: StringName) -> void:
	if not boutique_ouverte or choix_ouverts:
		return
	var type_bonus := "temporaire" if rarete == &"temporaire" else "permanent"
	var propositions := _cartes_achetables(type_bonus)
	# Vérifier le pool avant de dépenser : un catalogue désactivé ne piège pas le joueur.
	if propositions.is_empty():
		_actualiser_boutique("Aucune carte disponible dans cette catégorie.")
		return
	if rarete == &"rare_gratuit":
		if defis.boosters_rares_gratuits <= 0: return
		defis.boosters_rares_gratuits -= 1
		rarete = &"rare"
	else:
		var offre: Dictionary = {}
		for proposition in offres_boosters():
			if proposition.id == rarete: offre = proposition
		if offre.is_empty() or points < offre.prix:
			_actualiser_boutique("Vous n’avez pas assez de points pour ce booster.")
			return
		points -= offre.prix
	choix_ouverts = true
	catalogue_debug = false
	retour_debug.hide()
	var poids := poids_booster_commun
	match rarete:
		&"rare": poids = poids_booster_rare
		&"epique": poids = poids_booster_epique
		&"temporaire": poids = poids_booster_temporaire
	# Chaque carte reçoit sa propre rareté ; la couleur du booster ne l'impose plus.
	var choix := TIRAGE.tirer(propositions, poids, Vector3(puissance_commune, puissance_rare, puissance_epique))
	await boutique.animer_ouverture(rarete)
	_afficher_cartes(choix)

func _afficher_cartes(propositions: Array) -> void:
	boutique.hide()
	for proposition in propositions:
		var definition: Amelioration = proposition.definition
		var carte = CARTE.instantiate()
		carte.set_meta("multiplicateur", proposition.multiplicateur)
		carte.identifiant = definition.identifiant
		if catalogue_debug and definition.obtention_unique and cartes_obtenues.has(definition.identifiant):
			carte.lecture_seule = true
			carte.statut = "DÉJÀ OBTENUE"
		carte.titre = definition.titre
		carte.description = definition.description
		carte.illustration = definition.pictogramme
		carte.rarete = proposition.rarete
		carte.categorie = definition.type_bonus.to_upper()
		carte.effet_affiche = formater_effet(definition.identifiant, definition.valeur * proposition.multiplicateur)
		carte.duree_affichee = texte_duree(definition.duree) if definition.type_bonus == "temporaire" else ""
		carte.selected.connect(_choisir.bind(carte))
		cartes.add_child(carte)
	$Menu/Defilement/Centre/Marge/Contenu/Note.text = "DEBUG · Choix gratuit à 100 % · Les cartes uniques déjà obtenues sont désactivées." if catalogue_debug else "Choisissez une carte. Les soins sont immédiats ; les autres effets indiquent leur durée."
	menu.show()

func ouvrir_catalogue_debug() -> void:
	if not boutique_ouverte or choix_ouverts: return
	catalogue_debug = true
	choix_ouverts = true
	rarete_courante = &"rare"
	multiplicateur_choix_courant = 1.0
	retour_debug.show()
	var propositions: Array[Dictionary] = []
	for definition in catalogue_ameliorations.disponibles(mode_jeu):
		propositions.append(TIRAGE.proposition(definition, &"rare", 1.0))
	_afficher_cartes(propositions)

func _choisir(carte: Control) -> void:
	if not choix_ouverts or carte.get_parent() != cartes: return
	rarete_courante = carte.rarete
	multiplicateur_choix_courant = carte.get_meta("multiplicateur", 1.0)
	appliquer_amelioration(carte.identifiant)
	_retour_boutique()
	_actualiser_boutique("Carte appliquée. Vous pouvez acheter autre chose ou continuer.")

func _retour_boutique() -> void:
	choix_ouverts = false
	catalogue_debug = false
	retour_debug.hide()
	menu.hide()
	for enfant in cartes.get_children():
		cartes.remove_child(enfant)
		enfant.queue_free()
	_actualiser_boutique()
	boutique.show()

func _continuer() -> void:
	if not boutique_ouverte or choix_ouverts:
		return
	boutique_ouverte = false
	points = 0 # Aucun report : la prochaine boutique recomptera l'escorte vivante.
	if animation:
		animation.kill()
	boutique.hide()
	Input.mouse_mode = souris_avant
	get_tree().paused = false
	room_manager.call_deferred("passer_salle_suivante")


func valeur_base(identifiant: StringName) -> float:
	var definition := catalogue_ameliorations.trouver(identifiant)
	return definition.valeur if definition != null else 0.0

func appliquer_amelioration(identifiant: StringName) -> void:
	var definition := catalogue_ameliorations.trouver(identifiant)
	if definition == null or not catalogue_ameliorations.disponibles(mode_jeu).has(definition): return
	if definition.obtention_unique and cartes_obtenues.has(identifiant): return
	cartes_obtenues[identifiant] = true
	# Même le debug respecte l'effet fixe et l'obtention unique.
	var gain := definition.valeur * (multiplicateur_choix_courant if definition.puissance_variable else 1.0)
	var rarete_acquisition := rarete_courante if definition.puissance_variable else StringName(definition.rarete)
	if definition.type_bonus == "temporaire" and definition.duree == 0:
		# Un soin n’est pas un bonus actif : son effet est appliqué une seule fois.
		_appliquer_soin(definition.effet, gain)
	else:
		var acquisition := {"id": identifiant, "definition": definition, "rarete": rarete_acquisition,
			"gain": gain, "restant": definition.duree, "commence": false}
		if definition.effet in ["bouclier_camion", "bouclier_joueur"]: acquisition.bouclier_restant = gain
		acquisitions.append(acquisition)
		recalculer_effets()
	ameliorations_changees.emit()

func _appliquer_soin(effet: String, gain: float) -> void:
	if effet == "soin_joueur":
		joueur.BarreDeVie.value = minf(joueur.BarreDeVie.value + gain, joueur.BarreDeVie.max_value)
	elif effet == "soin_victimes":
		if mode_jeu == "zombie":
			room_manager.refuge.soigner_victimes(gain)
		else:
			for victime in escorte.freed_victims:
				if is_instance_valid(victime) and not victime.est_morte:
					victime.vie = minf(victime.vie + gain, victime.vie_max)
					victime.actualiser_barre_vie()

func recalculer_effets() -> void:
	var totaux: Dictionary = {}
	niveaux.clear()
	bonus_cumules_pourcent.clear()
	var protections: Array[Dictionary] = []
	boucliers_joueur.clear()
	sirene_definition = null
	rayon_sirene = 0.0
	extincteur.seuil_dernier_souffle = 25.0
	extincteur.duree_gel = 1.0
	for acquisition in acquisitions:
		var definition: Amelioration = acquisition.definition
		niveaux[acquisition.id] = niveaux.get(acquisition.id, 0) + 1
		bonus_cumules_pourcent[acquisition.id] = bonus_cumules_pourcent.get(acquisition.id, 0.0) + acquisition.gain
		totaux[definition.effet] = totaux.get(definition.effet, 0.0) + acquisition.gain
		if definition.effet == "bouclier_camion": protections.append(acquisition)
		if definition.effet == "bouclier_joueur": boucliers_joueur.append(acquisition)
		if definition.effet == "jet_givre": extincteur.duree_gel = definition.duree_effet
		if definition.effet == "dernier_souffle": extincteur.seuil_dernier_souffle = definition.seuil_vie
		if definition.effet == "sirene":
			sirene_definition = definition
			# Plusieurs sirènes élargissent le rayon, sans multiplier les appels.
			rayon_sirene = maxf(rayon_sirene, acquisition.gain)
	extincteur.ralentissement_jet = minf(80.0, totaux.get("jet_givre", 0.0))
	extincteur.bonus_dernier_souffle = totaux.get("dernier_souffle", 0.0)
	extincteur.particles.process_material.color = Color(0.06, 0.48, 1.0) if extincteur.ralentissement_jet > 0.0 else extincteur.couleur_jet_initiale
	bonus_vitesse_escorte = 1.0 + totaux.get("escorte_agile", 0.0) / 100.0
	_actualiser_vitesse_escorte()
	_actualiser_bouclier_joueur()
	if sirene_definition == null and mode_jeu == "zombie" and is_instance_valid(room_manager.refuge):
		room_manager.refuge.sirene_restante = 0.0
	extincteur.multiplicateur_degats_ameliorations = 1.0 + totaux.get("degats", 0.0) / 100.0
	var ancien_max: float = extincteur.max_charge
	extincteur.max_charge = charge_de_base * (1.0 + totaux.get("charge", 0.0) / 100.0)
	extincteur.charge = minf(extincteur.max_charge, extincteur.charge + maxf(0, extincteur.max_charge - ancien_max))
	extincteur.reload_rate = recharge_de_base * (1.0 + totaux.get("recharge", 0.0) / 100.0)
	var ancienne_vie_max: float = joueur.BarreDeVie.max_value
	joueur.BarreDeVie.max_value = vie_de_base + totaux.get("vie_max", 0.0)
	joueur.BarreDeVie.value = minf(joueur.BarreDeVie.max_value, joueur.BarreDeVie.value + maxf(0, joueur.BarreDeVie.max_value - ancienne_vie_max))
	if mode_jeu == "zombie" and is_instance_valid(room_manager.refuge):
		room_manager.refuge.reduction_degats = minf(80.0, totaux.get("blindage_camion", 0.0)) / 100.0
		# Les dictionnaires sont partagés : les coups diminuent la vraie réserve de chaque carte.
		room_manager.refuge.boucliers = protections
		room_manager.refuge.actualiser()

func _commencer_etape(_salle: Node3D) -> void:
	etape_en_cours = true
	sirene_timer = sirene_definition.intervalle if sirene_definition != null else 0.0
	for acquisition in acquisitions:
		acquisition.commence = true

func _terminer_etape(_salle: Node3D) -> void:
	etape_en_cours = false
	if mode_jeu == "zombie" and is_instance_valid(room_manager.refuge):
		room_manager.refuge.sirene_restante = 0.0
	for acquisition in acquisitions.duplicate():
		if acquisition.definition.type_bonus != "temporaire" or not acquisition.commence: continue
		acquisition.commence = false
		acquisition.restant -= 1
		if acquisition.restant <= 0: acquisitions.erase(acquisition)
	recalculer_effets()
	ameliorations_changees.emit()

func texte_duree(restant: int) -> String:
	if restant == 0: return "EFFET IMMÉDIAT"
	var unite := "VAGUE" if mode_jeu == "zombie" else "SALLE"
	return "%d %s%s RESTANTE%s" % [restant, unite, "S" if restant > 1 else "", "S" if restant > 1 else ""]

func formater_pourcentage(valeur: float) -> String:
	return String.num(valeur, 2).trim_suffix(".0")

func formater_effet(identifiant: StringName, gain: float) -> String:
	var definition := catalogue_ameliorations.trouver(identifiant)
	return definition.texte_effet % formater_pourcentage(gain) if definition != null else ""

func texte_effet(identifiant: StringName, _nombre: int = 1) -> String:
	return formater_effet(identifiant, bonus_cumules_pourcent.get(identifiant, 0.0))

func texte_effet_choix(identifiant: StringName) -> String:
	var definition := catalogue_ameliorations.trouver(identifiant)
	var multiplicateur := multiplicateur_choix_courant if definition != null and definition.puissance_variable else 1.0
	return formater_effet(identifiant, valeur_base(identifiant) * multiplicateur)

func get_resume() -> String:
	var lignes := PackedStringArray()
	for acquisition in acquisitions:
		lignes.append("%s : %s" % [acquisition.definition.titre, formater_effet(acquisition.id, acquisition.gain)])
	return "Aucune amélioration active." if lignes.is_empty() else "\n".join(lignes)

func _actualiser_vitesse_escorte() -> void:
	# Le signal couvre aussi les victimes libérées après l'achat de la carte.
	for victime in escorte.freed_victims:
		if is_instance_valid(victime): victime.multiplicateur_vitesse = bonus_vitesse_escorte

func _actualiser_bouclier_joueur() -> void:
	var restant := 0.0
	for protection in boucliers_joueur:
		restant += protection.bouclier_restant
	# La jauge de vie dessine la protection avec la même échelle que les PV.
	joueur.BarreDeVie.afficher_bouclier(restant)

func absorber_degats_joueur(degats: float) -> float:
	var degats_avant := degats
	# Dépenser les réserves les plus anciennes d'abord ; seul l'excédent touche les PV.
	for protection in boucliers_joueur:
		var absorption := minf(degats, protection.bouclier_restant)
		protection.bouclier_restant -= absorption
		degats -= absorption
		if degats <= 0.0: break
	_actualiser_bouclier_joueur()
	if degats < degats_avant: retours_bonus.afficher_impact_bouclier()
	return degats

func utiliser_secours() -> bool:
	for acquisition in acquisitions:
		if acquisition.definition.effet != "reserve_secours": continue
		joueur.BarreDeVie.value = joueur.BarreDeVie.max_value * clampf(acquisition.gain, 1.0, 100.0) / 100.0
		acquisitions.erase(acquisition)
		retours_bonus.afficher_secours()
		recalculer_effets()
		ameliorations_changees.emit()
		return true
	return false

func _process(delta: float) -> void:
	# Ce CanvasLayer fonctionne en pause pour les menus, mais la sirène attend le combat.
	if get_tree().paused or not etape_en_cours or sirene_definition == null: return
	if mode_jeu != "zombie" or not is_instance_valid(room_manager.refuge): return
	sirene_timer -= delta
	if sirene_timer <= 0.0:
		sirene_timer = sirene_definition.intervalle
		room_manager.refuge.declencher_sirene(rayon_sirene, sirene_definition.duree_effet)

func _cartes_achetables(type_bonus: String) -> Array[Amelioration]:
	var resultat: Array[Amelioration] = []
	for definition in catalogue_ameliorations.disponibles(mode_jeu, type_bonus):
		if definition.obtention_unique and cartes_obtenues.has(definition.identifiant): continue
		resultat.append(definition)
	return resultat

func _actualiser_pieces(_solde: int = 0) -> void:
	if not is_instance_valid(extincteur_mural):
		# La map est créée après la boutique : chercher l'objet au premier affichage.
		for objet in get_tree().get_nodes_in_group("extincteur_mural"):
			if get_parent().is_ancestor_of(objet):
				extincteur_mural = objet
				extincteur_mural.etat_change.connect(_actualiser_pieces)
				break
	var present := is_instance_valid(extincteur_mural)
	boutique.actualiser_ravitaillement(monnaie.solde, extincteur_mural.disponible if present else false,
		extincteur_mural.prix_recharge if present else 10, present)

func _acheter_recharge_murale() -> void:
	# Revérifier côté jeu : un bouton grisé ne remplace pas la vérification d'un achat.
	if not boutique_ouverte or choix_ouverts or not is_instance_valid(extincteur_mural): return
	if extincteur_mural.disponible: return
	if monnaie.depenser(extincteur_mural.prix_recharge):
		extincteur_mural.recharger()
		boutique.retour.text = "Extincteur mural rechargé : un plein de mousse vous attend."
