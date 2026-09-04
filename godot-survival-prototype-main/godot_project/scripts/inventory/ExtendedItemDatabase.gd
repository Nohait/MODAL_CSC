extends Node

## ExtendedItemDatabase - Comprehensive item definitions for the entire game
## All weapons, armor, consumables, resources, and special items

class_name ExtendedItemDatabase

# ============================================================================
# ITEM CATEGORIES
# ============================================================================

enum ItemType {
	WEAPON_MELEE,
	WEAPON_RANGED,
	ARMOR,
	CONSUMABLE,
	RESOURCE,
	BLUEPRINT,
	TOOL,
	AMMO,
	QUEST,
	SPECIAL
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC
}

# ============================================================================
# BASE ITEM STRUCTURE
# ============================================================================

const ITEM_TEMPLATE := {
	"id": "",
	"name": "",
	"description": "",
	"type": ItemType.RESOURCE,
	"rarity": Rarity.COMMON,
	"icon": "",
	"stack_size": 1,
	"weight": 1.0,
	"value": 0,
	
	# Equipment stats (for weapons/armor)
	"damage": 0,
	"attack_speed": 1.0,
	"range": 1.0,
	"durability": 100,
	"armor": 0,
	"slot": "",  # head, torso, legs, feet, hands, weapon, offhand
	
	# Consumable effects
	"health_restore": 0,
	"stamina_restore": 0,
	"hunger_restore": 0,
	"thirst_restore": 0,
	"effects": [],  # Status effects applied
	
	# Crafting
	"craftable": false,
	"craft_time": 0.0,
	"craft_station": "",
	"recipe": {},
	
	# Requirements
	"level_required": 1,
	"skills_required": {}
}

# ============================================================================
# COMPLETE ITEM DATABASE
# ============================================================================

