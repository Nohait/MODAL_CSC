"""
Combined Generate and Export Script
Generates all game assets and exports them to GLB format for Godot.
"""

import bpy
import json
import os
import sys
from pathlib import Path
from datetime import datetime

# Add this directory to path for imports
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))

# Import the generation function
from generate_master_assets import generate_all_assets

# Paths
OUTPUT_DIR = SCRIPT_DIR / "exports"
GODOT_ASSETS = SCRIPT_DIR.parent / "assets" / "models"
BLEND_FILE = SCRIPT_DIR / "generated_assets.blend"


def ensure_directories():
    """Create output directories."""
    directories = [
        OUTPUT_DIR,
        OUTPUT_DIR / "environment",
        OUTPUT_DIR / "props",
        OUTPUT_DIR / "characters",
        OUTPUT_DIR / "enemies",
        OUTPUT_DIR / "weapons",
        OUTPUT_DIR / "buildings",
        OUTPUT_DIR / "vehicles",
        OUTPUT_DIR / "armor",
        GODOT_ASSETS,
        GODOT_ASSETS / "environment",
        GODOT_ASSETS / "props", 
        GODOT_ASSETS / "characters",
        GODOT_ASSETS / "enemies",
        GODOT_ASSETS / "weapons",
        GODOT_ASSETS / "buildings",
        GODOT_ASSETS / "vehicles",
        GODOT_ASSETS / "armor",
    ]
    
    for dir_path in directories:
        dir_path.mkdir(parents=True, exist_ok=True)
    
    print(f"Output directories ready at {OUTPUT_DIR}")


def get_category_for_object(obj_name):
    """Determine category from object name."""
    name_lower = obj_name.lower()
    
    if any(x in name_lower for x in ["tree", "rock", "bush", "grass", "ground"]):
        return "environment"
    elif any(x in name_lower for x in ["crate", "barrel", "campfire", "container", "chest", "table", "chair", "bed", "workbench", "fence", "fire"]):
        return "props"
    elif any(x in name_lower for x in ["survivor", "npc", "player"]):
        return "characters"
    elif any(x in name_lower for x in ["zombie", "raider", "wolf", "bear", "deer", "dog", "boar", "enemy"]):
        return "enemies"
    elif any(x in name_lower for x in ["melee", "ranged", "throw", "gun", "sword", "axe", "knife", "bow", "pistol", "rifle", "bat", "crowbar", "machete", "spear", "sledgehammer", "pipe"]):
        return "weapons"
    elif any(x in name_lower for x in ["wall", "floor", "door", "roof", "window", "foundation", "storage"]):
        return "buildings"
    elif any(x in name_lower for x in ["vehicle", "car", "truck", "motorcycle", "atv", "boat", "helicopter"]):
        return "vehicles"
    elif any(x in name_lower for x in ["helmet", "armor", "vest", "gloves", "boots", "backpack"]):
        return "armor"
    else:
        return "props"  # Default to props instead of misc


def export_object(obj, category):
    """Export single object to GLB."""
    # Deselect all
    bpy.ops.object.select_all(action='DESELECT')
    
    # Select target object
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Store original location
    original_location = obj.location.copy()
    
    # Move to origin for export (already done by set_origin_to_bottom, but ensure it)
    obj.location = (0, 0, 0)
    
    # Export paths
    export_path = OUTPUT_DIR / category / f"{obj.name}.glb"
    godot_path = GODOT_ASSETS / category / f"{obj.name}.glb"
    
    # GLTF export settings optimized for Godot
    export_settings = {
        'filepath': str(export_path),
        'use_selection': True,
        'export_format': 'GLB',
        'export_apply': True,  # Apply modifiers
        'export_yup': True,  # Y-up for Godot
        'export_texcoords': True,
        'export_normals': True,
        'export_materials': 'EXPORT',
        'export_colors': True,
        'export_cameras': False,
        'export_lights': False,
        'export_extras': True,
        'use_active_collection': False,
    }
    
    try:
        bpy.ops.export_scene.gltf(**export_settings)
        
        # Copy to Godot assets folder
        import shutil
        shutil.copy2(export_path, godot_path)
        
        return True, str(export_path)
    except Exception as e:
        return False, str(e)
    finally:
        # Restore original location
        obj.location = original_location
        obj.select_set(False)


