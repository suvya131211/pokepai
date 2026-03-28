extends Node2D

const TILE_SIZE = 16

var area_name: String = ""
var area_type: String = ""  # "town", "route", "cave", "gym", "league"
var width: int = 30
var height: int = 20
var tiles: PackedInt32Array  # width * height
var exits: Array = []  # [{x, y, target_area, target_x, target_y}]
var npcs: Array = []   # [{x, y, name, type, dialog, team}]
var encounter_table: Array = []  # [{species_id, min_level, max_level, weight}]
var items: Array = []  # [{x, y, type, collected}]
var has_pokecenter: bool = false
var has_shop: bool = false
var gym_leader: Dictionary = {}  # {name, type, team, badge}
var requires_hm: String = ""  # "cut", "surf", "" for none
var hidden_items: Array = []  # [{x, y, type, found}]

# Tile types (reuse from world_generator)
enum Tile {
	WATER = 0, GRASS = 1, TALL_GRASS = 2, TREE = 3,
	PATH = 4, FLOOR = 5, WALL = 6, DOOR = 7,
	SAND = 8, CAVE_FLOOR = 9, CAVE_WALL = 10,
	LEDGE = 11, SIGN = 12, POKECENTER = 13, SHOP = 14,
	GYM_FLOOR = 15, FLOWER = 16, FENCE = 17,
	# Biome tiles
	SNOW = 18, ICE = 19, LAVA = 20, VOLCANO_ROCK = 21,
	SWAMP = 22, DEEP_WATER = 23, BRIDGE = 24, RUINS = 25,
	BERRY_BUSH = 26, LAKE_SHORE = 27,
}

const TILE_COLORS = {
	Tile.WATER: Color("#2196f3"),
	Tile.GRASS: Color("#4caf50"),
	Tile.TALL_GRASS: Color("#2e7d32"),
	Tile.TREE: Color("#1b5e20"),
	Tile.PATH: Color("#bcaaa4"),
	Tile.FLOOR: Color("#e0e0e0"),
	Tile.WALL: Color("#5d4037"),
	Tile.DOOR: Color("#8d6e63"),
	Tile.SAND: Color("#f5d67a"),
	Tile.CAVE_FLOOR: Color("#616161"),
	Tile.CAVE_WALL: Color("#424242"),
	Tile.LEDGE: Color("#795548"),
	Tile.SIGN: Color("#ffd54f"),
	Tile.POKECENTER: Color("#ef5350"),
	Tile.SHOP: Color("#42a5f5"),
	Tile.GYM_FLOOR: Color("#ffab40"),
	Tile.FLOWER: Color("#ec407a"),
	Tile.FENCE: Color("#a1887f"),
	Tile.SNOW: Color("#e8eaf6"),
	Tile.ICE: Color("#b3e5fc"),
	Tile.LAVA: Color("#ff5722"),
	Tile.VOLCANO_ROCK: Color("#4e342e"),
	Tile.SWAMP: Color("#558b2f"),
	Tile.DEEP_WATER: Color("#0d47a1"),
	Tile.BRIDGE: Color("#8d6e63"),
	Tile.RUINS: Color("#78909c"),
	Tile.BERRY_BUSH: Color("#e91e63"),
	Tile.LAKE_SHORE: Color("#ffe0b2"),
}

const WALKABLE_TILES = {
	Tile.WATER: false, Tile.GRASS: true, Tile.TALL_GRASS: true,
	Tile.TREE: false, Tile.PATH: true, Tile.FLOOR: true,
	Tile.WALL: false, Tile.DOOR: true, Tile.SAND: true,
	Tile.CAVE_FLOOR: true, Tile.CAVE_WALL: false, Tile.LEDGE: false,
	Tile.SIGN: false, Tile.POKECENTER: true, Tile.SHOP: true,
	Tile.GYM_FLOOR: true, Tile.FLOWER: true, Tile.FENCE: false,
	Tile.SNOW: true, Tile.ICE: true, Tile.LAVA: false, Tile.VOLCANO_ROCK: true,
	Tile.SWAMP: true, Tile.DEEP_WATER: false, Tile.BRIDGE: true, Tile.RUINS: true,
	Tile.BERRY_BUSH: true, Tile.LAKE_SHORE: true,
}

