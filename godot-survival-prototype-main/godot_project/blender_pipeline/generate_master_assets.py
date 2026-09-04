"""
Master Asset Generator - Generates ALL high-quality 3D assets for Godot Survival Prototype
Combines all detailed generators into one comprehensive pipeline.
Compatible with Blender 3.6+ and 4.x
"""

import bpy
import bmesh
import random
import math
import sys
import os
from pathlib import Path
from mathutils import Vector

# Blender version compatibility
BLENDER_VERSION = bpy.app.version
IS_BLENDER_4 = BLENDER_VERSION[0] >= 4
print(f"Blender version: {BLENDER_VERSION[0]}.{BLENDER_VERSION[1]}.{BLENDER_VERSION[2]}")

# Add templates directory to path
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR / "procedural" / "templates"))

# Try to import detailed generators
try:
    from zombie_detailed import ZombieGenerator
    HAS_ZOMBIE_GEN = True
except ImportError:
    HAS_ZOMBIE_GEN = False
    print("Warning: zombie_detailed module not found, using built-in")

try:
    from weapon_detailed import WeaponGenerator
    HAS_WEAPON_GEN = True
except ImportError:
    HAS_WEAPON_GEN = False
    print("Warning: weapon_detailed module not found, using built-in")


# ============================================================================
# CONFIGURATION
# ============================================================================

random.seed(42)  # Reproducible generation

EXPORT_PATH = SCRIPT_DIR / "exports"

# Asset counts per category
ASSET_CONFIG = {
    "trees": {"count": 12, "types": ["oak", "pine", "birch", "dead"]},
    "rocks": {"count": 15, "types": ["boulder", "small", "slab", "ore"]},
    "bushes": {"count": 8, "types": ["normal", "berry", "dead", "flowering"]},
    "props": {"count": 20},
    "characters": {"count": 5},
    "zombies": {"count": 8, "types": ["walker", "runner", "crawler", "bloater", "screamer", "spitter", "brute", "ravager"]},
    "animals": {"count": 8, "types": ["wolf", "bear", "deer", "dog", "boar", "rabbit", "crow", "fish"]},
    "raiders": {"count": 4, "types": ["scout", "gunner", "heavy", "boss"]},
    "weapons_melee": {"count": 12},
    "weapons_ranged": {"count": 13},
    "weapons_throwable": {"count": 3},
    "armor": {"count": 20},
    "buildings": {"count": 15},
    "vehicles": {"count": 6, "types": ["car", "truck", "motorcycle", "atv", "boat", "helicopter"]},
}


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


def set_origin_to_bottom(obj):
    """Set origin to bottom center of object for proper ground placement.
    
    This ensures models are placed correctly when spawned at Y=0 in Godot,
    with their feet/base touching the ground.
    """
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # First, apply all transforms to get accurate bounds
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    
    # Get the lowest Z point of the mesh in world space
    mesh = obj.data
    min_z = min((obj.matrix_world @ v.co).z for v in mesh.vertices)
    
    # Set the 3D cursor to the bottom center
    bpy.context.scene.cursor.location = (0.0, 0.0, min_z)
    
    # Set origin to 3D cursor
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    
    # Move object so origin is at world origin
    obj.location = (0.0, 0.0, 0.0)
    
    # Reset cursor
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    
    obj.select_set(False)


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
    for block in bpy.data.collections:
        if block.users == 0:
            bpy.data.collections.remove(block)


def link_to_collection(obj, collection):
    """Link object to collection, unlinking from scene collection."""
    for col in obj.users_collection:
        col.objects.unlink(obj)
    collection.objects.link(obj)


def apply_flat_shading(obj):
    """Apply flat low-poly shading."""
    if obj.type == 'MESH':
        for p in obj.data.polygons:
            p.use_smooth = False


# ============================================================================
# MATERIAL LIBRARY
# ============================================================================

class MaterialLibrary:
    """Centralized material creation."""
    
    _materials = {}
    
    @classmethod
    def get_or_create(cls, name, create_func, *args, **kwargs):
        """Get cached material or create new one."""
        if name not in cls._materials:
            cls._materials[name] = create_func(name, *args, **kwargs)
        return cls._materials[name]
    
    @staticmethod
    def create_pbr(name, color, roughness=0.7, metallic=0.0):
        """Create basic PBR material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (400, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (0, 0)
        bsdf.inputs["Base Color"].default_value = (*color[:3], 1.0)
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    @staticmethod
    def create_procedural(name, color1, color2, roughness=0.7, noise_scale=5.0):
        """Create procedural material with noise variation."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (600, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (300, 0)
        bsdf.inputs["Roughness"].default_value = roughness
        
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-200, 0)
        noise.inputs["Scale"].default_value = noise_scale
        noise.inputs["Detail"].default_value = 4.0
        
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (0, 0)
        ramp.color_ramp.elements[0].color = (*color1[:3], 1.0)
        ramp.color_ramp.elements[1].color = (*color2[:3], 1.0)
        
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat


# ============================================================================
# ENVIRONMENT GENERATOR
# ============================================================================

