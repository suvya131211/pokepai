extends Node2D
class_name ChunkManager

const WorldGeneratorScript = preload("res://scripts/world/world_generator.gd")
const ChunkScript = preload("res://scripts/world/chunk.gd")

const CHUNK_SIZE := 16
const TILE_SIZE := 16
const LOAD_RADIUS := 4   # chunks around player to keep loaded
const UNLOAD_RADIUS := 6  # chunks beyond this get freed

var generator
var loaded_chunks: Dictionary = {}  # Vector2i -> Chunk
var player_chunk: Vector2i = Vector2i.ZERO

func _ready() -> void:
	generator = WorldGeneratorScript.new()
	# Carve starter town at origin
	_load_chunks_around(Vector2i.ZERO)

func update_player_position(world_pos: Vector2) -> void:
	var new_chunk := Vector2i(
		floori(world_pos.x / (CHUNK_SIZE * TILE_SIZE)),
		floori(world_pos.y / (CHUNK_SIZE * TILE_SIZE))
	)
	if new_chunk != player_chunk:
		player_chunk = new_chunk
		GameManager.player_chunk = new_chunk
		_load_chunks_around(new_chunk)
		_unload_distant_chunks(new_chunk)

func _load_chunks_around(center: Vector2i) -> void:
	for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var cpos := Vector2i(center.x + dx, center.y + dy)
			if cpos not in loaded_chunks:
				_create_chunk(cpos)

func _create_chunk(cpos: Vector2i) -> void:
	var chunk = ChunkScript.new()
	chunk.generate(cpos.x, cpos.y, generator)
	loaded_chunks[cpos] = chunk
	add_child(chunk)

func _unload_distant_chunks(center: Vector2i) -> void:
	var to_remove: Array[Vector2i] = []
	for cpos in loaded_chunks:
		if absi(cpos.x - center.x) > UNLOAD_RADIUS or absi(cpos.y - center.y) > UNLOAD_RADIUS:
			to_remove.append(cpos)
	for cpos in to_remove:
		var chunk = loaded_chunks[cpos]
		chunk.queue_free()
		loaded_chunks.erase(cpos)

func get_tile_at_world(world_x: float, world_y: float) -> int:
	var cx := floori(world_x / (CHUNK_SIZE * TILE_SIZE))
	var cy := floori(world_y / (CHUNK_SIZE * TILE_SIZE))
	var cpos := Vector2i(cx, cy)
	if cpos in loaded_chunks:
		var chunk = loaded_chunks[cpos]
		var lx := floori(world_x / TILE_SIZE) - cx * CHUNK_SIZE
		var ly := floori(world_y / TILE_SIZE) - cy * CHUNK_SIZE
		return chunk.get_tile_at(lx, ly)
	return WorldGeneratorScript.Tile.MOUNTAIN  # unloaded = impassable

func is_walkable_at(world_x: float, world_y: float) -> bool:
	return generator.is_walkable(get_tile_at_world(world_x, world_y))

func get_chunk_at(world_pos: Vector2):
	var cx := floori(world_pos.x / (CHUNK_SIZE * TILE_SIZE))
	var cy := floori(world_pos.y / (CHUNK_SIZE * TILE_SIZE))
	return loaded_chunks.get(Vector2i(cx, cy), null)

func get_nearby_items(world_pos: Vector2, radius: float = 24.0) -> Array:
	var results = []
	var chunk = get_chunk_at(world_pos)
	if chunk:
		for item in chunk.items:
			if item["collected"]:
				continue
			var ix = float(chunk.position.x) + float(item["lx"]) * TILE_SIZE + TILE_SIZE / 2.0
			var iy = float(chunk.position.y) + float(item["ly"]) * TILE_SIZE + TILE_SIZE / 2.0
			if world_pos.distance_to(Vector2(ix, iy)) < radius:
				results.append(item)
	return results

func get_nearby_town(world_pos: Vector2) -> Dictionary:
	var chunk = get_chunk_at(world_pos)
	if chunk and chunk.is_town:
		return {"name": chunk.town_name, "chunk_pos": chunk.chunk_pos}
	return {}

func get_all_town_chunks() -> Array:
	var towns = []
	for cpos in loaded_chunks:
		var chunk = loaded_chunks[cpos]
		if chunk.is_town:
			towns.append({"name": chunk.town_name, "chunk_pos": cpos})
	return towns
