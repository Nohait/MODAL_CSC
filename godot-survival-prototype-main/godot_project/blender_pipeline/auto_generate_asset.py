import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(__file__))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

"""AI-driven procedural asset generator and preview renderer with human-in-the-loop review."""

import json
import random
import re
import sys
from pathlib import Path
from typing import Dict, Optional, Tuple

import bpy
from blender_pipeline.procedural.generators import registry
from blender_pipeline.procedural.texture_generator import generate_texture


PROJECT_ROOT = Path(__file__).resolve().parent
RENDER_BLEND = PROJECT_ROOT / "render_assets.blend"
RENDER_OUTPUT = PROJECT_ROOT / "renders" / "preview.png"
FINAL_ASSETS_ROOT = PROJECT_ROOT / "final_assets"
METADATA_FILE = FINAL_ASSETS_ROOT / "metadata.json"


def _load_render_file() -> None:
    """Ensure the render_assets.blend file is loaded."""
    if Path(bpy.data.filepath).resolve() == RENDER_BLEND:
        return
    bpy.ops.wm.open_mainfile(filepath=str(RENDER_BLEND))


def _ensure_camera() -> bpy.types.Object:
    """Guarantee a simple camera focused on origin for preview renders."""
    cam = bpy.data.objects.get("Camera")
    if cam is None or cam.type != "CAMERA":
        bpy.ops.object.camera_add(location=(4.0, -4.0, 3.0), rotation=(1.1, 0.0, 0.8))
        cam = bpy.context.active_object
        cam.name = "Camera"
    return cam


def _ensure_light() -> None:
    """Provide a basic sun light if missing."""
    sun = bpy.data.objects.get("Sun")
    if sun is None or sun.type != "LIGHT":
        bpy.ops.object.light_add(type="SUN", location=(5.0, -5.0, 6.0))
        sun = bpy.context.active_object
        sun.name = "Sun"
    sun.rotation_euler = (0.8, -0.2, 0.6)


def _parse_color(prompt: str) -> Tuple[float, float, float, float]:
    """Extract a color from hex or simple words; default to neutral gray."""
    match = re.search(r"#?([0-9a-fA-F]{6})", prompt)
    if match:
        hex_val = match.group(1)
        rgb = tuple(int(hex_val[i : i + 2], 16) / 255 for i in (0, 2, 4))
        return (*rgb, 1.0)

    words = {
        "green": (0.1, 0.35, 0.12, 1.0),
        "brown": (0.35, 0.24, 0.12, 1.0),
        "gray": (0.4, 0.4, 0.4, 1.0),
        "grey": (0.4, 0.4, 0.4, 1.0),
        "red": (0.5, 0.1, 0.1, 1.0),
        "blue": (0.1, 0.2, 0.5, 1.0),
        "yellow": (0.45, 0.4, 0.1, 1.0),
    }
    lowered = prompt.lower()
    for key, val in words.items():
        if key in lowered:
            return val
    return 0.3, 0.3, 0.3, 1.0


def _maybe_color(prompt: str) -> Optional[Tuple[float, float, float, float]]:
    try_val = _parse_color(prompt)
    # If parse_color returned default gray and no color keyword, treat as None
    if try_val == (0.3, 0.3, 0.3, 1.0) and not re.search(r"#?[0-9a-fA-F]{6}", prompt):
        color_words = ("green", "brown", "gray", "grey", "red", "blue", "yellow")
        if not any(word in prompt.lower() for word in color_words):
            return None
    return try_val


def _parse_size(prompt: str) -> float:
    match = re.search(r"(?:size|scale|big|small|large|tiny)\s*(\d*\.?\d+)", prompt, re.IGNORECASE)
    if match:
        try:
            return max(0.2, float(match.group(1)))
        except ValueError:
            pass

    lowered = prompt.lower()
    if "tiny" in lowered or "small" in lowered:
        return 0.6
    if "large" in lowered or "big" in lowered or "huge" in lowered:
        return 1.4
    return 1.0


