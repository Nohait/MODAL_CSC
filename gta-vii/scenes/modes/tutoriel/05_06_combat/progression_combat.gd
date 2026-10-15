extends Node

signal consigne_changee
signal rencontre_demandee
signal sortie_autorisee
signal salle_reussie

@export_range(5.0, 30.0, 1.0) var intervalle_conseils := 10.0
@export var autonome := false
@export var fin_provisoire := true
var joueur: CharacterBody3D
var ennemi: CharacterBody3D
var etat := "observation"
var rencontres_terminees := 0
var rappel := ""
var temps_conseil := 0.0
var temps_tir_sans_effet := 0.0
var vie_precedente := 0.0
var contact_dangereux := false

func preparer(personnage: CharacterBody3D) -> void:
	joueur = personnage
	joueur.degats_recus.connect(_sur_degats)
	consigne_changee.emit()

func commencer() -> void:
	if etat != "observation": return
	etat = "learning"
	consigne_changee.emit()
	rencontre_demandee.emit()

func surveiller(creature: CharacterBody3D) -> void:
	ennemi = creature
	vie_precedente = ennemi.vie
	temps_tir_sans_effet = 0
	contact_dangereux = false
	ennemi.died.connect(_sur_defaite, CONNECT_ONE_SHOT)

func _sur_defaite() -> void:
	if etat != "learning": return
	ennemi = null
	rencontres_terminees += 1
	rappel = ""
	etat = "transition"
	consigne_changee.emit()
	# Sortir du signal de mort avant de modifier les collisions de la salle.
	# Aucun second spawn ni attente suspendue sur un nœud en cours de destruction.
	call_deferred("_terminer_rencontre")

func _terminer_rencontre() -> void:
	if etat != "transition" or not is_instance_valid(joueur) or joueur.BarreDeVie.value <= 0: return
	etat = "sortie"
	sortie_autorisee.emit()
	consigne_changee.emit()

func consigne() -> String:
	if autonome and etat == "observation": return "Avancez à votre rythme. Ouvrez la porte avec E quand vous êtes prêt."
	if autonome and etat == "learning": return "Dégagez la pièce pour continuer."
	if not fin_provisoire and etat == "sortie": return "La créature est vaincue. Rejoignez le palier pour poursuivre."
	if not fin_provisoire and etat == "reussi": return "La voie est libre. Poursuivez à votre rythme."
	match etat:
		"observation": return "Une créature rôde derrière la porte. Ouvrez-la quand vous êtes prêt · E."
		"learning": return "La mousse atteint aussi les créatures. Gardez vos distances."
		"transition": return "La créature est vaincue."
		"sortie": return "La créature est vaincue. Rejoignez la sortie. Vous en rencontrerez d’autres plus tard."
		"reussi": return "La voie est libre. L’équipe prend le relais."
	return ""

func atteindre_sortie() -> void:
	if etat != "sortie" or joueur.BarreDeVie.value <= 0: return
	etat = "reussi"
	rappel = ""
	consigne_changee.emit()
	salle_reussie.emit()

func _sur_degats(_quantite: float) -> void:
	if is_instance_valid(ennemi) and joueur.global_position.distance_to(ennemi.global_position) < 2.5:
		contact_dangereux = true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(joueur) or joueur.BarreDeVie.value <= 0: return
	if etat != "learning": return
	if not is_instance_valid(ennemi): return
	temps_conseil += delta
	var arme = joueur.extincteur
	if ennemi.vie < vie_precedente:
		temps_tir_sans_effet = 0
	elif arme.is_attacking and not arme.is_overheated:
		temps_tir_sans_effet += delta
	else:
		temps_tir_sans_effet = maxf(0, temps_tir_sans_effet - delta)
	vie_precedente = ennemi.vie
	if temps_conseil < intervalle_conseils: return
	var conseil := ""
	if arme.is_overheated or arme.charge <= 0:
		conseil = "Relâchez le tir pour laisser la réserve se reconstituer."
	elif contact_dangereux and joueur.global_position.distance_to(ennemi.global_position) < 2.5:
		conseil = "Déplacez-vous et prenez de la distance pour éviter les coups."
	elif temps_tir_sans_effet >= 3:
		conseil = "Rapprochez-vous juste assez : le jet doit atteindre la créature. Visez-la en gardant vos distances."
	if not conseil.is_empty() or not rappel.is_empty():
		rappel = conseil
		temps_conseil = 0
		contact_dangereux = false
		temps_tir_sans_effet = 0
		consigne_changee.emit()
