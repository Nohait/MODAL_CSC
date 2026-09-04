"""
Complete Export Pipeline - Export all generated assets to GLTF/GLB for Godot.
Runs after generate_master_assets.py
"""

import bpy
import json
import os
from pathlib import Path
from datetime import datetime

# Paths
SCRIPT_DIR = Path(__file__).parent
OUTPUT_DIR = SCRIPT_DIR / "exports"
GODOT_ASSETS = SCRIPT_DIR.parent / "assets" / "models"


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
        GODOT_ASSETS,
        GODOT_ASSETS / "environment",
        GODOT_ASSETS / "props", 
        GODOT_ASSETS / "characters",
        GODOT_ASSETS / "enemies",
        GODOT_ASSETS / "weapons",
        GODOT_ASSETS / "buildings",
        GODOT_ASSETS / "vehicles",
    ]
    
    for dir_path in directories:
        dir_path.mkdir(parents=True, exist_ok=True)
    
    print(f"Output directories created at {OUTPUT_DIR}")


def get_category_for_object(obj_name):
    """Determine category from object name."""
    name_lower = obj_name.lower()
    
    if any(x in name_lower for x in ["tree", "rock", "bush", "grass"]):
        return "environment"
    elif any(x in name_lower for x in ["crate", "barrel", "campfire", "container", "chest"]):
        return "props"
    elif any(x in name_lower for x in ["survivor", "npc", "player"]):
        return "characters"
    elif any(x in name_lower for x in ["zombie", "raider", "wolf", "bear", "deer", "dog", "boar", "enemy"]):
        return "enemies"
    elif any(x in name_lower for x in ["weapon", "melee", "ranged", "throw", "gun", "sword", "axe", "knife", "bow", "pistol", "rifle"]):
        return "weapons"
    elif any(x in name_lower for x in ["wall", "floor", "door", "roof", "window", "foundation"]):
        return "buildings"
    elif any(x in name_lower for x in ["vehicle", "car", "truck", "motorcycle", "atv", "boat", "helicopter"]):
        return "vehicles"
    else:
        return "misc"


def export_object(obj, category, use_glb=True):
    """Export single object to GLTF/GLB."""
    # Deselect all
    bpy.ops.object.select_all(action='DESELECT')
    
    # Select target object
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Determine file extension
    ext = ".glb" if use_glb else ".gltf"
    
    # Export paths
    export_path = OUTPUT_DIR / category / (obj.name + ext)
    godot_path = GODOT_ASSETS / category / (obj.name + ext)
    
    # GLTF export settings optimized for Godot
    export_settings = {
        'filepath': str(export_path),
        'use_selection': True,
        'export_format': 'GLB' if use_glb else 'GLTF_SEPARATE',
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


def export_all_assets():
    """Export all assets in the scene."""
    ensure_directories()
    
    print("=" * 60)
    print("EXPORTING ASSETS TO GLTF")
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
            print(f"[{i+1}/{len(mesh_objects)}] Exported: {obj.name} -> {category}/")
            
            asset_entry = {
                "name": obj.name,
                "category": category,
                "file": f"{category}/{obj.name}.glb",
                "godot_path": f"res://assets/models/{category}/{obj.name}.glb",
                "bounds": {
                    "x": obj.dimensions.x,
                    "y": obj.dimensions.y,
                    "z": obj.dimensions.z
                }
            }
            manifest["assets"].append(asset_entry)
            manifest["categories"][category].append(obj.name)
            export_count += 1
        else:
            print(f"[{i+1}/{len(mesh_objects)}] FAILED: {obj.name} - {result}")
            error_count += 1
    
    # Write manifest
    manifest_path = OUTPUT_DIR / "manifest.json"
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    # Also copy to Godot assets
    godot_manifest = GODOT_ASSETS / "manifest.json"
    with open(godot_manifest, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    # Summary
    print("\n" + "=" * 60)
    print(f"EXPORT COMPLETE")
    print(f"  Success: {export_count}")
    print(f"  Failed:  {error_count}")
    print(f"  Manifest: {manifest_path}")
    print("=" * 60)
    
    return manifest


def create_godot_resources():
    """Create .tres resource files for Godot to easily load models."""
    manifest_path = GODOT_ASSETS / "manifest.json"
    
    if not manifest_path.exists():
        print("Manifest not found. Run export_all_assets() first.")
        return
    
    with open(manifest_path, 'r') as f:
        manifest = json.load(f)
    
    # Create model database resource
    database_content = """[gd_resource type="Resource" script_class="ModelDatabase" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ModelDatabase.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
"""
    
    # Categories loader
    categories_data = {}
    for asset in manifest["assets"]:
        cat = asset["category"]
        if cat not in categories_data:
            categories_data[cat] = []
        categories_data[cat].append({
            "name": asset["name"],
            "path": asset["godot_path"]
        })
    
    # Save database
    database_path = GODOT_ASSETS / "model_database.tres"
    with open(database_path, 'w') as f:
        f.write(database_content)
    
    print(f"Created Godot resources at {GODOT_ASSETS}")


if __name__ == "__main__":
    export_all_assets()
    create_godot_resources()
