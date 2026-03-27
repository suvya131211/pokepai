extends Node
class_name WorldGenerator

# Tile IDs (matching TileMapLayer atlas coords)
enum Tile {
	DEEP_WATER = 0,
	WATER = 1,
	SAND = 2,
	GRASS = 3,
	TALL_GRASS = 4,
	FOREST = 5,
	MOUNTAIN = 6,
	CAVE = 7,
	PATH = 8,
	TOWN = 9,
	SNOW = 10,
	SNOW_FOREST = 11,
	VOLCANIC = 12,
	BEACH = 13,
}

# Tile colors for drawing
const TILE_COLORS := {
	Tile.DEEP_WATER: Color("#0d3d5c"),
	Tile.WATER:      Color("#2196f3"),
	Tile.SAND:       Color("#f5d67a"),
	Tile.GRASS:      Color("#4caf50"),
	Tile.TALL_GRASS: Color("#2e7d32"),
	Tile.FOREST:     Color("#1b5e20"),
	Tile.MOUNTAIN:   Color("#795548"),
	Tile.CAVE:       Color("#4a4a4a"),
	Tile.PATH:       Color("#bcaaa4"),
	Tile.TOWN:       Color("#e0e0e0"),
	Tile.SNOW:       Color("#e8eaf6"),
	Tile.SNOW_FOREST:Color("#90a4ae"),
	Tile.VOLCANIC:   Color("#bf360c"),
	Tile.BEACH:      Color("#ffe0b2"),
}

const WALKABLE := {
	Tile.DEEP_WATER: false, Tile.WATER: false, Tile.MOUNTAIN: false,
	Tile.SAND: true, Tile.GRASS: true, Tile.TALL_GRASS: true,
	Tile.FOREST: true, Tile.CAVE: true, Tile.PATH: true,
	Tile.TOWN: true, Tile.SNOW: true, Tile.SNOW_FOREST: true,
	Tile.VOLCANIC: true, Tile.BEACH: true,
}

# Habitat mapping for spawning
const TILE_HABITAT := {
	Tile.GRASS: "grass", Tile.TALL_GRASS: "tall_grass", Tile.FOREST: "forest",
	Tile.SAND: "sand", Tile.CAVE: "cave", Tile.MOUNTAIN: "mountain",
	Tile.PATH: "path", Tile.TOWN: "town", Tile.SNOW: "snow",
	Tile.SNOW_FOREST: "snow", Tile.VOLCANIC: "cave", Tile.BEACH: "beach",
}

# Encounter step thresholds
const ENCOUNTER_STEPS := {
	"grass": 200.0, "tall_grass": 100.0, "forest": 150.0,
	"sand": 250.0, "cave": 120.0, "mountain": 300.0,
	"path": 0.0, "town": 0.0, "snow": 200.0, "beach": 250.0,
}

const CHUNK_SIZE := 16
const TILE_SIZE := 16  # pixels

var elevation_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var temperature_noise: FastNoiseLite

func _init() -> void:
	elevation_noise = FastNoiseLite.new()
	elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	elevation_noise.frequency = 0.008
	elevation_noise.fractal_octaves = 4
	elevation_noise.seed = randi()

	moisture_noise = FastNoiseLite.new()
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moisture_noise.frequency = 0.006
	moisture_noise.fractal_octaves = 3
	moisture_noise.seed = elevation_noise.seed + 1000

	temperature_noise = FastNoiseLite.new()
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	temperature_noise.frequency = 0.003
	temperature_noise.fractal_octaves = 2
	temperature_noise.seed = elevation_noise.seed + 2000

func get_tile(world_x: int, world_y: int) -> int:
	var e := (elevation_noise.get_noise_2d(world_x, world_y) + 1.0) / 2.0
	var m := (moisture_noise.get_noise_2d(world_x, world_y) + 1.0) / 2.0
	var t := (temperature_noise.get_noise_2d(world_x, world_y) + 1.0) / 2.0

	# Water
	if e < 0.30: return Tile.DEEP_WATER
	if e < 0.38: return Tile.WATER
	# Beach (narrow band near water)
	if e < 0.42: return Tile.BEACH if m > 0.3 else Tile.SAND

	# Cold biome
	if t < 0.3:
		if e < 0.65: return Tile.SNOW
		if e < 0.75: return Tile.SNOW_FOREST
		return Tile.MOUNTAIN

	# Hot biome
	if t > 0.75:
		if e < 0.55: return Tile.SAND
		if e < 0.65: return Tile.VOLCANIC
		return Tile.MOUNTAIN

	# Temperate biome
	if e < 0.55:
		return Tile.TALL_GRASS if m > 0.6 else Tile.GRASS
	if e < 0.65:
		return Tile.FOREST if m > 0.5 else Tile.GRASS
	if e < 0.80:
		return Tile.MOUNTAIN
	return Tile.CAVE

func is_walkable(tile: int) -> bool:
	return WALKABLE.get(tile, false)

func is_town_location(chunk_x: int, chunk_y: int) -> bool:
	# Towns at fixed intervals (every 8 chunks = 128 tiles apart)
	# plus the origin town at (0,0)
	if chunk_x == 0 and chunk_y == 0:
		return true
	if chunk_x % 8 == 0 and chunk_y % 8 == 0:
		# Hash to deterministic but sparse placement
		var h = hash(Vector2i(chunk_x, chunk_y))
		return (h % 5) == 0  # ~20% of grid points become towns
	return false

func get_town_name(chunk_x: int, chunk_y: int) -> String:
	if chunk_x == 0 and chunk_y == 0:
		return "Starter Town"
	var names := ["Oakvale", "Pinecrest", "Frosthollow", "Ashpeak", "Rivermere",
				   "Duskwood", "Thunderridge", "Coralshore", "Ironforge", "Moonwell",
				   "Stormhaven", "Goldleaf", "Shadowfen", "Crystalveil", "Emberglow"]
	var idx := absi(hash(Vector2i(chunk_x, chunk_y))) % names.size()
	return names[idx]
