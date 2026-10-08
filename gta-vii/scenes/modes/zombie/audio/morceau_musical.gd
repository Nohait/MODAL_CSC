class_name MorceauMusicalZombie
extends Resource

@export var titre := "Morceau"
@export var couches: Array[CoucheMusicaleZombie] = []
# Passer l'introduction silencieuse avant de lancer les couches de combat.
@export_range(0.0, 1200.0, 0.1) var debut_lecture := 0.0
# Une durée commune évite que les pistes les plus courtes terminent le morceau.
@export_range(0.0, 1200.0, 0.1) var duree := 0.0
