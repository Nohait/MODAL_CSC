class_name ProfilAmbiance
extends Resource

@export var nom := "Ambiance"
@export var sons: Array[AudioStream] = []
@export var boucle := false
@export_range(0.0, 900.0, 0.5) var attente_min := 180.0
@export_range(0.0, 900.0, 0.5) var attente_max := 360.0
@export var attente_initiale_distincte := false
@export var conserver_attente_entre_salles := false
@export_range(0.0, 900.0, 0.5) var attente_initiale_min := 15.0
@export_range(0.0, 900.0, 0.5) var attente_initiale_max := 30.0
@export_range(-45.0, 0.0, 1.0) var volume_db := -24.0
@export_range(1.0, 15.0, 0.5) var distance_reference := 5.0
@export_range(3.0, 60.0, 1.0) var portee := 25.0
@export_range(0.0, 3.0, 0.05) var hauteur := 1.0
@export_range(0.5, 1.5, 0.01) var vitesse_min := 0.96
@export_range(0.5, 1.5, 0.01) var vitesse_max := 1.04
@export_range(0.05, 8.0, 0.05) var fondu := 0.3
@export var resonance := false
