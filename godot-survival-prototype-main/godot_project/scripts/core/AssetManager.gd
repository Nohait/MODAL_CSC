extends Node
class_name AssetManagerClass
## Centralized asset management for all game textures, icons, and sprites
## Provides lazy-loading with caching for optimal memory usage

# Asset paths
const ICONS_PATH := "res://assets/icons/items/"
const WEAPONS_PATH := "res://assets/art/weapons/"
const ENEMIES_PATH := "res://assets/art/enemies/"
const ARMOR_PATH := "res://assets/art/armor/"
const ENVIRONMENT_PATH := "res://assets/art/environment/"
const CHARACTERS_PATH := "res://assets/art/characters/"
const UI_PATH := "res://assets/art/ui/"

# Cached textures
var _item_icons: Dictionary = {}
var _weapon_sprites: Dictionary = {}
var _enemy_sprites: Dictionary = {}
var _armor_sprites: Dictionary = {}
var _environment_sprites: Dictionary = {}

# Placeholder texture for missing assets
var _placeholder_texture: Texture2D

# Asset manifest - all available assets
const ITEM_ICONS := [
	# Resources - Basic
	"wood", "stone", "iron_ore", "copper_ore", "coal", "scrap_metal",
	"leather", "cloth", "rope", "plant_fiber",
	# Resources - Refined
	"iron_bar", "copper_bar", "steel_bar", "titanium_bar",
	"electronics", "gunpowder", "acid", "rubber", "glass", "plastic",
	# Food - Raw
	"raw_meat", "raw_fish", "berries", "carrot", "potato", "corn", "mushroom", "apple",
	# Food - Cooked
	"cooked_meat", "cooked_fish", "stew", "bread", "jerky", "canned_food", "mre",
	# Drinks
	"water_bottle", "purified_water", "juice", "coffee", "energy_drink", "beer", "whiskey",
	# Medical
	"bandage", "first_aid_kit", "medkit", "painkillers", "antibiotics",
	"antidote", "adrenaline", "splint", "radiation_pills",
	# Ammo
	"9mm_ammo", "rifle_ammo", "shotgun_shells", "arrows", "bolts",
	# Tools
	"pickaxe", "hatchet", "hammer", "wrench", "fishing_rod", "shovel", "saw", "lockpick",
	# Misc
	"flashlight", "torch", "map_piece", "key", "keycard", "dog_tags",
	"compass", "binoculars", "gasoline", "engine_parts", "battery",
]

const WEAPON_SPRITES := [
	# Melee
	"fists", "wood_club", "stone_knife", "makeshift_spear",
	"baseball_bat", "machete", "crowbar", "fire_axe",
	"katana", "sledgehammer", "spiked_bat", "combat_knife",
	# Ranged
	"makeshift_bow", "slingshot", "hunting_bow", "crossbow", "pistol",
	"compound_bow", "revolver", "shotgun", "rifle",
	"auto_pistol", "assault_rifle", "sniper_rifle",
	# Throwables
	"grenade", "molotov", "throwing_knife",
]

const ENEMY_SPRITES := [
	# Zombies
	"zombie_walker", "zombie_runner", "zombie_crawler",
	"bloater", "spitter", "screamer", "brute",
	# Bosses
	"ravager", "the_forsaken",
	# Animals
	"feral_dog", "wolf", "bear",
	# Raiders
	"raider_scout", "raider_gunner", "raider_heavy",
]

const ARMOR_SPRITES := [
	# Helmets
	"cloth_cap", "leather_cap", "military_helmet", "tactical_helmet", "reinforced_helmet",
	# Body
	"cloth_shirt", "leather_jacket", "military_vest", "tactical_armor", "swat_armor",
	# Hands
	"cloth_gloves", "leather_gloves", "tactical_gloves", "reinforced_gloves",
	# Feet
	"sneakers", "work_boots", "military_boots", "tactical_boots",
	# Backpacks
	"small_backpack", "medium_backpack", "military_backpack", "tactical_backpack",
]


