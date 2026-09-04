"""
Enhanced Procedural Texture Generator for Godot Survival Prototype
Generates high-quality PBR textures with multiple map types at higher resolution.
"""

import sys
import os
from pathlib import Path
from random import Random
from typing import Optional, Dict, List, Tuple

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy

# ============================================================================
# CONFIGURATION
# ============================================================================

TEXTURE_OUTPUT = Path(__file__).resolve().parent.parent / "renders" / "textures"
DEFAULT_RESOLUTION = 512  # Increased from 256
HIGH_RESOLUTION = 1024
BAKE_SAMPLES = 64  # Quality samples for baking

# ============================================================================
# TEXTURE STYLE DEFINITIONS - 40+ survival game styles
# ============================================================================

TEXTURE_STYLES: Dict[str, Dict] = {
    # === CONCRETE & STONE ===
    "cracked_concrete": {
        "category": "concrete",
        "base_color": (0.45, 0.45, 0.47),
        "secondary_color": (0.25, 0.25, 0.27),
        "roughness": 0.85,
        "metallic": 0.0,
        "noise_scale": 8.0,
        "musgrave_scale": 12.0,
        "description": "Weathered cracked concrete for bunkers and ruins"
    },
    "smooth_concrete": {
        "category": "concrete",
        "base_color": (0.55, 0.55, 0.57),
        "secondary_color": (0.45, 0.45, 0.47),
        "roughness": 0.6,
        "metallic": 0.0,
        "noise_scale": 4.0,
        "musgrave_scale": 6.0,
        "description": "Clean modern concrete surfaces"
    },
    "mossy_stone": {
        "category": "stone",
        "base_color": (0.35, 0.35, 0.32),
        "secondary_color": (0.15, 0.28, 0.12),
        "roughness": 0.9,
        "metallic": 0.0,
        "noise_scale": 6.0,
        "musgrave_scale": 10.0,
        "description": "Ancient stone covered in moss"
    },
    "granite": {
        "category": "stone",
        "base_color": (0.40, 0.38, 0.36),
        "secondary_color": (0.55, 0.52, 0.50),
        "roughness": 0.4,
        "metallic": 0.05,
        "noise_scale": 15.0,
        "musgrave_scale": 20.0,
        "description": "Polished granite with flecks"
    },
    "cobblestone": {
        "category": "stone",
        "base_color": (0.30, 0.28, 0.26),
        "secondary_color": (0.42, 0.40, 0.38),
        "roughness": 0.8,
        "metallic": 0.0,
        "noise_scale": 3.0,
        "musgrave_scale": 5.0,
        "description": "Rounded cobblestone paving"
    },
    
    # === METAL ===
    "rusty_metal": {
        "category": "metal",
        "base_color": (0.55, 0.28, 0.12),
        "secondary_color": (0.32, 0.18, 0.10),
        "roughness": 0.7,
        "metallic": 0.4,
        "noise_scale": 10.0,
        "musgrave_scale": 15.0,
        "description": "Heavily rusted steel panels"
    },
    "corroded_metal": {
        "category": "metal",
        "base_color": (0.42, 0.35, 0.28),
        "secondary_color": (0.65, 0.55, 0.40),
        "roughness": 0.8,
        "metallic": 0.3,
        "noise_scale": 8.0,
        "musgrave_scale": 12.0,
        "description": "Green-tinted corroded copper/brass"
    },
    "brushed_steel": {
        "category": "metal",
        "base_color": (0.65, 0.65, 0.68),
        "secondary_color": (0.50, 0.50, 0.55),
        "roughness": 0.35,
        "metallic": 0.9,
        "noise_scale": 20.0,
        "musgrave_scale": 3.0,
        "description": "Clean brushed stainless steel"
    },
    "galvanized_metal": {
        "category": "metal",
        "base_color": (0.58, 0.60, 0.62),
        "secondary_color": (0.45, 0.47, 0.50),
        "roughness": 0.5,
        "metallic": 0.7,
        "noise_scale": 12.0,
        "musgrave_scale": 8.0,
        "description": "Galvanized zinc-coated metal"
    },
    "painted_metal": {
        "category": "metal",
        "base_color": (0.15, 0.35, 0.20),
        "secondary_color": (0.10, 0.25, 0.15),
        "roughness": 0.45,
        "metallic": 0.6,
        "noise_scale": 5.0,
        "musgrave_scale": 8.0,
        "description": "Military green painted metal"
    },
    
    # === WOOD ===
    "weathered_wood": {
        "category": "wood",
        "base_color": (0.35, 0.28, 0.20),
        "secondary_color": (0.22, 0.17, 0.12),
        "roughness": 0.75,
        "metallic": 0.0,
        "noise_scale": 4.0,
        "musgrave_scale": 8.0,
        "description": "Old weathered wooden planks"
    },
    "fresh_lumber": {
        "category": "wood",
        "base_color": (0.55, 0.42, 0.28),
        "secondary_color": (0.45, 0.35, 0.22),
        "roughness": 0.55,
        "metallic": 0.0,
        "noise_scale": 3.0,
        "musgrave_scale": 6.0,
        "description": "Fresh cut lumber"
    },
    "charred_wood": {
        "category": "wood",
        "base_color": (0.08, 0.06, 0.05),
        "secondary_color": (0.15, 0.12, 0.10),
        "roughness": 0.9,
        "metallic": 0.0,
        "noise_scale": 6.0,
        "musgrave_scale": 10.0,
        "description": "Fire-damaged charred wood"
    },
    "plywood": {
        "category": "wood",
        "base_color": (0.62, 0.52, 0.38),
        "secondary_color": (0.50, 0.42, 0.30),
        "roughness": 0.5,
        "metallic": 0.0,
        "noise_scale": 5.0,
        "musgrave_scale": 7.0,
        "description": "Construction plywood sheets"
    },
    
    # === GROUND & NATURE ===
    "dirt_ground": {
        "category": "ground",
        "base_color": (0.28, 0.22, 0.15),
        "secondary_color": (0.35, 0.28, 0.18),
        "roughness": 0.95,
        "metallic": 0.0,
        "noise_scale": 6.0,
        "musgrave_scale": 10.0,
        "description": "Dry packed dirt"
    },
    "mud_ground": {
        "category": "ground",
        "base_color": (0.18, 0.14, 0.10),
        "secondary_color": (0.25, 0.20, 0.15),
        "roughness": 0.7,
        "metallic": 0.0,
        "noise_scale": 5.0,
        "musgrave_scale": 8.0,
        "description": "Wet muddy terrain"
    },
    "sand": {
        "category": "ground",
        "base_color": (0.72, 0.65, 0.50),
        "secondary_color": (0.65, 0.58, 0.42),
        "roughness": 0.85,
        "metallic": 0.0,
        "noise_scale": 8.0,
        "musgrave_scale": 15.0,
        "description": "Desert sand texture"
    },
    "grass": {
        "category": "ground",
        "base_color": (0.18, 0.35, 0.12),
        "secondary_color": (0.12, 0.25, 0.08),
        "roughness": 0.8,
        "metallic": 0.0,
        "noise_scale": 10.0,
        "musgrave_scale": 20.0,
        "description": "Grassy lawn texture"
    },
    "dead_grass": {
        "category": "ground",
        "base_color": (0.45, 0.38, 0.22),
        "secondary_color": (0.35, 0.30, 0.18),
        "roughness": 0.85,
        "metallic": 0.0,
        "noise_scale": 12.0,
        "musgrave_scale": 18.0,
        "description": "Dried dead grass"
    },
    "jungle_leaves": {
        "category": "foliage",
        "base_color": (0.10, 0.35, 0.12),
        "secondary_color": (0.06, 0.25, 0.08),
        "roughness": 0.6,
        "metallic": 0.0,
        "noise_scale": 5.0,
        "musgrave_scale": 8.0,
        "description": "Dense tropical foliage"
    },
    "autumn_leaves": {
        "category": "foliage",
        "base_color": (0.65, 0.35, 0.12),
        "secondary_color": (0.55, 0.25, 0.08),
        "roughness": 0.65,
        "metallic": 0.0,
        "noise_scale": 6.0,
        "musgrave_scale": 10.0,
        "description": "Fall colored foliage"
    },
    "bark": {
        "category": "foliage",
        "base_color": (0.25, 0.18, 0.12),
        "secondary_color": (0.18, 0.12, 0.08),
        "roughness": 0.9,
        "metallic": 0.0,
        "noise_scale": 4.0,
        "musgrave_scale": 7.0,
        "description": "Tree bark texture"
    },
    
    # === INDUSTRIAL & HAZARD ===
    "hazard_stripes": {
        "category": "industrial",
        "base_color": (0.95, 0.75, 0.10),
        "secondary_color": (0.10, 0.10, 0.10),
        "roughness": 0.4,
        "metallic": 0.2,
        "noise_scale": 3.0,
        "musgrave_scale": 2.0,
        "description": "Yellow/black warning stripes"
    },
    "chipped_paint": {
        "category": "industrial",
        "base_color": (0.75, 0.10, 0.10),
        "secondary_color": (0.20, 0.20, 0.20),
        "roughness": 0.5,
        "metallic": 0.3,
        "noise_scale": 6.0,
        "musgrave_scale": 10.0,
        "description": "Chipping red paint on metal"
    },
    "oil_stained": {
        "category": "industrial",
        "base_color": (0.15, 0.12, 0.10),
        "secondary_color": (0.08, 0.06, 0.05),
        "roughness": 0.3,
        "metallic": 0.1,
        "noise_scale": 8.0,
        "musgrave_scale": 12.0,
        "description": "Oil-stained concrete floor"
    },
    "asphalt": {
        "category": "industrial",
        "base_color": (0.12, 0.12, 0.12),
        "secondary_color": (0.18, 0.18, 0.18),
        "roughness": 0.75,
        "metallic": 0.0,
        "noise_scale": 15.0,
        "musgrave_scale": 25.0,
        "description": "Road asphalt surface"
    },
    
    # === FABRIC & SOFT ===
    "burlap": {
        "category": "fabric",
        "base_color": (0.55, 0.48, 0.35),
        "secondary_color": (0.45, 0.38, 0.28),
        "roughness": 0.9,
        "metallic": 0.0,
        "noise_scale": 20.0,
        "musgrave_scale": 30.0,
        "description": "Rough burlap sack material"
    },
    "canvas": {
        "category": "fabric",
        "base_color": (0.72, 0.68, 0.60),
        "secondary_color": (0.62, 0.58, 0.50),
        "roughness": 0.75,
        "metallic": 0.0,
        "noise_scale": 25.0,
        "musgrave_scale": 35.0,
        "description": "Heavy canvas material"
    },
    "leather": {
        "category": "fabric",
        "base_color": (0.32, 0.22, 0.15),
        "secondary_color": (0.25, 0.18, 0.12),
        "roughness": 0.55,
        "metallic": 0.0,
        "noise_scale": 8.0,
        "musgrave_scale": 12.0,
        "description": "Worn leather texture"
    },
    "military_camo": {
        "category": "fabric",
        "base_color": (0.25, 0.30, 0.18),
        "secondary_color": (0.15, 0.18, 0.10),
        "roughness": 0.7,
        "metallic": 0.0,
        "noise_scale": 4.0,
        "musgrave_scale": 6.0,
        "description": "Military camouflage pattern"
    },
    
    # === SPECIAL EFFECTS ===
    "radioactive_glow": {
        "category": "special",
        "base_color": (0.20, 0.85, 0.15),
        "secondary_color": (0.10, 0.45, 0.08),
        "roughness": 0.3,
        "metallic": 0.1,
        "noise_scale": 6.0,
        "musgrave_scale": 10.0,
        "description": "Radioactive green glow material"
    },
    "toxic_sludge": {
        "category": "special",
        "base_color": (0.35, 0.55, 0.15),
        "secondary_color": (0.20, 0.35, 0.08),
        "roughness": 0.2,
        "metallic": 0.0,
        "noise_scale": 5.0,
        "musgrave_scale": 8.0,
        "description": "Toxic waste sludge"
    },
    "blood_splatter": {
        "category": "special",
        "base_color": (0.45, 0.02, 0.02),
        "secondary_color": (0.25, 0.01, 0.01),
        "roughness": 0.4,
        "metallic": 0.1,
        "noise_scale": 7.0,
        "musgrave_scale": 12.0,
        "description": "Dried blood stains"
    },
    "ice": {
        "category": "special",
        "base_color": (0.75, 0.85, 0.92),
        "secondary_color": (0.55, 0.72, 0.85),
        "roughness": 0.15,
        "metallic": 0.0,
        "noise_scale": 10.0,
        "musgrave_scale": 15.0,
        "description": "Frozen ice surface"
    },
    "snow": {
        "category": "special",
        "base_color": (0.95, 0.95, 0.98),
        "secondary_color": (0.85, 0.88, 0.92),
        "roughness": 0.7,
        "metallic": 0.0,
        "noise_scale": 12.0,
        "musgrave_scale": 20.0,
        "description": "Fresh snow coverage"
    },
    
    # === BUILDING MATERIALS ===
    "brick_red": {
        "category": "building",
        "base_color": (0.55, 0.25, 0.18),
        "secondary_color": (0.42, 0.18, 0.12),
        "roughness": 0.8,
        "metallic": 0.0,
        "noise_scale": 4.0,
        "musgrave_scale": 6.0,
        "description": "Red clay brick wall"
    },
    "roof_tiles": {
        "category": "building",
        "base_color": (0.38, 0.22, 0.15),
        "secondary_color": (0.28, 0.15, 0.10),
        "roughness": 0.7,
        "metallic": 0.0,
        "noise_scale": 3.0,
        "musgrave_scale": 5.0,
        "description": "Ceramic roof tiles"
    },
    "stucco": {
        "category": "building",
        "base_color": (0.82, 0.78, 0.72),
        "secondary_color": (0.72, 0.68, 0.62),
        "roughness": 0.85,
        "metallic": 0.0,
        "noise_scale": 8.0,
        "musgrave_scale": 12.0,
        "description": "Textured stucco wall"
    },
    "drywall": {
        "category": "building",
        "base_color": (0.92, 0.90, 0.88),
        "secondary_color": (0.85, 0.83, 0.80),
        "roughness": 0.6,
        "metallic": 0.0,
        "noise_scale": 6.0,
        "musgrave_scale": 8.0,
        "description": "Interior drywall surface"
    },
    "corrugated_roof": {
        "category": "building",
        "base_color": (0.45, 0.42, 0.40),
        "secondary_color": (0.35, 0.32, 0.30),
        "roughness": 0.6,
        "metallic": 0.5,
        "noise_scale": 2.0,
        "musgrave_scale": 4.0,
        "description": "Corrugated metal roofing"
    },
}


