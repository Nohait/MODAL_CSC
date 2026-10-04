class_name Amelioration
extends Resource

@export var identifiant: StringName
@export var titre := "Nouvelle amélioration"
@export_multiline var description := ""
@export var pictogramme: Texture2D
@export_flags("Classique", "Zombie") var modes := 3
@export var active := true
@export_enum("permanent", "temporaire") var type_bonus := "permanent"
@export_enum("degats", "charge", "recharge", "vie_max", "soin_joueur", "soin_victimes", "blindage_camion", "bouclier_camion", "jet_givre", "dernier_souffle", "bouclier_joueur", "reserve_secours", "escorte_agile", "sirene") var effet := "degats"
# Valeur à puissance 100 %. Les raretés multiplient ce nombre.
@export_range(0.0, 1000.0, 1.0) var valeur := 20.0
# Zéro pour un soin immédiat ; sinon nombre de prochaines salles/vagues.
@export_range(0, 20) var duree := 0
# %s reçoit le gain ; écrire %% pour afficher un signe pourcentage.
@export var texte_effet := "+%s %% de dégâts"

@export_group("Effets particuliers")
# Secondes pour le gel ou l'appel de la sirène, indépendantes des salles/vagues.
@export_range(0.1, 30.0, 0.1) var duree_effet := 1.0
@export_range(1.0, 60.0, 0.5) var intervalle := 10.0
# Dernier souffle compare la vie actuelle à la vie maximale.
@export_range(1.0, 100.0, 1.0) var seuil_vie := 25.0
