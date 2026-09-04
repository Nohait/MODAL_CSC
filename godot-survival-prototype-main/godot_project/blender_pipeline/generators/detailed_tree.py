"""
Detailed Tree Generator - Creates realistic trees with proper trunks,
branches, and foliage for a survival game environment.
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector, Matrix


class DetailedTreeGenerator:
    """Generate detailed tree models with natural branching and foliage."""
    
    TREE_TYPES = {
        "pine_01": {
            "height": 8.0,
            "trunk_radius": 0.25,
            "trunk_taper": 0.6,
            "branch_style": "conifer",
            "foliage_style": "needles",
            "branch_layers": 8,
            "branch_angle": 85,
            "foliage_color": (0.15, 0.35, 0.12),
            "bark_color": (0.25, 0.15, 0.08)
        },
        "pine_02": {
            "height": 6.5,
            "trunk_radius": 0.20,
            "trunk_taper": 0.55,
            "branch_style": "conifer",
            "foliage_style": "needles",
            "branch_layers": 6,
            "branch_angle": 80,
            "foliage_color": (0.12, 0.30, 0.10),
            "bark_color": (0.28, 0.18, 0.10)
        },
        "pine_03": {
            "height": 10.0,
            "trunk_radius": 0.35,
            "trunk_taper": 0.65,
            "branch_style": "conifer",
            "foliage_style": "needles",
            "branch_layers": 10,
            "branch_angle": 88,
            "foliage_color": (0.18, 0.38, 0.15),
            "bark_color": (0.22, 0.12, 0.06)
        },
        "oak_01": {
            "height": 7.0,
            "trunk_radius": 0.4,
            "trunk_taper": 0.5,
            "branch_style": "deciduous",
            "foliage_style": "clusters",
            "branch_layers": 5,
            "branch_angle": 45,
            "foliage_color": (0.20, 0.42, 0.15),
            "bark_color": (0.20, 0.12, 0.06)
        },
        "oak_02": {
            "height": 9.0,
            "trunk_radius": 0.55,
            "trunk_taper": 0.45,
            "branch_style": "deciduous",
            "foliage_style": "clusters",
            "branch_layers": 6,
            "branch_angle": 50,
            "foliage_color": (0.22, 0.45, 0.18),
            "bark_color": (0.18, 0.10, 0.05)
        },
        "birch_01": {
            "height": 8.0,
            "trunk_radius": 0.15,
            "trunk_taper": 0.7,
            "branch_style": "sparse",
            "foliage_style": "clusters",
            "branch_layers": 6,
            "branch_angle": 55,
            "foliage_color": (0.35, 0.55, 0.22),
            "bark_color": (0.85, 0.82, 0.78)
        },
        "dead_01": {
            "height": 5.0,
            "trunk_radius": 0.25,
            "trunk_taper": 0.7,
            "branch_style": "dead",
            "foliage_style": "none",
            "branch_layers": 4,
            "branch_angle": 35,
            "foliage_color": (0.0, 0.0, 0.0),
            "bark_color": (0.15, 0.12, 0.10)
        },
        "dead_02": {
            "height": 4.0,
            "trunk_radius": 0.20,
            "trunk_taper": 0.75,
            "branch_style": "dead",
            "foliage_style": "none",
            "branch_layers": 3,
            "branch_angle": 40,
            "foliage_color": (0.0, 0.0, 0.0),
            "bark_color": (0.12, 0.10, 0.08)
        },
        "palm_01": {
            "height": 6.0,
            "trunk_radius": 0.18,
            "trunk_taper": 0.9,
            "branch_style": "palm",
            "foliage_style": "fronds",
            "branch_layers": 1,
            "branch_angle": 30,
            "foliage_color": (0.25, 0.50, 0.18),
            "bark_color": (0.35, 0.28, 0.18)
        },
        "stump_01": {
            "height": 0.6,
            "trunk_radius": 0.35,
            "trunk_taper": 0.9,
            "branch_style": "none",
            "foliage_style": "none",
            "branch_layers": 0,
            "branch_angle": 0,
            "foliage_color": (0.0, 0.0, 0.0),
            "bark_color": (0.22, 0.15, 0.08)
        }
    }
    
    def __init__(self, seed=None):
        if seed is not None:
            random.seed(seed)
    
    def generate(self, name: str, tree_type: str = "pine_01") -> bpy.types.Object:
        """Generate a detailed tree of the specified type."""
        config = self.TREE_TYPES.get(tree_type, self.TREE_TYPES["pine_01"])
        
        # Create materials
        bark_mat = self._create_bark_material(f"mat_{name}_bark", config["bark_color"])
        if config["foliage_style"] != "none":
            foliage_mat = self._create_foliage_material(f"mat_{name}_foliage", config["foliage_color"])
        else:
            foliage_mat = None
        
        parts = []
        
        # Create trunk
        trunk = self._create_trunk(config)
        trunk.data.materials.append(bark_mat)
        parts.append(trunk)
        
        # Create branches based on style
        if config["branch_style"] == "conifer":
            branches = self._create_conifer_branches(config, bark_mat, foliage_mat)
            parts.extend(branches)
        elif config["branch_style"] == "deciduous":
            branches = self._create_deciduous_branches(config, bark_mat, foliage_mat)
            parts.extend(branches)
        elif config["branch_style"] == "sparse":
            branches = self._create_sparse_branches(config, bark_mat, foliage_mat)
            parts.extend(branches)
        elif config["branch_style"] == "dead":
            branches = self._create_dead_branches(config, bark_mat)
            parts.extend(branches)
        elif config["branch_style"] == "palm":
            fronds = self._create_palm_fronds(config, foliage_mat)
            parts.extend(fronds)
        
        # Add roots for larger trees
        if config["trunk_radius"] > 0.25:
            roots = self._create_roots(config, bark_mat)
            parts.extend(roots)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in parts:
            if part is not None:
                part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        
        tree = bpy.context.active_object
        tree.name = name
        
        # Apply smooth shading to trunk only
        self._apply_mixed_shading(tree)
        
        # Set origin to bottom
        self._set_origin_to_bottom(tree)
        
        return tree
    
    def _create_trunk(self, config: dict) -> bpy.types.Object:
        """Create the main trunk with natural taper and bends."""
        height = config["height"]
        base_radius = config["trunk_radius"]
        taper = config["trunk_taper"]
        
        # Create base cylinder with more segments for detail
        segments = max(8, int(height * 2))
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=12,
            radius=base_radius,
            depth=height,
            end_fill_type='NGON'
        )
        trunk = bpy.context.active_object
        trunk.location.z = height / 2
        
        bm = bmesh.new()
        bm.from_mesh(trunk.data)
        bm.verts.ensure_lookup_table()
        
        # Apply taper and natural variation
        for v in bm.verts:
            # Normalize height position (0 at base, 1 at top)
            local_z = v.co.z + height / 2
            height_factor = local_z / height
            
            # Taper radius toward top
            radius_scale = 1.0 - (height_factor * (1.0 - taper))
            
            # Add slight bend/sway
            bend = math.sin(height_factor * math.pi * 0.5) * 0.1 * base_radius
            
            # Add bark roughness
            noise_scale = 0.02 * base_radius
            if height_factor > 0.05 and height_factor < 0.95:  # Not at ends
                noise_x = random.uniform(-noise_scale, noise_scale)
                noise_y = random.uniform(-noise_scale, noise_scale)
            else:
                noise_x = noise_y = 0
            
            # Apply transformations
            v.co.x = v.co.x * radius_scale + bend + noise_x
            v.co.y = v.co.y * radius_scale + noise_y
        
        bm.to_mesh(trunk.data)
        bm.free()
        
        return trunk
    
    def _create_conifer_branches(self, config: dict, bark_mat, foliage_mat) -> list:
        """Create conifer-style branches with needle clusters."""
        parts = []
        height = config["height"]
        trunk_radius = config["trunk_radius"]
        layers = config["branch_layers"]
        base_angle = math.radians(config["branch_angle"])
        
        # Start branches from about 30% up the trunk
        start_height = height * 0.3
        layer_spacing = (height - start_height) / (layers + 1)
        
        for layer in range(layers):
            layer_height = start_height + layer_spacing * (layer + 1)
            height_factor = layer_height / height
            
            # Branches get shorter toward top
            branch_length = trunk_radius * 6 * (1.0 - height_factor * 0.7)
            branch_radius = trunk_radius * 0.15 * (1.0 - height_factor * 0.5)
            
            # Branches droop more at bottom
            droop = base_angle - (1.0 - height_factor) * math.radians(20)
            
            # 4-6 branches per layer, rotated
            branches_in_layer = random.randint(4, 6)
            rotation_offset = random.uniform(0, math.pi * 2)
            
            for i in range(branches_in_layer):
                angle = rotation_offset + (i / branches_in_layer) * math.pi * 2
                
                # Create branch
                branch = self._create_branch(branch_length, branch_radius, droop)
                branch.location = (0, 0, layer_height)
                branch.rotation_euler.z = angle
                branch.data.materials.append(bark_mat)
                parts.append(branch)
                
                # Add needle clusters along branch
                if foliage_mat:
                    num_clusters = max(2, int(branch_length))
                    for c in range(num_clusters):
                        cluster_pos = (c + 1) / (num_clusters + 1)
                        
                        cluster = self._create_needle_cluster(branch_length * 0.35 * (1 - cluster_pos * 0.5))
                        
                        # Position along branch
                        cluster.location = (
                            math.cos(droop) * branch_length * cluster_pos,
                            0,
                            layer_height - math.sin(droop) * branch_length * cluster_pos * 0.3
                        )
                        cluster.rotation_euler.z = angle + random.uniform(-0.3, 0.3)
                        cluster.data.materials.append(foliage_mat)
                        parts.append(cluster)
        
        # Top tuft
        if foliage_mat:
            top_cluster = self._create_needle_cluster(trunk_radius * 3)
            top_cluster.location = (0, 0, height - trunk_radius)
            top_cluster.data.materials.append(foliage_mat)
            parts.append(top_cluster)
        
        return parts
    
    def _create_deciduous_branches(self, config: dict, bark_mat, foliage_mat) -> list:
        """Create deciduous tree branches with leaf clusters."""
        parts = []
        height = config["height"]
        trunk_radius = config["trunk_radius"]
        layers = config["branch_layers"]
        
        # Main structural branches
        start_height = height * 0.35
        
        for layer in range(layers):
            height_factor = (layer + 1) / (layers + 1)
            layer_height = start_height + (height - start_height) * height_factor
            
            branch_length = trunk_radius * 4 * (1.0 - height_factor * 0.4)
            branch_radius = trunk_radius * 0.25 * (1.0 - height_factor * 0.5)
            
            # Fewer, larger branches
            branches_in_layer = random.randint(2, 4)
            rotation_offset = random.uniform(0, math.pi * 2) + layer * 0.5
            
            for i in range(branches_in_layer):
                angle = rotation_offset + (i / branches_in_layer) * math.pi * 2
                angle += random.uniform(-0.3, 0.3)
                
                # Branch goes up and out
                branch_angle = math.radians(30 + random.uniform(-10, 20))
                
                branch = self._create_branch(branch_length, branch_radius, branch_angle)
                branch.location = (0, 0, layer_height)
                branch.rotation_euler.z = angle
                branch.data.materials.append(bark_mat)
                parts.append(branch)
                
                # Add leaf clusters at branch ends and along branch
                if foliage_mat:
                    # End cluster (large)
                    end_x = math.cos(branch_angle) * branch_length
                    end_z = math.sin(branch_angle) * branch_length
                    
                    cluster = self._create_leaf_cluster(branch_length * 0.8)
                    cluster.location = (
                        math.cos(angle) * end_x,
                        math.sin(angle) * end_x,
                        layer_height + end_z
                    )
                    cluster.data.materials.append(foliage_mat)
                    parts.append(cluster)
                    
                    # Mid-branch cluster
                    mid_cluster = self._create_leaf_cluster(branch_length * 0.5)
                    mid_cluster.location = (
                        math.cos(angle) * end_x * 0.6,
                        math.sin(angle) * end_x * 0.6,
                        layer_height + end_z * 0.6
                    )
                    mid_cluster.data.materials.append(foliage_mat)
                    parts.append(mid_cluster)
        
        return parts
    
    def _create_sparse_branches(self, config: dict, bark_mat, foliage_mat) -> list:
        """Create sparse birch-style branches."""
        parts = []
        height = config["height"]
        trunk_radius = config["trunk_radius"]
        
        # Birch has thin, drooping branches
        num_branches = random.randint(8, 14)
        
        for _ in range(num_branches):
            branch_height = height * random.uniform(0.4, 0.85)
            branch_length = trunk_radius * random.uniform(2, 4)
            branch_radius = trunk_radius * random.uniform(0.05, 0.1)
            angle = random.uniform(0, math.pi * 2)
            
            # Slight upward then droop
            branch_angle = math.radians(random.uniform(20, 50))
            
            branch = self._create_branch(branch_length, branch_radius, branch_angle, droop=True)
            branch.location = (0, 0, branch_height)
            branch.rotation_euler.z = angle
            branch.data.materials.append(bark_mat)
            parts.append(branch)
            
            if foliage_mat:
                cluster = self._create_leaf_cluster(branch_length * 0.4)
                end_x = math.cos(branch_angle) * branch_length
                end_z = math.sin(branch_angle) * branch_length
                cluster.location = (
                    math.cos(angle) * end_x,
                    math.sin(angle) * end_x,
                    branch_height + end_z * 0.7
                )
                cluster.data.materials.append(foliage_mat)
                parts.append(cluster)
        
        return parts
    
    def _create_dead_branches(self, config: dict, bark_mat) -> list:
        """Create broken, dead tree branches."""
        parts = []
        height = config["height"]
        trunk_radius = config["trunk_radius"]
        
        num_branches = random.randint(3, 7)
        
        for _ in range(num_branches):
            branch_height = height * random.uniform(0.25, 0.75)
            branch_length = trunk_radius * random.uniform(1.5, 3.0)
            branch_radius = trunk_radius * random.uniform(0.1, 0.2)
            angle = random.uniform(0, math.pi * 2)
            
            # Random angles for dead branches
            branch_angle = math.radians(random.uniform(-10, 40))
            
            branch = self._create_broken_branch(branch_length, branch_radius, branch_angle)
            branch.location = (0, 0, branch_height)
            branch.rotation_euler.z = angle
            branch.data.materials.append(bark_mat)
            parts.append(branch)
        
        return parts
    
    def _create_palm_fronds(self, config: dict, foliage_mat) -> list:
        """Create palm tree fronds at the top."""
        parts = []
        height = config["height"]
        trunk_radius = config["trunk_radius"]
        
        num_fronds = random.randint(6, 10)
        frond_length = trunk_radius * 8
        
        for i in range(num_fronds):
            angle = (i / num_fronds) * math.pi * 2
            
            frond = self._create_palm_frond(frond_length)
            frond.location = (0, 0, height - trunk_radius * 0.5)
            frond.rotation_euler = (
                math.radians(30 + random.uniform(-10, 20)),  # Droop
                0,
                angle
            )
            frond.data.materials.append(foliage_mat)
            parts.append(frond)
        
        return parts
    
    def _create_palm_frond(self, length: float) -> bpy.types.Object:
        """Create a single palm frond."""
        # Create spine
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=length * 0.02,
            depth=length
        )
        frond = bpy.context.active_object
        frond.location.z = length / 2
        
        # Add leaflets
        num_leaflets = 12
        for side in [-1, 1]:
            for i in range(num_leaflets):
                pos = (i + 1) / (num_leaflets + 1)
                leaflet_length = length * 0.3 * (1 - abs(pos - 0.5) * 2)
                
                bpy.ops.mesh.primitive_plane_add(size=1)
                leaflet = bpy.context.active_object
                leaflet.scale = (leaflet_length * 0.15, leaflet_length, 1)
                leaflet.location = (
                    side * leaflet_length * 0.3,
                    0,
                    pos * length
                )
                leaflet.rotation_euler = (
                    math.radians(side * 20),
                    0,
                    side * math.radians(60)
                )
                bpy.ops.object.transform_apply(scale=True)
                
                frond.select_set(True)
                leaflet.select_set(True)
                bpy.context.view_layer.objects.active = frond
                bpy.ops.object.join()
                frond = bpy.context.active_object
                bpy.ops.object.select_all(action='DESELECT')
        
        return frond
    
    def _create_branch(self, length: float, radius: float, angle: float, droop: bool = False) -> bpy.types.Object:
        """Create a single branch."""
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=radius,
            depth=length
        )
        branch = bpy.context.active_object
        
        # Rotate to point outward and up at angle
        branch.rotation_euler.x = angle
        branch.location.x = length / 2 * math.cos(angle)
        branch.location.z = length / 2 * math.sin(angle)
        
        # Taper
        bm = bmesh.new()
        bm.from_mesh(branch.data)
        for v in bm.verts:
            pos = (v.co.z + length / 2) / length
            v.co.x *= 1.0 - pos * 0.7
            v.co.y *= 1.0 - pos * 0.7
            if droop and pos > 0.5:
                v.co.z -= (pos - 0.5) * length * 0.3
        bm.to_mesh(branch.data)
        bm.free()
        
        return branch
    
    def _create_broken_branch(self, length: float, radius: float, angle: float) -> bpy.types.Object:
        """Create a broken/dead branch."""
        branch = self._create_branch(length, radius, angle)
        
        # Add jagged end
        bm = bmesh.new()
        bm.from_mesh(branch.data)
        for v in bm.verts:
            pos = (v.co.z + length / 2) / length
            if pos > 0.8:
                v.co.x += random.uniform(-radius * 0.5, radius * 0.5)
                v.co.y += random.uniform(-radius * 0.5, radius * 0.5)
                v.co.z += random.uniform(-radius * 0.3, radius * 0.3)
        bm.to_mesh(branch.data)
        bm.free()
        
        return branch
    
    def _create_needle_cluster(self, size: float) -> bpy.types.Object:
        """Create a cluster of conifer needles (cone shape)."""
        bpy.ops.mesh.primitive_cone_add(
            vertices=8,
            radius1=size * 0.8,
            radius2=size * 0.15,
            depth=size * 1.5
        )
        cluster = bpy.context.active_object
        
        # Flatten slightly
        cluster.scale.z = 0.4
        bpy.ops.object.transform_apply(scale=True)
        
        # Add noise for more natural look
        bm = bmesh.new()
        bm.from_mesh(cluster.data)
        for v in bm.verts:
            if abs(v.co.z) < size * 0.3:  # Middle section
                v.co.x += random.uniform(-size * 0.1, size * 0.1)
                v.co.y += random.uniform(-size * 0.1, size * 0.1)
        bm.to_mesh(cluster.data)
        bm.free()
        
        return cluster
    
    def _create_leaf_cluster(self, size: float) -> bpy.types.Object:
        """Create a cluster of leaves (sphere shape with variation)."""
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=size)
        cluster = bpy.context.active_object
        
        # Flatten and make irregular
        cluster.scale = (1.2, 1.2, 0.7)
        bpy.ops.object.transform_apply(scale=True)
        
        bm = bmesh.new()
        bm.from_mesh(cluster.data)
        for v in bm.verts:
            v.co += Vector((
                random.uniform(-size * 0.15, size * 0.15),
                random.uniform(-size * 0.15, size * 0.15),
                random.uniform(-size * 0.1, size * 0.1)
            ))
        bm.to_mesh(cluster.data)
        bm.free()
        
        return cluster
    
    def _create_roots(self, config: dict, bark_mat) -> list:
        """Create visible root structures at base."""
        roots = []
        trunk_radius = config["trunk_radius"]
        
        num_roots = random.randint(3, 6)
        
        for i in range(num_roots):
            angle = (i / num_roots) * math.pi * 2 + random.uniform(-0.3, 0.3)
            root_length = trunk_radius * random.uniform(1.5, 2.5)
            root_radius = trunk_radius * random.uniform(0.15, 0.25)
            
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6,
                radius=root_radius,
                depth=root_length
            )
            root = bpy.context.active_object
            
            # Angle down and out
            root.rotation_euler = (
                math.radians(70),  # Mostly horizontal, slight downward
                0,
                angle
            )
            root.location = (
                math.cos(angle) * trunk_radius * 0.7,
                math.sin(angle) * trunk_radius * 0.7,
                0.05
            )
            
            # Taper
            bm = bmesh.new()
            bm.from_mesh(root.data)
            for v in bm.verts:
                pos = (v.co.z + root_length / 2) / root_length
                v.co.x *= 1.0 - pos * 0.8
                v.co.y *= 1.0 - pos * 0.8
            bm.to_mesh(root.data)
            bm.free()
            
            root.data.materials.append(bark_mat)
            roots.append(root)
        
        return roots
    
    # === MATERIALS ===
    
    def _create_bark_material(self, name: str, color: tuple) -> bpy.types.Material:
        """Create bark material with noise texture."""
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        nodes.clear()
        
        output = nodes.new("ShaderNodeOutputMaterial")
        output.location = (600, 0)
        
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.location = (200, 0)
        bsdf.inputs["Roughness"].default_value = 0.85
        
        # Bark texture using noise
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-400, 0)
        noise.inputs["Scale"].default_value = 15.0
        noise.inputs["Detail"].default_value = 6.0
        
        # Stretch noise vertically for bark pattern
        mapping = nodes.new("ShaderNodeMapping")
        mapping.location = (-600, 0)
        mapping.inputs["Scale"].default_value[2] = 3.0  # Stretch Z
        
        texcoord = nodes.new("ShaderNodeTexCoord")
        texcoord.location = (-800, 0)
        
        # Color ramp for bark variation
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (-100, 0)
        ramp.color_ramp.elements[0].position = 0.4
        ramp.color_ramp.elements[0].color = (*color, 1.0)
        ramp.color_ramp.elements[1].position = 0.6
        ramp.color_ramp.elements[1].color = (color[0] * 0.6, color[1] * 0.6, color[2] * 0.6, 1.0)
        
        links.new(texcoord.outputs["Object"], mapping.inputs["Vector"])
        links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _create_foliage_material(self, name: str, color: tuple) -> bpy.types.Material:
        """Create foliage material with color variation."""
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
        
        # Subtle color variation
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-400, 0)
        noise.inputs["Scale"].default_value = 5.0
        
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (-100, 0)
        ramp.color_ramp.elements[0].position = 0.3
        ramp.color_ramp.elements[0].color = (*color, 1.0)
        ramp.color_ramp.elements[1].position = 0.7
        darker = (color[0] * 0.7, color[1] * 0.85, color[2] * 0.7)
        ramp.color_ramp.elements[1].color = (*darker, 1.0)
        
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        
        return mat
    
    def _apply_mixed_shading(self, obj: bpy.types.Object) -> None:
        """Apply smooth shading."""
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.shade_smooth()
    
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
