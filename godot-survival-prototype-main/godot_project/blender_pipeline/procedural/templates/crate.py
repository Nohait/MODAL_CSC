import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class CrateGenerator(BaseModelGenerator, BaseMaterial):
    asset_type = "crate"

    def generate(
        self,
        seed: int | None = None,
        size: float = 1.0,
        variation: float = 1.0,
        color: tuple[float, float, float, float] = (0.35, 0.22, 0.12, 1.0),
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions("crate")
        self._ensure_object_mode()
        self._deselect_all()

        bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, size * 0.5))
        crate = bpy.context.active_object
        crate.name = "crate_raw"

        bpy.ops.object.editmode_toggle()
        bpy.ops.mesh.bevel(offset=0.04 * size * (1.0 + variation * 0.1), segments=1, profile=0.8, affect='EDGES')
        bpy.ops.object.editmode_toggle()

        mat = self.create_material("Crate_Wood", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        noise = self.add_noise(nodes, scale=8.0, detail=1.0)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.8, color[1] * 0.75, color[2] * 0.7, 1.0)],
            positions=[0.25, 0.85],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])
        crate.data.materials.append(mat)

        if damage_level > 0:
            tilt = rng.uniform(-0.05, 0.05) * damage_level
            crate.rotation_euler[0] += tilt
            crate.rotation_euler[1] += tilt
            crate.scale.z *= max(0.6, 1.0 - 0.2 * damage_level)

        crate.name = "crate" if seed is None else f"crate_{seed}"
        self.apply_flat_shading(crate)
        self.center_on_origin(crate)
        self.place_in_collection(crate, "Crates")
        return crate
