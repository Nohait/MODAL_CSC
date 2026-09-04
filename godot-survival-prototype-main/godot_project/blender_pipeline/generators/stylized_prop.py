"""
Stylized Prop Generator
=======================
Creates detailed low-poly props, weapons, and tools for survival game.
Each prop has proper proportions and multi-material support.
"""

import bpy
import bmesh
import math
from mathutils import Vector

class StylizedPropGenerator:
    """Generates stylized low-poly props with detail."""
    
    PROP_CONFIGS = {
        # === MELEE WEAPONS ===
        'hatchet': {
            'category': 'weapon_melee',
            'parts': [
                {'type': 'handle', 'length': 0.4, 'radius': 0.02, 'material': 'wood'},
                {'type': 'axe_head', 'width': 0.15, 'height': 0.12, 'depth': 0.03, 'material': 'metal'},
            ],
        },
        'pickaxe': {
            'category': 'weapon_melee',
            'parts': [
                {'type': 'handle', 'length': 0.5, 'radius': 0.02, 'material': 'wood'},
                {'type': 'pickaxe_head', 'width': 0.25, 'height': 0.06, 'depth': 0.04, 'material': 'metal'},
            ],
        },
        'machete': {
            'category': 'weapon_melee',
            'parts': [
                {'type': 'handle', 'length': 0.12, 'radius': 0.018, 'material': 'wood'},
                {'type': 'blade', 'length': 0.35, 'width': 0.05, 'thickness': 0.005, 'material': 'metal'},
            ],
        },
        'baseball_bat': {
            'category': 'weapon_melee',
            'parts': [
                {'type': 'bat', 'length': 0.75, 'handle_radius': 0.02, 'head_radius': 0.04, 'material': 'wood'},
            ],
        },
        'crowbar': {
            'category': 'weapon_melee',
            'parts': [
                {'type': 'crowbar', 'length': 0.6, 'radius': 0.015, 'material': 'metal_red'},
            ],
        },
        'knife': {
            'category': 'weapon_melee',
            'parts': [
                {'type': 'handle', 'length': 0.1, 'radius': 0.015, 'material': 'wood'},
                {'type': 'blade', 'length': 0.15, 'width': 0.025, 'thickness': 0.003, 'material': 'metal'},
            ],
        },
        'spear': {
            'category': 'weapon_melee',
            'parts': [
                {'type': 'handle', 'length': 1.4, 'radius': 0.02, 'material': 'wood'},
                {'type': 'spear_point', 'length': 0.2, 'width': 0.05, 'material': 'metal'},
            ],
        },
        
        # === RANGED WEAPONS ===
        'bow': {
            'category': 'weapon_ranged',
            'parts': [
                {'type': 'bow', 'height': 0.9, 'width': 0.04, 'material': 'wood'},
                {'type': 'bowstring', 'height': 0.85, 'material': 'rope'},
            ],
        },
        'crossbow': {
            'category': 'weapon_ranged',
            'parts': [
                {'type': 'crossbow_body', 'length': 0.5, 'material': 'wood'},
                {'type': 'crossbow_arms', 'width': 0.45, 'material': 'metal'},
            ],
        },
        
        # === TOOLS ===
        'hammer': {
            'category': 'tool',
            'parts': [
                {'type': 'handle', 'length': 0.3, 'radius': 0.018, 'material': 'wood'},
                {'type': 'hammer_head', 'width': 0.1, 'height': 0.05, 'material': 'metal'},
            ],
        },
        'shovel': {
            'category': 'tool',
            'parts': [
                {'type': 'handle', 'length': 0.9, 'radius': 0.02, 'material': 'wood'},
                {'type': 'shovel_head', 'width': 0.18, 'height': 0.22, 'material': 'metal'},
            ],
        },
        'wrench': {
            'category': 'tool',
            'parts': [
                {'type': 'wrench', 'length': 0.25, 'width': 0.06, 'material': 'metal'},
            ],
        },
        
        # === RESOURCES ===
        'wood_log': {
            'category': 'resource',
            'parts': [
                {'type': 'log', 'length': 0.5, 'radius': 0.08, 'material': 'wood_bark'},
                {'type': 'log_rings', 'radius': 0.075, 'material': 'wood'},
            ],
        },
        'wood_plank': {
            'category': 'resource',
            'parts': [
                {'type': 'plank', 'length': 0.6, 'width': 0.15, 'height': 0.03, 'material': 'wood'},
            ],
        },
        'stone': {
            'category': 'resource',
            'parts': [
                {'type': 'rock', 'size': 0.2, 'material': 'stone'},
            ],
        },
        'iron_ore': {
            'category': 'resource',
            'parts': [
                {'type': 'ore', 'size': 0.15, 'material': 'iron_ore'},
            ],
        },
        'fiber_bundle': {
            'category': 'resource',
            'parts': [
                {'type': 'fiber_bundle', 'size': 0.12, 'material': 'fiber'},
            ],
        },
        
        # === CONTAINERS ===
        'crate': {
            'category': 'container',
            'parts': [
                {'type': 'crate', 'size': 0.5, 'material': 'wood'},
            ],
        },
        'barrel': {
            'category': 'container',
            'parts': [
                {'type': 'barrel', 'height': 0.7, 'radius': 0.25, 'material': 'metal'},
            ],
        },
        'chest': {
            'category': 'container',
            'parts': [
                {'type': 'chest_base', 'width': 0.5, 'height': 0.3, 'depth': 0.35, 'material': 'wood'},
                {'type': 'chest_lid', 'width': 0.5, 'height': 0.15, 'depth': 0.35, 'material': 'wood'},
                {'type': 'chest_lock', 'material': 'metal'},
            ],
        },
        'backpack': {
            'category': 'container',
            'parts': [
                {'type': 'backpack', 'width': 0.3, 'height': 0.45, 'depth': 0.15, 'material': 'fabric_green'},
            ],
        },
    }
    
    MATERIALS = {
        'wood': (0.55, 0.35, 0.18, 1.0),
        'wood_bark': (0.30, 0.20, 0.10, 1.0),
        'metal': (0.6, 0.6, 0.65, 1.0),
        'metal_red': (0.6, 0.15, 0.12, 1.0),
        'stone': (0.5, 0.48, 0.45, 1.0),
        'iron_ore': (0.45, 0.35, 0.30, 1.0),
        'fiber': (0.7, 0.75, 0.5, 1.0),
        'rope': (0.65, 0.55, 0.40, 1.0),
        'fabric_green': (0.25, 0.35, 0.20, 1.0),
        'leather': (0.45, 0.30, 0.18, 1.0),
    }
    
    def __init__(self, prop_type='hatchet'):
        self.prop_type = prop_type
        self.config = self.PROP_CONFIGS.get(prop_type, self.PROP_CONFIGS['hatchet'])
        self.materials_cache = {}
    
    def get_material(self, mat_name):
        """Get or create a material."""
        if mat_name in self.materials_cache:
            return self.materials_cache[mat_name]
        
        color = self.MATERIALS.get(mat_name, (0.5, 0.5, 0.5, 1.0))
        mat = bpy.data.materials.new(name=f"prop_{mat_name}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = color
        
        # Metal materials get lower roughness
        if 'metal' in mat_name:
            bsdf.inputs["Roughness"].default_value = 0.4
            bsdf.inputs["Metallic"].default_value = 0.8
        else:
            bsdf.inputs["Roughness"].default_value = 0.7
        
        self.materials_cache[mat_name] = mat
        return mat
    
    def create_handle(self, part):
        """Create a cylindrical handle."""
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=part['radius'],
            depth=part['length'],
            location=(0, 0, part['length'] / 2)
        )
        handle = bpy.context.active_object
        handle.data.materials.append(self.get_material(part['material']))
        return handle, Vector((0, 0, part['length']))
    
    def create_axe_head(self, part, attach_point):
        """Create an axe head."""
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(part['width']/2, 0, attach_point.z)
        )
        head = bpy.context.active_object
        head.scale = (part['width'], part['depth'], part['height'])
        bpy.ops.object.transform_apply(scale=True)
        
        # Bevel the cutting edge
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(head.data)
        
        # Scale front edge to create blade shape
        for v in bm.verts:
            if v.co.x > part['width'] * 0.3:
                v.co.z *= 1.3  # Extend blade height
                v.co.y *= 0.3  # Thin the edge
        
        bmesh.update_edit_mesh(head.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        head.data.materials.append(self.get_material(part['material']))
        return head
    
    def create_pickaxe_head(self, part, attach_point):
        """Create a pickaxe head (double-pointed)."""
        parts = []
        
        # Center piece
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=part['height'] / 2,
            depth=part['depth'] * 2,
            location=(0, 0, attach_point.z)
        )
        center = bpy.context.active_object
        center.rotation_euler.x = math.pi / 2
        bpy.ops.object.transform_apply(rotation=True)
        parts.append(center)
        
        # Two points
        for side in [-1, 1]:
            bpy.ops.mesh.primitive_cone_add(
                vertices=6,
                radius1=part['height'] / 2,
                radius2=0.005,
                depth=part['width'] / 2,
                location=(side * part['width'] / 4, 0, attach_point.z)
            )
            point = bpy.context.active_object
            point.rotation_euler.y = side * math.pi / 2
            bpy.ops.object.transform_apply(rotation=True)
            parts.append(point)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for p in parts:
            p.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        head = bpy.context.active_object
        head.data.materials.append(self.get_material(part['material']))
        return head
    
    def create_blade(self, part, attach_point):
        """Create a flat blade (for machete, knife)."""
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, attach_point.z + part['length'] / 2)
        )
        blade = bpy.context.active_object
        blade.scale = (part['thickness'], part['width'], part['length'])
        bpy.ops.object.transform_apply(scale=True)
        
        # Sharpen one edge
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(blade.data)
        for v in bm.verts:
            if v.co.y > 0:  # Front edge
                v.co.x *= 0.2  # Thin it
            # Taper to point
            if v.co.z > part['length'] * 0.3:
                taper = 1 - (v.co.z / part['length']) * 0.5
                v.co.y *= taper
        bmesh.update_edit_mesh(blade.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        blade.data.materials.append(self.get_material(part['material']))
        return blade
    
    def create_bat(self, part):
        """Create a baseball bat shape."""
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10,
            radius=part['head_radius'],
            depth=part['length'],
            location=(0, 0, part['length'] / 2)
        )
        bat = bpy.context.active_object
        
        # Taper handle end
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(bat.data)
        for v in bm.verts:
            t = v.co.z / part['length']  # 0 at bottom, 1 at top
            if t < 0.4:  # Handle region
                scale = part['handle_radius'] / part['head_radius']
                scale += (1 - scale) * (t / 0.4)
                v.co.x *= scale
                v.co.y *= scale
        bmesh.update_edit_mesh(bat.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        bat.data.materials.append(self.get_material(part['material']))
        return bat, Vector((0, 0, part['length']))
    
    def create_crowbar(self, part):
        """Create a crowbar with curved ends."""
        segments = []
        
        # Main shaft
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=part['radius'],
            depth=part['length'] * 0.7,
            location=(0, 0, part['length'] * 0.35)
        )
        segments.append(bpy.context.active_object)
        
        # Curved hook end (top)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=part['radius'],
            depth=part['length'] * 0.15,
            location=(part['length'] * 0.08, 0, part['length'] * 0.78)
        )
        hook = bpy.context.active_object
        hook.rotation_euler.y = math.pi / 4
        bpy.ops.object.transform_apply(rotation=True)
        segments.append(hook)
        
        # Flat pry end (bottom)
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, -part['length'] * 0.08)
        )
        pry = bpy.context.active_object
        pry.scale = (part['radius'] * 0.5, part['radius'] * 3, part['length'] * 0.12)
        bpy.ops.object.transform_apply(scale=True)
        segments.append(pry)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for s in segments:
            s.select_set(True)
        bpy.context.view_layer.objects.active = segments[0]
        bpy.ops.object.join()
        
        crowbar = bpy.context.active_object
        crowbar.data.materials.append(self.get_material(part['material']))
        return crowbar, Vector((0, 0, part['length']))
    
    def create_hammer_head(self, part, attach_point):
        """Create a hammer head."""
        # Main block
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, attach_point.z)
        )
        head = bpy.context.active_object
        head.scale = (part['width'], part['height'] * 0.8, part['height'])
        bpy.ops.object.transform_apply(scale=True)
        
        head.data.materials.append(self.get_material(part['material']))
        return head
    
    def create_shovel_head(self, part, attach_point):
        """Create a shovel head."""
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, part['height'] * 0.4, attach_point.z)
        )
        head = bpy.context.active_object
        head.scale = (0.02, part['height'], part['width'])
        bpy.ops.object.transform_apply(scale=True)
        
        # Curve it slightly
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(head.data)
        for v in bm.verts:
            curve = v.co.y * 0.15  # Curve based on Y position
            v.co.x -= abs(curve)
        bmesh.update_edit_mesh(head.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        head.data.materials.append(self.get_material(part['material']))
        return head
    
    def create_log(self, part):
        """Create a wood log."""
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=part['radius'],
            depth=part['length'],
            location=(0, 0, part['radius'])
        )
        log = bpy.context.active_object
        log.rotation_euler.y = math.pi / 2
        bpy.ops.object.transform_apply(rotation=True)
        
        log.data.materials.append(self.get_material(part['material']))
        return log, Vector((0, 0, part['radius'] * 2))
    
    def create_log_rings(self, part):
        """Create log end rings (visible wood grain)."""
        bpy.ops.mesh.primitive_circle_add(
            vertices=12,
            radius=part['radius'],
            fill_type='NGON',
            location=(0, 0, 0)
        )
        ring = bpy.context.active_object
        ring.data.materials.append(self.get_material(part['material']))
        return ring
    
    def create_plank(self, part):
        """Create a wooden plank."""
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, part['height'] / 2)
        )
        plank = bpy.context.active_object
        plank.scale = (part['width'], part['length'], part['height'])
        bpy.ops.object.transform_apply(scale=True)
        
        plank.data.materials.append(self.get_material(part['material']))
        return plank, Vector((0, 0, part['height']))
    
    def create_rock(self, part):
        """Create an irregular rock shape."""
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2,
            radius=part['size'],
            location=(0, 0, part['size'] * 0.7)
        )
        rock = bpy.context.active_object
        
        # Make it irregular
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(rock.data)
        import random
        random.seed(42)
        for v in bm.verts:
            v.co += Vector((
                random.uniform(-0.15, 0.15) * part['size'],
                random.uniform(-0.15, 0.15) * part['size'],
                random.uniform(-0.1, 0.1) * part['size']
            ))
        bmesh.update_edit_mesh(rock.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        rock.scale.z = 0.7
        bpy.ops.object.transform_apply(scale=True)
        
        rock.data.materials.append(self.get_material(part['material']))
        return rock, Vector((0, 0, part['size']))
    
    def create_ore(self, part):
        """Create ore chunk with crystal-like protrusions."""
        parts = []
        
        # Base rock
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1,
            radius=part['size'],
            location=(0, 0, part['size'] * 0.8)
        )
        base = bpy.context.active_object
        parts.append(base)
        
        # Crystal protrusions
        import random
        random.seed(123)
        for _ in range(4):
            bpy.ops.mesh.primitive_cone_add(
                vertices=5,
                radius1=part['size'] * 0.2,
                radius2=0,
                depth=part['size'] * 0.4,
                location=(
                    random.uniform(-0.5, 0.5) * part['size'],
                    random.uniform(-0.5, 0.5) * part['size'],
                    part['size'] + random.uniform(0, 0.3) * part['size']
                )
            )
            crystal = bpy.context.active_object
            crystal.rotation_euler = (
                random.uniform(-0.5, 0.5),
                random.uniform(-0.5, 0.5),
                random.uniform(0, 6.28)
            )
            parts.append(crystal)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for p in parts:
            p.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        ore = bpy.context.active_object
        ore.data.materials.append(self.get_material(part['material']))
        return ore, Vector((0, 0, part['size']))
    
    def create_crate(self, part):
        """Create a wooden crate with plank details."""
        size = part['size']
        
        # Main box
        bpy.ops.mesh.primitive_cube_add(
            size=size,
            location=(0, 0, size / 2)
        )
        crate = bpy.context.active_object
        
        crate.data.materials.append(self.get_material(part['material']))
        return crate, Vector((0, 0, size))
    
    def create_barrel(self, part):
        """Create a barrel with bulge."""
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16,
            radius=part['radius'],
            depth=part['height'],
            location=(0, 0, part['height'] / 2)
        )
        barrel = bpy.context.active_object
        
        # Add bulge in middle
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(barrel.data)
        for v in bm.verts:
            t = abs(v.co.z) / (part['height'] / 2)  # 0 at middle, 1 at ends
            bulge = 1 + (1 - t) * 0.15  # 15% bulge at middle
            v.co.x *= bulge
            v.co.y *= bulge
        bmesh.update_edit_mesh(barrel.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        barrel.data.materials.append(self.get_material(part['material']))
        return barrel, Vector((0, 0, part['height']))
    
    def create_chest_base(self, part):
        """Create chest body."""
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, part['height'] / 2)
        )
        base = bpy.context.active_object
        base.scale = (part['width'], part['depth'], part['height'])
        bpy.ops.object.transform_apply(scale=True)
        
        base.data.materials.append(self.get_material(part['material']))
        return base, Vector((0, 0, part['height']))
    
    def create_chest_lid(self, part):
        """Create arched chest lid."""
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, 0)
        )
        lid = bpy.context.active_object
        lid.scale = (part['width'], part['depth'], part['height'])
        bpy.ops.object.transform_apply(scale=True)
        
        # Arch the top
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(lid.data)
        for v in bm.verts:
            if v.co.z > 0:  # Top verts
                # Create arch based on Y position
                arch = (1 - (v.co.y / (part['depth']/2))**2) * part['height'] * 0.3
                v.co.z += arch
        bmesh.update_edit_mesh(lid.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        lid.data.materials.append(self.get_material(part['material']))
        return lid
    
    def create_chest_lock(self, part):
        """Create small lock for chest."""
        bpy.ops.mesh.primitive_cube_add(
            size=0.05,
            location=(0, 0.175, 0.15)
        )
        lock = bpy.context.active_object
        lock.data.materials.append(self.get_material(part['material']))
        return lock
    
    def create_backpack(self, part):
        """Create a backpack."""
        # Main body
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, part['height'] / 2)
        )
        pack = bpy.context.active_object
        pack.scale = (part['depth'], part['width'], part['height'])
        bpy.ops.object.transform_apply(scale=True)
        
        # Round the edges slightly
        bpy.ops.object.modifier_add(type='BEVEL')
        pack.modifiers["Bevel"].width = 0.02
        pack.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        
        pack.data.materials.append(self.get_material(part['material']))
        return pack, Vector((0, 0, part['height']))
    
    def create_spear_point(self, part, attach_point):
        """Create spear point."""
        bpy.ops.mesh.primitive_cone_add(
            vertices=6,
            radius1=part['width'] / 2,
            radius2=0,
            depth=part['length'],
            location=(0, 0, attach_point.z + part['length'] / 2)
        )
        point = bpy.context.active_object
        point.data.materials.append(self.get_material(part['material']))
        return point
    
    def create_bow(self, part):
        """Create a bow."""
        # Curved bow body using a curved cylinder
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=part['width'] / 2,
            depth=part['height'],
            location=(0, 0, part['height'] / 2)
        )
        bow = bpy.context.active_object
        
        # Curve it
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(bow.data)
        for v in bm.verts:
            t = v.co.z / (part['height'] / 2)  # -1 to 1
            curve = (1 - t**2) * 0.15  # Parabolic curve
            v.co.y += curve
        bmesh.update_edit_mesh(bow.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        bow.data.materials.append(self.get_material(part['material']))
        return bow, Vector((0, 0, part['height']))
    
    def create_bowstring(self, part):
        """Create bowstring."""
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=4,
            radius=0.003,
            depth=part['height'],
            location=(0, 0.12, part['height'] / 2)
        )
        string = bpy.context.active_object
        string.data.materials.append(self.get_material(part['material']))
        return string
    
    def create_fiber_bundle(self, part):
        """Create a bundle of plant fibers."""
        fibers = []
        import random
        random.seed(456)
        
        for i in range(8):
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=4,
                radius=0.008,
                depth=part['size'] * 2,
                location=(
                    random.uniform(-0.02, 0.02),
                    random.uniform(-0.02, 0.02),
                    part['size']
                )
            )
            fiber = bpy.context.active_object
            fiber.rotation_euler = (
                random.uniform(-0.2, 0.2),
                random.uniform(-0.2, 0.2),
                0
            )
            fibers.append(fiber)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for f in fibers:
            f.select_set(True)
        bpy.context.view_layer.objects.active = fibers[0]
        bpy.ops.object.join()
        
        bundle = bpy.context.active_object
        bundle.data.materials.append(self.get_material(part['material']))
        return bundle, Vector((0, 0, part['size'] * 2))
    
    def create_wrench(self, part):
        """Create a wrench."""
        # Handle
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, part['length'] / 2)
        )
        handle = bpy.context.active_object
        handle.scale = (part['width'] * 0.3, 0.01, part['length'] * 0.7)
        bpy.ops.object.transform_apply(scale=True)
        
        # Head (open end)
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, part['length'] * 0.9)
        )
        head = bpy.context.active_object
        head.scale = (part['width'], 0.015, part['length'] * 0.15)
        bpy.ops.object.transform_apply(scale=True)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        handle.select_set(True)
        head.select_set(True)
        bpy.context.view_layer.objects.active = handle
        bpy.ops.object.join()
        
        wrench = bpy.context.active_object
        wrench.data.materials.append(self.get_material(part['material']))
        return wrench, Vector((0, 0, part['length']))
    
    def create_crossbow_body(self, part):
        """Create crossbow body/stock."""
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, 0.05)
        )
        body = bpy.context.active_object
        body.scale = (0.04, part['length'], 0.08)
        bpy.ops.object.transform_apply(scale=True)
        body.data.materials.append(self.get_material(part['material']))
        return body, Vector((0, part['length'] * 0.4, 0.05))
    
    def create_crossbow_arms(self, part, attach_point):
        """Create crossbow bow arms."""
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=0.015,
            depth=part['width'],
            location=(0, attach_point.y, attach_point.z + 0.02)
        )
        arms = bpy.context.active_object
        arms.rotation_euler.y = math.pi / 2
        bpy.ops.object.transform_apply(rotation=True)
        
        # Curve ends slightly
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(arms.data)
        for v in bm.verts:
            t = abs(v.co.x) / (part['width'] / 2)
            v.co.y -= t * 0.05
        bmesh.update_edit_mesh(arms.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        arms.data.materials.append(self.get_material(part['material']))
        return arms
    
    def generate(self, name=None):
        """Generate the complete prop."""
        if name is None:
            name = self.prop_type
        
        bpy.ops.object.select_all(action='DESELECT')
        
        all_parts = []
        attach_point = Vector((0, 0, 0))
        
        for part in self.config['parts']:
            part_type = part['type']
            obj = None
            
            # Route to appropriate creation method
            if part_type == 'handle':
                obj, attach_point = self.create_handle(part)
            elif part_type == 'axe_head':
                obj = self.create_axe_head(part, attach_point)
            elif part_type == 'pickaxe_head':
                obj = self.create_pickaxe_head(part, attach_point)
            elif part_type == 'blade':
                obj = self.create_blade(part, attach_point)
            elif part_type == 'bat':
                obj, attach_point = self.create_bat(part)
            elif part_type == 'crowbar':
                obj, attach_point = self.create_crowbar(part)
            elif part_type == 'hammer_head':
                obj = self.create_hammer_head(part, attach_point)
            elif part_type == 'shovel_head':
                obj = self.create_shovel_head(part, attach_point)
            elif part_type == 'log':
                obj, attach_point = self.create_log(part)
            elif part_type == 'log_rings':
                obj = self.create_log_rings(part)
            elif part_type == 'plank':
                obj, attach_point = self.create_plank(part)
            elif part_type == 'rock':
                obj, attach_point = self.create_rock(part)
            elif part_type == 'ore':
                obj, attach_point = self.create_ore(part)
            elif part_type == 'crate':
                obj, attach_point = self.create_crate(part)
            elif part_type == 'barrel':
                obj, attach_point = self.create_barrel(part)
            elif part_type == 'chest_base':
                obj, attach_point = self.create_chest_base(part)
            elif part_type == 'chest_lid':
                obj = self.create_chest_lid(part)
                obj.location.z = attach_point.z
            elif part_type == 'chest_lock':
                obj = self.create_chest_lock(part)
                obj.location.z = attach_point.z
            elif part_type == 'backpack':
                obj, attach_point = self.create_backpack(part)
            elif part_type == 'spear_point':
                obj = self.create_spear_point(part, attach_point)
            elif part_type == 'bow':
                obj, attach_point = self.create_bow(part)
            elif part_type == 'bowstring':
                obj = self.create_bowstring(part)
            elif part_type == 'fiber_bundle':
                obj, attach_point = self.create_fiber_bundle(part)
            elif part_type == 'wrench':
                obj, attach_point = self.create_wrench(part)
            elif part_type == 'crossbow_body':
                obj, attach_point = self.create_crossbow_body(part)
            elif part_type == 'crossbow_arms':
                obj = self.create_crossbow_arms(part, attach_point)
            
            if obj:
                obj.name = f"{name}_{part_type}"
                all_parts.append(obj)
        
        # Join all parts
        if len(all_parts) > 1:
            bpy.ops.object.select_all(action='DESELECT')
            for part in all_parts:
                part.select_set(True)
            bpy.context.view_layer.objects.active = all_parts[0]
            bpy.ops.object.join()
        
        prop = bpy.context.active_object
        prop.name = name
        
        # Center origin at base
        bpy.context.scene.cursor.location = (0, 0, 0)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        
        return prop


def generate_prop(name, prop_type):
    """Convenience function to generate a prop."""
    generator = StylizedPropGenerator(prop_type)
    return generator.generate(name)


if __name__ == "__main__":
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    # Test various props
    props = ['hatchet', 'pickaxe', 'machete', 'crate', 'barrel', 'stone']
    for i, prop_type in enumerate(props):
        gen = StylizedPropGenerator(prop_type)
        prop = gen.generate(prop_type)
        prop.location.x = i * 1.0
