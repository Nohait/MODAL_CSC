extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if not Engine.get_meta("tutoriel_debug_actif", false) and not Engine.has_meta("tutoriel_debug_historique"): return
	if Engine.has_meta("tutoriel_debug_depart") and Reglages.chargement.en_cours: return
	var scene := get_tree().current_scene
	if not is_instance_valid(scene) or scene.scene_file_path.is_empty(): return
	if scene.get("session_tutoriel") == true: return
	if Engine.has_meta("tutoriel_debug_depart"): Engine.remove_meta("tutoriel_debug_depart")
	Engine.remove_meta("tutoriel_debug_historique")
	if not Engine.get_meta("tutoriel_debug_actif", false): return
	Engine.remove_meta("tutoriel_debug_actif")
	Engine.time_scale = 1.0
	get_tree().debug_collisions_hint = false
	get_tree().debug_navigation_hint = false
