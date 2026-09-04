"""
Detailed Weapon Generator - Creates high-quality weapon models
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector


class WeaponGenerator:
    """Generate detailed weapon models for Godot Survival Prototype."""
    
    # Weapon configurations
    MELEE_WEAPONS = {
        "fists": {"type": "unarmed", "size": 0.1, "damage": 5},
        "wood_club": {"type": "blunt", "size": 0.5, "damage": 12},
        "stone_knife": {"type": "blade", "size": 0.25, "damage": 15},
        "makeshift_spear": {"type": "polearm", "size": 1.2, "damage": 18},
        "baseball_bat": {"type": "blunt", "size": 0.8, "damage": 22},
        "machete": {"type": "blade", "size": 0.55, "damage": 28},
        "crowbar": {"type": "blunt", "size": 0.6, "damage": 25},
        "fire_axe": {"type": "axe", "size": 0.9, "damage": 35},
        "katana": {"type": "blade", "size": 0.9, "damage": 45},
        "sledgehammer": {"type": "blunt", "size": 1.1, "damage": 50},
        "spiked_bat": {"type": "blunt", "size": 0.85, "damage": 32},
        "combat_knife": {"type": "blade", "size": 0.3, "damage": 25},
    }
    
    RANGED_WEAPONS = {
        "makeshift_bow": {"type": "bow", "size": 0.8, "damage": 15},
        "slingshot": {"type": "sling", "size": 0.25, "damage": 8},
        "hunting_bow": {"type": "bow", "size": 1.0, "damage": 25},
        "crossbow": {"type": "crossbow", "size": 0.7, "damage": 35},
        "compound_bow": {"type": "bow", "size": 0.9, "damage": 40},
        "pistol": {"type": "handgun", "size": 0.2, "damage": 22},
        "revolver": {"type": "handgun", "size": 0.25, "damage": 35},
        "shotgun": {"type": "shotgun", "size": 0.9, "damage": 55},
        "rifle": {"type": "rifle", "size": 1.0, "damage": 45},
        "auto_pistol": {"type": "handgun", "size": 0.22, "damage": 18},
        "assault_rifle": {"type": "rifle", "size": 0.85, "damage": 38},
        "sniper_rifle": {"type": "rifle", "size": 1.2, "damage": 85},
        "smg": {"type": "smg", "size": 0.5, "damage": 20},
    }
    
    THROWABLES = {
        "grenade": {"type": "explosive", "size": 0.08, "damage": 100},
        "molotov": {"type": "fire", "size": 0.25, "damage": 40},
        "throwing_knife": {"type": "blade", "size": 0.2, "damage": 30},
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate_melee(self, name: str, weapon_id: str) -> bpy.types.Object:
        """Generate a melee weapon."""
        config = self.MELEE_WEAPONS.get(weapon_id, {"type": "blunt", "size": 0.5})
        weapon_type = config["type"]
        size = config["size"]
        
        if weapon_type == "blade":
            return self._create_blade_weapon(name, size, weapon_id)
        elif weapon_type == "axe":
            return self._create_axe_weapon(name, size)
        elif weapon_type == "polearm":
            return self._create_polearm_weapon(name, size, weapon_id)
        else:  # blunt
            return self._create_blunt_weapon(name, size, weapon_id)
    
    def generate_ranged(self, name: str, weapon_id: str) -> bpy.types.Object:
        """Generate a ranged weapon."""
        config = self.RANGED_WEAPONS.get(weapon_id, {"type": "rifle", "size": 1.0})
        weapon_type = config["type"]
        size = config["size"]
        
        if weapon_type == "bow":
            return self._create_bow_weapon(name, size, weapon_id)
        elif weapon_type == "crossbow":
            return self._create_crossbow_weapon(name, size)
        elif weapon_type == "handgun":
            return self._create_handgun_weapon(name, size, weapon_id)
        elif weapon_type == "shotgun":
            return self._create_shotgun_weapon(name, size)
        elif weapon_type == "smg":
            return self._create_smg_weapon(name, size)
        else:  # rifle
            return self._create_rifle_weapon(name, size, weapon_id)
    
    def generate_throwable(self, name: str, weapon_id: str) -> bpy.types.Object:
        """Generate a throwable weapon."""
        config = self.THROWABLES.get(weapon_id, {"type": "explosive", "size": 0.1})
        
        if weapon_id == "grenade":
            return self._create_grenade(name)
        elif weapon_id == "molotov":
            return self._create_molotov(name)
        else:
            return self._create_throwing_knife(name)
    
    # ========================================================================
    # MATERIAL CREATION
    # ========================================================================
    
    def _create_metal_material(self, name: str, color=(0.3, 0.3, 0.35), worn=0.0):
        """Create metal material with optional wear."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (400, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (200, 0)
        
        # Adjust color for wear
        worn_color = tuple(c + worn * 0.15 for c in color)
        bsdf.inputs["Base Color"].default_value = (*worn_color, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.3 + worn * 0.4
        bsdf.inputs["Metallic"].default_value = 0.9 - worn * 0.2
        
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_wood_material(self, name: str, color=(0.35, 0.25, 0.15)):
        """Create wood material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (600, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (300, 0)
        bsdf.inputs["Roughness"].default_value = 0.65
        
        # Wood grain with noise
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-200, 0)
        noise.inputs["Scale"].default_value = 20.0
        noise.inputs["Detail"].default_value = 3.0
        
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (0, 0)
        ramp.color_ramp.elements[0].color = (*color, 1.0)
        darker = tuple(c * 0.6 for c in color)
        ramp.color_ramp.elements[1].color = (*darker, 1.0)
        
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_rubber_material(self, name: str, color=(0.08, 0.08, 0.1)):
        """Create rubber/grip material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.85
        
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_glass_material(self, name: str):
        """Create glass material."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        
        bsdf.inputs["Base Color"].default_value = (0.8, 0.9, 0.8, 0.3)
        bsdf.inputs["Roughness"].default_value = 0.1
        bsdf.inputs["Transmission Weight"].default_value = 0.9
        
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        mat.blend_method = 'BLEND'
        
        return mat
    
    # ========================================================================
    # MELEE WEAPONS
    # ========================================================================
    
    def _create_blade_weapon(self, name: str, size: float, weapon_id: str):
        """Create bladed melee weapon (knife, machete, katana)."""
        parts = []
        
        blade_mat = self._create_metal_material(f"{name}_blade", (0.6, 0.6, 0.65))
        handle_mat = self._create_wood_material(f"{name}_handle")
        guard_mat = self._create_metal_material(f"{name}_guard", (0.25, 0.25, 0.28))
        
        # Blade
        blade_length = size * 0.7
        blade_width = size * 0.08 if weapon_id != "katana" else size * 0.05
        
        bpy.ops.mesh.primitive_cube_add(
            size=blade_length,
            location=(0, 0, blade_length / 2 + size * 0.2)
        )
        blade = bpy.context.active_object
        blade.scale = (0.02, blade_width / blade_length, 1.0)
        
        # Taper blade tip
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(blade.data)
        for v in bm.verts:
            if v.co.z > 0.3:
                factor = (v.co.z - 0.3) / 0.2
                v.co.y *= max(0.2, 1 - factor * 0.8)
        bmesh.update_edit_mesh(blade.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        blade.data.materials.append(blade_mat)
        parts.append(blade)
        
        # Fuller (groove in blade) for katana
        if weapon_id == "katana":
            bpy.ops.mesh.primitive_cube_add(
                size=blade_length * 0.8,
                location=(0.008, 0, blade_length / 2 + size * 0.22)
            )
            fuller = bpy.context.active_object
            fuller.scale = (0.003, 0.01, 1.0)
            fuller.data.materials.append(guard_mat)
            parts.append(fuller)
        
        # Guard
        guard_size = 0.04 if weapon_id == "combat_knife" else 0.08
        bpy.ops.mesh.primitive_cube_add(
            size=guard_size,
            location=(0, 0, size * 0.18)
        )
        guard = bpy.context.active_object
        guard.scale = (0.3, 2.0, 0.4)
        guard.data.materials.append(guard_mat)
        parts.append(guard)
        
        # Handle
        handle_length = size * 0.18
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=0.018,
            depth=handle_length,
            location=(0, 0, handle_length / 2)
        )
        handle = bpy.context.active_object
        handle.data.materials.append(handle_mat)
        parts.append(handle)
        
        # Handle wrapping for katana
        if weapon_id == "katana":
            for i in range(5):
                z = 0.02 + i * 0.03
                bpy.ops.mesh.primitive_torus_add(
                    major_radius=0.02,
                    minor_radius=0.003,
                    location=(0, 0, z)
                )
                wrap = bpy.context.active_object
                wrap.data.materials.append(guard_mat)
                parts.append(wrap)
        
        # Pommel
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.015,
            location=(0, 0, -0.01)
        )
        pommel = bpy.context.active_object
        pommel.data.materials.append(guard_mat)
        parts.append(pommel)
        
        return self._join_parts(parts, name)
    
    def _create_blunt_weapon(self, name: str, size: float, weapon_id: str):
        """Create blunt melee weapon (bat, club, crowbar)."""
        parts = []
        
        if weapon_id == "crowbar":
            mat = self._create_metal_material(f"{name}_metal", (0.3, 0.1, 0.1), worn=0.3)
        elif weapon_id == "wood_club":
            mat = self._create_wood_material(f"{name}_wood", (0.4, 0.28, 0.18))
        else:
            mat = self._create_wood_material(f"{name}_wood")
        
        spike_mat = self._create_metal_material(f"{name}_spike", worn=0.4)
        
        if weapon_id == "crowbar":
            # Main shaft
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6,
                radius=0.015,
                depth=size * 0.85,
                location=(0, 0, size * 0.4)
            )
            shaft = bpy.context.active_object
            shaft.data.materials.append(mat)
            parts.append(shaft)
            
            # Curved end
            bpy.ops.mesh.primitive_torus_add(
                major_radius=0.05,
                minor_radius=0.015,
                major_segments=8,
                minor_segments=6,
                location=(0, 0, size * 0.85)
            )
            curve = bpy.context.active_object
            curve.scale.y = 0.3
            curve.rotation_euler.x = math.radians(90)
            curve.data.materials.append(mat)
            parts.append(curve)
            
            # Flat end
            bpy.ops.mesh.primitive_cube_add(
                size=0.04,
                location=(0, 0, 0)
            )
            flat = bpy.context.active_object
            flat.scale = (0.5, 1.5, 0.3)
            flat.data.materials.append(mat)
            parts.append(flat)
            
        else:
            # Main body
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=10,
                radius=0.025 if weapon_id != "sledgehammer" else 0.02,
                depth=size * 0.8,
                location=(0, 0, size * 0.4)
            )
            body = bpy.context.active_object
            
            # Taper for bat
            if "bat" in weapon_id:
                bpy.ops.object.mode_set(mode='EDIT')
                bm = bmesh.from_edit_mesh(body.data)
                for v in bm.verts:
                    factor = 1 + v.co.z * 0.8
                    v.co.x *= factor
                    v.co.y *= factor
                bmesh.update_edit_mesh(body.data)
                bpy.ops.object.mode_set(mode='OBJECT')
            
            body.data.materials.append(mat)
            parts.append(body)
            
            # Handle (grip area)
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=8,
                radius=0.018,
                depth=size * 0.25,
                location=(0, 0, 0.05)
            )
            handle = bpy.context.active_object
            handle.data.materials.append(mat)
            parts.append(handle)
            
            # Spikes for spiked bat
            if weapon_id == "spiked_bat":
                for i in range(12):
                    angle = i * (2 * math.pi / 6)
                    z = 0.4 + (i % 2) * 0.15
                    
                    bpy.ops.mesh.primitive_cone_add(
                        vertices=4,
                        radius1=0.008,
                        radius2=0.0,
                        depth=0.05,
                        location=(
                            math.cos(angle) * 0.04,
                            math.sin(angle) * 0.04,
                            z
                        )
                    )
                    spike = bpy.context.active_object
                    spike.rotation_euler = (
                        math.radians(90) * math.cos(angle),
                        math.radians(90) * math.sin(angle),
                        0
                    )
                    spike.data.materials.append(spike_mat)
                    parts.append(spike)
            
            # Sledgehammer head
            if weapon_id == "sledgehammer":
                bpy.ops.mesh.primitive_cube_add(
                    size=0.12,
                    location=(0, 0, size * 0.85)
                )
                head = bpy.context.active_object
                head.scale = (0.8, 0.5, 1.2)
                head.data.materials.append(spike_mat)
                parts.append(head)
        
        return self._join_parts(parts, name)
    
    def _create_axe_weapon(self, name: str, size: float):
        """Create axe weapon."""
        parts = []
        
        metal_mat = self._create_metal_material(f"{name}_metal")
        wood_mat = self._create_wood_material(f"{name}_wood")
        
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=0.018,
            depth=size * 0.7,
            location=(0, 0, size * 0.35)
        )
        handle = bpy.context.active_object
        handle.data.materials.append(wood_mat)
        parts.append(handle)
        
        # Axe head
        bpy.ops.mesh.primitive_cube_add(
            size=0.15,
            location=(0, 0.06, size * 0.75)
        )
        head = bpy.context.active_object
        head.scale = (0.15, 1.0, 0.8)
        
        # Shape the blade
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(head.data)
        for v in bm.verts:
            if v.co.y > 0:
                v.co.y *= 1.2  # Extend blade edge
                v.co.x *= 0.3  # Taper edge
        bmesh.update_edit_mesh(head.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        head.data.materials.append(metal_mat)
        parts.append(head)
        
        # Back spike
        bpy.ops.mesh.primitive_cone_add(
            vertices=4,
            radius1=0.02,
            radius2=0.0,
            depth=0.08,
            location=(0, -0.06, size * 0.75)
        )
        spike = bpy.context.active_object
        spike.rotation_euler.x = math.radians(-90)
        spike.data.materials.append(metal_mat)
        parts.append(spike)
        
        return self._join_parts(parts, name)
    
    def _create_polearm_weapon(self, name: str, size: float, weapon_id: str):
        """Create polearm weapon (spear)."""
        parts = []
        
        wood_mat = self._create_wood_material(f"{name}_wood")
        metal_mat = self._create_metal_material(f"{name}_metal")
        
        # Shaft
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=0.015,
            depth=size * 0.9,
            location=(0, 0, size * 0.45)
        )
        shaft = bpy.context.active_object
        shaft.data.materials.append(wood_mat)
        parts.append(shaft)
        
        # Spear head
        bpy.ops.mesh.primitive_cone_add(
            vertices=4,
            radius1=0.025,
            radius2=0.0,
            depth=0.15,
            location=(0, 0, size * 0.95)
        )
        head = bpy.context.active_object
        head.data.materials.append(metal_mat)
        parts.append(head)
        
        # Binding
        for z in [size * 0.88, size * 0.85]:
            bpy.ops.mesh.primitive_torus_add(
                major_radius=0.018,
                minor_radius=0.004,
                location=(0, 0, z)
            )
            binding = bpy.context.active_object
            binding.data.materials.append(metal_mat)
            parts.append(binding)
        
        return self._join_parts(parts, name)
    
    # ========================================================================
    # RANGED WEAPONS
    # ========================================================================
    
    def _create_bow_weapon(self, name: str, size: float, weapon_id: str):
        """Create bow weapon."""
        parts = []
        
        wood_mat = self._create_wood_material(f"{name}_wood")
        string_mat = self._create_rubber_material(f"{name}_string", (0.6, 0.55, 0.5))
        
        # Bow body (curved)
        bpy.ops.mesh.primitive_torus_add(
            major_radius=size * 0.45,
            minor_radius=0.012 if weapon_id != "compound_bow" else 0.015,
            major_segments=24,
            minor_segments=6,
            location=(0, 0, size * 0.5)
        )
        bow = bpy.context.active_object
        bow.scale.x = 0.15
        bow.rotation_euler.x = math.radians(90)
        
        # Cut in half
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(bow.data)
        verts_to_delete = [v for v in bm.verts if v.co.x < 0]
        bmesh.ops.delete(bm, geom=verts_to_delete, context='VERTS')
        bmesh.update_edit_mesh(bow.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        bow.data.materials.append(wood_mat)
        parts.append(bow)
        
        # Grip
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=0.02,
            depth=0.08,
            location=(0, 0, size * 0.5)
        )
        grip = bpy.context.active_object
        grip.data.materials.append(wood_mat)
        parts.append(grip)
        
        # String
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=4,
            radius=0.003,
            depth=size * 0.85,
            location=(-0.05, 0, size * 0.5)
        )
        string = bpy.context.active_object
        string.data.materials.append(string_mat)
        parts.append(string)
        
        # Compound bow additions
        if weapon_id == "compound_bow":
            for z_offset in [0.35, 0.65]:
                bpy.ops.mesh.primitive_cylinder_add(
                    vertices=12,
                    radius=0.025,
                    depth=0.02,
                    location=(0.02, 0, z_offset * size)
                )
                cam = bpy.context.active_object
                cam.rotation_euler.y = math.radians(90)
                cam.data.materials.append(self._create_metal_material(f"{name}_cam"))
                parts.append(cam)
        
        return self._join_parts(parts, name)
    
    def _create_crossbow_weapon(self, name: str, size: float):
        """Create crossbow weapon."""
        parts = []
        
        wood_mat = self._create_wood_material(f"{name}_wood")
        metal_mat = self._create_metal_material(f"{name}_metal")
        string_mat = self._create_rubber_material(f"{name}_string")
        
        # Stock
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.6,
            location=(0, 0, 0)
        )
        stock = bpy.context.active_object
        stock.scale = (0.08, 0.15, 1.0)
        stock.data.materials.append(wood_mat)
        parts.append(stock)
        
        # Rail
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.5,
            location=(0.03, 0, size * 0.15)
        )
        rail = bpy.context.active_object
        rail.scale = (0.1, 0.05, 1.0)
        rail.data.materials.append(metal_mat)
        parts.append(rail)
        
        # Bow limb
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.5,
            location=(0, 0, size * 0.35)
        )
        limb = bpy.context.active_object
        limb.scale = (0.05, 1.0, 0.08)
        limb.rotation_euler.z = math.radians(15)
        limb.data.materials.append(wood_mat)
        parts.append(limb)
        
        # String
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=4,
            radius=0.003,
            depth=size * 0.45,
            location=(0, 0, size * 0.35)
        )
        string = bpy.context.active_object
        string.rotation_euler.x = math.radians(90)
        string.data.materials.append(string_mat)
        parts.append(string)
        
        return self._join_parts(parts, name)
    
    def _create_handgun_weapon(self, name: str, size: float, weapon_id: str):
        """Create handgun weapon."""
        parts = []
        
        metal_mat = self._create_metal_material(f"{name}_metal")
        grip_mat = self._create_rubber_material(f"{name}_grip")
        
        # Slide
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.8,
            location=(size * 0.15, 0, size * 0.15)
        )
        slide = bpy.context.active_object
        slide.scale = (1.0, 0.2, 0.35)
        slide.data.materials.append(metal_mat)
        parts.append(slide)
        
        # Frame
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.6,
            location=(0, 0, 0)
        )
        frame = bpy.context.active_object
        frame.scale = (0.8, 0.18, 0.3)
        frame.data.materials.append(metal_mat)
        parts.append(frame)
        
        # Grip
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.5,
            location=(-size * 0.15, 0, -size * 0.2)
        )
        grip = bpy.context.active_object
        grip.scale = (0.35, 0.2, 0.8)
        grip.rotation_euler.x = math.radians(-15)
        grip.data.materials.append(grip_mat)
        parts.append(grip)
        
        # Barrel
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=0.008,
            depth=size * 0.3,
            location=(size * 0.35, 0, size * 0.15)
        )
        barrel = bpy.context.active_object
        barrel.rotation_euler.y = math.radians(90)
        barrel.data.materials.append(metal_mat)
        parts.append(barrel)
        
        # Magazine
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.35,
            location=(-size * 0.1, 0, -size * 0.15)
        )
        mag = bpy.context.active_object
        mag.scale = (0.25, 0.15, 0.8)
        mag.data.materials.append(metal_mat)
        parts.append(mag)
        
        # Trigger guard
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.02,
            minor_radius=0.003,
            major_segments=8,
            location=(0, 0, -size * 0.02)
        )
        guard = bpy.context.active_object
        guard.scale.y = 0.3
        guard.rotation_euler.x = math.radians(90)
        guard.data.materials.append(metal_mat)
        parts.append(guard)
        
        # Sights
        for x_offset in [-0.02, size * 0.3]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.01,
                location=(x_offset, 0, size * 0.22)
            )
            sight = bpy.context.active_object
            sight.scale = (0.5, 0.3, 1.5)
            sight.data.materials.append(metal_mat)
            parts.append(sight)
        
        return self._join_parts(parts, name)
    
    def _create_rifle_weapon(self, name: str, size: float, weapon_id: str):
        """Create rifle weapon."""
        parts = []
        
        metal_mat = self._create_metal_material(f"{name}_metal")
        wood_mat = self._create_wood_material(f"{name}_wood")
        plastic_mat = self._create_rubber_material(f"{name}_plastic", (0.12, 0.12, 0.15))
        
        is_assault = "assault" in weapon_id
        is_sniper = "sniper" in weapon_id
        
        # Receiver
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.35,
            location=(0, 0, 0)
        )
        receiver = bpy.context.active_object
        receiver.scale = (1.0, 0.2, 0.35)
        receiver.data.materials.append(metal_mat)
        parts.append(receiver)
        
        # Barrel
        barrel_length = size * 0.6 if not is_sniper else size * 0.8
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=0.012 if not is_sniper else 0.015,
            depth=barrel_length,
            location=(size * 0.35, 0, 0.01)
        )
        barrel = bpy.context.active_object
        barrel.rotation_euler.y = math.radians(90)
        barrel.data.materials.append(metal_mat)
        parts.append(barrel)
        
        # Stock
        stock_mat = plastic_mat if is_assault else wood_mat
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.35,
            location=(-size * 0.32, 0, -0.02)
        )
        stock = bpy.context.active_object
        stock.scale = (1.0, 0.18, 0.35)
        stock.data.materials.append(stock_mat)
        parts.append(stock)
        
        # Grip
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.15,
            location=(-size * 0.05, 0, -size * 0.12)
        )
        grip = bpy.context.active_object
        grip.scale = (0.4, 0.2, 1.0)
        grip.rotation_euler.x = math.radians(-20)
        grip.data.materials.append(plastic_mat)
        parts.append(grip)
        
        # Magazine
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.18,
            location=(size * 0.02, 0, -size * 0.15)
        )
        mag = bpy.context.active_object
        mag.scale = (0.3, 0.15, 1.2)
        if is_assault:
            mag.scale.z = 1.5
        mag.data.materials.append(metal_mat)
        parts.append(mag)
        
        # Handguard
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.25,
            location=(size * 0.22, 0, -0.015)
        )
        handguard = bpy.context.active_object
        handguard.scale = (1.0, 0.22, 0.28)
        handguard.data.materials.append(plastic_mat)
        parts.append(handguard)
        
        # Scope for sniper
        if is_sniper:
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=16,
                radius=0.02,
                depth=size * 0.25,
                location=(0, 0, size * 0.08)
            )
            scope = bpy.context.active_object
            scope.rotation_euler.y = math.radians(90)
            scope.data.materials.append(metal_mat)
            parts.append(scope)
            
            # Scope lenses
            for x in [-size * 0.1, size * 0.1]:
                bpy.ops.mesh.primitive_cylinder_add(
                    vertices=16,
                    radius=0.022,
                    depth=0.01,
                    location=(x, 0, size * 0.08)
                )
                lens = bpy.context.active_object
                lens.rotation_euler.y = math.radians(90)
                lens.data.materials.append(self._create_glass_material(f"{name}_lens"))
                parts.append(lens)
        
        return self._join_parts(parts, name)
    
    def _create_shotgun_weapon(self, name: str, size: float):
        """Create shotgun weapon."""
        parts = []
        
        metal_mat = self._create_metal_material(f"{name}_metal", (0.15, 0.15, 0.18))
        wood_mat = self._create_wood_material(f"{name}_wood")
        
        # Barrel(s) - pump action style
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=0.015,
            depth=size * 0.65,
            location=(size * 0.2, 0, 0.02)
        )
        barrel = bpy.context.active_object
        barrel.rotation_euler.y = math.radians(90)
        barrel.data.materials.append(metal_mat)
        parts.append(barrel)
        
        # Magazine tube
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=0.012,
            depth=size * 0.5,
            location=(size * 0.15, 0, -0.02)
        )
        mag_tube = bpy.context.active_object
        mag_tube.rotation_euler.y = math.radians(90)
        mag_tube.data.materials.append(metal_mat)
        parts.append(mag_tube)
        
        # Receiver
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.25,
            location=(-size * 0.05, 0, 0)
        )
        receiver = bpy.context.active_object
        receiver.scale = (1.0, 0.22, 0.35)
        receiver.data.materials.append(metal_mat)
        parts.append(receiver)
        
        # Pump
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.15,
            location=(size * 0.15, 0, -0.025)
        )
        pump = bpy.context.active_object
        pump.scale = (1.0, 0.25, 0.3)
        pump.data.materials.append(wood_mat)
        parts.append(pump)
        
        # Stock
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.35,
            location=(-size * 0.32, 0, -0.02)
        )
        stock = bpy.context.active_object
        stock.scale = (1.0, 0.18, 0.35)
        stock.data.materials.append(wood_mat)
        parts.append(stock)
        
        # Grip
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.12,
            location=(-size * 0.12, 0, -size * 0.1)
        )
        grip = bpy.context.active_object
        grip.scale = (0.35, 0.2, 1.0)
        grip.rotation_euler.x = math.radians(-15)
        grip.data.materials.append(wood_mat)
        parts.append(grip)
        
        return self._join_parts(parts, name)
    
    def _create_smg_weapon(self, name: str, size: float):
        """Create SMG weapon."""
        parts = []
        
        metal_mat = self._create_metal_material(f"{name}_metal")
        plastic_mat = self._create_rubber_material(f"{name}_plastic", (0.1, 0.1, 0.12))
        
        # Receiver
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.5,
            location=(0, 0, 0)
        )
        receiver = bpy.context.active_object
        receiver.scale = (1.0, 0.2, 0.3)
        receiver.data.materials.append(metal_mat)
        parts.append(receiver)
        
        # Barrel with suppressor style
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16,
            radius=0.018,
            depth=size * 0.4,
            location=(size * 0.35, 0, 0)
        )
        barrel = bpy.context.active_object
        barrel.rotation_euler.y = math.radians(90)
        barrel.data.materials.append(metal_mat)
        parts.append(barrel)
        
        # Grip
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.2,
            location=(0, 0, -size * 0.15)
        )
        grip = bpy.context.active_object
        grip.scale = (0.3, 0.2, 1.0)
        grip.data.materials.append(plastic_mat)
        parts.append(grip)
        
        # Magazine
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.25,
            location=(size * 0.05, 0, -size * 0.2)
        )
        mag = bpy.context.active_object
        mag.scale = (0.25, 0.12, 1.3)
        mag.data.materials.append(metal_mat)
        parts.append(mag)
        
        # Folding stock
        bpy.ops.mesh.primitive_cube_add(
            size=size * 0.15,
            location=(-size * 0.2, 0, 0.02)
        )
        stock = bpy.context.active_object
        stock.scale = (1.0, 0.08, 0.15)
        stock.data.materials.append(metal_mat)
        parts.append(stock)
        
        return self._join_parts(parts, name)
    
    # ========================================================================
    # THROWABLES
    # ========================================================================
    
    def _create_grenade(self, name: str):
        """Create grenade model."""
        parts = []
        
        metal_mat = self._create_metal_material(f"{name}_metal", (0.25, 0.28, 0.22))
        
        # Body
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16,
            radius=0.03,
            depth=0.08,
            location=(0, 0, 0.04)
        )
        body = bpy.context.active_object
        body.data.materials.append(metal_mat)
        parts.append(body)
        
        # Top cap
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16,
            radius=0.025,
            depth=0.015,
            location=(0, 0, 0.085)
        )
        cap = bpy.context.active_object
        cap.data.materials.append(metal_mat)
        parts.append(cap)
        
        # Spoon
        bpy.ops.mesh.primitive_cube_add(
            size=0.06,
            location=(0.025, 0, 0.06)
        )
        spoon = bpy.context.active_object
        spoon.scale = (0.8, 0.15, 0.4)
        spoon.data.materials.append(metal_mat)
        parts.append(spoon)
        
        # Pin ring
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.012,
            minor_radius=0.003,
            location=(0, 0.025, 0.085)
        )
        ring = bpy.context.active_object
        ring.rotation_euler.x = math.radians(90)
        ring.data.materials.append(metal_mat)
        parts.append(ring)
        
        return self._join_parts(parts, name)
    
    def _create_molotov(self, name: str):
        """Create molotov cocktail model."""
        parts = []
        
        glass_mat = self._create_glass_material(f"{name}_glass")
        cloth_mat = self._create_wood_material(f"{name}_rag", (0.5, 0.4, 0.3))
        
        # Bottle body
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=0.035,
            depth=0.15,
            location=(0, 0, 0.075)
        )
        body = bpy.context.active_object
        body.data.materials.append(glass_mat)
        parts.append(body)
        
        # Bottle neck
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=0.015,
            depth=0.05,
            location=(0, 0, 0.175)
        )
        neck = bpy.context.active_object
        neck.data.materials.append(glass_mat)
        parts.append(neck)
        
        # Rag
        bpy.ops.mesh.primitive_cone_add(
            vertices=6,
            radius1=0.025,
            radius2=0.01,
            depth=0.04,
            location=(0, 0, 0.22)
        )
        rag = bpy.context.active_object
        rag.data.materials.append(cloth_mat)
        parts.append(rag)
        
        return self._join_parts(parts, name)
    
    def _create_throwing_knife(self, name: str):
        """Create throwing knife model."""
        parts = []
        
        metal_mat = self._create_metal_material(f"{name}_metal", (0.5, 0.5, 0.55))
        
        # Blade
        bpy.ops.mesh.primitive_cone_add(
            vertices=4,
            radius1=0.015,
            radius2=0.0,
            depth=0.12,
            location=(0, 0, 0.08)
        )
        blade = bpy.context.active_object
        blade.scale.x = 0.3
        blade.data.materials.append(metal_mat)
        parts.append(blade)
        
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=0.01,
            depth=0.05,
            location=(0, 0, 0)
        )
        handle = bpy.context.active_object
        handle.data.materials.append(metal_mat)
        parts.append(handle)
        
        return self._join_parts(parts, name)
    
    # ========================================================================
    # UTILITY
    # ========================================================================
    
    def _join_parts(self, parts: list, name: str):
        """Join all parts into a single object."""
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        weapon = bpy.context.active_object
        weapon.name = name
        
        # Apply flat shading
        for p in weapon.data.polygons:
            p.use_smooth = False
        
        return weapon


def generate_all_weapons():
    """Generate all weapon variants."""
    generator = WeaponGenerator()
    
    weapons = []
    x_offset = 0
    
    # Melee weapons
    for weapon_id in generator.MELEE_WEAPONS.keys():
        weapon = generator.generate_melee(f"melee_{weapon_id}", weapon_id)
        weapon.location.x = x_offset
        weapons.append(weapon)
        x_offset += 0.8
    
    x_offset += 1
    
    # Ranged weapons
    for weapon_id in generator.RANGED_WEAPONS.keys():
        weapon = generator.generate_ranged(f"ranged_{weapon_id}", weapon_id)
        weapon.location.x = x_offset
        weapons.append(weapon)
        x_offset += 1.2
    
    x_offset += 1
    
    # Throwables
    for weapon_id in generator.THROWABLES.keys():
        weapon = generator.generate_throwable(f"throw_{weapon_id}", weapon_id)
        weapon.location.x = x_offset
        weapons.append(weapon)
        x_offset += 0.3
    
    return weapons


if __name__ == "__main__":
    generate_all_weapons()
