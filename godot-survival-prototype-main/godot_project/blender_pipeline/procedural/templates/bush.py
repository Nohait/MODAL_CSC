import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class BushGenerator(BaseModelGenerator, BaseMaterial):
    asset_type = "bush"

    def generate(
        self,
        seed: int | None = None,
        size: float = 1.0,
        variation: float = 1.0,
        color: tuple[float, float, float, float] = (0.12, 0.32, 0.12, 1.0),
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions("bush")
        self._ensure_object_mode()
        self._deselect_all()

        parts = []
        puff_count = 3
        for idx in range(puff_count):
            radius = 0.35 * size * (1.0 + rng.uniform(-0.15, 0.15) * variation)
            offset = (
                rng.uniform(-0.1, 0.1) * size,
                rng.uniform(-0.1, 0.1) * size,
                0.15 * size + idx * 0.05,
            )
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=radius, location=offset)
            part = bpy.context.active_object
            part.scale.z *= 0.7
            part.rotation_euler[2] = rng.uniform(0.0, 0.6)
            part.name = f"bush_part_{idx}"
            parts.append(part)

        mat = self.create_material("Bush", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        noise = self.add_noise(nodes, scale=4.0 + variation, detail=1.0)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.9, color[1] * 1.05, color[2] * 0.9, 1.0)],
            positions=[0.3, 0.85],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])

        for part in parts:
            part.data.materials.append(mat)

        self._ensure_object_mode()
        self._deselect_all()
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()

        bush = bpy.context.active_object
        if damage_level > 0:
            squash = 1.0 - 0.2 * damage_level
            bush.scale.z *= max(0.5, squash)

        bush.name = "bush" if seed is None else f"bush_{seed}"
        self.apply_flat_shading(bush)
        self.center_on_origin(bush)
        self.place_in_collection(bush, "Bushes")
        return bush
