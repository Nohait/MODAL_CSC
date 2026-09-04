"""
Complete Game Asset Generator
=============================
Generates ALL game assets for Godot Survival Prototype:
- 80+ Item icons
- 15+ Enemy sprites
- 20+ Weapon sprites  
- 20+ Armor pieces
- Environment tiles & props
- UI elements

Run in Blender: blender --python generate_complete_game_assets.py
"""

import bpy
import bmesh
import math
import os
import sys
from pathlib import Path
from random import Random

# Path setup
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
ASSETS_DIR = PROJECT_ROOT / "assets"
RENDERS_DIR = SCRIPT_DIR / "renders"

# Create output directories
OUTPUT_DIRS = {
    "items": RENDERS_DIR / "items",
    "weapons": RENDERS_DIR / "weapons", 
    "enemies": RENDERS_DIR / "enemies",
    "armor": RENDERS_DIR / "armor",
    "environment": RENDERS_DIR / "environment",
    "ui": RENDERS_DIR / "ui",
    "characters": RENDERS_DIR / "characters",
    "effects": RENDERS_DIR / "effects",
}

for dir_path in OUTPUT_DIRS.values():
    dir_path.mkdir(parents=True, exist_ok=True)


# ============================================================================
# ASSET DEFINITIONS - Complete game content
# ============================================================================

ITEMS = {
    # Resources - Basic
    "wood": {"type": "resource", "color": (0.55, 0.35, 0.15), "shape": "log"},
    "stone": {"type": "resource", "color": (0.5, 0.5, 0.5), "shape": "rock"},
    "iron_ore": {"type": "resource", "color": (0.4, 0.35, 0.3), "shape": "ore"},
    "copper_ore": {"type": "resource", "color": (0.7, 0.45, 0.2), "shape": "ore"},
    "coal": {"type": "resource", "color": (0.15, 0.15, 0.15), "shape": "ore"},
    "scrap_metal": {"type": "resource", "color": (0.45, 0.45, 0.4), "shape": "scrap"},
    "leather": {"type": "resource", "color": (0.45, 0.3, 0.15), "shape": "flat"},
    "cloth": {"type": "resource", "color": (0.8, 0.75, 0.7), "shape": "flat"},
    "rope": {"type": "resource", "color": (0.6, 0.5, 0.35), "shape": "coil"},
    "plant_fiber": {"type": "resource", "color": (0.4, 0.55, 0.3), "shape": "bundle"},
    
    # Resources - Refined
    "iron_bar": {"type": "resource", "color": (0.6, 0.6, 0.6), "shape": "bar"},
    "copper_bar": {"type": "resource", "color": (0.8, 0.5, 0.2), "shape": "bar"},
    "steel_bar": {"type": "resource", "color": (0.7, 0.7, 0.75), "shape": "bar"},
    "titanium_bar": {"type": "resource", "color": (0.75, 0.8, 0.85), "shape": "bar"},
    "electronics": {"type": "resource", "color": (0.2, 0.6, 0.3), "shape": "circuit"},
    "gunpowder": {"type": "resource", "color": (0.2, 0.2, 0.2), "shape": "powder"},
    "acid": {"type": "resource", "color": (0.4, 0.8, 0.2), "shape": "bottle"},
    "rubber": {"type": "resource", "color": (0.1, 0.1, 0.1), "shape": "sheet"},
    "glass": {"type": "resource", "color": (0.7, 0.85, 0.9), "shape": "pane"},
    "plastic": {"type": "resource", "color": (0.9, 0.9, 0.95), "shape": "sheet"},
    
    # Food - Raw
    "raw_meat": {"type": "food", "color": (0.7, 0.25, 0.2), "shape": "meat"},
    "raw_fish": {"type": "food", "color": (0.6, 0.65, 0.7), "shape": "fish"},
    "berries": {"type": "food", "color": (0.5, 0.1, 0.3), "shape": "berries"},
    "carrot": {"type": "food", "color": (0.9, 0.5, 0.1), "shape": "vegetable"},
    "potato": {"type": "food", "color": (0.6, 0.5, 0.35), "shape": "vegetable"},
    "corn": {"type": "food", "color": (0.95, 0.85, 0.3), "shape": "corn"},
    "mushroom": {"type": "food", "color": (0.7, 0.6, 0.5), "shape": "mushroom"},
    "apple": {"type": "food", "color": (0.8, 0.2, 0.15), "shape": "fruit"},
    
    # Food - Cooked
    "cooked_meat": {"type": "food", "color": (0.5, 0.3, 0.2), "shape": "meat"},
    "cooked_fish": {"type": "food", "color": (0.55, 0.45, 0.35), "shape": "fish"},
    "stew": {"type": "food", "color": (0.5, 0.35, 0.25), "shape": "bowl"},
    "bread": {"type": "food", "color": (0.75, 0.55, 0.3), "shape": "loaf"},
    "jerky": {"type": "food", "color": (0.4, 0.25, 0.15), "shape": "strips"},
    "canned_food": {"type": "food", "color": (0.6, 0.6, 0.6), "shape": "can"},
    "mre": {"type": "food", "color": (0.4, 0.45, 0.3), "shape": "package"},
    
    # Drinks
    "water_bottle": {"type": "drink", "color": (0.3, 0.5, 0.8), "shape": "bottle"},
    "purified_water": {"type": "drink", "color": (0.5, 0.7, 0.95), "shape": "bottle"},
    "juice": {"type": "drink", "color": (0.9, 0.6, 0.2), "shape": "bottle"},
    "coffee": {"type": "drink", "color": (0.25, 0.15, 0.1), "shape": "cup"},
    "energy_drink": {"type": "drink", "color": (0.2, 0.9, 0.4), "shape": "can"},
    "beer": {"type": "drink", "color": (0.85, 0.65, 0.2), "shape": "bottle"},
    "whiskey": {"type": "drink", "color": (0.6, 0.35, 0.15), "shape": "bottle"},
    
    # Medical
    "bandage": {"type": "medical", "color": (0.95, 0.95, 0.95), "shape": "roll"},
    "first_aid_kit": {"type": "medical", "color": (0.9, 0.2, 0.2), "shape": "box"},
    "medkit": {"type": "medical", "color": (0.9, 0.9, 0.95), "shape": "case"},
    "painkillers": {"type": "medical", "color": (0.9, 0.5, 0.2), "shape": "pills"},
    "antibiotics": {"type": "medical", "color": (0.3, 0.7, 0.4), "shape": "pills"},
    "antidote": {"type": "medical", "color": (0.2, 0.8, 0.6), "shape": "syringe"},
    "adrenaline": {"type": "medical", "color": (0.9, 0.2, 0.3), "shape": "syringe"},
    "splint": {"type": "medical", "color": (0.7, 0.55, 0.3), "shape": "splint"},
    "radiation_pills": {"type": "medical", "color": (0.9, 0.85, 0.2), "shape": "pills"},
    
    # Ammo
    "9mm_ammo": {"type": "ammo", "color": (0.7, 0.6, 0.2), "shape": "bullet_box"},
    "rifle_ammo": {"type": "ammo", "color": (0.65, 0.55, 0.15), "shape": "bullet_box"},
    "shotgun_shells": {"type": "ammo", "color": (0.8, 0.2, 0.15), "shape": "shell_box"},
    "arrows": {"type": "ammo", "color": (0.5, 0.4, 0.25), "shape": "quiver"},
    "bolts": {"type": "ammo", "color": (0.4, 0.4, 0.4), "shape": "bolt_box"},
    
    # Tools
    "pickaxe": {"type": "tool", "color": (0.55, 0.55, 0.55), "shape": "pickaxe"},
    "hatchet": {"type": "tool", "color": (0.55, 0.55, 0.55), "shape": "hatchet"},
    "hammer": {"type": "tool", "color": (0.5, 0.5, 0.5), "shape": "hammer"},
    "wrench": {"type": "tool", "color": (0.55, 0.55, 0.55), "shape": "wrench"},
    "fishing_rod": {"type": "tool", "color": (0.45, 0.35, 0.2), "shape": "rod"},
    "shovel": {"type": "tool", "color": (0.5, 0.5, 0.5), "shape": "shovel"},
    "saw": {"type": "tool", "color": (0.6, 0.6, 0.6), "shape": "saw"},
    "lockpick": {"type": "tool", "color": (0.55, 0.55, 0.55), "shape": "lockpick"},
    
    # Misc
    "flashlight": {"type": "misc", "color": (0.2, 0.2, 0.2), "shape": "flashlight"},
    "torch": {"type": "misc", "color": (0.5, 0.35, 0.2), "shape": "torch"},
    "map_piece": {"type": "misc", "color": (0.8, 0.75, 0.6), "shape": "paper"},
    "key": {"type": "misc", "color": (0.75, 0.65, 0.2), "shape": "key"},
    "keycard": {"type": "misc", "color": (0.3, 0.5, 0.8), "shape": "card"},
    "dog_tags": {"type": "misc", "color": (0.6, 0.6, 0.6), "shape": "tags"},
    "compass": {"type": "misc", "color": (0.5, 0.5, 0.5), "shape": "compass"},
    "binoculars": {"type": "misc", "color": (0.2, 0.2, 0.2), "shape": "binoculars"},
    "rope_ladder": {"type": "misc", "color": (0.55, 0.45, 0.3), "shape": "ladder"},
    "gasoline": {"type": "misc", "color": (0.8, 0.2, 0.1), "shape": "canister"},
    "engine_parts": {"type": "misc", "color": (0.4, 0.4, 0.4), "shape": "parts"},
    "battery": {"type": "misc", "color": (0.2, 0.2, 0.2), "shape": "battery"},
}

