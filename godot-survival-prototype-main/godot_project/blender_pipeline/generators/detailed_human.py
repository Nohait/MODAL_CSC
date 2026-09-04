"""
Detailed Human Character Generator
Creates LDOE-style characters with muscle definition, clothing geometry, and organic shapes.
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector, Matrix


class DetailedHumanGenerator:
    """Generate detailed, realistic human characters with clothing and muscle definition."""
    
    CHARACTER_CONFIGS = {
        "survivor_male": {
            "height": 1.80,
            "build": "athletic",
            "gender": "male",
            "skin": (0.82, 0.70, 0.55, 1.0),
            "shirt_color": (0.28, 0.35, 0.25, 1.0),
            "pants_color": (0.30, 0.28, 0.22, 1.0),
            "boots_color": (0.18, 0.14, 0.10, 1.0),
            "hair_color": (0.18, 0.12, 0.08, 1.0),
            "has_jacket": True,
            "jacket_color": (0.22, 0.28, 0.20, 1.0),
        },
        "survivor_female": {
            "height": 1.68,
            "build": "lean_f",
            "gender": "female",
            "skin": (0.85, 0.72, 0.58, 1.0),
            "shirt_color": (0.55, 0.22, 0.22, 1.0),
            "pants_color": (0.22, 0.24, 0.30, 1.0),
            "boots_color": (0.15, 0.12, 0.10, 1.0),
            "hair_color": (0.40, 0.22, 0.12, 1.0),
            "has_jacket": False,
        },
        "npc_trader": {
            "height": 1.75,
            "build": "stocky",
            "gender": "male",
            "skin": (0.75, 0.62, 0.50, 1.0),
            "shirt_color": (0.50, 0.42, 0.28, 1.0),
            "pants_color": (0.38, 0.32, 0.24, 1.0),
            "boots_color": (0.22, 0.18, 0.12, 1.0),
            "hair_color": (0.28, 0.22, 0.16, 1.0),
            "has_jacket": True,
            "jacket_color": (0.35, 0.30, 0.22, 1.0),
        },
        "npc_mechanic": {
            "height": 1.82,
            "build": "muscular",
            "gender": "male",
            "skin": (0.72, 0.58, 0.45, 1.0),
            "shirt_color": (0.22, 0.28, 0.38, 1.0),
            "pants_color": (0.22, 0.28, 0.38, 1.0),
            "boots_color": (0.12, 0.12, 0.12, 1.0),
            "hair_color": (0.10, 0.08, 0.06, 1.0),
            "has_jacket": False,
        },
        "raider_scout": {
            "height": 1.76,
            "build": "lean",
            "gender": "male",
            "skin": (0.72, 0.58, 0.45, 1.0),
            "shirt_color": (0.15, 0.14, 0.14, 1.0),
            "pants_color": (0.12, 0.12, 0.12, 1.0),
            "boots_color": (0.10, 0.10, 0.10, 1.0),
            "hair_color": (0.08, 0.06, 0.05, 1.0),
            "has_jacket": True,
            "jacket_color": (0.12, 0.12, 0.10, 1.0),
        },
        "raider_heavy": {
            "height": 1.92,
            "build": "heavy",
            "gender": "male",
            "skin": (0.68, 0.54, 0.42, 1.0),
            "shirt_color": (0.18, 0.15, 0.12, 1.0),
            "pants_color": (0.15, 0.12, 0.10, 1.0),
            "boots_color": (0.12, 0.10, 0.08, 1.0),
            "hair_color": (0.0, 0.0, 0.0, 1.0),
            "has_jacket": True,
            "jacket_color": (0.15, 0.12, 0.10, 1.0),
        },
    }
    
    BUILD_PARAMS = {
        "lean":     {"bulk": 0.92, "muscle": 0.95, "fat": 0.85},
        "lean_f":   {"bulk": 0.88, "muscle": 0.88, "fat": 0.90},
        "athletic": {"bulk": 1.00, "muscle": 1.08, "fat": 0.95},
        "stocky":   {"bulk": 1.08, "muscle": 1.00, "fat": 1.15},
        "muscular": {"bulk": 1.05, "muscle": 1.20, "fat": 0.92},
        "heavy":    {"bulk": 1.15, "muscle": 1.10, "fat": 1.25},
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, char_type: str = "survivor_male") -> bpy.types.Object:
        """Generate a detailed human character."""
        config = self.CHARACTER_CONFIGS.get(char_type, self.CHARACTER_CONFIGS["survivor_male"])
        build = self.BUILD_PARAMS.get(config["build"], self.BUILD_PARAMS["athletic"])
        
        H = config["height"]
        head_unit = H / 8.0
        is_female = config.get("gender", "male") == "female"
        
        # Create materials
        mats = self._create_materials(name, config)
        
        all_parts = []
        
        # Build character from ground up
        z = 0.0
        
        # ============================================================
        # FEET & BOOTS
        # ============================================================
        boots = self._create_boots(head_unit, build, is_female)
        for boot in boots:
            boot.location.z += z
            self._apply_mat(boot, mats["boots"])
            all_parts.append(boot)
        boot_height = head_unit * 0.35
        z += boot_height
        
        # ============================================================
        # LOWER LEGS (CALVES) - with muscle shape
        # ============================================================
        calf_height = head_unit * 1.65
        for side in [-1, 1]:
            calf = self._create_calf(head_unit, build, is_female)
            calf.location = Vector((side * head_unit * 0.38, 0, z + calf_height * 0.5))
            self._apply_mat(calf, mats["pants"])
            all_parts.append(calf)
        z += calf_height
        
        # ============================================================
        # KNEES
        # ============================================================
        knee_r = head_unit * 0.22 * build["bulk"]
        for side in [-1, 1]:
            knee = self._create_sphere(knee_r, 12)
            knee.scale = (1.1, 0.9, 0.7)
            knee.location = Vector((side * head_unit * 0.38, 0.02, z))
            bpy.ops.object.transform_apply(scale=True)
            self._apply_mat(knee, mats["pants"])
            all_parts.append(knee)
        
        # ============================================================
        # UPPER LEGS (THIGHS) - with muscle shape
        # ============================================================
        thigh_height = head_unit * 1.85
        for side in [-1, 1]:
            thigh = self._create_thigh(head_unit, build, is_female)
            thigh.location = Vector((side * head_unit * 0.35, 0, z + thigh_height * 0.5))
            self._apply_mat(thigh, mats["pants"])
            all_parts.append(thigh)
        z += thigh_height
        
        # ============================================================
        # PELVIS / HIPS
        # ============================================================
        pelvis = self._create_pelvis(head_unit, build, is_female)
        pelvis_height = head_unit * 0.55
        pelvis.location = Vector((0, 0, z + pelvis_height * 0.5))
        self._apply_mat(pelvis, mats["pants"])
        all_parts.append(pelvis)
        
        # Belt
        belt = self._create_belt(head_unit, build)
        belt.location = Vector((0, 0, z + pelvis_height * 0.85))
        self._apply_mat(belt, mats["boots"])  # Dark belt
        all_parts.append(belt)
        
        z += pelvis_height
        
        # ============================================================
        # ABDOMEN / WAIST
        # ============================================================
        abdomen = self._create_abdomen(head_unit, build, is_female)
        abdomen_height = head_unit * 0.75
        abdomen.location = Vector((0, 0, z + abdomen_height * 0.5))
        self._apply_mat(abdomen, mats["shirt"])
        all_parts.append(abdomen)
        z += abdomen_height
        
        # ============================================================
        # CHEST / TORSO
        # ============================================================
        chest = self._create_chest(head_unit, build, is_female)
        chest_height = head_unit * 1.15
        chest.location = Vector((0, 0, z + chest_height * 0.5))
        self._apply_mat(chest, mats["shirt"])
        all_parts.append(chest)
        
        shoulder_z = z + chest_height * 0.88
        arm_attach_x = head_unit * 1.05 * build["bulk"]
        
        z += chest_height
        
        # ============================================================
        # JACKET (if has_jacket)
        # ============================================================
        if config.get("has_jacket", False):
            jacket_parts = self._create_jacket(head_unit, build, shoulder_z, chest_height, abdomen_height)
            for part in jacket_parts:
                self._apply_mat(part, mats["jacket"])
                all_parts.append(part)
        
        # ============================================================
        # SHOULDERS
        # ============================================================
        shoulder_r = head_unit * 0.20 * build["muscle"]
        for side in [-1, 1]:
            shoulder = self._create_shoulder(head_unit, build)
            shoulder.location = Vector((side * arm_attach_x, 0, shoulder_z))
            mat = mats["jacket"] if config.get("has_jacket") else mats["shirt"]
            self._apply_mat(shoulder, mat)
            all_parts.append(shoulder)
        
        # ============================================================
        # ARMS
        # ============================================================
        for side in [-1, 1]:
            arm_parts = self._create_arm(head_unit, build, side, arm_attach_x, shoulder_z, mats, config.get("has_jacket", False))
            all_parts.extend(arm_parts)
        
        # ============================================================
        # NECK
        # ============================================================
        neck = self._create_neck(head_unit, build)
        neck_height = head_unit * 0.28
        neck.location = Vector((0, 0, z + neck_height * 0.5))
        self._apply_mat(neck, mats["skin"])
        all_parts.append(neck)
        z += neck_height
        
        # ============================================================
        # HEAD
        # ============================================================
        head_parts = self._create_detailed_head(head_unit, mats, is_female, config)
        for part in head_parts:
            part.location.z += z + head_unit * 0.48
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
        
        # Apply smooth shading
        bpy.ops.object.shade_smooth()
        
        # Set origin to ground
        self._set_origin_to_ground(character)
        
        return character
    
    # ========================================================================
    # BODY PART CREATION METHODS
    # ========================================================================
    
    def _create_boots(self, hu: float, build: dict, is_female: bool) -> list:
        """Create detailed boots."""
        boots = []
        boot_length = hu * 1.0
        boot_width = hu * 0.38 * build["bulk"]
        boot_height = hu * 0.35
        
        for side in [-1, 1]:
            # Boot base
            bpy.ops.mesh.primitive_cube_add(size=1)
            boot = bpy.context.active_object
            boot.scale = (boot_width, boot_length, boot_height)
            bpy.ops.object.transform_apply(scale=True)
            
            # Shape the boot
            bm = bmesh.new()
            bm.from_mesh(boot.data)
            
            for v in bm.verts:
                # Toe taper
                if v.co.y > boot_length * 0.2:
                    taper = 1.0 - (v.co.y - boot_length * 0.2) / (boot_length * 0.8) * 0.25
                    v.co.x *= taper
                    if v.co.z > 0:
                        v.co.z *= taper
                
                # Heel
                if v.co.y < -boot_length * 0.3 and v.co.z < 0:
                    v.co.z -= hu * 0.03
                
                # Ankle taper (top)
                if v.co.z > boot_height * 0.3:
                    v.co.x *= 0.85
                    v.co.y *= 0.88
            
            bm.to_mesh(boot.data)
            bm.free()
            
            boot.location = Vector((side * hu * 0.38, boot_length * 0.15, boot_height * 0.5))
            
            # Add boot sole
            bpy.ops.mesh.primitive_cube_add(size=1)
            sole = bpy.context.active_object
            sole.scale = (boot_width * 1.05, boot_length * 1.02, hu * 0.04)
            sole.location = Vector((side * hu * 0.38, boot_length * 0.15, hu * 0.02))
            bpy.ops.object.transform_apply(scale=True)
            
            # Join sole to boot
            bpy.ops.object.select_all(action='DESELECT')
            boot.select_set(True)
            sole.select_set(True)
            bpy.context.view_layer.objects.active = boot
            bpy.ops.object.join()
            
            boots.append(boot)
        
        return boots
    
    def _create_calf(self, hu: float, build: dict, is_female: bool) -> bpy.types.Object:
        """Create calf with muscle shape."""
        height = hu * 1.65
        radius = hu * 0.18 * build["bulk"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=height)
        calf = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(calf.data)
        
        muscle = build["muscle"]
        
        for v in bm.verts:
            t = (v.co.z + height/2) / height  # 0 at bottom, 1 at top
            
            # Calf muscle bulge (back, upper portion)
            if t > 0.4 and t < 0.85:
                bulge_factor = math.sin((t - 0.4) / 0.45 * math.pi) * 0.35 * muscle
                if v.co.y < 0:  # Back of leg
                    v.co.y -= radius * bulge_factor
                v.co.x *= 1.0 + bulge_factor * 0.3
            
            # Taper at ankle
            if t < 0.25:
                taper = 0.75 + t * 1.0
                v.co.x *= taper
                v.co.y *= taper
            
            # Slight taper at top (behind knee)
            if t > 0.9:
                taper = 1.0 - (t - 0.9) * 0.8
                v.co.x *= taper
                v.co.y *= taper
        
        bm.to_mesh(calf.data)
        bm.free()
        
        return calf
    
    def _create_thigh(self, hu: float, build: dict, is_female: bool) -> bpy.types.Object:
        """Create thigh with muscle shape."""
        height = hu * 1.85
        radius = hu * 0.28 * build["bulk"]
        
        if is_female:
            radius *= 1.08  # Slightly wider hips
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=height)
        thigh = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(thigh.data)
        
        muscle = build["muscle"]
        fat = build["fat"]
        
        for v in bm.verts:
            t = (v.co.z + height/2) / height
            
            # Quadriceps bulge (front)
            if t > 0.2 and t < 0.8:
                quad_bulge = math.sin((t - 0.2) / 0.6 * math.pi) * 0.25 * muscle
                if v.co.y > 0:
                    v.co.y += radius * quad_bulge
            
            # Hamstring (back)
            if t > 0.3 and t < 0.9:
                ham_bulge = math.sin((t - 0.3) / 0.6 * math.pi) * 0.18 * muscle
                if v.co.y < 0:
                    v.co.y -= radius * ham_bulge
            
            # Inner thigh fullness
            if is_female and t > 0.5:
                inner = 1.0 + (t - 0.5) * 0.15 * fat
                if v.co.x > 0:  # Assuming inner is positive X for one leg
                    v.co.x *= inner
            
            # Taper toward knee
            if t < 0.15:
                taper = 0.82 + t * 1.2
                v.co.x *= taper
                v.co.y *= taper
            
            # Widen toward hip
            if t > 0.75:
                widen = 1.0 + (t - 0.75) * 0.4 * fat
                v.co.x *= widen
                v.co.y *= widen * 0.9
        
        bm.to_mesh(thigh.data)
        bm.free()
        
        return thigh
    
    def _create_pelvis(self, hu: float, build: dict, is_female: bool) -> bpy.types.Object:
        """Create pelvis/hip area."""
        width = hu * 1.5 * build["bulk"]
        depth = hu * 0.75 * build["fat"]
        height = hu * 0.55
        
        if is_female:
            width *= 1.12
            depth *= 1.05
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        pelvis = bpy.context.active_object
        pelvis.scale = (width, depth, height)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(pelvis.data)
        
        for v in bm.verts:
            # Round the sides (hip bones)
            dist = abs(v.co.x) / (width/2)
            if dist > 0.7:
                curve = math.sqrt(1.0 - (dist - 0.7) / 0.3 * 0.5)
                v.co.y *= curve
                if v.co.z < 0:
                    v.co.z *= curve
            
            # Narrow at bottom (between legs)
            if v.co.z < -height * 0.3:
                narrow = 0.65 + (v.co.z + height * 0.5) / (height * 0.2) * 0.35
                v.co.x *= max(0.5, narrow)
            
            # Buttocks (back, lower)
            if v.co.y < 0 and v.co.z < 0:
                butt = 1.0 + abs(v.co.z) / (height/2) * 0.2 * build["fat"]
                v.co.y *= butt
        
        bm.to_mesh(pelvis.data)
        bm.free()
        
        # Bevel edges
        bpy.ops.object.modifier_add(type='BEVEL')
        pelvis.modifiers["Bevel"].width = 0.02
        pelvis.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return pelvis
    
    def _create_belt(self, hu: float, build: dict) -> bpy.types.Object:
        """Create belt around waist."""
        width = hu * 1.45 * build["bulk"]
        depth = hu * 0.72 * build["fat"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1, depth=hu * 0.08)
        belt = bpy.context.active_object
        belt.scale = (width/2, depth/2, 1)
        bpy.ops.object.transform_apply(scale=True)
        
        # Add belt buckle
        bpy.ops.mesh.primitive_cube_add(size=1)
        buckle = bpy.context.active_object
        buckle.scale = (hu * 0.12, hu * 0.04, hu * 0.10)
        buckle.location = Vector((0, depth/2 + hu * 0.02, 0))
        bpy.ops.object.transform_apply(scale=True, location=True)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        belt.select_set(True)
        buckle.select_set(True)
        bpy.context.view_layer.objects.active = belt
        bpy.ops.object.join()
        
        return belt
    
    def _create_abdomen(self, hu: float, build: dict, is_female: bool) -> bpy.types.Object:
        """Create abdomen with subtle muscle definition."""
        width = hu * 1.35 * build["bulk"]
        depth = hu * 0.68 * build["fat"]
        height = hu * 0.75
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        abdomen = bpy.context.active_object
        abdomen.scale = (width, depth, height)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(abdomen.data)
        
        muscle = build["muscle"]
        
        for v in bm.verts:
            t = (v.co.z + height/2) / height
            
            # Waist narrowing in middle
            waist_curve = 1.0 - math.sin(t * math.pi) * 0.08
            v.co.x *= waist_curve
            
            # Slight belly curve
            if v.co.y > 0:
                belly = 1.0 + math.sin(t * math.pi) * 0.08 * build["fat"]
                v.co.y *= belly
            
            # Core/oblique definition (sides indent slightly)
            if abs(v.co.x) > width * 0.35:
                v.co.y *= 0.92
            
            # Narrow at top toward chest
            if t > 0.8:
                v.co.x *= 1.0 - (t - 0.8) * 0.3
        
        bm.to_mesh(abdomen.data)
        bm.free()
        
        bpy.ops.object.modifier_add(type='BEVEL')
        abdomen.modifiers["Bevel"].width = 0.015
        abdomen.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return abdomen
    
    def _create_chest(self, hu: float, build: dict, is_female: bool) -> bpy.types.Object:
        """Create chest with pectoral/breast definition."""
        width = hu * 2.0 * build["bulk"]
        depth = hu * 0.82 * build["fat"]
        height = hu * 1.15
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        chest = bpy.context.active_object
        chest.scale = (width, depth, height)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(chest.data)
        
        muscle = build["muscle"]
        
        for v in bm.verts:
            t = (v.co.z + height/2) / height
            x_norm = v.co.x / (width/2)
            
            # Shoulder width at top
            if t > 0.75:
                shoulder_expand = 1.0 + (t - 0.75) * 0.15
                v.co.x *= shoulder_expand
            
            # Narrow at waist (bottom)
            if t < 0.25:
                v.co.x *= 0.72 + t * 1.12
            
            # Pectoral/chest curve
            if v.co.y > 0:
                if is_female:
                    # Breast shape
                    if t > 0.3 and t < 0.75 and abs(x_norm) > 0.15 and abs(x_norm) < 0.65:
                        breast_t = (t - 0.3) / 0.45
                        breast_x = (abs(x_norm) - 0.15) / 0.5
                        breast = math.sin(breast_t * math.pi) * math.sin(breast_x * math.pi) * 0.35
                        v.co.y += depth * breast
                else:
                    # Pec muscles
                    if t > 0.45 and t < 0.85 and abs(x_norm) > 0.1 and abs(x_norm) < 0.7:
                        pec_t = (t - 0.45) / 0.4
                        pec_x = (abs(x_norm) - 0.1) / 0.6
                        pec = math.sin(pec_t * math.pi) * math.sin(pec_x * math.pi) * 0.22 * muscle
                        v.co.y += depth * pec
            
            # Back muscles (lats)
            if v.co.y < 0 and t > 0.3 and t < 0.85:
                lat_t = (t - 0.3) / 0.55
                if abs(x_norm) > 0.3 and abs(x_norm) < 0.85:
                    lat = math.sin(lat_t * math.pi) * 0.12 * muscle
                    v.co.y -= depth * lat
            
            # Round the shoulders
            if t > 0.8 and abs(x_norm) > 0.7:
                round_factor = (abs(x_norm) - 0.7) / 0.3
                v.co.z -= height * 0.08 * round_factor
                v.co.y *= 1.0 - round_factor * 0.2
        
        bm.to_mesh(chest.data)
        bm.free()
        
        bpy.ops.object.modifier_add(type='BEVEL')
        chest.modifiers["Bevel"].width = 0.02
        chest.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return chest
    
    def _create_jacket(self, hu: float, build: dict, shoulder_z: float, chest_h: float, abdomen_h: float) -> list:
        """Create jacket/vest overlay."""
        parts = []
        
        width = hu * 2.05 * build["bulk"]
        depth = hu * 0.88 * build["fat"]
        
        # Jacket body (slightly larger than torso)
        jacket_h = chest_h + abdomen_h * 0.4
        bpy.ops.mesh.primitive_cube_add(size=1)
        jacket = bpy.context.active_object
        jacket.scale = (width, depth, jacket_h)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(jacket.data)
        
        for v in bm.verts:
            t = (v.co.z + jacket_h/2) / jacket_h
            
            # Open front (V-neck shape)
            if v.co.y > 0 and abs(v.co.x) < width * 0.2:
                if t > 0.4:
                    v.co.y -= depth * 0.15 * (t - 0.4) / 0.6
            
            # Collar at top
            if t > 0.9 and v.co.y > 0:
                v.co.y += depth * 0.08
                v.co.z += jacket_h * 0.03
            
            # Taper at bottom
            if t < 0.15:
                v.co.x *= 0.85 + t * 1.0
        
        bm.to_mesh(jacket.data)
        bm.free()
        
        jacket.location = Vector((0, 0, shoulder_z - chest_h * 0.45))
        parts.append(jacket)
        
        # Pockets
        pocket_w = hu * 0.22
        pocket_h = hu * 0.18
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(size=1)
            pocket = bpy.context.active_object
            pocket.scale = (pocket_w, hu * 0.06, pocket_h)
            pocket.location = Vector((
                side * width * 0.32,
                depth/2 + hu * 0.03,
                shoulder_z - chest_h * 0.7
            ))
            bpy.ops.object.transform_apply(scale=True)
            parts.append(pocket)
        
        return parts
    
    def _create_shoulder(self, hu: float, build: dict) -> bpy.types.Object:
        """Create rounded shoulder."""
        r = hu * 0.20 * build["muscle"]
        
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=r)
        shoulder = bpy.context.active_object
        shoulder.scale = (1.2, 1.0, 0.8)
        bpy.ops.object.transform_apply(scale=True)
        
        return shoulder
    
    def _create_arm(self, hu: float, build: dict, side: int, attach_x: float, 
                    shoulder_z: float, mats: dict, has_jacket: bool) -> list:
        """Create complete arm with muscle definition."""
        parts = []
        
        upper_arm_h = hu * 1.35
        forearm_h = hu * 1.15
        
        arm_z = shoulder_z
        arm_x = side * attach_x
        
        # Upper arm (bicep/tricep)
        upper_arm = self._create_upper_arm(hu, build)
        arm_z -= upper_arm_h * 0.5
        upper_arm.location = Vector((arm_x, 0, arm_z))
        mat = mats["jacket"] if has_jacket else mats["shirt"]
        self._apply_mat(upper_arm, mat)
        parts.append(upper_arm)
        arm_z -= upper_arm_h * 0.5
        
        # Elbow
        elbow_r = hu * 0.10 * build["bulk"]
        elbow = self._create_sphere(elbow_r, 8)
        elbow.scale = (1.0, 0.85, 0.75)
        elbow.location = Vector((arm_x, -hu * 0.02, arm_z))
        bpy.ops.object.transform_apply(scale=True)
        self._apply_mat(elbow, mats["skin"])
        parts.append(elbow)
        
        # Forearm
        forearm = self._create_forearm(hu, build)
        arm_z -= forearm_h * 0.5
        forearm.location = Vector((arm_x, 0, arm_z))
        self._apply_mat(forearm, mats["skin"])
        parts.append(forearm)
        arm_z -= forearm_h * 0.5
        
        # Wrist
        wrist_r = hu * 0.065
        wrist = self._create_sphere(wrist_r, 6)
        wrist.location = Vector((arm_x, 0, arm_z))
        self._apply_mat(wrist, mats["skin"])
        parts.append(wrist)
        
        # Hand
        hand = self._create_hand(hu, build, side)
        hand.location = Vector((arm_x, 0, arm_z - hu * 0.22))
        self._apply_mat(hand, mats["skin"])
        parts.append(hand)
        
        return parts
    
    def _create_upper_arm(self, hu: float, build: dict) -> bpy.types.Object:
        """Create upper arm with bicep/tricep definition."""
        height = hu * 1.35
        radius = hu * 0.14 * build["muscle"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius, depth=height)
        arm = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(arm.data)
        
        muscle = build["muscle"]
        
        for v in bm.verts:
            t = (v.co.z + height/2) / height
            
            # Bicep bulge (front)
            if t > 0.25 and t < 0.75 and v.co.y > 0:
                bulge = math.sin((t - 0.25) / 0.5 * math.pi) * 0.35 * muscle
                v.co.y += radius * bulge
            
            # Tricep (back)
            if t > 0.3 and t < 0.8 and v.co.y < 0:
                bulge = math.sin((t - 0.3) / 0.5 * math.pi) * 0.25 * muscle
                v.co.y -= radius * bulge
            
            # Deltoid attachment at top
            if t > 0.85:
                expand = 1.0 + (t - 0.85) * 1.5
                v.co.x *= expand
                v.co.y *= expand
            
            # Taper toward elbow
            if t < 0.2:
                taper = 0.8 + t * 1.0
                v.co.x *= taper
                v.co.y *= taper
        
        bm.to_mesh(arm.data)
        bm.free()
        
        return arm
    
    def _create_forearm(self, hu: float, build: dict) -> bpy.types.Object:
        """Create forearm with muscle definition."""
        height = hu * 1.15
        radius = hu * 0.11 * build["muscle"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius, depth=height)
        arm = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(arm.data)
        
        muscle = build["muscle"]
        
        for v in bm.verts:
            t = (v.co.z + height/2) / height
            
            # Forearm muscle bulk (upper portion)
            if t > 0.5 and t < 0.9:
                bulge = math.sin((t - 0.5) / 0.4 * math.pi) * 0.3 * muscle
                v.co.x *= 1.0 + bulge * 0.5
                v.co.y *= 1.0 + bulge
            
            # Taper toward wrist
            if t < 0.25:
                taper = 0.7 + t * 1.2
                v.co.x *= taper
                v.co.y *= taper
        
        bm.to_mesh(arm.data)
        bm.free()
        
        return arm
    
    def _create_hand(self, hu: float, build: dict, side: int) -> bpy.types.Object:
        """Create a more detailed hand shape."""
        hand_l = hu * 0.65
        hand_w = hu * 0.28
        hand_d = hu * 0.12
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        hand = bpy.context.active_object
        hand.scale = (hand_w, hand_d, hand_l)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(hand.data)
        
        for v in bm.verts:
            t = (v.co.z + hand_l/2) / hand_l  # 0 at fingers, 1 at wrist
            
            # Taper toward fingers
            if t < 0.4:
                taper = 0.6 + t * 1.0
                v.co.x *= taper
                v.co.y *= taper
            
            # Palm curve
            if v.co.y < 0 and t > 0.4:
                v.co.y -= hand_d * 0.15
            
            # Knuckle bumps
            if t > 0.35 and t < 0.5 and v.co.y > 0:
                v.co.y += hand_d * 0.12
            
            # Thumb side
            if t > 0.5 and v.co.x * side > 0:
                v.co.x += side * hand_w * 0.08
        
        bm.to_mesh(hand.data)
        bm.free()
        
        # Add thumb
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=hu * 0.04, depth=hu * 0.18)
        thumb = bpy.context.active_object
        thumb.rotation_euler = (math.radians(30), math.radians(side * 45), 0)
        thumb.location = Vector((side * hand_w * 0.45, hand_d * 0.1, hu * 0.12))
        bpy.ops.object.transform_apply(rotation=True)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        hand.select_set(True)
        thumb.select_set(True)
        bpy.context.view_layer.objects.active = hand
        bpy.ops.object.join()
        
        # Add simple fingers
        for i in range(4):
            bpy.ops.mesh.primitive_cylinder_add(vertices=5, radius=hu * 0.028, depth=hu * 0.22)
            finger = bpy.context.active_object
            finger.location = Vector((
                (i - 1.5) * hand_w * 0.22,
                0,
                -hand_l * 0.45
            ))
            
            bpy.ops.object.select_all(action='DESELECT')
            hand.select_set(True)
            finger.select_set(True)
            bpy.context.view_layer.objects.active = hand
            bpy.ops.object.join()
        
        return hand
    
    def _create_neck(self, hu: float, build: dict) -> bpy.types.Object:
        """Create neck."""
        height = hu * 0.28
        radius = hu * 0.16 * build["bulk"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius, depth=height)
        neck = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(neck.data)
        
        for v in bm.verts:
            t = (v.co.z + height/2) / height
            
            # Wider at base (trapezius)
            if t < 0.3:
                expand = 1.0 + (0.3 - t) * 0.6
                v.co.x *= expand
                v.co.y *= expand * 0.8
            
            # Adam's apple
            if v.co.y > 0 and t > 0.4 and t < 0.7:
                v.co.y += radius * 0.08
        
        bm.to_mesh(neck.data)
        bm.free()
        
        return neck
    
    def _create_detailed_head(self, hu: float, mats: dict, is_female: bool, config: dict) -> list:
        """Create detailed head with facial features."""
        parts = []
        
        head_h = hu * 1.0
        head_w = hu * 0.75
        head_d = hu * 0.85
        
        # Main head
        bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=head_h * 0.5)
        head = bpy.context.active_object
        head.scale = (head_w / head_h, head_d / head_h, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(head.data)
        
        for v in bm.verts:
            z_norm = v.co.z / (head_h * 0.5)
            y_norm = v.co.y / (head_d * 0.5)
            
            # Jaw narrowing
            if z_norm < -0.2:
                jaw_narrow = 1.0 - (abs(z_norm) - 0.2) * 0.5
                v.co.x *= max(0.5, jaw_narrow)
                if z_norm < -0.5:
                    v.co.y *= max(0.6, jaw_narrow)
            
            # Chin
            if z_norm < -0.6 and y_norm > 0:
                v.co.y += head_d * 0.08
                v.co.z -= head_h * 0.03
            
            # Brow ridge
            if z_norm > 0.15 and z_norm < 0.35 and y_norm > 0.6:
                v.co.y += head_d * 0.05
                v.co.z += head_h * 0.02
            
            # Cheekbones
            if z_norm > -0.2 and z_norm < 0.1 and abs(v.co.x) > head_w * 0.35:
                v.co.y += head_d * 0.04 * (1.0 - abs(z_norm) / 0.2)
            
            # Female: softer jaw, fuller cheeks
            if is_female:
                if z_norm < 0:
                    v.co.x *= 1.0 - abs(z_norm) * 0.08
        
        bm.to_mesh(head.data)
        bm.free()
        
        self._apply_mat(head, mats["skin"])
        parts.append(head)
        
        # Eyes
        eye_size = hu * 0.06
        eye_z = head_h * 0.08
        eye_y = head_d * 0.38
        for side in [-1, 1]:
            # Eye socket indent
            bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=eye_size * 1.4)
            socket = bpy.context.active_object
            socket.location = Vector((side * head_w * 0.22, eye_y - hu * 0.02, eye_z))
            self._apply_mat(socket, mats["skin"])
            parts.append(socket)
            
            # Eyeball
            bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=eye_size)
            eye = bpy.context.active_object
            eye.location = Vector((side * head_w * 0.22, eye_y, eye_z))
            
            # Eye material (white with dark iris)
            eye_mat = bpy.data.materials.new(name=f"eye_{side}")
            eye_mat.use_nodes = True
            bsdf = eye_mat.node_tree.nodes.get("Principled BSDF")
            if bsdf:
                bsdf.inputs["Base Color"].default_value = (0.95, 0.95, 0.95, 1.0)
            self._apply_mat(eye, eye_mat)
            parts.append(eye)
            
            # Pupil/iris
            bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=eye_size * 0.45)
            iris = bpy.context.active_object
            iris.location = Vector((side * head_w * 0.22, eye_y + eye_size * 0.6, eye_z))
            
            iris_mat = bpy.data.materials.new(name=f"iris_{side}")
            iris_mat.use_nodes = True
            bsdf = iris_mat.node_tree.nodes.get("Principled BSDF")
            if bsdf:
                bsdf.inputs["Base Color"].default_value = (0.25, 0.18, 0.12, 1.0)
            self._apply_mat(iris, iris_mat)
            parts.append(iris)
        
        # Eyebrows
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(size=1)
            brow = bpy.context.active_object
            brow.scale = (hu * 0.12, hu * 0.025, hu * 0.025)
            brow.location = Vector((side * head_w * 0.22, eye_y + hu * 0.03, eye_z + hu * 0.10))
            brow.rotation_euler = (0, 0, side * math.radians(8))
            bpy.ops.object.transform_apply(scale=True, rotation=True)
            self._apply_mat(brow, mats["hair"])
            parts.append(brow)
        
        # Nose
        nose = self._create_nose(hu, is_female)
        nose.location = Vector((0, head_d * 0.42, -head_h * 0.05))
        self._apply_mat(nose, mats["skin"])
        parts.append(nose)
        
        # Ears
        for side in [-1, 1]:
            ear = self._create_ear(hu)
            ear.location = Vector((side * head_w * 0.48, -head_d * 0.05, head_h * 0.02))
            ear.rotation_euler = (0, 0, side * math.radians(-10))
            bpy.ops.object.transform_apply(rotation=True)
            self._apply_mat(ear, mats["skin"])
            parts.append(ear)
        
        # Mouth area
        bpy.ops.mesh.primitive_cube_add(size=1)
        mouth = bpy.context.active_object
        mouth.scale = (hu * 0.12, hu * 0.02, hu * 0.015)
        mouth.location = Vector((0, head_d * 0.36, -head_h * 0.22))
        bpy.ops.object.transform_apply(scale=True)
        
        mouth_mat = bpy.data.materials.new(name="mouth")
        mouth_mat.use_nodes = True
        bsdf = mouth_mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (0.4, 0.25, 0.22, 1.0)
        self._apply_mat(mouth, mouth_mat)
        parts.append(mouth)
        
        # Hair
        if config["hair_color"][0] > 0.01:
            hair = self._create_hair(hu, is_female, mats["hair"])
            parts.extend(hair)
        
        return parts
    
    def _create_nose(self, hu: float, is_female: bool) -> bpy.types.Object:
        """Create nose."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        nose = bpy.context.active_object
        
        nose_w = hu * 0.08 if is_female else hu * 0.10
        nose_d = hu * 0.14
        nose_h = hu * 0.18
        
        nose.scale = (nose_w, nose_d, nose_h)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(nose.data)
        
        for v in bm.verts:
            t = (v.co.z + nose_h/2) / nose_h
            
            # Bridge narrowing
            if t > 0.6:
                v.co.x *= 0.65 + (1.0 - t) * 0.9
            
            # Nostril flare at bottom
            if t < 0.2 and v.co.z < 0:
                v.co.x *= 1.3
            
            # Tip
            if t < 0.4 and v.co.y > 0:
                v.co.y += nose_d * 0.15 * (0.4 - t) / 0.4
        
        bm.to_mesh(nose.data)
        bm.free()
        
        bpy.ops.object.modifier_add(type='BEVEL')
        nose.modifiers["Bevel"].width = 0.008
        nose.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return nose
    
    def _create_ear(self, hu: float) -> bpy.types.Object:
        """Create ear."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        ear = bpy.context.active_object
        ear.scale = (hu * 0.04, hu * 0.08, hu * 0.12)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(ear.data)
        
        for v in bm.verts:
            # Curve the ear
            if v.co.y < 0:
                curve = abs(v.co.z) / (hu * 0.06)
                v.co.y -= hu * 0.02 * curve
        
        bm.to_mesh(ear.data)
        bm.free()
        
        bpy.ops.object.modifier_add(type='BEVEL')
        ear.modifiers["Bevel"].width = 0.006
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return ear
    
    def _create_hair(self, hu: float, is_female: bool, hair_mat) -> list:
        """Create hair."""
        parts = []
        
        head_h = hu * 1.0
        head_w = hu * 0.75
        
        if is_female:
            # Longer hair
            bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=head_h * 0.52)
            hair_top = bpy.context.active_object
            hair_top.scale = (0.95, 0.92, 0.75)
            hair_top.location = Vector((0, -hu * 0.02, head_h * 0.18))
            bpy.ops.object.transform_apply(scale=True)
            
            # Extend down
            bm = bmesh.new()
            bm.from_mesh(hair_top.data)
            for v in bm.verts:
                if v.co.z < 0 and v.co.y < 0:
                    v.co.z -= hu * 0.35 * (1.0 - v.co.y / (head_h * 0.5))
            bm.to_mesh(hair_top.data)
            bm.free()
            
            self._apply_mat(hair_top, hair_mat)
            parts.append(hair_top)
        else:
            # Short hair
            bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=head_h * 0.52)
            hair = bpy.context.active_object
            hair.scale = (0.98, 0.90, 0.55)
            hair.location = Vector((0, -hu * 0.03, head_h * 0.22))
            bpy.ops.object.transform_apply(scale=True)
            
            # Remove bottom half
            bm = bmesh.new()
            bm.from_mesh(hair.data)
            verts_del = [v for v in bm.verts if v.co.z < hu * 0.02]
            bmesh.ops.delete(bm, geom=verts_del, context='VERTS')
            bm.to_mesh(hair.data)
            bm.free()
            
            self._apply_mat(hair, hair_mat)
            parts.append(hair)
        
        return parts
    
    # ========================================================================
    # UTILITY METHODS
    # ========================================================================
    
    def _create_sphere(self, radius: float, segments: int = 12) -> bpy.types.Object:
        """Create UV sphere."""
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=segments//2, radius=radius)
        return bpy.context.active_object
    
    def _create_materials(self, name: str, config: dict) -> dict:
        """Create character materials."""
        mats = {}
        
        # Skin
        mats["skin"] = self._make_mat(f"{name}_skin", config["skin"], roughness=0.65)
        
        # Shirt
        mats["shirt"] = self._make_mat(f"{name}_shirt", config["shirt_color"], roughness=0.8)
        
        # Pants
        mats["pants"] = self._make_mat(f"{name}_pants", config["pants_color"], roughness=0.85)
        
        # Boots
        mats["boots"] = self._make_mat(f"{name}_boots", config["boots_color"], roughness=0.7)
        
        # Hair
        mats["hair"] = self._make_mat(f"{name}_hair", config["hair_color"], roughness=0.9)
        
        # Jacket (if present)
        if config.get("has_jacket"):
            mats["jacket"] = self._make_mat(f"{name}_jacket", config["jacket_color"], roughness=0.75)
        
        return mats
    
    def _make_mat(self, name: str, color: tuple, roughness: float = 0.7) -> bpy.types.Material:
        """Create material with given color."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = color
            bsdf.inputs["Roughness"].default_value = roughness
        return mat
    
    def _apply_mat(self, obj: bpy.types.Object, mat: bpy.types.Material) -> None:
        """Apply material to object."""
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)
    
    def _set_origin_to_ground(self, obj: bpy.types.Object) -> None:
        """Set origin to lowest point of mesh."""
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


