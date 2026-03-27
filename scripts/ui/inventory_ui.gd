extends Control
class_name InventoryUI

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func toggle(inventory) -> void:
	visible = !visible
	if visible:
		GameManager.change_state(GameManager.GameState.INVENTORY)
	else:
		GameManager.change_state(GameManager.GameState.WORLD)

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("open_inventory") or event.is_action_pressed("pause_menu")):
		visible = false
		GameManager.change_state(GameManager.GameState.WORLD)
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.07, 0.12, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(24, 40), "INVENTORY", HORIZONTAL_ALIGNMENT_LEFT, w, 20, Color("#4fc3f7"))

	# Balls section
	var y := 70.0
	draw_string(ThemeDB.fallback_font, Vector2(24, y), "Pokeballs", HORIZONTAL_ALIGNMENT_LEFT, w, 16, Color("#e0e0e0"))
	y += 28

	# Draw ball items (will be populated from player inventory in main scene)
	var ball_items := ["pokeball", "greatball", "ultraball"]
	var ball_colors := {"pokeball": Color("#f44336"), "greatball": Color("#2196f3"), "ultraball": Color("#ffd700")}
	for ball_type in ball_items:
		draw_circle(Vector2(40, y + 8), 10, ball_colors[ball_type])
		draw_circle(Vector2(40, y + 13), 10, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(60, y + 14), "%s: ?" % ball_type.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, w, 14, Color("#ccc"))
		y += 32

	y += 16
	draw_string(ThemeDB.fallback_font, Vector2(24, y), "Berries", HORIZONTAL_ALIGNMENT_LEFT, w, 16, Color("#e0e0e0"))
	y += 28
	var berry_colors := {"razz": Color("#e91e63"), "nanab": Color("#ffeb3b"), "pinap": Color("#8bc34a")}
	for berry_type in ["razz", "nanab", "pinap"]:
		draw_circle(Vector2(40, y + 8), 8, berry_colors[berry_type])
		draw_string(ThemeDB.fallback_font, Vector2(60, y + 14), "%s Berry: ?" % berry_type.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, w, 14, Color("#ccc"))
		y += 32

	draw_string(ThemeDB.fallback_font, Vector2(24, h - 16), "Press I or ESC to close", HORIZONTAL_ALIGNMENT_LEFT, w, 12, Color("#888"))
