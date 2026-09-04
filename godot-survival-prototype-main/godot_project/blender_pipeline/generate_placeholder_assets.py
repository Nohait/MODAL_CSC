"""
Standalone Asset Generator for Godot Survival Prototype
=================================================
Generates placeholder sprite assets without requiring Blender.
Uses PIL/Pillow to create simple but recognizable icons.

Run: python generate_placeholder_assets.py
"""

import os
import sys
from pathlib import Path
from random import Random
import math

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    print("Installing Pillow...")
    os.system(f"{sys.executable} -m pip install Pillow")
    from PIL import Image, ImageDraw, ImageFont, ImageFilter


# ============================================================================
# PATHS
# ============================================================================

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
ASSETS_DIR = PROJECT_ROOT / "assets"

OUTPUT_DIRS = {
    "items": ASSETS_DIR / "art" / "items",
    "weapons": ASSETS_DIR / "art" / "weapons",
    "enemies": ASSETS_DIR / "art" / "enemies",
    "armor": ASSETS_DIR / "art" / "armor",
    "environment": ASSETS_DIR / "art" / "environment",
    "ui": ASSETS_DIR / "art" / "ui",
    "icons": ASSETS_DIR / "icons" / "items",
}

for dir_path in OUTPUT_DIRS.values():
    dir_path.mkdir(parents=True, exist_ok=True)


# ============================================================================
# COLOR UTILITIES
# ============================================================================

def rgb_to_pil(rgb_tuple):
    """Convert (0-1) RGB to (0-255) RGB"""
    return tuple(int(c * 255) for c in rgb_tuple[:3])

def darken(color, amount=0.3):
    """Darken a color"""
    return tuple(max(0, int(c * (1 - amount))) for c in color)

def lighten(color, amount=0.3):
    """Lighten a color"""
    return tuple(min(255, int(c + (255 - c) * amount)) for c in color)


# ============================================================================
# ASSET DEFINITIONS
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


# ============================================================================
# ICON GENERATORS
# ============================================================================

