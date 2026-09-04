extends Node

class_name Inventory

signal inventory_changed

const ItemDatabase := preload("res://scripts/inventory/ItemDatabase.gd")

const MAX_SLOTS := 32
var slots: Array = []

func _ready() -> void:
    add_to_group("inventory")
    clear()

func clear() -> void:
    slots.clear()
    for i in range(MAX_SLOTS):
        slots.append({"item_id": "", "quantity": 0})
    emit_signal("inventory_changed")

func add_item(item_id: String, amount: int = 1) -> bool:
    if amount <= 0 or not ItemDatabase.has(item_id):
        return false
    var remaining: int = amount
    var stack_limit: int = ItemDatabase.stack_size(item_id)
    for slot in slots:
        if slot["item_id"] == item_id and slot["quantity"] < stack_limit:
            var capacity: int = stack_limit - int(slot["quantity"])
            var to_add: int = mini(capacity, remaining)
            slot["quantity"] = int(slot["quantity"]) + to_add
            remaining -= to_add
            if remaining == 0:
                break
    if remaining > 0:
        for slot in slots:
            if slot["item_id"] == "" or slot["quantity"] == 0:
                var to_add: int = mini(stack_limit, remaining)
                slot["item_id"] = item_id
                slot["quantity"] = to_add
                remaining -= to_add
                if remaining == 0:
                    break
    if remaining > 0:
        return false
    emit_signal("inventory_changed")
    return true

func add_item_to_slot(slot_index: int, item_id: String, amount: int = 1) -> bool:
    if slot_index < 0 or slot_index >= slots.size():
        return false
    if amount <= 0 or not ItemDatabase.has(item_id):
        return false

    var stack_limit := ItemDatabase.stack_size(item_id)
    if amount > stack_limit:
        return false

    var slot: Dictionary = slots[slot_index]
    if slot["item_id"] not in ["", item_id]:
        return false
    if int(slot["quantity"]) + amount > stack_limit:
        return false

    slot["item_id"] = item_id
    slot["quantity"] = int(slot["quantity"]) + amount
    slots[slot_index] = slot
    emit_signal("inventory_changed")
    return true

func has_items(requirements: Dictionary) -> bool:
    for item_id in requirements.keys():
        var needed := int(requirements[item_id])
        if _count_item(item_id) < needed:
            return false
    return true

func remove_items(requirements: Dictionary) -> bool:
    if not has_items(requirements):
        return false
    for item_id in requirements.keys():
        var needed: int = int(requirements[item_id])
        for slot in slots:
            if slot["item_id"] == item_id and slot["quantity"] > 0:
                var consumed: int = mini(int(slot["quantity"]), needed)
                slot["quantity"] = int(slot["quantity"]) - consumed
                needed -= consumed
                if slot["quantity"] == 0:
                    slot["item_id"] = ""
                if needed == 0:
                    break
    emit_signal("inventory_changed")
    return true

func _count_item(item_id: String) -> int:
    var total := 0
    for slot in slots:
        if slot["item_id"] == item_id:
            total += slot["quantity"]
    return total

func get_item_count(item_id: String) -> int:
    return _count_item(item_id)

func serialize_items() -> Array[Dictionary]:
    var items: Array[Dictionary] = []
    for index in range(slots.size()):
        var slot: Dictionary = slots[index]
        if str(slot.get("item_id", "")).is_empty() or int(slot.get("quantity", 0)) <= 0:
            continue
        items.append({
            "slot": index,
            "id": slot.get("item_id", ""),
            "count": slot.get("quantity", 0),
        })
    return items

func deserialize_items(items_data: Array) -> void:
    slots.clear()
    for i in range(MAX_SLOTS):
        slots.append({"item_id": "", "quantity": 0})

    for item_data in items_data:
        var slot_index := int(item_data.get("slot", -1))
        var item_id := str(item_data.get("id", ""))
        var count := int(item_data.get("count", 0))
        if slot_index < 0 or slot_index >= slots.size():
            continue
        if count <= 0 or not ItemDatabase.has(item_id):
            continue
        slots[slot_index] = {"item_id": item_id, "quantity": count}

    emit_signal("inventory_changed")

func get_slot(index: int) -> Dictionary:
    if index < 0 or index >= slots.size():
        return {"item_id": "", "quantity": 0}
    var slot: Dictionary = slots[index] as Dictionary
    return {"item_id": slot["item_id"], "quantity": slot["quantity"]}