class DetailedZombieGenerator:
    """Generate detailed zombie variants."""
    
    ZOMBIE_CONFIGS = {
        "zombie_walker":   {"height": 1.72, "build": "decay",  "skin": (0.45, 0.52, 0.38, 1.0)},
        "zombie_runner":   {"height": 1.70, "build": "lean",   "skin": (0.50, 0.55, 0.42, 1.0)},
        "zombie_crawler":  {"height": 0.55, "build": "decay",  "skin": (0.40, 0.48, 0.35, 1.0)},
        "zombie_bloater":  {"height": 1.65, "build": "bloat",  "skin": (0.55, 0.50, 0.40, 1.0)},
        "zombie_screamer": {"height": 1.68, "build": "lean",   "skin": (0.48, 0.52, 0.42, 1.0)},
        "zombie_spitter":  {"height": 1.74, "build": "decay",  "skin": (0.42, 0.55, 0.35, 1.0)},
        "zombie_brute":    {"height": 2.15, "build": "brute",  "skin": (0.52, 0.48, 0.40, 1.0)},
        "zombie_ravager":  {"height": 1.98, "build": "muscle", "skin": (0.48, 0.45, 0.38, 1.0)},
    }
    
    BUILD_PARAMS = {
        "lean":   {"bulk": 0.88, "muscle": 0.82, "fat": 0.80},
        "decay":  {"bulk": 0.90, "muscle": 0.75, "fat": 0.85},
        "bloat":  {"bulk": 1.45, "muscle": 0.65, "fat": 1.50},
        "brute":  {"bulk": 1.35, "muscle": 1.35, "fat": 1.10},
        "muscle": {"bulk": 1.12, "muscle": 1.25, "fat": 0.90},
    }
    
    def __init__(self, seed=None):
        self.char_gen = DetailedHumanGenerator(seed)
        if seed:
            random.seed(seed)
    
    def generate(self, name: str, zombie_type: str = "zombie_walker") -> bpy.types.Object:
        """Generate a zombie."""
        config = self.ZOMBIE_CONFIGS.get(zombie_type, self.ZOMBIE_CONFIGS["zombie_walker"])
        build_name = config["build"]
        
        # Create temp config for character generator
        temp_config = {
            "height": config["height"],
            "build": build_name,
            "gender": "male",
            "skin": config["skin"],
            "shirt_color": (0.28, 0.25, 0.22, 1.0),
            "pants_color": (0.25, 0.22, 0.20, 1.0),
            "boots_color": (0.18, 0.15, 0.12, 1.0),
            "hair_color": (0.0, 0.0, 0.0, 1.0),
            "has_jacket": False,
        }
        
        self.char_gen.CHARACTER_CONFIGS["_zombie"] = temp_config
        self.char_gen.BUILD_PARAMS[build_name] = self.BUILD_PARAMS.get(build_name, {"bulk": 1.0, "muscle": 1.0, "fat": 1.0})
        
        zombie = self.char_gen.generate(name, "_zombie")
        
        # Add decay/damage
        self._add_decay(zombie, zombie_type)
        
        return zombie
    
    def _add_decay(self, obj: bpy.types.Object, zombie_type: str) -> None:
        """Add decay effects to zombie."""
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        # Random vertex displacement for decay look
        decay_amount = 0.015 if "bloater" in zombie_type else 0.010
        for v in bm.verts:
            v.co.x += random.uniform(-decay_amount, decay_amount)
            v.co.y += random.uniform(-decay_amount, decay_amount)
            v.co.z += random.uniform(-decay_amount * 0.5, decay_amount * 0.5)
        
        # Lean/slouch
        lean = random.uniform(-0.08, 0.08)
        for v in bm.verts:
            if v.co.z > 0.8:
                v.co.x += lean * (v.co.z - 0.8)
                v.co.y += random.uniform(-0.02, 0.04) * (v.co.z - 0.8)
        
        bm.to_mesh(obj.data)
        bm.free()
