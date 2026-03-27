extends Node2D
class_name Chunk

const WorldGeneratorScript = preload("res://scripts/world/world_generator.gd")

var chunk_pos: Vector2i  # chunk grid position
var tiles: Array = []    # flat array of tile IDs (CHUNK_SIZE * CHUNK_SIZE)
var items: Array = []    # {local_x, local_y, type, collected}
var is_town: bool = false
var town_name: String = ""

const CHUNK_SIZE := 16
const TILE_SIZE := 16

func generate(cx: int, cy: int, generator) -> void:
	chunk_pos = Vector2i(cx, cy)
	position = Vector2(cx * CHUNK_SIZE * TILE_SIZE, cy * CHUNK_SIZE * TILE_SIZE)
	tiles.resize(CHUNK_SIZE * CHUNK_SIZE)

	is_town = generator.is_town_location(cx, cy)
	if is_town:
		town_name = generator.get_town_name(cx, cy)

	for ly in CHUNK_SIZE:
		for lx in CHUNK_SIZE:
			var wx := cx * CHUNK_SIZE + lx
			var wy := cy * CHUNK_SIZE + ly
			var tile: int
			if is_town and lx >= 4 and lx < 12 and ly >= 4 and ly < 12:
				tile = WorldGeneratorScript.Tile.TOWN
			elif is_town and (lx == 8 or ly == 8):
				tile = WorldGeneratorScript.Tile.PATH
			else:
				tile = generator.get_tile(wx, wy)
			tiles[ly * CHUNK_SIZE + lx] = tile

	# Scatter items
	if not is_town:
		for i in randi_range(0, 3):
			var lx := randi_range(0, CHUNK_SIZE - 1)
			var ly := randi_range(0, CHUNK_SIZE - 1)
			if generator.is_walkable(tiles[ly * CHUNK_SIZE + lx]):
				var roll := randf()
				var item_type: String
				if roll < 0.5: item_type = "pokeball"
				elif roll < 0.75: item_type = "greatball"
				elif roll < 0.9: item_type = "razz"
				else: item_type = "ultraball"
				items.append({"lx": lx, "ly": ly, "type": item_type, "collected": false})

func get_tile_at(local_x: int, local_y: int) -> int:
	if local_x < 0 or local_y < 0 or local_x >= CHUNK_SIZE or local_y >= CHUNK_SIZE:
		return WorldGeneratorScript.Tile.MOUNTAIN
	return tiles[local_y * CHUNK_SIZE + local_x]

func _draw() -> void:
	for ly in CHUNK_SIZE:
		for lx in CHUNK_SIZE:
			var tile: int = tiles[ly * CHUNK_SIZE + lx]
			var color = WorldGeneratorScript.TILE_COLORS.get(tile, Color.BLACK)
			var rect := Rect2(lx * TILE_SIZE, ly * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			draw_rect(rect, color)

			# Tall grass detail stripes
			if tile == WorldGeneratorScript.Tile.TALL_GRASS:
				draw_rect(Rect2(lx * TILE_SIZE + 2, ly * TILE_SIZE + 2, 4, 10), Color(0, 0.3, 0, 0.3))
				draw_rect(Rect2(lx * TILE_SIZE + 9, ly * TILE_SIZE + 1, 4, 11), Color(0, 0.3, 0, 0.3))

			# Forest tree shapes
			if tile == WorldGeneratorScript.Tile.FOREST or tile == WorldGeneratorScript.Tile.SNOW_FOREST:
				var trunk_color := Color("#5d4037")
				var leaf_color := Color("#2e7d32") if tile == WorldGeneratorScript.Tile.FOREST else Color("#78909c")
				draw_rect(Rect2(lx * TILE_SIZE + 6, ly * TILE_SIZE + 10, 4, 6), trunk_color)
				draw_circle(Vector2(lx * TILE_SIZE + 8, ly * TILE_SIZE + 7), 5, leaf_color)

	# Draw uncollected items as golden dots
	for item in items:
		if not item["collected"]:
			draw_circle(
				Vector2(item["lx"] * TILE_SIZE + TILE_SIZE / 2, item["ly"] * TILE_SIZE + TILE_SIZE / 2),
				3.0, Color("#ffd700")
			)

	# Draw town label
	if is_town:
		# Town marker - simple colored square indicator
		draw_rect(Rect2(7 * TILE_SIZE, 3 * TILE_SIZE, TILE_SIZE * 2, TILE_SIZE * 0.8), Color("#4fc3f7"))
