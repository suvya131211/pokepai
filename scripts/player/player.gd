extends CharacterBody2D
class_name PlayerCharacter

const SPEED := 100.0
const SPRINT_SPEED := 160.0
const TILE_SIZE := 16

var direction: String = "down"  # up/down/left/right
var is_moving: bool = false
var step_accumulator: float = 0.0
var follower_pokemon = null  # Pokemon instance
var _follower_pos: Vector2 = Vector2.ZERO

@onready var chunk_manager: ChunkManager = get_parent().get_node("ChunkManager")

signal encountered_pokemon(pokemon)
signal entered_town(town_info: Dictionary)

func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.WORLD:
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	is_moving = input_dir.length() > 0.1

	if is_moving:
		# Set direction
		if abs(input_dir.x) > abs(input_dir.y):
			direction = "right" if input_dir.x > 0 else "left"
		else:
			direction = "down" if input_dir.y > 0 else "up"

		var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED
		var desired_velocity := input_dir.normalized() * speed

		# Check walkability before moving
		var next_pos := global_position + desired_velocity * delta
		if chunk_manager.is_walkable_at(next_pos.x, next_pos.y):
			velocity = desired_velocity
		else:
			# Try sliding along axes
			if chunk_manager.is_walkable_at(global_position.x + desired_velocity.x * delta, global_position.y):
				velocity = Vector2(desired_velocity.x, 0)
			elif chunk_manager.is_walkable_at(global_position.x, global_position.y + desired_velocity.y * delta):
				velocity = Vector2(0, desired_velocity.y)
			else:
				velocity = Vector2.ZERO

		move_and_slide()
		step_accumulator += velocity.length() * delta

		# Update chunk manager
		chunk_manager.update_player_position(global_position)

		# Collect nearby items
		_check_item_pickups()

		# Check town entry
		var town := chunk_manager.get_nearby_town(global_position)
		if not town.is_empty() and town["name"] not in GameManager.towns_visited:
			GameManager.towns_visited.append(town["name"])
			entered_town.emit(town)
	else:
		velocity = Vector2.ZERO

	queue_redraw()

func consume_steps(threshold: float) -> bool:
	if step_accumulator >= threshold:
		step_accumulator = 0.0
		return true
	return false

func get_current_tile() -> int:
	return chunk_manager.get_tile_at_world(global_position.x, global_position.y)

func _check_item_pickups() -> void:
	var items := chunk_manager.get_nearby_items(global_position, 20.0)
	for item in items:
		item["collected"] = true
		GameManager.item_collected.emit(item["type"])
		# Chunk needs redraw
		var chunk := chunk_manager.get_chunk_at(global_position)
		if chunk:
			chunk.queue_redraw()

func _draw() -> void:
	# Player body (16x16 centered)
	var body_color := Color("#3f51b5")
	draw_rect(Rect2(-8, -8, 16, 16), body_color)

	# Eyes based on direction
	var eye_color := Color.WHITE
	match direction:
		"down":
			draw_rect(Rect2(-5, -3, 3, 3), eye_color)
			draw_rect(Rect2(2, -3, 3, 3), eye_color)
		"up":
			draw_rect(Rect2(-5, -1, 3, 3), eye_color)
			draw_rect(Rect2(2, -1, 3, 3), eye_color)
		"left":
			draw_rect(Rect2(-6, -3, 3, 3), eye_color)
		"right":
			draw_rect(Rect2(3, -3, 3, 3), eye_color)

	# Follower pokemon (trails behind)
	if follower_pokemon:
		_follower_pos = _follower_pos.lerp(global_position + Vector2(-20, 8), 0.08)
		var offset := _follower_pos - global_position
		draw_circle(offset, 7, follower_pokemon.color)
		draw_arc(offset, 7, 0, TAU, 16, Color.WHITE, 1.5)