WEAPONS = {
    # Melee - Tier 1
    "fists": {"tier": 1, "type": "unarmed", "damage": 5, "color": (0.8, 0.7, 0.6)},
    "wood_club": {"tier": 1, "type": "blunt", "damage": 15, "color": (0.55, 0.35, 0.15)},
    "stone_knife": {"tier": 1, "type": "blade", "damage": 12, "color": (0.5, 0.5, 0.5)},
    "makeshift_spear": {"tier": 1, "type": "polearm", "damage": 18, "color": (0.5, 0.4, 0.25)},
    
    # Melee - Tier 2
    "baseball_bat": {"tier": 2, "type": "blunt", "damage": 25, "color": (0.6, 0.4, 0.2)},
    "machete": {"tier": 2, "type": "blade", "damage": 30, "color": (0.6, 0.6, 0.6)},
    "crowbar": {"tier": 2, "type": "blunt", "damage": 28, "color": (0.5, 0.2, 0.2)},
    "fire_axe": {"tier": 2, "type": "blade", "damage": 35, "color": (0.7, 0.1, 0.1)},
    
    # Melee - Tier 3
    "katana": {"tier": 3, "type": "blade", "damage": 50, "color": (0.7, 0.7, 0.75)},
    "sledgehammer": {"tier": 3, "type": "blunt", "damage": 55, "color": (0.5, 0.5, 0.5)},
    "spiked_bat": {"tier": 3, "type": "blunt", "damage": 40, "color": (0.55, 0.35, 0.2)},
    "combat_knife": {"tier": 3, "type": "blade", "damage": 35, "color": (0.3, 0.3, 0.3)},
    
    # Ranged - Tier 1
    "makeshift_bow": {"tier": 1, "type": "bow", "damage": 20, "color": (0.5, 0.35, 0.2)},
    "slingshot": {"tier": 1, "type": "sling", "damage": 8, "color": (0.4, 0.3, 0.2)},
    
    # Ranged - Tier 2
    "hunting_bow": {"tier": 2, "type": "bow", "damage": 35, "color": (0.45, 0.3, 0.15)},
    "crossbow": {"tier": 2, "type": "crossbow", "damage": 45, "color": (0.35, 0.35, 0.35)},
    "pistol": {"tier": 2, "type": "pistol", "damage": 40, "color": (0.25, 0.25, 0.25)},
    
    # Ranged - Tier 3
    "compound_bow": {"tier": 3, "type": "bow", "damage": 50, "color": (0.2, 0.2, 0.2)},
    "revolver": {"tier": 3, "type": "pistol", "damage": 55, "color": (0.6, 0.6, 0.6)},
    "shotgun": {"tier": 3, "type": "shotgun", "damage": 70, "color": (0.4, 0.25, 0.15)},
    "rifle": {"tier": 3, "type": "rifle", "damage": 60, "color": (0.35, 0.35, 0.35)},
    
    # Ranged - Tier 4
    "auto_pistol": {"tier": 4, "type": "pistol", "damage": 45, "color": (0.3, 0.3, 0.3)},
    "assault_rifle": {"tier": 4, "type": "rifle", "damage": 50, "color": (0.25, 0.25, 0.25)},
    "sniper_rifle": {"tier": 4, "type": "rifle", "damage": 120, "color": (0.35, 0.4, 0.3)},
    
    # Throwables
    "grenade": {"tier": 3, "type": "explosive", "damage": 100, "color": (0.3, 0.35, 0.25)},
    "molotov": {"tier": 2, "type": "fire", "damage": 40, "color": (0.8, 0.4, 0.2)},
    "throwing_knife": {"tier": 2, "type": "thrown", "damage": 25, "color": (0.6, 0.6, 0.6)},
}

