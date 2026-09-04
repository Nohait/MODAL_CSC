"""
Detailed Prop Generator - Creates detailed props for survival game.
Includes containers, furniture, debris, and environmental objects.
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector


class DetailedPropGenerator:
    """Generate detailed prop models with wear, damage, and realistic details."""
    
    PROP_TYPES = {
        # Containers
        "crate_wooden": {
            "category": "container",
            "size": (0.8, 0.6, 0.5),
            "material_type": "wood",
            "damage_level": 0.3,
            "has_lid": True
        },
        "crate_military": {
            "category": "container",
            "size": (0.9, 0.5, 0.4),
            "material_type": "metal",
            "damage_level": 0.2,
            "has_lid": True
        },
        "barrel_metal": {
            "category": "container",
            "size": (0.5, 0.5, 0.9),
            "material_type": "metal",
            "damage_level": 0.4,
            "is_cylindrical": True
        },
        "barrel_plastic": {
            "category": "container",
            "size": (0.45, 0.45, 0.85),
            "material_type": "plastic",
            "damage_level": 0.15,
            "is_cylindrical": True,
            "color": (0.15, 0.25, 0.65)
        },
        "barrel_toxic": {
            "category": "container",
            "size": (0.5, 0.5, 0.9),
            "material_type": "metal",
            "damage_level": 0.5,
            "is_cylindrical": True,
            "color": (0.15, 0.55, 0.10),
            "has_hazard_symbol": True
        },
        "locker_metal": {
            "category": "container",
            "size": (0.4, 0.5, 1.8),
            "material_type": "metal",
            "damage_level": 0.35,
            "has_door": True
        },
        "trash_bag": {
            "category": "debris",
            "size": (0.5, 0.5, 0.7),
            "material_type": "plastic",
            "damage_level": 0.0,
            "is_organic_shape": True,
            "color": (0.05, 0.05, 0.05)
        },
        "trash_pile": {
            "category": "debris",
            "size": (1.0, 1.0, 0.5),
            "material_type": "mixed",
            "damage_level": 1.0,
            "is_organic_shape": True
        },
        
        # Furniture
        "table_wooden": {
            "category": "furniture",
            "size": (1.2, 0.7, 0.75),
            "material_type": "wood",
            "damage_level": 0.3,
            "has_legs": True
        },
        "chair_wooden": {
            "category": "furniture",
            "size": (0.45, 0.45, 0.9),
            "material_type": "wood",
            "damage_level": 0.4,
            "has_back": True
        },
        "chair_office": {
            "category": "furniture",
            "size": (0.6, 0.6, 1.0),
            "material_type": "mixed",
            "damage_level": 0.25,
            "has_wheels": True
        },
        "bed_single": {
            "category": "furniture",
            "size": (2.0, 0.9, 0.5),
            "material_type": "fabric",
            "damage_level": 0.45
        },
        "shelf_wooden": {
            "category": "furniture",
            "size": (1.0, 0.3, 1.8),
            "material_type": "wood",
            "damage_level": 0.35,
            "shelves": 4
        },
        
        # Infrastructure
        "concrete_barrier": {
            "category": "infrastructure",
            "size": (2.0, 0.6, 0.8),
            "material_type": "concrete",
            "damage_level": 0.4
        },
        "sandbag_wall": {
            "category": "infrastructure",
            "size": (1.5, 0.5, 0.8),
            "material_type": "fabric",
            "damage_level": 0.2,
            "bags_count": 8
        },
        "generator": {
            "category": "machine",
            "size": (0.7, 0.5, 0.6),
            "material_type": "metal",
            "damage_level": 0.3,
            "has_details": True
        },
        "workbench": {
            "category": "furniture",
            "size": (1.5, 0.8, 0.9),
            "material_type": "wood",
            "damage_level": 0.25,
            "has_tools": True
        },
        
        # Vehicles (static props)
        "tire": {
            "category": "debris",
            "size": (0.65, 0.22, 0.65),
            "material_type": "rubber",
            "damage_level": 0.3
        },
        "tire_stack": {
            "category": "debris",
            "size": (0.65, 0.65, 1.3),
            "material_type": "rubber",
            "damage_level": 0.35,
            "stack_count": 3
        },
        
        # Small props
        "cardboard_box": {
            "category": "container",
            "size": (0.4, 0.3, 0.3),
            "material_type": "cardboard",
            "damage_level": 0.5
        },
        "toolbox": {
            "category": "container",
            "size": (0.5, 0.25, 0.2),
            "material_type": "metal",
            "damage_level": 0.25,
            "color": (0.65, 0.12, 0.10)
        },
        "gas_can": {
            "category": "container",
            "size": (0.25, 0.15, 0.35),
            "material_type": "plastic",
            "damage_level": 0.2,
            "color": (0.7, 0.15, 0.10)
        },
        "medkit": {
            "category": "container",
            "size": (0.3, 0.2, 0.12),
            "material_type": "plastic",
            "damage_level": 0.1,
            "color": (0.9, 0.9, 0.9),
            "has_cross": True
        },
        "ammo_box": {
            "category": "container",
            "size": (0.3, 0.15, 0.12),
            "material_type": "metal",
            "damage_level": 0.15,
            "color": (0.25, 0.30, 0.20)
        }
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, prop_type: str = "crate_wooden") -> bpy.types.Object:
        """Generate a detailed prop of the specified type."""
        config = self.PROP_TYPES.get(prop_type, self.PROP_TYPES["crate_wooden"])
        
        category = config["category"]
        
        if category == "container":
            prop = self._create_container(name, config)
        elif category == "furniture":
            prop = self._create_furniture(name, config, prop_type)
        elif category == "debris":
            prop = self._create_debris(name, config, prop_type)
        elif category == "infrastructure":
            prop = self._create_infrastructure(name, config, prop_type)
        elif category == "machine":
            prop = self._create_machine(name, config, prop_type)
        else:
            prop = self._create_basic_prop(name, config)
        
        # Apply damage/wear
        if config["damage_level"] > 0:
            self._apply_wear(prop, config["damage_level"])
        
        prop.name = name
        self._set_origin_to_bottom(prop)
        
        return prop
    
    def _create_container(self, name: str, config: dict) -> bpy.types.Object:
        """Create container props (crates, barrels, boxes)."""
        size = config["size"]
        mat_type = config["material_type"]
        
        if config.get("is_cylindrical"):
            return self._create_barrel(name, config)
        
        # Create base box
        bpy.ops.mesh.primitive_cube_add(size=1)
        container = bpy.context.active_object
        container.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
        container.location.z = size[2] / 2
        bpy.ops.object.transform_apply(scale=True)
        
        # Add material
        mat = self._create_material_for_type(f"mat_{name}", mat_type, config.get("color"))
        container.data.materials.append(mat)
        
        # Add details based on material type
        if mat_type == "wood":
            self._add_wooden_planks_detail(container, size)
        elif mat_type == "metal":
            self._add_metal_edges(container, size)
        
        # Add lid if specified
        if config.get("has_lid"):
            lid = self._create_lid(size, mat_type, mat)
            lid.location.z = size[2] - 0.02
            container.select_set(True)
            lid.select_set(True)
            bpy.context.view_layer.objects.active = container
            bpy.ops.object.join()
            container = bpy.context.active_object
            bpy.ops.object.select_all(action='DESELECT')
        
        # Add special markings
        if config.get("has_cross"):
            cross = self._create_medical_cross(size)
            cross.location = (size[0] / 2 + 0.001, 0, size[2] / 2)
            container.select_set(True)
            cross.select_set(True)
            bpy.context.view_layer.objects.active = container
            bpy.ops.object.join()
            container = bpy.context.active_object
            bpy.ops.object.select_all(action='DESELECT')
        
        return container
    
    def _create_barrel(self, name: str, config: dict) -> bpy.types.Object:
        """Create barrel-shaped container."""
        size = config["size"]
        
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16,
            radius=size[0] / 2,
            depth=size[2]
        )
        barrel = bpy.context.active_object
        barrel.location.z = size[2] / 2
        
        # Add bulge in middle
        bm = bmesh.new()
        bm.from_mesh(barrel.data)
        for v in bm.verts:
            height_factor = 1 - abs(v.co.z) / (size[2] / 2)
            v.co.x *= 1 + height_factor * 0.08
            v.co.y *= 1 + height_factor * 0.08
        bm.to_mesh(barrel.data)
        bm.free()
        
        # Add rim rings
        for z in [-size[2] / 2 + 0.05, size[2] / 2 - 0.05]:
            ring = self._create_barrel_ring(size[0] / 2 + 0.02, 0.03)
            ring.location.z = size[2] / 2 + z
            barrel.select_set(True)
            ring.select_set(True)
            bpy.context.view_layer.objects.active = barrel
            bpy.ops.object.join()
            barrel = bpy.context.active_object
            bpy.ops.object.select_all(action='DESELECT')
        
        mat = self._create_material_for_type(f"mat_{name}", config["material_type"], config.get("color"))
        barrel.data.materials.append(mat)
        
        return barrel
    
    def _create_barrel_ring(self, radius: float, thickness: float) -> bpy.types.Object:
        """Create a ring for barrel decoration."""
        bpy.ops.mesh.primitive_torus_add(
            major_radius=radius,
            minor_radius=thickness,
            major_segments=16,
            minor_segments=6
        )
        ring = bpy.context.active_object
        ring.scale.z = 0.4
        bpy.ops.object.transform_apply(scale=True)
        return ring
    
    def _create_furniture(self, name: str, config: dict, prop_type: str) -> bpy.types.Object:
        """Create furniture props."""
        size = config["size"]
        
        if "table" in prop_type:
            return self._create_table(name, config)
        elif "chair" in prop_type:
            return self._create_chair(name, config, prop_type)
        elif "bed" in prop_type:
            return self._create_bed(name, config)
        elif "shelf" in prop_type:
            return self._create_shelf(name, config)
        elif "workbench" in prop_type:
            return self._create_workbench(name, config)
        elif "locker" in prop_type:
            return self._create_locker(name, config)
        else:
            return self._create_basic_prop(name, config)
    
    def _create_table(self, name: str, config: dict) -> bpy.types.Object:
        """Create a table with legs."""
        size = config["size"]
        parts = []
        
        mat = self._create_material_for_type(f"mat_{name}", config["material_type"])
        
        # Table top
        bpy.ops.mesh.primitive_cube_add(size=1)
        top = bpy.context.active_object
        top.scale = (size[0] / 2, size[1] / 2, 0.04)
        top.location.z = size[2] - 0.04
        bpy.ops.object.transform_apply(scale=True)
        top.data.materials.append(mat)
        parts.append(top)
        
        # Legs
        leg_inset = 0.08
        leg_radius = 0.035
        for x_sign in [-1, 1]:
            for y_sign in [-1, 1]:
                bpy.ops.mesh.primitive_cylinder_add(
                    vertices=8,
                    radius=leg_radius,
                    depth=size[2] - 0.08
                )
                leg = bpy.context.active_object
                leg.location = (
                    x_sign * (size[0] / 2 - leg_inset),
                    y_sign * (size[1] / 2 - leg_inset),
                    (size[2] - 0.08) / 2
                )
                leg.data.materials.append(mat)
                parts.append(leg)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_chair(self, name: str, config: dict, prop_type: str) -> bpy.types.Object:
        """Create a chair."""
        size = config["size"]
        parts = []
        
        mat = self._create_material_for_type(f"mat_{name}", config["material_type"])
        
        seat_height = 0.45
        seat_thickness = 0.05
        
        # Seat
        bpy.ops.mesh.primitive_cube_add(size=1)
        seat = bpy.context.active_object
        seat.scale = (size[0] / 2, size[1] / 2, seat_thickness)
        seat.location.z = seat_height
        bpy.ops.object.transform_apply(scale=True)
        seat.data.materials.append(mat)
        parts.append(seat)
        
        # Back
        if config.get("has_back"):
            bpy.ops.mesh.primitive_cube_add(size=1)
            back = bpy.context.active_object
            back.scale = (size[0] / 2, 0.02, (size[2] - seat_height) / 2)
            back.location = (0, -size[1] / 2 + 0.02, seat_height + (size[2] - seat_height) / 2)
            bpy.ops.object.transform_apply(scale=True)
            back.data.materials.append(mat)
            parts.append(back)
        
        # Legs
        leg_radius = 0.025 if "office" not in prop_type else 0.015
        leg_inset = 0.05
        for x_sign in [-1, 1]:
            for y_sign in [-1, 1]:
                bpy.ops.mesh.primitive_cylinder_add(
                    vertices=8,
                    radius=leg_radius,
                    depth=seat_height - seat_thickness
                )
                leg = bpy.context.active_object
                leg.location = (
                    x_sign * (size[0] / 2 - leg_inset),
                    y_sign * (size[1] / 2 - leg_inset),
                    (seat_height - seat_thickness) / 2
                )
                leg.data.materials.append(mat)
                parts.append(leg)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_bed(self, name: str, config: dict) -> bpy.types.Object:
        """Create a bed."""
        size = config["size"]
        parts = []
        
        frame_mat = self._create_material_for_type(f"mat_{name}_frame", "metal")
        mattress_mat = self._create_material_for_type(f"mat_{name}_mattress", "fabric")
        
        # Frame
        frame_height = 0.3
        bpy.ops.mesh.primitive_cube_add(size=1)
        frame = bpy.context.active_object
        frame.scale = (size[0] / 2, size[1] / 2, 0.05)
        frame.location.z = frame_height
        bpy.ops.object.transform_apply(scale=True)
        frame.data.materials.append(frame_mat)
        parts.append(frame)
        
        # Mattress
        bpy.ops.mesh.primitive_cube_add(size=1)
        mattress = bpy.context.active_object
        mattress.scale = (size[0] / 2 - 0.05, size[1] / 2 - 0.05, 0.1)
        mattress.location.z = frame_height + 0.15
        bpy.ops.object.transform_apply(scale=True)
        
        # Round mattress edges
        bpy.ops.object.modifier_add(type='BEVEL')
        mattress.modifiers["Bevel"].width = 0.03
        mattress.modifiers["Bevel"].segments = 3
        bpy.ops.object.modifier_apply(modifier="Bevel")
        mattress.data.materials.append(mattress_mat)
        parts.append(mattress)
        
        # Pillow
        bpy.ops.mesh.primitive_cube_add(size=1)
        pillow = bpy.context.active_object
        pillow.scale = (0.2, 0.3, 0.08)
        pillow.location = (-size[0] / 2 + 0.25, 0, frame_height + 0.28)
        bpy.ops.object.transform_apply(scale=True)
        bpy.ops.object.modifier_add(type='BEVEL')
        pillow.modifiers["Bevel"].width = 0.04
        pillow.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
        pillow.data.materials.append(mattress_mat)
        parts.append(pillow)
        
        # Legs
        for x in [size[0] / 2 - 0.1, -size[0] / 2 + 0.1]:
            for y in [size[1] / 2 - 0.1, -size[1] / 2 + 0.1]:
                bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.03, depth=frame_height)
                leg = bpy.context.active_object
                leg.location = (x, y, frame_height / 2)
                leg.data.materials.append(frame_mat)
                parts.append(leg)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_shelf(self, name: str, config: dict) -> bpy.types.Object:
        """Create a shelf unit."""
        size = config["size"]
        num_shelves = config.get("shelves", 4)
        parts = []
        
        mat = self._create_material_for_type(f"mat_{name}", config["material_type"])
        
        # Side panels
        for y_sign in [-1, 1]:
            bpy.ops.mesh.primitive_cube_add(size=1)
            panel = bpy.context.active_object
            panel.scale = (size[0] / 2, 0.02, size[2] / 2)
            panel.location = (0, y_sign * (size[1] / 2 - 0.02), size[2] / 2)
            bpy.ops.object.transform_apply(scale=True)
            panel.data.materials.append(mat)
            parts.append(panel)
        
        # Shelves
        shelf_spacing = size[2] / (num_shelves + 1)
        for i in range(num_shelves + 1):  # Include bottom
            bpy.ops.mesh.primitive_cube_add(size=1)
            shelf = bpy.context.active_object
            shelf.scale = (size[0] / 2, size[1] / 2, 0.02)
            shelf.location = (0, 0, i * shelf_spacing + 0.02)
            bpy.ops.object.transform_apply(scale=True)
            shelf.data.materials.append(mat)
            parts.append(shelf)
        
        # Back panel
        bpy.ops.mesh.primitive_cube_add(size=1)
        back = bpy.context.active_object
        back.scale = (0.01, size[1] / 2, size[2] / 2)
        back.location = (-size[0] / 2 + 0.01, 0, size[2] / 2)
        bpy.ops.object.transform_apply(scale=True)
        back.data.materials.append(mat)
        parts.append(back)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_workbench(self, name: str, config: dict) -> bpy.types.Object:
        """Create a workbench with tool details."""
        # Start with table base
        table = self._create_table(name, config)
        
        if config.get("has_tools"):
            mat = self._create_material_for_type(f"mat_{name}_metal", "metal")
            size = config["size"]
            
            # Add vise
            bpy.ops.mesh.primitive_cube_add(size=1)
            vise = bpy.context.active_object
            vise.scale = (0.1, 0.08, 0.1)
            vise.location = (size[0] / 2 - 0.15, 0, size[2] + 0.05)
            bpy.ops.object.transform_apply(scale=True)
            vise.data.materials.append(mat)
            
            table.select_set(True)
            vise.select_set(True)
            bpy.context.view_layer.objects.active = table
            bpy.ops.object.join()
            table = bpy.context.active_object
            bpy.ops.object.select_all(action='DESELECT')
        
        return table
    
    def _create_locker(self, name: str, config: dict) -> bpy.types.Object:
        """Create a metal locker."""
        size = config["size"]
        parts = []
        
        mat = self._create_material_for_type(f"mat_{name}", config["material_type"], (0.4, 0.45, 0.42))
        
        # Main body
        bpy.ops.mesh.primitive_cube_add(size=1)
        body = bpy.context.active_object
        body.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
        body.location.z = size[2] / 2
        bpy.ops.object.transform_apply(scale=True)
        body.data.materials.append(mat)
        parts.append(body)
        
        # Door indent
        bpy.ops.mesh.primitive_cube_add(size=1)
        door = bpy.context.active_object
        door.scale = (size[0] / 2 - 0.02, 0.01, size[2] / 2 - 0.05)
        door.location = (0, size[1] / 2 - 0.01, size[2] / 2)
        bpy.ops.object.transform_apply(scale=True)
        door.data.materials.append(mat)
        parts.append(door)
        
        # Vent slits
        for i in range(3):
            bpy.ops.mesh.primitive_cube_add(size=1)
            vent = bpy.context.active_object
            vent.scale = (size[0] / 2 - 0.05, 0.005, 0.015)
            vent.location = (0, size[1] / 2 + 0.005, size[2] * 0.7 + i * 0.05)
            bpy.ops.object.transform_apply(scale=True)
            vent.data.materials.append(mat)
            parts.append(vent)
        
        # Handle
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.015, depth=0.08)
        handle = bpy.context.active_object
        handle.rotation_euler.x = math.radians(90)
        handle.location = (size[0] / 2 - 0.05, size[1] / 2 + 0.02, size[2] / 2)
        handle.data.materials.append(mat)
        parts.append(handle)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_debris(self, name: str, config: dict, prop_type: str) -> bpy.types.Object:
        """Create debris props."""
        size = config["size"]
        
        if "tire" in prop_type:
            return self._create_tire(name, config, prop_type)
        elif "trash_bag" in prop_type:
            return self._create_trash_bag(name, config)
        elif "trash_pile" in prop_type:
            return self._create_trash_pile(name, config)
        else:
            return self._create_basic_prop(name, config)
    
    def _create_tire(self, name: str, config: dict, prop_type: str) -> bpy.types.Object:
        """Create a tire or tire stack."""
        mat = self._create_material_for_type(f"mat_{name}", "rubber")
        
        stack_count = config.get("stack_count", 1)
        parts = []
        
        for i in range(stack_count):
            bpy.ops.mesh.primitive_torus_add(
                major_radius=config["size"][0] / 2,
                minor_radius=config["size"][1] / 2,
                major_segments=24,
                minor_segments=8
            )
            tire = bpy.context.active_object
            tire.location.z = i * config["size"][1] * 1.8 + config["size"][1] / 2
            
            # Add tread pattern (simplified)
            bm = bmesh.new()
            bm.from_mesh(tire.data)
            for v in bm.verts:
                angle = math.atan2(v.co.y, v.co.x)
                if int(angle * 10) % 2 == 0:
                    dist = math.sqrt(v.co.x**2 + v.co.y**2)
                    if dist > config["size"][0] / 2 * 0.9:
                        v.co.x *= 1.03
                        v.co.y *= 1.03
            bm.to_mesh(tire.data)
            bm.free()
            
            tire.data.materials.append(mat)
            parts.append(tire)
        
        if len(parts) > 1:
            bpy.ops.object.select_all(action='DESELECT')
            for part in parts:
                part.select_set(True)
            bpy.context.view_layer.objects.active = parts[0]
            bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_trash_bag(self, name: str, config: dict) -> bpy.types.Object:
        """Create a tied trash bag."""
        size = config["size"]
        
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=size[0] / 2)
        bag = bpy.context.active_object
        bag.scale = (1.0, 0.9, 1.2)
        bag.location.z = size[2] / 2
        bpy.ops.object.transform_apply(scale=True)
        
        # Deform organically
        bm = bmesh.new()
        bm.from_mesh(bag.data)
        for v in bm.verts:
            v.co += Vector((
                random.uniform(-0.05, 0.05),
                random.uniform(-0.05, 0.05),
                random.uniform(-0.03, 0.03)
            ))
            # Pinch top
            if v.co.z > size[2] * 0.3:
                factor = (v.co.z - size[2] * 0.3) / (size[2] * 0.5)
                v.co.x *= 1 - factor * 0.7
                v.co.y *= 1 - factor * 0.7
        bm.to_mesh(bag.data)
        bm.free()
        
        mat = self._create_material_for_type(f"mat_{name}", "plastic", config.get("color"))
        bag.data.materials.append(mat)
        
        return bag
    
    def _create_trash_pile(self, name: str, config: dict) -> bpy.types.Object:
        """Create a pile of trash/debris."""
        size = config["size"]
        parts = []
        
        for i in range(random.randint(8, 15)):
            shape = random.choice(["cube", "sphere", "cylinder"])
            obj_size = random.uniform(0.05, 0.2)
            
            if shape == "cube":
                bpy.ops.mesh.primitive_cube_add(size=obj_size)
            elif shape == "sphere":
                bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=obj_size / 2)
            else:
                bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=obj_size / 2, depth=obj_size)
            
            obj = bpy.context.active_object
            obj.location = (
                random.uniform(-size[0] / 2, size[0] / 2),
                random.uniform(-size[1] / 2, size[1] / 2),
                random.uniform(0, size[2])
            )
            obj.rotation_euler = (
                random.uniform(0, math.pi * 2),
                random.uniform(0, math.pi * 2),
                random.uniform(0, math.pi * 2)
            )
            
            mat_type = random.choice(["plastic", "metal", "cardboard"])
            color = (random.uniform(0.1, 0.4), random.uniform(0.1, 0.4), random.uniform(0.1, 0.4))
            mat = self._create_material_for_type(f"mat_{name}_{i}", mat_type, color)
            obj.data.materials.append(mat)
            parts.append(obj)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_infrastructure(self, name: str, config: dict, prop_type: str) -> bpy.types.Object:
        """Create infrastructure props."""
        if "barrier" in prop_type:
            return self._create_concrete_barrier(name, config)
        elif "sandbag" in prop_type:
            return self._create_sandbag_wall(name, config)
        else:
            return self._create_basic_prop(name, config)
    
    def _create_concrete_barrier(self, name: str, config: dict) -> bpy.types.Object:
        """Create a concrete barrier."""
        size = config["size"]
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        barrier = bpy.context.active_object
        barrier.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
        barrier.location.z = size[2] / 2
        bpy.ops.object.transform_apply(scale=True)
        
        # Taper bottom
        bm = bmesh.new()
        bm.from_mesh(barrier.data)
        for v in bm.verts:
            if v.co.z < 0:
                v.co.x *= 1.15
                v.co.y *= 1.2
        bm.to_mesh(barrier.data)
        bm.free()
        
        mat = self._create_material_for_type(f"mat_{name}", "concrete")
        barrier.data.materials.append(mat)
        
        return barrier
    
    def _create_sandbag_wall(self, name: str, config: dict) -> bpy.types.Object:
        """Create a sandbag wall."""
        size = config["size"]
        bags_count = config.get("bags_count", 8)
        parts = []
        
        mat = self._create_material_for_type(f"mat_{name}", "fabric", (0.55, 0.50, 0.40))
        
        # Create individual sandbags
        bag_width = size[0] / 4
        bag_height = size[2] / 2
        bag_depth = size[1]
        
        for layer in range(2):
            for col in range(4):
                bpy.ops.mesh.primitive_cube_add(size=1)
                bag = bpy.context.active_object
                bag.scale = (bag_width / 2 - 0.02, bag_depth / 2, bag_height / 2 - 0.02)
                bag.location = (
                    -size[0] / 2 + bag_width / 2 + col * bag_width + (layer * bag_width / 2),
                    0,
                    bag_height / 2 + layer * bag_height * 0.9
                )
                bpy.ops.object.transform_apply(scale=True)
                
                # Round the bag
                bpy.ops.object.modifier_add(type='BEVEL')
                bag.modifiers["Bevel"].width = 0.03
                bag.modifiers["Bevel"].segments = 2
                bpy.ops.object.modifier_apply(modifier="Bevel")
                
                # Add sag/deformation
                bm = bmesh.new()
                bm.from_mesh(bag.data)
                for v in bm.verts:
                    v.co.z -= abs(v.co.x) * 0.1
                    v.co += Vector((
                        random.uniform(-0.01, 0.01),
                        random.uniform(-0.01, 0.01),
                        random.uniform(-0.01, 0.01)
                    ))
                bm.to_mesh(bag.data)
                bm.free()
                
                bag.data.materials.append(mat)
                parts.append(bag)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_machine(self, name: str, config: dict, prop_type: str) -> bpy.types.Object:
        """Create machine props."""
        if "generator" in prop_type:
            return self._create_generator(name, config)
        else:
            return self._create_basic_prop(name, config)
    
    def _create_generator(self, name: str, config: dict) -> bpy.types.Object:
        """Create a generator."""
        size = config["size"]
        parts = []
        
        body_mat = self._create_material_for_type(f"mat_{name}_body", "metal", (0.7, 0.15, 0.1))
        detail_mat = self._create_material_for_type(f"mat_{name}_detail", "metal")
        
        # Main body
        bpy.ops.mesh.primitive_cube_add(size=1)
        body = bpy.context.active_object
        body.scale = (size[0] / 2, size[1] / 2, size[2] / 2 - 0.05)
        body.location.z = size[2] / 2 - 0.05
        bpy.ops.object.transform_apply(scale=True)
        body.data.materials.append(body_mat)
        parts.append(body)
        
        # Engine block on top
        bpy.ops.mesh.primitive_cube_add(size=1)
        engine = bpy.context.active_object
        engine.scale = (size[0] / 2 - 0.05, size[1] / 2 - 0.05, 0.08)
        engine.location.z = size[2] - 0.08
        bpy.ops.object.transform_apply(scale=True)
        engine.data.materials.append(detail_mat)
        parts.append(engine)
        
        # Fuel cap
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.04, depth=0.03)
        cap = bpy.context.active_object
        cap.location = (size[0] / 4, 0, size[2])
        cap.data.materials.append(detail_mat)
        parts.append(cap)
        
        # Control panel
        bpy.ops.mesh.primitive_cube_add(size=1)
        panel = bpy.context.active_object
        panel.scale = (0.03, size[1] / 4, size[2] / 4)
        panel.location = (size[0] / 2 + 0.03, 0, size[2] / 2)
        bpy.ops.object.transform_apply(scale=True)
        panel.data.materials.append(detail_mat)
        parts.append(panel)
        
        # Handles
        for y in [size[1] / 3, -size[1] / 3]:
            bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.02, depth=0.08)
            handle = bpy.context.active_object
            handle.location = (0, y, size[2] + 0.04)
            handle.rotation_euler.y = math.radians(90)
            handle.data.materials.append(detail_mat)
            parts.append(handle)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _create_basic_prop(self, name: str, config: dict) -> bpy.types.Object:
        """Create a basic box prop as fallback."""
        size = config["size"]
        
        bpy.ops.mesh.primitive_cube_add(size=1)
        prop = bpy.context.active_object
        prop.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
        prop.location.z = size[2] / 2
        bpy.ops.object.transform_apply(scale=True)
        
        mat = self._create_material_for_type(f"mat_{name}", config["material_type"], config.get("color"))
        prop.data.materials.append(mat)
        
        return prop
    
    # === DETAIL METHODS ===
    
    def _add_wooden_planks_detail(self, obj: bpy.types.Object, size: tuple) -> None:
        """Add plank lines to wooden objects."""
        # This would add edge loops for plank appearance
        # Simplified version - just add some vertex displacement
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        for v in bm.verts:
            if abs(v.co.z - size[2] / 2) < 0.01:  # Top face
                v.co.z += random.uniform(-0.005, 0.005)
        bm.to_mesh(obj.data)
        bm.free()
    
    def _add_metal_edges(self, obj: bpy.types.Object, size: tuple) -> None:
        """Add beveled edges for metal look."""
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.modifier_add(type='BEVEL')
        obj.modifiers["Bevel"].width = 0.015
        obj.modifiers["Bevel"].segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
    
    def _create_lid(self, size: tuple, mat_type: str, mat: bpy.types.Material) -> bpy.types.Object:
        """Create a lid for containers."""
        bpy.ops.mesh.primitive_cube_add(size=1)
        lid = bpy.context.active_object
        lid.scale = (size[0] / 2 + 0.01, size[1] / 2 + 0.01, 0.03)
        bpy.ops.object.transform_apply(scale=True)
        lid.data.materials.append(mat)
        return lid
    
    def _create_medical_cross(self, size: tuple) -> bpy.types.Object:
        """Create a medical cross symbol."""
        cross_size = min(size[1], size[2]) * 0.6
        parts = []
        
        mat = bpy.data.materials.new(name="mat_cross")
        mat.use_nodes = True
        mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.8, 0.1, 0.1, 1.0)
        
        # Horizontal bar
        bpy.ops.mesh.primitive_cube_add(size=1)
        h_bar = bpy.context.active_object
        h_bar.scale = (0.002, cross_size / 2, cross_size / 6)
        bpy.ops.object.transform_apply(scale=True)
        h_bar.data.materials.append(mat)
        parts.append(h_bar)
        
        # Vertical bar
        bpy.ops.mesh.primitive_cube_add(size=1)
        v_bar = bpy.context.active_object
        v_bar.scale = (0.002, cross_size / 6, cross_size / 2)
        bpy.ops.object.transform_apply(scale=True)
        v_bar.data.materials.append(mat)
        parts.append(v_bar)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        return bpy.context.active_object
    
    def _apply_wear(self, obj: bpy.types.Object, level: float) -> None:
        """Apply wear and damage to mesh."""
        if level < 0.1:
            return
        
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        
        noise_amount = level * 0.02
        for v in bm.verts:
            if random.random() < level:
                v.co += Vector((
                    random.uniform(-noise_amount, noise_amount),
                    random.uniform(-noise_amount, noise_amount),
                    random.uniform(-noise_amount, noise_amount)
                ))
        
        bm.to_mesh(obj.data)
        bm.free()
    
    # === MATERIALS ===
    
    def _create_material_for_type(self, name: str, mat_type: str, color: tuple = None) -> bpy.types.Material:
        """Create material based on type."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        
        bsdf = nodes["Principled BSDF"]
        
        if mat_type == "wood":
            base_color = color or (0.40, 0.25, 0.12)
            bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.75
        elif mat_type == "metal":
            base_color = color or (0.35, 0.38, 0.40)
            bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
            bsdf.inputs["Metallic"].default_value = 0.85
            bsdf.inputs["Roughness"].default_value = 0.45
        elif mat_type == "plastic":
            base_color = color or (0.2, 0.25, 0.3)
            bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.35
        elif mat_type == "fabric":
            base_color = color or (0.3, 0.28, 0.25)
            bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.9
        elif mat_type == "concrete":
            base_color = color or (0.45, 0.45, 0.42)
            bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.95
        elif mat_type == "rubber":
            base_color = color or (0.05, 0.05, 0.05)
            bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.7
        elif mat_type == "cardboard":
            base_color = color or (0.55, 0.45, 0.35)
            bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.85
        else:
            base_color = color or (0.5, 0.5, 0.5)
            bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.5
        
        return mat
    
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
