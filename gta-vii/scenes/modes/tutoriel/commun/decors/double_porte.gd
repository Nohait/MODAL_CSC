extends StaticBody3D

signal ouverture_terminee
@export var deja_ouverte := false
var ouverture_declenchee := false
var ouverte := false
var charnieres: Array[Node3D] = []

func _ready() -> void:
	for cote in ["Gauche", "Droit"]:
		var charniere := Node3D.new()
		charniere.name = "Charniere" + cote
		add_child(charniere)
		charniere.position.x = -1.685 if cote == "Gauche" else 1.685
		get_node("Vantail" + cote).reparent(charniere, true)
		get_node("Poignee" + ("Gauche" if cote == "Gauche" else "Droite")).reparent(charniere, true)
		charnieres.append(charniere)
	if deja_ouverte:
		charnieres[0].rotation.y = -PI * 0.5
		charnieres[1].rotation.y = PI * 0.5
		$Collision.disabled = true
		ouverture_declenchee = true
		ouverte = true

func ouvrir() -> void:
	if ouverture_declenchee: return
	ouverture_declenchee = true
	# Les figurants attendent la fin réelle du mouvement des deux battants.
	var mouvement := create_tween().set_parallel(true)
	mouvement.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	mouvement.tween_property(charnieres[0], "rotation:y", -PI * 0.5, 0.8)
	mouvement.tween_property(charnieres[1], "rotation:y", PI * 0.5, 0.8)
	await mouvement.finished
	$Collision.set_deferred("disabled", true)
	ouverte = true
	ouverture_terminee.emit()
