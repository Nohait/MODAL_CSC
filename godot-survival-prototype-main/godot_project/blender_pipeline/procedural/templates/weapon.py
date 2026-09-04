import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class WeaponGenerator(BaseModelGenerator, BaseMaterial):
    asset_type = "weapon"

    def generate(
        self,
        seed: int | None = None,
        size: float = 1.0,
        variation: float = 1.0,
        color: tuple[float, float, float, float] = (0.18, 0.18, 0.2, 1.0),
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions("weapon")
        self._ensure_object_mode()
        self._deselect_all()

        parts = []
        # Barrel
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=0.04 * size,
            depth=1.0 * size,
            location=(0.5 * size, 0, 0.05 * size),
        )
        barrel = bpy.context.active_object
        barrel.rotation_euler[1] = 1.5708
        barrel.name = "weapon_barrel"
        parts.append(barrel)

        # Stock / body
        bpy.ops.mesh.primitive_cube_add(size=0.3 * size, location=(0, 0, 0))
        body = bpy.context.active_object
        body.scale.x = 2.0
        body.scale.z = 0.6
        body.name = "weapon_body"
        parts.append(body)

        # Grip
        bpy.ops.mesh.primitive_cube_add(size=0.15 * size, location=(-0.15 * size, -0.08 * size, -0.15 * size))
        grip = bpy.context.active_object
        grip.scale.z = 1.3
        grip.name = "weapon_grip"
        parts.append(grip)

        mat = self.create_material("Weapon_Metal", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        bsdf.inputs["Metallic"].default_value = 0.6
        bsdf.inputs["Roughness"].default_value = 0.3
        noise = self.add_noise(nodes, scale=12.0, detail=1.5)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.7, color[1] * 0.7, color[2] * 0.72, 1.0)],
            positions=[0.4, 0.85],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])

        for part in parts:
            part.data.materials.append(mat)

        self._ensure_object_mode()
        self._deselect_all()
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.join()

        weapon = bpy.context.active_object
        if damage_level > 0:
            weapon.scale.x *= 1.0 - 0.05 * damage_level
            weapon.rotation_euler[2] = rng.uniform(-0.1, 0.1) * damage_level

        weapon.name = "weapon" if seed is None else f"weapon_{seed}"
        self.apply_flat_shading(weapon)
        self.center_on_origin(weapon)
        self.place_in_collection(weapon, "Weapons")
        return weapon