# ============================================================================
# BAKING SETUP
# ============================================================================

def _ensure_scene_for_bake(bake_type: str = "EMIT", samples: int = BAKE_SAMPLES) -> None:
    """Configure scene for texture baking."""
    bpy.context.scene.render.engine = "CYCLES"
    bpy.context.scene.cycles.samples = samples
    bpy.context.scene.cycles.bake_type = bake_type
    bpy.context.scene.cycles.use_denoising = True


def _create_base_material(name: str) -> bpy.types.Material:
    """Create a new material with cleared node tree."""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    return mat


# ============================================================================
# NODE CREATION FOR DIFFERENT MAP TYPES
# ============================================================================

def _make_color_nodes(mat: bpy.types.Material, style_data: Dict, rng: Random) -> bpy.types.ShaderNodeOutputMaterial:
    """Create node setup for base color/albedo map."""
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    # Output
    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    emit = nodes.new("ShaderNodeEmission")
    emit.location = (400, 0)
    links.new(emit.outputs["Emission"], out.inputs["Surface"])

    # Noise texture
    tex_noise = nodes.new("ShaderNodeTexNoise")
    tex_noise.location = (-400, 200)
    tex_noise.inputs["Scale"].default_value = style_data["noise_scale"] + rng.uniform(-1, 1)
    tex_noise.inputs["Detail"].default_value = 6.0 + rng.uniform(-1, 1)
    tex_noise.inputs["Roughness"].default_value = 0.5
    
    # Musgrave for variation
    musgrave = nodes.new("ShaderNodeMusgraveTexture")
    musgrave.location = (-400, -100)
    musgrave.musgrave_type = 'FBM'
    musgrave.inputs["Scale"].default_value = style_data["musgrave_scale"] + rng.uniform(-2, 2)
    musgrave.inputs["Detail"].default_value = 4.0
    musgrave.inputs["Dimension"].default_value = 2.0
    
    # Voronoi for cell-like patterns
    voronoi = nodes.new("ShaderNodeVoronoiTexture")
    voronoi.location = (-400, -400)
    voronoi.feature = 'F1'
    voronoi.inputs["Scale"].default_value = style_data["noise_scale"] * 0.5
    
    # Color ramp for base colors
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (-100, 200)
    ramp.color_ramp.elements[0].color = (*style_data["base_color"], 1.0)
    ramp.color_ramp.elements[1].color = (*style_data["secondary_color"], 1.0)
    
    # Mix nodes for complexity
    mix1 = nodes.new("ShaderNodeMixRGB")
    mix1.location = (0, 0)
    mix1.blend_type = "MIX"
    mix1.inputs["Fac"].default_value = 0.5 + rng.uniform(-0.2, 0.2)
    
    mix2 = nodes.new("ShaderNodeMixRGB")
    mix2.location = (200, 0)
    mix2.blend_type = "OVERLAY"
    mix2.inputs["Fac"].default_value = 0.3 + rng.uniform(-0.1, 0.1)
    
    # Connect
    links.new(tex_noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], mix1.inputs["Color1"])
    links.new(musgrave.outputs["Fac"], mix1.inputs["Color2"])
    links.new(mix1.outputs["Color"], mix2.inputs["Color1"])
    links.new(voronoi.outputs["Distance"], mix2.inputs["Color2"])
    links.new(mix2.outputs["Color"], emit.inputs["Color"])
    
    return out


