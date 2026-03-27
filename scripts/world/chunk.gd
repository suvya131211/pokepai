extends Node2D
class_name Chunk

const WorldGeneratorScript = preload("res://scripts/world/world_generator.gd")

var chunk_pos: Vector2i  # chunk grid position
var tiles: Array = []    # flat array of tile IDs (CHUNK_SIZE * CHUNK_SIZE)
var items: Array = []    # {local_x, local_y, type, collected}
var spawned_pokemon: Array = []
var is_town: bool = false
var town_name: String = ""
var _has_water: bool = false

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

	# Spawn visible Pokemon on walkable tiles
	var spawn_count = randi_range(0, 2)  # 0-2 Pokemon per chunk (sporadic)
	for i in spawn_count:
		var lx = randi_range(0, CHUNK_SIZE - 1)
		var ly = randi_range(0, CHUNK_SIZE - 1)
		var tile = tiles[ly * CHUNK_SIZE + lx]
		var habitat = WorldGeneratorScript.TILE_HABITAT.get(tile, "")
		if habitat.is_empty() or habitat == "path" or habitat == "town":
			continue
		var pool = PokemonDB.get_species_for_habitat(habitat, "day", "clear")
		if pool.is_empty():
			continue
		var species = PokemonDB.weighted_random_pick(pool)
		if species.is_empty():
			continue
		var spawn_data = {"lx": lx, "ly": ly, "species": species, "level": randi_range(1, 8)}
		spawned_pokemon.append(spawn_data)

	# Check for water tiles to enable animation
	for t in tiles:
		if t == WorldGeneratorScript.Tile.WATER or t == WorldGeneratorScript.Tile.DEEP_WATER:
			_has_water = true
			break

	_spawn_pokemon_nodes()

func _process(_delta):
	if _has_water:
		queue_redraw()

func _spawn_pokemon_nodes() -> void:
	for data in spawned_pokemon:
		var owp = preload("res://scripts/world/overworld_spawn.gd").new()
		owp.setup(data["species"], data["level"])
		owp.position = Vector2(data["lx"] * TILE_SIZE + TILE_SIZE / 2, data["ly"] * TILE_SIZE + TILE_SIZE / 2)
		add_child(owp)

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

			# --- Enhanced tile details ---
			var tx = lx * TILE_SIZE
			var ty = ly * TILE_SIZE

			# Grid lines
			draw_line(Vector2(tx, ty), Vector2(tx + TILE_SIZE, ty), Color(0, 0, 0, 0.08), 0.5)
			draw_line(Vector2(tx, ty), Vector2(tx, ty + TILE_SIZE), Color(0, 0, 0, 0.08), 0.5)

			match tile:
				WorldGeneratorScript.Tile.GRASS:
					# Random grass blades
					var seed_val = (lx * 7 + ly * 13) % 5
					for g in seed_val:
						var gx = tx + (g * 6 + 2) % TILE_SIZE
						var gy = ty + (g * 8 + 3) % TILE_SIZE
						draw_line(Vector2(gx, gy + 4), Vector2(gx + 1, gy), Color(0.2, 0.5, 0.2, 0.4), 1.0)

				WorldGeneratorScript.Tile.WATER:
					# Shimmer animation
					var t = Time.get_ticks_msec() * 0.001
					var wave = sin(t * 2.0 + lx + ly * 0.5) * 0.1
					draw_rect(Rect2(tx + 2, ty + 6 + wave * 8, TILE_SIZE - 4, 2), Color(1, 1, 1, 0.15))

				WorldGeneratorScript.Tile.DEEP_WATER:
					var t2 = Time.get_ticks_msec() * 0.0008
					var wave2 = sin(t2 * 2.0 + lx * 0.7 + ly * 0.3) * 0.1
					draw_rect(Rect2(tx + 3, ty + 5 + wave2 * 6, TILE_SIZE - 6, 2), Color(1, 1, 1, 0.1))

				WorldGeneratorScript.Tile.SAND:
					# Sand dots
					var sdot = (lx * 3 + ly * 11) % 4
					for s in sdot:
						draw_circle(Vector2(tx + (s * 5 + 4) % TILE_SIZE, ty + (s * 7 + 5) % TILE_SIZE), 0.8, Color(0.85, 0.75, 0.45, 0.3))

				WorldGeneratorScript.Tile.MOUNTAIN:
					# Rock cracks
					draw_line(Vector2(tx + 3, ty + 5), Vector2(tx + 10, ty + 12), Color(0.3, 0.25, 0.2, 0.3), 0.8)
					draw_line(Vector2(tx + 8, ty + 2), Vector2(tx + 14, ty + 9), Color(0.3, 0.25, 0.2, 0.2), 0.8)

				WorldGeneratorScript.Tile.CAVE:
					# Dark spots
					draw_circle(Vector2(tx + 6, ty + 8), 3, Color(0, 0, 0, 0.2))
					draw_circle(Vector2(tx + 12, ty + 5), 2, Color(0, 0, 0, 0.15))

				WorldGeneratorScript.Tile.TOWN:
					# Small building shapes
					var bx = tx + 4
					var by = ty + 2
					if (lx + ly) % 3 == 0:
						# Building
						draw_rect(Rect2(bx, by + 4, 8, 8), Color(0.7, 0.65, 0.6, 0.5))
						# Roof
						var roof_points = PackedVector2Array([
							Vector2(bx - 1, by + 4), Vector2(bx + 4, by), Vector2(bx + 9, by + 4)
						])
						draw_colored_polygon(roof_points, Color(0.6, 0.2, 0.15, 0.5))
						# Door
						draw_rect(Rect2(bx + 3, by + 8, 3, 4), Color(0.4, 0.25, 0.15, 0.5))
					elif (lx + ly) % 3 == 1:
						# Fence/garden
						draw_rect(Rect2(bx, by + 6, 10, 1), Color(0.5, 0.35, 0.2, 0.4))
						draw_circle(Vector2(bx + 3, by + 8), 2, Color(0.4, 0.7, 0.3, 0.4))

				WorldGeneratorScript.Tile.PATH:
					# Cobblestone pattern
					if (lx + ly) % 2 == 0:
						draw_rect(Rect2(tx + 1, ty + 1, 7, 7), Color(0.65, 0.58, 0.52, 0.3))
						draw_rect(Rect2(tx + 9, ty + 9, 6, 6), Color(0.68, 0.6, 0.55, 0.2))

				WorldGeneratorScript.Tile.SNOW:
					# Sparkle
					var sp = (lx * 17 + ly * 31) % 3
					if sp == 0:
						draw_circle(Vector2(tx + 8, ty + 6), 1, Color(1, 1, 1, 0.5))

				WorldGeneratorScript.Tile.BEACH:
					# Shell/pebble
					if (lx * 7 + ly * 3) % 5 == 0:
						draw_circle(Vector2(tx + 10, ty + 10), 1.5, Color(0.95, 0.85, 0.7, 0.5))

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
