"""
Production-Quality Character Generator
Creates detailed humanoid characters matching mobile game quality (LDOE style).

Features:
- Proper humanoid silhouette with all limbs
- Clothing and gear geometry
- Facial features
- Correct origin at feet
- Optimized for game engines
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector, Matrix


class ProductionCharacterGenerator:
    """Generate production-quality humanoid characters."""
    
    CHARACTER_CONFIGS = {
        "survivor_male": {
            "height": 1.80,
            "build": "athletic",
            "skin": (0.82, 0.70, 0.55, 1.0),
            "shirt": (0.25, 0.32, 0.22, 1.0),      # Olive green
            "pants": (0.28, 0.25, 0.20, 1.0),      # Brown
            "boots": (0.15, 0.12, 0.10, 1.0),      # Dark brown
            "hair": (0.15, 0.10, 0.08, 1.0),       # Dark brown
            "gear": (0.35, 0.30, 0.25, 1.0),       # Tan gear
        },
        "survivor_female": {
            "height": 1.68,
            "build": "lean",
            "skin": (0.85, 0.72, 0.58, 1.0),
            "shirt": (0.60, 0.25, 0.25, 1.0),      # Maroon
            "pants": (0.20, 0.22, 0.28, 1.0),      # Dark blue
            "boots": (0.12, 0.10, 0.10, 1.0),
            "hair": (0.45, 0.25, 0.15, 1.0),       # Auburn
            "gear": (0.30, 0.28, 0.25, 1.0),
        },
        "npc_trader": {
            "height": 1.75,
            "build": "stocky",
            "skin": (0.75, 0.62, 0.50, 1.0),
            "shirt": (0.55, 0.45, 0.30, 1.0),      # Tan/khaki
            "pants": (0.35, 0.30, 0.22, 1.0),
            "boots": (0.20, 0.15, 0.10, 1.0),
            "hair": (0.25, 0.20, 0.15, 1.0),
            "gear": (0.50, 0.40, 0.25, 1.0),       # Gold-ish
        },
        "npc_mechanic": {
            "height": 1.82,
            "build": "muscular",
            "skin": (0.70, 0.55, 0.42, 1.0),
            "shirt": (0.20, 0.25, 0.35, 1.0),      # Blue coveralls
            "pants": (0.20, 0.25, 0.35, 1.0),      # Matching
            "boots": (0.10, 0.10, 0.10, 1.0),
            "hair": (0.08, 0.06, 0.05, 1.0),       # Black
            "gear": (0.60, 0.35, 0.15, 1.0),       # Orange accents
        },
        "raider_scout": {
            "height": 1.75,
            "build": "lean",
            "skin": (0.72, 0.58, 0.45, 1.0),
            "shirt": (0.12, 0.12, 0.12, 1.0),      # Black
            "pants": (0.10, 0.10, 0.10, 1.0),
            "boots": (0.08, 0.08, 0.08, 1.0),
            "hair": (0.05, 0.05, 0.05, 1.0),
            "gear": (0.50, 0.15, 0.10, 1.0),       # Red accents
        },
        "raider_heavy": {
            "height": 1.95,
            "build": "heavy",
            "skin": (0.68, 0.52, 0.40, 1.0),
            "shirt": (0.15, 0.12, 0.10, 1.0),
            "pants": (0.12, 0.10, 0.08, 1.0),
            "boots": (0.10, 0.08, 0.06, 1.0),
            "hair": (0.0, 0.0, 0.0, 1.0),          # Bald
            "gear": (0.40, 0.38, 0.35, 1.0),       # Metal
        },
    }
    
    BUILD_PARAMS = {
        "lean": {"shoulder_w": 0.38, "chest_d": 0.18, "waist_w": 0.28, "hip_w": 0.32, "limb_thick": 0.85},
        "athletic": {"shoulder_w": 0.42, "chest_d": 0.22, "waist_w": 0.32, "hip_w": 0.35, "limb_thick": 1.0},
        "stocky": {"shoulder_w": 0.46, "chest_d": 0.26, "waist_w": 0.38, "hip_w": 0.40, "limb_thick": 1.15},
        "muscular": {"shoulder_w": 0.48, "chest_d": 0.25, "waist_w": 0.35, "hip_w": 0.38, "limb_thick": 1.2},
        "heavy": {"shoulder_w": 0.52, "chest_d": 0.30, "waist_w": 0.42, "hip_w": 0.45, "limb_thick": 1.3},
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, char_type: str = "survivor_male") -> bpy.types.Object:
        """Generate a complete production-quality character."""
        config = self.CHARACTER_CONFIGS.get(char_type, self.CHARACTER_CONFIGS["survivor_male"])
        build = self.BUILD_PARAMS.get(config["build"], self.BUILD_PARAMS["athletic"])
        height = config["height"]
        
        # Create materials
        mats = {
            "skin": self._create_material(f"{name}_skin", config["skin"]),
            "shirt": self._create_material(f"{name}_shirt", config["shirt"]),
            "pants": self._create_material(f"{name}_pants", config["pants"]),
            "boots": self._create_material(f"{name}_boots", config["boots"]),
            "hair": self._create_material(f"{name}_hair", config["hair"]),
            "gear": self._create_material(f"{name}_gear", config["gear"]),
        }
        
        # All parts will be collected here
        all_parts = []
        
        # Calculate body segment heights (proportion-based)
        segments = {
            "foot_h": height * 0.04,
            "ankle_h": height * 0.03,
            "shin_h": height * 0.20,
            "knee_h": height * 0.03,
            "thigh_h": height * 0.22,
            "pelvis_h": height * 0.08,
            "abdomen_h": height * 0.08,
            "chest_h": height * 0.14,
            "shoulder_h": height * 0.04,
            "neck_h": height * 0.04,
            "head_h": height * 0.12,
        }
        
        # Build from ground up, tracking Z position
        z = 0.0
        
        # ========== FEET ==========
        foot_length = height * 0.15
        foot_width = height * 0.06 * build["limb_thick"]
        for side in [-1, 1]:
            foot = self._create_foot(foot_length, foot_width, segments["foot_h"])
            foot.location = Vector((
                side * build["hip_w"] * height * 0.5,
                foot_length * 0.2,  # Slightly forward
                segments["foot_h"] * 0.5
            ))
            self._apply_material(foot, mats["boots"])
            all_parts.append(foot)
        z += segments["foot_h"]
        
        # ========== LOWER LEGS (SHINS) ==========
        shin_radius = height * 0.04 * build["limb_thick"]
        for side in [-1, 1]:
            shin = self._create_limb_segment(
                radius_top=shin_radius * 1.1,
                radius_bot=shin_radius * 0.85,
                length=segments["shin_h"],
                segments=8
            )
            shin.location = Vector((
                side * build["hip_w"] * height * 0.5,
                0,
                z + segments["shin_h"] * 0.5
            ))
            self._apply_material(shin, mats["pants"])
            all_parts.append(shin)
            
            # Knee pad/detail
            knee = self._create_sphere(shin_radius * 1.2, segments=8)
            knee.location = Vector((
                side * build["hip_w"] * height * 0.5,
                shin_radius * 0.3,
                z + segments["shin_h"]
            ))
            self._apply_material(knee, mats["pants"])
            all_parts.append(knee)
        z += segments["shin_h"] + segments["knee_h"]
        
        # ========== UPPER LEGS (THIGHS) ==========
        thigh_radius = height * 0.055 * build["limb_thick"]
        for side in [-1, 1]:
            thigh = self._create_limb_segment(
                radius_top=thigh_radius * 1.2,
                radius_bot=thigh_radius * 0.9,
                length=segments["thigh_h"],
                segments=8
            )
            thigh.location = Vector((
                side * build["hip_w"] * height * 0.48,
                0,
                z + segments["thigh_h"] * 0.5
            ))
            self._apply_material(thigh, mats["pants"])
            all_parts.append(thigh)
        z += segments["thigh_h"]
        
        # ========== PELVIS / HIPS ==========
        pelvis = self._create_pelvis(
            width=build["hip_w"] * height * 1.1,
            depth=build["chest_d"] * height * 0.9,
            height_val=segments["pelvis_h"],
            build=build
        )
        pelvis.location = Vector((0, 0, z + segments["pelvis_h"] * 0.5))
        self._apply_material(pelvis, mats["pants"])
        all_parts.append(pelvis)
        
        # Belt
        belt = self._create_belt(build["hip_w"] * height * 1.15, build["chest_d"] * height * 0.95, height * 0.025)
        belt.location = Vector((0, 0, z + segments["pelvis_h"] * 0.8))
        self._apply_material(belt, mats["gear"])
        all_parts.append(belt)
        z += segments["pelvis_h"]
        
        # ========== ABDOMEN ==========
        abdomen = self._create_torso_section(
            top_width=build["waist_w"] * height * 1.1,
            bot_width=build["hip_w"] * height * 1.05,
            depth=build["chest_d"] * height * 0.85,
            height_val=segments["abdomen_h"]
        )
        abdomen.location = Vector((0, 0, z + segments["abdomen_h"] * 0.5))
        self._apply_material(abdomen, mats["shirt"])
        all_parts.append(abdomen)
        z += segments["abdomen_h"]
        
        # ========== CHEST ==========
        chest = self._create_chest(
            shoulder_w=build["shoulder_w"] * height,
            waist_w=build["waist_w"] * height * 1.1,
            depth=build["chest_d"] * height,
            height_val=segments["chest_h"],
            build=build
        )
        chest.location = Vector((0, 0, z + segments["chest_h"] * 0.5))
        self._apply_material(chest, mats["shirt"])
        all_parts.append(chest)
        
        # Store shoulder position for arms
        shoulder_z = z + segments["chest_h"] * 0.85
        arm_x = build["shoulder_w"] * height * 0.55
        z += segments["chest_h"]
        
        # ========== SHOULDERS ==========
        shoulder_radius = height * 0.045 * build["limb_thick"]
        for side in [-1, 1]:
            shoulder = self._create_sphere(shoulder_radius, segments=8)
            shoulder.location = Vector((side * arm_x, 0, shoulder_z))
            self._apply_material(shoulder, mats["shirt"])
            all_parts.append(shoulder)
        
        # ========== ARMS ==========
        upper_arm_len = height * 0.16
        lower_arm_len = height * 0.14
        arm_radius = height * 0.035 * build["limb_thick"]
        
        for side in [-1, 1]:
            arm_z = shoulder_z
            
            # Upper arm
            upper_arm = self._create_limb_segment(
                radius_top=arm_radius * 1.15,
                radius_bot=arm_radius * 0.9,
                length=upper_arm_len,
                segments=8
            )
            arm_z -= upper_arm_len * 0.5
            upper_arm.location = Vector((side * arm_x, 0, arm_z))
            self._apply_material(upper_arm, mats["shirt"])
            all_parts.append(upper_arm)
            arm_z -= upper_arm_len * 0.5
            
            # Elbow
            elbow = self._create_sphere(arm_radius * 1.0, segments=6)
            elbow.location = Vector((side * arm_x, 0, arm_z))
            self._apply_material(elbow, mats["skin"])
            all_parts.append(elbow)
            
            # Lower arm (forearm)
            forearm = self._create_limb_segment(
                radius_top=arm_radius * 0.95,
                radius_bot=arm_radius * 0.7,
                length=lower_arm_len,
                segments=8
            )
            arm_z -= lower_arm_len * 0.5
            forearm.location = Vector((side * arm_x, 0, arm_z))
            self._apply_material(forearm, mats["skin"])
            all_parts.append(forearm)
            arm_z -= lower_arm_len * 0.5
            
            # Hand
            hand = self._create_hand(height * 0.09, height * 0.045, height * 0.025)
            hand.location = Vector((side * arm_x, 0, arm_z - height * 0.02))
            self._apply_material(hand, mats["skin"])
            all_parts.append(hand)
        
        # ========== NECK ==========
        neck_radius = height * 0.035
        neck = self._create_limb_segment(
            radius_top=neck_radius,
            radius_bot=neck_radius * 1.2,
            length=segments["neck_h"],
            segments=8
        )
        neck.location = Vector((0, 0, z + segments["neck_h"] * 0.5))
        self._apply_material(neck, mats["skin"])
        all_parts.append(neck)
        z += segments["neck_h"]
        
        # ========== HEAD ==========
        head_parts = self._create_detailed_head(
            height=segments["head_h"],
            width=segments["head_h"] * 0.85,
            depth=segments["head_h"] * 0.9,
            mats=mats,
            has_hair=(config["hair"][3] > 0)  # Check if not bald
        )
        for part in head_parts:
            part.location.z += z + segments["head_h"] * 0.45
        all_parts.extend(head_parts)
        
        # ========== GEAR / ACCESSORIES ==========
        gear_parts = self._add_tactical_gear(height, build, shoulder_z, mats)
        all_parts.extend(gear_parts)
        
        # ========== JOIN ALL PARTS ==========
        bpy.ops.object.select_all(action='DESELECT')
        for part in all_parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = all_parts[0]
        bpy.ops.object.join()
        
        character = bpy.context.active_object
        character.name = name
        
        # Set origin to ground level (bottom of feet)
        self._set_origin_to_ground(character)
        
        # Apply smooth shading
        bpy.ops.object.shade_smooth()
        
        return character
    
    def _create_foot(self, length: float, width: float, height: float) -> bpy.types.Object:
        """Create a detailed foot/boot shape."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        foot = bpy.context.active_object
        foot.scale = (width, length, height)
        bpy.ops.object.transform_apply(scale=True)
        
        # Shape the foot - rounded front, flat back
        bm = bmesh.new()
        bm.from_mesh(foot.data)
        
        for v in bm.verts:
            # Taper the toe area
            if v.co.y > length * 0.3:
                taper = 1.0 - (v.co.y - length * 0.3) / (length * 0.7) * 0.4
                v.co.x *= taper
                v.co.z *= 0.8 + 0.2 * taper
            # Round the heel
            if v.co.y < -length * 0.3:
                v.co.z *= 0.9
        
        bm.to_mesh(foot.data)
        bm.free()
        
        return foot
    
    def _create_limb_segment(self, radius_top: float, radius_bot: float, length: float, segments: int = 8) -> bpy.types.Object:
        """Create a tapered cylinder for limb segments."""
        bpy.ops.mesh.primitive_cylinder_add(vertices=segments, radius=radius_top, depth=length)
        obj = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        # Taper bottom
        scale = radius_bot / radius_top
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= scale
                v.co.y *= scale
        
        bm.to_mesh(obj.data)
        bm.free()
        
        return obj
    
    def _create_sphere(self, radius: float, segments: int = 8) -> bpy.types.Object:
        """Create a UV sphere."""
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=segments//2, radius=radius)
        return bpy.context.active_object
    
    def _create_pelvis(self, width: float, depth: float, height_val: float, build: dict) -> bpy.types.Object:
        """Create pelvis/hip region."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.scale = (width, depth, height_val)
        bpy.ops.object.transform_apply(scale=True)
        
        # Round it out
        bpy.ops.object.modifier_add(type='BEVEL')
        obj.modifiers["Bevel"].width = min(width, depth, height_val) * 0.15
        obj.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return obj
    
    def _create_belt(self, width: float, depth: float, height: float) -> bpy.types.Object:
        """Create a belt around the waist."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        belt = bpy.context.active_object
        belt.scale = (width * 1.05, depth * 1.05, height)
        bpy.ops.object.transform_apply(scale=True)
        return belt
    
    def _create_torso_section(self, top_width: float, bot_width: float, depth: float, height_val: float) -> bpy.types.Object:
        """Create a torso section that tapers."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.scale = (top_width, depth, height_val)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        # Taper bottom to match hips
        scale = bot_width / top_width
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= scale
        
        bm.to_mesh(obj.data)
        bm.free()
        
        return obj
    
    def _create_chest(self, shoulder_w: float, waist_w: float, depth: float, height_val: float, build: dict) -> bpy.types.Object:
        """Create detailed chest with muscle definition."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.scale = (shoulder_w, depth, height_val)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        for v in bm.verts:
            # Taper to waist at bottom
            if v.co.z < 0:
                t = (v.co.z + height_val/2) / (height_val/2)  # 0 at bottom, 1 at middle
                v.co.x *= (waist_w/shoulder_w) + (1 - waist_w/shoulder_w) * t
            
            # Chest expansion at front-top
            if v.co.y > 0 and v.co.z > 0:
                v.co.y += depth * 0.15 * build["limb_thick"] * (v.co.z / (height_val/2))
            
            # Back muscle definition
            if v.co.y < 0 and v.co.z > 0:
                v.co.y -= depth * 0.05
        
        bm.to_mesh(obj.data)
        bm.free()
        
        # Bevel for smoother look
        bpy.ops.object.modifier_add(type='BEVEL')
        obj.modifiers["Bevel"].width = 0.02
        obj.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return obj
    
    def _create_hand(self, length: float, width: float, depth: float) -> bpy.types.Object:
        """Create a simplified hand shape."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        hand = bpy.context.active_object
        hand.scale = (width, depth, length)
        bpy.ops.object.transform_apply(scale=True)
        
        # Taper toward fingers
        bm = bmesh.new()
        bm.from_mesh(hand.data)
        for v in bm.verts:
            if v.co.z < 0:  # Finger end
                v.co.x *= 0.7
                v.co.y *= 0.6
        bm.to_mesh(hand.data)
        bm.free()
        
        return hand
    
    def _create_detailed_head(self, height: float, width: float, depth: float, mats: dict, has_hair: bool) -> list:
        """Create a detailed head with facial features."""
        parts = []
        
        # Main head shape
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=height * 0.5)
        head = bpy.context.active_object
        head.scale = (width / height, depth / height, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        
        # Shape the jaw
        bm = bmesh.new()
        bm.from_mesh(head.data)
        for v in bm.verts:
            # Narrow the jaw
            if v.co.z < -height * 0.15:
                factor = 1.0 - (abs(v.co.z + height * 0.15) / (height * 0.35)) * 0.35
                v.co.x *= max(0.5, factor)
                v.co.y *= max(0.6, factor)
            # Flatten the back slightly
            if v.co.y < -depth * 0.3:
                v.co.y *= 0.9
        bm.to_mesh(head.data)
        bm.free()
        
        self._apply_material(head, mats["skin"])
        parts.append(head)
        
        # Eyes
        eye_size = height * 0.06
        eye_y = depth * 0.35
        eye_z = height * 0.08
        for side in [-1, 1]:
            eye = self._create_sphere(eye_size, segments=6)
            eye.location = Vector((side * width * 0.22, eye_y, eye_z))
            self._apply_material(eye, mats["gear"])  # Dark eyes
            parts.append(eye)
        
        # Nose
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=height * 0.04, depth=height * 0.08)
        nose = bpy.context.active_object
        nose.rotation_euler = (math.radians(90), 0, 0)
        nose.location = Vector((0, depth * 0.42, height * 0.0))
        bpy.ops.object.transform_apply(rotation=True)
        self._apply_material(nose, mats["skin"])
        parts.append(nose)
        
        # Ears
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=height * 0.06)
            ear = bpy.context.active_object
            ear.scale = (0.4, 0.6, 1.0)
            ear.location = Vector((side * width * 0.48, -depth * 0.05, height * 0.05))
            bpy.ops.object.transform_apply(scale=True)
            self._apply_material(ear, mats["skin"])
            parts.append(ear)
        
        # Hair (if not bald)
        if has_hair:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=height * 0.52)
            hair = bpy.context.active_object
            hair.scale = (width / height * 1.02, depth / height * 0.95, 0.7)
            hair.location = Vector((0, -depth * 0.05, height * 0.15))
            bpy.ops.object.transform_apply(scale=True)
            
            # Cut the bottom half
            bm = bmesh.new()
            bm.from_mesh(hair.data)
            verts_to_delete = [v for v in bm.verts if v.co.z < 0]
            bmesh.ops.delete(bm, geom=verts_to_delete, context='VERTS')
            bm.to_mesh(hair.data)
            bm.free()
            
            self._apply_material(hair, mats["hair"])
            parts.append(hair)
        
        return parts
    
    def _add_tactical_gear(self, height: float, build: dict, shoulder_z: float, mats: dict) -> list:
        """Add tactical vest, pouches, and gear."""
        parts = []
        
        chest_z = shoulder_z - height * 0.08
        
        # Tactical vest base
        vest_w = build["shoulder_w"] * height * 0.95
        vest_d = build["chest_d"] * height * 1.1
        vest_h = height * 0.18
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        vest = bpy.context.active_object
        vest.scale = (vest_w, vest_d, vest_h)
        vest.location = Vector((0, 0, chest_z))
        bpy.ops.object.transform_apply(scale=True)
        self._apply_material(vest, mats["gear"])
        parts.append(vest)
        
        # Front pouches (3 across)
        pouch_size = height * 0.04
        for i in range(3):
            bpy.ops.mesh.primitive_cube_add(size=pouch_size)
            pouch = bpy.context.active_object
            pouch.scale = (1.0, 0.6, 1.2)
            pouch.location = Vector((
                (i - 1) * pouch_size * 1.5,
                vest_d * 0.55,
                chest_z - vest_h * 0.2
            ))
            bpy.ops.object.transform_apply(scale=True)
            self._apply_material(pouch, mats["gear"])
            parts.append(pouch)
        
        # Side pouches
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(size=pouch_size * 0.8)
            pouch = bpy.context.active_object
            pouch.scale = (0.8, 1.0, 1.5)
            pouch.location = Vector((
                side * vest_w * 0.52,
                0,
                chest_z - vest_h * 0.3
            ))
            bpy.ops.object.transform_apply(scale=True)
            self._apply_material(pouch, mats["gear"])
            parts.append(pouch)
        
        # Shoulder straps
        strap_w = height * 0.03
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(size=1)
            strap = bpy.context.active_object
            strap.scale = (strap_w, vest_d * 0.4, vest_h * 1.2)
            strap.location = Vector((
                side * vest_w * 0.35,
                0,
                chest_z + vest_h * 0.1
            ))
            bpy.ops.object.transform_apply(scale=True)
            self._apply_material(strap, mats["gear"])
            parts.append(strap)
        
        return parts
    
    def _apply_material(self, obj: bpy.types.Object, mat: bpy.types.Material) -> None:
        """Apply material to object."""
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)
    
    def _create_material(self, name: str, color: tuple) -> bpy.types.Material:
        """Create a PBR material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = color
            bsdf.inputs["Roughness"].default_value = 0.65
            bsdf.inputs["Metallic"].default_value = 0.0
        return mat
    
    def _set_origin_to_ground(self, obj: bpy.types.Object) -> None:
        """Set origin to the lowest point of the mesh (ground level)."""
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        
        # Apply transforms first
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        
        # Find the lowest Z coordinate
        mesh = obj.data
        if len(mesh.vertices) == 0:
            return
        
        min_z = min((obj.matrix_world @ v.co).z for v in mesh.vertices)
        
        # Set cursor to ground point
        bpy.context.scene.cursor.location = (0, 0, min_z)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        
        # Move object so origin is at world origin
        obj.location.z = -min_z
        bpy.ops.object.transform_apply(location=True)
        
        # Reset cursor
        bpy.context.scene.cursor.location = (0, 0, 0)


