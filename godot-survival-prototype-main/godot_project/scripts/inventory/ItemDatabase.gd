extends Node

class_name ItemDatabase

# Icon constants - only load icons that exist
const ICON_WOOD: Texture2D = preload("res://assets/icons/wood.png")
const ICON_STONE: Texture2D = preload("res://assets/icons/stone.png")
const ICON_FIBERS: Texture2D = preload("res://assets/icons/fibers.png")
const ICON_NONE: Texture2D = null

const ITEMS := {
    "wood": {"name": "Wood", "description": "Basic timber for crafting.", "icon": ICON_WOOD, "stack_size": 99},
    "stone": {"name": "Stone", "description": "Rough stone ore.", "icon": ICON_STONE, "stack_size": 99},
    "fibers": {"name": "Fibers", "description": "Plant fibers for crafting.", "icon": ICON_FIBERS, "stack_size": 99},
    "zombie_flesh": {"name": "Zombie Flesh", "description": "Rotting flesh from the undead.", "icon": ICON_NONE, "stack_size": 32},
    "plank": {"name": "Plank", "description": "Processed wood piece.", "icon": ICON_NONE, "stack_size": 25},
    "planks": {"name": "Planks", "description": "Processed wood boards.", "icon": ICON_NONE, "stack_size": 25},
    "pickaxe": {"name": "Pickaxe", "description": "Simple stone pickaxe.", "icon": ICON_NONE, "stack_size": 1},
    "hatchet": {"name": "Hatchet", "description": "Wood chopping tool.", "icon": ICON_NONE, "stack_size": 1},
    "rope": {"name": "Rope", "description": "Bundle of fibers.", "icon": ICON_NONE, "stack_size": 10},
    "water": {"name": "Water", "description": "Clean drinking water for bunker operations.", "icon": ICON_NONE, "stack_size": 32},
    "food": {"name": "Food", "description": "Rations for bunker teams.", "icon": ICON_NONE, "stack_size": 32},
    "scrap": {"name": "Scrap", "description": "Recovered industrial salvage.", "icon": ICON_NONE, "stack_size": 48},
    "fuel": {"name": "Fuel", "description": "Fuel reserves for heavy-duty bunker work.", "icon": ICON_NONE, "stack_size": 24},
    "metal_parts": {"name": "Metal Parts", "description": "Processed metal components.", "icon": ICON_NONE, "stack_size": 24},
    "med_supplies": {"name": "Med Supplies", "description": "Medical stock for injured teams.", "icon": ICON_NONE, "stack_size": 12},
    "defense_kits": {"name": "Defense Kits", "description": "Improvised defensive equipment.", "icon": ICON_NONE, "stack_size": 12},
    "electronics": {"name": "Electronics", "description": "Rare electronics for advanced bunker systems.", "icon": ICON_NONE, "stack_size": 12},
    "signal_intel": {"name": "Signal Intel", "description": "Actionable radio intelligence from dangerous zones.", "icon": ICON_NONE, "stack_size": 12},
    "survivor_credits": {"name": "Survivor Credits", "description": "Soft currency earned through bunker progress.", "icon": ICON_NONE, "stack_size": 999}
}

static func get_item(item_id: String) -> Dictionary:
    return ITEMS.get(item_id, {})

static func has(item_id: String) -> bool:
    return ITEMS.has(item_id)

static func stack_size(item_id: String) -> int:
    var info: Dictionary = get_item(item_id)
    return info.get("stack_size", 1) if info else 1
