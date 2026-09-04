"""
Detailed Zombie Generator - Creates various zombie types with proper detail
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector


class ZombieGenerator:
    """Generate detailed zombie character models."""
    
    # Zombie type configurations
    ZOMBIE_TYPES = {
        "walker": {
            "speed": "slow",
            "size": 1.0,
            "posture": "hunched",
            "damage_level": "medium",
            "color_decay": 0.5
        },
        "runner": {
            "speed": "fast", 
            "size": 0.95,
            "posture": "athletic",
            "damage_level": "low",
            "color_decay": 0.3
        },
        "crawler": {
            "speed": "slow",
            "size": 0.6,
            "posture": "crawling",
            "damage_level": "high",
            "color_decay": 0.7
        },
        "bloater": {
            "speed": "very_slow",
            "size": 1.4,
            "posture": "bloated",
            "damage_level": "extreme",
            "color_decay": 0.8
        },
        "screamer": {
            "speed": "medium",
            "size": 0.9,
            "posture": "hunched",
            "damage_level": "medium",
            "color_decay": 0.4
        },
        "spitter": {
            "speed": "medium",
            "size": 1.0,
            "posture": "hunched",
            "damage_level": "high",
            "color_decay": 0.6
        },
        "brute": {
            "speed": "slow",
            "size": 1.5,
            "posture": "hulking",
            "damage_level": "extreme",
            "color_decay": 0.6
        },
        "ravager": {
            "speed": "fast",
            "size": 1.8,
            "posture": "hulking",
            "damage_level": "extreme",
            "color_decay": 0.9
        }
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, zombie_type: str = "walker") -> bpy.types.Object:
        """Generate a zombie of the specified type."""
        config = self.ZOMBIE_TYPES.get(zombie_type, self.ZOMBIE_TYPES["walker"])
        
        parts = []
        
        # Get colors based on decay level
        skin_color, cloth_color, accent_color = self._get_zombie_colors(config["color_decay"])
        
        # Create materials
        skin_mat = self._create_zombie_skin_material(f"mat_{name}_skin", skin_color, config["color_decay"])
        cloth_mat = self._create_tattered_cloth_material(f"mat_{name}_cloth", cloth_color)
        gore_mat = self._create_gore_material(f"mat_{name}_gore")
        
        size = config["size"]
        posture = config["posture"]
        
        # Build body parts based on posture
        if posture == "crawling":
            parts.extend(self._create_crawling_body(size, skin_mat, cloth_mat, gore_mat))
        elif posture == "bloated":
            parts.extend(self._create_bloated_body(size, skin_mat, cloth_mat, gore_mat))
        elif posture == "hulking":
            parts.extend(self._create_hulking_body(size, skin_mat, cloth_mat, gore_mat))
        else:
            parts.extend(self._create_standard_body(size, skin_mat, cloth_mat, gore_mat, posture))
        
        # Add damage/decay details
        damage_level = config["damage_level"]
        if damage_level in ["high", "extreme"]:
            parts.extend(self._add_wounds(size, gore_mat))
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        zombie = bpy.context.active_object
        zombie.name = name
        
        # Apply flat shading
        for p in zombie.data.polygons:
            p.use_smooth = False
        
        return zombie
    
    def _get_zombie_colors(self, decay_level: float):
        """Get colors based on decay level (0-1)."""
        # Skin goes from pale to greenish-grey
        base_skin = (0.75, 0.68, 0.60)
        decayed_skin = (0.45, 0.52, 0.42)
        
        skin = tuple(
            base_skin[i] * (1 - decay_level) + decayed_skin[i] * decay_level
            for i in range(3)
        )
        
        # Clothes get darker and dirtier
        cloth = (
            0.35 - decay_level * 0.15,
            0.32 - decay_level * 0.12,
            0.28 - decay_level * 0.10
        )
        
        # Accent (blood stains, etc)
        accent = (0.35 + decay_level * 0.2, 0.08, 0.05)
        
        return skin, cloth, accent
    
    def _create_zombie_skin_material(self, name: str, base_color: tuple, decay: float):
        """Create zombie skin material with veins and decay."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (600, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (300, 0)
        bsdf.inputs["Roughness"].default_value = 0.7
        bsdf.inputs["Subsurface Weight"].default_value = 0.1 * (1 - decay)
        
        # Mix color with noise for variation
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-200, 0)
        noise.inputs["Scale"].default_value = 8.0
        noise.inputs["Detail"].default_value = 4.0
        
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (0, 0)
        ramp.color_ramp.elements[0].color = (*base_color, 1.0)
        # Darker variation
        darker = tuple(c * 0.7 for c in base_color)
        ramp.color_ramp.elements[1].color = (*darker, 1.0)
        ramp.color_ramp.elements[0].position = 0.4
        ramp.color_ramp.elements[1].position = 0.6
        
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_tattered_cloth_material(self, name: str, color: tuple):
        """Create tattered clothing material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (400, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (200, 0)
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.85
        
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_gore_material(self, name: str):
        """Create blood/gore material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (400, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (200, 0)
        bsdf.inputs["Base Color"].default_value = (0.4, 0.05, 0.02, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.3
        bsdf.inputs["Subsurface Weight"].default_value = 0.2
        
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_standard_body(self, size: float, skin_mat, cloth_mat, gore_mat, posture: str):
        """Create standard humanoid zombie body."""
        parts = []
        
        # Posture adjustments
        if posture == "hunched":
            torso_tilt = 15
            head_forward = 0.08
        elif posture == "athletic":
            torso_tilt = 5
            head_forward = 0.02
        else:
            torso_tilt = 10
            head_forward = 0.05
        
        # Torso
        bpy.ops.mesh.primitive_cube_add(size=0.4 * size, location=(0, 0, 1.0 * size))
        torso = bpy.context.active_object
        torso.scale = (0.9, 0.5, 1.1)
        torso.rotation_euler.x = math.radians(torso_tilt)
        torso.data.materials.append(cloth_mat)
        parts.append(torso)
        
        # Ribs detail (visible through torn clothing)
        for i in range(3):
            y_pos = 0.08 * (i - 1)
            bpy.ops.mesh.primitive_cube_add(
                size=0.05 * size,
                location=(0.18 * size, y_pos * size, (0.95 + i * 0.08) * size)
            )
            rib = bpy.context.active_object
            rib.scale = (0.2, 2.0, 0.5)
            rib.data.materials.append(skin_mat)
            parts.append(rib)
        
        # Head
        bpy.ops.mesh.primitive_cube_add(
            size=0.25 * size, 
            location=(head_forward * size, 0, 1.45 * size)
        )
        head = bpy.context.active_object
        head.scale = (0.85, 0.8, 1.0)
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        # Jaw (slightly open)
        bpy.ops.mesh.primitive_cube_add(
            size=0.08 * size,
            location=((head_forward + 0.08) * size, 0, 1.35 * size)
        )
        jaw = bpy.context.active_object
        jaw.scale = (0.8, 0.9, 0.4)
        jaw.rotation_euler.x = math.radians(15)  # Mouth open
        jaw.data.materials.append(skin_mat)
        parts.append(jaw)
        
        # Eyes (sunken)
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_uv_sphere_add(
                radius=0.02 * size,
                location=((head_forward + 0.1) * size, side * 0.05 * size, 1.48 * size)
            )
            eye = bpy.context.active_object
            eye.scale.x = 0.5  # Sunken
            eye.data.materials.append(gore_mat)  # Bloodshot
            parts.append(eye)
        
        # Neck
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=0.055 * size,
            depth=0.12 * size,
            location=(head_forward * 0.5 * size, 0, 1.28 * size)
        )
        neck = bpy.context.active_object
        neck.data.materials.append(skin_mat)
        parts.append(neck)
        
        # Hips
        bpy.ops.mesh.primitive_cube_add(size=0.35 * size, location=(0, 0, 0.7 * size))
        hips = bpy.context.active_object
        hips.scale = (0.85, 0.5, 0.4)
        hips.data.materials.append(cloth_mat)
        parts.append(hips)
        
        # Legs
        for side in [-1, 1]:
            # Upper leg
            bpy.ops.mesh.primitive_cube_add(
                size=0.11 * size,
                location=(0, side * 0.1 * size, 0.45 * size)
            )
            upper_leg = bpy.context.active_object
            upper_leg.scale.z = 2.5
            upper_leg.data.materials.append(cloth_mat)
            parts.append(upper_leg)
            
            # Lower leg
            bpy.ops.mesh.primitive_cube_add(
                size=0.09 * size,
                location=(0, side * 0.1 * size, 0.18 * size)
            )
            lower_leg = bpy.context.active_object
            lower_leg.scale.z = 2.0
            lower_leg.data.materials.append(cloth_mat)
            parts.append(lower_leg)
            
            # Foot
            bpy.ops.mesh.primitive_cube_add(
                size=0.07 * size,
                location=(0.02 * size, side * 0.1 * size, 0.04 * size)
            )
            foot = bpy.context.active_object
            foot.scale = (1.5, 1.0, 0.5)
            foot.data.materials.append(skin_mat)
            parts.append(foot)
        
        # Arms
        for side in [-1, 1]:
            arm_angle = random.uniform(-0.2, 0.4)  # Random arm position
            
            # Shoulder
            bpy.ops.mesh.primitive_cube_add(
                size=0.1 * size,
                location=(0, side * 0.25 * size, 1.12 * size)
            )
            shoulder = bpy.context.active_object
            shoulder.data.materials.append(cloth_mat)
            parts.append(shoulder)
            
            # Upper arm
            bpy.ops.mesh.primitive_cube_add(
                size=0.075 * size,
                location=(0, side * 0.30 * size, 0.92 * size)
            )
            upper_arm = bpy.context.active_object
            upper_arm.scale.z = 2.2
            upper_arm.rotation_euler.x = arm_angle
            upper_arm.data.materials.append(skin_mat)
            parts.append(upper_arm)
            
            # Lower arm
            bpy.ops.mesh.primitive_cube_add(
                size=0.065 * size,
                location=(0, side * 0.30 * size, 0.68 * size)
            )
            lower_arm = bpy.context.active_object
            lower_arm.scale.z = 1.8
            lower_arm.data.materials.append(skin_mat)
            parts.append(lower_arm)
            
            # Hand (claw-like)
            bpy.ops.mesh.primitive_cube_add(
                size=0.05 * size,
                location=(0, side * 0.30 * size, 0.54 * size)
            )
            hand = bpy.context.active_object
            hand.scale = (0.7, 1.3, 0.4)
            hand.data.materials.append(skin_mat)
            parts.append(hand)
            
            # Fingers
            for f in range(3):
                finger_offset = (f - 1) * 0.02 * size
                bpy.ops.mesh.primitive_cube_add(
                    size=0.012 * size,
                    location=(0.02 * size, side * 0.30 * size + finger_offset, 0.48 * size)
                )
                finger = bpy.context.active_object
                finger.scale.z = 2.5
                finger.data.materials.append(skin_mat)
                parts.append(finger)
        
        return parts
    
    def _create_crawling_body(self, size: float, skin_mat, cloth_mat, gore_mat):
        """Create crawler zombie (missing legs, drags itself)."""
        parts = []
        
        # Torso (horizontal)
        bpy.ops.mesh.primitive_cube_add(size=0.4 * size, location=(0, 0, 0.2 * size))
        torso = bpy.context.active_object
        torso.scale = (1.1, 0.5, 0.7)
        torso.rotation_euler.x = math.radians(75)
        torso.data.materials.append(cloth_mat)
        parts.append(torso)
        
        # Head (looking up)
        bpy.ops.mesh.primitive_cube_add(size=0.2 * size, location=(0.35 * size, 0, 0.25 * size))
        head = bpy.context.active_object
        head.rotation_euler.x = math.radians(-20)
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        # Arms (reaching forward)
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.06 * size,
                location=(0.3 * size, side * 0.2 * size, 0.08 * size)
            )
            arm = bpy.context.active_object
            arm.scale = (4.0, 1.0, 1.0)
            arm.rotation_euler.y = math.radians(10 * side)
            arm.data.materials.append(skin_mat)
            parts.append(arm)
        
        # Trailing intestines
        for i in range(3):
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=4,
                radius=0.02 * size,
                depth=0.3 * size,
                location=(-0.1 * size, (i - 1) * 0.08 * size, 0.1 * size)
            )
            guts = bpy.context.active_object
            guts.rotation_euler.y = math.radians(90)
            guts.data.materials.append(gore_mat)
            parts.append(guts)
        
        return parts
    
    def _create_bloated_body(self, size: float, skin_mat, cloth_mat, gore_mat):
        """Create bloated zombie with distended features."""
        parts = []
        
        # Bloated torso
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=8,
            radius=0.35 * size,
            location=(0, 0, 0.9 * size)
        )
        torso = bpy.context.active_object
        torso.scale = (0.9, 0.8, 1.1)
        torso.data.materials.append(skin_mat)
        parts.append(torso)
        
        # Add boils/pustules
        for i in range(8):
            angle = random.uniform(0, 2 * math.pi)
            height = random.uniform(0.7, 1.1) * size
            dist = random.uniform(0.25, 0.35) * size
            
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=6, ring_count=4,
                radius=random.uniform(0.03, 0.08) * size,
                location=(
                    math.cos(angle) * dist,
                    math.sin(angle) * dist * 0.8,
                    height
                )
            )
            boil = bpy.context.active_object
            boil.data.materials.append(gore_mat)
            parts.append(boil)
        
        # Small head
        bpy.ops.mesh.primitive_cube_add(size=0.18 * size, location=(0, 0, 1.4 * size))
        head = bpy.context.active_object
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        # Stubby arms
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.1 * size,
                location=(0, side * 0.4 * size, 0.9 * size)
            )
            arm = bpy.context.active_object
            arm.scale = (0.8, 0.8, 2.0)
            arm.data.materials.append(skin_mat)
            parts.append(arm)
        
        # Short thick legs
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.12 * size,
                location=(0, side * 0.15 * size, 0.35 * size)
            )
            leg = bpy.context.active_object
            leg.scale = (1.0, 1.0, 2.5)
            leg.data.materials.append(cloth_mat)
            parts.append(leg)
        
        return parts
    
    def _create_hulking_body(self, size: float, skin_mat, cloth_mat, gore_mat):
        """Create hulking brute zombie with massive upper body."""
        parts = []
        
        # Massive torso
        bpy.ops.mesh.primitive_cube_add(size=0.5 * size, location=(0, 0, 1.0 * size))
        torso = bpy.context.active_object
        torso.scale = (1.1, 0.7, 1.3)
        torso.data.materials.append(cloth_mat)
        parts.append(torso)
        
        # Muscular shoulders
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=8, ring_count=6,
                radius=0.15 * size,
                location=(0, side * 0.35 * size, 1.25 * size)
            )
            shoulder = bpy.context.active_object
            shoulder.data.materials.append(skin_mat)
            parts.append(shoulder)
        
        # Small head
        bpy.ops.mesh.primitive_cube_add(size=0.22 * size, location=(0.05 * size, 0, 1.5 * size))
        head = bpy.context.active_object
        head.scale = (0.9, 0.85, 0.9)
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        # Massive arms
        for side in [-1, 1]:
            # Upper arm
            bpy.ops.mesh.primitive_cube_add(
                size=0.12 * size,
                location=(0, side * 0.45 * size, 0.85 * size)
            )
            upper_arm = bpy.context.active_object
            upper_arm.scale = (1.2, 1.2, 2.5)
            upper_arm.data.materials.append(skin_mat)
            parts.append(upper_arm)
            
            # Lower arm
            bpy.ops.mesh.primitive_cube_add(
                size=0.1 * size,
                location=(0, side * 0.5 * size, 0.55 * size)
            )
            lower_arm = bpy.context.active_object
            lower_arm.scale = (1.3, 1.3, 2.2)
            lower_arm.data.materials.append(skin_mat)
            parts.append(lower_arm)
            
            # Huge fist
            bpy.ops.mesh.primitive_cube_add(
                size=0.12 * size,
                location=(0, side * 0.5 * size, 0.3 * size)
            )
            fist = bpy.context.active_object
            fist.scale = (1.2, 1.5, 0.8)
            fist.data.materials.append(skin_mat)
            parts.append(fist)
        
        # Thick legs
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.12 * size,
                location=(0, side * 0.15 * size, 0.4 * size)
            )
            leg = bpy.context.active_object
            leg.scale = (1.0, 1.0, 3.0)
            leg.data.materials.append(cloth_mat)
            parts.append(leg)
        
        return parts
    
    def _add_wounds(self, size: float, gore_mat):
        """Add wound details to zombie."""
        parts = []
        
        for i in range(random.randint(2, 5)):
            angle = random.uniform(0, 2 * math.pi)
            height = random.uniform(0.5, 1.2) * size
            dist = random.uniform(0.15, 0.25) * size
            
            bpy.ops.mesh.primitive_cube_add(
                size=random.uniform(0.03, 0.08) * size,
                location=(
                    math.cos(angle) * dist,
                    math.sin(angle) * dist,
                    height
                )
            )
            wound = bpy.context.active_object
            wound.scale = (
                random.uniform(0.5, 1.5),
                random.uniform(0.5, 1.5),
                random.uniform(0.2, 0.5)
            )
            wound.data.materials.append(gore_mat)
            parts.append(wound)
        
        return parts


def generate_all_zombies():
    """Generate all zombie variants."""
    generator = ZombieGenerator()
    
    zombies = []
    zombie_types = list(ZombieGenerator.ZOMBIE_TYPES.keys())
    
    for i, ztype in enumerate(zombie_types):
        zombie = generator.generate(f"zombie_{ztype}", ztype)
        zombie.location.x = i * 2.5
        zombies.append(zombie)
    
    return zombies


if __name__ == "__main__":
    generate_all_zombies()
