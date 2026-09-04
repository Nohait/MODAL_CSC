# Mixamo Character Setup Guide (FREE)

This guide walks you through getting professional, animated characters into your game for **$0**.

---

## Step 1: Get a Character from Mixamo (5 minutes)

1. Go to **https://mixamo.com** and sign in (Adobe account, free)

2. Click **"Characters"** tab and pick a character:
   - **Recommended for survivors:** "X Bot", "Y Bot", or any realistic humanoid
   - **Recommended for zombies:** Search "Zombie" in animations later

3. Click **"Download"** with these settings:
   - **Format:** FBX Binary (.fbx)
   - **Pose:** T-Pose
   - **Skin:** With Skin
   - **Frames per Second:** 30

4. Save to: `godot_project/assets/mixamo/raw/survivor_01.fbx`

---

## Step 2: Get Animations (10 minutes)

Still on Mixamo, click **"Animations"** tab and download these essential animations:

| Animation | Search Term | Download Settings |
|-----------|-------------|-------------------|
| Idle | "idle" or "breathing idle" | Without Skin, FBX |
| Walk | "walking" | Without Skin, FBX |
| Run | "running" | Without Skin, FBX |
| Sprint | "sprinting" | Without Skin, FBX |
| Attack | "sword slash" or "punch" | Without Skin, FBX |
| Hit | "hit reaction" | Without Skin, FBX |
| Death | "dying" | Without Skin, FBX |
| Pickup | "picking up" | Without Skin, FBX |

Save each with descriptive names:
- `idle.fbx`
- `walk.fbx`
- `run.fbx`
- etc.

---

## Step 3: Import into Godot

1. Open the project in Godot 4.5

2. Go to **Script > Run** and run the `MixamoImporter.gd` script:
   - Menu: **Project > Tools > Scripts > Run**
   - Or open the script and press **Shift+Ctrl+X**

3. The importer will:
   - Process all FBX files in `assets/mixamo/raw/`
   - Export characters to `assets/mixamo/characters/`
   - Build a shared animation library at `assets/mixamo/animations/mixamo_animations.tres`

---

## Step 4: Assign to Player

1. Open `scenes/Player3D.tscn`

2. Select the **Player3D** root node

3. In the Inspector, set:
   - **Character Scene:** `res://assets/mixamo/characters/survivor_01.tscn`
   - **Animation Library:** `res://assets/mixamo/animations/mixamo_animations.tres`

4. Run the game - you should see your character with animations!

---

## Quick Reference: Animation Names

The AnimationTree expects these animation names:
- `idle` - standing still
- `walk` - walking speed (~2 m/s)
- `run` - running speed (~5 m/s)  
- `sprint` - fast running (~8 m/s)
- `attack_melee` - melee attack
- `hit_react` - taking damage
- `death` - dying
- `pickup` - interacting/picking up items

The importer automatically maps Mixamo names to these if it recognizes them in the filename.

---

## Troubleshooting

### Character is tiny/huge
- In Godot, select the imported scene
- In the Import dock, set **Scale** appropriately
- Click "Reimport"

### Animations don't play
- Make sure the animation library is assigned
- Check that animation names match (case-sensitive)
- The AnimationTree blends based on movement speed

### Character rotates weirdly
- Mixamo exports Y-up, Godot expects Y-up, should work
- If rotated, adjust the root transform in the character scene

---

## Alternative: Quaternius Free Characters

If you want stylized low-poly characters instead:

1. Go to **https://quaternius.com/packs.html**
2. Download "Animated Characters" pack (free)
3. Extract to `assets/mixamo/raw/`
4. Run the importer

---

## Costs Breakdown

| Service | Cost | What You Get |
|---------|------|--------------|
| Mixamo | FREE | Characters + rigging + 2500+ animations |
| Quaternius | FREE | Dozens of stylized characters |
| KayKit | FREE | Simple but charming humanoids |

Total: **$0**

---

## Next Steps (If you want more variety)

### Option A: Meshy.ai (200 free credits/month)
- Text-to-3D character generation
- Upload to Mixamo for rigging
- Cost: Free tier gives ~5-10 characters

### Option B: ReadyPlayerMe (free)
- Customizable avatar creation
- Built-in skeleton compatible with Mixamo
- Great for player customization

### Option C: Pre-made packs (paid)
- Synty Studios: $20-50 per pack, hundreds of assets
- Stylized, high quality, animation-ready
