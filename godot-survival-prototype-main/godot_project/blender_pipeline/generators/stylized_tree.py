"""
Stylized Low-Poly Tree Generator
================================
Creates natural-looking trees with proper branching structure.
Not lollipop trees - actual tree shapes with branches.
"""

import bpy
import bmesh
import math
import random
from mathutils import Vector, Matrix, Euler

class StylizedTreeGenerator:
    """Generates stylized low-poly trees with natural branching."""
    
    TREE_TYPES = {
        'oak': {
            'trunk_height': 2.0,
            'trunk_radius': 0.25,
            'canopy_radius': 2.5,
            'canopy_height': 3.0,
            'branch_count': 5,
            'trunk_color': (0.35, 0.22, 0.10, 1.0),
            'leaf_color': (0.25, 0.45, 0.15, 1.0),
            'canopy_style': 'rounded',
        },
        'pine': {
            'trunk_height': 4.0,
            'trunk_radius': 0.2,
            'canopy_radius': 1.5,
            'canopy_height': 5.0,
            'branch_count': 0,
            'trunk_color': (0.30, 0.18, 0.08, 1.0),
            'leaf_color': (0.12, 0.28, 0.12, 1.0),
            'canopy_style': 'cone',
        },
        'birch': {
            'trunk_height': 3.5,
            'trunk_radius': 0.15,
            'canopy_radius': 1.8,
            'canopy_height': 2.5,
            'branch_count': 4,
            'trunk_color': (0.85, 0.82, 0.78, 1.0),  # White bark
            'leaf_color': (0.35, 0.55, 0.20, 1.0),   # Light green
            'canopy_style': 'sparse',
        },
        'dead': {
            'trunk_height': 3.0,
            'trunk_radius': 0.2,
            'canopy_radius': 0,
            'canopy_height': 0,
            'branch_count': 6,
            'trunk_color': (0.25, 0.20, 0.15, 1.0),
            'leaf_color': (0.0, 0.0, 0.0, 0.0),  # No leaves
            'canopy_style': 'none',
        },
        'bush': {
            'trunk_height': 0.3,
            'trunk_radius': 0.08,
            'canopy_radius': 0.8,
            'canopy_height': 0.9,
            'branch_count': 0,
            'trunk_color': (0.30, 0.20, 0.10, 1.0),
            'leaf_color': (0.20, 0.40, 0.12, 1.0),
            'canopy_style': 'bush',
        },
    }
    
    def __init__(self, tree_type='oak', scale=1.0, seed=None):
        self.tree_type = tree_type
        self.config = self.TREE_TYPES.get(tree_type, self.TREE_TYPES['oak'])
        self.scale = scale
        self.seed = seed if seed else random.randint(0, 99999)
        random.seed(self.seed)
        self.materials = {}
        
    def create_material(self, name, color):
        """Create a simple colored material."""
        mat = bpy.data.materials.new(name=f"tree_{self.tree_type}_{name}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.8
        return mat
    
    def setup_materials(self):
        """Create materials for trunk and leaves."""
        self.materials['trunk'] = self.create_material('trunk', self.config['trunk_color'])
        if self.config['leaf_color'][3] > 0:
            self.materials['leaves'] = self.create_material('leaves', self.config['leaf_color'])
    
    def create_trunk(self):
        """Create a natural-looking tree trunk."""
        height = self.config['trunk_height'] * self.scale
        radius = self.config['trunk_radius'] * self.scale
        
        # Create base cylinder
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=8,
            radius=radius,
            depth=height,
            location=(0, 0, height / 2)
        )
        trunk = bpy.context.active_object
        trunk.name = "Trunk"
        
        # Taper the trunk (thinner at top)
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(trunk.data)
        
        for v in bm.verts:
            # Normalize height position (0 at bottom, 1 at top)
            t = (v.co.z + height/2) / height
            taper = 1.0 - (t * 0.5)  # 50% thinner at top
            v.co.x *= taper
            v.co.y *= taper
            
            # Add slight organic variation
            if 0.1 < t < 0.9:
                v.co.x += random.uniform(-0.02, 0.02) * self.scale
                v.co.y += random.uniform(-0.02, 0.02) * self.scale
        
        bmesh.update_edit_mesh(trunk.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        trunk.data.materials.append(self.materials['trunk'])
        return trunk, height
    
    def create_branch(self, start_pos, direction, length, radius):
        """Create a single branch."""
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=6,
            radius=radius,
            depth=length,
            location=start_pos
        )
        branch = bpy.context.active_object
        
        # Rotate to point in direction
        branch.rotation_euler = direction.to_track_quat('Z', 'Y').to_euler()
        
        # Move so base is at start_pos
        offset = direction.normalized() * (length / 2)
        branch.location = start_pos + offset
        
        bpy.ops.object.transform_apply(rotation=True)
        
        # Taper
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(branch.data)
        for v in bm.verts:
            t = (v.co.z + length/2) / length
            taper = 1.0 - (t * 0.6)
            v.co.x *= taper
            v.co.y *= taper
        bmesh.update_edit_mesh(branch.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        branch.data.materials.append(self.materials['trunk'])
        return branch
    
    def create_branches(self, trunk_height):
        """Create branches coming off the trunk."""
        branch_count = self.config['branch_count']
        if branch_count == 0:
            return []
        
        branches = []
        radius = self.config['trunk_radius'] * self.scale
        
        for i in range(branch_count):
            # Distribute around trunk
            angle = (i / branch_count) * math.pi * 2 + random.uniform(-0.3, 0.3)
            height_factor = 0.5 + (i / branch_count) * 0.4  # Branches in upper half
            
            start_z = trunk_height * height_factor
            start_x = math.cos(angle) * radius * 0.8
            start_y = math.sin(angle) * radius * 0.8
            start_pos = Vector((start_x, start_y, start_z))
            
            # Branch direction (outward and slightly up)
            dir_x = math.cos(angle)
            dir_y = math.sin(angle)
            dir_z = random.uniform(0.2, 0.5)
            direction = Vector((dir_x, dir_y, dir_z)).normalized()
            
            # Branch size decreases with height
            branch_len = (0.8 + random.uniform(0, 0.4)) * self.scale * (1.2 - height_factor * 0.5)
            branch_rad = radius * 0.3 * (1.2 - height_factor * 0.4)
            
            branch = self.create_branch(start_pos, direction, branch_len, branch_rad)
            branch.name = f"Branch_{i}"
            branches.append(branch)
            
            # Sub-branches for dead trees
            if self.tree_type == 'dead' and random.random() > 0.5:
                end_pos = start_pos + direction * branch_len
                sub_dir = Vector((
                    dir_x + random.uniform(-0.5, 0.5),
                    dir_y + random.uniform(-0.5, 0.5),
                    random.uniform(-0.2, 0.4)
                )).normalized()
                sub_branch = self.create_branch(end_pos, sub_dir, branch_len * 0.5, branch_rad * 0.5)
                sub_branch.name = f"SubBranch_{i}"
                branches.append(sub_branch)
        
        return branches
    
    def create_canopy_rounded(self, trunk_height):
        """Create a rounded, natural canopy using multiple overlapping spheres."""
        canopy_r = self.config['canopy_radius'] * self.scale
        canopy_h = self.config['canopy_height'] * self.scale
        center_z = trunk_height + canopy_h * 0.3
        
        spheres = []
        
        # Main central sphere
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2,
            radius=canopy_r * 0.7,
            location=(0, 0, center_z)
        )
        main = bpy.context.active_object
        main.scale.z = 0.85
        spheres.append(main)
        
        # Surrounding smaller spheres for natural look
        for i in range(5):
            angle = i * math.pi * 2 / 5 + random.uniform(-0.2, 0.2)
            dist = canopy_r * 0.4
            x = math.cos(angle) * dist
            y = math.sin(angle) * dist
            z = center_z + random.uniform(-0.3, 0.3) * self.scale
            
            bpy.ops.mesh.primitive_ico_sphere_add(
                subdivisions=2,
                radius=canopy_r * (0.4 + random.uniform(0, 0.15)),
                location=(x, y, z)
            )
            sphere = bpy.context.active_object
            sphere.scale.z = random.uniform(0.7, 0.9)
            spheres.append(sphere)
        
        # Top cluster
        for i in range(3):
            angle = i * math.pi * 2 / 3
            dist = canopy_r * 0.25
            x = math.cos(angle) * dist
            y = math.sin(angle) * dist
            z = center_z + canopy_h * 0.35
            
            bpy.ops.mesh.primitive_ico_sphere_add(
                subdivisions=2,
                radius=canopy_r * 0.35,
                location=(x, y, z)
            )
            spheres.append(bpy.context.active_object)
        
        # Apply scale and join
        for s in spheres:
            bpy.ops.object.select_all(action='DESELECT')
            s.select_set(True)
            bpy.context.view_layer.objects.active = s
            bpy.ops.object.transform_apply(scale=True)
        
        # Join all spheres
        bpy.ops.object.select_all(action='DESELECT')
        for s in spheres:
            s.select_set(True)
        bpy.context.view_layer.objects.active = spheres[0]
        bpy.ops.object.join()
        
        canopy = bpy.context.active_object
        canopy.name = "Canopy"
        canopy.data.materials.append(self.materials['leaves'])
        
        return canopy
    
    def create_canopy_cone(self, trunk_height):
        """Create a conical pine tree canopy with layers."""
        canopy_r = self.config['canopy_radius'] * self.scale
        canopy_h = self.config['canopy_height'] * self.scale
        
        layers = []
        num_layers = 5
        
        for i in range(num_layers):
            # Each layer is a cone, getting smaller toward top
            layer_height = canopy_h / num_layers * 1.3
            layer_z = trunk_height * 0.6 + (i / num_layers) * canopy_h
            layer_radius = canopy_r * (1 - i / num_layers * 0.6)
            
            bpy.ops.mesh.primitive_cone_add(
                vertices=8,
                radius1=layer_radius,
                radius2=layer_radius * 0.3,
                depth=layer_height,
                location=(0, 0, layer_z + layer_height/2)
            )
            layer = bpy.context.active_object
            layers.append(layer)
        
        # Join layers
        bpy.ops.object.select_all(action='DESELECT')
        for layer in layers:
            layer.select_set(True)
        bpy.context.view_layer.objects.active = layers[0]
        bpy.ops.object.join()
        
        canopy = bpy.context.active_object
        canopy.name = "Canopy"
        canopy.data.materials.append(self.materials['leaves'])
        
        return canopy
    
    def create_canopy_sparse(self, trunk_height):
        """Create sparse canopy clusters (for birch-like trees)."""
        canopy_r = self.config['canopy_radius'] * self.scale
        canopy_h = self.config['canopy_height'] * self.scale
        center_z = trunk_height + canopy_h * 0.2
        
        clusters = []
        
        # Create several leaf clusters
        for i in range(8):
            angle = i * math.pi * 2 / 8 + random.uniform(-0.3, 0.3)
            dist = canopy_r * random.uniform(0.3, 0.7)
            x = math.cos(angle) * dist
            y = math.sin(angle) * dist
            z = center_z + random.uniform(-0.5, 0.7) * canopy_h
            
            bpy.ops.mesh.primitive_ico_sphere_add(
                subdivisions=1,
                radius=canopy_r * random.uniform(0.25, 0.4),
                location=(x, y, z)
            )
            cluster = bpy.context.active_object
            cluster.scale = (
                random.uniform(0.8, 1.2),
                random.uniform(0.8, 1.2),
                random.uniform(0.6, 0.9)
            )
            clusters.append(cluster)
        
        # Apply and join
        for c in clusters:
            bpy.ops.object.select_all(action='DESELECT')
            c.select_set(True)
            bpy.context.view_layer.objects.active = c
            bpy.ops.object.transform_apply(scale=True)
        
        bpy.ops.object.select_all(action='DESELECT')
        for c in clusters:
            c.select_set(True)
        bpy.context.view_layer.objects.active = clusters[0]
        bpy.ops.object.join()
        
        canopy = bpy.context.active_object
        canopy.name = "Canopy"
        canopy.data.materials.append(self.materials['leaves'])
        
        return canopy
    
    def create_canopy_bush(self, trunk_height):
        """Create a low, dense bush canopy."""
        canopy_r = self.config['canopy_radius'] * self.scale
        canopy_h = self.config['canopy_height'] * self.scale
        center_z = trunk_height + canopy_h * 0.4
        
        # Single irregular sphere for bush
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2,
            radius=canopy_r,
            location=(0, 0, center_z)
        )
        canopy = bpy.context.active_object
        canopy.scale = (1.0, 1.0, canopy_h / canopy_r)
        bpy.ops.object.transform_apply(scale=True)
        
        # Add some irregularity
        bpy.ops.object.mode_set(mode='EDIT')
        bm = bmesh.from_edit_mesh(canopy.data)
        for v in bm.verts:
            v.co += Vector((
                random.uniform(-0.1, 0.1) * self.scale,
                random.uniform(-0.1, 0.1) * self.scale,
                random.uniform(-0.05, 0.05) * self.scale
            ))
        bmesh.update_edit_mesh(canopy.data)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        canopy.name = "Canopy"
        canopy.data.materials.append(self.materials['leaves'])
        
        return canopy
    
    def generate(self, name=None):
        """Generate the complete tree."""
        if name is None:
            name = f"Tree_{self.tree_type}"
        
        bpy.ops.object.select_all(action='DESELECT')
        self.setup_materials()
        
        all_parts = []
        
        # Create trunk
        trunk, trunk_height = self.create_trunk()
        all_parts.append(trunk)
        
        # Create branches
        branches = self.create_branches(trunk_height)
        all_parts.extend(branches)
        
        # Create canopy based on style
        style = self.config['canopy_style']
        canopy = None
        
        if style == 'rounded':
            canopy = self.create_canopy_rounded(trunk_height)
        elif style == 'cone':
            canopy = self.create_canopy_cone(trunk_height)
        elif style == 'sparse':
            canopy = self.create_canopy_sparse(trunk_height)
        elif style == 'bush':
            canopy = self.create_canopy_bush(trunk_height)
        # 'none' style has no canopy
        
        if canopy:
            all_parts.append(canopy)
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        for part in all_parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = all_parts[0]
        bpy.ops.object.join()
        
        tree = bpy.context.active_object
        tree.name = name
        
        # Set origin to base of trunk
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bpy.context.scene.cursor.location = (0, 0, 0)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        
        return tree


def generate_tree(name, tree_type='oak', scale=1.0, seed=None):
    """Convenience function to generate a tree."""
    generator = StylizedTreeGenerator(tree_type=tree_type, scale=scale, seed=seed)
    return generator.generate(name)


if __name__ == "__main__":
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    # Generate test trees
    types = ['oak', 'pine', 'birch', 'dead', 'bush']
    for i, tree_type in enumerate(types):
        gen = StylizedTreeGenerator(tree_type=tree_type, scale=1.0)
        tree = gen.generate(f"Tree_{tree_type}")
        tree.location.x = i * 5
