import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

import bpy
from random import Random

from .model_base import BaseModelGenerator
from .material_base import BaseMaterial


class EnemyVariantGenerator(BaseModelGenerator, BaseMaterial):
    """Generates various zombie/enemy variants for LDOE-style gameplay"""
    asset_type = "enemy"

    ENEMY_TYPES = {
        # Basic zombies
        "zombie_walker": {"speed": "slow", "size": 1.0, "color": (0.45, 0.55, 0.4, 1.0), "threat": 1},
        "zombie_runner": {"speed": "fast", "size": 0.95, "color": (0.5, 0.6, 0.45, 1.0), "threat": 2},
        "zombie_crawler": {"speed": "slow", "size": 0.7, "color": (0.35, 0.45, 0.35, 1.0), "threat": 1, "crawling": True},
        
        # Special infected
        "bloater": {"speed": "slow", "size": 1.6, "color": (0.5, 0.6, 0.3, 1.0), "threat": 3, "bloated": True},
        "spitter": {"speed": "medium", "size": 1.1, "color": (0.55, 0.7, 0.4, 1.0), "threat": 3, "ranged": True},
        "screamer": {"speed": "medium", "size": 0.9, "color": (0.6, 0.5, 0.5, 1.0), "threat": 2, "alerts": True},
        "brute": {"speed": "slow", "size": 1.8, "color": (0.4, 0.45, 0.35, 1.0), "threat": 4, "armored": True},
        
        # Bosses
        "ravager": {"speed": "medium", "size": 2.2, "color": (0.35, 0.4, 0.3, 1.0), "threat": 5, "boss": True},
        "the_blind_one": {"speed": "fast", "size": 2.5, "color": (0.3, 0.35, 0.35, 1.0), "threat": 6, "boss": True},
        
        # Animals
        "feral_dog": {"speed": "fast", "size": 0.6, "color": (0.4, 0.35, 0.3, 1.0), "threat": 2, "quadruped": True},
        "wolf": {"speed": "fast", "size": 0.8, "color": (0.45, 0.45, 0.4, 1.0), "threat": 3, "quadruped": True},
        "bear": {"speed": "medium", "size": 1.4, "color": (0.35, 0.28, 0.22, 1.0), "threat": 4, "quadruped": True},
        
        # Raiders (human enemies)
        "raider_scout": {"speed": "fast", "size": 1.0, "color": (0.6, 0.5, 0.4, 1.0), "threat": 2, "human": True},
        "raider_gunner": {"speed": "medium", "size": 1.05, "color": (0.55, 0.45, 0.38, 1.0), "threat": 3, "human": True, "armed": True},
        "raider_heavy": {"speed": "slow", "size": 1.2, "color": (0.5, 0.42, 0.35, 1.0), "threat": 4, "human": True, "armored": True},
    }

    def generate(
        self,
        seed: int | None = None,
        enemy_type: str = "zombie_walker",
        size: float = 1.0,
        variation: float = 1.0,
        damage_level: float = 0.0,
    ) -> bpy.types.Object:
        rng = Random(seed)
        self.cleanup_old_versions(f"enemy_{enemy_type}")
        self._ensure_object_mode()
        self._deselect_all()

        config = self.ENEMY_TYPES.get(enemy_type, self.ENEMY_TYPES["zombie_walker"])
        base_size = config.get("size", 1.0) * size
        color = config.get("color", (0.45, 0.55, 0.4, 1.0))

        if config.get("quadruped"):
            parts = self._create_quadruped(base_size, rng, config)
        elif config.get("human"):
            parts = self._create_human_enemy(base_size, rng, config)
        elif config.get("crawling"):
            parts = self._create_crawler(base_size, rng, config)
        else:
            parts = self._create_zombie(base_size, rng, config)

        # Create and apply material
        mat = self._create_enemy_material(color, config, rng, damage_level)
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
        result.name = f"enemy_{enemy_type}_v001"
        return result

    def _create_zombie(self, size: float, rng: Random, config: dict) -> list:
        parts = []
        is_bloated = config.get("bloated", False)
        is_armored = config.get("armored", False)
        is_boss = config.get("boss", False)

        # Torso
        torso_scale = 1.4 if is_bloated else (1.2 if is_armored else 1.0)
        bpy.ops.mesh.primitive_cube_add(
            size=0.5 * size * torso_scale,
            location=(0, 0, 0.85 * size)
        )
        torso = bpy.context.active_object
        torso.scale.x *= 0.85
        torso.scale.y *= 0.5 if not is_bloated else 0.8
        torso.name = "enemy_torso"
        parts.append(torso)

        # Head
        head_size = 0.3 if not is_boss else 0.4
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=8,
            radius=head_size * size,
            location=(0, 0, 1.35 * size)
        )
        head = bpy.context.active_object
        head.scale.y *= 0.9
        head.name = "enemy_head"
        parts.append(head)

        # Legs
        leg_offset = 0.12 * size
        for side, offset in [("L", -leg_offset), ("R", leg_offset)]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.12 * size,
                location=(0, offset, 0.4 * size)
            )
            leg = bpy.context.active_object
            leg.scale.z = 2.5
            leg.scale.x = 0.9
            leg.name = f"enemy_leg_{side}"
            parts.append(leg)

        # Arms
        arm_offset = 0.28 * size * torso_scale
        for side, offset in [("L", -arm_offset), ("R", arm_offset)]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.1 * size,
                location=(0, offset, 0.95 * size)
            )
            arm = bpy.context.active_object
            arm.scale.x = 1.8
            arm.scale.z = 1.2
            arm.rotation_euler[1] = rng.uniform(-0.4, 0.4)
            arm.rotation_euler[0] = rng.uniform(-0.2, 0.2)
            arm.name = f"enemy_arm_{side}"
            parts.append(arm)

        # Extra features for special types
        if is_armored:
            self._add_armor_plates(parts, size, rng)
        
        if config.get("ranged"):
            self._add_spitter_features(parts, size, rng)

        return parts

    def _create_crawler(self, size: float, rng: Random, config: dict) -> list:
        parts = []

        # Low torso
        bpy.ops.mesh.primitive_cube_add(
            size=0.45 * size,
            location=(0, 0, 0.2 * size)
        )
        torso = bpy.context.active_object
        torso.scale = (1.2, 0.6, 0.4)
        torso.rotation_euler[1] = 0.1
        torso.name = "crawler_torso"
        parts.append(torso)

        # Head
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=10, ring_count=6,
            radius=0.18 * size,
            location=(0.25 * size, 0, 0.3 * size)
        )
        head = bpy.context.active_object
        head.name = "crawler_head"
        parts.append(head)

        # Arms (reaching forward)
        for side, offset in [("L", -0.15 * size), ("R", 0.15 * size)]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.08 * size,
                location=(0.35 * size, offset, 0.15 * size)
            )
            arm = bpy.context.active_object
            arm.scale = (2.5, 0.8, 0.6)
            arm.name = f"crawler_arm_{side}"
            parts.append(arm)

        return parts

    def _create_quadruped(self, size: float, rng: Random, config: dict) -> list:
        parts = []

        # Body
        bpy.ops.mesh.primitive_cube_add(
            size=0.4 * size,
            location=(0, 0, 0.4 * size)
        )
        body = bpy.context.active_object
        body.scale = (1.8, 0.7, 0.8)
        body.name = "animal_body"
        parts.append(body)

        # Head
        bpy.ops.mesh.primitive_cube_add(
            size=0.2 * size,
            location=(0.4 * size, 0, 0.5 * size)
        )
        head = bpy.context.active_object
        head.scale = (1.2, 0.8, 0.9)
        head.name = "animal_head"
        parts.append(head)

        # Legs (4)
        leg_positions = [
            (0.25 * size, -0.12 * size, "FL"),
            (0.25 * size, 0.12 * size, "FR"),
            (-0.25 * size, -0.12 * size, "BL"),
            (-0.25 * size, 0.12 * size, "BR"),
        ]
        for x, y, name in leg_positions:
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6, radius=0.04 * size, depth=0.35 * size,
                location=(x, y, 0.18 * size)
            )
            leg = bpy.context.active_object
            leg.name = f"animal_leg_{name}"
            parts.append(leg)

        # Tail
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6, radius=0.025 * size, depth=0.25 * size,
            location=(-0.45 * size, 0, 0.45 * size)
        )
        tail = bpy.context.active_object
        tail.rotation_euler[1] = -0.8
        tail.name = "animal_tail"
        parts.append(tail)

        return parts

    def _create_human_enemy(self, size: float, rng: Random, config: dict) -> list:
        parts = []
        is_armored = config.get("armored", False)

        # Torso
        bpy.ops.mesh.primitive_cube_add(
            size=0.45 * size,
            location=(0, 0, 0.9 * size)
        )
        torso = bpy.context.active_object
        torso.scale = (0.9, 0.45, 1.0)
        torso.name = "raider_torso"
        parts.append(torso)

        # Head with bandana/mask
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=12, ring_count=8,
            radius=0.18 * size,
            location=(0, 0, 1.35 * size)
        )
        head = bpy.context.active_object
        head.name = "raider_head"
        parts.append(head)

        # Legs
        for side, offset in [("L", -0.1 * size), ("R", 0.1 * size)]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.1 * size,
                location=(0, offset, 0.4 * size)
            )
            leg = bpy.context.active_object
            leg.scale.z = 2.8
            leg.name = f"raider_leg_{side}"
            parts.append(leg)

        # Arms
        for side, offset in [("L", -0.25 * size), ("R", 0.25 * size)]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.08 * size,
                location=(0, offset, 0.95 * size)
            )
            arm = bpy.context.active_object
            arm.scale = (1.6, 0.9, 1.0)
            arm.name = f"raider_arm_{side}"
            parts.append(arm)

        if is_armored:
            # Vest/armor
            bpy.ops.mesh.primitive_cube_add(
                size=0.48 * size,
                location=(0, 0, 0.9 * size)
            )
            vest = bpy.context.active_object
            vest.scale = (0.95, 0.5, 0.85)
            vest.name = "raider_vest"
            parts.append(vest)

        return parts

    def _add_armor_plates(self, parts: list, size: float, rng: Random) -> None:
        # Shoulder plates
        for offset in [-0.35 * size, 0.35 * size]:
            bpy.ops.mesh.primitive_cube_add(
                size=0.15 * size,
                location=(0, offset, 1.1 * size)
            )
            plate = bpy.context.active_object
            plate.scale = (0.8, 1.2, 0.4)
            plate.name = "armor_plate"
            parts.append(plate)

    def _add_spitter_features(self, parts: list, size: float, rng: Random) -> None:
        # Enlarged jaw/mouth area
        bpy.ops.mesh.primitive_cube_add(
            size=0.12 * size,
            location=(0.1 * size, 0, 1.25 * size)
        )
        jaw = bpy.context.active_object
        jaw.scale = (1.5, 1.2, 0.8)
        jaw.name = "spitter_jaw"
        parts.append(jaw)

    def _create_enemy_material(self, color: tuple, config: dict, rng: Random, damage: float) -> bpy.types.Material:
        mat_name = "Enemy_Skin" if not config.get("human") else "Raider_Skin"
        mat = self.create_material(mat_name, color)
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        bsdf = nodes.get("Principled BSDF")

        if config.get("human"):
            bsdf.inputs["Roughness"].default_value = 0.6
        else:
            bsdf.inputs["Roughness"].default_value = 0.75
            bsdf.inputs["Subsurface Weight"].default_value = 0.1

        noise = self.add_noise(nodes, scale=8.0, detail=1.5)
        dark_color = (color[0] * 0.7, color[1] * 0.75, color[2] * 0.65, 1.0)
        ramp = self.add_color_ramp(nodes, colors=[color, dark_color], positions=[0.25, 0.8])
        self.link(links, noise.outputs["Fac"], ramp.inputs["Fac"])
        self.link(links, ramp.outputs["Color"], bsdf.inputs["Base Color"])

        return mat
