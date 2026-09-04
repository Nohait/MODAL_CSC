"""
Detailed Zombie Generator - Creates horrifying zombie variants
with decay, wounds, tattered clothing, and distinctive features.
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector


class DetailedZombieGenerator:
    """Generate detailed zombie models with varying decay and horror elements."""
    
    ZOMBIE_TYPES = {
        "walker": {
            "speed": "slow",
            "height": 1.70,
            "posture": "shambling",
            "decay": 0.4,
            "clothing_damage": 0.6,
            "special_features": []
        },
        "runner": {
            "speed": "fast",
            "height": 1.68,
            "posture": "hunched_forward",
            "decay": 0.25,
            "clothing_damage": 0.4,
            "special_features": ["bloodshot_eyes"]
        },
        "crawler": {
            "speed": "slow",
            "height": 0.5,  # Measured from ground when crawling
            "posture": "crawling",
            "decay": 0.7,
            "clothing_damage": 0.9,
            "special_features": ["missing_legs", "drag_marks"]
        },
        "bloater": {
            "speed": "very_slow",
            "height": 1.60,
            "posture": "swollen",
            "decay": 0.8,
            "clothing_damage": 0.95,
            "special_features": ["bloated_belly", "pustules", "torn_skin"]
        },
        "screamer": {
            "speed": "medium",
            "height": 1.65,
            "posture": "head_back",
            "decay": 0.35,
            "clothing_damage": 0.5,
            "special_features": ["wide_mouth", "elongated_neck"]
        },
        "spitter": {
            "speed": "medium",
            "height": 1.72,
            "posture": "hunched",
            "decay": 0.55,
            "clothing_damage": 0.7,
            "special_features": ["swollen_cheeks", "dripping_mouth"]
        },
        "brute": {
            "speed": "slow",
            "height": 2.10,
            "posture": "hulking",
            "decay": 0.45,
            "clothing_damage": 0.8,
            "special_features": ["massive_arms", "armored_skin"]
        },
        "ravager": {
            "speed": "fast",
            "height": 2.30,
            "posture": "aggressive",
            "decay": 0.6,
            "clothing_damage": 0.85,
            "special_features": ["bone_spikes", "claws", "exposed_ribs"]
        }
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, zombie_type: str = "walker") -> bpy.types.Object:
        """Generate a detailed zombie of the specified type."""
        config = self.ZOMBIE_TYPES.get(zombie_type, self.ZOMBIE_TYPES["walker"])
        
        # Create materials based on decay level
        skin_mat = self._create_zombie_skin_material(f"mat_{name}_skin", config["decay"])
        cloth_mat = self._create_tattered_cloth_material(f"mat_{name}_cloth", config["clothing_damage"])
        gore_mat = self._create_gore_material(f"mat_{name}_gore")
        bone_mat = self._create_bone_material(f"mat_{name}_bone")
        
        parts = []
        height = config["height"]
        
        # Generate body based on posture
        if config["posture"] == "crawling":
            parts.extend(self._create_crawling_body(height, config, skin_mat, cloth_mat, gore_mat))
        elif config["posture"] == "swollen":
            parts.extend(self._create_bloated_body(height, config, skin_mat, cloth_mat, gore_mat))
        elif config["posture"] == "hulking":
            parts.extend(self._create_hulking_body(height, config, skin_mat, cloth_mat, gore_mat, bone_mat))
        elif config["posture"] == "aggressive":
            parts.extend(self._create_ravager_body(height, config, skin_mat, cloth_mat, gore_mat, bone_mat))
        else:
            parts.extend(self._create_standard_body(height, config, skin_mat, cloth_mat, gore_mat))
        
        # Add special features
        for feature in config["special_features"]:
            feature_parts = self._add_special_feature(feature, height, config, gore_mat, bone_mat)
            parts.extend(feature_parts)
        
        # Add wounds and decay details
        wound_parts = self._add_wounds(height, config["decay"], gore_mat)
        parts.extend(wound_parts)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            if part is not None:
                part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        zombie = bpy.context.active_object
        zombie.name = name
        
        # Apply shading
        self._apply_horror_shading(zombie)
        
        # Set origin to bottom
        self._set_origin_to_bottom(zombie)
        
        return zombie
    
    def _create_standard_body(self, height: float, config: dict, skin_mat, cloth_mat, gore_mat) -> list:
        """Create standard zombie body with shambling posture."""
        parts = []
        decay = config["decay"]
        posture = config["posture"]
        
        # Posture modifiers
        lean_forward = 0.1 if posture == "shambling" else 0.2 if posture == "hunched" else 0.05
        
        # === FEET ===
        for side in [-1, 1]:
            foot = self._create_zombie_foot(height, decay)
            foot.location = (lean_forward * height * 0.5, side * 0.09 * height, 0)
            foot.rotation_euler.x = random.uniform(-0.1, 0.1)
            foot.data.materials.append(cloth_mat if random.random() > decay else skin_mat)
            parts.append(foot)
        
        # === LEGS ===
        leg_base = 0.03 * height
        for side in [-1, 1]:
            # Lower leg - possibly damaged
            lower_leg = self._create_zombie_leg_lower(height, decay)
            lower_leg.location = (lean_forward * height * 0.3, side * 0.1 * height, leg_base + 0.18 * height)
            lower_leg.rotation_euler = (random.uniform(-0.15, 0.05), side * random.uniform(0, 0.1), 0)
            lower_leg.data.materials.append(cloth_mat)
            parts.append(lower_leg)
            
            # Upper leg
            upper_leg = self._create_zombie_leg_upper(height, decay)
            upper_leg.location = (lean_forward * height * 0.15, side * 0.095 * height, leg_base + 0.40 * height)
            upper_leg.rotation_euler.x = random.uniform(-0.1, 0.1)
            upper_leg.data.materials.append(cloth_mat)
            parts.append(upper_leg)
        
        # === PELVIS ===
        pelvis = self._create_pelvis(height, decay)
        pelvis.location = (lean_forward * height * 0.08, 0, leg_base + 0.52 * height)
        pelvis.data.materials.append(cloth_mat)
        parts.append(pelvis)
        
        # === TORSO ===
        torso = self._create_zombie_torso(height, decay, config["clothing_damage"])
        torso.location = (lean_forward * height * -0.05, 0, leg_base + 0.70 * height)
        torso.rotation_euler.x = lean_forward
        torso.data.materials.append(cloth_mat)
        parts.append(torso)
        
        # === ARMS ===
        arm_base_z = leg_base + 0.80 * height
        for side in [-1, 1]:
            arm_hang = random.uniform(0.2, 0.6)  # How limp the arm is
            
            # Shoulder
            shoulder = self._create_shoulder(height, decay)
            shoulder.location = (0, side * 0.18 * height, arm_base_z)
            shoulder.data.materials.append(cloth_mat)
            parts.append(shoulder)
            
            # Upper arm
            upper_arm = self._create_zombie_arm_upper(height, decay)
            upper_arm.location = (0.02 * height, side * 0.22 * height, arm_base_z - 0.08 * height)
            upper_arm.rotation_euler = (arm_hang, side * 0.15, 0)
            upper_arm.data.materials.append(cloth_mat if random.random() > 0.5 else skin_mat)
            parts.append(upper_arm)
            
            # Lower arm
            lower_arm = self._create_zombie_arm_lower(height, decay)
            lower_arm.location = (0.05 * height, side * 0.26 * height, arm_base_z - 0.20 * height)
            lower_arm.rotation_euler = (arm_hang * 1.5, side * 0.2, 0)
            lower_arm.data.materials.append(skin_mat)
            parts.append(lower_arm)
            
            # Hand - possibly clawed
            hand = self._create_zombie_hand(height, decay)
            hand.location = (0.08 * height, side * 0.28 * height, arm_base_z - 0.30 * height)
            hand.rotation_euler = (arm_hang * 0.5 + random.uniform(-0.3, 0.3), 0, side * random.uniform(-0.2, 0.2))
            hand.data.materials.append(skin_mat)
            parts.append(hand)
        
        # === NECK ===
        neck = self._create_zombie_neck(height, decay)
        neck.location = (lean_forward * height * -0.12, random.uniform(-0.01, 0.01) * height, leg_base + 0.90 * height)
        neck.rotation_euler = (lean_forward * 0.5, random.uniform(-0.15, 0.15), 0)
        neck.data.materials.append(skin_mat)
        parts.append(neck)
        
        # === HEAD ===
        head = self._create_zombie_head(height, decay, posture)
        head.location = (lean_forward * height * -0.15, random.uniform(-0.02, 0.02) * height, leg_base + 0.96 * height)
        head.rotation_euler = (lean_forward * -0.3 + random.uniform(-0.2, 0.1), random.uniform(-0.2, 0.2), random.uniform(-0.1, 0.1))
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        return parts
    
    def _create_crawling_body(self, height: float, config: dict, skin_mat, cloth_mat, gore_mat) -> list:
        """Create a crawler zombie - torso only, dragging itself."""
        parts = []
        decay = config["decay"]
        
        # Torso - elongated, dragging on ground
        torso = self._create_zombie_torso(height * 1.5, decay, 0.95)
        torso.location = (0, 0, 0.15)
        torso.rotation_euler = (math.radians(80), 0, 0)  # Nearly flat
        torso.scale.z = 0.7
        bpy.ops.object.transform_apply(scale=True)
        torso.data.materials.append(cloth_mat)
        parts.append(torso)
        
        # Arms reaching forward
        for side in [-1, 1]:
            upper_arm = self._create_zombie_arm_upper(height, decay)
            upper_arm.location = (0.3, side * 0.15, 0.18)
            upper_arm.rotation_euler = (math.radians(-70), side * 0.3, 0)
            upper_arm.data.materials.append(skin_mat)
            parts.append(upper_arm)
            
            lower_arm = self._create_zombie_arm_lower(height, decay)
            lower_arm.location = (0.5, side * 0.18, 0.12)
            lower_arm.rotation_euler = (math.radians(-85), side * 0.2, 0)
            lower_arm.data.materials.append(skin_mat)
            parts.append(lower_arm)
            
            hand = self._create_zombie_hand(height, decay, clawed=True)
            hand.location = (0.65, side * 0.2, 0.05)
            hand.rotation_euler = (math.radians(-90), 0, side * 0.3)
            hand.data.materials.append(skin_mat)
            parts.append(hand)
        
        # Head looking up/forward
        head = self._create_zombie_head(height, decay, "aggressive")
        head.location = (0.25, 0, 0.28)
        head.rotation_euler = (math.radians(20), random.uniform(-0.2, 0.2), 0)
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        # Gore trail / entrails where legs would be
        for i in range(3):
            gore = self._create_gore_chunk(height * 0.08)
            gore.location = (-0.2 - i * 0.15, random.uniform(-0.1, 0.1), 0.05)
            gore.data.materials.append(gore_mat)
            parts.append(gore)
        
        return parts
    
    def _create_bloated_body(self, height: float, config: dict, skin_mat, cloth_mat, gore_mat) -> list:
        """Create a bloated zombie with swollen features."""
        parts = []
        decay = config["decay"]
        
        # Massive swollen belly
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=height * 0.35)
        belly = bpy.context.active_object
        belly.scale = (1.2, 1.1, 1.0)
        belly.location = (0.05, 0, height * 0.45)
        bpy.ops.object.transform_apply(scale=True)
        
        # Add pustules
        self._add_pustules(belly, 12, height * 0.04)
        belly.data.materials.append(skin_mat)
        parts.append(belly)
        
        # Small legs (barely supporting weight)
        for side in [-1, 1]:
            leg = self._create_zombie_leg_lower(height * 0.8, decay)
            leg.location = (0, side * 0.2, height * 0.12)
            leg.scale = (1.3, 1.3, 0.8)
            bpy.ops.object.transform_apply(scale=True)
            leg.data.materials.append(cloth_mat)
            parts.append(leg)
        
        # Swollen arms
        for side in [-1, 1]:
            arm = self._create_zombie_arm_upper(height, decay)
            arm.location = (0, side * 0.35, height * 0.55)
            arm.scale = (1.4, 1.4, 0.9)
            arm.rotation_euler = (0.3, side * 0.4, 0)
            bpy.ops.object.transform_apply(scale=True)
            arm.data.materials.append(skin_mat)
            parts.append(arm)
        
        # Swollen head
        head = self._create_zombie_head(height, decay, "bloated")
        head.scale = (1.3, 1.2, 1.1)
        head.location = (0, 0, height * 0.75)
        bpy.ops.object.transform_apply(scale=True)
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        return parts
    
    def _create_hulking_body(self, height: float, config: dict, skin_mat, cloth_mat, gore_mat, bone_mat) -> list:
        """Create a brute zombie - massive and muscular."""
        parts = []
        decay = config["decay"]
        
        # Massive torso
        bpy.ops.mesh.primitive_cube_add(size=1)
        torso = bpy.context.active_object
        torso.scale = (height * 0.25, height * 0.35, height * 0.35)
        torso.location = (0, 0, height * 0.50)
        bpy.ops.object.transform_apply(scale=True)
        
        # Deform for muscular look
        bm = bmesh.new()
        bm.from_mesh(torso.data)
        for v in bm.verts:
            if v.co.x > 0:  # Puff out chest
                v.co.x += height * 0.05
            if v.co.z > 0:  # Wider shoulders
                v.co.y *= 1.15
        bm.to_mesh(torso.data)
        bm.free()
        torso.data.materials.append(skin_mat)
        parts.append(torso)
        
        # Thick legs
        for side in [-1, 1]:
            leg = self._create_zombie_leg_upper(height, decay)
            leg.scale = (1.8, 1.8, 1.0)
            leg.location = (0, side * 0.15, height * 0.22)
            bpy.ops.object.transform_apply(scale=True)
            leg.data.materials.append(cloth_mat)
            parts.append(leg)
        
        # Massive arms
        for side in [-1, 1]:
            # Upper arm - huge
            upper = self._create_zombie_arm_upper(height, decay)
            upper.scale = (2.2, 2.2, 1.2)
            upper.location = (0, side * 0.38, height * 0.58)
            upper.rotation_euler = (0.4, side * 0.3, 0)
            bpy.ops.object.transform_apply(scale=True)
            upper.data.materials.append(skin_mat)
            parts.append(upper)
            
            # Forearm
            lower = self._create_zombie_arm_lower(height, decay)
            lower.scale = (2.0, 2.0, 1.3)
            lower.location = (0.1, side * 0.45, height * 0.38)
            lower.rotation_euler = (0.8, side * 0.2, 0)
            bpy.ops.object.transform_apply(scale=True)
            lower.data.materials.append(skin_mat)
            parts.append(lower)
            
            # Massive fists
            fist = self._create_zombie_hand(height * 1.5, decay)
            fist.scale = (1.8, 1.8, 1.8)
            fist.location = (0.15, side * 0.48, height * 0.18)
            bpy.ops.object.transform_apply(scale=True)
            fist.data.materials.append(skin_mat)
            parts.append(fist)
        
        # Small head (emphasizes body mass)
        head = self._create_zombie_head(height * 0.8, decay, "aggressive")
        head.location = (-0.05, 0, height * 0.78)
        head.rotation_euler.x = 0.3  # Looking down
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        # Shoulder armor/bone plates
        for side in [-1, 1]:
            plate = self._create_bone_plate(height * 0.12)
            plate.location = (0, side * 0.32, height * 0.72)
            plate.rotation_euler.y = side * 0.4
            plate.data.materials.append(bone_mat)
            parts.append(plate)
        
        return parts
    
    def _create_ravager_body(self, height: float, config: dict, skin_mat, cloth_mat, gore_mat, bone_mat) -> list:
        """Create a ravager - tall, fast, with bone mutations."""
        parts = self._create_hulking_body(height, config, skin_mat, cloth_mat, gore_mat, bone_mat)
        
        # Add bone spikes along spine
        for i in range(5):
            spike = self._create_bone_spike(height * 0.08 * (1 - i * 0.15))
            spike.location = (-0.1, 0, height * 0.45 + i * 0.08)
            spike.rotation_euler.x = -0.5
            spike.data.materials.append(bone_mat)
            parts.append(spike)
        
        # Claws on hands (already added)
        for side in [-1, 1]:
            for finger in range(3):
                claw = self._create_bone_spike(height * 0.06)
                claw.location = (0.25, side * (0.45 + finger * 0.03), height * 0.12)
                claw.rotation_euler = (1.2, side * 0.2, finger * 0.15)
                claw.data.materials.append(bone_mat)
                parts.append(claw)
        
        # Exposed ribs
        for i in range(4):
            rib = self._create_exposed_rib(height * 0.15)
            rib.location = (0.15, 0, height * 0.45 + i * 0.06)
            rib.rotation_euler.z = math.radians(90)
            rib.data.materials.append(bone_mat)
            parts.append(rib)
        
        return parts
    
    # === BODY PART CREATION METHODS ===
    
    def _create_zombie_foot(self, height: float, decay: float) -> bpy.types.Object:
        """Create zombie foot - possibly bare and decayed."""
        h = height * 0.04
        bpy.ops.mesh.primitive_cube_add(size=1)
        foot = bpy.context.active_object
        foot.scale = (h * 2.5, h * 0.8, h)
        bpy.ops.object.transform_apply(scale=True)
        
        # Rough up the edges
        if decay > 0.5:
            self._add_decay_damage(foot, decay * 0.3)
        
        return foot
    
    def _create_zombie_leg_lower(self, height: float, decay: float) -> bpy.types.Object:
        """Create zombie lower leg with muscle definition."""
        h = height * 0.18
        r = height * 0.032
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=r, depth=h)
        leg = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(leg.data)
        for v in bm.verts:
            # Taper toward ankle
            if v.co.z < 0:
                v.co.x *= 0.65
                v.co.y *= 0.65
            # Calf muscle
            if v.co.z > h * 0.1 and v.co.z < h * 0.4:
                if v.co.y < 0:
                    v.co.y -= r * 0.35
        bm.to_mesh(leg.data)
        bm.free()
        
        if decay > 0.6:
            self._add_decay_damage(leg, decay * 0.2)
        
        return leg
    
    def _create_zombie_leg_upper(self, height: float, decay: float) -> bpy.types.Object:
        """Create zombie upper leg / thigh."""
        h = height * 0.20
        r = height * 0.045
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=r, depth=h)
        leg = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(leg.data)
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= 0.7
                v.co.y *= 0.7
        bm.to_mesh(leg.data)
        bm.free()
        
        return leg
    
    def _create_pelvis(self, height: float, decay: float) -> bpy.types.Object:
        """Create pelvis area."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        pelvis = bpy.context.active_object
        pelvis.scale = (height * 0.08, height * 0.16, height * 0.08)
        bpy.ops.object.transform_apply(scale=True)
        return pelvis
    
    def _create_zombie_torso(self, height: float, decay: float, clothing_damage: float) -> bpy.types.Object:
        """Create zombie torso with decay and damage."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        torso = bpy.context.active_object
        torso.scale = (height * 0.12, height * 0.22, height * 0.25)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(torso.data)
        
        # Narrow waist, wider chest/shoulders
        for v in bm.verts:
            if v.co.z < 0:
                v.co.y *= 0.8
            if v.co.z > height * 0.08:
                v.co.y *= 1.1
            # Hollow stomach if decayed
            if decay > 0.5 and v.co.z > -height * 0.05 and v.co.z < height * 0.05:
                if v.co.x > 0:
                    v.co.x -= height * 0.02 * decay
        
        bm.to_mesh(torso.data)
        bm.free()
        
        if clothing_damage > 0.7:
            self._add_decay_damage(torso, clothing_damage * 0.15)
        
        return torso
    
    def _create_shoulder(self, height: float, decay: float) -> bpy.types.Object:
        """Create shoulder joint."""
        r = height * 0.035
        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=5, radius=r)
        shoulder = bpy.context.active_object
        return shoulder
    
    def _create_zombie_arm_upper(self, height: float, decay: float) -> bpy.types.Object:
        """Create upper arm with emaciated look."""
        h = height * 0.14
        r = height * 0.028
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=h)
        arm = bpy.context.active_object
        
        # Make it look more muscular/bony
        bm = bmesh.new()
        bm.from_mesh(arm.data)
        for v in bm.verts:
            # Bicep area
            if v.co.z > 0 and v.co.x > 0:
                v.co.x += r * 0.25
        bm.to_mesh(arm.data)
        bm.free()
        
        return arm
    
    def _create_zombie_arm_lower(self, height: float, decay: float) -> bpy.types.Object:
        """Create forearm - thinner and bonier."""
        h = height * 0.12
        r = height * 0.022
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=h)
        arm = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(arm.data)
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= 0.6
                v.co.y *= 0.6
        bm.to_mesh(arm.data)
        bm.free()
        
        return arm
    
    def _create_zombie_hand(self, height: float, decay: float, clawed: bool = False) -> bpy.types.Object:
        """Create zombie hand - clawed and bony."""
        h = height * 0.05
        
        # Palm
        bpy.ops.mesh.primitive_cube_add(size=1)
        hand = bpy.context.active_object
        hand.scale = (h * 0.5, h * 0.9, h * 0.3)
        bpy.ops.object.transform_apply(scale=True)
        
        # Fingers
        for i in range(4):
            finger_len = h * (0.6 if not clawed else 0.8)
            bpy.ops.mesh.primitive_cylinder_add(vertices=4, radius=h * 0.06, depth=finger_len)
            finger = bpy.context.active_object
            finger.location = (0, -h * 0.35 + i * h * 0.22, -h * 0.15 - finger_len * 0.5)
            finger.rotation_euler.x = random.uniform(-0.3, 0.1)
            
            if clawed:
                # Add claw tip
                bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=h * 0.04, radius2=0, depth=h * 0.15)
                claw = bpy.context.active_object
                claw.location = (0, finger.location.y, finger.location.z - finger_len * 0.5 - h * 0.08)
                claw.rotation_euler.x = -0.2
                finger.select_set(True)
                claw.select_set(True)
                bpy.context.view_layer.objects.active = finger
                bpy.ops.object.join()
                finger = bpy.context.active_object
            
            hand.select_set(True)
            finger.select_set(True)
            bpy.context.view_layer.objects.active = hand
            bpy.ops.object.join()
            hand = bpy.context.active_object
            bpy.ops.object.select_all(action='DESELECT')
        
        return hand
    
    def _create_zombie_neck(self, height: float, decay: float) -> bpy.types.Object:
        """Create zombie neck - possibly elongated or twisted."""
        h = height * 0.06
        r = height * 0.028
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=h)
        neck = bpy.context.active_object
        
        return neck
    
    def _create_zombie_head(self, height: float, decay: float, expression: str = "neutral") -> bpy.types.Object:
        """Create detailed zombie head with facial features."""
        h = height * 0.12
        
        # Skull shape
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=h * 0.55)
        head = bpy.context.active_object
        head.scale = (1.1, 0.85, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(head.data)
        
        for v in bm.verts:
            # Sunken cheeks
            if abs(v.co.y) > h * 0.2 and v.co.z < h * 0.1 and v.co.z > -h * 0.2:
                v.co.x -= h * 0.08 * decay
            # Protruding brow
            if v.co.z > h * 0.15 and v.co.z < h * 0.3 and v.co.x > h * 0.25:
                v.co.x += h * 0.05
            # Jaw
            if v.co.z < -h * 0.2:
                v.co.y *= 0.8
                if expression == "aggressive":
                    v.co.z -= h * 0.05  # Dropped jaw
        
        bm.to_mesh(head.data)
        bm.free()
        
        # Add eye sockets (indentations)
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=h * 0.08)
            eye_socket = bpy.context.active_object
            eye_socket.location = (h * 0.35, side * h * 0.2, h * 0.08)
            eye_socket.scale = (1.2, 1.0, 0.8)
            bpy.ops.object.transform_apply(scale=True)
            
            head.select_set(True)
            eye_socket.select_set(True)
            bpy.context.view_layer.objects.active = head
            
            # Boolean difference would be better but is slow - just join for now
            bpy.ops.object.join()
            head = bpy.context.active_object
            bpy.ops.object.select_all(action='DESELECT')
        
        if decay > 0.5:
            self._add_decay_damage(head, decay * 0.2)
        
        return head
    
    # === SPECIAL FEATURES ===
    
    def _add_special_feature(self, feature: str, height: float, config: dict, gore_mat, bone_mat) -> list:
        """Add special zombie features."""
        parts = []
        
        if feature == "pustules":
            # Add to existing body - handled in bloated creation
            pass
        elif feature == "bone_spikes":
            # Add protruding bones
            for i in range(random.randint(2, 5)):
                spike = self._create_bone_spike(height * random.uniform(0.04, 0.08))
                spike.location = (
                    random.uniform(-0.1, 0.1),
                    random.uniform(-0.2, 0.2),
                    height * random.uniform(0.4, 0.8)
                )
                spike.rotation_euler = (random.uniform(-0.5, 0.5), random.uniform(-0.3, 0.3), 0)
                spike.data.materials.append(bone_mat)
                parts.append(spike)
        
        return parts
    
    def _add_pustules(self, obj: bpy.types.Object, count: int, size: float) -> None:
        """Add pustule bumps to a mesh."""
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bm.verts.ensure_lookup_table()
        
        for _ in range(count):
            if len(bm.verts) > 0:
                v = random.choice(bm.verts)
                # Push vertex outward
                v.co += v.normal * size * random.uniform(0.5, 1.5)
        
        bm.to_mesh(obj.data)
        bm.free()
    
    def _add_wounds(self, height: float, decay: float, gore_mat) -> list:
        """Add wound details to the zombie."""
        wounds = []
        wound_count = int(decay * 5)
        
        for _ in range(wound_count):
            wound = self._create_gore_chunk(height * random.uniform(0.02, 0.05))
            wound.location = (
                random.uniform(-0.1, 0.1),
                random.uniform(-0.15, 0.15),
                height * random.uniform(0.3, 0.8)
            )
            wound.data.materials.append(gore_mat)
            wounds.append(wound)
        
        return wounds
    
    def _create_gore_chunk(self, size: float) -> bpy.types.Object:
        """Create a small gore/wound detail."""
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=size)
        gore = bpy.context.active_object
        
        # Deform randomly
        bm = bmesh.new()
        bm.from_mesh(gore.data)
        for v in bm.verts:
            v.co.x += random.uniform(-size * 0.3, size * 0.3)
            v.co.y += random.uniform(-size * 0.3, size * 0.3)
            v.co.z += random.uniform(-size * 0.3, size * 0.3)
        bm.to_mesh(gore.data)
        bm.free()
        
        return gore
    
    def _create_bone_spike(self, length: float) -> bpy.types.Object:
        """Create a protruding bone spike."""
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=length * 0.2, radius2=0, depth=length)
        spike = bpy.context.active_object
        return spike
    
    def _create_bone_plate(self, size: float) -> bpy.types.Object:
        """Create a bone armor plate."""
        bpy.ops.mesh.primitive_cube_add(size=size)
        plate = bpy.context.active_object
        plate.scale = (0.3, 1.0, 0.8)
        bpy.ops.object.transform_apply(scale=True)
        
        # Round edges
        bpy.ops.object.modifier_add(type='BEVEL')
        plate.modifiers["Bevel"].width = size * 0.1
        plate.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return plate
    
    def _create_exposed_rib(self, width: float) -> bpy.types.Object:
        """Create an exposed rib bone."""
        bpy.ops.mesh.primitive_torus_add(
            major_radius=width * 0.5,
            minor_radius=width * 0.08,
            major_segments=12,
            minor_segments=6
        )
        rib = bpy.context.active_object
        rib.scale.y = 0.4  # Flatten into rib shape
        bpy.ops.object.transform_apply(scale=True)
        
        # Cut in half
        bm = bmesh.new()
        bm.from_mesh(rib.data)
        verts_to_delete = [v for v in bm.verts if v.co.x < 0]
        bmesh.ops.delete(bm, geom=verts_to_delete, context='VERTS')
        bm.to_mesh(rib.data)
        bm.free()
        
        return rib
    
    def _add_decay_damage(self, obj: bpy.types.Object, intensity: float) -> None:
        """Add decay damage to mesh vertices."""
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        for v in bm.verts:
            if random.random() < intensity:
                v.co += Vector((
                    random.uniform(-0.02, 0.02),
                    random.uniform(-0.02, 0.02),
                    random.uniform(-0.02, 0.02)
                ))
        
        bm.to_mesh(obj.data)
        bm.free()
    
    # === MATERIALS ===
    
    def _create_zombie_skin_material(self, name: str, decay: float) -> bpy.types.Material:
        """Create decayed zombie skin material."""
        # Color ranges from pale flesh to green-grey based on decay
        base = (0.75, 0.68, 0.60)
        decayed = (0.42, 0.50, 0.38)
        
        color = tuple(base[i] * (1 - decay) + decayed[i] * decay for i in range(3))
        
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (600, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (200, 0)
        bsdf.inputs["Roughness"].default_value = 0.75
        bsdf.inputs["Subsurface Weight"].default_value = 0.05
        
        # Add mottled skin texture
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-400, 0)
        noise.inputs["Scale"].default_value = 8.0
        noise.inputs["Detail"].default_value = 4.0
        
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (-100, 0)
        ramp.color_ramp.elements[0].position = 0.3
        ramp.color_ramp.elements[0].color = (*color, 1.0)
        ramp.color_ramp.elements[1].position = 0.7
        ramp.color_ramp.elements[1].color = (color[0] * 0.7, color[1] * 0.8, color[2] * 0.6, 1.0)
        
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_tattered_cloth_material(self, name: str, damage: float) -> bpy.types.Material:
        """Create tattered, dirty clothing material."""
        base_color = (0.15, 0.12, 0.10)  # Dark, dirty
        
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (400, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (0, 0)
        bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.9
        
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_gore_material(self, name: str) -> bpy.types.Material:
        """Create blood/gore material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (400, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (0, 0)
        bsdf.inputs["Base Color"].default_value = (0.35, 0.02, 0.01, 1.0)  # Dark red
        bsdf.inputs["Roughness"].default_value = 0.3
        bsdf.inputs["Subsurface Weight"].default_value = 0.2
        
        mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_bone_material(self, name: str) -> bpy.types.Material:
        """Create bone material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (400, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (0, 0)
        bsdf.inputs["Base Color"].default_value = (0.85, 0.82, 0.75, 1.0)  # Off-white bone
        bsdf.inputs["Roughness"].default_value = 0.6
        
        mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _apply_horror_shading(self, obj: bpy.types.Object) -> None:
        """Apply shading that emphasizes the horror elements."""
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.shade_smooth()
        
        # Edge split for hard edges on wounds - compatible with Blender 3.x and 4.x
        try:
            bpy.ops.object.modifier_add(type='EDGE_SPLIT')
            for mod in obj.modifiers:
                if mod.type == 'EDGE_SPLIT':
                    mod.split_angle = math.radians(40)
                    bpy.ops.object.modifier_apply(modifier=mod.name)
                    break
        except Exception as e:
            print(f"Edge split modifier not available: {e}")
    
    def _set_origin_to_bottom(self, obj: bpy.types.Object) -> None:
        """Set origin to bottom center."""
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        
        mesh = obj.data
        min_z = min((obj.matrix_world @ v.co).z for v in mesh.vertices)
        
        bpy.context.scene.cursor.location = (0.0, 0.0, min_z)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        obj.location = (0.0, 0.0, 0.0)
        bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
