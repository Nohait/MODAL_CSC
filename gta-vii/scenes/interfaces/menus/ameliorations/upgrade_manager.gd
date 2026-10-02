extends CanvasLayer

signal ameliorations_changees

@export_group("Équilibrage — bonus de base à puissance 100 %")
@export_range(0.0, 200.0, 1.0) var bonus_degats_pourcent := 20.0
@export_range(0.0, 200.0, 1.0) var bonus_charge_pourcent := 25.0
@export_range(0.0, 200.0, 1.0) var bonus_recharge_pourcent := 20.0
@export_group("Boutique — prix")
@export_range(1, 20) var prix_commun := 1
@export_range(1, 20) var prix_rare := 2
@export_range(1, 20) var prix_epique := 3
@export_group("Boutique — puissance des raretés")
# 50 % donne la moitié du bonus de base ; une carte dégâts à +20 % donne +10 %.
@export_range(0.0, 300.0, 10.0) var puissance_commune := 50.0
@export_range(0.0, 300.0, 10.0) var puissance_rare := 100.0
@export_range(0.0, 300.0, 10.0) var puissance_epique := 150.0

const CARTE = preload("res://scenes/interfaces/menus/ameliorations/carte_amelioration.tscn")
const BOUTIQUE = preload("res://scenes/interfaces/menus/boutique/prototype_boutique.tscn")
const CATALOGUE = preload("res://scenes/interfaces/menus/boutique/catalogue_boutique.gd")
const POOL = [
	{"id": &"pression", "titre": "Sous pression", "description": "Un jet plus puissant pour repousser les flammes."},
	{"id": &"reserve", "titre": "Grande réserve", "description": "Plus de charge pour tenir face à l'incendie."},
	{"id": &"recharge", "titre": "Second souffle", "description": "Reprendre l'avantage avant que le feu ne gagne."}
]

@onready var room_manager = $"../Salles/RoomManager"
@onready var extincteur = $"../player".extincteur
@onready var escorte = $"../VictimManager"
@onready var defis = $DefiManager
@onready var menu: Control = $Menu
@onready var cartes: HBoxContainer = $Menu/Defilement/Centre/Marge/Contenu/Cartes
var boutique: Control
var niveaux := {&"pression": 0, &"reserve": 0, &"recharge": 0}
var bonus_cumules_pourcent := {&"pression": 0.0, &"reserve": 0.0, &"recharge": 0.0}
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
var multiplicateur_choix_courant := 1.0
var rarete_courante: StringName = &"commun"


func _ready() -> void:
	menu.hide()
	charge_de_base = extincteur.max_charge
	recharge_de_base = extincteur.reload_rate
	# Le défi doit toujours coûter moins cher que le booster rare.
	defis.prix_sans_degats = mini(defis.prix_sans_degats, prix_rare - 1)
	room_manager.victimes_supplementaires_reserve = defis.victimes_supplementaires
	boutique = BOUTIQUE.instantiate()
	boutique.mode_demonstration = false
	boutique.catalogue = offres_boosters()
	add_child(boutique)
	boutique.hide()
	boutique.achat_demande.connect(_acheter_booster)
	boutique.defi_demande.connect(_acheter_defi)
	boutique.continuer_demande.connect(_continuer)
	room_manager.choix_amelioration_demande.connect(ouvrir_choix)


func offres_boosters() -> Array[Dictionary]:
	return [
		{"id": &"commun", "titre": "Commun", "couleur": CATALOGUE.COULEURS[&"commun"], "prix": prix_commun, "puissance": puissance_commune, "symbole": "I"},
		{"id": &"rare", "titre": "Rare", "couleur": CATALOGUE.COULEURS[&"rare"], "prix": prix_rare, "puissance": puissance_rare, "symbole": "II"},
		{"id": &"epique", "titre": "Épique", "couleur": CATALOGUE.COULEURS[&"epique"], "prix": prix_epique, "puissance": puissance_epique, "symbole": "III"}
	]