ENEMIES = {
    # Zombies - Basic
    "zombie_walker": {"tier": 1, "hp": 50, "damage": 10, "speed": "slow", "color": (0.45, 0.55, 0.4)},
    "zombie_runner": {"tier": 2, "hp": 40, "damage": 15, "speed": "fast", "color": (0.5, 0.6, 0.45)},
    "zombie_crawler": {"tier": 1, "hp": 30, "damage": 8, "speed": "slow", "color": (0.35, 0.45, 0.35)},
    
    # Zombies - Special
    "bloater": {"tier": 3, "hp": 200, "damage": 25, "speed": "slow", "color": (0.5, 0.6, 0.3), "special": "explode"},
    "spitter": {"tier": 3, "hp": 80, "damage": 20, "speed": "medium", "color": (0.55, 0.7, 0.4), "special": "ranged"},
    "screamer": {"tier": 2, "hp": 60, "damage": 5, "speed": "medium", "color": (0.6, 0.5, 0.5), "special": "alert"},
    "brute": {"tier": 4, "hp": 400, "damage": 40, "speed": "slow", "color": (0.4, 0.45, 0.35), "special": "armored"},
    
    # Bosses
    "ravager": {"tier": 5, "hp": 1000, "damage": 60, "speed": "medium", "color": (0.35, 0.4, 0.3), "boss": True},
    "the_forsaken": {"tier": 6, "hp": 2000, "damage": 80, "speed": "fast", "color": (0.3, 0.35, 0.35), "boss": True},
    
    # Animals
    "feral_dog": {"tier": 2, "hp": 60, "damage": 15, "speed": "fast", "color": (0.4, 0.35, 0.3), "quadruped": True},
    "wolf": {"tier": 3, "hp": 100, "damage": 25, "speed": "fast", "color": (0.45, 0.45, 0.4), "quadruped": True},
    "bear": {"tier": 4, "hp": 300, "damage": 50, "speed": "medium", "color": (0.35, 0.28, 0.22), "quadruped": True},
    
    # Raiders
    "raider_scout": {"tier": 2, "hp": 80, "damage": 20, "speed": "fast", "color": (0.6, 0.5, 0.4), "human": True},
    "raider_gunner": {"tier": 3, "hp": 120, "damage": 35, "speed": "medium", "color": (0.55, 0.45, 0.38), "human": True},
    "raider_heavy": {"tier": 4, "hp": 200, "damage": 45, "speed": "slow", "color": (0.5, 0.42, 0.35), "human": True},
}

ARMOR = {
    # Helmets
    "cloth_cap": {"slot": "head", "tier": 1, "defense": 5, "color": (0.6, 0.55, 0.45)},
    "leather_cap": {"slot": "head", "tier": 2, "defense": 10, "color": (0.45, 0.3, 0.15)},
    "military_helmet": {"slot": "head", "tier": 3, "defense": 20, "color": (0.35, 0.4, 0.3)},
    "tactical_helmet": {"slot": "head", "tier": 4, "defense": 30, "color": (0.25, 0.25, 0.25)},
    "reinforced_helmet": {"slot": "head", "tier": 5, "defense": 40, "color": (0.3, 0.3, 0.35)},
    
    # Body
    "cloth_shirt": {"slot": "body", "tier": 1, "defense": 5, "color": (0.7, 0.65, 0.6)},
    "leather_jacket": {"slot": "body", "tier": 2, "defense": 15, "color": (0.4, 0.25, 0.15)},
    "military_vest": {"slot": "body", "tier": 3, "defense": 25, "color": (0.35, 0.4, 0.3)},
    "tactical_armor": {"slot": "body", "tier": 4, "defense": 40, "color": (0.25, 0.25, 0.25)},
    "swat_armor": {"slot": "body", "tier": 5, "defense": 55, "color": (0.15, 0.15, 0.2)},
    
    # Hands
    "cloth_gloves": {"slot": "hands", "tier": 1, "defense": 3, "color": (0.65, 0.6, 0.55)},
    "leather_gloves": {"slot": "hands", "tier": 2, "defense": 6, "color": (0.45, 0.3, 0.15)},
    "tactical_gloves": {"slot": "hands", "tier": 3, "defense": 10, "color": (0.25, 0.25, 0.25)},
    "reinforced_gloves": {"slot": "hands", "tier": 4, "defense": 15, "color": (0.3, 0.3, 0.3)},
    
    # Feet
    "sneakers": {"slot": "feet", "tier": 1, "defense": 3, "color": (0.8, 0.8, 0.8)},
    "work_boots": {"slot": "feet", "tier": 2, "defense": 8, "color": (0.35, 0.25, 0.15)},
    "military_boots": {"slot": "feet", "tier": 3, "defense": 12, "color": (0.3, 0.35, 0.25)},
    "tactical_boots": {"slot": "feet", "tier": 4, "defense": 18, "color": (0.2, 0.2, 0.2)},
    
    # Backpacks
    "small_backpack": {"slot": "back", "tier": 1, "slots": 8, "color": (0.5, 0.45, 0.35)},
    "medium_backpack": {"slot": "back", "tier": 2, "slots": 12, "color": (0.35, 0.4, 0.3)},
    "military_backpack": {"slot": "back", "tier": 3, "slots": 16, "color": (0.3, 0.35, 0.25)},
    "tactical_backpack": {"slot": "back", "tier": 4, "slots": 20, "color": (0.25, 0.25, 0.25)},
}

