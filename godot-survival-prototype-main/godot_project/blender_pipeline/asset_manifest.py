"""
AI Asset Pipeline - Automated asset generation with minimal human input
Generates complete game assets using procedural generation and AI assistance
"""

import sys
import os
from pathlib import Path

# Ensure project root is in path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import json
import random
import hashlib
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Optional, Tuple
from enum import Enum


class AssetCategory(Enum):
    """Categories of game assets"""
    CHARACTER = "character"
    ZOMBIE = "zombie"
    WILDLIFE = "wildlife"
    WEAPON = "weapon"
    ARMOR = "armor"
    BUILDING = "building"
    PROP = "prop"
    VEHICLE = "vehicle"
    RESOURCE = "resource"
    VEGETATION = "vegetation"
    TERRAIN = "terrain"
    UI_ICON = "ui_icon"
    EFFECT = "effect"


class AssetQuality(Enum):
    """Quality tiers for assets"""
    PLACEHOLDER = "placeholder"
    DRAFT = "draft"
    PREVIEW = "preview"
    PRODUCTION = "production"
    POLISHED = "polished"


@dataclass
class AssetSpec:
    """Specification for a game asset"""
    name: str
    category: AssetCategory
    description: str
    tags: List[str] = field(default_factory=list)
    
    # Visual properties
    style: str = "stylized_survival"  # Art style
    color_palette: List[str] = field(default_factory=list)
    size_class: str = "medium"  # tiny, small, medium, large, huge
    
    # Technical properties
    poly_budget: int = 500  # For 2D, this affects detail level
    texture_size: int = 512
    animation_frames: int = 0
    
    # Variations
    variation_count: int = 3
    damage_states: int = 0  # 0 = no damage states
    
    # Metadata
    priority: int = 1  # 1 = highest
    dependencies: List[str] = field(default_factory=list)
    
    def to_prompt(self) -> str:
        """Convert spec to generation prompt"""
        parts = [
            f"Create a {self.size_class} {self.category.value}:",
            self.description,
            f"Style: {self.style}",
        ]
        
        if self.color_palette:
            parts.append(f"Colors: {', '.join(self.color_palette)}")
        
        if self.tags:
            parts.append(f"Keywords: {', '.join(self.tags)}")
        
        return " ".join(parts)


@dataclass
class GeneratedAsset:
    """Record of a generated asset"""
    spec: AssetSpec
    seed: int
    quality: AssetQuality
    file_paths: Dict[str, str] = field(default_factory=dict)
    generation_params: Dict = field(default_factory=dict)
    timestamp: float = 0.0
    approved: bool = False
    notes: str = ""