def _make_normal_nodes(mat: bpy.types.Material, style_data: Dict, rng: Random) -> bpy.types.ShaderNodeOutputMaterial:
    """Create node setup for normal map generation."""
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (800, 0)
    
    emit = nodes.new("ShaderNodeEmission")
    emit.location = (600, 0)
    links.new(emit.outputs["Emission"], out.inputs["Surface"])

    # Noise for bumps
    tex_noise = nodes.new("ShaderNodeTexNoise")
    tex_noise.location = (-400, 200)
    tex_noise.inputs["Scale"].default_value = style_data["noise_scale"] * 1.5
    tex_noise.inputs["Detail"].default_value = 8.0
    
    # Musgrave for larger features
    musgrave = nodes.new("ShaderNodeMusgraveTexture")
    musgrave.location = (-400, -100)
    musgrave.inputs["Scale"].default_value = style_data["musgrave_scale"]
    
    # Mix the heights
    mix = nodes.new("ShaderNodeMixRGB")
    mix.location = (-100, 50)
    mix.inputs["Fac"].default_value = 0.6
    links.new(tex_noise.outputs["Fac"], mix.inputs["Color1"])
    links.new(musgrave.outputs["Fac"], mix.inputs["Color2"])
    
    # Bump to normal
    bump = nodes.new("ShaderNodeBump")
    bump.location = (200, 0)
    bump.inputs["Strength"].default_value = 1.0
    bump.inputs["Distance"].default_value = 0.1
    links.new(mix.outputs["Color"], bump.inputs["Height"])
    
    # Normal to color (encode normal map as RGB)
    vector_math = nodes.new("ShaderNodeVectorMath")
    vector_math.operation = 'ADD'
    vector_math.location = (400, 0)
    vector_math.inputs[1].default_value = (1.0, 1.0, 1.0)
    
    vector_math2 = nodes.new("ShaderNodeVectorMath")
    vector_math2.operation = 'SCALE'
    vector_math2.location = (500, 0)
    vector_math2.inputs["Scale"].default_value = 0.5
    
    links.new(bump.outputs["Normal"], vector_math.inputs[0])
    links.new(vector_math.outputs["Vector"], vector_math2.inputs[0])
    links.new(vector_math2.outputs["Vector"], emit.inputs["Color"])
    
    return out