ENVIRONMENT = {
    # Ground Tiles
    "grass_tile": {"type": "ground", "color": (0.3, 0.5, 0.2)},
    "dirt_tile": {"type": "ground", "color": (0.45, 0.35, 0.25)},
    "sand_tile": {"type": "ground", "color": (0.85, 0.75, 0.55)},
    "stone_tile": {"type": "ground", "color": (0.5, 0.5, 0.5)},
    "concrete_tile": {"type": "ground", "color": (0.6, 0.6, 0.6)},
    "asphalt_tile": {"type": "ground", "color": (0.25, 0.25, 0.28)},
    "water_tile": {"type": "ground", "color": (0.2, 0.4, 0.7)},
    "toxic_tile": {"type": "ground", "color": (0.4, 0.6, 0.2)},
    
    # Props
    "tree_oak": {"type": "prop", "color": (0.25, 0.45, 0.2)},
    "tree_pine": {"type": "prop", "color": (0.15, 0.35, 0.15)},
    "tree_dead": {"type": "prop", "color": (0.4, 0.35, 0.3)},
    "bush_small": {"type": "prop", "color": (0.3, 0.5, 0.25)},
    "bush_large": {"type": "prop", "color": (0.25, 0.45, 0.2)},
    "rock_small": {"type": "prop", "color": (0.5, 0.5, 0.5)},
    "rock_large": {"type": "prop", "color": (0.45, 0.45, 0.45)},
    "boulder": {"type": "prop", "color": (0.4, 0.4, 0.4)},
    
    # Structures
    "wall_wood": {"type": "structure", "color": (0.55, 0.4, 0.25)},
    "wall_stone": {"type": "structure", "color": (0.5, 0.5, 0.5)},
    "wall_metal": {"type": "structure", "color": (0.45, 0.45, 0.5)},
    "door_wood": {"type": "structure", "color": (0.5, 0.35, 0.2)},
    "door_metal": {"type": "structure", "color": (0.4, 0.4, 0.45)},
    "crate_wood": {"type": "structure", "color": (0.55, 0.4, 0.25)},
    "crate_metal": {"type": "structure", "color": (0.4, 0.45, 0.4)},
    "barrel": {"type": "structure", "color": (0.3, 0.5, 0.3)},
    "barrel_toxic": {"type": "structure", "color": (0.8, 0.7, 0.1)},
    
    # Vehicles (wrecks)
    "car_wreck": {"type": "vehicle", "color": (0.4, 0.15, 0.1)},
    "truck_wreck": {"type": "vehicle", "color": (0.3, 0.35, 0.25)},
    "bus_wreck": {"type": "vehicle", "color": (0.7, 0.6, 0.2)},
}

UI_ELEMENTS = {
    "health_bar": {"type": "bar", "color": (0.8, 0.2, 0.2)},
    "stamina_bar": {"type": "bar", "color": (0.2, 0.7, 0.3)},
    "hunger_bar": {"type": "bar", "color": (0.8, 0.6, 0.2)},
    "thirst_bar": {"type": "bar", "color": (0.2, 0.5, 0.9)},
    "xp_bar": {"type": "bar", "color": (0.6, 0.4, 0.8)},
    "slot_normal": {"type": "slot", "color": (0.3, 0.3, 0.35)},
    "slot_selected": {"type": "slot", "color": (0.5, 0.5, 0.2)},
    "slot_equipped": {"type": "slot", "color": (0.2, 0.5, 0.3)},
    "button_normal": {"type": "button", "color": (0.35, 0.35, 0.4)},
    "button_hover": {"type": "button", "color": (0.45, 0.45, 0.5)},
    "button_pressed": {"type": "button", "color": (0.25, 0.25, 0.3)},
    "panel_dark": {"type": "panel", "color": (0.15, 0.15, 0.18)},
    "panel_light": {"type": "panel", "color": (0.25, 0.25, 0.28)},
}


# ============================================================================
# RENDERING SETUP
# ============================================================================

class AssetRenderer:
    """Handles Blender rendering setup and execution"""
    
    def __init__(self, resolution: int = 128, samples: int = 32):
        self.resolution = resolution
        self.samples = samples
        self.setup_scene()
    
    def setup_scene(self):
        """Configure Blender scene for asset rendering"""
        # Clear existing objects
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete()
        
        # Setup render settings
        scene = bpy.context.scene
        scene.render.engine = 'CYCLES'
        scene.cycles.samples = self.samples
        scene.cycles.use_denoising = True
        
        # Resolution
        scene.render.resolution_x = self.resolution
        scene.render.resolution_y = self.resolution
        scene.render.resolution_percentage = 100
        
        # Transparent background
        scene.render.film_transparent = True
        scene.render.image_settings.file_format = 'PNG'
        scene.render.image_settings.color_mode = 'RGBA'
        
        # Setup camera
        self._setup_camera()
        
        # Setup lighting
        self._setup_lighting()
    
    def _setup_camera(self):
        """Create isometric camera"""
        bpy.ops.object.camera_add(location=(5, -5, 5))
        cam = bpy.context.active_object
        cam.name = "AssetCamera"
        cam.data.type = 'ORTHO'
        cam.data.ortho_scale = 3.0
        
        # Point at origin
        cam.rotation_euler = (math.radians(54.736), 0, math.radians(45))
        
        bpy.context.scene.camera = cam
    
    def _setup_lighting(self):
        """Create three-point lighting"""
        # Key light
        bpy.ops.object.light_add(type='SUN', location=(5, -3, 8))
        key = bpy.context.active_object
        key.name = "KeyLight"
        key.data.energy = 3.0
        key.rotation_euler = (math.radians(45), math.radians(15), math.radians(30))
        
        # Fill light
        bpy.ops.object.light_add(type='SUN', location=(-5, -5, 5))
        fill = bpy.context.active_object
        fill.name = "FillLight"
        fill.data.energy = 1.5
        fill.rotation_euler = (math.radians(60), math.radians(-20), math.radians(-45))
        
        # Rim light
        bpy.ops.object.light_add(type='SUN', location=(0, 5, 3))
        rim = bpy.context.active_object
        rim.name = "RimLight"
        rim.data.energy = 2.0
        rim.rotation_euler = (math.radians(70), 0, math.radians(180))
    
    def render_to_file(self, filepath: str):
        """Render current scene to file"""
        bpy.context.scene.render.filepath = filepath
        bpy.ops.render.render(write_still=True)
    
    def clear_meshes(self):
        """Remove all mesh objects (keep camera/lights)"""
        for obj in list(bpy.data.objects):
            if obj.type == 'MESH':
                bpy.data.objects.remove(obj, do_unlink=True)


# ============================================================================
# MESH GENERATORS
# ============================================================================