class AssetManifest:
    """
    Complete manifest of all assets needed for the game
    This defines EVERYTHING that needs to be generated
    """
    
    def __init__(self):
        self.assets: Dict[str, AssetSpec] = {}
        self._build_complete_manifest()
    
    def _build_complete_manifest(self):
        """Build the complete list of assets needed for the game"""
        
        # =====================================================================
        # CHARACTERS
        # =====================================================================
        
        self._add("player_male", AssetSpec(
            name="Player Male",
            category=AssetCategory.CHARACTER,
            description="Male survivor character with rugged appearance, worn clothing",
            tags=["human", "survivor", "protagonist", "male"],
            color_palette=["brown", "olive", "gray", "tan"],
            size_class="medium",
            animation_frames=8,
            variation_count=5,
            priority=1
        ))
        
        self._add("player_female", AssetSpec(
            name="Player Female",
            category=AssetCategory.CHARACTER,
            description="Female survivor character with practical gear, determined expression",
            tags=["human", "survivor", "protagonist", "female"],
            color_palette=["brown", "olive", "gray", "tan"],
            size_class="medium",
            animation_frames=8,
            variation_count=5,
            priority=1
        ))
        
        self._add("npc_trader", AssetSpec(
            name="Trader NPC",
            category=AssetCategory.CHARACTER,
            description="Friendly merchant with backpack full of goods, weathered but trustworthy",
            tags=["human", "npc", "trader", "merchant"],
            color_palette=["brown", "orange", "beige"],
            size_class="medium",
            animation_frames=4,
            variation_count=3,
            priority=2
        ))
        
        self._add("npc_survivor", AssetSpec(
            name="Survivor NPC",
            category=AssetCategory.CHARACTER,
            description="Random survivor needing rescue or offering quests",
            tags=["human", "npc", "survivor", "civilian"],
            color_palette=["varied"],
            size_class="medium",
            animation_frames=4,
            variation_count=8,
            priority=3
        ))
        
        # =====================================================================
        # ZOMBIES
        # =====================================================================
        
        self._add("zombie_basic", AssetSpec(
            name="Basic Zombie",
            category=AssetCategory.ZOMBIE,
            description="Standard shambling zombie, torn clothing, pale rotting skin",
            tags=["undead", "enemy", "zombie", "basic"],
            color_palette=["gray", "green", "brown", "red"],
            size_class="medium",
            animation_frames=6,
            variation_count=8,
            damage_states=3,
            priority=1
        ))
        
        self._add("zombie_fast", AssetSpec(
            name="Fast Zombie",
            category=AssetCategory.ZOMBIE,
            description="Agile infected, recent turn, faster and more aggressive",
            tags=["undead", "enemy", "zombie", "fast", "runner"],
            color_palette=["pale", "red", "brown"],
            size_class="medium",
            animation_frames=8,
            variation_count=4,
            damage_states=2,
            priority=1
        ))
        
        self._add("zombie_brute", AssetSpec(
            name="Brute Zombie",
            category=AssetCategory.ZOMBIE,
            description="Massive muscular zombie, slow but extremely powerful",
            tags=["undead", "enemy", "zombie", "brute", "tank"],
            color_palette=["dark gray", "purple", "brown"],
            size_class="large",
            animation_frames=6,
            variation_count=3,
            damage_states=3,
            priority=2
        ))
        
        self._add("zombie_spitter", AssetSpec(
            name="Spitter Zombie",
            category=AssetCategory.ZOMBIE,
            description="Ranged zombie with bloated acid sacs, spits corrosive bile",
            tags=["undead", "enemy", "zombie", "ranged", "spitter"],
            color_palette=["green", "yellow", "brown"],
            size_class="medium",
            animation_frames=6,
            variation_count=3,
            damage_states=2,
            priority=2
        ))
        
        self._add("zombie_screamer", AssetSpec(
            name="Screamer Zombie",
            category=AssetCategory.ZOMBIE,
            description="Emaciated zombie that screams to attract others",
            tags=["undead", "enemy", "zombie", "support", "screamer"],
            color_palette=["pale", "white", "gray"],
            size_class="small",
            animation_frames=6,
            variation_count=2,
            damage_states=2,
            priority=2
        ))
        
        self._add("zombie_boss_butcher", AssetSpec(
            name="The Butcher Boss",
            category=AssetCategory.ZOMBIE,
            description="Massive boss zombie wielding meat cleaver, apron covered in blood",
            tags=["undead", "enemy", "zombie", "boss", "butcher"],
            color_palette=["dark red", "brown", "black"],
            size_class="huge",
            animation_frames=8,
            variation_count=1,
            damage_states=4,
            priority=2
        ))
        
        self._add("zombie_boss_witch", AssetSpec(
            name="The Witch Boss",
            category=AssetCategory.ZOMBIE,
            description="Twisted female boss with long claws, cries when idle, rages when disturbed",
            tags=["undead", "enemy", "zombie", "boss", "witch"],
            color_palette=["pale white", "black", "red"],
            size_class="medium",
            animation_frames=8,
            variation_count=1,
            damage_states=3,
            priority=2
        ))
        
        # =====================================================================
        # WILDLIFE
        # =====================================================================
        
        self._add("animal_deer", AssetSpec(
            name="Deer",
            category=AssetCategory.WILDLIFE,
            description="Wild deer, skittish, source of meat and leather",
            tags=["animal", "wildlife", "passive", "deer"],
            color_palette=["brown", "tan", "white"],
            size_class="medium",
            animation_frames=6,
            variation_count=3,
            priority=3
        ))
        
        self._add("animal_wolf", AssetSpec(
            name="Wolf",
            category=AssetCategory.WILDLIFE,
            description="Aggressive wolf, hunts in packs",
            tags=["animal", "wildlife", "hostile", "wolf"],
            color_palette=["gray", "brown", "white"],
            size_class="medium",
            animation_frames=6,
            variation_count=4,
            priority=2
        ))
        
        self._add("animal_bear", AssetSpec(
            name="Bear",
            category=AssetCategory.WILDLIFE,
            description="Large bear, territorial and dangerous",
            tags=["animal", "wildlife", "hostile", "bear"],
            color_palette=["brown", "black"],
            size_class="large",
            animation_frames=6,
            variation_count=2,
            priority=3
        ))
        
        self._add("animal_rabbit", AssetSpec(
            name="Rabbit",
            category=AssetCategory.WILDLIFE,
            description="Small rabbit, quick and elusive",
            tags=["animal", "wildlife", "passive", "rabbit", "small"],
            color_palette=["brown", "gray", "white"],
            size_class="tiny",
            animation_frames=4,
            variation_count=3,
            priority=4
        ))
        
        # =====================================================================
        # WEAPONS - MELEE
        # =====================================================================
        
        weapons_melee = [
            ("weapon_fist", "Bare Fists", "Empty hands for desperate fighting", ["unarmed"], "tiny"),
            ("weapon_wood_club", "Wood Club", "Crude wooden club, basic melee weapon", ["wood", "blunt", "primitive"], "small"),
            ("weapon_baseball_bat", "Baseball Bat", "Classic aluminum baseball bat", ["metal", "blunt", "sport"], "medium"),
            ("weapon_crowbar", "Crowbar", "Sturdy steel crowbar, multi-purpose tool", ["metal", "blunt", "tool"], "medium"),
            ("weapon_machete", "Machete", "Sharp jungle machete for clearing brush and enemies", ["metal", "blade", "cutting"], "medium"),
            ("weapon_fire_axe", "Fire Axe", "Heavy firefighter axe, devastating blows", ["metal", "blade", "heavy"], "medium"),
            ("weapon_katana", "Katana", "Traditional Japanese sword, fast and deadly", ["metal", "blade", "rare"], "medium"),
            ("weapon_chainsaw", "Chainsaw", "Motorized chainsaw, loud but devastating", ["metal", "power", "loud"], "large"),
        ]
        
        for asset_id, name, desc, tags, size in weapons_melee:
            self._add(asset_id, AssetSpec(
                name=name,
                category=AssetCategory.WEAPON,
                description=desc,
                tags=["weapon", "melee"] + tags,
                color_palette=["metal", "wood", "rust"],
                size_class=size,
                variation_count=2,
                damage_states=3,
                priority=1 if "primitive" in tags else 2
            ))
        
        # =====================================================================
        # WEAPONS - RANGED
        # =====================================================================
        
        weapons_ranged = [
            ("weapon_bow", "Wooden Bow", "Simple hunting bow", ["wood", "primitive", "silent"], "medium"),
            ("weapon_crossbow", "Crossbow", "Modern hunting crossbow", ["composite", "silent"], "medium"),
            ("weapon_pistol", "Pistol", "9mm semi-automatic pistol", ["firearm", "common"], "small"),
            ("weapon_revolver", "Revolver", ".44 magnum revolver, powerful", ["firearm", "powerful"], "small"),
            ("weapon_shotgun", "Shotgun", "12-gauge pump shotgun", ["firearm", "spread"], "large"),
            ("weapon_rifle", "Hunting Rifle", "Bolt-action hunting rifle with scope", ["firearm", "precision"], "large"),
            ("weapon_assault_rifle", "Assault Rifle", "Military assault rifle, fully automatic", ["firearm", "military", "rare"], "large"),
            ("weapon_sniper", "Sniper Rifle", "High-powered sniper rifle", ["firearm", "precision", "rare"], "large"),
        ]
        
        for asset_id, name, desc, tags, size in weapons_ranged:
            self._add(asset_id, AssetSpec(
                name=name,
                category=AssetCategory.WEAPON,
                description=desc,
                tags=["weapon", "ranged"] + tags,
                color_palette=["metal", "black", "wood"],
                size_class=size,
                variation_count=2,
                damage_states=3,
                priority=2
            ))
        
        # =====================================================================
        # ARMOR
        # =====================================================================
        
        armor_items = [
            ("armor_cloth_shirt", "Cloth Shirt", "Basic cloth shirt, minimal protection", "torso", "common"),
            ("armor_leather_jacket", "Leather Jacket", "Sturdy leather jacket", "torso", "uncommon"),
            ("armor_kevlar_vest", "Kevlar Vest", "Police kevlar vest", "torso", "rare"),
            ("armor_tactical_vest", "Tactical Vest", "Military tactical vest", "torso", "epic"),
            ("armor_power_armor", "Power Armor", "Experimental powered armor", "torso", "legendary"),
            ("armor_jeans", "Jeans", "Regular denim jeans", "legs", "common"),
            ("armor_cargo_pants", "Cargo Pants", "Durable cargo pants", "legs", "uncommon"),
            ("armor_combat_boots", "Combat Boots", "Military combat boots", "feet", "uncommon"),
            ("armor_bandana", "Bandana", "Simple cloth bandana", "head", "common"),
            ("armor_motorcycle_helmet", "Motorcycle Helmet", "Protective bike helmet", "head", "uncommon"),
            ("armor_military_helmet", "Military Helmet", "Ballistic military helmet", "head", "rare"),
            ("armor_night_vision", "Night Vision Goggles", "Military NVG", "head", "epic"),
        ]
        
        for asset_id, name, desc, slot, rarity in armor_items:
            self._add(asset_id, AssetSpec(
                name=name,
                category=AssetCategory.ARMOR,
                description=desc,
                tags=["armor", slot, rarity],
                color_palette=["varied"],
                size_class="small",
                variation_count=3,
                damage_states=3,
                priority=2 if rarity in ["common", "uncommon"] else 3
            ))
        
        # =====================================================================
        # BUILDINGS
        # =====================================================================
        
        buildings = [
            ("building_house_small", "Small House", "Suburban single-story house", ["residential", "loot"], "large"),
            ("building_house_large", "Large House", "Two-story suburban home", ["residential", "loot"], "huge"),
            ("building_cabin", "Forest Cabin", "Rustic wooden cabin", ["residential", "wood"], "medium"),
            ("building_store", "Convenience Store", "Small retail store", ["commercial", "loot"], "large"),
            ("building_gas_station", "Gas Station", "Roadside gas station", ["commercial", "fuel"], "large"),
            ("building_warehouse", "Warehouse", "Industrial storage warehouse", ["industrial", "loot"], "huge"),
            ("building_hospital", "Hospital", "Medical facility", ["medical", "loot", "dangerous"], "huge"),
            ("building_police_station", "Police Station", "Local police department", ["military", "loot", "dangerous"], "large"),
            ("building_military_base", "Military Bunker", "Underground military facility", ["military", "loot", "dangerous"], "huge"),
            ("building_farm", "Farm House", "Rural farmhouse with barn", ["rural", "food"], "large"),
            ("building_church", "Church", "Small town church", ["religious"], "large"),
            ("building_school", "School", "Elementary school building", ["institutional", "large_interior"], "huge"),
        ]
        
        for asset_id, name, desc, tags, size in buildings:
            self._add(asset_id, AssetSpec(
                name=name,
                category=AssetCategory.BUILDING,
                description=desc,
                tags=["building"] + tags,
                color_palette=["concrete", "brick", "wood", "metal"],
                size_class=size,
                damage_states=4,
                priority=2
            ))
        
        # =====================================================================
        # PROPS AND RESOURCES
        # =====================================================================
        
        props = [
            ("prop_tree_pine", "Pine Tree", "Tall evergreen pine tree", ["nature", "harvestable"], "large", 8),
            ("prop_tree_oak", "Oak Tree", "Broad deciduous oak tree", ["nature", "harvestable"], "large", 5),
            ("prop_tree_dead", "Dead Tree", "Bare dead tree", ["nature", "harvestable"], "medium", 3),
            ("prop_bush", "Bush", "Wild shrub, may contain berries", ["nature", "harvestable"], "small", 6),
            ("prop_rock_small", "Small Rock", "Boulder with mineral deposits", ["nature", "harvestable"], "small", 5),
            ("prop_rock_large", "Large Rock", "Large rock formation", ["nature", "harvestable"], "medium", 3),
            ("prop_car_sedan", "Sedan Car", "Abandoned sedan", ["vehicle", "loot", "metal"], "large", 4),
            ("prop_car_truck", "Pickup Truck", "Abandoned pickup truck", ["vehicle", "loot", "metal"], "large", 3),
            ("prop_car_wreck", "Car Wreckage", "Burned out vehicle remains", ["vehicle", "scrap"], "large", 5),
            ("prop_barrel", "Barrel", "Industrial barrel", ["container", "loot"], "small", 3),
            ("prop_crate_wood", "Wooden Crate", "Wooden shipping crate", ["container", "loot"], "small", 4),
            ("prop_crate_metal", "Metal Crate", "Military supply crate", ["container", "loot", "rare"], "small", 2),
            ("prop_dumpster", "Dumpster", "Trash dumpster", ["container", "loot"], "medium", 2),
            ("prop_mailbox", "Mailbox", "Residential mailbox", ["decoration"], "tiny", 2),
            ("prop_streetlight", "Street Light", "Broken street lamp", ["decoration", "light"], "large", 2),
            ("prop_bench", "Park Bench", "Wooden park bench", ["decoration"], "small", 2),
            ("prop_fence_wood", "Wooden Fence", "Basic wooden fence segment", ["barrier"], "small", 3),
            ("prop_fence_chain", "Chain Fence", "Chain-link fence segment", ["barrier"], "small", 2),
        ]
        
        for asset_id, name, desc, tags, size, variations in props:
            self._add(asset_id, AssetSpec(
                name=name,
                category=AssetCategory.PROP,
                description=desc,
                tags=["prop"] + tags,
                color_palette=["natural", "rust", "worn"],
                size_class=size,
                variation_count=variations,
                damage_states=2 if "harvestable" in tags else 0,
                priority=3
            ))
        
        # =====================================================================
        # RESOURCE ITEMS
        # =====================================================================
        
        resources = [
            ("resource_wood", "Wood", "Basic timber resource"),
            ("resource_stone", "Stone", "Raw stone material"),
            ("resource_iron_ore", "Iron Ore", "Unprocessed iron ore"),
            ("resource_copper_ore", "Copper Ore", "Raw copper ore"),
            ("resource_coal", "Coal", "Combustible coal"),
            ("resource_fibers", "Plant Fibers", "Natural plant fibers"),
            ("resource_cloth", "Cloth", "Fabric material"),
            ("resource_leather", "Leather", "Animal hide leather"),
            ("resource_rubber", "Rubber", "Synthetic rubber"),
            ("resource_glass", "Glass", "Glass material"),
            ("resource_electronics", "Electronics", "Electronic components"),
            ("resource_gunpowder", "Gunpowder", "Explosive compound"),
            ("resource_steel_ingot", "Steel Ingot", "Refined steel bar"),
            ("resource_titanium", "Titanium", "Rare titanium alloy"),
            ("resource_polymer", "Polymer", "Advanced synthetic polymer"),
        ]
        
        for asset_id, name, desc in resources:
            self._add(asset_id, AssetSpec(
                name=name,
                category=AssetCategory.RESOURCE,
                description=desc,
                tags=["resource", "material", "icon"],
                size_class="tiny",
                texture_size=64,
                priority=1
            ))
        
        # =====================================================================
        # CONSUMABLES
        # =====================================================================
        
        consumables = [
            ("item_bandage", "Bandage", "Basic wound dressing"),
            ("item_medkit", "Medkit", "Complete medical kit"),
            ("item_painkillers", "Painkillers", "Over-the-counter pain relief"),
            ("item_adrenaline", "Adrenaline Shot", "Emergency stimulant"),
            ("item_water_bottle", "Water Bottle", "Purified drinking water"),
            ("item_canned_food", "Canned Food", "Preserved canned goods"),
            ("item_mre", "MRE Pack", "Military ration"),
            ("item_berries", "Wild Berries", "Foraged berries"),
            ("item_meat_raw", "Raw Meat", "Uncooked animal meat"),
            ("item_meat_cooked", "Cooked Meat", "Prepared meat meal"),
        ]
        
        for asset_id, name, desc in consumables:
            self._add(asset_id, AssetSpec(
                name=name,
                category=AssetCategory.RESOURCE,
                description=desc,
                tags=["consumable", "item", "icon"],
                size_class="tiny",
                texture_size=64,
                priority=2
            ))
        
        # =====================================================================
        # TERRAIN TILES
        # =====================================================================
        
        terrain = [
            ("terrain_grass", "Grass", "Green grass ground"),
            ("terrain_dirt", "Dirt", "Brown dirt path"),
            ("terrain_sand", "Sand", "Sandy ground"),
            ("terrain_concrete", "Concrete", "Paved concrete"),
            ("terrain_asphalt", "Asphalt", "Road surface"),
            ("terrain_gravel", "Gravel", "Loose gravel"),
            ("terrain_mud", "Mud", "Wet muddy ground"),
            ("terrain_snow", "Snow", "Snow-covered ground"),
            ("terrain_water", "Water", "Shallow water"),
            ("terrain_wood_floor", "Wood Floor", "Wooden planking"),
            ("terrain_tile_floor", "Tile Floor", "Interior tiles"),
            ("terrain_carpet", "Carpet", "Interior carpeting"),
        ]
        
        for asset_id, name, desc in terrain:
            self._add(asset_id, AssetSpec(
                name=name,
                category=AssetCategory.TERRAIN,
                description=desc,
                tags=["terrain", "tile", "tileable"],
                size_class="small",
                texture_size=128,
                variation_count=4,
                priority=1
            ))
        
        # =====================================================================
        # EFFECTS
        # =====================================================================
        
        effects = [
            ("effect_blood_splatter", "Blood Splatter", "Gore effect"),
            ("effect_explosion", "Explosion", "Fiery explosion"),
            ("effect_smoke", "Smoke", "Rising smoke"),
            ("effect_fire", "Fire", "Burning flames"),
            ("effect_sparks", "Sparks", "Electric sparks"),
            ("effect_muzzle_flash", "Muzzle Flash", "Gun firing effect"),
            ("effect_impact_dust", "Dust Impact", "Ground impact"),
            ("effect_healing", "Healing", "Green healing aura"),
            ("effect_poison", "Poison", "Toxic green effect"),
            ("effect_lightning", "Lightning", "Electric discharge"),
        ]
        
        for asset_id, name, desc in effects:
            self._add(asset_id, AssetSpec(
                name=name,
                category=AssetCategory.EFFECT,
                description=desc,
                tags=["effect", "vfx", "animated"],
                size_class="small",
                animation_frames=8,
                priority=3
            ))
    
    def _add(self, asset_id: str, spec: AssetSpec):
        """Add an asset to the manifest"""
        self.assets[asset_id] = spec
    
    def get_by_category(self, category: AssetCategory) -> Dict[str, AssetSpec]:
        """Get all assets in a category"""
        return {k: v for k, v in self.assets.items() if v.category == category}
    
    def get_by_priority(self, priority: int) -> Dict[str, AssetSpec]:
        """Get all assets with specific priority"""
        return {k: v for k, v in self.assets.items() if v.priority == priority}
    
    def get_by_tag(self, tag: str) -> Dict[str, AssetSpec]:
        """Get all assets with a specific tag"""
        return {k: v for k, v in self.assets.items() if tag in v.tags}
    
    def to_json(self) -> str:
        """Export manifest to JSON"""
        data = {}
        for asset_id, spec in self.assets.items():
            spec_dict = asdict(spec)
            spec_dict["category"] = spec.category.value
            data[asset_id] = spec_dict
        return json.dumps(data, indent=2)
    
    def save(self, path: Path):
        """Save manifest to file"""
        path.write_text(self.to_json())
    
    @classmethod
    def load(cls, path: Path) -> "AssetManifest":
        """Load manifest from file"""
        manifest = cls()
        manifest.assets.clear()
        
        data = json.loads(path.read_text())
        for asset_id, spec_dict in data.items():
            spec_dict["category"] = AssetCategory(spec_dict["category"])
            manifest.assets[asset_id] = AssetSpec(**spec_dict)
        
        return manifest
    
    def get_generation_queue(self) -> List[Tuple[str, AssetSpec]]:
        """Get ordered queue of assets to generate (by priority)"""
        items = list(self.assets.items())
        items.sort(key=lambda x: (x[1].priority, x[0]))
        return items
    
    def get_stats(self) -> Dict:
        """Get statistics about the manifest"""
        stats = {
            "total_assets": len(self.assets),
            "by_category": {},
            "by_priority": {},
            "total_variations": 0,
            "total_animation_frames": 0
        }
        
        for spec in self.assets.values():
            cat = spec.category.value
            stats["by_category"][cat] = stats["by_category"].get(cat, 0) + 1
            stats["by_priority"][spec.priority] = stats["by_priority"].get(spec.priority, 0) + 1
            stats["total_variations"] += spec.variation_count
            stats["total_animation_frames"] += spec.animation_frames * spec.variation_count
        
        return stats


