import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class RockGenerator(BaseModelGenerator, BaseMaterial):
    asset_type = "rock"

    def generate(
        self,
        seed: int | None = None,
        size: float = 1.0,
        variation: float = 1.0,
        color: tuple[float, float, float, float] = (0.35, 0.36, 0.38, 1.0),
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions("rock")
        self._ensure_object_mode()
        self._deselect_all()

        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1,
            radius=0.5 * size * (1.0 + rng.uniform(-0.2, 0.2) * variation),
            location=(0.0, 0.0, 0.0),
        )
        rock = bpy.context.active_object
        rock.name = "rock_raw"

        # Add a couple of random scale tweaks for faceting
        rock.scale.x *= 1.0 + rng.uniform(-0.1, 0.1) * variation
        rock.scale.y *= 1.0 + rng.uniform(-0.1, 0.1) * variation
        rock.scale.z *= 0.6 + rng.uniform(-0.15, 0.1) * variation

        if damage_level > 0.0:
            rock.scale.z *= max(0.4, 1.0 - 0.3 * damage_level)

        mat = self.create_material("Rock", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        noise = self.add_noise(nodes, scale=5.0 + variation * 1.5, detail=1.0)
        ramp = self.add_color_ramp(
            nodes,
            colors=[color, (color[0] * 0.7, color[1] * 0.7, color[2] * 0.7, 1.0)],
            positions=[0.3, 0.8],
        )
        mix = self.add_mix_rgb(nodes, blend_type="MULTIPLY", fac=0.45)
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], mix.inputs["Color2"])
        self.link(links, bsdf.inputs["Base Color"], mix.inputs["Color1"])
        self.link(links, mix.outputs["Color"], bsdf.inputs["Base Color"])

        rock.data.materials.append(mat)

        self.apply_flat_shading(rock)
        self.center_on_origin(rock)
        self.place_in_collection(rock, "Rocks")
        rock.name = "rock" if seed is None else f"rock_{seed}"
        return rock