class MeshGenerator:
    """Generates various mesh shapes for assets"""
    
    @staticmethod
    def create_material(name: str, color: tuple) -> bpy.types.Material:
        """Create a simple material with given color"""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        # Clear default nodes
        for node in nodes:
            nodes.remove(node)
        
        # Create shader nodes
        output = nodes.new('ShaderNodeOutputMaterial')
        bsdf = nodes.new('ShaderNodeBsdfPrincipled')
        
        # Set color
        bsdf.inputs['Base Color'].default_value = (*color[:3], 1.0)
        bsdf.inputs['Roughness'].default_value = 0.7
        
        links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
        
        return mat
    
    @staticmethod
    def create_cube(name: str, size: float, color: tuple) -> bpy.types.Object:
        """Create a simple cube"""
        bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, size/2))
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        
        return obj
    
    @staticmethod
    def create_cylinder(name: str, radius: float, height: float, color: tuple) -> bpy.types.Object:
        """Create a cylinder"""
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=radius, depth=height,
            location=(0, 0, height/2)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        
        return obj
    
    @staticmethod
    def create_sphere(name: str, radius: float, color: tuple) -> bpy.types.Object:
        """Create a UV sphere"""
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=16, ring_count=8, radius=radius,
            location=(0, 0, radius)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        
        return obj


# ============================================================================
# ITEM GENERATOR
# ============================================================================