def _make_roughness_nodes(mat: bpy.types.Material, style_data: Dict, rng: Random) -> bpy.types.ShaderNodeOutputMaterial:
    """Create node setup for roughness map generation."""
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    emit = nodes.new("ShaderNodeEmission")
    emit.location = (400, 0)
    links.new(emit.outputs["Emission"], out.inputs["Surface"])

    # Noise texture
    tex_noise = nodes.new("ShaderNodeTexNoise")
    tex_noise.location = (-400, 100)
    tex_noise.inputs["Scale"].default_value = style_data["noise_scale"] * 2.0
    tex_noise.inputs["Detail"].default_value = 4.0
    
    # Musgrave
    musgrave = nodes.new("ShaderNodeMusgraveTexture")
    musgrave.location = (-400, -100)
    musgrave.inputs["Scale"].default_value = style_data["musgrave_scale"] * 0.8
    
    # Color ramp to control roughness range
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (0, 0)
    base_rough = style_data["roughness"]
    # Clamp values to valid range
    low_rough = max(0.0, base_rough - 0.15)
    high_rough = min(1.0, base_rough + 0.1)
    ramp.color_ramp.elements[0].color = (low_rough, low_rough, low_rough, 1.0)
    ramp.color_ramp.elements[1].color = (high_rough, high_rough, high_rough, 1.0)
    
    # Mix
    mix = nodes.new("ShaderNodeMixRGB")
    mix.location = (-100, 0)
    mix.inputs["Fac"].default_value = 0.5
    links.new(tex_noise.outputs["Fac"], mix.inputs["Color1"])
    links.new(musgrave.outputs["Fac"], mix.inputs["Color2"])
    links.new(mix.outputs["Color"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], emit.inputs["Color"])
    
    return out