class IconGenerator:
    """Generates 2D item icons"""
    
    def __init__(self, size: int = 64, rng: Random = None):
        self.size = size
        self.rng = rng or Random(42)
        self.padding = size // 8
    
    def create_base(self, bg_color=None):
        """Create base transparent image"""
        img = Image.new('RGBA', (self.size, self.size), (0, 0, 0, 0))
        return img, ImageDraw.Draw(img)
    
    def add_outline(self, img, color=(30, 30, 30), width=1):
        """Add dark outline to non-transparent pixels"""
        # Simple implementation - draw slightly larger shapes first
        return img
    
    def generate_item(self, name: str, config: dict) -> Image.Image:
        """Generate an item icon"""
        shape = config.get("shape", "cube")
        color = rgb_to_pil(config.get("color", (0.5, 0.5, 0.5)))
        
        img, draw = self.create_base()
        
        shape_funcs = {
            "log": self._draw_log,
            "rock": self._draw_rock,
            "ore": self._draw_ore,
            "scrap": self._draw_scrap,
            "flat": self._draw_flat,
            "coil": self._draw_coil,
            "bundle": self._draw_bundle,
            "bar": self._draw_bar,
            "circuit": self._draw_circuit,
            "powder": self._draw_bottle,
            "bottle": self._draw_bottle,
            "sheet": self._draw_flat,
            "pane": self._draw_pane,
            "meat": self._draw_meat,
            "fish": self._draw_fish,
            "berries": self._draw_berries,
            "vegetable": self._draw_vegetable,
            "corn": self._draw_corn,
            "mushroom": self._draw_mushroom,
            "fruit": self._draw_fruit,
            "bowl": self._draw_bowl,
            "loaf": self._draw_loaf,
            "strips": self._draw_strips,
            "can": self._draw_can,
            "package": self._draw_package,
            "cup": self._draw_cup,
            "roll": self._draw_roll,
            "box": self._draw_box,
            "case": self._draw_case,
            "pills": self._draw_pills,
            "syringe": self._draw_syringe,
            "splint": self._draw_splint,
            "bullet_box": self._draw_bullet_box,
            "shell_box": self._draw_shell_box,
            "quiver": self._draw_quiver,
            "bolt_box": self._draw_bolt_box,
            "pickaxe": self._draw_pickaxe,
            "hatchet": self._draw_hatchet,
            "hammer": self._draw_hammer,
            "wrench": self._draw_wrench,
            "rod": self._draw_rod,
            "shovel": self._draw_shovel,
            "saw": self._draw_saw,
            "lockpick": self._draw_lockpick,
            "flashlight": self._draw_flashlight,
            "torch": self._draw_torch,
            "paper": self._draw_paper,
            "key": self._draw_key,
            "card": self._draw_card,
            "tags": self._draw_tags,
            "compass": self._draw_compass,
            "binoculars": self._draw_binoculars,
            "canister": self._draw_canister,
            "parts": self._draw_parts,
            "battery": self._draw_battery,
        }
        
        func = shape_funcs.get(shape, self._draw_default)
        func(draw, color)
        
        return img
    
    def _draw_default(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p, p, p + s, p + s], fill=color, outline=darken(color))
    
    def _draw_log(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Draw horizontal cylinder
        draw.ellipse([p, p + s//4, p + s//4, p + s*3//4], fill=color, outline=darken(color))
        draw.rectangle([p + s//8, p + s//4, p + s*7//8, p + s*3//4], fill=color)
        draw.ellipse([p + s*3//4, p + s//4, p + s, p + s*3//4], fill=lighten(color, 0.2), outline=darken(color))
        # Growth rings
        draw.ellipse([p + s*13//16, p + s*3//8, p + s*15//16, p + s*5//8], fill=darken(color, 0.1))
    
    def _draw_rock(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        points = [
            (p + s//4, p + s*3//4),
            (p, p + s//2),
            (p + s//6, p + s//4),
            (p + s//2, p),
            (p + s*3//4, p + s//6),
            (p + s, p + s//3),
            (p + s*7//8, p + s*3//4),
            (p + s*2//3, p + s),
            (p + s//3, p + s),
        ]
        draw.polygon(points, fill=color, outline=darken(color))
    
    def _draw_ore(self, draw, color):
        self._draw_rock(draw, color)
        # Add sparkle
        p = self.padding
        s = self.size - p * 2
        sparkle = lighten(color, 0.5)
        draw.rectangle([p + s//3, p + s//3, p + s//2, p + s//2], fill=sparkle)
    
    def _draw_scrap(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Multiple overlapping pieces
        draw.polygon([(p, p + s//2), (p + s//3, p), (p + s*2//3, p + s//3)], fill=color, outline=darken(color))
        draw.polygon([(p + s//4, p + s), (p + s//2, p + s//3), (p + s, p + s//2)], fill=lighten(color, 0.1), outline=darken(color))
    
    def _draw_flat(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Folded material
        draw.polygon([(p, p + s//3), (p + s*2//3, p), (p + s, p + s*2//3), (p + s//3, p + s)], fill=color, outline=darken(color))
    
    def _draw_coil(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Draw as stacked circles
        for i in range(3):
            y_off = i * s // 6
            draw.ellipse([p + s//4, p + y_off + s//4, p + s*3//4, p + y_off + s*3//4], outline=color, width=3)
    
    def _draw_bundle(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Multiple lines
        for i in range(5):
            x = p + s//6 + i * s//8
            draw.line([(x, p + s//4), (x, p + s*3//4)], fill=color, width=2)
        # Tie
        draw.rectangle([p + s//8, p + s//2 - 3, p + s*7//8, p + s//2 + 3], fill=darken(color))
    
    def _draw_bar(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # 3D-ish bar
        draw.polygon([(p, p + s*2//3), (p + s//6, p + s//3), (p + s, p + s//3), (p + s*5//6, p + s*2//3)], fill=color, outline=darken(color))
        draw.polygon([(p + s, p + s//3), (p + s*5//6, p + s*2//3), (p + s*5//6, p + s), (p + s, p + s*2//3)], fill=darken(color, 0.2))
    
    def _draw_circuit(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # PCB board
        draw.rectangle([p, p + s//4, p + s, p + s*3//4], fill=color, outline=darken(color))
        # Components
        chip_color = (40, 40, 40)
        draw.rectangle([p + s//4, p + s*3//8, p + s//2, p + s*5//8], fill=chip_color)
        draw.rectangle([p + s*5//8, p + s*3//8, p + s*3//4, p + s*5//8], fill=chip_color)
    
    def _draw_bottle(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Body
        draw.rectangle([p + s//4, p + s//3, p + s*3//4, p + s], fill=color, outline=darken(color))
        # Neck
        draw.rectangle([p + s*3//8, p, p + s*5//8, p + s//3], fill=color, outline=darken(color))
        # Cap
        draw.rectangle([p + s*5//16, p, p + s*11//16, p + s//8], fill=darken(color, 0.3))
    
    def _draw_pane(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p + s//8, p, p + s*7//8, p + s], fill=color + (180,), outline=darken(color))
    
    def _draw_meat(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Steak shape
        draw.ellipse([p, p + s//4, p + s, p + s], fill=color, outline=darken(color))
        # Marbling
        draw.line([(p + s//3, p + s//2), (p + s*2//3, p + s*2//3)], fill=lighten(color, 0.3), width=2)
    
    def _draw_fish(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Body
        draw.ellipse([p, p + s//4, p + s*3//4, p + s*3//4], fill=color, outline=darken(color))
        # Tail
        draw.polygon([(p + s*5//8, p + s//2), (p + s, p + s//4), (p + s, p + s*3//4)], fill=color, outline=darken(color))
        # Eye
        draw.ellipse([p + s//8, p + s*3//8, p + s//4, p + s//2], fill=(255, 255, 255), outline=(0, 0, 0))
    
    def _draw_berries(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Multiple circles
        positions = [(p + s//4, p + s//3), (p + s//2, p + s//4), (p + s*3//4, p + s//3),
                     (p + s//3, p + s*2//3), (p + s*2//3, p + s*2//3)]
        for x, y in positions:
            draw.ellipse([x - s//8, y - s//8, x + s//8, y + s//8], fill=color, outline=darken(color))
    
    def _draw_vegetable(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Carrot/potato shape
        draw.ellipse([p + s//6, p, p + s*5//6, p + s*3//4], fill=color, outline=darken(color))
        # Stem
        draw.rectangle([p + s*3//8, p + s*3//4, p + s*5//8, p + s], fill=(60, 120, 40))
    
    def _draw_corn(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Cob
        draw.ellipse([p + s//4, p, p + s*3//4, p + s*3//4], fill=color, outline=darken(color))
        # Husk
        draw.polygon([(p, p + s//2), (p + s//4, p + s*3//4), (p, p + s)], fill=(80, 140, 50))
        draw.polygon([(p + s, p + s//2), (p + s*3//4, p + s*3//4), (p + s, p + s)], fill=(80, 140, 50))
    
    def _draw_mushroom(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Stem
        draw.rectangle([p + s*3//8, p + s//2, p + s*5//8, p + s], fill=(230, 220, 200))
        # Cap
        draw.ellipse([p + s//8, p, p + s*7//8, p + s*2//3], fill=color, outline=darken(color))
    
    def _draw_fruit(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.ellipse([p + s//8, p + s//8, p + s*7//8, p + s*7//8], fill=color, outline=darken(color))
        # Stem
        draw.line([(p + s//2, p), (p + s//2, p + s//6)], fill=(80, 60, 40), width=3)
    
    def _draw_bowl(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Bowl outline
        draw.ellipse([p, p + s//4, p + s, p + s], fill=(200, 180, 160), outline=(100, 80, 60))
        # Contents
        draw.ellipse([p + s//8, p + s*3//8, p + s*7//8, p + s*7//8], fill=color)
    
    def _draw_loaf(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.ellipse([p, p + s//4, p + s, p + s*3//4], fill=color, outline=darken(color))
        draw.rectangle([p, p + s//2, p + s, p + s*3//4], fill=color)
    
    def _draw_strips(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        for i in range(4):
            y = p + s//8 + i * s//4
            draw.rectangle([p + s//8, y, p + s*7//8, y + s//6], fill=color, outline=darken(color))
    
    def _draw_can(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p + s//6, p + s//8, p + s*5//6, p + s*7//8], fill=color, outline=darken(color))
        # Lid
        draw.ellipse([p + s//6, p, p + s*5//6, p + s//4], fill=lighten(color), outline=darken(color))
    
    def _draw_package(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p, p + s//6, p + s, p + s*5//6], fill=color, outline=darken(color))
        # Label
        draw.rectangle([p + s//4, p + s//3, p + s*3//4, p + s*2//3], fill=lighten(color, 0.3))
    
    def _draw_cup(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Cup body
        draw.rectangle([p + s//4, p + s//4, p + s*3//4, p + s], fill=(240, 240, 240), outline=(100, 100, 100))
        # Contents
        draw.rectangle([p + s//4 + 2, p + s//3, p + s*3//4 - 2, p + s - 2], fill=color)
    
    def _draw_roll(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.ellipse([p + s//6, p + s//4, p + s*5//6, p + s*3//4], fill=color, outline=darken(color))
    
    def _draw_box(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p + s//8, p + s//8, p + s*7//8, p + s*7//8], fill=color, outline=darken(color))
        # Cross symbol for medical
        if color[0] > 200 and color[1] < 100:  # Red box
            draw.rectangle([p + s*3//8, p + s//4, p + s*5//8, p + s*3//4], fill=(255, 255, 255))
            draw.rectangle([p + s//4, p + s*3//8, p + s*3//4, p + s*5//8], fill=(255, 255, 255))
    
    def _draw_case(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p, p + s//4, p + s, p + s*3//4], fill=color, outline=darken(color))
        # Handle
        draw.rectangle([p + s*3//8, p + s//8, p + s*5//8, p + s//4], fill=darken(color))
    
    def _draw_pills(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Pill bottle
        draw.rectangle([p + s//4, p + s//4, p + s*3//4, p + s], fill=(240, 240, 240), outline=(150, 150, 150))
        # Cap
        draw.rectangle([p + s//4, p + s//8, p + s*3//4, p + s//4], fill=color, outline=darken(color))
        # Label
        draw.rectangle([p + s//3, p + s//2, p + s*2//3, p + s*3//4], fill=color)
    
    def _draw_syringe(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Barrel
        draw.rectangle([p + s//4, p + s//4, p + s*3//4, p + s*3//4], fill=(240, 240, 240), outline=(150, 150, 150))
        # Plunger
        draw.rectangle([p + s*3//8, p, p + s*5//8, p + s//4], fill=(180, 180, 180))
        # Needle
        draw.line([(p + s//2, p + s*3//4), (p + s//2, p + s)], fill=(150, 150, 150), width=2)
        # Contents
        draw.rectangle([p + s//3, p + s//3, p + s*2//3, p + s*2//3], fill=color)
    
    def _draw_splint(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Two sticks
        draw.rectangle([p + s//4, p, p + s*3//8, p + s], fill=color, outline=darken(color))
        draw.rectangle([p + s*5//8, p, p + s*3//4, p + s], fill=color, outline=darken(color))
        # Bandage wraps
        draw.rectangle([p + s//8, p + s//4, p + s*7//8, p + s*3//8], fill=(240, 240, 240))
        draw.rectangle([p + s//8, p + s*5//8, p + s*7//8, p + s*3//4], fill=(240, 240, 240))
    
    def _draw_bullet_box(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p + s//8, p + s//4, p + s*7//8, p + s*3//4], fill=color, outline=darken(color))
        # Bullets visible
        for i in range(4):
            x = p + s//4 + i * s//6
            draw.ellipse([x, p + s*3//8, x + s//10, p + s*5//8], fill=(180, 160, 80))
    
    def _draw_shell_box(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p + s//8, p + s//4, p + s*7//8, p + s*3//4], fill=color, outline=darken(color))
    
    def _draw_quiver(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Quiver body
        draw.polygon([(p + s//4, p + s//4), (p + s*3//4, p + s//4), (p + s*2//3, p + s), (p + s//3, p + s)], fill=color, outline=darken(color))
        # Arrow tips
        for i in range(3):
            x = p + s//3 + i * s//8
            draw.polygon([(x, p), (x - s//16, p + s//4), (x + s//16, p + s//4)], fill=(150, 150, 150))
    
    def _draw_bolt_box(self, draw, color):
        self._draw_bullet_box(draw, color)
    
    def _draw_pickaxe(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Handle
        draw.line([(p + s//4, p + s*3//4), (p + s*3//4, p + s//4)], fill=(120, 80, 40), width=4)
        # Head
        draw.polygon([(p + s*5//8, p), (p + s, p + s//4), (p + s*3//4, p + s*3//8)], fill=color, outline=darken(color))
        draw.polygon([(p + s//2, p + s//4), (p + s*5//8, p), (p + s*3//4, p + s*3//8)], fill=color, outline=darken(color))
    
    def _draw_hatchet(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Handle
        draw.rectangle([p + s//4, p + s//4, p + s*3//8, p + s], fill=(120, 80, 40))
        # Head
        draw.polygon([(p + s//4, p), (p + s*3//4, p + s//4), (p + s//4, p + s//2)], fill=color, outline=darken(color))
    
    def _draw_hammer(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Handle
        draw.rectangle([p + s*3//8, p + s//4, p + s*5//8, p + s], fill=(120, 80, 40))
        # Head
        draw.rectangle([p + s//8, p, p + s*7//8, p + s//3], fill=color, outline=darken(color))
    
    def _draw_wrench(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Handle
        draw.rectangle([p + s*3//8, p + s//4, p + s*5//8, p + s*3//4], fill=color, outline=darken(color))
        # Head
        draw.ellipse([p + s//4, p, p + s*3//4, p + s//3], outline=color, width=4)
        # Jaw
        draw.rectangle([p + s//4, p + s*3//4, p + s*3//4, p + s], fill=color, outline=darken(color))
    
    def _draw_rod(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.line([(p + s//2, p), (p + s//2, p + s)], fill=color, width=3)
        # Reel
        draw.ellipse([p + s//4, p + s*2//3, p + s*3//4, p + s], fill=darken(color), outline=darken(color, 0.5))
    
    def _draw_shovel(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Handle
        draw.rectangle([p + s*3//8, p + s//4, p + s*5//8, p + s*3//4], fill=(120, 80, 40))
        # Blade
        draw.ellipse([p + s//6, p + s*2//3, p + s*5//6, p + s], fill=color, outline=darken(color))
    
    def _draw_saw(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Blade
        draw.rectangle([p, p + s//3, p + s*3//4, p + s*2//3], fill=color, outline=darken(color))
        # Handle
        draw.rectangle([p + s*3//4, p + s//4, p + s, p + s*3//4], fill=(120, 80, 40), outline=(80, 50, 25))
        # Teeth
        for i in range(6):
            x = p + s//8 + i * s//8
            draw.polygon([(x, p + s*2//3), (x + s//16, p + s*3//4), (x + s//8, p + s*2//3)], fill=color)
    
    def _draw_lockpick(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p + s//4, p + s//3, p + s*3//4, p + s*2//3], fill=color, outline=darken(color))
        draw.line([(p + s*3//4, p + s//2), (p + s, p + s//2)], fill=color, width=2)
        # Hook
        draw.arc([p + s*7//8, p + s//3, p + s, p + s*2//3], 270, 90, fill=color, width=2)
    
    def _draw_flashlight(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Body
        draw.rectangle([p + s//4, p + s//3, p + s*3//4, p + s*5//6], fill=color, outline=darken(color))
        # Lens
        draw.ellipse([p + s//4, p + s//8, p + s*3//4, p + s//2], fill=(255, 255, 200), outline=darken(color))
    
    def _draw_torch(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Handle
        draw.rectangle([p + s*3//8, p + s//3, p + s*5//8, p + s], fill=color, outline=darken(color))
        # Flame
        draw.ellipse([p + s//4, p, p + s*3//4, p + s//2], fill=(255, 150, 50))
        draw.ellipse([p + s*3//8, p, p + s*5//8, p + s//3], fill=(255, 220, 100))
    
    def _draw_paper(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p + s//8, p + s//8, p + s*7//8, p + s*7//8], fill=color, outline=darken(color))
        # Lines
        for i in range(4):
            y = p + s//4 + i * s//6
            draw.line([(p + s//4, y), (p + s*3//4, y)], fill=darken(color), width=1)
    
    def _draw_key(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Bow (top)
        draw.ellipse([p + s//4, p, p + s*3//4, p + s//2], outline=color, width=4)
        # Shaft
        draw.rectangle([p + s*3//8, p + s//3, p + s*5//8, p + s*3//4], fill=color)
        # Bit
        draw.rectangle([p + s//4, p + s*3//4, p + s*3//4, p + s], fill=color)
        draw.rectangle([p + s//4, p + s*5//6, p + s//3, p + s], fill=(0, 0, 0, 0))
    
    def _draw_card(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p, p + s//4, p + s, p + s*3//4], fill=color, outline=darken(color))
        # Chip
        draw.rectangle([p + s//8, p + s*3//8, p + s*3//8, p + s*5//8], fill=(220, 180, 50))
    
    def _draw_tags(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Two overlapping tags
        draw.ellipse([p + s//8, p + s//4, p + s*5//8, p + s*3//4], fill=color, outline=darken(color))
        draw.ellipse([p + s*3//8, p + s//3, p + s*7//8, p + s*5//6], fill=lighten(color), outline=darken(color))
        # Chain
        draw.line([(p + s*3//8, p + s*3//8), (p + s//2, p)], fill=darken(color), width=2)
    
    def _draw_compass(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.ellipse([p + s//8, p + s//8, p + s*7//8, p + s*7//8], fill=color, outline=darken(color))
        # Face
        draw.ellipse([p + s//4, p + s//4, p + s*3//4, p + s*3//4], fill=(240, 240, 230))
        # Needle
        draw.polygon([(p + s//2, p + s//4), (p + s*3//8, p + s//2), (p + s//2, p + s*3//4), (p + s*5//8, p + s//2)], 
                     fill=(200, 50, 50), outline=(100, 20, 20))
    
    def _draw_binoculars(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Two tubes
        draw.ellipse([p, p + s//4, p + s*2//5, p + s*3//4], fill=color, outline=darken(color))
        draw.ellipse([p + s*3//5, p + s//4, p + s, p + s*3//4], fill=color, outline=darken(color))
        # Bridge
        draw.rectangle([p + s*2//5, p + s*3//8, p + s*3//5, p + s*5//8], fill=color)
        # Lenses
        draw.ellipse([p + s//16, p + s*5//16, p + s*5//16, p + s*11//16], fill=(100, 150, 200))
        draw.ellipse([p + s*11//16, p + s*5//16, p + s*15//16, p + s*11//16], fill=(100, 150, 200))
    
    def _draw_canister(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p + s//6, p + s//6, p + s*5//6, p + s*5//6], fill=color, outline=darken(color))
        # Handle
        draw.rectangle([p + s//3, p, p + s*2//3, p + s//6], fill=darken(color))
        # Warning
        draw.polygon([(p + s//2, p + s*3//8), (p + s*3//8, p + s*5//8), (p + s*5//8, p + s*5//8)], fill=(255, 200, 0))
    
    def _draw_parts(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        # Gear
        draw.ellipse([p + s//4, p + s//4, p + s*3//4, p + s*3//4], fill=color, outline=darken(color))
        draw.ellipse([p + s*3//8, p + s*3//8, p + s*5//8, p + s*5//8], fill=darken(color, 0.3))
        # Teeth
        for i in range(8):
            angle = i * 45 * math.pi / 180
            cx, cy = p + s//2, p + s//2
            r = s//4
            x1 = cx + int(math.cos(angle) * r * 0.8)
            y1 = cy + int(math.sin(angle) * r * 0.8)
            x2 = cx + int(math.cos(angle) * r * 1.3)
            y2 = cy + int(math.sin(angle) * r * 1.3)
            draw.line([(x1, y1), (x2, y2)], fill=color, width=3)
    
    def _draw_battery(self, draw, color):
        p = self.padding
        s = self.size - p * 2
        draw.rectangle([p + s//6, p + s//4, p + s*5//6, p + s], fill=color, outline=darken(color))
        # Terminal
        draw.rectangle([p + s//3, p, p + s*2//3, p + s//4], fill=lighten(color))
        # Label
        draw.text((p + s//3, p + s//2), "+", fill=(255, 255, 255))


# ============================================================================
# WEAPON ICON GENERATOR
# ============================================================================

class WeaponIconGenerator(IconGenerator):
    """Generates weapon icons"""
    
    def generate_weapon(self, name: str, config: dict) -> Image.Image:
        weapon_type = config.get("type", "blunt")
        color = rgb_to_pil(config.get("color", (0.5, 0.5, 0.5)))
        tier = config.get("tier", 1)
        
        img, draw = self.create_base()
        
        if weapon_type == "blunt":
            self._draw_club(draw, color, tier)
        elif weapon_type == "blade":
            self._draw_blade(draw, color, tier)
        elif weapon_type == "polearm":
            self._draw_spear(draw, color, tier)
        elif weapon_type in ["bow", "crossbow"]:
            self._draw_bow(draw, color, tier)
        elif weapon_type == "pistol":
            self._draw_pistol(draw, color, tier)
        elif weapon_type in ["rifle", "shotgun"]:
            self._draw_rifle(draw, color, tier)
        elif weapon_type in ["explosive", "fire", "thrown"]:
            self._draw_throwable(draw, color, tier)
        elif weapon_type == "sling":
            self._draw_slingshot(draw, color, tier)
        elif weapon_type == "unarmed":
            self._draw_fist(draw, color, tier)
        else:
            self._draw_club(draw, color, tier)
        
        return img
    
    def _draw_club(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Handle
        draw.rectangle([p + s*3//8, p + s//3, p + s*5//8, p + s], fill=(120, 80, 40), outline=(80, 50, 25))
        # Head
        head_w = s//4 + tier * s//16
        draw.ellipse([p + s//2 - head_w//2, p, p + s//2 + head_w//2, p + s//2], fill=color, outline=darken(color))
    
    def _draw_blade(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        blade_len = s//2 + tier * s//8
        # Handle
        draw.rectangle([p + s*3//8, p + s - s//4, p + s*5//8, p + s], fill=(80, 60, 40), outline=(50, 35, 20))
        # Guard
        draw.rectangle([p + s//4, p + s - s//4 - 4, p + s*3//4, p + s - s//4], fill=darken(color))
        # Blade
        draw.polygon([
            (p + s//2, p),
            (p + s*3//8, p + s - s//4 - 4),
            (p + s*5//8, p + s - s//4 - 4)
        ], fill=color, outline=darken(color))
        # Edge highlight
        draw.line([(p + s//2, p + 2), (p + s*3//8 + 2, p + s - s//4 - 6)], fill=lighten(color, 0.4), width=1)
    
    def _draw_spear(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Shaft
        draw.rectangle([p + s*7//16, p + s//4, p + s*9//16, p + s], fill=(120, 80, 40), outline=(80, 50, 25))
        # Point
        draw.polygon([(p + s//2, p), (p + s//3, p + s//4), (p + s*2//3, p + s//4)], fill=color, outline=darken(color))
    
    def _draw_bow(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Bow body (arc)
        draw.arc([p, p, p + s, p + s], 200, 340, fill=color, width=4)
        # String
        draw.line([(p + s//8, p + s*3//4), (p + s*7//8, p + s*3//4)], fill=(200, 180, 140), width=1)
        draw.line([(p + s//8, p + s*3//4), (p + s//2, p + s//2)], fill=(200, 180, 140), width=1)
        draw.line([(p + s*7//8, p + s*3//4), (p + s//2, p + s//2)], fill=(200, 180, 140), width=1)
    
    def _draw_pistol(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Grip
        draw.rectangle([p + s//4, p + s//2, p + s//2, p + s], fill=(60, 50, 40), outline=(40, 30, 20))
        # Body
        draw.rectangle([p + s//4, p + s//4, p + s*3//4, p + s*5//8], fill=color, outline=darken(color))
        # Barrel
        draw.rectangle([p + s//2, p + s*3//8, p + s, p + s//2], fill=color, outline=darken(color))
        # Trigger guard
        draw.arc([p + s*3//8, p + s*5//8, p + s*5//8, p + s*3//4], 0, 180, fill=color, width=2)
    
    def _draw_rifle(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Stock
        draw.polygon([(p, p + s*5//8), (p + s//4, p + s//2), (p + s//4, p + s*3//4), (p, p + s)], fill=(80, 60, 40), outline=(50, 35, 20))
        # Body
        draw.rectangle([p + s//4, p + s*3//8, p + s*5//8, p + s*5//8], fill=color, outline=darken(color))
        # Barrel
        draw.rectangle([p + s*5//8, p + s*7//16, p + s, p + s*9//16], fill=darken(color), outline=darken(color, 0.3))
        # Magazine
        draw.rectangle([p + s*3//8, p + s*5//8, p + s//2, p + s*7//8], fill=darken(color))
    
    def _draw_throwable(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        draw.ellipse([p + s//4, p + s//4, p + s*3//4, p + s*3//4], fill=color, outline=darken(color))
        # Pin/fuse
        draw.rectangle([p + s*3//8, p, p + s*5//8, p + s//4], fill=darken(color))
    
    def _draw_slingshot(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Y shape
        draw.line([(p + s//2, p + s), (p + s//2, p + s//2)], fill=color, width=4)
        draw.line([(p + s//2, p + s//2), (p + s//4, p)], fill=color, width=4)
        draw.line([(p + s//2, p + s//2), (p + s*3//4, p)], fill=color, width=4)
        # Band
        draw.line([(p + s//4, p), (p + s*3//4, p)], fill=(150, 100, 50), width=2)
    
    def _draw_fist(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Hand
        draw.ellipse([p + s//8, p + s//4, p + s*7//8, p + s*7//8], fill=color, outline=darken(color))
        # Fingers curled
        for i in range(4):
            x = p + s//4 + i * s//6
            draw.ellipse([x, p + s//8, x + s//8, p + s//3], fill=color, outline=darken(color))


# ============================================================================
# ENEMY ICON GENERATOR
# ============================================================================

class EnemyIconGenerator(IconGenerator):
    """Generates enemy icons"""
    
    def generate_enemy(self, name: str, config: dict) -> Image.Image:
        color = rgb_to_pil(config.get("color", (0.5, 0.5, 0.5)))
        tier = config.get("tier", 1)
        
        img, draw = self.create_base()
        
        if config.get("quadruped"):
            self._draw_quadruped(draw, color, tier, name)
        elif config.get("human"):
            self._draw_human(draw, color, tier, name)
        elif config.get("boss"):
            self._draw_boss(draw, color, tier, name)
        else:
            self._draw_zombie(draw, color, tier, name)
        
        return img
    
    def _draw_zombie(self, draw, color, tier, name):
        p = self.padding
        s = self.size - p * 2
        size_mult = 1.0 + (tier - 1) * 0.15
        
        # Body
        body_h = int(s * 0.5 * size_mult)
        draw.ellipse([p + s//4, p + s - body_h, p + s*3//4, p + s], fill=color, outline=darken(color))
        
        # Head
        head_size = int(s * 0.35 * size_mult)
        head_y = p + s - body_h - head_size//2
        draw.ellipse([p + s//2 - head_size//2, head_y, p + s//2 + head_size//2, head_y + head_size], 
                     fill=color, outline=darken(color))
        
        # Eyes (menacing)
        eye_color = (255, 100, 100) if "bloater" not in name else (100, 200, 100)
        draw.ellipse([p + s*3//8, head_y + head_size//3, p + s*7//16, head_y + head_size//2], fill=eye_color)
        draw.ellipse([p + s*9//16, head_y + head_size//3, p + s*5//8, head_y + head_size//2], fill=eye_color)
        
        # Arms
        draw.line([(p + s//4, p + s - body_h + body_h//4), (p, p + s - body_h//2)], fill=color, width=4)
        draw.line([(p + s*3//4, p + s - body_h + body_h//4), (p + s, p + s - body_h//2)], fill=color, width=4)
    
    def _draw_human(self, draw, color, tier, name):
        p = self.padding
        s = self.size - p * 2
        
        # Body (more upright)
        draw.rectangle([p + s//3, p + s*2//5, p + s*2//3, p + s*4//5], fill=color, outline=darken(color))
        
        # Head
        head_size = s//4
        draw.ellipse([p + s//2 - head_size//2, p, p + s//2 + head_size//2, p + head_size], 
                     fill=(200, 160, 130), outline=(150, 120, 100))
        
        # Helmet/hat for military types
        if "gunner" in name or "heavy" in name:
            draw.arc([p + s//3, p - s//16, p + s*2//3, p + head_size//2], 0, 180, fill=(80, 90, 70), width=4)
        
        # Weapon indicator
        if "gunner" in name:
            draw.rectangle([p + s*2//3, p + s*2//5, p + s, p + s//2], fill=(60, 60, 60))
    
    def _draw_quadruped(self, draw, color, tier, name):
        p = self.padding
        s = self.size - p * 2
        size_mult = 0.8 + (tier - 1) * 0.15
        
        # Body (horizontal)
        body_w = int(s * 0.7 * size_mult)
        body_h = int(s * 0.35 * size_mult)
        draw.ellipse([p + s//2 - body_w//2, p + s//2, p + s//2 + body_w//2, p + s//2 + body_h], 
                     fill=color, outline=darken(color))
        
        # Head
        head_size = int(s * 0.25 * size_mult)
        draw.ellipse([p + s//2 + body_w//3, p + s//3, p + s//2 + body_w//2 + head_size//2, p + s//2 + head_size//2], 
                     fill=color, outline=darken(color))
        
        # Legs
        leg_positions = [
            (p + s//4, p + s//2 + body_h - 4),
            (p + s*3//8, p + s//2 + body_h - 4),
            (p + s*5//8, p + s//2 + body_h - 4),
            (p + s*3//4, p + s//2 + body_h - 4),
        ]
        for lx, ly in leg_positions:
            draw.rectangle([lx, ly, lx + s//16, p + s], fill=color, outline=darken(color))
        
        # Eyes
        eye_color = (255, 200, 50) if "wolf" in name or "dog" in name else (80, 50, 30)
        draw.ellipse([p + s*3//4, p + s*3//8, p + s*13//16, p + s*7//16], fill=eye_color)
    
    def _draw_boss(self, draw, color, tier, name):
        p = self.padding
        s = self.size - p * 2
        
        # Large body
        draw.ellipse([p, p + s//4, p + s, p + s], fill=color, outline=darken(color))
        
        # Head
        head_size = s//2
        draw.ellipse([p + s//4, p - s//8, p + s*3//4, p + s//2], fill=color, outline=darken(color))
        
        # Glowing eyes
        draw.ellipse([p + s*5//16, p + s//8, p + s*7//16, p + s*5//16], fill=(255, 50, 50))
        draw.ellipse([p + s*9//16, p + s//8, p + s*11//16, p + s*5//16], fill=(255, 50, 50))
        
        # Spikes/horns for bosses
        draw.polygon([(p + s//4, p), (p + s//3, p - s//6), (p + s*3//8, p + s//8)], fill=darken(color))
        draw.polygon([(p + s*3//4, p), (p + s*2//3, p - s//6), (p + s*5//8, p + s//8)], fill=darken(color))


# ============================================================================
# ARMOR ICON GENERATOR
# ============================================================================

class ArmorIconGenerator(IconGenerator):
    """Generates armor icons"""
    
    def generate_armor(self, name: str, config: dict) -> Image.Image:
        slot = config.get("slot", "body")
        color = rgb_to_pil(config.get("color", (0.5, 0.5, 0.5)))
        tier = config.get("tier", 1)
        
        img, draw = self.create_base()
        
        if slot == "head":
            self._draw_helmet(draw, color, tier)
        elif slot == "body":
            self._draw_vest(draw, color, tier)
        elif slot == "hands":
            self._draw_gloves(draw, color, tier)
        elif slot == "feet":
            self._draw_boots(draw, color, tier)
        elif slot == "back":
            self._draw_backpack(draw, color, tier)
        
        return img
    
    def _draw_helmet(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Dome
        draw.ellipse([p + s//8, p, p + s*7//8, p + s*3//4], fill=color, outline=darken(color))
        # Brim/visor
        draw.arc([p, p + s//3, p + s, p + s], 0, 180, fill=darken(color), width=4)
        if tier >= 3:
            # Face shield
            draw.rectangle([p + s//4, p + s//3, p + s*3//4, p + s*2//3], fill=(100, 120, 140, 180))
    
    def _draw_vest(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Body
        draw.rectangle([p + s//6, p + s//8, p + s*5//6, p + s*7//8], fill=color, outline=darken(color))
        # Collar
        draw.arc([p + s//4, p, p + s*3//4, p + s//3], 0, 180, fill=color, width=6)
        # Pockets for higher tiers
        if tier >= 2:
            draw.rectangle([p + s//4, p + s//2, p + s*3//8, p + s*5//8], fill=darken(color, 0.1), outline=darken(color))
            draw.rectangle([p + s*5//8, p + s//2, p + s*3//4, p + s*5//8], fill=darken(color, 0.1), outline=darken(color))
        if tier >= 4:
            # Plate carrier look
            draw.rectangle([p + s//3, p + s//4, p + s*2//3, p + s*3//4], fill=darken(color, 0.15))
    
    def _draw_gloves(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Palm
        draw.ellipse([p + s//8, p + s//4, p + s*7//8, p + s], fill=color, outline=darken(color))
        # Fingers
        for i in range(4):
            x = p + s//4 + i * s//6
            draw.ellipse([x, p, x + s//8, p + s//3], fill=color, outline=darken(color))
        # Thumb
        draw.ellipse([p, p + s*3//8, p + s//4, p + s*5//8], fill=color, outline=darken(color))
    
    def _draw_boots(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Boot shaft
        draw.rectangle([p + s//4, p, p + s*3//4, p + s*2//3], fill=color, outline=darken(color))
        # Sole
        draw.rectangle([p + s//8, p + s*2//3, p + s*7//8, p + s], fill=darken(color, 0.3), outline=darken(color, 0.4))
        # Toe
        draw.ellipse([p + s//8, p + s//2, p + s*7//8, p + s*5//6], fill=color, outline=darken(color))
    
    def _draw_backpack(self, draw, color, tier):
        p = self.padding
        s = self.size - p * 2
        # Main body
        draw.rectangle([p + s//8, p + s//6, p + s*7//8, p + s*5//6], fill=color, outline=darken(color))
        # Flap
        draw.rectangle([p + s//8, p, p + s*7//8, p + s//4], fill=darken(color, 0.1), outline=darken(color))
        # Straps
        draw.rectangle([p + s//4, p + s*5//6, p + s*3//8, p + s], fill=darken(color, 0.2))
        draw.rectangle([p + s*5//8, p + s*5//6, p + s*3//4, p + s], fill=darken(color, 0.2))
        # Pockets for larger packs
        if tier >= 2:
            draw.rectangle([p + s//4, p + s//2, p + s*3//4, p + s*2//3], fill=darken(color, 0.1), outline=darken(color))


# ============================================================================
# MAIN GENERATION
# ============================================================================

def generate_all_placeholder_assets(size: int = 64):
    """Generate all placeholder assets"""
    print("\n" + "=" * 60)
    print("GODOT SURVIVAL PROTOTYPE - PLACEHOLDER ASSET GENERATION")
    print("=" * 60 + "\n")
    
    item_gen = IconGenerator(size)
    weapon_gen = WeaponIconGenerator(size)
    enemy_gen = EnemyIconGenerator(size)
    armor_gen = ArmorIconGenerator(size)
    
    generators = [
        ("Items", item_gen.generate_item, ITEMS, OUTPUT_DIRS["icons"]),
        ("Weapons", weapon_gen.generate_weapon, WEAPONS, OUTPUT_DIRS["weapons"]),
        ("Enemies", enemy_gen.generate_enemy, ENEMIES, OUTPUT_DIRS["enemies"]),
        ("Armor", armor_gen.generate_armor, ARMOR, OUTPUT_DIRS["armor"]),
    ]
    
    total = sum(len(assets) for _, _, assets, _ in generators)
    current = 0
    
    for category, gen_func, assets, output_dir in generators:
        print(f"\n--- Generating {category} ({len(assets)} assets) ---")
        
        for name, config in assets.items():
            current += 1
            print(f"  [{current}/{total}] {name}...", end=" ")
            
            try:
                img = gen_func(name, config)
                output_path = output_dir / f"{name}.png"
                img.save(output_path, "PNG")
                print("OK")
            except Exception as e:
                print(f"ERROR: {e}")
    
    print("\n" + "=" * 60)
    print(f"COMPLETE! Generated {total} assets")
    print(f"Output: {ASSETS_DIR}")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Generate placeholder game assets")
    parser.add_argument("--size", type=int, default=64, help="Icon size in pixels")
    
    args = parser.parse_args()
    generate_all_placeholder_assets(size=args.size)
