extends Control
class_name PokedexUI

const COLS := 5
const CELL_W := 100.0
const CELL_H := 100.0

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func toggle() -> void:
	visible = !visible
	if visible:
		GameManager.change_state(GameManager.GameState.POKEDEX)
	else:
		GameManager.change_state(GameManager.GameState.WORLD)

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("open_pokedex") or event.is_action_pressed("pause_menu")):
		toggle()
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

	var stats := GameManager.get_pokedex_count()
	draw_string(ThemeDB.fallback_font, Vector2(24, 40), "POKEDEX  %d/%d" % [stats["caught"], stats["total"]], HORIZONTAL_ALIGNMENT_LEFT, w, 20, Color("#4fc3f7"))

	var start_x := 24.0
	var start_y := 60.0

	for i in PokemonDB.species.size():
		var s: Dictionary = PokemonDB.species[i]
		var col := i % COLS
		var row := i / COLS
		var x := start_x + col * CELL_W
		var y := start_y + row * CELL_H
		var is_caught: bool = s["id"] in GameManager.pokedex_caught

		draw_rect(Rect2(x, y, CELL_W - 6, CELL_H - 6), Color("#1c3144"))
		draw_rect(Rect2(x, y, CELL_W - 6, CELL_H - 6), Color("#4caf50") if is_caught else Color("#333"), false, 1.5)

		# Circle
		draw_circle(Vector2(x + 35, y + 35), 22, s["color"] if is_caught else Color("#333"))
		draw_arc(Vector2(x + 35, y + 35), 22, 0, TAU, 16, Color("#555"), 1.0)

		# ID
		draw_string(ThemeDB.fallback_font, Vector2(x + 4, y + 16), "#%03d" % s["id"], HORIZONTAL_ALIGNMENT_LEFT, CELL_W, 10, Color("#888"))

		# Name
		draw_string(ThemeDB.fallback_font, Vector2(x + 4, y + CELL_H - 16), s["name"] if is_caught else "???", HORIZONTAL_ALIGNMENT_LEFT, CELL_W - 10, 10, Color("#e0e0e0") if is_caught else Color("#444"))

	draw_string(ThemeDB.fallback_font, Vector2(24, h - 16), "Press P or ESC to close", HORIZONTAL_ALIGNMENT_LEFT, w, 12, Color("#888"))
