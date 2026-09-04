import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
import random


def _ensure_collection(name: str) -> bpy.types.Collection:
    """Fetch or create the named collection and link it to the scene if needed."""
    collection = bpy.data.collections.get(name)
    if collection is None:
        collection = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(collection)
    return collection


def _assign_to_collection(obj: bpy.types.Object, collection: bpy.types.Collection) -> None:
    """Link object to the target collection and unlink it from others."""
    if collection not in obj.users_collection:
        collection.objects.link(obj)
    for col in list(obj.users_collection):
        if col != collection:
            col.objects.unlink(obj)


def _create_material(name: str, base_a: tuple, base_b: tuple, scale: float) -> bpy.types.Material:
    """Create or refresh a simple Principled BSDF material with subtle noise variation."""
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
    mat.use_nodes = True

    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    noise = nodes.new("ShaderNodeTexNoise")
    ramp = nodes.new("ShaderNodeValToRGB")

    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Specular IOR Level"].default_value = 0.05

    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 1.0

    ramp.color_ramp.elements[0].position = 0.25
    ramp.color_ramp.elements[0].color = (*base_a, 1.0)
    ramp.color_ramp.elements[1].position = 0.85
    ramp.color_ramp.elements[1].color = (*base_b, 1.0)

    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    return mat


def _build_trunk(rng: random.Random) -> bpy.types.Object:
    height = 1.2 + rng.uniform(-0.1, 0.1)
    radius = 0.12 + rng.uniform(-0.02, 0.02)
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=6,
        radius=radius,
        depth=height,
        location=(0.0, 0.0, height * 0.5),
    )
    trunk = bpy.context.active_object
    trunk.name = "tree_trunk"
    bpy.ops.object.shade_flat()
    return trunk


def _build_canopy(rng: random.Random, trunk_height: float) -> list:
    layers = []
    layer_count = 3
    base_radius = 0.65 + rng.uniform(-0.05, 0.05)
    tip_offset = 0.1 + rng.uniform(0.0, 0.05)
    current_z = trunk_height * 0.95

    for idx in range(layer_count):
        height = 0.8 - 0.1 * idx + rng.uniform(-0.05, 0.05)
        radius = base_radius * (1 - 0.15 * idx) + rng.uniform(-0.03, 0.03)
        z_pos = current_z + height * 0.5 + idx * 0.05
        bpy.ops.mesh.primitive_cone_add(
            vertices=6,
            radius1=radius,
            radius2=0.02,
            depth=height,
            location=(0.0, 0.0, z_pos + tip_offset * (layer_count - idx - 1)),
        )
        cone = bpy.context.active_object
        cone.rotation_euler[2] = rng.uniform(0.0, 0.35)
        cone.name = f"tree_canopy_{idx}"
        bpy.ops.object.shade_flat()
        layers.append(cone)
        current_z += height * 0.4

    return layers


def generate_tree(seed: int | None = None) -> bpy.types.Object:
    """Generate a low-poly stylized pine tree and place it in the Trees collection."""
    def _deselect_all():
        for obj in bpy.context.view_layer.objects:
            obj.select_set(False)

    def _ensure_object_mode():
        active = bpy.context.view_layer.objects.active
        if active and active.mode != "OBJECT":
            bpy.ops.object.mode_set(mode="OBJECT")

    rng = random.Random(seed)
    target_collection = _ensure_collection("Trees")
    _ensure_object_mode()
    _deselect_all()

    trunk = _build_trunk(rng)
    canopy_layers = _build_canopy(rng, trunk.dimensions.z)

    trunk_mat = _create_material(
        "Tree_Trunk",
        base_a=(0.22, 0.13, 0.07),
        base_b=(0.28, 0.16, 0.08),
        scale=3.5,
    )
    foliage_mat = _create_material(
        "Tree_Foliage",
        base_a=(0.07, 0.25, 0.09),
        base_b=(0.12, 0.32, 0.12),
        scale=2.5,
    )

    trunk.data.materials.append(trunk_mat)
    for canopy in canopy_layers:
        canopy.data.materials.append(foliage_mat)

    for part in [trunk, *canopy_layers]:
        _assign_to_collection(part, target_collection)

    _ensure_object_mode()
    _deselect_all()
    for part in canopy_layers:
        part.select_set(True)
    trunk.select_set(True)
    bpy.context.view_layer.objects.active = trunk
    bpy.ops.object.join()

    tree_obj = bpy.context.active_object
    tree_obj.name = "tree" if seed is None else f"tree_{seed}"
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    tree_obj.location = (0.0, 0.0, 0.0)
    bpy.ops.object.shade_flat()

    _assign_to_collection(tree_obj, target_collection)
    return tree_obj
