extends Node

class_name ExpeditionSystem

const IdleEconomyConfig = preload("res://scripts/idle/IdleEconomyConfig.gd")

signal expedition_started(zone_id: String, finish_unix: int)
signal expedition_resolved(result: Dictionary)

func start_expedition(state: Dictionary, zone_id: String, now_unix: int) -> Dictionary:
	var active_expedition: Dictionary = state.get("active_expedition", {})
	if not active_expedition.is_empty():
		return {"ok": false, "reason": "A team is already in the field."}

	if not IdleEconomyConfig.is_zone_unlocked(state, zone_id):
		return {"ok": false, "reason": IdleEconomyConfig.get_zone_unlock_reason(state, zone_id)}

	var zone_def: Dictionary = IdleEconomyConfig.get_zone_def(zone_id)
	var supply_cost: Dictionary = zone_def.get("supply_cost", {})
	var resources: Dictionary = state.get("resources", {})
	if not IdleEconomyConfig.can_afford(resources, supply_cost):
		return {"ok": false, "reason": "Not enough food or water to launch."}

	IdleEconomyConfig.spend_resources(state, supply_cost)
	var expedition := {
		"zone_id": zone_id,
		"title": zone_def.get("title", zone_id.capitalize()),
		"started_unix": now_unix,
		"finish_unix": now_unix + int(zone_def.get("duration_seconds", 0)),
		"risk": zone_def.get("risk", "Low"),
	}
	state["active_expedition"] = expedition

	expedition_started.emit(zone_id, int(expedition.get("finish_unix", now_unix)))
	return {"ok": true, "expedition": expedition}

func resolve_ready(state: Dictionary, now_unix: int) -> Dictionary:
	var active_expedition: Dictionary = state.get("active_expedition", {})
	if active_expedition.is_empty():
		return {}

	if now_unix < int(active_expedition.get("finish_unix", now_unix + 1)):
		return {}

	var zone_id := str(active_expedition.get("zone_id", "green"))
	var zone_def: Dictionary = IdleEconomyConfig.get_zone_def(zone_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%s:%s" % [zone_id, now_unix]))
	var outcome := _roll_outcome(zone_def.get("outcomes", {}), rng)
	var rewards := _build_rewards(zone_def, outcome, rng)

	for resource_id in rewards.keys():
		IdleEconomyConfig.add_resource(state, str(resource_id), float(rewards.get(resource_id, 0.0)))

	var result := {
		"zone_id": zone_id,
		"title": zone_def.get("title", zone_id.capitalize()),
		"outcome": outcome,
		"rewards": rewards,
	}
	state["active_expedition"] = {}

	if outcome != "failure":
		var ftue: Dictionary = state.get("ftue", {})
		ftue["first_expedition_complete"] = true
		state["ftue"] = ftue

	expedition_resolved.emit(result)
	return result

func _roll_outcome(outcome_weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total_weight := 0
	for key in outcome_weights.keys():
		total_weight += int(outcome_weights.get(key, 0))

	if total_weight <= 0:
		return "full"

	var roll := rng.randi_range(1, total_weight)
	var running := 0
	for outcome in outcome_weights.keys():
		running += int(outcome_weights.get(outcome, 0))
		if roll <= running:
			return str(outcome)

	return "full"

func _build_rewards(zone_def: Dictionary, outcome: String, rng: RandomNumberGenerator) -> Dictionary:
	var multiplier := 1.0
	match outcome:
		"partial":
			multiplier = 0.65
		"injury":
			multiplier = 0.45
		"failure":
			multiplier = 0.0
		"jackpot":
			multiplier = 1.35

	var resolved := {}
	var reward_ranges: Dictionary = zone_def.get("reward_ranges", {})
	for resource_id in reward_ranges.keys():
		var range_value: Vector2 = reward_ranges.get(resource_id, Vector2.ZERO)
		var rolled_amount := rng.randi_range(int(range_value.x), int(range_value.y))
		var amount := snapped(float(rolled_amount) * multiplier, 0.1)
		if amount > 0.0:
			resolved[resource_id] = amount

	if outcome == "jackpot":
		resolved["survivor_credits"] = float(resolved.get("survivor_credits", 0.0)) + 3.0

	return resolved
