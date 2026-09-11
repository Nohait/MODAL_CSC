extends CanvasLayer

# L'interface ne fait que lire l'état actuel de l'arme
@onready var extincteur = $"../visual/weapon_holder/Extincteur"
@onready var jauge: ProgressBar = $Reserve/Jauge
@onready var etat: Label = $Reserve/Etat
# Le joueur calcule le cooldown effectif ; l'interface ne fait que l'afficher.
@onready var joueur = get_parent()
@onready var bonus_escorte: Label = $BonusEscorte

@onready var BarreDeVie: ProgressBar = $Vie/BarreDeVie
@export var vie_max := 100.0
var vie := vie_max

const COULEUR_VIE = Color(0.188, 0.541, 0.8, 1.0)

const COULEUR_NORMALE_EXTINCTEUR = Color(0.273, 0.562, 0.0, 1.0)
const COULEUR_SURCHAUFFE_EXTINCTEUR = Color(1.0, 0.35, 0.3)


func _ready() -> void:
	jauge.max_value = extincteur.max_charge
	BarreDeVie.max_value = vie_max
	BarreDeVie.value = vie

	
	maj_affichage()
	
	


func _process(_delta: float) -> void:
	# On recopie la charge à chaque image
	maj_affichage()


func maj_affichage() -> void:
	# Le bonus est un état continu, comme la jauge : on reflète sa valeur à chaque image.
	if joueur.bonus_dash_actif:
		bonus_escorte.text = "Escorte : dash -20 %% (%.2f s)" % joueur.get_dash_cooldown()
	else:
		bonus_escorte.text = "Escorte : aucun bonus"
	jauge.value = extincteur.charge

	# Feedback utilisateur sur la surchauffe :
	if extincteur.is_overheated:
		#sel_modulate permet de ne modifier que la couleur de la jauge
		jauge.self_modulate = COULEUR_SURCHAUFFE_EXTINCTEUR
		etat.text = "Surchauffe — recharge complète requise"
	elif extincteur.is_attacking:
		jauge.self_modulate = COULEUR_NORMALE_EXTINCTEUR
		etat.text = "Jet en cours"
	elif extincteur.charge < extincteur.max_charge:
		jauge.self_modulate = COULEUR_NORMALE_EXTINCTEUR
		etat.text = "Recharge en cours"
	else:
		jauge.self_modulate = COULEUR_NORMALE_EXTINCTEUR
		etat.text = "Prêt"
