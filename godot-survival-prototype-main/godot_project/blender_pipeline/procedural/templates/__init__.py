import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

# Template exports for procedural asset generation
from .model_base import BaseModelGenerator
from .material_base import BaseMaterial

# Environment assets
from .tree import TreeGenerator
from .rock import RockGenerator
from .bush import BushGenerator
from .ground_tile import GroundTileGenerator
from .building import BuildingGenerator
from .crate import CrateGenerator
from .ruin import RuinGenerator

# Characters & Enemies
from .character import CharacterGenerator
from .zombie import ZombieGenerator
from .enemy_variants import EnemyVariantGenerator

# Weapons & Armor
from .weapon import WeaponGenerator
from .melee_weapon import MeleeWeaponGenerator
from .ranged_weapon import RangedWeaponGenerator
from .armor import ArmorGenerator

__all__ = [
    "BaseModelGenerator",
    "BaseMaterial",
    "TreeGenerator",
    "RockGenerator",
    "BushGenerator",
    "GroundTileGenerator",
    "BuildingGenerator",
    "CrateGenerator",
    "RuinGenerator",
    "CharacterGenerator",
    "ZombieGenerator",
    "EnemyVariantGenerator",
    "WeaponGenerator",
    "MeleeWeaponGenerator",
    "RangedWeaponGenerator",
    "ArmorGenerator",
]
