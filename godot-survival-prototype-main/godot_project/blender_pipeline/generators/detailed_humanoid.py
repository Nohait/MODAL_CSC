"""
Detailed Humanoid Generator
===========================
Creates realistic low-poly humanoid characters with:
- Proper skull/face shape (not spheres)
- Muscle definition in limbs
- Chest and shoulder anatomy
- Basic facial features
- Natural body contours
"""

import bpy
import bmesh
import math
from mathutils import Vector, Matrix

class DetailedHumanoidGenerator:
    """Generates detailed low-poly humanoid characters."""
    
    VARIANTS = {
        'survivor_male': {
            'height': 1.8,
            'build': 'athletic',  # slim, athletic, muscular
            'skin': (0.76, 0.57, 0.42, 1.0),
            'hair_color': (0.15, 0.10, 0.07, 1.0),
            'hair_style': 'short',
            'shirt': (0.25, 0.40, 0.25, 1.0),  # Olive green
            'pants': (0.22, 0.20, 0.18, 1.0),  # Dark brown
            'shoes': (0.15, 0.12, 0.10, 1.0),
            'eye_color': (0.3, 0.25, 0.2, 1.0),
        },
        'survivor_female': {
            'height': 1.68,
            'build': 'slim',
            'skin': (0.82, 0.65, 0.52, 1.0),
            'hair_color': (0.35, 0.18, 0.08, 1.0),
            'hair_style': 'ponytail',
            'shirt': (0.7, 0.25, 0.25, 1.0),  # Red shirt
            'pants': (0.18, 0.22, 0.38, 1.0),  # Blue jeans
            'shoes': (0.12, 0.10, 0.08, 1.0),
            'eye_color': (0.25, 0.35, 0.25, 1.0),
        },
        'zombie_common': {
            'height': 1.75,
            'build': 'slim',
            'skin': (0.45, 0.52, 0.38, 1.0),  # Greenish
            'hair_color': (0.18, 0.15, 0.12, 1.0),
            'hair_style': 'patchy',
            'shirt': (0.32, 0.30, 0.28, 1.0),  # Dirty gray
            'pants': (0.28, 0.25, 0.22, 1.0),
            'shoes': (0.18, 0.15, 0.12, 1.0),
            'eye_color': (0.8, 0.75, 0.5, 1.0),  # Yellowed
            'decay': 0.3,
        },
        'zombie_runner': {
            'height': 1.70,
            'build': 'slim',
            'skin': (0.55, 0.48, 0.35, 1.0),  # Yellowed
            'hair_color': (0.12, 0.10, 0.08, 1.0),
            'hair_style': 'messy',
            'shirt': (0.40, 0.18, 0.15, 1.0),  # Blood stained
            'pants': (0.25, 0.22, 0.20, 1.0),
            'shoes': (0.15, 0.12, 0.10, 1.0),
            'eye_color': (0.9, 0.6, 0.3, 1.0),
            'decay': 0.2,
        },
        'zombie_brute': {
            'height': 2.1,
            'build': 'muscular',
            'skin': (0.35, 0.42, 0.32, 1.0),  # Dark green
            'hair_color': None,  # Bald
            'hair_style': None,
            'shirt': (0.25, 0.22, 0.20, 1.0),
            'pants': (0.22, 0.20, 0.18, 1.0),
            'shoes': (0.12, 0.10, 0.08, 1.0),
            'eye_color': (1.0, 0.4, 0.2, 1.0),  # Orange/red
            'decay': 0.4,
        },
        'zombie_bloated': {
            'height': 1.85,
            'build': 'heavy',
            'skin': (0.50, 0.55, 0.45, 1.0),  # Pale green
            'hair_color': (0.20, 0.18, 0.15, 1.0),
            'hair_style': 'bald_patches',
            'shirt': (0.35, 0.32, 0.28, 1.0),
            'pants': (0.30, 0.28, 0.25, 1.0),
            'shoes': (0.18, 0.15, 0.12, 1.0),
            'eye_color': (0.7, 0.8, 0.5, 1.0),
            'decay': 0.5,
        },
    }
    
    # Build multipliers for body parts
    BUILDS = {
        'slim': {'torso': 0.85, 'arms': 0.85, 'legs': 0.9, 'shoulders': 0.9},
        'athletic': {'torso': 1.0, 'arms': 1.0, 'legs': 1.0, 'shoulders': 1.05},
        'muscular': {'torso': 1.15, 'arms': 1.25, 'legs': 1.15, 'shoulders': 1.2},
        'heavy': {'torso': 1.4, 'arms': 1.1, 'legs': 1.2, 'shoulders': 1.1},
    }
    
    def __init__(self, variant='survivor_male'):
        self.variant = variant
        self.config = self.VARIANTS.get(variant, self.VARIANTS['survivor_male'])
        self.height = self.config['height']
        self.build = self.BUILDS[self.config['build']]
        self.head_size = self.height / 7.5
        self.materials = {}
        self.is_zombie = 'zombie' in variant
        self.decay = self.config.get('decay', 0)
        
    def create_material(self, name, color, metallic=0.0, roughness=0.7):
        """Create a PBR material."""
        mat = bpy.data.materials.new(name=f"{self.variant}_{name}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        return mat
    
    def setup_materials(self):
        """Create all character materials."""
        self.materials['skin'] = self.create_material('skin', self.config['skin'], roughness=0.6)
        self.materials['shirt'] = self.create_material('shirt', self.config['shirt'], roughness=0.8)
        self.materials['pants'] = self.create_material('pants', self.config['pants'], roughness=0.75)
        self.materials['shoes'] = self.create_material('shoes', self.config['shoes'], roughness=0.9)
        self.materials['eye'] = self.create_material('eye', self.config['eye_color'], roughness=0.3)
        if self.config.get('hair_color'):
            self.materials['hair'] = self.create_material('hair', self.config['hair_color'], roughness=0.85)
    
    def create_skull_shape(self):
        """Create a realistic skull/head shape."""
        h = self.head_size
        head_z = self.height - h * 0.5
        
        # Start with UV sphere
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=16, ring_count=12,
            radius=h * 0.5,
            location=(0, 0, head_z)
        )
        head = bpy.context.active_object
        head.name = "Head"
        
        # Sculpt into skull shape
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(head.data)
        
        for v in bm.verts:
            local_z = v.co.z  # Local z relative to sphere center
            local_y = v.co.y
            local_x = v.co.x
            
            # Flatten the back of the head slightly
            if local_y < -h * 0.1:
                v.co.y *= 0.9
            
            # Create jaw area - narrow the bottom
            if local_z < -h * 0.15:
                jaw_factor = 1.0 - abs(local_z + h * 0.15) / (h * 0.35)
                jaw_factor = max(0.6, jaw_factor)
                v.co.x *= jaw_factor
                v.co.y *= jaw_factor * 0.85
            
            # Slight forehead protrusion
            if local_z > h * 0.15 and local_y > 0:
                v.co.y += 0.02 * h
            
            # Cheekbone area
            if -h * 0.1 < local_z < h * 0.1 and abs(local_x) > h * 0.2:
                v.co.x *= 1.05
                v.co.y *= 0.95
            
            # Brow ridge
            if h * 0.1 < local_z < h * 0.2 and local_y > h * 0.15:
                v.co.y += 0.015 * h
                v.co.z += 0.01 * h
            
            # Eye socket indentations
            if 0 < local_z < h * 0.15 and local_y > h * 0.2:
                if abs(local_x) > h * 0.08 and abs(local_x) < h * 0.25:
                    v.co.y -= 0.03 * h
            
            # Nose bridge protrusion
            if -h * 0.05 < local_z < h * 0.15 and abs(local_x) < h * 0.08:
                if local_y > h * 0.25:
                    v.co.y += 0.04 * h
            
            # Chin
            if local_z < -h * 0.35 and local_y > 0:
                v.co.y += 0.02 * h
                v.co.z -= 0.01 * h
        
        bmesh.update_edit_mesh(head.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        # Apply smooth shading
        bpy.ops.object.shade_smooth()
        
        head.data.materials.append(self.materials['skin'])
        return head
    
    def create_facial_features(self, head_z):
        """Create eyes, nose, and mouth indication."""
        h = self.head_size
        parts = []
        
        # Eyes
        for side in [-1, 1]:
            eye_x = side * h * 0.15
            eye_y = h * 0.38
            eye_z = head_z + h * 0.08
            
            # Eyeball
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=12, ring_count=8,
                radius=h * 0.055,
                location=(eye_x, eye_y, eye_z)
            )
            eye = bpy.context.active_object
            eye.name = f"Eye_{'L' if side < 0 else 'R'}"
            eye.scale.y = 0.7  # Flatten
            bpy.ops.object.transform_apply(scale=True)
            eye.data.materials.append(self.materials['eye'])
            parts.append(eye)
            
            # Pupil
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=8, ring_count=6,
                radius=h * 0.025,
                location=(eye_x, eye_y + h * 0.035, eye_z)
            )
            pupil = bpy.context.active_object
            pupil.name = f"Pupil_{'L' if side < 0 else 'R'}"
            
            # Black pupil material
            pupil_mat = bpy.data.materials.new(name="pupil")
            pupil_mat.use_nodes = True
            bsdf = pupil_mat.node_tree.nodes["Principled BSDF"]
            bsdf.inputs["Base Color"].default_value = (0.02, 0.02, 0.02, 1.0)
            pupil.data.materials.append(pupil_mat)
            parts.append(pupil)
        
        # Nose
        bpy.ops.mesh.primitive_cone_add(
            vertices=6,
            radius1=h * 0.04,
            radius2=h * 0.02,
            depth=h * 0.08,
            location=(0, h * 0.42, head_z - h * 0.02)
        )
        nose = bpy.context.active_object
        nose.name = "Nose"
        nose.rotation_euler.x = math.radians(70)
        bpy.ops.object.transform_apply(rotation=True)
        nose.data.materials.append(self.materials['skin'])
        parts.append(nose)
        
        # Ears
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(
                size=1,
                location=(side * h * 0.48, h * 0.02, head_z + h * 0.02)
            )
            ear = bpy.context.active_object
            ear.name = f"Ear_{'L' if side < 0 else 'R'}"
            ear.scale = (h * 0.025, h * 0.06, h * 0.09)
            bpy.ops.object.transform_apply(scale=True)
            ear.data.materials.append(self.materials['skin'])
            parts.append(ear)
        
        return parts
    
    def create_hair(self, head_z):
        """Create hair based on style."""
        h = self.head_size
        style = self.config.get('hair_style')
        
        if not style or style == 'bald' or not self.config.get('hair_color'):
            return None
        
        parts = []
        
        if style == 'short':
            # Short hair cap
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=12, ring_count=8,
                radius=h * 0.48,
                location=(0, -h * 0.02, head_z + h * 0.08)
            )
            hair = bpy.context.active_object
            
            # Remove bottom half
            bpy.ops.object.mode_set(mode='EDIT')
            bm = bmesh.from_edit_mesh(hair.data)
            verts_to_delete = [v for v in bm.verts if v.co.z < -h * 0.1]
            bmesh.ops.delete(bm, geom=verts_to_delete, context='VERTS')
            bmesh.update_edit_mesh(hair.data)
            bpy.ops.object.mode_set(mode='OBJECT')
            
            hair.data.materials.append(self.materials['hair'])
            parts.append(hair)
            
        elif style == 'ponytail':
            # Hair cap
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=12, ring_count=8,
                radius=h * 0.46,
                location=(0, -h * 0.02, head_z + h * 0.1)
            )
            cap = bpy.context.active_object
            
            bpy.ops.object.mode_set(mode='EDIT')
            bm = bmesh.from_edit_mesh(cap.data)
            verts_to_delete = [v for v in bm.verts if v.co.z < -h * 0.05]
            bmesh.ops.delete(bm, geom=verts_to_delete, context='VERTS')
            bmesh.update_edit_mesh(cap.data)
            bpy.ops.object.mode_set(mode='OBJECT')
            
            cap.data.materials.append(self.materials['hair'])
            parts.append(cap)
            
            # Ponytail
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=8,
                radius=h * 0.08,
                depth=h * 0.4,
                location=(0, -h * 0.35, head_z - h * 0.05)
            )
            tail = bpy.context.active_object
            tail.rotation_euler.x = math.radians(-30)
            bpy.ops.object.transform_apply(rotation=True)
            tail.data.materials.append(self.materials['hair'])
            parts.append(tail)
            
        elif style in ['messy', 'patchy', 'bald_patches']:
            # Messy/patchy hair for zombies
            import random
            random.seed(hash(self.variant))
            
            num_clumps = 5 if style == 'patchy' else 8
            for i in range(num_clumps):
                angle = random.uniform(0, math.pi * 2)
                dist = random.uniform(h * 0.3, h * 0.42)
                x = math.cos(angle) * dist * 0.3
                y = -math.sin(angle) * dist * 0.5
                z = head_z + h * 0.2 + random.uniform(0, h * 0.15)
                
                bpy.ops.mesh.primitive_uv_sphere_add(
                    segments=6, ring_count=4,
                    radius=h * random.uniform(0.08, 0.15),
                    location=(x, y, z)
                )
                clump = bpy.context.active_object
                clump.scale.z = random.uniform(0.6, 1.2)
                bpy.ops.object.transform_apply(scale=True)
                clump.data.materials.append(self.materials['hair'])
                parts.append(clump)
        
        return parts
    
    def create_neck(self):
        """Create neck with muscle definition."""
        h = self.head_size
        neck_base = self.height - h * 1.35
        neck_top = self.height - h
        neck_height = neck_top - neck_base
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=h * 0.18 * self.build['torso'],
            depth=neck_height,
            location=(0, 0, (neck_top + neck_base) / 2)
        )
        neck = bpy.context.active_object
        neck.name = "Neck"
        
        # Taper toward head
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(neck.data)
        for v in bm.verts:
            t = (v.co.z + neck_height/2) / neck_height
            taper = 0.85 + t * 0.15
            v.co.x *= taper
            v.co.y *= taper * 0.9
        bmesh.update_edit_mesh(neck.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        neck.data.materials.append(self.materials['skin'])
        return neck
    
    def create_torso(self):
        """Create detailed torso with chest and shoulder definition."""
        h = self.head_size
        build = self.build
        
        shoulder_z = self.height - h * 1.35
        chest_z = shoulder_z - h * 0.8
        waist_z = shoulder_z - h * 2.0
        hip_z = waist_z - h * 0.7
        
        parts = []
        
        # Chest/Upper torso
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16,
            radius=h * 0.9 * build['shoulders'],
            depth=h * 1.2,
            location=(0, 0, shoulder_z - h * 0.6)
        )
        chest = bpy.context.active_object
        chest.name = "Chest"
        
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(chest.data)
        
        for v in bm.verts:
            local_z = v.co.z
            t = (local_z + h * 0.6) / (h * 1.2)  # 0 at bottom, 1 at top
            
            # Shoulder width at top, waist narrower at bottom
            width_factor = 0.7 + t * 0.3  # Waist is 70% of shoulders
            v.co.x *= width_factor * build['torso']
            
            # Chest depth - front protrudes more than back
            if v.co.y > 0:
                chest_bulge = 1.0 + (1 - abs(t - 0.6) * 2) * 0.15  # Bulge at chest level
                v.co.y *= chest_bulge * 0.65 * build['torso']
            else:
                v.co.y *= 0.55 * build['torso']
            
            # Pectoral definition
            if 0.4 < t < 0.8 and v.co.y > 0:
                if abs(v.co.x) > h * 0.2:
                    v.co.y += 0.02 * h
                    v.co.z += 0.01 * h
        
        bmesh.update_edit_mesh(chest.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        chest.data.materials.append(self.materials['shirt'])
        parts.append(chest)
        
        # Shoulders (deltoid muscles)
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=10, ring_count=8,
                radius=h * 0.18 * build['shoulders'],
                location=(side * h * 0.75 * build['shoulders'], 0, shoulder_z - h * 0.1)
            )
            shoulder = bpy.context.active_object
            shoulder.name = f"Shoulder_{'L' if side < 0 else 'R'}"
            shoulder.scale = (1.0, 0.8, 0.9)
            bpy.ops.object.transform_apply(scale=True)
            shoulder.data.materials.append(self.materials['shirt'])
            parts.append(shoulder)
        
        # Lower torso/hips
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=h * 0.55 * build['torso'],
            depth=h * 0.7,
            location=(0, 0, waist_z - h * 0.35)
        )
        hips = bpy.context.active_object
        hips.name = "Hips"
        
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(hips.data)
        for v in bm.verts:
            t = (v.co.z + h * 0.35) / (h * 0.7)
            # Wider at hips, narrower at waist
            hip_factor = 0.85 + (1 - t) * 0.15
            v.co.x *= hip_factor
            v.co.y *= 0.7
        bmesh.update_edit_mesh(hips.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        hips.data.materials.append(self.materials['pants'])
        parts.append(hips)
        
        return parts, hip_z
    
    def create_arm(self, side, shoulder_z):
        """Create detailed arm with muscle definition."""
        h = self.head_size
        build = self.build
        
        parts = []
        
        # Attachment point
        shoulder_x = side * h * 0.78 * build['shoulders']
        
        # Upper arm (bicep/tricep)
        upper_len = h * 1.1
        elbow_z = shoulder_z - upper_len
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10,
            radius=h * 0.12 * build['arms'],
            depth=upper_len,
            location=(shoulder_x, 0, shoulder_z - upper_len/2)
        )
        upper = bpy.context.active_object
        upper.name = f"UpperArm_{'L' if side < 0 else 'R'}"
        
        # Muscle shape
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(upper.data)
        for v in bm.verts:
            t = (v.co.z + upper_len/2) / upper_len
            # Bicep bulge in middle
            bulge = 1.0 + math.sin(t * math.pi) * 0.2 * build['arms']
            v.co.x *= bulge
            v.co.y *= bulge * 0.9
        bmesh.update_edit_mesh(upper.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        upper.data.materials.append(self.materials['shirt'])
        parts.append(upper)
        
        # Elbow joint
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=8, ring_count=6,
            radius=h * 0.08 * build['arms'],
            location=(shoulder_x, 0, elbow_z)
        )
        elbow = bpy.context.active_object
        elbow.name = f"Elbow_{'L' if side < 0 else 'R'}"
        elbow.data.materials.append(self.materials['skin'])
        parts.append(elbow)
        
        # Forearm
        forearm_len = h * 0.95
        wrist_z = elbow_z - forearm_len
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10,
            radius=h * 0.09 * build['arms'],
            depth=forearm_len,
            location=(shoulder_x, 0, elbow_z - forearm_len/2)
        )
        forearm = bpy.context.active_object
        forearm.name = f"Forearm_{'L' if side < 0 else 'R'}"
        
        # Taper toward wrist
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(forearm.data)
        for v in bm.verts:
            t = (v.co.z + forearm_len/2) / forearm_len
            taper = 0.7 + t * 0.3
            v.co.x *= taper
            v.co.y *= taper
        bmesh.update_edit_mesh(forearm.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        forearm.data.materials.append(self.materials['skin'])
        parts.append(forearm)
        
        # Hand
        hand = self.create_hand(side, shoulder_x, wrist_z)
        parts.extend(hand)
        
        return parts
    
    def create_hand(self, side, x, wrist_z):
        """Create detailed hand with fingers."""
        h = self.head_size
        parts = []
        
        # Palm
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(x, 0, wrist_z - h * 0.08)
        )
        palm = bpy.context.active_object
        palm.name = f"Palm_{'L' if side < 0 else 'R'}"
        palm.scale = (h * 0.09, h * 0.05, h * 0.12)
        bpy.ops.object.transform_apply(scale=True)
        palm.data.materials.append(self.materials['skin'])
        parts.append(palm)
        
        # Fingers (4 fingers + thumb)
        finger_starts = [
            (x - h * 0.04, 0, wrist_z - h * 0.14),  # Index
            (x - h * 0.015, 0, wrist_z - h * 0.145),  # Middle
            (x + h * 0.015, 0, wrist_z - h * 0.14),  # Ring
            (x + h * 0.04, 0, wrist_z - h * 0.13),  # Pinky
        ]
        finger_lengths = [h * 0.08, h * 0.09, h * 0.085, h * 0.07]
        
        for i, (fx, fy, fz) in enumerate(finger_starts):
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6,
                radius=h * 0.018,
                depth=finger_lengths[i],
                location=(fx, fy, fz - finger_lengths[i]/2)
            )
            finger = bpy.context.active_object
            finger.name = f"Finger_{i}_{'L' if side < 0 else 'R'}"
            finger.data.materials.append(self.materials['skin'])
            parts.append(finger)
        
        # Thumb
        thumb_x = x - side * h * 0.06
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=h * 0.022,
            depth=h * 0.06,
            location=(thumb_x, h * 0.03, wrist_z - h * 0.06)
        )
        thumb = bpy.context.active_object
        thumb.name = f"Thumb_{'L' if side < 0 else 'R'}"
        thumb.rotation_euler = (math.radians(30), math.radians(-side * 30), 0)
        bpy.ops.object.transform_apply(rotation=True)
        thumb.data.materials.append(self.materials['skin'])
        parts.append(thumb)
        
        return parts
    
    def create_leg(self, side, hip_z):
        """Create detailed leg with muscle definition."""
        h = self.head_size
        build = self.build
        
        parts = []
        
        hip_x = side * h * 0.35 * build['legs']
        
        # Upper leg (thigh)
        thigh_len = h * 1.6
        knee_z = hip_z - thigh_len
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=h * 0.18 * build['legs'],
            depth=thigh_len,
            location=(hip_x, 0, hip_z - thigh_len/2)
        )
        thigh = bpy.context.active_object
        thigh.name = f"Thigh_{'L' if side < 0 else 'R'}"
        
        # Muscle shape - thicker at top
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(thigh.data)
        for v in bm.verts:
            t = (v.co.z + thigh_len/2) / thigh_len
            taper = 0.65 + t * 0.35
            bulge = 1.0 + math.sin(t * math.pi) * 0.15
            v.co.x *= taper * bulge
            v.co.y *= taper * bulge * 0.85
        bmesh.update_edit_mesh(thigh.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        thigh.data.materials.append(self.materials['pants'])
        parts.append(thigh)
        
        # Knee
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=10, ring_count=8,
            radius=h * 0.11 * build['legs'],
            location=(hip_x, 0, knee_z)
        )
        knee = bpy.context.active_object
        knee.name = f"Knee_{'L' if side < 0 else 'R'}"
        knee.scale.y = 0.8
        bpy.ops.object.transform_apply(scale=True)
        knee.data.materials.append(self.materials['pants'])
        parts.append(knee)
        
        # Lower leg (calf)
        calf_len = h * 1.5
        ankle_z = knee_z - calf_len
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10,
            radius=h * 0.11 * build['legs'],
            depth=calf_len,
            location=(hip_x, 0, knee_z - calf_len/2)
        )
        calf = bpy.context.active_object
        calf.name = f"Calf_{'L' if side < 0 else 'R'}"
        
        # Calf muscle shape
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(calf.data)
        for v in bm.verts:
            t = (v.co.z + calf_len/2) / calf_len
            taper = 0.6 + t * 0.4
            # Calf bulge at top-back
            if v.co.y < 0 and t > 0.6:
                calf_bulge = 1.0 + (t - 0.6) * 0.4
                v.co.y *= calf_bulge
            v.co.x *= taper
            v.co.y *= taper
        bmesh.update_edit_mesh(calf.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        calf.data.materials.append(self.materials['pants'])
        parts.append(calf)
        
        # Foot
        foot = self.create_foot(side, hip_x, ankle_z)
        parts.extend(foot)
        
        return parts
    
    def create_foot(self, side, x, ankle_z):
        """Create detailed foot."""
        h = self.head_size
        parts = []
        
        # Main foot
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(x, h * 0.08, ankle_z - h * 0.08)
        )
        foot = bpy.context.active_object
        foot.name = f"Foot_{'L' if side < 0 else 'R'}"
        foot.scale = (h * 0.12, h * 0.28, h * 0.1)
        bpy.ops.object.transform_apply(scale=True)
        
        # Taper toward toes
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(foot.data)
        for v in bm.verts:
            if v.co.y > 0:  # Front of foot
                v.co.x *= 0.8
                v.co.z *= 0.85
        bmesh.update_edit_mesh(foot.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        foot.data.materials.append(self.materials['shoes'])
        parts.append(foot)
        
        # Ankle
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=8, ring_count=6,
            radius=h * 0.06,
            location=(x, 0, ankle_z - h * 0.02)
        )
        ankle = bpy.context.active_object
        ankle.name = f"Ankle_{'L' if side < 0 else 'R'}"
        ankle.data.materials.append(self.materials['shoes'])
        parts.append(ankle)
        
        return parts
    
    def apply_zombie_decay(self, all_parts):
        """Apply decay effects to zombie characters."""
        if not self.is_zombie or self.decay <= 0:
            return
        
        import random
        random.seed(hash(self.variant))
        
        for part in all_parts:
            if random.random() < self.decay * 0.5:
                # Random vertex displacement for decay
                bpy.ops.object.select_all(action='DESELECT')
                part.select_set(True)
                bpy.context.view_layer.objects.active = part
                
                bpy.ops.object.mode_set(mode='EDIT')
                bm = bmesh.from_edit_mesh(part.data)
                
                for v in bm.verts:
                    if random.random() < self.decay:
                        v.co += Vector((
                            random.uniform(-0.01, 0.01),
                            random.uniform(-0.01, 0.01),
                            random.uniform(-0.01, 0.01)
                        ))
                
                bmesh.update_edit_mesh(part.data)
                bpy.ops.object.mode_set(mode='OBJECT')
    
    def generate(self, name=None):
        """Generate the complete humanoid."""
        if name is None:
            name = self.variant
        
        bpy.ops.object.select_all(action='DESELECT')
        self.setup_materials()
        
        all_parts = []
        
        # Head
        head = self.create_skull_shape()
        all_parts.append(head)
        
        head_z = self.height - self.head_size * 0.5
        
        # Facial features
        face_parts = self.create_facial_features(head_z)
        all_parts.extend(face_parts)
        
        # Hair
        hair_parts = self.create_hair(head_z)
        if hair_parts:
            all_parts.extend(hair_parts)
        
        # Neck
        neck = self.create_neck()
        all_parts.append(neck)
        
        # Torso
        shoulder_z = self.height - self.head_size * 1.35
        torso_parts, hip_z = self.create_torso()
        all_parts.extend(torso_parts)
        
        # Arms
        for side in [-1, 1]:
            arm_parts = self.create_arm(side, shoulder_z)
            all_parts.extend(arm_parts)
        
        # Legs
        for side in [-1, 1]:
            leg_parts = self.create_leg(side, hip_z)
            all_parts.extend(leg_parts)
        
        # Apply zombie decay
        self.apply_zombie_decay(all_parts)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in all_parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = all_parts[0]
        bpy.ops.object.join()
        
        character = bpy.context.active_object
        character.name = name
        
        # Set origin to feet
        bpy.context.scene.cursor.location = (0, 0, 0)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        
        # Apply smooth shading
        bpy.ops.object.shade_smooth()
        
        return character


def generate_humanoid(name, variant='survivor_male'):
    """Convenience function."""
    gen = DetailedHumanoidGenerator(variant)
    return gen.generate(name)


if __name__ == "__main__":
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    # Test
    variants = ['survivor_male', 'survivor_female', 'zombie_common', 'zombie_brute']
    for i, v in enumerate(variants):
        gen = DetailedHumanoidGenerator(v)
        char = gen.generate(v)
        char.location.x = i * 2.5