class ProductionZombieGenerator:
    """Generate detailed zombie characters."""
    
    ZOMBIE_CONFIGS = {
        "zombie_walker": {
            "height": 1.72,
            "build": "decayed",
            "skin": (0.45, 0.52, 0.38, 1.0),
            "shirt": (0.30, 0.25, 0.22, 1.0),
            "pants": (0.25, 0.22, 0.20, 1.0),
        },
        "zombie_runner": {
            "height": 1.70,
            "build": "lean",
            "skin": (0.50, 0.55, 0.42, 1.0),
            "shirt": (0.35, 0.28, 0.25, 1.0),
            "pants": (0.28, 0.25, 0.22, 1.0),
        },
        "zombie_crawler": {
            "height": 0.60,  # Crawling
            "build": "decayed",
            "skin": (0.40, 0.48, 0.35, 1.0),
            "shirt": (0.25, 0.22, 0.20, 1.0),
            "pants": (0.22, 0.20, 0.18, 1.0),
        },
        "zombie_bloater": {
            "height": 1.65,
            "build": "bloated",
            "skin": (0.55, 0.50, 0.40, 1.0),
            "shirt": (0.28, 0.25, 0.22, 1.0),
            "pants": (0.25, 0.22, 0.20, 1.0),
        },
        "zombie_screamer": {
            "height": 1.68,
            "build": "lean",
            "skin": (0.48, 0.52, 0.42, 1.0),
            "shirt": (0.32, 0.28, 0.25, 1.0),
            "pants": (0.28, 0.25, 0.22, 1.0),
        },
        "zombie_spitter": {
            "height": 1.74,
            "build": "decayed",
            "skin": (0.42, 0.55, 0.35, 1.0),
            "shirt": (0.28, 0.25, 0.22, 1.0),
            "pants": (0.25, 0.22, 0.20, 1.0),
        },
        "zombie_brute": {
            "height": 2.20,
            "build": "massive",
            "skin": (0.52, 0.48, 0.40, 1.0),
            "shirt": (0.22, 0.20, 0.18, 1.0),
            "pants": (0.20, 0.18, 0.16, 1.0),
        },
        "zombie_ravager": {
            "height": 2.00,
            "build": "muscular",
            "skin": (0.48, 0.45, 0.38, 1.0),
            "shirt": (0.20, 0.18, 0.16, 1.0),
            "pants": (0.18, 0.16, 0.14, 1.0),
        },
    }
    
    BUILD_PARAMS = {
        "lean": {"shoulder_w": 0.36, "chest_d": 0.16, "waist_w": 0.26, "hip_w": 0.30, "limb_thick": 0.8},
        "decayed": {"shoulder_w": 0.38, "chest_d": 0.18, "waist_w": 0.28, "hip_w": 0.32, "limb_thick": 0.85},
        "bloated": {"shoulder_w": 0.50, "chest_d": 0.35, "waist_w": 0.55, "hip_w": 0.50, "limb_thick": 1.3},
        "muscular": {"shoulder_w": 0.48, "chest_d": 0.25, "waist_w": 0.38, "hip_w": 0.40, "limb_thick": 1.25},
        "massive": {"shoulder_w": 0.55, "chest_d": 0.32, "waist_w": 0.45, "hip_w": 0.48, "limb_thick": 1.4},
    }
    
    def __init__(self, seed=None):
        self.char_gen = ProductionCharacterGenerator(seed)
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, zombie_type: str = "zombie_walker") -> bpy.types.Object:
        """Generate a zombie character."""
        config = self.ZOMBIE_CONFIGS.get(zombie_type, self.ZOMBIE_CONFIGS["zombie_walker"])
        build_name = config["build"]
        build = self.BUILD_PARAMS.get(build_name, self.BUILD_PARAMS["decayed"])
        
        # Create a temporary character config for the base generator
        temp_config = {
            "height": config["height"],
            "build": build_name,
            "skin": config["skin"],
            "shirt": config["shirt"],
            "pants": config["pants"],
            "boots": (0.15, 0.12, 0.10, 1.0),
            "hair": (0.0, 0.0, 0.0, 0.0),  # No hair (bald)
            "gear": (0.25, 0.22, 0.18, 1.0),
        }
        
        # Add temp config and build
        self.char_gen.CHARACTER_CONFIGS["_zombie_temp"] = temp_config
        self.char_gen.BUILD_PARAMS[build_name] = build
        
        # Generate base character
        zombie = self.char_gen.generate(name, "_zombie_temp")
        
        # Add zombie-specific deformation
        self._add_zombie_decay(zombie, zombie_type)
        
        return zombie
    
    def _add_zombie_decay(self, zombie: bpy.types.Object, zombie_type: str) -> None:
        """Add decay effects to zombie mesh."""
        bm = bmesh.new()
        bm.from_mesh(zombie.data)
        
        # Random vertex displacement for decay
        for v in bm.verts:
            displacement = random.uniform(-0.015, 0.015)
            v.co.x += displacement
            v.co.y += displacement * 0.8
            v.co.z += displacement * 0.5
        
        # Asymmetric lean (zombies don't stand straight)
        lean_factor = random.uniform(-0.08, 0.08)
        for v in bm.verts:
            if v.co.z > 0.8:
                v.co.x += lean_factor * (v.co.z - 0.8)
        
        # Special deformation for bloater
        if "bloater" in zombie_type:
            for v in bm.verts:
                if 0.4 < v.co.z < 1.2:  # Torso area
                    # Bloat outward
                    dist = math.sqrt(v.co.x**2 + v.co.y**2)
                    if dist > 0.05:
                        bloat = random.uniform(1.1, 1.3)
                        v.co.x *= bloat
                        v.co.y *= bloat
        
        bm.to_mesh(zombie.data)
        bm.free()
