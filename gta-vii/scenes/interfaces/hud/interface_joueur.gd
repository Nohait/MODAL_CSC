extends CanvasLayer

# L’interface lit l’arme ; elle ne modifie ni sa charge, ni sa recharge.
@onready var extincteur = $"../visual/weapon_holder/Extincteur"
@onready var jauge = $Reserve/Jauge
@onready var etat: Label = $Reserve/Etat
@onready var BarreDeVie = $Vie/BarreDeVie
@export var vie_max := 100.0

func _ready() -> void:
	jauge.max_value = extincteur.max_charge
	BarreDeVie.max_value = vie_max
	BarreDeVie.value = vie_max
	# Le flash du cadre se produit uniquement si le joueur perd réellement des PV.
	get_parent().degats_recus.connect(BarreDeVie.reagir_aux_degats)
	maj_affichage()

func _process(_delta: float) -> void:
	maj_affichage()

func maj_affichage() -> void:
	# La capacité peut changer après l’achat d’une amélioration.
	jauge.max_value = extincteur.max_charge
	jauge.value = extincteur.charge
	var recharge: bool = not extincteur.is_attacking and extincteur.charge < extincteur.max_charge
	jauge.afficher_recharge(recharge)
	if extincteur.is_overheated:
		jauge.couleur = Color(0.9, 0.32, 0.19)
		etat.text = "SURCHAUFFE · Recharge complète requise"
		etat.modulate = Color(1, 0.6, 0.4)
	else:
		jauge.couleur = Color(0.86, 0.8, 0.64)
		etat.modulate = Color.WHITE
		if extincteur.is_attacking:
			etat.text = "JET EN COURS"
		elif recharge:
			etat.text = "RECHARGE EN COURS"
		else:
			etat.text = "PRÊT"
