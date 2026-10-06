extends EntreeEnnemisZombie

@export_range(0.0, 10.0, 0.01) var pose_fermee := 0.04
@export_range(0.0, 10.0, 0.01) var pose_ouverte := 3.0
@export_range(0.0, 0.5, 0.05) var debut_ouverture := 0.1
@export_range(0.2, 0.8, 0.05) var fin_ouverture := 0.35
@export_range(0.0, 0.8, 0.05) var debut_sortie := 0.35
@export_range(0.0, 5.0, 0.1) var energie_gyrophare := 1.8
@export_range(0.1, 3.0, 0.1) var periode_gyrophare := 0.7
@export_range(0.0, 5.0, 0.1) var energie_rampe := 1.2
@onready var gyrophare: OmniLight3D = $Gyrophare/Lumiere
@onready var lampe_rampe: OmniLight3D = $LumiereRampe
var lecteur: AnimationPlayer
var animation_rideau: StringName
var fraction_ouverte := 0.0
var temps_gyrophare := 0.0
var poussiere_lancee := false

func _ready() -> void:
	lecteur = $ModeleGarage.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if lecteur != null:
		for nom in lecteur.get_animation_list():
			if nom != "RESET":
				animation_rideau = nom
				break
		if not animation_rideau.is_empty():
			lecteur.play(animation_rideau)
			lecteur.pause()
	super._ready()
	# Le rideau coulisse : remplacer les coups sur les battants par une seule poussière.
	annonce_porte = null

func preparer(duree_totale: float) -> void:
	var avant := fraction_ouverte
	super.preparer(duree_totale)
	ouverture_depart = avant
	poussiere_lancee = false

func _portes() -> Node3D:
	# Le calendrier reste partagé ; seuls les anciens battants sont remplacés.
	return null

func _progression_sortie(progression: float) -> float:
	# Le calendrier d'ascenseur réservait seulement 20 % du temps à la sortie.
	# Ici les figurants marchent dès que le rideau est ouvert, au lieu d'être projetés.
	var debut := maxf(debut_sortie, fin_ouverture)
	return clampf((progression - debut) / maxf(0.01, 1.0 - debut), 0.0, 1.0)

func _process(delta: float) -> void:
	super._process(delta)
	temps_gyrophare += delta
	var annonce := occupee or ouverture_restante > 0.0 or fermeture_restante > 0.0
	gyrophare.light_energy = energie_gyrophare * (0.55 + 0.45 * sin(temps_gyrophare * TAU / periode_gyrophare)) if annonce else 0.0
	if annonce and fraction_ouverte > 0.02 and not poussiere_lancee:
		poussiere_lancee = true
		var poussiere: CPUParticles3D = $AnnoncePorte/Poussiere
		poussiere.restart()
		poussiere.emitting = true
	# La lumière révèle la rampe au fur et à mesure que le rideau se relève.
	lampe_rampe.light_energy = energie_rampe * fraction_ouverte

func _regler_portes(ouverture: float) -> void:
	if occupee:
		# Ouvrir assez tôt pour voir le rideau monter avant la sortie des figurants.
		var progression := clampf((temps / duree - debut_ouverture) / maxf(0.01, fin_ouverture - debut_ouverture), 0.0, 1.0)
		ouverture = lerpf(ouverture_depart, 1.0, progression)
	fraction_ouverte = clampf(ouverture, 0.0, 1.0)
	if lecteur == null or animation_rideau.is_empty(): return
	# Échantillonner la montée du vrai modèle évite de rejouer sa fermeture trop tôt.
	# Le calendrier appelle aussi cette fonction à l'envers pour refermer le rideau.
	lecteur.seek(lerpf(pose_fermee, pose_ouverte, fraction_ouverte), true)
