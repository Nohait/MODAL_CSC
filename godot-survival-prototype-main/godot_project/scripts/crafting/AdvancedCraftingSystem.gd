extends Node
class_name AdvancedCraftingSystemClass
## Handles blueprints, weapon/armor modifications, repairs, and research
## Extends base crafting with advanced mechanics

signal blueprint_learned(blueprint_id: String)
signal blueprint_discovered(blueprint_id: String)
signal modification_applied(item_id: String, mod_id: String)
signal item_repaired(item_id: String, durability: float)
signal research_started(research_id: String)
signal research_completed(research_id: String)
signal crafting_tier_unlocked(tier: int)

# ============================================================================
# BLUEPRINT SYSTEM
# ============================================================================

enum BlueprintRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

enum BlueprintCategory {
	WEAPON,
	ARMOR,
	TOOL,
	CONSUMABLE,
	BUILDING,
	VEHICLE,
	SPECIAL,
}

const BLUEPRINTS := {
	# ========== COMMON WEAPONS ==========
	"bp_wooden_bat": {
		"display_name": "Wooden Bat Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.COMMON,
		"unlocks_recipe": "wooden_bat",
		"description": "A basic melee weapon made from wood.",
		"tier": 1,
		"research_cost": {},
		"known_by_default": true,
	},
	"bp_wooden_spear": {
		"display_name": "Wooden Spear Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.COMMON,
		"unlocks_recipe": "wooden_spear",
		"description": "A primitive but effective weapon.",
		"tier": 1,
		"research_cost": {},
		"known_by_default": true,
	},
	"bp_stone_axe": {
		"display_name": "Stone Axe Blueprint",
		"category": BlueprintCategory.TOOL,
		"rarity": BlueprintRarity.COMMON,
		"unlocks_recipe": "stone_axe",
		"description": "Basic woodcutting tool.",
		"tier": 1,
		"research_cost": {},
		"known_by_default": true,
	},
	"bp_stone_pickaxe": {
		"display_name": "Stone Pickaxe Blueprint",
		"category": BlueprintCategory.TOOL,
		"rarity": BlueprintRarity.COMMON,
		"unlocks_recipe": "stone_pickaxe",
		"description": "Basic mining tool.",
		"tier": 1,
		"research_cost": {},
		"known_by_default": true,
	},
	
	# ========== UNCOMMON WEAPONS ==========
	"bp_machete": {
		"display_name": "Machete Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.UNCOMMON,
		"unlocks_recipe": "machete",
		"description": "Sharp blade useful for combat and clearing vegetation.",
		"tier": 2,
		"research_cost": {"scrap_metal": 5, "research_notes": 1},
	},
	"bp_crowbar": {
		"display_name": "Crowbar Blueprint",
		"category": BlueprintCategory.TOOL,
		"rarity": BlueprintRarity.UNCOMMON,
		"unlocks_recipe": "crowbar",
		"description": "Multi-purpose tool for prying and combat.",
		"tier": 2,
		"research_cost": {"scrap_metal": 3, "research_notes": 1},
	},
	"bp_makeshift_bow": {
		"display_name": "Makeshift Bow Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.UNCOMMON,
		"unlocks_recipe": "makeshift_bow",
		"description": "A simple ranged weapon.",
		"tier": 2,
		"research_cost": {"plant_fiber": 10, "research_notes": 1},
	},
	"bp_nail_bat": {
		"display_name": "Nail Bat Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.UNCOMMON,
		"unlocks_recipe": "nail_bat",
		"description": "A bat with nails for extra damage.",
		"tier": 2,
		"research_cost": {"nails": 10, "research_notes": 1},
	},
	
	# ========== RARE WEAPONS ==========
	"bp_katana": {
		"display_name": "Katana Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "katana",
		"description": "A masterfully crafted blade.",
		"tier": 3,
		"research_cost": {"steel_plate": 10, "research_notes": 5},
	},
	"bp_compound_bow": {
		"display_name": "Compound Bow Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "compound_bow",
		"description": "Advanced bow with improved accuracy and power.",
		"tier": 3,
		"research_cost": {"aluminum": 5, "polymer": 5, "research_notes": 5},
	},
	"bp_pistol": {
		"display_name": "Pistol Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "pistol",
		"description": "Basic firearm for self-defense.",
		"tier": 3,
		"research_cost": {"steel_plate": 8, "gears": 3, "research_notes": 5},
	},
	"bp_shotgun": {
		"display_name": "Shotgun Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "shotgun",
		"description": "Powerful close-range firearm.",
		"tier": 3,
		"research_cost": {"steel_plate": 12, "gears": 5, "research_notes": 8},
	},
	
	# ========== EPIC WEAPONS ==========
	"bp_assault_rifle": {
		"display_name": "Assault Rifle Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.EPIC,
		"unlocks_recipe": "assault_rifle",
		"description": "Military-grade automatic rifle.",
		"tier": 4,
		"research_cost": {"steel_plate": 20, "gears": 10, "electronics": 5, "research_notes": 15},
	},
	"bp_sniper_rifle": {
		"display_name": "Sniper Rifle Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.EPIC,
		"unlocks_recipe": "sniper_rifle",
		"description": "Long-range precision rifle.",
		"tier": 4,
		"research_cost": {"steel_plate": 25, "optics": 5, "research_notes": 15},
	},
	"bp_tactical_armor": {
		"display_name": "Tactical Armor Blueprint",
		"category": BlueprintCategory.ARMOR,
		"rarity": BlueprintRarity.EPIC,
		"unlocks_recipe": "tactical_armor",
		"description": "Military-grade body armor.",
		"tier": 4,
		"research_cost": {"kevlar": 10, "steel_plate": 15, "research_notes": 15},
	},
	
	# ========== LEGENDARY ITEMS ==========
	"bp_minigun": {
		"display_name": "Minigun Blueprint",
		"category": BlueprintCategory.WEAPON,
		"rarity": BlueprintRarity.LEGENDARY,
		"unlocks_recipe": "minigun",
		"description": "Heavy rotary weapon with devastating firepower.",
		"tier": 5,
		"research_cost": {"titanium": 20, "gears": 30, "electronics": 20, "research_notes": 50},
	},
	"bp_power_armor": {
		"display_name": "Power Armor Blueprint",
		"category": BlueprintCategory.ARMOR,
		"rarity": BlueprintRarity.LEGENDARY,
		"unlocks_recipe": "power_armor",
		"description": "Powered exoskeleton with maximum protection.",
		"tier": 5,
		"research_cost": {"titanium": 30, "electronics": 25, "power_cell": 10, "research_notes": 50},
	},
	
	# ========== COMMON ARMOR ==========
	"bp_cloth_armor": {
		"display_name": "Cloth Armor Blueprint",
		"category": BlueprintCategory.ARMOR,
		"rarity": BlueprintRarity.COMMON,
		"unlocks_recipe": "cloth_armor",
		"description": "Basic cloth protection.",
		"tier": 1,
		"research_cost": {},
		"known_by_default": true,
	},
	
	# ========== UNCOMMON ARMOR ==========
	"bp_leather_armor": {
		"display_name": "Leather Armor Blueprint",
		"category": BlueprintCategory.ARMOR,
		"rarity": BlueprintRarity.UNCOMMON,
		"unlocks_recipe": "leather_armor",
		"description": "Improved protection from tanned leather.",
		"tier": 2,
		"research_cost": {"leather": 10, "research_notes": 2},
	},
	"bp_padded_armor": {
		"display_name": "Padded Armor Blueprint",
		"category": BlueprintCategory.ARMOR,
		"rarity": BlueprintRarity.UNCOMMON,
		"unlocks_recipe": "padded_armor",
		"description": "Thick padding for impact protection.",
		"tier": 2,
		"research_cost": {"cloth": 15, "leather": 5, "research_notes": 2},
	},
	
	# ========== RARE ARMOR ==========
	"bp_metal_armor": {
		"display_name": "Metal Armor Blueprint",
		"category": BlueprintCategory.ARMOR,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "metal_armor",
		"description": "Heavy metal plate armor.",
		"tier": 3,
		"research_cost": {"steel_plate": 15, "leather": 5, "research_notes": 5},
	},
	"bp_swat_armor": {
		"display_name": "SWAT Armor Blueprint",
		"category": BlueprintCategory.ARMOR,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "swat_armor",
		"description": "Professional tactical protection.",
		"tier": 3,
		"research_cost": {"kevlar": 5, "steel_plate": 10, "research_notes": 8},
	},
	
	# ========== CONSUMABLES ==========
	"bp_medkit": {
		"display_name": "Medkit Blueprint",
		"category": BlueprintCategory.CONSUMABLE,
		"rarity": BlueprintRarity.UNCOMMON,
		"unlocks_recipe": "medkit",
		"description": "Professional medical supplies.",
		"tier": 2,
		"research_cost": {"medical_supplies": 5, "research_notes": 2},
	},
	"bp_antidote": {
		"display_name": "Antidote Blueprint",
		"category": BlueprintCategory.CONSUMABLE,
		"rarity": BlueprintRarity.UNCOMMON,
		"unlocks_recipe": "antidote",
		"description": "Cures poison and infections.",
		"tier": 2,
		"research_cost": {"herbs": 10, "research_notes": 2},
	},
	"bp_stim_pack": {
		"display_name": "Stim Pack Blueprint",
		"category": BlueprintCategory.CONSUMABLE,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "stim_pack",
		"description": "Powerful stimulant for combat boost.",
		"tier": 3,
		"research_cost": {"chemicals": 10, "adrenaline": 3, "research_notes": 5},
	},
	
	# ========== BUILDING ==========
	"bp_generator": {
		"display_name": "Generator Blueprint",
		"category": BlueprintCategory.BUILDING,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "generator",
		"description": "Fuel-powered electrical generator.",
		"tier": 3,
		"research_cost": {"engine_parts": 5, "electronics": 10, "research_notes": 8},
	},
	"bp_turret_basic": {
		"display_name": "Basic Turret Blueprint",
		"category": BlueprintCategory.BUILDING,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "turret_basic",
		"description": "Automated defense turret.",
		"tier": 3,
		"research_cost": {"steel_plate": 15, "electronics": 10, "gears": 8, "research_notes": 10},
	},
	"bp_solar_panel": {
		"display_name": "Solar Panel Blueprint",
		"category": BlueprintCategory.BUILDING,
		"rarity": BlueprintRarity.RARE,
		"unlocks_recipe": "solar_panel",
		"description": "Clean solar power generation.",
		"tier": 3,
		"research_cost": {"glass": 10, "electronics": 15, "copper_wire": 20, "research_notes": 10},
	},
	
	# ========== VEHICLE ==========
	"bp_chopper": {
		"display_name": "Chopper Blueprint",
		"category": BlueprintCategory.VEHICLE,
		"rarity": BlueprintRarity.EPIC,
		"unlocks_recipe": "chopper",
		"description": "Fast motorcycle for travel.",
		"tier": 4,
		"research_cost": {"engine_parts": 15, "steel_plate": 20, "rubber": 10, "research_notes": 20},
	},
	"bp_atv": {
		"display_name": "ATV Blueprint",
		"category": BlueprintCategory.VEHICLE,
		"rarity": BlueprintRarity.EPIC,
		"unlocks_recipe": "atv",
		"description": "All-terrain vehicle with storage.",
		"tier": 4,
		"research_cost": {"engine_parts": 20, "steel_plate": 25, "rubber": 15, "research_notes": 25},
	},
}


