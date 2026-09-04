"""
Stylized Asset Generation Master Script
========================================
Generates all game assets using the new stylized low-poly approach.
Run with: blender --background --python generate_stylized_assets.py
"""

import bpy
import os
import sys
import math
from pathlib import Path

# Add generators directory to path
script_dir = os.path.dirname(os.path.abspath(__file__))
generators_dir = os.path.join(script_dir, "generators")
sys.path.insert(0, generators_dir)

from stylized_character import StylizedCharacterGenerator
from stylized_tree import StylizedTreeGenerator
from stylized_prop import StylizedPropGenerator

# Local baking utility
sys.path.insert(0, script_dir)
from texture_baker import bake_albedo_ao_and_assign

# Output directory
OUTPUT_DIR = os.path.join(script_dir, "..", "assets", "models")
TEXTURE_DIR = os.path.join(script_dir, "..", "assets", "textures")

def ensure_output_dirs():
    """Create output directories if they don't exist."""
    categories = ['characters', 'enemies', 'trees', 'props', 'weapons', 'resources', 'buildings']
    for cat in categories:
        path = os.path.join(OUTPUT_DIR, cat)
        os.makedirs(path, exist_ok=True)
    return OUTPUT_DIR


def bake_textures(obj: bpy.types.Object, category: str, name: str, wear_profile: str = "generic") -> None:
    """Bake PBR textures and assign baked material for consistency."""
    out_dir = Path(TEXTURE_DIR) / category
    blood = 0.35 if wear_profile == "zombie" else 0.0
    bake_albedo_ao_and_assign(
        obj,
        texture_dir=out_dir,
        name_prefix=name,
        resolution=512,
        samples=48,
        bake_roughness=True,
        bake_metallic=False,
        pack_orm=True,
        wear_profile=wear_profile,
        wear_strength=0.35,
        blood_strength=blood,
    )

