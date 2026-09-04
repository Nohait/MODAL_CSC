import os
import subprocess
import sys
from pathlib import Path

from backend.config import BLENDER_EXECUTABLE, PREVIEW_PATH, PROJECT_ROOT


def install_deps():
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "PyQt6"])
    except subprocess.CalledProcessError as exc:
        print(f"[WARN] Failed to install PyQt6: {exc}")


def verify_blender():
    if not Path(BLENDER_EXECUTABLE).exists():
        print(f"[WARN] Blender executable not found at {BLENDER_EXECUTABLE}")
    else:
        try:
            subprocess.check_call([str(BLENDER_EXECUTABLE), "-v"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("[OK] Blender executable reachable")
        except Exception as exc:
            print(f"[WARN] Blender check failed: {exc}")


def ensure_placeholder():
    if PREVIEW_PATH.exists():
        return
    placeholder = PROJECT_ROOT / "ui_app" / "assets" / "preview_placeholder.png"
    if not placeholder.exists():
        return
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    try:
        import shutil

        shutil.copy2(placeholder, PREVIEW_PATH)
        print(f"[OK] Copied placeholder preview to {PREVIEW_PATH}")
    except Exception as exc:
        print(f"[WARN] Could not copy placeholder: {exc}")


def main():
    install_deps()
    verify_blender()
    ensure_placeholder()
    print("UI App Setup Complete")


if __name__ == "__main__":
    main()
