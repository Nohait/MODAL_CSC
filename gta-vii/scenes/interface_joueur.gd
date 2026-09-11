extends CanvasLayer

# L'interface ne fait que lire l'état actuel de l'arme
@onready var extincteur = $"../visual/weapon_holder/Extincteur"
@onready var jauge: ProgressBar = $Reserve/Jauge
@onready var etat: Label = $Reserve/Etat

const COULEUR_NORMALE = Color(0.273, 0.562, 0.0, 1.0)
const COULEUR_SURCHAUFFE = Color(1.0, 0.35, 0.3)


func _ready() -> void:
	jauge.max_value = extincteur.max_charge
	maj_affichage()


func _process(_delta: float) -> void:
	# On recopie la charge à chaque image
	maj_affichage()


func maj_affichage() -> void:
	jauge.value = extincteur.charge

	# Feedback utilisateur sur la surchauffe :
	if extincteur.is_overheated:
		#sel_modulate permet de ne modifier que la couleur de la jauge
		jauge.self_modulate = COULEUR_SURCHAUFFE
		etat.text = "Surchauffe — recharge complète requise"
	elif extincteur.is_attacking:
		jauge.self_modulate = COULEUR_NORMALE
		etat.text = "Jet en cours"
	elif extincteur.charge < extincteur.max_charge:
		jauge.self_modulate = COULEUR_NORMALE
		etat.text = "Recharge en cours"
	else:
		jauge.self_modulate = COULEUR_NORMALE
		etat.text = "Prêt"
