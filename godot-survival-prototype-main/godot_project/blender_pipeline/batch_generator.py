"""
Batch Asset Generator - Automatically generates all game assets with minimal input
Uses the asset manifest to systematically create all required assets
"""

import sys
import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import json
import time
import hashlib
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from concurrent.futures import ThreadPoolExecutor, as_completed
import subprocess

try:
    import bpy
    IN_BLENDER = True
except ImportError:
    IN_BLENDER = False

from blender_pipeline.asset_manifest import (
    AssetManifest,
    AssetSpec,
    AssetCategory,
    AssetQuality,
    GeneratedAsset
)


@dataclass
class GenerationConfig:
    """Configuration for batch generation"""
    output_dir: Path = Path("renders")
    quality: AssetQuality = AssetQuality.PREVIEW
    parallel_jobs: int = 1  # Blender doesn't like parallel well
    resume_from: Optional[str] = None
    categories_filter: Optional[List[AssetCategory]] = None
    priority_filter: Optional[int] = None
    overwrite_existing: bool = False
    generate_variations: bool = True
    generate_damage_states: bool = True
    export_godot: bool = True
    
    # Render settings by quality
    quality_settings: Dict = None
    
    def __post_init__(self):
        if self.quality_settings is None:
            self.quality_settings = {
                AssetQuality.PLACEHOLDER: {"resolution": 64, "samples": 1},
                AssetQuality.DRAFT: {"resolution": 128, "samples": 4},
                AssetQuality.PREVIEW: {"resolution": 256, "samples": 16},
                AssetQuality.PRODUCTION: {"resolution": 512, "samples": 64},
                AssetQuality.POLISHED: {"resolution": 1024, "samples": 128},
            }