def clear_scene():
    """Clear all objects from the scene."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def export_glb(obj, filepath):
    """Export object as GLB."""
    # Select only this object
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Export
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        use_selection=True,
        export_format='GLB',
        export_apply=True
    )
    print(f"  Exported: {os.path.basename(filepath)}")

def generate_characters(output_dir):
    """Generate all character models."""
    print("\n=== Generating Characters ===")
    
    characters = [
        ('survivor_male', 'survivor_male', 1.8),
        ('survivor_female', 'survivor_female', 1.7),
        ('survivor_male_2', 'survivor_male', 1.85),
        ('survivor_female_2', 'survivor_female', 1.65),
    ]
    
    for name, char_type, height in characters:
        clear_scene()
        gen = StylizedCharacterGenerator(height=height, character_type=char_type)
        obj = gen.generate(name)
        bake_textures(obj, 'characters', name, wear_profile='survivor')

        filepath = os.path.join(output_dir, 'characters', f'{name}.glb')
        export_glb(obj, filepath)

def generate_enemies(output_dir):
    """Generate all enemy models."""
    print("\n=== Generating Enemies ===")
    
    enemies = [
        # Regular zombies
        ('zombie_walker', 'zombie', 1.75),
        ('zombie_walker_2', 'zombie', 1.80),
        ('zombie_walker_3', 'zombie', 1.70),
        # Fast zombies
        ('zombie_runner', 'zombie_runner', 1.65),
        ('zombie_runner_2', 'zombie_runner', 1.70),
        # Brutes
        ('zombie_brute', 'zombie_brute', 2.2),
        ('zombie_brute_large', 'zombie_brute', 2.5),
    ]
    
    for name, char_type, height in enemies:
        clear_scene()
        gen = StylizedCharacterGenerator(height=height, character_type=char_type)
        obj = gen.generate(name)
        bake_textures(obj, 'enemies', name, wear_profile='zombie')

        filepath = os.path.join(output_dir, 'enemies', f'{name}.glb')
        export_glb(obj, filepath)

def generate_trees(output_dir):
    """Generate all tree models."""
    print("\n=== Generating Trees ===")
    
    trees = [
        # Oak trees (various sizes)
        ('tree_oak_small', 'oak', 0.7),
        ('tree_oak_medium', 'oak', 1.0),
        ('tree_oak_large', 'oak', 1.3),
        ('tree_oak_xl', 'oak', 1.6),
        # Pine trees
        ('tree_pine_small', 'pine', 0.8),
        ('tree_pine_medium', 'pine', 1.0),
        ('tree_pine_large', 'pine', 1.4),
        ('tree_pine_xl', 'pine', 1.8),
        # Birch trees
        ('tree_birch_small', 'birch', 0.8),
        ('tree_birch_medium', 'birch', 1.0),
        ('tree_birch_large', 'birch', 1.3),
        # Dead trees
        ('tree_dead_1', 'dead', 0.9),
        ('tree_dead_2', 'dead', 1.1),
        ('tree_dead_3', 'dead', 0.7),
        # Bushes
        ('bush_small', 'bush', 0.7),
        ('bush_medium', 'bush', 1.0),
        ('bush_large', 'bush', 1.3),
        ('bush_berry', 'bush', 0.9),
    ]
    
    seed = 1000
    for name, tree_type, scale in trees:
        clear_scene()
        gen = StylizedTreeGenerator(tree_type=tree_type, scale=scale, seed=seed)
        obj = gen.generate(name)
        bake_textures(obj, 'trees', name, wear_profile='environment')

        filepath = os.path.join(output_dir, 'trees', f'{name}.glb')
        export_glb(obj, filepath)
        seed += 1

def generate_weapons(output_dir):
    """Generate all weapon models."""
    print("\n=== Generating Weapons ===")
    
    weapons = [
        # Melee
        'hatchet', 'pickaxe', 'machete', 'baseball_bat', 
        'crowbar', 'knife', 'spear',
        # Ranged
        'bow', 'crossbow',
    ]
    
    for weapon in weapons:
        clear_scene()
        gen = StylizedPropGenerator(weapon)
        obj = gen.generate(weapon)
        bake_textures(obj, 'weapons', weapon, wear_profile='prop')

        filepath = os.path.join(output_dir, 'weapons', f'{weapon}.glb')
        export_glb(obj, filepath)

def generate_tools(output_dir):
    """Generate tool models (separate from weapons)."""
    print("\n=== Generating Tools ===")
    
    tools = ['hammer', 'shovel', 'wrench']
    
    for tool in tools:
        clear_scene()
        gen = StylizedPropGenerator(tool)
        obj = gen.generate(tool)
        bake_textures(obj, 'props', tool, wear_profile='prop')

        filepath = os.path.join(output_dir, 'props', f'{tool}.glb')
        export_glb(obj, filepath)

def generate_resources(output_dir):
    """Generate resource/loot models."""
    print("\n=== Generating Resources ===")
    
    resources = [
        'wood_log', 'wood_plank', 'stone', 'iron_ore', 'fiber_bundle'
    ]
    
    for resource in resources:
        clear_scene()
        gen = StylizedPropGenerator(resource)
        obj = gen.generate(resource)
        bake_textures(obj, 'resources', resource, wear_profile='prop')

        filepath = os.path.join(output_dir, 'resources', f'{resource}.glb')
        export_glb(obj, filepath)

def generate_props(output_dir):
    """Generate props and containers."""
    print("\n=== Generating Props ===")
    
    props = ['crate', 'barrel', 'chest', 'backpack']
    
    for prop in props:
        clear_scene()
        gen = StylizedPropGenerator(prop)
        obj = gen.generate(prop)
        bake_textures(obj, 'props', prop, wear_profile='prop')

        filepath = os.path.join(output_dir, 'props', f'{prop}.glb')
        export_glb(obj, filepath)

def generate_rocks(output_dir):
    """Generate rock variants."""
    print("\n=== Generating Rocks ===")
    
    # Create multiple rock variants with different seeds
    import random
    
    for i in range(5):
        clear_scene()
        random.seed(i * 100)
        gen = StylizedPropGenerator('stone')
        obj = gen.generate(f'rock_variant_{i+1}')
        
        # Vary the scale
        scale = 0.8 + (i * 0.2)
        obj.scale = (scale, scale, scale * 0.8)
        bpy.ops.object.transform_apply(scale=True)
        bake_textures(obj, 'props', f'rock_variant_{i+1}', wear_profile='environment')

        filepath = os.path.join(output_dir, 'props', f'rock_variant_{i+1}.glb')
        export_glb(obj, filepath)

def generate_buildings(output_dir):
    """Generate simple building structures."""
    print("\n=== Generating Buildings ===")
    
    # Simple wall segment
    clear_scene()
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.5))
    wall = bpy.context.active_object
    wall.scale = (2.0, 0.15, 3.0)
    bpy.ops.object.transform_apply(scale=True)
    
    mat = bpy.data.materials.new(name="wall_wood")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.45, 0.32, 0.18, 1.0)
    wall.data.materials.append(mat)
    wall.name = "wall_wood"
    
    bake_textures(wall, 'buildings', 'wall_wood', wear_profile='environment')
    filepath = os.path.join(output_dir, 'buildings', 'wall_wood.glb')
    export_glb(wall, filepath)
    
    # Simple floor
    clear_scene()
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.1))
    floor = bpy.context.active_object
    floor.scale = (2.0, 2.0, 0.2)
    bpy.ops.object.transform_apply(scale=True)
    
    mat = bpy.data.materials.new(name="floor_wood")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.50, 0.38, 0.22, 1.0)
    floor.data.materials.append(mat)
    floor.name = "floor_wood"
    
    bake_textures(floor, 'buildings', 'floor_wood', wear_profile='environment')
    filepath = os.path.join(output_dir, 'buildings', 'floor_wood.glb')
    export_glb(floor, filepath)
    
    # Door frame
    clear_scene()
    parts = []
    
    # Left post
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.55, 0, 1.1))
    left = bpy.context.active_object
    left.scale = (0.1, 0.15, 2.2)
    bpy.ops.object.transform_apply(scale=True)
    parts.append(left)
    
    # Right post
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.55, 0, 1.1))
    right = bpy.context.active_object
    right.scale = (0.1, 0.15, 2.2)
    bpy.ops.object.transform_apply(scale=True)
    parts.append(right)
    
    # Top beam
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2.25))
    top = bpy.context.active_object
    top.scale = (1.2, 0.15, 0.1)
    bpy.ops.object.transform_apply(scale=True)
    parts.append(top)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    
    door_frame = bpy.context.active_object
    door_frame.name = "door_frame"
    
    mat = bpy.data.materials.new(name="frame_wood")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.40, 0.28, 0.15, 1.0)
    door_frame.data.materials.append(mat)
    
    bake_textures(door_frame, 'buildings', 'door_frame', wear_profile='environment')
    filepath = os.path.join(output_dir, 'buildings', 'door_frame.glb')
    export_glb(door_frame, filepath)

def main():
    """Main generation function."""
    print("=" * 50)
    print("STYLIZED ASSET GENERATION")
    print("=" * 50)
    
    output_dir = ensure_output_dirs()
    print(f"Output directory: {output_dir}")
    
    # Generate all categories
    generate_characters(output_dir)
    generate_enemies(output_dir)
    generate_trees(output_dir)
    generate_weapons(output_dir)
    generate_tools(output_dir)
    generate_resources(output_dir)
    generate_props(output_dir)
    generate_rocks(output_dir)
    generate_buildings(output_dir)
    
    print("\n" + "=" * 50)
    print("GENERATION COMPLETE!")
    print("=" * 50)
    
    # Count exported files
    total = 0
    for root, dirs, files in os.walk(output_dir):
        total += len([f for f in files if f.endswith('.glb')])
    print(f"Total models exported: {total}")

if __name__ == "__main__":
    main()
