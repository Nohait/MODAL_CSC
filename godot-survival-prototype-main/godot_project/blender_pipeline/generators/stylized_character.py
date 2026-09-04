"""
Stylized Low-Poly Character Generator
=====================================
Creates clean, readable human characters with proper proportions.
Inspired by games like Astroneer, TABS, and modern survival games.

Key principles:
1. Proper anatomical proportions (7-8 head heights for adults)
2. Clean geometric shapes that read well at distance
3. Multi-material support (skin, clothes, hair)
4. Distinct silhouettes for different character types
"""

import bpy
import bmesh
import math
from mathutils import Vector, Matrix

class StylizedCharacterGenerator:
    """Generates stylized low-poly human characters with proper proportions."""
    
    # Anatomical proportions (in head-heights)
    PROPORTIONS = {
        'total_height': 7.5,      # Total body is 7.5 heads tall
        'head_to_chin': 1.0,      # Head is 1 head unit
        'chin_to_shoulders': 0.3,  # Neck
        'shoulders_to_waist': 2.0, # Torso upper
        'waist_to_hips': 0.7,      # Torso lower
        'hips_to_knee': 1.75,      # Upper leg
        'knee_to_ankle': 1.75,     # Lower leg
        'shoulder_width': 1.8,     # Shoulders are 1.8 heads wide
        'hip_width': 1.2,          # Hips are 1.2 heads wide
        'arm_length': 2.5,         # Full arm length
    }
    
    # Color palettes for different character types
    PALETTES = {
        'survivor_male': {
            'skin': (0.76, 0.57, 0.42, 1.0),      # Warm skin tone
            'hair': (0.15, 0.10, 0.07, 1.0),       # Dark brown hair
            'shirt': (0.25, 0.35, 0.25, 1.0),      # Olive green shirt
            'pants': (0.20, 0.18, 0.15, 1.0),      # Dark brown pants
            'shoes': (0.12, 0.10, 0.08, 1.0),      # Dark shoes
        },
        'survivor_female': {
            'skin': (0.80, 0.62, 0.48, 1.0),
            'hair': (0.45, 0.25, 0.12, 1.0),       # Auburn hair
            'shirt': (0.6, 0.3, 0.3, 1.0),         # Red-ish shirt
            'pants': (0.15, 0.20, 0.35, 1.0),      # Blue jeans
            'shoes': (0.15, 0.12, 0.10, 1.0),
        },
        'zombie': {
            'skin': (0.45, 0.55, 0.40, 1.0),       # Greenish dead skin
            'hair': (0.20, 0.18, 0.15, 1.0),       # Dirty hair
            'shirt': (0.30, 0.28, 0.25, 1.0),      # Torn gray shirt
            'pants': (0.25, 0.22, 0.20, 1.0),      # Dirty pants
            'shoes': (0.15, 0.13, 0.10, 1.0),
        },
        'zombie_runner': {
            'skin': (0.50, 0.45, 0.35, 1.0),       # Yellowed skin
            'hair': (0.10, 0.08, 0.06, 1.0),
            'shirt': (0.35, 0.15, 0.12, 1.0),      # Blood-stained
            'pants': (0.20, 0.18, 0.16, 1.0),
            'shoes': (0.10, 0.08, 0.06, 1.0),
        },
        'zombie_brute': {
            'skin': (0.35, 0.45, 0.35, 1.0),       # Deep green
            'hair': (0.0, 0.0, 0.0, 0.0),          # Bald (transparent)
            'shirt': (0.25, 0.23, 0.20, 1.0),
            'pants': (0.22, 0.20, 0.18, 1.0),
            'shoes': (0.12, 0.10, 0.08, 1.0),
        },
    }
    
    def __init__(self, height=1.8, character_type='survivor_male'):
        """
        Initialize generator.
        
        Args:
            height: Total character height in meters
            character_type: One of the PALETTES keys
        """
        self.height = height
        self.head_size = height / self.PROPORTIONS['total_height']
        self.character_type = character_type
        self.palette = self.PALETTES.get(character_type, self.PALETTES['survivor_male'])
        self.materials = {}
        
    def create_material(self, name, color):
        """Create a material with the given color."""
        mat = bpy.data.materials.new(name=f"{self.character_type}_{name}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.7
        return mat
    
    def setup_materials(self):
        """Create all materials for this character."""
        for name, color in self.palette.items():
            self.materials[name] = self.create_material(name, color)
    
    def create_head(self):
        """Create a stylized head with facial features."""
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=8,
            radius=self.head_size * 0.5,
            location=(0, 0, self.height - self.head_size * 0.5)
        )
        head = bpy.context.active_object
        head.name = "Head"
        
        # Slightly flatten and elongate for stylized look
        head.scale = (0.85, 0.9, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        
        # Add material
        head.data.materials.append(self.materials['skin'])
        
        return head
    
    def create_hair(self, head):
        """Create stylized hair on top of head."""
        if self.palette['hair'][3] < 0.1:  # Skip if transparent (bald)
            return None
            
        hair_z = self.height - self.head_size * 0.15
        
        # Simple hair cap
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=10, ring_count=6,
            radius=self.head_size * 0.48,
            location=(0, 0, hair_z)
        )
        hair = bpy.context.active_object
        hair.name = "Hair"
        
        # Only keep top half
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(hair.data)
        verts_to_delete = [v for v in bm.verts if v.co.z < hair_z - self.head_size * 0.1]
        bmesh.ops.delete(bm, geom=verts_to_delete, context='VERTS')
        bmesh.update_edit_mesh(hair.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        hair.data.materials.append(self.materials['hair'])
        return hair
    
    def create_torso(self):
        """Create the torso/shirt area."""
        h = self.head_size
        shoulder_y = self.height - h - h * 0.3  # Below neck
        waist_y = shoulder_y - h * 2.0
        
        torso_height = shoulder_y - waist_y
        torso_center = (shoulder_y + waist_y) / 2
        
        # Create torso as tapered cylinder
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=h * self.PROPORTIONS['shoulder_width'] * 0.5,
            depth=torso_height,
            location=(0, 0, torso_center)
        )
        torso = bpy.context.active_object
        torso.name = "Torso"
        
        # Taper the bottom (waist is narrower)
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(torso.data)
        
        for v in bm.verts:
            if v.co.z < 0:  # Bottom half
                factor = 0.7  # Waist is 70% of shoulder width
                v.co.x *= factor
                v.co.y *= factor
        
        bmesh.update_edit_mesh(torso.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        # Add chest depth
        torso.scale.y = 0.6
        bpy.ops.object.transform_apply(scale=True)
        
        torso.data.materials.append(self.materials['shirt'])
        return torso, waist_y
    
    def create_hips(self, waist_y):
        """Create hip/pants upper area."""
        h = self.head_size
        hip_bottom = waist_y - h * 0.7
        hip_center = (waist_y + hip_bottom) / 2
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=h * self.PROPORTIONS['hip_width'] * 0.5,
            depth=waist_y - hip_bottom,
            location=(0, 0, hip_center)
        )
        hips = bpy.context.active_object
        hips.name = "Hips"
        hips.scale.y = 0.7
        bpy.ops.object.transform_apply(scale=True)
        
        hips.data.materials.append(self.materials['pants'])
        return hips, hip_bottom
    
    def create_leg(self, side, hip_bottom):
        """Create a leg (upper + lower + foot)."""
        h = self.head_size
        x_offset = h * 0.35 * side  # side is -1 or 1
        
        parts = []
        
        # Upper leg
        upper_len = h * self.PROPORTIONS['hips_to_knee']
        knee_y = hip_bottom - upper_len
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=h * 0.22,
            depth=upper_len,
            location=(x_offset, 0, hip_bottom - upper_len/2)
        )
        upper = bpy.context.active_object
        upper.name = f"UpperLeg_{'L' if side < 0 else 'R'}"
        upper.scale.y = 0.85
        bpy.ops.object.transform_apply(scale=True)
        upper.data.materials.append(self.materials['pants'])
        parts.append(upper)
        
        # Lower leg
        lower_len = h * self.PROPORTIONS['knee_to_ankle']
        ankle_y = knee_y - lower_len
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=h * 0.18,
            depth=lower_len,
            location=(x_offset, 0, knee_y - lower_len/2)
        )
        lower = bpy.context.active_object
        lower.name = f"LowerLeg_{'L' if side < 0 else 'R'}"
        lower.scale.y = 0.85
        bpy.ops.object.transform_apply(scale=True)
        lower.data.materials.append(self.materials['pants'])
        parts.append(lower)
        
        # Foot
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(x_offset, h * 0.12, ankle_y - h * 0.08)
        )
        foot = bpy.context.active_object
        foot.name = f"Foot_{'L' if side < 0 else 'R'}"
        foot.scale = (h * 0.18, h * 0.35, h * 0.12)
        bpy.ops.object.transform_apply(scale=True)
        foot.data.materials.append(self.materials['shoes'])
        parts.append(foot)
        
        return parts
    
    def create_arm(self, side, shoulder_y):
        """Create an arm (upper + lower + hand)."""
        h = self.head_size
        x_offset = h * self.PROPORTIONS['shoulder_width'] * 0.5 * side
        
        parts = []
        arm_len = h * self.PROPORTIONS['arm_length']
        upper_len = arm_len * 0.45
        lower_len = arm_len * 0.40
        hand_len = arm_len * 0.15
        
        # Upper arm - angled slightly outward
        elbow_y = shoulder_y - upper_len * 0.9
        elbow_x = x_offset + (h * 0.15 * side)
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=h * 0.14,
            depth=upper_len,
            location=((x_offset + elbow_x)/2, 0, (shoulder_y + elbow_y)/2)
        )
        upper = bpy.context.active_object
        upper.name = f"UpperArm_{'L' if side < 0 else 'R'}"
        
        # Rotate to angle
        angle = math.radians(15 * side)
        upper.rotation_euler.y = angle
        bpy.ops.object.transform_apply(rotation=True)
        upper.data.materials.append(self.materials['shirt'])
        parts.append(upper)
        
        # Lower arm
        wrist_y = elbow_y - lower_len
        wrist_x = elbow_x + (h * 0.05 * side)
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=h * 0.11,
            depth=lower_len,
            location=((elbow_x + wrist_x)/2, 0, (elbow_y + wrist_y)/2)
        )
        lower = bpy.context.active_object
        lower.name = f"LowerArm_{'L' if side < 0 else 'R'}"
        lower.rotation_euler.y = angle * 0.5
        bpy.ops.object.transform_apply(rotation=True)
        lower.data.materials.append(self.materials['skin'])
        parts.append(lower)
        
        # Hand
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(wrist_x, 0, wrist_y - h * 0.12)
        )
        hand = bpy.context.active_object
        hand.name = f"Hand_{'L' if side < 0 else 'R'}"
        hand.scale = (h * 0.12, h * 0.06, h * 0.18)
        bpy.ops.object.transform_apply(scale=True)
        hand.data.materials.append(self.materials['skin'])
        parts.append(hand)
        
        return parts
    
    def create_neck(self, shoulder_y):
        """Create neck connecting head to torso."""
        h = self.head_size
        neck_top = self.height - h
        neck_height = neck_top - shoulder_y
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=h * 0.18,
            depth=neck_height + h * 0.1,
            location=(0, 0, (neck_top + shoulder_y) / 2)
        )
        neck = bpy.context.active_object
        neck.name = "Neck"
        neck.data.materials.append(self.materials['skin'])
        return neck
    
    def generate(self, name="StylizedCharacter"):
        """Generate the complete character."""
        # Clear existing mesh objects selection
        bpy.ops.object.select_all(action='DESELECT')
        
        # Setup materials
        self.setup_materials()
        
        all_parts = []
        
        # Create body parts
        head = self.create_head()
        all_parts.append(head)
        
        hair = self.create_hair(head)
        if hair:
            all_parts.append(hair)
        
        torso, waist_y = self.create_torso()
        all_parts.append(torso)
        
        shoulder_y = self.height - self.head_size * 1.3
        neck = self.create_neck(shoulder_y)
        all_parts.append(neck)
        
        hips, hip_bottom = self.create_hips(waist_y)
        all_parts.append(hips)
        
        # Legs
        for side in [-1, 1]:
            leg_parts = self.create_leg(side, hip_bottom)
            all_parts.extend(leg_parts)
        
        # Arms
        for side in [-1, 1]:
            arm_parts = self.create_arm(side, shoulder_y)
            all_parts.extend(arm_parts)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in all_parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = all_parts[0]
        bpy.ops.object.join()
        
        character = bpy.context.active_object
        character.name = name
        
        # Center origin
        bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_VOLUME', center='MEDIAN')
        
        # Move to ground level
        character.location.z = self.height / 2
        
        return character


def generate_character(name, character_type='survivor_male', height=1.8):
    """Convenience function to generate a character."""
    generator = StylizedCharacterGenerator(height=height, character_type=character_type)
    return generator.generate(name)


# Test when run directly in Blender
if __name__ == "__main__":
    # Clear scene
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    # Generate test characters
    generate_character("Survivor", "survivor_male", 1.8)
