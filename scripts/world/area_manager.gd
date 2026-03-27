extends Node2D

var AreaScript = preload("res://scripts/world/area.gd")
var AreaDataScript = preload("res://scripts/data/area_data.gd")

var current_area: Node2D = null  # Area instance
var current_area_name: String = ""
var area_data_source = null

func _ready():
	area_data_source = AreaDataScript.new()

func load_area(area_name: String, player_x: int = -1, player_y: int = -1) -> Dictionary:
	# Remove old area
	if current_area:
		current_area.queue_free()

	# Get area data
	var data = area_data_source.get_area(area_name)
	if data.is_empty():
		push_error("Area not found: " + area_name)
		return {}

	# Create new area
	current_area = AreaScript.new()
	current_area.setup(data)
	current_area_name = area_name
	add_child(current_area)

	# Return spawn position
	if player_x >= 0 and player_y >= 0:
		return {"x": player_x, "y": player_y}
	else:
		# Default spawn (first exit or center)
		var default_pos = data.get("spawn", {"x": data["width"] / 2, "y": data["height"] / 2})
		return default_pos

func get_tile_at(x: int, y: int) -> int:
	if current_area:
		return current_area.get_tile(x, y)
	return 6  # WALL

func is_walkable_at(world_x: float, world_y: float) -> bool:
	var tx = int(world_x / 16)
	var ty = int(world_y / 16)
	if current_area:
		return current_area.is_walkable(tx, ty)
	return false

func check_exit(world_x: float, world_y: float) -> Dictionary:
	var tx = int(world_x / 16)
	var ty = int(world_y / 16)
	if current_area:
		return current_area.get_exit_at(tx, ty)
	return {}

func check_npc(world_x: float, world_y: float) -> Dictionary:
	var tx = int(world_x / 16)
	var ty = int(world_y / 16)
	if current_area:
		# Check adjacent tiles too (facing direction)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var npc = current_area.get_npc_at(tx + dx, ty + dy)
				if not npc.is_empty():
					return npc
	return {}

var _last_encounter_tile: Vector2i = Vector2i(-999, -999)

func check_encounter(tile_x: int, tile_y: int) -> Dictionary:
	if current_area and current_area.is_encounter_tile(tile_x, tile_y):
		var current_tile = Vector2i(tile_x, tile_y)
		# Only check once per new tile stepped on (not per frame)
		if current_tile != _last_encounter_tile:
			_last_encounter_tile = current_tile
			if randf() < 0.12:  # 12% chance per new tile
				return current_area.spawn_encounter()
	return {}

func check_item(world_x: float, world_y: float) -> Dictionary:
	var tx = int(world_x / 16)
	var ty = int(world_y / 16)
	if current_area:
		return current_area.get_item_at(tx, ty)
	return {}

func get_current_area_name() -> String:
	return current_area_name

func get_tile_at_world(world_x: float, world_y: float) -> int:
	var tx = int(world_x / 16)
	var ty = int(world_y / 16)
	return get_tile_at(tx, ty)

func get_area_size() -> Vector2:
	if current_area:
		return Vector2(current_area.width * 16, current_area.height * 16)
	return Vector2(480, 320)