class ItemGenerator:
    """Generates item icons/meshes"""
    
    def __init__(self, rng: Random = None):
        self.rng = rng or Random(42)
    
    def generate(self, name: str, config: dict) -> bpy.types.Object:
        """Generate an item mesh based on config"""
        shape = config.get("shape", "cube")
        color = config.get("color", (0.5, 0.5, 0.5))
        
        generators = {
            "log": self._create_log,
            "rock": self._create_rock,
            "ore": self._create_ore,
            "scrap": self._create_scrap,
            "flat": self._create_flat,
            "coil": self._create_coil,
            "bundle": self._create_bundle,
            "bar": self._create_bar,
            "circuit": self._create_circuit,
            "powder": self._create_powder,
            "bottle": self._create_bottle,
            "sheet": self._create_sheet,
            "pane": self._create_pane,
            "meat": self._create_meat,
            "fish": self._create_fish,
            "berries": self._create_berries,
            "vegetable": self._create_vegetable,
            "corn": self._create_corn,
            "mushroom": self._create_mushroom,
            "fruit": self._create_fruit,
            "bowl": self._create_bowl,
            "loaf": self._create_loaf,
            "strips": self._create_strips,
            "can": self._create_can,
            "package": self._create_package,
            "cup": self._create_cup,
            "roll": self._create_roll,
            "box": self._create_box,
            "case": self._create_case,
            "pills": self._create_pills,
            "syringe": self._create_syringe,
            "splint": self._create_splint,
            "bullet_box": self._create_bullet_box,
            "shell_box": self._create_shell_box,
            "quiver": self._create_quiver,
            "bolt_box": self._create_bolt_box,
            "pickaxe": self._create_pickaxe,
            "hatchet": self._create_hatchet,
            "hammer": self._create_hammer,
            "wrench": self._create_wrench,
            "rod": self._create_rod,
            "shovel": self._create_shovel,
            "saw": self._create_saw,
            "lockpick": self._create_lockpick,
            "flashlight": self._create_flashlight,
            "torch": self._create_torch,
            "paper": self._create_paper,
            "key": self._create_key,
            "card": self._create_card,
            "tags": self._create_tags,
            "compass": self._create_compass,
            "binoculars": self._create_binoculars,
            "ladder": self._create_ladder,
            "canister": self._create_canister,
            "parts": self._create_parts,
            "battery": self._create_battery,
        }
        
        gen_func = generators.get(shape, self._create_default)
        return gen_func(name, color)
    
    def _create_default(self, name: str, color: tuple) -> bpy.types.Object:
        return MeshGenerator.create_cube(name, 0.5, color)
    
    def _create_log(self, name: str, color: tuple) -> bpy.types.Object:
        return MeshGenerator.create_cylinder(name, 0.15, 0.8, color)
    
    def _create_rock(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.3, location=(0, 0, 0.3))
        obj = bpy.context.active_object
        obj.name = name
        
        # Add some randomization
        for v in obj.data.vertices:
            v.co.x += self.rng.uniform(-0.05, 0.05)
            v.co.y += self.rng.uniform(-0.05, 0.05)
            v.co.z += self.rng.uniform(-0.02, 0.02)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_ore(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_rock(name, color)
    
    def _create_scrap(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.4, location=(0, 0, 0.2))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.2, 0.8, 0.4)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_flat(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.5, location=(0, 0, 0.05))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.8, 0.1)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_coil(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.2, minor_radius=0.03,
            location=(0, 0, 0.2)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_bundle(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.15, depth=0.4,
            location=(0, 0, 0.2)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_bar(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.5, location=(0, 0, 0.1))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (2.0, 0.4, 0.2)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_circuit(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.4, location=(0, 0, 0.05))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.7, 0.1)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_powder(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_can(name, color)
    
    def _create_bottle(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.1, depth=0.5,
            location=(0, 0, 0.25)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        # Add neck
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12, radius=0.04, depth=0.1,
            location=(0, 0, 0.55)
        )
        neck = bpy.context.active_object
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        neck.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.join()
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_sheet(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_flat(name, color)
    
    def _create_pane(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.5, location=(0, 0, 0.25))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.05, 1.0)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        mat.blend_method = 'BLEND'
        mat.node_tree.nodes["Principled BSDF"].inputs['Alpha'].default_value = 0.5
        obj.data.materials.append(mat)
        return obj
    
    def _create_meat(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.35, location=(0, 0, 0.15))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.8, 0.4)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_fish(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=6, radius=0.15,
            location=(0, 0, 0.15)
        )
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (2.0, 0.5, 0.6)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_berries(self, name: str, color: tuple) -> bpy.types.Object:
        # Multiple small spheres
        parts = []
        for i in range(5):
            angle = i * 72 * math.pi / 180
            x = math.cos(angle) * 0.1
            y = math.sin(angle) * 0.1
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=8, ring_count=4, radius=0.08,
                location=(x, y, 0.1)
            )
            parts.append(bpy.context.active_object)
        
        # Join all
        bpy.ops.object.select_all(action='DESELECT')
        for p in parts:
            p.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_vegetable(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=10, ring_count=6, radius=0.15,
            location=(0, 0, 0.15)
        )
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (0.6, 0.6, 1.2)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_corn(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12, radius=0.08, depth=0.4,
            location=(0, 0, 0.2)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_mushroom(self, name: str, color: tuple) -> bpy.types.Object:
        # Stem
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.05, depth=0.2,
            location=(0, 0, 0.1)
        )
        stem = bpy.context.active_object
        
        # Cap
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=6, radius=0.15,
            location=(0, 0, 0.25)
        )
        cap = bpy.context.active_object
        cap.scale = (1.0, 1.0, 0.5)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        stem.select_set(True)
        cap.select_set(True)
        bpy.context.view_layer.objects.active = stem
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_fruit(self, name: str, color: tuple) -> bpy.types.Object:
        return MeshGenerator.create_sphere(name, 0.15, color)
    
    def _create_bowl(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=16, ring_count=8, radius=0.2,
            location=(0, 0, 0.1)
        )
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 1.0, 0.5)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_loaf(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=6, radius=0.2,
            location=(0, 0, 0.15)
        )
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.5, 0.8, 0.6)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_strips(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_flat(name, color)
    
    def _create_can(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=20, radius=0.1, depth=0.25,
            location=(0, 0, 0.125)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_package(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_box(name, color)
    
    def _create_cup(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_can(name, color)
    
    def _create_roll(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.12, depth=0.15,
            location=(0, 0, 0.075)
        )
        obj = bpy.context.active_object
        obj.name = name
        obj.rotation_euler = (math.radians(90), 0, 0)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_box(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.35, location=(0, 0, 0.175))
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_case(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.4, location=(0, 0, 0.15))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.2, 0.8, 0.4)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_pills(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_bottle(name, color)
    
    def _create_syringe(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12, radius=0.03, depth=0.4,
            location=(0, 0, 0.2)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_splint(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.4, location=(0, 0, 0.1))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (0.2, 0.1, 1.5)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_bullet_box(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_box(name, color)
    
    def _create_shell_box(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_box(name, color)
    
    def _create_quiver(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12, radius=0.08, depth=0.5,
            location=(0, 0, 0.25)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_bolt_box(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_box(name, color)
    
    def _create_pickaxe(self, name: str, color: tuple) -> bpy.types.Object:
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.03, depth=0.7,
            location=(0, 0, 0.35)
        )
        handle = bpy.context.active_object
        
        # Head
        bpy.ops.mesh.primitive_cube_add(size=0.15, location=(0, 0, 0.75))
        head = bpy.context.active_object
        head.scale = (2.0, 0.3, 0.5)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        handle.select_set(True)
        head.select_set(True)
        bpy.context.view_layer.objects.active = handle
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_hatchet(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_pickaxe(name, color)
    
    def _create_hammer(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_pickaxe(name, color)
    
    def _create_wrench(self, name: str, color: tuple) -> bpy.types.Object:
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.025, depth=0.4,
            location=(0, 0, 0.2)
        )
        handle = bpy.context.active_object
        
        # Head
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.06, minor_radius=0.02,
            location=(0, 0, 0.45)
        )
        head = bpy.context.active_object
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        handle.select_set(True)
        head.select_set(True)
        bpy.context.view_layer.objects.active = handle
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_rod(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.015, depth=1.2,
            location=(0, 0, 0.6)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_shovel(self, name: str, color: tuple) -> bpy.types.Object:
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.025, depth=0.8,
            location=(0, 0, 0.4)
        )
        handle = bpy.context.active_object
        
        # Blade
        bpy.ops.mesh.primitive_cube_add(size=0.2, location=(0, 0, 0.85))
        blade = bpy.context.active_object
        blade.scale = (1.0, 0.1, 0.8)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        handle.select_set(True)
        blade.select_set(True)
        bpy.context.view_layer.objects.active = handle
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_saw(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.4, location=(0, 0, 0.15))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.5, 0.05, 0.5)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_lockpick(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6, radius=0.01, depth=0.15,
            location=(0, 0, 0.075)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_flashlight(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.04, depth=0.25,
            location=(0, 0, 0.125)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_torch(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.03, depth=0.5,
            location=(0, 0, 0.25)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_paper(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_flat(name, color)
    
    def _create_key(self, name: str, color: tuple) -> bpy.types.Object:
        # Key body
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.015, depth=0.1,
            location=(0, 0, 0.05)
        )
        body = bpy.context.active_object
        
        # Key head
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.04, minor_radius=0.015,
            location=(0, 0, 0.12)
        )
        head = bpy.context.active_object
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        body.select_set(True)
        head.select_set(True)
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_card(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.15, location=(0, 0, 0.01))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.6, 1.0, 0.05)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_tags(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.08, location=(0, 0, 0.04))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.6, 0.1)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_compass(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=24, radius=0.1, depth=0.03,
            location=(0, 0, 0.015)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_binoculars(self, name: str, color: tuple) -> bpy.types.Object:
        # Left tube
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.04, depth=0.15,
            location=(-0.05, 0, 0.075)
        )
        left = bpy.context.active_object
        
        # Right tube
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.04, depth=0.15,
            location=(0.05, 0, 0.075)
        )
        right = bpy.context.active_object
        
        # Bridge
        bpy.ops.mesh.primitive_cube_add(size=0.03, location=(0, 0, 0.075))
        bridge = bpy.context.active_object
        bridge.scale = (3.0, 0.5, 0.5)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        left.select_set(True)
        right.select_set(True)
        bridge.select_set(True)
        bpy.context.view_layer.objects.active = left
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_ladder(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_coil(name, color)
    
    def _create_canister(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.3, location=(0, 0, 0.2))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.5, 1.2)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_parts(self, name: str, color: tuple) -> bpy.types.Object:
        return self._create_scrap(name, color)
    
    def _create_battery(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.25, location=(0, 0, 0.15))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.6, 0.8)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj


# ============================================================================
# WEAPON GENERATOR
# ============================================================================

class WeaponGenerator:
    """Generates weapon meshes"""
    
    def __init__(self, rng: Random = None):
        self.rng = rng or Random(42)
    
    def generate(self, name: str, config: dict) -> bpy.types.Object:
        """Generate weapon mesh based on config"""
        weapon_type = config.get("type", "blunt")
        color = config.get("color", (0.5, 0.5, 0.5))
        tier = config.get("tier", 1)
        
        if weapon_type in ["blunt"]:
            return self._create_club(name, color, tier)
        elif weapon_type in ["blade"]:
            return self._create_blade(name, color, tier)
        elif weapon_type in ["polearm"]:
            return self._create_spear(name, color, tier)
        elif weapon_type in ["bow", "crossbow"]:
            return self._create_bow(name, color, tier)
        elif weapon_type in ["pistol"]:
            return self._create_pistol(name, color, tier)
        elif weapon_type in ["rifle", "shotgun"]:
            return self._create_rifle(name, color, tier)
        elif weapon_type in ["explosive", "fire", "thrown"]:
            return self._create_throwable(name, color, tier)
        else:
            return self._create_club(name, color, tier)
    
    def _create_club(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        size = 0.8 + tier * 0.1
        
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.03, depth=size * 0.7,
            location=(0, 0, size * 0.35)
        )
        handle = bpy.context.active_object
        
        # Head
        head_size = 0.08 + tier * 0.02
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10, radius=head_size, depth=size * 0.3,
            location=(0, 0, size * 0.85)
        )
        head = bpy.context.active_object
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        handle.select_set(True)
        head.select_set(True)
        bpy.context.view_layer.objects.active = handle
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_blade(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        blade_len = 0.3 + tier * 0.15
        
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.025, depth=0.2,
            location=(0, 0, 0.1)
        )
        handle = bpy.context.active_object
        
        # Blade
        bpy.ops.mesh.primitive_cube_add(size=0.1, location=(0, 0, 0.25 + blade_len/2))
        blade = bpy.context.active_object
        blade.scale = (0.3, 1.0, blade_len * 5)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        handle.select_set(True)
        blade.select_set(True)
        bpy.context.view_layer.objects.active = handle
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_spear(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        length = 1.0 + tier * 0.2
        
        # Shaft
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.02, depth=length,
            location=(0, 0, length/2)
        )
        shaft = bpy.context.active_object
        
        # Point
        bpy.ops.mesh.primitive_cone_add(
            vertices=8, radius1=0.04, depth=0.15,
            location=(0, 0, length + 0.075)
        )
        point = bpy.context.active_object
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        shaft.select_set(True)
        point.select_set(True)
        bpy.context.view_layer.objects.active = shaft
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_bow(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        # Simplified bow as curved cylinder
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.02, depth=0.8,
            location=(0, 0, 0.4)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_pistol(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        # Grip
        bpy.ops.mesh.primitive_cube_add(size=0.1, location=(0, 0, 0.08))
        grip = bpy.context.active_object
        grip.scale = (0.4, 1.0, 1.5)
        
        # Barrel
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12, radius=0.02, depth=0.2,
            location=(0, 0.03, 0.18)
        )
        barrel = bpy.context.active_object
        barrel.rotation_euler = (math.radians(90), 0, 0)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        grip.select_set(True)
        barrel.select_set(True)
        bpy.context.view_layer.objects.active = grip
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_rifle(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        # Stock
        bpy.ops.mesh.primitive_cube_add(size=0.1, location=(0, -0.15, 0.05))
        stock = bpy.context.active_object
        stock.scale = (0.4, 2.0, 0.8)
        
        # Receiver
        bpy.ops.mesh.primitive_cube_add(size=0.08, location=(0, 0.05, 0.08))
        receiver = bpy.context.active_object
        receiver.scale = (0.5, 1.5, 1.0)
        
        # Barrel
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12, radius=0.015, depth=0.4,
            location=(0, 0.35, 0.08)
        )
        barrel = bpy.context.active_object
        barrel.rotation_euler = (math.radians(90), 0, 0)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        stock.select_set(True)
        receiver.select_set(True)
        barrel.select_set(True)
        bpy.context.view_layer.objects.active = stock
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_throwable(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        return MeshGenerator.create_sphere(name, 0.1, color)


# ============================================================================
# ENEMY GENERATOR
# ============================================================================

class EnemyGenerator:
    """Generates enemy meshes"""
    
    def __init__(self, rng: Random = None):
        self.rng = rng or Random(42)
    
    def generate(self, name: str, config: dict) -> bpy.types.Object:
        """Generate enemy mesh based on config"""
        color = config.get("color", (0.5, 0.5, 0.5))
        
        if config.get("quadruped"):
            return self._create_quadruped(name, color, config)
        elif config.get("human"):
            return self._create_humanoid(name, color, config)
        elif config.get("boss"):
            return self._create_boss(name, color, config)
        else:
            return self._create_zombie(name, color, config)
    
    def _create_zombie(self, name: str, color: tuple, config: dict) -> bpy.types.Object:
        tier = config.get("tier", 1)
        scale = 1.0 + (tier - 1) * 0.2
        
        # Body
        bpy.ops.mesh.primitive_cube_add(size=0.4 * scale, location=(0, 0, 0.5 * scale))
        body = bpy.context.active_object
        body.scale = (0.8, 0.5, 1.2)
        
        # Head
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=8, radius=0.15 * scale,
            location=(0, 0, 0.85 * scale)
        )
        head = bpy.context.active_object
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        body.select_set(True)
        head.select_set(True)
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_humanoid(self, name: str, color: tuple, config: dict) -> bpy.types.Object:
        return self._create_zombie(name, color, config)
    
    def _create_quadruped(self, name: str, color: tuple, config: dict) -> bpy.types.Object:
        tier = config.get("tier", 1)
        scale = 0.6 + (tier - 1) * 0.2
        
        # Body
        bpy.ops.mesh.primitive_cube_add(size=0.4 * scale, location=(0, 0, 0.3 * scale))
        body = bpy.context.active_object
        body.scale = (0.6, 1.5, 0.8)
        
        # Head
        bpy.ops.mesh.primitive_cube_add(size=0.2 * scale, location=(0, 0.35 * scale, 0.35 * scale))
        head = bpy.context.active_object
        head.scale = (0.8, 1.2, 0.8)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        body.select_set(True)
        head.select_set(True)
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_boss(self, name: str, color: tuple, config: dict) -> bpy.types.Object:
        tier = config.get("tier", 5)
        scale = 1.5 + (tier - 5) * 0.3
        
        # Large body
        bpy.ops.mesh.primitive_cube_add(size=0.6 * scale, location=(0, 0, 0.6 * scale))
        body = bpy.context.active_object
        body.scale = (1.0, 0.7, 1.3)
        
        # Head
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=8, radius=0.25 * scale,
            location=(0, 0, 1.1 * scale)
        )
        head = bpy.context.active_object
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        body.select_set(True)
        head.select_set(True)
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj


# ============================================================================
# ARMOR GENERATOR
# ============================================================================

class ArmorGenerator:
    """Generates armor piece meshes"""
    
    def __init__(self, rng: Random = None):
        self.rng = rng or Random(42)
    
    def generate(self, name: str, config: dict) -> bpy.types.Object:
        """Generate armor mesh based on slot"""
        slot = config.get("slot", "body")
        color = config.get("color", (0.5, 0.5, 0.5))
        tier = config.get("tier", 1)
        
        if slot == "head":
            return self._create_helmet(name, color, tier)
        elif slot == "body":
            return self._create_vest(name, color, tier)
        elif slot == "hands":
            return self._create_gloves(name, color, tier)
        elif slot == "feet":
            return self._create_boots(name, color, tier)
        elif slot == "back":
            return self._create_backpack(name, color, tier)
        else:
            return self._create_vest(name, color, tier)
    
    def _create_helmet(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        size = 0.2 + tier * 0.02
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=16, ring_count=8, radius=size,
            location=(0, 0, size)
        )
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 1.1, 0.9)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_vest(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        size = 0.35 + tier * 0.03
        bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, size/2))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.6, 1.2)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_gloves(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.12, location=(0, 0, 0.06))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.7, 1.5)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_boots(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.15, location=(0, 0, 0.1))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (0.6, 1.2, 1.5)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_backpack(self, name: str, color: tuple, tier: int) -> bpy.types.Object:
        size = 0.25 + tier * 0.05
        bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, size * 0.7))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (0.9, 0.5, 1.2)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj


