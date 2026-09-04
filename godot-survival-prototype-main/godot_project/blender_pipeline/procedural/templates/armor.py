import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class ArmorGenerator(BaseModelGenerator, BaseMaterial):
    """Generates armor pieces: helmets, vests, gloves, boots, backpacks"""
    asset_type = "armor"

    ARMOR_TYPES = {
        # Helmets
        "cloth_cap": {"slot": "head", "tier": 1, "material": "cloth"},
        "military_cap": {"slot": "head", "tier": 2, "material": "cloth"},
        "tactical_helmet": {"slot": "head", "tier": 3, "material": "metal"},
        "swat_helmet": {"slot": "head", "tier": 4, "material": "metal", "visor": True},
        
        # Body armor
        "cloth_shirt": {"slot": "body", "tier": 1, "material": "cloth"},
        "leather_jacket": {"slot": "body", "tier": 2, "material": "leather"},
        "tactical_vest": {"slot": "body", "tier": 3, "material": "nylon"},
        "military_armor": {"slot": "body", "tier": 4, "material": "metal"},
        "swat_armor": {"slot": "body", "tier": 5, "material": "metal", "heavy": True},
        
        # Gloves
        "work_gloves": {"slot": "hands", "tier": 1, "material": "leather"},
        "tactical_gloves": {"slot": "hands", "tier": 2, "material": "nylon"},
        "reinforced_gloves": {"slot": "hands", "tier": 3, "material": "leather"},
        
        # Boots
        "sneakers": {"slot": "feet", "tier": 1, "material": "cloth"},
        "work_boots": {"slot": "feet", "tier": 2, "material": "leather"},
        "military_boots": {"slot": "feet", "tier": 3, "material": "leather"},
        "reinforced_boots": {"slot": "feet", "tier": 4, "material": "metal"},
        
        # Backpacks
        "small_backpack": {"slot": "back", "tier": 1, "capacity": 8},
        "military_backpack": {"slot": "back", "tier": 2, "capacity": 15},
        "hiking_backpack": {"slot": "back", "tier": 3, "capacity": 20},
        "tactical_backpack": {"slot": "back", "tier": 4, "capacity": 25},
    }

    MATERIAL_COLORS = {
        "cloth": (0.45, 0.42, 0.38, 1.0),
        "leather": (0.35, 0.25, 0.18, 1.0),
        "nylon": (0.25, 0.28, 0.22, 1.0),
        "metal": (0.35, 0.38, 0.35, 1.0),
    }

    def generate(
        self,
        seed: int | None = None,
        armor_type: str = "tactical_vest",
        size: float = 1.0,
        variation: float = 1.0,
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions(f"armor_{armor_type}")
        self._ensure_object_mode()
        self._deselect_all()

        config = self.ARMOR_TYPES.get(armor_type, self.ARMOR_TYPES["tactical_vest"])
        slot = config.get("slot", "body")
        parts = []

        if slot == "head":
            parts = self._create_helmet(config, size, rng)
        elif slot == "body":
            parts = self._create_body_armor(config, size, rng)
        elif slot == "hands":
            parts = self._create_gloves(config, size, rng)
        elif slot == "feet":
            parts = self._create_boots(config, size, rng)
        elif slot == "back":
            parts = self._create_backpack(config, size, rng)

        # Apply material
        mat_type = config.get("material", "cloth")
        mat = self._create_armor_material(mat_type, rng, damage_level)

        for part in parts:
            if part.data.materials:
                part.data.materials[0] = mat
            else:
                part.data.materials.append(mat)

        # Join parts
        self._ensure_object_mode()
        self._deselect_all()
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()

        result = bpy.context.active_object
        result.name = f"armor_{armor_type}_v001"
        return result

    def _create_helmet(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        tier = config.get("tier", 1)

        if tier <= 2:
            # Cap style
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=12, ring_count=6,
                radius=0.15 * size,
                location=(0, 0, 0)
            )
            cap = bpy.context.active_object
            cap.scale.z = 0.6
            cap.name = "helmet_cap"
            parts.append(cap)

            # Brim
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=16, radius=0.12 * size, depth=0.02 * size,
                location=(0.05 * size, 0, -0.02 * size)
            )
            brim = bpy.context.active_object
            brim.name = "helmet_brim"
            parts.append(brim)
        else:
            # Full helmet
            bpy.ops.mesh.primitive_uv_sphere_add(
                segments=16, ring_count=10,
                radius=0.16 * size,
                location=(0, 0, 0)
            )
            dome = bpy.context.active_object
            dome.scale = (1.0, 0.9, 0.95)
            dome.name = "helmet_dome"
            parts.append(dome)

            if config.get("visor"):
                bpy.ops.mesh.primitive_cube_add(
                    size=0.12 * size,
                    location=(0.1 * size, 0, -0.02 * size)
                )
                visor = bpy.context.active_object
                visor.scale = (0.3, 1.2, 0.8)
                visor.name = "helmet_visor"
                parts.append(visor)

        return parts

    def _create_body_armor(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        is_heavy = config.get("heavy", False)
        tier = config.get("tier", 1)

        # Main vest/torso piece
        thickness = 0.08 if tier >= 3 else 0.05
        bpy.ops.mesh.primitive_cube_add(
            size=0.35 * size,
            location=(0, 0, 0)
        )
        vest = bpy.context.active_object
        vest.scale = (0.9, thickness / 0.35, 1.2)
        vest.name = "armor_vest"
        parts.append(vest)

        # Shoulder pads for tier 3+
        if tier >= 3:
            for offset in [-0.2 * size, 0.2 * size]:
                bpy.ops.mesh.primitive_cube_add(
                    size=0.1 * size,
                    location=(0, offset, 0.15 * size)
                )
                pad = bpy.context.active_object
                pad.scale = (0.8, 1.3, 0.5)
                pad.name = "armor_shoulder"
                parts.append(pad)

        # Collar for tier 4+
        if tier >= 4:
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=12, radius=0.12 * size, depth=0.06 * size,
                location=(0, 0, 0.22 * size)
            )
            collar = bpy.context.active_object
            collar.name = "armor_collar"
            parts.append(collar)

        # Pouches
        if tier >= 2:
            for x_off in [-0.08 * size, 0.08 * size]:
                bpy.ops.mesh.primitive_cube_add(
                    size=0.06 * size,
                    location=(x_off, 0.06 * size, -0.08 * size)
                )
                pouch = bpy.context.active_object
                pouch.scale = (1.0, 0.6, 0.8)
                pouch.name = "armor_pouch"
                parts.append(pouch)

        return parts

    def _create_gloves(self, config: dict, size: float, rng: Random) -> list:
        parts = []

        # Palm
        bpy.ops.mesh.primitive_cube_add(
            size=0.08 * size,
            location=(0, 0, 0)
        )
        palm = bpy.context.active_object
        palm.scale = (1.0, 0.7, 0.4)
        palm.name = "glove_palm"
        parts.append(palm)

        # Fingers (simplified)
        for i, offset in enumerate([-0.025, -0.008, 0.008, 0.025]):
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6, radius=0.008 * size, depth=0.035 * size,
                location=(0.05 * size, offset * size, 0)
            )
            finger = bpy.context.active_object
            finger.rotation_euler[1] = 1.5708
            finger.name = f"glove_finger_{i}"
            parts.append(finger)

        # Thumb
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6, radius=0.01 * size, depth=0.025 * size,
            location=(0.02 * size, -0.04 * size, 0)
        )
        thumb = bpy.context.active_object
        thumb.rotation_euler = (0, 1.2, 0.5)
        thumb.name = "glove_thumb"
        parts.append(thumb)

        return parts

    def _create_boots(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        tier = config.get("tier", 1)

        # Main boot
        bpy.ops.mesh.primitive_cube_add(
            size=0.12 * size,
            location=(0, 0, 0.06 * size)
        )
        boot = bpy.context.active_object
        boot.scale = (0.9, 0.5, 1.2)
        boot.name = "boot_main"
        parts.append(boot)

        # Sole
        bpy.ops.mesh.primitive_cube_add(
            size=0.13 * size,
            location=(0.01 * size, 0, -0.02 * size)
        )
        sole = bpy.context.active_object
        sole.scale = (1.0, 0.6, 0.25)
        sole.name = "boot_sole"
        parts.append(sole)

        # Ankle support for higher tiers
        if tier >= 3:
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=10, radius=0.045 * size, depth=0.08 * size,
                location=(0, 0, 0.12 * size)
            )
            ankle = bpy.context.active_object
            ankle.name = "boot_ankle"
            parts.append(ankle)

        return parts

    def _create_backpack(self, config: dict, size: float, rng: Random) -> list:
        parts = []
        capacity = config.get("capacity", 10)
        pack_size = 0.2 + (capacity / 100)

        # Main compartment
        bpy.ops.mesh.primitive_cube_add(
            size=pack_size * size,
            location=(0, 0, 0)
        )
        main = bpy.context.active_object
        main.scale = (0.8, 0.5, 1.2)
        main.name = "backpack_main"
        parts.append(main)

        # Top flap
        bpy.ops.mesh.primitive_cube_add(
            size=pack_size * 0.4 * size,
            location=(0, 0.03 * size, pack_size * 0.5 * size)
        )
        flap = bpy.context.active_object
        flap.scale = (1.8, 0.3, 0.5)
        flap.name = "backpack_flap"
        parts.append(flap)

        # Side pockets
        if capacity >= 15:
            for offset in [-pack_size * 0.4 * size, pack_size * 0.4 * size]:
                bpy.ops.mesh.primitive_cube_add(
                    size=pack_size * 0.25 * size,
                    location=(offset, 0.04 * size, -0.05 * size)
                )
                pocket = bpy.context.active_object
                pocket.scale = (0.6, 0.4, 0.8)
                pocket.name = "backpack_pocket"
                parts.append(pocket)

        # Straps
        for offset in [-0.06 * size, 0.06 * size]:
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6, radius=0.012 * size, depth=pack_size * size,
                location=(offset, -0.08 * size, 0)
            )
            strap = bpy.context.active_object
            strap.name = "backpack_strap"
            parts.append(strap)

        return parts

    def _create_armor_material(self, mat_type: str, rng: Random, damage: float) -> bpy.types.Material:
        base_color = self.MATERIAL_COLORS.get(mat_type, (0.4, 0.4, 0.4, 1.0))
        color = (
            base_color[0] + rng.uniform(-0.03, 0.03),
            base_color[1] + rng.uniform(-0.03, 0.03),
            base_color[2] + rng.uniform(-0.03, 0.03),
            1.0
        )

        mat = self.create_material(f"Armor_{mat_type.capitalize()}", color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")

        if mat_type == "metal":
            bsdf.inputs["Metallic"].default_value = 0.7
            bsdf.inputs["Roughness"].default_value = 0.35 + damage * 0.3
        elif mat_type == "leather":
            bsdf.inputs["Roughness"].default_value = 0.65
        elif mat_type == "nylon":
            bsdf.inputs["Roughness"].default_value = 0.5
            bsdf.inputs["Sheen Weight"].default_value = 0.3
        else:  # cloth
            bsdf.inputs["Roughness"].default_value = 0.8

        noise = self.add_noise(nodes, scale=12.0, detail=1.5)
        dark_color = (color[0] * 0.75, color[1] * 0.75, color[2] * 0.75, 1.0)
        ramp = self.add_color_ramp(nodes, colors=[color, dark_color], positions=[0.3, 0.8])
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])

        return mat
