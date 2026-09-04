"""
Enhanced Asset Generator - Uses detailed generators for high-quality models.
This script integrates the new detailed generators for characters, zombies,
trees, props, and weapons.

Run in Blender with: blender --background --python generate_enhanced_assets.py
"""

import bpy
import bmesh
import random
import math
import sys
import os
import json
from pathlib import Path
from mathutils import Vector

# Script directory
SCRIPT_DIR = Path(__file__).parent

# Add generators to path
sys.path.insert(0, str(SCRIPT_DIR / "generators"))

# Import our detailed generators
try:
    from detailed_character import DetailedCharacterGenerator
    from detailed_zombie import DetailedZombieGenerator
    from detailed_tree import DetailedTreeGenerator
    from detailed_prop import DetailedPropGenerator
    from detailed_weapon import DetailedWeaponGenerator
    # Import organic body generators (focus on human silhouette)
    from organic_body import OrganicBodyGenerator, OrganicZombieGenerator
    print("Successfully imported all detailed generators")
    USE_ORGANIC_BODY = True
except ImportError as e:
    print(f"Error importing generators: {e}")
    print(f"Current path: {sys.path}")
    USE_ORGANIC_BODY = False
    raise

# Blender version info
BLENDER_VERSION = bpy.app.version
print(f"Blender version: {BLENDER_VERSION[0]}.{BLENDER_VERSION[1]}.{BLENDER_VERSION[2]}")

# Export path
EXPORT_PATH = SCRIPT_DIR.parent / "assets" / "models"

# Seed for reproducible generation
random.seed(42)


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

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
    
    print("Scene cleared")


def get_or_create_collection(name: str, parent=None):
    """Get existing or create new collection."""
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        if parent is not None:
            parent.children.link(col)
        else:
            bpy.context.scene.collection.children.link(col)
    return col


def link_to_collection(obj, collection):
    """Link object to collection, unlinking from scene collection."""
    for col in obj.users_collection:
        col.objects.unlink(obj)
    collection.objects.link(obj)


def export_glb(obj, filepath: Path):
    """Export single object as GLB."""
    # Ensure directory exists
    filepath.parent.mkdir(parents=True, exist_ok=True)
    
    # Deselect all
    bpy.ops.object.select_all(action='DESELECT')
    
    # Select only this object
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Export
    bpy.ops.export_scene.gltf(
        filepath=str(filepath),
        export_format='GLB',
        use_selection=True,
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_colors=True,
        export_materials='EXPORT',
    )
    
    obj.select_set(False)
    print(f"  Exported: {filepath.name}")


def set_origin_to_bottom(obj):
    """Set origin to bottom center of object."""
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    
    mesh = obj.data
    if len(mesh.vertices) == 0:
        return
    
    min_z = min((obj.matrix_world @ v.co).z for v in mesh.vertices)
    
    bpy.context.scene.cursor.location = (0.0, 0.0, min_z)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    obj.location = (0.0, 0.0, 0.0)
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    
    obj.select_set(False)


# ============================================================================
# GENERATION FUNCTIONS
# ============================================================================

def generate_characters(collection):
    """Generate player/NPC character models."""
    print("\n=== Generating Characters ===")
    
    # Use organic body generator for proper human silhouette
    if USE_ORGANIC_BODY:
        generator = OrganicBodyGenerator(seed=42)
    else:
        generator = DetailedCharacterGenerator(seed=42)
    
    characters = [
        ("survivor_male", "survivor_male"),
        ("survivor_female", "survivor_female"),
        ("npc_trader", "npc_trader"),
        ("npc_mechanic", "npc_mechanic"),
        ("raider_scout", "raider_scout"),
        ("raider_heavy", "raider_heavy"),
    ]
    
    models = []
    for name, char_type in characters:
        print(f"  Creating character: {name}")
        obj = generator.generate(name, char_type)
        link_to_collection(obj, collection)
        models.append((name, obj))
    
    return models