# ============================================================================
# MODIFICATION SYSTEM
# ============================================================================

enum ModSlot {
	BARREL,
	STOCK,
	GRIP,
	OPTIC,
	MAGAZINE,
	MUZZLE,
	BLADE,
	HANDLE,
	REINFORCEMENT,
	PADDING,
	PLATING,
}

const MODIFICATIONS := {
	# ========== BARREL MODS ==========
	"mod_barrel_extended": {
		"display_name": "Extended Barrel",
		"slot": ModSlot.BARREL,
		"stats": {"range": 0.2, "accuracy": 0.1},
		"tier": 2,
		"compatible": ["pistol", "rifle", "smg"],
		"craft_cost": {"steel_plate": 5, "screws": 3},
	},
	"mod_barrel_rifled": {
		"display_name": "Rifled Barrel",
		"slot": ModSlot.BARREL,
		"stats": {"accuracy": 0.25, "damage": 0.05},
		"tier": 3,
		"compatible": ["pistol", "rifle", "sniper"],
		"craft_cost": {"steel_plate": 8, "precision_parts": 2},
	},
	
	# ========== STOCK MODS ==========
	"mod_stock_tactical": {
		"display_name": "Tactical Stock",
		"slot": ModSlot.STOCK,
		"stats": {"accuracy": 0.15, "recoil": -0.1},
		"tier": 2,
		"compatible": ["rifle", "shotgun", "smg"],
		"craft_cost": {"polymer": 5, "aluminum": 3},
	},
	"mod_stock_padded": {
		"display_name": "Padded Stock",
		"slot": ModSlot.STOCK,
		"stats": {"recoil": -0.2, "comfort": 0.1},
		"tier": 2,
		"compatible": ["rifle", "shotgun", "sniper"],
		"craft_cost": {"polymer": 3, "leather": 5},
	},
	
	# ========== GRIP MODS ==========
	"mod_grip_ergonomic": {
		"display_name": "Ergonomic Grip",
		"slot": ModSlot.GRIP,
		"stats": {"handling": 0.15, "reload_speed": 0.05},
		"tier": 2,
		"compatible": ["pistol", "rifle", "smg", "shotgun"],
		"craft_cost": {"rubber": 3, "polymer": 2},
	},
	"mod_grip_vertical": {
		"display_name": "Vertical Grip",
		"slot": ModSlot.GRIP,
		"stats": {"stability": 0.2, "recoil": -0.1},
		"tier": 2,
		"compatible": ["rifle", "smg"],
		"craft_cost": {"polymer": 4, "screws": 2},
	},
	
	# ========== OPTIC MODS ==========
	"mod_optic_reddot": {
		"display_name": "Red Dot Sight",
		"slot": ModSlot.OPTIC,
		"stats": {"accuracy": 0.2},
		"tier": 2,
		"compatible": ["pistol", "rifle", "smg", "shotgun"],
		"craft_cost": {"glass": 3, "electronics": 2, "aluminum": 2},
	},
	"mod_optic_scope_2x": {
		"display_name": "2x Scope",
		"slot": ModSlot.OPTIC,
		"stats": {"accuracy": 0.3, "range": 0.15},
		"tier": 3,
		"compatible": ["rifle", "sniper"],
		"craft_cost": {"optics": 2, "aluminum": 3},
	},
	"mod_optic_scope_4x": {
		"display_name": "4x Scope",
		"slot": ModSlot.OPTIC,
		"stats": {"accuracy": 0.4, "range": 0.3},
		"tier": 3,
		"compatible": ["sniper"],
		"craft_cost": {"optics": 4, "aluminum": 5},
	},
	"mod_optic_scope_8x": {
		"display_name": "8x Scope",
		"slot": ModSlot.OPTIC,
		"stats": {"accuracy": 0.5, "range": 0.5},
		"tier": 4,
		"compatible": ["sniper"],
		"craft_cost": {"optics": 8, "titanium": 3},
	},
	
	# ========== MAGAZINE MODS ==========
	"mod_mag_extended": {
		"display_name": "Extended Magazine",
		"slot": ModSlot.MAGAZINE,
		"stats": {"ammo_capacity": 0.5},
		"tier": 2,
		"compatible": ["pistol", "rifle", "smg"],
		"craft_cost": {"steel_plate": 4, "spring": 2},
	},
	"mod_mag_quickdraw": {
		"display_name": "Quickdraw Magazine",
		"slot": ModSlot.MAGAZINE,
		"stats": {"reload_speed": 0.3},
		"tier": 2,
		"compatible": ["pistol", "rifle", "smg"],
		"craft_cost": {"aluminum": 4, "spring": 3},
	},
	"mod_mag_drum": {
		"display_name": "Drum Magazine",
		"slot": ModSlot.MAGAZINE,
		"stats": {"ammo_capacity": 1.0, "reload_speed": -0.2},
		"tier": 3,
		"compatible": ["rifle", "smg", "shotgun"],
		"craft_cost": {"steel_plate": 8, "spring": 5},
	},
	
	# ========== MUZZLE MODS ==========
	"mod_muzzle_suppressor": {
		"display_name": "Suppressor",
		"slot": ModSlot.MUZZLE,
		"stats": {"noise": -0.6, "damage": -0.05},
		"tier": 3,
		"compatible": ["pistol", "rifle", "smg", "sniper"],
		"craft_cost": {"steel_plate": 6, "aluminum": 4, "rubber": 2},
	},
	"mod_muzzle_compensator": {
		"display_name": "Compensator",
		"slot": ModSlot.MUZZLE,
		"stats": {"recoil": -0.2, "noise": 0.1},
		"tier": 2,
		"compatible": ["rifle", "smg"],
		"craft_cost": {"steel_plate": 5},
	},
	"mod_muzzle_brake": {
		"display_name": "Muzzle Brake",
		"slot": ModSlot.MUZZLE,
		"stats": {"recoil": -0.25, "accuracy": 0.05},
		"tier": 3,
		"compatible": ["rifle", "sniper"],
		"craft_cost": {"steel_plate": 6, "precision_parts": 1},
	},
	
	# ========== MELEE MODS ==========
	"mod_blade_sharpened": {
		"display_name": "Sharpened Edge",
		"slot": ModSlot.BLADE,
		"stats": {"damage": 0.15, "durability": -0.1},
		"tier": 2,
		"compatible": ["sword", "machete", "knife", "axe"],
		"craft_cost": {"whetstone": 2},
	},
	"mod_blade_serrated": {
		"display_name": "Serrated Edge",
		"slot": ModSlot.BLADE,
		"stats": {"damage": 0.1, "bleed_chance": 0.2},
		"tier": 2,
		"compatible": ["sword", "knife"],
		"craft_cost": {"steel_plate": 3, "file": 1},
	},
	"mod_blade_reinforced": {
		"display_name": "Reinforced Blade",
		"slot": ModSlot.BLADE,
		"stats": {"durability": 0.3, "damage": 0.05},
		"tier": 3,
		"compatible": ["sword", "machete", "axe"],
		"craft_cost": {"steel_plate": 6, "carbon": 2},
	},
	
	# ========== HANDLE MODS ==========
	"mod_handle_wrapped": {
		"display_name": "Wrapped Handle",
		"slot": ModSlot.HANDLE,
		"stats": {"handling": 0.15, "grip": 0.1},
		"tier": 1,
		"compatible": ["melee_all"],
		"craft_cost": {"leather": 3, "cloth": 2},
	},
	"mod_handle_extended": {
		"display_name": "Extended Handle",
		"slot": ModSlot.HANDLE,
		"stats": {"range": 0.1, "handling": -0.05},
		"tier": 2,
		"compatible": ["club", "axe", "hammer"],
		"craft_cost": {"wood": 5, "nails": 2},
	},
	
	# ========== ARMOR MODS ==========
	"mod_reinforcement_plate": {
		"display_name": "Steel Plates",
		"slot": ModSlot.REINFORCEMENT,
		"stats": {"armor": 0.2, "speed": -0.05},
		"tier": 2,
		"compatible": ["armor_all"],
		"craft_cost": {"steel_plate": 8, "screws": 4},
	},
	"mod_reinforcement_ceramic": {
		"display_name": "Ceramic Inserts",
		"slot": ModSlot.REINFORCEMENT,
		"stats": {"armor": 0.3},
		"tier": 3,
		"compatible": ["tactical_armor", "swat_armor"],
		"craft_cost": {"ceramic": 6, "kevlar": 2},
	},
	"mod_reinforcement_titanium": {
		"display_name": "Titanium Plating",
		"slot": ModSlot.REINFORCEMENT,
		"stats": {"armor": 0.35, "durability": 0.2},
		"tier": 4,
		"compatible": ["tactical_armor", "power_armor"],
		"craft_cost": {"titanium": 10},
	},
	
	"mod_padding_comfort": {
		"display_name": "Comfort Padding",
		"slot": ModSlot.PADDING,
		"stats": {"comfort": 0.2, "noise_reduction": 0.1},
		"tier": 1,
		"compatible": ["armor_all"],
		"craft_cost": {"cloth": 6, "foam": 2},
	},
	"mod_padding_thermal": {
		"display_name": "Thermal Lining",
		"slot": ModSlot.PADDING,
		"stats": {"cold_resist": 0.3, "heat_resist": -0.1},
		"tier": 2,
		"compatible": ["armor_all"],
		"craft_cost": {"cloth": 4, "fur": 3},
	},
	
	"mod_plating_spikes": {
		"display_name": "Armor Spikes",
		"slot": ModSlot.PLATING,
		"stats": {"melee_reflect": 0.1, "intimidation": 0.2},
		"tier": 2,
		"compatible": ["metal_armor", "leather_armor"],
		"craft_cost": {"steel_plate": 4, "nails": 10},
	},
	"mod_plating_camo": {
		"display_name": "Camouflage",
		"slot": ModSlot.PLATING,
		"stats": {"stealth": 0.2},
		"tier": 2,
		"compatible": ["armor_all"],
		"craft_cost": {"cloth": 8, "dye": 3},
	},
}


