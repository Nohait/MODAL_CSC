import bpy
import bmesh
import random
import math

random.seed(0)

# --------------------------------------------------
# Helpers
# --------------------------------------------------

def get_or_create_collection(name, parent=None):
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        if parent is not None:
            parent.children.link(col)
        else:
            bpy.context.scene.collection.children.link(col)
    return col


def clear_collection(col):
    # unlink and delete all objects in the collection
    for obj in list(col.objects):
        for child_col in obj.users_collection:
            child_col.objects.unlink(obj)
        bpy.data.objects.remove(obj, do_unlink=True)


def make_material(name, color):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links

        # clear default nodes
        for n in nodes:
            nodes.remove(n)

        # create nodes
        output = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")

        # assign basic low-poly style color
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)

        # roughness only (Blender 4+)
        bsdf.inputs["Roughness"].default_value = 0.9

        # link
        links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    return mat


def apply_flat_shading(obj):
    mesh = obj.data
    for p in mesh.polygons:
        p.use_smooth = False


# --------------------------------------------------
# Ground tiles
# --------------------------------------------------

def create_ground_tile(name, size=2.5, grid=10, height=0.15, color_variation=0.05):
    """Create a sculpted low-poly ground tile as a single mesh."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()

    half = size / 2.0

    verts = [[None for _ in range(grid + 1)] for _ in range(grid + 1)]

    for x in range(grid + 1):
        for y in range(grid + 1):
            fx = x / grid
            fy = y / grid
            px = (fx - 0.5) * size
            py = (fy - 0.5) * size

            # softer heights at the border for better tiling
            border_factor = min(fx, 1 - fx, fy, 1 - fy) * 2
            noise = (random.random() - 0.5) * height * border_factor
            v = bm.verts.new((px, py, noise))
            verts[x][y] = v

    bm.verts.ensure_lookup_table()

    for x in range(grid):
        for y in range(grid):
            v0 = verts[x][y]
            v1 = verts[x+1][y]
            v2 = verts[x+1][y+1]
            v3 = verts[x][y+1]
            bm.faces.new((v0, v1, v2, v3))

    bm.faces.ensure_lookup_table()
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    obj.location = (0, 0, 0)

    apply_flat_shading(obj)

    # material
    base_green = (0.40, 0.50, 0.30)
    jitter = lambda: (random.random() - 0.5) * color_variation
    color = (
        base_green[0] + jitter(),
        base_green[1] + jitter(),
        base_green[2] + jitter(),
    )
    mat = make_material(f"mat_ground_{name}", color)
    obj.data.materials.append(mat)

    return obj


def populate_ground(col, count=12):
    clear_collection(col)
    for i in range(count):
        tile = create_ground_tile(f"ground_{i:02d}")
        col.objects.link(tile)


# --------------------------------------------------
# Trees
# --------------------------------------------------

def create_tree(name):
    """Simple low-poly tree: prism trunk + low-poly cone foliage."""
    # trunk
    bpy.ops.mesh.primitive_cube_add(size=0.25, location=(0, 0, 0.5))
    trunk = bpy.context.active_object
    trunk.scale[2] = 2.0  # tall

    trunk_mat = make_material("mat_tree_trunk", (0.25, 0.16, 0.10))
    trunk.data.materials.append(trunk_mat)
    apply_flat_shading(trunk)

    # foliage
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.9, radius2=0.0,
                                    depth=2.0, location=(0, 0, 2.0))
    foliage = bpy.context.active_object
    foliage_mat = make_material("mat_tree_leaves", (0.18, 0.35, 0.12))
    foliage.data.materials.append(foliage_mat)
    apply_flat_shading(foliage)

    # join
    bpy.context.view_layer.objects.active = trunk
    foliage.select_set(True)
    trunk.select_set(True)
    bpy.ops.object.join()
    trunk.name = name
    return trunk


def populate_trees(col, count=8):
    clear_collection(col)
    for i in range(count):
        obj = create_tree(f"tree_{i:02d}")
        # small random variation
        s = random.uniform(0.8, 1.3)
        obj.scale = (s, s, s * random.uniform(1.0, 1.4))
        col.objects.link(obj)


# --------------------------------------------------
# Rocks
# --------------------------------------------------

def create_rock(name):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.6, location=(0, 0, 0.6))
    rock = bpy.context.active_object
    # squash / stretch
    rock.scale[0] = random.uniform(0.7, 1.3)
    rock.scale[1] = random.uniform(0.7, 1.3)
    rock.scale[2] = random.uniform(0.4, 0.9)

    mat = make_material("mat_rock", (0.35, 0.34, 0.33))
    rock.data.materials.append(mat)
    apply_flat_shading(rock)
    rock.name = name
    return rock


def populate_rocks(col, count=6):
    clear_collection(col)
    for i in range(count):
        rock = create_rock(f"rock_{i:02d}")
        col.objects.link(rock)


# --------------------------------------------------
# Bushes
# --------------------------------------------------

def create_bush(name):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.7, location=(0, 0, 0.7))
    bush = bpy.context.active_object
    bush.scale[0] = random.uniform(0.8, 1.2)
    bush.scale[1] = random.uniform(0.8, 1.2)
    bush.scale[2] = random.uniform(0.5, 0.9)

    mat = make_material("mat_bush", (0.20, 0.40, 0.20))
    bush.data.materials.append(mat)
    apply_flat_shading(bush)
    bush.name = name
    return bush


def populate_bushes(col, count=6):
    clear_collection(col)
    for i in range(count):
        bush = create_bush(f"bush_{i:02d}")
        col.objects.link(bush)


# --------------------------------------------------
# Crates & props
# --------------------------------------------------

def create_crate(name):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.5))
    crate = bpy.context.active_object
    mat = make_material("mat_crate", (0.35, 0.22, 0.10))
    crate.data.materials.append(mat)
    apply_flat_shading(crate)
    crate.name = name
    return crate


def populate_crates(col, count=6):
    clear_collection(col)
    for i in range(count):
        crate = create_crate(f"crate_{i:02d}")
        # random scale
        s = random.uniform(0.8, 1.1)
        crate.scale = (s, s, s * random.uniform(0.8, 1.2))
        col.objects.link(crate)


def create_barrel(name):
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.4, depth=1.2, location=(0, 0, 0.6))
    barrel = bpy.context.active_object
    mat = make_material("mat_barrel", (0.25, 0.25, 0.32))
    barrel.data.materials.append(mat)
    apply_flat_shading(barrel)
    barrel.name = name
    return barrel


def populate_props(col, count=8):
    clear_collection(col)
    # half crates, half barrels
    for i in range(count):
        if i % 2 == 0:
            obj = create_barrel(f"barrel_{i:02d}")
        else:
            obj = create_crate(f"prop_crate_{i:02d}")
        col.objects.link(obj)


# --------------------------------------------------
# Ruins
# --------------------------------------------------

def create_ruin_block(name):
    bpy.ops.mesh.primitive_cube_add(size=1.4, location=(0, 0, 0.7))
    ruin = bpy.context.active_object

    # deform vertices for a broken look
    mesh = ruin.data
    for v in mesh.vertices:
        v.co.x += (random.random() - 0.5) * 0.3
        v.co.y += (random.random() - 0.5) * 0.3
        v.co.z += (random.random() - 0.2) * 0.4

    mat = make_material("mat_ruin", (0.30, 0.30, 0.32))
    mesh.materials.append(mat)
    apply_flat_shading(ruin)
    ruin.name = name
    return ruin


def populate_ruins(col, count=4):
    clear_collection(col)
    for i in range(count):
        ruin = create_ruin_block(f"ruin_{i:02d}")
        col.objects.link(ruin)


# --------------------------------------------------
# Wildlife (simple silhouettes)
# --------------------------------------------------

def create_wildlife_blob(name, color):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=4, radius=0.6,
                                         location=(0, 0, 0.6))
    obj = bpy.context.active_object
    obj.scale[0] = random.uniform(0.7, 1.2)
    obj.scale[1] = random.uniform(0.4, 1.0)
    obj.scale[2] = random.uniform(0.6, 1.4)

    mat = make_material(name + "_mat", color)
    obj.data.materials.append(mat)
    apply_flat_shading(obj)
    obj.name = name
    return obj


def populate_wildlife(col, count=4):
    clear_collection(col)
    colors = [
        (0.45, 0.35, 0.25),  # deer-like
        (0.25, 0.25, 0.25),  # wolf-like
        (0.35, 0.20, 0.15),  # boar-like
        (0.30, 0.30, 0.30),
    ]
    for i in range(count):
        c = colors[i % len(colors)]
        obj = create_wildlife_blob(f"wildlife_{i:02d}", c)
        col.objects.link(obj)


# --------------------------------------------------
# Characters (simple stand-ins)
# --------------------------------------------------

def create_character_capsule(name, color):
    # body
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.3, depth=1.2,
                                        location=(0, 0, 0.6))
    body = bpy.context.active_object
    mat = make_material(name + "_mat", color)
    body.data.materials.append(mat)
    apply_flat_shading(body)

    # head
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=4, radius=0.3,
                                         location=(0, 0, 1.3))
    head = bpy.context.active_object
    head.data.materials.append(mat)
    apply_flat_shading(head)

    bpy.context.view_layer.objects.active = body
    head.select_set(True)
    body.select_set(True)
    bpy.ops.object.join()
    body.name = name
    return body


def populate_characters(col, count=3):
    clear_collection(col)
    colors = [
        (0.15, 0.35, 0.60),  # player
        (0.55, 0.15, 0.15),  # enemy
        (0.15, 0.55, 0.20),  # survivor
    ]
    for i in range(count):
        c = colors[i % len(colors)]
        char = create_character_capsule(f"character_{i:02d}", c)
        col.objects.link(char)


# --------------------------------------------------
# MAIN
# --------------------------------------------------

def main():
    # Make sure we have the Asset collections
    scene_root = bpy.context.scene.collection
    assets = get_or_create_collection("Assets")
    sub_names = [
        "Ground",
        "Trees",
        "Rocks",
        "Bushes",
        "Crates",
        "Props",
        "Characters",
        "Wildlife",
        "Ruins",
    ]
    sub_cols = {}
    for name in sub_names:
        sub_cols[name] = get_or_create_collection(name, parent=assets)

    # Populate each category
    populate_ground(sub_cols["Ground"], count=12)
    populate_trees(sub_cols["Trees"], count=8)
    populate_rocks(sub_cols["Rocks"], count=6)
    populate_bushes(sub_cols["Bushes"], count=6)
    populate_crates(sub_cols["Crates"], count=6)
    populate_props(sub_cols["Props"], count=8)
    populate_characters(sub_cols["Characters"], count=3)
    populate_wildlife(sub_cols["Wildlife"], count=4)
    populate_ruins(sub_cols["Ruins"], count=4)

    print("Asset generation complete.")

main()
