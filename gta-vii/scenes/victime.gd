extends CharacterBody3D



func _on_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Le joueur est proche de la victime")