# ============================================================================
# ENVIRONMENT GENERATOR
# ============================================================================

class EnvironmentGenerator:
    """Generates environment assets"""
    
    def __init__(self, rng: Random = None):
        self.rng = rng or Random(42)
    
    def generate(self, name: str, config: dict) -> bpy.types.Object:
        """Generate environment mesh based on type"""
        env_type = config.get("type", "prop")
        color = config.get("color", (0.5, 0.5, 0.5))
        
        if "tile" in name:
            return self._create_tile(name, color)
        elif "tree" in name:
            return self._create_tree(name, color)
        elif "bush" in name:
            return self._create_bush(name, color)
        elif "rock" in name or "boulder" in name:
            return self._create_rock(name, color)
        elif "wall" in name:
            return self._create_wall(name, color)
        elif "door" in name:
            return self._create_door(name, color)
        elif "crate" in name:
            return self._create_crate(name, color)
        elif "barrel" in name:
            return self._create_barrel(name, color)
        elif "car" in name or "truck" in name or "bus" in name:
            return self._create_vehicle(name, color)
        else:
            return MeshGenerator.create_cube(name, 0.5, color)
    
    def _create_tile(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_plane_add(size=2.0, location=(0, 0, 0))
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_tree(self, name: str, color: tuple) -> bpy.types.Object:
        # Trunk
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.1, depth=1.0,
            location=(0, 0, 0.5)
        )
        trunk = bpy.context.active_object
        trunk_mat = MeshGenerator.create_material(f"{name}_trunk_mat", (0.35, 0.25, 0.15))
        trunk.data.materials.append(trunk_mat)
        
        # Foliage
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2, radius=0.5,
            location=(0, 0, 1.2)
        )
        foliage = bpy.context.active_object
        foliage_mat = MeshGenerator.create_material(f"{name}_foliage_mat", color)
        foliage.data.materials.append(foliage_mat)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        trunk.select_set(True)
        foliage.select_set(True)
        bpy.context.view_layer.objects.active = trunk
        bpy.ops.object.join()
        
        obj = bpy.context.active_object
        obj.name = name
        return obj
    
    def _create_bush(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2, radius=0.3,
            location=(0, 0, 0.25)
        )
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.2, 1.0, 0.8)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_rock(self, name: str, color: tuple) -> bpy.types.Object:
        size = 0.4 if "small" in name else 0.8
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2, radius=size,
            location=(0, 0, size * 0.7)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        # Add randomization
        for v in obj.data.vertices:
            v.co.x += self.rng.uniform(-size*0.1, size*0.1)
            v.co.y += self.rng.uniform(-size*0.1, size*0.1)
            v.co.z += self.rng.uniform(-size*0.05, size*0.05)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_wall(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.5))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (1.0, 0.1, 1.0)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_door(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.5))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (0.5, 0.08, 1.0)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_crate(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cube_add(size=0.5, location=(0, 0, 0.25))
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_barrel(self, name: str, color: tuple) -> bpy.types.Object:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.25, depth=0.6,
            location=(0, 0, 0.3)
        )
        obj = bpy.context.active_object
        obj.name = name
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj
    
    def _create_vehicle(self, name: str, color: tuple) -> bpy.types.Object:
        # Simplified vehicle as box
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.4))
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = (0.8, 1.5, 0.6)
        
        mat = MeshGenerator.create_material(f"{name}_mat", color)
        obj.data.materials.append(mat)
        return obj