def _maybe_size(prompt: str) -> Optional[float]:
    match = re.search(r"(?:size|scale|big|small|large|tiny)\s*(\d*\.?\d+)", prompt, re.IGNORECASE)
    if match:
        try:
            return max(0.2, float(match.group(1)))
        except ValueError:
            return None
    lowered = prompt.lower()
    if any(word in lowered for word in ("tiny", "small", "large", "big", "huge")):
        return _parse_size(prompt)
    return None


def _parse_damage(prompt: str) -> float:
    lowered = prompt.lower()
    damage_words = [
        "broken",
        "damaged",
        "ruined",
        "battered",
        "cracked",
        "rusty",
        "worn",
    ]
    score = sum(word in lowered for word in damage_words)
    if score == 0:
        return 0.0
    return min(1.0, 0.2 * score)


def _maybe_damage(prompt: str) -> Optional[float]:
    lowered = prompt.lower()
    keywords = ("broken", "damaged", "ruined", "battered", "cracked", "rusty", "worn")
    if any(word in lowered for word in keywords):
        return _parse_damage(prompt)
    return None


def _parse_style(prompt: str) -> float:
    """Translate style intent into variation factor."""
    lowered = prompt.lower()
    if "clean" in lowered or "simple" in lowered:
        return 0.8
    if "chaotic" in lowered or "wild" in lowered:
        return 1.3
    if "stylized" in lowered or "ldoe" in lowered:
        return 1.0
    return 1.0


def _maybe_style(prompt: str) -> Optional[float]:
    lowered = prompt.lower()
    if any(word in lowered for word in ("clean", "simple", "chaotic", "wild", "stylized", "ldoe")):
        return _parse_style(prompt)
    return None


def _detect_asset_type(prompt: str) -> str:
    """Pick the best-matching asset type using registry listings."""
    prompt_low = prompt.lower()
    available = registry.list_generators()
    for asset in available:
        if asset in prompt_low:
            return asset

    tokens = re.findall(r"[a-z]+", prompt_low)
    scores: Dict[str, int] = {}
    for asset in available:
        scores[asset] = sum(asset in t or t in asset for t in tokens)
    best = max(scores, key=scores.get) if scores else None
    if best and scores[best] > 0:
        return best
    raise ValueError(f"Could not detect asset type from prompt: '{prompt}'")


def _detect_texture_style(prompt: str) -> Optional[str]:
    styles = {
        "cracked concrete": ["cracked concrete", "concrete", "crack"],
        "rusty metal": ["rust", "rusty metal", "corroded"],
        "jungle leaves": ["jungle", "leaf", "leaves", "foliage"],
        "hazard stripes": ["hazard", "stripe", "striped"],
        "chipped paint": ["chipped paint", "peeling", "flaky"],
    }
    lowered = prompt.lower()
    for style, keys in styles.items():
        if any(k in lowered for k in keys):
            return style
    return None


def _apply_texture(obj: bpy.types.Object, texture_path: str) -> None:
    if obj.type != "MESH":
        return

    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    if obj.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.uv.smart_project(angle_limit=66)
    bpy.ops.object.mode_set(mode="OBJECT")

    for slot in obj.material_slots:
        mat = slot.material
        if mat is None:
            continue
        if not mat.use_nodes:
            mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")
        if bsdf is None:
            bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        img_node = nodes.new("ShaderNodeTexImage")
        img_node.image = bpy.data.images.load(texture_path, check_existing=True)
        links.new(img_node.outputs["Color"], bsdf.inputs["Base Color"])
        out = nodes.get("Material Output")
        if out is None:
            out = nodes.new("ShaderNodeOutputMaterial")
        links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])


def _render_preview() -> None:
    _ensure_light()
    cam = _ensure_camera()
    bpy.context.scene.camera = cam

    RENDER_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.scene.render.filepath = str(RENDER_OUTPUT)
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)