def main():
    """Generate the asset manifest and print statistics"""
    manifest = AssetManifest()
    stats = manifest.get_stats()
    
    print("=" * 60)
    print("GODOT SURVIVAL PROTOTYPE - ASSET MANIFEST")
    print("=" * 60)
    print(f"\nTotal Assets Defined: {stats['total_assets']}")
    print(f"Total Variations: {stats['total_variations']}")
    print(f"Total Animation Frames: {stats['total_animation_frames']}")
    
    print("\nAssets by Category:")
    for cat, count in sorted(stats["by_category"].items()):
        print(f"  {cat}: {count}")
    
    print("\nAssets by Priority:")
    for pri, count in sorted(stats["by_priority"].items()):
        print(f"  Priority {pri}: {count}")
    
    # Save manifest
    output_path = PROJECT_ROOT / "blender_pipeline" / "asset_manifest.json"
    manifest.save(output_path)
    print(f"\nManifest saved to: {output_path}")
    
    # Print generation queue preview
    print("\nGeneration Queue (first 20):")
    queue = manifest.get_generation_queue()
    for i, (asset_id, spec) in enumerate(queue[:20]):
        print(f"  {i+1}. [{spec.priority}] {spec.name} ({spec.category.value})")


if __name__ == "__main__":
    main()
