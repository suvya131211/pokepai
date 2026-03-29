extends Control

var expanded: bool = false

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		expanded = !expanded
		visible = expanded
		get_viewport().set_input_as_handled()
		queue_redraw()

func _process(_delta):
	if visible:
		queue_redraw()

func _draw():
	if not visible:
		return
	var vp = get_viewport_rect().size
	var w = vp.x
	var h = vp.y

	# Dark overlay
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.75))

	# Panel
	var pw = w * 0.85
	var ph = h * 0.9
	var px = (w - pw) / 2
	var py = (h - ph) / 2
	draw_rect(Rect2(px, py, pw, ph), Color(0.06, 0.08, 0.14, 0.98))
	draw_rect(Rect2(px, py, pw, ph), Color("#4fc3f7"), false, 2.0)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(px + 20, py + 30), "CONTROLS  [H to close]", HORIZONTAL_ALIGNMENT_LEFT, pw, 20, Color("#4fc3f7"))

	# Two columns
	var col1_x = px + 20
	var col2_x = px + pw / 2 + 10
	var line_h = 17.0

	# Column 1: Exploration
	var y = py + 60
	_draw_section(col1_x, y, "EXPLORATION", [
		["WASD / Arrows", "Move"],
		["Shift", "Sprint"],
		["E", "Talk / Interact / Fish"],
		["P", "Pokedex"],
		["I", "Inventory"],
		["C", "Pokemon Summary"],
		["V", "Evolution Tracker"],
		["J", "Challenges / Stats"],
		["M", "Map (expand/collapse)"],
		["T", "Fly (fast travel)"],
		["H", "This help screen"],
	])

	y += 12 * line_h + 20
	_draw_section(col1_x, y, "SAVE / LOAD / AUDIO", [
		["F5", "Save game"],
		["F9", "Load game"],
		["F1", "Toggle music %s" % ("ON" if SoundManager.music_enabled else "OFF")],
		["F2", "Toggle SFX %s" % ("ON" if SoundManager.sfx_enabled else "OFF")],
	])

	y += 3 * line_h + 20
	_draw_section(col1_x, y, "INVENTORY (while open)", [
		["1-6", "Heal Pokemon with berry"],
		["R", "Use Repel (200 steps)"],
		["E", "Use Escape Rope"],
		["I / ESC", "Close inventory"],
	])

	# Column 2: Battle
	y = py + 60
	_draw_section(col2_x, y, "BATTLE — MENU", [
		["Click FIGHT / F", "Select a move"],
		["Click BAG / B", "Throw Pokeball"],
		["Click POKEMON / 3", "Switch Pokemon"],
		["Click RUN / R", "Flee battle"],
	])

	y += 5 * line_h + 20
	_draw_section(col2_x, y, "BATTLE — MOVES", [
		["1 / 2 / 3 / 4", "Select move"],
		["F (in move menu)", "Use first move"],
		["ESC", "Back to menu"],
	])

	y += 4 * line_h + 20
	_draw_section(col2_x, y, "BATTLE — CATCHING", [
		["", "Weaken wild Pokemon to < 50% HP"],
		["Click BAG", "Choose ball type"],
		["", "Lower HP + Status = better catch!"],
		["", "Pokeball < Great < Ultra < Master"],
	])

	y += 5 * line_h + 20
	_draw_section(col2_x, y, "TIPS", [
		["", "Talk to Nurse Joy (pink) to heal"],
		["", "Talk to Shopkeeper (blue) for items"],
		["", "Face Gym Leader (gold) and press E"],
		["", "Green dots on map = exits"],
		["", "Collect 8 badges for Pokemon League!"],
		["", "Stars on Pokemon = SHINY (rare!)"],
	])

	# Footer
	draw_string(ThemeDB.fallback_font, Vector2(px + 20, py + ph - 10), "Press H to close", HORIZONTAL_ALIGNMENT_LEFT, pw, 12, Color("#888"))

func _draw_section(x: float, y: float, title: String, items: Array):
	draw_string(ThemeDB.fallback_font, Vector2(x, y), title, HORIZONTAL_ALIGNMENT_LEFT, 300, 14, Color("#ffd700"))
	y += 20
	for item in items:
		var key = item[0]
		var desc = item[1]
		if key != "":
			draw_string(ThemeDB.fallback_font, Vector2(x, y), key, HORIZONTAL_ALIGNMENT_LEFT, 120, 12, Color("#4fc3f7"))
			draw_string(ThemeDB.fallback_font, Vector2(x + 130, y), desc, HORIZONTAL_ALIGNMENT_LEFT, 200, 12, Color("#ccc"))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(x, y), desc, HORIZONTAL_ALIGNMENT_LEFT, 300, 11, Color("#aaa"))
		y += 17
