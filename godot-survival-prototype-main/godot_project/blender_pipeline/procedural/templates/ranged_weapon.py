import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class RangedWeaponGenerator(BaseModelGenerator, BaseMaterial):
    """Generates ranged weapons: pistols, rifles, shotguns, bows, crossbows"""
    asset_type = "ranged_weapon"

    WEAPON_TYPES = {
        "pistol": {"barrel_len": 0.15, "body_scale": 0.8, "caliber": "small"},
        "revolver": {"barrel_len": 0.12, "body_scale": 0.9, "has_cylinder": True, "caliber": "medium"},
        "shotgun": {"barrel_len": 0.7, "body_scale": 1.2, "caliber": "large"},
        "rifle": {"barrel_len": 0.8, "body_scale": 1.0, "has_scope": False, "caliber": "medium"},
        "sniper_rifle": {"barrel_len": 0.9, "body_scale": 1.1, "has_scope": True, "caliber": "large"},
        "smg": {"barrel_len": 0.25, "body_scale": 0.9, "has_magazine": True, "caliber": "small"},
        "assault_rifle": {"barrel_len": 0.5, "body_scale": 1.0, "has_magazine": True, "caliber": "medium"},
        "bow": {"limb_len": 0.6, "is_bow": True},
        "crossbow": {"limb_len": 0.4, "body_len": 0.5, "is_crossbow": True},
        "makeshift_pistol": {"barrel_len": 0.12, "body_scale": 0.7, "rusty": True, "caliber": "small"},
    }

    def generate(
        self,
        seed: int | None = None,
        weapon_type: str = "pistol",
        size: float = 1.0,
        variation: float = 1.0,
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions(f"ranged_{weapon_type}")
        self._ensure_object_mode()
        self._deselect_all()

        config = self.WEAPON_TYPES.get(weapon_type, self.WEAPON_TYPES["pistol"])
        parts = []

        if config.get("is_bow"):
            parts = self._create_bow(config, size, rng)
        elif config.get("is_crossbow"):
            parts = self._create_crossbow(config, size, rng)
        else:
            parts = self._create_firearm(config, size, rng, weapon_type)

        # Apply materials
        is_rusty = config.get("rusty", False) or damage_level > 0.5
        mat = self._create_gun_material(rng, damage_level, is_rusty)

        for part in parts:
            if part.data.materials:
                part.data.materials[0] = mat
            else:
                part.data.materials.append(mat)

        # Join parts
        self._ensure_object_mode()
        self._deselect_all()
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()

        result = bpy.context.active_object
        result.name = f"ranged_{weapon_type}_v001"
        return result

    def _create_firearm(self, config: dict, size: float, rng: Random, weapon_type: str) -> list:
        parts = []
        barrel_len = config.get("barrel_len", 0.3) * size
        body_scale = config.get("body_scale", 1.0)

        # Barrel
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12, radius=0.02 * size, depth=barrel_len,
            location=(barrel_len / 2, 0, 0.05 * size)
        )
        barrel = bpy.context.active_object
        barrel.rotation_euler[1] = 1.5708
        barrel.name = "gun_barrel"
        parts.append(barrel)

        # Body/receiver
        body_width = 0.08 * size * body_scale
        body_height = 0.06 * size * body_scale
        body_len = 0.15 * size * body_scale

        bpy.ops.mesh.primitive_cube_add(
            size=body_len,
            location=(0, 0, 0.02 * size)
        )
        body = bpy.context.active_object
        body.scale = (1.0, body_width / body_len, body_height / body_len)
        body.name = "gun_body"
        parts.append(body)

        # Grip
        bpy.ops.mesh.primitive_cube_add(
            size=0.04 * size,
            location=(-0.03 * size, 0, -0.05 * size)
        )
        grip = bpy.context.active_object
        grip.scale = (0.8, 1.2, 2.0)
        grip.rotation_euler[1] = -0.2
        grip.name = "gun_grip"
        parts.append(grip)

        # Stock (for rifles/shotguns)
        if weapon_type in ["shotgun", "rifle", "sniper_rifle", "assault_rifle"]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.06 * size,
                location=(-0.15 * size, 0, 0)
            )
            stock = bpy.context.active_object
            stock.scale = (2.0, 0.6, 0.8)
            stock.name = "gun_stock"
            parts.append(stock)

        # Magazine
        if config.get("has_magazine"):
            bpy.ops.mesh.primitive_cube_add(
                size=0.03 * size,
                location=(0, 0, -0.04 * size)
            )
            mag = bpy.context.active_object
            mag.scale = (0.8, 0.5, 1.8)
            mag.name = "gun_magazine"
            parts.append(mag)

        # Cylinder (for revolvers)
        if config.get("has_cylinder"):
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6, radius=0.025 * size, depth=0.04 * size,
                location=(0.02 * size, 0, 0.02 * size)
            )
            cylinder = bpy.context.active_object
            cylinder.rotation_euler[0] = 1.5708
            cylinder.name = "gun_cylinder"
            parts.append(cylinder)

        # Scope
        if config.get("has_scope"):
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=12, radius=0.015 * size, depth=0.12 * size,
                location=(0.05 * size, 0, 0.08 * size)
            )
            scope = bpy.context.active_object
            scope.rotation_euler[1] = 1.5708
            scope.name = "gun_scope"
            parts.append(scope)

        return parts

    def _create_bow(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        limb_len = config.get("limb_len", 0.6) * size

        # Main bow curve (simplified as cylinder)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.015 * size, depth=limb_len * 2,
            location=(0, 0, 0)
        )
        limb = bpy.context.active_object
        limb.name = "bow_limb"
        parts.append(limb)

        # Grip area
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.025 * size, depth=0.1 * size,
            location=(0, 0, 0)
        )
        grip = bpy.context.active_object
        grip.name = "bow_grip"
        parts.append(grip)

        return parts

    def _create_crossbow(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        limb_len = config.get("limb_len", 0.4) * size
        body_len = config.get("body_len", 0.5) * size

        # Stock/body
        bpy.ops.mesh.primitive_cube_add(
            size=0.05 * size,
            location=(0, 0, 0)
        )
        body = bpy.context.active_object
        body.scale = (body_len / (0.05 * size), 0.5, 0.8)
        body.name = "crossbow_body"
        parts.append(body)

        # Limb
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.012 * size, depth=limb_len * 2,
            location=(body_len * 0.4, 0, 0.02 * size)
        )
        limb = bpy.context.active_object
        limb.rotation_euler[0] = 1.5708
        limb.name = "crossbow_limb"
        parts.append(limb)

        return parts

    def _create_gun_material(self, rng: Random, damage: float, rusty: bool) -> bpy.types.Material:
        if rusty:
            base = 0.25
            color = (base + 0.1, base, base - 0.05, 1.0)
        else:
            base = 0.15 + rng.uniform(-0.02, 0.02)
            color = (base, base, base + 0.01, 1.0)

        mat = self.create_material("Ranged_Metal", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        bsdf.inputs["Metallic"].default_value = 0.9 - damage * 0.3
        bsdf.inputs["Roughness"].default_value = 0.2 + damage * 0.4

        noise = self.add_noise(nodes, scale=25.0, detail=1.5)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.8, color[1] * 0.75, color[2] * 0.7, 1.0)],
            positions=[0.35, 0.85],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])

        return mat
