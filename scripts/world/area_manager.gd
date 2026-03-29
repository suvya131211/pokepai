extends Node2D

var AreaScript = preload("res://scripts/world/area.gd")
var AreaDataScript = preload("res://scripts/data/area_data.gd")

var current_area: Node2D = null  # Area instance
var current_area_name: String = ""
var area_data_source = null

func _ready():
	area_data_source = AreaDataScript.new()

func load_area(area_name: String, player_x: int = -1, player_y: int = -1) -> Dictionary:
	# Remove old area immediately
	if current_area:
		remove_child(current_area)
		current_area.free()
		current_area = null

	# Get area data
	if not area_data_source:
		push_error("[AREA] area_data_source is NULL! Recreating...")
		area_data_source = AreaDataScript.new()
	var data = area_data_source.get_area(area_name)
	EventTracker.log_event("AREA_LOAD_DEBUG", {"name": area_name, "data_empty": data.is_empty(), "has_tiles": data.has("tiles"), "tiles_size": data.get("tiles", []).size() if data.has("tiles") else -1})
	if data.is_empty():
		push_error("[AREA] Area not found: " + area_name)
		return {"x": 14, "y": 10}

	# Create new area
	current_area = AreaScript.new()
	current_area.setup(data)
	current_area_name = area_name
	current_area.z_index = 0  # ensure tiles draw below player (z_index=10)
	add_child(current_area)
	current_area.queue_redraw()
	_last_encounter_tile = Vector2i(-999, -999)  # reset encounter tracking
	print("[AREA] Loaded: %s (%dx%d), encounters: %d, pos: %s" % [area_name, data.get("width",0), data.get("height",0), data.get("encounters",[]).size(), str(current_area.position)])

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

func check_npc_facing(world_x: float, world_y: float, direction: String) -> Dictionary:
	var tx = int(world_x / 16)
	var ty = int(world_y / 16)
	if not current_area:
		return {}
	# Only check the tile the player is facing
	var dx = 0
	var dy = 0
	match direction:
		"up": dy = -1
		"down": dy = 1
		"left": dx = -1
		"right": dx = 1
	var npc = current_area.get_npc_at(tx + dx, ty + dy)
	if not npc.is_empty():
		return npc
	# Also check current tile
	npc = current_area.get_npc_at(tx, ty)
	return npc

var _last_encounter_tile: Vector2i = Vector2i(-999, -999)

func check_encounter(tile_x: int, tile_y: int) -> Dictionary:
	if current_area and current_area.is_encounter_tile(tile_x, tile_y):
		var current_tile = Vector2i(tile_x, tile_y)
		# Only check once per new tile stepped on (not per frame)
		if current_tile != _last_encounter_tile:
			_last_encounter_tile = current_tile
			# Lower rate for caves (every tile is encounter), higher for grass patches
			var rate = 0.03 if current_area.area_type == "cave" else 0.06
			if randf() < rate:  # 3% cave, 6% grass
				var entry = current_area.spawn_encounter()
				# Post-game level boost
				if not entry.is_empty() and StoryEvents.has_flag("champion"):
					entry = entry.duplicate()
					entry["min_level"] = entry.get("min_level", 5) + 10
					entry["max_level"] = entry.get("max_level", 10) + 15
				return entry
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

func check_trainer_los(player_x: float, player_y: float) -> Dictionary:
	if current_area:
		var tx = int(player_x / 16)
		var ty = int(player_y / 16)
		return current_area.check_trainer_los(tx, ty)
	return {}

func check_hidden_item(world_x: float, world_y: float) -> Dictionary:
	var tx = int(world_x / 16)
	var ty = int(world_y / 16)
	if current_area:
		for item in current_area.hidden_items:
			if item["x"] == tx and item["y"] == ty and not item.get("found", false):
				item["found"] = true
				return item
	return {}
