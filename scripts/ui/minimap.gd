extends Control
class_name Minimap

const WorldGeneratorScript = preload("res://scripts/world/world_generator.gd")

const MAP_SIZE := 100.0  # pixels
const MAP_RADIUS := 6    # chunks to show

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	var vp := get_viewport_rect().size
	position = Vector2(vp.x - MAP_SIZE - 12, 12)
	queue_redraw()

func _draw() -> void:
	if GameManager.state != GameManager.GameState.WORLD:
		return

	# Background
	draw_rect(Rect2(-2, -2, MAP_SIZE + 4, MAP_SIZE + 4), Color(0, 0, 0, 0.7))

	var center := GameManager.player_chunk
	var scale_px := MAP_SIZE / (MAP_RADIUS * 2.0 + 1.0)

	# Draw chunk colors
	for dy in range(-MAP_RADIUS, MAP_RADIUS + 1):
		for dx in range(-MAP_RADIUS, MAP_RADIUS + 1):
			var cx := center.x + dx
			var cy := center.y + dy
			var mx := (dx + MAP_RADIUS) * scale_px
			var my := (dy + MAP_RADIUS) * scale_px

			# Get average color from generator
			var world_gen = WorldGeneratorScript.new()
			var tile = world_gen.get_tile(cx * 16 + 8, cy * 16 + 8)
			var color = WorldGeneratorScript.TILE_COLORS.get(tile, Color.BLACK)
			draw_rect(Rect2(mx, my, scale_px, scale_px), color)

	# Player dot (center)
	var player_mx := MAP_RADIUS * scale_px + scale_px / 2
	var player_my := MAP_RADIUS * scale_px + scale_px / 2
	draw_circle(Vector2(player_mx, player_my), 3, Color.WHITE)

	# Info label
	var phase_icon = {"day":"☀","dawn":"🌅","dusk":"🌇","night":"🌙"}.get(GameManager.time_of_day, "")
	draw_string(ThemeDB.fallback_font, Vector2(0, MAP_SIZE + 14), "%s %s" % [phase_icon, GameManager.weather], HORIZONTAL_ALIGNMENT_LEFT, MAP_SIZE, 10, Color("#aaa"))