func _ready() -> void:
	_create_placeholder_texture()
	# Optionally preload common assets
	# _preload_common_assets()


func _create_placeholder_texture() -> void:
	## Create a simple colored placeholder texture
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 0.5, 1.0))
	
	# Add a question mark pattern
	for x in range(24, 40):
		for y in range(16, 24):
			img.set_pixel(x, y, Color.WHITE)
	for x in range(32, 40):
		for y in range(24, 40):
			img.set_pixel(x, y, Color.WHITE)
	for x in range(24, 40):
		for y in range(40, 48):
			img.set_pixel(x, y, Color.WHITE)
	
	_placeholder_texture = ImageTexture.create_from_image(img)


# ============================================================================
# ITEM ICONS
# ============================================================================

func get_item_icon(item_id: String) -> Texture2D:
	## Get item icon texture, loading and caching if needed
	if item_id in _item_icons:
		return _item_icons[item_id]
	
	var path := ICONS_PATH + item_id + ".png"
	var texture := _load_texture(path)
	_item_icons[item_id] = texture
	return texture


func preload_item_icons() -> void:
	## Preload all item icons into cache
	for item_id in ITEM_ICONS:
		get_item_icon(item_id)
	print("AssetManager: Preloaded %d item icons" % ITEM_ICONS.size())


# ============================================================================
# WEAPON SPRITES
# ============================================================================

func get_weapon_sprite(weapon_id: String) -> Texture2D:
	## Get weapon sprite texture
	if weapon_id in _weapon_sprites:
		return _weapon_sprites[weapon_id]
	
	var path := WEAPONS_PATH + weapon_id + ".png"
	var texture := _load_texture(path)
	_weapon_sprites[weapon_id] = texture
	return texture


func preload_weapon_sprites() -> void:
	## Preload all weapon sprites
	for weapon_id in WEAPON_SPRITES:
		get_weapon_sprite(weapon_id)
	print("AssetManager: Preloaded %d weapon sprites" % WEAPON_SPRITES.size())


# ============================================================================
# ENEMY SPRITES
# ============================================================================

func get_enemy_sprite(enemy_id: String) -> Texture2D:
	## Get enemy sprite texture
	if enemy_id in _enemy_sprites:
		return _enemy_sprites[enemy_id]
	
	var path := ENEMIES_PATH + enemy_id + ".png"
	var texture := _load_texture(path)
	_enemy_sprites[enemy_id] = texture
	return texture


func preload_enemy_sprites() -> void:
	## Preload all enemy sprites
	for enemy_id in ENEMY_SPRITES:
		get_enemy_sprite(enemy_id)
	print("AssetManager: Preloaded %d enemy sprites" % ENEMY_SPRITES.size())


# ============================================================================
# ARMOR SPRITES
# ============================================================================

func get_armor_sprite(armor_id: String) -> Texture2D:
	## Get armor sprite texture
	if armor_id in _armor_sprites:
		return _armor_sprites[armor_id]
	
	var path := ARMOR_PATH + armor_id + ".png"
	var texture := _load_texture(path)
	_armor_sprites[armor_id] = texture
	return texture


func preload_armor_sprites() -> void:
	## Preload all armor sprites
	for armor_id in ARMOR_SPRITES:
		get_armor_sprite(armor_id)
	print("AssetManager: Preloaded %d armor sprites" % ARMOR_SPRITES.size())


# ============================================================================
# GENERIC ASSET LOADING
# ============================================================================

func get_texture(path: String) -> Texture2D:
	## Load any texture by path
	return _load_texture(path)


func _load_texture(path: String) -> Texture2D:
	## Internal texture loader with error handling
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture:
			return texture
	
	push_warning("AssetManager: Failed to load texture: " + path)
	return _placeholder_texture