def generate_zombies(collection):
    """Generate zombie enemy models."""
    print("\n=== Generating Zombies ===")
    
    # Use organic body zombie generator
    if USE_ORGANIC_BODY:
        generator = OrganicZombieGenerator(seed=42)
    else:
        generator = DetailedZombieGenerator(seed=42)
    
    zombies = [
        ("zombie_walker", "zombie_walker"),
        ("zombie_runner", "zombie_runner"),
        ("zombie_crawler", "zombie_crawler"),
        ("zombie_bloater", "zombie_bloater"),
        ("zombie_screamer", "zombie_screamer"),
        ("zombie_spitter", "zombie_spitter"),
        ("zombie_brute", "zombie_brute"),
        ("zombie_ravager", "zombie_ravager"),
    ]
    
    models = []
    for name, zombie_type in zombies:
        print(f"  Creating zombie: {name}")
        obj = generator.generate(name, zombie_type)
        link_to_collection(obj, collection)
        models.append((name, obj))
    
    return models


def generate_trees(collection):
    """Generate tree and environment vegetation."""
    print("\n=== Generating Trees ===")
    
    generator = DetailedTreeGenerator(seed=42)
    
    trees = [
        ("tree_pine_01", "pine_01"),
        ("tree_pine_02", "pine_02"),
        ("tree_pine_03", "pine_03"),
        ("tree_oak_01", "oak_01"),
        ("tree_oak_02", "oak_02"),
        ("tree_birch_01", "birch_01"),
        ("tree_dead_01", "dead_01"),
        ("tree_dead_02", "dead_02"),
        ("tree_palm_01", "palm_01"),
        ("tree_stump_01", "stump_01"),
    ]
    
    models = []
    for name, tree_type in trees:
        print(f"  Creating tree: {name}")
        obj = generator.generate(name, tree_type)
        link_to_collection(obj, collection)
        models.append((name, obj))
    
    return models


def generate_props(collection):
    """Generate prop and furniture models."""
    print("\n=== Generating Props ===")
    
    generator = DetailedPropGenerator(seed=42)
    
    props = [
        # Containers
        ("crate_wooden", "crate_wooden"),
        ("crate_military", "crate_military"),
        ("barrel_metal", "barrel_metal"),
        ("barrel_plastic", "barrel_plastic"),
        ("barrel_toxic", "barrel_toxic"),
        ("locker_metal", "locker_metal"),
        ("cardboard_box", "cardboard_box"),
        ("toolbox", "toolbox"),
        ("gas_can", "gas_can"),
        ("medkit", "medkit"),
        ("ammo_box", "ammo_box"),
        # Furniture
        ("table_wooden", "table_wooden"),
        ("chair_wooden", "chair_wooden"),
        ("chair_office", "chair_office"),
        ("bed_single", "bed_single"),
        ("shelf_wooden", "shelf_wooden"),
        ("workbench", "workbench"),
        # Infrastructure
        ("concrete_barrier", "concrete_barrier"),
        ("sandbag_wall", "sandbag_wall"),
        ("generator", "generator"),
        # Debris
        ("tire", "tire"),
        ("tire_stack", "tire_stack"),
        ("trash_bag", "trash_bag"),
        ("trash_pile", "trash_pile"),
    ]
    
    models = []
    for name, prop_type in props:
        print(f"  Creating prop: {name}")
        obj = generator.generate(name, prop_type)
        link_to_collection(obj, collection)
        models.append((name, obj))
    
    return models


def generate_weapons(collection):
    """Generate weapon models."""
    print("\n=== Generating Weapons ===")
    
    generator = DetailedWeaponGenerator(seed=42)
    
    weapons = [
        # Melee - Blunt
        ("bat_wooden", "bat_wooden"),
        ("bat_metal", "bat_metal"),
        ("pipe_iron", "pipe_iron"),
        ("hammer", "hammer"),
        ("sledgehammer", "sledgehammer"),
        ("crowbar", "crowbar"),
        # Melee - Bladed
        ("machete", "machete"),
        ("knife_combat", "knife_combat"),
        ("knife_survival", "knife_survival"),
        ("axe_hatchet", "axe_hatchet"),
        ("axe_fire", "axe_fire"),
        ("katana", "katana"),
        # Firearms
        ("pistol_9mm", "pistol_9mm"),
        ("pistol_45", "pistol_45"),
        ("revolver", "revolver"),
        ("rifle_assault", "rifle_assault"),
        ("rifle_bolt", "rifle_bolt"),
        ("shotgun_pump", "shotgun_pump"),
        ("shotgun_auto", "shotgun_auto"),
        ("smg", "smg"),
        # Throwables
        ("grenade_frag", "grenade_frag"),
        ("molotov", "molotov"),
        # Tools
        ("shovel", "shovel"),
        ("pickaxe", "pickaxe"),
    ]
    
    models = []
    for name, weapon_type in weapons:
        print(f"  Creating weapon: {name}")
        obj = generator.generate(name, weapon_type)
        link_to_collection(obj, collection)
        models.append((name, obj))
    
    return models


