"""
Export Blender assets to Godot-compatible GLTF format.
Run this after generating assets with generate_survival_assets.py
"""

import bpy
import os
from pathlib import Path

# Configuration
SCRIPT_DIR = Path(__file__).parent
OUTPUT_DIR = SCRIPT_DIR.parent / "assets" / "models"


def ensure_directory(path):
    """Create directory if it doesn't exist."""
    Path(path).mkdir(parents=True, exist_ok=True)


def get_export_settings():
    """Get optimal GLTF export settings for Godot."""
    return {
        'export_format': 'GLB',
        'export_copyright': 'Godot Survival Prototype',
        'export_image_format': 'AUTO',
        'export_texture_dir': '',
        'export_texcoords': True,
        'export_normals': True,
        'export_tangents': True,
        'export_materials': 'EXPORT',
        'export_original_specular': False,
        'export_colors': True,
        'export_attributes': True,
        'use_mesh_edges': False,
        'use_mesh_vertices': False,
        'export_cameras': False,
        'use_selection': True,
        'use_visible': True,
        'use_renderable': True,
        'use_active_collection': False,
        'export_extras': False,
        'export_yup': True,  # Godot uses Y-up
        'export_apply': True,  # Apply modifiers
        'export_animations': False,  # Static assets
        'export_skins': False,
        'export_morph': False,
        'export_lights': False,
    }


def export_object(obj, output_path, settings):
    """Export a single object to GLTF."""
    # Store original location
    original_location = obj.location.copy()
    
    # Move to origin for export
    obj.location = (0, 0, 0)
    
    # Select only this object
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Export
    filepath = str(output_path / f"{obj.name}.glb")
    
    try:
        bpy.ops.export_scene.gltf(
            filepath=filepath,
            **settings
        )
        success = True
    except Exception as e:
        print(f"    ERROR exporting {obj.name}: {e}")
        success = False
    
    # Restore original location
    obj.location = original_location
    obj.select_set(False)
    
    return success


def export_collection(collection, output_path, settings):
    """Export all objects in a collection."""
    col_path = output_path / collection.name.lower()
    ensure_directory(col_path)
    
    exported = 0
    failed = 0
    
    for obj in collection.objects:
        if obj.type == 'MESH':
            if export_object(obj, col_path, settings):
                exported += 1
                print(f"    ✓ {obj.name}")
            else:
                failed += 1
    
    return exported, failed


def export_all_game_assets():
    """Export all game assets organized by category."""
    print("=" * 60)
    print("EXPORTING ASSETS TO GODOT")
    print("=" * 60)
    print(f"\nOutput directory: {OUTPUT_DIR}")
    
    ensure_directory(OUTPUT_DIR)
    settings = get_export_settings()
    
    # Find GameAssets collection
    game_assets = bpy.data.collections.get("GameAssets")
    
    if game_assets is None:
        print("ERROR: GameAssets collection not found!")
        print("Please run generate_survival_assets.py first.")
        return
    
    total_exported = 0
    total_failed = 0
    
    # Export each sub-collection
    for child_col in game_assets.children:
        print(f"\n[{child_col.name}]")
        exported, failed = export_collection(child_col, OUTPUT_DIR, settings)
        total_exported += exported
        total_failed += failed
        print(f"  Exported: {exported}, Failed: {failed}")
    
    print("\n" + "=" * 60)
    print(f"EXPORT COMPLETE")
    print(f"Total Exported: {total_exported}")
    print(f"Total Failed: {total_failed}")
    print(f"Output: {OUTPUT_DIR}")
    print("=" * 60)
    
    # Create import manifest for Godot
    create_import_manifest(OUTPUT_DIR)


def create_import_manifest(output_path):
    """Create a manifest file listing all exported assets."""
    manifest_path = output_path / "manifest.json"
    
    import json
    
    manifest = {
        "version": "1.0",
        "generator": "Godot Survival Prototype Asset Pipeline",
        "categories": {}
    }
    
    for category_dir in output_path.iterdir():
        if category_dir.is_dir():
            assets = []
            for asset_file in category_dir.glob("*.glb"):
                assets.append({
                    "name": asset_file.stem,
                    "file": f"{category_dir.name}/{asset_file.name}",
                    "type": "mesh"
                })
            if assets:
                manifest["categories"][category_dir.name] = assets
    
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    print(f"\nManifest created: {manifest_path}")


def export_single_asset(asset_name, output_path=None):
    """Export a single asset by name."""
    if output_path is None:
        output_path = OUTPUT_DIR
    
    output_path = Path(output_path)
    ensure_directory(output_path)
    
    obj = bpy.data.objects.get(asset_name)
    if obj is None:
        print(f"ERROR: Object '{asset_name}' not found")
        return False
    
    settings = get_export_settings()
    
    if export_object(obj, output_path, settings):
        print(f"Exported: {asset_name}.glb")
        return True
    return False


def export_category(category_name, output_path=None):
    """Export all assets in a specific category."""
    if output_path is None:
        output_path = OUTPUT_DIR
    
    output_path = Path(output_path)
    
    collection = bpy.data.collections.get(category_name)
    if collection is None:
        print(f"ERROR: Collection '{category_name}' not found")
        return
    
    settings = get_export_settings()
    exported, failed = export_collection(collection, output_path, settings)
    print(f"Exported: {exported}, Failed: {failed}")


# ============================================================================
# ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    export_all_game_assets()
