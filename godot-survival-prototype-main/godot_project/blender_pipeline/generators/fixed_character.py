"""
Fixed Character Generator - Creates properly proportioned humanoid characters
with correct axis orientation and connected body parts.

Axis Convention (Blender/Godot standard):
- X = Left-Right (width/shoulders)
- Y = Front-Back (depth)
- Z = Up-Down (height)
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector


class FixedCharacterGenerator:
    """Generate properly proportioned humanoid characters."""
    
    # Character type configurations
    CHARACTER_TYPES = {
        "survivor_male": {
            "height": 1.75,
            "build": "athletic",
            "skin_tone": (0.76, 0.65, 0.55),
            "clothing_color": (0.25, 0.30, 0.22),  # Olive tactical
            "accent_color": (0.15, 0.12, 0.10),   # Dark brown
        },
        "survivor_female": {
            "height": 1.65,
            "build": "lean",
            "skin_tone": (0.78, 0.67, 0.57),
            "clothing_color": (0.30, 0.28, 0.25),  # Gray
            "accent_color": (0.6, 0.3, 0.2),      # Red-brown
        },
        "npc_trader": {
            "height": 1.70,
            "build": "stocky",
            "skin_tone": (0.72, 0.60, 0.50),
            "clothing_color": (0.45, 0.35, 0.25),  # Brown merchant
            "accent_color": (0.6, 0.55, 0.4),     # Tan
        },
        "npc_mechanic": {
            "height": 1.80,
            "build": "muscular",
            "skin_tone": (0.65, 0.55, 0.45),
            "clothing_color": (0.2, 0.25, 0.35),   # Blue workwear
            "accent_color": (0.5, 0.3, 0.15),     # Orange
        },
        "raider_scout": {
            "height": 1.72,
            "build": "lean",
            "skin_tone": (0.70, 0.58, 0.48),
            "clothing_color": (0.15, 0.15, 0.15),  # Black
            "accent_color": (0.5, 0.1, 0.1),      # Red
        },
        "raider_heavy": {
            "height": 1.90,
            "build": "muscular",
            "skin_tone": (0.68, 0.56, 0.46),
            "clothing_color": (0.12, 0.10, 0.10),  # Dark
            "accent_color": (0.4, 0.35, 0.3),     # Metal
        },
    }
    
    # Build modifiers
    BUILDS = {
        "lean": {"width": 0.9, "depth": 0.85, "muscle": 0.9},
        "athletic": {"width": 1.0, "depth": 0.95, "muscle": 1.1},
        "stocky": {"width": 1.15, "depth": 1.1, "muscle": 1.0},
        "muscular": {"width": 1.2, "depth": 1.15, "muscle": 1.25},
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, char_type: str = "survivor_male") -> bpy.types.Object:
        """Generate a complete character with proper proportions."""
        config = self.CHARACTER_TYPES.get(char_type, self.CHARACTER_TYPES["survivor_male"])
        build = self.BUILDS.get(config["build"], self.BUILDS["athletic"])
        
        height = config["height"]
        
        # Create materials
        skin_mat = self._create_material(f"{name}_skin", config["skin_tone"])
        cloth_mat = self._create_material(f"{name}_cloth", config["clothing_color"])
        accent_mat = self._create_material(f"{name}_accent", config["accent_color"])
        
        parts = []
        
        # Body proportions (all as fractions of total height)
        head_h = height * 0.12
        neck_h = height * 0.025
        torso_h = height * 0.30
        pelvis_h = height * 0.08
        upper_leg_h = height * 0.23
        lower_leg_h = height * 0.21
        foot_h = height * 0.035
        
        upper_arm_h = height * 0.15
        lower_arm_h = height * 0.13
        hand_h = height * 0.045
        
        shoulder_w = height * 0.28 * build["width"]
        hip_w = height * 0.20 * build["width"]
        
        # Build character from feet up, keeping track of Z position
        z = 0
        
        # === FEET ===
        for side in [-1, 1]:
            foot = self._create_box(
                width=foot_h * 0.7,      # X - narrow
                depth=foot_h * 2.5,      # Y - long
                height=foot_h           # Z
            )
            foot.location = Vector((side * hip_w * 0.5, foot_h * 0.3, z + foot_h * 0.5))
            foot.data.materials.append(accent_mat)
            parts.append(foot)
        z += foot_h
        
        # === LOWER LEGS ===
        for side in [-1, 1]:
            leg = self._create_tapered_cylinder(
                radius_top=lower_leg_h * 0.12 * build["width"],
                radius_bottom=lower_leg_h * 0.08 * build["width"],
                height=lower_leg_h,
                segments=8
            )
            leg.location = Vector((side * hip_w * 0.5, 0, z + lower_leg_h * 0.5))
            leg.data.materials.append(cloth_mat)
            parts.append(leg)
        z += lower_leg_h
        
        # === UPPER LEGS ===
        for side in [-1, 1]:
            leg = self._create_tapered_cylinder(
                radius_top=upper_leg_h * 0.16 * build["width"] * build["muscle"],
                radius_bottom=upper_leg_h * 0.11 * build["width"],
                height=upper_leg_h,
                segments=8
            )
            leg.location = Vector((side * hip_w * 0.45, 0, z + upper_leg_h * 0.5))
            leg.data.materials.append(cloth_mat)
            parts.append(leg)
        z += upper_leg_h
        
        # === PELVIS ===
        pelvis = self._create_box(
            width=hip_w * 1.1,
            depth=hip_w * 0.5 * build["depth"],
            height=pelvis_h
        )
        pelvis.location = Vector((0, 0, z + pelvis_h * 0.5))
        pelvis.data.materials.append(cloth_mat)
        self._bevel_object(pelvis, 0.015)
        parts.append(pelvis)
        z += pelvis_h
        
        # === TORSO ===
        torso = self._create_torso_mesh(
            shoulder_width=shoulder_w,
            waist_width=hip_w * 0.95,
            depth=shoulder_w * 0.4 * build["depth"],
            height=torso_h,
            build=build
        )
        torso.location = Vector((0, 0, z + torso_h * 0.5))
        torso.data.materials.append(cloth_mat)
        parts.append(torso)
        
        # Store shoulder height for arms
        shoulder_z = z + torso_h * 0.92
        z += torso_h
        
        # === ARMS ===
        arm_x = shoulder_w * 0.52  # Just outside shoulders
        for side in [-1, 1]:
            arm_z = shoulder_z
            
            # Shoulder cap
            shoulder = self._create_sphere(radius=upper_arm_h * 0.15 * build["width"], segments=6)
            shoulder.location = Vector((side * arm_x, 0, arm_z))
            shoulder.data.materials.append(cloth_mat)
            parts.append(shoulder)
            
            # Upper arm
            upper_arm = self._create_tapered_cylinder(
                radius_top=upper_arm_h * 0.12 * build["width"] * build["muscle"],
                radius_bottom=upper_arm_h * 0.09 * build["width"],
                height=upper_arm_h,
                segments=8
            )
            arm_z -= upper_arm_h * 0.5
            upper_arm.location = Vector((side * arm_x, 0, arm_z))
            upper_arm.data.materials.append(cloth_mat)
            parts.append(upper_arm)
            arm_z -= upper_arm_h * 0.5
            
            # Lower arm
            lower_arm = self._create_tapered_cylinder(
                radius_top=lower_arm_h * 0.09 * build["width"],
                radius_bottom=lower_arm_h * 0.06 * build["width"],
                height=lower_arm_h,
                segments=8
            )
            arm_z -= lower_arm_h * 0.5
            lower_arm.location = Vector((side * arm_x, 0, arm_z))
            lower_arm.data.materials.append(skin_mat)
            parts.append(lower_arm)
            arm_z -= lower_arm_h * 0.5
            
            # Hand
            hand = self._create_box(
                width=hand_h * 0.8,
                depth=hand_h * 0.4,
                height=hand_h * 1.2
            )
            hand.location = Vector((side * arm_x, 0, arm_z - hand_h * 0.6))
            hand.data.materials.append(skin_mat)
            parts.append(hand)
        
        # === NECK ===
        neck = self._create_cylinder(
            radius=neck_h * 1.2 * build["width"],
            height=neck_h,
            segments=8
        )
        neck.location = Vector((0, 0, z + neck_h * 0.5))
        neck.data.materials.append(skin_mat)
        parts.append(neck)
        z += neck_h
        
        # === HEAD ===
        head = self._create_head_mesh(head_h, build)
        head.location = Vector((0, 0, z + head_h * 0.5))
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        # Add facial features
        face_parts = self._create_face_features(head_h, z + head_h * 0.5, skin_mat, accent_mat)
        parts.extend(face_parts)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        character = bpy.context.active_object
        character.name = name
        
        # Set origin to bottom center
        self._set_origin_to_bottom(character)
        
        # Apply smooth shading for better look
        bpy.ops.object.shade_smooth()
        
        return character
    
    def _create_box(self, width: float, depth: float, height: float) -> bpy.types.Object:
        """Create a box with correct XYZ dimensions."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.scale = (width, depth, height)
        bpy.ops.object.transform_apply(scale=True)
        return obj
    
    def _create_cylinder(self, radius: float, height: float, segments: int = 12) -> bpy.types.Object:
        """Create a cylinder standing upright (Z-axis)."""
        bpy.ops.mesh.primitive_cylinder_add(vertices=segments, radius=radius, depth=height)
        return bpy.context.active_object
    
    def _create_tapered_cylinder(self, radius_top: float, radius_bottom: float, height: float, segments: int = 8) -> bpy.types.Object:
        """Create a cylinder that tapers from top to bottom."""
        bpy.ops.mesh.primitive_cylinder_add(vertices=segments, radius=radius_top, depth=height)
        obj = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        # Scale bottom vertices
        scale_factor = radius_bottom / radius_top if radius_top > 0 else 1
        for v in bm.verts:
            if v.co.z < 0:  # Bottom half
                v.co.x *= scale_factor
                v.co.y *= scale_factor
        
        bm.to_mesh(obj.data)
        bm.free()
        
        return obj
    
    def _create_sphere(self, radius: float, segments: int = 8) -> bpy.types.Object:
        """Create a UV sphere."""
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=segments//2, radius=radius)
        return bpy.context.active_object
    
    def _create_torso_mesh(self, shoulder_width: float, waist_width: float, depth: float, height: float, build: dict) -> bpy.types.Object:
        """Create a properly shaped torso that's wider at shoulders than waist."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.scale = (shoulder_width, depth, height)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        # Taper toward waist (bottom)
        waist_factor = waist_width / shoulder_width
        for v in bm.verts:
            # Interpolate width based on height
            t = (v.co.z + height/2) / height  # 0 at bottom, 1 at top
            width_factor = waist_factor + (1.0 - waist_factor) * t
            v.co.x *= width_factor
            
            # Add chest depth (puff out front at top)
            if v.co.z > 0 and v.co.y > 0:
                v.co.y += depth * 0.15 * build["muscle"] * (v.co.z / (height/2))
        
        bm.to_mesh(obj.data)
        bm.free()
        
        # Bevel edges for smoother look
        self._bevel_object(obj, 0.02)
        
        return obj
    
    def _create_head_mesh(self, head_height: float, build: dict) -> bpy.types.Object:
        """Create a head with proper proportions."""
        # Head is roughly a sphere, slightly taller than wide
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=head_height * 0.5)
        obj = bpy.context.active_object
        
        # Make it slightly oval (taller)
        obj.scale = (0.85, 0.9, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        
        # Add jaw definition
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        for v in bm.verts:
            # Narrow the jaw area
            if v.co.z < -head_height * 0.2:
                factor = 1.0 - (abs(v.co.z + head_height * 0.2) / (head_height * 0.3)) * 0.2
                v.co.x *= factor
                v.co.y *= factor
        bm.to_mesh(obj.data)
        bm.free()
        
        return obj
    
    def _create_face_features(self, head_h: float, head_z: float, skin_mat, accent_mat) -> list:
        """Create basic face features (eyes, nose hint)."""
        parts = []
        eye_z = head_z + head_h * 0.1
        eye_y = head_h * 0.35
        
        # Eyes
        for side in [-1, 1]:
            eye = self._create_sphere(radius=head_h * 0.05, segments=6)
            eye.location = Vector((side * head_h * 0.15, eye_y, eye_z))
            eye.data.materials.append(accent_mat)
            parts.append(eye)
        
        return parts
    
    def _bevel_object(self, obj: bpy.types.Object, width: float) -> None:
        """Add bevel modifier and apply it."""
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_add(type='BEVEL')
        obj.modifiers["Bevel"].width = width
        obj.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
    
    def _create_material(self, name: str, color: tuple) -> bpy.types.Material:
        """Create a simple material with the given color."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (*color, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.7
        return mat
    
    def _set_origin_to_bottom(self, obj: bpy.types.Object) -> None:
        """Set object origin to bottom center."""
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
        
        # Move origin to bottom
        bbox = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        min_z = min(v.z for v in bbox)
        obj.location.z -= obj.location.z - min_z
        
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bpy.context.scene.cursor.location = (obj.location.x, obj.location.y, min_z)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bpy.context.scene.cursor.location = (0, 0, 0)


