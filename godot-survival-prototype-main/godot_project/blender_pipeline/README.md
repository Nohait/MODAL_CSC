# Godot Survival Prototype - 3D Asset Generation Pipeline

This pipeline generates all 3D game assets using Blender's Python API and exports them in GLTF/GLB format for use in Godot 4.

## Requirements

- **Blender 3.6+** (3.x or 4.x recommended)
  - Download from: https://www.blender.org/download/
  - Standard installation to Program Files is auto-detected

## Quick Start

### Option 1: PowerShell (Recommended)
```powershell
cd godot_project/blender_pipeline
.\generate_all_models.ps1
```

### Option 2: Batch File
```cmd
cd godot_project\blender_pipeline
generate_models.bat
```

### Option 3: Direct Blender Command
```bash
blender --background --python generate_master_assets.py
blender --background --python export_all_assets.py
```

## What Gets Generated

### Environment (35+ assets)
- **Trees**: Oak, Pine, Birch, Dead variants (12 models)
- **Rocks**: Boulders, Small rocks, Slabs, Ore nodes (15 models)
- **Bushes**: Normal, Berry, Dead, Flowering (8 models)

### Props (20+ assets)
- **Containers**: Wooden crates, Military crates, Metal crates
- **Barrels**: Metal, Rusty, Toxic, Fuel drums
- **Misc**: Campfires, Chests, Storage items

### Characters (10+ assets)
- **Survivors**: Multiple player character variants
- **NPCs**: Traders, Quest givers, Friendly survivors
- **Raiders**: Scout, Gunner, Heavy, Boss variants

### Enemies (15+ assets)
- **Zombies**: Walker, Runner, Crawler, Bloater, Screamer, Spitter, Brute, Ravager
- **Animals**: Wolf, Bear, Deer, Dog, Boar, Rabbit

### Weapons (28+ assets)
- **Melee**: Clubs, Knives, Spears, Bats, Machetes, Axes, Katanas, Sledgehammers
- **Ranged**: Bows, Crossbows, Pistols, Revolvers, Shotguns, Rifles, SMGs
- **Throwables**: Grenades, Molotovs, Throwing knives

### Armor (20+ assets)
- **Helmets**: Cloth caps, Leather hoods, Military helmets, Riot gear, Gas masks
- **Chest**: Shirts, Jackets, Tactical vests, Military armor, Hazmat suits
- **Accessories**: Gloves, Boots, Backpacks

### Buildings (15+ assets)
- **Walls**: Wood, Metal, Stone, Brick (with/without windows)
- **Floors**: Wood, Concrete, Metal tiles
- **Doors**: Wood and Metal variants
- **Misc**: Foundations, Roofs, Stairs

### Vehicles (6 assets)
- Car, Truck, Motorcycle, ATV, Boat, Helicopter

## Output Structure

```
godot_project/
├── blender_pipeline/
│   ├── exports/                    # Raw GLB exports
│   │   ├── environment/
│   │   ├── props/
│   │   ├── characters/
│   │   ├── enemies/
│   │   ├── weapons/
│   │   ├── buildings/
│   │   ├── vehicles/
│   │   └── manifest.json
│   └── ...
└── assets/
    └── models/                     # Godot-ready assets
        ├── environment/
        ├── props/
        ├── characters/
        ├── enemies/
        ├── weapons/
        ├── buildings/
        ├── vehicles/
        └── manifest.json
```

## Using in Godot

### With ModelManager Autoload

```gdscript
# Get a mesh by name
var tree_mesh: Mesh = ModelManager.get_model("tree_oak_00")

# Create a MeshInstance3D
var tree_instance: MeshInstance3D = ModelManager.create_mesh_instance("tree_oak_00")
add_child(tree_instance)

# Create with collision (StaticBody3D)
var rock: StaticBody3D = ModelManager.create_static_body("rock_boulder_00")
add_child(rock)

# Create prefabs (full resource nodes with functionality)
var tree_node = ModelManager.create_resource_node("tree", tree_position)
add_child(tree_node)

var zombie = ModelManager.create_enemy("zombie_walker")
add_child(zombie)

var car = ModelManager.create_vehicle("vehicle_car")
add_child(car)
```

### Manual Loading

```gdscript
var model = load("res://assets/models/environment/tree_oak_00.glb")
var instance = model.instantiate()
add_child(instance)
```

## Customization

### Adding New Assets

1. Edit `generate_master_assets.py` to add new generator methods
2. Run the pipeline again
3. Assets will be automatically exported and available

### Modifying Existing Assets

Each generator class is in `procedural/templates/`:
- `zombie_detailed.py` - Zombie types and variations
- `weapon_detailed.py` - Weapons (melee, ranged, throwable)
- `armor_detailed.py` - Armor pieces and accessories

Modify configurations in these files and regenerate.

### Material Customization

Materials are created via `MaterialLibrary` class in the main generator:
```python
# PBR material
mat = MaterialLibrary.create_pbr("mat_name", color, roughness=0.7, metallic=0.0)

# Procedural with noise variation
mat = MaterialLibrary.create_procedural("mat_name", color1, color2, roughness, noise_scale)
```

## Troubleshooting

### "Blender not found"
- Install Blender from https://www.blender.org/download/
- Or specify path: `.\generate_all_models.ps1 -BlenderPath "C:\path\to\blender.exe"`

### Generation fails
- Check `generate_log.txt` for Python errors
- Ensure Blender version is 3.6 or newer

### Models not appearing in Godot
- Refresh FileSystem dock (F5 or right-click → "Scan Files")
- Check that `.glb` files exist in `assets/models/`
- Verify `manifest.json` was created

### Collision issues
- Use `create_static_body()` for proper collision
- Or manually add CollisionShape3D to MeshInstance3D

## Performance Notes

- Total generation time: ~2-5 minutes depending on hardware
- Generated file size: ~50-100MB total
- All models use flat shading for stylized low-poly look
- PBR materials are baked for optimal Godot performance

## Credits

Generated using Blender Python API for Godot Survival Prototype game.