# ============================================================================
# REPAIR SYSTEM
# ============================================================================

const REPAIR_COSTS := {
	# Material type -> repair cost per 10% durability
	"wood": {"wood": 2, "nails": 1},
	"stone": {"stone": 3},
	"metal": {"scrap_metal": 3},
	"steel": {"steel_plate": 1},
	"cloth": {"cloth": 3},
	"leather": {"leather": 2},
	"polymer": {"polymer": 2},
	"electronics": {"electronics": 1, "copper_wire": 2},
}

const REPAIR_SKILL_BONUS := {
	# Repair skill level -> efficiency bonus
	0: 0.0,
	1: 0.1,
	2: 0.2,
	3: 0.3,
	4: 0.4,
	5: 0.5,
}


# ============================================================================
# RESEARCH SYSTEM
# ============================================================================

const RESEARCH_PROJECTS := {
	"research_metallurgy_1": {
		"display_name": "Basic Metallurgy",
		"description": "Unlock iron and steel processing.",
		"time": 300.0,  # 5 minutes
		"cost": {"research_notes": 3, "iron_ore": 10},
		"unlocks_blueprints": ["bp_machete", "bp_crowbar"],
		"tier": 2,
		"prerequisites": [],
	},
	"research_metallurgy_2": {
		"display_name": "Advanced Metallurgy",
		"description": "Unlock advanced steel forging.",
		"time": 600.0,
		"cost": {"research_notes": 8, "steel_plate": 5},
		"unlocks_blueprints": ["bp_katana"],
		"tier": 3,
		"prerequisites": ["research_metallurgy_1"],
	},
	"research_archery": {
		"display_name": "Archery",
		"description": "Unlock bow crafting.",
		"time": 180.0,
		"cost": {"research_notes": 2, "wood": 20},
		"unlocks_blueprints": ["bp_makeshift_bow"],
		"tier": 2,
		"prerequisites": [],
	},
	"research_archery_advanced": {
		"display_name": "Advanced Archery",
		"description": "Unlock compound bow.",
		"time": 480.0,
		"cost": {"research_notes": 6, "aluminum": 5},
		"unlocks_blueprints": ["bp_compound_bow"],
		"tier": 3,
		"prerequisites": ["research_archery"],
	},
	"research_firearms_basic": {
		"display_name": "Basic Firearms",
		"description": "Unlock pistol and shotgun crafting.",
		"time": 900.0,
		"cost": {"research_notes": 10, "gunpowder": 10, "steel_plate": 10},
		"unlocks_blueprints": ["bp_pistol", "bp_shotgun"],
		"tier": 3,
		"prerequisites": ["research_metallurgy_1"],
	},
	"research_firearms_advanced": {
		"display_name": "Advanced Firearms",
		"description": "Unlock military-grade weapons.",
		"time": 1800.0,
		"cost": {"research_notes": 25, "precision_parts": 10, "electronics": 5},
		"unlocks_blueprints": ["bp_assault_rifle", "bp_sniper_rifle"],
		"tier": 4,
		"prerequisites": ["research_firearms_basic"],
	},
	"research_armor_basic": {
		"display_name": "Basic Armor Crafting",
		"description": "Unlock leather and padded armor.",
		"time": 240.0,
		"cost": {"research_notes": 3, "leather": 10},
		"unlocks_blueprints": ["bp_leather_armor", "bp_padded_armor"],
		"tier": 2,
		"prerequisites": [],
	},
	"research_armor_advanced": {
		"display_name": "Advanced Armor",
		"description": "Unlock metal and tactical armor.",
		"time": 720.0,
		"cost": {"research_notes": 12, "steel_plate": 15, "kevlar": 3},
		"unlocks_blueprints": ["bp_metal_armor", "bp_swat_armor", "bp_tactical_armor"],
		"tier": 3,
		"prerequisites": ["research_armor_basic"],
	},
	"research_medicine": {
		"display_name": "Medical Research",
		"description": "Unlock advanced medical items.",
		"time": 360.0,
		"cost": {"research_notes": 5, "medical_supplies": 5, "herbs": 15},
		"unlocks_blueprints": ["bp_medkit", "bp_antidote"],
		"tier": 2,
		"prerequisites": [],
	},
	"research_chemistry": {
		"display_name": "Chemistry",
		"description": "Unlock chemical compounds and stim packs.",
		"time": 600.0,
		"cost": {"research_notes": 10, "chemicals": 15, "glass": 5},
		"unlocks_blueprints": ["bp_stim_pack"],
		"tier": 3,
		"prerequisites": ["research_medicine"],
	},
	"research_electronics": {
		"display_name": "Electronics",
		"description": "Unlock electronic devices.",
		"time": 480.0,
		"cost": {"research_notes": 8, "electronics": 10, "copper_wire": 20},
		"unlocks_blueprints": ["bp_generator", "bp_solar_panel"],
		"tier": 3,
		"prerequisites": [],
	},
	"research_automation": {
		"display_name": "Automation",
		"description": "Unlock automated defenses.",
		"time": 900.0,
		"cost": {"research_notes": 15, "electronics": 20, "gears": 15},
		"unlocks_blueprints": ["bp_turret_basic"],
		"tier": 3,
		"prerequisites": ["research_electronics"],
	},
	"research_vehicles": {
		"display_name": "Vehicle Engineering",
		"description": "Unlock vehicle construction.",
		"time": 1200.0,
		"cost": {"research_notes": 20, "engine_parts": 10, "rubber": 10},
		"unlocks_blueprints": ["bp_chopper", "bp_atv"],
		"tier": 4,
		"prerequisites": ["research_metallurgy_2", "research_electronics"],
	},
}


