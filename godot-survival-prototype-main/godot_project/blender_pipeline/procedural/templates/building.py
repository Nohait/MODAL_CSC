import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class BuildingGenerator(BaseModelGenerator, BaseMaterial):
    asset_type = "building"

    def generate(
        self,
        seed: int | None = None,
        size: float = 2.0,
        variation: float = 1.0,
        color: tuple[float, float, float, float] = (0.35, 0.35, 0.38, 1.0),
        damage_level: float = 0.2,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions("building")
        self._ensure_object_mode()
        self._deselect_all()

        bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, size * 0.5))
        shell = bpy.context.active_object
        shell.scale.x *= 1.6
        shell.scale.y *= 1.2
        shell.scale.z *= 1.5
        shell.name = "building_shell"

        # Simple roof slab
        bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, shell.location.z + shell.dimensions.z * 0.5))
        roof = bpy.context.active_object
        roof.scale.x = shell.scale.x
        roof.scale.y = shell.scale.y
        roof.scale.z = 0.1 * size
        roof.name = "building_roof"

        parts = [shell, roof]

        base_mat = self.create_material("Building_Wall", color)
        nodes = base_mat.node_tree.nodes
        links = base_mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        noise = self.add_noise(nodes, scale=3.0 + variation, detail=1.0)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.8, color[1] * 0.8, color[2] * 0.78, 1.0)],
            positions=[0.3, 0.85],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])

        roof_mat = self.create_material("Building_Roof", (color[0] * 0.6, color[1] * 0.6, color[2] * 0.6, 1.0))

        shell.data.materials.append(base_mat)
        roof.data.materials.append(roof_mat)

        self._ensure_object_mode()
        self._deselect_all()
        for p in parts:
            p.select_set(True)
        bpy.context.view_layer.objects.active = shell
        bpy.ops.object.join()

        building = bpy.context.active_object
        if damage_level > 0:
            building.scale.z *= 1.0 - 0.1 * damage_level
            building.rotation_euler[2] = rng.uniform(-0.1, 0.1) * variation * damage_level

        building.name = "building" if seed is None else f"building_{seed}"
        self.apply_flat_shading(building)
        self.center_on_origin(building)
        self.place_in_collection(building, "Buildings")
        return building