const ENCOUNTER_TILES = [Tile.TALL_GRASS, Tile.CAVE_FLOOR, Tile.SNOW, Tile.SWAMP, Tile.RUINS, Tile.VOLCANO_ROCK]

func setup(data: Dictionary) -> void:
	area_name = data.get("name", "Unknown")
	area_type = data.get("type", "route")
	width = data.get("width", 30)
	height = data.get("height", 20)
	var raw_tiles = data.get("tiles", [])
	if raw_tiles is PackedInt32Array:
		tiles = raw_tiles
	else:
		tiles = PackedInt32Array()
		for t in raw_tiles:
			tiles.append(t)
	exits = data.get("exits", [])
	npcs = data.get("npcs", [])
	encounter_table = data.get("encounters", [])
	items = data.get("items", [])
	has_pokecenter = data.get("pokecenter", false)
	has_shop = data.get("shop", false)
	gym_leader = data.get("gym_leader", {})
	requires_hm = data.get("requires_hm", "")
	hidden_items = data.get("hidden_items", [])
	# Force exit tiles and their neighbors to be walkable
	for ex in exits:
		var ex_x = ex.get("x", -1)
		var ex_y = ex.get("y", -1)
		if ex_x >= 0 and ex_y >= 0 and ex_x < width and ex_y < height:
			tiles[ex_y * width + ex_x] = Tile.PATH
			# Also make adjacent tile walkable (so player can reach the edge)
			if ex_x == 0 and ex_x + 1 < width:
				tiles[ex_y * width + (ex_x + 1)] = Tile.PATH
			elif ex_x == width - 1 and ex_x - 1 >= 0:
				tiles[ex_y * width + (ex_x - 1)] = Tile.PATH
			if ex_y == 0 and ex_y + 1 < height:
				tiles[(ex_y + 1) * width + ex_x] = Tile.PATH
			elif ex_y == height - 1 and ex_y - 1 >= 0:
				tiles[(ex_y - 1) * width + ex_x] = Tile.PATH
	print("[AREA] setup: %s, tiles: %d (expected %d)" % [
		area_name, tiles.size(), width * height])
	queue_redraw()

