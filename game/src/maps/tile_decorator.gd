## Decorates map geometry with tiles from Kenney Pixel Platformer.
## Overlays Sprite2D tiles on top of existing StaticBody2D collision rects.
## Tilemap: tilemap_packed.png, 18x18 tiles, 20 cols x 9 rows.
class_name TileDecorator
extends RefCounted

const TILE_SIZE: int = 18
const COLS: int = 20
const TILEMAP_PATH: String = "res://assets/tilesets/tilemap_packed.png"

# Tile atlas positions (col, row) in the packed tilemap
# Ground tiles (grass top)
const GRASS_TOP_LEFT := Vector2i(0, 0)
const GRASS_TOP_MID := Vector2i(1, 0)
const GRASS_TOP_RIGHT := Vector2i(2, 0)
const GRASS_FILL := Vector2i(1, 1)
const DIRT_FILL := Vector2i(4, 0)

# Platform tiles (thin floating)
const PLAT_LEFT := Vector2i(0, 2)
const PLAT_MID := Vector2i(1, 2)
const PLAT_RIGHT := Vector2i(2, 2)

# Stone/wall tiles
const STONE_TOP := Vector2i(5, 0)
const STONE_FILL := Vector2i(5, 1)

# Snow ground
const SNOW_TOP_LEFT := Vector2i(0, 6)
const SNOW_TOP_MID := Vector2i(1, 6)
const SNOW_TOP_RIGHT := Vector2i(2, 6)
const SNOW_FILL := Vector2i(1, 7)

# Background
const BG_DARK := Vector2i(16, 5)

# Decorations
const PLANT_1 := Vector2i(4, 4)
const PLANT_2 := Vector2i(5, 4)
const MUSHROOM := Vector2i(6, 4)
const ROCK_SMALL := Vector2i(8, 4)
const TREE_TOP := Vector2i(0, 4)
const TREE_TRUNK := Vector2i(0, 5)
const FENCE := Vector2i(14, 3)
const SIGN := Vector2i(7, 3)
const CRATE := Vector2i(7, 2)

static var _texture: Texture2D = null


static func _get_texture() -> Texture2D:
	if _texture == null:
		_texture = load(TILEMAP_PATH)
	return _texture


static func get_tile_texture(atlas_pos: Vector2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = _get_texture()
	atlas.region = Rect2(
		atlas_pos.x * TILE_SIZE,
		atlas_pos.y * TILE_SIZE,
		TILE_SIZE,
		TILE_SIZE
	)
	return atlas


static func decorate_ground(parent: Node2D, pos: Vector2, size: Vector2, theme: String = "grass") -> void:
	## Covers a ground rectangle with tiled sprites.
	## pos = center, size = full size of the rect.
	var top_left: Vector2 = pos - size / 2
	var tiles_x: int = ceili(size.x / TILE_SIZE)
	var tiles_y: int = ceili(size.y / TILE_SIZE)

	var top_tile: Vector2i
	var fill_tile: Vector2i

	match theme:
		"grass":
			top_tile = GRASS_TOP_MID
			fill_tile = GRASS_FILL
		"snow":
			top_tile = SNOW_TOP_MID
			fill_tile = SNOW_FILL
		"stone":
			top_tile = STONE_TOP
			fill_tile = STONE_FILL
		_:
			top_tile = GRASS_TOP_MID
			fill_tile = DIRT_FILL

	var container := Node2D.new()
	container.z_index = -1
	parent.add_child(container)

	for x in tiles_x:
		for y in tiles_y:
			var tile_pos: Vector2i
			if y == 0:
				# Top row — use surface tiles
				if x == 0:
					tile_pos = Vector2i(top_tile.x - 1, top_tile.y)  # left edge
				elif x == tiles_x - 1:
					tile_pos = Vector2i(top_tile.x + 1, top_tile.y)  # right edge
				else:
					tile_pos = top_tile  # middle
			else:
				tile_pos = fill_tile

			var sprite := Sprite2D.new()
			sprite.texture = get_tile_texture(tile_pos)
			sprite.position = top_left + Vector2(x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			container.add_child(sprite)


static func decorate_platform(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	## Covers a thin platform with platform tiles.
	var top_left: Vector2 = pos - size / 2
	var tiles_x: int = maxi(ceili(size.x / TILE_SIZE), 1)

	var container := Node2D.new()
	container.z_index = -1
	parent.add_child(container)

	for x in tiles_x:
		var tile_pos: Vector2i
		if tiles_x == 1:
			tile_pos = PLAT_MID
		elif x == 0:
			tile_pos = PLAT_LEFT
		elif x == tiles_x - 1:
			tile_pos = PLAT_RIGHT
		else:
			tile_pos = PLAT_MID

		var sprite := Sprite2D.new()
		sprite.texture = get_tile_texture(tile_pos)
		sprite.position = top_left + Vector2(x * TILE_SIZE + TILE_SIZE / 2, TILE_SIZE / 2)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		container.add_child(sprite)


static func decorate_wall(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	## Covers a vertical wall with stone tiles.
	var top_left: Vector2 = pos - size / 2
	var tiles_x: int = maxi(ceili(size.x / TILE_SIZE), 1)
	var tiles_y: int = ceili(size.y / TILE_SIZE)

	var container := Node2D.new()
	container.z_index = -1
	parent.add_child(container)

	for x in tiles_x:
		for y in tiles_y:
			var sprite := Sprite2D.new()
			sprite.texture = get_tile_texture(STONE_FILL)
			sprite.position = top_left + Vector2(x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			container.add_child(sprite)


static func add_decoration(parent: Node2D, pos: Vector2, tile: Vector2i, scale_factor: float = 1.0) -> void:
	## Places a single decorative tile sprite at a world position.
	var sprite := Sprite2D.new()
	sprite.texture = get_tile_texture(tile)
	sprite.position = pos
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.z_index = -1
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)


static func fill_background(parent: Node2D, width: float, height: float) -> void:
	## Fills the background with dark tiles.
	var tiles_x: int = ceili(width / TILE_SIZE) + 1
	var tiles_y: int = ceili(height / TILE_SIZE) + 1

	var container := Node2D.new()
	container.z_index = -10
	parent.add_child(container)

	for x in tiles_x:
		for y in tiles_y:
			var sprite := Sprite2D.new()
			sprite.texture = get_tile_texture(BG_DARK)
			sprite.position = Vector2(x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.modulate = Color(0.3, 0.3, 0.35, 1.0)
			container.add_child(sprite)
