"""
Organic Human Body Generator
Focus: Creating a realistic human body silhouette with proper volume and organic shapes.
No clothing - just the base body mesh that looks human.
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector


class OrganicBodyGenerator:
    """Generate organic, human-looking body meshes."""
    
    CHARACTER_CONFIGS = {
        "survivor_male": {"height": 1.80, "build": "athletic", "gender": "male"},
        "survivor_female": {"height": 1.68, "build": "athletic_f", "gender": "female"},
        "npc_trader": {"height": 1.75, "build": "stocky", "gender": "male"},
        "npc_mechanic": {"height": 1.82, "build": "muscular", "gender": "male"},
        "raider_scout": {"height": 1.76, "build": "lean", "gender": "male"},
        "raider_heavy": {"height": 1.92, "build": "heavy", "gender": "male"},
    }
    
    # Skin tones
    SKIN_TONES = {
        "survivor_male": (0.76, 0.60, 0.48, 1.0),
        "survivor_female": (0.80, 0.65, 0.52, 1.0),
        "npc_trader": (0.72, 0.56, 0.44, 1.0),
        "npc_mechanic": (0.68, 0.52, 0.40, 1.0),
        "raider_scout": (0.70, 0.54, 0.42, 1.0),
        "raider_heavy": (0.65, 0.50, 0.38, 1.0),
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, char_type: str = "survivor_male") -> bpy.types.Object:
        """Generate an organic human body."""
        config = self.CHARACTER_CONFIGS.get(char_type, self.CHARACTER_CONFIGS["survivor_male"])
        
        H = config["height"]
        is_female = config.get("gender", "male") == "female"
        build = config["build"]
        
        # Create the body as one unified mesh for more organic look
        body = self._create_unified_body(H, build, is_female)
        body.name = name
        
        # Apply skin material
        skin_color = self.SKIN_TONES.get(char_type, (0.75, 0.60, 0.48, 1.0))
        mat = self._create_skin_material(name, skin_color)
        body.data.materials.append(mat)
        
        # Smooth shading
        bpy.ops.object.shade_smooth()
        
        # Set origin to ground
        self._set_origin_to_ground(body)
        
        return body
    
    def _create_unified_body(self, H: float, build: str, is_female: bool) -> bpy.types.Object:
        """Create the entire body as connected organic shapes."""
        
        # Build parameters
        builds = {
            "lean":       {"mass": 0.88, "muscle": 0.92},
            "athletic":   {"mass": 1.00, "muscle": 1.05},
            "athletic_f": {"mass": 0.95, "muscle": 0.95},
            "stocky":     {"mass": 1.12, "muscle": 1.00},
            "muscular":   {"mass": 1.08, "muscle": 1.18},
            "heavy":      {"mass": 1.22, "muscle": 1.08},
        }
        b = builds.get(build, builds["athletic"])
        mass = b["mass"]
        muscle = b["muscle"]
        
        # Human proportions (8 heads system)
        head = H / 8.0
        
        all_parts = []
        
        # ================================================================
        # TORSO - The core of the body, organic shape
        # ================================================================
        torso = self._create_organic_torso(head, mass, muscle, is_female)
        all_parts.append(torso)
        
        # Torso spans from hips to shoulders
        torso_bottom = head * 0.0  # At hip level (we'll add legs below)
        torso_top = head * 3.0     # Shoulder level
        torso.location.z = (torso_bottom + torso_top) / 2
        
        # ================================================================
        # LEGS - Organic leg shapes with proper volume
        # ================================================================
        leg_length = head * 4.0  # Legs are 4 heads (half the body)
        
        for side in [-1, 1]:
            leg = self._create_organic_leg(head, mass, muscle, is_female)
            # Position at hip
            hip_width = head * 0.85 * mass
            if is_female:
                hip_width *= 1.08
            leg.location = Vector((side * hip_width * 0.5, 0, leg_length / 2))
            all_parts.append(leg)
        
        # ================================================================
        # ARMS - Organic arm shapes
        # ================================================================
        arm_length = head * 2.8  # Upper arm + forearm
        shoulder_width = head * 2.0 * mass
        shoulder_z = torso_top - head * 0.15
        
        for side in [-1, 1]:
            arm = self._create_organic_arm(head, mass, muscle, is_female)
            arm.location = Vector((side * shoulder_width * 0.52, 0, shoulder_z - arm_length * 0.5))
            all_parts.append(arm)
        
        # ================================================================
        # HANDS
        # ================================================================
        hand_z = shoulder_z - arm_length - head * 0.1
        for side in [-1, 1]:
            hand = self._create_hand(head, mass)
            hand.location = Vector((side * shoulder_width * 0.52, 0, hand_z))
            all_parts.append(hand)
        
        # ================================================================
        # NECK
        # ================================================================
        neck = self._create_neck(head, mass, muscle)
        neck.location.z = torso_top + head * 0.15
        all_parts.append(neck)
        
        # ================================================================
        # HEAD
        # ================================================================
        head_mesh = self._create_organic_head(head, is_female)
        head_mesh.location.z = torso_top + head * 0.8
        all_parts.append(head_mesh)
        
        # ================================================================
        # JOIN ALL PARTS
        # ================================================================
        bpy.ops.object.select_all(action='DESELECT')
        for part in all_parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = all_parts[0]
        bpy.ops.object.join()
        
        body = bpy.context.active_object
        
        # Apply subdivision for smoothness
        bpy.ops.object.modifier_add(type='SUBSURF')
        body.modifiers["Subdivision"].levels = 1
        body.modifiers["Subdivision"].render_levels = 1
        bpy.ops.object.modifier_apply(modifier="Subdivision")
        
        return body
    
    def _create_organic_torso(self, head: float, mass: float, muscle: float, is_female: bool) -> bpy.types.Object:
        """Create an organic torso with proper human shape."""
        
        # Torso dimensions
        height = head * 3.0  # From hips to shoulders
        
        # Create base cylinder with more segments for organic shaping
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16,
            radius=head * 0.9 * mass,
            depth=height,
            end_fill_type='NGON'
        )
        torso = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(torso.data)
        
        # Key vertical zones (0 = bottom/hips, 1 = top/shoulders)
        for v in bm.verts:
            t = (v.co.z + height/2) / height  # 0 at hips, 1 at shoulders
            
            # Get angle around body (for front/back/side variation)
            angle = math.atan2(v.co.y, v.co.x)
            is_front = v.co.y > 0
            is_side = abs(v.co.x) > abs(v.co.y)
            
            # ============================================
            # WIDTH (X) - Side to side
            # ============================================
            
            # Hips (bottom) - wider for stability
            if t < 0.2:
                hip_width = 1.0 if not is_female else 1.15
                v.co.x *= hip_width
            
            # Waist (middle) - narrower
            elif t > 0.25 and t < 0.45:
                waist_narrow = 0.72 if not is_female else 0.68
                # Smooth transition
                if t < 0.35:
                    factor = (t - 0.25) / 0.1
                    waist_narrow = 1.0 - (1.0 - waist_narrow) * factor
                elif t > 0.40:
                    factor = (t - 0.40) / 0.05
                    waist_narrow = waist_narrow + (1.0 - waist_narrow) * factor
                v.co.x *= waist_narrow
            
            # Chest/ribcage - expands
            elif t > 0.45 and t < 0.75:
                chest_expand = 1.05 * muscle
                v.co.x *= chest_expand
            
            # Shoulders (top) - widest
            elif t > 0.8:
                shoulder_width = 1.15 * muscle if not is_female else 1.0
                v.co.x *= shoulder_width
            
            # ============================================
            # DEPTH (Y) - Front to back
            # ============================================
            
            # Hips/buttocks - back protrusion
            if t < 0.25 and not is_front:
                butt = 1.0 + (0.25 - t) * 0.4
                if is_female:
                    butt *= 1.15
                v.co.y *= butt
            
            # Lower back curve (lumbar)
            if t > 0.2 and t < 0.45 and not is_front:
                curve_in = 0.88
                v.co.y *= curve_in
            
            # Belly (slight curve forward)
            if t > 0.25 and t < 0.5 and is_front:
                belly = 1.0 + math.sin((t - 0.25) / 0.25 * math.pi) * 0.08 * mass
                v.co.y *= belly
            
            # Chest - pecs or breasts
            if t > 0.55 and t < 0.85 and is_front:
                if is_female:
                    # Breasts
                    breast_t = (t - 0.55) / 0.3
                    breast = 1.0 + math.sin(breast_t * math.pi) * 0.35
                    # More projection on sides
                    side_factor = abs(math.sin(angle)) * 0.5 + 0.5
                    v.co.y *= 1.0 + (breast - 1.0) * side_factor
                else:
                    # Pecs
                    pec_t = (t - 0.55) / 0.3
                    pec = 1.0 + math.sin(pec_t * math.pi) * 0.15 * muscle
                    v.co.y *= pec
            
            # Upper back (lats)
            if t > 0.5 and t < 0.85 and not is_front:
                lat = 1.0 + math.sin((t - 0.5) / 0.35 * math.pi) * 0.12 * muscle
                v.co.y *= lat
            
            # Shoulders round off
            if t > 0.85:
                round_factor = (t - 0.85) / 0.15
                v.co.z -= height * 0.05 * round_factor * abs(v.co.x) / (head * mass)
        
        bm.to_mesh(torso.data)
        bm.free()
        
        return torso
    
    def _create_organic_leg(self, head: float, mass: float, muscle: float, is_female: bool) -> bpy.types.Object:
        """Create an organic leg with proper anatomy."""
        
        leg_length = head * 4.0
        
        # Create cylinder
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=head * 0.32 * mass,
            depth=leg_length,
            end_fill_type='NGON'
        )
        leg = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(leg.data)
        
        for v in bm.verts:
            t = (v.co.z + leg_length/2) / leg_length  # 0=foot, 1=hip
            
            angle = math.atan2(v.co.y, v.co.x)
            is_front = v.co.y > 0
            is_back = v.co.y < 0
            
            # Base radius scaling along length
            # Thicker at thigh, thinner at ankle
            radius_scale = 0.55 + t * 0.45  # 0.55 at ankle, 1.0 at hip
            
            # ============================================
            # THIGH (upper 50%)
            # ============================================
            if t > 0.5:
                thigh_t = (t - 0.5) / 0.5
                
                # Thigh gets thicker toward hip
                base = 0.85 + thigh_t * 0.15
                
                # Quadriceps (front bulge)
                if is_front:
                    quad = 1.0 + math.sin(thigh_t * math.pi) * 0.25 * muscle
                    v.co.y *= quad
                
                # Hamstrings (back)
                if is_back:
                    ham = 1.0 + math.sin(thigh_t * math.pi) * 0.18 * muscle
                    v.co.y *= ham
                
                # Inner thigh fullness
                if is_female and t > 0.6:
                    inner = 1.0 + (t - 0.6) * 0.25
                    if v.co.x > 0:  # Inner side
                        v.co.x *= inner
                
                radius_scale *= base
            
            # ============================================
            # KNEE (around 45-55%)
            # ============================================
            if t > 0.42 and t < 0.55:
                knee_t = abs(t - 0.48) / 0.07
                knee_narrow = 0.92 + knee_t * 0.08
                radius_scale *= knee_narrow
                
                # Kneecap (front)
                if is_front and t > 0.45 and t < 0.52:
                    v.co.y += head * 0.04
            
            # ============================================
            # CALF (25-45%)
            # ============================================
            if t > 0.22 and t < 0.45:
                calf_t = (t - 0.22) / 0.23
                
                # Calf muscle (back, upper portion)
                if is_back:
                    calf_bulge = math.sin(calf_t * math.pi) * 0.35 * muscle
                    v.co.y -= head * 0.15 * calf_bulge
                
                # Slight shin bone (front)
                if is_front:
                    v.co.y -= head * 0.02
                
                # Calf width
                radius_scale *= 0.75 + math.sin(calf_t * math.pi) * 0.15 * muscle
            
            # ============================================
            # ANKLE (bottom 22%)
            # ============================================
            if t < 0.22:
                ankle_t = t / 0.22
                radius_scale *= 0.55 + ankle_t * 0.2  # Thin ankle
                
                # Ankle bones protrude on sides
                if abs(v.co.x) > abs(v.co.y) and t < 0.12:
                    v.co.x *= 1.0 + (0.12 - t) * 1.5
            
            # Apply radius scaling
            v.co.x *= radius_scale
            v.co.y *= radius_scale
            
            # ============================================
            # FOOT (bottom portion extends forward)
            # ============================================
            if t < 0.08:
                foot_t = t / 0.08
                # Foot extends forward
                v.co.y += head * 0.5 * (1.0 - foot_t)
                # Flatten
                if v.co.z < -leg_length/2 + head * 0.15:
                    v.co.z = -leg_length/2 + head * 0.05
        
        bm.to_mesh(leg.data)
        bm.free()
        
        return leg
    
    def _create_organic_arm(self, head: float, mass: float, muscle: float, is_female: bool) -> bpy.types.Object:
        """Create an organic arm with proper anatomy."""
        
        arm_length = head * 2.8  # Upper arm + forearm
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10,
            radius=head * 0.18 * muscle,
            depth=arm_length,
            end_fill_type='NGON'
        )
        arm = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(arm.data)
        
        for v in bm.verts:
            t = (v.co.z + arm_length/2) / arm_length  # 0=hand end, 1=shoulder
            
            is_front = v.co.y > 0  # Front of arm (bicep side)
            is_back = v.co.y < 0   # Back of arm (tricep side)
            
            # Base taper - thicker at shoulder, thinner at wrist
            radius_scale = 0.6 + t * 0.4
            
            # ============================================
            # UPPER ARM / BICEP (top 55%)
            # ============================================
            if t > 0.45:
                upper_t = (t - 0.45) / 0.55
                
                # Deltoid attachment at very top
                if t > 0.85:
                    delt = 1.0 + (t - 0.85) * 2.0 * muscle
                    radius_scale *= delt
                
                # Bicep (front)
                if is_front and t > 0.5 and t < 0.85:
                    bicep_t = (t - 0.5) / 0.35
                    bicep = math.sin(bicep_t * math.pi) * 0.35 * muscle
                    v.co.y += head * 0.06 * bicep
                
                # Tricep (back)
                if is_back and t > 0.5 and t < 0.85:
                    tricep_t = (t - 0.5) / 0.35
                    tricep = math.sin(tricep_t * math.pi) * 0.25 * muscle
                    v.co.y -= head * 0.05 * tricep
            
            # ============================================
            # ELBOW (around 40-50%)
            # ============================================
            if t > 0.38 and t < 0.52:
                elbow_t = abs(t - 0.45) / 0.07
                radius_scale *= 0.85 + elbow_t * 0.15
                
                # Elbow point (back)
                if is_back and t > 0.42 and t < 0.48:
                    v.co.y -= head * 0.03
            
            # ============================================
            # FOREARM (15-40%)
            # ============================================
            if t > 0.15 and t < 0.42:
                forearm_t = (t - 0.15) / 0.27
                
                # Forearm muscles (bulge near elbow)
                if forearm_t > 0.4:
                    bulge = math.sin((forearm_t - 0.4) / 0.6 * math.pi) * 0.25 * muscle
                    radius_scale *= 1.0 + bulge
            
            # ============================================
            # WRIST (bottom 15%)
            # ============================================
            if t < 0.15:
                wrist_t = t / 0.15
                radius_scale *= 0.6 + wrist_t * 0.25  # Thin wrist
                
                # Wrist bones
                if abs(v.co.x) > abs(v.co.y):
                    v.co.x *= 1.0 + (0.15 - t) * 0.8
            
            # Apply radius scaling
            v.co.x *= radius_scale
            v.co.y *= radius_scale
        
        bm.to_mesh(arm.data)
        bm.free()
        
        return arm
    
    def _create_hand(self, head: float, mass: float) -> bpy.types.Object:
        """Create a simple but recognizable hand."""
        
        hand_length = head * 0.75
        hand_width = head * 0.35
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        hand = bpy.context.active_object
        hand.scale = (hand_width, head * 0.15, hand_length)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(hand.data)
        
        for v in bm.verts:
            t = (v.co.z + hand_length/2) / hand_length  # 0=fingers, 1=wrist
            
            # Taper toward fingers
            if t < 0.5:
                taper = 0.7 + t * 0.6
                v.co.x *= taper
            
            # Palm thickness
            if t > 0.4 and v.co.y < 0:
                v.co.y -= head * 0.02
            
            # Knuckles
            if t > 0.4 and t < 0.6 and v.co.y > 0:
                v.co.y += head * 0.015
        
        bm.to_mesh(hand.data)
        bm.free()
        
        # Add simple fingers as one block
        bpy.ops.mesh.primitive_cube_add(size=1)
        fingers = bpy.context.active_object
        fingers.scale = (hand_width * 0.85, head * 0.10, hand_length * 0.45)
        fingers.location = Vector((0, 0, -hand_length * 0.5 - hand_length * 0.2))
        bpy.ops.object.transform_apply(scale=True)
        
        # Shape fingers
        bm = bmesh.new()
        bm.from_mesh(fingers.data)
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= 0.7
        bm.to_mesh(fingers.data)
        bm.free()
        
        # Thumb
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=head * 0.04, depth=head * 0.25)
        thumb = bpy.context.active_object
        thumb.rotation_euler = (math.radians(30), math.radians(40), 0)
        thumb.location = Vector((hand_width * 0.45, 0, -hand_length * 0.1))
        bpy.ops.object.transform_apply(rotation=True)
        
        # Join all
        bpy.ops.object.select_all(action='DESELECT')
        hand.select_set(True)
        fingers.select_set(True)
        thumb.select_set(True)
        bpy.context.view_layer.objects.active = hand
        bpy.ops.object.join()
        
        return hand
    
    def _create_neck(self, head: float, mass: float, muscle: float) -> bpy.types.Object:
        """Create neck."""
        
        neck_height = head * 0.35
        neck_radius = head * 0.22 * mass
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10,
            radius=neck_radius,
            depth=neck_height
        )
        neck = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(neck.data)
        
        for v in bm.verts:
            t = (v.co.z + neck_height/2) / neck_height
            
            # Wider at base (trapezius)
            if t < 0.4:
                expand = 1.0 + (0.4 - t) * 0.5 * muscle
                v.co.x *= expand
                v.co.y *= expand * 0.85
            
            # Adam's apple (front, middle)
            if v.co.y > 0 and t > 0.3 and t < 0.6:
                v.co.y += neck_radius * 0.1
        
        bm.to_mesh(neck.data)
        bm.free()
        
        return neck
    
    def _create_organic_head(self, head: float, is_female: bool) -> bpy.types.Object:
        """Create an organic head shape."""
        
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=16,
            ring_count=12,
            radius=head * 0.52
        )
        head_mesh = bpy.context.active_object
        
        # Slightly elongate
        head_mesh.scale = (0.88, 0.92, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(head_mesh.data)
        
        head_r = head * 0.52
        
        for v in bm.verts:
            z_norm = v.co.z / head_r
            y_norm = v.co.y / head_r
            x_norm = v.co.x / head_r
            
            # Flatten top slightly
            if z_norm > 0.7:
                v.co.z *= 0.95
            
            # Jaw narrowing
            if z_norm < -0.15:
                jaw_t = (abs(z_norm) - 0.15) / 0.85
                jaw_narrow = 1.0 - jaw_t * 0.45
                v.co.x *= max(0.45, jaw_narrow)
                
                # Chin protrusion
                if z_norm < -0.6 and y_norm > 0:
                    v.co.y += head_r * 0.12 * (1.0 - abs(x_norm))
                    v.co.z -= head_r * 0.05
            
            # Cheekbones
            if z_norm > -0.2 and z_norm < 0.15 and abs(x_norm) > 0.4:
                cheek = 1.0 + (0.15 - abs(z_norm - (-0.025))) * 0.3
                v.co.y += head_r * 0.05 * min(1.0, cheek)
            
            # Brow ridge
            if z_norm > 0.1 and z_norm < 0.35 and y_norm > 0.65:
                brow = (0.35 - z_norm) / 0.25 * 0.08
                v.co.y += head_r * brow
                v.co.z += head_r * brow * 0.3
            
            # Eye sockets (indent)
            if z_norm > 0 and z_norm < 0.25 and y_norm > 0.5:
                if abs(x_norm) > 0.15 and abs(x_norm) < 0.5:
                    socket_depth = 0.06
                    v.co.y -= head_r * socket_depth
            
            # Nose bridge/nose
            if z_norm > -0.15 and z_norm < 0.2 and abs(x_norm) < 0.12:
                if y_norm > 0.6:
                    nose = (0.2 - z_norm) / 0.35 * 0.15
                    v.co.y += head_r * nose
            
            # Softer features for female
            if is_female:
                # Softer jaw
                if z_norm < 0:
                    v.co.x *= 0.96
                # Fuller lips area
                if z_norm < -0.3 and z_norm > -0.45 and y_norm > 0.4:
                    v.co.y += head_r * 0.03
        
        bm.to_mesh(head_mesh.data)
        bm.free()
        
        # Add ears
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(size=1)
            ear = bpy.context.active_object
            ear.scale = (head * 0.04, head * 0.08, head * 0.13)
            ear.location = Vector((side * head * 0.45, -head * 0.05, head * 0.02))
            bpy.ops.object.transform_apply(scale=True)
            
            # Join to head
            bpy.ops.object.select_all(action='DESELECT')
            head_mesh.select_set(True)
            ear.select_set(True)
            bpy.context.view_layer.objects.active = head_mesh
            bpy.ops.object.join()
        
        # Add nose
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=head * 0.06, radius2=head * 0.03, depth=head * 0.15)
        nose = bpy.context.active_object
        nose.rotation_euler = (math.radians(70), 0, 0)
        nose.location = Vector((0, head * 0.48, -head * 0.05))
        bpy.ops.object.transform_apply(rotation=True)
        
        bpy.ops.object.select_all(action='DESELECT')
        head_mesh.select_set(True)
        nose.select_set(True)
        bpy.context.view_layer.objects.active = head_mesh
        bpy.ops.object.join()
        
        return head_mesh
    
    def _create_skin_material(self, name: str, color: tuple) -> bpy.types.Material:
        """Create skin material with subsurface scattering look."""
        mat = bpy.data.materials.new(name=f"{name}_skin")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = color
            bsdf.inputs["Roughness"].default_value = 0.55
            # Subsurface for skin-like quality
            bsdf.inputs["Subsurface Weight"].default_value = 0.15
            bsdf.inputs["Subsurface Radius"].default_value = (0.5, 0.25, 0.15)
        return mat
    
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


class OrganicZombieGenerator:
    """Generate zombie variants using organic body."""
    
    ZOMBIE_CONFIGS = {
        "zombie_walker":   {"height": 1.72, "build": "decay"},
        "zombie_runner":   {"height": 1.70, "build": "lean"},
        "zombie_crawler":  {"height": 0.60, "build": "decay"},
        "zombie_bloater":  {"height": 1.65, "build": "bloat"},
        "zombie_screamer": {"height": 1.68, "build": "lean"},
        "zombie_spitter":  {"height": 1.74, "build": "decay"},
        "zombie_brute":    {"height": 2.15, "build": "heavy"},
        "zombie_ravager":  {"height": 1.98, "build": "muscular"},
    }
    
    ZOMBIE_SKIN = (0.48, 0.52, 0.40, 1.0)  # Greenish dead skin
    
    def __init__(self, seed=None):
        self.body_gen = OrganicBodyGenerator(seed)
        if seed:
            random.seed(seed)
    
    def generate(self, name: str, zombie_type: str = "zombie_walker") -> bpy.types.Object:
        """Generate zombie."""
        config = self.ZOMBIE_CONFIGS.get(zombie_type, self.ZOMBIE_CONFIGS["zombie_walker"])
        
        # Modify the body generator's config
        self.body_gen.CHARACTER_CONFIGS["_zombie"] = {
            "height": config["height"],
            "build": config["build"],
            "gender": "male"
        }
        self.body_gen.SKIN_TONES["_zombie"] = self.ZOMBIE_SKIN
        
        zombie = self.body_gen.generate(name, "_zombie")
        
        # Add decay/slouch
        self._add_decay(zombie, zombie_type)
        
        return zombie
    
    def _add_decay(self, obj: bpy.types.Object, zombie_type: str) -> None:
        """Add decay to zombie mesh."""
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        # Vertex noise for decayed look
        for v in bm.verts:
            v.co.x += random.uniform(-0.015, 0.015)
            v.co.y += random.uniform(-0.01, 0.01)
        
        # Slouch/lean
        lean_x = random.uniform(-0.06, 0.06)
        lean_y = random.uniform(-0.03, 0.05)
        
        for v in bm.verts:
            if v.co.z > 0.5:
                factor = (v.co.z - 0.5) * 0.1
                v.co.x += lean_x * factor
                v.co.y += lean_y * factor
        
        bm.to_mesh(obj.data)
        bm.free()
