import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class MeleeWeaponGenerator(BaseModelGenerator, BaseMaterial):
    """Generates melee weapons: clubs, bats, machetes, axes, knives, crowbars"""
    asset_type = "melee_weapon"

    WEAPON_TYPES = {
        "wood_club": {"handle_len": 0.8, "head_scale": 1.3, "material": "wood"},
        "baseball_bat": {"handle_len": 0.7, "head_scale": 1.1, "material": "wood"},
        "machete": {"handle_len": 0.25, "blade_len": 0.6, "material": "metal"},
        "fire_axe": {"handle_len": 0.9, "head_scale": 0.4, "material": "metal"},
        "crowbar": {"length": 0.7, "curve": 0.15, "material": "metal"},
        "knife": {"handle_len": 0.12, "blade_len": 0.2, "material": "metal"},
        "sledgehammer": {"handle_len": 1.0, "head_scale": 0.35, "material": "metal"},
        "pipe_wrench": {"handle_len": 0.4, "head_scale": 0.15, "material": "metal"},
        "katana": {"handle_len": 0.3, "blade_len": 0.9, "material": "metal"},
        "spiked_bat": {"handle_len": 0.7, "head_scale": 1.1, "has_spikes": True, "material": "wood"},
    }

    def generate(
        self,
        seed: int | None = None,
        weapon_type: str = "wood_club",
        size: float = 1.0,
        variation: float = 1.0,
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions(f"melee_{weapon_type}")
        self._ensure_object_mode()
        self._deselect_all()

        config = self.WEAPON_TYPES.get(weapon_type, self.WEAPON_TYPES["wood_club"])
        parts = []

        if weapon_type in ["wood_club", "baseball_bat", "spiked_bat"]:
            parts = self._create_club(config, size, rng)
        elif weapon_type in ["machete", "knife", "katana"]:
            parts = self._create_blade(config, size, rng)
        elif weapon_type in ["fire_axe", "sledgehammer"]:
            parts = self._create_axe(config, size, rng, weapon_type)
        elif weapon_type == "crowbar":
            parts = self._create_crowbar(config, size, rng)
        elif weapon_type == "pipe_wrench":
            parts = self._create_wrench(config, size, rng)

        # Apply materials
        mat_type = config.get("material", "wood")
        if mat_type == "wood":
            mat = self._create_wood_material(rng)
        else:
            mat = self._create_metal_material(rng, damage_level)

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
        result.name = f"melee_{weapon_type}_v001"
        return result

    def _create_club(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        handle_len = config.get("handle_len", 0.7) * size
        head_scale = config.get("head_scale", 1.2)

        # Handle
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.03 * size, depth=handle_len,
            location=(0, 0, handle_len / 2)
        )
        handle = bpy.context.active_object
        handle.name = "club_handle"
        parts.append(handle)

        # Head (thicker top)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10, radius=0.05 * size * head_scale, depth=0.25 * size,
            location=(0, 0, handle_len + 0.1 * size)
        )
        head = bpy.context.active_object
        head.name = "club_head"
        parts.append(head)

        # Add spikes if spiked bat
        if config.get("has_spikes", False):
            for i in range(6):
                angle = i * (3.14159 / 3)
                x = 0.06 * size * rng.uniform(0.8, 1.0)
                bpy.ops.mesh.primitive_cone_add(
                    vertices=4, radius1=0.015 * size, depth=0.04 * size,
                    location=(x * rng.choice([-1, 1]), x * rng.choice([-1, 1]), 
                             handle_len + rng.uniform(0.05, 0.15) * size)
                )
                spike = bpy.context.active_object
                spike.rotation_euler = (rng.uniform(-0.5, 0.5), rng.uniform(-0.5, 0.5), 0)
                spike.name = f"spike_{i}"
                parts.append(spike)

        return parts

    def _create_blade(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        handle_len = config.get("handle_len", 0.15) * size
        blade_len = config.get("blade_len", 0.4) * size

        # Handle
        bpy.ops.mesh.primitive_cube_add(
            size=0.08 * size,
            location=(0, 0, handle_len / 2)
        )
        handle = bpy.context.active_object
        handle.scale = (0.4, 0.8, handle_len / (0.08 * size))
        handle.name = "blade_handle"
        parts.append(handle)

        # Blade
        bpy.ops.mesh.primitive_cube_add(
            size=0.1 * size,
            location=(0, 0, handle_len + blade_len / 2)
        )
        blade = bpy.context.active_object
        blade.scale = (0.15, 1.0, blade_len / (0.1 * size))
        blade.name = "blade_blade"
        parts.append(blade)

        return parts

    def _create_axe(self, config: dict, size: float, rng: Random, axe_type: str) -> list:
        parts = []
        handle_len = config.get("handle_len", 0.9) * size

        # Handle
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.025 * size, depth=handle_len,
            location=(0, 0, handle_len / 2)
        )
        handle = bpy.context.active_object
        handle.name = "axe_handle"
        parts.append(handle)

        # Head
        if axe_type == "fire_axe":
            bpy.ops.mesh.primitive_cube_add(
                size=0.15 * size,
                location=(0.08 * size, 0, handle_len - 0.05 * size)
            )
            head = bpy.context.active_object
            head.scale = (1.5, 0.3, 1.2)
        else:  # sledgehammer
            bpy.ops.mesh.primitive_cube_add(
                size=0.12 * size,
                location=(0, 0, handle_len + 0.02 * size)
            )
            head = bpy.context.active_object
            head.scale = (1.0, 1.0, 0.8)
        head.name = "axe_head"
        parts.append(head)

        return parts

    def _create_crowbar(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        length = config.get("length", 0.7) * size

        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6, radius=0.02 * size, depth=length,
            location=(0, 0, length / 2)
        )
        bar = bpy.context.active_object
        bar.name = "crowbar_main"
        parts.append(bar)

        # Curved end
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6, radius=0.02 * size, depth=0.1 * size,
            location=(0.04 * size, 0, length - 0.02 * size)
        )
        end = bpy.context.active_object
        end.rotation_euler[1] = 1.2
        end.name = "crowbar_end"
        parts.append(end)

        return parts

    def _create_wrench(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        handle_len = config.get("handle_len", 0.4) * size

        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8, radius=0.025 * size, depth=handle_len,
            location=(0, 0, handle_len / 2)
        )
        handle = bpy.context.active_object
        handle.name = "wrench_handle"
        parts.append(handle)

        bpy.ops.mesh.primitive_cube_add(
            size=0.08 * size,
            location=(0, 0, handle_len + 0.03 * size)
        )
        head = bpy.context.active_object
        head.scale = (0.6, 1.2, 0.8)
        head.name = "wrench_head"
        parts.append(head)

        return parts

    def _create_wood_material(self, rng: Random) -> bpy.types.Material:
        color = (0.35 + rng.uniform(-0.05, 0.05), 0.22 + rng.uniform(-0.03, 0.03), 0.12, 1.0)
        mat = self.create_material("Melee_Wood", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        bsdf.inputs["Roughness"].default_value = 0.7
        noise = self.add_noise(nodes, scale=15.0, detail=2.0)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.7, color[1] * 0.6, color[2] * 0.5, 1.0)],
            positions=[0.3, 0.7],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])
        return mat

    def _create_metal_material(self, rng: Random, damage: float) -> bpy.types.Material:
        base = 0.5 - damage * 0.2
        color = (base, base, base + 0.02, 1.0)
        mat = self.create_material("Melee_Metal", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        bsdf.inputs["Metallic"].default_value = 0.85
        bsdf.inputs["Roughness"].default_value = 0.25 + damage * 0.3
        noise = self.add_noise(nodes, scale=20.0, detail=1.0)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.85, color[1] * 0.8, color[2] * 0.75, 1.0)],
            positions=[0.4, 0.9],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])
        return mat
