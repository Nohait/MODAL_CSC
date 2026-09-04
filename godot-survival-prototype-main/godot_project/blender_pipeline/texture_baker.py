"""blender_pipeline/texture_baker.py

Texture baking helpers for generated assets.

Goal: bridge the quality gap by exporting assets with baked textures
(albedo + AO + roughness + optional metallic) instead of flat per-material
colors.

Adds optional dirt/blood overlays (wear masks) and packs ORM textures for
engines that prefer it.

Works in headless Blender.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Iterable, Literal

import bpy


def _ensure_cycles(samples: int = 64) -> None:
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    # Baking is faster/cleaner if we avoid extra stuff
    scene.cycles.use_denoising = True
    scene.render.bake.use_cage = False
    scene.render.bake.margin = 2


def _ensure_uv(obj: bpy.types.Object) -> None:
    if obj.type != "MESH":
        return

    mesh = obj.data
    if mesh.uv_layers and len(mesh.uv_layers) > 0:
        return

    # Smart UV Project is robust for procedural meshes
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    if obj.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")

    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(
        angle_limit=66.0,
        island_margin=0.03,
        area_weight=0.0,
        correct_aspect=True,
        scale_to_bounds=True,
    )
    bpy.ops.object.mode_set(mode="OBJECT")


def _create_image(name: str, width: int, height: int, out_path: Path) -> bpy.types.Image:
    img = bpy.data.images.new(name=name, width=width, height=height, alpha=False)
    img.filepath_raw = str(out_path)
    img.file_format = "PNG"
    return img


def _add_bake_node_to_material(mat: bpy.types.Material, image: bpy.types.Image) -> bpy.types.Node:
    if not mat.use_nodes:
        mat.use_nodes = True

    nodes = mat.node_tree.nodes
    img_node = nodes.new("ShaderNodeTexImage")
    img_node.image = image
    nodes.active = img_node
    return img_node


def _bake(obj: bpy.types.Object, bake_type: str) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    if obj.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")

    bpy.ops.object.bake(type=bake_type)


WEAR_PROFILE = Literal["generic", "survivor", "zombie", "prop", "environment"]

WEAR_TINTS: dict[WEAR_PROFILE, tuple[float, float, float, float]] = {
    "generic": (0.42, 0.37, 0.30, 1.0),
    "survivor": (0.38, 0.34, 0.28, 1.0),
    "zombie": (0.32, 0.20, 0.18, 1.0),
    "prop": (0.40, 0.33, 0.26, 1.0),
    "environment": (0.36, 0.38, 0.32, 1.0),
}

BLOOD_TINT = (0.45, 0.05, 0.05, 1.0)


def _build_wear_mask_material() -> bpy.types.Material:
    """Create a temporary material that bakes a wear mask using pointiness + noise + AO."""
    mat = bpy.data.materials.new(name="__temp_wear_mask")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)

    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (320, 0)
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.0

    geom = nodes.new("ShaderNodeNewGeometry")
    geom.location = (-600, 120)

    ao = nodes.new("ShaderNodeAmbientOcclusion")
    ao.location = (-600, -100)
    ao.samples = 8

    noise = nodes.new("ShaderNodeTexNoise")
    noise.location = (-600, -340)
    noise.inputs["Scale"].default_value = 8.0
    noise.inputs["Detail"].default_value = 2.0

    ramp_edge = nodes.new("ShaderNodeValToRGB")
    ramp_edge.location = (-400, 100)
    ramp_edge.color_ramp.elements[0].position = 0.35
    ramp_edge.color_ramp.elements[1].position = 0.85

    ramp_noise = nodes.new("ShaderNodeValToRGB")
    ramp_noise.location = (-400, -240)
    ramp_noise.color_ramp.elements[0].position = 0.35
    ramp_noise.color_ramp.elements[1].position = 0.75

    mix_edge_noise = nodes.new("ShaderNodeMixRGB")
    mix_edge_noise.location = (-120, -40)
    mix_edge_noise.blend_type = "MULTIPLY"
    mix_edge_noise.inputs["Fac"].default_value = 1.0

    mix_with_ao = nodes.new("ShaderNodeMixRGB")
    mix_with_ao.location = (80, 40)
    mix_with_ao.blend_type = "MULTIPLY"
    mix_with_ao.inputs["Fac"].default_value = 1.0

    links.new(geom.outputs["Pointiness"], ramp_edge.inputs[0])
    links.new(noise.outputs["Fac"], ramp_noise.inputs[0])
    links.new(ramp_edge.outputs[0], mix_edge_noise.inputs[1])
    links.new(ramp_noise.outputs[0], mix_edge_noise.inputs[2])
    links.new(mix_edge_noise.outputs[0], mix_with_ao.inputs[1])
    links.new(ao.outputs["Color"], mix_with_ao.inputs[2])
    links.new(mix_with_ao.outputs[0], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    return mat


def _pack_orm(
    ao_img: bpy.types.Image | None,
    rough_img: bpy.types.Image | None,
    metallic_img: bpy.types.Image | None,
    orm_path: Path,
) -> Path | None:
    if not (ao_img and rough_img and metallic_img):
        return None

    width, height = ao_img.size
    orm_img = bpy.data.images.new(name=f"{orm_path.stem}", width=width, height=height, alpha=False)
    orm_img.filepath_raw = str(orm_path)
    orm_img.file_format = "PNG"

    ao_px = list(ao_img.pixels[:])
    rough_px = list(rough_img.pixels[:])
    metal_px = list(metallic_img.pixels[:])

    total = width * height * 4
    packed = [0.0] * total
    for i in range(0, total, 4):
        packed[i] = ao_px[i]      # R = AO
        packed[i + 1] = rough_px[i]  # G = Roughness
        packed[i + 2] = metal_px[i]  # B = Metallic
        packed[i + 3] = 1.0

    orm_img.pixels = packed
    orm_img.save()
    return orm_path


def _build_baked_material(
    name: str,
    albedo_img: bpy.types.Image,
    ao_img: bpy.types.Image,
    rough_img: bpy.types.Image | None,
    metallic_img: bpy.types.Image | None,
    wear_mask_img: bpy.types.Image | None,
    wear_profile: WEAR_PROFILE,
    wear_strength: float,
    blood_strength: float,
) -> bpy.types.Material:
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True

    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (900, 0)

    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (520, 0)
    bsdf.inputs["Roughness"].default_value = 0.75
    bsdf.inputs["Specular IOR Level"].default_value = 0.25

    tex_albedo = nodes.new("ShaderNodeTexImage")
    tex_albedo.location = (-520, 140)
    tex_albedo.image = albedo_img

    tex_ao = nodes.new("ShaderNodeTexImage")
    tex_ao.location = (-520, -80)
    tex_ao.image = ao_img
    tex_ao.interpolation = "Linear"

    mix_ao = nodes.new("ShaderNodeMixRGB")
    mix_ao.location = (240, 80)
    mix_ao.blend_type = "MULTIPLY"
    mix_ao.inputs["Fac"].default_value = 1.0

    last_color_output = tex_albedo.outputs["Color"]

    if wear_mask_img:
        tex_wear = nodes.new("ShaderNodeTexImage")
        tex_wear.location = (-520, -320)
        tex_wear.image = wear_mask_img
        tex_wear.interpolation = "Linear"

        separate = nodes.new("ShaderNodeSeparateRGB")
        separate.location = (-320, -120)

        wear_factor = nodes.new("ShaderNodeMath")
        wear_factor.location = (-140, -80)
        wear_factor.operation = "MULTIPLY"
        wear_factor.inputs[1].default_value = wear_strength

        wear_tint = nodes.new("ShaderNodeRGB")
        wear_tint.location = (-320, 40)
        wear_tint.outputs[0].default_value = WEAR_TINTS[wear_profile]

        wear_mix = nodes.new("ShaderNodeMixRGB")
        wear_mix.location = (40, 40)
        wear_mix.blend_type = "MULTIPLY"

        links.new(tex_wear.outputs["Color"], separate.inputs[0])
        links.new(separate.outputs[0], wear_factor.inputs[0])
        links.new(last_color_output, wear_mix.inputs[1])
        links.new(wear_tint.outputs[0], wear_mix.inputs[2])
        links.new(wear_factor.outputs[0], wear_mix.inputs[0])

        last_color_output = wear_mix.outputs[0]

        if wear_profile == "zombie" and blood_strength > 0:
            blood_factor = nodes.new("ShaderNodeMath")
            blood_factor.location = (220, -120)
            blood_factor.operation = "MULTIPLY"
            blood_factor.inputs[1].default_value = blood_strength

            blood_tint = nodes.new("ShaderNodeRGB")
            blood_tint.location = (40, -220)
            blood_tint.outputs[0].default_value = BLOOD_TINT

            blood_mix = nodes.new("ShaderNodeMixRGB")
            blood_mix.location = (420, -60)
            blood_mix.blend_type = "MULTIPLY"

            links.new(wear_factor.outputs[0], blood_factor.inputs[0])
            links.new(last_color_output, blood_mix.inputs[1])
            links.new(blood_tint.outputs[0], blood_mix.inputs[2])
            links.new(blood_factor.outputs[0], blood_mix.inputs[0])

            last_color_output = blood_mix.outputs[0]

    links.new(last_color_output, mix_ao.inputs[1])
    links.new(tex_ao.outputs["Color"], mix_ao.inputs[2])
    links.new(mix_ao.outputs["Color"], bsdf.inputs["Base Color"])

    if rough_img:
        tex_rough = nodes.new("ShaderNodeTexImage")
        tex_rough.location = (200, -260)
        tex_rough.image = rough_img
        if tex_rough.image:
            tex_rough.image.colorspace_settings.name = "Non-Color"
        links.new(tex_rough.outputs["Color"], bsdf.inputs["Roughness"])

    if metallic_img:
        tex_metal = nodes.new("ShaderNodeTexImage")
        tex_metal.location = (20, -420)
        tex_metal.image = metallic_img
        if tex_metal.image:
            tex_metal.image.colorspace_settings.name = "Non-Color"
        links.new(tex_metal.outputs["Color"], bsdf.inputs["Metallic"])

    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    return mat


def bake_albedo_ao_and_assign(
    obj: bpy.types.Object,
    texture_dir: str | os.PathLike,
    name_prefix: str | None = None,
    resolution: int = 512,
    samples: int = 64,
    bake_roughness: bool = True,
    bake_metallic: bool = False,
    pack_orm: bool = True,
    wear_profile: WEAR_PROFILE = "generic",
    wear_strength: float = 0.35,
    blood_strength: float = 0.25,
) -> dict[str, Path | None]:
    """UV unwrap obj if needed, bake maps, build a baked PBR material and assign it.

    Returns a dict of saved texture paths.
    """

    if obj.type != "MESH":
        raise ValueError("bake_albedo_ao_and_assign expects a mesh object")

    _ensure_cycles(samples=samples)
    _ensure_uv(obj)

    out_dir = Path(texture_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    prefix = name_prefix or obj.name
    albedo_path = out_dir / f"{prefix}_albedo.png"
    ao_path = out_dir / f"{prefix}_ao.png"
    rough_path = out_dir / f"{prefix}_roughness.png"
    metal_path = out_dir / f"{prefix}_metallic.png"
    wear_mask_path = out_dir / f"{prefix}_wear_mask.png"
    orm_path = out_dir / f"{prefix}_orm.png"

    albedo_img = _create_image(f"{prefix}_albedo", resolution, resolution, albedo_path)
    ao_img = _create_image(f"{prefix}_ao", resolution, resolution, ao_path)
    rough_img = _create_image(f"{prefix}_roughness", resolution, resolution, rough_path) if bake_roughness else None
    metal_img = _create_image(f"{prefix}_metallic", resolution, resolution, metal_path) if bake_metallic else None
    wear_img = _create_image(f"{prefix}_wear", resolution, resolution, wear_mask_path)

    original_materials = [m for m in obj.data.materials]

    # Wear mask bake using temporary material
    wear_mat = _build_wear_mask_material()
    obj.data.materials.clear()
    obj.data.materials.append(wear_mat)

    temp_wear_nodes = [_add_bake_node_to_material(wear_mat, wear_img)]
    bake_settings = bpy.context.scene.render.bake
    bake_settings.use_pass_direct = False
    bake_settings.use_pass_indirect = False
    bake_settings.use_pass_color = True
    _bake(obj, "DIFFUSE")
    wear_img.save()

    obj.data.materials.clear()
    for m in original_materials:
        if m:
            obj.data.materials.append(m)
    try:
        bpy.data.materials.remove(wear_mat)
    except Exception:
        pass

    mats: list[bpy.types.Material] = [m for m in obj.data.materials if m is not None]
    if not mats:
        fallback = bpy.data.materials.new(name=f"{prefix}_mat")
        fallback.use_nodes = True
        obj.data.materials.append(fallback)
        mats = [fallback]

    temp_nodes: list[bpy.types.Node] = []
    for mat in mats:
        temp_nodes.append(_add_bake_node_to_material(mat, albedo_img))

    bake_settings = bpy.context.scene.render.bake
    bake_settings.use_pass_direct = False
    bake_settings.use_pass_indirect = False
    bake_settings.use_pass_color = True
    _bake(obj, "DIFFUSE")

    for mat, node in zip(mats, temp_nodes):
        try:
            node.image = ao_img
            if mat.node_tree:
                mat.node_tree.nodes.active = node
        except Exception:
            pass
    _bake(obj, "AO")

    if bake_roughness and rough_img:
        for mat, node in zip(mats, temp_nodes):
            try:
                node.image = rough_img
                if mat.node_tree:
                    mat.node_tree.nodes.active = node
            except Exception:
                pass
        _bake(obj, "ROUGHNESS")

    if bake_metallic and metal_img:
        # Blender 4.0 bake API has no METALLIC pass; reuse EMIT by routing metallic to emission
        # Build temporary emission override
        for mat in mats:
            if not (mat and mat.use_nodes and mat.node_tree):
                continue
            nodes = mat.node_tree.nodes
            links = mat.node_tree.links
            principled = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
            if not principled:
                continue
            emit_node = nodes.new("ShaderNodeEmission")
            emit_node.location = (principled.location.x - 200, principled.location.y - 200)
            links.new(principled.outputs.get("Metallic"), emit_node.inputs["Color"])
            out_node = next((n for n in nodes if n.type == "OUTPUT_MATERIAL"), None)
            if out_node:
                links.new(emit_node.outputs[0], out_node.inputs["Surface"])
        for mat, node in zip(mats, temp_nodes):
            try:
                node.image = metal_img
                if mat.node_tree:
                    mat.node_tree.nodes.active = node
            except Exception:
                pass
        _bake(obj, "EMIT")

    albedo_img.save()
    ao_img.save()
    if bake_roughness and rough_img:
        rough_img.save()
    if bake_metallic and metal_img:
        metal_img.save()

    orm_saved = None
    if pack_orm and bake_roughness and bake_metallic:
        orm_saved = _pack_orm(ao_img, rough_img, metal_img, orm_path)

    baked_mat = _build_baked_material(
        f"{prefix}_baked",
        albedo_img,
        ao_img,
        rough_img if bake_roughness else None,
        metal_img if bake_metallic else None,
        wear_img,
        wear_profile,
        wear_strength,
        blood_strength,
    )
    obj.data.materials.clear()
    obj.data.materials.append(baked_mat)

    return {
        "albedo": albedo_path,
        "ao": ao_path,
        "roughness": rough_path if bake_roughness else None,
        "metallic": metal_path if bake_metallic else None,
        "wear_mask": wear_mask_path,
        "orm": orm_saved,
    }