class EnvironmentGenerator:
    """Generate environment assets (trees, rocks, bushes, etc.)."""
    
    def __init__(self, collection):
        self.collection = collection
    
    def generate_tree(self, name, tree_type="oak", size=1.0, seed=None):
        """Generate a detailed tree."""
        if seed:
            random.seed(seed)
        
        parts = []
        
        # Trunk
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
        
        trunk_mat = MaterialLibrary.create_procedural(
            f"mat_{name}_trunk",
            (0.25, 0.18, 0.12),
            (0.18, 0.12, 0.08),
            roughness=0.9
        )
        trunk.data.materials.append(trunk_mat)
        parts.append(trunk)
        
        # Foliage configuration per type
        foliage_configs = {
            "oak": {
                "layers": [(1.8, 0.9), (2.3, 0.7), (2.7, 0.5)],
                "color1": (0.15, 0.35, 0.12),
                "color2": (0.12, 0.28, 0.10)
            },
            "pine": {
                "layers": [(1.2, 0.8), (1.8, 0.6), (2.4, 0.4), (2.9, 0.2)],
                "color1": (0.08, 0.25, 0.10),
                "color2": (0.06, 0.20, 0.08)
            },
            "birch": {
                "layers": [(1.6, 0.6), (2.1, 0.5)],
                "color1": (0.20, 0.40, 0.15),
                "color2": (0.25, 0.45, 0.18)
            },
            "dead": {
                "layers": [],  # No foliage
                "color1": (0.3, 0.25, 0.18),
                "color2": (0.25, 0.20, 0.15)
            }
        }
        
        config = foliage_configs.get(tree_type, foliage_configs["oak"])
        
        if config["layers"]:
            foliage_mat = MaterialLibrary.create_procedural(
                f"mat_{name}_foliage",
                config["color1"],
                config["color2"],
                roughness=0.8
            )
            
            for height, radius in config["layers"]:
                h = height * size
                r = radius * size * random.uniform(0.9, 1.1)
                
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
                
                # Organic deformation
                for v in foliage.data.vertices:
                    v.co.x += random.uniform(-0.1, 0.1) * r
                    v.co.y += random.uniform(-0.1, 0.1) * r
                    v.co.z += random.uniform(-0.1, 0.1) * r
                
                foliage.data.materials.append(foliage_mat)
                parts.append(foliage)
        else:
            # Dead tree - add branches
            for i in range(5):
                angle = i * math.pi * 0.5 + random.uniform(-0.3, 0.3)
                branch_len = random.uniform(0.3, 0.5) * size
                height = random.uniform(0.8, 1.3) * size
                
                bpy.ops.mesh.primitive_cylinder_add(
                    vertices=4,
                    radius=0.025 * size,
                    depth=branch_len,
                    location=(
                        math.cos(angle) * 0.1 * size,
                        math.sin(angle) * 0.1 * size,
                        height
                    )
                )
                branch = bpy.context.active_object
                branch.rotation_euler = (
                    random.uniform(-0.3, 0.3),
                    math.radians(50 + random.uniform(-20, 20)),
                    angle
                )
                branch.data.materials.append(trunk_mat)
                parts.append(branch)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = trunk
        bpy.ops.object.join()
        
        tree = bpy.context.active_object
        tree.name = name
        apply_flat_shading(tree)
        link_to_collection(tree, self.collection)
        
        return tree
    
    def generate_rock(self, name, rock_type="boulder", size=1.0, seed=None):
        """Generate a detailed rock."""
        if seed:
            random.seed(seed)
        
        subdivisions = 2 if rock_type == "boulder" else 1
        base_radius = {
            "boulder": 0.5,
            "small": 0.2,
            "slab": 0.6,
            "ore": 0.4
        }.get(rock_type, 0.4) * size
        
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=subdivisions,
            radius=base_radius,
            location=(0, 0, base_radius * 0.7)
        )
        rock = bpy.context.active_object
        
        # Deform based on type
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
        
        bpy.ops.object.transform_apply(scale=True)
        
        # Vertex displacement
        for v in rock.data.vertices:
            noise_val = (
                math.sin(v.co.x * 5) * math.cos(v.co.y * 5) * 
                math.sin(v.co.z * 3)
            ) * 0.1 * size
            v.co.x += noise_val + random.uniform(-0.05, 0.05) * size
            v.co.y += noise_val + random.uniform(-0.05, 0.05) * size
            v.co.z += random.uniform(-0.03, 0.03) * size
        
        # Material
        if rock_type == "ore":
            rock_mat = MaterialLibrary.create_procedural(
                f"mat_{name}",
                (0.35, 0.30, 0.25),
                (0.6, 0.45, 0.2),  # Ore veins
                roughness=0.7
            )
        else:
            rock_mat = MaterialLibrary.create_procedural(
                f"mat_{name}",
                (0.35, 0.33, 0.30),
                (0.25, 0.24, 0.22),
                roughness=0.85
            )
        rock.data.materials.append(rock_mat)
        
        rock.name = name
        apply_flat_shading(rock)
        link_to_collection(rock, self.collection)
        
        return rock
    
    def generate_bush(self, name, bush_type="normal", size=1.0, seed=None):
        """Generate a detailed bush."""
        if seed:
            random.seed(seed)
        
        parts = []
        
        # Color configuration per type
        colors = {
            "normal": ((0.18, 0.38, 0.15), (0.15, 0.32, 0.12)),
            "berry": ((0.15, 0.35, 0.12), (0.6, 0.1, 0.1)),
            "dead": ((0.35, 0.28, 0.18), (0.30, 0.25, 0.15)),
            "flowering": ((0.18, 0.38, 0.15), (0.8, 0.5, 0.7))
        }
        
        color1, color2 = colors.get(bush_type, colors["normal"])
        
        bush_mat = MaterialLibrary.create_procedural(
            f"mat_{name}",
            color1, color2,
            roughness=0.8,
            noise_scale=8.0
        )
        
        cluster_count = 5 if bush_type != "dead" else 3
        
        for i in range(cluster_count):
            angle = i * (2 * math.pi / cluster_count) + random.uniform(-0.3, 0.3)
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
        link_to_collection(bush, self.collection)
        
        return bush
    
    def generate_all(self):
        """Generate all environment assets."""
        assets = []
        
        # Trees
        tree_types = ASSET_CONFIG["trees"]["types"]
        for i in range(ASSET_CONFIG["trees"]["count"]):
            tree_type = tree_types[i % len(tree_types)]
            tree = self.generate_tree(
                f"tree_{tree_type}_{i:02d}",
                tree_type=tree_type,
                size=random.uniform(0.8, 1.2),
                seed=i * 100
            )
            tree.location.x = (i % 6) * 3
            tree.location.y = (i // 6) * 3
            assets.append(tree)
        
        # Rocks
        rock_types = ASSET_CONFIG["rocks"]["types"]
        for i in range(ASSET_CONFIG["rocks"]["count"]):
            rock_type = rock_types[i % len(rock_types)]
            rock = self.generate_rock(
                f"rock_{rock_type}_{i:02d}",
                rock_type=rock_type,
                size=random.uniform(0.6, 1.4),
                seed=i * 100 + 1000
            )
            rock.location.x = 20 + (i % 5) * 2
            rock.location.y = (i // 5) * 2
            assets.append(rock)
        
        # Bushes
        bush_types = ASSET_CONFIG["bushes"]["types"]
        for i in range(ASSET_CONFIG["bushes"]["count"]):
            bush_type = bush_types[i % len(bush_types)]
            bush = self.generate_bush(
                f"bush_{bush_type}_{i:02d}",
                bush_type=bush_type,
                size=random.uniform(0.7, 1.3),
                seed=i * 100 + 2000
            )
            bush.location.x = 35 + (i % 4) * 2
            bush.location.y = (i // 4) * 2
            assets.append(bush)
        
        return assets


# ============================================================================
# PROP GENERATOR
# ============================================================================

class PropGenerator:
    """Generate props (crates, barrels, containers, etc.)."""
    
    def __init__(self, collection):
        self.collection = collection
    
    def generate_crate(self, name, crate_type="wooden", size=1.0, seed=None):
        """Generate a detailed crate."""
        if seed:
            random.seed(seed)
        
        parts = []
        
        color_configs = {
            "wooden": ((0.35, 0.25, 0.15), (0.25, 0.25, 0.28)),
            "military": ((0.20, 0.25, 0.18), (0.15, 0.18, 0.15)),
            "metal": ((0.35, 0.38, 0.40), (0.28, 0.30, 0.32))
        }
        
        wood_color, metal_color = color_configs.get(crate_type, color_configs["wooden"])
        
        wood_mat = MaterialLibrary.create_procedural(
            f"mat_{name}_wood",
            wood_color,
            (wood_color[0] * 0.7, wood_color[1] * 0.7, wood_color[2] * 0.7),
            roughness=0.8
        )
        
        metal_mat = MaterialLibrary.create_pbr(
            f"mat_{name}_metal",
            metal_color,
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
        corners = [(0.35, 0.35), (0.35, -0.35), (-0.35, 0.35), (-0.35, -0.35)]
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
        link_to_collection(crate, self.collection)
        
        return crate
    
    def generate_barrel(self, name, barrel_type="metal", size=1.0, seed=None):
        """Generate a detailed barrel."""
        if seed:
            random.seed(seed)
        
        color_configs = {
            "metal": ((0.25, 0.28, 0.32), 0.6),
            "rusty": ((0.45, 0.28, 0.15), 0.3),
            "toxic": ((0.15, 0.35, 0.12), 0.4),
            "fuel": ((0.55, 0.15, 0.10), 0.5)
        }
        
        body_color, metallic = color_configs.get(barrel_type, color_configs["metal"])
        
        body_mat = MaterialLibrary.create_pbr(
            f"mat_{name}_body",
            body_color,
            roughness=0.6,
            metallic=metallic
        )
        
        band_mat = MaterialLibrary.create_pbr(
            f"mat_{name}_band",
            (body_color[0] * 0.8, body_color[1] * 0.8, body_color[2] * 0.8),
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
        link_to_collection(barrel, self.collection)
        
        return barrel
    
    def generate_campfire(self, name, lit=True, size=1.0):
        """Generate a campfire."""
        parts = []
        
        stone_mat = MaterialLibrary.create_procedural(
            f"mat_{name}_stone",
            (0.32, 0.30, 0.28),
            (0.25, 0.24, 0.22),
            roughness=0.9
        )
        
        log_mat = MaterialLibrary.create_procedural(
            f"mat_{name}_log",
            (0.18, 0.12, 0.08),
            (0.12, 0.08, 0.05),
            roughness=0.85
        )
        
        # Stone ring
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
        for i in range(4):
            angle = i * (math.pi / 2) + random.uniform(-0.2, 0.2)
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6,
                radius=0.06 * size,
                depth=0.4 * size,
                location=(0, 0, 0.1 * size)
            )
            log = bpy.context.active_object
            log.rotation_euler = (math.radians(70), 0, angle)
            log.location.x = math.cos(angle) * 0.08 * size
            log.location.y = math.sin(angle) * 0.08 * size
            log.data.materials.append(log_mat)
            parts.append(log)
        
        # Fire effect
        if lit:
            fire_mat = MaterialLibrary.create_pbr(
                f"mat_{name}_fire",
                (1.0, 0.4, 0.1),
                roughness=0.3
            )
            fire_mat.use_nodes = True
            nodes = fire_mat.node_tree.nodes
            bsdf = nodes.get("Principled BSDF")
            if bsdf:
                bsdf.inputs["Emission Color"].default_value = (1.0, 0.5, 0.1, 1.0)
                bsdf.inputs["Emission Strength"].default_value = 5.0
            
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
        link_to_collection(campfire, self.collection)
        
        return campfire
    
    def generate_all(self):
        """Generate all prop assets."""
        assets = []
        
        # Crates
        crate_types = ["wooden", "military", "metal"]
        for i, ctype in enumerate(crate_types):
            for j in range(2):
                crate = self.generate_crate(
                    f"crate_{ctype}_{j:02d}",
                    crate_type=ctype,
                    seed=i * 10 + j
                )
                crate.location.x = i * 2
                crate.location.y = 10 + j
                assets.append(crate)
        
        # Barrels
        barrel_types = ["metal", "rusty", "toxic", "fuel"]
        for i, btype in enumerate(barrel_types):
            for j in range(2):
                barrel = self.generate_barrel(
                    f"barrel_{btype}_{j:02d}",
                    barrel_type=btype,
                    seed=i * 10 + j + 100
                )
                barrel.location.x = 10 + i * 2
                barrel.location.y = 10 + j
                assets.append(barrel)
        
        # Campfires
        campfire_lit = self.generate_campfire("campfire_lit", lit=True)
        campfire_lit.location = (20, 10, 0)
        assets.append(campfire_lit)
        
        campfire_unlit = self.generate_campfire("campfire_unlit", lit=False)
        campfire_unlit.location = (22, 10, 0)
        assets.append(campfire_unlit)
        
        return assets


# ============================================================================
# CHARACTER GENERATOR
# ============================================================================

class CharacterGenerator:
    """Generate character models (survivors, zombies, NPCs)."""
    
    def __init__(self, collection):
        self.collection = collection
    
    def generate_humanoid(self, name, char_type="survivor", size=1.0, seed=None):
        """Generate a humanoid character."""
        if seed:
            random.seed(seed)
        
        parts = []
        
        # Color schemes
        color_schemes = {
            "survivor": {
                "body": (0.25, 0.35, 0.25),
                "skin": (0.75, 0.65, 0.55),
                "accent": (0.35, 0.30, 0.25)
            },
            "zombie": {
                "body": (0.35, 0.32, 0.28),
                "skin": (0.45, 0.55, 0.42),
                "accent": (0.25, 0.22, 0.20)
            },
            "raider": {
                "body": (0.15, 0.15, 0.15),
                "skin": (0.70, 0.60, 0.50),
                "accent": (0.55, 0.15, 0.10)
            },
            "npc": {
                "body": (0.30, 0.30, 0.30),
                "skin": (0.72, 0.62, 0.52),
                "accent": (0.25, 0.25, 0.25)
            }
        }
        
        scheme = color_schemes.get(char_type, color_schemes["survivor"])
        
        body_mat = MaterialLibrary.create_pbr(f"mat_{name}_body", scheme["body"], roughness=0.7)
        skin_mat = MaterialLibrary.create_pbr(f"mat_{name}_skin", scheme["skin"], roughness=0.6)
        accent_mat = MaterialLibrary.create_pbr(f"mat_{name}_accent", scheme["accent"], roughness=0.5)
        
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
        
        # IMPORTANT: Set origin to bottom for proper ground placement in Godot
        set_origin_to_bottom(character)
        
        link_to_collection(character, self.collection)
        
        return character
    
    def generate_animal(self, name, animal_type="wolf", size=1.0, seed=None):
        """Generate an animal model."""
        if seed:
            random.seed(seed)
        
        parts = []
        
        configs = {
            "wolf": {"color": (0.30, 0.28, 0.25), "body_len": 0.8, "body_h": 0.35, "leg_h": 0.3},
            "bear": {"color": (0.25, 0.20, 0.15), "body_len": 1.0, "body_h": 0.5, "leg_h": 0.35},
            "deer": {"color": (0.45, 0.35, 0.25), "body_len": 0.7, "body_h": 0.3, "leg_h": 0.45},
            "dog": {"color": (0.35, 0.30, 0.25), "body_len": 0.5, "body_h": 0.25, "leg_h": 0.25},
            "boar": {"color": (0.28, 0.22, 0.18), "body_len": 0.6, "body_h": 0.35, "leg_h": 0.2},
        }
        
        config = configs.get(animal_type, configs["wolf"])
        
        body_mat = MaterialLibrary.create_procedural(
            f"mat_{name}",
            config["color"],
            (config["color"][0] * 0.8, config["color"][1] * 0.8, config["color"][2] * 0.8),
            roughness=0.7
        )
        
        body_len = config["body_len"] * size
        body_h = config["body_h"] * size
        leg_h = config["leg_h"] * size
        
        # Body
        bpy.ops.mesh.primitive_cube_add(
            size=body_len,
            location=(0, 0, leg_h + body_h / 2)
        )
        body = bpy.context.active_object
        body.scale = (1.0, 0.5, body_h / body_len)
        body.data.materials.append(body_mat)
        parts.append(body)
        
        # Head
        head_size = body_len * 0.4
        bpy.ops.mesh.primitive_cube_add(
            size=head_size,
            location=(body_len * 0.5, 0, leg_h + body_h * 0.7)
        )
        head = bpy.context.active_object
        head.scale = (1.2, 0.7, 0.8)
        head.data.materials.append(body_mat)
        parts.append(head)
        
        # Legs (4)
        leg_positions = [
            (body_len * 0.35, 0.15),
            (body_len * 0.35, -0.15),
            (-body_len * 0.35, 0.15),
            (-body_len * 0.35, -0.15),
        ]
        for lx, ly in leg_positions:
            bpy.ops.mesh.primitive_cube_add(
                size=0.08 * size,
                location=(lx, ly * size, leg_h * 0.5)
            )
            leg = bpy.context.active_object
            leg.scale.z = leg_h / 0.08
            leg.data.materials.append(body_mat)
            parts.append(leg)
        
        # Tail
        bpy.ops.mesh.primitive_cone_add(
            vertices=4,
            radius1=0.05 * size,
            radius2=0.02 * size,
            depth=0.3 * size,
            location=(-body_len * 0.55, 0, leg_h + body_h * 0.5)
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
        
        # IMPORTANT: Set origin to bottom for proper ground placement in Godot
        set_origin_to_bottom(animal)
        
        link_to_collection(animal, self.collection)
        
        return animal
    
    def generate_all(self):
        """Generate all character assets."""
        assets = []
        
        # Survivors
        for i in range(3):
            survivor = self.generate_humanoid(f"survivor_{i:02d}", "survivor", seed=i)
            survivor.location = (i * 2, 20, 0)
            assets.append(survivor)
        
        # NPCs
        for i in range(2):
            npc = self.generate_humanoid(f"npc_{i:02d}", "npc", seed=i + 100)
            npc.location = (6 + i * 2, 20, 0)
            assets.append(npc)
        
        return assets


# ============================================================================
# VEHICLE GENERATOR
# ============================================================================

class VehicleGenerator:
    """Generate vehicle models."""
    
    def __init__(self, collection):
        self.collection = collection
    
    def generate_vehicle(self, name, vehicle_type="car", size=1.0):
        """Generate a vehicle model."""
        parts = []
        
        configs = {
            "car": {"body_l": 2.5, "body_w": 1.2, "body_h": 0.8, "wheel_r": 0.25, "color": (0.35, 0.38, 0.42)},
            "truck": {"body_l": 3.5, "body_w": 1.4, "body_h": 1.2, "wheel_r": 0.35, "color": (0.28, 0.32, 0.35)},
            "motorcycle": {"body_l": 1.8, "body_w": 0.4, "body_h": 0.6, "wheel_r": 0.3, "color": (0.15, 0.15, 0.18)},
            "atv": {"body_l": 1.5, "body_w": 1.0, "body_h": 0.6, "wheel_r": 0.25, "color": (0.25, 0.30, 0.22)},
            "boat": {"body_l": 3.0, "body_w": 1.5, "body_h": 0.5, "wheel_r": 0, "color": (0.3, 0.35, 0.4)},
            "helicopter": {"body_l": 3.0, "body_w": 1.2, "body_h": 1.0, "wheel_r": 0.15, "color": (0.25, 0.28, 0.22)},
        }
        
        config = configs.get(vehicle_type, configs["car"])
        
        body_l = config["body_l"] * size
        body_w = config["body_w"] * size
        body_h = config["body_h"] * size
        wheel_r = config["wheel_r"] * size
        
        body_mat = MaterialLibrary.create_pbr(
            f"mat_{name}_body",
            config["color"],
            roughness=0.4,
            metallic=0.6
        )
        
        wheel_mat = MaterialLibrary.create_pbr(
            f"mat_{name}_wheel",
            (0.08, 0.08, 0.10),
            roughness=0.7
        )
        
        # Body
        bpy.ops.mesh.primitive_cube_add(
            size=1.0,
            location=(0, 0, body_h * 0.5 + wheel_r)
        )
        body = bpy.context.active_object
        body.scale = (body_l, body_w, body_h)
        body.data.materials.append(body_mat)
        parts.append(body)
        
        # Cabin for cars/trucks
        if vehicle_type in ["car", "truck"]:
            cabin_l = body_l * 0.5
            bpy.ops.mesh.primitive_cube_add(
                size=1.0,
                location=(body_l * 0.1, 0, body_h + wheel_r + body_h * 0.3)
            )
            cabin = bpy.context.active_object
            cabin.scale = (cabin_l, body_w * 0.9, body_h * 0.6)
            cabin.data.materials.append(body_mat)
            parts.append(cabin)
        
        # Helicopter rotor
        if vehicle_type == "helicopter":
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=16,
                radius=body_l * 0.8,
                depth=0.02,
                location=(0, 0, body_h + wheel_r + 0.3)
            )
            rotor = bpy.context.active_object
            rotor.data.materials.append(wheel_mat)
            parts.append(rotor)
        
        # Wheels
        if wheel_r > 0:
            if vehicle_type == "motorcycle":
                wheel_positions = [(0.6, 0), (-0.6, 0)]
            elif vehicle_type == "helicopter":
                wheel_positions = [(0.4, 0.4), (0.4, -0.4), (-0.5, 0)]
            else:
                wheel_positions = [
                    (0.4, 0.5), (0.4, -0.5),
                    (-0.4, 0.5), (-0.4, -0.5)
                ]
            
            for wx, wy in wheel_positions:
                bpy.ops.mesh.primitive_cylinder_add(
                    vertices=12,
                    radius=wheel_r,
                    depth=wheel_r * 0.6,
                    location=(wx * body_l, wy * body_w, wheel_r)
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
        link_to_collection(vehicle, self.collection)
        
        return vehicle
    
    def generate_all(self):
        """Generate all vehicle assets."""
        assets = []
        
        vehicle_types = ASSET_CONFIG["vehicles"]["types"]
        for i, vtype in enumerate(vehicle_types):
            vehicle = self.generate_vehicle(f"vehicle_{vtype}", vtype)
            vehicle.location.x = i * 6
            vehicle.location.y = 55
            assets.append(vehicle)
        
        return assets


# ============================================================================
# BUILDING GENERATOR
# ============================================================================

class BuildingGenerator:
    """Generate building components."""
    
    def __init__(self, collection):
        self.collection = collection
    
    def generate_wall(self, name, wall_type="wood", has_window=False, size=1.0):
        """Generate a wall segment."""
        parts = []
        
        colors = {
            "wood": ((0.35, 0.28, 0.20), (0.28, 0.22, 0.15)),
            "metal": ((0.35, 0.38, 0.40), (0.25, 0.28, 0.30)),
            "stone": ((0.42, 0.40, 0.38), (0.35, 0.33, 0.30)),
            "brick": ((0.55, 0.30, 0.25), (0.45, 0.25, 0.20))
        }
        
        wall_color, frame_color = colors.get(wall_type, colors["wood"])
        
        wall_mat = MaterialLibrary.create_procedural(
            f"mat_{name}_wall",
            wall_color,
            (wall_color[0] * 0.85, wall_color[1] * 0.85, wall_color[2] * 0.85),
            roughness=0.8
        )
        
        frame_mat = MaterialLibrary.create_pbr(f"mat_{name}_frame", frame_color, roughness=0.7)
        
        wall_h = 2.0 * size
        wall_w = 2.0 * size
        wall_d = 0.15 * size
        
        if has_window:
            # Create wall with window cutout using multiple pieces
            window_size = 0.6 * size
            
            # Left section
            bpy.ops.mesh.primitive_cube_add(
                size=1.0,
                location=(-wall_w * 0.35, 0, wall_h * 0.5)
            )
            left = bpy.context.active_object
            left.scale = (wall_w * 0.3, wall_d, wall_h)
            left.data.materials.append(wall_mat)
            parts.append(left)
            
            # Right section
            bpy.ops.mesh.primitive_cube_add(
                size=1.0,
                location=(wall_w * 0.35, 0, wall_h * 0.5)
            )
            right = bpy.context.active_object
            right.scale = (wall_w * 0.3, wall_d, wall_h)
            right.data.materials.append(wall_mat)
            parts.append(right)
            
            # Top section
            bpy.ops.mesh.primitive_cube_add(
                size=1.0,
                location=(0, 0, wall_h * 0.85)
            )
            top = bpy.context.active_object
            top.scale = (wall_w * 0.4, wall_d, wall_h * 0.3)
            top.data.materials.append(wall_mat)
            parts.append(top)
            
            # Bottom section
            bpy.ops.mesh.primitive_cube_add(
                size=1.0,
                location=(0, 0, wall_h * 0.15)
            )
            bottom = bpy.context.active_object
            bottom.scale = (wall_w * 0.4, wall_d, wall_h * 0.3)
            bottom.data.materials.append(wall_mat)
            parts.append(bottom)
        else:
            # Solid wall
            bpy.ops.mesh.primitive_cube_add(
                size=1.0,
                location=(0, 0, wall_h * 0.5)
            )
            wall = bpy.context.active_object
            wall.scale = (wall_w, wall_d, wall_h)
            wall.data.materials.append(wall_mat)
            parts.append(wall)
        
        # Frame posts
        for x in [-wall_w * 0.5, wall_w * 0.5]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.1 * size,
                location=(x, 0, wall_h * 0.5)
            )
            post = bpy.context.active_object
            post.scale.z = wall_h / 0.1
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
        link_to_collection(wall, self.collection)
        
        return wall
    
    def generate_floor(self, name, floor_type="wood", size=2.0):
        """Generate a floor tile."""
        colors = {
            "wood": ((0.38, 0.30, 0.22), (0.32, 0.25, 0.18)),
            "concrete": ((0.45, 0.45, 0.47), (0.38, 0.38, 0.40)),
            "metal": ((0.40, 0.42, 0.45), (0.35, 0.37, 0.40))
        }
        
        color1, color2 = colors.get(floor_type, colors["wood"])
        
        mat = MaterialLibrary.create_procedural(
            f"mat_{name}",
            color1, color2,
            roughness=0.75,
            noise_scale=8.0
        )
        
        bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, 0))
        floor = bpy.context.active_object
        floor.data.materials.append(mat)
        floor.name = name
        
        link_to_collection(floor, self.collection)
        
        return floor
    
    def generate_door(self, name, door_type="wood", size=1.0):
        """Generate a door."""
        colors = {
            "wood": (0.35, 0.25, 0.15),
            "metal": (0.30, 0.32, 0.35)
        }
        
        color = colors.get(door_type, colors["wood"])
        
        mat = MaterialLibrary.create_pbr(f"mat_{name}", color, roughness=0.6)
        
        parts = []
        
        # Door panel
        bpy.ops.mesh.primitive_cube_add(
            size=1.0,
            location=(0, 0, 1.0 * size)
        )
        panel = bpy.context.active_object
        panel.scale = (1.0 * size, 0.05 * size, 2.0 * size)
        panel.data.materials.append(mat)
        parts.append(panel)
        
        # Handle
        handle_mat = MaterialLibrary.create_pbr(f"mat_{name}_handle", (0.5, 0.5, 0.55), roughness=0.4, metallic=0.8)
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=0.03 * size,
            depth=0.1 * size,
            location=(0.35 * size, 0.05 * size, 0.9 * size)
        )
        handle = bpy.context.active_object
        handle.rotation_euler.x = math.radians(90)
        handle.data.materials.append(handle_mat)
        parts.append(handle)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        door = bpy.context.active_object
        door.name = name
        apply_flat_shading(door)
        link_to_collection(door, self.collection)
        
        return door
    
    def generate_all(self):
        """Generate all building assets."""
        assets = []
        
        # Walls
        wall_types = ["wood", "metal", "stone", "brick"]
        for i, wtype in enumerate(wall_types):
            wall = self.generate_wall(f"wall_{wtype}", wtype, has_window=False)
            wall.location = (i * 3, 45, 0)
            assets.append(wall)
            
            wall_window = self.generate_wall(f"wall_{wtype}_window", wtype, has_window=True)
            wall_window.location = (i * 3 + 12, 45, 0)
            assets.append(wall_window)
        
        # Floors
        floor_types = ["wood", "concrete", "metal"]
        for i, ftype in enumerate(floor_types):
            floor = self.generate_floor(f"floor_{ftype}", ftype)
            floor.location = (24 + i * 3, 45, 0)
            assets.append(floor)
        
        # Doors
        door_types = ["wood", "metal"]
        for i, dtype in enumerate(door_types):
            door = self.generate_door(f"door_{dtype}", dtype)
            door.location = (33 + i * 2, 45, 0)
            assets.append(door)
        
        return assets


# ============================================================================
# MAIN GENERATION
# ============================================================================

def generate_all_assets():
    """Generate all game assets."""
    print("=" * 60)
    print("GODOT SURVIVAL PROTOTYPE - MASTER ASSET GENERATION")
    print("=" * 60)
    
    clear_scene()
    
    # Create main collection
    assets_col = get_or_create_collection("GameAssets")
    
    # Create sub-collections
    env_col = get_or_create_collection("Environment", assets_col)
    prop_col = get_or_create_collection("Props", assets_col)
    char_col = get_or_create_collection("Characters", assets_col)
    enemy_col = get_or_create_collection("Enemies", assets_col)
    weapon_col = get_or_create_collection("Weapons", assets_col)
    building_col = get_or_create_collection("Buildings", assets_col)
    vehicle_col = get_or_create_collection("Vehicles", assets_col)
    
    all_assets = []
    
    # Generate Environment
    print("\n[1/6] Generating Environment Assets...")
    env_gen = EnvironmentGenerator(env_col)
    env_assets = env_gen.generate_all()
    all_assets.extend(env_assets)
    print(f"  Created {len(env_assets)} environment objects")
    
    # Generate Props
    print("\n[2/6] Generating Props...")
    prop_gen = PropGenerator(prop_col)
    prop_assets = prop_gen.generate_all()
    all_assets.extend(prop_assets)
    print(f"  Created {len(prop_assets)} prop objects")
    
    # Generate Characters
    print("\n[3/6] Generating Characters...")
    char_gen = CharacterGenerator(char_col)
    char_assets = char_gen.generate_all()
    all_assets.extend(char_assets)
    print(f"  Created {len(char_assets)} character objects")
    
    # Generate Enemies (using detailed generator if available)
    print("\n[4/6] Generating Enemies...")
    enemy_gen = CharacterGenerator(enemy_col)
    
    if HAS_ZOMBIE_GEN:
        zombie_gen = ZombieGenerator()
        zombie_types = ASSET_CONFIG["zombies"]["types"]
        for i, ztype in enumerate(zombie_types):
            zombie = zombie_gen.generate(f"zombie_{ztype}", ztype)
            # IMPORTANT: Set origin to bottom for proper ground placement
            set_origin_to_bottom(zombie)
            zombie.location = (i * 2.5, 25, 0)
            link_to_collection(zombie, enemy_col)
            all_assets.append(zombie)
    else:
        # Fallback to basic zombies
        for i in range(5):
            zombie = enemy_gen.generate_humanoid(f"zombie_{i:02d}", "zombie", seed=i + 500)
            zombie.location = (i * 2, 25, 0)
            all_assets.append(zombie)
    
    # Raiders
    for i in range(3):
        raider = enemy_gen.generate_humanoid(f"raider_{i:02d}", "raider", seed=i + 1000)
        raider.location = (20 + i * 2, 25, 0)
        all_assets.append(raider)
    
    # Animals
    animal_types = ["wolf", "bear", "deer", "dog", "boar"]
    for i, atype in enumerate(animal_types):
        animal = enemy_gen.generate_animal(f"{atype}_00", atype, seed=i * 100)
        animal.location = (i * 3, 30, 0)
        link_to_collection(animal, enemy_col)
        all_assets.append(animal)
    
    print(f"  Created enemies and animals")
    
    # Generate Weapons (using detailed generator if available)
    print("\n[5/6] Generating Weapons...")
    if HAS_WEAPON_GEN:
        weapon_gen = WeaponGenerator()
        x_offset = 0
        
        # Melee
        for weapon_id in list(weapon_gen.MELEE_WEAPONS.keys())[:6]:
            weapon = weapon_gen.generate_melee(f"melee_{weapon_id}", weapon_id)
            weapon.location = (x_offset, 35, 0)
            link_to_collection(weapon, weapon_col)
            all_assets.append(weapon)
            x_offset += 1
        
        # Ranged
        for weapon_id in list(weapon_gen.RANGED_WEAPONS.keys())[:6]:
            weapon = weapon_gen.generate_ranged(f"ranged_{weapon_id}", weapon_id)
            weapon.location = (x_offset, 35, 0)
            link_to_collection(weapon, weapon_col)
            all_assets.append(weapon)
            x_offset += 1.2
        
        # Throwables
        for weapon_id in weapon_gen.THROWABLES.keys():
            weapon = weapon_gen.generate_throwable(f"throw_{weapon_id}", weapon_id)
            weapon.location = (x_offset, 35, 0)
            link_to_collection(weapon, weapon_col)
            all_assets.append(weapon)
            x_offset += 0.5
    
    print(f"  Created weapons")
    
    # Generate Buildings
    print("\n[6/6] Generating Buildings & Vehicles...")
    building_gen = BuildingGenerator(building_col)
    building_assets = building_gen.generate_all()
    all_assets.extend(building_assets)
    
    vehicle_gen = VehicleGenerator(vehicle_col)
    vehicle_assets = vehicle_gen.generate_all()
    all_assets.extend(vehicle_assets)
    print(f"  Created {len(building_assets)} building and {len(vehicle_assets)} vehicle objects")
    
    # Summary
    print("\n" + "=" * 60)
    print(f"GENERATION COMPLETE: {len(all_assets)} total assets")
    print("=" * 60)
    
    # Setup camera
    bpy.ops.object.camera_add(location=(25, -35, 25))
    camera = bpy.context.active_object
    camera.rotation_euler = (math.radians(55), 0, 0)
    bpy.context.scene.camera = camera
    
    return all_assets


if __name__ == "__main__":
    generate_all_assets()