# ============================================================================
# MAIN GENERATION FUNCTION
# ============================================================================

def generate_all_assets(resolution: int = 128, samples: int = 32):
    """Generate all game assets and render to PNG files"""
    print("\n" + "="*60)
    print("GODOT SURVIVAL PROTOTYPE - COMPLETE ASSET GENERATION")
    print("="*60 + "\n")
    
    renderer = AssetRenderer(resolution=resolution, samples=samples)
    
    generators = {
        "items": (ItemGenerator(), ITEMS, OUTPUT_DIRS["items"]),
        "weapons": (WeaponGenerator(), WEAPONS, OUTPUT_DIRS["weapons"]),
        "enemies": (EnemyGenerator(), ENEMIES, OUTPUT_DIRS["enemies"]),
        "armor": (ArmorGenerator(), ARMOR, OUTPUT_DIRS["armor"]),
        "environment": (EnvironmentGenerator(), ENVIRONMENT, OUTPUT_DIRS["environment"]),
    }
    
    total_assets = sum(len(assets) for _, assets, _ in generators.values())
    current = 0
    
    for category, (generator, assets, output_dir) in generators.items():
        print(f"\n--- Generating {category.upper()} ({len(assets)} assets) ---")
        
        for asset_name, config in assets.items():
            current += 1
            print(f"  [{current}/{total_assets}] {asset_name}...")
            
            try:
                # Clear previous meshes
                renderer.clear_meshes()
                
                # Generate asset
                obj = generator.generate(asset_name, config)
                
                # Render to file
                output_path = str(output_dir / f"{asset_name}.png")
                renderer.render_to_file(output_path)
                
            except Exception as e:
                print(f"    ERROR: {e}")
    
    print("\n" + "="*60)
    print(f"COMPLETE! Generated {total_assets} assets")
    print(f"Output directory: {RENDERS_DIR}")
    print("="*60 + "\n")


# ============================================================================
# ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    # Parse command line arguments
    import argparse
    
    parser = argparse.ArgumentParser(description="Generate all game assets")
    parser.add_argument("--resolution", type=int, default=128, help="Render resolution")
    parser.add_argument("--samples", type=int, default=32, help="Render samples")
    
    # Handle Blender's -- argument separator
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    
    args = parser.parse_args(argv)
    
    generate_all_assets(resolution=args.resolution, samples=args.samples)
