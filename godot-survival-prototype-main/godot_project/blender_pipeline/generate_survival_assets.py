"""
Godot Survival Prototype - Complete 3D Asset Generator
Generates high-quality, detailed low-poly 3D models similar to LDOE but better.
All assets are procedurally generated with proper materials and export-ready.
"""

import bpy
import bmesh
import random
import math
import os
from pathlib import Path
from mathutils import Vector, Euler

# Configuration
random.seed(42)  # Reproducible generation
EXPORT_PATH = Path(__file__).parent.parent / "assets" / "models"
TEXTURE_PATH = Path(__file__).parent.parent / "assets" / "art"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def get_or_create_collection(name, parent=None):
    """Get existing or create new collection."""
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        if parent is not None:
            parent.children.link(col)
        else:
            bpy.context.scene.collection.children.link(col)
    return col


def clear_collection(col):
    """Remove all objects from a collection."""
    for obj in list(col.objects):
        for child_col in obj.users_collection:
            child_col.objects.unlink(obj)
        bpy.data.objects.remove(obj, do_unlink=True)


def clear_scene():
    """Clear entire scene for fresh generation."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    # Clear orphan data
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)


def apply_transform(obj):
    """Apply all transforms to object."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.select_set(False)


def set_origin_to_bottom(obj):
    """Set origin to bottom center of object."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    # Move origin to bottom
    bounds = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    min_z = min(v.z for v in bounds)
    obj.location.z -= min_z
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    obj.select_set(False)


def apply_smooth_shading(obj, angle=30):
    """Apply smooth shading with auto-smooth."""
    mesh = obj.data
    mesh.use_auto_smooth = True
    mesh.auto_smooth_angle = math.radians(angle)
    for p in mesh.polygons:
        p.use_smooth = True


def apply_flat_shading(obj):
    """Apply flat low-poly shading."""
    mesh = obj.data
    for p in mesh.polygons:
        p.use_smooth = False


# ============================================================================
# PBR MATERIAL SYSTEM
# ============================================================================

def create_pbr_material(name, base_color, roughness=0.7, metallic=0.0, 
                        emission=0.0, emission_color=None, subsurface=0.0):
    """Create a PBR material with advanced settings."""
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
        
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    
    # Clear defaults
    nodes.clear()
    
    # Create nodes
    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (400, 0)
    
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (0, 0)
    
    # Set values
    bsdf.inputs["Base Color"].default_value = (*base_color[:3], 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    
    if subsurface > 0:
        bsdf.inputs["Subsurface Weight"].default_value = subsurface
    
    if emission > 0 and emission_color:
        bsdf.inputs["Emission Color"].default_value = (*emission_color[:3], 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
    
    links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    
    return mat


def create_procedural_material(name, base_color, secondary_color=None,
                                roughness=0.7, metallic=0.0, noise_scale=5.0,
                                variation=0.2):
    """Create procedural material with noise-based color variation."""
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
        
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    
    nodes.clear()
    
    # Nodes
    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (600, 0)
    
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    
    if secondary_color:
        # Color mixing with noise
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-300, 0)
        noise.inputs["Scale"].default_value = noise_scale
        noise.inputs["Detail"].default_value = 4.0
        
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (-100, 0)
        ramp.color_ramp.elements[0].color = (*base_color[:3], 1.0)
        ramp.color_ramp.elements[1].color = (*secondary_color[:3], 1.0)
        ramp.color_ramp.elements[0].position = 0.5 - variation
        ramp.color_ramp.elements[1].position = 0.5 + variation
        
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = (*base_color[:3], 1.0)
    
    links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    
    return mat


# ============================================================================
# ENVIRONMENT ASSETS
# ============================================================================

def create_detailed_tree(name, tree_type="oak", size=1.0, seed=None):
    """Create a detailed low-poly tree with proper geometry."""
    if seed:
        random.seed(seed)
    
    parts = []
    
    # Trunk with taper
    trunk_segments = 6
    trunk_height = 1.5 * size
    trunk_radius_base = 0.15 * size
    trunk_radius_top = 0.08 * size
    
    bpy.ops.mesh.primitive_cone_add(
        vertices=8,
        radius1=trunk_radius_base,
        radius2=trunk_radius_top,
        depth=trunk_height,
        location=(0, 0, trunk_height / 2)
    )
    trunk = bpy.context.active_object
    trunk.name = f"{name}_trunk"
    
    # Add trunk detail - slight bend
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.subdivide(number_cuts=2)
    bpy.ops.object.mode_set(mode='OBJECT')
    
    for v in trunk.data.vertices:
        if v.co.z > trunk_height * 0.3:
            offset = (v.co.z / trunk_height) ** 2
            v.co.x += random.uniform(-0.05, 0.05) * size * offset
            v.co.y += random.uniform(-0.05, 0.05) * size * offset
    
    trunk_mat = create_procedural_material(
        f"mat_{name}_trunk",
        base_color=(0.25, 0.18, 0.12),
        secondary_color=(0.18, 0.12, 0.08),
        roughness=0.9,
        noise_scale=8.0
    )
    trunk.data.materials.append(trunk_mat)
    parts.append(trunk)
    
    # Foliage layers based on tree type
    if tree_type == "oak":
        foliage_layers = [
            {"height": 1.8, "radius": 0.9, "verts": 8},
            {"height": 2.3, "radius": 0.7, "verts": 8},
            {"height": 2.7, "radius": 0.5, "verts": 6},
        ]
        leaf_color = (0.15, 0.35, 0.12)
        leaf_color2 = (0.12, 0.28, 0.10)
    elif tree_type == "pine":
        foliage_layers = [
            {"height": 1.2, "radius": 0.8, "verts": 6},
            {"height": 1.8, "radius": 0.6, "verts": 6},
            {"height": 2.4, "radius": 0.4, "verts": 6},
            {"height": 2.9, "radius": 0.2, "verts": 6},
        ]
        leaf_color = (0.08, 0.25, 0.10)
        leaf_color2 = (0.06, 0.20, 0.08)
    elif tree_type == "dead":
        # No foliage, just branches
        foliage_layers = []
        # Add branches instead
        for i in range(4):
            angle = i * math.pi / 2 + random.uniform(-0.3, 0.3)
            branch_len = random.uniform(0.3, 0.6) * size
            height = random.uniform(0.8, 1.3) * size
            
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=4,
                radius=0.03 * size,
                depth=branch_len,
                location=(
                    math.cos(angle) * branch_len / 2,
                    math.sin(angle) * branch_len / 2,
                    height
                )
            )
            branch = bpy.context.active_object
            branch.rotation_euler = (
                0,
                math.radians(60 + random.uniform(-20, 20)),
                angle
            )
            branch.data.materials.append(trunk_mat)
            parts.append(branch)
        leaf_color = None
        leaf_color2 = None
    else:  # birch or default
        foliage_layers = [
            {"height": 1.6, "radius": 0.6, "verts": 8},
            {"height": 2.1, "radius": 0.5, "verts": 8},
        ]
        leaf_color = (0.20, 0.40, 0.15)
        leaf_color2 = (0.25, 0.45, 0.18)
    
    # Create foliage
    if foliage_layers:
        foliage_mat = create_procedural_material(
            f"mat_{name}_foliage",
            base_color=leaf_color,
            secondary_color=leaf_color2,
            roughness=0.8,
            noise_scale=6.0,
            variation=0.3
        )
        
        for layer in foliage_layers:
            h = layer["height"] * size
            r = layer["radius"] * size * random.uniform(0.9, 1.1)
            
            bpy.ops.mesh.primitive_ico_sphere_add(
                subdivisions=1,
                radius=r,
                location=(
                    random.uniform(-0.1, 0.1) * size,
                    random.uniform(-0.1, 0.1) * size,
                    h
                )
            )
            foliage = bpy.context.active_object
            foliage.scale.z = random.uniform(0.6, 0.8)
            
            # Randomize vertices for organic look
            for v in foliage.data.vertices:
                v.co.x += random.uniform(-0.1, 0.1) * r
                v.co.y += random.uniform(-0.1, 0.1) * r
                v.co.z += random.uniform(-0.1, 0.1) * r
            
            foliage.data.materials.append(foliage_mat)
            parts.append(foliage)
    
    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = trunk
    bpy.ops.object.join()
    
    tree = bpy.context.active_object
    tree.name = name
    apply_flat_shading(tree)
    
    return tree


def create_detailed_rock(name, rock_type="boulder", size=1.0, seed=None):
    """Create detailed rock with erosion-like features."""
    if seed:
        random.seed(seed)
    
    if rock_type == "boulder":
        subdivisions = 2
        base_radius = 0.5 * size
    elif rock_type == "small":
        subdivisions = 1
        base_radius = 0.2 * size
    elif rock_type == "slab":
        subdivisions = 1
        base_radius = 0.6 * size
    else:
        subdivisions = 1
        base_radius = 0.4 * size
    
    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=subdivisions,
        radius=base_radius,
        location=(0, 0, base_radius * 0.7)
    )
    rock = bpy.context.active_object
    
    # Deform for natural look
    if rock_type == "slab":
        rock.scale = (
            random.uniform(1.2, 1.8),
            random.uniform(1.0, 1.4),
            random.uniform(0.3, 0.5)
        )
    else:
        rock.scale = (
            random.uniform(0.7, 1.3),
            random.uniform(0.7, 1.3),
            random.uniform(0.5, 0.9)
        )
    
    apply_transform(rock)
    
    # Vertex displacement for erosion
    for v in rock.data.vertices:
        noise_val = (
            math.sin(v.co.x * 5) * math.cos(v.co.y * 5) * 
            math.sin(v.co.z * 3)
        ) * 0.1 * size
        v.co.x += noise_val + random.uniform(-0.05, 0.05) * size
        v.co.y += noise_val + random.uniform(-0.05, 0.05) * size
        v.co.z += random.uniform(-0.03, 0.03) * size
    
    # Material
    rock_mat = create_procedural_material(
        f"mat_{name}",
        base_color=(0.35, 0.33, 0.30),
        secondary_color=(0.25, 0.24, 0.22),
        roughness=0.85,
        noise_scale=10.0
    )
    rock.data.materials.append(rock_mat)
    
    rock.name = name
    apply_flat_shading(rock)
    
    return rock


def create_bush(name, bush_type="normal", size=1.0, seed=None):
    """Create detailed bush with multiple foliage clusters."""
    if seed:
        random.seed(seed)
    
    parts = []
    
    if bush_type == "berry":
        base_color = (0.15, 0.35, 0.12)
        accent_color = (0.6, 0.1, 0.1)
        clusters = 4
    elif bush_type == "dead":
        base_color = (0.35, 0.28, 0.18)
        accent_color = (0.30, 0.25, 0.15)
        clusters = 3
    else:
        base_color = (0.18, 0.38, 0.15)
        accent_color = (0.15, 0.32, 0.12)
        clusters = 5
    
    bush_mat = create_procedural_material(
        f"mat_{name}",
        base_color=base_color,
        secondary_color=accent_color,
        roughness=0.8,
        noise_scale=8.0
    )
    
    for i in range(clusters):
        angle = i * (2 * math.pi / clusters) + random.uniform(-0.3, 0.3)
        dist = random.uniform(0.1, 0.25) * size
        height = random.uniform(0.2, 0.4) * size
        
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1,
            radius=random.uniform(0.2, 0.35) * size,
            location=(
                math.cos(angle) * dist,
                math.sin(angle) * dist,
                height
            )
        )
        cluster = bpy.context.active_object
        cluster.scale = (
            random.uniform(0.8, 1.2),
            random.uniform(0.8, 1.2),
            random.uniform(0.6, 0.9)
        )
        
        # Randomize vertices
        for v in cluster.data.vertices:
            v.co.x += random.uniform(-0.05, 0.05) * size
            v.co.y += random.uniform(-0.05, 0.05) * size
            v.co.z += random.uniform(-0.03, 0.03) * size
        
        cluster.data.materials.append(bush_mat)
        parts.append(cluster)
    
    # Join all
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    bush = bpy.context.active_object
    bush.name = name
    apply_flat_shading(bush)
    
    return bush


def create_grass_patch(name, size=1.0, density=20, seed=None):
    """Create a patch of grass blades."""
    if seed:
        random.seed(seed)
    
    parts = []
    grass_mat = create_pbr_material(
        f"mat_{name}",
        base_color=(0.18, 0.38, 0.12),
        roughness=0.7
    )
    
    for i in range(density):
        angle = random.uniform(0, 2 * math.pi)
        dist = random.uniform(0, 0.4) * size
        
        # Create single grass blade
        blade_height = random.uniform(0.15, 0.35) * size
        
        bpy.ops.mesh.primitive_plane_add(
            size=0.02 * size,
            location=(
                math.cos(angle) * dist,
                math.sin(angle) * dist,
                blade_height / 2
            )
        )
        blade = bpy.context.active_object
        blade.scale.z = blade_height / 0.02
        blade.rotation_euler.z = random.uniform(0, 2 * math.pi)
        blade.rotation_euler.x = random.uniform(-0.2, 0.2)
        
        blade.data.materials.append(grass_mat)
        parts.append(blade)
    
    # Join all
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    grass = bpy.context.active_object
    grass.name = name
    
    return grass


# ============================================================================
# PROPS & STRUCTURES
# ============================================================================

def create_crate(name, crate_type="wooden", size=1.0, seed=None):
    """Create detailed crate with planks and metal bands."""
    if seed:
        random.seed(seed)
    
    parts = []
    
    if crate_type == "wooden":
        wood_color = (0.35, 0.25, 0.15)
        metal_color = (0.25, 0.25, 0.28)
    elif crate_type == "military":
        wood_color = (0.20, 0.25, 0.18)
        metal_color = (0.15, 0.18, 0.15)
    else:
        wood_color = (0.40, 0.30, 0.20)
        metal_color = (0.30, 0.28, 0.25)
    
    wood_mat = create_procedural_material(
        f"mat_{name}_wood",
        base_color=wood_color,
        secondary_color=(wood_color[0] * 0.7, wood_color[1] * 0.7, wood_color[2] * 0.7),
        roughness=0.8,
        noise_scale=6.0
    )
    
    metal_mat = create_pbr_material(
        f"mat_{name}_metal",
        base_color=metal_color,
        roughness=0.5,
        metallic=0.7
    )
    
    # Main box
    bpy.ops.mesh.primitive_cube_add(size=0.8 * size, location=(0, 0, 0.4 * size))
    box = bpy.context.active_object
    box.data.materials.append(wood_mat)
    parts.append(box)
    
    # Metal bands
    for z in [0.15, 0.65]:
        bpy.ops.mesh.primitive_cube_add(
            size=0.85 * size,
            location=(0, 0, z * size)
        )
        band = bpy.context.active_object
        band.scale.z = 0.08
        band.data.materials.append(metal_mat)
        parts.append(band)
    
    # Corner reinforcements
    corners = [
        (0.35, 0.35), (0.35, -0.35),
        (-0.35, 0.35), (-0.35, -0.35)
    ]
    for cx, cy in corners:
        bpy.ops.mesh.primitive_cube_add(
            size=0.08 * size,
            location=(cx * size, cy * size, 0.4 * size)
        )
        corner = bpy.context.active_object
        corner.scale.z = 5.0
        corner.data.materials.append(metal_mat)
        parts.append(corner)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    crate = bpy.context.active_object
    crate.name = name
    apply_flat_shading(crate)
    
    return crate


def create_barrel(name, barrel_type="metal", size=1.0, seed=None):
    """Create detailed barrel with bands and damage."""
    if seed:
        random.seed(seed)
    
    if barrel_type == "metal":
        body_color = (0.25, 0.28, 0.32)
        band_color = (0.20, 0.20, 0.22)
        metallic = 0.6
    elif barrel_type == "rusty":
        body_color = (0.45, 0.28, 0.15)
        band_color = (0.35, 0.20, 0.12)
        metallic = 0.3
    elif barrel_type == "toxic":
        body_color = (0.15, 0.35, 0.12)
        band_color = (0.12, 0.28, 0.10)
        metallic = 0.4
    else:
        body_color = (0.30, 0.30, 0.35)
        band_color = (0.25, 0.25, 0.28)
        metallic = 0.5
    
    body_mat = create_pbr_material(
        f"mat_{name}_body",
        base_color=body_color,
        roughness=0.6,
        metallic=metallic
    )
    
    band_mat = create_pbr_material(
        f"mat_{name}_band",
        base_color=band_color,
        roughness=0.5,
        metallic=metallic + 0.2
    )
    
    parts = []
    
    # Main cylinder
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=12,
        radius=0.3 * size,
        depth=0.9 * size,
        location=(0, 0, 0.45 * size)
    )
    body = bpy.context.active_object
    
    # Add slight bulge
    for v in body.data.vertices:
        height_factor = 1 - abs(v.co.z - 0.45 * size) / (0.45 * size)
        bulge = 1 + height_factor * 0.05
        v.co.x *= bulge
        v.co.y *= bulge
    
    body.data.materials.append(body_mat)
    parts.append(body)
    
    # Bands
    for z in [0.1, 0.45, 0.8]:
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.32 * size,
            minor_radius=0.015 * size,
            major_segments=12,
            minor_segments=6,
            location=(0, 0, z * size)
        )
        band = bpy.context.active_object
        band.data.materials.append(band_mat)
        parts.append(band)
    
    # Top lid
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=12,
        radius=0.28 * size,
        depth=0.02 * size,
        location=(0, 0, 0.91 * size)
    )
    lid = bpy.context.active_object
    lid.data.materials.append(band_mat)
    parts.append(lid)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    barrel = bpy.context.active_object
    barrel.name = name
    apply_flat_shading(barrel)
    
    return barrel


def create_campfire(name, lit=True, size=1.0):
    """Create campfire with logs and optional flames."""
    parts = []
    
    # Stone ring
    stone_mat = create_procedural_material(
        f"mat_{name}_stone",
        base_color=(0.32, 0.30, 0.28),
        secondary_color=(0.25, 0.24, 0.22),
        roughness=0.9
    )
    
    for i in range(8):
        angle = i * (2 * math.pi / 8)
        bpy.ops.mesh.primitive_cube_add(
            size=0.15 * size,
            location=(
                math.cos(angle) * 0.35 * size,
                math.sin(angle) * 0.35 * size,
                0.075 * size
            )
        )
        stone = bpy.context.active_object
        stone.rotation_euler.z = angle + random.uniform(-0.2, 0.2)
        stone.scale = (
            random.uniform(0.8, 1.2),
            random.uniform(0.8, 1.2),
            random.uniform(0.6, 1.0)
        )
        stone.data.materials.append(stone_mat)
        parts.append(stone)
    
    # Logs
    log_mat = create_procedural_material(
        f"mat_{name}_log",
        base_color=(0.18, 0.12, 0.08),
        secondary_color=(0.12, 0.08, 0.05),
        roughness=0.85
    )
    
    for i in range(4):
        angle = i * (math.pi / 2) + random.uniform(-0.2, 0.2)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=0.06 * size,
            depth=0.4 * size,
            location=(0, 0, 0.1 * size)
        )
        log = bpy.context.active_object
        log.rotation_euler = (
            math.radians(70),
            0,
            angle
        )
        log.location.x = math.cos(angle) * 0.08 * size
        log.location.y = math.sin(angle) * 0.08 * size
        log.data.materials.append(log_mat)
        parts.append(log)
    
    # Flames/embers
    if lit:
        fire_mat = create_pbr_material(
            f"mat_{name}_fire",
            base_color=(1.0, 0.4, 0.1),
            roughness=0.3,
            emission=5.0,
            emission_color=(1.0, 0.5, 0.1)
        )
        
        for i in range(3):
            bpy.ops.mesh.primitive_cone_add(
                vertices=4,
                radius1=0.08 * size,
                radius2=0.0,
                depth=0.25 * size,
                location=(
                    random.uniform(-0.05, 0.05) * size,
                    random.uniform(-0.05, 0.05) * size,
                    0.15 * size + i * 0.05 * size
                )
            )
            flame = bpy.context.active_object
            flame.data.materials.append(fire_mat)
            parts.append(flame)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    campfire = bpy.context.active_object
    campfire.name = name
    apply_flat_shading(campfire)
    
    return campfire


# ============================================================================
# CHARACTERS & ENEMIES
# ============================================================================

def create_humanoid(name, character_type="survivor", size=1.0, seed=None):
    """Create detailed humanoid character model."""
    if seed:
        random.seed(seed)
    
    parts = []
    
    # Color schemes
    if character_type == "survivor":
        body_color = (0.25, 0.35, 0.25)  # Green clothing
        skin_color = (0.75, 0.65, 0.55)
        accent_color = (0.35, 0.30, 0.25)
    elif character_type == "zombie":
        body_color = (0.35, 0.32, 0.28)  # Tattered
        skin_color = (0.45, 0.55, 0.42)  # Greenish
        accent_color = (0.25, 0.22, 0.20)
    elif character_type == "raider":
        body_color = (0.15, 0.15, 0.15)  # Dark
        skin_color = (0.70, 0.60, 0.50)
        accent_color = (0.55, 0.15, 0.10)  # Red accents
    else:
        body_color = (0.30, 0.30, 0.30)
        skin_color = (0.72, 0.62, 0.52)
        accent_color = (0.25, 0.25, 0.25)
    
    body_mat = create_pbr_material(f"mat_{name}_body", body_color, roughness=0.7)
    skin_mat = create_pbr_material(f"mat_{name}_skin", skin_color, roughness=0.6, subsurface=0.1)
    accent_mat = create_pbr_material(f"mat_{name}_accent", accent_color, roughness=0.5)
    
    # Torso
    bpy.ops.mesh.primitive_cube_add(size=0.4 * size, location=(0, 0, 1.0 * size))
    torso = bpy.context.active_object
    torso.scale = (0.9, 0.5, 1.1)
    torso.data.materials.append(body_mat)
    parts.append(torso)
    
    # Head
    bpy.ops.mesh.primitive_cube_add(size=0.25 * size, location=(0, 0, 1.45 * size))
    head = bpy.context.active_object
    head.scale = (0.9, 0.85, 1.0)
    head.data.materials.append(skin_mat)
    parts.append(head)
    
    # Neck
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=6,
        radius=0.06 * size,
        depth=0.1 * size,
        location=(0, 0, 1.28 * size)
    )
    neck = bpy.context.active_object
    neck.data.materials.append(skin_mat)
    parts.append(neck)
    
    # Hips
    bpy.ops.mesh.primitive_cube_add(size=0.35 * size, location=(0, 0, 0.7 * size))
    hips = bpy.context.active_object
    hips.scale = (0.9, 0.5, 0.4)
    hips.data.materials.append(body_mat)
    parts.append(hips)
    
    # Legs
    for side in [-1, 1]:
        # Upper leg
        bpy.ops.mesh.primitive_cube_add(
            size=0.12 * size,
            location=(0, side * 0.1 * size, 0.45 * size)
        )
        upper_leg = bpy.context.active_object
        upper_leg.scale.z = 2.5
        upper_leg.data.materials.append(body_mat)
        parts.append(upper_leg)
        
        # Lower leg
        bpy.ops.mesh.primitive_cube_add(
            size=0.10 * size,
            location=(0, side * 0.1 * size, 0.18 * size)
        )
        lower_leg = bpy.context.active_object
        lower_leg.scale.z = 2.0
        lower_leg.data.materials.append(body_mat)
        parts.append(lower_leg)
        
        # Foot
        bpy.ops.mesh.primitive_cube_add(
            size=0.08 * size,
            location=(0.03 * size, side * 0.1 * size, 0.04 * size)
        )
        foot = bpy.context.active_object
        foot.scale = (1.5, 1.0, 0.5)
        foot.data.materials.append(accent_mat)
        parts.append(foot)
    
    # Arms
    for side in [-1, 1]:
        # Shoulder
        bpy.ops.mesh.primitive_cube_add(
            size=0.1 * size,
            location=(0, side * 0.25 * size, 1.15 * size)
        )
        shoulder = bpy.context.active_object
        shoulder.data.materials.append(body_mat)
        parts.append(shoulder)
        
        # Upper arm
        bpy.ops.mesh.primitive_cube_add(
            size=0.08 * size,
            location=(0, side * 0.30 * size, 0.95 * size)
        )
        upper_arm = bpy.context.active_object
        upper_arm.scale.z = 2.0
        upper_arm.data.materials.append(body_mat)
        parts.append(upper_arm)
        
        # Lower arm
        bpy.ops.mesh.primitive_cube_add(
            size=0.07 * size,
            location=(0, side * 0.30 * size, 0.72 * size)
        )
        lower_arm = bpy.context.active_object
        lower_arm.scale.z = 1.8
        lower_arm.data.materials.append(skin_mat)
        parts.append(lower_arm)
        
        # Hand
        bpy.ops.mesh.primitive_cube_add(
            size=0.06 * size,
            location=(0, side * 0.30 * size, 0.58 * size)
        )
        hand = bpy.context.active_object
        hand.scale = (0.8, 1.2, 0.5)
        hand.data.materials.append(skin_mat)
        parts.append(hand)
    
    # Join all
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    character = bpy.context.active_object
    character.name = name
    apply_flat_shading(character)
    
    return character


def create_animal(name, animal_type="wolf", size=1.0, seed=None):
    """Create animal model."""
    if seed:
        random.seed(seed)
    
    parts = []
    
    if animal_type == "wolf":
        body_color = (0.30, 0.28, 0.25)
        body_length = 0.8
        body_height = 0.35
        leg_height = 0.3
    elif animal_type == "bear":
        body_color = (0.25, 0.20, 0.15)
        body_length = 1.0
        body_height = 0.5
        leg_height = 0.35
    elif animal_type == "deer":
        body_color = (0.45, 0.35, 0.25)
        body_length = 0.7
        body_height = 0.3
        leg_height = 0.45
    else:  # dog
        body_color = (0.35, 0.30, 0.25)
        body_length = 0.5
        body_height = 0.25
        leg_height = 0.25
    
    body_mat = create_procedural_material(
        f"mat_{name}",
        base_color=body_color,
        secondary_color=(body_color[0] * 0.8, body_color[1] * 0.8, body_color[2] * 0.8),
        roughness=0.7
    )
    
    # Body
    bpy.ops.mesh.primitive_cube_add(
        size=body_length * size,
        location=(0, 0, (leg_height + body_height/2) * size)
    )
    body = bpy.context.active_object
    body.scale = (1.0, 0.5, body_height / body_length)
    body.data.materials.append(body_mat)
    parts.append(body)
    
    # Head
    head_size = body_length * 0.4 * size
    bpy.ops.mesh.primitive_cube_add(
        size=head_size,
        location=(body_length * 0.5 * size, 0, (leg_height + body_height * 0.7) * size)
    )
    head = bpy.context.active_object
    head.scale = (1.2, 0.7, 0.8)
    head.data.materials.append(body_mat)
    parts.append(head)
    
    # Legs (4)
    leg_positions = [
        (body_length * 0.35, 0.15),
        (body_length * 0.35, -0.15),
        (-body_length * 0.35, 0.15),
        (-body_length * 0.35, -0.15),
    ]
    for lx, ly in leg_positions:
        bpy.ops.mesh.primitive_cube_add(
            size=0.08 * size,
            location=(lx * size, ly * size, leg_height * 0.5 * size)
        )
        leg = bpy.context.active_object
        leg.scale.z = leg_height / 0.08
        leg.data.materials.append(body_mat)
        parts.append(leg)
    
    # Tail
    bpy.ops.mesh.primitive_cone_add(
        vertices=4,
        radius1=0.05 * size,
        radius2=0.02 * size,
        depth=0.3 * size,
        location=(-body_length * 0.55 * size, 0, (leg_height + body_height * 0.5) * size)
    )
    tail = bpy.context.active_object
    tail.rotation_euler = (0, math.radians(60), 0)
    tail.data.materials.append(body_mat)
    parts.append(tail)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    animal = bpy.context.active_object
    animal.name = name
    apply_flat_shading(animal)
    
    return animal


# ============================================================================
# WEAPONS
# ============================================================================

def create_melee_weapon(name, weapon_type="machete", size=1.0):
    """Create melee weapon model."""
    parts = []
    
    if weapon_type == "machete":
        blade_length = 0.5
        blade_width = 0.06
        handle_length = 0.15
        blade_color = (0.55, 0.55, 0.58)
        handle_color = (0.20, 0.15, 0.10)
    elif weapon_type == "axe":
        blade_length = 0.25
        blade_width = 0.15
        handle_length = 0.6
        blade_color = (0.50, 0.50, 0.52)
        handle_color = (0.30, 0.22, 0.15)
    elif weapon_type == "bat":
        blade_length = 0.5
        blade_width = 0.06
        handle_length = 0.25
        blade_color = (0.35, 0.28, 0.20)
        handle_color = (0.30, 0.25, 0.18)
    elif weapon_type == "knife":
        blade_length = 0.2
        blade_width = 0.03
        handle_length = 0.1
        blade_color = (0.60, 0.60, 0.62)
        handle_color = (0.15, 0.12, 0.08)
    else:  # club
        blade_length = 0.35
        blade_width = 0.08
        handle_length = 0.2
        blade_color = (0.28, 0.22, 0.15)
        handle_color = (0.25, 0.20, 0.12)
    
    blade_mat = create_pbr_material(
        f"mat_{name}_blade",
        base_color=blade_color,
        roughness=0.3,
        metallic=0.8 if weapon_type not in ["bat", "club"] else 0.0
    )
    
    handle_mat = create_pbr_material(
        f"mat_{name}_handle",
        base_color=handle_color,
        roughness=0.7
    )
    
    # Handle
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=8,
        radius=0.02 * size,
        depth=handle_length * size,
        location=(0, 0, handle_length * 0.5 * size)
    )
    handle = bpy.context.active_object
    handle.data.materials.append(handle_mat)
    parts.append(handle)
    
    # Blade/head
    if weapon_type == "axe":
        bpy.ops.mesh.primitive_cube_add(
            size=blade_width * size,
            location=(0, 0, (handle_length + blade_length * 0.5) * size)
        )
        blade = bpy.context.active_object
        blade.scale = (0.2, 1.0, blade_length / blade_width)
    elif weapon_type == "bat":
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=blade_width * 0.5 * size,
            depth=blade_length * size,
            location=(0, 0, (handle_length + blade_length * 0.5) * size)
        )
        blade = bpy.context.active_object
    else:
        bpy.ops.mesh.primitive_cube_add(
            size=blade_length * size,
            location=(0, 0, (handle_length + blade_length * 0.5) * size)
        )
        blade = bpy.context.active_object
        blade.scale = (0.05, blade_width / blade_length, 1.0)
    
    blade.data.materials.append(blade_mat)
    parts.append(blade)
    
    # Guard (for bladed weapons)
    if weapon_type in ["machete", "knife"]:
        bpy.ops.mesh.primitive_cube_add(
            size=0.03 * size,
            location=(0, 0, handle_length * size)
        )
        guard = bpy.context.active_object
        guard.scale = (0.5, 3.0, 0.5)
        guard.data.materials.append(blade_mat)
        parts.append(guard)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    weapon = bpy.context.active_object
    weapon.name = name
    apply_flat_shading(weapon)
    
    return weapon


def create_ranged_weapon(name, weapon_type="rifle", size=1.0):
    """Create ranged weapon model."""
    parts = []
    
    if weapon_type == "rifle":
        barrel_length = 0.6
        body_length = 0.4
        stock_length = 0.25
        body_color = (0.18, 0.18, 0.20)
        wood_color = (0.30, 0.22, 0.15)
    elif weapon_type == "shotgun":
        barrel_length = 0.55
        body_length = 0.25
        stock_length = 0.3
        body_color = (0.15, 0.15, 0.18)
        wood_color = (0.35, 0.25, 0.18)
    elif weapon_type == "pistol":
        barrel_length = 0.12
        body_length = 0.15
        stock_length = 0.0
        body_color = (0.12, 0.12, 0.15)
        wood_color = (0.20, 0.15, 0.10)
    elif weapon_type == "bow":
        barrel_length = 0.0
        body_length = 0.8
        stock_length = 0.0
        body_color = (0.30, 0.22, 0.15)
        wood_color = (0.28, 0.20, 0.12)
    else:  # smg
        barrel_length = 0.25
        body_length = 0.2
        stock_length = 0.1
        body_color = (0.15, 0.15, 0.18)
        wood_color = (0.12, 0.12, 0.14)
    
    metal_mat = create_pbr_material(
        f"mat_{name}_metal",
        base_color=body_color,
        roughness=0.35,
        metallic=0.85
    )
    
    wood_mat = create_pbr_material(
        f"mat_{name}_wood",
        base_color=wood_color,
        roughness=0.6
    )
    
    if weapon_type == "bow":
        # Bow body (curved)
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.35 * size,
            minor_radius=0.015 * size,
            major_segments=16,
            minor_segments=6,
            location=(0, 0, 0.4 * size)
        )
        bow = bpy.context.active_object
        bow.scale.y = 0.2
        bow.rotation_euler.x = math.radians(90)
        bow.data.materials.append(wood_mat)
        parts.append(bow)
        
        # String
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=4,
            radius=0.003 * size,
            depth=0.7 * size,
            location=(0, -0.06 * size, 0.4 * size)
        )
        string = bpy.context.active_object
        string.data.materials.append(metal_mat)
        parts.append(string)
    else:
        # Barrel
        if barrel_length > 0:
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=8,
                radius=0.015 * size,
                depth=barrel_length * size,
                location=(barrel_length * 0.5 * size, 0, 0.04 * size)
            )
            barrel = bpy.context.active_object
            barrel.rotation_euler.y = math.radians(90)
            barrel.data.materials.append(metal_mat)
            parts.append(barrel)
        
        # Body/receiver
        bpy.ops.mesh.primitive_cube_add(
            size=body_length * size,
            location=(0, 0, 0)
        )
        body = bpy.context.active_object
        body.scale = (1.0, 0.2, 0.3)
        body.data.materials.append(metal_mat)
        parts.append(body)
        
        # Grip
        bpy.ops.mesh.primitive_cube_add(
            size=0.06 * size,
            location=(-body_length * 0.2 * size, 0, -0.06 * size)
        )
        grip = bpy.context.active_object
        grip.scale = (0.8, 0.5, 1.5)
        grip.data.materials.append(wood_mat)
        parts.append(grip)
        
        # Stock
        if stock_length > 0:
            bpy.ops.mesh.primitive_cube_add(
                size=stock_length * size,
                location=(-body_length * 0.5 * size - stock_length * 0.5 * size, 0, -0.02 * size)
            )
            stock = bpy.context.active_object
            stock.scale = (1.0, 0.3, 0.5)
            stock.data.materials.append(wood_mat)
            parts.append(stock)
        
        # Magazine
        if weapon_type in ["rifle", "smg", "pistol"]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.04 * size,
                location=(0, 0, -0.06 * size)
            )
            mag = bpy.context.active_object
            mag.scale = (0.8, 0.5, 2.0)
            mag.data.materials.append(metal_mat)
            parts.append(mag)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    weapon = bpy.context.active_object
    weapon.name = name
    apply_flat_shading(weapon)
    
    return weapon


# ============================================================================
# ARMOR & EQUIPMENT
# ============================================================================

def create_armor_piece(name, armor_type="vest", size=1.0):
    """Create armor/clothing piece."""
    
    if armor_type == "vest":
        bpy.ops.mesh.primitive_cube_add(size=0.4 * size, location=(0, 0, 0.2 * size))
        armor = bpy.context.active_object
        armor.scale = (0.9, 0.5, 1.0)
        color = (0.20, 0.25, 0.18)
    elif armor_type == "helmet":
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=8,
            radius=0.15 * size,
            location=(0, 0, 0.15 * size)
        )
        armor = bpy.context.active_object
        armor.scale.z = 0.8
        color = (0.22, 0.28, 0.20)
    elif armor_type == "backpack":
        bpy.ops.mesh.primitive_cube_add(size=0.3 * size, location=(0, 0, 0.2 * size))
        armor = bpy.context.active_object
        armor.scale = (0.8, 0.4, 1.2)
        color = (0.28, 0.22, 0.15)
    elif armor_type == "boots":
        bpy.ops.mesh.primitive_cube_add(size=0.1 * size, location=(0, 0, 0.08 * size))
        armor = bpy.context.active_object
        armor.scale = (1.5, 1.0, 1.6)
        color = (0.15, 0.12, 0.10)
    else:  # gloves
        bpy.ops.mesh.primitive_cube_add(size=0.06 * size, location=(0, 0, 0.03 * size))
        armor = bpy.context.active_object
        armor.scale = (0.8, 1.2, 0.5)
        color = (0.18, 0.15, 0.12)
    
    mat = create_pbr_material(f"mat_{name}", base_color=color, roughness=0.6)
    armor.data.materials.append(mat)
    armor.name = name
    apply_flat_shading(armor)
    
    return armor


# ============================================================================
# BUILDINGS & STRUCTURES
# ============================================================================

def create_wall_segment(name, wall_type="wood", size=1.0, has_window=False):
    """Create wall segment for base building."""
    parts = []
    
    if wall_type == "wood":
        wall_color = (0.35, 0.28, 0.20)
        frame_color = (0.28, 0.22, 0.15)
    elif wall_type == "metal":
        wall_color = (0.35, 0.38, 0.40)
        frame_color = (0.25, 0.28, 0.30)
    else:  # stone
        wall_color = (0.42, 0.40, 0.38)
        frame_color = (0.35, 0.33, 0.30)
    
    wall_mat = create_procedural_material(
        f"mat_{name}_wall",
        base_color=wall_color,
        secondary_color=(wall_color[0] * 0.85, wall_color[1] * 0.85, wall_color[2] * 0.85),
        roughness=0.8
    )
    
    frame_mat = create_pbr_material(f"mat_{name}_frame", base_color=frame_color, roughness=0.7)
    
    wall_height = 2.0 * size
    wall_width = 2.0 * size
    wall_depth = 0.15 * size
    
    if has_window:
        # Wall with window hole
        window_size = 0.6 * size
        
        # Left section
        bpy.ops.mesh.primitive_cube_add(
            size=1.0,
            location=(-wall_width * 0.35, 0, wall_height * 0.5)
        )
        left = bpy.context.active_object
        left.scale = (wall_width * 0.3, wall_depth, wall_height)
        left.data.materials.append(wall_mat)
        parts.append(left)
        
        # Right section
        bpy.ops.mesh.primitive_cube_add(
            size=1.0,
            location=(wall_width * 0.35, 0, wall_height * 0.5)
        )
        right = bpy.context.active_object
        right.scale = (wall_width * 0.3, wall_depth, wall_height)
        right.data.materials.append(wall_mat)
        parts.append(right)
        
        # Top section
        bpy.ops.mesh.primitive_cube_add(
            size=1.0,
            location=(0, 0, wall_height * 0.85)
        )
        top = bpy.context.active_object
        top.scale = (wall_width * 0.4, wall_depth, wall_height * 0.3)
        top.data.materials.append(wall_mat)
        parts.append(top)
        
        # Bottom section
        bpy.ops.mesh.primitive_cube_add(
            size=1.0,
            location=(0, 0, wall_height * 0.15)
        )
        bottom = bpy.context.active_object
        bottom.scale = (wall_width * 0.4, wall_depth, wall_height * 0.3)
        bottom.data.materials.append(wall_mat)
        parts.append(bottom)
        
        # Window frame
        for pos in [(-0.3, 0.5), (0.3, 0.5), (0, 0.25), (0, 0.75)]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.05 * size,
                location=(pos[0] * window_size, 0, pos[1] * wall_height + wall_height * 0.25)
            )
            frame_part = bpy.context.active_object
            if abs(pos[0]) > 0.1:
                frame_part.scale.z = window_size / 0.05 * 1.1
            else:
                frame_part.scale.x = window_size / 0.05 * 1.2
            frame_part.data.materials.append(frame_mat)
            parts.append(frame_part)
    else:
        # Solid wall
        bpy.ops.mesh.primitive_cube_add(
            size=1.0,
            location=(0, 0, wall_height * 0.5)
        )
        wall = bpy.context.active_object
        wall.scale = (wall_width, wall_depth, wall_height)
        wall.data.materials.append(wall_mat)
        parts.append(wall)
    
    # Frame posts
    for x in [-wall_width * 0.5, wall_width * 0.5]:
        bpy.ops.mesh.primitive_cube_add(
            size=0.1 * size,
            location=(x, 0, wall_height * 0.5)
        )
        post = bpy.context.active_object
        post.scale.z = wall_height / 0.1
        post.data.materials.append(frame_mat)
        parts.append(post)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    wall = bpy.context.active_object
    wall.name = name
    apply_flat_shading(wall)
    
    return wall


def create_floor_tile(name, floor_type="wood", size=2.0):
    """Create floor tile for base building."""
    
    if floor_type == "wood":
        color = (0.38, 0.30, 0.22)
        color2 = (0.32, 0.25, 0.18)
    elif floor_type == "concrete":
        color = (0.45, 0.45, 0.47)
        color2 = (0.38, 0.38, 0.40)
    else:  # metal
        color = (0.40, 0.42, 0.45)
        color2 = (0.35, 0.37, 0.40)
    
    mat = create_procedural_material(
        f"mat_{name}",
        base_color=color,
        secondary_color=color2,
        roughness=0.75,
        noise_scale=8.0
    )
    
    bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, 0))
    floor = bpy.context.active_object
    floor.data.materials.append(mat)
    floor.name = name
    
    return floor


# ============================================================================
# VEHICLES
# ============================================================================

def create_vehicle(name, vehicle_type="car", size=1.0):
    """Create vehicle model."""
    parts = []
    
    if vehicle_type == "car":
        body_length = 2.5 * size
        body_width = 1.2 * size
        body_height = 0.8 * size
        wheel_radius = 0.25 * size
        body_color = (0.35, 0.38, 0.42)
    elif vehicle_type == "truck":
        body_length = 3.5 * size
        body_width = 1.4 * size
        body_height = 1.2 * size
        wheel_radius = 0.35 * size
        body_color = (0.28, 0.32, 0.35)
    elif vehicle_type == "motorcycle":
        body_length = 1.8 * size
        body_width = 0.4 * size
        body_height = 0.6 * size
        wheel_radius = 0.3 * size
        body_color = (0.15, 0.15, 0.18)
    else:  # atv
        body_length = 1.5 * size
        body_width = 1.0 * size
        body_height = 0.6 * size
        wheel_radius = 0.25 * size
        body_color = (0.25, 0.30, 0.22)
    
    body_mat = create_pbr_material(
        f"mat_{name}_body",
        base_color=body_color,
        roughness=0.4,
        metallic=0.6
    )
    
    wheel_mat = create_pbr_material(
        f"mat_{name}_wheel",
        base_color=(0.08, 0.08, 0.10),
        roughness=0.7
    )
    
    # Body
    bpy.ops.mesh.primitive_cube_add(
        size=1.0,
        location=(0, 0, body_height * 0.5 + wheel_radius)
    )
    body = bpy.context.active_object
    body.scale = (body_length, body_width, body_height)
    body.data.materials.append(body_mat)
    parts.append(body)
    
    # Cabin (for cars/trucks)
    if vehicle_type in ["car", "truck"]:
        cabin_length = body_length * 0.5
        bpy.ops.mesh.primitive_cube_add(
            size=1.0,
            location=(body_length * 0.1, 0, body_height + wheel_radius + body_height * 0.3)
        )
        cabin = bpy.context.active_object
        cabin.scale = (cabin_length, body_width * 0.9, body_height * 0.6)
        cabin.data.materials.append(body_mat)
        parts.append(cabin)
    
    # Wheels
    if vehicle_type == "motorcycle":
        wheel_positions = [(0.6, 0), (-0.6, 0)]
    else:
        wheel_positions = [
            (0.4, 0.5), (0.4, -0.5),
            (-0.4, 0.5), (-0.4, -0.5)
        ]
    
    for wx, wy in wheel_positions:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=wheel_radius,
            depth=wheel_radius * 0.6,
            location=(wx * body_length, wy * body_width, wheel_radius)
        )
        wheel = bpy.context.active_object
        wheel.rotation_euler.x = math.radians(90)
        wheel.data.materials.append(wheel_mat)
        parts.append(wheel)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    vehicle = bpy.context.active_object
    vehicle.name = name
    apply_flat_shading(vehicle)
    
    return vehicle


# ============================================================================
# MAIN GENERATION FUNCTION
# ============================================================================

def generate_all_assets():
    """Generate all game assets."""
    print("=" * 60)
    print("GODOT SURVIVAL PROTOTYPE - ASSET GENERATION")
    print("=" * 60)
    
    clear_scene()
    
    # Create main collection
    assets_col = get_or_create_collection("GameAssets")
    
    # Sub-collections
    collections = {
        "Environment": get_or_create_collection("Environment", assets_col),
        "Props": get_or_create_collection("Props", assets_col),
        "Characters": get_or_create_collection("Characters", assets_col),
        "Enemies": get_or_create_collection("Enemies", assets_col),
        "Animals": get_or_create_collection("Animals", assets_col),
        "Weapons": get_or_create_collection("Weapons", assets_col),
        "Armor": get_or_create_collection("Armor", assets_col),
        "Buildings": get_or_create_collection("Buildings", assets_col),
        "Vehicles": get_or_create_collection("Vehicles", assets_col),
    }
    
    # ==================== ENVIRONMENT ====================
    print("\n[1/9] Generating Environment Assets...")
    
    # Trees
    tree_types = ["oak", "pine", "birch", "dead"]
    for i, ttype in enumerate(tree_types):
        for j in range(3):
            tree = create_detailed_tree(f"tree_{ttype}_{j:02d}", tree_type=ttype, seed=i*100+j)
            tree.scale *= random.uniform(0.8, 1.2)
            collections["Environment"].objects.link(tree)
            tree.location.x = (i * 4) + j * 1.5
    
    # Rocks
    rock_types = ["boulder", "small", "slab"]
    for i, rtype in enumerate(rock_types):
        for j in range(4):
            rock = create_detailed_rock(f"rock_{rtype}_{j:02d}", rock_type=rtype, seed=i*100+j)
            collections["Environment"].objects.link(rock)
            rock.location.x = 20 + i * 3 + j
    
    # Bushes
    bush_types = ["normal", "berry", "dead"]
    for i, btype in enumerate(bush_types):
        for j in range(3):
            bush = create_bush(f"bush_{btype}_{j:02d}", bush_type=btype, seed=i*100+j)
            collections["Environment"].objects.link(bush)
            bush.location.x = 35 + i * 2 + j
    
    # Grass patches
    for i in range(5):
        grass = create_grass_patch(f"grass_patch_{i:02d}", density=15, seed=i)
        collections["Environment"].objects.link(grass)
        grass.location.x = 45 + i * 1.5
    
    print(f"  Created {len(collections['Environment'].objects)} environment objects")
    
    # ==================== PROPS ====================
    print("\n[2/9] Generating Props...")
    
    # Crates
    crate_types = ["wooden", "military", "old"]
    for i, ctype in enumerate(crate_types):
        for j in range(2):
            crate = create_crate(f"crate_{ctype}_{j:02d}", crate_type=ctype, seed=i*10+j)
            collections["Props"].objects.link(crate)
            crate.location = (i * 2, 10, 0)
    
    # Barrels
    barrel_types = ["metal", "rusty", "toxic"]
    for i, btype in enumerate(barrel_types):
        for j in range(2):
            barrel = create_barrel(f"barrel_{btype}_{j:02d}", barrel_type=btype, seed=i*10+j)
            collections["Props"].objects.link(barrel)
            barrel.location = (10 + i * 2, 10, 0)
    
    # Campfires
    campfire_lit = create_campfire("campfire_lit", lit=True)
    collections["Props"].objects.link(campfire_lit)
    campfire_lit.location = (20, 10, 0)
    
    campfire_unlit = create_campfire("campfire_unlit", lit=False)
    collections["Props"].objects.link(campfire_unlit)
    campfire_unlit.location = (22, 10, 0)
    
    print(f"  Created {len(collections['Props'].objects)} prop objects")
    
    # ==================== CHARACTERS ====================
    print("\n[3/9] Generating Characters...")
    
    for i in range(3):
        survivor = create_humanoid(f"survivor_{i:02d}", character_type="survivor", seed=i)
        collections["Characters"].objects.link(survivor)
        survivor.location = (i * 2, 20, 0)
    
    print(f"  Created {len(collections['Characters'].objects)} character objects")
    
    # ==================== ENEMIES ====================
    print("\n[4/9] Generating Enemies...")
    
    # Zombies
    zombie_seeds = [100, 200, 300, 400, 500]
    for i, seed in enumerate(zombie_seeds):
        zombie = create_humanoid(f"zombie_{i:02d}", character_type="zombie", seed=seed)
        collections["Enemies"].objects.link(zombie)
        zombie.location = (i * 2, 25, 0)
    
    # Raiders
    for i in range(3):
        raider = create_humanoid(f"raider_{i:02d}", character_type="raider", seed=i+1000)
        collections["Enemies"].objects.link(raider)
        raider.location = (12 + i * 2, 25, 0)
    
    print(f"  Created {len(collections['Enemies'].objects)} enemy objects")
    
    # ==================== ANIMALS ====================
    print("\n[5/9] Generating Animals...")
    
    animal_types = ["wolf", "bear", "deer", "dog"]
    for i, atype in enumerate(animal_types):
        for j in range(2):
            animal = create_animal(f"{atype}_{j:02d}", animal_type=atype, seed=i*10+j)
            collections["Animals"].objects.link(animal)
            animal.location = (i * 4 + j * 2, 30, 0)
    
    print(f"  Created {len(collections['Animals'].objects)} animal objects")
    
    # ==================== WEAPONS ====================
    print("\n[6/9] Generating Weapons...")
    
    # Melee weapons
    melee_types = ["machete", "axe", "bat", "knife", "club"]
    for i, wtype in enumerate(melee_types):
        weapon = create_melee_weapon(f"melee_{wtype}", weapon_type=wtype)
        collections["Weapons"].objects.link(weapon)
        weapon.location = (i * 1.5, 35, 0)
    
    # Ranged weapons
    ranged_types = ["rifle", "shotgun", "pistol", "bow", "smg"]
    for i, wtype in enumerate(ranged_types):
        weapon = create_ranged_weapon(f"ranged_{wtype}", weapon_type=wtype)
        collections["Weapons"].objects.link(weapon)
        weapon.location = (10 + i * 1.5, 35, 0)
    
    print(f"  Created {len(collections['Weapons'].objects)} weapon objects")
    
    # ==================== ARMOR ====================
    print("\n[7/9] Generating Armor...")
    
    armor_types = ["vest", "helmet", "backpack", "boots", "gloves"]
    for i, atype in enumerate(armor_types):
        armor = create_armor_piece(f"armor_{atype}", armor_type=atype)
        collections["Armor"].objects.link(armor)
        armor.location = (i * 1.5, 40, 0)
    
    print(f"  Created {len(collections['Armor'].objects)} armor objects")
    
    # ==================== BUILDINGS ====================
    print("\n[8/9] Generating Building Components...")
    
    # Walls
    wall_types = ["wood", "metal", "stone"]
    for i, wtype in enumerate(wall_types):
        wall = create_wall_segment(f"wall_{wtype}", wall_type=wtype)
        collections["Buildings"].objects.link(wall)
        wall.location = (i * 3, 45, 0)
        
        wall_window = create_wall_segment(f"wall_{wtype}_window", wall_type=wtype, has_window=True)
        collections["Buildings"].objects.link(wall_window)
        wall_window.location = (i * 3 + 10, 45, 0)
    
    # Floors
    floor_types = ["wood", "concrete", "metal"]
    for i, ftype in enumerate(floor_types):
        floor = create_floor_tile(f"floor_{ftype}", floor_type=ftype)
        collections["Buildings"].objects.link(floor)
        floor.location = (20 + i * 3, 45, 0)
    
    print(f"  Created {len(collections['Buildings'].objects)} building objects")
    
    # ==================== VEHICLES ====================
    print("\n[9/9] Generating Vehicles...")
    
    vehicle_types = ["car", "truck", "motorcycle", "atv"]
    for i, vtype in enumerate(vehicle_types):
        vehicle = create_vehicle(f"vehicle_{vtype}", vehicle_type=vtype)
        collections["Vehicles"].objects.link(vehicle)
        vehicle.location = (i * 6, 55, 0)
    
    print(f"  Created {len(collections['Vehicles'].objects)} vehicle objects")
    
    # ==================== SUMMARY ====================
    total = sum(len(col.objects) for col in collections.values())
    print("\n" + "=" * 60)
    print(f"GENERATION COMPLETE: {total} assets created")
    print("=" * 60)
    
    # Position camera
    bpy.ops.object.camera_add(location=(25, -30, 20))
    camera = bpy.context.active_object
    camera.rotation_euler = (math.radians(60), 0, 0)
    bpy.context.scene.camera = camera
    
    return collections


def export_assets_to_gltf(collections, output_path=None):
    """Export all assets to GLTF format for Godot."""
    if output_path is None:
        output_path = EXPORT_PATH
    
    output_path = Path(output_path)
    output_path.mkdir(parents=True, exist_ok=True)
    
    print("\nExporting assets to GLTF...")
    
    for col_name, collection in collections.items():
        col_path = output_path / col_name.lower()
        col_path.mkdir(parents=True, exist_ok=True)
        
        for obj in collection.objects:
            # Select only this object
            bpy.ops.object.select_all(action='DESELECT')
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            
            # Export
            filepath = str(col_path / f"{obj.name}.glb")
            bpy.ops.export_scene.gltf(
                filepath=filepath,
                use_selection=True,
                export_format='GLB',
                export_materials='EXPORT',
                export_colors=True,
            )
            print(f"  Exported: {obj.name}.glb")
    
    print(f"\nAll assets exported to: {output_path}")


# ============================================================================
# ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    collections = generate_all_assets()
    # Uncomment to export:
    # export_assets_to_gltf(collections)

# Run generation
generate_all_assets()
