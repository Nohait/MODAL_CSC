extends CanvasLayer


signal ameliorations_changees


@export_group("Équilibrage — bonus de base par choix")

## Valeur d'un choix dégâts à puissance 100 %.
@export_range(0.0, 200.0, 1.0)
var bonus_degats_pourcent := 20.0

## Valeur d'un choix réserve à puissance 100 %.
@export_range(0.0, 200.0, 1.0)
var bonus_charge_pourcent := 25.0

## Valeur d'un choix recharge à puissance 100 %.
@export_range(0.0, 200.0, 1.0)
var bonus_recharge_pourcent := 20.0


@export_group("Puissance selon l'escorte")

## Nombre de victimes bénéficiant du premier palier.
@export_range(1, 20, 1)
var victimes_palier_principal := 4

## Puissance ajoutée par chacune des premières victimes.
## 50 signifie +50 % de la valeur de base de la carte.
@export_range(0.0, 200.0, 1.0)
var puissance_par_premiere_victime := 50.0

## Puissance ajoutée par chaque victime après le palier principal.
@export_range(0.0, 200.0, 1.0)
var puissance_par_victime_supplementaire := 25.0


const CARTE = preload(
	"res://scenes/interfaces/menus/ameliorations/carte_amelioration.tscn"
)


const POOL = [
	{
		"id": &"pression",
		"titre": "Sous pression",
		"description": "Un jet plus puissant pour repousser les flammes."
	},
	{
		"id": &"reserve",
		"titre": "Grande réserve",
		"description": "Plus de charge pour tenir face à l'incendie."
	},
	{
		"id": &"recharge",
		"titre": "Second souffle",
		"description": "Reprendre l'avantage avant que le feu ne gagne."
	}
]


@onready var room_manager = (
	$"../Salles/RoomManager"
)

@onready var extincteur = (
	$"../player".extincteur
)

@onready var menu: Control = $Menu

@onready var cartes: HBoxContainer = (
	$Menu/Defilement/Centre/Marge/Contenu/Cartes
)


# Le nombre de fois où chaque amélioration a été choisie.
# Conservé pour les éventuels menus/statistiques.
var niveaux := {
	&"pression": 0,
	&"reserve": 0,
	&"recharge": 0
}


# Contrairement à l'ancien système, deux choix du même type
# peuvent désormais avoir des puissances différentes.
#
# On conserve donc directement le pourcentage réellement acquis.
var bonus_cumules_pourcent := {
	&"pression": 0.0,
	&"reserve": 0.0,
	&"recharge": 0.0
}


var choix_ouverts := false

var souris_avant: int

var animation: Tween


var charge_de_base: float
var recharge_de_base: float


# Puissance du choix actuellement présenté.
# 0.5 = 50 %, 1.0 = 100 %, 2.0 = 200 %, etc.
var multiplicateur_choix_courant := 1.0

var victimes_choix_courant := 0


func _ready() -> void:
	menu.hide()

	charge_de_base = extincteur.max_charge
	recharge_de_base = extincteur.reload_rate

	room_manager.choix_amelioration_demande.connect(
		ouvrir_choix
	)


func ouvrir_choix(
	nombre_victimes: int
) -> void:

	if choix_ouverts:
		return

	# Sécurité supplémentaire :
	# normalement le RoomManager n'émet même pas le signal à zéro.
	if nombre_victimes <= 0:
		room_manager.call_deferred(
			"passer_salle_suivante"
		)

		return


	victimes_choix_courant = nombre_victimes

	multiplicateur_choix_courant = (
		calculer_multiplicateur_bonus(
			nombre_victimes
		)
	)


	choix_ouverts = true

	extincteur.stop_primary_attack()


	var propositions: Array = (
		POOL.duplicate()
	)

	propositions.shuffle()


	for proposition in propositions.slice(
		0,
		3
	):
		var carte = CARTE.instantiate()

		carte.identifiant = proposition.id
		carte.titre = proposition.titre
		carte.description = proposition.description

		# La carte affiche directement le vrai bonus
		# correspondant à l'escorte actuelle.
		carte.effet_affiche = (
			texte_effet_choix(
				proposition.id
			)
		)

		carte.selected.connect(
			_choisir.bind(carte)
		)

		cartes.add_child(
			carte
		)


	souris_avant = Input.mouse_mode

	Input.mouse_mode = (
		Input.MOUSE_MODE_VISIBLE
	)

	get_tree().paused = true


	menu.modulate.a = 0.0
	menu.show()


	animation = create_tween()

	animation.tween_property(
		menu,
		"modulate:a",
		1.0,
		0.2
	)