func preload_all() -> void:
	## Preload all game assets
	var start_time := Time.get_ticks_msec()
	
	preload_item_icons()
	preload_weapon_sprites()
	preload_enemy_sprites()
	preload_armor_sprites()
	
	var elapsed := Time.get_ticks_msec() - start_time
	print("AssetManager: All assets preloaded in %d ms" % elapsed)


func clear_cache() -> void:
	## Clear all cached textures to free memory
	_item_icons.clear()
	_weapon_sprites.clear()
	_enemy_sprites.clear()
	_armor_sprites.clear()
	_environment_sprites.clear()
	print("AssetManager: Cache cleared")


func get_cache_stats() -> Dictionary:
	## Get statistics about cached assets
	return {
		"item_icons": _item_icons.size(),
		"weapon_sprites": _weapon_sprites.size(),
		"enemy_sprites": _enemy_sprites.size(),
		"armor_sprites": _armor_sprites.size(),
		"environment_sprites": _environment_sprites.size(),
		"total": _item_icons.size() + _weapon_sprites.size() + _enemy_sprites.size() + _armor_sprites.size() + _environment_sprites.size(),
	}


# ============================================================================
# SPRITE ANIMATION HELPERS
# ============================================================================

func create_animated_sprite_frames(
	base_name: String,
	frame_count: int,
	path_prefix: String,
	fps: float = 10.0
) -> SpriteFrames:
	## Create SpriteFrames resource from numbered image files
	var frames := SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", fps)
	
	for i in range(frame_count):
		var path := "%s%s_%d.png" % [path_prefix, base_name, i]
		var texture := _load_texture(path)
		frames.add_frame("default", texture)
	
	return frames


func get_enemy_animation(enemy_id: String, animation: String = "idle") -> SpriteFrames:
	## Get animated sprite frames for enemy
	# For now, return single-frame animation
	# Can be expanded when animation sheets are available
	var frames := SpriteFrames.new()
	frames.add_animation(animation)
	frames.set_animation_speed(animation, 10.0)
	frames.add_frame(animation, get_enemy_sprite(enemy_id))
	return frames


# ============================================================================
# ICON GENERATION (RUNTIME)
# ============================================================================

func generate_tinted_icon(base_texture: Texture2D, tint: Color) -> Texture2D:
	## Create a tinted version of an icon
	var img := base_texture.get_image()
	if not img:
		return base_texture
	
	img = img.duplicate()
	
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var pixel := img.get_pixel(x, y)
			if pixel.a > 0:
				pixel = pixel.blend(tint)
				img.set_pixel(x, y, pixel)
	
	return ImageTexture.create_from_image(img)


func generate_quality_overlay(base_texture: Texture2D, quality: int) -> Texture2D:
	## Add quality indicator border to item icon
	## Quality: 0=common, 1=uncommon, 2=rare, 3=epic, 4=legendary
	var quality_colors := [
		Color(0.5, 0.5, 0.5),    # Common - Gray
		Color(0.2, 0.8, 0.2),    # Uncommon - Green
		Color(0.2, 0.4, 1.0),    # Rare - Blue
		Color(0.6, 0.2, 0.8),    # Epic - Purple
		Color(1.0, 0.6, 0.0),    # Legendary - Orange
	]
	
	var img := base_texture.get_image()
	if not img:
		return base_texture
	
	img = img.duplicate()
	var border_color := quality_colors[clampi(quality, 0, 4)]
	var w := img.get_width()
	var h := img.get_height()
	
	# Draw border
	for x in range(w):
		img.set_pixel(x, 0, border_color)
		img.set_pixel(x, 1, border_color)
		img.set_pixel(x, h - 1, border_color)
		img.set_pixel(x, h - 2, border_color)
	for y in range(h):
		img.set_pixel(0, y, border_color)
		img.set_pixel(1, y, border_color)
		img.set_pixel(w - 1, y, border_color)
		img.set_pixel(w - 2, y, border_color)
	
	return ImageTexture.create_from_image(img)
