import subprocess
import sys
from pathlib import Path


def main():
    root = Path(__file__).resolve().parent
    spec_file = root / "AXC.spec"
    dist_dir = root / "dist" / "AXC_Asset_Generator"
    dist_dir.parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--clean",
        "--noconfirm",
        str(spec_file),
    ]
    print("Running:", " ".join(cmd))
    try:
        subprocess.check_call(cmd, cwd=root)
        print(f"Build complete. Output at {dist_dir}")
    except subprocess.CalledProcessError as exc:
        print(f"Build failed: {exc}")
        sys.exit(exc.returncode)


if __name__ == "__main__":
    main()
