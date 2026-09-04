import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class RuinGenerator(BaseModelGenerator, BaseMaterial):
    asset_type = "ruin"

    def generate(
        self,
        seed: int | None = None,
        size: float = 1.5,
        variation: float = 1.0,
        color: tuple[float, float, float, float] = (0.4, 0.4, 0.42, 1.0),
        damage_level: float = 0.5,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions("ruin")
        self._ensure_object_mode()
        self._deselect_all()

        bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, size * 0.5))
        base = bpy.context.active_object
        base.name = "ruin_block"

        bpy.ops.object.editmode_toggle()
        bpy.ops.mesh.subdivide(number_cuts=1)
        bpy.ops.object.editmode_toggle()

        # Chip away height for damage
        base.scale.z *= max(0.3, 1.0 - 0.5 * damage_level)
        base.scale.x *= 1.2 + rng.uniform(-0.1, 0.1) * variation
        base.scale.y *= 0.6 + rng.uniform(-0.1, 0.1) * variation

        mat = self.create_material("Ruin_Concrete", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        noise = self.add_noise(nodes, scale=4.0 + 2.0 * variation, detail=1.5)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.7, color[1] * 0.7, color[2] * 0.65, 1.0)],
            positions=[0.25, 0.8],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])
        base.data.materials.append(mat)

        base.name = "ruin" if seed is None else f"ruin_{seed}"
        self.apply_flat_shading(base)
        self.center_on_origin(base)
        self.place_in_collection(base, "Ruins")
        return base