def _make_metallic_nodes(mat: bpy.types.Material, style_data: Dict, rng: Random) -> bpy.types.ShaderNodeOutputMaterial:
    """Create node setup for metallic map generation."""
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    emit = nodes.new("ShaderNodeEmission")
    emit.location = (400, 0)
    links.new(emit.outputs["Emission"], out.inputs["Surface"])

    base_metallic = style_data["metallic"]
    
    if base_metallic < 0.1:
        # Non-metallic - output near black
        emit.inputs["Color"].default_value = (base_metallic, base_metallic, base_metallic, 1.0)
    else:
        # Metallic with variation
        tex_noise = nodes.new("ShaderNodeTexNoise")
        tex_noise.location = (-300, 0)
        tex_noise.inputs["Scale"].default_value = style_data["noise_scale"]
        
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (100, 0)
        low_metal = max(0.0, base_metallic - 0.1)
        ramp.color_ramp.elements[0].color = (low_metal, low_metal, low_metal, 1.0)
        ramp.color_ramp.elements[1].color = (base_metallic, base_metallic, base_metallic, 1.0)
        
        links.new(tex_noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], emit.inputs["Color"])
    
    return out


def _make_ao_nodes(mat: bpy.types.Material, style_data: Dict, rng: Random) -> bpy.types.ShaderNodeOutputMaterial:
    """Create node setup for ambient occlusion map generation."""
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    emit = nodes.new("ShaderNodeEmission")
    emit.location = (400, 0)
    links.new(emit.outputs["Emission"], out.inputs["Surface"])

    # Voronoi for crevices
    voronoi = nodes.new("ShaderNodeVoronoiTexture")
    voronoi.location = (-400, 100)
    voronoi.feature = 'DISTANCE_TO_EDGE'
    voronoi.inputs["Scale"].default_value = style_data["noise_scale"] * 0.5
    
    # Noise for general occlusion
    tex_noise = nodes.new("ShaderNodeTexNoise")
    tex_noise.location = (-400, -100)
    tex_noise.inputs["Scale"].default_value = style_data["noise_scale"]
    tex_noise.inputs["Detail"].default_value = 2.0
    
    # Combine and ramp
    mix = nodes.new("ShaderNodeMixRGB")
    mix.location = (-100, 0)
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 0.3
    
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (100, 0)
    ramp.color_ramp.elements[0].color = (0.7, 0.7, 0.7, 1.0)
    ramp.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)
    
    links.new(voronoi.outputs["Distance"], mix.inputs["Color1"])
    links.new(tex_noise.outputs["Fac"], mix.inputs["Color2"])
    links.new(mix.outputs["Color"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], emit.inputs["Color"])
    
    return out


