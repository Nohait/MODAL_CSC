import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(__file__))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import math
from pathlib import Path

import bpy

# Where to save sprites (relative to this .blend file)
OUT_DIR = Path(bpy.path.abspath("//renders"))

# Which asset collections to render
ASSET_COLLECTIONS = [
    # Environment
    "Ground",
    "Trees",
    "Rocks",
    "Bushes",
    "Props",
    "Ruins",
    "Buildings",
    
    # Containers
    "Crates",
    "Containers",
    
    # Characters
    "Characters",
    "Wildlife",
    
    # Enemies
    "Zombies",
    "ZombieVariants",
    "Raiders",
    "Animals",
    "Bosses",
    
    # Weapons
    "MeleeWeapons",
    "RangedWeapons",
    "Throwables",
    
    # Armor & Equipment
    "Helmets",
    "BodyArmor",
    "Gloves",
    "Boots",
    "Backpacks",
    
    # Items
    "Consumables",
    "Materials",
    "Ammo",
    "Tools",
]

MODE_SETTINGS = {
    "preview": {"resolution": 512, "samples": 16},
    "final": {"resolution": 1024, "samples": 64},
}


def ensure_out_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def get_assets_root():
    """Return the Assets collection if it exists, else None."""
    return bpy.data.collections.get("Assets")


def get_subcollection(name):
    assets = get_assets_root()
    if assets:
        for child in assets.children:
            if child.name == name:
                return child
    # fallback: global collection with that name
    return bpy.data.collections.get(name)


def get_all_meshes():
    return [obj for obj in bpy.data.objects if obj.type == "MESH"]


def _get_or_create_camera() -> bpy.types.Object:
    cam = bpy.data.objects.get("RenderCam")
    if cam and cam.type == "CAMERA":
        return cam
    bpy.ops.object.camera_add(location=(6.0, -6.0, 6.0))
    cam = bpy.context.active_object
    cam.name = "RenderCam"
    return cam


def _setup_isometric_camera(cam: bpy.types.Object) -> None:
    cam.data.type = "ORTHO"
    cam.location = (6.0, -6.0, 6.0)
    cam.rotation_euler = (math.radians(60), 0.0, math.radians(45))


def _frame_object(cam: bpy.types.Object, obj: bpy.types.Object, padding: float = 1.4) -> None:
    dims = obj.dimensions
    max_dim = max(dims.x, dims.y, dims.z)
    cam.data.ortho_scale = max_dim * padding


def _configure_render(mode: str) -> None:
    settings = MODE_SETTINGS.get(mode, MODE_SETTINGS["preview"])
    scene = bpy.context.scene
    scene.render.resolution_x = settings["resolution"]
    scene.render.resolution_y = settings["resolution"]
    if scene.render.engine == "CYCLES":
        scene.cycles.samples = settings["samples"]


def _get_versioned_filepath(base_dir: Path, base_name: str) -> Path:
    ensure_out_dir(base_dir)
    version = 1
    while True:
        candidate = base_dir / f"{base_name}_v{version:03d}.png"
        if not candidate.exists():
            return candidate
        version += 1


def _hide_all_meshes(except_obj: bpy.types.Object | None = None):
    for obj in get_all_meshes():
        obj.hide_render = True
    if except_obj:
        except_obj.hide_render = False


def render_object(obj: bpy.types.Object, asset_type: str, mode: str = "preview") -> Path:
    cam = _get_or_create_camera()
    _setup_isometric_camera(cam)
    _frame_object(cam, obj)
    _configure_render(mode)

    _hide_all_meshes(except_obj=obj)
    obj.location = (0.0, 0.0, 0.0)

    out_dir = OUT_DIR / asset_type
    ensure_out_dir(out_dir)
    filepath = _get_versioned_filepath(out_dir, obj.name)

    scene = bpy.context.scene
    scene.camera = cam
    scene.render.filepath = str(filepath)
    bpy.ops.render.render(write_still=True)
    return filepath


def render_collection(col, mode: str = "preview"):
    if col is None:
        print("Collection is None, skipping")
        return

    meshes = [obj for obj in col.objects if obj.type == "MESH"]
    if not meshes:
        print(f"No mesh objects found in collection {col.name}.")
        return

    print(f"Rendering collection: {col.name}")
    for obj in meshes:
        print(f"  -> {obj.name}")
        filepath = render_object(obj, asset_type=col.name, mode=mode)
        print(f"     saved to {filepath}")


def main(mode: str = "preview"):
    mode = mode.lower()
    if mode not in MODE_SETTINGS:
        mode = "preview"

    for name in ASSET_COLLECTIONS:
        col = get_subcollection(name)
        if col is None:
            print(f"Collection '{name}' not found, skipping.")
        else:
            render_collection(col, mode=mode)

    print(f"Rendering finished in {mode} mode.")


if __name__ == "__main__":
    # Accept optional mode argument when running as a script
    import sys

    mode_arg = "preview"
    if "--" in sys.argv:
        try:
            mode_arg = sys.argv[sys.argv.index("--") + 1]
        except IndexError:
            mode_arg = "preview"
    elif len(sys.argv) > 1:
        mode_arg = sys.argv[1]

    main(mode=mode_arg)
