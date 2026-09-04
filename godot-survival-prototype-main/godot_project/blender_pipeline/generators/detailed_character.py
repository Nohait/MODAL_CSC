"""
Detailed Character Generator - Creates properly proportioned humanoid characters
with anatomical detail, clothing, and accessories for Godot Survival Prototype.
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector


class DetailedCharacterGenerator:
    """Generate detailed humanoid characters with proper anatomy and clothing."""
    
    # Character type configurations
    CHARACTER_TYPES = {
        "survivor_male": {
            "height": 1.75,
            "build": "athletic",
            "skin_tone": (0.76, 0.65, 0.55),
            "clothing": "tactical",
            "hair": "short"
        },
        "survivor_female": {
            "height": 1.65,
            "build": "athletic",
            "skin_tone": (0.78, 0.67, 0.57),
            "clothing": "tactical",
            "hair": "ponytail"
        },
        "npc_trader": {
            "height": 1.70,
            "build": "stocky",
            "skin_tone": (0.72, 0.60, 0.50),
            "clothing": "merchant",
            "hair": "bald"
        },
        "npc_mechanic": {
            "height": 1.80,
            "build": "muscular",
            "skin_tone": (0.65, 0.55, 0.45),
            "clothing": "workwear",
            "hair": "short"
        },
        "raider_scout": {
            "height": 1.72,
            "build": "lean",
            "skin_tone": (0.70, 0.58, 0.48),
            "clothing": "raider_light",
            "hair": "mohawk"
        },
        "raider_heavy": {
            "height": 1.85,
            "build": "muscular",
            "skin_tone": (0.68, 0.56, 0.46),
            "clothing": "raider_heavy",
            "hair": "bald"
        },
    }
    
    # Body proportions (relative to height)
    PROPORTIONS = {
        "head_height": 0.13,
        "neck_height": 0.03,
        "torso_height": 0.30,
        "pelvis_height": 0.08,
        "upper_leg": 0.22,
        "lower_leg": 0.20,
        "upper_arm": 0.14,
        "lower_arm": 0.12,
        "hand": 0.05,
        "foot": 0.04,
        "shoulder_width": 0.25,
        "hip_width": 0.18,
    }
    
    # Build modifiers
    BUILDS = {
        "lean": {"mass": 0.85, "muscle": 0.9},
        "athletic": {"mass": 1.0, "muscle": 1.1},
        "stocky": {"mass": 1.15, "muscle": 1.0},
        "muscular": {"mass": 1.2, "muscle": 1.3},
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, char_type: str = "survivor_male") -> bpy.types.Object:
        """Generate a detailed character of the specified type."""
        config = self.CHARACTER_TYPES.get(char_type, self.CHARACTER_TYPES["survivor_male"])
        build = self.BUILDS.get(config["build"], self.BUILDS["athletic"])
        
        height = config["height"]
        
        # Create materials
        skin_mat = self._create_skin_material(f"mat_{name}_skin", config["skin_tone"])
        cloth_mat = self._create_clothing_material(f"mat_{name}_cloth", config["clothing"])
        accent_mat = self._create_accent_material(f"mat_{name}_accent", config["clothing"])
        hair_mat = self._create_hair_material(f"mat_{name}_hair")
        
        parts = []
        
        # Build the body from bottom up
        y_pos = 0  # Current height position
        
        # === FEET ===
        for side in [-1, 1]:
            foot = self._create_foot(height, build)
            foot.location.x = side * self.PROPORTIONS["hip_width"] * height * 0.5
            foot.location.z = y_pos
            foot.data.materials.append(accent_mat)
            parts.append(foot)
        
        # === LOWER LEGS ===
        y_pos += self.PROPORTIONS["foot"] * height
        for side in [-1, 1]:
            lower_leg = self._create_lower_leg(height, build)
            lower_leg.location.x = side * self.PROPORTIONS["hip_width"] * height * 0.5
            lower_leg.location.z = y_pos + self.PROPORTIONS["lower_leg"] * height * 0.5
            lower_leg.data.materials.append(cloth_mat)
            parts.append(lower_leg)
        
        # === UPPER LEGS ===
        y_pos += self.PROPORTIONS["lower_leg"] * height
        for side in [-1, 1]:
            upper_leg = self._create_upper_leg(height, build)
            upper_leg.location.x = side * self.PROPORTIONS["hip_width"] * height * 0.45
            upper_leg.location.z = y_pos + self.PROPORTIONS["upper_leg"] * height * 0.5
            upper_leg.data.materials.append(cloth_mat)
            parts.append(upper_leg)
        
        # === PELVIS/HIPS ===
        y_pos += self.PROPORTIONS["upper_leg"] * height
        pelvis = self._create_pelvis(height, build)
        pelvis.location.z = y_pos + self.PROPORTIONS["pelvis_height"] * height * 0.5
        pelvis.data.materials.append(cloth_mat)
        parts.append(pelvis)
        
        # === TORSO ===
        y_pos += self.PROPORTIONS["pelvis_height"] * height
        torso = self._create_torso(height, build, config["clothing"])
        torso.location.z = y_pos + self.PROPORTIONS["torso_height"] * height * 0.5
        torso.data.materials.append(cloth_mat)
        parts.append(torso)
        
        # === SHOULDERS & ARMS ===
        shoulder_y = y_pos + self.PROPORTIONS["torso_height"] * height * 0.85
        for side in [-1, 1]:
            # Shoulder
            shoulder = self._create_shoulder(height, build)
            shoulder.location.x = side * self.PROPORTIONS["shoulder_width"] * height * 0.55
            shoulder.location.z = shoulder_y
            shoulder.data.materials.append(cloth_mat)
            parts.append(shoulder)
            
            # Upper arm
            upper_arm = self._create_upper_arm(height, build)
            upper_arm.location.x = side * self.PROPORTIONS["shoulder_width"] * height * 0.65
            upper_arm.location.z = shoulder_y - self.PROPORTIONS["upper_arm"] * height * 0.5
            upper_arm.data.materials.append(cloth_mat)
            parts.append(upper_arm)
            
            # Lower arm
            lower_arm = self._create_lower_arm(height, build)
            lower_arm.location.x = side * self.PROPORTIONS["shoulder_width"] * height * 0.65
            lower_arm.location.z = shoulder_y - self.PROPORTIONS["upper_arm"] * height - self.PROPORTIONS["lower_arm"] * height * 0.5
            lower_arm.data.materials.append(skin_mat)
            parts.append(lower_arm)
            
            # Hand
            hand = self._create_hand(height, build)
            hand.location.x = side * self.PROPORTIONS["shoulder_width"] * height * 0.65
            hand.location.z = shoulder_y - self.PROPORTIONS["upper_arm"] * height - self.PROPORTIONS["lower_arm"] * height
            hand.data.materials.append(skin_mat)
            parts.append(hand)
        
        # === NECK ===
        y_pos += self.PROPORTIONS["torso_height"] * height
        neck = self._create_neck(height, build)
        neck.location.z = y_pos + self.PROPORTIONS["neck_height"] * height * 0.5
        neck.data.materials.append(skin_mat)
        parts.append(neck)
        
        # === HEAD ===
        y_pos += self.PROPORTIONS["neck_height"] * height
        head = self._create_head(height, build)
        head.location.z = y_pos + self.PROPORTIONS["head_height"] * height * 0.5
        head.data.materials.append(skin_mat)
        parts.append(head)
        
        # === HAIR ===
        if config["hair"] != "bald":
            hair = self._create_hair(height, config["hair"])
            hair.location.z = y_pos + self.PROPORTIONS["head_height"] * height * 0.7
            hair.data.materials.append(hair_mat)
            parts.append(hair)
        
        # === EQUIPMENT/ACCESSORIES ===
        equipment = self._add_equipment(height, config["clothing"], cloth_mat, accent_mat)
        parts.extend(equipment)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        character = bpy.context.active_object
        character.name = name
        
        # Apply smooth shading with edge split for low-poly look
        self._apply_stylized_shading(character)
        
        # Set origin to bottom
        self._set_origin_to_bottom(character)
        
        return character
    
    def _create_foot(self, height: float, build: dict) -> bpy.types.Object:
        """Create a detailed foot."""
        h = self.PROPORTIONS["foot"] * height
        w = h * 0.6 * build["mass"]
        d = h * 2.0
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        foot = bpy.context.active_object
        foot.scale = (d, w, h)
        
        # Shape it - taper toward toes
        bm = bmesh.new()
        bm.from_mesh(foot.data)
        bmesh.ops.translate(bm, verts=[v for v in bm.verts if v.co.x > 0], vec=(0.1, 0, -0.1))
        bm.to_mesh(foot.data)
        bm.free()
        
        bpy.ops.object.transform_apply(scale=True)
        return foot
    
    def _create_lower_leg(self, height: float, build: dict) -> bpy.types.Object:
        """Create a detailed lower leg (calf)."""
        h = self.PROPORTIONS["lower_leg"] * height
        r = h * 0.18 * build["mass"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=h)
        leg = bpy.context.active_object
        
        # Taper toward ankle
        bm = bmesh.new()
        bm.from_mesh(leg.data)
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= 0.7
                v.co.y *= 0.7
        # Add calf muscle bulge
        for v in bm.verts:
            if v.co.z > h * 0.1 and v.co.z < h * 0.4 and v.co.y < 0:
                v.co.y -= r * 0.3 * build["muscle"]
        bm.to_mesh(leg.data)
        bm.free()
        
        return leg
    
    def _create_upper_leg(self, height: float, build: dict) -> bpy.types.Object:
        """Create a detailed upper leg (thigh)."""
        h = self.PROPORTIONS["upper_leg"] * height
        r = h * 0.22 * build["mass"] * build["muscle"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=h)
        leg = bpy.context.active_object
        
        # Taper toward knee
        bm = bmesh.new()
        bm.from_mesh(leg.data)
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= 0.75
                v.co.y *= 0.75
        bm.to_mesh(leg.data)
        bm.free()
        
        return leg
    
    def _create_pelvis(self, height: float, build: dict) -> bpy.types.Object:
        """Create pelvis/hip area."""
        h = self.PROPORTIONS["pelvis_height"] * height
        w = self.PROPORTIONS["hip_width"] * height * build["mass"]
        d = w * 0.6
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        pelvis = bpy.context.active_object
        pelvis.scale = (d, w, h)
        bpy.ops.object.transform_apply(scale=True)
        
        # Round the edges
        bpy.ops.object.modifier_add(type='BEVEL')
        pelvis.modifiers["Bevel"].width = 0.02
        pelvis.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        return pelvis
    
    def _create_torso(self, height: float, build: dict, clothing: str) -> bpy.types.Object:
        """Create detailed torso with chest and back."""
        h = self.PROPORTIONS["torso_height"] * height
        shoulder_w = self.PROPORTIONS["shoulder_width"] * height * build["mass"]
        waist_w = shoulder_w * 0.75
        d = shoulder_w * 0.45
        
        # Create basic torso shape
        bpy.ops.mesh.primitive_cube_add(size=1)
        torso = bpy.context.active_object
        torso.scale = (d, shoulder_w * 0.9, h)
        bpy.ops.object.transform_apply(scale=True)
        
        # Shape it - narrow waist, wider chest
        bm = bmesh.new()
        bm.from_mesh(torso.data)
        for v in bm.verts:
            # Taper waist
            if v.co.z < 0:
                factor = 0.75 + (v.co.z + h/2) / h * 0.25
                v.co.y *= factor
            # Puff out chest
            if v.co.z > h * 0.1 and v.co.x > 0:
                v.co.x += d * 0.15 * build["muscle"]
        bm.to_mesh(torso.data)
        bm.free()
        
        # Add clothing details
        if "tactical" in clothing:
            self._add_vest_detail(torso, h, shoulder_w)
        
        return torso
    
    def _add_vest_detail(self, torso: bpy.types.Object, h: float, w: float) -> None:
        """Add tactical vest pouches and details to torso."""
        bm = bmesh.new()
        bm.from_mesh(torso.data)
        
        # Extrude some faces for pockets
        front_faces = [f for f in bm.faces if f.normal.x > 0.5]
        if front_faces:
            for f in front_faces[:2]:
                result = bmesh.ops.extrude_face_region(bm, geom=[f])
                verts = [v for v in result['geom'] if isinstance(v, bmesh.types.BMVert)]
                bmesh.ops.translate(bm, verts=verts, vec=(0.02, 0, 0))
        
        bm.to_mesh(torso.data)
        bm.free()
    
    def _create_shoulder(self, height: float, build: dict) -> bpy.types.Object:
        """Create shoulder joint."""
        r = height * 0.035 * build["muscle"]
        
        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=4, radius=r)
        shoulder = bpy.context.active_object
        shoulder.scale.y = 1.2
        bpy.ops.object.transform_apply(scale=True)
        
        return shoulder
    
    def _create_upper_arm(self, height: float, build: dict) -> bpy.types.Object:
        """Create upper arm with bicep."""
        h = self.PROPORTIONS["upper_arm"] * height
        r = h * 0.22 * build["muscle"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=h)
        arm = bpy.context.active_object
        
        # Add bicep bulge
        bm = bmesh.new()
        bm.from_mesh(arm.data)
        for v in bm.verts:
            if v.co.z > 0 and v.co.x > 0:
                v.co.x += r * 0.2 * build["muscle"]
        bm.to_mesh(arm.data)
        bm.free()
        
        return arm
    
    def _create_lower_arm(self, height: float, build: dict) -> bpy.types.Object:
        """Create forearm."""
        h = self.PROPORTIONS["lower_arm"] * height
        r = h * 0.18 * build["mass"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=h)
        arm = bpy.context.active_object
        
        # Taper toward wrist
        bm = bmesh.new()
        bm.from_mesh(arm.data)
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= 0.7
                v.co.y *= 0.7
        bm.to_mesh(arm.data)
        bm.free()
        
        return arm
    
    def _create_hand(self, height: float, build: dict) -> bpy.types.Object:
        """Create a simple hand."""
        h = self.PROPORTIONS["hand"] * height
        w = h * 0.8
        d = h * 0.4
        
        # Palm
        bpy.ops.mesh.primitive_cube_add(size=1)
        hand = bpy.context.active_object
        hand.scale = (d, w, h * 0.6)
        bpy.ops.object.transform_apply(scale=True)
        
        # Add finger block
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -h * 0.4))
        fingers = bpy.context.active_object
        fingers.scale = (d * 0.8, w * 0.9, h * 0.5)
        bpy.ops.object.transform_apply(scale=True)
        
        # Join
        hand.select_set(True)
        fingers.select_set(True)
        bpy.context.view_layer.objects.active = hand
        bpy.ops.object.join()
        
        return hand
    
    def _create_neck(self, height: float, build: dict) -> bpy.types.Object:
        """Create neck."""
        h = self.PROPORTIONS["neck_height"] * height
        r = height * 0.04 * build["mass"]
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=h)
        neck = bpy.context.active_object
        
        return neck
    
    def _create_head(self, height: float, build: dict) -> bpy.types.Object:
        """Create detailed head with facial features."""
        h = self.PROPORTIONS["head_height"] * height
        w = h * 0.7
        d = h * 0.85
        
        # Main head shape
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=h * 0.5)
        head = bpy.context.active_object
        head.scale = (d / h, w / h, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        
        # Shape the head - flatten back, define jaw
        bm = bmesh.new()
        bm.from_mesh(head.data)
        for v in bm.verts:
            # Flatten back of head
            if v.co.x < -h * 0.2:
                v.co.x = max(v.co.x, -h * 0.35)
            # Define jaw
            if v.co.z < -h * 0.15 and v.co.x > 0:
                v.co.y *= 0.85
            # Brow ridge
            if v.co.z > h * 0.1 and v.co.z < h * 0.25 and v.co.x > h * 0.2:
                v.co.x += h * 0.03
        bm.to_mesh(head.data)
        bm.free()
        
        # Add simple facial features (nose bump)
        bm = bmesh.new()
        bm.from_mesh(head.data)
        for v in bm.verts:
            if abs(v.co.y) < h * 0.1 and v.co.z > -h * 0.1 and v.co.z < h * 0.15 and v.co.x > h * 0.3:
                v.co.x += h * 0.05
        bm.to_mesh(head.data)
        bm.free()
        
        return head
    
    def _create_hair(self, height: float, style: str) -> bpy.types.Object:
        """Create hair based on style."""
        h = self.PROPORTIONS["head_height"] * height
        
        if style == "short":
            bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=4, radius=h * 0.52)
            hair = bpy.context.active_object
            hair.scale = (0.9, 1.0, 0.7)
            # Cut off bottom half
            bm = bmesh.new()
            bm.from_mesh(hair.data)
            verts_to_delete = [v for v in bm.verts if v.co.z < 0]
            bmesh.ops.delete(bm, geom=verts_to_delete, context='VERTS')
            bm.to_mesh(hair.data)
            bm.free()
            
        elif style == "ponytail":
            bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=4, radius=h * 0.52)
            hair = bpy.context.active_object
            hair.scale = (0.95, 1.0, 0.6)
            
            # Add ponytail
            bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=h * 0.08, depth=h * 0.4)
            tail = bpy.context.active_object
            tail.location = (-h * 0.3, 0, -h * 0.1)
            tail.rotation_euler.y = math.radians(45)
            
            hair.select_set(True)
            tail.select_set(True)
            bpy.context.view_layer.objects.active = hair
            bpy.ops.object.join()
            
        elif style == "mohawk":
            bpy.ops.mesh.primitive_cube_add(size=1)
            hair = bpy.context.active_object
            hair.scale = (h * 0.6, h * 0.08, h * 0.25)
            hair.location.z = h * 0.15
            bpy.ops.object.transform_apply(scale=True)
            
        else:  # Default
            bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=3, radius=h * 0.5)
            hair = bpy.context.active_object
        
        bpy.ops.object.transform_apply(scale=True)
        return hair
    
    def _add_equipment(self, height: float, clothing: str, cloth_mat, accent_mat) -> list:
        """Add equipment and accessories based on clothing type."""
        equipment = []
        
        if "tactical" in clothing:
            # Belt
            belt_y = height * 0.52
            bpy.ops.mesh.primitive_torus_add(
                major_radius=self.PROPORTIONS["hip_width"] * height * 0.5,
                minor_radius=0.015,
                major_segments=16,
                minor_segments=6
            )
            belt = bpy.context.active_object
            belt.location.z = belt_y
            belt.rotation_euler.x = math.radians(90)
            belt.data.materials.append(accent_mat)
            equipment.append(belt)
            
            # Backpack straps hint
            for side in [-1, 1]:
                bpy.ops.mesh.primitive_cube_add(size=1)
                strap = bpy.context.active_object
                strap.scale = (0.01, 0.02, height * 0.15)
                strap.location = (-height * 0.08, side * height * 0.06, height * 0.75)
                bpy.ops.object.transform_apply(scale=True)
                strap.data.materials.append(accent_mat)
                equipment.append(strap)
        
        if "raider" in clothing:
            # Shoulder pad
            bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=3, radius=height * 0.05)
            pad = bpy.context.active_object
            pad.scale = (1.2, 1.5, 0.6)
            pad.location = (0, self.PROPORTIONS["shoulder_width"] * height * 0.6, height * 0.82)
            bpy.ops.object.transform_apply(scale=True)
            pad.data.materials.append(accent_mat)
            equipment.append(pad)
        
        return equipment
    
    def _create_skin_material(self, name: str, base_color: tuple) -> bpy.types.Material:
        """Create realistic skin material."""
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
        bsdf.inputs["Roughness"].default_value = 0.6
        bsdf.inputs["Subsurface Weight"].default_value = 0.1
        
        # Add subtle variation
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-400, 0)
        noise.inputs["Scale"].default_value = 15.0
        noise.inputs["Detail"].default_value = 2.0
        
        mix = nodes.new("ShaderNodeMixRGB")
        mix.location = (-200, 0)
        mix.blend_type = 'MULTIPLY'
        mix.inputs["Fac"].default_value = 0.1
        mix.inputs["Color1"].default_value = (*base_color, 1.0)
        
        links.new(noise.outputs["Color"], mix.inputs["Color2"])
        links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_clothing_material(self, name: str, clothing_type: str) -> bpy.types.Material:
        """Create clothing material based on type."""
        colors = {
            "tactical": (0.15, 0.20, 0.15),  # Military green
            "merchant": (0.35, 0.28, 0.20),  # Brown
            "workwear": (0.20, 0.22, 0.28),  # Dark blue-gray
            "raider_light": (0.12, 0.10, 0.08),  # Dark worn leather
            "raider_heavy": (0.08, 0.08, 0.10),  # Almost black
        }
        
        base_color = colors.get(clothing_type, colors["tactical"])
        
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
        bsdf.inputs["Roughness"].default_value = 0.8
        
        # Fabric variation
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-400, 0)
        noise.inputs["Scale"].default_value = 25.0
        
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (-200, 0)
        ramp.color_ramp.elements[0].color = (*base_color, 1.0)
        ramp.color_ramp.elements[1].color = (base_color[0] * 1.2, base_color[1] * 1.2, base_color[2] * 1.2, 1.0)
        
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_accent_material(self, name: str, clothing_type: str) -> bpy.types.Material:
        """Create accent material for belts, straps, etc."""
        colors = {
            "tactical": (0.10, 0.08, 0.05),  # Dark brown leather
            "merchant": (0.25, 0.18, 0.10),  # Tan leather
            "workwear": (0.15, 0.12, 0.08),  # Work leather
            "raider_light": (0.20, 0.05, 0.02),  # Red accent
            "raider_heavy": (0.30, 0.08, 0.05),  # Blood red
        }
        
        base_color = colors.get(clothing_type, colors["tactical"])
        
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (400, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (0, 0)
        bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.5
        bsdf.inputs["Metallic"].default_value = 0.1
        
        mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_hair_material(self, name: str) -> bpy.types.Material:
        """Create hair material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (400, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (0, 0)
        bsdf.inputs["Base Color"].default_value = (0.05, 0.03, 0.02, 1.0)  # Dark brown/black
        bsdf.inputs["Roughness"].default_value = 0.7
        
        mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _apply_stylized_shading(self, obj: bpy.types.Object) -> None:
        """Apply stylized low-poly shading with smooth groups."""
        # Apply smooth shading
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.shade_smooth()
        
        # Add edge split for hard edges - compatible with Blender 3.x and 4.x
        try:
            bpy.ops.object.modifier_add(type='EDGE_SPLIT')
            # Find the edge split modifier by type
            for mod in obj.modifiers:
                if mod.type == 'EDGE_SPLIT':
                    mod.split_angle = math.radians(35)
                    bpy.ops.object.modifier_apply(modifier=mod.name)
                    break
        except Exception as e:
            # If edge split fails, just use smooth shading
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