def export_all_assets():
    """Export all assets in the scene."""
    ensure_directories()
    
    print("\n" + "=" * 60)
    print("EXPORTING ASSETS TO GLB")
    print("=" * 60)
    
    manifest = {
        "version": "1.0",
        "generated": datetime.now().isoformat(),
        "categories": {},
        "assets": []
    }
    
    export_count = 0
    error_count = 0
    
    # Get all mesh objects (not camera, light, etc.)
    mesh_objects = [obj for obj in bpy.data.objects if obj.type == 'MESH']
    
    print(f"\nFound {len(mesh_objects)} mesh objects to export\n")
    
    for i, obj in enumerate(mesh_objects):
        category = get_category_for_object(obj.name)
        
        # Initialize category in manifest
        if category not in manifest["categories"]:
            manifest["categories"][category] = []
        
        # Export
        success, result = export_object(obj, category)
        
        if success:
            print(f"[{i+1}/{len(mesh_objects)}] ✓ {obj.name} -> {category}/")
            
            asset_entry = {
                "name": obj.name,
                "category": category,
                "file": f"{category}/{obj.name}.glb",
                "godot_path": f"res://assets/models/{category}/{obj.name}.glb",
                "bounds": {
                    "x": round(obj.dimensions.x, 3),
                    "y": round(obj.dimensions.y, 3),
                    "z": round(obj.dimensions.z, 3)
                }
            }
            manifest["assets"].append(asset_entry)
            manifest["categories"][category].append(obj.name)
            export_count += 1
        else:
            print(f"[{i+1}/{len(mesh_objects)}] ✗ FAILED: {obj.name} - {result}")
            error_count += 1
    
    # Write manifest
    manifest_path = GODOT_ASSETS / "manifest.json"
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    # Create Godot resource file
    create_model_database()
    
    # Summary
    print("\n" + "=" * 60)
    print(f"EXPORT COMPLETE")
    print(f"  Success: {export_count}")
    print(f"  Failed:  {error_count}")
    print(f"\nAssets exported to:")
    print(f"  {GODOT_ASSETS}")
    print("=" * 60)
    
    return manifest


def create_model_database():
    """Create a Godot resource file that lists all models."""
    manifest_path = GODOT_ASSETS / "manifest.json"
    
    if not manifest_path.exists():
        return
    
    with open(manifest_path, 'r') as f:
        manifest = json.load(f)
    
    # Create a simple .tres file
    tres_content = """[gd_resource type="Resource" format=3]

[resource]
"""
    
    tres_path = GODOT_ASSETS / "model_database.tres"
    with open(tres_path, 'w') as f:
        f.write(tres_content)
    
    print(f"Created model database at {tres_path}")


def main():
    """Main entry point - generate and export all assets."""
    print("=" * 60)
    print("GODOT SURVIVAL PROTOTYPE - FULL ASSET PIPELINE")
    print("=" * 60)
    
    # Step 1: Generate all assets
    print("\n[STEP 1] Generating assets...")
    all_assets = generate_all_assets()
    
    # Step 2: Save blend file
    print("\n[STEP 2] Saving blend file...")
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
    print(f"  Saved to: {BLEND_FILE}")
    
    # Step 3: Export all assets
    print("\n[STEP 3] Exporting to GLB...")
    export_all_assets()
    
    print("\n" + "=" * 60)
    print("PIPELINE COMPLETE!")
    print("=" * 60)


if __name__ == "__main__":
    main()
