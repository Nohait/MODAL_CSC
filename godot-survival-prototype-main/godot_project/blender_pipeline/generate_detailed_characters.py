"""
Generate Detailed Characters
============================
Generates high-quality humanoid characters with proper anatomy.
Run with: blender --background --python generate_detailed_characters.py
"""

import bpy
import os
import sys

from pathlib import Path

# Add generators directory to path
script_dir = os.path.dirname(os.path.abspath(__file__))
generators_dir = os.path.join(script_dir, "generators")
sys.path.insert(0, generators_dir)

from detailed_humanoid import DetailedHumanoidGenerator

# Local utilities
sys.path.insert(0, script_dir)
from texture_baker import bake_albedo_ao_and_assign

# Output directory
OUTPUT_DIR = os.path.join(script_dir, "..", "assets", "models")
TEXTURE_DIR = os.path.join(script_dir, "..", "assets", "textures")

def ensure_output_dirs():
    """Create output directories."""
    for cat in ['characters', 'enemies']:
        path = os.path.join(OUTPUT_DIR, cat)
        os.makedirs(path, exist_ok=True)
    return OUTPUT_DIR

def clear_scene():
    """Clear all objects."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    # Clear orphan data
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)

def export_glb(obj, filepath):
    """Export object as GLB."""
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        use_selection=True,
        export_format='GLB',
        export_apply=True
    )
    print(f"  Exported: {os.path.basename(filepath)}")


def bake_textures_for(obj, category: str, name: str) -> None:
    """Bake PBR maps and assign a baked material with wear overlays."""
    out_dir = Path(TEXTURE_DIR) / category
    wear_profile = "zombie" if category == "enemies" else "survivor"
    blood_strength = 0.4 if category == "enemies" else 0.0
    bake_albedo_ao_and_assign(
        obj,
        texture_dir=out_dir,
        name_prefix=name,
        resolution=512,
        samples=64,
        bake_roughness=True,
        bake_metallic=False,
        pack_orm=True,
        wear_profile=wear_profile,
        wear_strength=0.4,
        blood_strength=blood_strength,
    )

def generate_survivors(output_dir):
    """Generate survivor character models."""
    print("\n=== Generating Survivor Characters ===")
    
    survivors = [
        # Male survivors with variations
        ('survivor_male_1', 'survivor_male'),
        ('survivor_male_2', 'survivor_male'),
        ('survivor_male_3', 'survivor_male'),
        # Female survivors
        ('survivor_female_1', 'survivor_female'),
        ('survivor_female_2', 'survivor_female'),
        ('survivor_female_3', 'survivor_female'),
    ]
    
    for name, variant in survivors:
        clear_scene()
        gen = DetailedHumanoidGenerator(variant)
        obj = gen.generate(name)

        bake_textures_for(obj, "characters", name)
        
        filepath = os.path.join(output_dir, 'characters', f'{name}.glb')
        export_glb(obj, filepath)

def generate_zombies(output_dir):
    """Generate zombie enemy models."""
    print("\n=== Generating Zombie Enemies ===")
    
    zombies = [
        # Common walkers
        ('zombie_walker_1', 'zombie_common'),
        ('zombie_walker_2', 'zombie_common'),
        ('zombie_walker_3', 'zombie_common'),
        ('zombie_walker_4', 'zombie_common'),
        ('zombie_walker_5', 'zombie_common'),
        # Runners
        ('zombie_runner_1', 'zombie_runner'),
        ('zombie_runner_2', 'zombie_runner'),
        ('zombie_runner_3', 'zombie_runner'),
        # Brutes
        ('zombie_brute_1', 'zombie_brute'),
        ('zombie_brute_2', 'zombie_brute'),
        # Bloated
        ('zombie_bloated_1', 'zombie_bloated'),
        ('zombie_bloated_2', 'zombie_bloated'),
    ]
    
    for name, variant in zombies:
        clear_scene()
        gen = DetailedHumanoidGenerator(variant)
        obj = gen.generate(name)

        bake_textures_for(obj, "enemies", name)
        
        filepath = os.path.join(output_dir, 'enemies', f'{name}.glb')
        export_glb(obj, filepath)

def main():
    """Main generation function."""
    print("=" * 50)
    print("DETAILED CHARACTER GENERATION")
    print("=" * 50)
    
    output_dir = ensure_output_dirs()
    print(f"Output: {output_dir}")
    
    generate_survivors(output_dir)
    generate_zombies(output_dir)
    
    print("\n" + "=" * 50)
    print("CHARACTER GENERATION COMPLETE!")
    print("=" * 50)

if __name__ == "__main__":
    main()
