extends CanvasLayer

signal ameliorations_changees

@export_group("Équilibrage — bonus par choix")
# Saisir 20 pour +20 %. Les cartes lisent aussi ces valeurs.
@export_range(0.0, 200.0, 1.0) var bonus_degats_pourcent := 20.0
@export_range(0.0, 200.0, 1.0) var bonus_charge_pourcent := 25.0
@export_range(0.0, 200.0, 1.0) var bonus_recharge_pourcent := 20.0

const CARTE = preload("res://scenes/interfaces/menus/ameliorations/carte_amelioration.tscn")
# Le pool peut grandir : on mélange une copie, puis on prend trois choix distincts.
const POOL = [
	{"id": &"pression", "titre": "Sous pression", "description": "Un jet plus puissant pour repousser les flammes."},
	{"id": &"reserve", "titre": "Grande réserve", "description": "Plus de charge pour tenir face à l'incendie."},
	{"id": &"recharge", "titre": "Second souffle", "description": "Reprendre l'avantage avant que le feu ne gagne."}
]

@onready var room_manager = $"../Salles/RoomManager"
@onready var extincteur = $"../player".extincteur
@onready var menu: Control = $Menu
@onready var cartes: HBoxContainer = $Menu/Defilement/Centre/Marge/Contenu/Cartes

# Compter les choix permet un cumul simple : deux choix dégâts donnent +40 %.
var niveaux := {&"pression": 0, &"reserve": 0, &"recharge": 0}
var choix_ouverts := false
var souris_avant: int
var animation: Tween
var charge_de_base: float
var recharge_de_base: float


func _ready() -> void:
	menu.hide()
	charge_de_base = extincteur.max_charge
	recharge_de_base = extincteur.reload_rate
	room_manager.choix_amelioration_demande.connect(ouvrir_choix)


func ouvrir_choix() -> void:
	if choix_ouverts:
		return
	choix_ouverts = true
	extincteur.stop_primary_attack()
	var propositions: Array = POOL.duplicate()
	propositions.shuffle()
	for proposition in propositions.slice(0, 3):
		var carte = CARTE.instantiate()
		carte.identifiant = proposition.id
		carte.titre = proposition.titre
		carte.description = proposition.description
		carte.effet_affiche = texte_effet(proposition.id)
		# bind mémorise la carte concernée par CE signal.
		carte.selected.connect(_choisir.bind(carte))
		cartes.add_child(carte)
	souris_avant = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	menu.modulate.a = 0.0
	menu.show()
	# Le gestionnaire est Always : le fondu et les cartes vivent pendant la pause.
	animation = create_tween()
	animation.tween_property(menu, "modulate:a", 1.0, 0.2)
	cartes.get_child(0).grab_focus()


func _choisir(carte: Control) -> void:
	# Fermer le verrou immédiatement empêche un double clic de donner deux bonus.
	if not choix_ouverts or carte.get_parent() != cartes:
		return
	choix_ouverts = false
	appliquer_amelioration(carte.identifiant)
	if animation:
		animation.kill()
	menu.hide()
	for enfant in cartes.get_children():
		enfant.release_focus()
		cartes.remove_child(enfant)
		enfant.queue_free()
	Input.mouse_mode = souris_avant
	# La transition attend des images physiques : retirer la pause AVANT de la lancer.
	get_tree().paused = false
	room_manager.call_deferred("passer_salle_suivante")


func appliquer_amelioration(identifiant: StringName) -> void:
	if not niveaux.has(identifiant):
		return
	niveaux[identifiant] += 1
	match identifiant:
		&"pression":
			extincteur.multiplicateur_degats_ameliorations = 1.0 + bonus_degats_pourcent / 100.0 * niveaux[identifiant]
		&"reserve":
			var ancien_max: float = extincteur.max_charge
			extincteur.max_charge = charge_de_base * (1.0 + bonus_charge_pourcent / 100.0 * niveaux[identifiant])
			# Donner la capacité gagnée, sans remplir gratuitement toute la réserve.
			extincteur.charge += extincteur.max_charge - ancien_max
		&"recharge":
			extincteur.reload_rate = recharge_de_base * (1.0 + bonus_recharge_pourcent / 100.0 * niveaux[identifiant])
	ameliorations_changees.emit()


# Un seul endroit produit les pourcentages des cartes et du récapitulatif.
func texte_effet(identifiant: StringName, nombre: int = 1) -> String:
	match identifiant:
		&"pression":
			return "+%s %% de dégâts" % String.num(bonus_degats_pourcent * nombre, 2).trim_suffix(".0")
		&"reserve":
			return "+%s %% de charge maximale" % String.num(bonus_charge_pourcent * nombre, 2).trim_suffix(".0")
		&"recharge":
			return "+%s %% de vitesse de recharge" % String.num(bonus_recharge_pourcent * nombre, 2).trim_suffix(".0")
	return ""


func get_resume() -> String:
	var lignes := PackedStringArray()
	for proposition in POOL:
		var nombre: int = niveaux[proposition.id]
		if nombre > 0:
			lignes.append("%s : %s" % [proposition.titre, texte_effet(proposition.id, nombre)])
	return "\n".join(lignes) if not lignes.is_empty() else "Aucune amélioration acquise. Franchissez une porte après avoir libéré une salle."