func _choisir(
	carte: Control
) -> void:

	if (
		not choix_ouverts
		or carte.get_parent() != cartes
	):
		return


	choix_ouverts = false


	appliquer_amelioration(
		carte.identifiant
	)


	if animation:
		animation.kill()


	menu.hide()


	for enfant in cartes.get_children():
		enfant.release_focus()

		cartes.remove_child(
			enfant
		)

		enfant.queue_free()


	Input.mouse_mode = souris_avant

	get_tree().paused = false


	room_manager.call_deferred(
		"passer_salle_suivante"
	)


func calculer_multiplicateur_bonus(
	nombre_victimes: int
) -> float:

	if nombre_victimes <= 0:
		return 0.0


	var premieres := mini(
		nombre_victimes,
		victimes_palier_principal
	)


	var supplementaires := maxi(
		nombre_victimes
		- victimes_palier_principal,
		0
	)


	var puissance_pourcent := (
		premieres
		* puissance_par_premiere_victime
		+ supplementaires
		* puissance_par_victime_supplementaire
	)


	return (
		puissance_pourcent
		/ 100.0
	)


func valeur_base(
	identifiant: StringName
) -> float:

	match identifiant:
		&"pression":
			return bonus_degats_pourcent

		&"reserve":
			return bonus_charge_pourcent

		&"recharge":
			return bonus_recharge_pourcent

	return 0.0


func appliquer_amelioration(
	identifiant: StringName
) -> void:

	if not niveaux.has(
		identifiant
	):
		return


	niveaux[identifiant] += 1


	var gain_pourcent := (
		valeur_base(identifiant)
		* multiplicateur_choix_courant
	)


	bonus_cumules_pourcent[
		identifiant
	] += gain_pourcent


	match identifiant:
		&"pression":
			extincteur.multiplicateur_degats_ameliorations = (
				1.0
				+ bonus_cumules_pourcent[
					identifiant
				]
				/ 100.0
			)


		&"reserve":
			var ancien_max: float = (
				extincteur.max_charge
			)

			extincteur.max_charge = (
				charge_de_base
				* (
					1.0
					+ bonus_cumules_pourcent[
						identifiant
					]
					/ 100.0
				)
			)

			# Comme avant :
			# on donne uniquement la capacité nouvellement gagnée.
			extincteur.charge += (
				extincteur.max_charge
				- ancien_max
			)


		&"recharge":
			extincteur.reload_rate = (
				recharge_de_base
				* (
					1.0
					+ bonus_cumules_pourcent[
						identifiant
					]
					/ 100.0
				)
			)


	ameliorations_changees.emit()


func formater_pourcentage(
	valeur: float
) -> String:

	return String.num(
		valeur,
		2
	).trim_suffix(".0")


func formater_effet(
	identifiant: StringName,
	pourcentage: float
) -> String:

	var nombre := (
		formater_pourcentage(
			pourcentage
		)
	)

	match identifiant:
		&"pression":
			return (
				"+%s %% de dégâts"
				% nombre
			)

		&"reserve":
			return (
				"+%s %% de charge maximale"
				% nombre
			)

		&"recharge":
			return (
				"+%s %% de vitesse de recharge"
				% nombre
			)

	return ""


# Fonction conservée avec son ancien comportement général :
# "nombre" copies du bonus de base.
func texte_effet(
	identifiant: StringName,
	nombre: int = 1
) -> String:

	return formater_effet(
		identifiant,
		valeur_base(identifiant)
		* nombre
	)


func texte_effet_choix(
	identifiant: StringName
) -> String:

	return formater_effet(
		identifiant,
		valeur_base(identifiant)
		* multiplicateur_choix_courant
	)


func get_resume() -> String:
	var lignes := PackedStringArray()


	for proposition in POOL:
		var total: float = (
			bonus_cumules_pourcent[
				proposition.id
			]
		)

		if total <= 0.0:
			continue

		lignes.append(
			"%s : %s"
			% [
				proposition.titre,
				formater_effet(
					proposition.id,
					total
				)
			]
		)


	if lignes.is_empty():
		return (
			"Aucune amélioration acquise."
		)


	return "\n".join(
		lignes
	)
