import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(__file__))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

"""Command-line helper to drive auto_generate_asset.py via Blender."""

import os
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent
BLEND_FILE = PROJECT_ROOT / "render_assets.blend"
AUTO_SCRIPT = PROJECT_ROOT / "auto_generate_asset.py"
PREVIEW_PATH = PROJECT_ROOT / "renders" / "preview.png"


def _run_blender(prompt: str) -> int:
    """Invoke Blender in background to generate the asset once (auto-accept)."""
    cmd = [
        "blender",
        str(BLEND_FILE),
        "-b",
        "-P",
        str(AUTO_SCRIPT),
        "--",
        prompt,
    ]
    # Send "accept" to auto_generate_asset.py so it exits after one loop.
    proc = subprocess.run(cmd, input="accept\n".encode(), stdout=sys.stdout, stderr=sys.stderr)
    return proc.returncode


def _show_preview():
    if not PREVIEW_PATH.exists():
        print(f"Preview not found at {PREVIEW_PATH}")
        return
    print(f"Preview saved to: {PREVIEW_PATH}")
    opener = None
    if os.name == "posix":
        opener = "xdg-open" if sys.platform != "darwin" else "open"
    elif os.name == "nt":
        opener = "start"

    if opener:
        try:
            subprocess.run([opener, str(PREVIEW_PATH)], check=False)
        except Exception:
            pass


def main():
    prompt = input("Describe the asset you want to generate: ").strip()
    if not prompt:
        print("No prompt provided, exiting.")
        return

    while True:
        code = _run_blender(prompt)
        if code != 0:
            print(f"Blender exited with code {code}.")
            return
        _show_preview()

        choice = input("Accept, tweak, or regenerate? ").strip().lower()
        if choice.startswith("a"):
            print("Asset accepted.")
            break
        if choice.startswith("t"):
            tweak = input("What needs adjusting? ").strip()
            if tweak:
                prompt = f"{prompt} {tweak}"
            continue
        if choice.startswith("r"):
            prompt = prompt  # keep same prompt, new run will randomize inside Blender
            continue

        print("Please respond with Accept, Tweak, or Regenerate.")


if __name__ == "__main__":
    main()