# ============================================================================
# STATE
# ============================================================================

var _learned_blueprints: Array = []
var _discovered_blueprints: Array = []  # Found but not researched
var _completed_research: Array = []
var _active_research: Dictionary = {}  # research_id -> progress data
var _unlocked_tiers: int = 1
var _repair_skill_level: int = 0


func _ready() -> void:
	# Add default blueprints
	for bp_id in BLUEPRINTS:
		var bp: Dictionary = BLUEPRINTS[bp_id]
		if bp.get("known_by_default", false):
			_learned_blueprints.append(bp_id)


func _process(delta: float) -> void:
	_update_research(delta)


# ============================================================================
# BLUEPRINT FUNCTIONS
# ============================================================================

func learn_blueprint(blueprint_id: String) -> bool:
	if blueprint_id not in BLUEPRINTS:
		return false
	
	if blueprint_id in _learned_blueprints:
		return false
	
	var bp: Dictionary = BLUEPRINTS[blueprint_id]
	if bp.get("tier", 1) > _unlocked_tiers:
		return false
	
	_learned_blueprints.append(blueprint_id)
	emit_signal("blueprint_learned", blueprint_id)
	
	return true


func discover_blueprint(blueprint_id: String) -> bool:
	if blueprint_id not in BLUEPRINTS:
		return false
	
	if blueprint_id in _learned_blueprints or blueprint_id in _discovered_blueprints:
		return false
	
	_discovered_blueprints.append(blueprint_id)
	emit_signal("blueprint_discovered", blueprint_id)
	
	return true