# ============================================================================
# PLANE AND BAKING
# ============================================================================

def _setup_plane(mat: bpy.types.Material) -> bpy.types.Object:
    """Create and UV-unwrap a plane for baking."""
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, 0, 0))
    plane = bpy.context.active_object
    plane.data.materials.append(mat)
    
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.uv.smart_project(angle_limit=66)
    bpy.ops.object.mode_set(mode="OBJECT")
    
    return plane


def _bake_to_image(plane: bpy.types.Object, mat: bpy.types.Material, 
                   img_name: str, resolution: int) -> str:
    """Bake material to image and save."""
    TEXTURE_OUTPUT.mkdir(parents=True, exist_ok=True)
    img_path = TEXTURE_OUTPUT / img_name

    # Create image
    image = bpy.data.images.new(name=img_name, width=resolution, height=resolution, alpha=False)
    image.filepath_raw = str(img_path)
    image.file_format = "PNG"

    # Link image to material for baking
    img_node = mat.node_tree.nodes.new("ShaderNodeTexImage")
    img_node.image = image
    mat.node_tree.nodes.active = img_node

    # Select plane for baking
    for obj in bpy.context.view_layer.objects:
        obj.select_set(False)
    if bpy.context.view_layer.objects.active and bpy.context.view_layer.objects.active.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    plane.select_set(True)
    bpy.context.view_layer.objects.active = plane
    
    # Bake
    bpy.ops.object.bake(type="EMIT")
    image.save()

    return str(img_path)


