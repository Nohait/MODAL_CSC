"""
Detailed Armor Generator - Creates high-quality armor pieces for Godot Survival Prototype.
Includes helmets, chest pieces, leg armor, boots, gloves, and backpacks.
"""

import bpy
import bmesh
import math
import random
from mathutils import Vector


class ArmorGenerator:
    """Generate detailed armor models with PBR materials."""
    
    # Armor piece configurations
    HELMETS = {
        "cloth_cap": {
            "type": "light",
            "base_shape": "cap",
            "coverage": 0.6,
            "material": "cloth",
            "color": (0.35, 0.30, 0.25),
            "protection": 5
        },
        "leather_hood": {
            "type": "light", 
            "base_shape": "hood",
            "coverage": 0.7,
            "material": "leather",
            "color": (0.28, 0.20, 0.12),
            "protection": 10
        },
        "military_helmet": {
            "type": "medium",
            "base_shape": "helmet",
            "coverage": 0.85,
            "material": "metal",
            "color": (0.22, 0.25, 0.18),
            "protection": 25
        },
        "riot_helmet": {
            "type": "heavy",
            "base_shape": "full_helmet",
            "coverage": 1.0,
            "material": "metal",
            "color": (0.15, 0.15, 0.18),
            "protection": 35
        },
        "gas_mask": {
            "type": "special",
            "base_shape": "mask",
            "coverage": 0.8,
            "material": "rubber",
            "color": (0.10, 0.10, 0.10),
            "protection": 15
        },
        "swat_helmet": {
            "type": "heavy",
            "base_shape": "tactical",
            "coverage": 0.95,
            "material": "composite",
            "color": (0.12, 0.12, 0.12),
            "protection": 40
        }
    }
    
    CHEST_PIECES = {
        "cloth_shirt": {
            "type": "light",
            "coverage": 0.4,
            "material": "cloth",
            "color": (0.40, 0.35, 0.30),
            "protection": 5
        },
        "leather_jacket": {
            "type": "light",
            "coverage": 0.6,
            "material": "leather",
            "color": (0.25, 0.18, 0.12),
            "protection": 15
        },
        "tactical_vest": {
            "type": "medium",
            "coverage": 0.75,
            "material": "kevlar",
            "color": (0.18, 0.20, 0.15),
            "protection": 30
        },
        "military_armor": {
            "type": "heavy",
            "coverage": 0.9,
            "material": "metal",
            "color": (0.22, 0.25, 0.18),
            "protection": 45
        },
        "riot_armor": {
            "type": "heavy",
            "coverage": 0.95,
            "material": "composite",
            "color": (0.12, 0.12, 0.15),
            "protection": 55
        },
        "hazmat_suit": {
            "type": "special",
            "coverage": 1.0,
            "material": "rubber",
            "color": (0.65, 0.55, 0.15),
            "protection": 20
        }
    }
    
    LEG_ARMOR = {
        "cloth_pants": {
            "type": "light",
            "material": "cloth",
            "color": (0.30, 0.28, 0.25),
            "protection": 5
        },
        "leather_pants": {
            "type": "light",
            "material": "leather",
            "color": (0.22, 0.15, 0.10),
            "protection": 12
        },
        "cargo_pants": {
            "type": "medium",
            "material": "cloth",
            "color": (0.25, 0.28, 0.22),
            "protection": 15
        },
        "tactical_pants": {
            "type": "medium",
            "material": "kevlar",
            "color": (0.18, 0.18, 0.15),
            "protection": 25
        },
        "military_greaves": {
            "type": "heavy",
            "material": "metal",
            "color": (0.20, 0.22, 0.18),
            "protection": 35
        }
    }
    
    ACCESSORIES = {
        "work_gloves": {"slot": "hands", "material": "leather", "color": (0.30, 0.22, 0.15)},
        "tactical_gloves": {"slot": "hands", "material": "kevlar", "color": (0.15, 0.15, 0.12)},
        "boots_basic": {"slot": "feet", "material": "leather", "color": (0.25, 0.18, 0.12)},
        "military_boots": {"slot": "feet", "material": "leather", "color": (0.12, 0.12, 0.10)},
        "small_backpack": {"slot": "back", "material": "cloth", "color": (0.35, 0.30, 0.25)},
        "tactical_backpack": {"slot": "back", "material": "kevlar", "color": (0.18, 0.20, 0.15)},
        "military_backpack": {"slot": "back", "material": "canvas", "color": (0.22, 0.25, 0.18)},
    }
    
    def __init__(self):
        """Initialize generator."""
        self.materials_cache = {}
    
    def _create_material(self, name, color, material_type, roughness=0.6, metallic=0.0):
        """Create PBR material for armor."""
        if name in self.materials_cache:
            return self.materials_cache[name]
        
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (600, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (200, 0)
        
        # Material-specific settings
        material_configs = {
            "cloth": {"roughness": 0.85, "metallic": 0.0},
            "leather": {"roughness": 0.7, "metallic": 0.0},
            "metal": {"roughness": 0.4, "metallic": 0.8},
            "kevlar": {"roughness": 0.75, "metallic": 0.1},
            "rubber": {"roughness": 0.65, "metallic": 0.0},
            "composite": {"roughness": 0.5, "metallic": 0.4},
            "canvas": {"roughness": 0.8, "metallic": 0.0}
        }
        
        config = material_configs.get(material_type, {"roughness": roughness, "metallic": metallic})
        
        # Add subtle noise for texture
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-400, 0)
        noise.inputs["Scale"].default_value = 15.0
        noise.inputs["Detail"].default_value = 3.0
        
        color_ramp = nodes.new("ShaderNodeValToRGB")
        color_ramp.location = (-200, 0)
        color_ramp.color_ramp.elements[0].color = (color[0] * 0.9, color[1] * 0.9, color[2] * 0.9, 1.0)
        color_ramp.color_ramp.elements[1].color = (color[0] * 1.1, color[1] * 1.1, color[2] * 1.1, 1.0)
        color_ramp.color_ramp.elements[0].position = 0.4
        color_ramp.color_ramp.elements[1].position = 0.6
        
        mix = nodes.new("ShaderNodeMixRGB")
        mix.location = (0, 0)
        mix.inputs["Fac"].default_value = 0.3
        mix.inputs["Color1"].default_value = (*color, 1.0)
        
        links.new(noise.outputs["Fac"], color_ramp.inputs["Fac"])
        links.new(color_ramp.outputs["Color"], mix.inputs["Color2"])
        links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
        
        bsdf.inputs["Roughness"].default_value = config["roughness"]
        bsdf.inputs["Metallic"].default_value = config["metallic"]
        
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        self.materials_cache[name] = mat
        return mat
    
    def generate_helmet(self, name, helmet_type="military_helmet"):
        """Generate a helmet model."""
        config = self.HELMETS.get(helmet_type, self.HELMETS["military_helmet"])
        
        parts = []
        
        mat = self._create_material(
            f"mat_{name}",
            config["color"],
            config["material"]
        )
        
        base_shape = config["base_shape"]
        
        if base_shape == "cap":
            # Simple cloth cap
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=8, ring_count=6,
                radius=0.12,
                location=(0, 0, 0.06)
            )
            helmet = bpy.context.active_object
            
            # Cut bottom half
            bpy.ops.object.mode_set(mode='EDIT')
            bpy.ops.mesh.select_all(action='DESELECT')
            bpy.ops.object.mode_set(mode='OBJECT')
            
            for v in helmet.data.vertices:
                if v.co.z < 0:
                    v.co.z = 0
            
            helmet.scale.z = 0.6
            helmet.data.materials.append(mat)
            parts.append(helmet)
            
        elif base_shape == "hood":
            # Hood with drape
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=10, ring_count=8,
                radius=0.13,
                location=(0, 0, 0.05)
            )
            helmet = bpy.context.active_object
            
            # Shape into hood
            for v in helmet.data.vertices:
                if v.co.z < -0.02:
                    v.co.z = -0.02
                # Drape at back
                if v.co.y < -0.05 and v.co.z < 0.05:
                    v.co.z -= 0.03
            
            helmet.data.materials.append(mat)
            parts.append(helmet)
            
        elif base_shape == "helmet":
            # Military helmet dome
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=12, ring_count=8,
                radius=0.14,
                location=(0, 0, 0.08)
            )
            helmet = bpy.context.active_object
            
            for v in helmet.data.vertices:
                if v.co.z < 0.02:
                    v.co.z = 0.02
                # Slight front extension
                if v.co.y > 0.08:
                    v.co.z -= 0.015
            
            helmet.data.materials.append(mat)
            parts.append(helmet)
            
            # Add rim
            bpy.ops.mesh.primitive_torus_add(
                major_radius=0.13,
                minor_radius=0.01,
                major_segments=12,
                minor_segments=4,
                location=(0, 0, 0.03)
            )
            rim = bpy.context.active_object
            rim.data.materials.append(mat)
            parts.append(rim)
            
        elif base_shape == "full_helmet":
            # Full coverage riot helmet
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=12, ring_count=10,
                radius=0.15,
                location=(0, 0, 0.08)
            )
            helmet = bpy.context.active_object
            
            for v in helmet.data.vertices:
                if v.co.z < -0.02:
                    v.co.z = -0.02
            
            helmet.data.materials.append(mat)
            parts.append(helmet)
            
            # Face shield (visor)
            visor_mat = self._create_material(
                f"mat_{name}_visor",
                (0.1, 0.1, 0.12),
                "composite"
            )
            
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=8,
                radius=0.08,
                depth=0.005,
                location=(0, 0.12, 0.04)
            )
            visor = bpy.context.active_object
            visor.rotation_euler.x = math.radians(75)
            visor.scale = (1.4, 0.8, 1)
            visor.data.materials.append(visor_mat)
            parts.append(visor)
            
        elif base_shape == "mask":
            # Gas mask
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=8,
                radius=0.08,
                depth=0.12,
                location=(0, 0.05, 0.02)
            )
            face = bpy.context.active_object
            face.rotation_euler.x = math.radians(90)
            face.data.materials.append(mat)
            parts.append(face)
            
            # Eye pieces
            lens_mat = self._create_material(
                f"mat_{name}_lens",
                (0.15, 0.18, 0.15),
                "composite"
            )
            
            for x in [-0.04, 0.04]:
                bpy.ops.mesh.primitive_cylinder_add(
                    vertices=6,
                    radius=0.025,
                    depth=0.02,
                    location=(x, 0.11, 0.06)
                )
                lens = bpy.context.active_object
                lens.rotation_euler.x = math.radians(90)
                lens.data.materials.append(lens_mat)
                parts.append(lens)
            
            # Filter canister
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=8,
                radius=0.03,
                depth=0.08,
                location=(0, 0.12, -0.03)
            )
            filter_can = bpy.context.active_object
            filter_can.rotation_euler.x = math.radians(70)
            filter_can.data.materials.append(mat)
            parts.append(filter_can)
            
        elif base_shape == "tactical":
            # SWAT style helmet
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=12, ring_count=10,
                radius=0.14,
                location=(0, 0, 0.08)
            )
            helmet = bpy.context.active_object
            
            for v in helmet.data.vertices:
                if v.co.z < 0.01:
                    v.co.z = 0.01
                # Angular edges
                if v.co.z > 0.12:
                    v.co.z = 0.12
            
            helmet.data.materials.append(mat)
            parts.append(helmet)
            
            # NVG mount
            bpy.ops.mesh.primitive_cube_add(
                size=0.04,
                location=(0, 0.08, 0.14)
            )
            mount = bpy.context.active_object
            mount.scale = (1.5, 1, 0.5)
            mount.data.materials.append(mat)
            parts.append(mount)
        
        # Join all parts
        if len(parts) > 1:
            bpy.ops.object.select_all(action='DESELECT')
            for part in parts:
                part.select_set(True)
            bpy.context.view_layer.objects.active = parts[0]
            bpy.ops.object.join()
        
        helmet = bpy.context.active_object
        helmet.name = name
        
        # Flat shading
        for p in helmet.data.polygons:
            p.use_smooth = False
        
        return helmet
    
    def generate_chest_armor(self, name, armor_type="tactical_vest"):
        """Generate chest armor model."""
        config = self.CHEST_PIECES.get(armor_type, self.CHEST_PIECES["tactical_vest"])
        
        parts = []
        
        mat = self._create_material(
            f"mat_{name}",
            config["color"],
            config["material"]
        )
        
        coverage = config["coverage"]
        
        # Base torso shape
        bpy.ops.mesh.primitive_cube_add(
            size=0.4,
            location=(0, 0, 0)
        )
        body = bpy.context.active_object
        body.scale = (0.8, 0.5, 1.2)
        
        # Taper slightly at waist
        for v in body.data.vertices:
            if v.co.z < 0:
                v.co.x *= 0.9
                v.co.y *= 0.95
        
        body.data.materials.append(mat)
        parts.append(body)
        
        if config["type"] in ["medium", "heavy"]:
            # Add armor plates
            plate_mat = self._create_material(
                f"mat_{name}_plate",
                (config["color"][0] * 0.9, config["color"][1] * 0.9, config["color"][2] * 0.9),
                "metal" if config["type"] == "heavy" else "kevlar"
            )
            
            # Front plate
            bpy.ops.mesh.primitive_cube_add(
                size=0.25,
                location=(0, 0.22, 0.05)
            )
            front_plate = bpy.context.active_object
            front_plate.scale = (1.0, 0.15, 1.5)
            front_plate.data.materials.append(plate_mat)
            parts.append(front_plate)
            
            # Back plate
            bpy.ops.mesh.primitive_cube_add(
                size=0.25,
                location=(0, -0.20, 0.05)
            )
            back_plate = bpy.context.active_object
            back_plate.scale = (1.0, 0.15, 1.5)
            back_plate.data.materials.append(plate_mat)
            parts.append(back_plate)
        
        if config["type"] == "heavy":
            # Shoulder guards
            for x in [-0.22, 0.22]:
                bpy.ops.mesh.primitive_uv_sphere_add(
                    segments=6, ring_count=4,
                    radius=0.08,
                    location=(x, 0, 0.25)
                )
                shoulder = bpy.context.active_object
                shoulder.scale = (1.0, 0.8, 0.6)
                shoulder.data.materials.append(mat)
                parts.append(shoulder)
        
        # Pouches for tactical vests
        if "tactical" in armor_type or "military" in armor_type:
            pouch_mat = self._create_material(
                f"mat_{name}_pouch",
                (config["color"][0] * 0.85, config["color"][1] * 0.85, config["color"][2] * 0.85),
                "canvas"
            )
            
            for x in [-0.12, 0.12]:
                bpy.ops.mesh.primitive_cube_add(
                    size=0.08,
                    location=(x, 0.22, -0.12)
                )
                pouch = bpy.context.active_object
                pouch.scale = (1.0, 0.6, 1.2)
                pouch.data.materials.append(pouch_mat)
                parts.append(pouch)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        armor = bpy.context.active_object
        armor.name = name
        
        for p in armor.data.polygons:
            p.use_smooth = False
        
        return armor
    
    def generate_backpack(self, name, backpack_type="tactical_backpack"):
        """Generate a backpack model."""
        config = self.ACCESSORIES.get(backpack_type, self.ACCESSORIES["small_backpack"])
        
        parts = []
        
        mat = self._create_material(
            f"mat_{name}",
            config["color"],
            config["material"]
        )
        
        # Size based on type
        if "military" in backpack_type:
            size = 1.3
        elif "tactical" in backpack_type:
            size = 1.0
        else:
            size = 0.7
        
        # Main compartment
        bpy.ops.mesh.primitive_cube_add(
            size=0.25 * size,
            location=(0, 0, 0.15 * size)
        )
        main = bpy.context.active_object
        main.scale = (0.8, 0.5, 1.2)
        main.data.materials.append(mat)
        parts.append(main)
        
        # Top flap/lid
        bpy.ops.mesh.primitive_cube_add(
            size=0.22 * size,
            location=(0, 0.02 * size, 0.28 * size)
        )
        lid = bpy.context.active_object
        lid.scale = (0.85, 0.4, 0.3)
        lid.data.materials.append(mat)
        parts.append(lid)
        
        # Side pockets
        if size >= 1.0:
            for x in [-0.12, 0.12]:
                bpy.ops.mesh.primitive_cube_add(
                    size=0.06 * size,
                    location=(x * size, 0.06 * size, 0.08 * size)
                )
                pocket = bpy.context.active_object
                pocket.scale = (0.8, 1.0, 1.5)
                pocket.data.materials.append(mat)
                parts.append(pocket)
        
        # Straps
        strap_mat = self._create_material(
            f"mat_{name}_strap",
            (config["color"][0] * 0.7, config["color"][1] * 0.7, config["color"][2] * 0.7),
            config["material"]
        )
        
        for x in [-0.08, 0.08]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.02,
                location=(x * size, -0.08 * size, 0.12 * size)
            )
            strap = bpy.context.active_object
            strap.scale = (1.5, 0.5, 8.0)
            strap.data.materials.append(strap_mat)
            parts.append(strap)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        backpack = bpy.context.active_object
        backpack.name = name
        
        for p in backpack.data.polygons:
            p.use_smooth = False
        
        return backpack
    
    def generate_boots(self, name, boot_type="military_boots"):
        """Generate boot models."""
        config = self.ACCESSORIES.get(boot_type, self.ACCESSORIES["boots_basic"])
        
        parts = []
        
        mat = self._create_material(
            f"mat_{name}",
            config["color"],
            config["material"]
        )
        
        # Boot body
        bpy.ops.mesh.primitive_cube_add(
            size=0.1,
            location=(0, 0, 0.08)
        )
        body = bpy.context.active_object
        body.scale = (0.8, 1.2, 1.6)
        body.data.materials.append(mat)
        parts.append(body)
        
        # Sole
        sole_mat = self._create_material(
            f"mat_{name}_sole",
            (0.05, 0.05, 0.05),
            "rubber"
        )
        
        bpy.ops.mesh.primitive_cube_add(
            size=0.1,
            location=(0, 0.01, 0.01)
        )
        sole = bpy.context.active_object
        sole.scale = (0.9, 1.4, 0.25)
        sole.data.materials.append(sole_mat)
        parts.append(sole)
        
        # Toe cap
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=6, ring_count=4,
            radius=0.04,
            location=(0, 0.07, 0.04)
        )
        toe = bpy.context.active_object
        toe.scale = (1.2, 1.0, 0.6)
        toe.data.materials.append(mat)
        parts.append(toe)
        
        # Join
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        boot = bpy.context.active_object
        boot.name = name
        
        for p in boot.data.polygons:
            p.use_smooth = False
        
        return boot
    
    def generate_all(self, collection=None):
        """Generate all armor pieces."""
        assets = []
        
        # Helmets
        for i, (helmet_id, _) in enumerate(self.HELMETS.items()):
            helmet = self.generate_helmet(f"helmet_{helmet_id}", helmet_id)
            helmet.location = (i * 0.5, 0, 0)
            if collection:
                for col in helmet.users_collection:
                    col.objects.unlink(helmet)
                collection.objects.link(helmet)
            assets.append(helmet)
        
        # Chest pieces
        for i, (armor_id, _) in enumerate(self.CHEST_PIECES.items()):
            armor = self.generate_chest_armor(f"armor_{armor_id}", armor_id)
            armor.location = (i * 0.8, 2, 0)
            if collection:
                for col in armor.users_collection:
                    col.objects.unlink(armor)
                collection.objects.link(armor)
            assets.append(armor)
        
        # Backpacks
        backpack_types = ["small_backpack", "tactical_backpack", "military_backpack"]
        for i, bp_type in enumerate(backpack_types):
            backpack = self.generate_backpack(f"backpack_{bp_type}", bp_type)
            backpack.location = (i * 0.6, 4, 0)
            if collection:
                for col in backpack.users_collection:
                    col.objects.unlink(backpack)
                collection.objects.link(backpack)
            assets.append(backpack)
        
        # Boots
        boot_types = ["boots_basic", "military_boots"]
        for i, boot_type in enumerate(boot_types):
            boot = self.generate_boots(f"boots_{boot_type}", boot_type)
            boot.location = (i * 0.4, 5, 0)
            if collection:
                for col in boot.users_collection:
                    col.objects.unlink(boot)
                collection.objects.link(boot)
            assets.append(boot)
        
        return assets


if __name__ == "__main__":
    # Test generation
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    gen = ArmorGenerator()
    assets = gen.generate_all()
    print(f"Generated {len(assets)} armor pieces")
