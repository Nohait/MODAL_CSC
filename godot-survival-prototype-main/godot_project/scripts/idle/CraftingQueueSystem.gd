extends Node

class_name CraftingQueueSystem

const IdleEconomyConfig = preload("res://scripts/idle/IdleEconomyConfig.gd")
const MAX_QUEUE_SIZE := 3

signal craft_started(recipe_id: String, finish_unix: int)
signal craft_completed(recipe_id: String, outputs: Dictionary)

func can_queue_recipe(state: Dictionary, recipe_id: String) -> Dictionary:
	var recipe: Dictionary = IdleEconomyConfig.get_recipe_def(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "reason": "Unknown recipe."}

	if IdleEconomyConfig.get_room_level(state, "workshop") <= 0:
		return {"ok": false, "reason": "Workshop is offline."}

	var queue: Array = state.get("craft_queue", [])
	if queue.size() >= MAX_QUEUE_SIZE:
		return {"ok": false, "reason": "Crafting queue full."}

	var resources: Dictionary = state.get("resources", {})
	var inputs: Dictionary = recipe.get("inputs", {})
	if not IdleEconomyConfig.can_afford(resources, inputs):
		return {"ok": false, "reason": "Not enough materials."}

	return {"ok": true, "reason": ""}

func queue_craft(state: Dictionary, recipe_id: String, now_unix: int) -> Dictionary:
	var check := can_queue_recipe(state, recipe_id)
	if not bool(check.get("ok", false)):
		return check

	var recipe: Dictionary = IdleEconomyConfig.get_recipe_def(recipe_id)
	IdleEconomyConfig.spend_resources(state, recipe.get("inputs", {}))

	var queue: Array = state.get("craft_queue", [])
	var previous_finish := now_unix
	if not queue.is_empty():
		var last_job: Dictionary = queue[queue.size() - 1]
		previous_finish = max(previous_finish, int(last_job.get("finish_unix", now_unix)))

	var finish_unix := previous_finish + int(recipe.get("duration_seconds", 0))
	var job := {
		"recipe_id": recipe_id,
		"title": recipe.get("title", recipe_id.capitalize()),
		"finish_unix": finish_unix,
	}
	queue.append(job)
	state["craft_queue"] = queue

	craft_started.emit(recipe_id, finish_unix)
	return {"ok": true, "job": job}

func resolve_ready(state: Dictionary, now_unix: int) -> Array:
	var queue: Array = state.get("craft_queue", [])
	if queue.is_empty():
		return []

	var remaining: Array = []
	var completed: Array = []
	for job in queue:
		var job_dict: Dictionary = job
		if now_unix < int(job_dict.get("finish_unix", now_unix + 1)):
			remaining.append(job_dict)
			continue

		var recipe_id := str(job_dict.get("recipe_id", ""))
		var recipe: Dictionary = IdleEconomyConfig.get_recipe_def(recipe_id)
		var outputs: Dictionary = recipe.get("outputs", {})
		var resolved_outputs := {}
		for resource_id in outputs.keys():
			var amount := float(outputs.get(resource_id, 0.0))
			var added := IdleEconomyConfig.add_resource(state, str(resource_id), amount)
			if added > 0.0:
				resolved_outputs[resource_id] = added

		completed.append({
			"recipe_id": recipe_id,
			"title": recipe.get("title", recipe_id.capitalize()),
			"outputs": resolved_outputs,
		})
		craft_completed.emit(recipe_id, resolved_outputs)

	if not completed.is_empty():
		var ftue: Dictionary = state.get("ftue", {})
		ftue["first_craft_complete"] = true
		state["ftue"] = ftue

	state["craft_queue"] = remaining
	return completed
