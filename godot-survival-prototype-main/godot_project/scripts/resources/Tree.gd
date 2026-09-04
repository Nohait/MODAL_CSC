extends Harvestable
class_name TreeResource
## Harvestable tree - drops wood when destroyed

func _init() -> void:
	hp = 50.0
	drops = [{"item_id": "wood", "min_count": 3, "max_count": 5}]


func _play_hit_effect() -> void:
	if not mesh_pivot:
		return
	
	# Tree-specific effect: rotation shake
	var tween := create_tween()
	tween.tween_property(mesh_pivot, "rotation_degrees:z", 5.0, 0.1)
	tween.tween_property(mesh_pivot, "rotation_degrees:z", -5.0, 0.1)
	tween.tween_property(mesh_pivot, "rotation_degrees:z", 0.0, 0.1)