def _save_asset_copy(asset_type: str, obj_name: str, params: Dict, prompt: str) -> Path:
    dest_dir = FINAL_ASSETS_ROOT / asset_type
    dest_dir.mkdir(parents=True, exist_ok=True)
    blend_path = dest_dir / f"{obj_name}.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), copy=True)
    _append_metadata(asset_type, obj_name, blend_path, params, prompt)
    return blend_path


def _append_metadata(asset_type: str, obj_name: str, blend_path: Path, params: Dict, prompt: str) -> None:
    METADATA_FILE.parent.mkdir(parents=True, exist_ok=True)
    data = []
    if METADATA_FILE.exists():
        try:
            data = json.loads(METADATA_FILE.read_text())
        except Exception:
            data = []

    entry = {
        "asset_type": asset_type,
        "name": obj_name,
        "blend_path": str(blend_path),
        "preview": str(RENDER_OUTPUT),
        "params": params,
        "prompt": prompt,
        "texture": params.get("texture_path"),
    }
    data.append(entry)
    METADATA_FILE.write_text(json.dumps(data, indent=2))


def _update_params_from_text(params: Dict, text: str) -> Dict:
    updated = dict(params)
    size_val = _maybe_size(text)
    color_val = _maybe_color(text)
    damage_val = _maybe_damage(text)
    style_val = _maybe_style(text)
    texture_style = _detect_texture_style(text)

    if size_val is not None:
        updated["size"] = size_val
    if color_val is not None:
        updated["color"] = color_val
    if damage_val is not None:
        updated["damage_level"] = damage_val
    if style_val is not None:
        updated["variation"] = style_val
    if texture_style:
        updated["texture_style"] = texture_style
        updated["texture_path"] = generate_texture(texture_style, updated.get("seed"))
    return updated


def _generate_asset(asset_type: str, params: Dict):
    generator = registry.get_generator(asset_type)
    return generator.generate(**params)


def generate_from_prompt(prompt: str):
    """Main entry: parse prompt, generate asset, and loop for user review."""
    _load_render_file()

    asset_type = _detect_asset_type(prompt)
    texture_style = _detect_texture_style(prompt)
    params: Dict = {
        "seed": random.randint(0, 999999),
        "size": _parse_size(prompt),
        "variation": _parse_style(prompt),
        "color": _parse_color(prompt),
        "damage_level": _parse_damage(prompt),
    }
    if texture_style:
        params["texture_style"] = texture_style
        params["texture_path"] = generate_texture(texture_style, params["seed"])

    while True:
        obj = _generate_asset(asset_type, params)
        if params.get("texture_path"):
            _apply_texture(obj, params["texture_path"])
        _render_preview()
        print("Generated asset:", obj.name)
        print(f"Preview saved to: {RENDER_OUTPUT}")
        choice = input("Accept, tweak, or regenerate? ").strip().lower()

        if choice.startswith("a"):
            saved_path = _save_asset_copy(asset_type, obj.name, params, prompt)
            print(f"Saved to: {saved_path}")
            break
        if choice.startswith("t"):
            tweak_text = input("What needs adjusting? ").strip()
            params = _update_params_from_text(params, tweak_text)
            continue
        if choice.startswith("r"):
            params["seed"] = random.randint(0, 999999)
            if params.get("texture_style"):
                params["texture_path"] = generate_texture(params["texture_style"], params["seed"])
            continue

        print("Please respond with Accept, Tweak, or Regenerate.")


def _main():
    args = sys.argv
    if "--" in args:
        prompt_parts = args[args.index("--") + 1 :]
    else:
        prompt_parts = args[1:]
    prompt = " ".join(prompt_parts).strip()
    if not prompt:
        prompt = "low poly tree"
    generate_from_prompt(prompt)


if __name__ == "__main__":
    _main()
