extends Control

var active_challenge: String = ""
var challenge_stats: Dictionary = {
	"pokemon_caught_count": 0,
	"battle_tower_floor": 0,
	"speedrun_time": 0.0,
}

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_J:
		if GameManager.state == GameManager.GameState.WORLD:
			visible = !visible
			get_viewport().set_input_as_handled()
			queue_redraw()
	if visible and event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			visible = false
		elif event.keycode == KEY_1:
			_start_catch_challenge()
		elif event.keycode == KEY_2:
			_start_speedrun_timer()

func _start_catch_challenge():
	active_challenge = "catch_all"
	visible = false
	challenge_stats["pokemon_caught_count"] = GameManager.pokedex_caught.size()

func _start_speedrun_timer():
	active_challenge = "speedrun"
	challenge_stats["speedrun_time"] = 0.0
	visible = false

func _process(delta):
	if active_challenge == "speedrun":
		challenge_stats["speedrun_time"] += delta
	if active_challenge == "catch_all":
		challenge_stats["pokemon_caught_count"] = GameManager.pokedex_caught.size()
	if visible:
		queue_redraw()

func _draw():
	if not visible:
		return
	var vp = get_viewport_rect().size
	var w = vp.x
	var h = vp.y

	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.8))

	var pw = 400.0
	var ph = 300.0
	var px = (w - pw) / 2
	var py = (h - ph) / 2
	draw_rect(Rect2(px, py, pw, ph), Color(0.05, 0.07, 0.12, 0.98))
	draw_rect(Rect2(px, py, pw, ph), Color("#4fc3f7"), false, 2.0)

	draw_string(ThemeDB.fallback_font, Vector2(px + 20, py + 30), "CHALLENGES  [J to toggle]", HORIZONTAL_ALIGNMENT_LEFT, pw, 18, Color("#ffd700"))

	var y = py + 60
	# Catch 'em all
	var caught = GameManager.pokedex_caught.size()
	var total = PokemonDB.species.size()
	draw_string(ThemeDB.fallback_font, Vector2(px + 20, y), "1. Catch 'Em All", HORIZONTAL_ALIGNMENT_LEFT, pw, 14, Color("#4fc3f7"))
	y += 20
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, y), "Progress: %d/%d Pokemon (%d%%)" % [caught, total, caught * 100 / maxi(total, 1)], HORIZONTAL_ALIGNMENT_LEFT, pw, 12, Color("#ccc"))
	y += 16
	# Progress bar
	draw_rect(Rect2(px + 30, y, pw - 60, 10), Color("#222"))
	draw_rect(Rect2(px + 30, y, (pw - 60) * float(caught) / float(maxi(total, 1)), 10), Color("#4caf50"))
	y += 20
	if caught >= total:
		draw_string(ThemeDB.fallback_font, Vector2(px + 30, y), "COMPLETE! You're a Pokemon Master!", HORIZONTAL_ALIGNMENT_LEFT, pw, 12, Color("#ffd700"))
	y += 24

	# Speedrun
	draw_string(ThemeDB.fallback_font, Vector2(px + 20, y), "2. Speedrun Timer", HORIZONTAL_ALIGNMENT_LEFT, pw, 14, Color("#4fc3f7"))
	y += 20
	if active_challenge == "speedrun":
		var t = challenge_stats["speedrun_time"]
		var mins = int(t / 60)
		var secs = int(t) % 60
		draw_string(ThemeDB.fallback_font, Vector2(px + 30, y), "Timer: %02d:%02d (running)" % [mins, secs], HORIZONTAL_ALIGNMENT_LEFT, pw, 12, Color("#4caf50"))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(px + 30, y), "Press 2 to start timer", HORIZONTAL_ALIGNMENT_LEFT, pw, 12, Color("#aaa"))
	y += 24

	# Shiny counter
	y += 10
	draw_string(ThemeDB.fallback_font, Vector2(px + 20, y), "Stats", HORIZONTAL_ALIGNMENT_LEFT, pw, 14, Color("#4fc3f7"))
	y += 20
	var shiny_count = 0
	for pkmn in GameManager.party:
		if pkmn.is_shiny:
			shiny_count += 1
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, y), "Shinies found: %d" % shiny_count, HORIZONTAL_ALIGNMENT_LEFT, pw, 12, Color("#ffd700"))
	y += 16
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, y), "Badges: %d/8" % GameManager.badges_earned, HORIZONTAL_ALIGNMENT_LEFT, pw, 12, Color("#ccc"))
	y += 16
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, y), "Party size: %d/6" % GameManager.party.size(), HORIZONTAL_ALIGNMENT_LEFT, pw, 12, Color("#ccc"))

	draw_string(ThemeDB.fallback_font, Vector2(px + 20, py + ph - 16), "Press ESC to close", HORIZONTAL_ALIGNMENT_LEFT, pw, 10, Color("#888"))