const ITEMS := {
	# ==========================================================================
	# MELEE WEAPONS
	# ==========================================================================
	"fists": {
		"id": "fists",
		"name": "Bare Fists",
		"description": "Your bare hands. Better than nothing.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/fists.png",
		"stack_size": 1,
		"damage": 5,
		"attack_speed": 1.5,
		"range": 0.5,
		"durability": -1,  # Infinite
		"slot": "weapon"
	},
	"wood_club": {
		"id": "wood_club",
		"name": "Wooden Club",
		"description": "A crude wooden club. Simple but effective.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/wood_club.png",
		"stack_size": 1,
		"damage": 12,
		"attack_speed": 1.0,
		"range": 1.0,
		"durability": 50,
		"slot": "weapon",
		"craftable": true,
		"craft_time": 5.0,
		"recipe": {"wood": 5}
	},
	"stone_knife": {
		"id": "stone_knife",
		"name": "Stone Knife",
		"description": "A sharpened stone blade. Good for cutting.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/stone_knife.png",
		"stack_size": 1,
		"damage": 10,
		"attack_speed": 1.3,
		"range": 0.7,
		"durability": 40,
		"slot": "weapon",
		"craftable": true,
		"craft_time": 8.0,
		"recipe": {"stone": 3, "wood": 2}
	},
	"makeshift_spear": {
		"id": "makeshift_spear",
		"name": "Makeshift Spear",
		"description": "A sharpened stick. Keeps enemies at bay.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/spear.png",
		"stack_size": 1,
		"damage": 15,
		"attack_speed": 0.9,
		"range": 1.8,
		"durability": 35,
		"slot": "weapon",
		"craftable": true,
		"craft_time": 10.0,
		"recipe": {"wood": 6, "fibers": 2}
	},
	"iron_hatchet": {
		"id": "iron_hatchet",
		"name": "Iron Hatchet",
		"description": "A sturdy iron hatchet. Great for wood and skulls.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/hatchet.png",
		"stack_size": 1,
		"damage": 22,
		"attack_speed": 1.1,
		"range": 1.0,
		"durability": 100,
		"slot": "weapon",
		"craftable": true,
		"craft_time": 30.0,
		"craft_station": "workbench_basic",
		"recipe": {"iron_ore": 5, "wood": 3}
	},
	"machete": {
		"id": "machete",
		"name": "Machete",
		"description": "A sharp jungle machete. Slices through anything.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/machete.png",
		"stack_size": 1,
		"damage": 28,
		"attack_speed": 1.2,
		"range": 1.2,
		"durability": 80,
		"slot": "weapon",
		"craftable": true,
		"craft_time": 45.0,
		"craft_station": "workbench_basic",
		"recipe": {"steel_ingot": 4, "rubber": 1}
	},
	"baseball_bat": {
		"id": "baseball_bat",
		"name": "Baseball Bat",
		"description": "Classic aluminum bat. Home run!",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/baseball_bat.png",
		"stack_size": 1,
		"damage": 25,
		"attack_speed": 1.0,
		"range": 1.3,
		"durability": 120,
		"slot": "weapon"
	},
	"crowbar": {
		"id": "crowbar",
		"name": "Crowbar",
		"description": "Heavy steel crowbar. Multi-purpose tool.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/crowbar.png",
		"stack_size": 1,
		"damage": 24,
		"attack_speed": 0.9,
		"range": 1.1,
		"durability": 150,
		"slot": "weapon"
	},
	"fire_axe": {
		"id": "fire_axe",
		"name": "Fire Axe",
		"description": "Heavy firefighter's axe. Devastating power.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/fire_axe.png",
		"stack_size": 1,
		"damage": 45,
		"attack_speed": 0.7,
		"range": 1.4,
		"durability": 100,
		"slot": "weapon"
	},
	"katana": {
		"id": "katana",
		"name": "Katana",
		"description": "Traditional Japanese sword. Swift and deadly.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/katana.png",
		"stack_size": 1,
		"damage": 42,
		"attack_speed": 1.4,
		"range": 1.5,
		"durability": 80,
		"slot": "weapon",
		"level_required": 15
	},
	"chainsaw": {
		"id": "chainsaw",
		"name": "Chainsaw",
		"description": "Roaring chainsaw. Loud but devastating.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.EPIC,
		"icon": "res://assets/icons/chainsaw.png",
		"stack_size": 1,
		"damage": 65,
		"attack_speed": 0.8,
		"range": 1.2,
		"durability": 60,
		"slot": "weapon",
		"level_required": 25,
		"craftable": true,
		"craft_time": 180.0,
		"craft_station": "workbench_advanced",
		"recipe": {"steel_ingot": 10, "electronics": 5, "polymer": 3}
	},
	"energy_sword": {
		"id": "energy_sword",
		"name": "Energy Blade",
		"description": "Experimental plasma blade. Cuts through anything.",
		"type": ItemType.WEAPON_MELEE,
		"rarity": Rarity.LEGENDARY,
		"icon": "res://assets/icons/energy_sword.png",
		"stack_size": 1,
		"damage": 95,
		"attack_speed": 1.3,
		"range": 1.6,
		"durability": 200,
		"slot": "weapon",
		"level_required": 50,
		"effects": [{"type": "burn", "chance": 0.3, "damage": 5, "duration": 3}]
	},
	
	# ==========================================================================
	# RANGED WEAPONS
	# ==========================================================================
	"slingshot": {
		"id": "slingshot",
		"name": "Slingshot",
		"description": "Simple slingshot. Quiet and uses rocks as ammo.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/slingshot.png",
		"stack_size": 1,
		"damage": 8,
		"attack_speed": 1.2,
		"range": 15.0,
		"durability": 50,
		"slot": "weapon",
		"ammo_type": "stone",
		"craftable": true,
		"craft_time": 15.0,
		"recipe": {"wood": 3, "rubber": 2}
	},
	"wood_bow": {
		"id": "wood_bow",
		"name": "Wooden Bow",
		"description": "Handcrafted hunting bow. Silent and reliable.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/bow.png",
		"stack_size": 1,
		"damage": 18,
		"attack_speed": 0.8,
		"range": 25.0,
		"durability": 60,
		"slot": "weapon",
		"ammo_type": "arrow",
		"craftable": true,
		"craft_time": 30.0,
		"recipe": {"wood": 8, "fibers": 5}
	},
	"compound_bow": {
		"id": "compound_bow",
		"name": "Compound Bow",
		"description": "Modern hunting bow. Powerful and accurate.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/compound_bow.png",
		"stack_size": 1,
		"damage": 32,
		"attack_speed": 0.7,
		"range": 35.0,
		"durability": 100,
		"slot": "weapon",
		"ammo_type": "arrow"
	},
	"crossbow": {
		"id": "crossbow",
		"name": "Crossbow",
		"description": "Heavy crossbow. Slow but devastating.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/crossbow.png",
		"stack_size": 1,
		"damage": 55,
		"attack_speed": 0.4,
		"range": 40.0,
		"durability": 80,
		"slot": "weapon",
		"ammo_type": "bolt",
		"level_required": 10
	},
	"pistol_9mm": {
		"id": "pistol_9mm",
		"name": "9mm Pistol",
		"description": "Standard semi-automatic pistol.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/pistol.png",
		"stack_size": 1,
		"damage": 22,
		"attack_speed": 1.5,
		"range": 20.0,
		"durability": 100,
		"slot": "weapon",
		"ammo_type": "ammo_9mm",
		"magazine_size": 15
	},
	"revolver": {
		"id": "revolver",
		"name": ".44 Magnum",
		"description": "Powerful revolver. Makes a statement.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/revolver.png",
		"stack_size": 1,
		"damage": 45,
		"attack_speed": 0.8,
		"range": 25.0,
		"durability": 120,
		"slot": "weapon",
		"ammo_type": "ammo_44",
		"magazine_size": 6,
		"level_required": 15
	},
	"shotgun_pump": {
		"id": "shotgun_pump",
		"name": "Pump Shotgun",
		"description": "12-gauge pump-action shotgun. Close range devastation.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/shotgun.png",
		"stack_size": 1,
		"damage": 65,
		"attack_speed": 0.6,
		"range": 12.0,
		"durability": 100,
		"slot": "weapon",
		"ammo_type": "ammo_12g",
		"magazine_size": 8,
		"spread": 15.0,
		"pellets": 8,
		"level_required": 20
	},
	"rifle_hunting": {
		"id": "rifle_hunting",
		"name": "Hunting Rifle",
		"description": "Bolt-action rifle with scope. Precision at range.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/rifle.png",
		"stack_size": 1,
		"damage": 75,
		"attack_speed": 0.5,
		"range": 80.0,
		"durability": 80,
		"slot": "weapon",
		"ammo_type": "ammo_762",
		"magazine_size": 5,
		"level_required": 25,
		"scope_zoom": 4.0
	},
	"assault_rifle": {
		"id": "assault_rifle",
		"name": "Assault Rifle",
		"description": "Military assault rifle. Full auto capability.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.EPIC,
		"icon": "res://assets/icons/assault_rifle.png",
		"stack_size": 1,
		"damage": 28,
		"attack_speed": 3.5,
		"range": 50.0,
		"durability": 120,
		"slot": "weapon",
		"ammo_type": "ammo_556",
		"magazine_size": 30,
		"level_required": 35
	},
	"sniper_rifle": {
		"id": "sniper_rifle",
		"name": "Sniper Rifle",
		"description": "High-powered sniper rifle. One shot, one kill.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.EPIC,
		"icon": "res://assets/icons/sniper.png",
		"stack_size": 1,
		"damage": 150,
		"attack_speed": 0.3,
		"range": 150.0,
		"durability": 60,
		"slot": "weapon",
		"ammo_type": "ammo_50bmg",
		"magazine_size": 5,
		"level_required": 40,
		"scope_zoom": 8.0
	},
	"minigun": {
		"id": "minigun",
		"name": "Minigun",
		"description": "Six-barreled rotary machine gun. Absolute destruction.",
		"type": ItemType.WEAPON_RANGED,
		"rarity": Rarity.LEGENDARY,
		"icon": "res://assets/icons/minigun.png",
		"stack_size": 1,
		"damage": 15,
		"attack_speed": 10.0,
		"range": 40.0,
		"durability": 200,
		"slot": "weapon",
		"ammo_type": "ammo_556",
		"magazine_size": 200,
		"level_required": 60,
		"movement_penalty": 0.5
	},
	
	# ==========================================================================
	# ARMOR - HEAD
	# ==========================================================================
	"bandana": {
		"id": "bandana",
		"name": "Bandana",
		"description": "Simple cloth bandana. Minimal protection.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/bandana.png",
		"stack_size": 1,
		"armor": 2,
		"durability": 30,
		"slot": "head",
		"craftable": true,
		"craft_time": 10.0,
		"recipe": {"cloth": 3}
	},
	"cap": {
		"id": "cap",
		"name": "Baseball Cap",
		"description": "Regular cap. Not much protection.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/cap.png",
		"stack_size": 1,
		"armor": 3,
		"durability": 40,
		"slot": "head"
	},
	"motorcycle_helmet": {
		"id": "motorcycle_helmet",
		"name": "Motorcycle Helmet",
		"description": "Full-face bike helmet. Good protection.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/motorcycle_helmet.png",
		"stack_size": 1,
		"armor": 12,
		"durability": 80,
		"slot": "head"
	},
	"combat_helmet": {
		"id": "combat_helmet",
		"name": "Combat Helmet",
		"description": "Military ballistic helmet. Serious protection.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/combat_helmet.png",
		"stack_size": 1,
		"armor": 22,
		"durability": 100,
		"slot": "head",
		"level_required": 20
	},
	"night_vision_goggles": {
		"id": "night_vision_goggles",
		"name": "Night Vision Goggles",
		"description": "Military NVG. See in complete darkness.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.EPIC,
		"icon": "res://assets/icons/nvg.png",
		"stack_size": 1,
		"armor": 8,
		"durability": 60,
		"slot": "head",
		"level_required": 35,
		"effects": [{"type": "night_vision", "strength": 1.0}]
	},
	
	# ==========================================================================
	# ARMOR - TORSO
	# ==========================================================================
	"cloth_shirt": {
		"id": "cloth_shirt",
		"name": "Cloth Shirt",
		"description": "Basic cotton shirt. Barely any protection.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/cloth_shirt.png",
		"stack_size": 1,
		"armor": 3,
		"durability": 30,
		"slot": "torso",
		"craftable": true,
		"craft_time": 15.0,
		"recipe": {"cloth": 5}
	},
	"leather_jacket": {
		"id": "leather_jacket",
		"name": "Leather Jacket",
		"description": "Sturdy leather jacket. Decent protection.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/leather_jacket.png",
		"stack_size": 1,
		"armor": 12,
		"durability": 80,
		"slot": "torso",
		"craftable": true,
		"craft_time": 60.0,
		"craft_station": "workbench_basic",
		"recipe": {"leather": 8, "cloth": 3}
	},
	"kevlar_vest": {
		"id": "kevlar_vest",
		"name": "Kevlar Vest",
		"description": "Police ballistic vest. Good bullet resistance.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/kevlar_vest.png",
		"stack_size": 1,
		"armor": 28,
		"durability": 100,
		"slot": "torso",
		"level_required": 20
	},
	"tactical_vest": {
		"id": "tactical_vest",
		"name": "Tactical Vest",
		"description": "Military tactical vest with pouches.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.EPIC,
		"icon": "res://assets/icons/tactical_vest.png",
		"stack_size": 1,
		"armor": 38,
		"durability": 120,
		"slot": "torso",
		"level_required": 35,
		"extra_inventory_slots": 4
	},
	"power_armor_chest": {
		"id": "power_armor_chest",
		"name": "Power Armor Chestpiece",
		"description": "Experimental powered armor. Maximum protection.",
		"type": ItemType.ARMOR,
		"rarity": Rarity.LEGENDARY,
		"icon": "res://assets/icons/power_armor.png",
		"stack_size": 1,
		"armor": 65,
		"durability": 200,
		"slot": "torso",
		"level_required": 60,
		"effects": [{"type": "strength_boost", "value": 5}]
	},
	
	# ==========================================================================
	# CONSUMABLES
	# ==========================================================================
	"bandage": {
		"id": "bandage",
		"name": "Bandage",
		"description": "Basic wound dressing. Heals minor wounds.",
		"type": ItemType.CONSUMABLE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/bandage.png",
		"stack_size": 20,
		"health_restore": 15,
		"craftable": true,
		"craft_time": 5.0,
		"recipe": {"cloth": 2}
	},
	"first_aid_kit": {
		"id": "first_aid_kit",
		"name": "First Aid Kit",
		"description": "Complete first aid supplies.",
		"type": ItemType.CONSUMABLE,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/first_aid.png",
		"stack_size": 10,
		"health_restore": 40,
		"craftable": true,
		"craft_time": 20.0,
		"craft_station": "workbench_basic",
		"recipe": {"cloth": 5, "alcohol": 2}
	},
	"medkit": {
		"id": "medkit",
		"name": "Military Medkit",
		"description": "Professional medical kit. Full treatment.",
		"type": ItemType.CONSUMABLE,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/medkit.png",
		"stack_size": 5,
		"health_restore": 75
	},
	"adrenaline_shot": {
		"id": "adrenaline_shot",
		"name": "Adrenaline Shot",
		"description": "Emergency stimulant. Temporary boost.",
		"type": ItemType.CONSUMABLE,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/adrenaline.png",
		"stack_size": 5,
		"health_restore": 25,
		"stamina_restore": 100,
		"effects": [{"type": "speed_boost", "value": 0.3, "duration": 30}]
	},
	"water_bottle": {
		"id": "water_bottle",
		"name": "Water Bottle",
		"description": "Purified drinking water.",
		"type": ItemType.CONSUMABLE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/water.png",
		"stack_size": 10,
		"thirst_restore": 30
	},
	"canned_food": {
		"id": "canned_food",
		"name": "Canned Food",
		"description": "Preserved canned goods. Long shelf life.",
		"type": ItemType.CONSUMABLE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/canned_food.png",
		"stack_size": 10,
		"hunger_restore": 25
	},
	"cooked_meat": {
		"id": "cooked_meat",
		"name": "Cooked Meat",
		"description": "Well-prepared meat. Nutritious.",
		"type": ItemType.CONSUMABLE,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/cooked_meat.png",
		"stack_size": 5,
		"hunger_restore": 45,
		"health_restore": 10,
		"craftable": true,
		"craft_time": 30.0,
		"craft_station": "campfire",
		"recipe": {"raw_meat": 1}
	},
	"mre_pack": {
		"id": "mre_pack",
		"name": "MRE Pack",
		"description": "Military ration. Complete meal.",
		"type": ItemType.CONSUMABLE,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/mre.png",
		"stack_size": 5,
		"hunger_restore": 75,
		"thirst_restore": 25,
		"stamina_restore": 20
	},
	
	# ==========================================================================
	# RESOURCES
	# ==========================================================================
	"wood": {
		"id": "wood",
		"name": "Wood",
		"description": "Basic timber. Essential crafting material.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/wood.png",
		"stack_size": 99,
		"weight": 0.5,
		"value": 1
	},
	"stone": {
		"id": "stone",
		"name": "Stone",
		"description": "Raw stone. Used for tools and building.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/stone.png",
		"stack_size": 99,
		"weight": 0.8,
		"value": 1
	},
	"fibers": {
		"id": "fibers",
		"name": "Plant Fibers",
		"description": "Natural plant fibers. Used for rope and cloth.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/fibers.png",
		"stack_size": 99,
		"weight": 0.1,
		"value": 1
	},
	"cloth": {
		"id": "cloth",
		"name": "Cloth",
		"description": "Fabric material. For clothing and bandages.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/cloth.png",
		"stack_size": 50,
		"weight": 0.2,
		"value": 3,
		"craftable": true,
		"craft_time": 10.0,
		"recipe": {"fibers": 5}
	},
	"leather": {
		"id": "leather",
		"name": "Leather",
		"description": "Animal hide leather. For armor and gear.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/leather.png",
		"stack_size": 30,
		"weight": 0.4,
		"value": 8
	},
	"iron_ore": {
		"id": "iron_ore",
		"name": "Iron Ore",
		"description": "Raw iron ore. Smelt into ingots.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/iron_ore.png",
		"stack_size": 50,
		"weight": 1.0,
		"value": 5
	},
	"steel_ingot": {
		"id": "steel_ingot",
		"name": "Steel Ingot",
		"description": "Refined steel bar. For advanced crafting.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/steel_ingot.png",
		"stack_size": 30,
		"weight": 1.2,
		"value": 20,
		"craftable": true,
		"craft_time": 60.0,
		"craft_station": "forge",
		"recipe": {"iron_ore": 3, "coal": 2}
	},
	"electronics": {
		"id": "electronics",
		"name": "Electronics",
		"description": "Electronic components. For advanced devices.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/electronics.png",
		"stack_size": 20,
		"weight": 0.3,
		"value": 25
	},
	"gunpowder": {
		"id": "gunpowder",
		"name": "Gunpowder",
		"description": "Explosive compound. For ammunition.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/gunpowder.png",
		"stack_size": 50,
		"weight": 0.2,
		"value": 15,
		"craftable": true,
		"craft_time": 30.0,
		"craft_station": "chemistry_station",
		"recipe": {"charcoal": 3, "sulfur": 2, "saltpeter": 1}
	},
	"titanium": {
		"id": "titanium",
		"name": "Titanium",
		"description": "Rare titanium alloy. Extremely durable.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.EPIC,
		"icon": "res://assets/icons/titanium.png",
		"stack_size": 20,
		"weight": 0.8,
		"value": 100
	},
	"polymer": {
		"id": "polymer",
		"name": "Advanced Polymer",
		"description": "Synthetic polymer. For high-tech equipment.",
		"type": ItemType.RESOURCE,
		"rarity": Rarity.EPIC,
		"icon": "res://assets/icons/polymer.png",
		"stack_size": 20,
		"weight": 0.3,
		"value": 75
	},
	
	# ==========================================================================
	# AMMUNITION
	# ==========================================================================
	"arrow": {
		"id": "arrow",
		"name": "Arrow",
		"description": "Wooden arrow for bows.",
		"type": ItemType.AMMO,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/arrow.png",
		"stack_size": 50,
		"craftable": true,
		"craft_time": 5.0,
		"recipe": {"wood": 2, "fibers": 1}
	},
	"bolt": {
		"id": "bolt",
		"name": "Crossbow Bolt",
		"description": "Metal bolt for crossbows.",
		"type": ItemType.AMMO,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/bolt.png",
		"stack_size": 30,
		"craftable": true,
		"craft_time": 10.0,
		"recipe": {"iron_ore": 2, "wood": 1}
	},
	"ammo_9mm": {
		"id": "ammo_9mm",
		"name": "9mm Rounds",
		"description": "Standard 9mm pistol ammunition.",
		"type": ItemType.AMMO,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/ammo_9mm.png",
		"stack_size": 100,
		"craftable": true,
		"craft_time": 20.0,
		"craft_station": "workbench_basic",
		"recipe": {"iron_ore": 2, "gunpowder": 3}
	},
	"ammo_556": {
		"id": "ammo_556",
		"name": "5.56mm Rounds",
		"description": "Military rifle ammunition.",
		"type": ItemType.AMMO,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/ammo_556.png",
		"stack_size": 100,
		"craftable": true,
		"craft_time": 30.0,
		"craft_station": "workbench_advanced",
		"recipe": {"steel_ingot": 2, "gunpowder": 5}
	},
	"ammo_12g": {
		"id": "ammo_12g",
		"name": "12 Gauge Shells",
		"description": "Shotgun shells.",
		"type": ItemType.AMMO,
		"rarity": Rarity.RARE,
		"icon": "res://assets/icons/ammo_12g.png",
		"stack_size": 50
	},
	
	# ==========================================================================
	# TOOLS
	# ==========================================================================
	"pickaxe": {
		"id": "pickaxe",
		"name": "Pickaxe",
		"description": "Stone mining pickaxe.",
		"type": ItemType.TOOL,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/pickaxe.png",
		"stack_size": 1,
		"durability": 100,
		"damage": 8,
		"slot": "weapon",
		"tool_type": "mining",
		"gather_bonus": 0.25,
		"craftable": true,
		"craft_time": 20.0,
		"recipe": {"wood": 5, "stone": 8}
	},
	"hatchet": {
		"id": "hatchet",
		"name": "Hatchet",
		"description": "Wood chopping hatchet.",
		"type": ItemType.TOOL,
		"rarity": Rarity.COMMON,
		"icon": "res://assets/icons/hatchet.png",
		"stack_size": 1,
		"durability": 100,
		"damage": 12,
		"slot": "weapon",
		"tool_type": "chopping",
		"gather_bonus": 0.25,
		"craftable": true,
		"craft_time": 20.0,
		"recipe": {"wood": 5, "stone": 5}
	},
	"flashlight": {
		"id": "flashlight",
		"name": "Flashlight",
		"description": "Battery-powered flashlight.",
		"type": ItemType.TOOL,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/flashlight.png",
		"stack_size": 1,
		"durability": 200,
		"effects": [{"type": "light", "radius": 100}]
	},
	"lockpick": {
		"id": "lockpick",
		"name": "Lockpick",
		"description": "Set of lockpicks. For opening locked containers.",
		"type": ItemType.TOOL,
		"rarity": Rarity.UNCOMMON,
		"icon": "res://assets/icons/lockpick.png",
		"stack_size": 10,
		"durability": 1
	}
}

# ============================================================================
# API
# ============================================================================

static func get_item(item_id: String) -> Dictionary:
	if ITEMS.has(item_id):
		var item: Dictionary = ITEMS[item_id].duplicate(true)
		return item
	return {}

static func has_item(item_id: String) -> bool:
	return ITEMS.has(item_id)

static func get_by_type(item_type: ItemType) -> Array:
	var results := []
	for item_id in ITEMS:
		if ITEMS[item_id].get("type", -1) == item_type:
			results.append(item_id)
	return results

static func get_by_rarity(rarity: Rarity) -> Array:
	var results := []
	for item_id in ITEMS:
		if ITEMS[item_id].get("rarity", Rarity.COMMON) == rarity:
			results.append(item_id)
	return results

static func get_craftable() -> Array:
	var results := []
	for item_id in ITEMS:
		if ITEMS[item_id].get("craftable", false):
			results.append(item_id)
	return results

static func stack_size(item_id: String) -> int:
	var item := get(item_id)
	return item.get("stack_size", 1) if item else 1

static func get_all_ids() -> Array:
	return ITEMS.keys()