def generate_rocks(collection):
    """Generate rock models using built-in generator."""
    print("\n=== Generating Rocks ===")
    
    rocks = []
    rock_types = [
        ("rock_boulder_01", 2.0, "boulder"),
        ("rock_boulder_02", 2.5, "boulder"),
        ("rock_medium_01", 1.0, "medium"),
        ("rock_medium_02", 0.8, "medium"),
        ("rock_small_01", 0.4, "small"),
        ("rock_small_02", 0.3, "small"),
        ("rock_slab_01", 1.2, "slab"),
        ("rock_ore_iron", 0.8, "ore"),
        ("rock_ore_copper", 0.7, "ore"),
    ]
    
    for name, size, rock_type in rock_types:
        print(f"  Creating rock: {name}")
        obj = create_rock(name, size, rock_type)
        link_to_collection(obj, collection)
        rocks.append((name, obj))
    
    return rocks


def create_rock(name: str, size: float, rock_type: str) -> bpy.types.Object:
    """Create a rock model."""
    # Start with icosphere for organic shape
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=size / 2)
    rock = bpy.context.active_object
    rock.name = name
    
    # Deform for natural look
    bm = bmesh.new()
    bm.from_mesh(rock.data)
    
    for v in bm.verts:
        # Random displacement
        noise = random.uniform(-size * 0.15, size * 0.15)
        v.co += v.normal * noise
        
        # Flatten bottom if boulder
        if rock_type == "boulder" and v.co.z < -size * 0.2:
            v.co.z = -size * 0.25
        
        # Flatten for slab type
        if rock_type == "slab":
            v.co.z *= 0.3
            v.co.x *= 1.5
            v.co.y *= 1.5
    
    bm.to_mesh(rock.data)
    bm.free()
    
    # Create material
    mat = bpy.data.materials.new(name=f"mat_{name}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    
    if rock_type == "ore":
        # Metallic ore coloring
        if "iron" in name:
            bsdf.inputs["Base Color"].default_value = (0.35, 0.28, 0.25, 1.0)
        else:  # copper
            bsdf.inputs["Base Color"].default_value = (0.45, 0.35, 0.25, 1.0)
        bsdf.inputs["Metallic"].default_value = 0.3
    else:
        bsdf.inputs["Base Color"].default_value = (0.35, 0.33, 0.30, 1.0)
    
    bsdf.inputs["Roughness"].default_value = 0.9
    rock.data.materials.append(mat)
    
    set_origin_to_bottom(rock)
    
    return rock


def generate_bushes(collection):
    """Generate bush/shrub models."""
    print("\n=== Generating Bushes ===")
    
    bushes = []
    bush_types = [
        ("bush_green_01", 0.8, (0.15, 0.35, 0.12)),
        ("bush_green_02", 1.0, (0.18, 0.38, 0.15)),
        ("bush_berry_01", 0.7, (0.20, 0.30, 0.15)),
        ("bush_dead_01", 0.6, (0.25, 0.22, 0.18)),
        ("bush_flowering_01", 0.75, (0.20, 0.35, 0.18)),
    ]
    
    for name, size, color in bush_types:
        print(f"  Creating bush: {name}")
        obj = create_bush(name, size, color)
        link_to_collection(obj, collection)
        bushes.append((name, obj))
    
    return bushes


def create_bush(name: str, size: float, color: tuple) -> bpy.types.Object:
    """Create a bush model."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=size / 2)
    bush = bpy.context.active_object
    bush.name = name
    bush.scale = (1.2, 1.2, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    
    # Organic deformation
    bm = bmesh.new()
    bm.from_mesh(bush.data)
    
    for v in bm.verts:
        v.co += Vector((
            random.uniform(-size * 0.1, size * 0.1),
            random.uniform(-size * 0.1, size * 0.1),
            random.uniform(-size * 0.05, size * 0.05)
        ))
    
    bm.to_mesh(bush.data)
    bm.free()
    
    # Material
    mat = bpy.data.materials.new(name=f"mat_{name}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.8
    bush.data.materials.append(mat)
    
    # Add berries if berry bush
    if "berry" in name:
        add_berries(bush, size)
    
    set_origin_to_bottom(bush)
    
    return bush


def add_berries(bush: bpy.types.Object, size: float):
    """Add berry details to bush."""
    berry_mat = bpy.data.materials.new(name=f"mat_{bush.name}_berry")
    berry_mat.use_nodes = True
    berry_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.6, 0.1, 0.15, 1.0)
    
    for _ in range(8):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=size * 0.05)
        berry = bpy.context.active_object
        berry.location = (
            random.uniform(-size * 0.3, size * 0.3),
            random.uniform(-size * 0.3, size * 0.3),
            random.uniform(size * 0.1, size * 0.4)
        )
        berry.data.materials.append(berry_mat)
        
        bush.select_set(True)
        berry.select_set(True)
        bpy.context.view_layer.objects.active = bush
        bpy.ops.object.join()
        bush = bpy.context.active_object
        bpy.ops.object.select_all(action='DESELECT')


def generate_buildings(collection):
    """Generate building/structure models."""
    print("\n=== Generating Buildings ===")
    
    buildings = []
    building_types = [
        ("building_house_small", (6, 5, 3)),
        ("building_house_medium", (8, 7, 3.5)),
        ("building_bunker", (5, 5, 2.5)),
        ("building_watchtower", (3, 3, 8)),
        ("building_shed", (3, 2.5, 2.5)),
        ("building_garage", (5, 6, 3)),
        ("building_store", (8, 6, 4)),
        ("building_warehouse", (12, 8, 5)),
    ]
    
    for name, size in building_types:
        print(f"  Creating building: {name}")
        obj = create_building(name, size)
        link_to_collection(obj, collection)
        buildings.append((name, obj))
    
    return buildings


def create_building(name: str, size: tuple) -> bpy.types.Object:
    """Create a simple building structure."""
    width, depth, height = size
    parts = []
    
    # Wall material
    wall_mat = bpy.data.materials.new(name=f"mat_{name}_wall")
    wall_mat.use_nodes = True
    wall_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.6, 0.58, 0.55, 1.0)
    wall_mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    
    # Roof material
    roof_mat = bpy.data.materials.new(name=f"mat_{name}_roof")
    roof_mat.use_nodes = True
    roof_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.3, 0.25, 0.22, 1.0)
    
    # Main structure
    bpy.ops.mesh.primitive_cube_add(size=1)
    base = bpy.context.active_object
    base.scale = (width / 2, depth / 2, height / 2)
    base.location.z = height / 2
    bpy.ops.object.transform_apply(scale=True)
    base.data.materials.append(wall_mat)
    parts.append(base)
    
    # Roof (simple peaked or flat)
    if "tower" not in name and "bunker" not in name:
        bpy.ops.mesh.primitive_cube_add(size=1)
        roof = bpy.context.active_object
        roof.scale = (width / 2 + 0.3, depth / 2 + 0.3, 0.2)
        roof.location.z = height + 0.1
        bpy.ops.object.transform_apply(scale=True)
        
        # Add pitch to roof
        bm = bmesh.new()
        bm.from_mesh(roof.data)
        for v in bm.verts:
            if v.co.z > 0:
                v.co.z += 0.5 - abs(v.co.y) * 0.3
        bm.to_mesh(roof.data)
        bm.free()
        
        roof.data.materials.append(roof_mat)
        parts.append(roof)
    
    # Door opening
    bpy.ops.mesh.primitive_cube_add(size=1)
    door = bpy.context.active_object
    door.scale = (0.1, 0.5, 1.0)
    door.location = (width / 2 + 0.1, 0, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    
    door_mat = bpy.data.materials.new(name=f"mat_{name}_door")
    door_mat.use_nodes = True
    door_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.25, 0.18, 0.12, 1.0)
    door.data.materials.append(door_mat)
    parts.append(door)
    
    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    building = bpy.context.active_object
    building.name = name
    
    set_origin_to_bottom(building)
    
    return building


def generate_vehicles(collection):
    """Generate vehicle models."""
    print("\n=== Generating Vehicles ===")
    
    vehicles = []
    vehicle_types = [
        ("vehicle_car_sedan", (4.5, 1.8, 1.4)),
        ("vehicle_car_suv", (4.8, 2.0, 1.8)),
        ("vehicle_truck_pickup", (5.2, 2.0, 1.8)),
        ("vehicle_motorcycle", (2.2, 0.8, 1.2)),
        ("vehicle_atv", (2.0, 1.2, 1.1)),
        ("vehicle_boat", (4.0, 1.8, 1.0)),
    ]
    
    for name, size in vehicle_types:
        print(f"  Creating vehicle: {name}")
        obj = create_vehicle(name, size)
        link_to_collection(obj, collection)
        vehicles.append((name, obj))
    
    return vehicles


def create_vehicle(name: str, size: tuple) -> bpy.types.Object:
    """Create a basic vehicle shape."""
    length, width, height = size
    parts = []
    
    # Body material
    body_mat = bpy.data.materials.new(name=f"mat_{name}_body")
    body_mat.use_nodes = True
    body_color = (random.uniform(0.2, 0.6), random.uniform(0.2, 0.5), random.uniform(0.2, 0.5), 1.0)
    body_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = body_color
    body_mat.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.8
    body_mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.3
    
    if "motorcycle" in name or "atv" in name:
        # Simple motorcycle/ATV shape
        bpy.ops.mesh.primitive_cube_add(size=1)
        body = bpy.context.active_object
        body.scale = (length / 2, width / 2, height / 3)
        body.location.z = height / 2
        bpy.ops.object.transform_apply(scale=True)
        body.data.materials.append(body_mat)
        parts.append(body)
        
        # Wheels
        for x in [length * 0.35, -length * 0.35]:
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=height * 0.3, depth=width * 0.2)
            wheel = bpy.context.active_object
            wheel.rotation_euler.x = math.radians(90)
            wheel.location = (x, 0, height * 0.3)
            
            wheel_mat = bpy.data.materials.new(name=f"mat_{name}_wheel")
            wheel_mat.use_nodes = True
            wheel_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.05, 0.05, 1.0)
            wheel.data.materials.append(wheel_mat)
            parts.append(wheel)
    
    elif "boat" in name:
        # Simple boat hull
        bpy.ops.mesh.primitive_cube_add(size=1)
        hull = bpy.context.active_object
        hull.scale = (length / 2, width / 2, height / 2)
        hull.location.z = height / 2
        bpy.ops.object.transform_apply(scale=True)
        
        # Taper bow
        bm = bmesh.new()
        bm.from_mesh(hull.data)
        for v in bm.verts:
            if v.co.x > length * 0.2:
                factor = (v.co.x - length * 0.2) / (length * 0.3)
                v.co.y *= 1 - factor * 0.6
                v.co.z *= 1 - factor * 0.3
        bm.to_mesh(hull.data)
        bm.free()
        
        hull.data.materials.append(body_mat)
        parts.append(hull)
    
    else:
        # Car/truck shape
        # Lower body
        bpy.ops.mesh.primitive_cube_add(size=1)
        lower = bpy.context.active_object
        lower.scale = (length / 2, width / 2, height * 0.35)
        lower.location.z = height * 0.35
        bpy.ops.object.transform_apply(scale=True)
        lower.data.materials.append(body_mat)
        parts.append(lower)
        
        # Cabin
        cabin_length = length * 0.5 if "truck" in name else length * 0.6
        bpy.ops.mesh.primitive_cube_add(size=1)
        cabin = bpy.context.active_object
        cabin.scale = (cabin_length / 2, width / 2 - 0.1, height * 0.35)
        cabin.location = (-length * 0.1, 0, height * 0.7)
        bpy.ops.object.transform_apply(scale=True)
        
        cabin_mat = bpy.data.materials.new(name=f"mat_{name}_cabin")
        cabin_mat.use_nodes = True
        cabin_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.1, 0.1, 0.12, 1.0)
        cabin_mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.1
        cabin.data.materials.append(cabin_mat)
        parts.append(cabin)
        
        # Wheels
        wheel_positions = [
            (length * 0.35, width * 0.45),
            (length * 0.35, -width * 0.45),
            (-length * 0.35, width * 0.45),
            (-length * 0.35, -width * 0.45),
        ]
        for x, y in wheel_positions:
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=height * 0.25, depth=0.2)
            wheel = bpy.context.active_object
            wheel.rotation_euler.x = math.radians(90)
            wheel.location = (x, y, height * 0.25)
            
            wheel_mat = bpy.data.materials.new(name=f"mat_{name}_wheel")
            wheel_mat.use_nodes = True
            wheel_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.05, 0.05, 1.0)
            wheel.data.materials.append(wheel_mat)
            parts.append(wheel)
    
    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    vehicle = bpy.context.active_object
    vehicle.name = name
    
    set_origin_to_bottom(vehicle)
    
    return vehicle


# ============================================================================
# MAIN GENERATION
# ============================================================================

def generate_all_assets():
    """Generate all game assets."""
    print("\n" + "=" * 60)
    print("ENHANCED ASSET GENERATION PIPELINE")
    print("=" * 60)
    
    clear_scene()
    
    # Create collections
    main_col = get_or_create_collection("GameAssets")
    char_col = get_or_create_collection("Characters", main_col)
    enemy_col = get_or_create_collection("Enemies", main_col)
    env_col = get_or_create_collection("Environment", main_col)
    prop_col = get_or_create_collection("Props", main_col)
    weapon_col = get_or_create_collection("Weapons", main_col)
    building_col = get_or_create_collection("Buildings", main_col)
    vehicle_col = get_or_create_collection("Vehicles", main_col)
    
    all_models = []
    
    # Generate all categories
    all_models.extend(generate_characters(char_col))
    all_models.extend(generate_zombies(enemy_col))
    all_models.extend(generate_trees(env_col))
    all_models.extend(generate_rocks(env_col))
    all_models.extend(generate_bushes(env_col))
    all_models.extend(generate_props(prop_col))
    all_models.extend(generate_weapons(weapon_col))
    all_models.extend(generate_buildings(building_col))
    all_models.extend(generate_vehicles(vehicle_col))
    
    print(f"\n=== Generated {len(all_models)} models total ===")
    
    return all_models


def export_all_assets(models: list):
    """Export all generated models to GLB files."""
    print("\n" + "=" * 60)
    print("EXPORTING ASSETS")
    print("=" * 60)
    
    EXPORT_PATH.mkdir(parents=True, exist_ok=True)
    
    manifest = {
        "version": "2.0",
        "generator": "enhanced_asset_generator",
        "models": {}
    }
    
    # Category subdirectories
    categories = {
        "survivor": "characters",
        "npc": "characters",
        "raider": "characters",
        "zombie": "enemies",
        "tree": "environment",
        "rock": "environment",
        "bush": "environment",
        "building": "buildings",
        "vehicle": "vehicles",
    }
    
    for name, obj in models:
        # Determine category
        category = "props"  # default
        for prefix, cat in categories.items():
            if name.startswith(prefix):
                category = cat
                break
        
        # Check for weapons
        weapon_prefixes = ["bat_", "pipe_", "hammer", "sledge", "crowbar", "machete", 
                         "knife_", "axe_", "katana", "pistol", "revolver", "rifle_",
                         "shotgun", "smg", "grenade", "molotov", "shovel", "pickaxe"]
        for prefix in weapon_prefixes:
            if name.startswith(prefix):
                category = "weapons"
                break
        
        # Export path
        category_path = EXPORT_PATH / category
        filepath = category_path / f"{name}.glb"
        
        export_glb(obj, filepath)
        
        manifest["models"][name] = {
            "path": f"res://assets/models/{category}/{name}.glb",
            "category": category
        }
    
    # Save manifest
    manifest_path = EXPORT_PATH / "manifest.json"
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    print(f"\nManifest saved: {manifest_path}")
    
    # Generate Godot resource file
    generate_godot_database(manifest)
    
    print(f"\n=== Exported {len(models)} models to {EXPORT_PATH} ===")


def generate_godot_database(manifest: dict):
    """Generate a Godot resource file for easy asset loading."""
    tres_content = '[gd_resource type="Resource" script_class="ModelDatabase" format=3]\n\n'
    tres_content += '[resource]\n'
    tres_content += 'script = ExtResource("res://scripts/resources/ModelDatabase.gd")\n'
    
    # Add model paths
    for name, data in manifest["models"].items():
        safe_name = name.replace("-", "_")
        tres_content += f'{safe_name} = "{data["path"]}"\n'
    
    tres_path = EXPORT_PATH / "model_database.tres"
    with open(tres_path, 'w') as f:
        f.write(tres_content)
    print(f"Godot database saved: {tres_path}")


def save_blend_file():
    """Save the current scene as a .blend file."""
    blend_path = SCRIPT_DIR / "enhanced_assets.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    print(f"\nBlend file saved: {blend_path}")


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    print("\nStarting Enhanced Asset Generation...")
    
    # Generate all assets
    models = generate_all_assets()
    
    # Export to GLB
    export_all_assets(models)
    
    # Save blend file
    save_blend_file()
    
    print("\n" + "=" * 60)
    print("GENERATION COMPLETE!")
    print("=" * 60)
