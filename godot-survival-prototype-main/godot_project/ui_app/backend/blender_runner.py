import time
import json
from pathlib import Path
from typing import Optional, List

from PyQt6.QtGui import QPixmap

from .config import (
    AUTO_GENERATE_SCRIPT,
    BLEND_FILE,
    BLENDER_EXECUTABLE,
    PREVIEW_PATH,
    LOG_PATH,
)

_last_log: str = ""
_last_error: str = ""
_last_consistency: dict | None = None
_last_turntable_frames: List[Path] = []
_last_turntable_gif: Path | None = None


def build_blender_command(prompt: str) -> list[str]:
    """Return the blender command to run in headless mode."""
    return [
        str(BLENDER_EXECUTABLE),
        str(BLEND_FILE),
        "-b",
        "--python",
        str(AUTO_GENERATE_SCRIPT),
        "--",
        prompt,
    ]


def record_log(log: str, err: str = "") -> None:
    """Store the latest log and error for UI display."""
    global _last_log, _last_error
    _last_log = log
    _last_error = err
    _write_log()


def _preview_updated(timeout: float = 2.0) -> bool:
    """Check if preview file exists and is recently modified."""
    if not PREVIEW_PATH.exists():
        return False
    mod_time = PREVIEW_PATH.stat().st_mtime
    now = time.time()
    return (now - mod_time) <= timeout


def get_preview_image() -> Optional[QPixmap]:
    if not PREVIEW_PATH.exists():
        return None
    pixmap = QPixmap(str(PREVIEW_PATH))
    return pixmap if not pixmap.isNull() else None


def get_log_output() -> str:
    return _last_log


def get_last_error() -> str:
    return _last_error or _last_log


def record_consistency(json_payload: str):
    global _last_consistency
    try:
        _last_consistency = json.loads(json_payload)
    except Exception:
        _last_consistency = None


def record_turntable_frames(frames: list[str]):
    global _last_turntable_frames
    _last_turntable_frames = [Path(f) for f in frames]


def get_consistency_info() -> dict | None:
    return _last_consistency


def get_turntable_frames() -> List[Path]:
    return _last_turntable_frames


def build_turntable_gif(output_path: Path) -> bool:
    if not _last_turntable_frames:
        return False
    try:
        from PIL import Image
    except ImportError:
        return False

    frames = []
    for p in _last_turntable_frames:
        if Path(p).exists():
            try:
                frames.append(Image.open(p))
            except Exception:
                continue
    if not frames:
        return False
    output_path.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        output_path,
        save_all=True,
        append_images=frames[1:],
        duration=80,
        loop=0,
        disposal=2,
    )
    global _last_turntable_gif
    _last_turntable_gif = output_path
    return True


def get_turntable_gif_path() -> Optional[Path]:
    return _last_turntable_gif


def parse_progress(line: str) -> int | None:
    """Extract percent from lines like 'Progress: 42%'."""
    line = line.strip()
    if line.lower().startswith("progress:"):
        try:
            pct = int("".join(ch for ch in line if ch.isdigit()))
            return max(0, min(100, pct))
        except ValueError:
            return None
    return None


def _write_log():
    try:
        LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        LOG_PATH.write_text(_last_log)
    except Exception:
        pass


__all__ = [
    "build_blender_command",
    "record_log",
    "get_preview_image",
    "get_log_output",
    "get_last_error",
    "parse_progress",
    "record_consistency",
    "record_turntable_frames",
    "get_consistency_info",
    "get_turntable_frames",
    "build_turntable_gif",
    "get_turntable_gif_path",
]