func has_blueprint(blueprint_id: String) -> bool:
	return blueprint_id in _learned_blueprints


func get_blueprints_by_category(category: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for bp_id in _learned_blueprints:
		var bp: Dictionary = BLUEPRINTS.get(bp_id, {})
		if bp.get("category", -1) == category:
			var entry := bp.duplicate()
			entry["id"] = bp_id
			results.append(entry)
	
	return results


func get_all_learned_blueprints() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for bp_id in _learned_blueprints:
		var bp: Dictionary = BLUEPRINTS.get(bp_id, {}).duplicate()
		bp["id"] = bp_id
		results.append(bp)
	
	return results


func get_discovered_blueprints() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for bp_id in _discovered_blueprints:
		var bp: Dictionary = BLUEPRINTS.get(bp_id, {}).duplicate()
		bp["id"] = bp_id
		bp["research_cost"] = bp.get("research_cost", {})
		results.append(bp)
	
	return results


# ============================================================================
# MODIFICATION FUNCTIONS
# ============================================================================

func apply_modification(item_data: Dictionary, mod_id: String) -> Dictionary:
	if mod_id not in MODIFICATIONS:
		return {"success": false, "error": "Unknown modification"}
	
	var mod: Dictionary = MODIFICATIONS[mod_id]
	var item_type: String = item_data.get("type", "")
	var compatible: Array = mod.get("compatible", [])
	
	# Check compatibility
	var is_compatible := false
	for comp in compatible:
		if comp == item_type or comp == "melee_all" or comp == "armor_all":
			is_compatible = true
			break
		if item_type.contains(comp):
			is_compatible = true
			break
	
	if not is_compatible:
		return {"success": false, "error": "Modification not compatible"}
	
	# Check mod slot
	var slot: int = mod.get("slot", -1)
	var existing_mods: Array = item_data.get("modifications", [])
	
	for existing in existing_mods:
		var existing_mod: Dictionary = MODIFICATIONS.get(existing, {})
		if existing_mod.get("slot", -2) == slot:
			return {"success": false, "error": "Slot already occupied"}
	
	# Apply modification
	existing_mods.append(mod_id)
	item_data["modifications"] = existing_mods
	
	# Apply stat bonuses
	var stats: Dictionary = mod.get("stats", {})
	for stat in stats:
		var current: float = item_data.get(stat, 0.0)
		item_data[stat] = current + stats[stat]
	
	emit_signal("modification_applied", item_data.get("id", ""), mod_id)
	
	return {"success": true, "item": item_data}


func remove_modification(item_data: Dictionary, mod_id: String) -> Dictionary:
	var mods: Array = item_data.get("modifications", [])
	
	if mod_id not in mods:
		return {"success": false, "error": "Modification not found"}
	
	var mod: Dictionary = MODIFICATIONS.get(mod_id, {})
	var stats: Dictionary = mod.get("stats", {})
	
	# Remove stat bonuses
	for stat in stats:
		var current: float = item_data.get(stat, 0.0)
		item_data[stat] = current - stats[stat]
	
	mods.erase(mod_id)
	item_data["modifications"] = mods
	
	return {"success": true, "item": item_data, "removed_mod": mod_id}


func get_compatible_mods(item_data: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var item_type: String = item_data.get("type", "")
	var existing_slots: Array = []
	
	for mod_id in item_data.get("modifications", []):
		var mod: Dictionary = MODIFICATIONS.get(mod_id, {})
		existing_slots.append(mod.get("slot", -1))
	
	for mod_id in MODIFICATIONS:
		var mod: Dictionary = MODIFICATIONS[mod_id]
		var compatible: Array = mod.get("compatible", [])
		var slot: int = mod.get("slot", -1)
		
		if slot in existing_slots:
			continue
		
		for comp in compatible:
			if comp == item_type or comp == "melee_all" or comp == "armor_all":
				var entry := mod.duplicate()
				entry["id"] = mod_id
				results.append(entry)
				break
			if item_type.contains(comp):
				var entry := mod.duplicate()
				entry["id"] = mod_id
				results.append(entry)
				break
	
	return results


func get_item_mod_stats(item_data: Dictionary) -> Dictionary:
	var total_stats: Dictionary = {}
	
	for mod_id in item_data.get("modifications", []):
		var mod: Dictionary = MODIFICATIONS.get(mod_id, {})
		for stat in mod.get("stats", {}):
			total_stats[stat] = total_stats.get(stat, 0.0) + mod["stats"][stat]
	
	return total_stats


# ============================================================================
# REPAIR FUNCTIONS
# ============================================================================

func repair_item(item_data: Dictionary, repair_amount: float = 1.0) -> Dictionary:
	var current_durability: float = item_data.get("durability", 1.0)
	var max_durability: float = item_data.get("max_durability", 1.0)
	
	if current_durability >= max_durability:
		return {"success": false, "error": "Item at full durability"}
	
	var material_type: String = item_data.get("material", "metal")
	var repair_cost: Dictionary = REPAIR_COSTS.get(material_type, {"scrap_metal": 3})
	
	var durability_to_repair := min(repair_amount, max_durability - current_durability)
	var repair_units := ceil(durability_to_repair * 10.0)  # Cost per 10%
	
	# Calculate actual cost
	var actual_cost: Dictionary = {}
	var efficiency := 1.0 + REPAIR_SKILL_BONUS.get(_repair_skill_level, 0.0)
	
	for item_id in repair_cost:
		actual_cost[item_id] = int(ceil(repair_cost[item_id] * repair_units / efficiency))
	
	# Apply repair
	var new_durability := current_durability + durability_to_repair
	item_data["durability"] = clampf(new_durability, 0.0, max_durability)
	
	emit_signal("item_repaired", item_data.get("id", ""), item_data["durability"])
	
	return {
		"success": true,
		"item": item_data,
		"cost": actual_cost,
		"durability_restored": durability_to_repair,
	}


func get_repair_cost(item_data: Dictionary) -> Dictionary:
	var current_durability: float = item_data.get("durability", 1.0)
	var max_durability: float = item_data.get("max_durability", 1.0)
	
	if current_durability >= max_durability:
		return {}
	
	var material_type: String = item_data.get("material", "metal")
	var repair_cost: Dictionary = REPAIR_COSTS.get(material_type, {"scrap_metal": 3})
	
	var durability_needed := max_durability - current_durability
	var repair_units := ceil(durability_needed * 10.0)
	
	var efficiency := 1.0 + REPAIR_SKILL_BONUS.get(_repair_skill_level, 0.0)
	
	var actual_cost: Dictionary = {}
	for item_id in repair_cost:
		actual_cost[item_id] = int(ceil(repair_cost[item_id] * repair_units / efficiency))
	
	return actual_cost


func set_repair_skill(level: int) -> void:
	_repair_skill_level = clampi(level, 0, 5)


# ============================================================================
# RESEARCH FUNCTIONS
# ============================================================================

func start_research(research_id: String) -> Dictionary:
	if research_id not in RESEARCH_PROJECTS:
		return {"success": false, "error": "Unknown research"}
	
	if research_id in _completed_research:
		return {"success": false, "error": "Already completed"}
	
	if not _active_research.is_empty():
		return {"success": false, "error": "Research already in progress"}
	
	var project: Dictionary = RESEARCH_PROJECTS[research_id]
	
	# Check prerequisites
	for prereq in project.get("prerequisites", []):
		if prereq not in _completed_research:
			return {"success": false, "error": "Prerequisites not met"}
	
	# Check tier
	if project.get("tier", 1) > _unlocked_tiers:
		return {"success": false, "error": "Tier not unlocked"}
	
	_active_research = {
		"id": research_id,
		"progress": 0.0,
		"total_time": project.get("time", 300.0),
		"started_at": Time.get_unix_time_from_system(),
	}
	
	emit_signal("research_started", research_id)
	
	return {"success": true, "research": _active_research}


func cancel_research() -> Dictionary:
	if _active_research.is_empty():
		return {"success": false, "error": "No research in progress"}
	
	var refund: Dictionary = {}
	var research_id: String = _active_research.get("id", "")
	var project: Dictionary = RESEARCH_PROJECTS.get(research_id, {})
	var progress: float = _active_research.get("progress", 0.0) / _active_research.get("total_time", 1.0)
	
	# Partial refund based on progress
	var refund_rate := maxf(0.5 - progress * 0.5, 0.0)
	for item_id in project.get("cost", {}):
		refund[item_id] = int(project["cost"][item_id] * refund_rate)
	
	_active_research.clear()
	
	return {"success": true, "refund": refund}


func _update_research(delta: float) -> void:
	if _active_research.is_empty():
		return
	
	_active_research["progress"] = _active_research.get("progress", 0.0) + delta
	
	if _active_research["progress"] >= _active_research.get("total_time", 300.0):
		_complete_research()


func _complete_research() -> void:
	var research_id: String = _active_research.get("id", "")
	var project: Dictionary = RESEARCH_PROJECTS.get(research_id, {})
	
	_completed_research.append(research_id)
	
	# Unlock blueprints
	for bp_id in project.get("unlocks_blueprints", []):
		learn_blueprint(bp_id)
	
	emit_signal("research_completed", research_id)
	
	_active_research.clear()


func get_active_research() -> Dictionary:
	if _active_research.is_empty():
		return {}
	
	var data: Dictionary = _active_research.duplicate()
	var progress_pct := data.get("progress", 0.0) / data.get("total_time", 1.0)
	data["progress_percent"] = clampf(progress_pct, 0.0, 1.0)
	
	return data


func get_available_research() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for research_id in RESEARCH_PROJECTS:
		if research_id in _completed_research:
			continue
		
		var project: Dictionary = RESEARCH_PROJECTS[research_id].duplicate()
		project["id"] = research_id
		
		# Check prerequisites
		var prereqs_met := true
		for prereq in project.get("prerequisites", []):
			if prereq not in _completed_research:
				prereqs_met = false
				break
		
		project["available"] = prereqs_met and project.get("tier", 1) <= _unlocked_tiers
		results.append(project)
	
	return results


func get_completed_research() -> Array:
	return _completed_research.duplicate()


# ============================================================================
# TIER SYSTEM
# ============================================================================

func unlock_tier(tier: int) -> bool:
	if tier <= _unlocked_tiers:
		return false
	
	if tier > _unlocked_tiers + 1:
		return false  # Can only unlock next tier
	
	_unlocked_tiers = tier
	emit_signal("crafting_tier_unlocked", tier)
	
	return true


func get_unlocked_tier() -> int:
	return _unlocked_tiers


func get_tier_requirements(tier: int) -> Dictionary:
	## Returns requirements to unlock a crafting tier
	match tier:
		2:
			return {"base_level": 3, "blueprints_learned": 5}
		3:
			return {"base_level": 6, "blueprints_learned": 15, "research_completed": 3}
		4:
			return {"base_level": 10, "blueprints_learned": 30, "research_completed": 8}
		5:
			return {"base_level": 14, "blueprints_learned": 50, "research_completed": 15}
	
	return {}


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"learned_blueprints": _learned_blueprints.duplicate(),
		"discovered_blueprints": _discovered_blueprints.duplicate(),
		"completed_research": _completed_research.duplicate(),
		"active_research": _active_research.duplicate(),
		"unlocked_tiers": _unlocked_tiers,
		"repair_skill_level": _repair_skill_level,
	}


func load_data(data: Dictionary) -> void:
	_learned_blueprints = data.get("learned_blueprints", [])
	_discovered_blueprints = data.get("discovered_blueprints", [])
	_completed_research = data.get("completed_research", [])
	_active_research = data.get("active_research", {})
	_unlocked_tiers = data.get("unlocked_tiers", 1)
	_repair_skill_level = data.get("repair_skill_level", 0)
	
	# Ensure defaults are known
	for bp_id in BLUEPRINTS:
		var bp: Dictionary = BLUEPRINTS[bp_id]
		if bp.get("known_by_default", false) and bp_id not in _learned_blueprints:
			_learned_blueprints.append(bp_id)