def _cleanup_plane(plane: bpy.types.Object) -> None:
    """Remove the temporary baking plane."""
    bpy.ops.object.select_all(action='DESELECT')
    plane.select_set(True)
    bpy.context.view_layer.objects.active = plane
    bpy.ops.object.delete()


# ============================================================================
# PUBLIC API
# ============================================================================

def generate_texture(style: str, seed: Optional[int] = None, 
                     resolution: int = DEFAULT_RESOLUTION) -> str:
    """
    Generate and bake a procedural color texture.
    
    Args:
        style: Texture style name (e.g., 'rusty_metal', 'cracked_concrete')
        seed: Random seed for reproducibility
        resolution: Output texture resolution (default 512)
    
    Returns:
        Path to the generated PNG file
    """
    rng = Random(seed)
    style_key = style.lower().replace(" ", "_")
    
    if style_key not in TEXTURE_STYLES:
        # Fall back to generic if style not found
        style_data = {
            "base_color": (0.5, 0.5, 0.5),
            "secondary_color": (0.3, 0.3, 0.3),
            "roughness": 0.7,
            "metallic": 0.0,
            "noise_scale": 6.0,
            "musgrave_scale": 10.0,
        }
    else:
        style_data = TEXTURE_STYLES[style_key]
    
    _ensure_scene_for_bake()
    mat = _create_base_material(f"Tex_{style_key}")
    _make_color_nodes(mat, style_data, rng)
    plane = _setup_plane(mat)

    img_name = f"{style_key}_color_{seed or rng.randint(0, 999999)}.png"
    result_path = _bake_to_image(plane, mat, img_name, resolution)
    
    _cleanup_plane(plane)
    
    return result_path


