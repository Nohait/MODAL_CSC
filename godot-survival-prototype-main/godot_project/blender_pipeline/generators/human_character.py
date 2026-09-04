"""
Human-Proportioned Character Generator
Uses proper anatomical ratios based on the "8 heads tall" standard.

Human Anatomy Reference (8 heads tall adult):
- Head: 1/8 of height
- Shoulders: ~2 head widths (NOT half the body height!)
- Torso (shoulders to crotch): ~3 heads
- Legs (crotch to ground): ~4 heads
- Arms: fingertips reach mid-thigh
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector


class HumanCharacterGenerator:
    """Generate properly proportioned human characters."""
    
    CHARACTER_CONFIGS = {
        "survivor_male": {
            "height": 1.80,
            "build": "athletic",
            "skin": (0.82, 0.70, 0.55, 1.0),
            "shirt": (0.28, 0.35, 0.25, 1.0),
            "pants": (0.30, 0.28, 0.22, 1.0),
            "boots": (0.18, 0.14, 0.10, 1.0),
            "hair": (0.18, 0.12, 0.08, 1.0),
        },
        "survivor_female": {
            "height": 1.68,
            "build": "lean_f",
            "skin": (0.85, 0.72, 0.58, 1.0),
            "shirt": (0.55, 0.22, 0.22, 1.0),
            "pants": (0.22, 0.24, 0.30, 1.0),
            "boots": (0.15, 0.12, 0.10, 1.0),
            "hair": (0.40, 0.22, 0.12, 1.0),
        },
        "npc_trader": {
            "height": 1.75,
            "build": "stocky",
            "skin": (0.75, 0.62, 0.50, 1.0),
            "shirt": (0.50, 0.42, 0.28, 1.0),
            "pants": (0.38, 0.32, 0.24, 1.0),
            "boots": (0.22, 0.18, 0.12, 1.0),
            "hair": (0.28, 0.22, 0.16, 1.0),
        },
        "npc_mechanic": {
            "height": 1.82,
            "build": "muscular",
            "skin": (0.72, 0.58, 0.45, 1.0),
            "shirt": (0.22, 0.28, 0.38, 1.0),
            "pants": (0.22, 0.28, 0.38, 1.0),
            "boots": (0.12, 0.12, 0.12, 1.0),
            "hair": (0.10, 0.08, 0.06, 1.0),
        },
        "raider_scout": {
            "height": 1.76,
            "build": "lean",
            "skin": (0.72, 0.58, 0.45, 1.0),
            "shirt": (0.15, 0.14, 0.14, 1.0),
            "pants": (0.12, 0.12, 0.12, 1.0),
            "boots": (0.10, 0.10, 0.10, 1.0),
            "hair": (0.08, 0.06, 0.05, 1.0),
        },
        "raider_heavy": {
            "height": 1.92,
            "build": "heavy",
            "skin": (0.68, 0.54, 0.42, 1.0),
            "shirt": (0.18, 0.15, 0.12, 1.0),
            "pants": (0.15, 0.12, 0.10, 1.0),
            "boots": (0.12, 0.10, 0.08, 1.0),
            "hair": (0.0, 0.0, 0.0, 1.0),  # Bald
        },
    }
    
    # Build modifiers - these are MULTIPLIERS for the base proportions
    # Keep them close to 1.0 for natural look
    BUILD_PARAMS = {
        "lean":     {"bulk": 0.90, "muscle": 0.95},
        "lean_f":   {"bulk": 0.85, "muscle": 0.90},
        "athletic": {"bulk": 1.00, "muscle": 1.05},
        "stocky":   {"bulk": 1.10, "muscle": 1.00},
        "muscular": {"bulk": 1.08, "muscle": 1.15},
        "heavy":    {"bulk": 1.20, "muscle": 1.10},
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, char_type: str = "survivor_male") -> bpy.types.Object:
        """Generate a properly proportioned human character."""
        config = self.CHARACTER_CONFIGS.get(char_type, self.CHARACTER_CONFIGS["survivor_male"])
        build = self.BUILD_PARAMS.get(config["build"], self.BUILD_PARAMS["athletic"])
        
        H = config["height"]  # Total height
        
        # ============================================================
        # PROPER HUMAN PROPORTIONS (8 heads tall system)
        # ============================================================
        head_size = H / 8.0  # One "head unit"
        
        # Widths (based on head units, NOT height!)
        shoulder_width = head_size * 2.2 * build["bulk"]   # ~2.2 heads wide
        chest_width = head_size * 2.0 * build["bulk"]
        waist_width = head_size * 1.4 * build["bulk"]
        hip_width = head_size * 1.6 * build["bulk"]
        
        # Depths (front to back)
        chest_depth = head_size * 0.9 * build["bulk"]
        waist_depth = head_size * 0.7 * build["bulk"]
        hip_depth = head_size * 0.85 * build["bulk"]
        
        # Vertical segments
        head_h = head_size
        neck_h = head_size * 0.3
        shoulder_h = head_size * 0.25
        chest_h = head_size * 1.2
        waist_h = head_size * 0.8
        hip_h = head_size * 0.6
        
        upper_leg_h = head_size * 2.0
        lower_leg_h = head_size * 1.8
        foot_h = head_size * 0.25
        
        upper_arm_h = head_size * 1.4
        lower_arm_h = head_size * 1.2
        hand_h = head_size * 0.7
        
        # Limb thicknesses
        thigh_radius = head_size * 0.35 * build["bulk"]
        calf_radius = head_size * 0.25 * build["bulk"]
        upper_arm_radius = head_size * 0.22 * build["muscle"]
        forearm_radius = head_size * 0.18 * build["muscle"]
        
        # Create materials
        mats = self._create_materials(name, config)
        
        all_parts = []
        z = 0.0  # Build from ground up
        
        # ============================================================
        # FEET
        # ============================================================
        foot_length = head_size * 1.1
        foot_width = head_size * 0.4
        for side in [-1, 1]:
            foot = self._create_box(foot_width, foot_length, foot_h)
            foot.location = Vector((side * hip_width * 0.28, foot_length * 0.15, foot_h * 0.5))
            self._apply_mat(foot, mats["boots"])
            all_parts.append(foot)
        z += foot_h
        
        # ============================================================
        # LOWER LEGS (CALVES)
        # ============================================================
        for side in [-1, 1]:
            calf = self._create_limb(calf_radius, calf_radius * 0.85, lower_leg_h)
            calf.location = Vector((side * hip_width * 0.28, 0, z + lower_leg_h * 0.5))
            self._apply_mat(calf, mats["pants"])
            all_parts.append(calf)
        z += lower_leg_h
        
        # ============================================================
        # KNEES
        # ============================================================
        knee_r = calf_radius * 1.1
        for side in [-1, 1]:
            knee = self._create_sphere(knee_r, 8)
            knee.location = Vector((side * hip_width * 0.28, 0, z))
            self._apply_mat(knee, mats["pants"])
            all_parts.append(knee)
        
        # ============================================================
        # UPPER LEGS (THIGHS)
        # ============================================================
        for side in [-1, 1]:
            thigh = self._create_limb(thigh_radius, calf_radius * 1.0, upper_leg_h)
            thigh.location = Vector((side * hip_width * 0.26, 0, z + upper_leg_h * 0.5))
            self._apply_mat(thigh, mats["pants"])
            all_parts.append(thigh)
        z += upper_leg_h
        
        # ============================================================
        # HIPS / PELVIS
        # ============================================================
        hips = self._create_body_section(hip_width, hip_depth, hip_h, hip_width * 0.95, hip_depth * 0.95)
        hips.location = Vector((0, 0, z + hip_h * 0.5))
        self._apply_mat(hips, mats["pants"])
        all_parts.append(hips)
        z += hip_h
        
        # ============================================================
        # WAIST / ABDOMEN
        # ============================================================
        abdomen = self._create_body_section(waist_width, waist_depth, waist_h, hip_width * 0.9, hip_depth * 0.9)
        abdomen.location = Vector((0, 0, z + waist_h * 0.5))
        self._apply_mat(abdomen, mats["shirt"])
        all_parts.append(abdomen)
        z += waist_h
        
        # ============================================================
        # CHEST / TORSO
        # ============================================================
        chest = self._create_chest_mesh(shoulder_width, chest_width, chest_depth, chest_h, waist_width, waist_depth, build)
        chest.location = Vector((0, 0, z + chest_h * 0.5))
        self._apply_mat(chest, mats["shirt"])
        all_parts.append(chest)
        
        shoulder_z = z + chest_h * 0.9  # Where arms attach
        z += chest_h
        
        # ============================================================
        # SHOULDERS
        # ============================================================
        shoulder_r = upper_arm_radius * 1.3
        arm_attach_x = shoulder_width * 0.48
        for side in [-1, 1]:
            shoulder = self._create_sphere(shoulder_r, 8)
            shoulder.location = Vector((side * arm_attach_x, 0, shoulder_z))
            self._apply_mat(shoulder, mats["shirt"])
            all_parts.append(shoulder)
        
        # ============================================================
        # ARMS
        # ============================================================
        for side in [-1, 1]:
            arm_z = shoulder_z
            arm_x = side * arm_attach_x
            
            # Upper arm
            upper_arm = self._create_limb(upper_arm_radius, forearm_radius * 1.05, upper_arm_h)
            arm_z -= upper_arm_h * 0.5
            upper_arm.location = Vector((arm_x, 0, arm_z))
            self._apply_mat(upper_arm, mats["shirt"])
            all_parts.append(upper_arm)
            arm_z -= upper_arm_h * 0.5
            
            # Elbow
            elbow = self._create_sphere(forearm_radius * 1.1, 6)
            elbow.location = Vector((arm_x, 0, arm_z))
            self._apply_mat(elbow, mats["skin"])
            all_parts.append(elbow)
            
            # Forearm
            forearm = self._create_limb(forearm_radius, forearm_radius * 0.75, lower_arm_h)
            arm_z -= lower_arm_h * 0.5
            forearm.location = Vector((arm_x, 0, arm_z))
            self._apply_mat(forearm, mats["skin"])
            all_parts.append(forearm)
            arm_z -= lower_arm_h * 0.5
            
            # Hand
            hand = self._create_box(hand_h * 0.5, hand_h * 0.3, hand_h)
            hand.location = Vector((arm_x, 0, arm_z - hand_h * 0.4))
            self._apply_mat(hand, mats["skin"])
            all_parts.append(hand)
        
        # ============================================================
        # NECK
        # ============================================================
        neck_r = head_size * 0.22
        neck = self._create_limb(neck_r, neck_r * 1.1, neck_h)
        neck.location = Vector((0, 0, z + neck_h * 0.5))
        self._apply_mat(neck, mats["skin"])
        all_parts.append(neck)
        z += neck_h
        
        # ============================================================
        # HEAD
        # ============================================================
        head_parts = self._create_head(head_size, mats, has_hair=(config["hair"][0] > 0.01))
        for part in head_parts:
            part.location.z += z + head_h * 0.45
        all_parts.extend(head_parts)
        
        # ============================================================
        # JOIN ALL & FINALIZE
        # ============================================================
        bpy.ops.object.select_all(action='DESELECT')
        for part in all_parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = all_parts[0]
        bpy.ops.object.join()
        
        character = bpy.context.active_object
        character.name = name
        
        # Set origin to ground
        self._set_origin_to_ground(character)
        
        # Smooth shading
        bpy.ops.object.shade_smooth()
        
        return character
    
    def _create_box(self, width: float, depth: float, height: float) -> bpy.types.Object:
        """Create a box (X=width, Y=depth, Z=height)."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.scale = (width, depth, height)
        bpy.ops.object.transform_apply(scale=True)
        return obj
    
    def _create_limb(self, radius_top: float, radius_bot: float, length: float) -> bpy.types.Object:
        """Create a tapered cylinder for limbs."""
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=radius_top, depth=length)
        obj = bpy.context.active_object
        
        if abs(radius_top - radius_bot) > 0.001:
            bm = bmesh.new()
            bm.from_mesh(obj.data)
            scale = radius_bot / radius_top
            for v in bm.verts:
                if v.co.z < 0:
                    v.co.x *= scale
                    v.co.y *= scale
            bm.to_mesh(obj.data)
            bm.free()
        
        return obj
    
    def _create_sphere(self, radius: float, segments: int = 8) -> bpy.types.Object:
        """Create a sphere."""
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=segments//2, radius=radius)
        return bpy.context.active_object
    
    def _create_body_section(self, top_w: float, top_d: float, height: float, 
                             bot_w: float, bot_d: float) -> bpy.types.Object:
        """Create a body section that tapers."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.scale = (top_w, top_d, height)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        w_scale = bot_w / top_w
        d_scale = bot_d / top_d
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= w_scale
                v.co.y *= d_scale
        
        bm.to_mesh(obj.data)
        bm.free()
        
        return obj
    
    def _create_chest_mesh(self, shoulder_w: float, chest_w: float, chest_d: float, 
                           height: float, waist_w: float, waist_d: float, build: dict) -> bpy.types.Object:
        """Create a properly shaped chest/torso."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.scale = (shoulder_w, chest_d, height)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        for v in bm.verts:
            # Vertical position factor (0=bottom, 1=top)
            t = (v.co.z + height/2) / height
            
            # Width: narrower at waist (bottom), wider at shoulders (top)
            w_factor = (waist_w/shoulder_w) + (1.0 - waist_w/shoulder_w) * t
            v.co.x *= w_factor
            
            # Depth: narrower at waist
            d_factor = (waist_d/chest_d) + (1.0 - waist_d/chest_d) * (t * 0.7 + 0.3)
            v.co.y *= d_factor
            
            # Chest puff (front, upper area)
            if v.co.y > 0 and t > 0.5:
                puff = chest_d * 0.12 * build["muscle"] * (t - 0.5) * 2
                v.co.y += puff
        
        bm.to_mesh(obj.data)
        bm.free()
        
        # Slight bevel
        bpy.ops.object.modifier_add(type='BEVEL')
        obj.modifiers["Bevel"].width = 0.015
        obj.modifiers["Bevel"].segments = 1
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return obj
    
    def _create_head(self, size: float, mats: dict, has_hair: bool) -> list:
        """Create head with facial features."""
        parts = []
        
        # Main head (slightly oval)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=size * 0.5)
        head = bpy.context.active_object
        head.scale = (0.85, 0.9, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        
        # Shape jaw
        bm = bmesh.new()
        bm.from_mesh(head.data)
        for v in bm.verts:
            if v.co.z < -size * 0.15:
                factor = 1.0 - abs(v.co.z + size * 0.15) / (size * 0.35) * 0.3
                v.co.x *= max(0.55, factor)
                v.co.y *= max(0.65, factor)
        bm.to_mesh(head.data)
        bm.free()
        
        self._apply_mat(head, mats["skin"])
        parts.append(head)
        
        # Eyes
        eye_size = size * 0.055
        for side in [-1, 1]:
            eye = self._create_sphere(eye_size, 6)
            eye.location = Vector((side * size * 0.18, size * 0.38, size * 0.08))
            self._apply_mat(eye, mats["boots"])  # Dark
            parts.append(eye)
        
        # Nose
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=size * 0.035, depth=size * 0.08)
        nose = bpy.context.active_object
        nose.rotation_euler = (math.radians(90), 0, 0)
        nose.location = Vector((0, size * 0.44, 0))
        bpy.ops.object.transform_apply(rotation=True)
        self._apply_mat(nose, mats["skin"])
        parts.append(nose)
        
        # Ears
        for side in [-1, 1]:
            ear = self._create_sphere(size * 0.055, 5)
            ear.scale = (0.35, 0.5, 0.8)
            ear.location = Vector((side * size * 0.42, -size * 0.05, size * 0.05))
            bpy.ops.object.transform_apply(scale=True)
            self._apply_mat(ear, mats["skin"])
            parts.append(ear)
        
        # Hair
        if has_hair:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=size * 0.52)
            hair = bpy.context.active_object
            hair.scale = (0.88, 0.85, 0.65)
            hair.location = Vector((0, -size * 0.04, size * 0.18))
            bpy.ops.object.transform_apply(scale=True)
            
            # Remove bottom half
            bm = bmesh.new()
            bm.from_mesh(hair.data)
            verts_del = [v for v in bm.verts if v.co.z < -size * 0.05]
            bmesh.ops.delete(bm, geom=verts_del, context='VERTS')
            bm.to_mesh(hair.data)
            bm.free()
            
            self._apply_mat(hair, mats["hair"])
            parts.append(hair)
        
        return parts
    
    def _create_materials(self, name: str, config: dict) -> dict:
        """Create all materials for character."""
        mats = {}
        for key in ["skin", "shirt", "pants", "boots", "hair"]:
            mats[key] = self._make_mat(f"{name}_{key}", config[key])
        return mats
    
    def _make_mat(self, name: str, color: tuple) -> bpy.types.Material:
        """Create a material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = color
            bsdf.inputs["Roughness"].default_value = 0.7
        return mat
    
    def _apply_mat(self, obj: bpy.types.Object, mat: bpy.types.Material) -> None:
        """Apply material to object."""
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)
    
    def _set_origin_to_ground(self, obj: bpy.types.Object) -> None:
        """Set origin to lowest point."""
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        
        mesh = obj.data
        if len(mesh.vertices) == 0:
            return
        
        min_z = min((obj.matrix_world @ v.co).z for v in mesh.vertices)
        
        bpy.context.scene.cursor.location = (0, 0, min_z)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        obj.location.z = -min_z
        bpy.ops.object.transform_apply(location=True)
        bpy.context.scene.cursor.location = (0, 0, 0)


class HumanZombieGenerator:
    """Generate zombie variants using human proportions."""
    
    ZOMBIE_CONFIGS = {
        "zombie_walker": {"height": 1.72, "build": "decay", "skin": (0.48, 0.55, 0.40, 1.0)},
        "zombie_runner": {"height": 1.70, "build": "lean", "skin": (0.52, 0.58, 0.45, 1.0)},
        "zombie_crawler": {"height": 0.55, "build": "decay", "skin": (0.42, 0.50, 0.38, 1.0)},
        "zombie_bloater": {"height": 1.65, "build": "bloat", "skin": (0.58, 0.52, 0.42, 1.0)},
        "zombie_screamer": {"height": 1.68, "build": "lean", "skin": (0.50, 0.55, 0.45, 1.0)},
        "zombie_spitter": {"height": 1.74, "build": "decay", "skin": (0.45, 0.58, 0.38, 1.0)},
        "zombie_brute": {"height": 2.15, "build": "brute", "skin": (0.55, 0.50, 0.42, 1.0)},
        "zombie_ravager": {"height": 1.98, "build": "muscular", "skin": (0.50, 0.48, 0.40, 1.0)},
    }
    
    BUILD_PARAMS = {
        "lean": {"bulk": 0.88, "muscle": 0.85},
        "decay": {"bulk": 0.92, "muscle": 0.80},
        "bloat": {"bulk": 1.45, "muscle": 0.70},
        "brute": {"bulk": 1.35, "muscle": 1.30},
        "muscular": {"bulk": 1.15, "muscle": 1.20},
    }
    
    def __init__(self, seed=None):
        self.char_gen = HumanCharacterGenerator(seed)
        if seed:
            random.seed(seed)
    
    def generate(self, name: str, zombie_type: str = "zombie_walker") -> bpy.types.Object:
        """Generate a zombie."""
        config = self.ZOMBIE_CONFIGS.get(zombie_type, self.ZOMBIE_CONFIGS["zombie_walker"])
        build_name = config["build"]
        
        # Create temp config
        temp_config = {
            "height": config["height"],
            "build": build_name,
            "skin": config["skin"],
            "shirt": (0.32, 0.28, 0.24, 1.0),
            "pants": (0.28, 0.25, 0.22, 1.0),
            "boots": (0.18, 0.15, 0.12, 1.0),
            "hair": (0.0, 0.0, 0.0, 1.0),
        }
        
        self.char_gen.CHARACTER_CONFIGS["_zombie"] = temp_config
        self.char_gen.BUILD_PARAMS[build_name] = self.BUILD_PARAMS.get(build_name, {"bulk": 1.0, "muscle": 1.0})
        
        zombie = self.char_gen.generate(name, "_zombie")
        
        # Add decay
        self._add_decay(zombie)
        
        return zombie
    
    def _add_decay(self, obj: bpy.types.Object) -> None:
        """Add decay effects."""
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        for v in bm.verts:
            v.co.x += random.uniform(-0.012, 0.012)
            v.co.y += random.uniform(-0.008, 0.008)
        
        # Lean
        lean = random.uniform(-0.06, 0.06)
        for v in bm.verts:
            if v.co.z > 0.7:
                v.co.x += lean * (v.co.z - 0.7)
        
        bm.to_mesh(obj.data)
        bm.free()
