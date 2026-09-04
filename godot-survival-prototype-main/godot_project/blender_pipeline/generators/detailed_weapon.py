"""
Detailed Weapon Generator - Creates detailed weapons for survival game.
Includes melee weapons, firearms, and throwables with proper details.
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector


class DetailedWeaponGenerator:
    """Generate detailed weapon models with grips, guards, and mechanical parts."""
    
    WEAPON_TYPES = {
        # Melee - Blunt
        "bat_wooden": {
            "category": "melee_blunt",
            "length": 0.85,
            "material": "wood",
            "grip_length": 0.25,
            "head_type": "tapered"
        },
        "bat_metal": {
            "category": "melee_blunt",
            "length": 0.80,
            "material": "metal",
            "grip_length": 0.22,
            "head_type": "tapered",
            "has_tape": True
        },
        "pipe_iron": {
            "category": "melee_blunt",
            "length": 0.75,
            "material": "metal",
            "grip_length": 0.20,
            "head_type": "pipe"
        },
        "hammer": {
            "category": "melee_blunt",
            "length": 0.35,
            "material": "metal",
            "grip_length": 0.28,
            "head_type": "hammer"
        },
        "sledgehammer": {
            "category": "melee_blunt",
            "length": 0.90,
            "material": "metal",
            "grip_length": 0.70,
            "head_type": "sledge"
        },
        "crowbar": {
            "category": "melee_blunt",
            "length": 0.65,
            "material": "metal",
            "grip_length": 0.15,
            "head_type": "crowbar"
        },
        
        # Melee - Bladed
        "machete": {
            "category": "melee_blade",
            "length": 0.55,
            "material": "metal",
            "grip_length": 0.12,
            "blade_type": "machete",
            "blade_width": 0.05
        },
        "knife_combat": {
            "category": "melee_blade",
            "length": 0.30,
            "material": "metal",
            "grip_length": 0.11,
            "blade_type": "combat",
            "blade_width": 0.03
        },
        "knife_survival": {
            "category": "melee_blade",
            "length": 0.28,
            "material": "metal",
            "grip_length": 0.10,
            "blade_type": "survival",
            "blade_width": 0.035,
            "has_serration": True
        },
        "axe_hatchet": {
            "category": "melee_blade",
            "length": 0.40,
            "material": "metal",
            "grip_length": 0.32,
            "blade_type": "hatchet"
        },
        "axe_fire": {
            "category": "melee_blade",
            "length": 0.70,
            "material": "metal",
            "grip_length": 0.55,
            "blade_type": "fire_axe"
        },
        "katana": {
            "category": "melee_blade",
            "length": 1.00,
            "material": "metal",
            "grip_length": 0.28,
            "blade_type": "katana",
            "blade_width": 0.035
        },
        
        # Firearms - Pistols
        "pistol_9mm": {
            "category": "firearm_pistol",
            "length": 0.20,
            "material": "metal",
            "caliber": "9mm",
            "has_magazine": True
        },
        "pistol_45": {
            "category": "firearm_pistol",
            "length": 0.22,
            "material": "metal",
            "caliber": ".45",
            "has_magazine": True
        },
        "revolver": {
            "category": "firearm_pistol",
            "length": 0.25,
            "material": "metal",
            "caliber": ".357",
            "has_cylinder": True
        },
        
        # Firearms - Rifles
        "rifle_assault": {
            "category": "firearm_rifle",
            "length": 0.85,
            "material": "metal",
            "stock_type": "tactical",
            "has_magazine": True,
            "has_rails": True
        },
        "rifle_bolt": {
            "category": "firearm_rifle",
            "length": 1.10,
            "material": "wood_metal",
            "stock_type": "classic",
            "has_scope_mount": True
        },
        "shotgun_pump": {
            "category": "firearm_shotgun",
            "length": 1.00,
            "material": "wood_metal",
            "action_type": "pump"
        },
        "shotgun_auto": {
            "category": "firearm_shotgun",
            "length": 0.95,
            "material": "metal",
            "action_type": "auto",
            "has_magazine": True
        },
        "smg": {
            "category": "firearm_smg",
            "length": 0.50,
            "material": "metal",
            "has_magazine": True,
            "has_foregrip": True
        },
        
        # Throwables
        "grenade_frag": {
            "category": "throwable",
            "size": 0.08,
            "type": "frag"
        },
        "molotov": {
            "category": "throwable",
            "size": 0.25,
            "type": "molotov"
        },
        
        # Tools (used as weapons)
        "shovel": {
            "category": "tool",
            "length": 1.20,
            "material": "wood_metal",
            "head_type": "shovel",
            "grip_length": 1.00
        },
        "pickaxe": {
            "category": "tool",
            "length": 0.85,
            "material": "wood_metal",
            "head_type": "pick",
            "grip_length": 0.70
        }
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, weapon_type: str = "knife_combat") -> bpy.types.Object:
        """Generate a detailed weapon of the specified type."""
        config = self.WEAPON_TYPES.get(weapon_type, self.WEAPON_TYPES["knife_combat"])
        
        category = config["category"]
        
        if category == "melee_blunt":
            weapon = self._create_blunt_weapon(name, config, weapon_type)
        elif category == "melee_blade":
            weapon = self._create_blade_weapon(name, config, weapon_type)
        elif category.startswith("firearm"):
            weapon = self._create_firearm(name, config, category)
        elif category == "throwable":
            weapon = self._create_throwable(name, config)
        elif category == "tool":
            weapon = self._create_tool_weapon(name, config, weapon_type)
        else:
            weapon = self._create_basic_weapon(name, config)
        
        weapon.name = name
        self._set_origin_to_center(weapon)
        
        return weapon
    
    def _create_blunt_weapon(self, name: str, config: dict, weapon_type: str) -> bpy.types.Object:
        """Create blunt melee weapons (bats, pipes, hammers)."""
        length = config["length"]
        grip_length = config["grip_length"]
        head_type = config["head_type"]
        material = config["material"]
        
        parts = []
        
        # Create appropriate materials
        if material == "wood":
            main_mat = self._create_wood_material(f"mat_{name}")
        else:
            main_mat = self._create_metal_material(f"mat_{name}")
        
        grip_mat = self._create_grip_material(f"mat_{name}_grip")
        
        if head_type == "tapered":
            # Baseball bat style
            weapon = self._create_bat(length, grip_length, material == "wood")
            weapon.data.materials.append(main_mat)
            parts.append(weapon)
        
        elif head_type == "pipe":
            # Iron pipe
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.02, depth=length)
            pipe = bpy.context.active_object
            
            # Make hollow
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.015, depth=length + 0.01)
            inner = bpy.context.active_object
            
            # Add end cap
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.025, depth=0.015)
            cap = bpy.context.active_object
            cap.location.z = length / 2 + 0.0075
            
            pipe.select_set(True)
            cap.select_set(True)
            bpy.context.view_layer.objects.active = pipe
            bpy.ops.object.join()
            pipe = bpy.context.active_object
            bpy.ops.object.select_all(action='DESELECT')
            
            inner.select_set(True)
            bpy.ops.object.delete()
            
            pipe.data.materials.append(main_mat)
            parts.append(pipe)
        
        elif head_type == "hammer":
            # Claw hammer
            weapon = self._create_hammer(length, grip_length)
            parts.append(weapon)
        
        elif head_type == "sledge":
            # Sledgehammer
            weapon = self._create_sledgehammer(length, grip_length)
            parts.append(weapon)
        
        elif head_type == "crowbar":
            # Crowbar
            weapon = self._create_crowbar(length)
            weapon.data.materials.append(main_mat)
            parts.append(weapon)
        
        # Add grip tape if specified
        if config.get("has_tape"):
            tape = self._create_grip_tape(grip_length, 0.022)
            tape.location.z = -length / 2 + grip_length / 2
            tape.data.materials.append(grip_mat)
            parts.append(tape)
        
        # Join all parts
        if len(parts) > 1:
            bpy.ops.object.select_all(action='DESELECT')
            for part in parts:
                if part is not None:
                    part.select_set(True)
            bpy.context.view_layer.objects.active = parts[0]
            bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_bat(self, length: float, grip_length: float, is_wood: bool) -> bpy.types.Object:
        """Create a baseball bat shape."""
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.02, depth=length)
        bat = bpy.context.active_object
        
        bm = bmesh.new()
        bm.from_mesh(bat.data)
        
        for v in bm.verts:
            # Position along bat (0 = handle end, 1 = head end)
            pos = (v.co.z + length / 2) / length
            
            # Taper from knob through grip, then widen to barrel
            if pos < 0.05:  # Knob
                scale = 1.2
            elif pos < grip_length / length:  # Grip
                scale = 0.85
            elif pos < 0.5:  # Transition
                t = (pos - grip_length / length) / (0.5 - grip_length / length)
                scale = 0.85 + t * 0.9
            else:  # Barrel
                scale = 1.75 - (pos - 0.5) * 0.5
            
            v.co.x *= scale
            v.co.y *= scale
        
        bm.to_mesh(bat.data)
        bm.free()
        
        return bat
    
    def _create_hammer(self, length: float, grip_length: float) -> bpy.types.Object:
        """Create a claw hammer."""
        parts = []
        
        wood_mat = self._create_wood_material("mat_hammer_handle")
        metal_mat = self._create_metal_material("mat_hammer_head")
        
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.015, depth=grip_length)
        handle = bpy.context.active_object
        handle.location.z = grip_length / 2
        handle.data.materials.append(wood_mat)
        parts.append(handle)
        
        # Head
        head_length = length - grip_length
        bpy.ops.mesh.primitive_cube_add(size=1)
        head = bpy.context.active_object
        head.scale = (0.03, head_length / 2, 0.025)
        head.location = (0, 0, grip_length + 0.015)
        bpy.ops.object.transform_apply(scale=True)
        
        # Taper the claw end
        bm = bmesh.new()
        bm.from_mesh(head.data)
        for v in bm.verts:
            if v.co.y < 0:  # Claw side
                v.co.z *= 0.7
                if v.co.y < -head_length * 0.3:
                    # Split for claw
                    v.co.x *= 1 + abs(v.co.y) * 2
        bm.to_mesh(head.data)
        bm.free()
        
        head.data.materials.append(metal_mat)
        parts.append(head)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_sledgehammer(self, length: float, grip_length: float) -> bpy.types.Object:
        """Create a sledgehammer."""
        parts = []
        
        wood_mat = self._create_wood_material("mat_sledge_handle")
        metal_mat = self._create_metal_material("mat_sledge_head")
        
        # Long handle
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.018, depth=grip_length)
        handle = bpy.context.active_object
        handle.location.z = grip_length / 2
        handle.data.materials.append(wood_mat)
        parts.append(handle)
        
        # Heavy head
        head_size = length - grip_length
        bpy.ops.mesh.primitive_cube_add(size=1)
        head = bpy.context.active_object
        head.scale = (head_size / 2, 0.06, 0.06)
        head.location = (0, 0, grip_length + 0.03)
        bpy.ops.object.transform_apply(scale=True)
        
        # Bevel edges
        bpy.ops.object.modifier_add(type='BEVEL')
        head.modifiers["Bevel"].width = 0.008
        head.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        head.data.materials.append(metal_mat)
        parts.append(head)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_crowbar(self, length: float) -> bpy.types.Object:
        """Create a crowbar."""
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.015, depth=length)
        crowbar = bpy.context.active_object
        
        # Make hexagonal cross-section
        crowbar.scale.x = 0.8
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(crowbar.data)
        
        for v in bm.verts:
            pos = (v.co.z + length / 2) / length
            
            # Curved hook at top
            if pos > 0.85:
                curve = (pos - 0.85) / 0.15
                v.co.y += curve * 0.08
                v.co.z -= curve * curve * 0.03
            
            # Slight bend at bottom (pry end)
            if pos < 0.15:
                curve = (0.15 - pos) / 0.15
                v.co.y -= curve * 0.04
        
        bm.to_mesh(crowbar.data)
        bm.free()
        
        return crowbar
    
    def _create_blade_weapon(self, name: str, config: dict, weapon_type: str) -> bpy.types.Object:
        """Create bladed weapons (knives, machetes, axes)."""
        length = config["length"]
        grip_length = config["grip_length"]
        blade_type = config.get("blade_type", "knife")
        blade_width = config.get("blade_width", 0.03)
        
        parts = []
        
        blade_mat = self._create_blade_material(f"mat_{name}_blade")
        grip_mat = self._create_grip_material(f"mat_{name}_grip")
        guard_mat = self._create_metal_material(f"mat_{name}_guard")
        
        blade_length = length - grip_length
        
        if blade_type in ["machete", "combat", "survival", "katana"]:
            # Blade
            blade = self._create_blade(blade_length, blade_width, blade_type)
            blade.location.z = grip_length + blade_length / 2
            blade.data.materials.append(blade_mat)
            parts.append(blade)
            
            # Guard
            if blade_type != "machete":
                guard = self._create_guard(blade_width * 1.5, blade_type)
                guard.location.z = grip_length
                guard.data.materials.append(guard_mat)
                parts.append(guard)
            
            # Grip
            grip = self._create_knife_grip(grip_length, blade_type)
            grip.location.z = grip_length / 2
            grip.data.materials.append(grip_mat)
            parts.append(grip)
            
            # Pommel
            if blade_type in ["combat", "katana"]:
                pommel = self._create_pommel(blade_type)
                pommel.location.z = 0
                pommel.data.materials.append(guard_mat)
                parts.append(pommel)
        
        elif blade_type in ["hatchet", "fire_axe"]:
            parts = self._create_axe(length, grip_length, blade_type)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            if part is not None:
                part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_blade(self, length: float, width: float, blade_type: str) -> bpy.types.Object:
        """Create a blade shape."""
        thickness = 0.004
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        blade = bpy.context.active_object
        blade.scale = (thickness, width / 2, length / 2)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(blade.data)
        
        for v in bm.verts:
            pos = (v.co.z + length / 2) / length  # 0 at base, 1 at tip
            
            if blade_type == "machete":
                # Wide blade, curves at tip
                if pos > 0.85:
                    curve = (pos - 0.85) / 0.15
                    v.co.y *= 1 - curve * 0.7
                # Edge beveling
                if v.co.x > 0 and v.co.y > 0:
                    v.co.x -= thickness * 0.4
            
            elif blade_type == "combat":
                # Clip point
                if pos > 0.7:
                    curve = (pos - 0.7) / 0.3
                    v.co.y *= 1 - curve * 0.8
                    if v.co.x < 0:  # Spine
                        v.co.y *= 1 - curve * 0.3
            
            elif blade_type == "survival":
                # Drop point
                if pos > 0.6:
                    curve = (pos - 0.6) / 0.4
                    v.co.y *= 1 - curve * 0.6
            
            elif blade_type == "katana":
                # Curved blade
                v.co.x += math.sin(pos * math.pi) * 0.015
                if pos > 0.9:
                    curve = (pos - 0.9) / 0.1
                    v.co.y *= 1 - curve * 0.85
        
        bm.to_mesh(blade.data)
        bm.free()
        
        return blade
    
    def _create_guard(self, width: float, blade_type: str) -> bpy.types.Object:
        """Create a blade guard/crossguard."""
        if blade_type == "katana":
            # Tsuba (round guard)
            bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=width, depth=0.008)
            guard = bpy.context.active_object
        else:
            # Crossguard
            bpy.ops.mesh.primitive_cube_add(size=1)
            guard = bpy.context.active_object
            guard.scale = (0.008, width, 0.015)
            bpy.ops.object.transform_apply(scale=True)
        
        return guard
    
    def _create_knife_grip(self, length: float, blade_type: str) -> bpy.types.Object:
        """Create a knife grip/handle."""
        if blade_type == "katana":
            # Wrapped handle
            bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.015, depth=length)
        else:
            # Ergonomic grip
            bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.014, depth=length)
        
        grip = bpy.context.active_object
        
        # Add finger grooves
        bm = bmesh.new()
        bm.from_mesh(grip.data)
        for v in bm.verts:
            pos = (v.co.z + length / 2) / length
            # Wavy profile for finger grooves
            wave = math.sin(pos * math.pi * 4) * 0.002
            dist = math.sqrt(v.co.x**2 + v.co.y**2)
            if dist > 0.01:
                v.co.x *= 1 + wave / dist * 10
                v.co.y *= 1 + wave / dist * 10
        bm.to_mesh(grip.data)
        bm.free()
        
        return grip
    
    def _create_pommel(self, blade_type: str) -> bpy.types.Object:
        """Create a pommel."""
        if blade_type == "katana":
            bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.012, depth=0.015)
        else:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.015)
        
        return bpy.context.active_object
    
    def _create_axe(self, length: float, grip_length: float, axe_type: str) -> list:
        """Create an axe."""
        parts = []
        
        wood_mat = self._create_wood_material("mat_axe_handle")
        metal_mat = self._create_metal_material("mat_axe_head")
        
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.018, depth=grip_length)
        handle = bpy.context.active_object
        handle.location.z = grip_length / 2
        
        # Taper slightly
        bm = bmesh.new()
        bm.from_mesh(handle.data)
        for v in bm.verts:
            pos = (v.co.z + grip_length / 2) / grip_length
            v.co.x *= 0.85 + pos * 0.15
            v.co.y *= 0.85 + pos * 0.15
        bm.to_mesh(handle.data)
        bm.free()
        
        handle.data.materials.append(wood_mat)
        parts.append(handle)
        
        # Axe head
        head_size = length - grip_length
        
        if axe_type == "hatchet":
            bpy.ops.mesh.primitive_cube_add(size=1)
            head = bpy.context.active_object
            head.scale = (head_size / 2, 0.015, 0.08)
            head.location = (head_size / 4, 0, grip_length + 0.02)
            bpy.ops.object.transform_apply(scale=True)
            
            # Taper to edge
            bm = bmesh.new()
            bm.from_mesh(head.data)
            for v in bm.verts:
                if v.co.x > 0:  # Blade side
                    edge_factor = v.co.x / (head_size / 2)
                    v.co.y *= 1 - edge_factor * 0.8
            bm.to_mesh(head.data)
            bm.free()
        
        else:  # fire_axe
            bpy.ops.mesh.primitive_cube_add(size=1)
            head = bpy.context.active_object
            head.scale = (head_size * 0.6, 0.012, 0.12)
            head.location = (head_size * 0.3, 0, grip_length + 0.02)
            bpy.ops.object.transform_apply(scale=True)
            
            # Fire axe has pick on back
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.02, radius2=0, depth=0.08)
            pick = bpy.context.active_object
            pick.rotation_euler.y = math.radians(-90)
            pick.location = (-0.04, 0, grip_length + 0.02)
            
            head.select_set(True)
            pick.select_set(True)
            bpy.context.view_layer.objects.active = head
            bpy.ops.object.join()
            head = bpy.context.active_object
            bpy.ops.object.select_all(action='DESELECT')
        
        head.data.materials.append(metal_mat)
        parts.append(head)
        
        return parts
    
    def _create_firearm(self, name: str, config: dict, category: str) -> bpy.types.Object:
        """Create firearm weapons."""
        length = config["length"]
        
        parts = []
        
        body_mat = self._create_metal_material(f"mat_{name}_body", dark=True)
        grip_mat = self._create_grip_material(f"mat_{name}_grip")
        detail_mat = self._create_metal_material(f"mat_{name}_detail")
        
        if "pistol" in category:
            parts = self._create_pistol(length, config, body_mat, grip_mat, detail_mat)
        elif "rifle" in category:
            parts = self._create_rifle(length, config, body_mat, grip_mat, detail_mat)
        elif "shotgun" in category:
            parts = self._create_shotgun(length, config, body_mat, grip_mat, detail_mat)
        elif "smg" in category:
            parts = self._create_smg(length, config, body_mat, grip_mat, detail_mat)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            if part is not None:
                part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_pistol(self, length: float, config: dict, body_mat, grip_mat, detail_mat) -> list:
        """Create a pistol."""
        parts = []
        
        # Slide
        bpy.ops.mesh.primitive_cube_add(size=1)
        slide = bpy.context.active_object
        slide.scale = (length / 2, 0.015, 0.025)
        slide.location = (length / 4, 0, 0.045)
        bpy.ops.object.transform_apply(scale=True)
        slide.data.materials.append(body_mat)
        parts.append(slide)
        
        # Frame
        bpy.ops.mesh.primitive_cube_add(size=1)
        frame = bpy.context.active_object
        frame.scale = (length * 0.4, 0.013, 0.02)
        frame.location = (0, 0, 0.02)
        bpy.ops.object.transform_apply(scale=True)
        frame.data.materials.append(body_mat)
        parts.append(frame)
        
        # Grip
        bpy.ops.mesh.primitive_cube_add(size=1)
        grip = bpy.context.active_object
        grip.scale = (0.02, 0.018, 0.05)
        grip.location = (-length * 0.15, 0, -0.025)
        grip.rotation_euler.y = math.radians(-15)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        grip.data.materials.append(grip_mat)
        parts.append(grip)
        
        # Trigger guard
        bpy.ops.mesh.primitive_torus_add(major_radius=0.02, minor_radius=0.003, major_segments=12, minor_segments=4)
        guard = bpy.context.active_object
        guard.scale.z = 0.5
        guard.location = (0.01, 0, -0.01)
        guard.rotation_euler.x = math.radians(90)
        bpy.ops.object.transform_apply(scale=True)
        guard.data.materials.append(body_mat)
        parts.append(guard)
        
        # Barrel (visible at front)
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.006, depth=0.03)
        barrel = bpy.context.active_object
        barrel.rotation_euler.y = math.radians(90)
        barrel.location = (length / 2 + 0.01, 0, 0.045)
        barrel.data.materials.append(detail_mat)
        parts.append(barrel)
        
        # Front sight
        bpy.ops.mesh.primitive_cube_add(size=0.006)
        sight = bpy.context.active_object
        sight.location = (length / 2 - 0.01, 0, 0.072)
        sight.data.materials.append(detail_mat)
        parts.append(sight)
        
        # Magazine if specified
        if config.get("has_magazine"):
            bpy.ops.mesh.primitive_cube_add(size=1)
            mag = bpy.context.active_object
            mag.scale = (0.012, 0.015, 0.04)
            mag.location = (-length * 0.15, 0, -0.06)
            bpy.ops.object.transform_apply(scale=True)
            mag.data.materials.append(body_mat)
            parts.append(mag)
        
        # Cylinder for revolver
        if config.get("has_cylinder"):
            bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.02, depth=0.03)
            cylinder = bpy.context.active_object
            cylinder.rotation_euler.x = math.radians(90)
            cylinder.location = (0.02, 0, 0.03)
            cylinder.data.materials.append(body_mat)
            parts.append(cylinder)
        
        return parts
    
    def _create_rifle(self, length: float, config: dict, body_mat, grip_mat, detail_mat) -> list:
        """Create a rifle."""
        parts = []
        stock_type = config.get("stock_type", "tactical")
        
        # Receiver
        bpy.ops.mesh.primitive_cube_add(size=1)
        receiver = bpy.context.active_object
        receiver.scale = (length * 0.25, 0.025, 0.04)
        receiver.location = (0, 0, 0)
        bpy.ops.object.transform_apply(scale=True)
        receiver.data.materials.append(body_mat)
        parts.append(receiver)
        
        # Barrel
        barrel_length = length * 0.45
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.012, depth=barrel_length)
        barrel = bpy.context.active_object
        barrel.rotation_euler.y = math.radians(90)
        barrel.location = (length * 0.25 + barrel_length / 2, 0, 0.01)
        barrel.data.materials.append(detail_mat)
        parts.append(barrel)
        
        # Handguard
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.022, depth=barrel_length * 0.6)
        handguard = bpy.context.active_object
        handguard.rotation_euler.y = math.radians(90)
        handguard.location = (length * 0.25 + barrel_length * 0.3, 0, 0)
        handguard.data.materials.append(body_mat)
        parts.append(handguard)
        
        # Stock
        if stock_type == "tactical":
            bpy.ops.mesh.primitive_cube_add(size=1)
            stock = bpy.context.active_object
            stock.scale = (length * 0.22, 0.02, 0.045)
            stock.location = (-length * 0.22, 0, -0.01)
            bpy.ops.object.transform_apply(scale=True)
        else:  # Classic wood stock
            bpy.ops.mesh.primitive_cube_add(size=1)
            stock = bpy.context.active_object
            stock.scale = (length * 0.3, 0.025, 0.06)
            stock.location = (-length * 0.25, 0, -0.02)
            bpy.ops.object.transform_apply(scale=True)
            
            # Curve the stock
            bm = bmesh.new()
            bm.from_mesh(stock.data)
            for v in bm.verts:
                if v.co.x < 0:
                    v.co.z -= abs(v.co.x) * 0.15
            bm.to_mesh(stock.data)
            bm.free()
        
        stock.data.materials.append(grip_mat if stock_type == "tactical" else self._create_wood_material("mat_stock"))
        parts.append(stock)
        
        # Pistol grip
        bpy.ops.mesh.primitive_cube_add(size=1)
        grip = bpy.context.active_object
        grip.scale = (0.02, 0.02, 0.06)
        grip.location = (-0.03, 0, -0.06)
        grip.rotation_euler.y = math.radians(-15)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        grip.data.materials.append(grip_mat)
        parts.append(grip)
        
        # Magazine
        if config.get("has_magazine"):
            bpy.ops.mesh.primitive_cube_add(size=1)
            mag = bpy.context.active_object
            mag.scale = (0.025, 0.02, 0.08)
            mag.location = (0.02, 0, -0.08)
            mag.rotation_euler.y = math.radians(-5)
            bpy.ops.object.transform_apply(scale=True, rotation=True)
            mag.data.materials.append(body_mat)
            parts.append(mag)
        
        # Rails if specified
        if config.get("has_rails"):
            for offset in [0.025, -0.025]:
                bpy.ops.mesh.primitive_cube_add(size=1)
                rail = bpy.context.active_object
                rail.scale = (0.15, 0.003, 0.005)
                rail.location = (length * 0.35, offset, 0.025)
                bpy.ops.object.transform_apply(scale=True)
                rail.data.materials.append(detail_mat)
                parts.append(rail)
        
        return parts
    
    def _create_shotgun(self, length: float, config: dict, body_mat, grip_mat, detail_mat) -> list:
        """Create a shotgun."""
        parts = []
        
        # Receiver
        bpy.ops.mesh.primitive_cube_add(size=1)
        receiver = bpy.context.active_object
        receiver.scale = (length * 0.15, 0.03, 0.045)
        receiver.location = (0, 0, 0)
        bpy.ops.object.transform_apply(scale=True)
        receiver.data.materials.append(body_mat)
        parts.append(receiver)
        
        # Barrel
        barrel_length = length * 0.55
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.015, depth=barrel_length)
        barrel = bpy.context.active_object
        barrel.rotation_euler.y = math.radians(90)
        barrel.location = (length * 0.15 + barrel_length / 2, 0, 0.01)
        barrel.data.materials.append(detail_mat)
        parts.append(barrel)
        
        # Pump/forend
        if config.get("action_type") == "pump":
            bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.025, depth=0.15)
            pump = bpy.context.active_object
            pump.rotation_euler.y = math.radians(90)
            pump.location = (length * 0.25, 0, -0.01)
            pump.data.materials.append(grip_mat)
            parts.append(pump)
        
        # Stock
        wood_mat = self._create_wood_material("mat_shotgun_stock")
        bpy.ops.mesh.primitive_cube_add(size=1)
        stock = bpy.context.active_object
        stock.scale = (length * 0.28, 0.025, 0.055)
        stock.location = (-length * 0.22, 0, -0.015)
        bpy.ops.object.transform_apply(scale=True)
        
        # Curve the stock
        bm = bmesh.new()
        bm.from_mesh(stock.data)
        for v in bm.verts:
            if v.co.x < 0:
                v.co.z -= abs(v.co.x) * 0.12
        bm.to_mesh(stock.data)
        bm.free()
        
        stock.data.materials.append(wood_mat)
        parts.append(stock)
        
        return parts
    
    def _create_smg(self, length: float, config: dict, body_mat, grip_mat, detail_mat) -> list:
        """Create a submachine gun."""
        parts = []
        
        # Compact receiver
        bpy.ops.mesh.primitive_cube_add(size=1)
        receiver = bpy.context.active_object
        receiver.scale = (length * 0.4, 0.03, 0.05)
        receiver.location = (0, 0, 0)
        bpy.ops.object.transform_apply(scale=True)
        receiver.data.materials.append(body_mat)
        parts.append(receiver)
        
        # Short barrel
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.01, depth=length * 0.35)
        barrel = bpy.context.active_object
        barrel.rotation_euler.y = math.radians(90)
        barrel.location = (length * 0.35, 0, 0)
        barrel.data.materials.append(detail_mat)
        parts.append(barrel)
        
        # Pistol grip
        bpy.ops.mesh.primitive_cube_add(size=1)
        grip = bpy.context.active_object
        grip.scale = (0.018, 0.022, 0.055)
        grip.location = (-length * 0.1, 0, -0.055)
        grip.rotation_euler.y = math.radians(-12)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        grip.data.materials.append(grip_mat)
        parts.append(grip)
        
        # Foregrip if specified
        if config.get("has_foregrip"):
            bpy.ops.mesh.primitive_cube_add(size=1)
            foregrip = bpy.context.active_object
            foregrip.scale = (0.015, 0.018, 0.04)
            foregrip.location = (length * 0.15, 0, -0.045)
            bpy.ops.object.transform_apply(scale=True)
            foregrip.data.materials.append(grip_mat)
            parts.append(foregrip)
        
        # Magazine
        if config.get("has_magazine"):
            bpy.ops.mesh.primitive_cube_add(size=1)
            mag = bpy.context.active_object
            mag.scale = (0.02, 0.018, 0.12)
            mag.location = (0.02, 0, -0.1)
            bpy.ops.object.transform_apply(scale=True)
            mag.data.materials.append(body_mat)
            parts.append(mag)
        
        # Folding stock
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.008, depth=length * 0.25)
        stock = bpy.context.active_object
        stock.rotation_euler.y = math.radians(90)
        stock.location = (-length * 0.25, 0, 0.02)
        stock.data.materials.append(body_mat)
        parts.append(stock)
        
        return parts
    
    def _create_throwable(self, name: str, config: dict) -> bpy.types.Object:
        """Create throwable weapons."""
        throw_type = config["type"]
        size = config["size"]
        
        parts = []
        
        if throw_type == "frag":
            # Grenade body
            bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=size / 2)
            body = bpy.context.active_object
            body.scale.z = 1.3
            bpy.ops.object.transform_apply(scale=True)
            
            # Add pineapple texture (grid pattern)
            bm = bmesh.new()
            bm.from_mesh(body.data)
            for v in bm.verts:
                angle = math.atan2(v.co.y, v.co.x)
                if int(angle * 6) % 2 == 0 and int(v.co.z * 20) % 2 == 0:
                    dist = math.sqrt(v.co.x**2 + v.co.y**2)
                    v.co.x *= 0.95
                    v.co.y *= 0.95
            bm.to_mesh(body.data)
            bm.free()
            
            mat = self._create_metal_material(f"mat_{name}", dark=True)
            mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.25, 0.30, 0.20, 1.0)
            body.data.materials.append(mat)
            parts.append(body)
            
            # Spoon
            bpy.ops.mesh.primitive_cube_add(size=1)
            spoon = bpy.context.active_object
            spoon.scale = (size * 0.15, size * 0.3, 0.003)
            spoon.location = (size * 0.4, 0, size * 0.3)
            bpy.ops.object.transform_apply(scale=True)
            spoon.data.materials.append(mat)
            parts.append(spoon)
            
            # Pin ring
            bpy.ops.mesh.primitive_torus_add(major_radius=size * 0.15, minor_radius=0.003)
            ring = bpy.context.active_object
            ring.location = (size * 0.5, 0, size * 0.5)
            ring.data.materials.append(mat)
            parts.append(ring)
        
        elif throw_type == "molotov":
            # Bottle
            bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=size * 0.15, depth=size * 0.6)
            bottle = bpy.context.active_object
            bottle.location.z = size * 0.3
            
            # Taper neck
            bm = bmesh.new()
            bm.from_mesh(bottle.data)
            for v in bm.verts:
                if v.co.z > size * 0.15:
                    taper = 1 - (v.co.z - size * 0.15) / (size * 0.15) * 0.6
                    v.co.x *= taper
                    v.co.y *= taper
            bm.to_mesh(bottle.data)
            bm.free()
            
            glass_mat = bpy.data.materials.new(name=f"mat_{name}_glass")
            glass_mat.use_nodes = True
            glass_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.4, 0.25, 0.15, 1.0)
            glass_mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.1
            bottle.data.materials.append(glass_mat)
            parts.append(bottle)
            
            # Rag
            bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=size * 0.08, radius2=size * 0.03, depth=size * 0.15)
            rag = bpy.context.active_object
            rag.location.z = size * 0.65
            
            cloth_mat = bpy.data.materials.new(name=f"mat_{name}_rag")
            cloth_mat.use_nodes = True
            cloth_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.6, 0.55, 0.45, 1.0)
            rag.data.materials.append(cloth_mat)
            parts.append(rag)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_tool_weapon(self, name: str, config: dict, weapon_type: str) -> bpy.types.Object:
        """Create tool weapons (shovel, pickaxe)."""
        length = config["length"]
        grip_length = config["grip_length"]
        head_type = config["head_type"]
        
        parts = []
        
        wood_mat = self._create_wood_material(f"mat_{name}_handle")
        metal_mat = self._create_metal_material(f"mat_{name}_head")
        
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.018, depth=grip_length)
        handle = bpy.context.active_object
        handle.location.z = grip_length / 2
        handle.data.materials.append(wood_mat)
        parts.append(handle)
        
        if head_type == "shovel":
            # Shovel blade
            bpy.ops.mesh.primitive_cube_add(size=1)
            blade = bpy.context.active_object
            blade.scale = (0.15, 0.003, 0.2)
            blade.location = (0, 0, grip_length + 0.1)
            blade.rotation_euler.x = math.radians(25)
            bpy.ops.object.transform_apply(scale=True, rotation=True)
            
            # Round the blade
            bm = bmesh.new()
            bm.from_mesh(blade.data)
            for v in bm.verts:
                if v.co.z < 0:
                    dist = abs(v.co.x)
                    v.co.z -= dist * 0.5
            bm.to_mesh(blade.data)
            bm.free()
            
            blade.data.materials.append(metal_mat)
            parts.append(blade)
        
        elif head_type == "pick":
            # Pickaxe head
            bpy.ops.mesh.primitive_cube_add(size=1)
            head = bpy.context.active_object
            head.scale = (0.25, 0.015, 0.035)
            head.location = (0, 0, grip_length + 0.02)
            bpy.ops.object.transform_apply(scale=True)
            
            # Taper to points
            bm = bmesh.new()
            bm.from_mesh(head.data)
            for v in bm.verts:
                if abs(v.co.x) > 0.1:
                    taper = (abs(v.co.x) - 0.1) / 0.15
                    v.co.z *= 1 - taper * 0.7
                    v.co.y *= 1 - taper * 0.5
            bm.to_mesh(head.data)
            bm.free()
            
            head.data.materials.append(metal_mat)
            parts.append(head)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_basic_weapon(self, name: str, config: dict) -> bpy.types.Object:
        """Create a basic weapon as fallback."""
        length = config.get("length", 0.5)
        
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.02, depth=length)
        weapon = bpy.context.active_object
        
        mat = self._create_metal_material(f"mat_{name}")
        weapon.data.materials.append(mat)
        
        return weapon
    
    def _create_grip_tape(self, length: float, radius: float) -> bpy.types.Object:
        """Create grip tape wrapping."""
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=length)
        tape = bpy.context.active_object
        return tape
    
    # === MATERIALS ===
    
    def _create_wood_material(self, name: str) -> bpy.types.Material:
        """Create wood material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        
        bsdf = nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = (0.45, 0.28, 0.15, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.7
        
        return mat
    
    def _create_metal_material(self, name: str, dark: bool = False) -> bpy.types.Material:
        """Create metal material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        
        bsdf = nodes["Principled BSDF"]
        if dark:
            bsdf.inputs["Base Color"].default_value = (0.08, 0.08, 0.08, 1.0)
        else:
            bsdf.inputs["Base Color"].default_value = (0.4, 0.42, 0.45, 1.0)
        bsdf.inputs["Metallic"].default_value = 0.9
        bsdf.inputs["Roughness"].default_value = 0.35
        
        return mat
    
    def _create_blade_material(self, name: str) -> bpy.types.Material:
        """Create shiny blade material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        
        bsdf = nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = (0.7, 0.72, 0.75, 1.0)
        bsdf.inputs["Metallic"].default_value = 1.0
        bsdf.inputs["Roughness"].default_value = 0.15
        
        return mat
    
    def _create_grip_material(self, name: str) -> bpy.types.Material:
        """Create grip/rubber material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        
        bsdf = nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = (0.05, 0.05, 0.05, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.85
        
        return mat
    
    def _set_origin_to_center(self, obj: bpy.types.Object) -> None:
        """Set origin to center (for weapons held in hand)."""
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_MASS')
        obj.location = (0.0, 0.0, 0.0)
