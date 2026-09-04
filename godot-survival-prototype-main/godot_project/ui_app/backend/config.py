import os
from pathlib import Path

# Auto-detect Blender executable (Windows default path, override via env if needed)
BLENDER_EXECUTABLE = Path(
    os.environ.get("BLENDER_EXECUTABLE", r"C:\Program Files\Blender Foundation\Blender 4.0\blender.exe")
)

# Project root is the parent of this file's parent (ui_app/backend/ -> ui_app/)
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

BLEND_FILE = PROJECT_ROOT / "blender_pipeline" / "render_assets.blend"
AUTO_GENERATE_SCRIPT = PROJECT_ROOT / "blender_pipeline" / "auto_generate_asset.py"
PREVIEW_PATH = PROJECT_ROOT / "blender_pipeline" / "renders" / "preview.png"
FINAL_ASSETS_PATH = PROJECT_ROOT / "blender_pipeline" / "final_assets"
LOG_PATH = PROJECT_ROOT / "ui_app" / "ui_app.log"


def verify_paths():
    """Check that expected paths exist; print warnings if not."""
    paths = {
        "BLENDER_EXECUTABLE": BLENDER_EXECUTABLE,
        "BLEND_FILE": BLEND_FILE,
        "AUTO_GENERATE_SCRIPT": AUTO_GENERATE_SCRIPT,
        "PREVIEW_PATH": PREVIEW_PATH,
        "FINAL_ASSETS_PATH": FINAL_ASSETS_PATH,
    }

    for name, path in paths.items():
        if not Path(path).exists():
            print(f"[WARN] {name} not found at {path}")
        else:
            print(f"[OK] {name}: {path}")


__all__ = [
    "BLENDER_EXECUTABLE",
    "BLEND_FILE",
    "AUTO_GENERATE_SCRIPT",
    "PREVIEW_PATH",
    "FINAL_ASSETS_PATH",
    "LOG_PATH",
    "verify_paths",
]