def generate_pbr_texture_set(style: str, seed: Optional[int] = None,
                              resolution: int = DEFAULT_RESOLUTION,
                              include_maps: List[str] = None) -> Dict[str, str]:
    """
    Generate a complete PBR texture set (color, normal, roughness, metallic, AO).
    
    Args:
        style: Texture style name
        seed: Random seed for reproducibility
        resolution: Output texture resolution
        include_maps: List of maps to generate ('color', 'normal', 'roughness', 'metallic', 'ao')
                      Default is all maps.
    
    Returns:
        Dictionary mapping map type to file path
    """
    if include_maps is None:
        include_maps = ['color', 'normal', 'roughness', 'metallic', 'ao']
    
    rng = Random(seed)
    style_key = style.lower().replace(" ", "_")
    
    if style_key not in TEXTURE_STYLES:
        style_data = {
            "base_color": (0.5, 0.5, 0.5),
            "secondary_color": (0.3, 0.3, 0.3),
            "roughness": 0.7,
            "metallic": 0.0,
            "noise_scale": 6.0,
            "musgrave_scale": 10.0,
        }
    else:
        style_data = TEXTURE_STYLES[style_key]
    
    _ensure_scene_for_bake()
    
    results = {}
    base_seed = seed or rng.randint(0, 999999)
    
    map_generators = {
        'color': _make_color_nodes,
        'normal': _make_normal_nodes,
        'roughness': _make_roughness_nodes,
        'metallic': _make_metallic_nodes,
        'ao': _make_ao_nodes,
    }
    
    for map_type in include_maps:
        if map_type not in map_generators:
            continue
            
        mat = _create_base_material(f"Tex_{style_key}_{map_type}")
        map_generators[map_type](mat, style_data, rng)
        plane = _setup_plane(mat)
        
        img_name = f"{style_key}_{map_type}_{base_seed}.png"
        result_path = _bake_to_image(plane, mat, img_name, resolution)
        results[map_type] = result_path
        
        _cleanup_plane(plane)
        
        # Clean up material
        bpy.data.materials.remove(mat)
    
    return results


def get_available_styles() -> List[str]:
    """Return list of all available texture styles."""
    return list(TEXTURE_STYLES.keys())


def get_styles_by_category(category: str) -> List[str]:
    """Return styles filtered by category."""
    return [name for name, data in TEXTURE_STYLES.items() 
            if data.get("category") == category]


def get_categories() -> List[str]:
    """Return list of all texture categories."""
    categories = set()
    for data in TEXTURE_STYLES.values():
        if "category" in data:
            categories.add(data["category"])
    return sorted(list(categories))


def get_style_info(style: str) -> Dict:
    """Get detailed information about a texture style."""
    style_key = style.lower().replace(" ", "_")
    return TEXTURE_STYLES.get(style_key, {})


__all__ = [
    "generate_texture",
    "generate_pbr_texture_set",
    "get_available_styles",
    "get_styles_by_category",
    "get_categories",
    "get_style_info",
    "TEXTURE_STYLES",
    "DEFAULT_RESOLUTION",
    "HIGH_RESOLUTION",
]
