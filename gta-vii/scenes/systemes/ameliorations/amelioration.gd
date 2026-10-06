class_name Amelioration
extends Resource

@export var identifiant: StringName
@export var titre := "Nouvelle amélioration"
@export_multiline var description := ""
@export var pictogramme: Texture2D
@export_flags("Classique", "Zombie") var modes := 3
@export var active := true
@export_enum("permanent", "temporaire") var type_bonus := "permanent"
@export_enum("degats", "charge", "recharge", "vie_max", "soin_joueur", "soin_victimes", "blindage_camion", "bouclier_camion", "jet_givre", "dernier_souffle", "bouclier_joueur", "reserve_secours", "escorte_agile", "sirene", "choc_thermique", "verglas", "gel_profond", "eclats_glace", "brise_glace", "mousse_persistante", "mousse_expansive", "enrobage", "reaction_chaine", "jet_pulse", "double_lance", "sillage_secours", "depart_pression", "freinage_urgence", "deuxieme_souffle", "intervention_eclair", "retour_pression", "surpression", "formation_serree", "passage_securise", "priorite_blesses", "courage_contagieux", "equipe_soutien", "extraction_urgence", "circuit_secours", "eau_glacee", "reseau_interconnecte", "reserve_collective", "zone_repli", "gyrophare_intervention", "maintenance_preventive") var effet := "degats"
@export_group("Obtention et rareté")
@export var obtention_unique := false
# Identifiants des cartes à obtenir avant que celle-ci entre dans les tirages.
@export var prerequis: Array[StringName] = []
# Les statistiques existent en trois versions ; les autres cartes gardent leur effet fixe.
@export var puissance_variable := true
@export_enum("commun", "rare", "epique", "legendaire") var rarete := "rare"
@export_group("Puissance")
# Valeur à 100 %, ou effet exact si Puissance variable est décoché.
@export_range(0.0, 1000.0, 0.1) var valeur := 20.0
# Zéro pour un effet immédiat ; les boucliers restent jusqu'à épuisement, sans durée.
@export_range(0, 20) var duree := 0
# %s reçoit le gain ; écrire %% pour afficher un signe pourcentage.
@export var texte_effet := "+%s %% de dégâts"

@export_group("Effets particuliers")
# Secondes pour le gel ou l'appel de la sirène, indépendantes des salles/vagues.
@export_range(0.1, 30.0, 0.1) var duree_effet := 1.0
@export_range(1.0, 60.0, 0.5) var intervalle := 10.0
# Dernier souffle compare la vie actuelle à la vie maximale.
@export_range(1.0, 100.0, 1.0) var seuil_vie := 25.0