class BatchGenerator:
    """Batch asset generation system"""
    
    def __init__(self, config: GenerationConfig = None):
        self.config = config or GenerationConfig()
        self.manifest = AssetManifest()
        self.generated: Dict[str, GeneratedAsset] = {}
        self.failed: Dict[str, str] = {}
        self.progress_file = PROJECT_ROOT / "blender_pipeline" / "generation_progress.json"
        
        # Ensure output directory exists
        self.output_dir = PROJECT_ROOT / "blender_pipeline" / self.config.output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_all(self) -> Dict[str, GeneratedAsset]:
        """Generate all assets in the manifest"""
        queue = self._get_filtered_queue()
        total = len(queue)
        
        print(f"\n{'='*60}")
        print(f"BATCH ASSET GENERATION")
        print(f"{'='*60}")
        print(f"Total assets to generate: {total}")
        print(f"Quality: {self.config.quality.value}")
        print(f"Output: {self.output_dir}")
        print(f"{'='*60}\n")
        
        # Load previous progress if resuming
        if self.config.resume_from:
            self._load_progress()
        
        start_time = time.time()
        
        for i, (asset_id, spec) in enumerate(queue):
            # Skip if already generated and not overwriting
            if asset_id in self.generated and not self.config.overwrite_existing:
                print(f"[{i+1}/{total}] Skipping {asset_id} (already generated)")
                continue
            
            print(f"\n[{i+1}/{total}] Generating: {spec.name}")
            print(f"  Category: {spec.category.value}")
            print(f"  Variations: {spec.variation_count}")
            
            try:
                result = self._generate_asset(asset_id, spec)
                self.generated[asset_id] = result
                print(f"  ✓ Generated successfully")
            except Exception as e:
                self.failed[asset_id] = str(e)
                print(f"  ✗ Failed: {e}")
            
            # Save progress periodically
            if (i + 1) % 10 == 0:
                self._save_progress()
        
        elapsed = time.time() - start_time
        
        # Final save
        self._save_progress()
        
        # Print summary
        print(f"\n{'='*60}")
        print(f"GENERATION COMPLETE")
        print(f"{'='*60}")
        print(f"Successful: {len(self.generated)}")
        print(f"Failed: {len(self.failed)}")
        print(f"Time: {elapsed:.1f} seconds")
        print(f"{'='*60}\n")
        
        return self.generated
    
    def _get_filtered_queue(self) -> List[Tuple[str, AssetSpec]]:
        """Get filtered and sorted generation queue"""
        queue = self.manifest.get_generation_queue()
        
        if self.config.categories_filter:
            queue = [(k, v) for k, v in queue if v.category in self.config.categories_filter]
        
        if self.config.priority_filter is not None:
            queue = [(k, v) for k, v in queue if v.priority == self.config.priority_filter]
        
        # Skip to resume point if specified
        if self.config.resume_from:
            found = False
            new_queue = []
            for item in queue:
                if item[0] == self.config.resume_from:
                    found = True
                if found:
                    new_queue.append(item)
            if new_queue:
                queue = new_queue
        
        return queue
    
    def _generate_asset(self, asset_id: str, spec: AssetSpec) -> GeneratedAsset:
        """Generate a single asset with all variations"""
        settings = self.config.quality_settings[self.config.quality]
        seed = int(hashlib.md5(asset_id.encode()).hexdigest()[:8], 16)
        
        file_paths = {}
        
        # Generate main asset
        main_path = self._render_variation(asset_id, spec, seed, 0, settings)
        file_paths["main"] = str(main_path)
        
        # Generate variations
        if self.config.generate_variations and spec.variation_count > 1:
            for v in range(1, spec.variation_count):
                var_seed = seed + v * 1000
                var_path = self._render_variation(asset_id, spec, var_seed, v, settings)
                file_paths[f"variation_{v}"] = str(var_path)
        
        # Generate damage states
        if self.config.generate_damage_states and spec.damage_states > 0:
            for d in range(1, spec.damage_states + 1):
                damage_level = d / spec.damage_states
                dam_path = self._render_damage_state(asset_id, spec, seed, damage_level, settings)
                file_paths[f"damage_{d}"] = str(dam_path)
        
        # Generate animation frames if animated
        if spec.animation_frames > 0:
            for f in range(spec.animation_frames):
                frame_path = self._render_animation_frame(asset_id, spec, seed, f, settings)
                file_paths[f"frame_{f}"] = str(frame_path)
        
        # Export to Godot format if enabled
        if self.config.export_godot:
            godot_paths = self._export_to_godot(asset_id, spec, file_paths)
            file_paths.update(godot_paths)
        
        return GeneratedAsset(
            spec=spec,
            seed=seed,
            quality=self.config.quality,
            file_paths=file_paths,
            generation_params=settings,
            timestamp=time.time(),
            approved=False
        )
    
    def _render_variation(
        self,
        asset_id: str,
        spec: AssetSpec,
        seed: int,
        variation: int,
        settings: Dict
    ) -> Path:
        """Render a single variation of an asset"""
        output_subdir = self.output_dir / spec.category.value
        output_subdir.mkdir(parents=True, exist_ok=True)
        
        if variation == 0:
            filename = f"{asset_id}.png"
        else:
            filename = f"{asset_id}_v{variation}.png"
        
        output_path = output_subdir / filename
        
        if IN_BLENDER:
            self._render_in_blender(spec, seed, variation, output_path, settings)
        else:
            # Create placeholder
            self._create_placeholder(spec, output_path, settings)
        
        return output_path
    
    def _render_damage_state(
        self,
        asset_id: str,
        spec: AssetSpec,
        seed: int,
        damage_level: float,
        settings: Dict
    ) -> Path:
        """Render a damage state of an asset"""
        output_subdir = self.output_dir / spec.category.value
        output_subdir.mkdir(parents=True, exist_ok=True)
        
        damage_pct = int(damage_level * 100)
        filename = f"{asset_id}_dmg{damage_pct}.png"
        output_path = output_subdir / filename
        
        if IN_BLENDER:
            self._render_in_blender(
                spec, seed, 0, output_path, settings,
                damage_level=damage_level
            )
        else:
            self._create_placeholder(spec, output_path, settings)
        
        return output_path
    
    def _render_animation_frame(
        self,
        asset_id: str,
        spec: AssetSpec,
        seed: int,
        frame: int,
        settings: Dict
    ) -> Path:
        """Render an animation frame"""
        output_subdir = self.output_dir / spec.category.value / "animations"
        output_subdir.mkdir(parents=True, exist_ok=True)
        
        filename = f"{asset_id}_f{frame:03d}.png"
        output_path = output_subdir / filename
        
        if IN_BLENDER:
            self._render_in_blender(
                spec, seed, 0, output_path, settings,
                animation_frame=frame
            )
        else:
            self._create_placeholder(spec, output_path, settings)
        
        return output_path
    
    def _render_in_blender(
        self,
        spec: AssetSpec,
        seed: int,
        variation: int,
        output_path: Path,
        settings: Dict,
        damage_level: float = 0.0,
        animation_frame: int = 0
    ):
        """Actually render in Blender"""
        from blender_pipeline.procedural.generators import registry
        
        # Get appropriate generator
        asset_type = self._spec_to_generator_type(spec)
        
        try:
            generator = registry.get_generator(asset_type)
        except KeyError:
            # Fallback to generic generator
            generator = registry.get_generator("crate")
        
        # Parse color from spec
        color = self._parse_color_palette(spec.color_palette)
        
        # Size mapping
        size_map = {
            "tiny": 0.3,
            "small": 0.6,
            "medium": 1.0,
            "large": 1.5,
            "huge": 2.5
        }
        size = size_map.get(spec.size_class, 1.0)
        
        # Generate the model
        obj = generator.generate(
            seed=seed + variation,
            size=size,
            variation=1.0 + variation * 0.2,
            color=color,
            damage_level=damage_level
        )
        
        # Setup render
        self._setup_render(settings)
        
        # Frame the object
        self._frame_object(obj)
        
        # Render
        bpy.context.scene.render.filepath = str(output_path)
        bpy.ops.render.render(write_still=True)
    
    def _setup_render(self, settings: Dict):
        """Setup Blender render settings"""
        scene = bpy.context.scene
        scene.render.resolution_x = settings["resolution"]
        scene.render.resolution_y = settings["resolution"]
        scene.render.image_settings.file_format = "PNG"
        scene.render.film_transparent = True
        
        if scene.render.engine == "CYCLES":
            scene.cycles.samples = settings["samples"]
    
    def _frame_object(self, obj):
        """Position camera to frame object"""
        import math
        
        cam = bpy.data.objects.get("Camera")
        if not cam:
            bpy.ops.object.camera_add(location=(4, -4, 3))
            cam = bpy.context.active_object
            cam.name = "Camera"
        
        cam.data.type = "ORTHO"
        cam.location = (4, -4, 3)
        cam.rotation_euler = (math.radians(60), 0, math.radians(45))
        
        # Auto-size
        dims = obj.dimensions
        max_dim = max(dims.x, dims.y, dims.z)
        cam.data.ortho_scale = max_dim * 1.5
        
        bpy.context.scene.camera = cam
    
    def _create_placeholder(self, spec: AssetSpec, output_path: Path, settings: Dict):
        """Create a placeholder image when not in Blender"""
        try:
            from PIL import Image, ImageDraw, ImageFont
        except ImportError:
            # Create empty file as placeholder
            output_path.write_bytes(b"")
            return
        
        size = settings["resolution"]
        
        # Color based on category
        colors = {
            AssetCategory.CHARACTER: (100, 149, 237),
            AssetCategory.ZOMBIE: (144, 238, 144),
            AssetCategory.WILDLIFE: (255, 218, 185),
            AssetCategory.WEAPON: (192, 192, 192),
            AssetCategory.ARMOR: (70, 130, 180),
            AssetCategory.BUILDING: (139, 119, 101),
            AssetCategory.PROP: (188, 143, 143),
            AssetCategory.RESOURCE: (255, 215, 0),
            AssetCategory.TERRAIN: (85, 107, 47),
            AssetCategory.EFFECT: (255, 99, 71),
        }
        color = colors.get(spec.category, (128, 128, 128))
        
        img = Image.new("RGBA", (size, size), (*color, 200))
        draw = ImageDraw.Draw(img)
        
        # Draw category name
        text = spec.name[:20]
        try:
            font = ImageFont.truetype("arial.ttf", size // 10)
        except:
            font = ImageFont.load_default()
        
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        x = (size - text_width) // 2
        y = (size - text_height) // 2
        draw.text((x, y), text, fill=(255, 255, 255), font=font)
        
        img.save(output_path)
    
    def _spec_to_generator_type(self, spec: AssetSpec) -> str:
        """Map asset spec to generator type"""
        category_map = {
            AssetCategory.CHARACTER: "character",
            AssetCategory.ZOMBIE: "zombie",
            AssetCategory.WEAPON: "weapon",
            AssetCategory.BUILDING: "building",
            AssetCategory.PROP: "crate",
            AssetCategory.VEGETATION: "tree",
            AssetCategory.TERRAIN: "ground_tile",
        }
        return category_map.get(spec.category, "crate")
    
    def _parse_color_palette(self, palette: List[str]) -> Tuple[float, float, float, float]:
        """Parse color palette to RGBA"""
        if not palette:
            return (0.5, 0.5, 0.5, 1.0)
        
        color_map = {
            "red": (0.8, 0.2, 0.2, 1.0),
            "green": (0.2, 0.6, 0.2, 1.0),
            "blue": (0.2, 0.4, 0.8, 1.0),
            "brown": (0.4, 0.3, 0.2, 1.0),
            "gray": (0.5, 0.5, 0.5, 1.0),
            "black": (0.1, 0.1, 0.1, 1.0),
            "white": (0.9, 0.9, 0.9, 1.0),
            "tan": (0.8, 0.7, 0.5, 1.0),
            "olive": (0.5, 0.5, 0.3, 1.0),
            "metal": (0.6, 0.6, 0.65, 1.0),
            "wood": (0.5, 0.35, 0.2, 1.0),
            "rust": (0.6, 0.3, 0.15, 1.0),
        }
        
        first_color = palette[0].lower()
        return color_map.get(first_color, (0.5, 0.5, 0.5, 1.0))
    
    def _export_to_godot(
        self,
        asset_id: str,
        spec: AssetSpec,
        file_paths: Dict[str, str]
    ) -> Dict[str, str]:
        """Export assets in Godot-friendly format"""
        godot_paths = {}
        
        # Create Godot resource paths
        godot_assets_dir = PROJECT_ROOT / "assets" / "generated" / spec.category.value
        godot_assets_dir.mkdir(parents=True, exist_ok=True)
        
        # Copy main asset
        if "main" in file_paths:
            src = Path(file_paths["main"])
            if src.exists():
                dst = godot_assets_dir / f"{asset_id}.png"
                import shutil
                shutil.copy2(src, dst)
                godot_paths["godot_main"] = str(dst)
        
        # Generate .import file for Godot
        import_content = self._generate_godot_import(asset_id, spec)
        import_path = godot_assets_dir / f"{asset_id}.png.import"
        import_path.write_text(import_content)
        
        return godot_paths
    
    def _generate_godot_import(self, asset_id: str, spec: AssetSpec) -> str:
        """Generate Godot .import file content"""
        path = f"res://assets/generated/{spec.category.value}/{asset_id}.png"
        return f"""[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{hashlib.md5(asset_id.encode()).hexdigest()[:12]}"
path="res://.godot/imported/{asset_id}.png-{hashlib.md5(asset_id.encode()).hexdigest()[:8]}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="{path}"
dest_files=["res://.godot/imported/{asset_id}.png-{hashlib.md5(asset_id.encode()).hexdigest()[:8]}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""
    
    def _save_progress(self):
        """Save generation progress to file"""
        data = {
            "generated": {k: asdict(v) for k, v in self.generated.items()},
            "failed": self.failed,
            "timestamp": time.time()
        }
        # Convert enums
        for k, v in data["generated"].items():
            v["quality"] = v["quality"].value if isinstance(v["quality"], AssetQuality) else v["quality"]
            if "spec" in v:
                v["spec"]["category"] = v["spec"]["category"].value if isinstance(v["spec"]["category"], AssetCategory) else v["spec"]["category"]
        
        self.progress_file.write_text(json.dumps(data, indent=2, default=str))
    
    def _load_progress(self):
        """Load previous generation progress"""
        if not self.progress_file.exists():
            return
        
        try:
            data = json.loads(self.progress_file.read_text())
            self.failed = data.get("failed", {})
            # Note: Full restoration of generated assets would need more work
            print(f"Loaded progress: {len(data.get('generated', {}))} previously generated")
        except Exception as e:
            print(f"Could not load progress: {e}")


def main():
    """Run batch generation"""
    config = GenerationConfig(
        quality=AssetQuality.PREVIEW,
        generate_variations=True,
        generate_damage_states=True,
        export_godot=True,
    )
    
    generator = BatchGenerator(config)
    generator.generate_all()


if __name__ == "__main__":
    main()
