import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class TreeGenerator(BaseModelGenerator, BaseMaterial):
    asset_type = "tree"

    def generate(
        self,
        seed: int | None = None,
        size: float = 1.0,
        variation: float = 1.0,
        color: tuple[float, float, float, float] = (0.07, 0.3, 0.1, 1.0),
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions("tree")
        self._ensure_object_mode()
        self._deselect_all()

        trunk_h = size * (1.0 + rng.uniform(-0.1, 0.1) * variation)
        trunk_r = 0.12 * size * (1.0 + rng.uniform(-0.1, 0.1) * variation)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=trunk_r,
            depth=trunk_h,
            location=(0.0, 0.0, trunk_h * 0.5),
        )
        trunk = bpy.context.active_object
        trunk.name = "tree_trunk"

        canopy_layers = []
        base_radius = 0.7 * size
        layer_count = 3
        for idx in range(layer_count):
            height = (0.8 - 0.1 * idx) * size * (1.0 + rng.uniform(-0.08, 0.08) * variation)
            radius = base_radius * (1 - 0.18 * idx) * (1.0 + rng.uniform(-0.08, 0.08) * variation)
            z_pos = trunk_h * 0.9 + height * 0.5 + idx * 0.05
            bpy.ops.mesh.primitive_cone_add(
                vertices=6,
                radius1=radius,
                radius2=0.02,
                depth=height,
                location=(0.0, 0.0, z_pos),
                rotation=(0.0, 0.0, rng.uniform(0.0, 0.35) * variation),
            )
            cone = bpy.context.active_object
            cone.name = f"tree_canopy_{idx}"
            canopy_layers.append(cone)

        # Materials
        trunk_mat = self.create_material("Tree_Trunk", (0.25, 0.16, 0.09, 1.0))
        foliage_mat = self.create_material("Tree_Foliage", color)
        nodes = foliage_mat.node_tree.nodes
        links = foliage_mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        noise = self.add_noise(nodes, scale=3.0 + variation * 0.5, detail=1.0)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.8, color[1] * 0.9, color[2] * 0.8, 1.0)],
            positions=[0.2, 0.9],
        )
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])

        trunk.data.materials.append(trunk_mat)
        for canopy in canopy_layers:
            canopy.data.materials.append(foliage_mat)

        # Join parts
        self._ensure_object_mode()
        self._deselect_all()
        trunk.select_set(True)
        for part in canopy_layers:
            part.select_set(True)
        bpy.context.view_layer.objects.active = trunk
        bpy.ops.object.join()

        tree = bpy.context.active_object
        if damage_level > 0:
            wobble = 0.05 * damage_level * variation
            tree.scale.x *= 1.0 - rng.uniform(0.0, wobble)
            tree.scale.y *= 1.0 - rng.uniform(0.0, wobble)

        tree.name = "tree" if seed is None else f"tree_{seed}"
        self.apply_flat_shading(tree)
        self.center_on_origin(tree)
        self.place_in_collection(tree, "Trees")
        return tree
