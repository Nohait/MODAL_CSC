import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

"""Base helpers for procedural materials using Blender shader nodes."""

import bpy


class BaseMaterial:
    """Utility methods for constructing lightweight procedural materials."""

    def create_material(self, name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
        """Create (or reset) a Principled BSDF material with a base color."""
        mat = bpy.data.materials.get(name)
        if mat is None:
            mat = bpy.data.materials.new(name)
        mat.use_nodes = True

        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()

        out = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.85
        bsdf.inputs["Specular IOR Level"].default_value = 0.05

        links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
        return mat

    def add_noise(self, nodes, name: str = "Noise", scale: float = 5.0, detail: float = 2.0):
        noise = nodes.new("ShaderNodeTexNoise")
        noise.label = name
        noise.inputs["Scale"].default_value = scale
        noise.inputs["Detail"].default_value = detail
        return noise

    def add_color_ramp(self, nodes, colors: list[tuple[float, float, float, float]], positions: list[float]):
        ramp = nodes.new("ShaderNodeValToRGB")
        for idx, (col, pos) in enumerate(zip(colors, positions)):
            if idx == 0:
                elem = ramp.color_ramp.elements[0]
            elif idx == 1 and len(ramp.color_ramp.elements) == 1:
                elem = ramp.color_ramp.elements.new(pos)
            else:
                elem = ramp.color_ramp.elements.new(pos)
            elem.position = pos
            elem.color = col
        return ramp

    def add_mix_rgb(self, nodes, blend_type: str = "MIX", fac: float = 0.5):
        mix = nodes.new("ShaderNodeMixRGB")
        mix.blend_type = blend_type
        mix.inputs["Fac"].default_value = fac
        return mix

    def link(self, links, from_socket, to_socket):
        links.new(from_socket, to_socket)