# Nom conservé pour le signal existant du RoomManager ; il ouvre désormais la boutique.
func ouvrir_choix(_nombre_victimes: int) -> void:
	if boutique_ouverte or choix_ouverts:
		return
	points = 0
	for victime in escorte.freed_victims:
		if is_instance_valid(victime) and not victime.est_morte and not victime.is_queued_for_deletion():
			points += victime.points_boutique
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
	if rarete == &"rare_gratuit":
		if defis.boosters_rares_gratuits <= 0:
			return
		defis.boosters_rares_gratuits -= 1
		rarete = &"rare"
	else:
		var offre: Dictionary = {}
		for proposition in offres_boosters():
			if proposition.id == rarete:
				offre = proposition
		if offre.is_empty() or points < offre.prix:
			_actualiser_boutique("Vous n'avez pas assez de points pour ce booster.")
			return
		points -= offre.prix
	# Verrouiller avant de construire les cartes évite un double achat.
	choix_ouverts = true
	rarete_courante = rarete
	match rarete:
		&"commun": multiplicateur_choix_courant = puissance_commune / 100.0
		&"rare": multiplicateur_choix_courant = puissance_rare / 100.0
		&"epique": multiplicateur_choix_courant = puissance_epique / 100.0
	# Le verrou d’achat est déjà actif : aucun second clic ne dépense de points.
	await boutique.animer_ouverture(rarete)
	boutique.hide()
	var propositions: Array = POOL.duplicate()
	propositions.shuffle()
	for proposition in propositions.slice(0, 3):
		var carte = CARTE.instantiate()
		carte.identifiant = proposition.id
		carte.titre = proposition.titre
		carte.description = proposition.description
		carte.rarete = rarete
		carte.categorie = "EXTINCTEUR · " + CATALOGUE.NOMS[rarete].to_upper()
		carte.effet_affiche = texte_effet_choix(proposition.id)
		carte.selected.connect(_choisir.bind(carte))
		cartes.add_child(carte)
	menu.show()


func _choisir(carte: Control) -> void:
	if not choix_ouverts or carte.get_parent() != cartes:
		return
	choix_ouverts = false
	appliquer_amelioration(carte.identifiant)
	menu.hide()
	for enfant in cartes.get_children():
		cartes.remove_child(enfant)
		enfant.queue_free()
	_actualiser_boutique("Amélioration acquise. Vous pouvez acheter autre chose ou continuer.")
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
	match identifiant:
		&"pression": return bonus_degats_pourcent
		&"reserve": return bonus_charge_pourcent
		&"recharge": return bonus_recharge_pourcent
	return 0.0


func appliquer_amelioration(identifiant: StringName) -> void:
	if not niveaux.has(identifiant):
		return
	niveaux[identifiant] += 1
	var gain: float = valeur_base(identifiant) * multiplicateur_choix_courant
	bonus_cumules_pourcent[identifiant] += gain
	acquisitions.append({"id": identifiant, "rarete": rarete_courante, "gain": gain})
	match identifiant:
		&"pression":
			extincteur.multiplicateur_degats_ameliorations = 1.0 + bonus_cumules_pourcent[identifiant] / 100.0
		&"reserve":
			var ancien_max: float = extincteur.max_charge
			extincteur.max_charge = charge_de_base * (1.0 + bonus_cumules_pourcent[identifiant] / 100.0)
			# Remplir uniquement la capacité nouvellement ajoutée.
			extincteur.charge += extincteur.max_charge - ancien_max
		&"recharge":
			extincteur.reload_rate = recharge_de_base * (1.0 + bonus_cumules_pourcent[identifiant] / 100.0)
	ameliorations_changees.emit()


func formater_pourcentage(valeur: float) -> String:
	return String.num(valeur, 2).trim_suffix(".0")


func formater_effet(identifiant: StringName, pourcentage: float) -> String:
	var nombre := formater_pourcentage(pourcentage)
	match identifiant:
		&"pression": return "+%s %% de dégâts" % nombre
		&"reserve": return "+%s %% de charge maximale" % nombre
		&"recharge": return "+%s %% de vitesse de recharge" % nombre
	return ""


func texte_effet(identifiant: StringName, _nombre: int = 1) -> String:
	# Le récapitulatif lit les vrais gains cumulés, qui dépendent désormais des raretés.
	return formater_effet(identifiant, bonus_cumules_pourcent[identifiant])


func texte_effet_choix(identifiant: StringName) -> String:
	return formater_effet(identifiant, valeur_base(identifiant) * multiplicateur_choix_courant)


func get_resume() -> String:
	var lignes := PackedStringArray()
	for proposition in POOL:
		if niveaux[proposition.id] > 0:
			lignes.append("%s : %s" % [proposition.titre, texte_effet(proposition.id)])
	return "Aucune amélioration acquise." if lignes.is_empty() else "\n".join(lignes)
