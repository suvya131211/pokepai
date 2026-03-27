extends Control
class_name Hotbar

const SLOT_SIZE := 40.0
const SLOT_PADDING := 4.0
const MAX_SLOTS := 6

func _ready() -> void:
	# Position at bottom center
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	# Reposition on resize
	var vp := get_viewport_rect().size
	position = Vector2((vp.x - (SLOT_SIZE + SLOT_PADDING) * MAX_SLOTS) / 2.0, vp.y - SLOT_SIZE - 12)
	queue_redraw()

func _draw() -> void:
	if GameManager.state != GameManager.GameState.WORLD:
		return

	var party := GameManager.party
	for i in MAX_SLOTS:
		var x := i * (SLOT_SIZE + SLOT_PADDING)
		# Slot background
		draw_rect(Rect2(x, 0, SLOT_SIZE, SLOT_SIZE), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(x, 0, SLOT_SIZE, SLOT_SIZE), Color("#4fc3f7") if i < party.size() else Color("#333"), false, 1.5)

		if i < party.size():
			var pkmn: Pokemon = party[i]
			# Pokemon circle
			draw_circle(Vector2(x + SLOT_SIZE / 2, SLOT_SIZE / 2 - 2), 12.0, pkmn.color)
			draw_arc(Vector2(x + SLOT_SIZE / 2, SLOT_SIZE / 2 - 2), 12.0, 0, TAU, 12, Color.WHITE, 1.0)
			# HP bar under
			var hp_ratio := float(pkmn.hp) / float(pkmn.max_hp)
			var bar_color := Color("#4caf50") if hp_ratio > 0.5 else (Color("#ff9800") if hp_ratio > 0.25 else Color("#f44336"))
			draw_rect(Rect2(x + 4, SLOT_SIZE - 8, (SLOT_SIZE - 8) * hp_ratio, 4), bar_color)
			draw_rect(Rect2(x + 4, SLOT_SIZE - 8, SLOT_SIZE - 8, 4), Color("#333"), false, 0.5)
			# Level
			draw_string(ThemeDB.fallback_font, Vector2(x + 2, SLOT_SIZE - 10), "Lv%d" % pkmn.level, HORIZONTAL_ALIGNMENT_LEFT, SLOT_SIZE, 8, Color("#aaa"))

	# Ball count to the right
	var ball_x := MAX_SLOTS * (SLOT_SIZE + SLOT_PADDING) + 10
	draw_circle(Vector2(ball_x + 8, SLOT_SIZE / 2), 6, Color("#f44336"))
	draw_circle(Vector2(ball_x + 8, SLOT_SIZE / 2 + 3), 6, Color.WHITE)
	# TODO: show total ball count from inventory