func get_tile(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= width or y >= height:
		return Tile.WALL
	return tiles[y * width + x]

func is_walkable(x: int, y: int) -> bool:
	var tile = get_tile(x, y)
	if tile == Tile.WATER:
		for pkmn in GameManager.party:
			for move in pkmn.known_moves:
				if move.get("name", "") == "Surf":
					return true
		return false
	return WALKABLE_TILES.get(tile, false)

func is_encounter_tile(x: int, y: int) -> bool:
	return get_tile(x, y) in ENCOUNTER_TILES

func get_exit_at(x: int, y: int) -> Dictionary:
	for ex in exits:
		if ex["x"] == x and ex["y"] == y:
			return ex
	return {}

func get_npc_at(x: int, y: int) -> Dictionary:
	for npc in npcs:
		if npc["x"] == x and npc["y"] == y:
			return npc
	return {}

func get_item_at(x: int, y: int) -> Dictionary:
	for item in items:
		if item["x"] == x and item["y"] == y and not item.get("collected", false):
			return item
	return {}

func spawn_encounter() -> Dictionary:
	if encounter_table.is_empty():
		return {}
	# Weighted random from encounter table
	var total_weight = 0.0
	for entry in encounter_table:
		total_weight += entry.get("weight", 10.0)
	var roll = randf() * total_weight
	for entry in encounter_table:
		roll -= entry.get("weight", 10.0)
		if roll <= 0:
			return entry
	return encounter_table.back()

func _draw() -> void:
	for y in height:
		for x in width:
			var tile = get_tile(x, y)
			var color = TILE_COLORS.get(tile, Color.BLACK)
			var rect = Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			draw_rect(rect, color)

			# Tile details
			_draw_tile_detail(x, y, tile)

	# Draw items
	for item in items:
		if not item.get("collected", false):
			draw_circle(Vector2(item["x"] * TILE_SIZE + 8, item["y"] * TILE_SIZE + 8), 4, Color("#ffd700"))

	# Draw NPCs as colored circles with direction indicator
	for npc in npcs:
		var nx = npc["x"] * TILE_SIZE + 8
		var ny = npc["y"] * TILE_SIZE + 8
		var npc_color = Color("#e53935") if npc.get("type", "") == "trainer" else Color("#4fc3f7")
		if npc.get("type", "") == "gym_leader":
			npc_color = Color("#ffd700")
		elif npc.get("type", "") == "rival":
			npc_color = Color("#ff9800")
		elif npc.get("type", "") == "rocket":
			npc_color = Color("#9c27b0")
		draw_circle(Vector2(nx, ny), 6, npc_color)
		draw_arc(Vector2(nx, ny), 6, 0, TAU, 8, Color.WHITE, 1.0)

	# Draw exit arrows
	for ex in exits:
		var ex_x = ex["x"] * TILE_SIZE + 8
		var ex_y = ex["y"] * TILE_SIZE + 8
		draw_circle(Vector2(ex_x, ex_y), 3, Color(0, 1, 0, 0.5))

	# Area name label (top center)
	draw_rect(Rect2(width * TILE_SIZE / 2 - 60, 2, 120, 16), Color(0, 0, 0, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(width * TILE_SIZE / 2 - 55, 14), area_name, HORIZONTAL_ALIGNMENT_CENTER, 110, 11, Color.WHITE)

func _draw_tile_detail(x: int, y: int, tile: int) -> void:
	var tx = x * TILE_SIZE
	var ty = y * TILE_SIZE

	# Grid lines
	draw_line(Vector2(tx, ty), Vector2(tx + TILE_SIZE, ty), Color(0, 0, 0, 0.06), 0.5)
	draw_line(Vector2(tx, ty), Vector2(tx, ty + TILE_SIZE), Color(0, 0, 0, 0.06), 0.5)

	match tile:
		Tile.TALL_GRASS:
			var seed_val = (x * 7 + y * 13) % 4
			for g in seed_val:
				var gx = tx + (g * 5 + 3) % TILE_SIZE
				var gy = ty + (g * 7 + 2) % TILE_SIZE
				draw_line(Vector2(gx, gy + 5), Vector2(gx + 1, gy), Color(0.15, 0.4, 0.15, 0.5), 1.0)

		Tile.WATER:
			var t = Time.get_ticks_msec() * 0.001
			var wave = sin(t * 2.0 + x + y * 0.5) * 0.15
			draw_rect(Rect2(tx + 2, ty + 6 + wave * 6, TILE_SIZE - 4, 2), Color(1, 1, 1, 0.15))

		Tile.TREE:
			# Trunk
			draw_rect(Rect2(tx + 6, ty + 10, 4, 6), Color("#5d4037"))
			# Canopy
			draw_circle(Vector2(tx + 8, ty + 7), 5, Color("#2e7d32"))

		Tile.POKECENTER:
			# Red cross
			draw_rect(Rect2(tx + 6, ty + 3, 4, 10), Color("#ef5350"))
			draw_rect(Rect2(tx + 3, ty + 6, 10, 4), Color("#ef5350"))

		Tile.SHOP:
			# Blue store icon
			draw_rect(Rect2(tx + 3, ty + 4, 10, 8), Color("#1565c0"))
			draw_rect(Rect2(tx + 5, ty + 8, 3, 4), Color("#e0e0e0"))  # door

		Tile.GYM_FLOOR:
			# Gym badge marker
			if (x + y) % 3 == 0:
				draw_circle(Vector2(tx + 8, ty + 8), 3, Color(1, 0.85, 0.2, 0.3))

		Tile.FLOWER:
			draw_circle(Vector2(tx + 5, ty + 5), 2, Color("#e91e63"))
			draw_circle(Vector2(tx + 11, ty + 10), 2, Color("#ffeb3b"))

		Tile.FENCE:
			draw_rect(Rect2(tx + 2, ty + 6, TILE_SIZE - 4, 2), Color("#795548"))
			draw_rect(Rect2(tx + 4, ty + 2, 2, 12), Color("#795548"))
			draw_rect(Rect2(tx + 10, ty + 2, 2, 12), Color("#795548"))

		Tile.SIGN:
			draw_rect(Rect2(tx + 4, ty + 4, 8, 6), Color("#f9a825"))
			draw_rect(Rect2(tx + 7, ty + 10, 2, 4), Color("#795548"))

		Tile.DOOR:
			draw_rect(Rect2(tx + 4, ty + 2, 8, 12), Color("#6d4c41"))
			draw_circle(Vector2(tx + 10, ty + 8), 1.5, Color("#ffd700"))

		Tile.CAVE_FLOOR:
			if (x * 11 + y * 7) % 5 == 0:
				draw_circle(Vector2(tx + 8, ty + 8), 1, Color(0.3, 0.3, 0.3, 0.3))

		Tile.SNOW:
			# Snowflake sparkles
			if (x * 13 + y * 7) % 5 == 0:
				draw_circle(Vector2(tx + 8, ty + 6), 1.5, Color(1, 1, 1, 0.6))
			if (x * 11 + y * 3) % 7 == 0:
				draw_circle(Vector2(tx + 4, ty + 12), 1, Color(1, 1, 1, 0.4))

		Tile.ICE:
			# Ice shine lines
			draw_line(Vector2(tx + 2, ty + 4), Vector2(tx + 10, ty + 12), Color(1, 1, 1, 0.3), 0.5)
			draw_line(Vector2(tx + 8, ty + 2), Vector2(tx + 14, ty + 8), Color(1, 1, 1, 0.2), 0.5)

		Tile.LAVA:
			# Lava bubble animation
			var lt = Time.get_ticks_msec() * 0.002
			var bubble = sin(lt + x * 2 + y * 3) * 0.3
			draw_circle(Vector2(tx + 6 + bubble * 4, ty + 8), 2, Color(1, 0.8, 0, 0.5))

		Tile.VOLCANO_ROCK:
			# Cracks with glow
			draw_line(Vector2(tx + 3, ty + 5), Vector2(tx + 12, ty + 10), Color(1, 0.3, 0, 0.3), 1.0)

		Tile.SWAMP:
			# Murky water spots
			draw_circle(Vector2(tx + 5, ty + 8), 3, Color(0.2, 0.35, 0.15, 0.3))
			draw_circle(Vector2(tx + 11, ty + 5), 2, Color(0.25, 0.4, 0.1, 0.2))

		Tile.BRIDGE:
			# Plank lines
			for i in 3:
				draw_line(Vector2(tx, ty + 4 + i * 4), Vector2(tx + TILE_SIZE, ty + 4 + i * 4), Color(0.4, 0.25, 0.15, 0.4), 1.0)

		Tile.RUINS:
			# Cracked stone
			draw_rect(Rect2(tx + 2, ty + 2, 5, 5), Color(0.5, 0.55, 0.6, 0.3))
			draw_rect(Rect2(tx + 9, ty + 8, 4, 6), Color(0.5, 0.55, 0.6, 0.2))

		Tile.BERRY_BUSH:
			# Bush with berries
			draw_circle(Vector2(tx + 8, ty + 8), 5, Color(0.2, 0.5, 0.2, 0.6))
			draw_circle(Vector2(tx + 5, ty + 6), 2, Color(0.9, 0.2, 0.3))
			draw_circle(Vector2(tx + 11, ty + 7), 2, Color(0.9, 0.2, 0.3))

		Tile.LAKE_SHORE:
			# Sandy shore with water line
			var wt = Time.get_ticks_msec() * 0.001
			var wave = sin(wt + x * 0.5) * 2
			draw_line(Vector2(tx, ty + 12 + wave), Vector2(tx + TILE_SIZE, ty + 12 + wave), Color(0.3, 0.6, 0.9, 0.3), 1.5)

func _process(_delta):
	# Water animation
	queue_redraw()
