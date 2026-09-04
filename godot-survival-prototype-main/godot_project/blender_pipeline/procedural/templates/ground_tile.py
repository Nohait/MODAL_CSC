import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class GroundTileGenerator(BaseModelGenerator, BaseMaterial):
    asset_type = "ground_tile"

    def generate(
        self,
        seed: int | None = None,
        size: float = 1.0,
        variation: float = 1.0,
        color: tuple[float, float, float, float] = (0.22, 0.2, 0.17, 1.0),
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions("ground_tile")
        self._ensure_object_mode()
        self._deselect_all()

        bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, 0))
        tile = bpy.context.active_object
        tile.name = "ground_tile_raw"

        bpy.ops.object.editmode_toggle()
        bpy.ops.mesh.subdivide(number_cuts=2)
        bpy.ops.object.editmode_toggle()

        tile.scale.z = 1.0
        tile.location.z = 0.0

        if damage_level > 0:
            tile.scale.x *= 1.0 - 0.05 * damage_level
            tile.scale.y *= 1.0 - 0.05 * damage_level

        mat = self.create_material("Ground", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        noise = self.add_noise(nodes, scale=2.5 + variation, detail=0.5)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.9, color[1] * 0.85, color[2] * 0.8, 1.0)],
            positions=[0.3, 0.8],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])

        tile.data.materials.append(mat)
        self.apply_flat_shading(tile)
        self.center_on_origin(tile)
        self.place_in_collection(tile, "Ground")
        tile.name = "ground_tile" if seed is None else f"ground_tile_{seed}"
        return tile
