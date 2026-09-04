import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class ZombieGenerator(BaseModelGenerator, BaseMaterial):
    asset_type = "zombie"

    def generate(
        self,
        seed: int | None = None,
        size: float = 1.0,
        variation: float = 1.0,
        color: tuple[float, float, float, float] = (0.4, 0.65, 0.45, 1.0),
        damage_level: float = 0.3,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions("zombie")
        self._ensure_object_mode()
        self._deselect_all()

        parts = []
        # Torso
        bpy.ops.mesh.primitive_cube_add(size=0.6 * size, location=(0, 0, 0.9 * size))
        torso = bpy.context.active_object
        torso.scale.x *= 0.8
        torso.scale.y *= 0.4
        torso.name = "zombie_torso"
        parts.append(torso)

        # Head
        bpy.ops.mesh.primitive_cube_add(size=0.35 * size, location=(0, 0, 1.4 * size))
        head = bpy.context.active_object
        head.scale.x *= 0.9
        head.scale.y *= 0.9
        head.name = "zombie_head"
        parts.append(head)

        # Legs
        leg_y = 0.12 * size
        for offset in (-leg_y, leg_y):
            bpy.ops.mesh.primitive_cube_add(size=0.15 * size, location=(0, offset, 0.45 * size))
            leg = bpy.context.active_object
            leg.scale.z = 2.2
            leg.name = f"zombie_leg_{'L' if offset < 0 else 'R'}"
            parts.append(leg)

        # Arms
        arm_y = 0.28 * size
        for offset in (-arm_y, arm_y):
            bpy.ops.mesh.primitive_cube_add(size=0.12 * size, location=(0, offset, 1.0 * size))
            arm = bpy.context.active_object
            arm.scale.x = 1.6
            arm.scale.z = 1.1
            arm.rotation_euler[1] = rng.uniform(-0.3, 0.3) * variation
            arm.name = f"zombie_arm_{'L' if offset < 0 else 'R'}"
            parts.append(arm)

        body_mat = self.create_material("Zombie_Skin", color)
        nodes = body_mat.node_tree.nodes
        links = body_mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        noise = self.add_noise(nodes, scale=6.0, detail=1.0)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.8, color[1] * 0.9, color[2] * 0.75, 1.0)],
            positions=[0.2, 0.85],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])

        for part in parts:
            part.data.materials.append(body_mat)

        self._ensure_object_mode()
        self._deselect_all()
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = torso
        bpy.ops.object.join()

        zombie = bpy.context.active_object
        if damage_level > 0:
            zombie.rotation_euler[2] = rng.uniform(-0.2, 0.2) * (1.0 + damage_level)
            zombie.scale.x *= 1.0 - 0.1 * damage_level

        zombie.name = "zombie" if seed is None else f"zombie_{seed}"
        self.apply_flat_shading(zombie)
        self.center_on_origin(zombie)
        self.place_in_collection(zombie, "Zombies")
        return zombie