# Also create a fixed zombie generator
class FixedZombieGenerator:
    """Generate zombie variants with decay effects."""
    
    ZOMBIE_TYPES = {
        "zombie_walker": {
            "height": 1.70,
            "build": "decayed",
            "skin_tone": (0.45, 0.55, 0.40),  # Greenish
            "cloth_color": (0.25, 0.22, 0.20),
        },
        "zombie_runner": {
            "height": 1.68,
            "build": "lean",
            "skin_tone": (0.50, 0.52, 0.45),
            "cloth_color": (0.30, 0.25, 0.22),
        },
        "zombie_crawler": {
            "height": 0.50,  # Crawling height
            "build": "decayed",
            "skin_tone": (0.40, 0.48, 0.38),
            "cloth_color": (0.20, 0.18, 0.16),
        },
        "zombie_bloater": {
            "height": 1.60,
            "build": "bloated",
            "skin_tone": (0.55, 0.50, 0.42),
            "cloth_color": (0.22, 0.20, 0.18),
        },
        "zombie_screamer": {
            "height": 1.65,
            "build": "lean",
            "skin_tone": (0.48, 0.50, 0.45),
            "cloth_color": (0.28, 0.25, 0.22),
        },
        "zombie_spitter": {
            "height": 1.72,
            "build": "decayed",
            "skin_tone": (0.42, 0.52, 0.35),  # More green
            "cloth_color": (0.25, 0.22, 0.18),
        },
        "zombie_brute": {
            "height": 2.10,
            "build": "massive",
            "skin_tone": (0.50, 0.48, 0.42),
            "cloth_color": (0.18, 0.16, 0.14),
        },
        "zombie_ravager": {
            "height": 1.95,
            "build": "muscular",
            "skin_tone": (0.45, 0.42, 0.38),
            "cloth_color": (0.15, 0.13, 0.12),
        },
    }
    
    BUILDS = {
        "lean": {"width": 0.85, "depth": 0.8, "muscle": 0.85},
        "decayed": {"width": 0.9, "depth": 0.85, "muscle": 0.8},
        "bloated": {"width": 1.5, "depth": 1.4, "muscle": 0.7},
        "muscular": {"width": 1.2, "depth": 1.1, "muscle": 1.3},
        "massive": {"width": 1.5, "depth": 1.3, "muscle": 1.5},
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
        self.char_gen = FixedCharacterGenerator(seed)
    
    def generate(self, name: str, zombie_type: str = "zombie_walker") -> bpy.types.Object:
        """Generate a zombie with decay effects."""
        config = self.ZOMBIE_TYPES.get(zombie_type, self.ZOMBIE_TYPES["zombie_walker"])
        build = self.BUILDS.get(config["build"], self.BUILDS["decayed"])
        
        # Use the character generator as base
        char_config = {
            "height": config["height"],
            "build": config["build"],
            "skin_tone": config["skin_tone"],
            "clothing_color": config["cloth_color"],
            "accent_color": (0.3, 0.15, 0.1),  # Blood/dirt
        }
        
        # Temporarily add this config
        self.char_gen.CHARACTER_TYPES["_zombie_temp"] = char_config
        self.char_gen.BUILDS[config["build"]] = build
        
        zombie = self.char_gen.generate(name, "_zombie_temp")
        
        # Add zombie-specific deformation
        self._add_decay_effects(zombie, zombie_type)
        
        return zombie
    
    def _add_decay_effects(self, zombie: bpy.types.Object, zombie_type: str) -> None:
        """Add decay/horror effects to zombie mesh."""
        bm = bmesh.new()
        bm.from_mesh(zombie.data)
        
        # Random vertex displacement for decayed look
        for v in bm.verts:
            offset = random.uniform(-0.02, 0.02)
            v.co.x += offset
            v.co.y += offset * 0.5
        
        # Asymmetric posture (lean to one side)
        lean_angle = random.uniform(-0.1, 0.1)
        for v in bm.verts:
            if v.co.z > 0.5:  # Upper body
                v.co.x += lean_angle * (v.co.z - 0.5)
        
        bm.to_mesh(zombie.data)
        bm.free()
