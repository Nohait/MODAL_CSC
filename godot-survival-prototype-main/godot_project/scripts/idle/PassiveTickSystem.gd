extends Node

class_name PassiveTickSystem

const IdleEconomyConfig = preload("res://scripts/idle/IdleEconomyConfig.gd")

signal passive_progress_applied(summary: Dictionary)

func apply_passive_progress(state: Dictionary, elapsed_seconds: float) -> Dictionary:
	var applied_seconds := clampf(elapsed_seconds, 0.0, float(IdleEconomyConfig.OFFLINE_CAP_SECONDS))
	var generated := {}

	if applied_seconds <= 0.0:
		return {
			"elapsed_seconds": 0.0,
			"generated": {},
		}

	for room_id in IdleEconomyConfig.ROOM_ORDER:
		var level := IdleEconomyConfig.get_room_level(state, room_id)
		if level <= 0:
			continue

		var rates: Dictionary = IdleEconomyConfig.get_room_production_rates(room_id, level)
		for resource_id in rates.keys():
			var produced := float(rates.get(resource_id, 0.0)) * applied_seconds / 60.0
			var added := IdleEconomyConfig.add_resource(state, str(resource_id), produced)
			if added > 0.0:
				generated[resource_id] = float(generated.get(resource_id, 0.0)) + added

	var summary := {
		"elapsed_seconds": applied_seconds,
		"generated": generated,
	}
	passive_progress_applied.emit(summary)
	return summary
